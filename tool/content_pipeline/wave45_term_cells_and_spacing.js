/**
 * 第 45 波：术语格碎片、`本课` 后缺空格、JavaScript 概念表里的三处坏格。
 *
 * 第 43、44 波把标点与字数收干净之后，全面复查（.tmp/probe105~111）只剩三族能机械判定的缺陷：
 *   Q1 `本课` 后面直接粘着课程名：`本课Python 装饰器与生成器要解决的是…`。实测 29 处
 *      跟在后面的都是本课标题（probe112），所以按标题包一层《》而不是只补空格。
 *      课文侧 27 处（27 篇）、题库侧 2 处。
 *   Q2 反写括号碎片 `）、回溯处理（`：生成器把「核心概念定义」那格的正文从
 *      「…（`>=` 不能被切成 `>` 和 `=`）、**回溯处理**（`>` 与 `>>`）…」中间截断，
 *      倒过来当成了术语名，同一个碎片被 24 处课文判断依据和 2 处解析抄了一遍。
 *      按那一格真正在讲的术语改成 `最长匹配与回溯处理`，26 处落点读起来都通。
 *   Q3 五处要手工定夺的格：programming_js_types.md 的概念表里术语格被拆成「与」、定义格被写成
 *      一行代码、JavaScript 那格整句被拦腰截断；fundamentals_compiler_frontend.md 的术语格与
 *      考点 7 的边界句留着裸碎片（不带反引号，Q2 抓不到）。逐格重写，每格期望命中 1 次。
 *
 *   node tool/content_pipeline/wave45_term_cells_and_spacing.js [--apply] [--show]
 */
const fs = require('fs');
const path = require('path');

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const MANIFEST = 'assets/content/manifest.json';

/* ---------------------------------------------------------------- 小工具 */

