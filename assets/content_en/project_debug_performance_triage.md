# Project: Debug and Profile a Slow API

![Project: Debug and Profile a Slow API](images/remaining_project_debug_performance_triage.webp)

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.

> Content update time: 2026-10-03 | Level: Advanced | Estimated time: 110 minutes

## Learning objectives

- Turn a vague report such as "the API is slow" into a reproducible latency measurement.
- Use logs and traces to separate queue time, database time, external-call time and serialization time.
- Write a falsifiable hypothesis before changing code, then run a single-variable experiment.
- Prove an optimization with a before/after benchmark and a regression gate that keeps it honest.

> One-sentence summary: use logs, traces, profilers and load tests to locate a real API bottleneck, establish a baseline first, and prove the improvement with reproducible regression data.

## Prerequisites

- You can read a latency percentile and explain why the average hides the tail.
- You have used structured logging and can add a request identifier.
- You know the difference between CPU time and wall-clock waiting time.
- You can run a benchmark against a fixed data set.
- You understand that a cache changes both performance and consistency behavior.

## Project scenario

The order query endpoint has a normal average latency, but P95 keeps rising and some requests take more than three seconds. The team already tried adding worker threads and a cache without improvement. Your job is to move from symptom to evidence to hypothesis to experiment, find the root cause, and submit a reproducible before/after comparison.

The scenario is intentionally adversarial: the obvious fixes are already attempted and they did not help. That is a hint that the bottleneck is not raw CPU capacity. The disciplined path is to measure the phases of the request and find where the time actually goes.

## Architecture and data flow

```text
client -> load balancer -> worker queue -> request handler
                                             |
                       +---------------------+---------------------+
                       |                     |                     |
                  database               external API        serialization
                       |                     |                     |
                       +-------- stage timings + request id -------+
                                             |
                                        metrics / traces
```

- Every request gets a trace identifier at the edge and passes it to logs, database comments and outbound calls.
- Each phase records a duration in milliseconds so the total can be decomposed rather than guessed.
- A slow-request sampler keeps the full trace of the worst 1 percent of requests instead of logging everything.
- The load generator uses a fixed dataset, a fixed concurrency and a warm-up period so runs are comparable.
- The benchmark report records P50, P95, P99, error rate and throughput together; one number alone is not evidence.

## Scope and features

- [ ] Add request-level structured logs with a trace identifier.
- [ ] Record phase timings for queue, database, external call and serialization.
- [ ] Sample slow requests and store the full timing breakdown.
- [ ] Build a repeatable load test with a fixed dataset and concurrency ramp.
- [ ] Change one variable per experiment and keep a short experiment log.
- [ ] Produce a before/after report with P50/P95/P99 and error rate.
- [ ] Keep a regression benchmark in CI with an agreed budget.

## Implementation steps

### Step 1: Define the service-level objective and a reproducible baseline

Write down the target, for example "P95 under 300 ms and error rate under 0.5 percent at 50 concurrent users on the standard dataset". Record the machine, commit, dataset version and warm-up procedure. Without a fixed context, two benchmark numbers cannot be compared.

Evidence: a baseline report with raw output, the exact command and the environment description.

### Step 2: Add tracing fields to requests, queries and external calls

Generate a request identifier at the edge, attach it to the logging context and propagate it to the database and external calls. Log the phase name, duration and outcome category. Never log full payloads or personal data.

Evidence: one slow request whose trace shows a single clearly dominant phase.

### Step 3: Profile CPU and waiting time separately

Use `cProfile` for CPU-heavy code and a sampling profiler such as `py-spy` for production-like runs. Remember that a profiler shows where CPU time goes, not why a request waits on a lock or a socket. Combine the profile with the phase timings from step 2.

Evidence: a flame graph or a cumulative profile plus the matching phase timing table.

### Step 4: Test hypotheses in a fixed order

