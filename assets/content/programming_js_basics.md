# JavaScript 与运行环境

![浏览器与 Node.js 两种运行环境](images/diagram_js_env.webp)

![JavaScript 与运行环境](images/remaining_js_basics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类为「JavaScript」，课程主题为「JavaScript 与运行环境」，学习阶段为「基础」，建议用时 50 分钟。

**本课要解决的主问题**：浏览器与 Node 的差异、运行方式、严格模式与代码质量工具。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「JavaScript 与运行环境」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「JavaScript 与运行环境」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「JavaScript」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：没有硬性先修课；仍建议先具备本分类的基础阅读与操作能力。

**学习位置**：本课位于《JavaScript DOM 入门》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《变量、类型与类型转换》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释JavaScript 与运行环境解决了什么问题，而不是只背术语。
- 能说清 「JavaScript」、「Node」、「浏览器」、「console」 之间的关系，并分别举出一个例子。
- 能把 JavaScript 放回「JavaScript 与运行环境」的知识体系，说明它和 Node 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：浏览器与 Node 的差异、运行方式、严格模式与代码质量工具。

**教材衔接：前置知识**

- 能独立打开与保存文件即可；Node 会在正文中从零解释。
- 本课阶段：基础。建议先掌握同一分类的基础课程，并能独立运行正文里的 JavaScript 示例。
- 开始前先复习：JavaScript、Node、浏览器。
- 如果 JavaScript 是什么 这一步看不懂，先记录具体卡点，再用 JavaScript 复现一遍。

**教材衔接：本课小结**

先分清代码运行在浏览器还是 Node，再去查对应的 API；语言核心两者通用。

## 核心概念定义

> 阅读约定：本课先给「JavaScript 与运行环境」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| JavaScript | JavaScript 是动态类型、基于原型的脚本语言，标准名为 ECMAScript。它既能跑在浏览器里操作页面，也能通过 Node.js 写服务端、命令行和桌面应用。 | 仅在「JavaScript 与运行环境」明确给出的输入、版本与资源条件下成立。 |
| 浏览器 | 解析 HTML/CSS、执行 JavaScript 并管理网络与页面的客户端环境。 | 仅在「JavaScript 与运行环境」明确给出的输入、版本与资源条件下成立。 |
| 事件循环 | 先执行同步代码与微任务，再取宏任务，它决定了 setTimeout 与 Promise 的执行顺序。 | 仅在「JavaScript 与运行环境」明确给出的输入、版本与资源条件下成立。 |
| 严格模式 | 用 use strict 或在 ES 模块中默认启用，禁止隐式全局变量与部分静默失败的行为。 | 仅在「JavaScript 与运行环境」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「JavaScript 与运行环境」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「JavaScript」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「浏览器」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「事件循环」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「JavaScript 与运行环境」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | JavaScript | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 浏览器 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 事件循环 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「JavaScript 与运行环境」自己的示例验证。「JavaScript 与运行环境」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：JavaScript 是什么**

JavaScript 是**动态类型、基于原型**的脚本语言，标准名为 ECMAScript。它既能跑在浏览器里操作页面，也能通过 Node.js 写服务端、命令行和桌面应用。

**教材衔接：两种运行环境**

| 环境 | 提供的能力 |
| --- | --- |
| 浏览器 | DOM、事件、fetch、localStorage、Canvas |
| Node.js | 文件系统、进程、网络、npm 生态 |

语言核心（变量、函数、对象、Promise）两边通用，宿主 API 不同。

**教材衔接：运行方式**

```html
<!-- 浏览器：defer 表示解析完 HTML 再执行，避免阻塞 -->
<script src="app.js" defer></script>
```

```bash
node app.js      # 运行脚本
node             # 进入 REPL 交互模式
```

```javascript
console.log('Hello, JavaScript!');
console.warn('警告');
console.error('错误');
console.table([{ a: 1 }, { a: 2 }]);   // 以表格展示
```

**教材衔接：运行环境速查**

| 能力 | 浏览器 | Node.js |
| --- | --- | --- |
| 操作 DOM | 有（`document`） | 无 |
| 获取用户事件 | 有（`addEventListener`） | 无 |
| 读写本地文件 | 受限（File API） | 有（`node:fs`） |
| 发起网络请求 | `fetch` | `fetch`（18+ 内置） |
| 定时器 | `setTimeout` / `setInterval` | 同样支持 |
| 全局对象 | `window` | `globalThis` |
| 模块系统 | ESM 为主 | ESM 与 CommonJS 都支持 |
| 环境变量 | 无（构建时注入） | `process.env` |

脚本加载方式速查：

| 写法 | 解析阻塞 | 执行时机 |
| --- | --- | --- |
| `<script src="a.js">` | 阻塞解析 | 立即按顺序执行 |
| `<script async src="a.js">` | 不阻塞 | 下载完立刻执行（顺序不确定） |
| `<script defer src="a.js">` | 不阻塞 | DOM 解析完成后按顺序执行 |
| `type="module"` | 不阻塞 | 默认 defer 语义，作用域独立 |

**教材衔接：控制台速查**

| 目的 | 写法 |
| --- | --- |
| 打印值 | `console.log(a, b)` |
| 打印对象结构 | `console.dir(obj, { depth: null })` |
| 表格展示数组 | `console.table(list)` |
| 分组输出 | `console.group()` / `console.groupEnd()` |
| 计时 | `console.time("t")` / `console.timeEnd("t")` |
| 断言 | `console.assert(cond, "提示")` |
| 调用栈 | `console.trace()` |
| 断点 | 代码里写 `debugger;` |

**教材衔接：零基础详解：JavaScript 到底在哪里运行**

### 一句话说清它是什么

JavaScript 是**脚本语言**：不需要提前编译，写完立刻由运行环境解释执行。
它有两大宿主：浏览器（能操作页面）和 Node.js（能读写文件、起服务）。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 引擎 | 翻译官 | V8（Chrome/Node）、JavaScriptCore（Safari） |
| 宿主环境 | 翻译官上班的公司 | 浏览器给了 `document`，Node 给了 `fs` |
| 事件循环 | 排队叫号 | 同步任务先做完，再处理回调队列 |
| 单线程 | 只有一个窗口办业务 | 所以耗时操作要异步，否则界面卡死 |

**同一门语言，能用的 API 取决于宿主环境**——浏览器里没有 `fs`，Node 里没有 `document`。

### 逐行拆解第一个程序

```javascript
// 浏览器控制台或 Node 里都能运行
console.log("Hello, World!");   // 打印到控制台

const name = "小明";             // 常量，不能重新赋值
let age = 18;                   // 变量，可以改
age = age + 1;                  // 重新赋值

console.log(`你好，${name}，明年 ${age} 岁`);
```

| 行 | 在做什么 | 为什么这么写 |
| --- | --- | --- |
| `console.log(...)` | 输出内容 | 调试最常用的手段 |
| `const name = ...` | 声明一个不可重新赋值的名字 | 默认就用 `const`，更安全 |
| `let age = 18` | 声明一个可以改的变量 | 确实需要改时才用 `let` |
| `` `...${x}...` `` | 模板字符串 | 反引号 + `${}` 才能插值 |

### `var`、`let`、`const` 三者的取舍

| 关键字 | 能否重新赋值 | 作用域 | 能否重复声明 | 建议 |
| --- | --- | --- | --- | --- |
| `var` | 能 | 函数作用域 | 能 | 老代码里见，新代码别用 |
| `let` | 能 | 块作用域 `{}` | 不能 | 需要改时用 |
| `const` | 不能 | 块作用域 `{}` | 不能 | **默认选择** |

注意：`const` 锁的是「绑定」，不是内容：
`const arr = [1]; arr.push(2);` 是合法的，但 `arr = []` 会报错。

### 在浏览器里怎么跑起来

```html
<!DOCTYPE html>
<html lang="zh-CN">
  <head><meta charset="utf-8"><title>JS 入门</title></head>
  <body>
    <p id="out">等待中…</p>
    <script src="main.js"></script>
    <!-- 也可以直接内联：<script>console.log('hi')</script> -->
  </body>
</html>
```

脚本放在 `</body>` 前，或用 `defer`，能保证 HTML 先解析完，`document` 才可用。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `==` 比较 | `"1" == 1` 是 true | 一律用 `===` |
| 忘记 `await` | 拿到的是 Promise 而不是结果 | 在 `async` 函数里 `await` |
| 循环里用 `var` | 回调里全是最后一个值 | 改用 `let` |
| 变量未声明就赋值 | 严格模式报错，非严格模式污染全局 | 始终用 `let` / `const` |
| 数字与字符串相加 | `"1" + 2` 得到 `"12"` | 先 `Number()` 转换 |
| 直接读 `undefined` 的属性 | `TypeError: Cannot read properties of undefined` | 用 `?.` 可选链 |
| 以为对象是复制的 | 改副本影响了原对象 | 用展开 `{...obj}` 做浅拷贝 |
| 中文标点 | `SyntaxError` | 代码里全部用英文半角 |

### 三类运行环境要分清

| 环境 | 能做什么 | 不能做什么 |
| --- | --- | --- |
| 浏览器 | 操作 DOM、发请求、存 localStorage | 读写本地文件 |
| Node.js | 读写文件、起 HTTP 服务 | 访问 `document` |
| 两者共有 | 语法、内置对象、Promise、JSON | —— |

### 手把手练习：命令行问候与简单统计

```javascript
// Node 环境：node hello.js
const readline = require("node:readline/promises");

async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const name = (await rl.question("请输入姓名：")).trim();
  const scores = [88, 92, 79];
  const total = scores.reduce((sum, n) => sum + n, 0);
  const avg = (total / scores.length).toFixed(1);

  console.log(`你好，${name || "朋友"}！平均分 ${avg}`);
  rl.close();
}

main();
```

### 学完自测

- [ ] 能说出浏览器和 Node 各自多出哪些能力。
- [ ] 能解释 `const` 声明的数组为什么还能 `push`。
- [ ] 知道 `var` 与 `let` 在循环回调里的差别。
- [ ] 能说出 `==` 和 `===` 的区别。
- [ ] 知道脚本为什么建议放在 `</body>` 前或用 `defer`。

**教材衔接：版本与时效**

- JavaScript 依赖的新 API 必须有降级路径，否则老环境直接报错。
- 升级「JavaScript 与运行环境」涉及的依赖前，先用 JavaScript 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 JavaScript 的版本变量，记录编译、测试与产物体积的变化。
- 回归范围锁定 JavaScript 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 JavaScript 的新旧版本差异，并据此调整下次复核时间。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 JavaScript、Node | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「JavaScript 与运行环境」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「JavaScript 与运行环境」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:javascript`，用于动手验证《JavaScript 与运行环境》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《JavaScript 与运行环境》原文中的最小示例。先预测《JavaScript 与运行环境》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```html
<!-- 浏览器：defer 表示解析完 HTML 再执行，避免阻塞 -->
<script src="app.js" defer></script>
```

**教材衔接：严格模式**

```javascript
'use strict';    // 禁止隐式全局变量、静默失败等历史行为
```

ES Module 默认就是严格模式；新代码建议使用模块而不是全局脚本。

**教材衔接：代码质量工具**

```bash
npm install --save-dev eslint prettier
npx eslint . --fix
npx prettier --write .
```

ESLint 抓潜在错误，Prettier 统一格式，两者配合是前端工程的标准配置。

## 时间/空间复杂度或性能分析

**复杂度证据**：「JavaScript 与运行环境」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「JavaScript 与运行环境」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「JavaScript 与运行环境」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《JavaScript 与运行环境》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「JavaScript 与运行环境」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 报错或现象 | 含义 | 处理方式 |
| --- | --- | --- |
| `ReferenceError: x is not defined` | 变量未声明就使用 | 检查拼写与作用域，声明后再用 |
| `TypeError: Cannot read properties of undefined` | 访问了 `undefined` 的属性 | 用可选链或先判空 |
| `SyntaxError: Unexpected token` | 语法错误（常漏括号或逗号） | 看行号，检查上一行是否完整 |
| 页面报 `require is not defined` | 浏览器没有 CommonJS | 改用 ESM 的 `import` |
| `process is not defined` | 在浏览器用了 Node API | 改前端方案或在构建时注入 |
| 脚本在 `<head>` 里执行却拿不到元素 | 脚本先于 DOM 运行 | 加 `defer` 或放到 `</body>` 前 |
| `async` 脚本顺序错乱 | `async` 不保证顺序 | 有依赖关系时改用 `defer` 或模块 |
| 修改了变量但页面没更新 | 缺少渲染逻辑 | 修改数据后显式更新 DOM 或触发框架重渲染 |
| `let` 重复声明 | `SyntaxError: Identifier has already been declared` | 同一作用域内不要重复声明 |
| 严格模式才报的错（如未声明赋值） | 静默失败 | 用 ESM 或加 `"use strict"` 暴露问题 |

**教材衔接：故障现场**

### 现场 1：ReferenceError: x is not defined

**症状**：在《JavaScript 与运行环境》的复现场景中，变量未声明就使用。

**根因**：“变量未声明就使用”只是表层结果。向上追溯会落到“ReferenceError: x is not defined”这一步，因为它省略了《JavaScript 与运行环境》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《JavaScript 与运行环境》的问题，检查拼写与作用域，声明后再用。

**验证**：在《JavaScript 与运行环境》中按“检查拼写与作用域，声明后再用”调整后，从“ReferenceError: x is not defined”的触发条件重放同一条路径，确认“变量未声明就使用”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：TypeError: Cannot read properties of undefined

**症状**：在《JavaScript 与运行环境》的复现场景中，访问了 undefined 的属性。

**根因**：触发点是把“TypeError: Cannot read properties of undefined”当成安全做法。它没有满足《JavaScript 与运行环境》要求的前提，因此先表现为“访问了 undefined 的属性”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《JavaScript 与运行环境》的问题，用可选链或先判空。

**验证**：先在《JavaScript 与运行环境》中记录“TypeError: Cannot read properties of undefined”留下的失败证据，再执行“用可选链或先判空”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：SyntaxError: Unexpected token

**症状**：在《JavaScript 与运行环境》的复现场景中，语法错误（常漏括号或逗号）。

**根因**：触发点是把“SyntaxError: Unexpected token”当成安全做法。它没有满足《JavaScript 与运行环境》要求的前提，因此先表现为“语法错误（常漏括号或逗号）”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《JavaScript 与运行环境》的问题，看行号，检查上一行是否完整。

**验证**：先在《JavaScript 与运行环境》中记录“SyntaxError: Unexpected token”留下的失败证据，再执行“看行号，检查上一行是否完整”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 关联 | 《变量、类型与类型转换》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《JavaScript DOM 入门》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《变量、类型与类型转换》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「JavaScript 与运行环境」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《JavaScript 与运行环境》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

下面哪项是浏览器提供、Node.js 没有的能力？

A. 数组方法
B. 闭包
C. Promise
D. DOM 操作

**参考答案**：DOM 操作

**解析**：作答时，先用JavaScript建立输入与输出的基线，再把DOM 操作代入边界条件核对，结论才能复现。这道题的关键在「JavaScript 与运行环境」的JavaScript、Node、浏览器：先确认题干“下面哪项是浏览器提供、Node.js”问的是哪一步，再排除偷换前提的选项。

### 自测 2

阅读「JavaScript 与运行环境」正文里的这段 JavaScript 代码，下面哪一项判断是正确的？

```javascript
// 浏览器控制台或 Node 里都能运行
console.log("Hello, World!");   // 打印到控制台

const name = "小明";             // 常量，不能重新赋值
let age = 18;                   // 变量，可以改
age = age + 1;                  // 重新赋值

console.log(`你好，${name}，明年 ${age} 岁`);
```

A. 这段代码只做静态声明，没有循环、分支或可观察输出。
B. 这段代码包含循环结构，同一段逻辑会被重复执行。
C. 这段代码会产生可观察的输出，运行后能看到结果。
D. 这段代码会读取外部输入，结果依赖传入的数据。

**参考答案**：这段代码会产生可观察的输出，运行后能看到结果。

**解析**：在「JavaScript 与运行环境」里，这段代码会产生可观察的输出，运行后能看到结果。这段代码出自「JavaScript 与运行环境」的正文示例，围绕JavaScript、Node、浏览器展开；把输入或边界换成空值、极值或失败情况后，结论要以「JavaScript 与运行环境」的实际运行结果为准。

### 自测 3

围绕“JavaScript 与运行环境”中的 JavaScript、Node、浏览器，下列哪两项是本课强调的实践判断？

A. 只要 JavaScript 的常规示例通过，就可以跳过边界与异常路径
B. 验证 Node 时要固定版本并覆盖边界输入，结论才可复现
C. 把 Node 的单次运行结果当成所有版本和规模都成立
D. 学习 JavaScript 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 Node 时要固定版本并覆盖边界输入，结论才可复现；学习 JavaScript 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：结论应落在验证 Node 时要固定版本并覆盖边界输入。本课把JavaScript 与运行环境拆成概念、示例与故障现场三部分，因此判断 JavaScript 时必须同时交代输入、输出和失败路径，这使“学习 JavaScript 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在JavaScript 与运行环境里，判断 Node 时要固定版本与边界输入，所以“验证 Node 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 能说清浏览器与 Node 各自提供什么能力。
- [ ] 知道 `defer` 与 `async` 的差别和使用场景。
- [ ] 会用 `console.table`、`console.time`、`debugger` 调试。
- [ ] 遇到 `undefined` 报错先查取值链上的空值。
- [ ] 前端代码使用 ESM 导入，不混用 `require`。

**教材衔接：动手练习**

> 本课练习重点：围绕「JavaScript、Node、浏览器」完成复述、实验和交付，每个结果都要能被别人检查。

先复现 Node 的时序问题，再引入取消或超时机制。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. JavaScript 与运行环境解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Node」是什么关系？

验收标准：用自己的话解释 JavaScript，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「JavaScript 是什么」小节做一次五步记录，原例取自 JavaScript，改动只允许动一处JavaScript，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

在浏览器控制台或 Node.js 中写一个 JavaScript 的最小示例，列出 3 组输入输出。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「JavaScript」和「Node」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```javascript
console.log('Hello, JavaScript!');
console.warn('警告');
console.error('错误');
console.table([{ a: 1 }, { a: 2 }]);   // 以表格展示
```

**预期输出**：Hello, JavaScript!

### 任务 2：只改一个条件

把「JavaScript 与运行环境」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 Node 换成边界值，其他输入保持原样。
- 预测：先写下「JavaScript 与运行环境」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响JavaScript。

### 任务 3：迁移到自己的数据

换一个 Node 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「下面哪项是浏览器提供、Node.js 没有的能力？」的判断依据。
- [ ] 不看解析，能说出「<script defer> 的作用是？」的判断依据。
- [ ] 不看解析，能说出「ECMAScript 指的是？」的判断依据。
- [ ] 不看解析，能说出「let、const 与 var 的作用域区别是？」的判断依据。
- [ ] 不看解析，能说出「"use strict" 严格模式的主要作用是？」的判断依据。
- [ ] 至少运行一次 JavaScript 的示例，记录输入、输出和 JavaScript 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `JavaScript` | JavaScript 是动态类型、基于原型的脚本语言，标准名为 ECMAScript。它既能跑在浏览器里操作页面，也能通过 Node.js 写服务端、命令行和桌面应用。 |
| `浏览器` | 解析 HTML/CSS、执行 JavaScript 并管理网络与页面的客户端环境。 |
| `事件循环` | 先执行同步代码与微任务，再取宏任务，它决定了 setTimeout 与 Promise 的执行顺序。 |
| `严格模式` | 用 use strict 或在 ES 模块中默认启用，禁止隐式全局变量与部分静默失败的行为。 |

## 考点精讲

### 考点 1：概念判断·JavaScript

- **题目**：下面哪项是浏览器提供、Node.js 没有的能力？
- **判断依据**：作答时，先用JavaScript建立输入与输出的基线，再把DOM 操作代入边界条件核对，结论才能复现。这道题的关键在「JavaScript 与运行环境」的JavaScript、Node、浏览器：先确认题干“下面哪项是浏览器提供、Node.js”问的是哪一步，再排除偷换前提的选项。

### 考点 2：概念判断·JavaScript

- **题目**：<script defer> 的作用是？
- **判断依据**：在「JavaScript 与运行环境」里，HTML 解析完成后再执行脚本。defer 让脚本异步下载并在文档解析完成后按顺序执行，避免阻塞首屏渲染。回到「JavaScript 与运行环境」的正文示例，用“<script defer 的作用是”走一遍JavaScript、Node、浏览器的完整流程，能复现的结论才可以保留。

### 考点 3：代码补全·JavaScript

- **题目**：阅读「JavaScript 与运行环境」正文里的这段 JavaScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「JavaScript 与运行环境」里，这段代码会产生可观察的输出，运行后能看到结果。这段代码出自「JavaScript 与运行环境」的正文示例，围绕JavaScript、Node、浏览器展开；把输入或边界换成空值、极值或失败情况后，结论要以「JavaScript 与运行环境」的实际运行结果为准。

### 考点 4：多选辨析·JavaScript

- **题目**：围绕“JavaScript 与运行环境”中的 JavaScript、Node、浏览器，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在验证 Node 时要固定版本并覆盖边界输入。本课把JavaScript 与运行环境拆成概念、示例与故障现场三部分，因此判断 JavaScript 时必须同时交代输入、输出和失败路径，这使“学习 JavaScript 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在JavaScript 与运行环境里，判断 Node 时要固定版本与边界输入，所以“验证 Node 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 5：概念判断·JavaScript

- **题目**："use strict" 严格模式的主要作用是？
- **判断依据**：在「JavaScript 与运行环境」里，把未声明就赋值等静默错误改为直接抛错。ES Module 与 class 内部默认就是严格模式，因此现代代码很少手写它。把“把未声明就赋值等静默错误改为直接抛错”代回「JavaScript 与运行环境」里“"use strict" 严格模式的主要作用是”的例子核对，条件一旦改变，结论就要用JavaScript、Node、浏览器重新推导。

### 考点 6：填空·JavaScript

- **题目**：补全代码：「JavaScript 与运行环境」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const name = (await rl.____("请输入姓名：")).trim;`
- **判断依据**：是合法的，但 arr = [] 会报错。这道题的关键在「JavaScript 与运行环境」的JavaScript、Node、浏览器：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。把“question”代回「JavaScript 与运行环境」里“JavaScript 与运行环境示例中”的例子核对，条件一旦改变，结论就要用JavaScript、Node、浏览器重新推导。

## English Overview

**Title:** JavaScript & Runtimes

**Summary:** Browser vs Node, running code, strict mode and tooling.

**Category:** JavaScript
**Level:** 基础
**Key terms:** JavaScript, Node, 浏览器, console, ECMAScript

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Node.js 22+ / 现代浏览器
；本课聚焦 JavaScript。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：JavaScript、Node、浏览器、console、ECMAScript
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**JavaScript & Runtimes** focuses on Browser vs Node, running code, strict mode and tooling.

### Learning Outcomes

- Explain what **JavaScript & Runtimes** solves and when it should be used.

### Glossary

- Topic: **JavaScript & Runtimes**
- Related terms: JavaScript, Node, 浏览器, console

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| JavaScript 是什么 | JavaScript 是什么 |
| 两种运行环境 | 两种运行环境 |
| 运行方式 | 运行方式 |
| 严格模式 | 严格模式 |
| 代码质量工具 | 代码质量Tools |
| 本课小结 | Summary |
| 运行环境速查 | 运行环境速查 |
| 控制台速查 | 控制台速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [ECMAScript 标准](https://tc39.es/ecma262/) | JavaScript 语言标准 |
| [Node.js 文档](https://nodejs.org/docs/latest/api/) | 服务端运行时与模块 |
| [MDN JavaScript 指南](https://developer.mozilla.org/docs/Web/JavaScript/Guide) | 语言基础与浏览器 API |

> 「JavaScript 与运行环境」的链接用于离线阅读后的延伸核对；App 不会自动联网。
