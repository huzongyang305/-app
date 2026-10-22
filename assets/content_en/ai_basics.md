# AI, Machine Learning and Generation AI

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Projected duration: 13 minutes

## Learning objectives

- I can explain in my own words what "AI, Machine Learning and Generating AI" solves, not just the term.
- The relationship between "AI," "mechanical learning", "deep learning" and "generic AI" is clear, with one example.
- It's a way to put this subject back into the "AI and smart body" knowledge system, which is an example of how it works with each other.
- It is possible to complete this course and check its results using acceptance standards.

A summary of the sentence: Three relationships, three learning paradigms and pathways.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Read it first: AI, machine learning, in-depth study.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Relationship between the three concepts

```text
人工智能 AI（让机器表现出智能）
└── 机器学习 ML（从数据中学习规律，而不是逐条写规则）
    ├── 深度学习 DL（用多层神经网络学习表示）
    │   └── 生成式 AI（生成文本、图像、音频、代码）
    └── 其他方法（决策树、SVM、聚类等）
```

The traditional programming is the "man-write rule" and machine learning is "person-to-data, machines to find rules", while generating AI is "mechanics generate new content on a probabilities basis."

## Three types of model for machine learning

|Parameter|Data|Objective|Example:|
| --- | --- | --- | --- |
|Supervision of learning|Label|Forecast Label|Price projections, spam classification|
|No supervisory learning|No Label|Found Structure|Cluster, dimension, anomaly detection|
|Enhanced learning|Incentive signal.|Learning policy.|Game AI, robotic control|

## What can I do?

- Text: Abstracts, translations, writing, code generation, questions and answers
- Images and videos: graphics, drawings, video production
- Voice recognition (ASR) and speech synthesis (TTS)
- Multiform: textual understanding, document resolution, screen operation

## Typical application architecture

```text
用户输入 -> 预处理（清洗/分块）-> 模型推理（LLM/多模态）
        -> 后处理（校验/引用/格式化）-> 返回结果
        -> 记录日志与评测指标 -> 持续迭代
```

## Learning Path Proposal

1. Create a concept map (preliminary to this classification).
2. Get a hint and call API, make the first small tool available.
3. Learn to embed with RAG so that the model is based on its own data.
4. Learning Agent: Tools to access, memory, planning and multi-intelligence.
5. Final engineering: assessment, cost, safety and detectability.

## Quick check of terminology

|Terminology|Meaning|
| --- | --- |
|Parameter / Weight|Values learned within the model|
|Training / Logic|Learning stage / Use phase|
| Token |The smallest unit for modeling text|
|Context Window|Token limit at once|
|Imagination.|Modeling seems to be a reasonable but incorrect element|

## Retrospect.

|Business scene|Recommended programme|Why?|
| --- | --- | --- |
|Document questions and answers (based on internal information)|RAG (Research Enhancement)|Knowledge is updated, traceable and not subject to training|
|Can not open message|Tip Project + Structure Output|Minimum cost, field control|
|Stable style and speech (visiting)|Less sample hints, fine-tuned if necessary|The style depends on the example, not on training.|
|High and simple categories|Small model + distillation/quantification|Delays and costs are sensitive enough|
|Multi-step operations (Listing, Checklist)|Agent + Tool Call|Need to interact with the system, not just generate|
|Image/Voice Processing|Multi-modular or specialized models|Visual/voice-specific models are usually more cost-effective|

Option four asks: **Whether knowledge needs to be updated frequently (for RAG), ** whether output must be structured strictly** (for schema + validation) ** Whether action is required** (to use tool + permission control) and ** What are the costs versus delayed budget** (tight small model + cache).Answer these four questions and decide whether to use a hint or a rag.

## It's the end of this class.
AI is the goal, and machine learning is a method. In-depth learning is current mainstream technology; generating AI is one of the hottest applications.** Clears up levels before going to some level.**

<!-- appendix:v1 -->

## Survey of the conceptual hierarchy

|Level|Watch it.|Example:|
| --- | --- | --- |
|Artificial intelligence|Let the machine show intelligence.|Planning, reasoning and perception|
|Machine learning.|Learning rules from data|Return, classification, cluster|
|In-depth learning|It's a multi-layered neural network.| CNN、Transformer |
|Generating AI|Generate new content|Text, Images, Audio, Video|
|Large Language Model|A large-scale pretrained text model| GPT、Claude、Llama、Qwen |

## Model Type Contrast

