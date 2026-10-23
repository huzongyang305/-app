// 打印“同一条解析里句首 24 字撞车”的两句话，判断是否真是重复。
// 用法：node tool/content_pipeline/show_prefix_dupes.js
import fs from 'node:fs';

const norm = (s) => String(s).replace(/[\s`*_]/g, '').replace(/[，。；：、！？"'“”‘’()（）\[\]]/g, '');
const m = JSON.parse(fs.readFileSync('assets/content/manifest.json', 'utf8'));
let n = 0;
for (const c of m.categories) {
  for (const l of c.lessons) {
    (l.quiz || []).forEach((q, i) => {
      const ex = q.explanation || '';
      const sentences = ex.split(/[。！？]/).map((x) => x.trim()).filter((x) => x.length > 12);
      const seen = new Map();
      for (const s of sentences) {
        const k = norm(s).slice(0, 24);
        if (seen.has(k)) {
          n++;
          console.log(`\n=== ${l.id} #${i}`);
          console.log('甲：' + seen.get(k).slice(0, 120));
          console.log('乙：' + s.slice(0, 120));
          break;
        }
        seen.set(k, s);
      }
    });
  }
}
console.log(`\n合计 ${n} 条`);
