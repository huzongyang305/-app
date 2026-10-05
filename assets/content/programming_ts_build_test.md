# TypeScript 构建工具链与测试

![构建工具与测试工具的分工](images/diagram_ts_build_test.webp)

![TypeScript 构建工具链与测试](images/remaining_ts_build_test.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「TypeScript 构建工具链与测试」解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「tsup」、「Vite」、「vitest」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：tsc/tsup/Vite 选型、双格式产物与 vitest 测试。

## 前置知识

- 先完成上一课《TypeScript 进阶类型与框架实践》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：TypeScript、tsup、Vite。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 工具选型

| 工具 | 定位 |
| --- | --- |
| tsc | 类型检查与生成 d.ts（不做打包优化） |
| Vite | 前端开发服务器与生产打包 |
| tsup / esbuild | 库打包，速度快，可同时产出 ESM/CJS |
| swc | 极快的转译器，常用于替代 Babel |
| unbuild / rollup | 库产物与 tree-shaking 更可控 |

库项目常见组合：tsup 产出 `dist/index.mjs` 与 `dist/index.cjs` + tsc 生成 `.d.ts`，并在 package.json 用 `exports` 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。

## tsconfig 与产物一致

`module`/`moduleResolution` 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）；`target` 决定语法降级程度；库项目开启 `declaration` 与 `declarationMap` 方便跳转到源码。

## 测试：vitest

vitest 与 Vite 共用配置，开箱支持 TS；测试要点：对纯函数做单元测试，对 HTTP/数据库用替身或内存实现做集成测试；异步用例要 `await` 并断言 reject（`await expect(fn()).rejects.toThrow()`）。

## 类型也要测

| 手段 | 用途 |
| --- | --- |
| `tsc --noEmit` | 全量类型检查，进 CI |
| tsd / expect-type | 断言类型行为（如 Omit 是否正确） |
| ESLint + typescript-eslint | 禁 any、要求显式返回类型、限制浮空 Promise |

`@typescript-eslint/no-floating-promises` 能拦掉大量异步漏 await 的 bug，值得开启。

## CI 基线

顺序：`install → lint → tsc --noEmit → test --coverage → build`。构建产物要做体积检查（bundlesize/rollup-plugin-visualizer），防止依赖悄悄膨胀。

## 本课小结
TypeScript 工具链的核心原则：**类型检查与打包分离、产物格式与运行时对齐、类型行为也要测试**。


## 构建产物速查

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

## 测试工具速查

| 工具 | 定位 | 特点 |
| --- | --- | --- |
| Vitest | 单元测试 | 与 Vite 共享配置，速度快 |
| Jest | 单元测试 | 生态成熟，配置较多 |
| Testing Library | 组件测试 | 面向用户行为而非实现 |
| Playwright | 端到端 | 多浏览器、自动等待 |
| MSW | 接口模拟 | 在网络层拦截，贴近真实 |
| fast-check | 属性测试 | 自动生成边界输入 |

## 常用 lint 规则速查

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

## 常见错误对照表

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

## 自测清单

- [ ] 库同时提供 ESM、CJS 与类型声明，并用 `exports` 暴露。
- [ ] `package.json` 的 `files` 只包含发布所需内容。
- [ ] CI 覆盖 `tsc --noEmit`、lint、测试与打包。
- [ ] 组件测试断言用户行为，端到端使用自动等待。
- [ ] lint 开启 Promise 相关规则，避免漏 `await`。


## 零基础详解：构建产物与测试策略

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

## 动手练习


> 本课练习重点：围绕「TypeScript、tsup、Vite」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「TypeScript 构建工具链与测试」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「tsup」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个最小类型示例，先让 `tsc --noEmit` 通过，再故意制造一次类型错误。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「TypeScript」和「tsup」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：库项目同时产出 ESM 与 CJS 常用？

- **正确判断**：tsup/esbuild 配合 tsc 生成 d.ts
- **判断依据**：正确答案是「tsup/esbuild 配合 tsc 生成 d.ts」，本课在「工具选型」中说明：库项目常见组合：tsup 产出 dist/index.mjs 与 dist/index.cjs + tsc 生成 .d.ts，并在 package.json 用 exports 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。打包器负责产物格式，tsc 负责类型声明。本课还在「零基础详解：构建产物与测试策略」中说明：知道为什么库要同时产出 ESM 与 CJS。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：关于类型检查与打包，正确说法是？

- **正确判断**：两者分离
- **判断依据**：正确答案是「两者分离」，本课在「本课小结」中说明：TypeScript 工具链的核心原则：类型检查与打包分离、产物格式与运行时对齐、类型行为也要测试。Vite/esbuild/swc 只转译不检查类型。本课还在「测试：vitest」中说明：vitest 与 Vite 共用配置，开箱支持 TS。本课还在「tsconfig 与产物一致」中说明：module/moduleResolution 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：能拦掉漏写 await 的 lint 规则是？

- **正确判断**：no-floating-promises
- **判断依据**：正确答案是「no-floating-promises」，本课在「类型也要测」中说明：@typescript-eslint/no-floating-promises 能拦掉大量异步漏 await 的 bug，值得开启。它要求 Promise 被 await、return 或显式 void 处理。本课还在「本课小结」中说明：TypeScript 工具链的核心原则：类型检查与打包分离、产物格式与运行时对齐、类型行为也要测试。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：tsc --noEmit 的用途是？

- **正确判断**：只做类型检查，不生成 JS 文件
- **判断依据**：正确答案是「只做类型检查，不生成 JS 文件」，本课在「零基础详解：构建产物与测试策略」中说明：构建负责把源码变成能跑的产物（ESM、CJS、类型声明），测试负责证明它是对的。打包器通常不做类型检查，所以 CI 里要单独跑一次 tsc --noEmit 把类型问题拦住。本课还在「工具选型」中说明：库项目常见组合：tsup 产出 dist/index.mjs 与 dist/index.cjs + tsc 生成 .d.ts，并在 package.json 用 exports 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：TypeScript 的项目引用（references）与增量构建的价值是？

- **正确判断**：把大项目拆成多个子项目
- **判断依据**：正确答案是「把大项目拆成多个子项目」，本课在「测试：vitest」中说明：测试要点：对纯函数做单元测试，对 HTTP/数据库用替身或内存实现做集成测试。monorepo 中配合 composite 与 build 模式，可以显著缩短类型检查时间。本课还在「测试：vitest」中说明：vitest 与 Vite 共用配置，开箱支持 TS。本课还在「tsconfig 与产物一致」中说明：module/moduleResolution 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「TypeScript 构建工具链与测试」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"____": false`

- **正确判断**：sideEffects / sideeffects
- **判断依据**：正确答案是「sideEffects」，本课在「CI 基线」中说明：构建产物要做体积检查（bundlesize/rollup-plugin-visualizer），防止依赖悄悄膨胀。本课示例中还能看到 `"sideEffects": false` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：不看题干，用自己的话补全这句话，再与标准答案对照。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「库项目同时产出 ESM 与 CJS 常用？」的判断依据。
- [ ] 不看解析，能说出「关于类型检查与打包，正确说法是？」的判断依据。
- [ ] 不看解析，能说出「能拦掉漏写 await 的 lint 规则是？」的判断依据。
- [ ] 不看解析，能说出「tsc --noEmit 的用途是？」的判断依据。
- [ ] 不看解析，能说出「TypeScript 的项目引用（references）与增量构建的价值是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「TypeScript 构建工具链与测试」示例中，下面这行代码缺少哪个…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `dist/index.mjs` | 库项目常见组合：tsup 产出 `dist/index.mjs` 与 `dist/index.cjs` + tsc 生成 `.d.ts`，并在 package.json 用 `exports` 字段声明条件导出，避免"双… |
| `dist/index.cjs` | 库项目常见组合：tsup 产出 `dist/index.mjs` 与 `dist/index.cjs` + tsc 生成 `.d.ts`，并在 package.json 用 `exports` 字段声明条件导出，避免"双… |
| `.d.ts` | 库项目常见组合：tsup 产出 `dist/index.mjs` 与 `dist/index.cjs` + tsc 生成 `.d.ts`，并在 package.json 用 `exports` 字段声明条件导出，避免"双… |
| `exports` | 库项目常见组合：tsup 产出 `dist/index.mjs` 与 `dist/index.cjs` + tsc 生成 `.d.ts`，并在 package.json 用 `exports` 字段声明条件导出，避免"双… |
| `module` | `module`/`moduleResolution` 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）；`target` 决定语法降级程度；库项目开启 `declarat… |
| `moduleResolution` | `module`/`moduleResolution` 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）；`target` 决定语法降级程度；库项目开启 `declarat… |
| `target` | `module`/`moduleResolution` 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）；`target` 决定语法降级程度；库项目开启 `declarat… |
| `declaration` | `module`/`moduleResolution` 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）；`target` 决定语法降级程度；库项目开启 `declarat… |
| `declarationMap` | `module`/`moduleResolution` 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）；`target` 决定语法降级程度；库项目开启 `declarat… |
| `await` | vitest 与 Vite 共用配置，开箱支持 TS；测试要点：对纯函数做单元测试，对 HTTP/数据库用替身或内存实现做集成测试；异步用例要 `await` 并断言 reject（`await expect(fn())… |
| `await expect(fn()).rejects.toThrow()` | vitest 与 Vite 共用配置，开箱支持 TS；测试要点：对纯函数做单元测试，对 HTTP/数据库用替身或内存实现做集成测试；异步用例要 `await` 并断言 reject（`await expect(fn())… |
| `tsc --noEmit` | \| `tsc --noEmit` \| 全量类型检查，进 CI \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：库项目同时产出 ESM 与 CJS 常用？

**参考回答**：正确答案是「tsup/esbuild 配合 tsc 生成 d.ts」，本课在「工具选型」中说明：库项目常见组合：tsup 产出 dist/index.mjs 与 dist/index.cjs + tsc 生成 .d.ts，并在 package.json 用 exports 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。打包器负责产物格式，tsc 负责类型声明。本课还在「零基础详解·构建产物与测试策略」中说明：知道为什么库要同时产出 ESM 与 CJS。

### 追问 2：关于类型检查与打包，正确说法是？

**参考回答**：正确答案是「两者分离」，本课在「本课小结」中说明：TypeScript 工具链的核心原则：类型检查与打包分离、产物格式与运行时对齐、类型行为也要测试。Vite/esbuild/swc 只转译不检查类型。本课还在「测试·vitest」中说明：vitest 与 Vite 共用配置，开箱支持 TS。本课还在「tsconfig 与产物一致」中说明：module/moduleResolution 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）。

### 追问 3：能拦掉漏写 await 的 lint 规则是？

**参考回答**：正确答案是「no-floating-promises」，本课在「类型也要测」中说明：@typescript-eslint/no-floating-promises 能拦掉大量异步漏 await 的 bug，值得开启。它要求 Promise 被 await、return 或显式 void 处理。本课还在「本课小结」中说明：TypeScript 工具链的核心原则：类型检查与打包分离、产物格式与运行时对齐、类型行为也要测试。

### 追问 4：tsc --noEmit 的用途是？

**参考回答**：正确答案是「只做类型检查，不生成 JS 文件」，本课在「零基础详解·构建产物与测试策略」中说明：构建负责把源码变成能跑的产物（ESM、CJS、类型声明），测试负责证明它是对的。打包器通常不做类型检查，所以 CI 里要单独跑一次 tsc --noEmit 把类型问题拦住。本课还在「工具选型」中说明：库项目常见组合：tsup 产出 dist/index.mjs 与 dist/index.cjs + tsc 生成 .d.ts，并在 package.json 用 exports 字段声明条件导出，避免"双包危害"（同一依赖被加载两份）。

### 追问 5：TypeScript 的项目引用（references）与增量构建的价值是？

**参考回答**：正确答案是「把大项目拆成多个子项目」，本课在「测试·vitest」中说明：测试要点：对纯函数做单元测试，对 HTTP/数据库用替身或内存实现做集成测试。monorepo 中配合 composite 与 build 模式，可以显著缩短类型检查时间。本课还在「测试·vitest」中说明：vitest 与 Vite 共用配置，开箱支持 TS。本课还在「tsconfig 与产物一致」中说明：module/moduleResolution 要与运行时一致（Node ESM 用 node16/nodenext，打包器用 bundler）。

## English Overview

**Title:** Build & Test

**Summary:** tsc/tsup/Vite, dual output and vitest.

**Category:** TypeScript  
**Level:** 基础  
**Key terms:** TypeScript, tsup, Vite, vitest, CI

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、tsup、Vite、vitest、CI
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与编译配置 |
| [Decorators 与模块](https://www.typescriptlang.org/docs/) | 语言特性与生态集成 |

> 本课主题：tsc/tsup/Vite 选型、双格式产物与 vitest 测试。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
