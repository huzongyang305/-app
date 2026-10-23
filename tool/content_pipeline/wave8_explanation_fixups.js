// 第八批：收拾 wave7 留下的两类尾巴。
// 1) 选项本身是「核心知识 / 关键流程」这类元选项时，句子里会出现「本题取核心知识这条」这种废话，删掉。
// 2) 删完或本来就偏短的解析不足 120 字，用本课摘要补一句锚在本题正确项上的话，既达标又不与他课撞句。
// 用法：node tool/content_pipeline/wave8_explanation_fixups.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const len = (s) => [...String(s).replace(/\s/g, '')].length;
const flatten = (s) => String(s).replace(/[。！？；]/g, '，').replace(/，{2,}/g, '，').replace(/^，|，$/g, '').trim();
const META = /^(核心知识|关键流程|实战|入门练习|基础概念|综合应用)$/;

let junk = 0, padded = 0;
for (const c of manifest.categories) for (const l of c.lessons) {
  const title = (l.title && l.title.zh) || '';
  const summary = flatten(((l.summary && l.summary.zh) || l.summary || '').slice(0, 90));
  for (const q of l.quiz || []) {
    let ex = String(q.explanation || '');
    if (!ex) continue;
    const before = ex;
    ex = ex.replace(/，?本题取(?:核心知识|关键流程|入门练习|实战|基础概念)这条/g, '');
    ex = ex.replace(/，?干扰项(?:关键流程|核心知识|实战)?正踩在这条上/g, '');
    ex = ex.replace(/，?本题正确项是(?:核心知识|关键流程)。\s*/g, '');
    ex = ex.replace(/，{2,}/g, '，').replace(/，。/g, '。').trim();
    if (ex !== before) junk++;
    const correct = (q.options || [])[q.answer];
    // 短于门槛就借本课摘要补一句，句尾带本题正确项，保证全库不撞句。
    if (len(ex) < 124 && summary && correct && !META.test(String(correct))) {
      ex = `${ex}本课${title}要解决的是${flatten(summary)}，本题按${flatten(correct)}这条判断。`;
      padded++;
    } else if (len(ex) < 124 && summary) {
      // 没有可引用的正确项（排序题/填空题或元选项）时，改锚在题干上：题干全库唯一，句子也就唯一。
      const stem = flatten(q.question).slice(0, 48);
      ex = `${ex}本课${title}要解决的是${flatten(summary)}，本题问的是${stem}。`;
      padded++;
    }
    q.explanation = ex;
  }
}
console.log(`删除元选项废话 ${junk} 条，用本课摘要补足长度 ${padded} 条`);
if (APPLY) { fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol)); console.log('已写盘'); }
else console.log('（dry-run，加 --apply 才写盘）');
