// 找出「有序列表被代码块打断后从 2/3/4 重新起头」的位置：
// 渲染器会把它当成一个新列表，显示成 3. 4. 而不是接上前面的 1. 2.
import fs from 'node:fs';
import path from 'node:path';

const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const hits = [];
let files = 0;
for (const c of manifest.categories) for (const l of c.lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const lines = fs.readFileSync(p, 'utf8').split(/\r?\n/);
  let open = 0, prevFence = -1;
  lines.forEach((line, i) => {
    const m = /^ {0,3}(`{3,})/.exec(line);
    if (m) { const len = m[1].length; if (open === 0) open = len; else if (len >= open) { open = 0; prevFence = i; } return; }
    if (open > 0) return;
    const g = /^(\d{1,2})\.\s/.exec(line);
    if (!g) return;
    const n = Number(g[1]);
    if (n !== 1 && prevFence === i - 2) { // 紧邻代码块之后（隔一个空行）且不是从 1 开始
      hits.push(`${path.basename(p)}:${i + 1} 从 ${n}. 起头`);
      files++;
    }
    prevFence = -1;
  });
}
console.log(`有序列表被打断后重新起头：${hits.length} 处，涉及文件按处计数 ${files}`);
for (const h of hits.slice(0, 40)) console.log('  ' + h);
