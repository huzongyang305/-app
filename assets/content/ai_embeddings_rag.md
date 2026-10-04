# 嵌入、向量检索与 RAG

![嵌入、向量检索与 RAG](images/remaining_ai_embeddings_rag.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「嵌入、向量检索与 RAG」解决了什么问题，而不是只背术语。
- 能说清 「嵌入」、「向量检索」、「RAG」、「分块」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「AI 与智能体」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：语义向量、向量库、RAG 流程与分块策略。

## 前置知识

- 先完成上一课《提示工程》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：嵌入、向量检索、RAG。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 嵌入：把文本变成向量

嵌入模型把文本映射成高维向量，语义相近的文本在向量空间中距离更近。

```python
from openai import OpenAI
client = OpenAI()
response = client.embeddings.create(
    model="text-embedding-3-small",
    input=["二分查找的时间复杂度", "二分法查找效率"],
)
v1, v2 = [item.embedding for item in response.data]
```

相似度常用**余弦相似度**（只看向量方向，与长度无关）：

```text
cos(a, b) = (a · b) / (|a| × |b|)      越接近 1 越相似
```

## 向量数据库

| 方案 | 特点 |
| --- | --- |
| FAISS | 单机库，速度快，适合原型与离线检索 |
| Chroma | 轻量、易用，适合小规模本地应用 |
| pgvector | 直接长在 PostgreSQL 上，省一套运维 |
| Milvus / Qdrant / Pinecone | 面向大规模或托管场景 |

检索流程：查询向量化 → 近似最近邻搜索（ANN）→ 取 Top-K → 可选重排序（Rerank）。

## RAG：让模型基于资料回答

```text
离线：文档 -> 清洗 -> 分块 -> 嵌入 -> 存入向量库
在线：问题 -> 嵌入 -> 检索 Top-K 片段 -> 拼进提示 -> LLM 生成 -> 带引用返回
```

```python
def answer(question: str) -> str:
    q_vec = embed(question)
    chunks = vector_store.search(q_vec, top_k=5)
    context = "\n\n".join(f"[{i+1}] {c.text}" for i, c in enumerate(chunks))
    prompt = f"""仅根据下面的资料回答问题，资料不足时明确说「资料中没有」。
资料：
{context}
问题：{question}
要求：在结论后标注使用的资料编号，如 [1][3]。"""
    return llm(prompt)
```

## 分块策略

| 策略 | 适用 |
| --- | --- |
| 固定长度 + 重叠 | 通用，简单可靠 |
| 按标题/段落切分 | 结构化文档，语义完整 |
| 按代码/表格切分 | 技术文档，保持语法完整 |
| 父子块（小块检索、大块喂给模型） | 兼顾检索精度与上下文完整性 |

块太大噪声多，太小语义不完整；常见起点是 300~800 token，重叠 10%~20%。

## 影响效果的关键点

1. 检索质量比提示词更重要——检索不到，模型只能编。
2. 加入重排序（cross-encoder）通常能明显提升 Top-K 质量。
3. 必须做引用与溯源，便于用户核实。
4. 混合检索（关键词 BM25 + 向量）对专有名词与代码更友好。
5. 定期评测：命中率、答案正确率、引用准确率。

## 可直接套用的提示模板

```text
角色：你是严谨的技术文档助手。
要求：
1. 仅依据【资料】回答，不要使用资料之外的知识。
2. 资料不足时明确回答「资料中没有相关信息」，不要猜测。
3. 引用格式：[编号]，如 [1][3]，编号对应【资料】中的序号。
4. 涉及数字、版本号、参数时，必须与资料原文完全一致。
5. 回答先给结论，再给依据，最后列出引用来源。

【资料】
[1] ……
[2] ……

【问题】{question}
```

模板的价值在于**把约束显式化**：限定来源、规定引用、要求一致、禁止编造。生产环境还要配合长度限制、敏感词过滤与超时降级。

## 评测脚本要点

1. 准备四类用例：可直接查到、需跨文档综合、无答案、含对抗性表述（提示注入）。
2. 每条记录：问题、标准答案要点、期望命中的文档 ID。
3. 自动指标：命中率（Top-K 是否包含期望文档）、要点覆盖率、引用准确率、无答案问题的正确拒答率。
4. 用 LLM-as-Judge 打分后**人工抽检校准**，避免评审判偏。
5. 每次改分块、改嵌入模型、改提示后重跑同一套用例并对比，形成回归。

把这套脚本接进 CI，就能避免"改一次提示、感觉变好了、实际变差"的常见陷阱。

## 混合检索与重排的调参

**为什么需要混合**：向量检索擅长语义相似（"怎么退货" ↔ "退款流程"），但对专有名词、代码标识符、型号编号容易失手；关键词检索（BM25）恰好相反。两者互补。

| 方案 | 优点 | 缺点 |
| --- | --- | --- |
| 纯向量 | 语义泛化好 | 稀有词/精确匹配弱 |
| 纯 BM25 | 精确匹配强、速度快 | 不理解同义与改写 |
| 混合 + 重排 | 召回与精度兼顾 | 链路更长、延迟与成本增加 |

**融合策略**：常见做法是两路各取 Top-20，用 RRF（倒数排名融合）合并——只看名次不看分数，避免两路分数量纲不可比的问题。RRF 的核心参数是常数 k（常用 60），k 越大越弱化头部差异。

**两阶段检索的阈值调参**：

1. 粗排召回 Top-K：K 太小会漏（召回率低），太大会引入噪声，建议从 20 起调。
2. 重排后取 Top-N 喂给模型：N 常取 3~5，取决于上下文预算。
3. 相似度阈值：低于阈值直接判"资料中没有"，**这个阈值必须用评测集标定**（不同嵌入模型的分数分布差异极大，不能照搬别人的 0.8）。
4. 用「命中率」与「答案正确率」两条曲线判断：K 增大命中率上升但正确率可能下降，取两者都较好的区间。

评测方法：固定问题集，分别跑纯向量、纯 BM25、混合、混合+重排四种配置，对比命中率、答案正确率、P95 延迟与每问成本，用数据决定是否值得引入重排。

## 本课小结
RAG = **检索 + 生成**。它用外部知识弥补模型的知识截止与幻觉问题，是当前企业落地最常见的 LLM 架构。

<!-- appendix:v1 -->

## RAG 链路速查

| 阶段 | 关键决策 | 常见做法 |
| --- | --- | --- |
| 解析 | 保留结构与页码 | PDF 解析、表格结构化 |
| 分块 | 粒度与重叠 | 300 到 800 Token，重叠 10% 到 20% |
| 嵌入 | 模型与维度 | 中文优先选中文或多语模型 |
| 存储 | 向量库与元数据 | 向量 + 文档 ID + 位置 + 权限 |
| 检索 | 召回策略 | 向量 + 关键词混合，取 top 20 到 50 |
| 重排 | 精排 | Cross-Encoder 取 top 3 到 8 |
| 生成 | 提示构造 | 片段编号 + 要求引用 |
| 评测 | 命中与作答 | 召回率、忠实度、引用准确率 |

## 相似度速查

| 度量 | 公式直觉 | 适用 |
| --- | --- | --- |
| 余弦相似度 | 看方向夹角 | 文本嵌入（最常用） |
| 点积 | 方向与长度都算 | 归一化后等价于余弦 |
| 欧氏距离 | 看空间距离 | 图像特征 |
| 内积最大值搜索（MIPS） | 最大内积 | 推荐与检索 |

重要前提：**查询与文档必须使用同一个嵌入模型与同一版本**，否则向量空间不一致。

```python
import math
from dataclasses import dataclass

def cosine_similarity(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(y * y for y in b))
    return 0.0 if norm_a == 0 or norm_b == 0 else dot / (norm_a * norm_b)


@dataclass
class Chunk:
    doc_id: str
    position: int
    text: str
    vector: list[float]
    metadata: dict


def hybrid_score(vector_score: float, keyword_score: float, alpha: float = 0.7) -> float:
    """混合检索：向量分与关键词分加权，alpha 控制偏向。"""
    return alpha * vector_score + (1 - alpha) * keyword_score


def retrieve(query_vec, chunks, top_k=5, filters=None, alpha=0.7, keyword_fn=None):
    """带元数据过滤与混合打分的检索。"""
    scored = []
    for chunk in chunks:
        if filters and not all(chunk.metadata.get(k) == v for k, v in filters.items()):
            continue
        vector_score = cosine_similarity(query_vec, chunk.vector)
        keyword_score = keyword_fn(chunk.text) if keyword_fn else 0.0
        scored.append((hybrid_score(vector_score, keyword_score, alpha), chunk))
    scored.sort(key=lambda item: -item[0])
    return scored[:top_k]


def build_prompt(question: str, hits) -> str:
    """把检索片段编号后拼进提示，便于要求引用来源。"""
    context = "\n\n".join(
        f"[{i + 1}] ({c.doc_id} 第 {c.position} 段)\n{c.text}"
        for i, (_, c) in enumerate(hits)
    )
    return (
        "只能依据下面的资料回答；资料不足时明确说明无法回答。\n"
        "回答末尾用 [编号] 标注引用来源。\n\n"
        f"资料：\n{context}\n\n问题：{question}"
    )


print(round(cosine_similarity([1, 2, 3], [2, 4, 6]), 4))
```

## 分块策略对照

| 策略 | 适用 | 注意 |
| --- | --- | --- |
| 固定长度 | 通用快速方案 | 可能切断句子 |
| 按段落 | 结构清晰的文档 | 段落过长需再切 |
| 按标题层级 | 手册、规范 | 保留标题作为上下文 |
| 语义分块 | 内容主题变化明显 | 计算成本较高 |
| 父子块 | 检索小块、返回大块 | 兼顾精度与上下文 |
| 表格与图表单独处理 | 财务报表、论文 | 转成结构化描述 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 查询与文档用不同嵌入模型 | 检索结果随机 | 统一模型与版本 |
| 分块过大 | 检索噪声多 | 300 到 800 Token，加重叠 |
| 分块过小 | 语义断裂 | 保留标题与上下文前缀 |
| 不做重排 | 相关性不足 | 向量召回后加 Cross-Encoder 精排 |
| 无元数据过滤 | 越权召回他人文档 | 强制按租户与权限过滤 |
| 没有引用信息 | 回答无法核验 | 片段带文档 ID 与位置，回答标引用 |
| 只测检索不测作答 | 端到端质量差 | 分别评测召回与生成 |
| 语料更新后不重建索引 | 用户拿到旧内容 | 变更触发增量索引与版本标记 |
| 直接拼接用户输入 | 提示注入 | 分隔符隔离并声明资料不可信 |
| 忽略文档解析质量 | 表格数字错乱 | 解析后抽样人工校验 |

## 自测清单

- [ ] 能画出 RAG 的完整链路与每阶段决策点。
- [ ] 查询与文档使用同一嵌入模型与版本。
- [ ] 分块粒度合理且保留上下文与来源信息。
- [ ] 检索有元数据权限过滤与重排。
- [ ] 分别评测召回质量与作答质量。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「嵌入、向量检索、RAG」完成复述、实验和交付，每个结果都要能被别人检查。

先写评测样例，再改一个提示、模型或数据变量，最后比较质量、成本与安全。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「嵌入、向量检索与 RAG」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「向量检索」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

构造 5 条小型离线样例，写清输入、期望输出、评分标准和失败案例。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「嵌入」和「向量检索」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Embeddings & RAG

**Summary:** Embeddings, vector stores, RAG and chunking.

**Category:** AI & Agents  
**Level:** 进阶  
**Key terms:** 嵌入, 向量检索, RAG, 分块, 重排序

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：主流大模型 API、开源模型与向量数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：嵌入、向量检索、RAG、分块、重排序
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Embeddings & RAG** focuses on Embeddings, vector stores, RAG and chunking.

### Learning Outcomes

- Explain what **Embeddings & RAG** solves and when it should be used.
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

- Topic: **Embeddings & RAG**
- Related terms: 嵌入, 向量检索, RAG, 分块
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 嵌入：把文本变成向量 | 嵌入：把文本变成Vector |
| 向量数据库 | VectorDatabase |
| RAG：让模型基于资料回答 | RAG：让Model基于资料回答 |
| 分块策略 | 分块策略 |
| 影响效果的关键点 | 影响效果的关键点 |
| 可直接套用的提示模板 | 可直接套用的Prompt模板 |
| 评测脚本要点 | 评测脚本要点 |
| 混合检索与重排的调参 | 混合Retrieval与重排的调参 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [OpenAI Docs](https://platform.openai.com/docs/) | 模型 API、工具与评估 |
| [Hugging Face Docs](https://huggingface.co/docs) | 模型、数据集与推理 |
| [Model Context Protocol](https://modelcontextprotocol.io/) | Agent 工具与上下文协议 |

> 本课主题：语义向量、向量库、RAG 流程与分块策略。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

