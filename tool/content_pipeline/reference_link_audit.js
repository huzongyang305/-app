// 统计 参考资料与复核 里的占位锚点链接与删除后的真实链接数。
// 用法：node tool/content_pipeline/reference_link_audit.js
import fs from 'node:fs';
import path from 'node:path';

const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

const ANCHOR = /^-\s*\[本课(?:资料锚点|索引词)[^\]]*\]\((https?:\/\/[^)]+)\)/;
let withAnchor = 0, anchorTotal = 0, thin = 0, hosts = new Map();
const thinList = [];
const forms = new Map();
for (const l of lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const lines = fs.readFileSync(p, 'utf8').split(/\r?\n/);
  const anchors = [];
  lines.forEach((line, i) => {
    const m = ANCHOR.exec(line.trim());
    if (m) anchors.push({ i, url: m[1] });
  });
  if (!anchors.length) continue;
  withAnchor++;
  anchorTotal += anchors.length;
  for (const a of anchors) {
    const host = new URL(a.url).host;
    hosts.set(host, (hosts.get(host) || 0) + 1);
    const form = a.url.replace(/\/[^/]*$/, '/…').slice(0, 60);
    forms.set(form, (forms.get(form) || 0) + 1);
  }
  const real = lines.filter((line) => /https?:\/\//.test(line) && !ANCHOR.test(line.trim())).length;
  if (real < 2) { thin++; thinList.push(`${l.id} 真实链接行 ${real}`); }
}
console.log(`含占位锚点的课文 ${withAnchor} 篇，锚点合计 ${anchorTotal} 条`);
console.log(`删除锚点后真实链接行不足 2 的课文：${thin} 篇`);
for (const t of thinList.slice(0, 10)) console.log('  ' + t);
console.log('域名分布：', [...hosts].map(([h, n]) => `${h} ${n}`).join('，'));
console.log('链接形态：');
for (const [f, n] of [...forms].sort((a, b) => b[1] - a[1]).slice(0, 6)) console.log(`  ${n}× ${f}`);
