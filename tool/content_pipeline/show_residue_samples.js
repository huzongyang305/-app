// 打印残留模板类的样本，供重写波次定形。
// 用法：node tool/content_pipeline/show_residue_samples.js [模式关键词] [数量]
import fs from 'node:fs';

const needle = process.argv[2] || '正确答案是「';
const limit = Number(process.argv[3] || 3);
const m = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));
const lessons = [];
for (const c of m.categories) for (const l of c.lessons) lessons.push(l);

let shown = 0;
for (const l of lessons) {
  for (let i = 0; i < (l.quiz || []).length && shown < limit; i++) {
    const q = l.quiz[i];
    const ex = q.explanation || '';
    if (!ex.includes(needle)) continue;
    shown++;
    console.log(`\n=== ${l.id} #${i} [${q.type}] 题干：${String(q.question || '').slice(0, 60)}`);
    console.log(ex);
  }
}
