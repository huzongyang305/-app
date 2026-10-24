/*
 * wave39_restore_pipe_code.js
 * 还原被竖线截断的行内代码：早先生成课文时把 `a | b` 这类写法按竖线切了列，
 * 留下「`0 \」「`curl ... \」这种断头代码。这里按（文件, 行号）精确改写，
 * 并把题库里同样被切断的 7 条解析一起补回，保证课文与题库口径一致。
 * 用法：node tool/content_pipeline/wave39_restore_pipe_code.js [--apply]
 */
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const CONTENT = path.join(ROOT, 'assets', 'content');
const APPLY = process.argv.includes('--apply');

// 表格里用 \| 转义，正文与题库里直接写竖线。
const ESC = '\\|'; // 落到文件里的两个字符 \|

const MD = [
  // ---------- programming_typescript.md ----------
  {
    f: 'programming_typescript.md',
    n: 50,
    must: '可空',
    text:
      '| 可空 | `string ' +
      ESC +
      ' null`、`number ' +
      ESC +
      ' undefined` | 只在「可空类型要显式写出 null / undefined」这一前提下成立，换输入或换环境要重新验证。 |',
  },

  // ---------- ts_basic_types.md ----------
  {
    f: 'ts_basic_types.md',
    n: 37,
    must: '最少要写的代码',
    text:
      '| 最少要写的代码 | `type UserId = string ' +
      ESC +
      ' number` | 只在「联合类型只列出实际允许的分支」这一前提下成立，换输入或换环境要重新验证。 |',
  },
  {
    f: 'ts_basic_types.md',
    n: 39,
    must: '最常见的错误',
    text:
      '| 最常见的错误 | 把联合类型当成任意类型：`string ' +
      ESC +
      ' number` 的值不能直接当 `number` 用 | 静态检查只在编译期成立，运行期输入仍需校验。 |',
  },
  {
    f: 'ts_basic_types.md',
    n: 41,
    must: '怎么确认学会了',
    text:
      '| 怎么确认学会了 | 定义 `type Weekday = "Mon" ' +
      ESC +
      ' "Tue" ' +
      ESC +
      ' "Wed"`，只允许这三个字面量 | 只在「字面量联合的取值范围是封闭的」这一前提下成立，换输入或换环境要重新验证。 |',
  },

  // ---------- programming_ts_decorators_types_pro.md ----------
  {
    f: 'programming_ts_decorators_types_pro.md',
    n: 43,
    must: 'useState<User',
    text:
      '| 状态 | `useState<User ' +
      ESC +
      ' null>(null)` | 只在「初始值与返回值都要写成可空联合」这一前提下成立，换输入或换环境要重新验证。 |',
  },
  {
    f: 'programming_ts_decorators_types_pro.md',
    n: 45,
    must: 'createContext<Auth',
    text:
      '| 上下文 | `createContext<Auth ' +
      ESC +
      ' null>(null)` | 易错：忘记 Provider 导致运行时报错；正确做法是自定义 hook 在为空时抛错。 |',
  },

  // ---------- programming_ts_narrowing_generics.md ----------
  {
    f: 'programming_ts_narrowing_generics.md',
    n: 51,
    must: '联合类型 A',
    text:
      '| 联合类型 A ' +
      ESC +
      ' B | 命中任一分支即可，用之前要先窄化 | 只在「窄化只在当前控制流内有效」这一前提下成立，换输入或换环境要重新验证。 |',
  },

  // ---------- programming_js_operators_control.md ----------
  { f: 'programming_js_operators_control.md', n: 18, must: '这类问题时，能说出触发条件', text: '- 遇到「`0 || 5`」这类问题时，能说出触发条件与修复顺序。' },
  { f: 'programming_js_operators_control.md', n: 65, must: '典型现象是', text: '- **`0 || 5`**：典型现象是 0 被当成空值；正确做法是取默认值改用 `??`。' },
  {
    f: 'programming_js_operators_control.md',
    n: 307,
    must: '得 5',
    text: '| `0 ' + ESC + ESC + ' 5` 得 5 | 0 被当成空值 | 改用 `??` |',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 315,
    must: 'if (name == "a"',
    text: '| `if (name == "a" ' + ESC + ESC + ' "b")` | 条件恒为真，判断落到错误分支 | 每个分支写完整比较 |',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 316,
    must: '混着写不加括号',
    text: '| 用 `??` 与 `' + ESC + ESC + '` 混着写不加括号 | 解析直接报错 | 两种运算符混用时补括号 |',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 317,
    must: '默认值',
    text: '| `0 ' + ESC + ESC + ' 默认值` | 0 被替换掉 | 需要保留 0 时用 `??` |',
  },
  { f: 'programming_js_operators_control.md', n: 328, must: '现场 1', text: '### 现场 1：`0 || 5`' },
  { f: 'programming_js_operators_control.md', n: 330, must: '症状', text: '**症状**：0 被当成空值，合法的 0 和空字符串也被换成默认值。' },
  { f: 'programming_js_operators_control.md', n: 332, must: '根因与修复', text: '**根因与修复**：`||` 挡的是所有假值，只想挡 null 与 undefined 时改用 `??`。' },
  {
    f: 'programming_js_operators_control.md',
    n: 334,
    must: '自检',
    text: '**自检**：在本课示例里复现「`0 || 5`」，改成 `0 ?? 5` 后重跑；如果症状消失且失败路径按预期变化，说明定位正确。',
  },
  { f: 'programming_js_operators_control.md', n: 392, must: '现场 9', text: '### 现场 9：`if (name == "a" || "b")`' },
  { f: 'programming_js_operators_control.md', n: 394, must: '症状', text: '**症状**：条件恒为真，任何输入都走进第一条分支。' },
  {
    f: 'programming_js_operators_control.md',
    n: 396,
    must: '根因与修复',
    text: '**根因与修复**：`"b"` 本身是真值，右侧永远轮不到；比较要写全成 `name == "a" || name == "b"`。',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 398,
    must: '自检',
    text: '**自检**：在本课示例里复现「`if (name == "a" || "b")`」，改成两边都写比较后重跑；如果症状消失且失败路径按预期变化，说明定位正确。',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 420,
    must: '本课错误表记录了',
    text: '本课错误表记录了「`0 || 5`」这类做法。请写出它会出现的现象、根因，以及修复顺序。',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 422,
    must: '参考答案',
    text: '**参考答案**：现象是 0 被当成空值；正确做法是取默认值改用 `??`。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 450,
    must: '四步写成可执行的检查清单',
    text: '面对「`0 || 5`」引发的问题，请把“复现现象 → 保留证据 → 改用 `??` → 回归验证”四步写成可执行的检查清单。',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 452,
    must: '参考答案',
    text: '**参考答案**：第一步按 `0 || 5` 复现；第二步记录输入、版本与完整报错；第三步按改用 `??` 只改一处；第四步重跑并确认失败路径也按预期变化。',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 497,
    must: '判断依据',
    sub: '易错点是`0 \\，改法是5` 得 5。',
    with: '易错点是 `0 || 5` 把 0 当成空值，改法是取默认值改用 `??`。',
  },
  {
    f: 'programming_js_operators_control.md',
    n: 527,
    must: '判断依据',
    sub: '易错点：`0 \\会造成\\。正确做法：5` 得 5。',
    with: '易错点：`0 || 5` 会造成合法的 0 被替换掉。正确做法：需要保留 0 时改用 `??`。',
  },
  { f: 'programming_js_operators_control.md', n: 549, must: '考点 11', text: '### 考点 11：排错——`0 || 5`' },
  { f: 'programming_js_operators_control.md', n: 551, must: '现象', text: '- **现象**：0 被当成空值，合法的 0 也被换成默认值。' },
  { f: 'programming_js_operators_control.md', n: 552, must: '处理', text: '- **处理**：只想挡 null 与 undefined 时改用 `??`。' },
  {
    f: 'programming_js_operators_control.md',
    n: 566,
    must: '现象分',
    text: '- **现象分**：能写出「0 被当成空值、合法的 0 也被替换」，而不是只写“程序有错”。',
  },
  { f: 'programming_js_operators_control.md', n: 567, must: '证据分', text: '- **证据分**：保留触发 `0 || 5` 的输入、版本和错误原文。' },
  { f: 'programming_js_operators_control.md', n: 568, must: '修复分', text: '- **修复分**：按「改用 `??`」只改一处，并同时回归正常路径与边界路径。' },

  // ---------- programming_shell_bash.md ----------
  {
    f: 'programming_shell_bash.md',
    n: 296,
    must: 'xargs rm',
    text: '| 用 `ls ' + ESC + ' xargs rm` | 文件名带空格就出事 | 改用 `find ... -print0 ' + ESC + ' xargs -0 rm` |',
  },
  {
    f: 'programming_shell_bash.md',
    n: 303,
    must: 'cd` 失败后继续执行',
    text: '| `cd` 失败后继续执行 | 后续命令在错误目录运行 | `cd "$dir" ' + ESC + ESC + ' exit 1` |',
  },
  {
    f: 'programming_shell_bash.md',
    n: 304,
    must: '误删根目录',
    text: '| `rm -rf "$dir/"` 且 `dir` 为空 | 误删根目录 | 校验变量非空：`[[ -n "$dir" ]] ' + ESC + ESC + ' exit 1` |',
  },
  { f: 'programming_shell_bash.md', n: 361, must: '现场 7', text: '### 现场 7：用 `ls | xargs rm`' },
  { f: 'programming_shell_bash.md', n: 363, must: '症状', text: '**症状**：文件名被空格拆成多个参数，`rm` 删到预期外的文件。' },
  {
    f: 'programming_shell_bash.md',
    n: 365,
    must: '根因与修复',
    text: '**根因与修复**：`ls` 的输出按空格和换行切词，改用 `find ... -print0 | xargs -0 rm` 以 NUL 分隔。',
  },
  {
    f: 'programming_shell_bash.md',
    n: 367,
    must: '自检',
    text: '**自检**：在本课示例里复现「用 `ls | xargs rm`」，改成 `find ... -print0 | xargs -0 rm` 后重跑；如果症状消失且失败路径按预期变化，说明定位正确。',
  },

  // ---------- programming_shell_pipeline.md ----------
  {
    f: 'programming_shell_pipeline.md',
    n: 283,
    must: 'xargs',
    text: '| `xargs` 不加 `-0` | 含空格文件名被拆 | `find -print0 ' + ESC + ' xargs -0` |',
  },

  // ---------- programming_shell_robust.md ----------
  {
    f: 'programming_shell_robust.md',
    n: 84,
    must: 'cd "$dir"',
    text: '- **`cd "$dir"`**：典型现象是 cd 失败后脚本继续在错误目录执行；正确做法是 `cd -- "$dir" || exit 1`。',
  },
  {
    f: 'programming_shell_robust.md',
    n: 86,
    must: '典型现象是',
    text: '- **`curl ... | bash`**：典型现象是脚本没落地就先执行；正确做法是下载后校验哈希再执行。',
  },
  {
    f: 'programming_shell_robust.md',
    n: 322,
    must: 'cd "$dir"',
    text: '| `cd "$dir"` | cd 失败后继续在错误目录执行 | `cd -- "$dir" ' + ESC + ESC + ' exit 1` |',
  },
  {
    f: 'programming_shell_robust.md',
    n: 324,
    must: 'curl',
    text: '| `curl ... ' + ESC + ' bash` | 未校验的远端脚本直接执行 | 下载后校验哈希再执行 |',
  },
  {
    f: 'programming_shell_robust.md',
    n: 335,
    must: 'cd` 不检查',
    text: '| 用 `cd` 不检查 | 后续命令在错误目录执行 | `cd "$DIR" ' + ESC + ESC + ' exit 1` |',
  },
  {
    f: 'programming_shell_robust.md',
    n: 339,
    must: 'set -e` 却依赖失败后继续',
    text: '| `set -e` 却依赖失败后继续 | 脚本提前退出 | 把允许失败的命令放进 `if !` 或 `' + ESC + ESC + ' true` |',
  },
  {
    f: 'programming_shell_robust.md',
    n: 344,
    must: 'cd` 后不检查',
    text: '| 用 `cd` 后不检查 | 后续操作在错误目录执行 | `cd -- "$dir" ' + ESC + ESC + ' exit 1` |',
  },
  { f: 'programming_shell_robust.md', n: 363, must: '症状', text: '**症状**：目录不存在时 `cd` 已经失败，后面的命令仍在原目录跑。' },
  {
    f: 'programming_shell_robust.md',
    n: 365,
    must: '根因与修复',
    text: '**根因与修复**：`cd` 的返回值没人接，写成 `cd -- "$dir" || exit 1`。',
  },
  {
    f: 'programming_shell_robust.md',
    n: 367,
    must: '自检',
    text: '**自检**：在本课示例里复现「`cd "$dir"`」，改成 `cd -- "$dir" || exit 1` 后重跑；如果症状消失且失败路径按预期变化，说明定位正确。',
  },
  { f: 'programming_shell_robust.md', n: 377, must: '现场 4', text: '### 现场 4：`curl ... | bash`' },
  { f: 'programming_shell_robust.md', n: 379, must: '症状', text: '**症状**：远端内容直接被 shell 执行，中途被替换也察觉不到。' },
  {
    f: 'programming_shell_robust.md',
    n: 381,
    must: '根因与修复',
    text: '**根因与修复**：管道把下载和执行连成一步，应先落盘校验哈希，再执行本地文件。',
  },
  {
    f: 'programming_shell_robust.md',
    n: 383,
    must: '自检',
    text: '**自检**：在本课示例里复现「`curl ... | bash`」，改成先 `curl -o` 再 `sha256sum -c` 后重跑；如果症状消失且失败路径按预期变化，说明定位正确。',
  },
  {
    f: 'programming_shell_robust.md',
    n: 530,
    must: '判断依据',
    sub: '易错点是`cd "$dir"`，改法是\\。',
    with: '易错点是 `cd "$dir"` 不检查返回值，会造成后续命令在错误目录执行，改法是 `cd -- "$dir" || exit 1`。',
  },
  {
    f: 'programming_shell_robust.md',
    n: 542,
    must: '判断依据',
    sub: '易错点是`curl ... \\，改法是下载后校验哈希再执行。易错点是`chmod 777`，会造成按需最小权限（如 750），改法是权限过大。',
    with: '易错点是 `curl ... | bash` 未校验就执行，改法是下载后校验哈希再执行。易错点是 `chmod 777` 会造成权限过大，改法是按需最小权限（如 750）。',
  },
  { f: 'programming_shell_robust.md', n: 583, must: '现象', text: '- **现象**：`cd` 已失败但脚本没停，后续命令落在错误目录。' },
  { f: 'programming_shell_robust.md', n: 584, must: '处理', text: '- **处理**：写成 `cd -- "$dir" || exit 1`。' },

  // ---------- toolchain_cli.md ----------
  {
    f: 'toolchain_cli.md',
    n: 238,
    must: 'cd` 失败后继续执行',
    text: '| `cd` 失败后继续执行 | 在错误目录操作 | `cd -- "$dir" ' + ESC + ESC + ' exit 1` |',
  },
  {
    f: 'toolchain_cli.md',
    n: 241,
    must: '混淆',
    text: '| `>` 与 `' + ESC + '` 混淆 | 命令行为不符 | `>` 写进文件，`' + ESC + '` 交给下一条命令 |',
  },
  { f: 'toolchain_cli.md', n: 283, must: '根因与修复', text: '**根因与修复**：`cd` 失败没人接，写成 `cd -- "$dir" || exit 1`。' },
  {
    f: 'toolchain_cli.md',
    n: 285,
    must: '自检',
    text: '**自检**：在本课示例里复现「`cd` 失败后继续执行」，改成 `cd -- "$dir" || exit 1` 后重跑；如果症状消失且失败路径按预期变化，说明定位正确。',
  },
  { f: 'toolchain_cli.md', n: 303, must: '现场 8', text: '### 现场 8：`>` 与 `|` 混淆' },
  { f: 'toolchain_cli.md', n: 305, must: '症状', text: '**症状**：把管道写成重定向，输出落进一个名为 `|` 的文件。' },
  {
    f: 'toolchain_cli.md',
    n: 307,
    must: '根因与修复',
    text: '**根因与修复**：`>` 把输出写进文件，`|` 把输出交给下一条命令，两者不能互换。',
  },
  {
    f: 'toolchain_cli.md',
    n: 309,
    must: '自检',
    text: '**自检**：在本课示例里复现「`>` 与 `|` 混淆」，改成需要落盘用 `>`、需要接力用 `|` 后重跑；如果症状消失且失败路径按预期变化，说明定位正确。',
  },
  {
    f: 'toolchain_cli.md',
    n: 438,
    must: '判断依据',
    sub: '改法是`cd -- "$dir" \\。',
    with: '改法是 `cd -- "$dir" || exit 1`。',
  },

  // ---------- programming_python_typing_testing.md ----------
  {
    f: 'programming_python_typing_testing.md',
    n: 621,
    must: '判断依据',
    sub: '改法是3.10+ 可直接用 `X \\。',
    with: '改法是 3.10+ 可直接用 `X | None`。',
  },

  // ---------- fundamentals_probability.md ----------
  {
    f: 'fundamentals_probability.md',
    n: 447,
    must: '判断依据',
    sub: '易错点是混淆 `P(A\\，会造成B)` 与 `P(B\\，改法是A)`。',
    with: '易错点是混淆 P(A|B) 与 P(B|A)，会造成结论完全相反，改法是先写清条件再用贝叶斯公式换算。',
  },
  {
    f: 'fundamentals_probability.md',
    n: 453,
    must: '判断依据',
    sub: '易错点是混淆 `P(A\\，会造成B)` 与 `P(B\\，改法是A)`。',
    with: '易错点是把条件概率的方向弄反，P(A|B) 并不等于 P(B|A)；改法是分别写清“谁是谁的条件”。',
  },
];

