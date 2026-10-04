# Multi-line and simultaneous.

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- I can explain in my own words what the problem is, not just a term.
- The relationship between "wielding", "synchronized" and "volatile" is clear, with one example.
- It's a way to put the knowledge back into Java, and it tells us how much of this is going on.
- It is possible to complete this course and check its results using acceptance standards.

> Synchronized/volatile/atomic, CompletableFuture and virtual.

## Pre-knowledge

- One lesson, “Lambda and Stream API”, is completed; if available, this course can be used for self-testing.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we start, let's review the threads.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Create Threads

```java
// 方式一：实现 Runnable（推荐，组合优于继承）
Runnable task = () -> System.out.println("运行在 " + Thread.currentThread().getName());
Thread thread = new Thread(task);
thread.start();
thread.join();                 // 等待结束

// 方式二：线程池提交任务
ExecutorService pool = Executors.newFixedThreadPool(4);
Future<Integer> future = pool.submit(() -> 1 + 1);
System.out.println(future.get());
pool.shutdown();
```

## Share Status & Sync

```java
class Counter {
    private int count = 0;

    public synchronized void increase() { count++; }   // 方法级同步

    public int get() { return count; }
}

// 显式锁
private final ReentrantLock lock = new ReentrantLock();
public void increase2() {
    lock.lock();
    try { count++; } finally { lock.unlock(); }
}
```

⟦ Visibility and order, but not atomity**, ⟦1 still needs locking or switching to ⟦2.

```java
private final AtomicInteger atomicCount = new AtomicInteger();
atomicCount.incrementAndGet();
```

## Combining Tool Class

```java
ConcurrentHashMap<String, Integer> cache = new ConcurrentHashMap<>();
cache.computeIfAbsent("key", k -> 1);

CountDownLatch latch = new CountDownLatch(3);
latch.countDown();
latch.await();
```

## Completable Future

```java
CompletableFuture<String> future = CompletableFuture
        .supplyAsync(() -> "结果")
        .thenApply(String::toUpperCase)
        .thenCompose(s -> CompletableFuture.completedFuture(s + "!"))
        .exceptionally(e -> "失败：" + e.getMessage());

System.out.println(future.join());
```

## Java Memory Model Elements

- Each thread has its own working memory, and sharing variables may not see the latest values.
- ⟦0 and ⟦1 create a happens-before relationship to ensure visibility.
- The four conditions of death are the same as those for avoidance (uniform chaining).

## Virtual thread (Java 21+)

```java
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (int i = 0; i < 10_000; i++) {
        executor.submit(() -> {
            Thread.sleep(1000);          // 阻塞不再是问题：虚拟线程自动让出载体线程
            return null;
        });
    }
}
```

The virtual threads are very light, they're good for the IO scene and there is no need to write a complicated hiccup.

## Thread pool parameters and common malfunctions

|Parameters|Meaning|Setup|
| --- | --- | --- |
| corePoolSize |Number of permanent lines|Based on CPU and task type (CPU intensive core, IO more intense)|
| maximumPoolSize |Maximum threads|When there's a line, it makes sense.|
| keepAliveTime |Free threads for survival|AllCoreThreadTimeout|
| workQueue |Task Queue|** You have to use a line, and the borderless queue will cover up until OOM|
| threadFactory |Thread Creation|It's a meaningful line name.|
| rejectedExecutionHandler |Reject Policy|Caller Runspolicy (self-release pressure) or custom downgrade|

