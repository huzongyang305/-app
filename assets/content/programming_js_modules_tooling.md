# 模块化与工程化

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![ES Module 与 CommonJS 对照](images/diagram_js_modules.webp)

![模块化与工程化](images/remaining_js_modules_tooling.webp)

## 本节知识框架

**课程定位**：所属分类 `javascript`（JavaScript），课程主题 `模块化与工程化`，学习阶段 进阶，建议用时 50 分钟。

本课主线：ES Module、CommonJS、npm 与 package.json、常见构建工具。

**学完本课应当能够**
- 说清 `this` 与 `.mjs` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `ESM` 的行为，记录输入、输出与失败条件。
- 遇到「混用 `require` 与 `import`」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `this`：先掌握 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking），再用它解释 `.mjs` 为什么会出现。
2. `.mjs`：先掌握 Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM，再用它解释 `ESM` 为什么会出现。
3. `ESM`：先掌握 ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出，再用它解释 `具名导出与默认导出` 为什么会出现。
4. `具名导出与默认导出`：先掌握 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「JavaScript」分类的第 15 课。先修内容：《错误处理与调试》。《错误处理与调试》里的 `异常`、`try` 是本课的前提。相关或后续课程：《实战：Vite + React 待办应用》。

### 完成判据

- **定义关**：不看正文也能说明 `this` 是 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking），并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `模块化与工程化`，而不是只背结论。
- **示例关**：能运行或推演 `模块化与工程化` 的 `javascript` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `模块化与工程化` 示例里的 调用了 `add()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 混用 `require` 与 `import`，记录现象并按 统一 ESM 修复。
- **迁移关**：能把 `ESM`、`import`、`export`、`npm` 放进一个与 `模块化与工程化` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `模块化与工程化` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| this | 模块特性：自动严格模式、顶层 this 是 undefined、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。 | 静态检查只在编译期成立，运行期输入仍需校验。 |
| .mjs | Node 中 .mjs 或 package.json 里的 "type": "module" 表示使用 ESM；新项目一律优先 ESM。 | 易错：未声明 ESM；正确做法是加 `"type": "module"` 或用 `.mjs`。 |
| ESM | ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出。 | 易错：运行时报错；正确做法是统一 ESM。 |
| 具名导出与默认导出 | 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错。 | 只在「具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错」这一前提下成立，换输入或换环境要重新验证。 |

## 原理与运行机制

### 机制总览

**教材衔接：常见工具链**

| 工具 | 作用 |
| --- | --- |
| Vite / Webpack / esbuild | 打包与开发服务器 |
| Babel | 把新语法降级为旧浏览器可运行代码 |
| TypeScript | 给 JS 加静态类型 |
| ESLint / Prettier | 代码检查与格式化 |
| Vitest / Jest | 单元测试 |

**教材衔接：依赖与打包的实践要点**

| 场景 | 做法 |
| --- | --- |
| 区分依赖类型 | 运行时依赖放 dependencies，构建/测试工具放 devDependencies |
| 锁定版本 | 提交 lock 文件；CI 用 `npm ci` 而不是 `npm install` |
| 减少体积 | 按需引入（`import { x } from 'lib'`）、用打包分析器找大依赖、优先 ESM 以便 tree-shaking |
| 代码分割 | 路由级动态 `import()` 拆包，首屏只加载必要代码 |
| 兼容旧浏览器 | 由构建工具按 browserslist 生成 polyfill，而不是全量引入 |
| 供应链安全 | 定期 `npm audit`、锁定版本、谨慎新增依赖 |

常见坑：① 直接依赖与传递依赖版本冲突导致"本地能跑、CI 报错"（用 lock 文件与同一 Node 版本解决）；② 循环依赖使模块导出为 undefined（重构拆分或用延迟引用）；③ ESM 与 CommonJS 混用出现 `require is not defined`（检查 package.json 的 type 与构建输出格式）；④ 只在开发环境生效的 `process.env` 变量在生产未注入，导致运行时报错。

**教材衔接：package.json 关键字段速查**

| 字段 | 作用 | 示例 |
| --- | --- | --- |
| `type` | 决定 `.js` 按哪种模块解析 | `"type": "module"` |
| `main` | CommonJS 入口 | `"main": "./dist/index.cjs"` |
| `module` | ESM 入口（打包器识别） | `"module": "./dist/index.js"` |
| `exports` | 条件导出，控制外部可访问路径 | `"exports": { ".": { "import": "./esm/index.js" } }` |
| `scripts` | 常用命令 | `"test": "vitest run"` |
| `dependencies` | 运行时依赖 | 生产必需 |
| `devDependencies` | 开发依赖 | 测试、构建工具 |
| `engines` | 声明 Node 版本要求 | `"node": ">=20"` |
| `packageManager` | 锁定包管理器版本 | `"pnpm@9.0.0"` |

版本范围速查：

| 写法 | 允许升级范围 |
| --- | --- |
| `1.2.3` | 精确锁定 |
| `~1.2.3` | 补丁位可变（1.2.x） |
| `^1.2.3` | 主版本不变（1.x.x） |
| `>=1.2.3 <2` | 区间 |
| `*` 或 `latest` | 任意，禁止在生产使用 |

**教材衔接：版本与时效**

- devDependencies 依赖的新 API 必须有降级路径，否则老环境直接报错。
- 升级前确认 ESM 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 devDependencies 记录构建与运行结果。
- 回归范围锁定 devDependencies 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 ESM 的版本变化。

### 机制拆解：每一步的输入、动作与输出

#### 1. `this`
- 输入：`ESM`；本步把 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking） 当作判断规则。
- 动作：围绕 `this` 保留中间状态，并记录它与 `.mjs` 的对应关系。
- 输出：`.mjs`，它可以被下一段代码、测试或记录继续使用。
- `this` 的失败条件：静态检查只在编译期成立，运行期输入仍需校验。

#### 2. `.mjs`
- 输入：`this`；本步把 Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM 当作判断规则。
- 动作：围绕 `.mjs` 保留中间状态，并记录它与 `ESM` 的对应关系。
- 输出：`ESM`，它可以被下一段代码、测试或记录继续使用。
- `.mjs` 的失败条件：当`Cannot use import statement outside a module`时，会出现未声明 ESM。

#### 3. `ESM`
- 输入：`.mjs`；本步把 ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出 当作判断规则。
- 动作：围绕 `ESM` 保留中间状态，并记录它与 `具名导出与默认导出` 的对应关系。
- 输出：`具名导出与默认导出`，它可以被下一段代码、测试或记录继续使用。
- `ESM` 的失败条件：当混用 `require` 与 `import`时，会出现运行时报错。

#### 4. `具名导出与默认导出`
- 输入：`ESM`；本步把 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错 当作判断规则。
- 动作：围绕 `具名导出与默认导出` 保留中间状态，并记录它与 `add` 的对应关系。
- 输出：`add`，它可以被下一段代码、测试或记录继续使用。
- `具名导出与默认导出` 的失败条件：只在「具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错」这一前提下成立，换输入或换环境要重新验证。

### 示例中的可观察事实

1. 调用了 `add()`；它对应的课程主题是 `模块化与工程化`。
2. 调用了 `multiply()`；它对应的课程主题是 `模块化与工程化`。
3. 出现字面量 `./math.js`；它对应的课程主题是 `模块化与工程化`。
4. 出现字面量 `./heavy.js`；它对应的课程主题是 `模块化与工程化`。
5. 调用了 `require()`；它对应的课程主题是 `模块化与工程化`。
6. 出现字面量 `./math`；它对应的课程主题是 `模块化与工程化`。

### 复现实验记录

- 环境：`模块化与工程化` 使用 `javascript` 示例，固定 `ESM`、`import`、`export`、`npm` 作为第一组条件。
- 首轮输入：先确认 调用了 `add()`，预测 `this` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `ESM`，观察 `具名导出与默认导出` 是否仍满足定义。
- 失败注入：复现 混用 `require` 与 `import`，确认现象是 运行时报错。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `模块化与工程化` 时才能区分概念错误与实现错误。

## 典型应用场景

- **混用 `require` 与 `import`**：典型现象是运行时报错；正确做法是统一 ESM。
- **忘写扩展名**：典型现象是浏览器报找不到模块；正确做法是ESM 中写全 `.js`。
- **用相对路径跳太多层**：典型现象是难以维护；正确做法是配路径别名。
- **依赖装到 `dependencies`**：典型现象是包体积变大；正确做法是构建工具放 `devDependencies`。

### 最小验证场景

- 准备：保留 `javascript` 示例的原始输入，先记录 `模块化与工程化` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `add()`，再改变一个与 `this` 相关的条件。
- 判定：新结果与 `模块化与工程化` 的基线不同不等于错误；只有当差异破坏了 `this` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `this` 时，先满足它的定义：模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）；静态检查只在编译期成立，运行期输入仍需校验。
- 使用 `.mjs` 时，先满足它的定义：Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM；易错：未声明 ESM；正确做法是加 `"type": "module"` 或用 `.mjs`。
- 使用 `ESM` 时，先满足它的定义：ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出；易错：运行时报错；正确做法是统一 ESM。
- 使用 `具名导出与默认导出` 时，先满足它的定义：具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错；只在「具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错」这一前提下成立，换输入或换环境要重新验证。

## 代码/协议/SQL 示例

### 最小可验证示例

```javascript
// math.js
export const PI = 3.14;
export function add(a, b) { return a + b; }
export default function multiply(a, b) { return a * b; }

