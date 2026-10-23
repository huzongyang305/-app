// 抽查：manifest 解析里是否仍有重复片段与占位追加句。
// 用法：node tool/content_pipeline/inspect_explanations.js
import fs from 'node:fs';

const m = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));
const lessons = [];
for (const c of m.categories) for (const l of c.lessons) lessons.push(l);

let dup = 0, meta = 0, samples = [];
for (const l of lessons) {
  (l.quiz || []).forEach((q, i) => {
    const ex = q.explanation || '';
    const c = (ex.match(/本题正确项是/g) || []).length;
    if (c >= 2) {
      dup++;
      if (samples.length < 4) samples.push([l.id, i, ex]);
    }
    if (/本题还要同时命中(核心知识|关键流程|入门练习|实战|基础概念)这条。/.test(ex)) meta++;
  });
}
console.log(`重复“本题正确项是”片段：${dup} 条；占位追加句：${meta} 条`);
for (const [id, i, ex] of samples) console.log(`\n--- ${id} #${i}\n${ex}`);
