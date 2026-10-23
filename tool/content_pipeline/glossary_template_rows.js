// 列出 术语速查 里被判为模板残留的行（复刻治理审计口径）。
// 用法：node tool/content_pipeline/glossary_template_rows.js
import fs from 'node:fs';
import path from 'node:path';

const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

const MARKERS = ['Related terms:', 'focuses on', '它在「', '复习时回到正文', '课程摘要'];
const BAD_TERM = /\s[-=]\s|\.py\b|\.js\b|\(\)|\/\/|\.\.\//;

const fenceMask = (lines) => {
  const mask = lines.map(() => true);
  let open = 0;
  lines.forEach((line, i) => {
    const m = /^ {0,3}(`{3,})/.exec(line);
    if (m) {
      const len = m[1].length;
      if (open === 0) { open = len; mask[i] = false; return; }
      if (len >= open) { open = 0; mask[i] = false; return; }
    }
    if (open > 0) mask[i] = false;
  });
  return mask;
};

let total = 0;
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const lines = fs.readFileSync(p, 'utf8').split(/\r?\n/);
  const mask = fenceMask(lines);
  const start = lines.findIndex((line, i) => mask[i] && /^##\s+术语速查\s*$/.test(line));
  if (start < 0) continue;
  const end = lines.findIndex((line, i) => i > start && mask[i] && /^##\s+\S/.test(line));
  const stop = end < 0 ? lines.length : end;
  const rows = [];
  for (let i = start + 1; i < stop; i++) {
    if (!mask[i] || !/^\s*\|/.test(lines[i])) continue;
    const cells = lines[i].trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((x) => x.trim()).filter(Boolean);
    if (cells.length < 2) continue;
    if (cells[1].startsWith('|') || /^:?-{2,}:?$/.test(cells[0])) continue;
    if (cells[0] === '术语') continue;
    rows.push({ line: i + 1, term: cells[0], expl: cells[1], raw: lines[i] });
  }
  const counts = new Map();
  for (const r of rows) counts.set(r.expl, (counts.get(r.expl) || 0) + 1);
  for (const r of rows) {
    const term = r.term.replace(/`/g, '');
    const why = MARKERS.find((m) => r.expl.includes(m))
      || (counts.get(r.expl) > 1 ? `重复定义 x${counts.get(r.expl)}` : '')
      || (r.expl.startsWith('|') ? '竖线开头' : '')
      || (term !== 'Node.js' && BAD_TERM.test(term) ? '术语名带代码痕迹' : '');
    if (!why) continue;
    total++;
    console.log(`${l.id}:${r.line}  [${why}]  ${r.raw.slice(0, 160)}`);
  }
}
console.log(`\n模板残留行合计 ${total} 行`);