const BANK = [
  {
    id: 'js_operators_control',
    qi: 0,
    sub: '易错点是`0 \\，改法是5` 得 5。',
    with: '易错点是 `0 || 5` 把 0 当成空值，改法是取默认值改用 `??`。',
  },
  {
    id: 'js_operators_control',
    qi: 5,
    sub: '易错点：`0 \\会造成\\。正确做法：5` 得 5。',
    with: '易错点：`0 || 5` 会造成合法的 0 被替换掉。正确做法：需要保留 0 时改用 `??`。',
  },
  {
    id: 'shell_robust',
    qi: 1,
    sub: '易错点是`cd "$dir"`，改法是\\。',
    with: '易错点是 `cd "$dir"` 不检查返回值，会造成后续命令在错误目录执行，改法是 `cd -- "$dir" || exit 1`。',
  },
  {
    id: 'shell_robust',
    qi: 3,
    sub: '易错点是`curl ... \\，改法是下载后校验哈希再执行。易错点是`chmod 777`，会造成按需最小权限（如 750），改法是权限过大。',
    with: '易错点是 `curl ... | bash` 未校验就执行，改法是下载后校验哈希再执行。易错点是 `chmod 777` 会造成权限过大，改法是按需最小权限（如 750）。',
  },
  {
    id: 'cli',
    qi: 4,
    sub: '改法是`cd -- "$dir" \\。',
    with: '改法是 `cd -- "$dir" || exit 1`。',
  },
  {
    id: 'python_typing_testing',
    qi: 1,
    sub: '改法是3.10+ 可直接用 `X \\。',
    with: '改法是 3.10+ 可直接用 `X | None`。',
  },
  {
    id: 'probability',
    qi: 3,
    sub: '易错点是混淆 `P(A\\，会造成B)` 与 `P(B\\，改法是A)`。',
    with: '易错点是混淆 P(A|B) 与 P(B|A)，会造成结论完全相反，改法是先写清条件再用贝叶斯公式换算。',
  },
  {
    id: 'probability',
    qi: 4,
    sub: '易错点是混淆 `P(A\\，会造成B)` 与 `P(B\\，改法是A)`。',
    with: '易错点是把条件概率的方向弄反，P(A|B) 并不等于 P(B|A)；改法是分别写清“谁是谁的条件”。',
  },
];

