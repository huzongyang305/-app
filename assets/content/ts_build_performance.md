# 类型检查与构建性能优化

![类型检查与构建性能优化](images/remaining_ts_build_performance.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「类型检查与构建性能优化」解决了什么问题，而不是只背术语。
- 能说清 「类型检查性能」、「incremental」、「项目引用」、「skipLibCheck」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：定位类型检查热点、增量构建与 CI 分工。

## 前置知识

- 先完成上一课《TypeScript 测试策略》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：类型检查性能、incremental、项目引用。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 慢在哪里：先定位再优化

| 手段 | 命令 | 看什么 |
| --- | --- | --- |
| 生成耗时报告 | `tsc --noEmit --extendedDiagnostics` | 总时间、文件数、类型数 |
| 定位最慢文件 | `tsc --noEmit --generateTrace trace` | trace 里的耗时热点 |
| 检查项目引用 | `tsc --build --verbose` | 是否真的增量 |
| 打包分析 | `vite build --mode analyze` 或 source-map-explorer | 产物体积构成 |
| 依赖体积 | `npx vite-bundle-visualizer` | 哪个依赖最大 |

经验：**大部分类型检查慢，来自过深的类型推导、过大的单一项目与无节制的第三方类型参与检查。**

## 提速手段速查

| 手段 | 效果 | 代价 |
| --- | --- | --- |
| `skipLibCheck: true` | 跳过依赖声明文件检查 | 依赖类型错误不会被发现 |
| 项目引用 + `composite` | 只重检查改动项目 | 配置复杂 |
| `incremental` + `tsBuildInfoFile` | 复用上次结果 | 需要缓存产物 |
| 收窄 `include` | 减少参与文件 | 需确保不漏文件 |
| 避免巨型联合与深层泛型 | 减少推导爆炸 | 需要重构类型 |
| 拆包与懒加载 | 减小主包体积 | 增加分包复杂度 |
| 用 SWC / esbuild 转译 | 转译极快 | 不做类型检查，需单独跑 tsc |

```jsonc
// 推荐的 tsconfig 组合：类型检查快、职责清晰
{
  "compilerOptions": {
    "incremental": true,
    "tsBuildInfoFile": "./node_modules/.cache/tsbuildinfo",
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "isolatedModules": true,
    "moduleDetection": "force"
  },
  "include": ["src", "tests", "types"],
  "exclude": ["dist", "node_modules", "coverage"]
}
```

```json
{
  "scripts": {
    "typecheck": "tsc --noEmit",
    "typecheck:trace": "tsc --noEmit --generateTrace .trace",
    "build": "vite build",
    "size": "source-map-explorer dist/assets/*.js"
  }
}
```

## CI 中的分工

| 阶段 | 工具 | 目的 |
| --- | --- | --- |
| 转译 / 打包 | esbuild、SWC、Vite | 快速产出产物 |
| 类型检查 | `tsc --noEmit` | 独立门禁，不可省略 |
| 体积门禁 | 打包分析 | 主包超过阈值则失败 |
| 缓存 | 依赖与 tsbuildinfo | 加速重复构建 |

注意：**打包器不做类型检查**，CI 必须单独跑一次 `tsc --noEmit`。

## 类型层面的性能陷阱

| 陷阱 | 后果 | 处理 |
| --- | --- | --- |
| 巨量联合类型（上千成员） | 每处判断都要遍历 | 拆分或用映射表 |
| 递归类型无深度限制 | 推导爆炸 | 限制递归层数 |
| 交叉类型层层叠加 | 属性合并极慢 | 明确定义接口 |
| 在类型里做复杂字符串运算 | 编译器负担重 | 运行时处理更合适 |
| 全量 `include` 包含测试与脚本 | 检查范围膨胀 | 分离 tsconfig |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `skipLibCheck` 掩盖自身错误 | 自己的类型错误仍在 | 它只跳过 .d.ts，按需使用 |
| 只跑打包不跑类型检查 | 类型错误进线上 | CI 加 `tsc --noEmit` |
| 打开 incremental 但不缓存产物 | 每次都全量 | CI 持久化 tsbuildinfo |
| 单项目包含所有代码 | 改一行全量检查 | 用项目引用拆分 |
| 盲目内联所有依赖 | 主包巨大 | 按路由拆包、懒加载 |
| 只看构建总时长 | 不知优化方向 | 用 extendedDiagnostics 定位 |

## 自测清单

- [ ] 会用 `--extendedDiagnostics` 与 `--generateTrace` 定位慢点。
- [ ] 开启 incremental 并在 CI 中缓存构建信息。
- [ ] 用项目引用拆分大仓库，只重检查改动部分。
- [ ] CI 独立跑 `tsc --noEmit` 作为类型门禁。
- [ ] 有产物体积门禁，避免依赖膨胀。

<!-- appendix:v3 -->

## 零基础详解：让 TypeScript 构建变快

### 一句话说清它是什么

大项目变慢通常来自三处：**类型检查太慢、重复构建、缓存没命中**。
解决思路是：拆分项目、增量构建、并行与缓存，以及别让类型检查挡住开发。

### 用生活比喻理解

| 手段 | 比喻 | 说明 |
| --- | --- | --- |
| 项目引用 | 分车间生产 | 每个子项目独立编译 |
| 增量构建 | 只修坏掉的零件 | 用 `.tsbuildinfo` 记录状态 |
| 转译器 | 快速流水线 | esbuild 与 swc 只转译不检查 |
| 缓存 | 复用上次成果 | 输入没变就不重跑 |
| 并行 | 多线开工 | 多个包同时构建 |

### 第一步：先测量，别猜

```bash
# 类型检查耗时
time npx tsc --noEmit --extendedDiagnostics

# 看哪些文件最耗时
npx tsc --noEmit --generateTrace trace
npx @typescript/analyze-trace trace
```

`--extendedDiagnostics` 会输出「检查了多少文件、用了多少内存、最慢的环节」，先看这些数字。

### 第二步：项目引用与增量

```json
// 根 tsconfig.json
{
  "files": [],
  "references": [
    { "path": "./packages/types" },
    { "path": "./packages/ui" },
    { "path": "./apps/web" }
  ]
}
```

```json
// packages/ui/tsconfig.json
{
  "extends": "../config/tsconfig.base.json",
  "compilerOptions": {
    "composite": true,
    "incremental": true,
    "tsBuildInfoFile": "./dist/.tsbuildinfo",
    "declaration": true,
    "outDir": "./dist",
    "rootDir": "./src"
  },
  "include": ["src"]
}
```

```bash
npx tsc --build          # 只重新编译有变化的部分
npx tsc --build --clean  # 清理
```

### 第三步：开发用转译，提交前再检查

| 场景 | 工具 | 说明 |
| --- | --- | --- |
| 本地开发热更新 | Vite、esbuild、swc | 只转译，毫秒级反馈 |
| 提交前与 CI | `tsc --noEmit` | 完整类型检查 |
| 库产物 | tsup、rollup | 产出 ESM/CJS 与 d.ts |

**不要指望打包器做类型检查**，两边分工才能又快又稳。

### 第四步：配置层面的提速开关

```json
{
  "compilerOptions": {
    "incremental": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true
  },
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

| 选项 | 作用 | 注意 |
| --- | --- | --- |
| `incremental` | 复用上次结果 | 保留 `.tsbuildinfo` |
| `skipLibCheck` | 跳过第三方声明检查 | 只跳第三方，不跳自己的代码 |
| `exclude` 测试文件 | 减少检查量 | CI 里再单独检查测试 |
| `isolatedModules` | 每个文件独立转译 | 兼容 esbuild 与 swc |
| `composite` | 支持项目引用 | 必须配 `declaration` |

### 第五步：CI 里的并行与缓存

```yaml
jobs:
  typecheck:
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: npm }
      - run: npm ci
      - uses: actions/cache@v4
        with:
          path: "**/*.tsbuildinfo"
          key: tsbuild-${{ github.sha }}
          restore-keys: tsbuild-
      - run: npx tsc --build
