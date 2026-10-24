/**
 * 第 36 波：解析与课文里「本题正确项是X」「本题取X这条」的 X 补上书名号。
 *
 * 背景：生成解析时把正确项原文直接接在「本题正确项是」后面，读到哪算哪——选项本身带标点时
 * 尤其糟，比如「本题正确项是新 RuntimeException("处理失败", cause)。术语 …」，学员分不清哪个
 * 句号属于句子、哪个属于代码。同一句里的干扰项早就写成「干扰项「X」」，只有正确项裸着，口径不一。
 *
 * 判定：只认逐字对得上本题正确项原文的那一段，原样包进「」，选项结尾的标点挪到书名号外面；
 * 已带「」或对不上任何正确项的不碰，只报数。课文侧按题干定位本课题库的那道题，定位不到就跳过。
 *
 *   node tool/content_pipeline/wave36_option_quote.js [--apply] [--show]
 */
const fs = require('fs');

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const MANIFEST = 'assets/content/manifest.json';
const MARKERS = ['本题正确项是', '本题要填的是', '正确项：'];
const TAIL_PUNCT = /[。；！？]+$/;
const HEAD = /^\s*-\s*\*\*(?:题目|题干)\*\*：([\s\S]*)$/;
const JUDGE = /^(\s*-\s*\*\*判断依据\*\*：)([\s\S]*)$/;

const flat = (t) => String(t || '').replace(/[\s`*_「」『』“”"]/g, '');

function correctOptions(question) {
  const options = (question.options || []).map(String);
  const indexes =
    Array.isArray(question.answers) && question.answers.length
      ? question.answers
      : Array.isArray(question.correct_order) && question.correct_order.length
      ? question.correct_order
      : typeof question.answer === 'number'
      ? [question.answer]
      : [];
  const chosen = indexes
    .map(Number)
    .filter((i) => Number.isInteger(i) && options[i] != null)
    .map((i) => options[i]);
  // 填空题没有 options，可接受答案在 accepted_answers 里（含小写变体），
  // 解析中的「正确项：X」和「本题还要同时命中x这条」都要按它逐字比对。
  const accepted = Array.isArray(question.accepted_answers)
    ? question.accepted_answers.map(String)
    : [];
  return [...chosen, ...accepted].sort((a, b) => b.length - a.length);
}

/// marker 末尾和选项开头可能共用一个字（「本题正确项是」+「是否自动补跑…」），
/// 直接按 marker 长度切会把选项的「是」吃掉，所以允许这一格重叠。
function matchAt(text, from, options, overlapChar) {
  for (const option of options) {
    if (text.startsWith(option, from)) return [option, option.length];
    if (
      overlapChar &&
      option.startsWith(overlapChar) &&
      text.startsWith(option.slice(1), from)
    ) {
      return [option, option.length - 1];
    }
  }
  return [null, 0];
}

function quoteAfterMarkers(text, options) {
  let out = String(text || '');
  let hits = 0;
  for (const marker of MARKERS) {
    const overlapChar = marker[marker.length - 1];
    let at = out.indexOf(marker);
    while (at >= 0) {
      const from = at + marker.length;
      const next = out[from];
      if (next === '「' || next === '`' || next === '“') {
        at = out.indexOf(marker, from);
        continue;
      }
      const [matched, consumed] = matchAt(out, from, options, overlapChar);
      if (!matched) {
        at = out.indexOf(marker, from);
        continue;
      }
      const inner = matched.replace(TAIL_PUNCT, '');
      const trailing = matched.slice(inner.length);
      const rest = out.slice(from + consumed);
      out =
        out.slice(0, from) +
        '「' +
        inner +
        '」' +
        (TAIL_PUNCT.test(rest) ? '' : trailing) +
        rest;
      hits++;
      at = out.indexOf(marker, from + 2 + inner.length);
    }
  }
  return [out, hits];
}

/// 「本题取X这条」「本题还要同时命中X这条」「本题按X这条判断」三处同理补书名号。
const TAKE_FORMS = [
  ['本题取', '这条'],
  ['本题还要同时命中', '这条'],
  ['本题按', '这条判断'],
];

function quoteTakeClause(text, options) {
  let out = String(text || '');
  let hits = 0;
  for (const [prefix, suffix] of TAKE_FORMS) {
    const overlapChar = prefix[prefix.length - 1];
    let at = out.indexOf(prefix);
    while (at >= 0) {
      const from = at + prefix.length;
      if (out[from] === '「') {
        at = out.indexOf(prefix, from);
        continue;
      }
      const [matched, consumed] = matchAt(out, from, options, overlapChar);
      if (!matched || !out.startsWith(suffix, from + consumed)) {
        at = out.indexOf(prefix, from);
        continue;
      }
      out =
        out.slice(0, from) +
        '「' +
        matched +
        '」' +
        out.slice(from + consumed);
      hits++;
      at = out.indexOf(prefix, from + matched.length + 2);
    }
  }
  return [out, hits];
}

