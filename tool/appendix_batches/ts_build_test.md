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
