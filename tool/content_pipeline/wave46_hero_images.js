#!/usr/bin/env node
/**
 * 波次 46：把 42 篇课文的首图换成新生成的同主题配图。
 *
 * 背景：这批课文（前端框架、后端、ML、移动进阶、离散数学等）的配图是从别的课文
 * 复制来的，首屏那张图画的是完全不相干的东西。新图由
 *   node tool/generate_curriculum_diagrams.js --group=p9
 * 生成，规格在 tool/curriculum_diagrams/p9_*.js。
 *
 * 顺带：alt 统一成 H1 标题；替换后彻底没人引用的旧配图删掉（与 wave1 的口径一致，
 * deep_check 会把「未被引用的配图」当成缺陷统计）。
 *
 * 用法：node tool/content_pipeline/wave46_hero_images.js [--apply] [--show]
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..', 'assets', 'content');
const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');

const SPECS = Object.assign(
  {},
  require('../curriculum_diagrams/p9_frontend.js'),
  require('../curriculum_diagrams/p9_backend_ml.js'),
  require('../curriculum_diagrams/p9_mobile_math.js'),
);

const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'manifest.json'), 'utf8'));
const fileById = new Map();
for (const category of manifest.categories)
  for (const lesson of category.lessons) fileById.set(lesson.id, lesson.file);

const readDoc = (file) => {
  const raw = fs.readFileSync(file, 'utf8');
  const rows = raw.split('\n');
  return { raw, rows, crlf: rows.map((r) => r.endsWith('\r')) };
};
const render = (doc) => doc.rows.map((r, i) => (doc.crlf[i] ? r + '\r' : r)).join('\n');
const IMAGE = /!\[([^\]]*)\]\((?:images\/)?([^)\s]+)\)/;
// H1 与首图之间只允许空行、元信息引用行和小节标题，否则这张图不是首屏配图。
const BEFORE = (row) => row.trim() === '' || /^>\s/.test(row) || /^#{1,4}\s/.test(row);

const changes = [];
const problems = [];
const notes = [];

for (const [id, spec] of Object.entries(SPECS)) {
  const rel = fileById.get(id);
  if (!rel) { problems.push(`${id}：manifest 里没有这篇`); continue; }
  const file = path.join(__dirname, '..', '..', rel);
  if (!fs.existsSync(file)) { problems.push(`${id}：${rel} 不存在`); continue; }
  const target = `images/${spec.image}`;
  if (!fs.existsSync(path.join(ROOT, target))) { problems.push(`${id}：配图未生成 ${target}`); continue; }
  const doc = readDoc(file);
  const hits = [];
  doc.rows.forEach((row, i) => { const m = row.match(IMAGE); if (m) hits.push({ i, m }); });
  if (hits.length === 0) { problems.push(`${id}：正文里没有图片`); continue; }
  const [first] = hits;
  if (!/^#\s/.test(doc.rows[0])) { problems.push(`${id}：首行不是 H1 标题`); continue; }
  if (first.i > 20) { problems.push(`${id}：首图在第 ${first.i + 1} 行，太靠后`); continue; }
  for (const row of doc.rows.slice(1, first.i))
    if (!BEFORE(row)) { problems.push(`${id}：首图前第 ${first.i + 1} 行有意外的正文`); break; }
  const oldImg = first.m[2];
  if (oldImg === spec.image) continue;
  const title = doc.rows[0].replace(/^#\s+/, '').trim();
  if (first.m[1].trim() !== title) notes.push(`${id}：alt「${first.m[1]}」改成 H1`);
  doc.rows[first.i] = `![${title}](${target})`;
  if (!doc.rows[first.i].includes(target)) { problems.push(`${id}：替换后找不到新图`); continue; }
  changes.push({ id, rel, file, doc, oldImg, newImg: spec.image, line: first.i });
}

// 替换后彻底没人引用的旧图
const referenced = new Set();
for (const f of fs.readdirSync(ROOT).filter((x) => x.endsWith('.md'))) {
  const hit = changes.find((c) => path.basename(c.rel) === f);
  const text = hit ? render(hit.doc) : fs.readFileSync(path.join(ROOT, f), 'utf8');
  for (const m of text.matchAll(/!\[[^\]]*\]\((?:images\/)?([^)\s]+)\)/g)) referenced.add(m[1]);
}
const orphaned = [...new Set(changes.map((c) => c.oldImg))].filter((img) => !referenced.has(img));
const orphanBytes = orphaned.reduce((sum, img) => sum + fs.statSync(path.join(ROOT, 'images', img)).size, 0);

console.log(`待改配图 ${changes.length} 篇`);
for (const n of notes) console.log('  ' + n);
if (orphaned.length)
  console.log(`替换后没人引用的旧图 ${orphaned.length} 张，约 ${(orphanBytes / 1024).toFixed(0)}KB：${orphaned.join(', ')}`);
if (problems.length) { console.log(`\n问题 ${problems.length}：`); for (const p of problems) console.log('  ' + p); }
if (SHOW) for (const c of changes) console.log(`  ${c.id} L${c.line + 1}: ${c.oldImg} -> ${c.newImg}`);

if (problems.length) { console.log('\n有问题，未落盘。'); process.exitCode = 1; }
else if (!APPLY) console.log('\n试运行：加 --apply 落盘。');
else {
  for (const c of changes) fs.writeFileSync(c.file, render(c.doc));
  for (const img of orphaned) fs.unlinkSync(path.join(ROOT, 'images', img));
  console.log(`已落盘：课文 ${changes.length} 篇，删除未引用配图 ${orphaned.length} 张`);
}
