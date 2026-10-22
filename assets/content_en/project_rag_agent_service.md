# Project: Local RAG Support Agent

![Project: Local RAG Support Agent](images/remaining_project_rag_agent_service.webp)

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.

> Content update time: 2026-10-03 | Level: Advanced | Estimated time: 140 minutes

## Learning objectives

- Separate document ingestion, chunking, indexing, retrieval, reranking and generation into independent stages.
- Make every answer carry traceable citations back to specific document chunks.
- Give agent tools parameter schemas, timeouts and least-privilege boundaries.
- Evaluate retrieval hit rate, citation correctness and refusal rate with an offline evaluation set.

> One-sentence summary: build an offline-demonstrable knowledge-base question answering agent covering chunking, retrieval, citations, tool calling, evaluation and guardrails.

## Prerequisites

- You understand embeddings and cosine similarity at a conceptual level.
- You can call a local or remote model behind a small interface and can mock it in tests.
- You know how to split a document while keeping source metadata.
- You have written tests for pure functions with deterministic fixtures.
- You accept that a model answer is untrusted output until evidence and policy checks pass.

## Project scenario

A support team needs to answer questions about product documentation. The system must retrieve evidence from a local knowledge base before generating an answer, and every claim must cite the retrieved source. When evidence is weak it must refuse to answer instead of guessing. When a question needs live data, such as an order lookup, the agent must call a controlled tool with a validated parameter schema rather than inventing a result.

The goal is not to build the largest possible agent. The goal is to build one whose answers can be audited: for each answer you can point to the evidence, reproduce the retrieval step and explain why a refusal happened.

## Architecture and data flow

```text
documents -> clean -> chunk -> index (keyword + vector)
                                      |
question -----------------------------+-> retrieve top-k -> rerank -> context budget
                                                                        |
                                                                        v
                                                             grounded generation
                                                                        |
                                          tool router (schema, allowlist, timeout)
                                                                        |
                                                                        v
                                                    answer + citations + trace
```

- Ingestion is a batch pipeline with a content hash so the same document is not indexed twice.
- Retrieval combines a keyword index for identifiers with a vector index for semantics, then reranks the merged candidates.
- The context builder enforces a token budget and keeps the source path and chunk offset for every included block.
- The generator receives only the selected context and must emit citation markers that the renderer validates.
- The tool router rejects unknown tools and invalid arguments before any side effect happens.
- The trace records stage timings, candidate counts, the chosen model and the refusal reason.

## Scope and features

- [ ] Import Markdown and plain text documents while preserving title, section and source path.
- [ ] Split documents into overlapping chunks that never cut a code block in half.
- [ ] Build a reproducible index with a manifest that records content hashes and embedding version.
- [ ] Retrieve with hybrid keyword plus vector search and rerank the top candidates.
- [ ] Answer only from retrieved evidence and attach citations to each answer.
- [ ] Refuse when the best score is below the threshold or no candidate is relevant.
- [ ] Call allowlisted tools with a schema, a timeout and a maximum result size.
- [ ] Emit retrieval and generation latency for every request.

## Implementation steps

### Step 1: Define chunks, sources and evaluation samples

Model a chunk as `id`, `document_id`, `text`, `heading_path`, `offset`, `content_hash` and optional `metadata`. Model an evaluation sample as a question, the expected source documents, whether the question is answerable, and the expected tool call if any. These two models determine what every later stage can prove.

Evidence: a committed JSON schema or dataclass plus five example samples with known sources.

### Step 2: Implement cleaning, chunking and metadata retention

Normalize line endings, strip navigation noise and keep the heading hierarchy. Split on paragraph boundaries with a target size and a small overlap, and treat fenced code blocks as atomic units. Every chunk must keep the path of its source document.

Evidence: a test that feeds a document with a code block and asserts that the block appears in exactly one chunk.

### Step 3: Build a reproducible vector index

Store the embedding model identifier, the chunking version and the document content hash in an index manifest. Rebuilding with unchanged inputs must produce the same chunk identifiers. A reproducibility test catches silent drift when the embedding model or chunk size changes.

Evidence: two consecutive builds produce the same manifest and the same retrieval results for a fixed query set.

### Step 4: Retrieve, rerank and control the context budget

Merge keyword and vector results with reciprocal rank fusion or a weighted score. Rerank the top candidates with a cross-encoder or a deterministic scoring function. Then fill the context within a token budget, preferring high-scoring and diverse chunks. Always keep the source metadata attached.

