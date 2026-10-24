/**
 * 第 37 波：补上「选项自带句号」造成的两处破口。
 *
 * 背景：一批 code/single 题的正确项原文以「。」结尾（如「…权限和重试。」），生成解析时把它塞进
 * 「本题正确项是X术语 …」，句号被吞在选项里，读起来变成「…重试」术语 …」——句子没有断开。
 * 同一句的「本题取X这条」也因为文本里少了那个句号，跟选项逐字对不上，第 36 波不敢包书名号。
 *
 * 做三件事（都可重复执行）：
 *   1. 允许正确项结尾标点缺失的匹配，把「本题取/本题按/本题还要同时命中」的裸写也包进「」；
 *   2. 「」后面直接跟着「术语/涉及/本课/题干/判断时/最后/易错点/正确做法」时补一个句号；
 *   3. 填空题的答案统一写成「本题要填的是「canonical」。」，canonical 取 accepted_answers 第一项，
 *      课文里旧写法「本题还要同时命中「x」这条。」同步换成这一句。
 *
 *   node tool/content_pipeline/wave37_answer_punct.js [--apply] [--show]
 */
const fs = require('fs');

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const MANIFEST = 'assets/content/manifest.json';
const MARKERS = ['本题正确项是', '本题要填的是', '正确项：'];
const TAKE_FORMS = [['本题取', '这条'], ['本题按', '这条判断'], ['本题还要同时命中', '这条']];
const CONNECT = /^(?:术语|涉及|本课|题干|判断时|最后|易错点|正确做法)/;
const PUNCT_CHARS = '。；！？，、：」』)）';
const TAIL_PUNCT = /[。；！？]+$/;
const HEAD = /^\s*-\s*\*\*(?:题目|题干)\*\*：([\s\S]*)$/;
const JUDGE = /^(\s*-\s*\*\*判断依据\*\*：)([\s\S]*)$/;

const flat = (t) => String(t || '').replace(/[\s`*_「」『』“”"]/g, '');
const stripTail = (t) => String(t).replace(TAIL_PUNCT, '');

function answerTexts(question) {
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
  const accepted = Array.isArray(question.accepted_answers)
    ? question.accepted_answers.map(String)
    : [];
  return [...chosen, ...accepted].sort((a, b) => b.length - a.length);
}

/// 依次尝试：原文、与 marker 共用一个字、选项结尾标点没写出来的那一截。
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
    const loose = stripTail(option);
    if (loose && loose !== option && text.startsWith(loose, from)) {
      return [loose, loose.length];
    }
  }
  return [null, 0];
}

function quoteMarkers(text, options) {
  let out = String(text || '');
  let hits = 0;
  for (const marker of MARKERS) {
    let at = out.indexOf(marker);
    while (at >= 0) {
      const from = at + marker.length;
      const next = out[from];
      if (next === '「' || next === '`' || next === '“') {
        at = out.indexOf(marker, from);
        continue;
      }
      const [matched, consumed] = matchAt(out, from, options, marker[marker.length - 1]);
      if (!matched) {
        at = out.indexOf(marker, from);
        continue;
      }
      const inner = stripTail(matched);
      const trailing = matched.slice(inner.length);
      const rest = out.slice(from + consumed);
      out =
        out.slice(0, from) + '「' + inner + '」' +
        (PUNCT_CHARS.includes(rest[0] || '') ? '' : trailing) + rest;
      hits++;
      at = out.indexOf(marker, from + 2 + inner.length);
    }
  }
  return [out, hits];
}

function quoteTakeClauses(text, options) {
  let out = String(text || '');
  let hits = 0;
  for (const [prefix, suffix] of TAKE_FORMS) {
    let at = out.indexOf(prefix);
    while (at >= 0) {
      const from = at + prefix.length;
      if (out[from] === '「') {
        at = out.indexOf(prefix, from);
        continue;
      }
      const [matched, consumed] = matchAt(out, from, options, prefix[prefix.length - 1]);
      if (!matched || !out.startsWith(suffix, from + consumed)) {
        at = out.indexOf(prefix, from);
        continue;
      }
      out = out.slice(0, from) + '「' + stripTail(matched) + '」' + out.slice(from + consumed);
      hits++;
      at = out.indexOf(prefix, from + matched.length + 2);
    }
  }
  return [out, hits];
}