Test the most likely causes one at a time: a missing index or an N+1 query, blocking I/O inside the request path, repeated serialization, connection-pool exhaustion, lock contention, and only then caching. Each experiment needs a prediction: "if the N+1 query is the cause, database time will drop after batching and P95 will fall accordingly".

Evidence: an experiment log with one row per hypothesis, the change, the observed metrics and the decision.

### Step 5: Apply the smallest fix and repeat the same benchmark

Do not bundle three optimizations into one commit. Apply the change that the evidence supports, rerun the identical benchmark and compare the full metric set. If the improvement does not appear, revert the change instead of keeping it "just in case".

Evidence: before/after output produced by the same script on the same dataset.

### Step 6: Keep the regression test and the rollback plan

Convert the fixed benchmark into a CI check with a generous budget, and keep the correctness tests that protect the optimized path. Write down how to roll back the change and which signal would trigger a rollback.

Evidence: a CI run that fails when the budget is exceeded and a rollback note in the pull request.

## Key code

The helper below keeps phase measurement explicit and cheap. It does not replace a profiler; it answers the first question of every investigation: which phase is consuming the wall-clock time?

```python
import cProfile
import pstats
import time
from contextlib import contextmanager

@contextmanager
def stage(name: str, timings: dict[str, float]):
    started = time.perf_counter()
    try:
        yield
    finally:
        timings[name] = (time.perf_counter() - started) * 1000

with cProfile.Profile() as profiler:
    timings: dict[str, float] = {}
    with stage('database', timings):
        rows = repository.query_orders(order_ids)
    with stage('external', timings):
        enrich_with_shipping(rows)
    with stage('serialize', timings):
        payload = serializer.dump(rows)

pstats.Stats(profiler).sort_stats('cumulative').print_stats(20)
print({key: round(value, 2) for key, value in timings.items()})
```

```python
# A benchmark must be boring and repeatable to be useful.
def run_load_test(client, dataset, concurrency, duration_seconds):
    metrics = LatencyRecorder()
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        deadline = time.monotonic() + duration_seconds
        futures = [
            pool.submit(worker, client, dataset, metrics, deadline)
            for _ in range(concurrency)
        ]
        for future in futures:
            future.result()
    return metrics.report()  # p50, p95, p99, error_rate, throughput
```

Keep the load generator independent from the service under test. If both share a process, the generator's own CPU and memory usage contaminate the measurement.

## Verification commands and expected output

```bash
python bench/seed_dataset.py --rows 100000 --out /tmp/orders.db
python bench/run_load.py --concurrency 50 --duration 60 --out before.json
python -m pytest -q tests/test_orders.py
python bench/run_load.py --concurrency 50 --duration 60 --out after.json
python bench/compare.py before.json after.json
```

Expected evidence: the baseline report includes P50, P95, P99, error rate and throughput; the trace of a slow request shows which phase dominates; the correctness tests pass; the comparison shows the improvement and its confidence interval. A change that improves the average but worsens P99 must be treated as a regression for a tail-sensitive service.

## Suggested directory structure

```text
app/
  api/
  domain/
  repository/        # queries and indexes
  telemetry/
    logging.py       # request-scoped structured logs
    timings.py       # stage recorder
bench/
  seed_dataset.py
  run_load.py
  compare.py
tests/
  test_orders.py
  test_performance_budget.py
docs/
  experiments.md     # one row per hypothesis and result
```

The experiment log is part of the deliverable. It shows reviewers not only the final change but also the reasoning that rejected alternative explanations.

## Quality gates

- [ ] Each benchmark run records the dataset version, concurrency, warm-up and commit.
- [ ] P50, P95, P99, error rate and throughput are reported together.
- [ ] A slow-request trace can be traced back to the responsible phase.
- [ ] Only one variable changes per experiment.
- [ ] The optimization keeps all correctness tests green.
- [ ] A performance budget runs in CI with an explicit tolerance.
- [ ] A rollback path is written down before the change is deployed.

## Security, cost and observability