** Four rejection strategies**: Abortpolicy (unusual, default), Caleb Runspolicy (a caller's execution, natural back pressure), DiscardPolicy (discussion, careful use) and Discard OldestPolicie (release of the old task).

** Frequent malfunctions and queuing**: 1 line-out leads to a build up of tasks, an explosion in memory; 2 thread pools are filled with slow assignments (unset downstream), as shown by the queue for all requests;3 The sharing of the same pool leads to death locks (father waiting for son, children queuing);Checking: ⟦0, get ActiveCount/getQueue.size to monitor the line state and stack.

## It's the end of this class.
Three things went hand in hand:** visibility (volatile/synchronized), atomity (lock/atomic class) and orderly (happes-before)**.Business code prioritizes the thread pool and CompletableFuture, stand back.

<!-- appendix:v1 -->

## Joint Tool Scanning

|Requirements|Recommended tool|Annotations|
| --- | --- | --- |
|It's simple.| `synchronized` |Syntax:|
|Timeout / Breakable / Fair| `ReentrantLock` |I'll be right back.|
|Read less.| `ReentrantReadWriteLock` |Read it and write each other.|
|Atom Count| `AtomicInteger` / `LongAdder` |It's better if you don't.|
|Thread is clear, Map.| `ConcurrentHashMap` |I'll do it with the twilight.|
|Mission execution| `ThreadPoolExecutor` |Clear core numbers, queues and rejection strategies|
|Time job| `ScheduledExecutorService` |Don't use ⟦0.|
|Result Aggregation| `CompletableFuture` |Combining multiple different tasks|
|Interfacing| `CountDownLatch` / `CyclicBarrier` |It's too much, it's recycled.|
|Limited flow.| `Semaphore` |Controls the number of lines visited simultaneously|

Thread pool parameters:

|Parameters|Meaning|Setup|
| --- | --- | --- |
| `corePoolSize` |Number of links|Based on QPS and single task time|
| `maximumPoolSize` |Maximum threads|CPU intensity ≈ core number; IO density magnified|
| `keepAliveTime` |Free recycling time|Combining flow fluctuations|
| `workQueue` |Task Queue|** There must be boundaries, or there's a spill.|
| `threadFactory` |Thread Name|Naming is easy to check (e. g. ⟦0)|
| `handler` |Reject Policy|Use ⟦0 for back pressure, or downgrade after custom record|

```java
// 手动创建线程池：参数明确，便于定位问题
ExecutorService pool = new ThreadPoolExecutor(
        8, 32, 60L, TimeUnit.SECONDS,
        new ArrayBlockingQueue<>(1000),
        new ThreadFactory() {
            private final AtomicInteger seq = new AtomicInteger();
            @Override
            public Thread newThread(Runnable r) {
                return new Thread(r, "order-pool-" + seq.incrementAndGet());
            }
        },
        new ThreadPoolExecutor.CallerRunsPolicy());
```

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
| `Executors.newFixedThreadPool(...)` |Queued unbound, task buildup OOM|Manually, ⟦0 and specify a line.|
|Zero, multi-line.|The results are small.|Use ⟦0 or lock|
|Make it self-reinforcing.|Still missing updates|It's only visible, not complex atoms.|
|The double-check lock forgot.|Probably got a semi-initialized object.|Single case with static internal class or more semen|
|Zero, lock. 1 constant.|Global disturbance. Very poor performance.|It's a special.|
|There's a lock and it doesn't match the sequence.|Dead lock.|Align the lock order, or use a time-out.|
|It's just a little bit more than that.|Locked off in an anomaly.| `lock(); try { ... } finally { lock.unlock(); }` |
|It's not normal.|It's been swallowed, and there are no marks.|Handle with 0 / 1 , or 2 .|
|The context of the request for a different mission| `NullPointerException` |Context does not pass by thread, which requires explicit reference|
|I forgot to close the pool.|Process cannot exit, thread leak.|Use 0 to call 1+2|
|The local locks in the virtual circuit.|Platform's pinned down.|Virtual threads fit for IO to wait and avoid long periods of zero.|

## Self-Detected List

- [ ] Can you tell the difference between ⟦ and ?
- [ ] Liners always use lined lines and explicit rejection strategies.
- [ ] The locks are in order, or the time-lapse is used to avoid a deadlock.
- [ ] Know the atom semantics of ⟦0.
- [ ] Combine the walker with ⟦0 and handle the abnormal branch.

<!-- appendix:v3 -->

## Zero-basic detail: thread, thread pool and cogeneration tool

### What is it?

The way Java does it is: ** don't give yourself new Thread, but deliver to the pool.**
Share data with protection and transmit the results from one mission to another.

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
|Thread|Office window|Each window runs its own logic.|
|Thread pool|Established service groups|Reuse threads to avoid frequent creation of destruction|
| `synchronized` |Door lock.|At the same time, there's only one person.|
| `volatile` |Publicity Bar|Preserve visibility, but not atomity|
| `AtomicInteger` |A machine with a counter.|It's an atom.|
| `Future` |Take the note.|Take it. We'll get the results later.|
|Virtual Thread|It's a very light job.|JDK 21+, suitable for mass IO waiting|

### From new Thread to thread pool

```java
// 1. 直接创建：不推荐，难以控制数量
new Thread(() -> System.out.println("跑起来了")).start();

// 2. 线程池：推荐
ExecutorService pool = Executors.newFixedThreadPool(4);
try {
    for (int i = 0; i < 10; i++) {
        int taskId = i;
        pool.submit(() -> System.out.println("任务 " + taskId));
    }
} finally {
    pool.shutdown();                       // 不再接收新任务
    pool.awaitTermination(10, TimeUnit.SECONDS);
}
```

|Create with|Apply scene|Attention.|
| --- | --- | --- |
| `newFixedThreadPool(n)` |CPU intensive|Threads are about the core.|
| `newCachedThreadPool()` |A lot of short assignments.|It could be infinity.|
| `newScheduledThreadPool(n)` |Regular and periodic tasks|Replace Timer|
| `newVirtualThreadPerTaskExecutor()` |A lot of IO waiting.|JDK 21+, high|

### Get Return Value: Future and CompletableFuture

```java
ExecutorService pool = Executors.newFixedThreadPool(2);

Future<Integer> future = pool.submit(() -> {
    Thread.sleep(500);
    return 42;
});
Integer value = future.get(2, TimeUnit.SECONDS);   // 阻塞等待结果

// 组合多个异步任务
CompletableFuture<String> a = CompletableFuture.supplyAsync(() -> "A");
CompletableFuture<String> b = CompletableFuture.supplyAsync(() -> "B");
String combined = a.thenCombine(b, (x, y) -> x + y).join();
System.out.println(combined);                       // AB
```

### Three ways to protect shared data

```java
// 1. synchronized：简单可靠
private final Object lock = new Object();
private int count = 0;
void increase() {
    synchronized (lock) { count++; }
}

// 2. 原子类：单变量自增最省事
private final AtomicInteger counter = new AtomicInteger();
void increaseFast() { counter.incrementAndGet(); }

// 3. 显式锁：需要超时或公平策略时用
private final ReentrantLock lock2 = new ReentrantLock();
void doWork() {
    lock2.lock();
    try { /* 临界区 */ } finally { lock2.unlock(); }
}
```

|Tools|Scope of protection|When?|
| --- | --- | --- |
| `volatile` |Visibility of individual variables|Status Marker|
| `AtomicInteger` / `LongAdder` |Atom Operations for Individual Variables|Count, add|
| `synchronized` |A code or method|When multiple variables need to be protected|
| `ReentrantLock` |A code.|It's time-out, cutable and fair.|
| `ConcurrentHashMap` |And read and write maps|Multi-line Cache|

### Commonly.

|Gather.|Features|
| --- | --- |
| `ConcurrentHashMap` |It's a high-quality reading and writing.|
| `CopyOnWriteArrayList` |Read too little, copy it.|
| `BlockingQueue` |Producer consumer queue, natural jamming|
| `ConcurrentLinkedQueue` |Unlocked line, vomiting.|

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Make it self-reinforcing.|The results are small.|Use Zero.|
|New Threads|Memory surges, switching times.|Use the thread pool.|
|I don't remember.|Program does not quit|Zero in.|
|It's in the lock.|All the other threads are held up.|Reduce the critical area.|
|It's not in the same order.|Dead lock.|Unlock|
|Use ⟦0 and write.|The data's out of order and even dead.|Use Zero.|
|Ignoring Zero Spectacular|Mission failed.|Capture and process ⟦0|
|I thought it was going to be faster.|It's a lot slower than that.|It's up to you.|

### Handheld exercise: Counting orders

```java
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.LongAdder;

public class OrderStats {
    public static void main(String[] args) throws Exception {
        List<Integer> orders = new ArrayList<>();
        for (int i = 1; i <= 1000; i++) orders.add(i);

        LongAdder total = new LongAdder();
        ExecutorService pool = Executors.newFixedThreadPool(4);

        List<Callable<Void>> tasks = new ArrayList<>();
        int chunk = 250;
        for (int start = 0; start < orders.size(); start += chunk) {
            int from = start, to = Math.min(start + chunk, orders.size());
            tasks.add(() -> {
                for (int value : orders.subList(from, to)) total.add(value);
                return null;
            });
        }

        try {
            for (Future<Void> f : pool.invokeAll(tasks)) f.get();
        } finally {
            pool.shutdown();
        }
        System.out.println("订单总额：" + total.sum());
    }
}
```

### Learn how to measure yourself.

- [ Laughs ] Can you tell me why the thread pool was recommended instead of just a new Thread?
- [ ] Know the difference between ⟦ and .
- [ ] Can you tell me the difference between ⟦ and ?
- [ Chuckles ] Know what kind of old collection you can replace.
- [ ] The most common cause of death and method of avoidance can be stated.

<!-- scaffold:v1 -->

<!-- exercise-guard:v1 -->

## Let's practice.

### Practice 1: Restatement of Concept (10 mins)

In the course, three or five words are used to explain what's going on between multiple threads and a border condition.

**Acceptance standard: at least one lesson keyword is used and an example given.

### Practice 2: Example rewrite (20 minutes)

Select a minimum example from the text to predict changes in an input before actually verifying and recording differences.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Migration assignment (30 minutes)

Writes a runable subcategory, adds an ordinary test and a border input test.

- It's not like we have to go through it, but I don't know what you mean.
- Output of a result that can be checked by others.
- Write about a problem that is still uncertain and how to verify it.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Concurrency

**Summary:** Threads, pools, synchronization, CompletableFuture, virtual threads.

**Category:** Java  
**Level:** Advanced
**Key terms:** Thread, synchronized, volatile, AtomicInteger, virtual thread

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable context: Java 21+ / Maven or Gradle
- Source: Internal structured curriculum and engineering practices
- Related themes: threads, synchronized, volatile, AtomicInteger
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Concurrency** focuses on Threads, pools, synchronization, CompletableFuture, virtual threads.

### Learning Outcomes

- Explain what **Concurrency** solves and when it should be used.
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

- Topic: **Concurrency**
- Related terms: Thread, synchronized, volatile
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|Create Threads| Create thread |
|Share Status & Sync| Sharing status and synchronization |
|Combining Tool Class| Concurrent Tools Class |
|Completable Future| CompletableFuture Combined Asynchronous Task |
|Java Memory Model Elements| Java Memory Model Essentials |
|Virtual thread (Java 21+)| Virtual Thread (Java 21 +) |
|Thread pool parameters and common malfunctions| Thread Pool Parameters and Common Faults |
|It's the end of this class.| Lesson Summary |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