```

在 monorepo 里再配合 `turbo run typecheck --filter='...[origin/main]'`，只检查受影响的包。

### 什么时候该重构而不是调参数

| 症状 | 建议 |
| --- | --- |
| 单个文件几千行 | 拆分模块 |
| 类型体操层层嵌套 | 简化或加缓存类型 |
| 一个包要检查上万文件 | 按职责拆成多个子项目 |
| 循环依赖多 | 抽出公共包 |
| 每个文件都 import 整个 barrel | 直接从具体文件导入 |

**barrel 文件（`index.ts` 汇总导出）很方便，但会让类型检查范围大幅膨胀**，大项目里要谨慎。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 没有基线数据 | 不知道优化有没有效果 | 先用 `--extendedDiagnostics` |
| 删掉 `.tsbuildinfo` | 每次都全量 | 加入缓存并保留 |
| 把 `skipLibCheck` 当万能 | 自己代码的问题被掩盖 | 它只跳第三方声明 |
| 用 barrel 全量导出 | 检查范围爆炸 | 直接从具体模块导入 |
| 开发时跑完整类型检查 | 热更新变慢 | 开发用转译，提交前检查 |
| CI 每次都全量构建 | 时间随代码线性增长 | 增量加受影响分析 |
| 单进程串行跑所有包 | 浪费机器 | 并行 job 或任务编排 |
| 只看总耗时 | 找不到瓶颈 | 看 trace 定位 |

### 学完自测

- [ ] 能说出项目引用解决的什么问题。
- [ ] 知道 `incremental` 依赖哪个文件。
- [ ] 能说出 `skipLibCheck` 的边界。
- [ ] 知道为什么 barrel 文件会拖慢类型检查。
- [ ] 能说出 CI 里加速的三条手段。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「类型检查性能、incremental、项目引用」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「类型检查与构建性能优化」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「incremental」是什么关系？

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
- 至少覆盖「类型检查性能」和「incremental」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「类型检查与构建性能优化」不是孤立术语，而是在「TypeScript」中解决一类具体问题。
- 关键关系：先分清「类型检查性能」与「incremental」的职责，再理解「项目引用」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Build & Typecheck Performance

**Summary:** Diagnosing typecheck hotspots, incremental builds and CI split.

**Category:** TypeScript  
**Level:** 高级  
**Key terms:** 类型检查性能, incremental, 项目引用, skipLibCheck, 体积门禁

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：类型检查性能、incremental、项目引用、skipLibCheck、体积门禁
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) | 类型系统与编译配置 |
| [Decorators 与模块](https://www.typescriptlang.org/docs/) | 语言特性与生态集成 |

> 本课主题：定位类型检查热点、增量构建与 CI 分工。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

