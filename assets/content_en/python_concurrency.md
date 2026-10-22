# ♪ Side by side ♪

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- I can explain in my own words what the problem is, not just a word.
- The relationship between "co-op", "GIL" and "threading" is clear, with one example.
- It's a way to put this subject back into the "Python" system of knowledge, and it shows how much it has to do with each other.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: GIL, multi-routing, multiple processes and asyncio.

## Pre-knowledge

- The first lesson is " Type Notes and Tests " ; if available, this course can be used for self-testing.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Read it first: co-opt, parallel, GIL.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## GIL: Python.

CPython has a global interpreter (GIL) with only one linear byte code at the same time.

- ** CPU intensive** tasks cannot be speeded up and should be multi-processed.
- **IO intensive** missions release GIL while waiting, and speed can be significantly increased by multiple steps.

## Multi-linking

```python
import threading
import time

def download(name):
    time.sleep(1)              # 模拟网络等待
    print(f"{name} 下载完成")

threads = [threading.Thread(target=download, args=(f"文件{i}",)) for i in range(3)]
for t in threads:
    t.start()
for t in threads:
    t.join()                   # 等待全部结束
```

Share data by locking:

```python
lock = threading.Lock()
count = 0

def increase():
    global count
    for _ in range(100000):
        with lock:
            count += 1
```

## Multiprocessing

```python
from concurrent.futures import ProcessPoolExecutor

def cpu_heavy(n):
    return sum(i * i for i in range(n))

if __name__ == "__main__":
    with ProcessPoolExecutor() as pool:
        results = list(pool.map(cpu_heavy, [10**6, 10**6, 10**6]))
    print(results)
```

Thread well, replace ⟦0 with 1 and it's perfect for the IO scene.

## ♪ Asyncio ♪

Step is a one-way cycle of event collaboration: when you're in contact with Zero, it gives way to control and allows for high parallel network requests.

```python
import asyncio

async def fetch(name):
    await asyncio.sleep(1)         # 模拟网络请求
    return f"{name} 完成"

async def main():
    results = await asyncio.gather(
        fetch("A"), fetch("B"), fetch("C")
    )
    print(results)                 # 三个任务并发，总耗时约 1 秒

asyncio.run(main())
```

Note: ** Aniso function cannot be used to block calls** (e.g. ⟦, sync entries), otherwise the entire event cycle should be blocked and replaced by a walk library such as ⟦1 or 2.

## How?

|Scenes|Recommended programme|
| --- | --- |
|A large number of networks/ files|Zero or linear pool.|
|Small simultaneous, simple code.| `threading` |
|CPU intensive calculations| `multiprocessing` |
|Need for inter-process communication| `multiprocessing.Queue` / `Pipe` |

## It's the end of this class.
Remember one sentence: **IO calculates multi-processes using an arcade or thread; the scrambling code is most afraid of jamming.

<!-- appendix:v1 -->

## Quick check.

|Scenes|Recommended programme|Rationale|Key|
| --- | --- | --- | --- |
|A large number of networks/ files| `asyncio` |One-way event cycle, minimum cost| `async def`、`await`、`asyncio.gather` |
|Syndication, Synchronization| `ThreadPoolExecutor` |Waiting for IO to release GIL| `executor.map`、`submit` |
|CPU intensive calculations| `ProcessPoolExecutor` |Get out of the way, Gil.| `ProcessPoolExecutor`、`multiprocessing` |
|Multiple Threads to Share Status|Thread + Lock|Quantified atoms| `threading.Lock`、`RLock` |
|Production consumption model| `queue.Queue` |It's natural.| `put`、`get`、`task_done` |
|Timed / delayed|⟦ or dispatch library|Do not block the thread.|We're not going to make it.|

GIL Quick check:

|Problem|Conclusions|
| --- | --- |
|What's that?|CPython-level mutually exclusive locks to ensure only a linear byte code at the same time|
|The CPU. Is it intense?|Impact. Multiple threads are difficult to speed, and multiprocesses should be used|
|Impact, IO?|The impact is small, and the IO will release the GIL.|
|Do you still need to lock the multiple?|It's not atom-like.|
|Will it be removed in the future?|There are no selected GILs, but eco-compatibility continues.|

