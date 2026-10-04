# Distance programming

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- We can explain what we're dealing with in our own words, not just the term.
- The relationship between Promise, Async, Wait and Incident Cycle is clear.
- It's a way to put back the knowledge of JavaScript, which is how it works with each other.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: echo, Promise, async/await, event cycle and fech.

## Pre-knowledge

- First, the first lesson " Numericals and common methods " ; if available, this course can be used for self-measurement.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Before we begin: Promise, async, await.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## From Return

```javascript
// 回调：多层嵌套会形成「回调地狱」
setTimeout(() => {
  console.log('1 秒后执行');
}, 1000);

// Promise：三种状态 pending → fulfilled / rejected
const task = new Promise((resolve, reject) => {
  const ok = true;
  ok ? resolve('成功') : reject(new Error('失败'));
});

task
  .then(value => console.log(value))
  .catch(error => console.error(error))
  .finally(() => console.log('结束'));
```

Parallel & Serial:

```javascript
Promise.all([fetchA(), fetchB()]);        // 全部成功才成功，最快但要等最慢的
Promise.allSettled([fetchA(), fetchB()]); // 不因单个失败而中断
Promise.race([fetchA(), timeout()]);      // 竞速，取最先完成的
```

## async / await

```javascript
async function loadUser(id) {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const user = await response.json();
    return user;
  } catch (error) {
    console.error('加载失败', error);
    throw error;                 // 交给调用方处理
  }
}

const [a, b] = await Promise.all([loadUser(1), loadUser(2)]);   // 并发请求
```

The ⟦0 function always returns Promise; `await` can only be used at the top of the async function or module.

## Event Cycle

```text
调用栈 → 微任务队列（Promise.then、queueMicrotask）→ 宏任务队列（setTimeout、事件、IO）
```

Each cycle of events** clears all microtasks** and executes the next macro, so the output order below is 1 #3 #2:

```javascript
console.log(1);
setTimeout(() => console.log(2), 0);
Promise.resolve().then(() => console.log(3));
```

## Fetch.

```javascript
const response = await fetch('/api/items', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'book' }),
});
const data = await response.json();
```

⟦Reject,**4x5/xx only in case of a network error.

## Combination and common traps

|Requirements| API |Attention.|
| --- | --- | --- |
|It's all going to work.| Promise.all |Either failure is immediately subject and the remaining tasks will be performed (with self-cancellation)|
|Get all the results.| Promise.allSettled |Returns [{status, value/reason}] for mass tasks|
|Quickest finish| Promise.race |Often used for timeout control|
|First success| Promise.any |Failed Project|

** The correct version of overtime control**: transfer to the setch with AbortController, not just a timer -- the latter does not really cancel requests and the service continues.

** Constricted flow**: 1,000 requests at one time blow up the connector pool and target service, either in batch (5-10 per batch) or combined with a signal;The Node end also needs to note the default number of connections and file description caps.

Five high-frequency traps: 1 in cycle ⟦ leading to a series (first collection of Promise and second round);2 Forgets that ⟦3 makes the error unhandrejection; 3 uses await (forEach without waiting) in 4;4 The CPU intensive tasks are mixed in the cycle of events; 5 setstate (React) produces warnings and competitions after components have been offloaded.

## It's the end of this class.
A three-step set: **Promise expression, async/await is written in sync and event cycle determines the order of execution.

<!-- appendix:v1 -->

## Promise Quick Check

|Methodology|When?|Failures|Return value|
| --- | --- | --- | --- |
| `Promise.all(list)` |All of them.|Either failed immediately|Result arrays, sequence consistent with input|
| `Promise.allSettled(list)` |Allow Partial Failure|Never|Zero arrays|
| `Promise.race(list)` |Take the fastest one.|The quickest result is success.|Single result|
| `Promise.any(list)` |Take the quickest successful result.|Failed All|Single successful value|
| `await Promise.resolve(x)` |Package Synchronization Values as|It won't fail.| `x` |

## Async / Wait

