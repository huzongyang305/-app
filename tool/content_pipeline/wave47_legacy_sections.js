#!/usr/bin/env node
/**
 * 波次 47：收掉 retrofit 留下的重复小节。
 *
 * 背景：retrofit.js 只在课文里「没有规范小节标题」时才补写规范小节，于是带着旧标题
 * （## 代码示例、## 复杂度与性能分析）的课文被追加了一整份只有套话的规范小节，
 * 一篇课文里出现两个讲同一件事的章节；backend 那 4 篇还同时留着旧章节骨架
 * （## 本章摘要 + ## 自我测试，题目与题库不同源、答案口径冲突）。
 *
 * 做法：
 *   1. 旧标题改名为规范标题，把尾部规范小节里除套话以外的正文并进来，删掉尾部小节；
 *   2. 旧自测块和旧章节摘要整段删除（规范小节已在同篇里）；
 *   3. 只在能确认套话口径时才动笔，任何一条守卫不过就把该篇记为问题并跳过。
 *
 * 用法：node tool/content_pipeline/wave47_legacy_sections.js [--apply] [--show]
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..', 'assets', 'content');
const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');

// 旧标题 → 规范标题
const RENAMES = new Map([
  ['代码示例', '代码/协议/SQL 示例'],
  ['复杂度与性能分析', '时间/空间复杂度或性能分析'],
  ['复杂度或性能分析', '时间/空间复杂度或性能分析'],
]);

// retrofit 写进去的套话，整行命中就丢（标题前可能带《课名》前缀）
const GENERIC = [
  /^(?:《[^》]+》)?正文首个示例可作为最小验证起点（原样保留在上方章节）：先跑通，再改一个输入观察输出变化。$/,
  /^(?:《[^》]+》)?正文首个完整示例如下，先运行确认环境，再按正文步骤改一个输入观察输出变化。$/,
  /^- 在《.+》里处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。$/,
  /^- 用本课方案处理规模 n 时，先估计主循环与嵌套层数，再决定优化方向；小样本上的耗时读数不能外推。$/,
  /^- 性能结论要绑定输入分布：换数据规模、并发度或缓存命中情况后须重新测量。$/,
];

// 整段删除的旧小节：只有在同篇已有规范 counterpart 时才删
const DROPS = new Map([
  ['本章摘要', '本节知识框架'],
  ['自我测试', '自测题与参考答案'],
]);

const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'manifest.json'), 'utf8'));
const readDoc = (file) => {
  const raw = fs.readFileSync(file, 'utf8');
  // 这批课文整篇只有一种换行，插入/删除行以后按原样写回，别把整篇改成 CRLF 或 LF
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  return { rows: raw.split(/\r?\n/), eol };
};
const render = (doc) => doc.rows.join(doc.eol);

/** H2 小节切块；围栏里的 # 不算标题。 */
function slice(rows) {
  const spans = [];
  let fence = false;
  let start = null;
  rows.forEach((row, index) => {
    if (/^(```|~~~)/.test(row.trim())) fence = !fence;
    if (fence) return;
    if (/^##\s+\S/.test(row)) {
      if (start !== null) spans.push({ ...start, end: index });
      start = { title: row.replace(/^##\s+/, '').trim(), index };
    }
  });
  if (start !== null) spans.push({ ...start, end: rows.length });
  return spans;
}

const trimmedTail = (rows) => {
  const out = rows.slice();
  while (out.length && (out[out.length - 1].trim() === '' || out[out.length - 1].trim() === '---')) out.pop();
  return out;
};

// 拼接处容易出现两个连续空行，压成一个
const collapseBlanks = (rows) => rows.filter((row, index) => row.trim() !== '' || rows[index - 1]?.trim() !== '');

const problems = [];
const done = [];

for (const category of manifest.categories) {
  for (const lesson of category.lessons) {
    const file = path.join(__dirname, '..', '..', lesson.file);
    if (!fs.existsSync(file)) {
      problems.push(`${lesson.id}：${lesson.file} 不存在`);
      continue;
    }
    const doc = readDoc(file);
    let spans = slice(doc.rows);
    const titles = spans.map((s) => s.title);
    const ops = [];

    for (const [legacy, canonical] of RENAMES) {
      if (!titles.includes(legacy)) continue;
      if (titles.includes(canonical)) {
        // 两个都在：只有尾部规范小节全是套话+可辨识正文时才合并
        const legacySpan = spans.find((s) => s.title === legacy);
        const canonSpan = spans.find((s) => s.title === canonical);
        if (legacySpan.index > canonSpan.index) {
          problems.push(`${lesson.id}：${legacy} 在规范小节之后，位置不处理`);
          continue;
        }
        const body = doc.rows.slice(canonSpan.index + 1, canonSpan.end);
        const kept = [];
        let sawFence = false;
        for (const row of body) {
          const t = row.trim();
          if (t === '' || t === '---') continue;
          if (/^(```|~~~)/.test(t)) sawFence = true;
          if (GENERIC.some((re) => re.test(t))) continue;
          if (/^-\s/.test(t) && t.length < 70 && !sawFence && /处理规模|重新测量|不能外推/.test(t)) continue;
          kept.push(row);
        }
        ops.push({ kind: 'merge', legacy, canonical, canonSpan, kept });
      } else {
        ops.push({ kind: 'rename', legacy, canonical });
      }
    }

    for (const [legacy, canonical] of DROPS) {
      if (!titles.includes(legacy)) continue;
      if (!titles.includes(canonical)) {
        problems.push(`${lesson.id}：要删 ${legacy} 但同篇没有 ${canonical}`);
        continue;
      }
      if (legacy === '自我测试') {
        const body = doc.rows
          .slice(spans.find((s) => s.title === legacy).index + 1, spans.find((s) => s.title === legacy).end)
          .join('\n');
        const letters = [...body.matchAll(/\*\*正确答案：([A-F])/g)].length;
        if (letters === 0) {
          problems.push(`${lesson.id}：自我测试里没有答案行，先人工看`);
          continue;
        }
      }
      ops.push({ kind: 'drop', legacy });
    }

    if (!ops.length) continue;

    // 从后往前改，行号不会漂
    const edits = [];
    for (const op of ops) {
      if (op.kind === 'rename') {
        const span = spans.find((s) => s.title === op.legacy);
        edits.push({ from: span.index, to: span.index + 1, rows: [`## ${op.canonical}`] });
      } else if (op.kind === 'drop') {
        const span = spans.find((s) => s.title === op.legacy);
        edits.push({ from: span.index, to: span.end, rows: [] });
      } else {
        const legacySpan = spans.find((s) => s.title === op.legacy);
        const head = doc.rows.slice(legacySpan.index + 1, legacySpan.end);
        // 这批课文用 --- 分隔小节，并进来以后还得留着一个
        const hadRule = head.filter((row) => row.trim() !== '').pop()?.trim() === '---';
        const merged = collapseBlanks([
          ...trimmedTail(head),
          ...(op.kept.length ? ['', ...op.kept] : []),
        ]);
        while (merged.length && merged[0].trim() === '') merged.shift();
        if (hadRule) merged.push('', '---');
        merged.push('');
        edits.push({ from: legacySpan.index, to: legacySpan.end, rows: [`## ${op.canonical}`, '', ...merged] });
        edits.push({ from: op.canonSpan.index, to: op.canonSpan.end, rows: [] });
      }
    }
    edits.sort((a, b) => b.from - a.from);
    for (const edit of edits) doc.rows.splice(edit.from, edit.to - edit.from, ...edit.rows);

    spans = slice(doc.rows);
    const after = spans.map((s) => s.title);
    const dupes = after.filter((t, i) => after.indexOf(t) !== i);
    if (dupes.length) problems.push(`${lesson.id}：改名后仍有重复小节 ${dupes.join('/')}`);
    for (const need of ['代码/协议/SQL 示例', '时间/空间复杂度或性能分析']) {
      if (titles.includes(need) && !after.includes(need)) problems.push(`${lesson.id}：${need} 弄丢了`);
    }
    const text = render(doc);
    if (text.length < 6000) problems.push(`${lesson.id}：删除后正文只剩 ${text.length} 字`);
    done.push({ lesson, doc, ops });
  }
}

if (SHOW || !APPLY) {
  for (const item of done) {
    console.log(
      `${item.lesson.id}  ${item.ops.map((o) => o.kind + ':' + (o.legacy || o.canonical)).join(', ')}`,
    );
  }
}

if (APPLY) {
  for (const item of done) {
    const file = path.join(__dirname, '..', '..', item.lesson.file);
    fs.writeFileSync(file, render(item.doc), 'utf8');
  }
}

console.log(
  `${APPLY ? '已落盘' : '试运行'}：课文 ${done.length - problems.length} 篇，问题 ${problems.length} 项`,
);
for (const p of problems) console.log('  问题：' + p);
if (problems.length && APPLY) process.exitCode = 1;
