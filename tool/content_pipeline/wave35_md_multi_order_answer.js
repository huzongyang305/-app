/**
 * 第 35 波：课文考点精讲里，多选/排序题的判断依据还在用「本题正确项是X」的单选口径。
 *
 * 背景：题库侧早就不这么写多选和排序了——多选是「按《…》的正文口径，本题要同时选中「A」、「B」，
 * 漏掉任一项都算没答全」，排序是「按《…》正文的先后，本题顺序是「a」 → 「b」」。课文的判断依据
 * 是更早抄过去的副本，784 个块仍然把多选讲成只有一个正确项，跟同一个块里的「- **正确项**：AD」
 * 自相矛盾，学员照着背只会漏选。
 *
 * 判定：按题干定位到本课题库的那道题，只处理 multi / order。
 *   ① 去掉答案句和「本题取X这条」后，课文尾部与解析尾部逐字一样（绝大多数）——整行换成解析；
 *   ② 尾部有课文自己写的术语或易错点——只把答案句换成解析的那句、删掉「本题取X这条」，其余不动。
 * 题干在本课题库里对不上号、或解析里找不到多选/排序答案句的，一律不碰，只报数。
 *
 *   node tool/content_pipeline/wave35_md_multi_order_answer.js [--apply]
 */
const fs = require('fs');

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const MANIFEST = 'assets/content/manifest.json';
const ANSWER_MARK = /同时选中|顺序是|都要选|需同时/;
const TAKE_CLAUSE = /，?本题取[^。]{0,300}?这条/g;
const TAKE_CLAUSE_ONE = /，?本题取[^。]{0,300}?这条/;
const BY_CLAUSE = /，?本题按[^。，]{0,200}?这条判断/g;
const HEAD = /^\s*-\s*\*\*(?:题目|题干)\*\*：([\s\S]*)$/;
const JUDGE = /^(\s*-\s*\*\*判断依据\*\*：)([\s\S]*)$/;
const TAIL_START = /术语|涉及术语|易错点/;

const flat = (text) =>
  String(text || '').replace(/[\s`*_「」『』“”"]/g, '');

/// 与审计口径一致：反引号与书名号里的标点不算句子边界，返回句末标点之后的位置。
function sentenceEnd(text, from) {
  let inCode = false;
  let inQuote = false;
  for (let i = from; i < text.length; i++) {
    const ch = text[i];
    if (ch === '`') inCode = !inCode;
    else if (!inCode) {
      if (ch === '「' || ch === '『' || ch === '“') inQuote = true;
      else if (ch === '」' || ch === '』' || ch === '”') inQuote = false;
    }
    if (!inCode && !inQuote && '。！!？?；;'.includes(ch)) return i + 1;
  }
  return text.length;
}

/// 解析开头那句答案（到「术语/易错点」之前）；不像多选/排序口径的返回 null。
function answerSentence(explanation) {
  const hit = TAIL_START.exec(explanation);
  const head = (hit ? explanation.slice(0, hit.index) : explanation).trim();
  if (!head || !ANSWER_MARK.test(head)) return null;
  if (!/[。；;]$/.test(head)) return null;
  return head;
}

/// 去掉「本题正确项是X。」整句与「本题取X这条」「本题按X这条判断」从句，剩下的就是课文自己写的术语/易错点。
function stripAnswerPhrases(text) {
  let out = String(text || '');
  for (let at = out.indexOf('本题正确项是'); at >= 0; ) {
    let start = at;
    while (start > 0 && !'。！!？?；;'.includes(out[start - 1])) start--;
    const end = sentenceEnd(out, at);
    out = out.slice(0, start) + out.slice(end);
    at = out.indexOf('本题正确项是', start);
  }
  out = out.replace(TAKE_CLAUSE, '');
  out = out.replace(BY_CLAUSE, '');
  return out
    .replace(/\s{2,}/g, ' ')
    .replace(/。{2,}/g, '。')
    .replace(/^[，、；。\s]+/, '')
    .trim();
}

function tailOf(text) {
  const hit = TAIL_START.exec(text);
  return hit ? flat(text.slice(hit.index)) : '';
}

const raw = fs.readFileSync(MANIFEST, 'utf8');
const manifest = JSON.parse(raw);
const stats = {
  blocks: 0,
  replaced: 0,
  spliced: 0,
  already: 0,
  noAnswerSentence: 0,
  stemMiss: 0,
  files: 0,
};
const samples = [];

for (const category of manifest.categories) {
  for (const lesson of category.lessons || []) {
    const file = `assets/content/${String(lesson.file || '').split('/').pop()}`;
    if (!fs.existsSync(file)) continue;
    const text = fs.readFileSync(file, 'utf8');
    const nl = text.includes('\r\n') ? '\r\n' : '\n';
    const lines = text.split(/\r?\n/);
    const start = lines.findIndex((line) => line.trim() === '## 考点精讲');
    if (start < 0) continue;
    let stop = lines.length;
    for (let i = start + 1; i < lines.length; i++) {
      if (/^##(?!#)/.test(lines[i])) { stop = i; break; }
    }
    let stem = null;
    let changed = 0;
    for (let i = start + 1; i < stop; i++) {
      if (/^\s*#{2,4}\s/.test(lines[i])) { stem = null; continue; }
      const head = HEAD.exec(lines[i]);
      if (head) { stem = head[1]; continue; }
      const judge = JUDGE.exec(lines[i]);
      if (!judge || !stem) continue;
      const question = (lesson.quiz || []).find(
        (item) => flat(item.question) === flat(stem)
      );
      if (!question) { stats.stemMiss++; continue; }
      const type = question.type || 'single';
      if (type !== 'multi' && type !== 'order') continue;
      if (!/本题正确项是|本题取[^。]{0,300}?这条/.test(judge[2])) continue;
      stats.blocks++;
      const explanation = String(question.explanation || '');
      const answer = answerSentence(explanation);
      if (!answer) { stats.noAnswerSentence++; continue; }
      const stripped = stripAnswerPhrases(judge[2]);
      if (flat(stripped) === flat(explanation)) { stats.already++; continue; }
      const mdTail = tailOf(stripped);
      const expTail = tailOf(explanation);
      const body = stripped.trim();
      let next;
      if (!body || mdTail === expTail) {
        next = judge[1] + explanation.trim().replace(/\s+/g, ' ');
        stats.replaced++;
      } else {
        next = judge[1] + `${answer} ${body}`.replace(/([。；！？]) +/, '$1').trim();
        stats.spliced++;
      }
      if (next !== lines[i]) {
        if (SHOW && samples.length < 24 && body && mdTail !== expTail) {
          samples.push([
            '拼接',
            `${lesson.id} ${type}`,
            judge[2],
            next.slice(judge[1].length),
          ]);
        }
        lines[i] = next;
        changed++;
      }
    }
    if (APPLY && changed) {
      fs.writeFileSync(file, lines.join(nl));
      stats.files++;
    } else if (changed) {
      stats.files++;
    }
  }
}

const s = stats;
console.log(
  `多选/排序块 ${s.blocks}｜整行换成解析 ${s.replaced}｜只换答案句 ${s.spliced}｜已同步 ${s.already}｜` +
    `解析里没有多选/排序答案句 ${s.noAnswerSentence}｜题干对不上 ${s.stemMiss}｜改动文件 ${s.files}`
);
if (SHOW) {
  for (const sample of samples) {
    console.log(`\n[${sample[0]}] ${sample[1]}\n  原文 ${sample[2]}\n  改后 ${sample[3]}`);
  }
}
if (!APPLY) console.log('（试运行，加 --apply 才落盘）');
