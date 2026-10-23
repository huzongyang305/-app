// 归类残留模板解析的句式，供重建波次覆盖全部形态。
// 用法：node tool/content_pipeline/classify_residue.js
import fs from 'node:fs';

const m = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));
const lessons = [];
for (const c of m.categories) for (const l of c.lessons) lessons.push(l);

const NEEDLES = ['正确答案是「', '该判断与术语', '解决了什么问题，而不是只背术语', '本题还要同时命中核心知识这条', '本题还要同时命中关键流程这条', '本题还要同时命中实战这条', '本题还要同时命中入门练习这条', '本题还要同时命中基础概念这条'];
const buckets = new Map();
const ids = new Map();
let total = 0;
for (const l of lessons) {
  (l.quiz || []).forEach((q, i) => {
    const ex = q.explanation || '';
    if (!NEEDLES.some((n) => ex.includes(n))) return;
    total++;
    const shape = ex.replace(/[\u4e00-\u9fa5A-Za-z0-9 `@#%&*/_+=.,、：:；;（）()<>'"“”-]{1,}/g, (s) => (s.length > 6 ? '█' : s)).slice(0, 90);
    const key = ex.slice(0, 6) + '|' + (ex.includes('正确答案是「') ? 'lead' : '') + (ex.includes('该判断与术语') ? 'term' : '') + (ex.includes('解决了什么问题') ? 'placeholder' : '') + (/(本题还要同时命中[^。]*这条。)/.test(ex) ? 'append' : '') + (((ex.match(/本题正确项是/g) || []).length) >= 2 ? 'trip' : '');
    buckets.set(key, (buckets.get(key) || 0) + 1);
    if (!ids.has(key)) ids.set(key, `${l.id}#${i}`);
  });
}
console.log(`命中 ${total} 条`);
const sorted = [...buckets].sort((a, b) => b[1] - a[1]);
for (const [k, n] of sorted) console.log(`${String(n).padStart(4)}  ${k}  例：${ids.get(k)}`);