const maskCode = (line) =>
  String(line)
    .replace(/``[^`\n]*``/g, (m) => ' '.repeat(m.length))
    .replace(/`[^`\n]*`/g, (m) => ' '.repeat(m.length));

/// 只在行内代码之外做替换
function editOutsideCode(line, re, fn) {
  const masked = maskCode(line);
  const edits = [];
  let m;
  re.lastIndex = 0;
  while ((m = re.exec(masked)) !== null) {
    if (m[0].length === 0) {
      re.lastIndex++;
      continue;
    }
    edits.push([m.index, m.index + m[0].length, fn(m)]);
  }
  let out = line;
  for (const [start, end, text] of edits.sort((a, b) => b[0] - a[0])) {
    out = out.slice(0, start) + text + out.slice(end);
  }
  return [out, edits.length];
}

const norm = (s) => String(s || '').replace(/\s+/g, '');

/// test/content_test.dart:18 splitExplanationSentences 的等价实现，boundary 传两套口径
function sentences(text, boundary = '。；\n') {
  const out = [];
  let buf = '';
  let inQuote = false;
  let inCode = false;
  for (const ch of String(text || '')) {
    if (ch === '`') {
      inCode = !inCode;
    } else if (!inCode) {
      if (ch === '「' || ch === '『' || ch === '“') inQuote = true;
      else if (ch === '」' || ch === '』' || ch === '”') inQuote = false;
    }
    buf += ch;
    if (boundary.includes(ch) && !inQuote && !inCode) {
      if (buf.trim()) out.push(buf.trim());
      buf = '';
    }
  }
  if (buf.trim()) out.push(buf.trim());
  return out;
}

/* ---------------------------------------------------------------- 载入 */

const manifestRaw = fs.readFileSync(MANIFEST, 'utf8');
if (JSON.stringify(JSON.parse(manifestRaw), null, 2) + '\n' !== manifestRaw) {
  console.error('manifest 重新序列化与原文不等价，改动会扩散，停止。');
  process.exit(1);
}
const manifest = JSON.parse(manifestRaw);
const lessons = [];
for (const cat of manifest.categories) for (const l of cat.lessons || []) lessons.push(l);

const stats = { Q1: 0, Q2: 0, Q3: 0 };
const side = { md: { Q1: 0, Q2: 0, Q3: 0 }, mf: { Q1: 0, Q2: 0, Q3: 0 } };
const notes = [];
const samples = [];
const SHOW_ALL = SHOW;
const note = (text) => notes.push(text);

const docs = [];
for (const lesson of lessons) {
  if (!fs.existsSync(lesson.file)) {
    note(`缺课文文件 ${lesson.file}`);
    continue;
  }
  const raw = fs.readFileSync(lesson.file, 'utf8');
  const split = raw.split('\n');
  docs.push({
    lesson,
    file: lesson.file,
    rows: split.map((s) => (s.endsWith('\r') ? s.slice(0, -1) : s)),
    crlf: split.map((s) => s.endsWith('\r')),
    before: split.map((s) => (s.endsWith('\r') ? s.slice(0, -1) : s)),
    dirty: false,
  });
}

const render = (doc) => doc.rows.map((r, i) => (doc.crlf[i] ? r + '\r' : r)).join('\n');

/// 围栏代码块之外的行下标，Q1/Q2 都不该动到示例代码
function proseIndexes(rows) {
  const out = [];
  let inFence = false;
  for (let i = 0; i < rows.length; i++) {
    const t = rows[i].trimLeft();
    if (t.startsWith('```') || t.startsWith('~~~')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) out.push(i);
  }
  return out;
}

/* ---------------------------------------------------------------- Q1 本课 + 课程名 */

/// 实测 29 处 `本课` 后面紧跟着的就是本课标题（probe112），所以按标题包一层《》，
/// 比只补一个空格读得清楚：本课Python 装饰器与生成器要解决的是… → 本课《Python 装饰器与生成器》要解决的是…
const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const TIGHT_LEFTOVER = /本课[A-Za-z]/;

function fixTight(text, title) {
  if (!title) return [text, 0];
  return editOutsideCode(text, new RegExp('本课' + escapeRe(title), 'g'), () => `本课《${title}》`);
}

for (const doc of docs) {
  const title = (doc.lesson.title && doc.lesson.title.zh) || '';
  for (const i of proseIndexes(doc.rows)) {
    const [next, n] = fixTight(doc.rows[i], title);
    if (!n) continue;
    if (SHOW_ALL && doc.rows[i] !== next) samples.push(['Q1 md', doc.rows[i], next]);
    doc.rows[i] = next;
    doc.dirty = true;
    stats.Q1 += n;
    side.md.Q1 += n;
  }
}

for (const lesson of lessons) {
  const title = (lesson.title && lesson.title.zh) || '';
  for (const q of lesson.quiz || []) {
    for (const field of ['question', 'explanation']) {
      const [next, n] = fixTight(q[field] || '', title);
      if (!n) continue;
      if (SHOW_ALL) samples.push(['Q1 quiz ' + lesson.id, q[field], next]);
      q[field] = next;
      stats.Q1 += n;
      side.mf.Q1 += n;
    }
    for (let k = 0; k < (q.options || []).length; k++) {
      const [next, n] = fixTight(q.options[k], title);
      if (!n) continue;
      q.options[k] = next;
      stats.Q1 += n;
      side.mf.Q1 += n;
    }
  }
}

/* ---------------------------------------------------------------- Q2 反写括号碎片 */

const FRAG = '`）、回溯处理（`';
const FRAG_FIXED = '`最长匹配与回溯处理`';

for (const doc of docs) {
  for (const i of proseIndexes(doc.rows)) {
    if (!doc.rows[i].includes(FRAG)) continue;
    if (SHOW_ALL) samples.push(['Q2 md ' + path.basename(doc.file), doc.rows[i], doc.rows[i].split(FRAG).join(FRAG_FIXED)]);
    doc.rows[i] = doc.rows[i].split(FRAG).join(FRAG_FIXED);
    doc.dirty = true;
    stats.Q2++;
    side.md.Q2++;
  }
}
for (const lesson of lessons) {
  for (const q of lesson.quiz || []) {
    for (const field of ['question', 'explanation']) {
      const s = q[field] || '';
      if (!s.includes(FRAG)) continue;
      if (SHOW_ALL) samples.push(['Q2 quiz ' + lesson.id, s, s.split(FRAG).join(FRAG_FIXED)]);
      q[field] = s.split(FRAG).join(FRAG_FIXED);
      stats.Q2++;
      side.mf.Q2++;
    }
  }
}

/* ---------------------------------------------------------------- Q3 手工格 */

const HAND = [
  {
    file: 'assets/content/programming_js_types.md',
    id: 'js_types',
    old: '| 与 | 三条铁律：**默认 const、比较用 ===、空值判断用 ?? 或 == null**。理解 + 与 - 的隐式转换差异，能解释多数「诡异」行为。 | 只在「三条铁律：**默认 const、比较用 ===、空值判断用 ?? 或 == null**」这一前提下成立，换输入或换环境要重新验证。 |',
    next: "| 隐式转换 | 三条铁律：**默认 const、比较用 ===、空值判断用 ?? 或 == null**。理解 `+` 与 `-` 的隐式转换差异，能解释多数「诡异」行为。 | `==` 会按类型规则改值，`'' == 0` 与 `null == undefined` 都是坑；从别的模块拿到值时先归一化再比较。 |",
  },
  {
    file: 'assets/content/programming_js_types.md',
    id: 'js_types',
    old: "| 类型转换 | Number('42'); // 42。 | 只在「Number('42'); // 42」这一前提下成立，换输入或换环境要重新验证。 |",
    next: "| 类型转换 | 把值按目标形态重新取一次：`Number('42')` 得 `42`，`'1' + 1` 得 `'11'`，`'1' - 1` 得 `0`。 | `+` 碰到字符串走拼接，`-`、`*`、`/` 一律先把操作数转成数字，混写时要先定结合顺序。 |",
  },
  {
    file: 'assets/content/programming_js_types.md',
    id: 'js_types',
    old: '| JavaScript | JavaScript 是动态类型、基于原型的脚本语言，标准名为 ECMAScript。它既能跑在浏览器里操作页面 | 静态检查只在编译期成立，运行期输入仍需校验。 |',
    next: '| JavaScript | 动态类型、基于原型的脚本语言，标准名为 ECMAScript；既能跑在浏览器里操作页面，也能用 Node.js 跑在服务端。 | 静态检查只在编译期成立，运行期输入仍需校验。 |',
  },
  {
    file: 'assets/content/fundamentals_compiler_frontend.md',
    id: 'compiler_frontend',
    old: '| ）、回溯处理（ | 关键概念：**最长匹配**（>= 不能被切成 > 和 =）、**回溯处理**（> 与 >>）、**保留字表**（标识符识别后再查表判断是否为关键字）。 | 只在「关键概念：**最长匹配**（>= 不能被切成 > 和 =）、**回溯处理**（> 与 >>）、**保留字表**（标识符识别后再查表判断是否为关键字）」这一前提下成立，换输入或换环境要重新验证。 |',
    next: '| 最长匹配与回溯处理 | 词法层每次尽量多读：`>=` 不拆成 `>` 加 `=`；读到 `>` 先试探更长的 `>>`，接不上再回退。标识符读完后还要查保留字表才定类别。 | 这三步只看字符流、不看含义，报出来的错都属词法；含义与结构的问题出现在之后的语法、语义阶段，排查时别混成一团。 |',
  },
  {
    file: 'assets/content/fundamentals_compiler_frontend.md',
    id: 'compiler_frontend',
    old: '- **）、回溯处理（ 的边界**：只在「关键概念：**最长匹配**（`>=` 不能被切成 `>` 和 `=`）、**回溯处理**（`>` 与 `>>`）、**保留字表**（标识符识别后再查表判断是否为关键字）」这一前提下成立，换输入或换环境要重新验证。',
    next: '- **最长匹配与回溯处理的边界**：判定只看字符流，`>=` 不拆成 `>` 与 `=`，读到 `>` 先探 `>>`；标识符要再查一次保留字表才定成关键字。含义层面的错误属于语法与语义阶段，排查时先确认问题出在哪一层。',
  },
];

for (const fix of HAND) {
  const doc = docs.find((d) => d.file === fix.file);
  if (!doc) {
    note(`Q3 找不到课文 ${fix.file}`);
    continue;
  }
  let hit = 0;
  for (let i = 0; i < doc.rows.length; i++) {
    if (doc.rows[i] !== fix.old) continue;
    hit++;
    if (SHOW_ALL) samples.push(['Q3 ' + fix.id, doc.rows[i], fix.next]);
    doc.rows[i] = fix.next;
    doc.dirty = true;
  }
  if (hit !== 1) note(`Q3 ${fix.id}：课文命中 ${hit} 次，期望 1 次`);
  stats.Q3 += hit;
  side.md.Q3 += hit;
}

/* ---------------------------------------------------------------- 护栏 */

const blockers = [];
const patchedManifest = JSON.stringify(manifest, null, 2) + '\n';
const patched = JSON.parse(patchedManifest);
const allLessons = patched.categories.flatMap((c) => c.lessons || []);

// 1) 题干覆盖：课文里还得按 content_test 的口径找得到每条题干
for (const doc of docs) {
  const body = norm(render(doc));
  for (const q of doc.lesson.quiz || []) {
    const stem = norm(q.question);
    if (stem && !body.includes(stem)) blockers.push(`题干覆盖丢失 ${path.basename(doc.file)}：${q.question.slice(0, 40)}`);
  }
}

// 2) 解析长度：补全只会变长，这里守住 120 字符下限
for (const lesson of allLessons) {
  for (const q of lesson.quiz || []) {
    if ((q.explanation || '').trim().length < 120) blockers.push(`解析短于 120 ${lesson.id}/${q.type}`);
  }
}

// 3) 语料级模板句：两套断句口径都只许变好
{
  const audit = (boundary) => {
    const seen = new Map();
    for (const lesson of allLessons) {
      for (const q of lesson.quiz || []) {
        for (const s of sentences(q.explanation, boundary)) {
          if (s.length < 12) continue;
          seen.set(s, (seen.get(s) || 0) + 1);
        }
      }
    }
    for (const [s, n] of seen) if (n >= 5) blockers.push(`模板句重复 ${n}×（${boundary} 口径）：${s.slice(0, 70)}`);
  };
  audit('。；\n');
  audit('。！？!?；;');
}

// 4) 概念表与术语表的首格：改完之后不许再留下括号碎片或单字残句
for (const doc of docs) {
  let section = '';
  for (const line of render(doc).split('\n')) {
    if (/^## /.test(line)) section = line.slice(3).trim();
    if (!/^(核心概念定义|术语速查)$/.test(section)) continue;
    if (!/^\|/.test(line) || /^\|\s*[-: ]+\|/.test(line)) continue;
    const cells = line.split('|').slice(1, -1).map((s) => s.trim());
    if (cells.length < 2 || /^(术语|概念|名词)\s*$/.test(cells[0])) continue;
    if (/^[）、，。；：]|[（「『“]$/.test(cells[0])) blockers.push(`${section}首格仍是碎片 ${path.basename(doc.file)}：${cells[0].slice(0, 30)}`);
  }
}

// 5) 标点碰撞与孤儿粗体：这两项在 43 波之后全是 0，改动不许把它们再引入
{
  const COLLIDE = [/([。；，！？])\1+/, /([。！？])”([。！？])/, /。？|：；/];
  for (const doc of docs) {
    for (const i of proseIndexes(doc.rows)) {
      if (doc.rows[i] === doc.before[i]) continue;
      const masked = maskCode(doc.rows[i]);
      for (const re of COLLIDE) if (re.test(masked)) blockers.push(`新引入标点碰撞 ${path.basename(doc.file)} 第 ${i + 1} 行`);
      const marks = [...maskCode(doc.rows[i]).matchAll(/\*\*/g)];
      if (marks.length % 2 === 1) blockers.push(`新引入孤儿粗体 ${path.basename(doc.file)} 第 ${i + 1} 行`);
    }
  }
  for (const lesson of allLessons) {
    for (const q of lesson.quiz || []) {
      for (const s of [q.question, q.explanation, ...(q.options || [])]) {
        const masked = maskCode(String(s || ''));
        for (const re of COLLIDE) if (re.test(masked)) blockers.push(`题库新引入标点碰撞 ${lesson.id}`);
      }
    }
  }
}

// 6) `本课` 后不许再粘着拉丁字母：Q1 的口径是标题包《》，漏一条就该在这里响
for (const doc of docs) {
  for (const i of proseIndexes(doc.rows)) {
    if (TIGHT_LEFTOVER.test(doc.rows[i])) blockers.push(`本课仍粘英文 ${path.basename(doc.file)} 第 ${i + 1} 行`);
  }
}
for (const lesson of allLessons) {
  for (const q of lesson.quiz || []) {
    for (const s of [q.question, q.explanation, ...(q.options || [])]) {
      if (TIGHT_LEFTOVER.test(String(s || ''))) blockers.push(`题库本课仍粘英文 ${lesson.id}`);
    }
  }
}

// 7) 行数与字数下限：课文只能变长不能变形
for (const doc of docs) {
  const out = render(doc);
  if (doc.rows.length !== doc.before.length) blockers.push(`行数变化 ${path.basename(doc.file)}`);
  if (out.replace(/\r/g, '').length < 6000) blockers.push(`课文字数跌破 6000 ${path.basename(doc.file)}`);
  let inFence = false;
  for (const line of doc.rows) {
    const t = line.trimLeft();
    if (t.startsWith('```') || t.startsWith('~~~')) inFence = !inFence;
  }
  if (inFence) blockers.push(`围栏不闭合 ${path.basename(doc.file)}`);
}

/* ---------------------------------------------------------------- 报告 */

console.log(
  `Q1 本课+课程名补书名号 ${stats.Q1}｜Q2 反写括号碎片 ${stats.Q2}｜Q3 手工重写概念格 ${stats.Q3}｜` +
    `改动课文 ${docs.filter((d) => d.dirty).length} 篇`
);
console.log(`按侧拆分：课文 Q1 ${side.md.Q1} / Q2 ${side.md.Q2} / Q3 ${side.md.Q3}｜题库 Q1 ${side.mf.Q1} / Q2 ${side.mf.Q2}`);
for (const n of notes) console.log('提示：' + n);
if (SHOW) {
  for (const [tag, a, b] of samples.slice(0, 24)) {
    console.log(`\n[${tag}] 原：${a}\n      改：${b}`);
  }
}
if (blockers.length) {
  console.error(`\n护栏拦住 ${blockers.length} 项：`);
  for (const b of blockers.slice(0, 20)) console.error('  ' + b);
  process.exit(1);
}
console.log('护栏全绿：题干覆盖、解析长度、模板句两套口径、表格首格碎片、标点与粗体、行数与字数下限。');

if (!APPLY) {
  console.log('试运行，未落盘。加 --apply 生效。');
  process.exit(0);
}

for (const doc of docs) {
  if (!doc.dirty) continue;
  fs.writeFileSync(doc.file, render(doc));
}
fs.writeFileSync(MANIFEST, patchedManifest);
console.log(`已落盘：课文 ${docs.filter((d) => d.dirty).length} 篇 + manifest`);
