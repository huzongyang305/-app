# 异步编程

![异步编程](images/remaining_js_async.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「异步编程」解决了什么问题，而不是只背术语。
- 能说清 「Promise」、「async」、「await」、「事件循环」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「JavaScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：回调、Promise、async/await、事件循环与 fetch 实战。

## 前置知识

- 先完成上一课《数组与常用方法》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Promise、async、await。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 从回调到 Promise

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

并行与串行：

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

`async` 函数总是返回 Promise；`await` 只能在 async 函数或模块顶层使用。

## 事件循环

```text
调用栈 → 微任务队列（Promise.then、queueMicrotask）→ 宏任务队列（setTimeout、事件、IO）
```

每轮事件循环会**清空所有微任务**再执行下一个宏任务，所以下面输出顺序是 1 → 3 → 2：

```javascript
console.log(1);
setTimeout(() => console.log(2), 0);
Promise.resolve().then(() => console.log(3));
```

## fetch 实战

```javascript
const response = await fetch('/api/items', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ name: 'book' }),
});
const data = await response.json();
```

`fetch` 只在网络错误时 reject，**4xx/5xx 也会 resolve**，所以要检查 `response.ok`；超时可用 `AbortController` 实现。

## 并发编排与常见陷阱

| 需求 | API | 注意 |
| --- | --- | --- |
| 全部成功才继续 | Promise.all | 任一失败立即 reject，其余任务仍会执行（需自行取消） |
| 拿到全部结果（含失败） | Promise.allSettled | 返回 [{status, value/reason}]，适合批量任务 |
| 取最快完成 | Promise.race | 常用于超时控制 |
| 取第一个成功 | Promise.any | 全部失败才 reject（AggregateError） |

**超时控制的正确写法**：用 AbortController 传入 fetch，而不是只 race 一个计时器——后者不会真正取消请求，服务端仍会继续处理。

**并发限流**：一次发起 1000 个请求会打爆连接池与目标服务，应分批（每批 5~10 个）或用信号量控制并发；Node 端还要注意默认的连接数与文件描述符上限。

五个高频陷阱：① 在循环里 `await` 导致串行（应先用 `map` 收集 Promise 再 `Promise.all`）；② 忘记 `await` 使错误变成 unhandledRejection；③ 在 `forEach` 里用 await（forEach 不等待）；④ 事件循环里混入 CPU 密集任务阻塞微任务；⑤ 在组件卸载后才 setState（React 中会产生警告与竞态）。

## 本课小结
异步三件套：**Promise 表达结果、async/await 写成同步风格、事件循环决定执行顺序**。并发请求用 `Promise.all`，别写成串行 await。


## Promise 组合速查

| 方法 | 何时用 | 失败行为 | 返回值 |
| --- | --- | --- | --- |
| `Promise.all(list)` | 全部成功才算成功 | 任一失败立即 reject | 结果数组，顺序与输入一致 |
| `Promise.allSettled(list)` | 允许部分失败 | 永不 reject | `{status, value/reason}` 数组 |
| `Promise.race(list)` | 取最快的一个（含失败） | 最快的结果决定成败 | 单个结果 |
| `Promise.any(list)` | 取最快的成功结果 | 全部失败才 reject（`AggregateError`） | 单个成功值 |
| `await Promise.resolve(x)` | 把同步值包成 Promise | 不会失败 | `x` |

## async / await 速查

| 写法 | 含义 |
| --- | --- |
| `async function f() {}` | 返回值自动包成 Promise |
| `await p` | 等待 Promise 落定，失败会抛出异常 |
| `try { await p } catch (e) {}` | 捕获异步错误的标准写法 |
| `for await (const x of stream)` | 逐个消费异步可迭代对象 |
| `await Promise.all([...])` | 并发执行多个任务，比逐个 `await` 快得多 |
| `arr.map(async (x) => ...)` | 得到的是 Promise 数组，记得 `await Promise.all(...)` |
| `return await p` 与 `return p` | 在 `try` 里需要捕获错误时用前者，否则可直接 `return p` |

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

## 常见错误对照表

| 容易写错的写法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `items.forEach(async (i) => { await save(i) })` | 外层不等待，函数直接结束 | `forEach` 忽略返回值；改成 `for...of` + `await` 或 `await Promise.all(items.map(...))` |
| `try { fetch(url) } catch {}` 不写 `await` | 请求失败无法被捕获 | 必须 `await fetch(url)`，否则拿到的是 Promise |
| `fetch` 返回 404 就走 `catch` | 不会进 `catch` | HTTP 错误不触发 reject，要检查 `res.ok` |
| 循环里逐个 `await` | 串行执行，耗时相加 | 无依赖时用 `Promise.all` 并发 |
| `await` 写在 `map` 的回调外 | 拿到 Promise 数组而不是结果 | 先 `map` 收集 Promise，再 `await Promise.all` |
| 忘记处理 rejected | 浏览器报 `UnhandledPromiseRejection` | 加 `try/catch`、`.catch()` 或全局兜底 |
| `setTimeout(fn, 0)` 想先让 DOM 更新 | 顺序与预期不符 | 微任务（Promise）先于宏任务（定时器）执行 |
| `await` 一个普通值 | 不会报错，会包一层 | 可以直接写同步值，但要注意可读性 |

## 自测清单

- [ ] 能说出 `all`、`allSettled`、`race`、`any` 的差别。
- [ ] 知道 `async` 函数一定返回 Promise。
- [ ] 记得 `fetch` 只在网络层失败时 reject，HTTP 4xx/5xx 要自己判断。
- [ ] 能用 `Promise.all` 把串行请求改成并发请求。
- [ ] 知道微任务（Promise）优先于宏任务（`setTimeout`）执行。


## 零基础详解：事件循环、Promise 与 async/await

### 一句话说清它是什么

JavaScript 只有**一个主线程**，所以耗时操作不能傻等。
异步的本质是：**先登记一个回调，等结果好了再回来执行**。事件循环负责调度这些回调。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 主线程 | 只有一个窗口的柜台 | 一次只能办一件事 |
| 异步任务 | 取号后去旁边等 | 不占着窗口 |
| 事件循环 | 叫号系统 | 窗口空了就叫下一个 |
| 微任务 | VIP 队列 | Promise 回调，优先于宏任务 |
| 宏任务 | 普通队列 | setTimeout、事件回调 |

**关键结论**：`setTimeout(fn, 0)` 不会立刻执行，它排在所有微任务之后。

### 一段代码看清执行顺序

```javascript
console.log("1 同步");
setTimeout(() => console.log("4 宏任务"), 0);
Promise.resolve().then(() => console.log("3 微任务"));
console.log("2 同步");
// 输出顺序：1 同步 → 2 同步 → 3 微任务 → 4 宏任务
```

规则：**同步代码 → 微任务队列清空 → 取一个宏任务 → 再清空微任务 → 循环**。

### 从回调地狱到 async/await

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

### Promise 的三种状态与四个方法

| 状态 | 含义 | 能否再变 |
| --- | --- | --- |
| pending | 进行中 | —— |
| fulfilled | 成功 | 不能再变 |
| rejected | 失败 | 不能再变 |

| 方法 | 作用 | 什么时候用 |
| --- | --- | --- |
| `Promise.all` | 全部成功才成功，任一失败即失败 | 结果都要，且缺一不可 |
| `Promise.allSettled` | 等全部结束，不管成功失败 | 批量任务，想拿到每一份结果 |
| `Promise.race` | 第一个结束的说了算 | 超时控制 |
| `Promise.any` | 第一个成功的说了算 | 多个镜像源，任一个可用即可 |

```javascript
// 并发请求：别用循环里 await，那样是串行
const users = await Promise.all(ids.map((id) => fetchUser(id)));

// 超时控制
const result = await Promise.race([
  fetchData(),
  new Promise((_, reject) => setTimeout(() => reject(new Error("超时")), 3000)),
]);
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忘写 `await` | 拿到 Promise 对象而不是数据 | 在 `async` 函数里 await |
| 循环里逐个 `await` | 总耗时是各任务之和 | 用 `Promise.all` 并发 |
| `forEach` 里用 `await` | 不会等待，循环直接结束 | 改 `for...of` |
| 漏了 `catch` | 出现未处理的 Promise 拒绝 | 加 `try/catch` 或 `.catch` |
| 在非 `async` 函数里用 `await` | 语法错误 | 函数加 `async`，或用 `.then` |
| 以为 `setTimeout(fn, 0)` 立即执行 | 顺序不对 | 记住微任务优先 |
| 混用回调与 Promise | 错误处理遗漏 | 统一成 Promise 风格 |
| 忘了 `return` Promise | 外层拿不到结果 | `return await` 或直接 `return` |

### 取消与超时

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

### 手把手练习：并发抓取并容错

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

### 学完自测

- [ ] 能背出「同步 → 微任务 → 宏任务」的执行顺序。
- [ ] 能说出 Promise 的三种状态。
- [ ] 知道 `Promise.all` 与 `allSettled` 的差别。
- [ ] 能解释为什么循环里 `await` 比 `Promise.all` 慢。
- [ ] 会用 `AbortController` 实现请求超时。

## 动手练习


> 本课练习重点：围绕「Promise、async、await」完成复述、实验和交付，每个结果都要能被别人检查。

先在 Node 或浏览器复现行为，再改写异步与错误路径，最后补测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「异步编程」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「async」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在浏览器控制台或 Node.js 中写一个最小示例，列出至少 3 组输入输出。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Promise」和「async」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Promise.all 的行为是？

- **正确判断**：全部成功才成功
- **判断依据**：正确答案是「全部成功才成功」，本课在「本课小结」中说明：异步三件套：Promise 表达结果、async/await 写成同步风格、事件循环决定执行顺序。Promise.all 并行执行，全部 fulfilled 才成功。本课还在「事件循环」中说明：每轮事件循环会清空所有微任务再执行下一个宏任务，所以下面输出顺序是 1 → 3 → 2。本课还在「并发编排与常见陷阱」中说明：④ 事件循环里混入 CPU 密集任务阻塞微任务。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：事件循环中微任务与宏任务的执行顺序是？

- **正确判断**：每轮先清空微任务
- **判断依据**：正确答案是「每轮先清空微任务」，本课在「本课小结」中说明：异步三件套：Promise 表达结果、async/await 写成同步风格、事件循环决定执行顺序。Promise.then 属于微任务，setTimeout 属于宏任务，微任务总在下一个宏任务之前执行完。本课还在「事件循环」中说明：每轮事件循环会清空所有微任务再执行下一个宏任务，所以下面输出顺序是 1 → 3 → 2。本课还在「零基础详解：事件循环、Promise 与 async/await」中说明：能背出「同步 → 微任务 → 宏任务」的执行顺序。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：fetch 遇到 HTTP 404 时会？

- **正确判断**：resolve
- **判断依据**：正确答案是「resolve」，本课在「fetch 实战」中说明：fetch 只在网络错误时 reject，4xx/5xx 也会 resolve，所以要检查 response.ok。fetch 只在网络层失败时 reject，4xx/5xx 仍算成功响应，需要手动检查 response.ok。本课还在「并发编排与常见陷阱」中说明：④ 事件循环里混入 CPU 密集任务阻塞微任务。本课还在「零基础详解：事件循环、Promise 与 async/await」中说明：规则：同步代码 → 微任务队列清空 → 取一个宏任务 → 再清空微任务 → 循环。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：Promise.allSettled 与 Promise.all 的关键区别是？

- **正确判断**：allSettled 等全部完成并返回每个任务的成功/失败状态，不会因单个失败而短路
- **判断依据**：正确答案是「allSettled 等全部完成并返回每个任务的成功/失败状态，不会因单个失败而短路」，本课在「零基础详解：事件循环、Promise 与 async/await」中说明：关键结论：setTimeout(fn, 0) 不会立刻执行，它排在所有微任务之后。批量任务中允许部分失败时用 allSettled，必须全部成功才继续时用 all。本课还在「async / await」中说明：await 只能在 async 函数或模块顶层使用。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：async 函数总是返回什么？

- **正确判断**：Promise（返回非 Promise 值也会被包装）
- **判断依据**：正确答案是「Promise（返回非 Promise 值也会被包装）」，本课在「async / await」中说明：async 函数总是返回 Promise。因此调用方需要 await 或 .then 处理，抛错会变成 rejected 的 Promise。本课还在「零基础详解：事件循环、Promise 与 async/await」中说明：规则：同步代码 → 微任务队列清空 → 取一个宏任务 → 再清空微任务 → 循环。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「异步编程」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const controller = new ____();`

- **正确判断**：AbortController / abortcontroller
- **判断依据**：正确答案是「AbortController」，本课在「并发编排与常见陷阱」中说明：超时控制的正确写法：用 AbortController 传入 fetch，而不是只 race 一个计时器——后者不会真正取消请求，服务端仍会继续处理。本课还在「fetch 实战」中说明：超时可用 AbortController 实现。本课还在「零基础详解：事件循环、Promise 与 async/await」中说明：会用 AbortController 实现请求超时。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Promise.all 的行为是？」的判断依据。
- [ ] 不看解析，能说出「事件循环中微任务与宏任务的执行顺序是？」的判断依据。
- [ ] 不看解析，能说出「fetch 遇到 HTTP 404 时会？」的判断依据。
- [ ] 不看解析，能说出「Promise.allSettled 与 Promise.all 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「async 函数总是返回什么？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「异步编程」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ___…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Asynchronous JavaScript

**Summary:** Callbacks, promises, async/await, event loop and fetch.

**Category:** JavaScript  
**Level:** 进阶  
**Key terms:** Promise, async, await, 事件循环, fetch, 微任务

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Node.js 22+ / 现代浏览器
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Promise、async、await、事件循环、fetch、微任务
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


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
- Related terms: Promise, async, await, 事件循环
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning Objectives |
| 前置知识 | Pre-knowledge |
| 从回调到 Promise | From Callback to Promise |
| async / await | async/await |
| 事件循环 | Event Loop |
| fetch 实战 | fetch combat |
| 并发编排与常见陷阱 | Concurrent choreography and common pitfalls |
| 本课小结 | Lesson Summary |
| Promise 组合速查 | Promise Portfolio Quick Look |
| async / await 速查 | async/await quick check |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN JavaScript](https://developer.mozilla.org/docs/Web/JavaScript) | 语言、DOM 与运行时 |
| [ECMAScript](https://ecma-international.org/publications-and-standards/standards/ecma-262/) | 语言标准 |

> 本课主题：回调、Promise、async/await、事件循环与 fetch 实战。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