```python
import asyncio

async def fetch(name, delay):
    await asyncio.sleep(delay)      # 模拟网络等待，注意不是 time.sleep
    return f"{name} 完成"

async def main():
    # 并发执行，总耗时约等于最慢的那个（0.3 秒）
    results = await asyncio.gather(fetch("a", 0.3), fetch("b", 0.1))
    print(results)

asyncio.run(main())
```

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Call Zero in the concert.|The whole thing's stuck.|Change 0;synthetic blocking library 1⟧|
|It's in the middle of a process.|All other tasks are waiting.|Use ⟦0/ 1 for a different client|
|I forgot. It's a negotiation.| `RuntimeWarning: coroutine was never awaited` |The co-ordination function must be zero or one.|
|Multi-wire sharing arrays directly|The results are small.|Lock or use ⟦0 for aggregation|
|Run with multiple threads, CPU.|It didn't even go up.|Multi-process or original extension|
|Zero, unsequenced objects.| `PicklingError` |Passing simple data or serializing objects|
|Unlimited Create Thread / Concord|There's a huge increase in memory, and there's an enormous cost of movement.|Use the thread pool to limit transmission (`asyncio.Semaphore`)|
|I forgot to close the pool.|Process cannot exit|Zero or visible 1|
|Multi-process direct global variable|Father process doesn't change.|Process memory independent, return value or share memory / queue|
|Call with ⟦0| `RuntimeError: asyncio.run() cannot be called from a running event loop` |The top floor is called only once.|

## Self-Detected List

- [ ] Can correctly select asyncio, multiple threads and multi-processes by `IO/ CPU intensity'.
- [ Laughs ] Knows when Gil will release, and why sharing counts should be locked.
- [ ] There will be no blockages in the coordination process.
- [ ] Limiting the size of a signal or linear pool.
- [ ] and waits for multiple courses, not one by one.

<!-- appendix:v3 -->

## Zero basic details: GIL, threads, process and asyncio

### What is it?

Python has GIL, so ** multi-wire cannot run a CPU intensive mission in parallel, but it's perfect for IO to wait;
If you want a real parallel, it's multiple processes; if you want to deal with thousands of network connections, use asyncio.

### It's a life metaphor.

|Programme|A metaphor.|It fits.|
| --- | --- | --- |
|Multi-line|One cashier, one person.|IO Waiting (download, read and write)|
|Multiple Processes|How many stores?|CPU intensity (calculation, image processing)|
| asyncio |One waiter at the same time.|High-symmetric requests|
| GIL |Just a microphone.|Allows only one byte at the same time|

### Decision sheet: IO or CPU

|Task Type|Preferred|Example:|
| --- | --- | --- |
|IO, intensive. Not many jobs.| `ThreadPoolExecutor` |Download files, read and write disks|
|IO, it's a lot of work.| `asyncio` |Ten thousand HTTP requests|
|CPU intensity| `ProcessPoolExecutor` |Numerical, image-processing|
|Simple Parallel Cycle| `concurrent.futures` |Batch processing|

### A comparison of the three forms.

```python
# 1. 多线程：适合 IO
from concurrent.futures import ThreadPoolExecutor

def download(url: str) -> int:
    ...                       # 假设这里是网络请求
    return len(url)

with ThreadPoolExecutor(max_workers=8) as pool:
    sizes = list(pool.map(download, urls))

# 2. 多进程：适合 CPU
from concurrent.futures import ProcessPoolExecutor

def heavy(n: int) -> int:
    return sum(i * i for i in range(n))

with ProcessPoolExecutor() as pool:
    results = list(pool.map(heavy, [10**6, 10**6, 10**6]))

# 3. asyncio：适合高并发 IO
import asyncio
import httpx

async def fetch(client: httpx.AsyncClient, url: str) -> int:
    resp = await client.get(url)
    return resp.status_code

async def main() -> None:
    async with httpx.AsyncClient() as client:
        tasks = [fetch(client, url) for url in urls]
        statuses = await asyncio.gather(*tasks)
    print(statuses)

