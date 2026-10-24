// 第 25 波：清掉解析里三处机器生成残句。
//
// 早年的解析生成器在正文后面拼过三种尾巴，现在都留下了可见的破损：
//   1. 「本题正确项是X。本题还要同时命中：Y。」——X 是去掉反引号/下划线的走形版本，
//      真正能被审计认出来的只有带代码标记的 Y，两条并存既重复又让「正确项」指到一个不存在的选项文本；
//   2. 「本课《标题》要解决的是…，本题问的是填空…课程 `片段。」——按字数截断后句子停在半空；
//   3. 「题干「填空：补齐下面这段术语说明中的空缺，课程 `片段」」——把整道题干塞进引号并截断，
//      反引号不配对，读起来像乱码。
// 三种都只删不改写：解析正文（机制、易错点、正确做法）原样保留。每条都过一遍审计的硬指标
// （长度、复述正确项、代码题落在本课主题上、标点），过不了就保持原样。
// 用法：node tool/content_pipeline/wave25_strip_broken_tails.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

// 对齐 tool/audit_content_governance.dart 的 _normalizeAnswerText
const norm = (s) =>
  String(s || '')
    .replace(/（[A-Za-z0-9_.-]+ 第 \d+ 题）/g, '')
    .replace(/^[「『“"\s]+|[」』”"\s]+$/g, '')
    .replace(/[\s。！？!?]+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();

// 对齐 _correctOptions
const correctOptions = (q) => {
  const options = (Array.isArray(q.options) ? q.options : []).map(String);
  const direct = typeof q.answer === 'number' ? q.answer : null;
  if (direct !== null && direct >= 0 && direct < options.length) return [options[direct]];
  const pick = (list) =>
    (Array.isArray(list) ? list : [])
      .map((v) => (typeof v === 'number' ? v : parseInt(String(v), 10)))
      .filter((i) => Number.isInteger(i) && i >= 0 && i < options.length);
  const byAnswers = pick(q.answers);
  if (byAnswers.length) return byAnswers.map((i) => options[i]);
  const byOrder = pick(q.correct_order);
  if (byOrder.length) return byOrder.map((i) => options[i]);
  if (Array.isArray(q.accepted_answers) && q.accepted_answers.length) return [String(q.accepted_answers[0])];
  return [];
};

const BAD_PUNCT = /[。；，]{2,}|。，|，。|…；/;

// 审计对 code/debug 题要求解析命中本课标题或关键词
const mentionsDomain = (lesson, text) => {
  if (lesson.title && text.includes(lesson.title)) return true;
  return (lesson.keywords || []).some((k) => String(k).length >= 2 && text.includes(k));
};

const passGuards = (lesson, q, ex) => {
  if (ex.length < 120) return false;
  if (BAD_PUNCT.test(ex)) return false;
  const flat = norm(ex);
  const parts = correctOptions(q).map(norm).filter(Boolean);
  if (parts.some((p) => !flat.includes(p))) return false;
  if ((q.type === 'code' || q.type === 'debug') && !mentionsDomain(lesson, ex)) return false;
  return true;
};

const tidy = (text) =>
  text
    .replace(/[，、；]{2,}/g, '，')
    .replace(/。{2,}/g, '。')
    .replace(/，。/g, '。')
    .replace(/\s{2,}/g, ' ')
    .trim();

const stats = { merged: 0, tail: 0, quote: 0, rejected: 0, untouched: 0 };
const samples = [];
const note = (kind, id, before, after) => {
  if (!SHOW || samples.length >= 15) return;
  samples.push(`${kind} ${id}｜…${before.slice(-40)} → …${after.slice(-40)}`);
};

for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    for (const q of l.quiz || []) {
      if (typeof q.explanation !== 'string' || !q.explanation) continue;
      let ex = q.explanation;
      const original = ex;
      let changed = false;

      // 1) 「本题正确项是<走形>。本题还要同时命中：<原文>。」→ 只留带原文的那条
      const dupHead = ex.indexOf('本题正确项是');
      const dupTail = ex.indexOf('本题还要同时命中：');
      if (dupHead >= 0 && dupTail > dupHead) {
        const candidate = tidy(
          ex.slice(0, dupHead) + '本题正确项是' + ex.slice(dupTail + '本题还要同时命中：'.length),
        );
        if (passGuards(l, q, candidate)) {
          note('dup', l.id, ex, candidate);
          ex = candidate;
          changed = true;
          stats.merged++;
        } else stats.rejected++;
      }

      // 2) 截断的「本课…要解决的是…」模板尾句，整句删掉
      const tailMatch = /本课[^。」「]{1,40}要解决的是[\s\S]*$/.exec(ex);
      if (tailMatch) {
        const candidate = tidy(ex.slice(0, tailMatch.index).replace(/[，、；：]+$/, '') + '。');
        if (passGuards(l, q, candidate)) {
          if (!changed) note('tail', l.id, ex, candidate);
          ex = candidate;
          changed = true;
          stats.tail++;
        } else stats.rejected++;
      }

      // 3) 塞进引号又被截断的题干片段：「题干「填空：…课程 `半句」」→「题干」
      const quoteRe = /题干「(?:填空：补齐|[^」]*课程 `)[^」]*」/;
      if (quoteRe.test(ex)) {
        const candidate = tidy(ex.replace(quoteRe, '题干'));
        if (passGuards(l, q, candidate)) {
          if (!changed) note('quote', l.id, ex, candidate);
          ex = candidate;
          changed = true;
          stats.quote++;
        } else stats.rejected++;
      }

      if (!changed) { if (original !== ex) stats.untouched++; continue; }
      if (ex === original) { stats.untouched++; continue; }
      q.explanation = ex;
    }
  }
}

console.log(
  `合并重复正确项句 ${stats.merged} 条、删截断模板尾句 ${stats.tail} 条、删截断题干引号 ${stats.quote} 条，守卫退回 ${stats.rejected} 次`,
);
if (samples.length) console.log(samples.join('\n'));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
