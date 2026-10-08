# TypeScript 构建工具链与测试

![构建工具与测试工具的分工](images/diagram_ts_build_test.webp)

![TypeScript 构建工具链与测试](images/remaining_ts_build_test.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：45 分钟

## 本节知识框架

**课程定位**：所属分类为「TypeScript」，课程主题为「TypeScript 构建工具链与测试」，学习阶段为「基础」，建议用时 45 分钟。

**本课要解决的主问题**：tsc/tsup/Vite 选型、双格式产物与 vitest 测试。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「TypeScript 构建工具链与测试」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「TypeScript 构建工具链与测试」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「TypeScript」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：没有硬性先修课；仍建议先具备本分类的基础阅读与操作能力。

**学习位置**：本课位于《TypeScript 工程配置与实践》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《TypeScript 类型收窄与泛型》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释TypeScript 构建工具链与测试解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「tsup」、「Vite」、「vitest」 之间的关系，并分别举出一个例子。
- 能把 TypeScript 放回「TypeScript 构建工具链与测试」的知识体系，说明它和 tsup 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：tsc/tsup/Vite 选型、双格式产物与 vitest 测试。

**教材衔接：前置知识**

- 先完成上一课《TypeScript 进阶类型与框架实践》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议先掌握同一分类的基础课程，并能独立运行正文里的 prepublishOnly 示例。
- 开始前先复习：TypeScript、tsup、Vite。
- 卡在 TypeScript 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

TypeScript 工具链的核心原则：**类型检查与打包分离、产物格式与运行时对齐、类型行为也要测试**。

## 核心概念定义

> 阅读约定：本课先给「TypeScript 构建工具链与测试」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| TypeScript | 在 JavaScript 上增加静态类型系统的语言，编译后可运行在浏览器或 Node.js。 | 仅在「TypeScript 构建工具链与测试」明确给出的输入、版本与资源条件下成立。 |
| tsup | 库项目常见组合：tsup 产出 dist/index.mjs 与 dist/index.cjs + tsc 生成 .d.ts，并在 package.json 用 exports 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。 | 仅在「TypeScript 构建工具链与测试」明确给出的输入、版本与资源条件下成立。 |
| Vite | 现代前端构建工具：开发时用原生 ESM 按需编译并热更新，打包时用 Rollup 产出静态资源。 | 仅在「TypeScript 构建工具链与测试」明确给出的输入、版本与资源条件下成立。 |
| 转译与类型检查分离 | esbuild、swc 只做语法转换，类型错误要靠 tsc --noEmit 单独把关。 | 仅在「TypeScript 构建工具链与测试」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「TypeScript 构建工具链与测试」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：类型也要测**

| 手段 | 用途 |
| --- | --- |
| `tsc --noEmit` | 全量类型检查，进 CI |
| tsd / expect-type | 断言类型行为（如 Omit 是否正确） |
| ESLint + typescript-eslint | 禁 any、要求显式返回类型、限制浮空 Promise |

`@typescript-eslint/no-floating-promises` 能拦掉大量异步漏 await 的 bug，值得开启。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「TypeScript」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「tsup」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「Vite」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「TypeScript 构建工具链与测试」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | TypeScript | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | tsup | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | Vite | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「TypeScript 构建工具链与测试」自己的示例验证。「TypeScript 构建工具链与测试」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：工具选型**

| 工具 | 定位 |
| --- | --- |
| tsc | 类型检查与生成 d.ts（不做打包优化） |
| Vite | 前端开发服务器与生产打包 |
| tsup / esbuild | 库打包，速度快，可同时产出 ESM/CJS |
| swc | 极快的转译器，常用于替代 Babel |
| unbuild / rollup | 库产物与 tree-shaking 更可控 |

库项目常见组合：tsup 产出 `dist/index.mjs` 与 `dist/index.cjs` + tsc 生成 `.d.ts`，并在 package.json 用 `exports` 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。

**教材衔接：tsconfig 与产物一致**

`module`/`moduleResolution` 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）；`target` 决定语法降级程度；库项目开启 `declaration` 与 `declarationMap` 方便跳转到源码。

**教材衔接：CI 基线**

顺序：`install → lint → tsc --noEmit → test --coverage → build`。构建产物要做体积检查（bundlesize/rollup-plugin-visualizer），防止依赖悄悄膨胀。

**教材衔接：常用 lint 规则速查**

| 规则 | 作用 |
| --- | --- |
| `no-floating-promises` | 禁止漏写 `await` 的 Promise |
| `no-misused-promises` | 禁止把 async 函数当同步回调传 |
| `await-thenable` | 只对 thenable 使用 await |
| `strict-boolean-expressions` | 禁止在条件里使用非布尔值 |
| `no-explicit-any` | 禁止显式 `any` |
| `consistent-type-imports` | 类型导入统一用 `import type` |
| `no-unnecessary-condition` | 找出永远为真/假的判断 |
| `switch-exhaustiveness-check` | 要求 switch 覆盖联合所有成员 |

**教材衔接：版本与时效**

- 版本提示：TypeScript 的行为在最近几个大版本里有过调整，升级「TypeScript 构建工具链与测试」前先用 prepublishOnly 复现当前输出，再对照官方发布说明逐条核对。
- 升级前先用 prepublishOnly 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 prepublishOnly 记录构建与运行结果。
- 升级后重点回归 TypeScript 的默认值、警告信息与错误格式。
- 升级后把 prepublishOnly 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 TypeScript、tsup | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「TypeScript 构建工具链与测试」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「TypeScript 构建工具链与测试」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:typescript`，用于动手验证《TypeScript 构建工具链与测试》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《TypeScript 构建工具链与测试》原文中的最小示例。先预测《TypeScript 构建工具链与测试》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```jsonc
// 条件导出：让不同环境拿到合适的产物
{
  "name": "my-lib",
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    }
  },
  "files": ["dist"],
  "sideEffects": false
}
```

**教材衔接：测试：vitest**

vitest 与 Vite 共用配置，开箱支持 TS；测试要点：对纯函数做单元测试，对 HTTP/数据库用替身或内存实现做集成测试；异步用例要 `await` 并断言 reject（`await expect(fn()).rejects.toThrow()`）。

**教材衔接：构建产物速查**

| 目标 | 配置要点 |
| --- | --- |
| 只产 ESM | `"type": "module"` + `format: ["esm"]` |
| 同时产 ESM 与 CJS | 用 tsup / unbuild 输出 `.js` 与 `.cjs`，配合 `exports` 条件导出 |
| 生成类型声明 | `tsc --emitDeclarationOnly` 或打包器 `dts: true` |
| 保持目录结构 | `tsc` 直接编译，不做打包 |
| 浏览器库 | 输出 `iife` / `umd` 并声明 `globalName` |
| Node CLI | 顶部加 `#!/usr/bin/env node` shebang |

