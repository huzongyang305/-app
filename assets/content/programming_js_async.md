# 异步编程

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：45 分钟

![事件循环、微任务与宏任务](images/diagram_js_async.webp)

![异步编程](images/remaining_js_async.webp)

## 学习目标

- 能用自己的话解释异步编程解决了什么问题，而不是只背术语。
- 能说清 「Promise」、「async」、「await」、「事件循环」 之间的关系，并分别举出一个例子。
- 能把 Promise 放回「异步编程」的知识体系，说明它和 async 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：回调、Promise、async/await、事件循环与 fetch 实战。

## 前置知识

- 先完成上一课《数组与常用方法》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「数组与常用方法」，或确认自己能独立跑通正文里的 setTimeout 示例。
- 开始前先复习：Promise、async、await。
- 卡在 Promise 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

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

## 常见错误与排查

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

## 复习与自测

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

把 setTimeout 的错误处理改成显式分支，并为每条分支补一个用例。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 异步编程解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「async」是什么关系？

验收标准：说明 Promise 与 async 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：把 setTimeout 当作原例，改动一次async的取值，记录命令、输出与差异原因；五步里缺任意一步都算未完成。

### 练习 3：交付一个小结果（30 分钟）

在运行时里验证 async 的行为，记录三组输入与对应输出。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Promise」和「async」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

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

**预期输出**：结束

### 任务 2：只改一个条件

把「异步编程」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 async 换成边界值，其他输入保持原样。
- 预测：先写下「异步编程」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Promise。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 Promise 数据，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：items.forEach(async (i) => { await save(i) })

**症状**：在《异步编程》的复现场景中，外层不等待，函数直接结束。

**根因**：触发点是把“items.forEach(async (i) => { await save(i) })”当成安全做法。它没有满足《异步编程》要求的前提，因此先表现为“外层不等待，函数直接结束”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《异步编程》的问题，forEach 忽略返回值；改成 for...of + await 或 await Promise.all(items.map(...))。

**验证**：在《异步编程》中按“forEach 忽略返回值；改成 for...of + await 或 await Promise.all(items.map(...))”调整后，从“items.forEach(async (i) => { await save(i) })”的触发条件重放同一条路径，确认“外层不等待，函数直接结束”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：try { fetch(url) } catch {} 不写 await

**症状**：在《异步编程》的复现场景中，请求失败无法被捕获。

**根因**：“请求失败无法被捕获”只是表层结果。向上追溯会落到“try { fetch(url) } catch {} 不写 await”这一步，因为它省略了《异步编程》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《异步编程》的问题，必须 await fetch(url)，否则拿到的是 Promise。

**验证**：在《异步编程》中按“必须 await fetch(url)，否则拿到的是 Promise”调整后，从“try { fetch(url) } catch {} 不写 await”的触发条件重放同一条路径，确认“请求失败无法被捕获”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：fetch 返回 404 就走 catch

**症状**：在《异步编程》的复现场景中，不会进 catch。

**根因**：触发点是把“fetch 返回 404 就走 catch”当成安全做法。它没有满足《异步编程》要求的前提，因此先表现为“不会进 catch”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《异步编程》的问题，HTTP 错误不触发 reject，要检查 res.ok。

**验证**：在《异步编程》中按“HTTP 错误不触发 reject，要检查 res.ok”调整后，从“fetch 返回 404 就走 catch”的触发条件重放同一条路径，确认“不会进 catch”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 版本与时效

- setTimeout 依赖的新 API 必须有降级路径，否则老环境直接报错。
- 升级「异步编程」涉及的依赖前，先用 setTimeout 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 setTimeout 记录构建与运行结果。
- 先回归 Promise 与 async 的默认行为和错误信息，再扩大测试范围。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 Promise 的版本变化。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Promise.all 的行为是？」的判断依据。
- [ ] 不看解析，能说出「事件循环中微任务与宏任务的执行顺序是？」的判断依据。
- [ ] 不看解析，能说出「fetch 遇到 HTTP 404 时会？」的判断依据。
- [ ] 不看解析，能说出「Promise.allSettled 与 Promise.all 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「async 函数总是返回什么？」的判断依据。
- [ ] 跑通「异步编程」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「异步编程」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `Promise` | 表示异步操作最终结果的对象，可链式处理成功和失败。 |
| `async` | 标记异步函数或异步块，使内部可以使用 await 而不阻塞调用线程。 |
| `await` | ② 忘记 await 使错误变成 unhandledRejection。 |
| `事件循环` | 运行时从任务队列取出回调并执行的调度循环，负责协调同步栈与异步任务。 |
| `fetch` | 浏览器和现代运行时提供的基于 Promise 的 HTTP 请求接口。 |

