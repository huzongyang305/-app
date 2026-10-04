# Processes and Threads

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- I can explain in my own words what the process is and how it's going to be, not just a word.
- It is possible to explain the relationship between process, thread and context.
- It's a system of knowledge that can put back into the "operating systems" and indicate how much it has to do with each other.
- It is possible to complete this course and check its results using acceptance standards.

> Summary of sentence: Distinction between resource allocation and movement control, as well as concurrent security issues.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Read it first: process, thread and parallel.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Process: Unit for resource allocation

Process is an example of a running program with separate virtual address space, file descriptors and signal processing resources.

```text
进程 = 代码段 + 数据段 + 堆 + 栈 + 打开的文件 + 页表 ...
```

## Thread: Unit of CPU Schedule

Threads are execution streams within the process, multiple lines of the same process** share address space and open documents** but each has a separate stack and repository status.

|Contrast|Process|Thread|
| --- | --- | --- |
|Address Space|Independence|Share|
|Create Costs|Large|Small|
|Communication|Pipes, shared memory, message queue|Directly read-write the variable|
|Segregation|Strong.|Weak. A thread crash could slow down the process.|
|Switch Costs|High (toggle table)|Low|

## Context Switch

The core number of CPUs is limited, and the operating system transfers multiple lines from a single time cycle to run simultaneously.

```text
线程 A 运行 -> 时间片用完 -> 保存 A 的上下文
            -> 载入 B 的上下文 -> 线程 B 运行
```

Irresistance will cost more, so the number of threads is not as good.

## Parallel security issues

Many threads change the shared data to create competitive conditions:

```python
import threading

count = 0

def increase():
    global count
    for _ in range(100000):
        count += 1        # 实际是「读-改-写」三步，非原子

threads = [threading.Thread(target=increase) for _ in range(2)]
for t in threads:
    t.start()
for t in threads:
    t.join()

print(count)   # 很可能小于 200000
```

Solutions: Locking, using atoms or avoiding the sharing of variability.

```python
lock = threading.Lock()

def safe_increase():
    global count
    for _ in range(100000):
        with lock:
            count += 1
```

## Steps of re-emergence and death locks

** Experiment I: Contest (lost update)**

1. Each thread increases the global number of variables by 100,000 (reading-reforms-writing three steps non-atom).
2. It's expected to be 200,000, which is usually less than that - the missing update.
3. Repairs: capped in mutually exclusive locks or converted to atom type; 10 times after repair, the result should be stabilized at 200,000.

** Experiment II: Deadlock**

1. Prepare two locks a, b; thread T1 first a, thread T2 first b and then a.
2. Insert short sleep between locks, magnify the chance of a staggered process.
3. (b) Restoration: a single locking order (all set), or a time-lapse lock (excess and release already held locks and try again).

** Validation and observation tools**

|Means|Purpose|
| --- | --- |
|Over and over again.|It's an occasional problem. It takes a lot of time to expose it.|
|Print Thread Stack / Faulthandler|Watch where the thread is when you're locked.|
|Top-H, look at the threads.|Thread growth means no recovery after creation|
|And a single test.|Make sure you don't come back.|

Key cognitions: competition and the death lock** will not be stable, so it must be verified with a combination of high frequency tests instead of one pass.

## It's the end of this class.
** Process segregation of resources, linear sharing of resources. ** Sharing brings ease and problems with synchronization.

<!-- appendix:v1 -->

## Processes and Threads

|Dimensions|Process|Thread|
| --- | --- | --- |
|Definitions|Basic unit for resource allocation|Basic unit for CPU|
|Address Space|We're all alone.|Share with Process|
|Create Costs|Large (including pages and resources)|Small|
|Communication|Conduit, Message Queue, Sharing Memory, Socket|Direct reading and writing sharing variable (sync required)|
|Segregation|One crash doesn't usually affect the other.|Weak, a thread collapses the whole process.|
|Switch Costs|High (page cut, TLB)|Lower|
|Typical uses|Isolation of services, multi-nucleus calculations|IO.|

Thread sharing with private content:

|Share|Private|
| --- | --- |
|Code segments, stacks, global variables, open files|Barn, register, program counter, thread local storage|

## Quick check of common problems

|Problem|Causes|phenomena|Response|
| --- | --- | --- | --- |
|Competition conditions|Multi-lines staggered shared data|It's a random, occasional error.|Locked, atom operations and reduced sharing|
|Dead lock.|It's like a lock on each other.|Lines permanently blocked.|Unlocked, timed out and avoid nesting.|
|Live lock.|Try again, but you can't push it.|CPU High but No Progress|Add random retreat|
|Hunger|Low-priority threads are not scheduled for long periods|Delay in the completion of individual tasks|Fair lock, queue.|
|Hypothetical Sharing|Change Line to Cache Line|Performance is far below expectations.|Data Alignment, Local Threads Plus|

```python
import threading

counter = 0
lock = threading.Lock()

def worker(times: int) -> None:
    global counter
    for _ in range(times):
        with lock:                 # 复合操作必须加锁
            counter += 1

threads = [threading.Thread(target=worker, args=(10_000,)) for _ in range(4)]
for t in threads: t.start()
for t in threads: t.join()
print(counter)                     # 40000
```

