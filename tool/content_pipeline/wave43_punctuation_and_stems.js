/**
 * 第 43 波：标点与成对符号缺陷收尾。
 *
 * 第 42 波逐条核对后剩下的、能机械判定的五类缺陷在这里一次做完：
 *   P1 标点碰撞折叠：。？→？、？？→？、：；→；、。”。→。」、同一标点连排收成单个、
 *      ：」这一前提→」这一前提，另有一处被切空的括号
 *   P2 孤儿粗体：`超时与重试显式配置**：` 这类只留下半个 ** 的残段，删掉那两个星号；
 *      反方向的 `**答案：C → D → A → B`（整行只有一个 ** 且在行首）补上行尾闭合
 *   P3 被截短的题干：判断依据里的 `题干「…前半截」问的就是这一条` 与 `与题干「…前半截」的要求对不上`，
 *       按本题题干原文补全（题干就在上一行「- **题目**：」和题库 question 字段里，以题库为准）
 *   P4 被截短的排序链：课文里 `本题顺序是「核心知识」。` 只剩一步，按题库解析补成完整链
 *   P5 四处要人工定夺的落点：反引号嵌套 2 处、注入尾巴 1 处、被切短的引用 1 处，逐条写死并核对次数
 *
 * 为什么 P3 不能像第 38 波那样整段删：content_test.dart:18 的断句器会把解析逐句统计，
 * 同一句在语料里出现 5 次以上就判失败。实测折叠成 `题干问的就是这一条。` 会多出 2 种重复句
 * （6× 和 5×），补全题干则一种都没有，所以这里只能补、不能删。
 * 补全时还要把题干自带的引号摘掉，只留外层这一对「」：题干里出现 “”「」 时，治理审计那套
 * 更宽的断句口径会在嵌套闭合处认为引号已经关掉，把残句 `」的要求对不上，应排除。` 重复到 26 门课。
 *
 *   node tool/content_pipeline/wave43_punctuation_and_stems.js [--apply] [--show]
 */
const fs = require('fs');
const path = require('path');

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const MANIFEST = 'assets/content/manifest.json';

/* ---------------------------------------------------------------- 小工具 */

/// 行内代码用等长空格掩掉，下标与原文一一对应，回填时还能取到原文
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

