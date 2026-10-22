# AIAgent Base

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Projected time: 17 minutes

## Learning objectives

- It is possible to explain in its own words what the "AI Agent Foundation" solves, not just a term.
- The relationship between "Agent", "React," "tool calls" and "MCP" is clear, with one example.
- It's a way to put this subject back into the "AI and smart body" knowledge system, which is an example of how it works with each other.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: rect cycle, tool call, memory and MCP.

## Pre-knowledge

- The first lesson is " Embedded, Vector and RAG " ; if available, this course can be used for self-testing.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Read it before starting: Agent, Rect.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## The difference between Agent and normal conversations

```text
普通 LLM：输入 -> 输出（一轮问答）
Agent   ：目标 -> 思考 -> 调用工具 -> 观察结果 -> 再思考 -> …… -> 完成
```

An Agent usually consists of four parts:

|Composition|Role|
| --- | --- |
|Model (brain)|Decision-making, planning and generation|
|Tools (hands and feet)|Search, computing, database, code execution, API|
|Memory.|Preservation of dialogue, facts and historical experience|
|Loop control|To decide when to continue, when to end and when to deliver.|

## Rect

REACT = Reasoning+Acting, the classic Agent mode:

```text
Thought     我需要知道今天的汇率
Action      调用 tool: get_exchange_rate(currency="USD", date="today")
Observation {"rate": 7.12}
Thought     已经拿到数据，可以回答了
Answer      今天美元兑人民币约为 7.12
```

Points: Each step** is observable, interruptable and retried**; the cycle must have a maximum number of steps or it may not be used indefinitely.

## Tools Call

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

Process: Hand over the tool description to the model → "What function will you call, what parameters?"** The model is only responsible for making decisions, and the execution must be controlled by your code and authorized.**

## Memory.

|Type|Annotations|
| --- | --- |
|Short-term memory.|Context window for the current dialogue|
|Long-term memory|Fact and preference of vector storage, search as required|
|Situational memory|Processes and Results of Past Tasks for Rewinding|
|Semantic Memory|Abstracted rules and knowledge|

The long context requires** a strategy of compression and oblivion**: summary history, preservation of key facts, search for relevance rather than brainlessness.

## MCP: Model context protocol

MCP (Model Context Protocol) exposes "tool and data sources" to the model client:

```text
Agent（MCP Client） <-> MCP Server（文件、数据库、GitHub、浏览器…）
```

The benefits are one-time realization, multiple client reuse; security limits on server access to sensitive resources.

## Design list

1. The tool describes the use, parameters and structure of return for a model to be correct.
2. All tools are to be called with time-out, retrying and so forth.
3. Critical operations (transfers, deletions and mail) must be manually confirmed (human-in-the-loop).
4. Sets maximum steps, maximum token and budget ceiling.
5. Record the whole trip, easy to play and position.

## React recycleable skeletons

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

Three security boundaries:** white list of tools** (models cannot call unregistered capacity),** parameter validation and abnormal background** (tool failure leads to error rather than collapse)** maximum step** (preventing unlimited cycle burning).The production environment is subject to overtime, authorization and manual validation points.

## It's the end of this class.
Agent = **LLM +Memory + Cycle**. Its capacity ceilings are determined by tools and its reliability is determined by circular controls, privileges and assessments.

<!-- appendix:v1 -->

## Agent make a quick check.

|Composition|Role|Design elements|
| --- | --- | --- |
|Model|Logic and decision-making|Select by task difficulty, support the call|
|System Tips|Defining roles, boundaries and output norms|Version management, with evaluation|
|Tools|Interact with the outside world|It's clear. The parameters are schema, as much as possible.|
|Memory.|Short-term context and long-term storage|Summary + Vector Retrieval + Metadata Filter|
|Planning|Disaggregation and sequence of tasks|Support for reprogramming, limit maximum steps|
|Reflections|Self-censorship and correction|Clear acceptance criteria|
|Watch out!|Authority and security|White list, speed limit, sensitive operation confirmed.|
|Observable|Query and Optimization|Record full trajectories, Token and time consuming|

## Quick check of circulation and termination conditions