## Check your commands.

|Purpose|Command|
| --- | --- |
|View Process and Thread| `ps -eLf \| grep app`、`top -H -p <pid>` |
|View Threshold| `pstack <pid>`、`gdb -p <pid>` + `thread apply all bt` |
|View Java Threads| `jstack <pid>`、`jcmd <pid> Thread.print` |
|Check the locks.|I'm going to get you two.|
|View resource occupancy|Zero, one.|
|View File Threads| `lsof -p <pid>` |

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Processing CPU intensive tasks by thread|It's not accelerating.|GIL Limit, Change to Multi Process|
|Cover the whole function with a lock.|Syndicate into serials|Lock critical areas only|
|The same business with more locks.|I can't believe it.|Uniform or single locks|
|Thread pool core is much larger than nuclei and the task is CPU type|Context Switching Costs|CPU-intensive threads are about the same number.|
|Share variable objects between threads without synchronization|Data damage|Sending with Unmovable Data, Locked or Message|
|Forget it.|Lead exit or statistical error|Wait explicitly for the end of all lines.|
|Replace Synchronization with ⟦0|Test passed but failed on the line.|Use conditional variables, queues or events|
|Job Uncaptured|The line's quiet, the job is lost.|On-line access is centralized and documented|
|Uncleaned before process exit|Zombie Process|Waiting or not, and then one.|

## Self-Detected List

- [ ] It can be said that the process is a resource unit, and the threads are dispatch units.
- [ ] Knowledge of inter-lineal and private memory areas.
- [ ] The lock covers only the critical areas and is in a uniform order.
- [ Laughs ] It's gonna be a hell of a lot more than that.
- [ ] Thread pool size determined by task type (CPU / IO).

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeating, experimenting and delivering around "processes, threads," each result is subject to scrutiny.

Draws the process, thread or resource state before simulating schedule and competition.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Process and Thread?
2. Without it, what concrete consequences would there be?
3. What's it got to do with the thread?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Simulate the movement, competition or allocation of resources with a false code or small script and record at least 5 changes in status.

Mission requests:

- The result must be checked, not just “I understand”.
- It's not like we have a lot of work to do with it.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Process & Thread

**Summary:** Resource ownership vs scheduling, and race conditions.

**Category:** Operating Systems  
**Level:** Progress
**Key terms:** Process, Threading, Combination, Context Switch, Lock, Competition

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable environment: Linux 6.x / POSIX
- Source: Internal structured curriculum and engineering practices
- Related themes: process, threading, synopsis, context switching, locks, competition
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- top50-rewrite:v1 -->

## Course-specific fine reading: process and thread

### I. KNOWLEDGE

- ** Process: Unit for resource allocation**: Process is an example of a running process with separate virtual address space, file description and signal processing resources. Processes are isolated from each other and the collapse of one process usually does not affect others.
- ** Thread: CPU Scheduler**: Line is an execution stream within the process, multiple threads of the same process** share address space and open documents** but each has a separate stack and repository status.
- ** Context switch**: CPU core is limited, and the operating system transfers multiple threads "both" over time.
- ** Complementary security issues**: multiple linear modifications of shared data create competitive conditions:
- ** Steps to repeat the race and death lock** ** Experiment I: competition (lost updates)**
- ** Process and speed check: understand its definition, input, output and failure borders.
- ** Common simultaneous problem survey**: understanding of its definition, input, output and failed borders.
- **Search command quick check**: understand its definition, input, output and failed borders.

### II. MECHANISMS AND VERIFICATION

|Theme|Questions to answer|Authentication Method|
| --- | --- | --- |
|Process: Unit for resource allocation|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Thread: Unit of CPU Schedule|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Context Switch|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Parallel security issues|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Steps of re-emergence and death locks|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Processes and Threads|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Quick check of common problems|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Check your commands.|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|

### III. EXCHANGE ISSUES

1. Process: What is the boundary between resource allocation and adjacent themes?
2. Thread: What is the border between CPU and the adjacent subject?
3. What's the border with an adjacent subject?
4. What's the border between security and adjacent themes?
5. What's the line between a race and a death lock?
6. What's the boundary between process and thread?
7. What's the border between a common problem and an adjacent subject?
8. What's the border with the adjacent subject?

### IV. FUNCTIONS CLASSING

1. Fixed input and environment, confirming problem recurrence.
2. Find the first anomaly, don't guess from the end.
3. Only one variable is changed, and projections and real results are recorded.
4. Rehabilitate borders, fail and repeat tests.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Process & Thread** focuses on Resource ownership vs scheduling, and race conditions.

### Learning Outcomes

- Explain what **Process & Thread** solves and when it should be used.
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

- Topic: **Process & Thread**
- Related terms: Process, Threading, Combination, Context Switch
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Process: Unit for resource allocation|Process: Unit for resource allocation|
|Thread: Unit of CPU Schedule|Thread: Unit of CPU Schedule|
|Context Switch|Context Switch|
|Parallel security issues|Question of Concurency|
|Steps of re-emergence and death locks|Steps of re-emergence and death locks|
|It's the end of this class.| Summary |
|Processes and Threads|Processes and Threads|
|Quick check of common problems|It's a regular Concurrecy problem.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

