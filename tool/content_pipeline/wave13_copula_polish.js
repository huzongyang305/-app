// 第 13 波：清理重建拼接出来的重复字与残缺标点。
// wave11/12 用模板拼接「正确做法是 + 原文」，原文本身以「是」开头就成了「是是」；
// 同类问题还有 的的/了了/在在 以及 到/在 后紧跟句读。只改解析，不动题干。
// 用法：node tool/content_pipeline/wave13_copula_polish.js [--apply]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const P = 'assets/content/manifest.json';
const eol = fs.readFileSync(P, 'utf8').includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(fs.readFileSync(P, 'utf8'));
const lessons = [];
for (const c of manifest.categories) for (const l of c.lessons) lessons.push(l);

const RULES = [
  [/是是/g, '是'],
  [/的的/g, '的'],
  [/了了/g, '了'],
  [/在在/g, '在'],
  [/与与/g, '与'],
  [/和和/g, '和'],
  [/要要/g, '要'],
  [/是：/g, '是'],
  [/，+/g, '，'],
  [/。，/g, '。'],
  [/（）/g, ''],
];

let touched = 0;
for (const l of lessons) {
  for (const q of l.quiz || []) {
    const ex = q.explanation || '';
    let next = ex;
    for (const [re, to] of RULES) next = next.replace(re, to);
    if (next !== ex) {
      touched++;
      if (APPLY) q.explanation = next;
    }
  }
}
console.log(`解析重复字与残缺标点清理：${touched} 条`);
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
