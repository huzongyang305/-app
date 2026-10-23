const fs = require('fs');
const path = require('path');
const DIR = 'F:/app/assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(DIR, 'manifest.json'), 'utf8'));
const norm = (s) => String(s).replace(/\s+/g, '');
const seen = new Map();
for (const c of manifest.categories) {
  for (const l of c.lessons) {
    (l.quiz || []).forEach((q, i) => {
      const k = norm(q.question);
      if (!seen.has(k)) seen.set(k, []);
      seen.get(k).push({ id: l.id, cat: c.id, i, q });
    });
  }
}
const dup = [...seen.entries()].filter(([, v]) => v.length > 1);
console.log('duplicate stems:', dup.length);
for (const [k, v] of dup) {
  console.log('--- ' + k.slice(0, 70));
  for (const e of v) {
    const same = v.filter((x) => x !== e);
    console.log('    ' + e.id + '#' + (e.i + 1) + ' [' + e.cat + '] ans=' + JSON.stringify(e.q.answer ?? e.q.answer_indexes ?? null) + ' opts=' + (e.q.options ? e.q.options.length : 0) + ' sameAsOthers=' + same.every((s) => JSON.stringify(s.q) === JSON.stringify(e.q)));
  }
}
const short = [];
for (const c of manifest.categories) for (const l of c.lessons) {
  const f = path.join(DIR, path.basename(l.file));
  if (!fs.existsSync(f)) continue;
  const n = fs.readFileSync(f, 'utf8').length;
  if (n < 6000) short.push(l.id + '=' + n);
}
console.log('under 6000:', short.join(', ') || 'none');
