# AI、机器学习与生成式 AI

![AI、机器学习与生成式 AI](images/remaining_ai_basics.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：13 分钟

## 学习目标

- 能用自己的话解释「AI、机器学习与生成式 AI」解决了什么问题，而不是只背术语。
- 能说清 「AI」、「机器学习」、「深度学习」、「生成式 AI」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「AI 与智能体」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：三者关系、三类学习范式与学习路径。

## 前置知识

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：AI、机器学习、深度学习。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 三个概念的关系

```text
人工智能 AI（让机器表现出智能）
└── 机器学习 ML（从数据中学习规律，而不是逐条写规则）
    ├── 深度学习 DL（用多层神经网络学习表示）
    │   └── 生成式 AI（生成文本、图像、音频、代码）
    └── 其他方法（决策树、SVM、聚类等）
```

传统编程是「人写规则」，机器学习是「人给数据，机器找规则」，生成式 AI 则是「机器按概率生成新内容」。

## 机器学习的三类范式

| 范式 | 数据 | 目标 | 例子 |
| --- | --- | --- | --- |
| 监督学习 | 带标签 | 预测标签 | 房价预测、垃圾邮件分类 |
| 无监督学习 | 无标签 | 发现结构 | 聚类、降维、异常检测 |
| 强化学习 | 奖励信号 | 学策略 | 游戏 AI、机器人控制 |

## 生成式 AI 能做什么

- 文本：摘要、翻译、写作、代码生成、问答
- 图像与视频：文生图、修图、视频生成
- 语音：语音识别（ASR）与语音合成（TTS）
- 多模态：图文理解、文档解析、屏幕操作

## 典型应用架构

```text
用户输入 -> 预处理（清洗/分块）-> 模型推理（LLM/多模态）
        -> 后处理（校验/引用/格式化）-> 返回结果
        -> 记录日志与评测指标 -> 持续迭代
```

## 学习路径建议

1. 先建立概念地图（本分类前 3 篇）。
2. 掌握提示工程与调用 API，做出第一个可用的小工具。
3. 学习嵌入与 RAG，让模型基于自己的资料回答。
4. 学习 Agent：工具调用、记忆、规划与多智能体协作。
5. 最后补工程化：评测、成本、安全与可观测性。

## 从场景反推技术选型

| 业务场景 | 推荐方案 | 为什么 |
| --- | --- | --- |
| 文档问答（基于内部资料） | RAG（检索增强） | 知识可更新、可溯源，无需训练 |
| 固定格式的信息抽取 | 提示工程 + 结构化输出 | 成本最低，字段可控 |
| 稳定风格与话术（客服） | 少样本提示，必要时微调 | 风格靠示例，不强依赖训练 |
| 高并发简单分类 | 小模型 + 蒸馏/量化 | 延迟与成本敏感，精度足够 |
| 多步操作（下单、查库） | Agent + 工具调用 | 需要与系统交互而非纯生成 |
| 图像/语音处理 | 多模态模型或专用模型 | 视觉/语音专用模型通常更划算 |

选型四问：**知识是否需要频繁更新**（要→RAG）、**输出是否必须严格结构化**（要→schema + 校验）、**是否需要执行动作**（要→工具调用 + 权限控制）、**成本与延迟预算是多少**（紧→小模型 + 缓存）。先答这四问，再决定用提示、RAG 还是微调。

## 本课小结
AI 是目标，机器学习是方法，深度学习是当前主流技术，生成式 AI 是其中最热的应用形态。**先分清层次，再深入某一层**。


## 概念层级速查

| 层级 | 关注点 | 例子 |
| --- | --- | --- |
| 人工智能 | 让机器表现出智能行为 | 规划、推理、感知 |
| 机器学习 | 从数据中学习规律 | 回归、分类、聚类 |
| 深度学习 | 用多层神经网络表示特征 | CNN、Transformer |
| 生成式 AI | 生成新内容 | 文本、图像、音频、视频 |
| 大语言模型 | 大规模预训练的文本模型 | GPT、Claude、Llama、Qwen |

## 模型类型对照

| 类型 | 输入到输出 | 典型任务 |
| --- | --- | --- |
| 判别式 | 输入到标签 | 分类、检测、排序 |
| 生成式 | 输入到新内容 | 写作、绘图、语音合成 |
| 嵌入模型 | 文本到向量 | 检索、聚类、去重 |
| 重排模型 | 查询与文档对到分数 | 精排 |
| 多模态模型 | 多模态输入到文本或内容 | 图文问答、OCR 理解 |

```python
from dataclasses import dataclass

@dataclass
class TokenBudget:
    """上下文预算：把窗口切成提示、资料、输出三部分。"""

    window: int                 # 模型上下文上限
    prompt: int                 # 系统提示与指令
    retrieved: int              # 检索资料
    output: int                 # 预留输出

    @property
    def used(self) -> int:
        return self.prompt + self.retrieved + self.output

    @property
    def remaining(self) -> int:
        return self.window - self.used

    def fits(self) -> bool:
        return self.remaining >= 0

    def trim_retrieved(self) -> "TokenBudget":
        """超预算时优先裁剪检索资料，保证提示与输出完整。"""
        if self.fits():
            return self
        overflow = -self.remaining
        return TokenBudget(
            self.window, self.prompt,
            max(0, self.retrieved - overflow),
            self.output,
        )


def estimate_tokens(text: str, chars_per_token: float = 1.6) -> int:
    """粗略估算 Token 数：中文约 1 字 1 到 2 Token，英文约 4 字符 1 Token。"""
    return max(1, int(len(text) / chars_per_token))


budget = TokenBudget(window=128_000, prompt=2_000, retrieved=90_000, output=4_000)
print(budget.fits(), budget.remaining)
print(estimate_tokens("请把下面这段中文总结成三句话。"))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把「生成式 AI」等同于「大模型」 | 概念混淆 | 生成式 AI 含图像、语音等多种模型 |
| 认为模型参数越多越好 | 成本与延迟失控 | 按任务难度选型，小模型 + 路由常更划算 |
| 按字符数估 Token | 预算估算偏差大 | 中文与代码的 Token 密度不同，按实测校准 |
| 忽略上下文窗口限制 | 请求被截断或报错 | 预留输出空间并裁剪资料 |
| 认为模型输出一定正确 | 幻觉进入生产 | 提供依据 + 校验 + 兜底话术 |
| 用大模型做纯规则任务 | 成本高且不稳定 | 规则能解决就用规则 |
| 不记录模型版本 | 结果变化无法归因 | 记录模型名、版本与参数 |
| 忽略推理参数影响 | 输出不稳定 | 明确温度、top_p 与最大输出长度 |
| 直接处理敏感数据 | 合规风险 | 脱敏、鉴权与私有部署 |
| 只做 Demo 不做评测 | 上线后质量不可控 | 建离线评测集并持续回归 |

## 自测清单

- [ ] 能画出 AI、机器学习、深度学习、生成式 AI 的层级关系。
- [ ] 能按任务选择合适的模型类型（判别、生成、嵌入、重排）。
- [ ] 会为请求做 Token 预算并预留输出空间。
- [ ] 知道幻觉无法完全消除，必须用检索与校验兜底。
- [ ] 模型版本与推理参数都进入配置管理与评测。

## 动手练习


> 本课练习重点：围绕「AI、机器学习、深度学习」完成复述、实验和交付，每个结果都要能被别人检查。

先写评测样例，再改一个提示、模型或数据变量，最后比较质量、成本与安全。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「AI、机器学习与生成式 AI」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「机器学习」是什么关系？

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
- 至少覆盖「AI」和「机器学习」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：监督学习与无监督学习的关键区别是？

- **正确判断**：是否使用带标签的数据
- **判断依据**：监督学习需要标签，无监督学习从未标注数据中发现结构。其他选项：监督与无监督的区别在于是否使用带标签的数据。与数据量、是否用神经网络、是否在线运行都无关。正确项「是否使用带标签的数据」描述正确，能够解释题干场景中的现象与结果。错误项「数据量大小」在边界或失败路径上会得出错误结果。把题干「监督学习与无监督学习的关键区别是？」放回《AI、机器学习与生成式 AI》的「三者关系、三类学习范式与学习路径」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：生成式 AI 与深度学习的关系是？

- **正确判断**：生成式 AI 是深度学习的一个应用方向
- **判断依据**：生成式 AI 主要建立在深度学习（尤其是 Transformer 与扩散模型）之上。其他选项：生成式 AI 是深度学习的一个应用方向，而不是取代它。两者的包含关系也不能颠倒。正确项「生成式 AI 是深度学习的一个应用方向」抓住了题干的核心条件，是经得起边界检验的表述。错误项「两者无关」把不同概念混在一起，缺少题干限定的前提。错误项「生成式 AI 取代了深度学习」与课程给出的定义相冲突，不能回答题目所问。错误项「深度学习属于生成式 AI」在边界或失败路径上会得出错误结果。把题干「生成式 AI 与深度学习的关系是？」放回《AI、机器学习与生成式 AI》的「三者关系、三类学习范式与学习路径」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：上下文窗口指的是？

- **正确判断**：模型一次能处理的 token 上限
- **判断依据**：上下文窗口决定单次请求可以携带多少 token，超出需要分块、摘要或检索。其他选项：上下文窗口指单次能处理的 token 上限。训练数据总量与参数个数都是另外的概念。正确项「模型一次能处理的 token 上限」与本课示例和结论一致，可以直接用于实际编码。错误项「屏幕显示区域」只看到了表面现象，没有解释题干真正考查的机制。错误项「模型的参数个数（仅部分场景成立）」把因果关系颠倒了，不能作为正确结论。把题干「上下文窗口指的是？」放回《AI、机器学习与生成式 AI》的「三者关系、三类学习范式与学习路径」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：AI、机器学习与深度学习的包含关系是？

- **正确判断**：深度学习 ⊂ 机器学习 ⊂ 人工智能
- **判断依据**：AI 是最大范畴，机器学习是其中依赖数据学习规律的分支，深度学习是其子集。其他选项：包含关系是深度学习 ⊂ 机器学习 ⊂ 人工智能。其余选项把层次颠倒或说成互不相干。正确项「深度学习 ⊂ 机器学习 ⊂ 人工智能」描述正确，能够解释题干场景中的现象与结果。错误项「三者互相独立」与课程给出的定义相冲突，不能回答题目所问。错误项「机器学习 ⊂ 深度学习 ⊂ AI」只看到了表面现象，没有解释题干真正考查的机制。错误项「AI ⊂ 深度学习」适用于其他场景，但与本题的前提不匹配。把题干「AI、机器学习与深度学习的包含关系是？」放回《AI、机器学习与生成式 AI》的「三者关系、三类学习范式与学习路径」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：Token 与「词」的关系是？

- **正确判断**：Token 是模型处理文本的最小单位
- **判断依据**：计费、上下文长度与截断策略都按 Token 计算，中文往往一个字对应 1~2 个 Token。其他选项：Token 是模型处理文本的最小单位。正确项「Token 是模型处理文本的最小单位」与本课示例和结论一致，可以直接用于实际编码。错误项「一个 Token 恒等于一个词」只看到了表面现象，没有解释题干真正考查的机制。错误项「Token 只在中文里存在」在边界或失败路径上会得出错误结果。错误项「Token 就是字符编码」适用于其他场景，但与本题的前提不匹配。把题干「Token 与「词」的关系是？」放回《AI、机器学习与生成式 AI》的「三者关系、三类学习范式与学习路径」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「监督学习与无监督学习的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「生成式 AI 与深度学习的关系是？」的判断依据。
- [ ] 不看解析，能说出「上下文窗口指的是？」的判断依据。
- [ ] 不看解析，能说出「AI、机器学习与深度学习的包含关系是？」的判断依据。
- [ ] 不看解析，能说出「Token 与「词」的关系是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** AI, ML & GenAI

**Summary:** How AI, ML, DL and GenAI relate.

**Category:** AI & Agents  
**Level:** 基础  
**Key terms:** AI, 机器学习, 深度学习, 生成式 AI

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：主流大模型 API、开源模型与向量数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：AI、机器学习、深度学习、生成式 AI
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## Full English Study Guide

### Overview

**AI, ML & GenAI** focuses on How AI, ML, DL and GenAI relate.

### Learning Outcomes

- Explain what **AI, ML & GenAI** solves and when it should be used.
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

- Topic: **AI, ML & GenAI**
- Related terms: AI, 机器学习, 深度学习, 生成式 AI
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 三个概念的关系 | 三个概念的关系 |
| 机器学习的三类范式 | 机器学习的三类范式 |
| 生成式 AI 能做什么 | 生成式 AI 能做什么 |
| 典型应用架构 | 典型应用架构 |
| 学习路径建议 | 学习路径建议 |
| 术语速查 | 术语速查 |
| 从场景反推技术选型 | 从场景反推技术选型 |
| 本课小结 | Summary |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


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

> 本课主题：三者关系、三类学习范式与学习路径。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

