# AI Agent 基础

![AI Agent 基础](images/remaining_ai_agent_basics.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：17 分钟

## 学习目标

- 能用自己的话解释「AI Agent 基础」解决了什么问题，而不是只背术语。
- 能说清 「Agent」、「ReAct」、「工具调用」、「MCP」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「AI 与智能体」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：ReAct 循环、工具调用、记忆与 MCP。

## 前置知识

- 先完成上一课《嵌入、向量检索与 RAG》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：Agent、ReAct、工具调用。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## Agent 与普通对话的区别

```text
普通 LLM：输入 -> 输出（一轮问答）
Agent   ：目标 -> 思考 -> 调用工具 -> 观察结果 -> 再思考 -> …… -> 完成
```

一个 Agent 通常由四部分组成：

| 组成 | 作用 |
| --- | --- |
| 模型（大脑） | 决策、规划、生成 |
| 工具（手脚） | 搜索、计算、数据库、代码执行、API |
| 记忆 | 保存对话、事实与历史经验 |
| 循环控制 | 决定何时继续、何时结束、何时交给人 |

## ReAct 循环

ReAct = Reasoning + Acting，是最经典的 Agent 模式：

```text
Thought     我需要知道今天的汇率
Action      调用 tool: get_exchange_rate(currency="USD", date="today")
Observation {"rate": 7.12}
Thought     已经拿到数据，可以回答了
Answer      今天美元兑人民币约为 7.12
```

要点：每一步都要**可观察、可中断、可重试**；循环必须有最大步数上限，否则可能无限调用工具。

## 工具调用（Function Calling）

```python
tools = [{
    "type": "function",
    "function": {
        "name": "query_orders",
        "description": "按用户 ID 查询订单列表",
        "parameters": {
            "type": "object",
            "properties": {
                "user_id": {"type": "string", "description": "用户唯一标识"},
                "limit": {"type": "integer", "default": 10},
            },
            "required": ["user_id"],
        },
    },
}]
```

流程：把工具描述交给模型 → 模型返回「要调用哪个函数、参数是什么」→ 你的程序真正执行 → 把结果回传给模型 → 模型决定下一步。**模型只负责决定，执行必须由你的代码控制并做权限校验。**

## 记忆

| 类型 | 说明 |
| --- | --- |
| 短期记忆 | 当前对话的上下文窗口 |
| 长期记忆 | 向量库存放的事实与偏好，按需检索 |
| 情景记忆 | 过去任务的过程与结果，用于复盘 |
| 语义记忆 | 抽象出的规则与知识 |

上下文过长时需要**压缩与遗忘策略**：摘要历史、保留关键事实、按相关性检索，而不是无脑全塞。

## MCP：模型上下文协议

MCP（Model Context Protocol）用统一协议把「工具与数据源」暴露给模型客户端：

```text
Agent（MCP Client） <-> MCP Server（文件、数据库、GitHub、浏览器…）
```

好处是一次实现、多个客户端复用；安全上要限制服务器权限，避免模型越权访问敏感资源。

## 设计清单

1. 工具描述写清楚用途、参数与返回结构，模型才会用对。
2. 所有工具调用都要有超时、重试与幂等设计。
3. 关键操作（转账、删除、发邮件）必须人工确认（Human-in-the-loop）。
4. 设置最大步数、最大 token 与预算上限。
5. 全程记录 trace，方便回放与定位问题。

## ReAct 循环的可运行骨架

```python
import json

MAX_STEPS = 6                     # 必须设上限，否则可能无限调用

TOOLS = {
    "get_weather": lambda city: {"city": city, "temp": 24, "desc": "多云"},
    "search_docs": lambda q: {"hits": ["..."]},
}

def run_agent(question: str) -> str:
    messages = [
        {"role": "system", "content":
         "你可以调用工具。需要时输出 JSON："
         '{"action":"工具名","args":{...}}；可以直接回答时输出 '
         '{"action":"final","args":{"answer":"..."}}'},
        {"role": "user", "content": question},
    ]
    for step in range(MAX_STEPS):
        raw = llm(messages)                       # 模型只负责决策
        plan = json.loads(raw)
        if plan["action"] == "final":
            return plan["args"]["answer"]
        tool = TOOLS.get(plan["action"])          # 白名单校验，未知工具直接拒绝
        if tool is None:
            messages.append({"role": "user", "content": "工具不存在，请重试"})
            continue
        try:
            result = tool(**plan["args"])         # 由我们的代码真正执行
        except Exception as exc:
            result = {"error": str(exc)}
        messages.append({"role": "user",
                         "content": "工具返回：" + json.dumps(result, ensure_ascii=False)})
    return "已达最大步数，未能完成任务"
```

三个安全边界：**工具白名单**（模型不能调用未注册能力）、**参数校验与异常兜底**（工具失败要回传错误而非崩溃）、**最大步数**（防止无限循环烧钱）。生产环境还要加超时、权限校验与人工确认点。

## 本课小结
Agent = **LLM + 工具 + 记忆 + 循环**。它的能力上限由工具决定，可靠性由循环控制、权限与评测决定。


## Agent 组成速查

| 组成 | 作用 | 设计要点 |
| --- | --- | --- |
| 模型 | 推理与决策 | 按任务难度选择，支持工具调用 |
| 系统提示 | 定义角色、边界、输出规范 | 版本化管理，配合评测 |
| 工具（Tools） | 与外部世界交互 | 描述清晰、参数有 schema、尽量幂等 |
| 记忆 | 短期上下文与长期存储 | 摘要 + 向量检索 + 元数据过滤 |
| 规划 | 任务分解与顺序 | 支持重规划，限制最大步数 |
| 反思 | 自我检查与纠错 | 明确的验收标准 |
| 护栏 | 权限与安全 | 白名单、速率限制、敏感操作二次确认 |
| 可观测性 | 排查与优化 | 记录完整轨迹、Token 与耗时 |

## 循环与终止条件速查

| 环节 | 说明 |
| --- | --- |
| 观察（Observe） | 读取输入、工具返回与中间结果 |
| 思考（Think） | 分析现状、决定下一步 |
| 行动（Act） | 调用工具或给出答案 |
| 终止 | 得到最终答案、达到步数上限、超时、预算耗尽、需要人工介入 |

```text
你可以使用以下工具：
- search_docs(query: string) -> 返回最相关的 5 个片段
- run_sql(sql: string) -> 只允许 SELECT，最多返回 100 行

工作规则：
1. 先检索资料再回答，禁止凭记忆编造字段名。
2. 每次只调用一个工具，观察结果后再决定下一步。
3. 最多调用 6 次工具；仍无法确定时，说明缺少什么信息。
4. 最终回答必须引用来源片段编号。
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不给步数上限 | 无限循环，成本失控 | 明确最大步数与超时 |
| 工具描述模糊 | 模型传错参数、反复重试 | 写清用途、参数含义与返回结构 |
| 工具无幂等保护 | 重试导致重复下单 | 引入幂等键，写操作加确认 |
| 把所有内容塞进上下文 | 成本高、注意力涣散 | 只放必要信息，长文档走检索 |
| 无权限控制 | Agent 越权操作 | 工具层做白名单与参数校验，不依赖提示词 |
| 只评测最终答案 | 无法发现绕路与危险调用 | 评测完整轨迹与工具调用序列 |
| 依赖模型自报成功 | 假成功导致线上事故 | 用工具返回的真实状态判断结果 |
| 没有人工兜底 | 高风险操作无法中止 | 关键动作需人工确认（human in the loop） |
| 提示词与代码混在一起改 | 无法回溯与回归 | 提示词入库，变更走评审与评测 |

## 自测清单

- [ ] Agent 有明确的角色、工具清单与终止条件。
- [ ] 所有工具都有参数 schema 与幂等设计。
- [ ] 全程记录轨迹（思考摘要、工具调用、耗时、Token）。
- [ ] 高风险操作需人工确认或有回滚方案。
- [ ] 评测既看结果，也看步数与工具调用是否合理。

## 动手练习


> 本课练习重点：围绕「Agent、ReAct、工具调用」完成复述、实验和交付，每个结果都要能被别人检查。

先写评测样例，再改一个提示、模型或数据变量，最后比较质量、成本与安全。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「AI Agent 基础」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ReAct」是什么关系？

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
- 至少覆盖「Agent」和「ReAct」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Agent 与普通一问一答的关键区别是？

- **正确判断**：能围绕目标循环调用工具并观察结果
- **判断依据**：Agent 通过「思考-行动-观察」的循环逐步逼近目标。其他选项：Agent 的关键是围绕目标循环调用工具并观察结果。回答长度与是否本地运行都不是区分点。正确项「能围绕目标循环调用工具并观察结果」是该问题的规范说法，换成其他表述都会丢失条件。错误项「只能本地运行（仅部分场景成立）」适用于其他场景，但与本题的前提不匹配。错误项「不需要模型」把因果关系颠倒了，不能作为正确结论。错误项「回答更长」属于相邻主题的说法，范围与本题要求不一致。把题干「Agent 与普通一问一答的关键区别是？」放回《AI Agent 基础》的「ReAct 循环、工具调用、记忆与 MCP」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：ReAct 循环的三个核心要素是？

- **正确判断**：Thought，Action
- **判断依据**：模型先推理，再选择动作，然后根据观察结果继续推理。其他选项：ReAct 循环是 Thought，Action 三要素。其余选项属于训练流程或无关概念。正确项「Thought，Action」是该问题的规范说法，换成其他表述都会丢失条件。错误项「训练、验证、测试」适用于其他场景，但与本题的前提不匹配。错误项「Prompt、Model、Token」忽略了题目中的限制条件，因此不成立。错误项「输入、输出、日志」属于相邻主题的说法，范围与本题要求不一致。把题干「ReAct 循环的三个核心要素是？」放回《AI Agent 基础》的「ReAct 循环、工具调用、记忆与 MCP」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：关于工具调用，下面说法正确的是？

- **正确判断**：模型只决定调用哪个工具
- **判断依据**：执行权必须在应用侧，并做参数校验、权限控制与超时重试。其他选项：模型只输出工具调用意图，真正执行与权限控制由应用代码负责。工具会失败，必须设计错误处理。正确项「模型只决定调用哪个工具」是该问题的规范说法，换成其他表述都会丢失条件。错误项「模型会直接执行工具」适用于其他场景，但与本题的前提不匹配。错误项「工具不需要权限控制」把因果关系颠倒了，不能作为正确结论。错误项「工具调用不会失败」属于相邻主题的说法，范围与本题要求不一致。把题干「关于工具调用，下面说法正确的是？」放回《AI Agent 基础》的「ReAct 循环、工具调用、记忆与 MCP」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：Agent 的「规划」通常包含什么？

- **正确判断**：把目标拆成子任务
- **判断依据**：规划与反思（reflection）配合，能让 Agent 在失败后换策略而不是重复同样的调用。其他选项：规划包含任务分解、顺序安排与根据中间结果的动态调整。只做检索或只调一次工具都不算规划。正确项「把目标拆成子任务」是该问题的规范说法，换成其他表述都会丢失条件。错误项「只生成最终答案」适用于其他场景，但与本题的前提不匹配。错误项「只做向量检索」把因果关系颠倒了，不能作为正确结论。错误项「只调用一次工具」忽略了题目中的限制条件，因此不成立。把题干「Agent 的「规划」通常包含什么？」放回《AI Agent 基础》的「ReAct 循环、工具调用、记忆与 MCP」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：为 Agent 设计工具时最关键的要求是？

- **正确判断**：描述清晰，参数 schema 明确
- **判断依据**：工具描述就是给模型的「接口文档」，含糊的描述会导致错误调用与反复重试。其他选项：工具要描述清晰、参数 schema 明确、尽量幂等且失败可解释。工具过多或功能混杂会让模型难以选择。正确项「描述清晰，参数 schema 明确」既符合定义也满足题干限定的场景，因此应当选择。错误项「工具数量越多越好」忽略了题目中的限制条件，因此不成立。错误项「把多个功能塞进一个工具」属于相邻主题的说法，范围与本题要求不一致。错误项「只要返回字符串即可」把不同概念混在一起，缺少题干限定的前提。把题干「为 Agent 设计工具时最关键的要求是？」放回《AI Agent 基础》的「ReAct 循环、工具调用、记忆与 MCP」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Agent 与普通一问一答的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「ReAct 循环的三个核心要素是？」的判断依据。
- [ ] 不看解析，能说出「关于工具调用，下面说法正确的是？」的判断依据。
- [ ] 不看解析，能说出「Agent 的「规划」通常包含什么？」的判断依据。
- [ ] 不看解析，能说出「为 Agent 设计工具时最关键的要求是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** AI Agent Basics

**Summary:** ReAct loop, tool calling, memory and MCP.

**Category:** AI & Agents  
**Level:** 基础  
**Key terms:** Agent, ReAct, 工具调用, MCP, 记忆

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：主流大模型 API、开源模型与向量数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Agent、ReAct、工具调用、MCP、记忆
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## Full English Study Guide

### Overview

**AI Agent Basics** focuses on ReAct loop, tool calling, memory and MCP.

### Learning Outcomes

- Explain what **AI Agent Basics** solves and when it should be used.
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

- Topic: **AI Agent Basics**
- Related terms: Agent, ReAct, 工具调用, MCP
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning Objectives |
| 前置知识 | Pre-knowledge |
| Agent 与普通对话的区别 | Difference between Agent and Normal Conversation |
| ReAct 循环 | ReAct Loop |
| 工具调用（Function Calling） | Function Calling |
| 记忆 | memory. |
| MCP：模型上下文协议 | MCP: Model Context Protocol |
| 设计清单 | Design checklist |
| ReAct 循环的可运行骨架 | Runnable skeleton of a ReAct cycle |
| 本课小结 | Lesson Summary |

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

> 本课主题：ReAct 循环、工具调用、记忆与 MCP。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

