# TypeScript 工程配置与实践

![TypeScript 工程配置的四个环节](images/diagram_ts_project.webp)

![TypeScript 工程配置与实践](images/remaining_ts_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释TypeScript 工程配置与实践解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「tsconfig」、「strict」、「zod」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：strict、tsc --noEmit、zod 运行时校验与团队规范。

## 前置知识

- 先完成上一课《TypeScript 工具类型与声明文件》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：TypeScript、tsconfig、strict。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## tsconfig 关键选项

| 选项 | 建议 |
| --- | --- |
| `strict` | 必开，含 strictNullChecks、noImplicitAny 等 |
| `noUncheckedIndexedAccess` | 数组下标访问返回 `T \| undefined`，更安全 |
| `exactOptionalPropertyTypes` | 区分「缺失」与「undefined」 |
| `paths` | 配置 `@/` 别名，避免 `../../..` |
| `moduleResolution: bundler/node16` | 与打包器或 Node 实际行为对齐 |
| `skipLibCheck` | 加快编译（但会放过依赖的类型错误） |

## 类型检查与构建分离

打包器（Vite/esbuild/swc）只做转译，**不做类型检查**。因此 CI 必须单独跑 `tsc --noEmit`，否则类型错误会直接进生产。同理，`ts-node`/`tsx` 运行时也建议配类型检查脚本。

## 运行时校验不可省

类型在运行时不存在，接口返回、localStorage、URL 参数都可能是任意值。用 zod / valibot 在边界校验：

```text
const User = z.object({ id: z.number(), name: z.string() });
const user = User.parse(await res.json());   // 校验后再用，类型自动推导
```

原则：**外部数据必须先校验再收窄类型**，把 `unknown` 变成可信类型。

## 与框架集成

React：组件 props 用显式类型，事件与 ref 用库提供类型；避免 `React.FC`（隐式 children 已不推荐）。Node：`@types/node` 必装，注意 CommonJS/ESM 的模块解析差异。跨端（uni-app/React Native）注意平台类型差异。

## 团队规范

1. 禁止 `any`（用 `unknown` 或具体类型），ESLint 加 `@typescript-eslint/no-explicit-any`。
2. 类型导入用 `import type`，避免运行时副作用。
3. 提交前跑 `tsc --noEmit` + lint + 测试。
4. 逐步迁移 JS 项目：先 `allowJs + checkJs`，再逐文件开启严格模式。

## 本课小结
TypeScript 工程化的三件事：**strict 打开、tsc 进 CI、边界做运行时校验**；做到这三点，类型系统才能真正减少线上问题。

## tsconfig 关键配置速查

| 选项 | 建议值 | 作用 |
| --- | --- | --- |
| `strict` | `true` | 打开全部严格检查 |
| `target` | `ES2022` | 输出语法的目标版本 |
| `lib` | `["ES2022", "DOM"]` | 可用的内置类型库 |
| `module` / `moduleResolution` | 按运行时选择 | 决定 import 解析规则 |
| `noUncheckedIndexedAccess` | `true` | 下标访问返回可能 `undefined` |
| `exactOptionalPropertyTypes` | `true` | 区分缺失与 `undefined` |
| `noImplicitOverride` | `true` | 重写必须写 `override` |
| `noFallthroughCasesInSwitch` | `true` | 禁止 switch 穿透 |
| `isolatedModules` | `true` | 与打包器（esbuild/swc）兼容 |
| `skipLibCheck` | `true` | 跳过依赖类型检查，加快编译 |
| `noEmit` | CI 时 `true` | 只做类型检查 |
| `baseUrl` / `paths` | 按需 | 路径别名，打包器需同步配置 |

```jsonc
// tsconfig.json 参考
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "noEmit": true,
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src", "tests", "types"]
}
```

## 类型检查与构建的分工速查

| 工具 | 是否做类型检查 | 说明 |
| --- | --- | --- |
| `tsc` | 是 | 官方编译器，可作为类型门禁 |
| `tsc --noEmit` | 是 | CI 中最常用的检查方式 |
| `esbuild` / `swc` | 否 | 只转译，速度快，不做类型检查 |
| `Vite`（开发） | 否 | 依赖编辑器与 `tsc` 检查类型 |
| `babel` | 否 | 只去类型 |
| `ts-node` / `tsx` | 视配置 | 运行 TS，类型检查通常需另跑 |

结论：**打包器负责产物，`tsc --noEmit` 负责类型门禁**，两者都要在流水线里。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只在编辑器里看类型错误 | CI 放行有类型问题的代码 | 流水线加 `tsc --noEmit` |
| `paths` 只在 tsconfig 配置 | 打包或运行时找不到模块 | 打包器同步配置别名 |
| `include` 漏掉目录 | 部分文件不参与检查 | 显式列出 `src`、`tests`、`types` |
| `skipLibCheck` 以为能掩盖自身错误 | 自身错误仍会报出 | 它只跳过 `.d.ts` 检查 |
| 用 `ts-ignore` 关掉报错 | 错误被永久掩盖 | 用 `ts-expect-error` 并写明原因 |
| 依赖 `.ts` 扩展名导入 | 打包器或运行时解析失败 | 用无扩展名或按运行时要求 |
| `moduleResolution` 配错 | 找不到依赖类型 | 与运行时（Node / Bundler）保持一致 |
| 混用 ESM 与 CJS | `require is not defined` 之类错误 | 统一模块体系并设置 `type` |
| 只在本地跑构建 | 环境差异导致失败 | CI 用固定 Node 版本与 lock 文件 |
| 忘记提交 `types/` 目录 | 同事编译失败 | 类型声明纳入版本管理 |

## 自测清单

- [ ] 项目开启 `strict` 与 `noUncheckedIndexedAccess`。
- [ ] CI 里单独跑 `tsc --noEmit` 作为类型门禁。
- [ ] 别名在 tsconfig 与打包器里保持一致。
- [ ] 使用 `ts-expect-error` 而非 `ts-ignore`，并写明原因。
- [ ] Node 版本与模块体系在项目里明确固定。

## 零基础详解：工程配置、构建与类型检查

### 一句话说清它是什么

TypeScript 项目有三件事必须分清：
**写代码时的类型检查**、**打包器负责的转译**、**CI 里的强制门禁**。
三者混在一起，就会出现「本地能跑、线上报错」。

### 用生活比喻理解

| 环节 | 比喻 | 说明 |
| --- | --- | --- |
| `tsc` | 质检员 | 只查类型，不做打包 |
| 打包器（Vite/esbuild） | 搬运工 | 只转译和合并，**不查类型** |
| CI | 出厂闸门 | 类型检查、测试、构建一起卡住 |
| `tsconfig.json` | 工艺标准 | 严格程度、目标版本、路径别名 |

### 一份可直接用的 tsconfig

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022", "DOM"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noUnusedLocals": true,
    "exactOptionalPropertyTypes": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "noEmit": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src"]
}
```

| 选项 | 作用 |
| --- | --- |
| `strict` | 打开一组严格检查，新项目必开 |
| `noUncheckedIndexedAccess` | 数组或字典取值可能为 undefined |
| `noUnusedLocals` | 未使用的变量直接报错 |
| `verbatimModuleSyntax` | 明确区分类型导入与值导入 |
| `noEmit` | 只做类型检查，产物交给打包器 |
| `skipLibCheck` | 跳过第三方声明检查，提速 |

### 三条命令各管一段

```bash
tsc --noEmit          # 类型检查：CI 必跑
vite build            # 打包产物：不查类型
tsc --noEmit && vite build   # 组合成真正的发布前检查
```

**记住：Vite、esbuild、swc 都不会因为类型错误而中断构建。**

### 路径别名要同时配两处

```typescript
// tsconfig 里配 paths 只解决「类型解析」
import { api } from "@/lib/api";
```

```javascript
// vite.config.ts 里还要配别名，才能让打包器找到真实文件
import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";