function wrap(text, options) {
  const [quoted, markerHits] = quoteAfterMarkers(text, options);
  const [taken, takeHits] = quoteTakeClause(quoted, options);
  return [taken, markerHits + takeHits];
}

/// 还有没有「包不住」的裸写：marker 后面既不是书名号，也接不上任何正确项原文。
function nakedRemnants(text, options) {
  const out = [];
  for (const marker of MARKERS) {
    const overlapChar = marker[marker.length - 1];
    let at = String(text || '').indexOf(marker);
    while (at >= 0) {
      const from = at + marker.length;
      const next = String(text || '')[from];
      const [matched] = matchAt(String(text || ''), from, options, overlapChar);
      if (next !== '「' && next !== '`' && next !== '“' && !matched) {
        out.push(String(text || '').slice(from, from + 60));
      }
      at = String(text || '').indexOf(marker, from);
    }
  }
  return out;
}

const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);
const stats = {
  bankQuestions: 0,
  bankHits: 0,
  bankMiss: 0,
  mdBlocks: 0,
  mdHits: 0,
  mdMiss: 0,
  stemMiss: 0,
  files: 0,
};
const samples = [];

for (const category of manifest.categories) {
  for (const lesson of category.lessons || []) {
    const optionsByQuestion = new Map();
    for (const question of lesson.quiz || []) {
      const options = correctOptions(question);
      if (!options.length) continue;
      optionsByQuestion.set(flat(question.question), options);
      const [wrapped, hits] = wrap(question.explanation, options);
      const remnants = nakedRemnants(wrapped, options);
      if (remnants.length) {
        stats.bankMiss += remnants.length;
        if (SHOW && remnants.length < 3) {
          samples.push([`裸写残留 解析 ${lesson.id}`, String(question.question).slice(0, 50), remnants.join(' ⏐ ')]);
        }
      }
      if (hits) {
        stats.bankQuestions++;
        stats.bankHits += hits;
        question.explanation = wrapped;
      }
    }

    const file = `assets/content/${String(lesson.file || '').split('/').pop()}`;
    if (!fs.existsSync(file)) continue;
    const text = fs.readFileSync(file, 'utf8');
    const nl = text.includes('\r\n') ? '\r\n' : '\n';
    const lines = text.split(/\r?\n/);
    const start = lines.findIndex((line) => line.trim() === '## 考点精讲');
    if (start < 0) continue;
    let stop = lines.length;
    for (let i = start + 1; i < lines.length; i++) {
      if (/^##(?!#)/.test(lines[i])) {
        stop = i;
        break;
      }
    }
    let stem = null;
    let changed = 0;
    for (let i = start + 1; i < stop; i++) {
      if (/^\s*#{2,4}\s/.test(lines[i])) {
        stem = null;
        continue;
      }
      const head = HEAD.exec(lines[i]);
      if (head) {
        stem = head[1];
        continue;
      }
      const judge = JUDGE.exec(lines[i]);
      if (!judge || !stem) continue;
      if (
        !/本题正确项是|正确项：|本题取|本题还要同时命中|本题按/.test(judge[2])
      ) {
        continue;
      }
      const options = optionsByQuestion.get(flat(stem));
      if (!options) {
        stats.stemMiss++;
        continue;
      }
      stats.mdBlocks++;
      const [wrapped, hits] = wrap(judge[2], options);
      const remnants = nakedRemnants(wrapped, options);
      if (remnants.length) {
        stats.mdMiss += remnants.length;
        if (SHOW && remnants.length < 3) {
          samples.push([`裸写残留 课文 ${lesson.id}`, String(stem).slice(0, 50), remnants.join(' ⏐ ')]);
        }
      }
      if (!hits) continue;
      if (SHOW && samples.length < 20) samples.push([lesson.id, judge[2], wrapped]);
      stats.mdHits += hits;
      lines[i] = judge[1] + wrapped;
      changed++;
    }
    if (changed) {
      stats.files++;
      if (APPLY) fs.writeFileSync(file, lines.join(nl));
    }
  }
}

if (APPLY) {
  fs.writeFileSync(
    MANIFEST,
    JSON.stringify(manifest, null, 2).split('\n').join(eol)
  );
}
console.log(
  `解析：命中题目 ${stats.bankQuestions}（补 ${stats.bankHits} 处）｜有裸写但对不上正确项 ${stats.bankMiss}`
);
console.log(
  `课文：判断依据块 ${stats.mdBlocks}（补 ${stats.mdHits} 处）｜对不上 ${stats.mdMiss}｜题干定位不到 ${stats.stemMiss}｜改动文件 ${stats.files}`
);
if (SHOW) {
  for (const sample of samples) {
    console.log(
      `\n[${sample[0]}]\n  原文 ${sample[1]}\n  改后 ${sample[2]}`
    );
  }
}
if (!APPLY) console.log('（试运行，加 --apply 才落盘）');