// main.js
import multiply, { PI, add as sum } from './math.js';
import * as math from './math.js';           // 命名空间导入

// 动态导入：按需加载，返回 Promise
const module = await import('./heavy.js');
```

**教材衔接：ES Module**

模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。

**教材衔接：CommonJS（Node 旧标准）**

```javascript
// 导出
module.exports = { add };
// 导入
const { add } = require('./math');
```

Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM。

**教材衔接：npm 与 package.json**

```bash
npm init -y
npm install lodash            # 生产依赖
npm install --save-dev vitest # 开发依赖
npm update
npm audit
npx vite                      # 执行本地依赖的命令
```

```json
{
  "name": "demo",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "test": "vitest",
    "build": "vite build"
  },
  "dependencies": { "lodash": "^4.17.21" },
  "devDependencies": { "vitest": "^2.0.0" }
}
```

语义化版本 `^4.17.21`：允许升级次版本与修订版本，不跨主版本。`package-lock.json` 必须提交，保证依赖可复现。

**教材衔接：模块语法速查**

| 目的 | ESM | CommonJS |
| --- | --- | --- |
| 导出命名 | `export const a = 1;` | `module.exports.a = 1;` |
| 导出默认 | `export default fn;` | `module.exports = fn;` |
| 导入命名 | `import { a } from "./m.js";` | `const { a } = require("./m");` |
| 导入默认 | `import fn from "./m.js";` | `const fn = require("./m");` |
| 全部导入 | `import * as ns from "./m.js";` | `const ns = require("./m");` |
| 只导入类型 | `import type { T } from "./t.js";` | 不适用 |
| 动态导入 | `const m = await import("./m.js");` | `require()` 本身即动态 |
| 加载时机 | 静态分析、可 tree shaking | 运行时解析 |
| 顶层 await | 支持 | 不支持 |

注意：浏览器里引用相对模块必须写扩展名（`./util.js`），Node 的 ESM 同样要求完整路径。

**教材衔接：常用命令速查**

| 目的 | 命令 |
| --- | --- |
| 安装依赖（严格按 lock） | `npm ci` |
| 新增依赖 | `npm install lodash` |
| 新增开发依赖 | `npm install -D vitest` |
| 运行脚本 | `npm run build` |
| 检查过期依赖 | `npm outdated` |
| 审计漏洞 | `npm audit --production` |
| 查看依赖树 | `npm ls --depth=0` |
| 清理重装 | `rm -rf node_modules package-lock.json && npm install` |

**教材衔接：零基础详解：模块与工具链**

### 一句话说清它是什么

模块解决「代码怎么拆、怎么互相引用」，工具链解决「代码怎么写、怎么打包、怎么发布」。
现在的主流组合是：**ESM 语法 + 包管理器 + 打包器 + 代码检查**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 模块 | 独立房间 | 各自有进出口，互不打扰 |
| `export` | 出口 | 明确对外提供什么 |
| `import` | 进口 | 用多少引多少 |
| 包管理器 | 仓库 | 下载与管理第三方依赖 |
| 打包器 | 打包流水线 | 合并、压缩、拆分产物 |
| Linter | 质检员 | 提前发现可疑写法 |

### ESM 的四种导入导出

```javascript
// math.js —— 具名导出
export const PI = 3.14159;
export function add(a, b) { return a + b; }
export default function multiply(a, b) { return a * b; }