export default defineConfig({
  resolve: {
    alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) },
  },
});
```

### CI 最小门禁

```yaml
- run: npm ci
- run: npx tsc --noEmit
- run: npm run lint
- run: npm test -- --run
- run: npm run build
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 以为打包会查类型 | 类型错误照样上线 | CI 单独跑 `tsc --noEmit` |
| 只配 tsconfig 别名 | 运行时找不到模块 | 打包器同步配置 |
| 关掉 `strict` | 空值错误频发 | 新项目一律开启 |
| 忽略 `noUncheckedIndexedAccess` | 数组取值可能 undefined | 开启并处理 |
| 类型与值混用导入 | 打包产物异常 | 用 `import type` |
| `skipLibCheck` 被误解 | 以为不检查自己的代码 | 它只跳过第三方声明 |
| 依赖版本不锁 | 别人装出来行为不同 | 提交 lockfile，CI 用 `npm ci` |
| 类型检查很慢 | 开发体验差 | 用项目引用与增量构建 |

### 手把手练习：加一个类型检查脚本

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "tsc --noEmit && vite build",
    "check": "npm run typecheck && npm run lint && npm test -- --run"
  }
}
```

把 `npm run check` 作为提交前与 CI 的统一入口，能避免「忘了跑某一项」。

### 学完自测

- [ ] 能说出 `tsc --noEmit` 与打包器各自负责什么。
- [ ] 知道路径别名为什么要在两处配置。
- [ ] 能说出 `strict` 与 `noUncheckedIndexedAccess` 的作用。
- [ ] 知道 CI 里最少要跑哪几条命令。
- [ ] 能解释为什么要提交 lockfile 并使用 `npm ci`。

## 动手练习

> 本课练习重点：围绕「TypeScript、tsconfig、strict」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. TypeScript 工程配置与实践解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「tsconfig」是什么关系？

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
- 至少覆盖「TypeScript」和「tsconfig」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 安装依赖 | `npm ci` | 依赖与锁文件一致 |
| 类型检查 | `npx tsc --noEmit` | 没有类型错误 |
| 运行测试 | `npm test` | 测试全部通过 |
| 构建 | `npm run build` | 产物生成成功 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条测试，其中包含一条非法输入或失败路径。
- [ ] 重复执行同一操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

## 可运行练习

### 任务 1：先跑通，再解释

```typescript
// tsconfig 里配 paths 只解决「类型解析」
import { api } from "@/lib/api";
```

### 任务 2：只改一个条件

把「TypeScript 工程配置与实践」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把TypeScript的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「TypeScript 工程配置与实践」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响TypeScript。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 TypeScript 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 TypeScript 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 TypeScript 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“TypeScript 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 TypeScript 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 tsconfig 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 tsconfig 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 tsconfig 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“tsconfig 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 tsconfig 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，TypeScript 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

- TypeScript 5.x 主线持续收紧类型推导、装饰器与模块解析行为
- 升级前先跑 tsc --noEmit，再处理构建工具与 ESLint 规则差异

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「用 Vite/esbuild 打包时会做类型检查吗？」的判断依据。
- [ ] 不看解析，能说出「接口返回数据应该如何处理？」的判断依据。
- [ ] 不看解析，能说出「团队禁止 any 后，处理未知数据应使用？」的判断依据。
- [ ] 不看解析，能说出「tsconfig 中 strict: true 会开启什么？」的判断依据。
- [ ] 不看解析，能说出「tsconfig 里 paths 别名的作用与限制是？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 本课语境 |
| --- | --- |
| `strict` | \| `strict` \| 必开，含 strictNullChecks、noImplicitAny 等 \| |
| `noUncheckedIndexedAccess` | \| `noUncheckedIndexedAccess` \| 数组下标访问返回 `T \\| undefined`，更安全 \| |
| `T \| undefined` | \| `noUncheckedIndexedAccess` \| 数组下标访问返回 `T \\| undefined`，更安全 \| |
| `exactOptionalPropertyTypes` | \| `exactOptionalPropertyTypes` \| 区分「缺失」与「undefined」 \| |
| `paths` | \| `paths` \| 配置 `@/` 别名，避免 `../../..` \| |
| `@/` | \| `paths` \| 配置 `@/` 别名，避免 `../../..` \| |

## 考点精讲

### 考点 1：多选辨析·TypeScript

- **题目**：围绕“TypeScript 工程配置与实践”中的 TypeScript、tsconfig、strict，下列哪两项是本课强调的实践判断？
- **判断依据**：在「TypeScript 工程配置与实践」里，学习 TypeScript 时要同时说明输入、输出和失败路径，不能只看正常流程。在TypeScript 工程配置与实践里，判断 tsconfig 时要固定版本与边界输入，所以“验证 tsconfig 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·TypeScript

- **题目**：接口返回数据应该如何处理？
- **判断依据**：在「TypeScript 工程配置与实践」里，作答时，先用TypeScript建立输入与输出的基线，再把用 zod 等做运行时校验后再使用代入边界条件核对，结论才能复现。“接口返回数据应该如何处理”与「TypeScript 工程配置与实践」的术语表相呼应，只有符合TypeScript、tsconfig、strict约束的“用 zod 等做运行时校验后再使用”才是正文支持的结论。

### 考点 3：概念判断·TypeScript

- **题目**：团队禁止 any 后，处理未知数据应使用？
- **判断依据**：在「TypeScript 工程配置与实践」里，unknown + 类型收窄。unknown 强制显式校验，是最安全的未知类型。把“unknown + 类型收窄”代回「TypeScript 工程配置与实践」里“团队禁止 any 后”的例子核对，条件一旦改变，结论就要用TypeScript、tsconfig、strict重新推导。

### 考点 4：代码补全·TypeScript

- **题目**：下面这段 TypeScript 代码摘自「TypeScript 工程配置与实践」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「TypeScript 工程配置与实践」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「TypeScript 工程配置与实践」的正文示例，围绕TypeScript、tsconfig、strict展开；把输入或边界换成空值、极值或失败情况后，结论要以「TypeScript 工程配置与实践」的实际运行结果为准。

### 考点 5：概念判断·TypeScript

- **题目**：tsconfig 里 paths 别名的作用与限制是？
- **判断依据**：在「TypeScript 工程配置与实践」里，配置模块路径别名。tsc 只做类型解析，实际产物路径由打包器或运行时的解析规则决定。把“配置模块路径别名”代回「TypeScript 工程配置与实践」里“tsconfig 里 paths 别名的作用与限制是”的例子核对，条件一旦改变，结论就要用TypeScript、tsconfig、strict重新推导。

### 考点 6：填空·"____": true,

- **题目**：补全代码：「TypeScript 工程配置与实践」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"____": true,`
- **判断依据**：空格应填写「noUncheckedIndexedAccess」、「nouncheckedindexedaccess」。这道题的关键在「TypeScript 工程配置与实践」的TypeScript、tsconfig、strict：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。

