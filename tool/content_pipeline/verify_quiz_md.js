const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F'];
const norm = (s) => String(s).replace(/\s+/g, '');
const optLine = /^([A-F])\s*[.、)]\s*(.*)$/;
const manifest = JSON.parse(fs.readFileSync(process.argv[3] || path.join(DIR, 'manifest.json'), 'utf8'));

function blocks(lines, qText) {
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

const problems = [];
let checked = 0;
for (const c of manifest.categories) {
  for (const l of c.lessons) {
    const file = path.join(DIR, path.basename(l.file));
    if (!fs.existsSync(file)) continue;
    const lines = fs.readFileSync(file, 'utf8').split('\n');
    (l.quiz || []).forEach((q, qi) => {
      const type = q.type || 'single';
      if (!q.options || !Array.isArray(q.options) || !q.options.length) return;
      if (type === 'order') return;
      const correct = type === 'multi' ? (q.answer_indexes || []) : [q.answer];
      if (correct.some((x) => typeof x !== 'number')) return;
      for (const [s, e] of blocks(lines, q.question)) {
        const rows = [];
        for (let i = s; i < e; i++) {
          const m = optLine.exec(lines[i].trim());
          if (m) rows.push({ i, letter: m[1], body: m[2].replace(/\s+$/, '') });
        }
        if (rows.length !== q.options.length) continue;
        checked++;
        const ok = rows.every((r, k) => norm(r.body.replace(/\u2705\s*$/, '')) === norm(q.options[k]));
        if (!ok) { problems.push(l.id + '#' + (qi + 1) + ' L' + (s + 1) + ' option-text order differs from manifest'); continue; }
        const marks = rows.filter((r) => /\u2705\s*$/.test(r.body)).map((r) => r.letter);
        if (marks.length && marks.length === correct.length) {
          const wrong = marks.filter((mk, k) => LETTERS[correct[k]] !== mk);
          if (wrong.length) problems.push(l.id + '#' + (qi + 1) + ' L' + (s + 1) + ' checkmark on ' + marks.join(''));
        }
        const ansRe = type === 'multi' ? /正确答案/ : /正确答案|参考答案/;
        for (let i = s; i < e; i++) {
          const line = lines[i];
          if (!ansRe.test(line) || optLine.test(line.trim())) continue;
          const got = (line.match(/[A-F]/g) || []);
          const want = correct.map((x) => LETTERS[x]);
          if (got.length && !want.every((w) => got.includes(w))) {
            problems.push(l.id + '#' + (qi + 1) + ' L' + (i + 1) + ' answer line says ' + got.join('') + ' want ' + want.join(''));
          }
        }
      }
    });
  }
}
console.log('blocks checked', checked, 'problems', problems.length);
console.log(problems.slice(0, 40).join('\n'));
