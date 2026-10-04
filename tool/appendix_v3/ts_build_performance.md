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