// main.js —— 具名导入
import { PI, add } from "./math.js";
import multiply from "./math.js";                 // 默认导入
import * as math from "./math.js";                // 整体导入
import { add as sum } from "./math.js";           // 改名
import "./setup.js";                              // 只执行副作用
```

| 对比 | 具名导出 | 默认导出 |
| --- | --- | --- |
| 数量 | 可以有多个 | 一个模块只能一个 |
| 导入名字 | 必须对应，可以改名 | 可以随意命名 |
| 工具支持 | 静态分析更好，利于 tree shaking | 稍差 |
| 建议 | **优先具名** | 只在单一主体时使用 |

### CommonJS 与 ESM 的差异

| 对比 | CommonJS（require） | ESM（import） |
| --- | --- | --- |
| 环境 | Node 传统写法 | 浏览器与 Node 现代写法 |
| 加载时机 | 运行时 | 编译期确定依赖 |
| 是否可动态 | `require` 可条件调用 | 用 `import()` 动态导入 |
| Tree shaking | 差 | 好 |
| 新项目建议 | 少用 | **首选** |

```javascript
// 动态导入：按需加载，减小首屏体积
button.addEventListener("click", async () => {
  const { openDialog } = await import("./dialog.js");
  openDialog();
});
```

### package.json 关键字段

```json
{
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc --noEmit && vite build",
    "lint": "eslint .",
    "test": "vitest run"
  },
  "dependencies": { "react": "^19.0.0" },
  "devDependencies": { "vite": "^7.0.0", "typescript": "^5.6.0" }
}
```

| 字段 | 作用 |
| --- | --- |
| `type: module` | 让 `.js` 按 ESM 解析 |
| `dependencies` | 运行时需要 |
| `devDependencies` | 只在开发或构建时需要 |
| `scripts` | 统一命令入口，避免各人敲不同命令 |
| `exports` / `main` / `module` | 发布库时告诉外界入口在哪 |

### 一条常见流水线

```bash
npm ci          # 按 lockfile 精确安装，CI 用这个
npm run lint    # 静态检查
npm test        # 单元测试
npm run build   # 类型检查 + 打包
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 混用 `require` 与 `import` | 运行时报错 | 统一 ESM |
| 忘写扩展名 | 浏览器报找不到模块 | ESM 中写全 `.js` |
| 用相对路径跳太多层 | 难以维护 | 配路径别名 |
| 依赖装到 `dependencies` | 包体积变大 | 构建工具放 `devDependencies` |
| 忽略 lockfile | 不同机器装出不同版本 | 提交并 CI 用 `npm ci` |
| 循环依赖 | 拿到 undefined | 抽出公共模块打破环 |
| 全量引入大库 | 首屏变慢 | 按需导入或动态导入 |
| 生产公开 source map | 源码泄露 | 只上传到错误监控平台 |

