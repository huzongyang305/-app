const fs = require('fs');
const path = require('path');
const dir = 'F:/app/assets/content';
const fence = String.fromCharCode(96, 96, 96);
let removed = 0;
const risky = [];
for (const f of fs.readdirSync(dir)) {
  if (!f.endsWith('.md')) continue;
  const p = path.join(dir, f);
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  const drop = new Set();
  let open = null;
  for (let i = 0; i < lines.length; i++) {
    const t = lines[i].trimLeft();
    if (!t.startsWith(fence)) continue;
    if (open === null) { open = i; continue; }
    if (!lines[open].trimLeft().slice(3).trim() && i === open + 1) {
      drop.add(open); drop.add(i); removed++;
    }
    open = null;
  }
  if (drop.size) {
    const kept = lines.filter((_, i) => !drop.has(i));
    const remaining = kept.filter((l) => l.trimLeft().startsWith(fence)).length;
    if (remaining < 2) risky.push(f);
    while (kept.length && !kept[kept.length - 1].trim()) kept.pop();
    kept.push('');
    fs.writeFileSync(p, kept.join('\n'));
  }
}
console.log('empty fences removed:', removed, 'files left with <2 fences:', risky.join(', ') || 'none');
