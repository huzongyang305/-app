# 实战：REST API 与 SQLite 事务服务

![实战：REST API 与 SQLite 事务服务](images/remaining_project_rest_api_sqlite.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：120 分钟

## 学习目标

- 能用资源、状态码和错误模型表达清楚接口契约。
- 能把库存判断与预约写入放进同一事务。
- 能用唯一约束和幂等键处理重复请求。
- 能用契约测试覆盖成功、冲突、校验失败和重试。

## 前置知识

- 已完成本分类的基础与进阶课程，能独立运行正文中的最小示例。
- 熟悉命令行、依赖管理、测试和 Git 基本操作。
- 本课涉及：REST、SQLite、事务、幂等、API 契约。

## 项目背景

仓储系统需要对外开放库存预约接口。客户端会重试超时请求，多个请求可能同时竞争同一商品库存；服务必须返回稳定错误结构，并在任何失败路径下保证预约记录与库存数量一致。

一句话摘要：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。

## 技术栈

- Python 3.12
- FastAPI
- Pydantic
- SQLite
- pytest
- TestClient

## 架构与数据流

```text
输入 → 参数校验 → 业务处理 → 持久化/外部调用 → 结果输出 → 指标与日志
                 ↘ 失败分类 → 重试/回滚 → 错误响应
```

- 读路径要明确查询条件、分页方式和返回字段，避免一次加载全部数据。
- 写路径要明确事务边界、幂等键和失败补偿，不能留下半完成状态。
- 外部调用要设置超时、重试上限和降级策略。
- 每个关键阶段都要留下日志、指标或测试证据。

## 功能范围

- [ ] 创建库存预约并返回预约号
- [ ] 查询预约状态与商品剩余库存
- [ ] 取消未发货预约并恢复库存
- [ ] 重复幂等键返回同一结果
- [ ] 统一错误结构与请求追踪号

## 示例数据与边界

| 场景 | 输入 | 期望结果 | 检查点 |
| --- | --- | --- | --- |
| 正常路径 | 合法的最小数据集 | 成功返回并写入正确数据 | 状态码、数据库记录、日志 |
| 边界值 | 最大值、最小值或空集合 | 明确成功或给出可理解错误 | 不崩溃、不越界、不写半条数据 |
| 非法输入 | 类型错误、缺字段、超长内容 | 返回校验错误并指出字段 | 错误结构统一且不泄露内部信息 |
| 依赖失败 | 数据库不可用、超时、网络抖动 | 重试、降级或快速失败 | 可恢复、可观测、无重复副作用 |

## 实施步骤

### 步骤 1：写清接口资源、请求字段和错误码

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 2：设计商品、库存和预约三张表及唯一约束

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 3：实现仓储层并明确事务边界

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 4：实现创建、查询和取消用例

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 5：注入并发与重复请求测试

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 6：记录慢查询、冲突率和 P95 延迟

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

## 关键代码

```python
CREATE TABLE reservations (
  id TEXT PRIMARY KEY,
  sku TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  status TEXT NOT NULL,
  idempotency_key TEXT NOT NULL UNIQUE
);

BEGIN IMMEDIATE;
UPDATE inventory SET available = available - :qty
WHERE sku = :sku AND available >= :qty;
-- changes() 为 0 时抛出库存冲突并回滚
INSERT INTO reservations(id, sku, quantity, status, idempotency_key)
VALUES (:id, :sku, :qty, 'reserved', :key);
COMMIT;
```

## 验证命令与预期输出

先在干净环境执行启动和测试命令，再把真实输出记录到项目 README 或实施记录中。

```text
1. 安装依赖并启动项目
2. 执行至少 3 条自动化测试，其中包含 1 条失败路径
3. 用正常请求验证成功响应
4. 用非法输入验证错误响应
5. 重复执行一次，确认没有重复写入或副作用
```

预期输出必须包含：启动成功标志、测试通过数量、成功请求结果、错误状态码和重复执行的幂等结论。只写“运行正常”不算验收证据。

## 建议目录结构

```text
src/
  entry/        启动与配置
  domain/       业务模型与规则
  service/      用例编排
  infra/        数据库、HTTP、消息等适配器
tests/          单元、集成与接口测试
```

目录可以按语言习惯调整，但输入边界、业务规则和外部适配必须分层，不能全部堆在入口文件。

## 质量门禁

- [ ] 格式化和静态检查通过，不遗留明显警告。
- [ ] 单元测试覆盖核心规则，集成测试覆盖数据库或外部边界。
- [ ] 错误响应不泄露堆栈、SQL 和密钥。
- [ ] 配置来自环境变量或配置文件，不硬编码敏感信息。
- [ ] README 写清启动、测试、配置和回滚步骤。

## 安全、成本与可观测性

- 权限遵循最小授权，数据库账号、云资源和接口令牌都不能使用管理员默认权限。
- 所有外部输入都要校验、限长并转义，错误信息不能泄露内部路径和 SQL。
- 密钥通过环境变量或密钥管理服务注入，并记录轮换方式。
- 为数据库连接、线程/协程、队列、文件和网络请求设置上限，避免资源耗尽。
- 至少记录请求量、错误率、P95/P99 延迟、资源使用和成本趋势。
- 出现异常时能从日志和指标还原时间线，而不是只看到一句“服务不可用”。

## 测试与验收

- 库存充足时创建预约并准确扣减一次
- 库存不足返回 409 且预约表不新增记录
- 相同幂等键重复提交返回同一预约号
- 取消预约后库存恢复且重复取消不二次加回

### 验收记录表

| 检查项 | 证据 | 结果 | 备注 |
| --- | --- | --- | --- |
| 最小路径可运行 | 启动命令与输出 |  |  |
| 失败路径可恢复 | 错误日志与重试 |  |  |
| 自动化测试通过 | 测试报告 |  |  |
| 配置和密钥安全 | 配置检查 |  |  |

## 常见问题

| 问题 | 原因 | 解决 |
| --- | --- | --- |
| 先查库存再单独更新 | 并发请求造成超卖 | 使用条件更新或事务锁 |
| 把错误信息直接拼进响应 | 泄露 SQL、路径或堆栈 | 统一映射为稳定错误码 |
| 幂等键只放在内存 | 重启后重复请求仍会写两次 | 数据库唯一约束持久化幂等键 |
| 取消接口没有状态检查 | 已发货订单被错误取消 | 校验状态机并返回冲突错误 |

## 扩展任务

- 增加仓库维度和分区库存
- 接入 OpenAPI 契约测试
- 用 PostgreSQL 替换 SQLite 并做并发压测

## 性能、容量与故障演练

| 维度 | 基线 | 压测方法 | 失败信号 |
| --- | --- | --- | --- |
| 延迟 | 记录 P50/P95/P99 | 用固定数据集逐步增加并发 | P99 持续上升或超时率增加 |
| 吞吐 | 记录每秒处理量 | 逐步加压直到资源打满 | 队列积压、CPU/内存饱和 |
| 存储 | 记录数据增长与索引大小 | 导入 10 倍数据并观察查询 | 磁盘、连接或锁等待成为瓶颈 |
| 恢复 | 记录故障恢复时间 | 停止数据库、注入延迟或重复请求 | 数据不一致、重复副作用、无法回滚 |

至少完成一次故障演练：先写下预期行为，再注入故障，最后对比真实行为并修正监控或代码。没有演练的容错设计只能算假设。

## 实施记录与复盘

每完成一步，记录以下内容：

1. 本步的输入、命令和输出是什么？
2. 遇到的最小失败是什么，如何定位和修复？
3. 哪个假设被验证或推翻？
4. 下一步的风险是什么，如何回滚？
5. 如果数据量或并发扩大 10 倍，最先出现的瓶颈在哪里？

## 动手练习

### 练习 1：最小可运行版本（30 分钟）

只实现最核心的一条路径，确保能启动、能返回结果、能运行测试。

**验收标准**：留下启动命令、请求示例和成功输出。

### 练习 2：失败路径（30 分钟）

制造一次输入错误、依赖失败或超时，记录系统如何报错、如何恢复。

**验收标准**：错误信息清晰，且不会破坏已有数据。

### 练习 3：扩展一个功能（60 分钟）

从扩展任务中选一项实现，并补一条自动化测试。

**验收标准**：新功能通过测试，且原有测试不回归。

## 本课小结

- 项目课的核心不是堆功能，而是把输入、状态、错误和验收标准连接起来。
- 先跑通最小路径，再补失败处理、测试和文档，最后才做性能优化。
- 每个阶段都要留下可复现证据：命令、输出、测试和变更记录。
- 完成后用扩展任务检验迁移能力，而不是只复制示例代码。

## 完成标准

- [ ] 能从干净环境按 README 启动项目。
- [ ] 至少 3 条自动化测试通过，且包含一条失败路径。
- [ ] 能演示一次错误、一次恢复和一次回滚。
- [ ] 有一份资源或性能基线，能说明瓶颈在哪里。
- [ ] 能说清一个尚未解决的问题和下一步验证方法。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：REST 库存服务中，哪一个字段最适合作为客户端重试的幂等依据？

- **正确判断**：客户端生成的幂等键
- **判断依据**：正确答案是「客户端生成的幂等键」，本课在「项目背景」中说明：一句话摘要：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。客户端在第一次请求前生成幂等键，重试时保持不变，服务端才能识别两次请求属于同一业务操作。本课还在「项目背景」中说明：客户端会重试超时请求，多个请求可能同时竞争同一商品库存。本课还在「项目背景」中说明：服务必须返回稳定错误结构，并在任何失败路径下保证预约记录与库存数量一致。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：为什么库存扣减与预约写入必须处于同一事务？

- **正确判断**：避免出现扣了库存却没有预约的半完成状态
- **判断依据**：正确答案是「避免出现扣了库存却没有预约的半完成状态」，本课在「项目专属规格：实战：REST API 与 SQLite 事务服务」中说明：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。库存扣减和预约记录是同一次业务操作的两个事实，任一失败都必须一起回滚。本课还在「项目背景」中说明：客户端会重试超时请求，多个请求可能同时竞争同一商品库存。本课还在「项目背景」中说明：服务必须返回稳定错误结构，并在任何失败路径下保证预约记录与库存数量一致。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：库存不足时返回 409 而不是 500 的主要理由是什么？

- **正确判断**：409 表示请求与当前资源状态冲突
- **判断依据**：正确答案是「409 表示请求与当前资源状态冲突」，本课在「测试与验收」中说明：库存不足返回 409 且预约表不新增记录。库存不足不是服务器崩溃，而是请求与当前库存状态冲突，409 能准确表达这种可预期的业务失败。本课还在「项目背景」中说明：一句话摘要：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：取消已发货预约时，服务端最稳妥的处理方式是什么？

- **正确判断**：校验状态机并返回 409 冲突
- **判断依据**：正确答案是「校验状态机并返回 409 冲突」，本课在「项目专属规格：实战：REST API 与 SQLite 事务服务」中说明：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。状态机规定已发货可能是终态或需要逆向流程，普通取消请求不能跳过业务规则。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：补全代码：「实战：REST API 与 SQLite 事务服务」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"project": "____",`

- **正确判断**：project_rest_api_sqlite
- **判断依据**：正确答案是「project_rest_api_sqlite」，这道题在问补全代码：实战：RESTAPI与SQLite事务服务…，`"project":"____",`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `"project": "project_rest_api_sqlite",` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「REST 库存服务中，哪一个字段最适合作为客户端重试的幂等依据？」的判断依据。
- [ ] 不看解析，能说出「为什么库存扣减与预约写入必须处于同一事务？」的判断依据。
- [ ] 不看解析，能说出「库存不足时返回 409 而不是 500 的主要理由是什么？」的判断依据。
- [ ] 不看解析，能说出「取消已发货预约时，服务端最稳妥的处理方式是什么？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「实战：REST API 与 SQLite 事务服务」示例中，下面这行…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `"project":"____",` | 判断依据**：正确答案是「project_rest_api_sqlite」，这道题在问补全代码：实战：RESTAPI与SQLite事务服务…，`"project":"____",`，判断时要把题干限定的输入、边界与目标逐… |
| `REST` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `SQLite` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `事务` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `幂等` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `API 契约` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：REST 库存服务中，哪一个字段最适合作为客户端重试的幂等依据？

**参考回答**：正确答案是「客户端生成的幂等键」，本课在「项目背景」中说明：一句话摘要：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。客户端在第一次请求前生成幂等键，重试时保持不变，服务端才能识别两次请求属于同一业务操作。本课还在「项目背景」中说明：客户端会重试超时请求，多个请求可能同时竞争同一商品库存。本课还在「项目背景」中说明：服务必须返回稳定错误结构，并在任何失败路径下保证预约记录与库存数量一致。

### 追问 2：为什么库存扣减与预约写入必须处于同一事务？

**参考回答**：正确答案是「避免出现扣了库存却没有预约的半完成状态」，本课在「项目专属规格·实战·REST API 与 SQLite 事务服务」中说明：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。库存扣减和预约记录是同一次业务操作的两个事实，任一失败都必须一起回滚。本课还在「项目背景」中说明：客户端会重试超时请求，多个请求可能同时竞争同一商品库存。本课还在「项目背景」中说明：服务必须返回稳定错误结构，并在任何失败路径下保证预约记录与库存数量一致。

### 追问 3：库存不足时返回 409 而不是 500 的主要理由是什么？

**参考回答**：正确答案是「409 表示请求与当前资源状态冲突」，本课在「测试与验收」中说明：库存不足返回 409 且预约表不新增记录。库存不足不是服务器崩溃，而是请求与当前库存状态冲突，409 能准确表达这种可预期的业务失败。本课还在「项目背景」中说明：一句话摘要：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。

### 追问 4：取消已发货预约时，服务端最稳妥的处理方式是什么？

**参考回答**：正确答案是「校验状态机并返回 409 冲突」，本课在「项目专属规格·实战·REST API 与 SQLite 事务服务」中说明：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。状态机规定已发货可能是终态或需要逆向流程，普通取消请求不能跳过业务规则。

### 追问 5：补全代码：「实战：REST API 与 SQLite 事务服务」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `"project": "____",`

**参考回答**：正确答案是「project_rest_api_sqlite」，这道题在问补全代码：实战：RESTAPI与SQLite事务服务…，`"project":"____",`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `"project": "project_rest_api_sqlite",` 这样的用法，说明该关键字在本课代码中承担实际功能。

## English Overview

**Title:** Project: REST API with SQLite Transactions

**Summary:** Build a testable inventory reservation API with transactions and idempotent retries.

**Category:** Project Practice  
**Level:** 高级  
**Key terms:** REST, SQLite, 事务, 幂等, API 契约

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：通用项目交付流程
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：REST、SQLite、事务、幂等、API 契约
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：实战：REST API 与 SQLite 事务服务

### 核心场景

从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。 项目目标是把「REST、SQLite、事务、幂等、API 契约」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | REST、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。


## 项目交付物

### 建议仓库结构

```text
src/
tests/
docs/
README.md
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
  "project": "project_rest_api_sqlite",
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

> 项目验收围绕「REST、SQLite、事务」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [The Twelve-Factor App](https://12factor.net/) | 可部署应用原则 |
| [Google SRE Books](https://sre.google/books/) | 可观测性与发布工程 |

> 本课主题：从接口契约到数据库事务，完成一个可测试、可回滚、支持幂等重试的库存预约服务。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。


## Full English Study Guide

### Overview

**Project: REST API with SQLite Transactions** focuses on Build a testable inventory reservation API with transactions and idempotent retries.

### Learning Outcomes

- Explain what **Project: REST API with SQLite Transactions** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Project: REST API with SQLite Transactions**
- Related terms: REST, SQLite, 事务, 幂等
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.
