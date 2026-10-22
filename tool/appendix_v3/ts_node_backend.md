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