function readLines(p) {
  const raw = fs.readFileSync(p, 'utf8');
  const nl = raw.includes('\r\n') ? '\r\n' : '\n';
  return { lines: raw.split(/\r?\n/), nl, eolAtEnd: raw.endsWith('\n') };
}

const byFile = new Map();
let hits = 0;
const miss = [];

for (const fix of MD) {
  const p = path.join(CONTENT, fix.f);
  if (!fs.existsSync(p)) {
    miss.push(fix.f + ':' + fix.n + ' 文件不存在');
    continue;
  }
  if (!byFile.has(fix.f)) byFile.set(fix.f, readLines(p));
  const box = byFile.get(fix.f);
  const idx = fix.n - 1;
  const cur = box.lines[idx];
  if (cur === undefined) {
    miss.push(fix.f + ':' + fix.n + ' 行不存在');
    continue;
  }
  if (fix.must && !cur.includes(fix.must)) {
    miss.push(fix.f + ':' + fix.n + ' 锚点丢失「' + fix.must + '」→ ' + cur.slice(0, 60));
    continue;
  }
  if (fix.sub) {
    if (!cur.includes(fix.sub)) {
      miss.push(fix.f + ':' + fix.n + ' 片段未命中 → ' + cur.slice(0, 80));
      continue;
    }
    box.lines[idx] = cur.split(fix.sub).join(fix.with);
    hits++;
  } else {
    if (cur === fix.text) continue;
    box.lines[idx] = fix.text;
    hits++;
  }
}

