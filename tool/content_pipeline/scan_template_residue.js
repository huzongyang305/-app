// 扫描解析与正文里残留的模板片段，给重写波次定位靶子。
// 用法：node tool/content_pipeline/scan_template_residue.js
import fs from 'node:fs';
import path from 'node:path';

const m = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));
const lessons = [];
for (const c of m.categories) for (const l of c.lessons) lessons.push(l);

const PATTERNS = [
  '正确答案是「',
  '该判断与术语',
  '解决了什么问题，而不是只背术语',
  '错误表现方面，',
  '本题正确项是',
  '本题还要同时命中',
  '本题取',
  '正是踩了这条',
  '相关：正文给出可操作定义与适用边界',
];

const hits = new Map(PATTERNS.map((p) => [p, { ex: 0, md: 0 }]));
for (const l of lessons) {
  for (const q of l.quiz || []) {
    const ex = q.explanation || '';
    for (const p of PATTERNS) if (ex.includes(p)) hits.get(p).ex++;
  }
  const p = path.join('assets/content', path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const md = fs.readFileSync(p, 'utf8');
  for (const P of PATTERNS) if (md.includes(P)) hits.get(P).md++;
}
for (const [p, v] of hits) console.log(`${p.padEnd(24)} 解析 ${String(v.ex).padStart(4)} 条 / 正文 ${String(v.md).padStart(4)} 篇`);