### 手把手练习：拆分一个小项目

```text
src/
  main.js          入口：只负责组装
  api/user.js      数据访问
  utils/format.js  纯函数
  ui/list.js       渲染
```

```javascript
// utils/format.js
export const formatName = (user) => `${user.last}${user.first}`;

// api/user.js
export async function fetchUsers() {
  const res = await fetch("/api/users");
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// ui/list.js
import { formatName } from "../utils/format.js";

export function renderUsers(container, users) {
  container.replaceChildren(
    ...users.map((u) => {
      const li = document.createElement("li");
      li.textContent = formatName(u);
      return li;
    }),
  );
}

// main.js
import { fetchUsers } from "./api/user.js";
import { renderUsers } from "./ui/list.js";

const list = document.querySelector("#users");
fetchUsers()
  .then((users) => renderUsers(list, users))
  .catch((error) => console.error("加载失败：", error));
```

### 学完自测

- [ ] 能说出具名导出与默认导出的区别。
- [ ] 知道 ESM 与 CommonJS 的三个差异。
- [ ] 能说出 `dependencies` 与 `devDependencies` 的划分依据。
- [ ] 知道动态 `import()` 能带来什么好处。
- [ ] 能在 CI 里按 lint、test、build 顺序跑完整流水线。

**运行方式**：运行 `模块化与工程化` 的示例时，保存为 `.js` 后用 `node 文件名.js` 运行；涉及浏览器 API 的示例要放到页面里执行。

### 示例精读：先找证据，再改一个条件

