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
