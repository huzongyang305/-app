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
