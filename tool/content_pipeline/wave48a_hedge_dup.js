// 波次 48a：删掉「只在「D」这一前提下成立，换输入或换环境要重新验证。」这类
// 定义复读套话。只处理 D 在同一行/同一考点块里已经逐字出现过的情况——
// 删掉的是复读，不是信息。表格单元格里的套话要写真内容，留给后续波次。
const fs = require('fs');
const path = require('path');

const dir = path.resolve(__dirname, '../../assets/content');
const apply = process.argv.includes('--apply');

const HEDGE = /只在「(.+?)」这一前提下成立，换输入或换环境要重新验证。/g;

const readDoc = (file) => {
  const raw = fs.readFileSync(file, 'utf8');
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  return { rows: raw.split(/\r?\n/), eol };
};

// 判断「是不是把同一句定义又抄了一遍」时忽略标点与空白差异：
// 生成器偶尔在括号里多带一个顿号，不应因此留下套话。
const key = (text) => text.replace(/[\s。．，,、；;：:！!？?“”"']/g, '');
const repeats = (haystack, needle) =>
  needle.length > 4 && key(haystack).includes(key(needle));

let files = 0;
const stat = { tail: 0, answer: 0, boundary: 0 };
const skip = { tail: 0, boundary: 0 };
let cellHits = 0;
const preview = [];
const note = (shape, from, to) => {
  if (preview.filter((p) => p.shape === shape).length >= 2) return;
  preview.push({ shape, from, to });
};

for (const name of fs.readdirSync(dir).filter((f) => f.endsWith('.md'))) {
  const file = path.join(dir, name);
  const doc = readDoc(file);
  let touched = false;

  for (let i = 0; i < doc.rows.length; i++) {
    const row = doc.rows[i];
    if (!row.includes('这一前提下成立')) continue;
    HEDGE.lastIndex = 0;
    const marks = [];
    let m;
    while ((m = HEDGE.exec(row)) !== null) marks.push({ d: m[1], at: m.index, len: m[0].length });
    if (!marks.length) continue;

    // 表格行里的套话格：需要人工补写，只统计不动。
    if (/^\s*\|/.test(row)) {
      cellHits += marks.length;
      continue;
    }

    let next = row;
    const isAnswer = /^\s*\*\*参考答案\*\*：/.test(row);
    for (const mark of marks.reverse()) {
      const before = next.slice(0, mark.at);
      const after = next.slice(mark.at + mark.len);
      if (isAnswer && repeats(after, mark.d)) {
        // 参考答案：定义随后还会再出现一次，去掉开头的套话并接住后半句。
        const tail = after.replace(/^\s+/, '').replace(/^同时要把/, '要把');
        next = before + tail;
        stat.answer++;
        note('参考答案', row, next);
        continue;
      }
      if (repeats(before, mark.d)) {
        // 行内已给出定义：把「；只在…」整段去掉，句号补回行尾。
        const merged = (before.replace(/；$/, '') + after.replace(/^\s+/, '')).replace(/\s+$/, '');
        next = /[。！？：;；,，]$/.test(merged) ? merged : `${merged}。`;
        stat.tail++;
        note('行内复读', row, next);
        continue;
      }
      if (/^(\s*-\s+\*\*[^*]*的边界\*\*：)$/.test(before)) {
        // 整行都是套话的考点边界行，交给第二遍按「要点」比对后再删。
        continue;
      }
      skip.tail++;
    }
    if (next !== row) {
      doc.rows[i] = next;
      touched = true;
    }
  }

  // 考点块：上一行「- **要点**：D」已逐字给出定义时，删掉整行边界复读。
  for (let i = doc.rows.length - 1; i > 0; i--) {
    const row = doc.rows[i];
    const hedge = /^\s*-\s+\*\*.*的边界\*\*：只在「(.+?)」这一前提下成立，换输入或换环境要重新验证。\s*$/.exec(
      row,
    );
    if (!hedge) continue;
    const keyPoint = doc.rows[i - 1];
    if (!/^\s*-\s+\*\*要点\*\*：/.test(keyPoint)) {
      skip.boundary++;
      continue;
    }
    if (!repeats(keyPoint, hedge[1])) {
      skip.boundary++;
      continue;
    }
    doc.rows.splice(i, 1);
    stat.boundary++;
    note('考点边界', row, '(整行删除，上一行要点已含该定义)');
    touched = true;
  }

  if (touched && apply) fs.writeFileSync(file, doc.rows.join(doc.eol), 'utf8');
  if (touched) files++;
}

console.log(`${apply ? '已落盘' : '试运行'}：套话删除 行内复读 ${stat.tail}、参考答案 ${stat.answer}、考点边界 ${stat.boundary}`);
console.log(`跳过（需要写真内容，留给后续）：表格单元格 ${cellHits}、无同行定义的 ${skip.tail}、边界缺要点的 ${skip.boundary}`);
console.log(`涉及课文 ${files} 篇`);
for (const p of preview) {
  console.log(`\n[${p.shape}]\n  改前 ${p.from.trim().slice(0, 170)}\n  改后 ${String(p.to).trim().slice(0, 170)}`);
}
