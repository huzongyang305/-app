# 实战：本地 RAG 客服 Agent

![实战：本地 RAG 客服 Agent](images/remaining_project_rag_agent_service.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：140 分钟

## 学习目标

- 能把文档切分、索引、召回、重排和生成拆成独立阶段。
- 能让每个回答携带可追溯的文档片段引用。
- 能为 Agent 工具设置参数校验、超时和权限边界。
- 能用离线评测集验证命中率、引用正确率和拒答率。

## 前置知识

- 已完成本分类的基础与进阶课程，能独立运行正文中的最小示例。
- 熟悉命令行、依赖管理、测试和 Git 基本操作。
- 本课涉及：RAG、Agent、向量检索、引用、评测。

## 项目背景

客服团队需要回答产品文档问题。系统必须先从本地知识库检索证据，再生成带来源的回答；当证据不足时明确拒答，遇到订单查询等实时数据时调用受控工具，而不是让模型编造。

一句话摘要：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。

## 技术栈

- Python 3.12
- 向量索引
- Embedding
- 检索器
- 工具调用
- pytest

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

- [ ] 导入 Markdown/PDF 文本并保留来源元数据
- [ ] 混合关键词与向量检索并重排 Top-K
- [ ] 回答只使用检索到的证据
- [ ] 工具调用采用白名单和参数模式
- [ ] 输出引用、置信度与拒答原因
- [ ] 记录检索与生成阶段延迟

## 示例数据与边界

| 场景 | 输入 | 期望结果 | 检查点 |
| --- | --- | --- | --- |
| 正常路径 | 合法的最小数据集 | 成功返回并写入正确数据 | 状态码、数据库记录、日志 |
| 边界值 | 最大值、最小值或空集合 | 明确成功或给出可理解错误 | 不崩溃、不越界、不写半条数据 |
| 非法输入 | 类型错误、缺字段、超长内容 | 返回校验错误并指出字段 | 错误结构统一且不泄露内部信息 |
| 依赖失败 | 数据库不可用、超时、网络抖动 | 重试、降级或快速失败 | 可恢复、可观测、无重复副作用 |

## 实施步骤

### 步骤 1：定义知识块、来源和评测样本模型

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 2：实现清洗、切分与元数据保留

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 3：建立可重复构建的向量索引

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 4：实现召回、重排和上下文预算控制

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 5：接入受控工具与引用格式化

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

### 步骤 6：运行离线评测并修复未命中与幻觉案例

- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。
- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。
- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。
- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。

## 关键代码

```python
def answer_question(question: str, retriever, llm) -> dict:
    hits = retriever.search(question, top_k=8)
    if not hits or hits[0].score < 0.62:
        return {'answer': '知识库中没有足够证据。', 'citations': [], 'grounded': False}
    context = '\n\n'.join(
        f'[{i+1}] {hit.text}\nSource: {hit.source}' for i, hit in enumerate(hits[:4])
    )
    response = llm.generate(
        system='Only answer from the supplied context. Cite every claim.',
        user=f'Question: {question}\n\nContext:\n{context}',
    )
    return {'answer': response, 'citations': [hit.source for hit in hits[:4]], 'grounded': True}
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

- 问题有明确证据时回答包含正确来源编号
- 知识库没有相关片段时系统拒答而不是编造
- 工具收到越权参数时在调用前被拒绝
- 索引重建后相同评测集结果保持稳定

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
| 只做向量召回 | 专有名词和编号经常漏检 | 混合关键词检索并重排 |
| 把全部文档塞进上下文 | 成本高且中间信息被忽略 | 限制 Top-K 并保留来源元数据 |
| 无法拒答 | 无证据时仍然生成答案 | 设置低置信度和空召回兜底 |
| 工具没有权限边界 | 模型可读取或修改敏感数据 | 白名单、参数校验和最小权限 |

## 扩展任务

- 加入多模态图片 OCR 与表格理解
- 实现多轮对话查询改写
- 把评测结果接入 CI 并阻止回归发布

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

### 考点 1：RAG 客服 Agent 在生成答案前最关键的步骤是什么？

- **正确判断**：先检索并筛选可引用的证据
- **判断依据**：正确答案是「先检索并筛选可引用的证据」，本课在「功能范围」中说明：导入 Markdown/PDF 文本并保留来源元数据。RAG 的核心是先检索到与问题相关且能追溯来源的证据，再把有限上下文交给模型生成。本课还在「项目背景」中说明：系统必须先从本地知识库检索证据，再生成带来源的回答。本课还在「项目背景」中说明：当证据不足时明确拒答，遇到订单查询等实时数据时调用受控工具，而不是让模型编造。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：为什么生产级 RAG 通常要混合关键词检索与向量检索？

- **正确判断**：兼顾语义相似与错误码
- **判断依据**：正确答案是「兼顾语义相似与错误码」，本课在「项目背景」中说明：一句话摘要：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。向量检索擅长语义相近但表达不同的内容，关键词检索则能稳定命中错误码、产品编号和专有名词。本课还在「项目背景」中说明：系统必须先从本地知识库检索证据，再生成带来源的回答。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：当知识库没有任何相关片段时，Agent 应该如何处理？

- **正确判断**：明确说明证据不足并拒答
- **判断依据**：正确答案是「明确说明证据不足并拒答」，本课在「项目背景」中说明：当证据不足时明确拒答，遇到订单查询等实时数据时调用受控工具，而不是让模型编造。无法获得可靠证据时，系统应把不确定性明确告诉用户，而不是通过模型常识补全看似合理的事实。本课还在「项目专属规格：实战：本地 RAG 客服 Agent」中说明：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：为 Agent 工具设置白名单和参数校验的主要目的是什么？

- **正确判断**：限制可执行操作并防止越权副作用
- **判断依据**：正确答案是「限制可执行操作并防止越权副作用」，本课在「项目背景」中说明：一句话摘要：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。模型可能生成错误参数或被提示注入诱导调用工具，因此权限不能依赖模型自觉。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：补全代码：「实战：本地 RAG 客服 Agent」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `hits = retriever.search(____, top_k=8)`

- **正确判断**：question
- **判断依据**：正确答案是「question」，本课在「项目专属规格：实战：本地 RAG 客服 Agent」中说明：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。本课示例中还能看到 `hits = retriever.search(question, top_k=8)` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「RAG 客服 Agent 在生成答案前最关键的步骤是什么？」的判断依据。
- [ ] 不看解析，能说出「为什么生产级 RAG 通常要混合关键词检索与向量检索？」的判断依据。
- [ ] 不看解析，能说出「当知识库没有任何相关片段时，Agent 应该如何处理？」的判断依据。
- [ ] 不看解析，能说出「为 Agent 工具设置白名单和参数校验的主要目的是什么？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「实战：本地 RAG 客服 Agent」示例中，下面这行代码缺少哪个关…」的判断依据。
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
| `RAG` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `Agent` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `向量检索` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `引用` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |
| `评测` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：RAG 客服 Agent 在生成答案前最关键的步骤是什么？

**参考回答**：正确答案是「先检索并筛选可引用的证据」，本课在「功能范围」中说明：导入 Markdown/PDF 文本并保留来源元数据。RAG 的核心是先检索到与问题相关且能追溯来源的证据，再把有限上下文交给模型生成。本课还在「项目背景」中说明：系统必须先从本地知识库检索证据，再生成带来源的回答。本课还在「项目背景」中说明：当证据不足时明确拒答，遇到订单查询等实时数据时调用受控工具，而不是让模型编造。

### 追问 2：为什么生产级 RAG 通常要混合关键词检索与向量检索？

**参考回答**：正确答案是「兼顾语义相似与错误码」，本课在「项目背景」中说明：一句话摘要：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。向量检索擅长语义相近但表达不同的内容，关键词检索则能稳定命中错误码、产品编号和专有名词。本课还在「项目背景」中说明：系统必须先从本地知识库检索证据，再生成带来源的回答。

### 追问 3：当知识库没有任何相关片段时，Agent 应该如何处理？

**参考回答**：正确答案是「明确说明证据不足并拒答」，本课在「项目背景」中说明：当证据不足时明确拒答，遇到订单查询等实时数据时调用受控工具，而不是让模型编造。无法获得可靠证据时，系统应把不确定性明确告诉用户，而不是通过模型常识补全看似合理的事实。本课还在「项目专属规格·实战·本地 RAG 客服 Agent」中说明：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。

### 追问 4：为 Agent 工具设置白名单和参数校验的主要目的是什么？

**参考回答**：正确答案是「限制可执行操作并防止越权副作用」，本课在「项目背景」中说明：一句话摘要：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。模型可能生成错误参数或被提示注入诱导调用工具，因此权限不能依赖模型自觉。

### 追问 5：补全代码：「实战：本地 RAG 客服 Agent」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `hits = retriever.search(____, top_k=8)`

**参考回答**：正确答案是「question」，本课在「项目专属规格·实战·本地 RAG 客服 Agent」中说明：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。本课示例中还能看到 `hits = retriever.search(question, top_k=8)` 这样的用法，说明该关键字在本课代码中承担实际功能。

## English Overview

**Title:** Project: Local RAG Support Agent

**Summary:** Build a citation-based RAG agent with retrieval, tools, evaluation and guardrails.

**Category:** Project Practice  
**Level:** 高级  
**Key terms:** RAG, Agent, 向量检索, 引用, 评测

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：通用项目交付流程
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：RAG、Agent、向量检索、引用、评测
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：实战：本地 RAG 客服 Agent

### 核心场景

构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。 项目目标是把「RAG、Agent、向量检索、引用、评测」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | RAG、时间、来源 | 必填校验、长度限制、幂等键 |
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
  "project": "project_rag_agent_service",
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

> 项目验收围绕「RAG、Agent、向量检索」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [The Twelve-Factor App](https://12factor.net/) | 可部署应用原则 |
| [Google SRE Books](https://sre.google/books/) | 可观测性与发布工程 |

> 本课主题：构建可离线演示的知识库问答 Agent，覆盖切分、检索、引用、工具调用、评测与安全护栏。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。


## Full English Study Guide

### Overview

**Project: Local RAG Support Agent** focuses on Build a citation-based RAG agent with retrieval, tools, evaluation and guardrails.

### Learning Outcomes

- Explain what **Project: Local RAG Support Agent** solves and when it should be used.
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

- Topic: **Project: Local RAG Support Agent**
- Related terms: RAG, Agent, 向量检索, 引用
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.