1. 调用了 `add()`；它出现在 `模块化与工程化` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `multiply()`；它出现在 `模块化与工程化` 的示例中，阅读时先确认它前后各发生了什么。
3. 出现字面量 `./math.js`；它出现在 `模块化与工程化` 的示例中，阅读时先确认它前后各发生了什么。
4. 出现字面量 `./heavy.js`；它出现在 `模块化与工程化` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `require()`；它出现在 `模块化与工程化` 的示例中，阅读时先确认它前后各发生了什么。
6. 出现字面量 `./math`；它出现在 `模块化与工程化` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `模块化与工程化` 中与 `this` 对照：示例必须能支持 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking），否则说明这一段还缺少实现或验证步骤。
- 在 `模块化与工程化` 中与 `.mjs` 对照：示例必须能支持 Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM，否则说明这一段还缺少实现或验证步骤。
- 在 `模块化与工程化` 中与 `ESM` 对照：示例必须能支持 ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出，否则说明这一段还缺少实现或验证步骤。
- 在 `模块化与工程化` 中与 `具名导出与默认导出` 对照：示例必须能支持 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（模块化与工程化）**：事件循环与 DOM 操作是瓶颈来源：记录脚本执行时间、长任务与主线程阻塞时长。

**测量方法**：以 `模块化与工程化` 的 `ESM` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `模块化与工程化` 的 `ESM`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `模块化与工程化` 的 `import`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `模块化与工程化` 的 `export`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `模块化与工程化` 的 `npm`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `模块化与工程化` 的 `package.json`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `模块化与工程化` 中 `this` 的边界：静态检查只在编译期成立，运行期输入仍需校验。达到边界时不要外推，必须重新测量。
- `模块化与工程化` 中 `.mjs` 的边界：易错：未声明 ESM；正确做法是加 `"type": "module"` 或用 `.mjs`。达到边界时不要外推，必须重新测量。
- `模块化与工程化` 中 `ESM` 的边界：易错：运行时报错；正确做法是统一 ESM。达到边界时不要外推，必须重新测量。
- `模块化与工程化` 中 `具名导出与默认导出` 的边界：只在「具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `模块化与工程化` 的代码证据：先验证 调用了 `add()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 混用 `require` 与 `import` | 运行时报错 | 统一 ESM |
| 忘写扩展名 | 浏览器报找不到模块 | ESM 中写全 `.js` |
| 用相对路径跳太多层 | 难以维护 | 配路径别名 |
| 依赖装到 `dependencies` | 包体积变大 | 构建工具放 `devDependencies` |
| 忽略 lockfile | 不同机器装出不同版本 | 提交并 CI 用 `npm ci` |
| 循环依赖 | 拿到 undefined | 抽出公共模块打破环 |
| 全量引入大库 | 首屏变慢 | 按需导入或动态导入 |
| 生产公开 source map | 源码泄露 | 只上传到错误监控平台 |
| `Cannot use import statement outside a module` | 未声明 ESM | 加 `"type": "module"` 或用 `.mjs` |
| `require is not defined` | 浏览器环境无 CommonJS | 改用 `import` |
| `ERR_MODULE_NOT_FOUND` | 相对路径缺少扩展名 | Node ESM 写完整文件名 |
| 循环导入导致某个值为 `undefined` | 模块互相依赖 | 抽出公共模块，或用动态 `import` 延迟加载 |
| 依赖版本在不同机器不一致 | 没提交 lock 文件 | 提交 `package-lock.json` / `pnpm-lock.yaml` |
| `npm install` 结果与 CI 不同 | install 会更新版本 | CI 用 `npm ci` |
| 把构建工具放进 `dependencies` | 生产镜像体积变大 | 移到 `devDependencies` |
| 导入整个工具库只用其中一个函数 | 打包体积暴涨 | 按需导入或用支持 tree shaking 的库 |
| 打包后 `process.env` 为 `undefined` | 环境变量未注入 | 在构建配置里定义（如 Vite 的 `define`） |
| 本地能用、线上报路径错误 | `base` 或 `publicPath` 未配置 | 配置部署子路径 |
| Cannot use import statement outside a module | 未声明 ESM。 | 加 "type": "module" 或用 .mjs。 |
| require is not defined | 浏览器环境无 CommonJS。 | 改用 import。 |
| ERR_MODULE_NOT_FOUND | 相对路径缺少扩展名。 | Node ESM 写完整文件名。 |

### 现场 1：混用 `require` 与 `import`

**症状**：运行时报错。

**根因与修复**：统一 ESM。

**自检**：在本课示例里复现「混用 `require` 与 `import`」，改成统一 ESM后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：忘写扩展名

**症状**：浏览器报找不到模块。

**根因与修复**：ESM 中写全 `.js`。

**自检**：在本课示例里复现「忘写扩展名」，改成ESM 中写全 `.js`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：用相对路径跳太多层

**症状**：难以维护。

**根因与修复**：配路径别名。

**自检**：在本课示例里复现「用相对路径跳太多层」，改成配路径别名后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：依赖装到 `dependencies`

**症状**：包体积变大。

**根因与修复**：构建工具放 `devDependencies`。

**自检**：在本课示例里复现「依赖装到 `dependencies`」，改成构建工具放 `devDependencies`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：忽略 lockfile

**症状**：不同机器装出不同版本。

**根因与修复**：提交并 CI 用 `npm ci`。

**自检**：在本课示例里复现「忽略 lockfile」，改成提交并 CI 用 `npm ci`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：循环依赖

**症状**：拿到 undefined。

**根因与修复**：抽出公共模块打破环。

**自检**：在本课示例里复现「循环依赖」，改成抽出公共模块打破环后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：全量引入大库

**症状**：首屏变慢。

**根因与修复**：按需导入或动态导入。

**自检**：在本课示例里复现「全量引入大库」，改成按需导入或动态导入后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：生产公开 source map

**症状**：源码泄露。

**根因与修复**：只上传到错误监控平台。

**自检**：在本课示例里复现「生产公开 source map」，改成只上传到错误监控平台后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`Cannot use import statement outside a module`

**症状**：未声明 ESM。

**根因与修复**：加 `"type": "module"` 或用 `.mjs`。

**自检**：在本课示例里复现「`Cannot use import statement outside a module`」，改成加 `"type": "module"` 或用 `.mjs`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`错误处理与调试`。本课默认这些内容已经掌握。
- **相关或后续**：`实战：Vite + React 待办应用`。本课术语会在这些课程里继续使用。
- **术语归属**：`this`、`.mjs`、`ESM` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《实战：Vite + React 待办应用》也涉及 `Vite`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `错误处理与调试`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `实战：Vite + React 待办应用`：共同关键词 `Vite`。

### 容易混淆的相邻概念

- `this` 与 `.mjs`：前者强调 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）；后者强调 Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `.mjs` 与 `ESM`：前者强调 Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM；后者强调 ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `ESM` 与 `具名导出与默认导出`：前者强调 ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出；后者强调 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `this` 的操作性定义，并说明它与 `.mjs` 的区别。

**参考答案**：模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。

`.mjs` 的定位是：Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「混用 `require` 与 `import`」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是运行时报错；正确做法是统一 ESM。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `javascript` 示例，把其中的 `'./math.js'` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `javascript` 示例应当复现正文给出的结果；把 `'./math.js'` 换成边界值后，如果结果改变或报错，先核对它是否满足 `模块化与工程化` 中`this` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `javascript` 示例，说明它体现了`this` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`this` 的定义是 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking），示例正是在实现这条定义。改动与 `this` 有关的一个输入后，如果结果不再符合 `模块化与工程化` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `模块化与工程化` 的方法迁移到自己的项目：围绕 `this` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「ERR_MODULE_NOT_FOUND」，它会导致相对路径缺少扩展名；检验方式是按Node ESM 写完整文件名改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `this` 与 `.mjs`：各写一行适用场景、一行失败表现。

**参考答案**：`this` 的定义是模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）；`.mjs` 的定义是Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「混用 `require` 与 `import`」引发的问题，请把“复现 运行时报错 → 保留证据 → 统一 ESM → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按运行时报错复现；第二步记录输入、版本与完整报错；第三步按统一 ESM只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `具名导出与默认导出`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：只在「具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错」这一前提下成立，换输入或换环境要重新验证。 同时要把 `具名导出与默认导出` 的定义 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `this` → `.mjs` → `ESM` → `具名导出与默认导出` 的作用链。

**参考答案**：起点是 `this` 的定义 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）；中间每一步都保留可观察状态；终点由 `具名导出与默认导出` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `模块化与工程化` 中，现象是 相对路径缺少扩展名。请围绕 ERR_MODULE_NOT_FOUND 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 ERR_MODULE_NOT_FOUND，记录输入与完整错误；再按 Node ESM 写完整文件名 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `模块化与工程化`：先给主问题，再按顺序说出 `this`、`.mjs`、`ESM`、`具名导出与默认导出`，最后给一个失败案例。

**自评标准**：主问题必须对应 ES Module、CommonJS、npm 与 package.json、常见构建工具；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `this` | 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。 |
| `.mjs` | Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM。 |
| `ESM` | ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出。 |
| `具名导出与默认导出` | 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错。 |

**术语关系**：`this`（模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）） → `.mjs`（Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM） → `ESM`（ECMAScript 模块：用 import/export 静态声明依赖） → `具名导出与默认导出`（具名导出要用同名导入）。

## 考点精讲

`模块化与工程化` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：导出模块默认值的语法是？
- **正确项**：export default function {}
- **判断依据**：这道题检验本课主问题：ES Module、CommonJS、npm 与 package.json、常见构建工具。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 2：第 2 题

- **题目**：package-lock.json 的主要作用是？
- **正确项**：锁定依赖的确切版本
- **判断依据**：这道题检验本课主问题：ES Module、CommonJS、npm 与 package.json、常见构建工具。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 3：第 3 题

- **题目**：版本号 ^4.17.21 表示允许升级到？
- **正确项**：4.x.x 的最新版
- **判断依据**：这道题检验本课主问题：ES Module、CommonJS、npm 与 package.json、常见构建工具。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 4：第 4 题

- **题目**：围绕“模块化与工程化”中的 ESM、import、export，下列哪两项是本课强调的实践判断？
- **正确项**：验证 import 时要固定版本并覆盖边界输入，结论才可复现；学习 ESM 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `ESM` 上：ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出。复习时把 `ESM` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：下面这段 `javascript` 代码来自 `模块化与工程化`。课程主线是ES Module、CommonJS、npm 与 package.json、常见构建工具。代码与 `this` 有关。哪一项是代码里真实出现的内容？
- **正确项**：出现字面量 `./heavy.js`
- **判断依据**：这道题落在术语 `this` 上：模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。复习时把 `this` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `ES Module、CommonJS、npm 与 package.json、常见构建工具。`，这段说明是：模块特性：自动严格模式、顶层 ``____`` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。空缺处应填哪个术语？
- **正确项**：this
- **判断依据**：这道题落在术语 `this` 上：模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。复习时把 `this` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`this`

- **要点**：模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）。
- **this 的边界**：静态检查只在编译期成立，运行期输入仍需校验。

### 考点 8：`.mjs`

- **要点**：Node 中 `.mjs` 或 `package.json` 里的 `"type": "module"` 表示使用 ESM；新项目一律优先 ESM。
- **.mjs 的边界**：易错：未声明 ESM；正确做法是加 `"type": "module"` 或用 `.mjs`。

### 考点 9：`ESM`

- **要点**：ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出。
- **ESM 的边界**：易错：运行时报错；正确做法是统一 ESM。

### 考点 10：`具名导出与默认导出`

- **要点**：具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错。
- **具名导出与默认导出 的边界**：只在「具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错」这一前提下成立，换输入或换环境要重新验证。

### 考点 11：排错——混用 `require` 与 `import`

- **现象**：运行时报错。
- **处理**：统一 ESM。

### 考点 12：排错——忘写扩展名

- **现象**：浏览器报找不到模块。
- **处理**：ESM 中写全 `.js`。

### 考点 13：综合辨析——`this` 与 `具名导出与默认导出`

- **辨析点**：`this` 的定义是 模块特性：自动严格模式、顶层 `this` 是 `undefined`、同一模块只执行一次、静态分析可做摇树优化（tree shaking）；`具名导出与默认导出` 的定义是 具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错。
- **答题要求**：面对 `模块化与工程化` 的题目，先判断描述的是 `this` 还是 `具名导出与默认导出`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 运行时报错，而不是只写“程序有错”。
- **证据分**：保留触发 混用 `require` 与 `import` 的输入、版本和错误原文。
- **修复分**：按 统一 ESM 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Node.js 22+ / 现代浏览器
；本课聚焦 ESM。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：ESM、import、export、npm、package.json、Vite
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：ESM、import、export、npm、package.json、Vite。

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN 模块](https://developer.mozilla.org/docs/Web/JavaScript/Guide/Modules) | ES Module 与依赖组织 |
| [npm 文档](https://docs.npmjs.com/) | 包管理与发布 |
| [MDN Promise](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Promise) | Promise 与异步链 |

| [本课术语索引：模块化与工程化](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「模块化与工程化」的链接用于离线阅读后的延伸核对；App 不会自动联网。