/// 「…重试」术语 …」这种引用后直接接下一个句子，补句号断开。
function breakAfterQuote(text) {
  let out = '';
  let hits = 0;
  for (let i = 0; i < text.length; i++) {
    out += text[i];
    if (text[i] !== '」') continue;
    const next = text.slice(i + 1, i + 2);
    if (!next || PUNCT_CHARS.includes(next)) continue;
    if (!CONNECT.test(text.slice(i + 1, i + 8))) continue;
    out += '。';
    hits++;
  }
  return [out, hits];
}

/// 填空题：答案句只认 accepted_answers 的第一项（规范写法），其余大小写变体不再罗列。
function normalizeFillSentence(text, canonical) {
  let out = String(text || '');
  if (!canonical) return [out, 0];
  let hits = 0;
  const sentence = `本题要填的是「${stripTail(canonical)}」。`;
  for (const pattern of [
    /本题要填的是[^。]*?。/g,
    /本题还要同时命中[\s\S]*?这条。/g,
  ]) {
    const next = out.replace(pattern, sentence);
    if (next !== out) {
      out = next;
      hits++;
    }
  }
  return [out, hits];
}

const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);
const stats = { bank: 0, quote: 0, break: 0, fill: 0, mdBlocks: 0, mdQuote: 0, mdBreak: 0, mdFill: 0, miss: 0, files: 0 };
const samples = [];

function repair(text, question) {
  let out = String(text || '');
  let quote = 0;
  let brk = 0;
  let fill = 0;
  if (question.type === 'fill') {
    const canonical = (question.accepted_answers || [])[0];
    [out, fill] = normalizeFillSentence(out, canonical);
  }
  const options = answerTexts(question);
  if (options.length) {
    [out, quote] = quoteMarkers(out, options);
    [out, brk] = quoteTakeClauses(out, options);
    quote += brk;
  }
  [out, brk] = breakAfterQuote(out);
  return [out, quote, brk, fill];
}

for (const category of manifest.categories) {
  for (const lesson of category.lessons || []) {
    const byStem = new Map();
    for (const question of lesson.quiz || []) {
      byStem.set(flat(question.question), question);
      const [repaired, quote, brk, fill] = repair(question.explanation, question);
      if (repaired === question.explanation) continue;
      stats.bank++;
      stats.quote += quote;
      stats.break += brk;
      stats.fill += fill;
      if (SHOW && samples.length < 12 && brk) {
        samples.push([`解析 ${lesson.id}`, String(question.explanation), repaired]);
      }
      question.explanation = repaired;
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
      const question = byStem.get(flat(stem));
      if (!question) {
        if (/」(?:术语|涉及|本课|题干|判断时)/.test(judge[2])) stats.miss++;
        continue;
      }
      const [repaired, quote, brk, fill] = repair(judge[2], question);
      if (repaired === judge[2]) continue;
      stats.mdBlocks++;
      stats.mdQuote += quote;
      stats.mdBreak += brk;
      stats.mdFill += fill;
      if (SHOW && samples.length < 24) {
        samples.push([`课文 ${lesson.id}`, judge[2], repaired]);
      }
      lines[i] = judge[1] + repaired;
      changed++;
    }
    if (changed) {
      stats.files++;
      if (APPLY) fs.writeFileSync(file, lines.join(nl));
    }
  }
}

if (APPLY) {
  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
}
console.log(
  `解析：改动 ${stats.bank} 条｜包正确项 ${stats.quote} 处｜补句号 ${stats.break} 处｜填空口径 ${stats.fill} 处`
);
console.log(
  `课文：改动文件 ${stats.files}｜判断依据块 ${stats.mdBlocks}｜包正确项 ${stats.mdQuote}｜补句号 ${stats.mdBreak}｜填空口径 ${stats.mdFill}｜题干定位不到 ${stats.miss}`
);
if (SHOW) {
  for (const sample of samples) {
    console.log(`\n[${sample[0]}]\n  原文 ${sample[1]}\n  改后 ${sample[2]}`);
  }
}
if (!APPLY) console.log('（试运行，加 --apply 才落盘）');
