/*
 * wave42b_diversify_hardening_boilerplate.js — 拆掉安全加固课里五连发的模板句
 *   node tool/content_pipeline/wave42b_diversify_hardening_boilerplate.js          # 干跑
 *   node tool/content_pipeline/wave42b_diversify_hardening_boilerplate.js --apply
 *
 * wave42 把注入的截短题干收口成通用句后，Shell 脚本安全加固（进阶）五条解析里
 * 「题干要放回…/做这类判断时…/按本课口径…」三句变成逐字相同，
 * 触发 content_test 的「解析中仍有重复 5 次以上的模板句」。
 * 直接删又会让四条解析跌破 120 字符下限，所以按每题考点改写成语义各异的句子，
 * 课文与 manifest 解析同步改，两侧口径继续保持一致。
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const apply = process.argv.includes('--apply');
const lessonFile = 'assets/content/shell_security_hardening.md';
const manifestFile = 'assets/content/manifest.json';

const TRIPLE =
  '题干要放回《Shell 脚本安全加固（进阶）》的主线里看：覆盖命令注入、权限、临时文件、密钥和危险命令保护。做这类判断时，常踩的坑是直接执行外部输入，其后果是留下命令注入风险。按本课口径，这类题应校验输入并避免拼接命令。';

// old 必须唯一：三句模板本身五题共用，只能把各题的下文一起圈进来定位。
const FIXES = [
  {
    tag: 'multi 命令注入+权限',
    old: TRIPLE + '干扰项「只要 命令注入 的常规示例通过，就可以跳过边界与异常路径」与题干的要求对不上，应排除。',
    new:
      '两条正确项说的是一件事：先把脚本会读什么、会写什么、失败时怎么退出讲清楚，再把权限验证钉在同一个版本上补齐边界输入。' +
      '只跑通正常流程得到的结论在这类脚本里站不住，失败路径和版本记录缺一条都算答得不完整。' +
      '干扰项「只要 命令注入 的常规示例通过，就可以跳过边界与异常路径」与题干的要求对不上，应排除。',
  },
  {
    tag: 'code 覆盖清单',
    old: TRIPLE + '干扰项「这段 Shell 代码只展示语法，不会读取任何输入或产生可验证输出。」与题干的要求对不上，应排除。',
    new:
      '读这段代码要先确认它真的读取了外部输入并产生可核对的输出，否则无法判断防护有没有生效。' +
      '正确项之所以是那条覆盖清单，是因为命令注入、权限、临时文件、密钥和危险命令五个面缺一个都可能出事。' +
      '干扰项「这段 Shell 代码只展示语法，不会读取任何输入或产生可验证输出。」与题干的要求对不上，应排除。',
  },
  {
    tag: 'single 危险操作收口',
    old: TRIPLE + '干扰项「结构化日志、运行指标和通知让脚本可观测、可追踪。」与题干的要求对不上，应排除。',
    new:
      '这道题问的是危险操作的收口动作：先以 dry-run 跑一遍，再要人工确认，用锁挡住并发执行，最后留一条回滚路径。' +
      '只谈可观测性或只谈跨环境测试，都没有回答「这一步怎么安全落地」。' +
      '干扰项「结构化日志、运行指标和通知让脚本可观测、可追踪。」与题干的要求对不上，应排除。',
  },
  {
    tag: 'single 主线一致',
    old: TRIPLE + '干扰项「只要小数据能跑通，大规模和异常情况也一定正确。」与题干的要求对不上，应排除。',
    new:
      '主线要求五个面同时在场：命令注入、权限、临时文件、密钥与危险命令保护，缺一面就只是局部加固。' +
      '区分 Bash 与 POSIX 行为属于可移植性，重试、幂等与日志属于自动化，都不能替代安全加固本身。' +
      '干扰项「只要小数据能跑通，大规模和异常情况也一定正确。」与题干的要求对不上，应排除。',
  },
  {
    // 顺序题的模板句就是解析结尾，前面的四步链足以把这条 old 定位到唯一一处。
    tag: 'order 正文顺序',
    old: '本题顺序是「核心知识」 → 「关键流程」 → 「实践路径」 → 「常见误区」。' + TRIPLE,
    new:
      '本题顺序是「核心知识」 → 「关键流程」 → 「实践路径」 → 「常见误区」。' +
      '这条链只按正文的推进次序作答：先立概念，再走流程，然后落到实践路径，最后用常见误区收尾，' +
      '不要把它和某一层的具体加固动作互换位置。',
  },
];

const count = (hay, needle) => hay.split(needle).length - 1;
const lessonText = fs.readFileSync(path.join(root, lessonFile), 'utf8');
const manifestText = fs.readFileSync(path.join(root, manifestFile), 'utf8');

const blockers = [];
for (const fx of FIXES) {
  const md = count(lessonText, fx.old);
  const mf = count(manifestText, fx.old);
  if (md !== 1) blockers.push(`COUNT ${fx.tag}：课文里 old 出现 ${md} 次，要求 1 次`);
  if (mf !== 1) blockers.push(`COUNT ${fx.tag}：manifest 里 old 出现 ${mf} 次，要求 1 次`);
  console.log(`${fx.tag.padEnd(22)} 课文 ${md} 处 / 题库 ${mf} 处，${fx.old.length} → ${fx.new.length} 字符`);
}

// 改完真要在内存里落一遍：解析最短的那条不能跌破 content_test 的 120 字符下限。
let patchedManifest = manifestText;
for (const fx of FIXES) patchedManifest = patchedManifest.split(fx.old).join(fx.new);
const lesson = JSON.parse(patchedManifest).categories.flatMap((c) => c.lessons).find((l) => l.id === 'shell_security_hardening');
for (const [i, q] of (lesson.quiz || []).entries()) {
  console.log(`  quiz[${i}] ${q.type} 改后解析 ${q.explanation.length} 字符${q.explanation.length < 120 ? '  << 低于 120' : ''}`);
  if (q.explanation.length < 120) blockers.push(`SHORT quiz[${i}]：解析改后只剩 ${q.explanation.length} 字符`);
}

// 逐题模板句在整个语料里最多只能出现 4 次，这里直接核对新句子之间不互相撞车。
// content_test 的切句不会在 「…」／《…》 内部断开，这里按嵌套深度自己扫，
// 免得把「干扰项「…」与题干…」这种整句误切成三段而误报重复。
const sentences = (s) => {
  const out = [];
  let depth = 0;
  let cur = '';
  for (const ch of s) {
    cur += ch;
    if (ch === '「' || ch === '《') depth += 1;
    else if (ch === '」' || ch === '》') depth = Math.max(0, depth - 1);
    else if (depth === 0 && '。！？'.includes(ch)) {
      out.push(cur.trim());
      cur = '';
    }
  }
  if (cur.trim()) out.push(cur.trim());
  return out.filter((x) => x.length >= 12);
};
const seen = new Map();
for (const fx of FIXES) {
  for (const sent of sentences(fx.new)) seen.set(sent, (seen.get(sent) || 0) + 1);
}
for (const [sent, n] of seen) if (n > 1) blockers.push(`DUP-NEW 「${sent.slice(0, 30)}…」在新句里重复 ${n} 次`);

let patchedLesson = lessonText;
for (const fx of FIXES) patchedLesson = patchedLesson.split(fx.old).join(fx.new);
if (count(patchedLesson, TRIPLE)) blockers.push(`RESIDUE：改后课文里仍剩 ${count(patchedLesson, TRIPLE)} 处模板三连句`);
if (count(patchedManifest, TRIPLE)) blockers.push(`RESIDUE：改后 manifest 里仍剩 ${count(patchedManifest, TRIPLE)} 处模板三连句`);

if (blockers.length) {
  for (const b of blockers) console.log('  ! ' + b);
  console.log(apply ? '有拦截项，未写盘。' : '干跑未通过。');
  process.exitCode = 1;
} else if (apply) {
  let md = lessonText;
  let mf = manifestText;
  for (const fx of FIXES) {
    md = md.split(fx.old).join(fx.new);
    mf = mf.split(fx.old).join(fx.new);
  }
  fs.writeFileSync(path.join(root, lessonFile), md);
  fs.writeFileSync(path.join(root, manifestFile), mf);
  console.log(`已改写 ${FIXES.length} 条解析（课文 + manifest 同步）。`);
} else {
  console.log('干跑通过：五处定位唯一、新句互不重复。加 --apply 写盘。');
}