Evidence: a retrieval report showing recall@k on the evaluation set and a context assembly test that never exceeds the budget.

### Step 5: Ground the generation and validate citations

Pass numbered evidence blocks to the model and require the answer to reference those numbers. After generation, parse the citation markers and reject any answer that cites a missing block. When the top score is below the threshold or retrieval returns nothing, return a structured refusal with the reason.

Evidence: tests for a grounded answer, a missing-citation answer and an out-of-scope question.

### Step 6: Add controlled tools and offline evaluation

Register each tool with a name, a parameter schema, a timeout and a permission scope. Validate arguments against the schema before execution. Run the evaluation set on every change and compare hit rate, citation correctness, refusal rate and tool-call validity against the previous run.

Evidence: an evaluation table committed to the repository plus one CI job that fails on a regression beyond the agreed threshold.

## Key code

The function below shows the minimum contract of a grounded answer: retrieve, check evidence, build a bounded context, generate, and return the sources together with the answer.

```python
from dataclasses import dataclass

@dataclass
class Hit:
    text: str
    source: str
    score: float

def answer_question(question: str, retriever, llm) -> dict:
    hits = retriever.search(question, top_k=8)
    if not hits or hits[0].score < 0.62:
        return {
            'answer': 'The knowledge base does not contain enough evidence.',
            'citations': [],
            'grounded': False,
            'reason': 'low_retrieval_score',
        }

    context = '\n\n'.join(
        f'[{index}] {hit.text}\nSource: {hit.source}'
        for index, hit in enumerate(hits[:4], start=1)
    )
    response = llm.generate(
        system='Answer only from the supplied context. Cite every claim.',
        user=f'Question: {question}\n\nContext:\n{context}',
    )
    citations = [hit.source for hit in hits[:4]]
    return {'answer': response, 'citations': citations, 'grounded': True}
```

```python
TOOLS = {
    'get_order_status': {
        'schema': {'order_id': str},
        'scope': 'orders:read',
        'timeout_seconds': 3,
    },
}

def call_tool(name: str, arguments: dict) -> dict:
    if name not in TOOLS:
        raise ToolNotAllowed(name)
    spec = TOOLS[name]
    validate_arguments(spec['schema'], arguments)
    return execute_with_timeout(name, arguments, spec['timeout_seconds'])
```

Two boundaries are visible here. The retrieval threshold is the only reason the model is allowed to answer, and the tool router validates both the tool name and the arguments before any side effect. Neither decision is delegated to the language model.

## Verification commands and expected output

```bash
python -m support_agent.index --docs docs/ --out index/
python -m support_agent.evaluate --set evals/support_questions.jsonl
pytest -q tests/test_retrieval.py tests/test_grounding.py tests/test_tools.py
```

Expected evidence: the index command prints the number of documents and chunks and writes a manifest; the evaluation prints hit rate, citation correctness, refusal rate and tool validity; the tests show a grounded answer with citations, a refusal for an uncovered question, and a rejected tool call with an invalid parameter. Rebuilding the index twice with unchanged input must produce identical chunk identifiers.

## Suggested directory structure

```text
support_agent/
  ingest/
    clean.py          # normalization rules
    chunk.py          # paragraph-aware splitting
    index.py          # embedding and manifest
  retrieve/
    keyword.py
    vector.py
    rerank.py
  generate/
    prompt.py
    citations.py
    refusal.py
  tools/
    registry.py       # allowlist and schemas
    orders.py         # one narrowly scoped tool
  evaluate/
    runner.py
    metrics.py
evals/
  support_questions.jsonl
tests/
```

The dependency direction matters: ingestion never imports the generator, retrieval never imports the web framework, and tools never import the prompt builder. This keeps each stage independently testable and prevents circular dependencies as the project grows.

## Quality gates

- [ ] Chunking never splits a fenced code block or a table row across chunks.
- [ ] The index manifest records document hashes and the embedding version.
- [ ] Every answer has at least one citation, or a structured refusal reason.
- [ ] Citation markers in the answer are validated against the retrieved evidence numbers.
- [ ] Every tool has a schema, a timeout and a least-privilege scope.
- [ ] The evaluation set includes answerable, unanswerable and tool-required questions.
- [ ] A regression beyond the agreed threshold fails the build.

## Security, cost and observability

