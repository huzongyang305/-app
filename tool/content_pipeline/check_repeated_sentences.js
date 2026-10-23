// 复刻 content_test 的解析断句（只在 。；\n 处断，忽略 `…` 与「…」内部），
// 统计 repo 内重复 5 次以上的模板句。用法：node tool/content_pipeline/check_repeated_sentences.js [阈值]
import fs from 'node:fs';

const threshold = Number(process.argv[2] || 5);
const m = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));
const lessons = [];
for (const c of m.categories) for (const l of c.lessons) lessons.push(l);

function split(text) {
  const out = [];
  let buf = '';
  let inQuote = false;
  let inCode = false;
  for (const ch of String(text)) {
    if (ch === '`') inCode = !inCode;
    else if (!inCode) {
      if (ch === '「' || ch === '『' || ch === '“') inQuote = true;
      else if (ch === '」' || ch === '』' || ch === '”') inQuote = false;
    }
    buf += ch;
    if ((ch === '。' || ch === '；' || ch === '\n') && !inQuote && !inCode) {
      const s = buf.trim();
      if (s) out.push(s);
      buf = '';
    }
  }
  if (buf.trim()) out.push(buf.trim());
  return out;
}

const counts = new Map();
const short = [];
for (const l of lessons) {
  for (let i = 0; i < (l.quiz || []).length; i++) {
    const ex = l.quiz[i].explanation || '';
    if (ex.trim().length < 120) short.push(`${l.id}#${i} ${ex.trim().length}`);
    for (const s of split(ex)) if (s.length >= 12) counts.set(s, (counts.get(s) || 0) + 1);
  }
}
const bad = [...counts].filter(([, n]) => n >= threshold).sort((a, b) => b[1] - a[1]);
console.log(`解析总数 ${lessons.reduce((a, l) => a + (l.quiz || []).length, 0)}，短解析 ${short.length} 条，重复句类 ${bad.length}`);
for (const [s, n] of bad.slice(0, 20)) console.log(`${n}×  ${s.slice(0, 90)}`);
for (const s of short.slice(0, 10)) console.log(`短：${s}`);