```jsonc
// 条件导出：让不同环境拿到合适的产物
{
  "name": "my-lib",
  "type": "module",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    }
  },
  "files": ["dist"],
  "sideEffects": false
}
```

**教材衔接：测试工具速查**

| 工具 | 定位 | 特点 |
| --- | --- | --- |
| Vitest | 单元测试 | 与 Vite 共享配置，速度快 |
| Jest | 单元测试 | 生态成熟，配置较多 |
| Testing Library | 组件测试 | 面向用户行为而非实现 |
| Playwright | 端到端 | 多浏览器、自动等待 |
| MSW | 接口模拟 | 在网络层拦截，贴近真实 |
| fast-check | 属性测试 | 自动生成边界输入 |

**教材衔接：零基础详解：构建产物与测试策略**

### 一句话说清它是什么

构建负责把源码变成能跑的产物（ESM、CJS、类型声明），测试负责证明它是对的。
库项目与应用的关注点不同：**库要兼顾多种模块格式，应用只要跑起来最快最稳**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 打包器 | 流水线 | 转译、合并、压缩 |
| tsc | 质检员 | 只出类型声明与类型检查 |
| ESM / CJS | 两种插头 | 不同环境需要不同格式 |
| 单元测试 | 零件检验 | 快、覆盖细 |
| 集成测试 | 装配检验 | 验证模块之间 |
| E2E | 整车试驾 | 慢但最接近真实 |

