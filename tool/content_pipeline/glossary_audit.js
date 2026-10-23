// 统计术语速查占位解释的分布：占位行有多少、是否位于 术语速查 小节内、
// 同一文件里是否还存在另一张可复用的真实术语表。
import fs from 'node:fs';
import path from 'node:path';

const PH = '定位线索见正文小节';
const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));

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
const cellsOf = (line) => line.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((x) => x.trim());
const isSep = (cells) => cells.length > 0 && cells.every((c) => /^:?-{2,}:?$/.test(c));

const rows = [];
for (const c of manifest.categories) for (const l of c.lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const { lines } = { lines: fs.readFileSync(p, 'utf8').split(/\r?\n/) };
  const mask = fenceMask(lines);
  let ph = 0, phInGloss = 0, otherGlossary = 0;
  let inGloss = false;
  lines.forEach((line, i) => {
    if (!mask[i]) return;
    if (/^##\s+术语速查\s*$/.test(line)) inGloss = true;
    else if (/^##\s+\S/.test(line)) inGloss = false;
    if (line.includes(PH)) { ph++; if (inGloss) phInGloss++; }
    if (/^\s*\|/.test(line)) {
      const cs = cellsOf(line);
      if (!isSep(cs) && !/^术语$/.test(cs[0]) && cs.length >= 2 && !line.includes(PH) && cs[1].length > 6) otherGlossary++;
    }
  });
  if (ph) rows.push({ file: path.basename(p), ph, phInGloss, otherGlossary });
}
rows.sort((a, b) => b.ph - a.ph);
console.log(`占位文件 ${rows.length} 个，占位行 ${rows.reduce((a, r) => a + r.ph, 0)} 条，其中位于 术语速查 小节 ${rows.reduce((a, r) => a + r.phInGloss, 0)} 条`);
console.log('有其它真实表格可借用的文件：', rows.filter((r) => r.otherGlossary >= 4).length);
console.log('完全没有可借用内容的文件：', rows.filter((r) => r.otherGlossary < 4).length);
for (const r of rows.slice(0, 12)) console.log(`  ${r.file} :: 占位 ${r.ph} / 速查内 ${r.phInGloss} / 其它表格行 ${r.otherGlossary}`);
