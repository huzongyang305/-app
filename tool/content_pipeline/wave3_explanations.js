// 第四批：清理题库解析里的生成脚手架。
// 早期批量生成的解析统一是这个句式：
//   在 `课名` 第 N 题中，正确答案是「X」。在「课名」第 N 题中，该判断与术语 `T` 对应：…。
//   在「课名」第 N 题中，错误表现方面，…，应按…修复。
// App 里解析就在题目下方，「在第 N 题中」这种自我指涉只会造成噪声。
// 本脚本只删脚手架、合并重复句，不改任何事实内容；改完必须仍然复述正确选项。
// 用法：node tool/content_pipeline/wave3_explanations.js [--apply] [--list]
import fs from 'node:fs';
import path from 'node:path';

const APPLY = process.argv.includes('--apply');
const LIST = process.argv.includes('--list');
const CONTENT_DIR = 'assets/content';
const MANIFEST = path.join(CONTENT_DIR, 'manifest.json');
const raw = fs.readFileSync(MANIFEST, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const norm = (s) => String(s).replace(/[\s`*_]/g, '').replace(/[，。；：、！？"'“”‘’()（）\[\]]/g, '');

// 「在 `X` 第 3 题中，」/「在「X」第 3 题中，」/「在『X』第 3 题中，」——整段删掉，后面句子本身就是完整陈述。
const SCAFFOLD = /在\s*[`「『][^`」』]{1,60}[`」』]\s*第\s*\d+\s*题\s*中\s*[，,、]?\s*/g;
const SCAFFOLD_TEST = /在\s*[`「『][^`」』]{1,60}[`」』]\s*第\s*\d+\s*题\s*中/;
// 同一句被拼接两遍时只留第一遍。
function dedupeSentences(parts) {
  const seen = new Set();
  const out = [];
  for (const p of parts) {
    const k = norm(p).slice(0, 30);
    if (k.length < 8 || seen.has(k)) continue;
    seen.add(k);
    out.push(p);
  }
  return out.join('');
}
function polish(text) {
  let t = text.replace(SCAFFOLD, '');
  t = t.replace(/[，,]\s*([。！？])/g, '$1');      // 悬空逗号
  t = t.replace(/^\s*[。！？，,；;]\s*/, '');       // 句首残留标点
  t = t.replace(/\s{2,}/g, ' ');
  t = dedupeSentences(t.split(/(?<=[。！？])/).map((x) => x.trim()).filter(Boolean));
  t = t.trim();
  if (t && !/[。！？]$/.test(t)) t += '。';
  return t;
}

let touched = 0, samples = [], lostAnswer = 0, emptied = 0, lessonsHit = 0;
for (const c of manifest.categories) for (const l of c.lessons) {
  let hitHere = 0;
  for (const q of l.quiz || []) {
    const old = String(q.explanation || '');
    if (!SCAFFOLD_TEST.test(old)) continue; // 只动带自我指涉脚手架的解析，手写解析一律不碰
    const opts = q.options || [];
    const correct = opts[q.answer];
    const next = polish(old);
    if (!next) { emptied++; continue; }
    // 安全阀：原解析复述了正确选项，改完必须仍然复述；否则放弃这一条。
    if (correct && opts.length > 1 && norm(old).includes(norm(correct)) && !norm(next).includes(norm(correct))) {
      lostAnswer++;
      continue;
    }
    if (next === old) continue;
    touched++; hitHere++;
    if (samples.length < 6 && LIST) samples.push([l.id, old, next]);
    if (APPLY) q.explanation = next;
  }
  if (hitHere) lessonsHit++;
}

console.log(`解析去脚手架：改写 ${touched} 条，涉及 ${lessonsHit} 门课；跳过（会丢正确项）${lostAnswer} 条，跳过（清空）${emptied} 条`);
for (const [id, a, b] of samples) {
  console.log(`\n--- ${id}\n旧：${a}\n新：${b}`);
}
if (APPLY) {
  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('\n已写盘 manifest.json');
} else console.log('\n（dry-run，加 --apply 才写盘）');
