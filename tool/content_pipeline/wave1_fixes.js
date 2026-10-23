// 复核后的确定性修复批：只处理无需再创作、可机械验证的缺陷。
//   1) related 指向不存在课程 id 的 5 条死链改写；
//   2) 术语速查/核心概念定义表格：表头声明 2 列但数据行 3 列，渲染时第 3 列
//      （生活类比）被丢弃 —— 把第 3 列并进第 2 列，信息不丢且满足测试的表头口径；
//   3) 45 个文件缺规范元信息行 —— 在文首补 `> 内容更新时间：… · 学习阶段：… · 预计用时：… 分钟`；
//   4) 删除未被任何课程引用的配图，回收 APK 体积。
// 用法：node tool/content_pipeline/wave1_fixes.js [--apply]
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.cwd();
const APPLY = process.argv.includes('--apply');
const CONTENT_DIR = 'assets/content';
const IMG_DIR = path.join(CONTENT_DIR, 'images');
const manifestPath = path.join(CONTENT_DIR, 'manifest.json');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push({ ...l, catId: c.id });
const ids = new Set(lessons.map((l) => l.id));

/* ---------- 1. related 死链 ---------- */
const RELATED_FIX = { python_list_dict_basics: 'python_data_structures', python_errors_files: 'python_errors_logging_files' };
let relatedFixed = 0;
// 直接改 manifest 里的课程对象：lessons 是展开副本，改副本不会写回。
for (const c of manifest.categories) for (const l of c.lessons) {
  if (!Array.isArray(l.related)) continue;
  const next = [];
  for (const r of l.related) {
    if (ids.has(r)) { if (r !== l.id && !next.includes(r)) next.push(r); continue; }
    const alt = RELATED_FIX[r];
    if (alt && ids.has(alt)) { if (alt !== l.id && !next.includes(alt)) next.push(alt); relatedFixed++; continue; }
    relatedFixed++;
  }
  l.related = next;
}
console.log(`related 死链清理：${relatedFixed} 条`);