### 库项目的双格式产物

```json
{
  "name": "my-lib",
  "type": "module",
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.js",
      "require": "./dist/index.cjs"
    }
  },
  "files": ["dist"],
  "scripts": {
    "build": "tsup src/index.ts --format esm,cjs --dts --clean",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "prepublishOnly": "npm run typecheck && npm run test && npm run build"
  }
}
```

| 字段 | 作用 |
| --- | --- |
| `main` | 老工具用的 CommonJS 入口 |
| `module` | 打包器优先用的 ESM 入口 |
| `types` | 类型声明入口 |
| `exports` | 现代解析规则，按条件分发 |
| `files` | 发布时只带上必要目录 |

### 一份实用的 vitest 配置

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      thresholds: { lines: 80, functions: 80, branches: 70 },
    },
    globals: true,
  },
});
```

### 测试写得好的四个特征

```typescript
import { describe, expect, it, vi } from "vitest";
import { calcTotal } from "../src/calc";

describe("calcTotal", () => {
  it("空购物车返回 0", () => {
    expect(calcTotal([])).toBe(0);
  });

  it("按数量与单价计算", () => {
    expect(calcTotal([{ price: 10, qty: 3 }])).toBe(30);
  });

  it("超过 100 元打九折", () => {
    expect(calcTotal([{ price: 60, qty: 2 }])).toBe(108);
  });

  it("调用支付网关一次", async () => {
    const pay = vi.fn().mockResolvedValue({ ok: true });
    await payOnce(pay);
    expect(pay).toHaveBeenCalledTimes(1);
  });
});
```

| 特征 | 说明 |
| --- | --- |
| 名字描述行为 | 「超过 100 元打九折」而不是「测试 2」 |
| 一个用例一个断言点 | 失败时定位准确 |
| 不依赖外部服务 | 用 mock 或内存实现 |
| 可重复运行 | 不依赖顺序与时间 |

### 常见测试类型与配比

| 类型 | 数量占比 | 速度 | 覆盖什么 |
| --- | --- | --- | --- |
| 单元测试 | 最多 | 毫秒 | 纯函数、业务规则 |
| 集成测试 | 中等 | 百毫秒 | 模块协作、数据库 |
| E2E | 最少 | 秒到分钟 | 关键用户流程 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 以为打包器会做类型检查 | 类型错误照样发布 | CI 单独跑 `tsc --noEmit` |
| 只出 ESM 不兼容老项目 | 使用方 require 失败 | 同时产出 CJS |
| `exports` 路径写错 | 装包后找不到入口 | 本地 `npm pack` 验证 |
| 忘了 `files` | 把源码一起发布 | 只发布 dist |
| mock 过度 | 重构后测试全红 | 优先测行为 |
| 测试依赖当前时间 | 明天就失败 | 注入时间或冻结时钟 |
| 覆盖率刷到 100% | 断言很弱 | 关注分支与断言质量 |
| 测试之间共享状态 | 单独跑就过 | 每个用例自带准备清理 |

### 手把手练习：验证发布产物

```bash
#!/usr/bin/env bash
set -euo pipefail

npm run typecheck
npm run test
npm run build

# 打包出真实的发布物并在临时项目里安装验证
readonly TARBALL="$(npm pack --silent)"
readonly TMP="$(mktemp -d)"
trap 'rm -rf "$TMP" "$TARBALL"' EXIT

cd "$TMP"
npm init -y >/dev/null
npm install "/path/to/$TARBALL" >/dev/null

