// 核对：工作区里的 术语速查 相对 HEAD 是否丢了真解释。
// 对每个被改动的课程文件，取 HEAD 与本版 术语速查 小节的 术语->解释 映射，
// 报告「HEAD 有真解释、本版没有/变成占位」的术语。
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const PH = /定位线索见正文小节|速查表只保留名称/;
const cellsOf = (line) => line.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((x) => x.trim());
const isSep = (c) => c.length > 0 && c.every((x) => /^:?-{2,}:?$/.test(x));

function gloss(text) {
  const lines = text.split(/\r?\n/);
  let open = 0;
  const mask = lines.map(() => true);
  lines.forEach((line, i) => {
    const m = /^ {0,3}(`{3,})/.exec(line);
    if (m) { const len = m[1].length; if (open === 0) { open = len; mask[i] = false; return; } if (len >= open) { open = 0; mask[i] = false; return; } }
    if (open > 0) mask[i] = false;
  });
  const start = lines.findIndex((l, i) => mask[i] && /^##\s+术语速查\s*$/.test(l));
  if (start < 0) return null;
  let stop = lines.findIndex((l, i) => i > start && mask[i] && /^##\s+\S/.test(l));
  if (stop < 0) stop = lines.length;
  const out = new Map();
  for (let i = start + 1; i < stop; i++) {
    if (!mask[i] || !/^\s*\|/.test(lines[i])) continue;
    const c = cellsOf(lines[i]);
    if (isSep(c) || /^术语$/.test(c[0])) continue;
    const term = c[0], desc = c.slice(1).filter(Boolean).join('：');
    if (!term || !desc) continue;
    const k = term.toLowerCase().replace(/[\s_\/-]+/g, '');
    const prev = out.get(k);
    out.set(k, prev === undefined || (!PH.test(desc) && PH.test(prev)) ? { term, desc } : prev);
  }
  return out;
}

const manifest = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));
const files = [];
for (const c of manifest.categories) for (const l of c.lessons) files.push(path.basename(String(l.file)));

let bad = 0, checked = 0;
for (const f of files) {
  const p = 'assets/content/' + f;
  if (!fs.existsSync(p)) continue;
  let head;
  try { head = execFileSync('git', ['-c', 'core.safecrlf=false', 'show', `HEAD:${p}`], { encoding: 'utf8', maxBuffer: 64 << 20 }); }
  catch { continue; }
  if (head === fs.readFileSync(p, 'utf8')) continue;
  checked++;
  const a = gloss(head), b = gloss(fs.readFileSync(p, 'utf8'));
  if (!a || !b) { console.log(`  ${f} :: 小节缺失，无法比对`); bad++; continue; }
  const lost = [];
  for (const [k, v] of a) {
    if (PH.test(v.desc)) continue;
    const now = b.get(k);
    if (!now) lost.push(`${v.term}（整行消失）`);
    else if (PH.test(now.desc) || now.desc.length < v.desc.length * 0.5) lost.push(`${v.term}（解释被替换/截短）`);
  }
  if (lost.length) { console.log(`  ${f} :: 丢 ${lost.length} 条真解释 -> ${lost.slice(0, 6).join(' | ')}`); bad++; }
}
console.log(`比对 ${checked} 个已改动文件，问题 ${bad} 个`);