## 考点精讲

### 考点 1：代码补全·Promise

- **题目**：阅读「异步编程」正文里的这段 JavaScript 代码，下面哪一项判断是正确的？
- **判断依据**：在「异步编程」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「异步编程」里封装边界决定Promise从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「异步编程」的实际运行结果为准。“阅读异步编程正文里的这段”与「异步编程」的术语表相呼应，只有符合Promise、async、await约束的“这段代码把主要逻辑封装在函数或方法里”才是正文支持的结论。

### 考点 2：多选辨析·Promise

- **题目**：围绕“异步编程”中的 Promise、async、await，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把异步编程拆成概念、示例与故障现场三部分，因此判断 Promise 时必须同时交代输入、输出和失败路径，这使“学习 Promise 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在异步编程里，判断 async 时要固定版本与边界输入，所以“验证 async 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·Promise

- **题目**：fetch 遇到 HTTP 404 时会？
- **判断依据**：在「异步编程」里，resolve。fetch 只在网络层失败时 reject，4xx/5xx 仍算成功响应，需要手动检查 response.ok。这道题的关键在「异步编程」的Promise、async、await：先确认题干“fetch 遇到 HTTP 404”问的是哪一步，再排除偷换前提的选项。

### 考点 4：概念判断·Promise

- **题目**：Promise.allSettled 与 Promise.all 的关键区别是？
- **判断依据**：在「异步编程」里，结论应落在「allSettled 等全部完成并返回每个任务的成功/失败状态，不会因单个失败而短路」。结论应落在allSettled 等全部完成并返回每个任务的成功/失败状态。批量任务中允许部分失败时用 allSettled，必须全部成功才继续时用 all。这道题的关键在「异步编程」的Promise、async、await：先确认题干“Promise.allSettled”问的是哪一步，再排除偷换前提的选项。

### 考点 5：概念判断·Promise

- **题目**：async 函数总是返回什么？
- **判断依据**：在「异步编程」里，Promise（返回非 Promise 值也会被包装）。因此调用方需要 await 或 .then 处理，抛错会变成 rejected 的 Promise。“async”与「异步编程」的术语表相呼应，只有符合Promise、async、await约束的“Promise（返回非 Promise”才是正文支持的结论。

### 考点 6：填空·Promise

- **题目**：补全代码：「异步编程」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const controller = new ____;`
- **判断依据**：空格应填写「AbortController」、「abortcontroller」。回到「异步编程」的正文示例，用“补全代码”走一遍Promise、async、await的完整流程，能复现的结论才可以保留。回到Promise、async、await本身再看一遍：只有“AbortController”与题干“AbortController”的前提一致，结论才成立。

## English Overview

**Title:** Asynchronous JavaScript

**Summary:** Callbacks, promises, async/await, event loop and fetch.

**Category:** JavaScript
**Level:** 进阶
**Key terms:** Promise, async, await, 事件循环, fetch, 微任务

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Node.js 22+ / 现代浏览器；本课聚焦 Promise。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Promise、async、await、事件循环、fetch、微任务
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**Asynchronous JavaScript** focuses on Callbacks, promises, async/await, event loop and fetch.

### Learning Outcomes

- Explain what **Asynchronous JavaScript** solves and when it should be used.

### Glossary

- Topic: **Asynchronous JavaScript**
- Related terms: Promise, async, await, 事件循环

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

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN Promise](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Promise) | Promise 与异步链 |
| [Node 事件循环](https://nodejs.org/en/learn/asynchronous-work/event-loop-timers-and-nexttick) | 事件循环与异步顺序 |
| [ECMAScript 标准](https://tc39.es/ecma262/) | JavaScript 语言标准 |

> 「异步编程」的链接用于离线阅读后的延伸核对；App 不会自动联网。
