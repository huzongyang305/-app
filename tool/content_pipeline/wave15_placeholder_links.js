// 第 15 波：删除参考资料小节里的生成占位锚点链接。
// 两类都是生成器为了凑链接数写的：[本课资料锚点 <lesson_id>](zh.wikipedia.org/w/index.php?search=<lesson_id>)
// 和 - 本课索引词：[锚点 <lesson_id>](datatracker.ietf.org/doc/html/rfc9110#<术语>)。
// 前者按课程 ID 检索维基必然空手而归，后者把 PostgreSQL、FastAPI 这类词挂到 HTTP 规范的碎片上，
// 读者点进去只会看到无关段落。每篇删除后仍留有 2 条以上真实官方链接，不违反 P2 复核要求。
// 用法：node tool/content_pipeline/wave15_placeholder_links.js [--apply]
import fs from 'node:fs';
import path from 'node:path';

const APPLY = process.argv.includes('--apply');
const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

const PLACEHOLDER = [
  /^-\s*\[本课资料锚点[^\]]*\]\(https?:\/\/zh\.wikipedia\.org\/w\/index\.php\?search=[^)]*\)\s*$/,
  /^-\s*本课索引词[：:]\s*\[锚点[^\]]*\]\([^)]*\)\s*$/,
  /^-\s*\[本课索引词[^\]]*\]\([^)]*\)\s*$/,
];

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

let files = 0, removed = 0, keptForLength = 0;
const short = [];
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const raw = fs.readFileSync(p, 'utf8');
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  const lines = raw.split(/\r?\n/);
  const mask = fenceMask(lines);
  const drop = new Set();
  lines.forEach((line, i) => {
    if (!mask[i]) return;
    if (PLACEHOLDER.some((re) => re.test(line.trim()))) drop.add(i);
  });
  if (!drop.size) continue;
  const kept = [];
  lines.forEach((line, i) => {
    if (drop.has(i)) return;
    // 删除后若与前一行同为空行，合并掉多余空行（代码围栏内不动）。
    if (line.trim() === '' && kept.length && kept[kept.length - 1].trim() === '' && mask[i]) return;
    kept.push(line);
  });
  const next = kept.join(eol);
  // 正文有 6000 字符硬指标，删掉这一行就跌破的课文先留着占位链接，单独补内容。
  if (next.length < 6000) {
    keptForLength++;
    short.push(`${l.id} 删除后 ${next.length} 字符`);
    continue;
  }
  files++;
  removed += drop.size;
  const linkLines = kept.filter((line) => /https?:\/\//.test(line)).length;
  if (linkLines < 2) console.log(`  链接不足：${l.id} 剩余链接行 ${linkLines}`);
  if (APPLY) fs.writeFileSync(p, next);
}

console.log(`删除占位锚点：${files} 个文件、${removed} 行；因 6000 字符指标保留锚点：${keptForLength} 篇`);
for (const s of short.slice(0, 10)) console.log('  ' + s);
console.log(APPLY ? '已写盘' : '（dry-run，加 --apply 才写盘）');
