// 题库解析质量盘点：
// A 解析里没有复述正确选项（governance 的同款口径）
// B 解析里有「在某课 第 N 题中」这类内部题号/跨课引用（生成模板痕迹）
// C 解析里同一句话重复出现（模板拼接产物）
// D 题干过短或选项长度严重失衡（答案泄露）
import fs from 'node:fs';
import path from 'node:path';

const CONTENT_DIR = 'assets/content';
const manifest = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, 'manifest.json'), 'utf8'));
const norm = (s) => String(s).replace(/[\s`*_]/g, '').replace(/[，。；：、！？"'“”‘’()（）\[\]]/g, '');

const stats = { total: 0, noAnswer: 0, internalRef: 0, repeated: 0, shortStem: 0, leak: 0 };
const examples = { internalRef: [], repeated: [], shortStem: [], leak: [] };
const perLesson = [];

for (const c of manifest.categories) for (const l of c.lessons) {
  const quiz = l.quiz || [];
  let hit = 0;
  for (const q of quiz) {
    if (q.type && q.type !== 'single') continue;
    const opts = q.options || [];
    const ans = opts[q.answer];
    if (!ans) continue;
    stats.total++;
    const ex = String(q.explanation || '');
    const row = [];
    if (!norm(ex).includes(norm(ans))) { stats.noAnswer++; row.push('A'); }
    if (/第\s*\d+\s*题/.test(ex) || /在\s*`[^`]+`\s*第/.test(ex)) {
      stats.internalRef++; row.push('B');
      if (examples.internalRef.length < 5) examples.internalRef.push(`${l.id}: ${ex.slice(0, 90)}`);
    }
    const sentences = ex.split(/[。！？]/).map((x) => x.trim()).filter((x) => x.length > 12);
    const seen = new Set(); let dup = false;
    for (const s of sentences) { const k = norm(s).slice(0, 24); if (seen.has(k)) { dup = true; break; } seen.add(k); }
    if (dup) { stats.repeated++; row.push('C'); if (examples.repeated.length < 5) examples.repeated.push(`${l.id}: ${ex.slice(0, 90)}`); }
    if (String(q.question).replace(/\s/g, '').length < 12) {
      stats.shortStem++; row.push('D');
      if (examples.shortStem.length < 8) examples.shortStem.push(`${l.id}: ${q.question}`);
    }
    const lens = opts.map((o) => String(o).replace(/\s/g, '').length);
    const max = Math.max(...lens);
    if (max > 0 && String(opts[q.answer]).replace(/\s/g, '').length === max && max >= 2 * Math.min(...lens) && max - Math.min(...lens) > 14) {
      stats.leak++; row.push('E');
      if (examples.leak.length < 5) examples.leak.push(`${l.id}: 正确项 ${max} 字 / 最短 ${Math.min(...lens)} 字`);
    }
    if (row.length) hit++;
  }
  if (hit) perLesson.push({ id: l.id, file: path.basename(String(l.file)), hit });
}
console.log('单选类题目总数：', stats.total);
console.log('A 解析未复述正确项：', stats.noAnswer);
console.log('B 解析含内部题号或跨课引用：', stats.internalRef);
console.log('C 解析有重复句：', stats.repeated);
console.log('D 题干过短（<12 字）：', stats.shortStem);
console.log('E 正确项显著最长（可能泄露答案）：', stats.leak);
console.log('受影响课程：', perLesson.length);
perLesson.sort((a, b) => b.hit - a.hit);
console.log('题害最多的课程：', perLesson.slice(0, 12).map((x) => `${x.id}(${x.hit})`).join(' '));
for (const k of ['internalRef', 'repeated', 'shortStem', 'leak']) {
  if (examples[k].length) console.log(`\n[${k}]\n  ` + examples[k].join('\n  '));
}