|Type|Enter to Output|Typical job.|
| --- | --- | --- |
|Ruler|Enter to Tab|Classification, testing and sequencing|
|Generating|Enter to New|Writing, mapping and speech synthesis|
|Embedded Model|Text to Vector|Retrieval, clustering, heavy.|
|Reorder Model|Query to Document Score|Platoon|
|Multimodule Model|Multiple mode input to text or content|Questions and answers, OCR understand.|

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

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|"Generate AI" is like a big model.|Confusion of concepts|Generating AI with Images, Voice etc.|
|The more we think about it, the better.|Cost and delay out of control|Select by task difficulty, small model + route is more cost-effective|
|By character Token|Budget estimates are very different|Chinese is different from code Token density, calibrated by reality|
|Ignore Context Limit|Request interrupted or misreported|Preserve output space and cut information|
|I think the model must be right.|Imagination into production.|Provide a basis + verify the background|
|It's a big model for pure rules.|It's expensive and unstable.|The rules are the rules.|
|Do not record model version|It's not the cause of change.|Record model names, versions and parameters|
|Ignore Arguments|Output Unstable|Specify temperature, top_p and maximum output length|
|Directly processing sensitive data|Compliance risk|De-sensitization, awareness and private deployment|
|Just do it, Demo. No evaluation.|Uncontrollable online.|Build offline assessment and continue to return|

## Self-Detected List

- [ ] Draws a hierarchy of AI, machine learning, in-depth learning, generating AI.
- [ ] Be able to select the appropriate model type by task (segregation, generation, embedding, re-alignment).
- [ ] Token budget and leave room for output.
- [ ] Knowing that hallucinations cannot be completely eliminated, the search and verification must go to the bottom.
- [ ] Model versions and reasoning parameters are entered into configuration management and evaluation.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeating, experimenting and delivering around "AI, Machine Learning, In-depth Learning", each result is subject to scrutiny.

Prepare a sample, then change the hint, model or data variable and eventually compare quality, cost and safety.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with "AI, Machine Learning and Generation"?
2. Without it, what concrete consequences would there be?
3. What's it got to do with "mechanical learning"?

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
- It's not like it's the same thing that happens to me.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** AI, ML & GenAI

**Summary:** How AI, ML, DL and GenAI relate.

**Category:** AI & Agents  
**Level:** Foundation
**Key terms:**AI, Machine Learning, In-depth Learning, Generating AI

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: main mainstream model API, open source model and vector database
- Source: Internal structured curriculum and engineering practices
- Related themes: AI, Machine Learning, In-depth Learning, Generating AI
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- top50-rewrite:v1 -->

## Courses are specialized: AI, Machine Learning and Generating AI

### I. KNOWLEDGE

- ** Relationship between the three concepts**: artificial intelligence AI
- ** Three types of model for machine learning: understanding its definition, input, output and failure.
- ** Generating AI can do **: understand its definition, input, output and failure boundaries.
- ** Typical application structure**: user input - > preprocessing (cleaning/division)- > model reasoning (LLM/multimodal)
- ** Study path proposal: 1. Create a conceptual map (preliminary to this classification).
- ** The terminology is fast-tracked: understanding its definition, input, output and failure boundaries.
- **Technology selected from the scene: understanding its definition, input, output and failure.
- **Strategic review: understanding its definition, input, output and failure.

### II. MECHANISMS AND VERIFICATION

|Theme|Questions to answer|Authentication Method|
| --- | --- | --- |
|Relationship between the three concepts|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Three types of model for machine learning|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|What can I do?|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Typical application architecture|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Learning Path Proposal|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Quick check of terminology|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Retrospect.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Survey of the conceptual hierarchy|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|

### III. EXCHANGE ISSUES

1. What's the relationship between these three concepts and each other?
2. What are the three paradigms of machine learning with each other?
3. What can I do with the borderline of an adjacent subject?
4. What's the border between typical application structures and adjacent themes?
5. What's the boundary between learning paths and adjacent themes?
6. What's the border with the adjacent subject?
7. What's the boundary between a scenario and an adjacent subject?
8. What's the boundary with an adjacent subject?

### IV. FUNCTIONS CLASSING

1. Fixed input and environment, confirming problem recurrence.
2. Find the first anomaly, don't guess from the end.
3. Only one variable is changed, and projections and real results are recorded.
4. Rehabilitate borders, fail and repeat tests.

<!-- full-english-guide:v1 -->

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
- Relaid terms: AI, Machine Learning, In-depth Learning, Generating AI
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Relationship between the three concepts|Relationship between the three concepts|
|Three types of model for machine learning|Three types of model for machine learning|
|What can I do?|What can I do?|
|Typical application architecture|Typical application architecture|
|Learning Path Proposal|Learning Path Proposal|
|Quick check of terminology|Quick check of terminology|
|Retrospect.|Retrospect.|
|It's the end of this class.| Summary |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