/// 把行内代码换成占位符，用来数符号个数
const bare = (line) => line.replace(/``[^`\n]*``/g, '<code>').replace(/`[^`\n]*`/g, '<code>');

const norm = (s) => String(s || '').replace(/\s+/g, '');
/// 截短是拦腰切的，比对前把标点也抹掉
const key = (s) => norm(s).replace(/[，。、；：！？,.;:!?「」『』“”《》()（）\-—_/]/g, '');

const count = (hay, needle) => (needle ? hay.split(needle).length - 1 : 0);

/// test/content_test.dart:18 splitExplanationSentences 的等价实现
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

const stats = { P1: 0, P2: 0, P3: 0, P4: 0, P5: 0 };
const side = { md: { P1: 0, P2: 0, P3: 0 }, mf: { P1: 0, P2: 0, P3: 0 } };
const notes = [];
const samples = [];
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

/* ---------------------------------------------------------------- P1 标点碰撞 */

const COLLAPSE = [
  [/。？/g, '？'],
  [/？？/g, '？'],
  [/：；/g, '；'],
  // 引号里已经带了句末标点，引号外那一个就是重复：…对照。”。哪一条… → …对照。”哪一条…
  [/([。！？])”([。！？])/g, (m) => `${m[1]}”`],
  // 同一个标点连排：补全题干时摘掉 “” 会把 「。”。」」压成「。。」，这里一并收成单个
  [/([。；，！？])\1+/g, (m) => m[1]],
  [/：」这一前提/g, '」这一前提'],
  [/特征（年龄、）/g, '特征（如年龄、性别）'],
];

function collapse(text) {
  let out = text;
  let n = 0;
  for (const [re, fixed] of COLLAPSE) {
    const [next, c] = editOutsideCode(out, re, (m) => (typeof fixed === 'function' ? fixed(m) : fixed));
    out = next;
    n += c;
  }
  return [out, n];
}

/* ---------------------------------------------------------------- P2 孤儿粗体 */

/// 一行里 ** 的个数为奇数时，从左往右配对后剩下的那一个是孤儿。
/// 只认「前面是文字、后面是全角冒号或汉字」的形态，免得误伤 *args / **kwargs / 2 ** 10。
function orphanBoldAt(line) {
  const masked = maskCode(line);
  const marks = [...masked.matchAll(/\*\*/g)].map((m) => m.index);
  if (marks.length === 0 || marks.length % 2 === 0) return -1;
  const at = marks[marks.length - 1];
  const before = masked[at - 1];
  const after = masked[at + 2];
  if (!before || !after) return -1;
  if (before === '*' || after === '*' || /\s/.test(before)) return -1;
  if (!/[：\u4e00-\u9fa5]/.test(after)) return -1;
  return at;
}

/// 整行只有一个 ** 且它就在行首：那是「**答案：C → D → A → B」这类忘了收尾的粗体开场。
/// 补上闭合而不是删掉——删掉会把整行的强调一起丢掉。
function closeOrphanBoldOpen(line) {
  const masked = maskCode(line);
  const marks = [...masked.matchAll(/\*\*/g)].map((m) => m.index);
  if (marks.length !== 1 || marks[0] !== 0) return [line, 0];
  if (/^#/.test(line.trimStart()) || /\*\*\s*$/.test(masked)) return [line, 0];
  return [`${line.replace(/\s+$/, '')}**`, 1];
}

function repairBoldPair(line) {
  const at = orphanBoldAt(line);
  if (at >= 0) return [line.slice(0, at) + line.slice(at + 2), 1];
  return closeOrphanBoldOpen(line);
}

function pass12(text) {
  const [collapsed, c1] = collapse(text);
  const [out, c2] = repairBoldPair(collapsed);
  return [out, c1, c2];
}

/* ------------------------------------------------- P1 + P2 落一遍 */

const SKIP_KEYS = new Set(['code', 'file', 'id', 'language', 'slot', 'image', 'asset']);

function walkStrings(node, fn) {
  if (Array.isArray(node)) {
    for (let i = 0; i < node.length; i++) {
      const v = node[i];
      if (typeof v === 'string') node[i] = fn(v);
      else walkStrings(v, fn);
    }
    return;
  }
  if (node && typeof node === 'object') {
    for (const [k, v] of Object.entries(node)) {
      if (typeof v === 'string') {
        if (!SKIP_KEYS.has(k)) node[k] = fn(v);
      } else {
        walkStrings(v, fn);
      }
    }
  }
}

for (const doc of docs) {
  let inFence = false;
  for (let i = 0; i < doc.rows.length; i++) {
    if (/^\s*(```|~~~)/.test(doc.rows[i])) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    const [next, c1, c2] = pass12(doc.rows[i]);
    if (c1 || c2) {
      if (SHOW && samples.length < 24) samples.push([`P1/P2 课文 ${path.basename(doc.file)}:${i + 1}`, doc.rows[i], next]);
      doc.rows[i] = next;
      doc.dirty = true;
      stats.P1 += c1;
      stats.P2 += c2;
      side.md.P1 += c1;
      side.md.P2 += c2;
    }
  }
}

for (const lesson of lessons) {
  walkStrings(lesson.quiz || [], (v) => {
    const [next, c1, c2] = pass12(v);
    if (c1 || c2) {
      stats.P1 += c1;
      stats.P2 += c2;
      side.mf.P1 += c1;
      side.mf.P2 += c2;
      if (SHOW && samples.length < 48) samples.push([`P1/P2 题库 ${lesson.id}`, v, next]);
    }
    return next;
  });
}

/* ---------------------------------------------------------------- P3 题干补全 */

/// 把 text 里所有 题干「X」 的 X 换成题干原文；给不出原文就原样留着并记一条
function restoreStems(text, resolve, where) {
  let n = 0;
  const out = String(text || '').replace(/题干「([^」\n]*)」/g, (whole, trunc) => {
    if (trunc.includes('「')) {
      note(`P3 跳过 ${where}：题干自带「」，嵌套引号交给人工波`);
      return whole;
    }
    const full = resolve(trunc);
    if (!full) {
      note(`P3 跳过 ${where}：定位不到「${trunc}」的题干`);
      return whole;
    }
    if (key(full) === key(trunc)) return whole;
    if (!key(full).startsWith(key(trunc))) {
      note(`P3 跳过 ${where}：「${trunc}」不是「${full}」的前缀`);
      return whole;
    }
    // 只保留外层这一对「」。题干自带引号时留着会让切句口径在嵌套闭合处提前认为引号已关，
    // 于是同一截残句（例如「」的要求对不上，应排除。」）跨课重复，撞上治理审计的模板句阈值。
    n++;
    return `题干「${full.replace(/[「」『』“”]/g, '')}」`;
  });
  return [out, n];
}

// 题库侧：每条解析只认自己那道题的题干，落点是确定的
for (const lesson of lessons) {
  for (const q of lesson.quiz || []) {
    const stem = q.question || '';
    const [next, n] = restoreStems(q.explanation || '', () => stem, `${lesson.id} 解析`);
    if (n) {
      q.explanation = next;
      stats.P3 += n;
      side.mf.P3 += n;
    }
  }
}

const STEM_LINE = /^\s*-?\s*\*\*(?:题目|题干)\*\*：(.*)$/;

// 课文侧：上一行「- **题目**：」给出题干，文本以题库原文为准
for (const doc of docs) {
  const table = new Map();
  for (const q of doc.lesson.quiz || []) table.set(key(q.question), q.question || '');
  let pending = '';
  let inFence = false;
  for (let i = 0; i < doc.rows.length; i++) {
    const line = doc.rows[i];
    if (/^\s*(```|~~~)/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    const s = STEM_LINE.exec(line);
    if (s) {
      pending = table.get(key(s[1])) || s[1];
      continue;
    }
    if (!line.includes('题干「')) continue;
    const resolve = (trunc) => {
      if (pending && key(pending).startsWith(key(trunc))) return pending;
      const hits = new Set();
      for (const q of doc.lesson.quiz || []) {
        const stem = q.question || '';
        if (key(stem).startsWith(key(trunc))) hits.add(stem);
      }
      return hits.size === 1 ? [...hits][0] : null;
    };
    const [next, n] = restoreStems(line, resolve, `${path.basename(doc.file)}:${i + 1}`);
    if (n) {
      doc.rows[i] = next;
      doc.dirty = true;
      stats.P3 += n;
      side.md.P3 += n;
      if (SHOW && samples.length < 72) samples.push([`P3 课文 ${path.basename(doc.file)}:${i + 1}`, line, next]);
    }
  }
}

/* ---------------------------------------------------------------- P4 排序链补全 */

const CHAIN = /本题顺序是((?:「[^」\n]*」)(?:\s*→\s*「[^」\n]*」)+)。/;
const SINGLE = /本题顺序是「([^」\n]*)」。/;

for (const doc of docs) {
  const chainOf = new Map();
  for (const q of doc.lesson.quiz || []) {
    const m = CHAIN.exec(q.explanation || '');
    if (m) chainOf.set(key(q.question), m[1]);
  }
  let pending = '';
  let answer = '';
  let inFence = false;
  for (let i = 0; i < doc.rows.length; i++) {
    const line = doc.rows[i];
    if (/^\s*(```|~~~)/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    const s = STEM_LINE.exec(line);
    if (s) {
      pending = s[1];
      continue;
    }
    const a = /^\s*-?\s*\*\*正确项\*\*：(.*)$/.exec(line);
    if (a) {
      answer = a[1];
      continue;
    }
    if (!SINGLE.test(line)) continue;
    let chain = chainOf.get(key(pending)) || '';
    if (!chain.includes(' → ') && answer.includes('→')) {
      chain = answer
        .split(/\s*→\s*/)
        .filter(Boolean)
        .map((step) => `「${step}」`)
        .join(' → ');
    }
    if (!chain.includes(' → ')) {
      note(`P4 跳过 ${path.basename(doc.file)}:${i + 1}：取不到完整顺序链`);
      continue;
    }
    const next = line.replace(SINGLE, `本题顺序是${chain}。`);
    if (next !== line) {
      doc.rows[i] = next;
      doc.dirty = true;
      stats.P4++;
      if (SHOW && samples.length < 96) samples.push([`P4 课文 ${path.basename(doc.file)}:${i + 1}`, line, next]);
    }
    answer = '';
  }
}

/* ---------------------------------------------------------------- P5 人工定夺 */

const HAND = [
  {
    id: 'M1 契约填空题的反引号嵌套',
    file: 'assets/content/cross_api_contract.md',
    old: '`GET /users/{`____`}`',
    next: '`GET /users/{____}`',
    expectMd: 1,
    expectManifest: 1,
  },
  {
    id: 'M2 带标签 break 的空缺写法',
    file: 'assets/content/programming_java_control_methods.md',
    old: '``____` outer;`',
    next: '`____ outer;`',
    expectMd: 1,
    expectManifest: 1,
  },
  {
    id: 'M3 解析尾巴上的注入残段',
    file: 'assets/content/java_modern_features.md',
    old: '排列模式。：Record、Sealed 与模式匹配` 里，与 `Record` 有关的说法中，哪一项最符合用 Record、密封类和模式匹配表达不可变数据与封闭类型层次？（现代 Java：Record、Sealed 与模式匹配·Java 第 3 题）',
    next: '排列模式。',
    expectMd: 1,
    expectManifest: 0,
  },
  {
    id: 'M4 术语关系里被切短的示例引用',
    file: 'assets/content/ai_multimodal.md',
    old: '（提示词越具体越可控：`一只柯基犬）',
    next: '（提示词越具体越可控）',
    expectMd: 1,
    expectManifest: 0,
  },
];

for (const fix of HAND) {
  let md = 0;
  const doc = docs.find((d) => d.file === fix.file);
  if (doc) {
    for (let i = 0; i < doc.rows.length; i++) {
      if (!doc.rows[i].includes(fix.old)) continue;
      md += count(doc.rows[i], fix.old);
      doc.rows[i] = doc.rows[i].split(fix.old).join(fix.next);
      doc.dirty = true;
    }
  }
  let mf = 0;
  walkStrings(manifest, (v) => {
    if (!v.includes(fix.old)) return v;
    mf += count(v, fix.old);
    return v.split(fix.old).join(fix.next);
  });
  if (md !== fix.expectMd) note(`P5 ${fix.id}：课文命中 ${md} 次，期望 ${fix.expectMd} 次`);
  if (mf !== fix.expectManifest) note(`P5 ${fix.id}：题库命中 ${mf} 次，期望 ${fix.expectManifest} 次`);
  stats.P5 += md + mf;
  if (SHOW) samples.push([`P5 ${fix.id}`, fix.old, fix.next]);
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

// 3) 语料级模板句：同一句出现 5 次以上就失败
//    两套口径都要守：content_test.dart:18 只在 。；\n 断句，治理审计还把 ！？; 也当边界，
//    题干里自带引号时后一套会切出跨课重复的残句（实测 26 门课撞同一截「」的要求对不上，应排除。）
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

// 4) 解析点名的干扰项与断言引用，必须还能对上本题选项原文
{
  const dropped = /[\s`*_「」『』“”"]/g;
  const flatten = (s) => String(s).replace(dropped, '');
  for (const lesson of allLessons) {
    for (const q of lesson.quiz || []) {
      const options = (q.options || []).map(flatten);
      for (const m of String(q.explanation || '').matchAll(/干扰项「([^」]{2,120})」/g)) {
        const want = flatten(m[1]);
        if (!options.includes(want)) blockers.push(`干扰项引用失配 ${lesson.id}：${m[1].slice(0, 40)}`);
      }
      for (const m of String(q.explanation || '').matchAll(/(?:调用了|出现字面量|代码里出现了)\s*`[^`]+`/g)) {
        const want = flatten(m[0]);
        if (!options.some((o) => o.includes(want))) blockers.push(`断言引用失配 ${lesson.id}：${m[0].slice(0, 40)}`);
      }
    }
  }
}

// 5) 课文结构：行数不变、表格列数不变、字数不破 6000，符号配对只能变好不能变坏
const parity = (s, re) => (bare(s).match(re) || []).length;
let preexisting = 0;
for (const doc of docs) {
  const out = render(doc);
  if (doc.rows.length !== doc.before.length) blockers.push(`行数变化 ${path.basename(doc.file)}`);
  if (out.replace(/\r/g, '').length < 6000) blockers.push(`课文字数跌破 6000 ${path.basename(doc.file)}`);
  let inFence = false;
  for (let i = 0; i < doc.rows.length; i++) {
    const before = doc.before[i];
    const line = doc.rows[i];
    if (/^\s*(```|~~~)/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    const columns = (s) => s.replace(/\\\|/g, '').split('|').length;
    if (line.trimStart().startsWith('|') && columns(line) !== columns(before)) {
      blockers.push(`表格列数变化 ${path.basename(doc.file)}:${i + 1}`);
    }
    if (before === line) continue;
    const odd = (s, re) => parity(s, re) % 2 === 1;
    const unbalancedQuote = (s) => (parity(s, /「/g) - parity(s, /」/g)) % 2 !== 0;
    const checks = [
      [odd(line, /`/g), odd(before, /`/g), '反引号'],
      [unbalancedQuote(line), unbalancedQuote(before), '「」'],
      [odd(line, /\*\*/g), odd(before, /\*\*/g), '**'],
    ];
    for (const [afterBad, beforeBad, label] of checks) {
      if (afterBad && !beforeBad) blockers.push(`${label} 配对变坏 ${path.basename(doc.file)}:${i + 1}`);
      else if (afterBad && beforeBad) preexisting++;
    }
  }
}

/* ---------------------------------------------------------------- 汇报 */

if (SHOW) {
  for (const [head, before, after] of samples.slice(0, 44)) {
    console.log(`\n[${head}]\n  改前 ${String(before).slice(0, 140)}\n  改后 ${String(after).slice(0, 170)}`);
  }
}
const uniqNotes = [...new Set(notes)];
if (uniqNotes.length) {
  console.log(`\n按原样保留 ${uniqNotes.length} 处：`);
  for (const n of uniqNotes.slice(0, 30)) console.log('   ' + n);
}
console.log(
  `\nP1 标点折叠 ${stats.P1}｜P2 孤儿粗体 ${stats.P2}｜P3 题干补全 ${stats.P3}｜P4 排序链补全 ${stats.P4}｜P5 人工 ${stats.P5}｜改动课文 ${docs.filter((d) => d.dirty).length} 篇`
);
console.log(`改后仍留着历史奇数符号行的行数（本波没动它们）：${preexisting}`);
console.log(
  `按侧拆分：课文 P1 ${side.md.P1} / P2 ${side.md.P2} / P3 ${side.md.P3}｜题库 P1 ${side.mf.P1} / P2 ${side.mf.P2} / P3 ${side.mf.P3}`
);
if (blockers.length) {
  console.log(`\n拦截 ${blockers.length} 条：`);
  for (const b of [...new Set(blockers)].slice(0, 30)) console.log('   ' + b);
  process.exit(1);
}
console.log('护栏全绿：题干覆盖 / 解析长度 / 模板句 / 干扰项与断言引用 / 课文结构');
if (!APPLY) {
  console.log('（试运行，加 --apply 才落盘）');
  process.exit(0);
}
let written = 0;
for (const doc of docs) {
  if (!doc.dirty) continue;
  fs.writeFileSync(doc.file, render(doc));
  written++;
}
fs.writeFileSync(MANIFEST, patchedManifest);
console.log(`已落盘：课文 ${written} 篇 + manifest`);
