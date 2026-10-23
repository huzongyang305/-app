const fs = require('fs');
const path = require('path');
const dir = 'F:/app/assets/content';
const manifest = JSON.parse(fs.readFileSync('F:/app/assets/content/manifest.json', 'utf8'));
const fileToIds = new Map();
for (const c of manifest.categories) for (const l of c.lessons) {
  const b = path.basename(l.file);
  if (!fileToIds.has(b)) fileToIds.set(b, []);
  fileToIds.get(b).push(l.id);
}
const out = [];
for (const f of fs.readdirSync(dir)) {
  if (!f.endsWith('.md')) continue;
  const md = fs.readFileSync(path.join(dir, f), 'utf8');
  const lines = md.split('\n');
  const heads = [];
  let fence = false;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('```')) { fence = !fence; continue; }
    if (fence) continue;
    const m = /^(#{2,6})\s+(.*)$/.exec(lines[i]);
    if (m) heads.push([i, m[1].length, m[2].trim()]);
  }
  for (let k = 0; k < heads.length; k++) {
    const h = heads[k];
    let end = lines.length;
    for (let n = k + 1; n < heads.length; n++) { if (heads[n][1] <= h[1]) { end = heads[n][0]; break; } }
    let has = false;
    for (let i = h[0] + 1; i < end; i++) { const t = lines[i].trim(); if (t && !t.startsWith('#') && t !== '---') { has = true; break; } }
    if (!has) out.push(f + ' L' + (h[0] + 1) + ' [' + h[2] + '] levels=' + h[1]);
  }
}
console.log(out.length);
console.log(out.slice(0, 60).join('\n'));
