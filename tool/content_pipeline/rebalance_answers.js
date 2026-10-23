const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const MPATH = path.join(DIR, 'manifest.json');
const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'];
const norm = (s) => String(s).replace(/\s+/g, '');

const manifest = JSON.parse(fs.readFileSync(MPATH, 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push({ cat: c, l });

function leak(q, answer) {
  const o = q.options.map((s) => String(s).trim().length);
  const c = o[answer];
  const second = Math.max(...o.filter((_, i) => i !== answer));
  return second >= 0 && c - second >= 8;
}
const letterRef = /[ABCDEF]\s*[．.、]|选项\s*[ABCDEF]|[ABCDEF]\s*(?:选项|项)|答案[是为：:]*\s*[ABCDEF]|正确答案\s*[是为]?\s*[ABCDEF]/;

const optLine = /^([A-F])\s*[.、)]\s*(.*)$/;
const ansLine = /^(\*\*)?正确答案(\*\*)?\s*[：:]\s*\*{0,2}([A-F])(?:\s*(?:项|是|为)?\s*([ABCDEF])(?:、[ABCDEF])*)?\*{0,2}\s*$/;

function blocks(lines, qText) {
  // returns [start,end) line ranges of heading blocks containing the question text
  const target = norm(qText);
  const idxs = [];
  lines.forEach((l, i) => { if (norm(l).includes(target) && !optLine.test(l.trim())) idxs.push(i); });
  const heads = [];
  let fence = false;
  lines.forEach((l, i) => {
    if (l.trimLeft().startsWith('```')) { fence = !fence; return; }
    if (!fence && /^#{2,6}\s/.test(l)) heads.push(i);
  });
  const out = [];
  for (const q of idxs) {
    let s = 0;
    for (const h of heads) if (h < q) s = h; else break;
    let e = lines.length;
    for (const h of heads) if (h > s) { e = h; break; }
    if (!out.some((r) => r[0] === s)) out.push([s, e]);
  }
  return out;
}

function trySwap(lines, q, from, to) {
  // returns mutated lines or null when the block layout is not recognised
  const ranges = blocks(lines, q.question);
  if (!ranges.length) return null;
  const next = lines.slice();
  for (const [s, e] of ranges) {
    const seg = next.slice(s, e);
    const rows = [];
    seg.forEach((l, i) => {
      const m = optLine.exec(l.trim());
      if (m) rows.push({ i, letter: m[1], body: m[2] });
    });
    if (rows.length !== q.options.length) return null;
    const textOf = {};
    const markOf = {};
    for (const r of rows) {
      let body = r.body.replace(/\s+$/, '');
      const cm = body.match(/\s*✅\s*$/);
      const marked = !!cm;
      if (cm) body = body.slice(0, cm.index);
      textOf[r.letter] = body.trim();
      markOf[r.letter] = marked;
    }
    const lFrom = LETTERS[from], lTo = LETTERS[to];
    if (textOf[lFrom] === undefined || textOf[lTo] === undefined) return null;
    if (!textOf[lFrom] || !textOf[lTo]) return null;
    if (q.options.some((o, i) => norm(o) !== norm(textOf[LETTERS[i]]))) return null;
    const newText = {};
    for (let i = 0; i < q.options.length; i++) newText[LETTERS[i]] = textOf[LETTERS[i]];
    newText[lFrom] = textOf[lTo];
    newText[lTo] = textOf[lFrom];
    const newMark = {};
    for (let i = 0; i < q.options.length; i++) newMark[LETTERS[i]] = markOf[LETTERS[i]];
    newMark[lFrom] = markOf[lTo];
    newMark[lTo] = markOf[lFrom];
    for (const r of rows) {
      const body = newText[r.letter] + (newMark[r.letter] ? ' ✅' : '');
      next[s + r.i] = r.letter + '. ' + body + '  ';
    }
    let ansFixed = false;
    const re = new RegExp('(正确答案[^A-F\\n]*)' + lFrom);
    for (let i = 0; i < e - s; i++) {
      const line = next[s + i];
      if (/正确答案/.test(line) && re.test(line)) {
        next[s + i] = line.replace(re, '$1' + lTo);
        ansFixed = true;
      }
    }
    if (!ansFixed) return null;
  }
  return next;
}

const idx1 = [];
for (const { cat, l } of lessons) {
  (l.quiz || []).forEach((q, qi) => {
    if (((q.type || 'single') === 'single') && q.answer === 1 && q.options && q.options.length >= 4) {
      if (letterRef.test(String(q.explanation || ''))) return;
      idx1.push({ cat, l, q, qi });
    }
  });
}
idx1.sort((a, b) => {
  const ka = a.cat.id + '|' + a.l.id + '|' + a.qi;
  const kb = b.cat.id + '|' + b.l.id + '|' + b.qi;
  return ka < kb ? -1 : ka > kb ? 1 : 0;
});

const quota = { 0: 24, 2: 2, 3: 65 };
const moved = { 0: 0, 2: 0, 3: 0 };
const fileEdits = new Map();
const skipped = [];
let cursor = 0;
outer:
while (moved[0] < quota[0] || moved[2] < quota[2] || moved[3] < quota[3]) {
  if (cursor >= idx1.length) break;
  const cand = idx1[cursor++];
  const file = path.join(DIR, path.basename(cand.l.file));
  const lines = (fileEdits.get(file) || fs.readFileSync(file, 'utf8')).split('\n');
  for (const to of [3, 0, 2]) {
    if (moved[to] >= quota[to]) continue;
    if (leak({ options: cand.q.options }, to)) continue;
    const next = trySwap(lines, cand.q, 1, to);
    if (!next) { skipped.push(cand.l.id + '#' + (cand.qi + 1)); continue outer; }
    fileEdits.set(file, next.join('\n'));
    const tmp = cand.q.options[1];
    cand.q.options[1] = cand.q.options[to];
    cand.q.options[to] = tmp;
    cand.q.answer = to;
    moved[to]++;
    if (moved[0] >= quota[0] && moved[2] >= quota[2] && moved[3] >= quota[3]) break outer;
    continue outer;
  }
  skipped.push('layout:' + cand.l.id + '#' + (cand.qi + 1));
}
console.log('moved', JSON.stringify(moved), 'skipped', skipped.length);
fs.writeFileSync(path.join(__dirname, 'moved_log.json'), JSON.stringify(skipped, null, 1));
module.exports = { fileEdits, manifest, moved };
if (require.main === module && process.argv[2] === '--apply') {
  for (const [file, text] of fileEdits) fs.writeFileSync(file, text);
  fs.writeFileSync(MPATH, JSON.stringify(manifest, null, 2) + '\n');
  console.log('applied', fileEdits.size, 'files');
}
