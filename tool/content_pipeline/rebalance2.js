const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const MPATH = path.join(DIR, 'manifest.json');
const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'];
const norm = (s) => String(s).replace(/\s+/g, '');
const optLine = /^([A-F])\s*[.、)]\s*(.*)$/;
const letterRef = /[ABCDEF]\s*[．.、]|选项\s*[ABCDEF]|[ABCDEF]\s*(?:选项|项)|正确答案\s*[是为]?\s*[ABCDEF]/;
const fence = String.fromCharCode(96, 96, 96);

const manifest = JSON.parse(fs.readFileSync(MPATH, 'utf8'));
const texts = new Map(); // file -> lines
function readText(basename) {
  if (!texts.has(basename)) texts.set(basename, fs.readFileSync(path.join(DIR, basename), 'utf8').split('\n'));
  return texts.get(basename);
}

function blockRanges(lines, qText) {
  const target = norm(qText);
  const hits = [];
  lines.forEach((l, i) => { if (norm(l).includes(target) && !optLine.test(l.trim())) hits.push(i); });
  const heads = [];
  let f = false;
  lines.forEach((l, i) => {
    if (l.trimLeft().startsWith(fence)) { f = !f; return; }
    if (!f && /^#{2,6}\s/.test(l)) heads.push(i);
  });
  const out = [];
  for (const h of hits) {
    let s = 0;
    for (const x of heads) { if (x < h) s = x; else break; }
    let e = lines.length;
    for (const x of heads) { if (x > s) { e = x; break; } }
    if (!out.some((r) => r[0] === s)) out.push([s, e]);
  }
  return out;
}

function swapInLines(lines, q, from, to) {
  const ranges = blockRanges(lines, q.question);
  if (!ranges.length) return null;
  const next = lines.slice();
  const lFrom = LETTERS[from], lTo = LETTERS[to];
  let touched = 0;
  for (const [s, e] of ranges) {
    const rows = [];
    for (let i = s; i < e; i++) {
      const m = optLine.exec(lines[i].trim());
      if (m) rows.push({ i, letter: m[1], body: m[2].replace(/\s+$/, '') });
    }
    if (rows.length !== q.options.length) {
      if (/正确答案[^A-F\n]*[A-F]/.test(lines.slice(s, e).join('\n'))) return null;
      continue; // prose block without options and without answer letters
    }
    const text = {}, mark = {};
    for (const r of rows) {
      let body = r.body;
      const cm = body.match(/\s*✅\s*$/);
      if (cm) body = body.slice(0, cm.index);
      text[r.letter] = body.trim();
      mark[r.letter] = !!cm;
    }
    if (rows.some((r) => norm(text[r.letter]) !== norm(q.options[LETTERS.indexOf(r.letter)]))) return null;
    if (!text[lFrom] || !text[lTo]) return null;
    const nt = {}, nm = {};
    for (const r of rows) { nt[r.letter] = text[r.letter]; nm[r.letter] = mark[r.letter]; }
    nt[lFrom] = text[lTo]; nt[lTo] = text[lFrom];
    nm[lFrom] = mark[lTo]; nm[lTo] = mark[lFrom];
    for (const r of rows) next[r.i] = r.letter + '. ' + nt[r.letter] + (nm[r.letter] ? ' ✅' : '') + '  ';
    const re = new RegExp('(正确答案[^A-F\\n]*)' + lFrom);
    let fixed = false;
    for (let i = s; i < e; i++) {
      if (/正确答案/.test(next[i]) && re.test(next[i])) { next[i] = next[i].replace(re, '$1' + lTo); fixed = true; }
    }
    if (!fixed) return null;
    touched++;
  }
  return touched ? next : null;
}

function leak(q, answer) {
  const o = q.options.map((s) => String(s).trim().length);
  const second = Math.max(...o.filter((_, i) => i !== answer));
  return second >= 0 && o[answer] - second >= 8;
}

// group every single-choice question by normalized stem
const groups = new Map();
for (const c of manifest.categories) {
  for (const l of c.lessons) {
    (l.quiz || []).forEach((q, qi) => {
      if ((q.type || 'single') !== 'single') return;
      if (typeof q.answer !== 'number' || !Array.isArray(q.options) || q.options.length < 4) return;
      const k = norm(q.question);
      if (!groups.has(k)) groups.set(k, []);
      groups.get(k).push({ lesson: l, qi, q });
    });
  }
}

const cands = [];
for (const [k, list] of groups) {
  if (list.length < 1) continue;
  if (!list.every((x) => x.q.answer === 1)) continue;
  const base = list[0].q.options;
  if (!list.every((x) => x.q.options.length === base.length && x.q.options.every((o, i) => norm(o) === norm(base[i])))) continue;
  if (list.some((x) => letterRef.test(String(x.q.explanation || '')))) continue;
  cands.push({ key: k, list });
}
cands.sort((a, b) => (a.key < b.key ? -1 : a.key > b.key ? 1 : 0));

const quota = { 0: 24, 2: 2, 3: 65 };
const moved = { 0: 0, 2: 0, 3: 0 };
const skipped = [];
let cursor = 0;
outer:
while (moved[0] < quota[0] || moved[2] < quota[2] || moved[3] < quota[3]) {
  if (cursor >= cands.length) break;
  const cand = cands[cursor++];
  const files = [...new Set(cand.list.map((x) => path.basename(x.lesson.file)))];
  for (const to of [3, 0, 2]) {
    if (moved[to] >= quota[to]) continue;
    if (leak(cand.list[0].q, to)) continue;
    const staged = [];
    let ok = true;
    for (const f of files) {
      const res = swapInLines(readText(f), cand.list[0].q, 1, to);
      if (!res) { ok = false; break; }
      staged.push({ f, lines: res });
    }
    if (!ok) { skipped.push(cand.key.slice(0, 40)); continue outer; }
    for (const { f, lines } of staged) texts.set(f, lines);
    for (const entry of cand.list) {
      const tmp = entry.q.options[1];
      entry.q.options[1] = entry.q.options[to];
      entry.q.options[to] = tmp;
      entry.q.answer = to;
    }
    moved[to]++;
    if (moved[0] >= quota[0] && moved[2] >= quota[2] && moved[3] >= quota[3]) break outer;
    continue outer;
  }
}
console.log('moved', JSON.stringify(moved), 'skipped-layout', skipped.length, 'candidates', cands.length);
if (process.argv[2] === '--apply') {
  for (const [f, lines] of texts) fs.writeFileSync(path.join(DIR, f), lines.join('\n'));
  fs.writeFileSync(MPATH, JSON.stringify(manifest, null, 2));
  console.log('applied', texts.size, 'files');
}
