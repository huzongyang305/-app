const fs = require('fs');
const manifest = JSON.parse(fs.readFileSync('F:/app/assets/content/manifest.json', 'utf8'));
const qs = [];
for (const c of manifest.categories) for (const l of c.lessons) for (const q of (l.quiz || [])) {
  if ((q.type || 'single') === 'single' && typeof q.answer === 'number') qs.push({ id: l.id, cat: c.id, q });
}
const n = qs.length;
const cnt = {};
for (const x of qs) cnt[x.q.answer] = (cnt[x.q.answer] || 0) + 1;
console.log('single-choice total', n);
for (let i = 0; i < 4; i++) console.log('  index', i, cnt[i] || 0, (((cnt[i] || 0) * 100) / n).toFixed(2) + '%');
console.log('  other', Object.entries(cnt).filter(([k]) => +k > 3).map(([k, v]) => k + ':' + v).join(','));

function leak(x) {
  const o = x.q.options.map((s) => String(s).trim().length);
  const c = o[x.q.answer];
  const rest = o.filter((_, i) => i !== x.q.answer);
  const second = Math.max(...rest);
  return c - second >= 8;
}
const leaksNow = qs.filter(leak).length;
console.log('longest-correct leak now', leaksNow, ((leaksNow * 100) / n).toFixed(1) + '%');

const letterRef = /[ABCDEF]\s*[．.、]|选项\s*[ABCDEF]|[ABCDEF]\s*(?:选项|项)|答案[是为：:]*\s*[ABCDEF]/;
const idx1 = qs.filter((x) => x.q.answer === 1);
const clean = idx1.filter((x) => !letterRef.test(String(x.q.explanation || '')));
console.log('index1 count', idx1.length, '| without letter refs in explanation', clean.length);
const per = {};
for (const x of clean) {
  for (let k = 0; k < 4; k++) {
    if (k === 1) continue;
    const alt = { q: { ...x.q, answer: k } };
    if (!leak(alt)) (per[k] = per[k] || []).push(x);
  }
}
console.log('movable (no new leak) per target', Object.entries(per).map(([k, v]) => k + ':' + v.length).join(' '));
const share = (cnt[1] || 0) - Math.ceil(n * 0.25) + 1;
console.log('need to move about', share, 'questions out of index 1');
