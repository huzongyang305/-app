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