|Link|Annotations|
| --- | --- |
|Observe|Read input, tool return and intermediate results|
|Think|Analysis of the current situation and decision on next steps|
|Action|Call or give the answer|
|Terminating|Final answer, maximum number of steps, time overruns, manual intervention.|

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

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|No maximum step|Infinite cycle, out of control.|Clear maximum step and timeout|
|Tool Description Fuzzy|Model error, repeat|Write uses, parameters and return structures|
|Tools without protection|Retrying leads to repeats.|Introduction of quail, write and confirm.|
|Put everything in the context.|It's expensive, it's distracted.|Only necessary information. Long files go for search.|
|Unauthorised|Agent overstepping|White List & Parameter Validation, without hints|
|Only the final answer.|Unable to detect circuits and dangerous calls|Evaluate full track and tool call sequences|
|Reliance on the model to report success|A fake success caused an accident online.|Let's use the tool to judge the results.|
|No one's working.|High-risk operations cannot be aborted.|Critical actions require manual confirmation (human in the loop)|
|The hints are mixed with the code.|Can't trace it.|Plugin library, change evaluation and assessment|

## Self-Detected List

- [ ] Agent has a clear list of roles, tools and conditions for termination.
- [ ] All tools are designed with parameters such as schema.
- [ ] Record the entire trajectory (summary of reflection, tool call, time-consuming, Token).
- [ ] High-risk operations require manual confirmation or rollback programmes.
- [ ] Evaluate whether it is reasonable to evaluate both the results and the number of steps and tools.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeat, experiment and deliver around "Agent, React, Tools" each result to be checked.

Prepare a sample, then change the hint, model or data variable and eventually compare quality, cost and safety.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with AI Age Foundation?
2. Without it, what concrete consequences would there be?
3. What's it got to do with "React"?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Construct 5 small offline examples of input, desired output, rating criteria and failure cases.

Mission requests:

- The result must be checked, not just “I understand”.
- This post is part of our special coverage “Agent” and “React”.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** AI Agent Basics

**Summary:** ReAct loop, tool calling, memory and MCP.

**Category:** AI & Agents  
**Level:** Foundation
**Key terms:**Agent, React, tool call, MCP, memory

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable Environment: Mainstream Large Model API, Open Source Model and Vector Database
- Source: Internal structured curriculum and engineering practices
- Related themes: Agent, React, Tool Call, MCP, Memory
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- top50-rewrite:v1 -->

## The curriculum is based on the following:

### I. KNOWLEDGE

- ** Distinguished from normal conversations**: regular LLM: Input - > Output (round of questions and answers)
- **React Loop**: Reacting = Reasoning+Acting, the classic Agent mode:
- **Function Calling
- **Remember: understand its definition, input, output and failed boundaries.
- **MCP: Model Context protocol**: MCP (Model Context Protocol) exposes "tool and data sources" to the model client by means of a unified agreement:
- ** Design list: 1. The tool describes the purpose, parameters and structure of return in order for the model to be correct.
- **React recoilable skeletons**:import json
- **Agent composition quick check**: understanding its definition, input, output and failure boundaries.

### II. MECHANISMS AND VERIFICATION

|Theme|Questions to answer|Authentication Method|
| --- | --- | --- |
|The difference between Agent and normal conversations|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Rect|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Tools Call|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Memory.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|MCP: Model context protocol|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Design list|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|React recycleable skeletons|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Agent make a quick check.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|

### III. EXCHANGE ISSUES

1. What's the difference between Agent and a regular conversation?
2. React, what's the boundary with an adjacent subject?
3. What's the border between Function Calling and an adjacent theme?
4. What's the border with the adjacent subject?
5. MCP: What is the boundary of a model context with an adjacent theme?
6. What's the boundary with an adjacent subject?
7. React, what's the line between a revolving skeletal and an adjacent subject?
8. What is the boundary between Agent's formation and the adjacent subject?

### IV. FUNCTIONS CLASSING

1. Fixed input and environment, confirming problem recurrence.
2. Find the first anomaly, don't guess from the end.
3. Only one variable is changed, and projections and real results are recorded.
4. Rehabilitate borders, fail and repeat tests.

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
- Relaid terms: Agent, React, Tool Call, MCP
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|The difference between Agent and normal conversations| Difference between Agent and Normal Conversation |
|Rect| ReAct Loop |
|Tools Call| Function Calling |
|Memory.| memory. |
|MCP: Model context protocol| MCP: Model Context Protocol |
|Design list| Design checklist |
|React recycleable skeletons| Runnable skeleton of a ReAct cycle |
|It's the end of this class.| Lesson Summary |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

