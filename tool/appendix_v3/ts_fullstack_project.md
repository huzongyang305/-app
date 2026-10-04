## 零基础详解：全栈 TypeScript 项目

### 一句话说清它是什么

全栈 TypeScript 的核心价值是**一份类型定义两端共用**，改接口时前端立即报错。
前提是：类型来自同一份 schema，而不是两边各写一份。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| schema | 合同的原始稿 | 唯一事实来源 |
| 运行时校验 | 开箱验货 | 类型在运行时不存在 |
| 端到端类型 | 一条线贯穿两端 | 后端改字段，前端立刻报错 |
| 契约优先 | 先定接口再写实现 | 前后端可并行开发 |

### 三种共享类型的方式

| 方式 | 类型安全 | 运行时校验 | 适合 |
| --- | --- | --- | --- |
| 手写共享类型包 | 中 | 需自己加 | 简单项目 |
| OpenAPI 生成客户端 | 强 | 需自己加 | 已有 REST 接口、对外提供 API |
| tRPC | 最强 | 配合 zod | 前后端同仓库的 TS 项目 |

### 统一事实来源：zod schema

```typescript
// packages/shared/src/user.ts
import { z } from "zod";

export const UserSchema = z.object({
  id: z.number().int().positive(),
  name: z.string().min(1).max(50),
  email: z.string().email(),
  role: z.enum(["admin", "user"]).default("user"),
});

export type User = z.infer<typeof UserSchema>;

export const CreateUserSchema = UserSchema.omit({ id: true });
export type CreateUserInput = z.infer<typeof CreateUserSchema>;
```

```typescript
// 后端：入参必须先过 schema
app.post("/users", async (req, reply) => {
  const parsed = CreateUserSchema.safeParse(req.body);
  if (!parsed.success) {
    return reply.status(400).send({
      error: "参数不合法",
      issues: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`),
    });
  }
  const user = await createUser(parsed.data);
  return reply.status(201).send(UserSchema.parse(user)); // 出参也校验
});
```

```typescript
// 前端：同一份类型
import { type User, UserSchema } from "@app/shared/user";

async function loadUser(id: number): Promise<User> {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error(`请求失败 ${res.status}`);
  const data: unknown = await res.json();
  return UserSchema.parse(data);     // 运行时真的校验
}
```

**关键点：入参和出参都要校验。** 只校验入参，脏数据照样会流向前端。

### tRPC：端到端类型推断

```typescript
// server/router.ts
import { initTRPC } from "@trpc/server";
import { z } from "zod";

const t = initTRPC.create();

export const appRouter = t.router({
  userById: t.procedure
    .input(z.object({ id: z.number().int().positive() }))
    .query(({ input }) => findUser(input.id)),

  createUser: t.procedure
    .input(CreateUserSchema)
    .mutation(({ input }) => createUser(input)),
});

export type AppRouter = typeof appRouter;
```

```typescript
// client.ts
import { createTRPCClient, httpBatchLink } from "@trpc/client";
import type { AppRouter } from "./server/router";

const client = createTRPCClient<AppRouter>({
  links: [httpBatchLink({ url: "/trpc" })],
});

const user = await client.userById.query({ id: 1 });   // 完全类型安全
```

改后端字段名，前端会立刻编译报错——这就是端到端类型的价值。

### 错误处理：统一结构

```typescript
export type ApiError = {
  error: string;         // 给人看
  code: string;          // 给程序判断
  issues?: string[];     // 校验明细
  requestId?: string;    // 便于排查
};

export class AppError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly status = 400,
  ) {
    super(message);
  }
}
```

前端只根据 `code` 分支，**绝不比较文案**（文案随时会改）。

### 环境变量两端各自的注意事项

```typescript
// 服务端：启动时校验
const ServerEnv = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
});
export const env = ServerEnv.parse(process.env);

// 前端：只暴露前缀变量，且它们会被打进产物，绝不能放密钥
const PublicEnv = z.object({
  VITE_API_BASE: z.string().url(),
});
export const publicEnv = PublicEnv.parse(import.meta.env);
```

**前端环境变量是公开的**，任何密钥都不能放进去。

### 全栈项目的 CI

```yaml
- run: pnpm install --frozen-lockfile
- run: pnpm typecheck                    # 两端一起检查类型
- run: pnpm lint
- run: pnpm test -- --run
- run: pnpm --filter shared build        # 先构建共享包
- run: pnpm --filter web build
- run: pnpm --filter api build
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 两端各写一份类型 | 字段改了不同步 | 共用 schema |
| 只校验入参 | 脏数据流向客户端 | 入参出参都校验 |
| 用 `as User` 代替校验 | 运行时崩溃 | `parse` 或 `safeParse` |
| 前端放密钥 | 打包后公开 | 只放公开配置 |
| 比较错误文案 | 文案一改就失效 | 用 `code` |
| 共享包没先构建 | 本地能跑 CI 报错 | CI 里按依赖顺序构建 |
| 类型推断太深导致编译慢 | 开发体验差 | 拆分类型、减少体操 |
| 忽略删除字段的兼容 | 老客户端崩 | 先保留字段再下线 |

### 学完自测

- [ ] 能说出三种共享类型方式的取舍。
- [ ] 知道为什么入参与出参都要校验。
- [ ] 能说出 tRPC 相比手写类型的优势。
- [ ] 知道前端环境变量为什么不能放密钥。
- [ ] 能说出全栈 CI 里至少要跑哪些步骤。