/* ---------- 2. 表格第 3 列并入第 2 列 ---------- */
const TABLE_SECTIONS = ['术语速查', '核心概念定义'];
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
const tableSpans = (lines) => {
  const mask = fenceMask(lines);
  const spans = [];
  let start = -1;
  lines.forEach((line, i) => {
    const isRow = mask[i] && /^\s*\|.*\|\s*$/.test(line);
    if (isRow && start < 0) start = i;
    if (!isRow && start >= 0) { spans.push([start, i - 1]); start = -1; }
  });
  if (start >= 0) spans.push([start, lines.length - 1]);
  return spans;
};
const cellsOf = (line) => line.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((x) => x.trim());
const isSep = (cells) => cells.length > 0 && cells.every((c) => /^:?-{2,}:?$/.test(c));
// Windows 工作副本里正文是 CRLF：按原换行符读写，避免整文件重排。
const load = (p) => {
  const raw = fs.readFileSync(p, 'utf8');
  return { lines: raw.split(/\r?\n/), eol: raw.includes('\r\n') ? '\r\n' : '\n' };
};
let tablesFixed = 0, rowsMerged = 0;
const touchedFiles = new Set();
for (const l of lessons) {
  const base = path.basename(String(l.file));
  const p = path.join(CONTENT_DIR, base);
  if (!fs.existsSync(p)) continue;
  const { lines, eol } = load(p);
  const mask = fenceMask(lines);
  // 只处理规范小节内的表格，避免动到正文里的对照表。
  const wanted = new Set();
  for (const title of TABLE_SECTIONS) {
    let inSec = false, level = 0;
    lines.forEach((line, i) => {
      if (!mask[i]) return;
      const h = /^(#{1,6})\s+(.*)$/.exec(line);
      if (h) {
        if (h[2].trim() === title) { inSec = true; level = h[1].length; return; }
        if (inSec && h[1].length <= level) inSec = false;
        return;
      }
      if (inSec && /^\s*\|/.test(line)) wanted.add(i);
    });
  }
  let changed = 0;
  for (const [s, e] of tableSpans(lines)) {
    const rows = [];
    for (let i = s; i <= e; i++) if (wanted.has(i)) rows.push(i);
    if (rows.length < 2) continue;
    const header = cellsOf(lines[rows[0]]);
    if (header.length !== 2 || !/^术语$/.test(header[0])) continue;
    for (const i of rows) {
      const cells = cellsOf(lines[i]);
      if (cells.length <= 2) continue;
      if (isSep(cells)) { lines[i] = '| --- | --- |'; changed++; continue; }
      const merged = `${cells[1]}（${cells.slice(2).join('；')}）`;
      lines[i] = `| ${cells[0]} | ${merged.replace(/"/g, '"')} |`;
      changed++;
    }
  }
  if (changed) { tablesFixed++; rowsMerged += changed; touchedFiles.add(base); if (APPLY) fs.writeFileSync(p, lines.join(eol)); }
}
console.log(`表格列合并：${tablesFixed} 个文件，${rowsMerged} 行`);

/* ---------- 3. 规范元信息行 ---------- */
const sched = JSON.parse(fs.readFileSync('docs/content_review_schedule.json', 'utf8'));
const planned = new Map();
for (const b of sched.batches || []) for (const id of b.lesson_ids || []) planned.set(id, b.planned_review_at);
let metaAdded = 0, metaFixed = 0;
for (const l of lessons) {
  const base = path.basename(String(l.file));
  const p = path.join(CONTENT_DIR, base);
  if (!fs.existsSync(p)) continue;
  const { lines, eol } = load(p);
  const mask = fenceMask(lines);
  const idx = lines.findIndex((x, i) => mask[i] && /^>\s*内容更新时间：/.test(x));
  const bare = lines.findIndex((x, i) => mask[i] && /^>\s*学习阶段：\S+\s*·\s*预计用时：\d+\s*分钟\s*$/.test(x));
  const canonical = `> 内容更新时间：2026-10-06 · 学习阶段：${l.difficulty} · 预计用时：${l.minutes} 分钟`;
  if (idx >= 0) continue;
  if (bare >= 0) { lines[bare] = canonical; metaFixed++; }
  else {
    // 插到 H1（及其配图、原有友好头部块）之后
    let at = lines.findIndex((x) => /^#\s+/.test(x));
    if (at < 0) continue;
    at += 1;
    while (at < lines.length && (!lines[at].trim() || /^!\[/.test(lines[at].trim()) || /^>\s*\*?\*?(版本|难度|前置知识|预计)/.test(lines[at].trim()) || /^>\s*版本/.test(lines[at].trim()))) at++;
    // 若上面是 `> **版本**…` 块，整块后面插
    while (at > 0 && /^>\s/.test(lines[at - 1].trim()) === false && lines[at - 1].trim() !== '') break;
    lines.splice(at, 0, canonical, '');
    metaAdded++;
  }
  if (APPLY) fs.writeFileSync(p, lines.join(eol));
  touchedFiles.add(base);
}
console.log(`元信息行：改写 ${metaFixed} 个，补写 ${metaAdded} 个`);

/* ---------- 4. 配图：重挂 → 清替代文本 → 删孤儿 ---------- */
// 4a. 仅当「孤儿图文件名与课程 id 精确同名」且「该课现用图与本课零词元重叠」时
//     才重挂，避免用相似度猜测把主题本来正确的图换错。
const tokens = (s) => new Set(String(s).toLowerCase().split(/[^a-z0-9]+/).filter((x) => x.length > 2 && !['diagram', 'lesson', 'category', 'remaining', 'visual', 'p0x', 'webp', 'the', 'and'].includes(x)));
const referenced = new Set();
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  for (const m of fs.readFileSync(p, 'utf8').matchAll(/!\[[^\]]*\]\(([^)]+)\)/g)) referenced.add(path.basename(m[1].trim()));
}
// 测试与源码里直接写死的配图也算引用，删掉会让 widget 测试拿到空图。
const scanCode = (dir) => {
  if (!fs.existsSync(dir)) return;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === 'failures' || e.name === 'build') continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { scanCode(p); continue; }
    if (!/\.(dart|html|js|json|md)$/i.test(e.name)) continue;
    for (const m of fs.readFileSync(p, 'utf8').matchAll(/images\/([A-Za-z0-9_.-]+\.(?:webp|png|jpe?g|gif|svg))/g)) referenced.add(m[1]);
  }
};
scanCode('test');
scanCode('lib');
const orphans = fs.readdirSync(IMG_DIR).filter((f) => /\.(webp|png|jpe?g|gif|svg)$/i.test(f) && !referenced.has(f));
const orphanByLesson = new Map();
for (const f of orphans) {
  const stem = path.basename(f, path.extname(f)).replace(/^(remaining|lesson|diagram|category|visual|p0x)_/, '');
  const hit = lessons.find((l) => l.id === stem || path.basename(String(l.file), '.md') === stem);
  if (hit) orphanByLesson.set(hit.id, f);
}
let repointed = 0;
for (const l of lessons) {
  const cand = orphanByLesson.get(l.id);
  if (!cand) continue;
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  const { lines, eol } = load(p);
  const first = lines.findIndex((x) => /^!\[[^\]]*\]\([^)]+\.webp\)/i.test(x.trim()));
  if (first < 0) continue;
  const cur = path.basename(/!\[[^\]]*\]\(([^)]+)\)/.exec(lines[first].trim())[1]);
  const mine = new Set([...tokens(l.id), ...tokens(l.catId), ...tokens(path.basename(String(l.file), '.md'))]);
  const overlap = [...tokens(cur)].filter((x) => mine.has(x)).length;
  if (overlap > 0) continue; // 现图主题相符，保留
  lines[first] = `![${l.title.zh}](images/${cand})`;
  if (APPLY) fs.writeFileSync(p, lines.join(eol));
  orphans.splice(orphans.indexOf(cand), 1);
  repointed++;
  touchedFiles.add(path.basename(String(l.file)));
  console.log(`  重挂：${l.id} ← ${cand}（原 ${cur}）`);
}
// 4b. 替代文本泄漏批次代号：`![课题示意：english code]` 统一改为课题名。
let altFixed = 0;
for (const l of lessons) {
  const base = path.basename(String(l.file));
  const p = path.join(CONTENT_DIR, base);
  if (!fs.existsSync(p)) continue;
  const { lines, eol } = load(p);
  let changed = 0;
  for (let i = 0; i < lines.length; i++) {
    const m = /^(\s*!\[)([^\]]*)(\]\([^)]+\).*)$/.exec(lines[i]);
    if (!m) continue;
    const alt = m[2];
    if (!/[a-z]+[_ ][a-z]+/.test(alt)) continue;
    const cleaned = alt.replace(/示意[:：]\s*[A-Za-z0-9 _-]+$/, '').replace(/[A-Za-z0-9]+(?:[_ ][A-Za-z0-9]+){2,}/g, '').replace(/[:：\s]+$/, '').trim();
    const final = cleaned.length >= 4 ? cleaned : `${l.title.zh}示意图`;
    if (final !== alt) { lines[i] = `${m[1]}${final}${m[3]}`; changed++; }
  }
  if (changed) { altFixed++; if (APPLY) fs.writeFileSync(p, lines.join(eol)); touchedFiles.add(base); }
}
console.log(`配图重挂：${repointed} 张；替代文本清理：${altFixed} 个文件`);
// 4c. 剩余孤儿图删除（重复副本或已无课程使用）。
let bytesFreed = 0;
for (const f of orphans) {
  const st = fs.statSync(path.join(IMG_DIR, f));
  bytesFreed += st.size;
  if (APPLY) fs.unlinkSync(path.join(IMG_DIR, f));
}
console.log(`未引用配图删除：${orphans.length} 张，约 ${(bytesFreed / 1024 / 1024).toFixed(2)}MB`);
console.log(orphans.slice(0, 40).join('\n'));

if (APPLY) {
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  console.log('manifest 已写回');
} else console.log('（dry-run，加 --apply 才写盘）');
console.log(`涉及正文文件 ${touchedFiles.size} 个`);