node -e "import('my-lib').then(m => console.log('ESM 正常', Object.keys(m)))"
node -e "console.log('CJS 正常', Object.keys(require('my-lib')))"
echo "发布前检查全部通过"
```

### 学完自测

- [ ] 能说出 `main`、`module`、`types`、`exports` 的分工。
- [ ] 知道为什么库要同时产出 ESM 与 CJS。
- [ ] 能说出单元、集成、E2E 的数量配额与原因。
- [ ] 知道 `npm pack` 能验证什么。
- [ ] 能说出「弱断言」为什么让覆盖率失去意义。

## 时间/空间复杂度或性能分析

**复杂度证据**：「TypeScript 构建工具链与测试」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「TypeScript 构建工具链与测试」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「TypeScript 构建工具链与测试」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《TypeScript 构建工具链与测试》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「TypeScript 构建工具链与测试」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只配置 `main` 不配置 `exports` | 现代解析器拿不到 ESM 入口 | 补 `exports` 条件导出 |
| 类型声明与实现分开发布 | 使用者类型不匹配 | 同一版本一起产出并校验 |
| 忘记 `files` 字段 | 发布了源码、测试与配置 | 只发布 `dist` |
| 库没有 `sideEffects: false` | tree shaking 效果差 | 声明无副作用（谨慎评估） |
| CI 只跑打包不跑类型检查 | 类型错误进入发布 | 加 `tsc --noEmit` |
| 测试用 `any` 断言 | 失去类型收益 | 用类型守卫或夹具类型 |
| 组件测试断言实现细节 | 重构后大量失败 | 断言用户可见行为 |
| 端到端测试用固定等待 | 偶发失败 | 用自动等待与可观测条件 |
| 接口模拟散落在各处 | 维护困难 | 用 MSW 集中定义 handler |
| 依赖 `ts-node` 直接跑生产 | 启动慢、类型未预检 | 构建后运行产物 |

**教材衔接：故障现场**

### 现场 1：只配置 main 不配置 exports

**症状**：在《TypeScript 构建工具链与测试》的复现场景中，现代解析器拿不到 ESM 入口。

**根因**：触发点是把“只配置 main 不配置 exports”当成安全做法。它没有满足《TypeScript 构建工具链与测试》要求的前提，因此先表现为“现代解析器拿不到 ESM 入口”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《TypeScript 构建工具链与测试》的问题，补 exports 条件导出。

**验证**：先在《TypeScript 构建工具链与测试》中记录“只配置 main 不配置 exports”留下的失败证据，再执行“补 exports 条件导出”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：类型声明与实现分开发布

**症状**：在《TypeScript 构建工具链与测试》的复现场景中，使用者类型不匹配。

**根因**：触发点是把“类型声明与实现分开发布”当成安全做法。它没有满足《TypeScript 构建工具链与测试》要求的前提，因此先表现为“使用者类型不匹配”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《TypeScript 构建工具链与测试》的问题，同一版本一起产出并校验。

**验证**：保留《TypeScript 构建工具链与测试》里触发“使用者类型不匹配”的输入、版本和日志，按“同一版本一起产出并校验”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：忘记 files 字段

**症状**：在《TypeScript 构建工具链与测试》的复现场景中，发布了源码、测试与配置。

**根因**：当出现“忘记 files 字段”时，执行路径已经绕过了《TypeScript 构建工具链与测试》的关键约束，最终以“发布了源码、测试与配置”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《TypeScript 构建工具链与测试》的问题，只发布 dist。

**验证**：在《TypeScript 构建工具链与测试》中按“只发布 dist”调整后，从“忘记 files 字段”的触发条件重放同一条路径，确认“发布了源码、测试与配置”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 关联 | 《TypeScript 实战：全栈类型安全》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《TypeScript 工程配置与实践》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《TypeScript 类型收窄与泛型》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「TypeScript 构建工具链与测试」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《TypeScript 构建工具链与测试》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

库项目同时产出 ESM 与 CJS 常用？

A. webpack
B. tsup/esbuild 配合 tsc 生成 d.ts
C. tsc 单跑
D. 只用 Babel 转译，再手动补齐两份类型声明文件，但这会引入新的复杂度

**参考答案**：tsup/esbuild 配合 tsc 生成 d.ts

**解析**：在「TypeScript 构建工具链与测试」里，tsup/esbuild 配合 tsc 生成 d.ts。打包器负责产物格式，tsc 负责类型声明。把“tsup/esbuild 配合 tsc”代回「TypeScript 构建工具链与测试」里“库项目同时产出 ESM 与 CJS 常用”的例子核对，条件一旦改变，结论就要用TypeScript、tsup、Vite重新推导。

### 自测 2

这段 TypeScript 代码是「TypeScript 构建工具链与测试」的示例片段，下面哪一项描述与它一致？

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      thresholds: { lines: 80, functions: 80, branches: 70 },
    },
    globals: true,
  },
});
```

