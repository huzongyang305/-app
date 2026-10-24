// 第 27 波：给三节课的解析写出「本题自己的易错点」。
//
// 第 11 波重建解析残句时，是从整课里抽出「一条易错点 + 一条正确做法」，再原样盖到这一课的每道题上，
// 于是 css_selectors_intro、js_console_start、union_find 各有一对句子在自己的 5 道题里重复出现。
// 过去这些题的解析里带着不配对的「」和反引号，测试的断句器会把整段当成一句，重复被掩盖了；
// 第 25、26 波把残句修干净之后，重复就露出来并被 P0 检查拦下。
// 这里按每题的考点逐条改写这一对句子，其余文字（正确项复述、术语界定、干扰项说明）一律不动。
// 用法：node tool/content_pipeline/wave27_per_question_pitfalls.js [--apply] [--show]
import fs from 'node:fs';

const APPLY = process.argv.includes('--apply');
const SHOW = process.argv.includes('--show');
const P = 'assets/content/manifest.json';
const raw = fs.readFileSync(P, 'utf8');
const eol = raw.includes('\r\n') ? '\r\n' : '\n';
const manifest = JSON.parse(raw);

const FROM = {
  css_selectors_intro:
    '常见错法是选择器写得过于具体，其后果是后续样式无法覆盖，只能不断加权重。正确做法是控制嵌套层级，优先使用类选择器。',
  js_console_start:
    '常见错法是只看页面不看控制台，其后果是脚本报错被误判成样式问题。正确做法是先看控制台的第一条错误。',
  union_find:
    '常见错法是查找不做路径压缩，其后果是树高退化，重复查询很慢。正确做法是查找时顺手压缩路径，把沿途节点挂到根上。',
};

// key = 课时 id#题库下标，value = 按本题考点改写后的「常见错法…正确做法…」两句
const MAP = {
  'css_selectors_intro#0':
    '常见错法是把 .notice 当成 id 或标签名，其后果是以为只会有一个元素被命中，漏掉同一 class 的其余节点。正确做法是记住类选择器命中的是一批元素，改样式前先数清页面上带这个类名的元素。',
  'css_selectors_intro#1':
    '常见错法是只按书写先后判断谁生效，其后果是权重更高的规则被后写的低权重规则「覆盖」时看不出原因。正确做法是先比权重再比顺序，行内样式与 id 选择器的位置要单独记住。',
  'css_selectors_intro#2':
    '常见错法是只读结构标签不读 class 属性值，其后果是把示例里出现的字面量认错。正确做法是顺着 class 属性回到样式表，确认命中的选择器名与代码里的字面量逐字一致。',
  'css_selectors_intro#3':
    '常见错法是默认这段文字的观感来自浏览器样式，其后果是把颜色和字重归因到没写规则的标签上。正确做法是逐条对照示例里的类选择器声明，看清颜色与字重各由哪一条给出。',
  'css_selectors_intro#5':
    '常见错法是只勾自己熟悉的那一条，其后果是把命中范围与优先级两件事混作一件。正确做法是分别判断 class 命中的元素集合与行内、id、类、元素的优先级顺序，两项都要选中。',

  'js_console_start#0':
    '常见错法是只盯页面渲染结果找线索，其后果是字符串本身写错了也被当成样式问题。正确做法是在控制台里核对输出的字面量，与代码中书写的文本逐字比对。',
  'js_console_start#1':
    '常见错法是用 == 比较用户输入与数字，其后果是空串、null 被隐式转换后判成相等。正确做法是默认写 ===，确实要宽松比较时把转换规则写在注释里。',
  'js_console_start#2':
    '常见错法是只跑一遍正常输入就下结论，其后果是边界值触发的报错没人看见。正确做法是把版本、边界输入与失败路径都写进验证步骤，留下控制台记录再对照。',
  'js_console_start#3':
    '常见错法是以为省掉分号能让语法检查更严，其后果是自动插入规则生效时行首的 ( 或 [ 被接成上一次调用的参数。正确做法是按团队约定保留分号，报错时先核对语句被解析成的边界。',
  'js_console_start#4':
    '常见错法是出问题时只在页面里找现象，其后果是把脚本报错读成样式没生效。正确做法是打开开发者工具的控制台面板，先读第一条报错的行号与来源文件。',

  'union_find#0':
    '常见错法是只测合并成功的用例，其后果是重复边与空输入这两类分支没人覆盖。正确做法是把输入、输出和失败路径逐项写清，再固定数据规模复现一遍结论。',
  'union_find#1':
    '常见错法是把返回 false 读成调用失败，其后果是对已经连通的点对反复重试同一条边。正确做法是把 false 当作「这条边冗余」，在判环与最小生成树里直接跳过。',
  'union_find#2':
    '常见错法是只看变量名猜类型，其后果是把构造函数调用与普通函数调用混为一谈。正确做法是在代码里找到 DSU() 的调用点，确认它返回带查找与合并方法的实例。',
  'union_find#4':
    '常见错法是以为合并过的集合还能原路拆回去，其后果是删除元素后父指针指向已失效的节点。正确做法是需要分裂或撤销时改用可回退的并查集写法，或按连通性重建结构。',
  'union_find#5':
    '常见错法是只统计 find 的次数不统计根节点个数，其后果是把同一个分量数成好几个。正确做法是合并完再数根节点，并与 Kruskal 里「每加一条边少一个分量」对齐。',
};