- Treat retrieved documents and model output as untrusted input; strip active content before rendering.
- Keep secrets and model credentials in environment variables or a local secret store, never in the index.
- Scope tools to the minimum data they need and log every tool call with the requesting user and argument hash.
- Defend against prompt injection inside documents by separating instructions from evidence and by validating tool arguments outside the model.
- Bound context size, top-k and tool result size so a single request cannot exhaust the budget.
- Track retrieval latency, generation latency, token usage, refusal rate and citation failure rate.
- Record a cost baseline per thousand questions and alert when the average context size grows without a quality gain.

## Tests and acceptance

- A question with clear evidence returns an answer whose citations point to the correct source.
- A question with no relevant chunks returns a structured refusal instead of a fabricated answer.
- A tool call with an out-of-scope parameter is rejected before execution.
- Rebuilding the index over unchanged documents produces stable evaluation results.
- An answer that cites a non-existent evidence number is rejected by the citation validator.
- An injected instruction inside a document does not cause an unauthorized tool call.

### Acceptance record

| Check | Evidence | Result | Notes |
| --- | --- | --- | --- |
| Grounded answer works | Citation and source check | | |
| Refusal works | Structured refusal output | | |
| Tools are controlled | Validation and scope test | | |
| Evaluation is stable | Two-run report | | |

## Common pitfalls

| Problem | Cause | Fix |
| --- | --- | --- |
| Product codes are often missed | Only vector retrieval is used | Add keyword retrieval and rerank the merged candidates |
| The model ignores the middle of the context | Too many documents are stuffed into the prompt | Limit top-k and enforce a context budget |
| The agent answers without evidence | There is no refusal path | Add a score threshold and an empty-result fallback |
| A tool reads sensitive data | The model chooses the tool and the arguments freely | Use an allowlist, a schema and least-privilege scopes |
| A prompt injection inside a document changes behavior | Instructions and evidence are mixed in one block | Separate roles, quote evidence and validate actions outside the model |
| Evaluation results change after every rebuild | Chunking or embedding versions are not recorded | Version the manifest and compare chunk identifiers |

## Extension tasks

- Add OCR for images and table understanding for scanned documents.
- Implement multi-turn query rewriting that keeps the original user intent.
- Wire the evaluation job into CI and block releases on quality regression.
- Add a small web UI that shows the retrieved chunks next to the answer for review.
- Add a feedback endpoint that stores user ratings without storing private question text.

## Performance and failure drills

| Dimension | Baseline | Method | Failure signal |
| --- | --- | --- | --- |
| Retrieval latency | P50/P95 per query | Grow the index by 10x | Latency grows non-linearly |
| Answer quality | Hit rate and citation accuracy | Run the fixed evaluation set | Metric drops after an index or prompt change |
| Cost | Tokens per answered question | Track average context size | Cost rises without a quality gain |
| Failure recovery | Time to rebuild the index | Delete the index and rebuild | Results differ for unchanged documents |

Perform at least one real drill: corrupt or delete part of the index, rebuild it, and compare the evaluation metrics with the recorded baseline. The drill is complete only when the difference is explained.

## Practice exercises

### Exercise 1: Grounded answer (40 minutes)

Implement retrieval with a fixed top-k and a threshold, then produce one answer with citations. Do not add tools yet.

Acceptance: a known question returns the correct source, and an uncovered question returns a refusal.

### Exercise 2: Controlled tool (40 minutes)

Add one read-only tool with a parameter schema and a timeout. Test an invalid argument and a timeout.

Acceptance: both failures are rejected before the tool runs and the error is visible in the trace.

### Exercise 3: Evaluation loop (60 minutes)

Build a ten-question evaluation set with sources and expected refusals. Run it twice and explain every difference.

Acceptance: a committed evaluation report and one concrete fix driven by the report.

## Summary

- Retrieval quality decides answer quality; generation cannot repair missing evidence.
- Citations turn a plausible answer into an auditable one.
- Refusal is a feature, not a failure of the model.
- Tools must be fenced by schemas, scopes and timeouts because the model is not a security boundary.
- Offline evaluation is the only reliable way to notice quality regressions before users do.

## References

- Retrieval-augmented generation overview: https://arxiv.org/abs/2005.11401
- Sentence Transformers documentation: https://www.sbert.net/
- FAISS similarity search library: https://faiss.ai/
- Model Context Protocol specification: https://modelcontextprotocol.io/
- OWASP Top 10 for Large Language Model Applications: https://owasp.org/www-project-top-10-for-large-language-model-applications/