- Never log full payloads, tokens or personal data when adding request tracing.
- Keep benchmark data synthetic or anonymized and store it outside the repository.
- Protect the profiling endpoint or keep sampling local; a public profiler can leak internals.
- Track latency, error rate, throughput, queue depth and resource saturation together.
- Cap concurrency and request duration in the load test so a runaway script cannot take down a shared environment.
- Record the cost of every optimization: extra cache memory, added index storage or duplicated data.

## Tests and acceptance

- The fixed dataset produces a repeatable baseline with P95 and P99 inside the expected variance.
- Injecting database latency moves the dominant phase to `database` in the trace.
- The correctness suite returns the same results before and after the optimization.
- A deliberately introduced regression fails the CI performance budget.
- The before/after report explains the cause, the change, the measured effect and the remaining risk.

### Acceptance record

| Check | Evidence | Result | Notes |
| --- | --- | --- | --- |
| Baseline is reproducible | Two runs with close percentiles | | |
| Trace locates the phase | Slow-request trace | | |
| Fix improves the tail | Before/after comparison | | |
| Correctness is preserved | Full test suite output | | |

## Common pitfalls

| Problem | Cause | Fix |
| --- | --- | --- |
| A cache hides the root cause | The fix was chosen before measuring | Measure phases first, then decide whether caching is appropriate |
| The average looks fine while users complain | Only the mean is monitored | Track P95/P99 and error rate |
| Three changes land together | The experiment was not controlled | Change one variable per run |
| The optimization breaks correctness | No regression tests were kept | Keep contract tests and run the benchmark on the same dataset |
| Benchmarks cannot be compared | Dataset, concurrency or machine differs | Record the environment and use the same script |

## Extension tasks

- Add distributed tracing and a flame graph for the worst requests.
- Replay anonymized production traffic to reproduce the long tail.
- Put a performance budget into the release gate with an agreed tolerance.
- Add a queue-depth metric that explains backpressure before latency rises.
- Compare two candidate fixes in one experiment log and document why the rejected one was not chosen.

## Performance and failure drills

| Dimension | Baseline | Method | Failure signal |
| --- | --- | --- | --- |
| Latency | P50/P95/P99 at fixed concurrency | Increase concurrency in steps | P99 rises faster than throughput |
| Throughput | Requests per second | Hold at the target load | Queue depth grows |
| Errors | Error rate by status class | Inject a slow dependency | Timeouts and 5xx increase |
| Recovery | Time back to baseline | Remove the injected fault | Metrics stay degraded after the fault ends |

Perform one real drill: inject 500 ms of database latency, confirm that the trace points to the database phase, then remove the injection and confirm that the metrics recover. Write down how long recovery took.

## Practice exercises

### Exercise 1: Baseline (30 minutes)

Build a fixed dataset and record a baseline with P50, P95, P99, error rate and throughput.

Acceptance: a second run on the same machine stays within an agreed variance.

### Exercise 2: Find the phase (40 minutes)

Add stage timings and find the dominant phase for the slowest requests. Do not change the implementation yet.

Acceptance: a trace that identifies the phase with numbers, not intuition.

### Exercise 3: Fix and prove (60 minutes)

Choose one supported hypothesis, apply the smallest change, rerun the identical benchmark and compare the full metric set.

Acceptance: a before/after report and a CI budget that blocks the regression from returning.

## Summary

- Measurements come before opinions; a baseline is the first deliverable.
- Percentiles and phase timings turn a vague symptom into a specific, testable claim.
- A profiler answers where CPU time goes, while traces answer where wall-clock time goes.
- One variable per experiment is what makes attribution possible.
- An optimization is complete only when correctness is preserved, the tail improves and a regression gate is in place.

## References

- Python profiling documentation: https://docs.python.org/3/library/profile.html
- py-spy sampling profiler: https://github.com/benfred/py-spy
- OpenTelemetry Python documentation: https://opentelemetry.io/docs/languages/python/
- Latency percentile guidance: https://research.google/pubs/pub40801/
- pytest-benchmark documentation: https://pytest-benchmark.readthedocs.io/
