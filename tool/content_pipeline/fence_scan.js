const fs = require('fs');
const path = require('path');
const dir = 'F:/app/assets/content';
const fence = String.fromCharCode(96, 96, 96);
const out = [];
for (const f of fs.readdirSync(dir)) {
  if (!f.endsWith('.md')) continue;
  const lines = fs.readFileSync(path.join(dir, f), 'utf8').split('\n');
  let open = null;
  for (let i = 0; i < lines.length; i++) {
    const t = lines[i].trimLeft();
    if (!t.startsWith(fence)) continue;
    if (open === null) {
      const info = t.slice(3).trim();
      if (!info) open = i;
      else open = { i, info };
    } else {
      if (typeof open === 'number') out.push(f + ' L' + (open + 1) + ' bare (closes L' + (i + 1) + ')');
      open = null;
    }
  }
  if (open !== null) out.push(f + ' UNCLOSED from L' + ((typeof open === 'number' ? open : open.i) + 1));
}
console.log(out.length);
console.log(out.join('\n'));
