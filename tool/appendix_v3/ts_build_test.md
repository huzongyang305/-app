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