|Writing|Meaning|
| --- | --- |
| `async function f() {}` |Return value as Promise|
| `await p` |Waiting for Promise to drop the anomaly|
| `try { await p } catch (e) {}` |Standard writing for scrambling|
| `for await (const x of stream)` |Individually consuming an iterative object|
| `await Promise.all([...])` |It's a lot faster than one-on-one.|
| `arr.map(async (x) => ...)` |Getting Promise, remember?|
|Zero and one.|You need to use the first one when you're wrong.|

```js
// 并发请求：3 个请求同时发出，总耗时接近最慢的那个
const [user, orders, coupons] = await Promise.all([
  fetchUser(id),
  fetchOrders(id),
  fetchCoupons(id),
]);

// 允许部分失败：拿到每个任务的成败明细
const results = await Promise.allSettled([fetchA(), fetchB()]);
const okCount = results.filter((r) => r.status === "fulfilled").length;
```

## Common Error Table

|It's easy to write the wrong way.|Actual|Reasons and correct practices|
| --- | --- | --- |
| `items.forEach(async (i) => { await save(i) })` |No wait on the outside. It's over.|⟦0 Ignore return value; to 1⟧+2 or 3|
|No, I don't.|Request failed to be captured|It's got to be zero, or it's Promise.|
|We're going back to 404.|I'm not going in.|HTTP error does not trigger project, check ⟦0|
|One by one in the cycle.|Serial execution, plus time|When without dependence, use ⟦0 intermix.|
|It's written on the back of one.|Get Promise arrays instead of results|First of all, collect the Promise and then one.|
|Forgetd.|Browser|Plus 0, 1 or everything.|
|I'd like to have DOM update first.|It's not in order.|Micromission before macro (timer)|
|It's a normal value.|It's not a mistake, it'll be one floor.|You can write the sync, but you have to be readable.|

## Self-Detected List

- [ ] Can you tell us the difference between 12 and 3
- [ ] Knows that the ⟦0 function must return Promise.
- [ ] Remember that ⟦ is only about to be judged when the network fails, HTTP 4x5/xx.
- [ ] Can be used to convert the serial request into a simultaneous request.
- [ ] Know that micromissions take precedence over macro missions (⟦).

<!-- appendix:v3 -->

## Zero base details: cycle of events, Promise and async/await

### What is it?

JavaScript has only one main route, so time-consuming can't wait.
The essence of the step is: **Register a callback and then come back for execution.** Incident cycle is responsible for dispatching these calls.

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
|Main|There's only one window at the counter.|There's only one thing to do at a time.|
|Steppin' on the job.|Go ahead and wait.|I don't have a window.|
|Event Cycle|Call the system.|When the window is empty, call me next.|
|Micromissions|VIP Queue|Promise echoes ahead of macros|
|Macro tasks|Normal queue|SetTimeout, echo.|

** Key conclusion: ⟦ will not be carried out immediately, after all the microtasks.

### A code to see the order of execution

```javascript
console.log("1 同步");
setTimeout(() => console.log("4 宏任务"), 0);
Promise.resolve().then(() => console.log("3 微任务"));
console.log("2 同步");
// 输出顺序：1 同步 → 2 同步 → 3 微任务 → 4 宏任务
```

Rule: **Sync code clears the microtask line takes a macro job and emptys the subtask loop.**

### From hell to async/await

```javascript
// 1. 回调：嵌套深、错误处理分散
getUser(id, (err, user) => {
  if (err) return handle(err);
  getOrders(user.id, (err2, orders) => {
    if (err2) return handle(err2);
    console.log(orders);
  });
});

// 2. Promise 链：能扁平化，但仍要写 then
getUser(id)
  .then((user) => getOrders(user.id))
  .then((orders) => console.log(orders))
  .catch(handle);

// 3. async/await：像同步代码一样，推荐
async function show() {
  try {
    const user = await getUser(id);
    const orders = await getOrders(user.id);
    console.log(orders);
  } catch (error) {
    handle(error);
  }
}
```

### Three states and four methods for Promise

|Status|Meaning|Can you change?|
| --- | --- | --- |
| pending |Ongoing| —— |
| fulfilled |Success|It's not gonna change.|
| rejected |Failed|It's not gonna change.|

