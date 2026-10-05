# TypeScript Node 后端开发

![TypeScript Node 后端开发](images/remaining_ts_node_backend.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「TypeScript Node 后端开发」解决了什么问题，而不是只背术语。
- 能说清 「Node后端」、「Fastify」、「NestJS」、「zod」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「TypeScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：框架选型、分层职责、schema 校验与生产必做项。

## 前置知识

- 先完成上一课《TypeScript 类型体操进阶》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Node后端、Fastify、NestJS。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 框架选型速查

| 框架 | 定位 | 特点 |
| --- | --- | --- |
| Express | 极简 | 生态最大，需要自己拼装 |
| Fastify | 高性能 | Schema 校验内建、插件体系 |
| NestJS | 企业级 | 模块、依赖注入、装饰器，约定强 |
| Hono | 轻量 + 多运行时 | 适合边缘函数与 Node |

选择依据：团队规模与约定强度。小服务用 Fastify，团队大、模块多用 NestJS。

## 分层与职责速查

| 层 | 职责 | 不该做 |
| --- | --- | --- |
| 路由 / 控制器 | 参数解析、校验、状态码 | 写业务规则 |
| 服务层 | 业务规则与编排 | 直接依赖 HTTP 对象 |
| 仓储层 | 数据访问 | 业务判断 |
| DTO / Schema | 请求与响应结构 | 暴露内部实体 |
| 中间件 | 日志、鉴权、限流、错误处理 | 承载业务逻辑 |

```ts
import Fastify from "fastify";
import { z } from "zod";

// 用 schema 同时完成运行时校验与类型推断
const CreateOrderSchema = z.object({
  userId: z.string().uuid(),
  items: z
    .array(z.object({ sku: z.string().min(1), quantity: z.number().int().positive() }))
    .min(1),
});
type CreateOrderInput = z.infer<typeof CreateOrderSchema>;

const app = Fastify({ logger: { level: "info" } });

app.post("/api/orders", async (request, reply) => {
  const parsed = CreateOrderSchema.safeParse(request.body);
  if (!parsed.success) {
    // 统一错误结构，前端可稳定解析
    return reply.status(400).send({
      code: "INVALID_ARGUMENT",
      message: "参数校验失败",
      details: parsed.error.issues.map((issue) => ({
        path: issue.path.join("."),
        message: issue.message,
      })),
    });
  }

  try {
    const order = await orderService.create(parsed.data);
    return reply.status(201).send(order);
  } catch (error) {
    if (error instanceof OrderConflictError) {
      return reply.status(409).send({ code: "CONFLICT", message: error.message });
    }
    request.log.error({ err: error }, "创建订单失败");
    return reply.status(500).send({ code: "INTERNAL", message: "服务异常" });
  }
});

// 进程级兜底：未捕获异常与未处理拒绝都要记录后退出，交给编排重启
process.on("uncaughtException", (error) => {
  app.log.fatal({ err: error }, "未捕获异常，进程退出");
  process.exit(1);
});
process.on("unhandledRejection", (reason) => {
  app.log.fatal({ err: reason }, "未处理的 Promise 拒绝，进程退出");
  process.exit(1);
});
```

## 生产必做项速查

| 项 | 做法 |
| --- | --- |
| 优雅关闭 | 监听 SIGTERM，停止接收新请求并等待在途请求 |
| 健康检查 | `/livez` 只看进程，`/readyz` 检查关键依赖 |
| 配置管理 | 启动时校验必填环境变量，缺失直接退出 |
| 日志 | 结构化 JSON，带 trace id，禁止打印敏感字段 |
| 超时 | 每个下游调用设置超时并提供取消信号 |
| 限流 | 按用户与 IP 维度限流，返回 429 与 Retry-After |
| 错误 | 统一错误结构，区分可重试与不可重试 |
| 依赖注入 | 构造注入，便于测试替换 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 直接把 `request.body as Order` | 运行时字段缺失导致崩溃 | 用 schema 校验后再使用 |
| 未捕获异常不记录就退出 | 线上无迹可查 | 记录 fatal 日志后退出 |
| 忽略 SIGTERM | 发布时请求被中断 | 实现优雅关闭 |
| 在控制器里写业务逻辑 | 无法复用与测试 | 抽到服务层 |
| 用 `any` 传请求体 | 类型安全失效 | 校验后使用推断类型 |
| 日志打印完整请求体 | 敏感信息泄漏 | 只记录必要字段并脱敏 |
| 单例连接池未配置上限 | 高并发下打满数据库 | 显式设置池大小与超时 |

## 自测清单

- [ ] 请求入参经 schema 校验并推断类型。
- [ ] 分层清晰，控制器不写业务逻辑。
- [ ] 实现优雅关闭与两个健康检查端点。
- [ ] 配置在启动时校验，缺失即失败。
- [ ] 日志结构化且脱敏，异常有兜底处理。


## 零基础详解：TypeScript 写 Node 后端

### 一句话说清它是什么

用 TypeScript 写后端，核心工作只有四件：**收请求、校验数据、处理业务、返回响应**。
框架（Express、Fastify、NestJS）只是把这四件事组织得更规整。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 路由 | 前台分诊 | 按路径把请求分给处理函数 |
| 中间件 | 安检通道 | 统一做日志、鉴权、错误处理 |
| DTO 校验 | 开箱验货 | 进来的数据必须先检查 |
| 服务层 | 后厨 | 真正的业务逻辑 |
| 数据层 | 仓库 | 与数据库打交道 |

### 分层结构

```text
src/
  app.ts            组装：注册中间件与路由
  server.ts         启动：监听端口、优雅关闭
  routes/user.ts    路由：只负责解析与返回
  services/user.ts  业务：纯逻辑，可单测
  repositories/     数据：SQL 或 ORM
  schemas/          zod 校验与类型
```

**原则**：路由层不写业务，业务层不碰 HTTP 对象，这样才测得好。

### 一个最小可用的 Fastify 服务

```typescript
import Fastify from "fastify";
import { z } from "zod";

const CreateUser = z.object({
  name: z.string().min(1).max(50),
  email: z.string().email(),
});

export function buildApp() {
  const app = Fastify({ logger: true });

  // 1. 统一错误处理
  app.setErrorHandler((error, _req, reply) => {
    app.log.error(error);
    reply.status(error.statusCode ?? 500).send({ error: error.message });
  });

  // 2. 健康检查
  app.get("/healthz/live", async () => ({ ok: true }));

  // 3. 业务路由：校验放在最前面
  app.post("/users", async (req, reply) => {
    const parsed = CreateUser.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({
        error: "参数不合法",
        issues: parsed.error.issues.map((i) => i.message),
      });
    }

    const user = await createUser(parsed.data);
    return reply.status(201).send(user);
  });

  return app;
}
```

### 启动与优雅关闭

```typescript
// server.ts
import { buildApp } from "./app.js";

const app = buildApp();
const port = Number(process.env.PORT ?? 3000);

try {
  await app.listen({ port, host: "0.0.0.0" });
} catch (error) {
  app.log.error(error);
  process.exit(1);
}

for (const signal of ["SIGTERM", "SIGINT"] as const) {
  process.on(signal, async () => {
    app.log.info(`收到 ${signal}，开始关闭`);
    await app.close();          // 等在途请求处理完
    process.exit(0);
  });
}
```

### 中间件的四件必备

| 中间件 | 作用 | 常见坑 |
| --- | --- | --- |
| 请求日志 | 记录方法、路径、耗时、状态码 | 别打印请求体里的敏感字段 |
| 身份认证 | 校验 token 并挂到 `req.user` | 忘记区分 401 与 403 |
| 参数校验 | 用 schema 校验 body、query、params | 只校验 body 漏掉 query |
| 错误处理 | 统一转成标准错误响应 | 把内部堆栈直接返回给用户 |

### 错误响应的统一格式

```typescript
type ApiError = {
  error: string;          // 给人看的信息
  code?: string;          // 给程序判断的稳定标识
  requestId?: string;     // 便于排查
  issues?: string[];      // 校验明细
};
```

**关键**：对外只暴露安全信息，细节写进日志；给程序判断要用 `code`，不要让它去比较文案。

### 状态码速查

| 码 | 含义 | 使用场景 |
| --- | --- | --- |
| 200 / 201 | 成功 / 已创建 | 查询成功、创建成功 |
| 204 | 成功但无内容 | 删除成功 |
| 400 | 参数错误 | 校验失败 |
| 401 | 未认证 | 没登录或 token 失效 |
| 403 | 无权限 | 已登录但越权 |
| 404 | 不存在 | 资源没找到 |
| 409 | 冲突 | 唯一键重复 |
| 429 | 请求过频 | 触发限流 |
| 500 | 服务端错误 | 未预期异常 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 路由里写业务逻辑 | 无法单测、难以复用 | 抽到服务层 |
| 不校验 query 与 params | 脏数据进业务 | 三处都校验 |
| 用 `any` 接请求体 | 类型形同虚设 | 用 `unknown` 加 schema |
| 把数据库错误直接返回 | 泄露表结构 | 转成统一错误 |
| 忘记优雅关闭 | 发布时请求被中断 | 监听信号并 `app.close()` |
| 每个请求新建连接池 | 连接耗尽 | 全局复用连接池 |
| 日志打印密码或 token | 泄露 | 白名单字段记录 |
| 没设超时 | 慢请求占满连接 | 设置请求与下游超时 |

### 手把手练习：带校验与分页的查询接口

```typescript
const ListQuery = z.object({
  page: z.coerce.number().int().min(1).default(1),
  size: z.coerce.number().int().min(1).max(100).default(20),
  keyword: z.string().trim().max(50).optional(),
});

app.get("/users", async (req, reply) => {
  const parsed = ListQuery.safeParse(req.query);
  if (!parsed.success) {
    return reply.status(400).send({ error: "查询参数不合法" });
  }

  const { page, size, keyword } = parsed.data;
  const { items, total } = await listUsers({ page, size, keyword });

  return reply.send({
    items,
    pagination: { page, size, total, pages: Math.ceil(total / size) },
  });
});
```

### 学完自测

- [ ] 能说出路由、服务、数据三层各自的职责。
- [ ] 知道为什么只校验 body 不够。
- [ ] 能说出 401 与 403 的区别。
- [ ] 知道优雅关闭要监听哪些信号。
- [ ] 能说出错误响应里 `code` 字段的用途。

## 动手练习


> 本课练习重点：围绕「Node后端、Fastify、NestJS」完成复述、实验和交付，每个结果都要能被别人检查。

先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「TypeScript Node 后端开发」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Fastify」是什么关系？

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
- 至少覆盖「Node后端」和「Fastify」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「TypeScript Node 后端开发」不是孤立术语，而是在「TypeScript」中解决一类具体问题。
- 关键关系：先分清「Node后端」与「Fastify」的职责，再理解「NestJS」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：处理请求体时，最安全的做法是？

- **正确判断**：用 schema 做运行时校验，再用推断出的类型
- **判断依据**：外部输入必须做运行时校验，schema 同时提供类型推断，做到一次定义两处受益。选项一、三只存在于编译期，运行时字段缺失照样崩溃。正确项「用 schema 做运行时校验，再用推断出的类型」正面回答了题目所问，符合课程给出的定义与适用范围。错误项「只做 TypeScript 类型标注」属于相邻主题的说法，范围与本题要求不一致。错误项「信任前端传来的字段」把不同概念混在一起，缺少题干限定的前提。错误项「直接把 request.body 断言为业务类型」与课程给出的定义相冲突，不能回答题目所问。把题干「处理请求体时，最安全的做法是？」放回《TypeScript Node 后端开发》的「框架选型、分层职责、schema 校验与生产必做项」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：收到 SIGTERM 时，服务应该？

- **正确判断**：停止接收新请求并等待在途请求完成后再退出
- **判断依据**：优雅关闭能避免发布或缩容时中断用户请求。选项一会造成大量 5xx 或被中断的写操作。选项四不属于进程职责，应由编排系统负责。正确项「停止接收新请求并等待在途请求完成后再退出」抓住了题干的核心条件，是经得起边界检验的表述。错误项「忽略信号」与课程给出的定义相冲突，不能回答题目所问。错误项「重启自身」只看到了表面现象，没有解释题干真正考查的机制。错误项「立刻退出进程（仅部分场景成立）」在边界或失败路径上会得出错误结果。把题干「收到 SIGTERM 时，服务应该？」放回《TypeScript Node 后端开发》的「框架选型、分层职责、schema 校验与生产必做项」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：liveness 与 readiness 探针的分工是？

- **正确判断**：liveness 判断进程是否需重启
- **判断依据**：liveness 失败触发重启，readiness 失败只从负载均衡摘除，职责不能混用。选项一、三、四都会导致误重启或错误摘流。正确项「liveness 判断进程是否需重启」既符合定义也满足题干限定的场景，因此应当选择。错误项「readiness 失败应重启容器」把因果关系颠倒了，不能作为正确结论。错误项「两者完全一样」忽略了题目中的限制条件，因此不成立。错误项「liveness 检查依赖，readiness 检查磁盘」把不同概念混在一起，缺少题干限定的前提。把题干「liveness 与 readiness 探针的分工是？」放回《TypeScript Node 后端开发》的「框架选型、分层职责、schema 校验与生产必做项」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：关于错误响应，推荐的做法是？

- **正确判断**：统一错误结构（code、message、details）并使用合适状态码
- **判断依据**：统一结构便于前端稳定处理，状态码表达语义，details 提供字段级信息。选项一让客户端无法区分成败。选项四让调用方无从判断原因。正确项「统一错误结构（code、message、details）并使用合适状态码」抓住了题干的核心条件，是经得起边界检验的表述。错误项「所有错误都返回 200 和错误文案（忽略了题干限定的前提）」把不同概念混在一起，缺少题干限定的前提。错误项「直接返回异常堆栈」只看到了表面现象，没有解释题干真正考查的机制。错误项「只返回状态码不带任何信息」在边界或失败路径上会得出错误结果。把题干「关于错误响应，推荐的做法是？」放回《TypeScript Node 后端开发》的「框架选型、分层职责、schema 校验与生产必做项」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：配置项在什么时候校验最合适？

- **正确判断**：服务启动时集中校验
- **判断依据**：启动时失败能立即暴露问题，避免带病运行到半夜才崩。选项一、三、四都会把问题推迟到更危险的时刻。正确项「服务启动时集中校验」抓住了题干的核心条件，是经得起边界检验的表述。错误项「上线后由监控发现」把不同概念混在一起，缺少题干限定的前提。错误项「由运维人工检查」与课程给出的定义相冲突，不能回答题目所问。错误项「第一次用到时再校验」只看到了表面现象，没有解释题干真正考查的机制。把题干「配置项在什么时候校验最合适？」放回《TypeScript Node 后端开发》的「框架选型、分层职责、schema 校验与生产必做项」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「处理请求体时，最安全的做法是？」的判断依据。
- [ ] 不看解析，能说出「收到 SIGTERM 时，服务应该？」的判断依据。
- [ ] 不看解析，能说出「liveness 与 readiness 探针的分工是？」的判断依据。
- [ ] 不看解析，能说出「关于错误响应，推荐的做法是？」的判断依据。
- [ ] 不看解析，能说出「配置项在什么时候校验最合适？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Node Backend in TypeScript

**Summary:** Framework choice, layering, schema validation and production checklist.

**Category:** TypeScript  
**Level:** 进阶  
**Key terms:** Node后端, Fastify, NestJS, zod, 优雅关闭, 健康检查

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：TypeScript 5.x / Node.js 22+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Node后端、Fastify、NestJS、zod、优雅关闭、健康检查
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

> 本课主题：框架选型、分层职责、schema 校验与生产必做项。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

