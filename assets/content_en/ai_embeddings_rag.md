# Embedded, Vector Retrieval and RAG

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- It is possible to explain in its own words what the problem of embedded, vector-retrieving and RAG has been solved rather than simply using terminology.
- The relationship between "embedded" and "vector search", "ag," and "parts" is clear, with one example.
- It's a way to put this subject back into the "AI and smart body" knowledge system, which is an example of how it works with each other.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of a sentence: semantic vector, vector bank, RAG process and segment policy.

## Pre-knowledge

- The first lesson is " Tip Project " ; if available, this course can be used for self-testing.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Read it first: embedded, vector search, RAG.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Embedded: Turn text into vector

Embedded models map text into high-dimensional vectors, and semantically similar texts are closer in vector space.

```python
from openai import OpenAI
client = OpenAI()
response = client.embeddings.create(
    model="text-embedding-3-small",
    input=["二分查找的时间复杂度", "二分法查找效率"],
)
v1, v2 = [item.embedding for item in response.data]
```

Similarity ** cosine symmetry (direction only, not length):

```text
cos(a, b) = (a · b) / (|a| × |b|)      越接近 1 越相似
```

## Vector Database

|Programme|Features|
| --- | --- |
| FAISS |Single hangar, fast. Prototype and offline.|
| Chroma |Light and easy to use, suitable for small-scale local applications|
| pgvector |Directly on PostgreSQL.|
| Milvus / Qdrant / Pinecone |Large-scale or hosting scenes|

Retrieval process: Query to the nearest search (ANN) for Top-K reorderable.

## RAG: Let the model be based on information

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

## Split Policy

|Policy|Application|
| --- | --- |
|Fixed length + overlapping|Universal, simple and reliable.|
|By Title/Paragraph|Structured documents, semantic integrity|
|Split by code/table|Technical files, keep grammar complete.|
|Father and son (small piece search, large item feeding model)|Balance search accuracy with context integrity|

Too much noise and too little semantic; the common starting point is 300-800 token, which overlaps 10-20%.

## Key points for impact

1. Retrieving quality is more important than hints - no search, only the model.
2. Adding a rearrangement (cross-encoder) usually increases the Top-K quality significantly.
3. Quoted and traced to facilitate user verification.
4. Mixed search (keyword BM25+ vector) is more proficient to proprietary terms and codes.
5. Periodic assessment: hit rate, correct answer rate, accurate reference rate.

## Directly available reminder template

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

The value of the template is **: limited source, specified reference, consistent requirements and prohibition.

## Evaluation of script points

1. Four types of use are prepared: direct access, cross-document synthesis, no answers and adversarial representations (input).
2. Each record: question, standard answer points, expected document ID.
3. Automatic indicator: Whether Top-K contains the desired document, point coverage, quote accuracy, correct rejection rate for questions not answered.
4. LLM-as-Judge ** Manually calibrated to avoid judgement evaluation.
5. Each time the partitioning, embedding and re-drive are used in one set of examples to form a return.

By connecting this script to the CI, you can avoid a common trap of changing tips, feeling better and getting worse.

## Mixed Retrieval and Reordering

**Why a mix is needed**: Vector search is symmetrical ( "how to return" ↔ "refunding process") but it can easily fail with proprietary terms, code identifiers and model numbers; keyword retrieval (BM25) is the opposite.The two complement each other.

|Programme|Advantage|Disadvantages|
| --- | --- | --- |
|Pure Vector|That's a good syntax.|Rare word/precision match weak|
|Pure BM25|It's a good match, fast.|Do not understand synonyms and rewrite|
|Mixed + Reset|Recall and precision.|Longer links, delays and increased costs|

** Integration strategy**: It is common to combine Top-20s with RRF (incorporation in penultimate ranking) - not counting, avoiding the problem of dichotomy.The core parameter for RRF is constant k (commonly 60) and the larger it becomes weaker than head differences.

** Threshold reference for the two-stage search**

1. Top-K: Too small to slip (low rate of recall), too large to introduce noise, and suggest a switch from 20.
2. Reset Top-N feed model: N usually takes 3-5 depending on the context budget.
3. Similarity threshold: no direct rating below the threshold " ,** which must be measured in aggregate** (the distribution of fractions between embedded models is very different and cannot be replicated).
4. And judging by the curve of hit rate and correct answer rate: K increases but probably decreases both.

