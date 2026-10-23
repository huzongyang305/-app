// 第三批：把 术语速查 里「多张表 / 三列表」重建成唯一一张两列表。
// 上一批把旧骨架的章节并进规范小节后，部分课程的 术语速查 里出现了第二张表，
// 列数与表头口径不一致（术语|英文|含义），渲染时表头与内容错位。
// 用法：node tool/content_pipeline/wave2b_glossary.js [--apply]
import fs from 'node:fs';
import path from 'node:path';

const APPLY = process.argv.includes('--apply');
const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

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
const load = (p) => {
  const raw = fs.readFileSync(p, 'utf8');
  return { lines: raw.split(/\r?\n/), eol: raw.includes('\r\n') ? '\r\n' : '\n' };
};
const cellsOf = (line) => line.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((x) => x.trim());
const isSep = (cells) => cells.length > 0 && cells.every((c) => /^:?-{2,}:?$/.test(c));
// 生成器留下的空话解释：同一术语若在别处有真解释，必须让位给真解释。
const PLACEHOLDER = /定位线索见正文小节|速查表只保留名称/;
const better = (a, b) => {
  if (a === undefined) return b;
  const score = (x) => (PLACEHOLDER.test(x) ? -100000 : x.length);
  return score(b) > score(a) ? b : a;
};

let rebuilt = 0, rowTotal = 0, rescued = 0, keptPlaceholder = 0;
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const { lines, eol } = load(p);
  const mask = fenceMask(lines);
  const heads = [];
  lines.forEach((line, i) => { if (mask[i] && /^##\s+术语速查\s*$/.test(line)) heads.push(i); });
  if (!heads.length) continue;
  const start = heads[0];
  const end = lines.findIndex((line, i) => i > start && mask[i] && /^##\s+\S/.test(line));
  const stop = end < 0 ? lines.length : end;

  const rows = new Map();
  const stray = [];
  for (let i = start + 1; i < stop; i++) {
    const line = lines[i];
    if (!mask[i] || !/^\s*\|/.test(line)) { if (line.trim() && !/^\s*[|>-]/.test(line)) stray.push(i); continue; }
    const cells = cellsOf(line);
    if (isSep(cells) || /^术语$/.test(cells[0])) continue;
    const term = cells[0];
    const desc = cells.slice(1).filter(Boolean).join('：');
    if (!term || !desc) continue;
    const key = term.toLowerCase().replace(/[\s_\/-]+/g, '');
    const prev = rows.get(key);
    if (prev === undefined) rows.set(key, { term, desc });
    else {
      const best = better(prev.desc, desc);
      if (best !== prev.desc) rescued++;
      rows.set(key, { term: prev.term, desc: best });
    }
  }
  if (!rows.size) continue;
  // 只重建确实不合口径的小节：出现非两列行、多个表头或多余分隔行。
  let badCells = 0, headers = 0, seps = 0;
  for (let i = start + 1; i < stop; i++) {
    if (!mask[i] || !/^\s*\|/.test(lines[i])) continue;
    const cells = cellsOf(lines[i]);
    if (cells.length !== 2) badCells++;
    if (/^术语/.test(cells[0])) headers++;
    if (isSep(cells)) seps++;
  }
  if (!badCells && headers <= 1 && seps <= 1) continue;
  if (rows.size < 6) continue; // 测试要求速查表至少 6 行，重建后不能掉到线下

  const rebuiltLines = [
    ...stray.map((i) => lines[i]),
    '',
    '| 术语 | 一句话说明 |',
    '| --- | --- |',
    ...[...rows.values()].map(({ term, desc }) => `| ${term} | ${desc} |`),
    '',
  ];
  const next = [...lines.slice(0, start + 1), ...rebuiltLines, ...lines.slice(stop)];
  if (next.join('').length < lines.join('').length * 0.6) continue; // 明显丢内容就不动
  rebuilt++; rowTotal += rows.size;
  keptPlaceholder += [...rows.values()].filter((r) => PLACEHOLDER.test(r.desc)).length;
  if (APPLY) fs.writeFileSync(p, next.join(eol));
}

console.log(`术语速查重建为单张两列表：${rebuilt} 个文件，共 ${rowTotal} 行`);
console.log(`同名术语取真解释 ${rescued} 处，仍是占位解释 ${keptPlaceholder} 行`);
console.log(APPLY ? '已写盘' : '（dry-run，加 --apply 才写盘）');
