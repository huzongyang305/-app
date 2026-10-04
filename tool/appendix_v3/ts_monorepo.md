## 零基础详解：Monorepo 与多包协作

### 一句话说清它是什么

Monorepo 是「把多个包放进同一个仓库」的组织方式。
好处是跨包改动一次提交完成、类型即时联动；代价是**构建与 CI 必须做增量**，否则会越来越慢。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| workspace | 一栋楼里的多个房间 | 同仓库管理多个包 |
| 内部依赖 | 隔壁借东西 | 用 workspace 协议而不是发布到 npm |
| 任务编排 | 施工排期 | 按依赖顺序构建 |
| 受影响分析 | 只修坏掉的那几间 | 只跑相关任务 |
| 缓存 | 复用上次成果 | 没变就不重跑 |

### 什么时候该用 Monorepo

| 场景 | 建议 |
| --- | --- |
| 前后端共享类型定义 | ✅ 收益明显 |
| 多个包需要同步发版 | ✅ 一次提交改完 |
| 只有一个应用 | ❌ 直接单包更简单 |
| 团队完全独立、几乎不共享代码 | ❌ 拆分仓库更合适 |

### 目录结构

```text
repo/
  apps/
    web/                 前端应用
    api/                 后端服务
  packages/
    ui/                  共享组件
    types/               共享类型
    config/              共享配置（eslint、tsconfig）
  pnpm-workspace.yaml
  turbo.json
  package.json
```

### 两个关键配置文件

```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"
```

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "typecheck": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["build"], "outputs": ["coverage/**"] },
    "lint": {}
  }
}
```

| 配置 | 作用 |
| --- | --- |
| `dependsOn: ["^build"]` | 先构建依赖的包 |
| `outputs` | 声明产物路径，用于缓存 |
| 根 `package.json` 脚本 | 用 `turbo run build` 一键跑全部 |

### 内部依赖怎么写

```json
// packages/ui/package.json
{
  "name": "@myapp/ui",
  "version": "0.0.0",
  "private": true,
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": { "types": "./dist/index.d.ts", "import": "./dist/index.js" }
  }
}
```

```json
// apps/web/package.json
{
  "dependencies": {
    "@myapp/ui": "workspace:*"
  }
}
```

`workspace:*` 让本地包直接链接，不用先发布到 npm。

### CI 里只跑受影响的包

```yaml
- run: pnpm install --frozen-lockfile
- run: pnpm turbo run lint typecheck test build --filter='...[origin/main]'
```

| 过滤写法 | 含义 |
| --- | --- |
| `--filter=web` | 只跑 web 包 |
| `--filter='...[origin/main]'` | 只跑相对 main 有变化的包及其依赖者 |
| `--filter=@myapp/ui...` | ui 包及其依赖 |
| `--filter=...^build` | 只跑构建任务 |

### 三个必须守住的约定

```text
1. 每个包自己声明依赖，不靠「根目录恰好装了」这种巧合
2. 共享配置抽成 @myapp/config，各处 extends 它，避免规则漂移
3. 内部包设为 private，避免误发布到公共仓库
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 依赖靠提升「碰巧能用」 | 别人机器上装不起来 | 每个包显式声明依赖 |
| 忘记声明 outputs | 缓存失效，每次都重跑 | 在 turbo.json 写清产物 |
| 全量跑 CI | 一小时起步 | 用 `--filter` 只跑受影响 |
| 用 `*` 版本引用内部包 | 装到旧的远端版本 | 用 `workspace:*` |
| 内部包被误发布 | 公开仓库出现私有代码 | 加 `"private": true` |
| 循环依赖 | 构建顺序无法确定 | 拆出公共包打破环 |
| tsconfig 各写一套 | 类型行为不一致 | 抽共享配置 |
| lockfile 未提交 | 版本不一致 | 提交并 CI 用 frozen-lockfile |

### 手把手练习：加一个共享类型包

```json
// packages/types/package.json
{
  "name": "@myapp/types",
  "version": "0.0.0",
  "private": true,
  "types": "./src/index.ts",
  "exports": { ".": "./src/index.ts" }
}
```

```typescript
// packages/types/src/index.ts
export type User = {
  id: number;
  name: string;
  email?: string;
};

export type ApiResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };
```

```typescript
// apps/api/src/handler.ts
import type { ApiResult, User } from "@myapp/types";

export function getUser(id: number): ApiResult<User> {
  if (id <= 0) return { ok: false, error: "id 不合法" };
  return { ok: true, data: { id, name: "小明" } };
}
```

```bash
pnpm install
pnpm turbo run typecheck --filter='...[origin/main]'
```

### 学完自测

- [ ] 能说出 Monorepo 的两个收益与两个代价。
- [ ] 知道 `workspace:*` 解决什么问题。
- [ ] 能说出 `dependsOn: ["^build"]` 的含义。
- [ ] 知道 CI 为什么要用 `--filter=...[origin/main]`。
- [ ] 能说出内部包必须加 `private` 的原因。
