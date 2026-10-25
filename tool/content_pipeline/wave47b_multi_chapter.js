#!/usr/bin/env node
/**
 * 波次 47b：把 7 篇「整章式」课文折回规范小节结构。
 *
 * 背景：backend 4 篇和 devops 3 篇是从讲义直接搬进来的，正文里留着 `## 7.1 …`、
 * `## 1. …` 这种章节号标题和一份 `## 目录`；retrofit 又在文末补了一整套规范小节，
 * 于是读者翻完二十多章才看到「本节知识框架」。
 *
 * 做法（整篇重新拼装，不做原地增删，小节边界不会算错）：
 *   1. 丢掉 `## 目录`、`## 本章摘要`、`## 自我测试`；
 *   2. `## 本节知识框架`、`## 核心概念定义` 和 retrofit 那份 `## 原理与运行机制`
 *      提到篇首，正文各章整块挂在它下面；
 *   3. 章节里所有标题整体下沉一级，并去掉章号——原来的 `## 7.1 认证 vs 授权` 变成
 *      `### 认证 vs 授权`，它名下的 `### 生活中的类比` 变成 `#### 生活中的类比`，
 *      这样只起分组作用的标题底下不会空着；
 *   4. 其余小节按原顺序接在后面。
 *
 * 守门：拼装前后逐行比对（忽略标题行、空行与 ---），内容少一行就不落盘。
 *
 * 用法：node tool/content_pipeline/wave47b_multi_chapter.js [--apply]
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..', 'assets', 'content');
const APPLY = process.argv.includes('--apply');

const CANON = [
  '本节知识框架',
  '核心概念定义',
  '原理与运行机制',
  '典型应用场景',
  '代码/协议/SQL 示例',
  '时间/空间复杂度或性能分析',
  '常见误区与易错点',
  '与其他知识点的关系',
  '自测题与参考答案',
  '考点精讲',
  '术语速查',
  '参考资料与复核',
  '内容元数据',
];

const CHAPTER = /^\d+(?:\.\d+)*[\.、]?\s+\S/;
const DROP = new Set(['目录', '本章摘要', '自我测试']);
const FRAME_BOILER = /正文各章按「输入是什么/;
const MOVED = ['本节知识框架', '核心概念定义', '原理与运行机制'];

const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'manifest.json'), 'utf8'));

const readDoc = (file) => {
  const raw = fs.readFileSync(file, 'utf8');
  return { rows: raw.split(/\r?\n/), eol: raw.includes('\r\n') ? '\r\n' : '\n' };
};

/** 按 H2 切段；围栏代码块里的 # 不算标题。 */
function slice(rows) {
  const spans = [];
  let fence = false;
  let start = null;
  rows.forEach((row, index) => {
    if (/^(```|~~~)/.test(row.trim())) fence = !fence;
    if (fence) return;
    if (/^##\s+\S/.test(row)) {
      if (start) spans.push({ ...start, end: index });
      start = { title: row.replace(/^##\s+/, '').trim(), index };
    }
  });
  if (start) spans.push({ ...start, end: rows.length });
  return spans;
}

const trimTail = (rows) => {
  const out = rows.slice();
  while (out.length && (out[out.length - 1].trim() === '' || out[out.length - 1].trim() === '---')) out.pop();
  return out;
};

/** 可比正文行：跳过标题、空行和分隔线，用来证明内容一行没丢。 */
const keyLines = (rows) =>
  rows
    .map((row) => row.trim())
    .filter((row) => row !== '' && row !== '---' && !/^#{1,6}\s/.test(row))
    .sort();

/** 一段小节，末尾统一补一个空行。 */
const blockOf = (rows, span) => [...trimTail(rows.slice(span.index, span.end)), ''];

/** 整段下沉一级标题并去掉章号。 */
function deepen(rows) {
  const out = [];
  let fence = false;
  rows.forEach((row, offset) => {
    if (/^(```|~~~)/.test(row.trim())) fence = !fence;
    if (!fence) {
      const heading = /^(#{1,5})\s+(.*)$/.exec(row);
      if (heading) {
        const level = Math.min(6, heading[1].length + 1);
        const title = heading[2].replace(/^\d+(?:\.\d+)*[\.、]?\s+/, '');
        // 章标题本身就是分组标题，父级由新加上的 ## 原理与运行机制 承担
        out.push(offset === 0 ? `### ${title}` : `${'#'.repeat(level)} ${title}`);
        return;
      }
    }
    out.push(row);
  });
  return out;
}

const problems = [];
const results = [];

for (const category of manifest.categories) {
  for (const lesson of category.lessons) {
    const file = path.join(__dirname, '..', '..', lesson.file);
    if (!fs.existsSync(file)) continue;
    const doc = readDoc(file);
    const spans = slice(doc.rows);
    const chapters = spans.filter((s) => CHAPTER.test(s.title) && !CANON.includes(s.title));
    if (chapters.length < 3) continue;

    const moved = MOVED.map((t) => spans.find((s) => s.title === t));
    if (moved.some((s) => s === undefined)) {
      problems.push(`${lesson.id}：缺 ${MOVED.join('/')} 之一`);
      continue;
    }
    const frame = moved[2];
    if (!FRAME_BOILER.test(doc.rows.slice(frame.index + 1, frame.end).join('\n'))) {
      problems.push(`${lesson.id}：原理与运行机制不是 retrofit 补写的那段，位置不处理`);
      continue;
    }
    if (frame.index < chapters[0].index) {
      problems.push(`${lesson.id}：原理与运行机制本来就在正文之前，无需重排`);
      continue;
    }

    const assembled = [...doc.rows.slice(0, spans[0].index)];
    for (const span of moved) assembled.push(...blockOf(doc.rows, span));
    for (const span of chapters) assembled.push(...trimTail(deepen(doc.rows.slice(span.index, span.end))), '');
    for (const span of spans) {
      if (DROP.has(span.title) || MOVED.includes(span.title)) continue;
      if (CHAPTER.test(span.title) && !CANON.includes(span.title)) continue;
      assembled.push(...blockOf(doc.rows, span));
    }

    const keptRows = doc.rows.filter((row, index) => {
      const span = spans.find((s) => index >= s.index && index < s.end);
      return !(span && DROP.has(span.title));
    });
    const before = keyLines(keptRows);
    const after = keyLines(assembled);
    if (before.length !== after.length) {
      const missing = before.filter((row) => !after.includes(row));
      const extra = after.filter((row) => !before.includes(row));
      problems.push(
        `${lesson.id}：正文行数 ${before.length}→${after.length}｜丢 ${missing.length} 行：${(missing[0] || '').slice(0, 40)}｜多 ${extra.length} 行：${(extra[0] || '').slice(0, 40)}`,
      );
      continue;
    }

    const newSpans = slice(assembled);
    const titles = newSpans.map((s) => s.title);
    if (titles.some((t) => CHAPTER.test(t))) problems.push(`${lesson.id}：仍残留章节号 H2`);
    const dupes = titles.filter((t, i) => titles.indexOf(t) !== titles.lastIndexOf(t));
    if (dupes.length) problems.push(`${lesson.id}：小节重复 ${dupes.join('/')}`);
    const missing = CANON.filter((t) => !titles.includes(t));
    if (missing.length) problems.push(`${lesson.id}：缺规范小节 ${missing.join('/')}`);
    if (titles[0] !== '本节知识框架') problems.push(`${lesson.id}：首个小节是 ${titles[0]}`);
    if (!/^#\s/.test(assembled[0])) problems.push(`${lesson.id}：首行不是 H1`);
    if (assembled.join('\n').length < 6000) problems.push(`${lesson.id}：正文只剩 ${assembled.join('\n').length} 字`);
    results.push({ lesson, rows: assembled, eol: doc.eol, titles, before: spans.length, after: newSpans.length });
  }
}

for (const r of results) {
  console.log(`${r.lesson.id}  H2 ${r.before}→${r.after}\n   ${r.titles.join(' | ')}`);
}
if (APPLY) {
  for (const r of results) {
    if (problems.some((p) => p.startsWith(`${r.lesson.id}：`))) continue;
    fs.writeFileSync(path.join(__dirname, '..', '..', r.lesson.file), r.rows.join(r.eol), 'utf8');
  }
}
console.log(`${APPLY ? '已落盘' : '试运行'}：课文 ${results.length} 篇，问题 ${problems.length} 项`);
for (const p of problems) console.log('  问题：' + p);
if (problems.length) process.exitCode = 1;