const norm = (s) =>
  String(s || '')
    .replace(/（[A-Za-z0-9_.-]+ 第 \d+ 题）/g, '')
    .replace(/^[「『“"\s]+|[»』”"\s]+$/g, '')
    .replace(/[\s。！？!?]+$/g, '')
    .replace(/\s+/g, ' ')
    .trim();

const truthTexts = (q) => {
  const opts = (Array.isArray(q.options) ? q.options : []).map(String);
  const pick = (list) =>
    (Array.isArray(list) ? list : [])
      .map((v) => (typeof v === 'number' ? v : parseInt(String(v), 10)))
      .filter((i) => Number.isInteger(i) && i >= 0 && i < opts.length);
  const a = pick(q.answers);
  if (a.length) return a.map((i) => opts[i]);
  const o = pick(q.correct_order);
  if (o.length) return o.map((i) => opts[i]);
  if (Array.isArray(q.accepted_answers) && q.accepted_answers.length) return q.accepted_answers.map(String);
  const direct = typeof q.answer === 'number' ? q.answer : null;
  if (direct !== null && direct >= 0 && direct < opts.length) return [opts[direct]];
  return [];
};

// 复刻 test/content_test.dart 的断句器：引号与代码跨度内部的标点不断句
function splitSentences(text) {
  const out = [];
  let buf = '', inQuote = false, inCode = false;
  for (const ch of text) {
    if (ch === '`') inCode = !inCode;
    else if (!inCode) {
      if (ch === '「' || ch === '『' || ch === '“') inQuote = true;
      else if (ch === '」' || ch === '』' || ch === '”') inQuote = false;
    }
    buf += ch;
    if ((ch === '。' || ch === '；' || ch === '\n') && !inQuote && !inCode) {
      if (buf.trim()) out.push(buf.trim());
      buf = '';
    }
  }
  if (buf.trim()) out.push(buf.trim());
  return out;
}

const all = [];
for (const c of manifest.categories) for (const l of c.lessons || []) for (const q of l.quiz || []) all.push(q);
const counts = new Map();
for (const q of all) {
  for (const s of splitSentences(String(q.explanation || ''))) {
    const t = s.trim();
    if (t.length >= 12) counts.set(t, (counts.get(t) || 0) + 1);
  }
}

const stats = { fixed: 0, rejected: 0 };
const samples = [];
for (const c of manifest.categories) {
  for (const l of c.lessons || []) {
    if (!FROM[l.id]) continue;
    (l.quiz || []).forEach((q, qi) => {
      const key = `${l.id}#${qi}`;
      const replacement = MAP[key];
      const ex = String(q.explanation || '');
      if (!replacement || !ex.includes(FROM[l.id])) return;
      const next = ex.replace(FROM[l.id], replacement);
      const texts = truthTexts(q).map(norm).filter(Boolean);
      const flat = norm(next);
      const newSentences = splitSentences(next).filter((s) => s.length >= 12);
      const stillDuplicated = newSentences.some((s) => (counts.get(s) || 0) >= 5);
      if (next.length < 120 || texts.some((t) => !flat.includes(t)) || stillDuplicated) {
        stats.rejected++;
        console.log(`守卫退回 ${key}`);
        return;
      }
      q.explanation = next;
      stats.fixed++;
      if (SHOW) samples.push(`${key}｜${replacement.slice(0, 34)}…`);
      for (const s of newSentences) counts.set(s, (counts.get(s) || 0) + 1);
    });
  }
}

console.log(`改写逐题易错点 ${stats.fixed} 条，守卫退回 ${stats.rejected} 条`);
if (samples.length) console.log(samples.join('\n'));
if (APPLY) {
  fs.writeFileSync(P, JSON.stringify(manifest, null, 2).split('\n').join(eol));
  console.log('已写盘');
} else console.log('（dry-run，加 --apply 才写盘）');