asyncio.run(main())
```

### Locking: sharing data is required

```python
import threading

counter = 0
lock = threading.Lock()

def increase() -> None:
    global counter
    for _ in range(1000):
        with lock:                 # 只有这一小段需要保护
            counter += 1
```

There is no sharing of memory between multiple processes, so** the process does not need to be locked but serialized data are needed.**

### Three rules for asyncio.

1. ** Do not block call in the co-operation.** (⟦,), it's stuck throughout the cycle of events.
2. It's a walk-in.
3. The CPU's intensive work is thrown to the ⟦ or process pool.

```python
import asyncio

async def main() -> None:
    await asyncio.sleep(1)                 # 正确：异步睡眠
    # time.sleep(1)                        # 错误：会阻塞整个事件循环
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Multi-wire CPU intensity|It's slower than a single line.|Change Process|
|We'll block it in the co-ordination.|And it's all in a series.|A walk-in or a thready pool.|
|I forgot to lock it up.|Count results are small|Share Variables with Lock or Atom Scheme|
|Pass it through the process.|Unsequenced. Wrong.|Use a module level function|
|There's been an unusual swallowing of the thread.|Mission silently failed.|Collecting ⟦0|
|Unlimited Create Threads|Memory surge|Use a thread pool to control the number.|
|I don't remember.|It's not done.|Use Zero.|
|Use ⟦0 in Jupyter|Clock of events|Use ⟦0 or nest_asyncio|

### Hands practice: grab and count

```python
import asyncio
import time

import httpx


async def fetch(client: httpx.AsyncClient, url: str) -> tuple[str, int | str]:
    try:
        resp = await client.get(url, timeout=5)
        return url, resp.status_code
    except httpx.HTTPError as exc:
        return url, f"失败：{exc.__class__.__name__}"


async def main(urls: list[str]) -> None:
    start = time.perf_counter()
    async with httpx.AsyncClient() as client:
        results = await asyncio.gather(*(fetch(client, u) for u in urls))
    for url, status in results:
        print(f"{status}  {url}")
    print(f"耗时 {time.perf_counter() - start:.2f} 秒")


if __name__ == "__main__":
    asyncio.run(main(["https://example.com"] * 5))
```

### Learn how to measure yourself.

- [ ] Can explain the impact of GIL in one sentence.
- [ ] Can judge whether IO is dense or CPU, and choose a pair of options.
- [ Chuckles ] Know why you can't block the call.
- [ ] Know the difference between multiple processes and multi-wire sharing.
- [ Chuckles ] Can you tell me why the limit is set?

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeat, experiment and deliver around "System, Parallel, GIL", with each result subject to scrutiny.

Write runable scripts, then use type notes and test to protect core functions, and finally process real inputs.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem?
2. Without it, what concrete consequences would there be?
3. What's it got to do with "parallel"?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a small script within 20 lines to use this lesson concept for processing real text or list data.

Mission requests:

- The result must be checked, not just “I understand”.
- This post is part of our special coverage Syria Protests 2011.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Concurrency & Async

**Summary:** GIL, threading, multiprocessing and asyncio.

**Category:** Python  
**Level:** Advanced
**Key terms:** Parallel, GIL, launching, asyncio,

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable environment: Python 3.12+
- Source: Internal structured curriculum and engineering practices
- Related themes: simultaneous, parallel, GIL, making, asyncio, multi-process
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Concurrency & Async** focuses on GIL, threading, multiprocessing and asyncio.

### Learning Outcomes

- Explain what **Concurrency & Async** solves and when it should be used.
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

- Topic: **Concurrency & Async**
- Related terms: Parallel, GIL,
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|GIL: Python.|GIL: Key premise for Python Concurrence|
|Multi-linking|Multi-linking|
|Multiprocessing|Multiprocessing|
|♪ Asyncio ♪| Async asyncio |
|How?|How?|
|It's the end of this class.| Summary |
|Quick check.|Concurrence Project Scanning|
|Common Error Table|Common mirrors|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