A. 这段代码包含条件分支，不同输入会走不同的执行路径。
B. 这段代码只做静态声明，没有循环、分支或可观察输出。
C. 这段代码会产生可观察的输出，运行后能看到结果。
D. 这段代码包含循环结构，同一段逻辑会被重复执行。

**参考答案**：这段代码只做静态声明，没有循环、分支或可观察输出。

**解析**：在「TypeScript 构建工具链与测试」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「TypeScript 构建工具链与测试」的正文示例，围绕TypeScript、tsup、Vite展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 构建工具链与测试」的实际运行结果为准。

### 自测 3

围绕“TypeScript 构建工具链与测试”中的 TypeScript、tsup、Vite，下列哪两项是本课强调的实践判断？

A. 只要 TypeScript 的常规示例通过，就可以跳过边界与异常路径
B. 验证 tsup 时要固定版本并覆盖边界输入，结论才可复现
C. 把 tsup 的单次运行结果当成所有版本和规模都成立
D. 学习 TypeScript 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 tsup 时要固定版本并覆盖边界输入，结论才可复现；学习 TypeScript 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：在「TypeScript 构建工具链与测试」里，学习 TypeScript 时要同时说明输入、输出和失败路径，不能只看正常流程。在TypeScript 构建工具链与测试里，判断 tsup 时要固定版本与边界输入，所以“验证 tsup 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 库同时提供 ESM、CJS 与类型声明，并用 `exports` 暴露。
- [ ] `package.json` 的 `files` 只包含发布所需内容。
- [ ] CI 覆盖 `tsc --noEmit`、lint、测试与打包。
- [ ] 组件测试断言用户行为，端到端使用自动等待。
- [ ] lint 开启 Promise 相关规则，避免漏 `await`。

**教材衔接：动手练习**

> 本课练习重点：围绕「TypeScript、tsup、Vite」完成复述、实验和交付，每个结果都要能被别人检查。

为 prepublishOnly 写出类型签名，然后故意传错一个参数观察编译器报错。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. TypeScript 构建工具链与测试解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「tsup」是什么关系？

验收标准：用自己的话解释 TypeScript，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：五步记录要写进笔记——原例是 prepublishOnly，改动落在TypeScript上，结论必须能被他人在同一环境里复现。

### 练习 3：交付一个小结果（30 分钟）