let files = 0;
for (const [f, box] of byFile) {
  if (box.lines.join('\n') === readLines(path.join(CONTENT, f)).lines.join('\n')) continue;
  files++;
  if (APPLY) fs.writeFileSync(path.join(CONTENT, f), box.lines.join(box.nl) + (box.eolAtEnd ? box.nl : ''), 'utf8');
}

console.log(
  (APPLY ? '应用' : '干跑') +
    '：课文 计划 ' +
    MD.length +
    ' 条｜命中 ' +
    hits +
    ' 处｜改动文件 ' +
    files +
    '｜未命中 ' +
    miss.length
);
miss.forEach((m) => console.log('  跳过 ' + m));

// ---------- 题库 ----------
const mPath = path.join(CONTENT, 'manifest.json');
const mRaw = fs.readFileSync(mPath, 'utf8');
const man = JSON.parse(mRaw);
const lessons = new Map();
for (const cat of man.categories || []) for (const l of cat.lessons || []) lessons.set(l.id, l);
let bankHits = 0;
for (const fix of BANK) {
  const les = lessons.get(fix.id);
  if (!les) {
    console.log('  题库跳过：找不到课时 ' + fix.id);
    continue;
  }
  const q = (les.quiz || [])[fix.qi];
  if (!q) {
    console.log('  题库跳过：' + fix.id + ' 没有第 ' + fix.qi + ' 题');
    continue;
  }
  const fields = ['explanation', 'question'].filter((k) => typeof q[k] === 'string' && q[k].includes(fix.sub));
  if (!fields.length) {
    console.log('  题库跳过：' + fix.id + ' q' + fix.qi + ' 片段未命中');
    continue;
  }
  fields.forEach((k) => {
    q[k] = q[k].split(fix.sub).join(fix.with);
    bankHits++;
  });
}
console.log('题库：计划 ' + BANK.length + ' 条｜命中 ' + bankHits + ' 处');
if (APPLY && bankHits) {
  const eol = mRaw.includes('\r\n') ? '\r\n' : '\n';
  fs.writeFileSync(mPath, JSON.stringify(man, null, 2).split('\n').join(eol), 'utf8');
}