The method of evaluation is a fixed set of questions, running pure vectors, BM25, mixing and reordering four configurations, comparing the hit rate with the correct answer rates, P95 delay to the cost per question and using data to decide whether it would be worthwhile to introduce a new one.

## It's the end of this class.
RAG = **Research + Generate**. It compensates for the knowledge cut-off and hallucination of models by using external knowledge, which is currently the most common LLM structure in which enterprises land.

<!-- appendix:v1 -->

## RAG, link check.

|Phase|Key decision-making|Common practice|
| --- | --- | --- |
|Parsing|Retain Structure & Page Number|PDF Parsing, Table Structure|
|Blocks|Gravity and overlap|300 to 800 Token, overlap 10% to 20%|
|Embedded|Models and dimensions|Chinese preferred text or multilingual model|
|Storage|Vector & Metadata|Vector + Document ID + Location + Permission|
|Retrieval|The recall strategy.|Vector + Mixing of Keywords, top 20-50|
|Reorder|Platoon|Cross-Encoder takes three to eight|
|Generate|Tip Constructing|Snippet number + request reference|
|Evaluation|Hit and answer.|Recall rate, fidelity, accuracy of reference|

## Similarity.

|Measurement|Formula Intuitive|Application|
| --- | --- | --- |
|Cosine Similarity|Look at the angles.|Text Embedding (most commonly used)|
|Point|Direction and length.|Equivalent to Cosine|
|Orchid distance.|Look at the distance.|Image Features|
|Maximum Internal Search (MPS)|Max.|Recommended and retrieved|

Important premise:** Query and documentation must be based on the same embedded model** or not in vector space.

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

## Split Policy Contrast

|Policy|Application|Attention.|
| --- | --- | --- |
|Fixed length|Universal Quick Programme|Maybe cut the sentence.|
|By Paragraph|Clear Document|It's too long to cut.|
|By Title Level|Handbooks, norms|Retain title as context|
|Semantic Blocks|The subject of content is clearly changed.|Costed|
|Father and son.|Retrieving small pieces, returning large ones.|Balance Precision with Context|
|Tables and charts are handled separately|Financial statements, papers|Change to a structured description|

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Different embedded models for query and document|Retrieval results random|Harmonization of models and versions|
|It's too big.|Retrieving noise|300 to 800 Token, overlay.|
|It's too small.|Semantic Break|Retain Title & Context Prefix|
|No reordering|Inadequate relevance|Cross-Encoder Platoon after vector recall|
|No metadata filter|Excessive recall of another person's file|Force Filter by Tenants and Permissions|
|Can not open message|Answers cannot be verified.|Snippet document ID and position, answer the reference|
|I don't know what to do with it.|End-to-end quality|Evaluate recall and generation separately|
|Do not recreate the index after updating|Users get old content|Change Trigger Index and Version Tag|
|Directly spell user input|Injection|Separator sequester and declare that information is not credible|
|Ignore document parsing quality|Table Numeric|Sampling after parsing|

## Self-Detected List

- [ ] Can draw a complete link between RAG and the decision point at each stage.
- [ ] The search uses the same embedded model and version as the document.
- [ ] The particle size is reasonable and the context and source information is maintained.
- [ ] Retrieving metadata privileges filters and rearrangements.
- [ ] Assessment of the quality of recall and response, respectively.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around "Infiltration, Vector, RAG" each result is subject to scrutiny.

Prepare a sample, then change the hint, model or data variable and eventually compare quality, cost and safety.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with embedded, vector search and RAG?
2. Without it, what concrete consequences would there be?
3. What does it have to do with vector search?

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

- The result must be checked, not just "I understand."
- I'm not sure if you're going to be able to do this.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Embeddings & RAG

**Summary:** Embeddings, vector stores, RAG and chunking.

**Category:** AI & Agents  
**Level:** Progress
**Key terms:** Embedded, Vector Retrieval, RAG, Reorder

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable environment: main mainstream model API, open source model and vector database
- Source: Internal structured curriculum and engineering practices
- Related themes: embedded, vector search, RAG, reordering
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

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
- Relaid terms: embedded, vector search, RAG, segment
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Embedded: Turn text into vector|Embedded: Translating text into Victor|
|Vector Database| VectorDatabase |
|RAG: Let the model be based on information|RAG: Let Model answer on the basis of information|
|Split Policy|Split Policy|
|Key points for impact|Key points for impact|
|Directly available reminder template|Directly available Prompt templates|
|Evaluation of script points|Evaluation of script points|
|Mixed Retrieval and Reordering|Mixed Retrieval and Rearrangement|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

