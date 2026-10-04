# TypeScript 实战：全栈类型安全

![TypeScript 实战：全栈类型安全](images/remaining_ts_fullstack_project.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「TypeScript 实战：全栈类型安全」解决了什么问题，而不是只背术语。
- 能说清 「TypeScript」、「全栈」、「zod」、「tRPC」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：共享 schema、运行时校验与端到端类型。

## 前置知识

- 先完成上一课《TypeScript 构建工具链与测试》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：TypeScript、全栈、zod。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 目标

让前端与后端共享同一套类型契约，把"接口对不上"这类问题消灭在编译期。

## 共享类型包

把请求/响应类型放到独立包（monorepo 里的 `packages/shared`），前后端都依赖它；类型变更时编译会同时暴露两端的不兼容，比联调时才发现便宜得多。用 workspace（pnpm/npm/yarn）管理本地包引用。

## 运行时契约

类型只存在于编译期，因此服务端入口与客户端出口都要校验：

```text
// shared/schema.ts
export const CreateUser = z.object({ name: z.string().min(1), age: z.number().int().min(0) });
export type CreateUser = z.infer<typeof CreateUser>;   // 类型从 schema 推导，单一事实来源
```

服务端用同一 schema 校验请求体，客户端用同一 schema 校验响应，双方共享定义但各自保证运行时安全。

## 接口层

方案从轻到重：手写 fetch 封装（简单）→ OpenAPI 生成客户端（跨语言友好）→ tRPC（全 TS 项目，端到端类型推断，改后端接口前端立刻报错）。选择依据是团队语言栈与是否需要对外开放 API。

## 端到端流程

1. 定义 schema 与类型（shared）。
2. 服务端：路由 + 校验 + 业务 + 返回类型化 DTO。
3. 客户端：调用 + 校验响应 + 状态管理。
4. 测试：schema 单测、接口集成测试、前端组件测试。
5. CI：lint → tsc → test → build，任一步失败阻断合并。

## 常见坑

1. 前后端各写一份类型导致漂移——必须单一来源。
2. 只信任编译期类型，跳过运行时校验——外部输入永远不可信。
3. 版本升级时类型破坏性变更没有通知机制——用 changesets 管理版本与变更日志。
4. 过度使用 any 绕过类型错误，把问题推迟到线上。

## 本课小结
全栈类型安全的关键是**单一事实来源（schema）+ 两端运行时校验 + CI 强制类型检查**；做到这三点，接口联调成本会大幅下降。

<!-- appendix:v1 -->

## 端到端类型安全速查

| 方案 | 做法 | 适用 |
| --- | --- | --- |
| 共享类型包 | monorepo 内 `packages/shared` 放 DTO 与校验 schema | 前后端同仓 |
| OpenAPI / Swagger | 后端产出规范，前端生成客户端 | 跨团队、多语言 |
| tRPC | 直接调用后端过程，自动推断类型 | 全 TS、同仓、同框架 |
| GraphQL Codegen | 由 schema 生成类型与 hooks | GraphQL 项目 |
| Prisma | 由数据库 schema 生成类型安全客户端 | Node 后端 |

```ts
// 共享 schema：类型与运行时校验来自同一处定义
import { z } from "zod";

export const CreateOrderSchema = z.object({
  userId: z.string().uuid(),
  items: z.array(z.object({
    sku: z.string().min(1),
    quantity: z.number().int().positive(),
  })).min(1),
  note: z.string().max(200).optional(),
});

export type CreateOrderInput = z.infer<typeof CreateOrderSchema>;

// 服务端：解析失败返回 400，成功则拿到强类型数据
export function parseCreateOrder(body: unknown): CreateOrderInput {
  return CreateOrderSchema.parse(body);
}
```

## 契约与校验速查

| 环节 | 应该做什么 |
| --- | --- |
| 定义契约 | 用 schema 描述请求与响应结构 |
| 服务端校验 | 入口处 `parse`，失败返回 400 与字段错误 |
| 客户端类型 | 由 schema 推断，不手写重复类型 |
| 数据库约束 | 与业务规则一致（唯一、非空、长度） |
| 版本演进 | 新增字段可选，废弃字段先标注再移除 |
| 兼容性 | 用契约测试或生成物 diff 检测破坏性变更 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 前后端各写一份类型 | 字段漂移，运行时才发现 | 共享 schema 或由 OpenAPI 生成 |
| 只做编译期校验 | 非法请求进入业务逻辑 | 入口处做运行时校验 |
| 直接信任 `req.body` 类型 | 类型是断言出来的 | 用 `unknown` + schema 解析 |
| 契约破坏性变更不通知 | 客户端批量报错 | 契约测试 + 版本化 |
| 在客户端校验代替服务端校验 | 绕过前端即可攻击 | 服务端必须独立校验 |
| 数据库缺少约束 | 脏数据进入系统 | 加唯一、非空、外键约束 |
| 用 `any` 转换响应 | 失去类型安全 | 解析后推断类型 |
| 时间字段用字符串随意比较 | 时区与格式混乱 | 统一 ISO 8601 / UTC |
| 金额用浮点数 | 精度误差 | 用整数最小单位或 decimal 字符串 |
| 错误响应结构不统一 | 前端处理分支混乱 | 统一错误结构（code/message/details） |

## 自测清单

- [ ] 前后端类型来自同一份 schema 或生成物。
- [ ] 入口做运行时校验，失败返回明确字段错误。
- [ ] 数据库约束与业务规则保持一致。
- [ ] 契约变更经过兼容性检查。
- [ ] 时间与金额的表示方式全链路统一。

<!-- appendix:v3 -->

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

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「TypeScript、全栈、zod」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「TypeScript 实战：全栈类型安全」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「全栈」是什么关系？

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
- 至少覆盖「TypeScript」和「全栈」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

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

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Full-stack Type Safety

**Summary:** Shared schemas, runtime validation and e2e types.

**Category:** TypeScript  
**Level:** 高级  
**Key terms:** TypeScript, 全栈, zod, tRPC, monorepo

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：TypeScript、全栈、zod、tRPC、monorepo
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：TypeScript 实战：全栈类型安全

### 核心场景

共享 schema、运行时校验与端到端类型。 项目目标是把「TypeScript、全栈、zod、tRPC、monorepo」落实为可运行、可测试、可回滚的交付物。

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

<!-- project-delivery:v1 -->

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
  "project": "ts_fullstack_project",
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

> 项目验收围绕「TypeScript、全栈、zod」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

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

> 本课主题：共享 schema、运行时校验与端到端类型。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