|Methodology|Role|When?|
| --- | --- | --- |
| `Promise.all` |It's all going to work. Any failure is a failure.|It's all going to happen, and I can't.|
| `Promise.allSettled` |When it's all over, no matter how successful.|I'm trying to get every one of them.|
| `Promise.race` |It's the first thing to say.|Timeout Control|
| `Promise.any` |It's the first one.|Multiple mirrors, any one of them.|

```javascript
// 并发请求：别用循环里 await，那样是串行
const users = await Promise.all(ids.map((id) => fetchUser(id)));

// 超时控制
const result = await Promise.race([
  fetchData(),
  new Promise((_, reject) => setTimeout(() => reject(new Error("超时")), 3000)),
]);
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Forget it.|Get Promise Object instead of Data|In the ⟦0 function|
|One by one in the cycle.|Time is the sum of tasks.|Use Zero.|
|I'm gonna use one of those.|Not waiting. The cycle is over.|It's all right.|
|It's gone.|Unprocessed Promise Refuses|Plus 0 or 1|
|In the non-⟦0 function, use 1|Syntax Error|Add ⟦0 or use 1|
|I thought we were gonna do it now.|It's in the wrong order.|Remember the micromission priority.|
|Combination with Promise|Error Processing Missing|Unified Promise style|
|Forget it, Promise.|We can't get results on the outside.|Zero or directly one.|

### Cancel and Timeout

```javascript
const controller = new AbortController();
const timer = setTimeout(() => controller.abort(), 3000);

try {
  const res = await fetch(url, { signal: controller.signal });
  console.log(await res.json());
} catch (error) {
  console.log(error.name === "AbortError" ? "请求超时" : error.message);
} finally {
  clearTimeout(timer);
}
```

### Hand hands practice: both grab and take.

```javascript
async function fetchJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${url} 返回 ${res.status}`);
  return res.json();
}

async function loadAll(urls) {
  const results = await Promise.allSettled(urls.map(fetchJson));
  const ok = [];
  const failed = [];

  results.forEach((r, i) => {
    if (r.status === "fulfilled") ok.push(r.value);
    else failed.push({ url: urls[i], reason: r.reason.message });
  });

  return { ok, failed };
}

loadAll(["/api/a", "/api/b"]).then(({ ok, failed }) => {
  console.log(`成功 ${ok.length} 个，失败 ${failed.length} 个`);
});
```

### Learn how to measure yourself.

- [ ] Can back up the order of "sync microtask macro."
- [ ] Could say three states of Promise.
- [ ] Know the difference between ⟦ and .
- [ Chuckles ] Can explain why the cycle is more slow than that.
- [ Chuckles ] It's gonna be time-out.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeat, experiment and deliver around Promise, async, await.

Either the Node or the browser is active first, and then rewrite between steps and errors.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem?
2. Without it, what concrete consequences would there be?
3. What's it got to do with "async"?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a minimum example of at least 3 group inputs in the browser console or Node.js.

Mission requests:

- The result must be checked, not just “I understand”.
- At least cover the key words "Promise" and "async".
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Asynchronous JavaScript

**Summary:** Callbacks, promises, async/await, event loop and fetch.

**Category:** JavaScript  
**Level:** Progress
**Key terms:**Promise, async, event cycle, fitch, microtask

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable context: Node.js 22+/ Modern Browser
- Source: Internal structured curriculum and engineering practices
- Related themes: Promise, async, await, event cycle, fetch, microtask
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Asynchronous JavaScript** focuses on Callbacks, promises, async/await, event loop and fetch.

### Learning Outcomes

- Explain what **Asynchronous JavaScript** solves and when it should be used.
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

- Topic: **Asynchronous JavaScript**
- Relaid terms: Promise, async, event cycle
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|From Return| From Callback to Promise |
| async / await | async/await |
|Event Cycle| Event Loop |
|Fetch.| fetch combat |
|Combination and common traps| Concurrent choreography and common pitfalls |
|It's the end of this class.| Lesson Summary |
|Promise Quick Check| Promise Portfolio Quick Look |
|Async / Wait| async/await quick check |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