写一个只做一件事的小程序：输入 TypeScript，输出 tsup，其余全部省略。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「TypeScript」和「tsup」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
      thresholds: { lines: 80, functions: 80, branches: 70 },
    },
    globals: true,
  },
});
```

### 任务 2：只改一个条件

把「TypeScript 构建工具链与测试」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 tsup 换成边界值，其他输入保持原样。
- 预测：先写下「TypeScript 构建工具链与测试」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：prepublishOnly 在改动前后的输出可以对照，且影响范围可控。

### 任务 3：迁移到自己的数据

换一个 tsup 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「库项目同时产出 ESM 与 CJS 常用？」的判断依据。
- [ ] 不看解析，能说出「关于类型检查与打包，正确说法是？」的判断依据。
- [ ] 不看解析，能说出「能拦掉漏写 await 的 lint 规则是？」的判断依据。
- [ ] 不看解析，能说出「tsc --noEmit 的用途是？」的判断依据。
- [ ] 不看解析，能说出「TypeScript 的项目引用（references）与增量构建的价值是？」的判断依据。
- [ ] 跑通「TypeScript 构建工具链与测试」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「TypeScript 构建工具链与测试」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `TypeScript` | 在 JavaScript 上增加静态类型系统的语言，编译后可运行在浏览器或 Node.js。 |
| `tsup` | 库项目常见组合：tsup 产出 dist/index.mjs 与 dist/index.cjs + tsc 生成 .d.ts，并在 package.json 用 exports 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。 |
| `Vite` | 现代前端构建工具：开发时用原生 ESM 按需编译并热更新，打包时用 Rollup 产出静态资源。 |
| `转译与类型检查分离` | esbuild、swc 只做语法转换，类型错误要靠 tsc --noEmit 单独把关。 |

## 考点精讲

### 考点 1：概念判断·TypeScript

- **题目**：库项目同时产出 ESM 与 CJS 常用？
- **判断依据**：在「TypeScript 构建工具链与测试」里，tsup/esbuild 配合 tsc 生成 d.ts。打包器负责产物格式，tsc 负责类型声明。把“tsup/esbuild 配合 tsc”代回「TypeScript 构建工具链与测试」里“库项目同时产出 ESM 与 CJS 常用”的例子核对，条件一旦改变，结论就要用TypeScript、tsup、Vite重新推导。

### 考点 2：代码补全·TypeScript

- **题目**：这段 TypeScript 代码是「TypeScript 构建工具链与测试」的示例片段，下面哪一项描述与它一致？
- **判断依据**：在「TypeScript 构建工具链与测试」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「TypeScript 构建工具链与测试」的正文示例，围绕TypeScript、tsup、Vite展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 构建工具链与测试」的实际运行结果为准。

### 考点 3：概念判断·TypeScript

- **题目**：能拦掉漏写 await 的 lint 规则是？
- **判断依据**：在「TypeScript 构建工具链与测试」里，no-floating-promises。它要求 Promise 被 await、return 或显式 void 处理。在「TypeScript 构建工具链与测试」里判断这道题，要把TypeScript、tsup、Vite的条件、过程与失败路径逐项对齐，换成“能拦掉漏写 await 的 lint”这个场景，只有满足前提的结论才成立。

### 考点 4：概念判断·TypeScript

- **题目**：tsc --noEmit 的用途是？
- **判断依据**：在「TypeScript 构建工具链与测试」里，结论应落在「只做类型检查，不生成 JS 文件」。打包器通常不做类型检查，所以 CI 里要单独跑一次 tsc --noEmit 把类型问题拦住。在「TypeScript 构建工具链与测试」里，这道题要求区分概念与边界，「只做类型检查，不生成 JS 文件」只有在题干给出的前提下才成立，而「把 TS 编译成 JS，但这会拖慢构建速度」、「生成类型声明文件」缺少同一组条件。

### 考点 5：多选辨析·TypeScript

- **题目**：围绕“TypeScript 构建工具链与测试”中的 TypeScript、tsup、Vite，下列哪两项是本课强调的实践判断？
- **判断依据**：在「TypeScript 构建工具链与测试」里，学习 TypeScript 时要同时说明输入、输出和失败路径，不能只看正常流程。在TypeScript 构建工具链与测试里，判断 tsup 时要固定版本与边界输入，所以“验证 tsup 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 6：填空·"____": false

- **题目**：补全代码：「TypeScript 构建工具链与测试」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"____": false`
- **判断依据**：在「TypeScript 构建工具链与测试」里，sideEffects。回到「TypeScript 构建工具链与测试」的正文示例，用“补全代码”走一遍TypeScript、tsup、Vite的完整流程，能复现的结论才可以保留。回到TypeScript、tsup、Vite本身再看一遍：只有“sideEffects”与题干“TypeScript”的前提一致，结论才成立。

## English Overview

**Title:** Build & Test

**Summary:** tsc/tsup/Vite, dual output and vitest.

**Category:** TypeScript
**Level:** 基础
**Key terms:** TypeScript, tsup, Vite, vitest, CI

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：TypeScript 5.x / Node.js 22+；本课聚焦 TypeScript。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、tsup、Vite、vitest、CI
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与语言指南 |
| [项目引用](https://www.typescriptlang.org/docs/handbook/project-references.html) | 大型项目拆分与增量构建 |
| [Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html) | 内置类型变换 |

> 「TypeScript 构建工具链与测试」的链接用于离线阅读后的延伸核对；App 不会自动联网。