## English Overview

**Title:** TypeScript in Production

**Summary:** Strict mode, tsc in CI, runtime validation and conventions.

**Category:** TypeScript
**Level:** 基础
**Key terms:** TypeScript, tsconfig, strict, zod, CI

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、tsconfig、strict、zod、CI
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：TypeScript 工程配置与实践

### 核心场景

strict、tsc --noEmit、zod 运行时校验与团队规范。 项目目标是把「TypeScript、tsconfig、strict、zod、CI」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | TypeScript、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。

## 项目交付物

### 建议仓库结构

```text
src/
  domain/
  adapters/
tests/
tsconfig.json
package.json
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "ts_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「TypeScript、tsconfig、strict」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

## Full English Study Guide

### Overview

**TypeScript in Production** focuses on Strict mode, tsc in CI, runtime validation and conventions.

### Learning Outcomes

- Explain what **TypeScript in Production** solves and when it should be used.

### Glossary

- Topic: **TypeScript in Production**
- Related terms: TypeScript, tsconfig, strict, zod

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| tsconfig 关键选项 | tsconfig 关键选项 |
| 类型检查与构建分离 | Types检查与Build分离 |
| 运行时校验不可省 | 运行时校验不可省 |
| 与框架集成 | 与框架集成 |
| 团队规范 | 团队规范 |
| 本课小结 | Summary |
| tsconfig 关键配置速查 | tsconfig 关键配置速查 |
| 类型检查与构建的分工速查 | Types检查与Build的分工速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [tsconfig 参考](https://www.typescriptlang.org/tsconfig/) | 编译选项与严格模式 |
| [TypeScript Node 指南](https://nodejs.org/en/learn/typescript) | Node 中的 TypeScript |
| [声明文件](https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html) | 类型声明与发布 |

> 「TypeScript 工程配置与实践」的链接用于离线阅读后的延伸核对；App 不会自动联网。
