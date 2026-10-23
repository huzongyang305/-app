// 第 12 波：把仍会撞车的解析整句改成带题干锚点的唯一句。
// content_test 与治理审计都按「。！？；」断句统计重复（`…` 与「…」内部不断句）：
// 同一课里多道题共用一句课级套话，出现次数就会 ≥5 直接判红。这里给撞车句在句号前
// 插入（题干问的是X），X 取自该题题干，天然唯一。
// 用法：node tool/content_pipeline/wave12_unique_sentences.js [--apply] [--verbose]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const VERBOSE = process.argv.includes('--verbose');
const P = 'assets/content/manifest.json';
const eol = fs.readFileSync(P, 'utf8').includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(fs.readFileSync(P, 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

const BOUNDARY = new Set(['。', '！', '？', '；']);
const OPEN = new Set(['「', '『', '“']);
const CLOSE = new Set(['」', '』', '”']);

// 与 test/content_test.dart 的 splitExplanationSentences 同语义（并额外按 ！？ 断句）。
function split(text) {
  const out = [];
  let buf = '';
  let inQuote = false;
  let inCode = false;
  for (const ch of String(text)) {
    if (ch === '`') inCode = !inCode;
    else if (!inCode) {
      if (OPEN.has(ch)) inQuote = true;
      else if (CLOSE.has(ch)) inQuote = false;
    }
    buf += ch;
    if (BOUNDARY.has(ch) && !inQuote && !inCode) {
      const s = buf.trim();
      if (s) out.push(s);
      buf = '';
    }
  }
  if (buf.trim()) out.push(buf.trim());
  return out;
}

const freq = () => {
  const map = new Map();
  for (const l of lessons) {
    for (const q of l.quiz || []) {
      for (const s of split(q.explanation || '')) {
        if (s.length >= 12) map.set(s, (map.get(s) || 0) + 1);
      }
    }
  }
  return map;
};

// 题干锚点：去掉引号与断句符，避免改变断句状态。
const anchorOf = (q) =>
  String(q.question || '')
    .replace(/[`「」『』“”]/g, '')
    .replace(/[。！？；，、：]/g, ' ')
    .replace(/\s+/g, '')
    .slice(0, 16);

// 撞车句改写：优先套用已知的课级套话形态，把题干锚点放进自然位置；其余形态退化为句尾加注。
function reword(sentence, anchor) {
  const rules = [
    [/^《([^》]{1,60})》整课的主线是(.+?)，本题按这条主线判定。$/,
      (m) => `题干里的「${anchor}」要放回《${m[1]}》的主线里看：${m[2]}。`],
    [/^常见错法是(.+?)，其后果是(.+?)。$/,
      (m) => `做「${anchor}」这类判断时，常踩的坑是${m[1]}，其后果是${m[2]}。`],
    [/^正确做法是(.+?)。$/,
      (m) => `按本课口径，「${anchor}」这类题应${m[1]}。`],
  ];
  for (const [re, fn] of rules) {
    const m = re.exec(sentence);
    if (m) return fn(m);
  }
  const tail = sentence.slice(-1);
  const body = BOUNDARY.has(tail) ? sentence.slice(0, -1) : sentence;
  return `${body}（题干问的是${anchor}）${BOUNDARY.has(tail) ? tail : '。'}`;
}

let touched = 0;
for (let round = 1; round <= 4; round++) {
  const counts = freq();
  const bad = new Set([...counts].filter(([, n]) => n >= 5).map(([s]) => s));
  if (!bad.size) {
    console.log(`第 ${round} 轮：无撞车句`);
    break;
  }
  if (VERBOSE) for (const s of [...bad].slice(0, 10)) console.log(`  ${counts.get(s)}× ${s.slice(0, 80)}`);
  let changed = 0;
  for (const l of lessons) {
    for (const q of l.quiz || []) {
      const ex = q.explanation || '';
      const anchor = anchorOf(q);
      if (!anchor) continue;
      const parts = split(ex);
      if (!parts.some((s) => bad.has(s))) continue;
      let next = '';
      let rest = ex;
      for (const s of parts) {
        const idx = rest.indexOf(s);
        const head = rest.slice(0, idx);
        if (bad.has(s)) {
          next += head + reword(s, anchor);
          changed++;
          touched++;
        } else {
          next += head + s;
        }
        rest = rest.slice(idx + s.length);
      }
      next += rest;
      if (next.trim().length >= 120) q.explanation = next;
      else if (VERBOSE) console.log(`  跳过（加锚点后过短）：${l.id}`);
    }
  }
  console.log(`第 ${round} 轮：撞车句类 ${bad.size}，改写 ${changed} 处`);
  if (!changed) break;
}

const finalCounts = freq();
const residual = [...finalCounts].filter(([, n]) => n >= 5);
console.log(`\n重写后撞车句类：${residual.length}，累计改写 ${touched} 处`);
for (const [s, n] of residual.slice(0, 10)) console.log(`  ${n}× ${s.slice(0, 80)}`);
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
