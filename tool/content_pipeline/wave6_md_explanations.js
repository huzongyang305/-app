// 第六批：把 考点精讲 的判断依据与题库解析对齐。
// wave3/wave5 清理的是 manifest 里的 explanation，正文 考点精讲 还留着
// 「这道题落在术语 X 上…」「这道题检验本课主问题…」这类生成句式，
// 学员在教程里读到的和答题后看到的解释是两套话。这里按题干精确匹配，把判断依据换成同一份解析。
// 用法：node tool/content_pipeline/wave6_md_explanations.js [--apply] [--list]
import fs from 'node:fs';
import path from 'node:path';

const APPLY = process.argv.includes('--apply');
const LIST = process.argv.includes('--list');
const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));

const norm = (s) => String(s).replace(/\s+/g, '').replace(/[*`_]/g, '');
const lines = (p) => {
  const raw = fs.readFileSync(p, 'utf8');
  return { arr: raw.split(/\r?\n/), eol: raw.includes('\r\n') ? '\r\n' : '\n' };
};

let filesTouched = 0, rowsReplaced = 0, unmatched = 0, bulletsFixed = 0, skippedShort = 0;
const samples = [];
for (const c of manifest.categories) for (const l of c.lessons) {
  const p = path.join(CONTENT_DIR, path.basename(String(l.file)));
  if (!fs.existsSync(p)) continue;
  const { arr, eol } = lines(p);
  const start = arr.findIndex((x) => /^##\s+考点精讲\s*$/.test(x));
  if (start < 0) continue;
  let stop = arr.findIndex((x, i) => i > start && /^##\s+\S/.test(x));
  if (stop < 0) stop = arr.length;

  const byStem = new Map();
  for (const q of l.quiz || []) byStem.set(norm(q.question), String(q.explanation || '').trim());

  let local = 0;
  for (let i = start + 1; i < stop; i++) {
    if (arr[i].startsWith('- - ')) { arr[i] = arr[i].replace(/^- - /, '- '); bulletsFixed++; }
    const m = /^(\s*-?\s*\*\*题目\*\*：)(.*)$/.exec(arr[i]);
    if (!m) continue;
    const ex = byStem.get(norm(m[2]));
    if (!ex) { unmatched++; continue; }
    // 找该题对应的 判断依据 行（可能在题目行之后第一或第二行）
    let j = -1;
    for (let k = i + 1; k < Math.min(i + 5, stop); k++) {
      if (/\*\*判断依据\*\*/.test(arr[k])) { j = k; break; }
      if (/\*\*题目\*\*/.test(arr[k])) break;
    }
    if (j < 0) continue;
    const old = arr[j];
    arr[j] = old.replace(/\*\*判断依据\*\*：[\s\S]*$/, `**判断依据**：${ex}`);
    if (arr[j] !== old) local++;
  }
  if (!local) continue;
  const text = arr.join(eol);
  if (text.replace(/\s/g, '').length < 6200) { skippedShort++; continue; }
  filesTouched++; rowsReplaced += local;
  if (samples.length < 3 && LIST) samples.push([path.basename(p), local]);
  if (APPLY) fs.writeFileSync(p, text);
}
console.log(`考点精讲判断依据对齐题库解析：${filesTouched} 个文件、${rowsReplaced} 行；题干未匹配 ${unmatched} 处，因正文过短跳过 ${skippedShort} 个文件，修复 - - 断行 ${bulletsFixed} 处`);
for (const [f, n] of samples) console.log(`  ${f} :: ${n} 行`);
console.log(APPLY ? '已写盘' : '（dry-run，加 --apply 才写盘）');
