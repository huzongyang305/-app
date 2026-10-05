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

<!-- appendix:v1 -->

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

<!-- practice-diversified:v1 -->

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

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

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

<!-- top50-rewrite:v1 -->

## 课程专属精读：AI Agent 基础

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| Agent 与普通对话的区别 | 普通 LLM：输入 -> 输出（一轮问答） Agent ：目标 -> 思考 -> 调用工具 -> 观察结果 -> 再思考 -> …… -> 完成 | 运行示例 + 换一个边界输入 |
| ReAct 循环 | ReAct = Reasoning + Acting，是最经典的 Agent 模式： | 运行示例 + 换一个边界输入 |
| 工具调用（Function Calling） | tools = [{ "type": "function", "function": { "name": "queryorders", "description": "按用户 … | 运行示例 + 换一个边界输入 |
| 记忆 | 上下文过长时需要压缩与遗忘策略：摘要历史、保留关键事实、按相关性检索，而不是无脑全塞。 | 复述要点 + 举一个反例 |
| MCP：模型上下文协议 | MCP（Model Context Protocol）用统一协议把「工具与数据源」暴露给模型客户端： | 运行示例 + 换一个边界输入 |
| ReAct 循环的可运行骨架 | import json | 运行示例 + 换一个边界输入 |

### 二、机制与验证

1. **Agent 与普通对话的区别**：普通 LLM：输入 -> 输出（一轮问答） Agent ：目标 -> 思考 -> 调用工具 -> 观察结果 -> 再思考 -> …… -> 完成 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
2. **ReAct 循环**：ReAct = Reasoning + Acting，是最经典的 Agent 模式： 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
3. **工具调用（Function Calling）**：tools = [{ "type": "function", "function": { "name": "queryorders", "description": "按用户 … 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
4. **记忆**：上下文过长时需要压缩与遗忘策略：摘要历史、保留关键事实、按相关性检索，而不是无脑全塞。 验证方式：先复述要点，再举一个反例说明边界。
5. **MCP：模型上下文协议**：MCP（Model Context Protocol）用统一协议把「工具与数据源」暴露给模型客户端： 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
6. **ReAct 循环的可运行骨架**：import json 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。

### 三、专属检查问题

1. 「Agent 与普通对话的区别」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「ReAct 循环」的输入和输出分别是什么？
3. 「工具调用（Function Calling）」最常见的失败方式是什么？如何定位？
4. 「记忆」的适用边界在哪里？什么情况下不该使用？
5. 「MCP：模型上下文协议」和相邻主题相比，最关键的差别是什么？
6. 「ReAct 循环的可运行骨架」如何验证自己真的掌握了？写出一个可执行的检查步骤。

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：Agent 与普通对话的区别的核心要点是什么？**

答：普通 LLM：输入 -> 输出（一轮问答） Agent ：目标 -> 思考 -> 调用工具 -> 观察结果 -> 再思考 -> …… -> 完成

**问：ReAct 循环的核心要点是什么？**

答：ReAct = Reasoning + Acting，是最经典的 Agent 模式：

**问：工具调用（Function Calling）的核心要点是什么？**

答：tools = [{ "type": "function", "function": { "name": "queryorders", "description": "按用户 …

**问：记忆的核心要点是什么？**

答：上下文过长时需要压缩与遗忘策略：摘要历史、保留关键事实、按相关性检索，而不是无脑全塞。

**问：MCP：模型上下文协议的核心要点是什么？**

答：MCP（Model Context Protocol）用统一协议把「工具与数据源」暴露给模型客户端：

**问：ReAct 循环的可运行骨架的核心要点是什么？**

答：import json

## 逐步练习：AI Agent 基础

### 练习 1：Agent 与普通对话的区别

1. 不看原文，用自己的话复述：普通 LLM：输入 -> 输出（一轮问答） Agent ：目标 -> 思考 -> 调用工具 -> 观察结果 -> 再思考 -> …… -> 完成
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：ReAct 循环

1. 不看原文，用自己的话复述：ReAct = Reasoning + Acting，是最经典的 Agent 模式：
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：工具调用（Function Calling）

1. 不看原文，用自己的话复述：tools = [{ "type": "function", "function": { "name": "queryorders", "description": "按用户 …
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 4：记忆

1. 不看原文，用自己的话复述：上下文过长时需要压缩与遗忘策略：摘要历史、保留关键事实、按相关性检索，而不是无脑全塞。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 5：MCP：模型上下文协议

1. 不看原文，用自己的话复述：MCP（Model Context Protocol）用统一协议把「工具与数据源」暴露给模型客户端：
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 6：ReAct 循环的可运行骨架

1. 不看原文，用自己的话复述：import json
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：AI Agent 基础

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「Agent 与普通对话的区别」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「ReAct 循环」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「工具调用（Function Calling）」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「记忆」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「MCP：模型上下文协议」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「ReAct 循环的可运行骨架」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：AI Agent 基础

1. 「Agent 与普通对话的区别」的输入和输出分别是什么？
2. 「ReAct 循环」最常见的失败方式是什么？如何定位？
3. 「工具调用（Function Calling）」的适用边界在哪里？什么情况下不该使用？
4. 「记忆」和相邻主题相比，最关键的差别是什么？
5. 「MCP：模型上下文协议」如何验证自己真的掌握了？写出一个可执行的检查步骤。
6. 「ReAct 循环的可运行骨架」要解决什么问题？请用一句话说明，并给出一个具体例子。

## 专属进阶任务 5：AI Agent 基础

把本课 6 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

### 验收标准

- 例子可以独立运行，输出与预期一致。
- 两条边界用例都说清了输入、预期与实际结果。
- 验证结论用一句话写清，不依赖“感觉正确”。

<!-- full-english-guide:v1 -->
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

<!-- bilingual-outline:v1 -->

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

> 本课主题：ReAct 循环、工具调用、记忆与 MCP。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

