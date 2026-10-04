# 图解事件循环：同步、微任务与宏任务

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「图解事件循环：同步、微任务与宏任务」解决了什么问题，而不是只背术语。
- 能说清 「事件循环」、「微任务」、「宏任务」、「Promise」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「图解专题」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：用时间线讲清执行顺序、渲染时机与长任务卡顿的原因。

## 前置知识

- 先完成上一课《图解调用栈与递归》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：事件循环、微任务、宏任务。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


![事件循环执行顺序示意图](images/event_loop.webp)

## 一句话说清

JavaScript 只有一条主线程：**同步代码先跑完，再清空微任务队列，然后取一个宏任务**，
如此循环。看懂这条流水线，所有「为什么输出顺序和我写的不一样」都能解释。

## 一张图看懂事件循环

```text
        ┌───────────────────────────┐
        │      调用栈 Call Stack     │  同步代码在这里执行
        └─────────────┬─────────────┘
                      │ 栈空
                      ▼
        ┌───────────────────────────┐
        │   微任务队列 Microtasks    │  Promise.then、queueMicrotask
        │   全部清空，一个不留        │  MutationObserver
        └─────────────┬─────────────┘
                      │ 清空后
                      ▼
        ┌───────────────────────────┐
        │   宏任务队列 Macrotasks    │  setTimeout、setInterval
        │   只取一个，执行完再回头看 │  I/O、UI 事件
        └─────────────┬─────────────┘
                      │
                      └──────► 回到微任务检查（循环）
```

## 一段代码验证顺序

```javascript
console.log("1 同步");

setTimeout(() => console.log("5 宏任务"), 0);

Promise.resolve()
  .then(() => console.log("3 微任务"))
  .then(() => console.log("4 微任务链"));

console.log("2 同步");

// 输出：1 同步 → 2 同步 → 3 微任务 → 4 微任务链 → 5 宏任务
```

```text
时间线
  t0  ┌─ 同步：打印 1
      ├─ 注册 setTimeout 回调 → 放进宏任务队列
      ├─ 注册 Promise.then → 放进微任务队列
      ├─ 同步：打印 2
      │   同步结束，栈空
  t1  ├─ 清空微任务：打印 3
      ├─ 微任务里又注册了 then → 继续清空：打印 4
  t2  ├─ 取一个宏任务：打印 5
      └─ 循环
```

## 为什么 setTimeout(fn, 0) 不是立刻执行

| 阶段 | 说明 |
| --- | --- |
| `setTimeout(fn, 0)` 的真实含义 | 最快也要等下一轮宏任务 |
| 前面还有同步代码 | 必须等同步全部执行完 |
| 前面还有微任务 | 微任务优先于任何宏任务 |
| 浏览器还要渲染 | 渲染时机也在事件循环里排队 |

## 微任务与宏任务速查

| 类别 | 常见来源 | 执行时机 |
| --- | --- | --- |
| 同步代码 | 普通语句 | 立即，在调用栈上 |
| 微任务 | `Promise.then`、`queueMicrotask`、`await` 之后 | 每个宏任务后全部清空 |
| 宏任务 | `setTimeout`、`setInterval`、I/O、UI 事件 | 每轮只取一个 |
| 渲染 | 样式计算、布局、绘制 | 通常在微任务清空后、下一个宏任务前 |

**注意**：`await` 之后的部分相当于接在微任务里执行。

```javascript
async function run() {
  console.log("A");
  await null;              // 之后的代码进入微任务
  console.log("C");
}
run();
console.log("B");
// 输出：A → B → C
```

## 长任务为什么会卡住界面

```text
理想情况（每帧 16.7ms 内完成）
  [同步任务 5ms][微任务 2ms][渲染 5ms][空闲]

长任务阻塞（同步任务 200ms）
  [────────同步任务 200ms────────][渲染]  ← 中间 12 帧被跳过，用户看到卡顿
```

对策：

| 手段 | 说明 |
| --- | --- |
| 拆分任务 | 用 `setTimeout` 或 `requestIdleCallback` 切片 |
| 移出主线程 | 用 Web Worker 处理计算 |
| 减少同步计算 | 缓存、记忆化、虚拟列表 |
| 避免强制同步布局 | 批量读、批量写 |

## 新手最容易踩的六个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 以为 `setTimeout(0)` 立即执行 | 顺序不符预期 | 记住同步与微任务优先 |
| 在微任务里无限注册微任务 | 页面卡死，宏任务饿死 | 微任务里别无限自增 |
| 用 `await` 当同步用 | 顺序错乱 | 记住 `await` 之后进微任务 |
| 循环里同步做重计算 | 界面卡顿 | 拆分或放 Worker |
| 期望 `forEach` + `await` 生效 | 循环不等待 | 改 `for...of` 或 `Promise.all` |
| 忘记清理定时器 | 组件卸载后仍执行 | 卸载时 `clearTimeout` |

## 本课小结
- 执行顺序口诀：**同步 → 微任务清空 → 一个宏任务 → 再清微任务 → 循环**。
- 想让某段代码「尽快但在当前同步代码之后」执行，用微任务；想「下一轮再执行」用宏任务。
- 卡顿的根因永远是**主线程被长时间占用**，而不是异步本身。

<!-- appendix:v4 -->

## 补充：任务队列细分、渲染时机与长任务治理

### 宏任务不止一种

```text
浏览器事件循环里的宏任务来源
  · setTimeout / setInterval 回调
  · DOM 事件回调（点击、输入）
  · 网络请求完成回调
  · MessageChannel（常用于 polyfill 与调度）
  · requestAnimationFrame 回调（在渲染前执行）

每轮循环只取一个宏任务，执行完清空微任务，然后才可能渲染
```

| 任务类型 | 执行时机 | 用途 |
| --- | --- | --- |
| 同步代码 | 立刻，在调用栈上 | 普通逻辑 |
| 微任务 | 每个宏任务后全部清空 | Promise、queueMicrotask |
| 宏任务 | 每轮一个 | 定时器、事件 |
| requestAnimationFrame | 渲染前 | 动画更新 |
| requestIdleCallback | 空闲时（可能不执行） | 低优先级任务 |

### 渲染到底发生在什么时候

```text
一帧的理想顺序（约 16.7ms）
  输入事件 → 微任务清空 → rAF 回调 → 样式计算 → 布局 → 绘制 → 合成

关键推论
  · 在 rAF 里改样式，可以在同一帧内被应用
  · 在 setTimeout 里改样式，可能要等到下一帧
  · 微任务如果一直追加，渲染永远轮不到 → 页面「卡死」
```

```javascript
// 反例：微任务里无限自我追加，页面完全无响应
function spin() {
  Promise.resolve().then(spin);   // 永不回到渲染阶段
}
```

### Node 的六个阶段

```text
   ┌───────────────┐
   │   timers      │  setTimeout / setInterval 到期回调
   ├───────────────┤
   │   pending     │  系统级回调
   ├───────────────┤
   │   poll        │  IO 回调（多数时间停在这里）
   ├───────────────┤
   │   check       │  setImmediate
   ├───────────────┤
   │   close       │  关闭回调
   └───────────────┘
   每个阶段之间清空微任务队列

setImmediate 通常在 poll 之后的 check 阶段执行，
而 setTimeout(fn, 0) 要等下一轮 timers —— 因此两者顺序在主模块中不确定
```

### 长任务治理的四种手段

| 手段 | 做法 | 适用 |
| --- | --- | --- |
| 时间切片 | 每处理 N 条就让出主线程 | 大数组处理 |
| Web Worker | 把纯计算搬到 Worker | 解析、加密、图像处理 |
| 增量渲染 | 分批插入 DOM | 列表首屏 |
| 让出执行权 | `await scheduler.yield()` 或 `setTimeout(0)` | 需要保持可交互 |

```javascript
// 时间切片：每 5ms 让出一次，保持页面可响应
async function processInChunks(items, handle) {
  const CHUNK_MS = 5;
  let start = performance.now();
  for (const item of items) {
    handle(item);
    if (performance.now() - start > CHUNK_MS) {
      await new Promise((r) => setTimeout(r, 0));   // 让出主线程
      start = performance.now();
    }
  }
}
```

### 用性能面板定位问题

```text
DevTools → Performance 录制时重点看三样
  · 长任务（红色三角标记）：超过 50ms 的任务
  · Main 泳道：函数调用的耗时排序
  · Frames：是否有掉帧（帧间隔 > 16.7ms）

常见结论
  · 长任务集中在一次 map 里 → 时间切片或 Worker
  · 掉帧伴随大量 Layout → 避免强制同步布局
  · 微任务堆积 → 检查 Promise 递归与 await 链
```

### 自查清单

- [ ] 能说出宏任务与微任务的执行顺序
- [ ] 知道 rAF 在渲染前执行，适合做动画
- [ ] 知道微任务无限追加会导致页面失去响应
- [ ] 能用时间切片或 Worker 拆分长任务
- [ ] 会用 Performance 面板识别长任务与掉帧

<!-- scaffold:v1 -->

<!-- exercise-guard:v1 -->

## 动手练习

### 练习 1：概念复述（10 分钟）

合上教程，用 3～5 句话解释「图解事件循环：同步、微任务与宏任务」解决什么问题，并写出一个边界条件。

**验收标准**：至少使用一个本课关键词，并给出一个反例。

### 练习 2：示例改写（20 分钟）

从正文选一个最小示例，先预测修改一个输入后的结果，再实际验证并记录差异。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：迁移任务（30 分钟）

不看原图手绘一遍流程，再用自己的话指出图中的关键状态变化。

- 至少覆盖「事件循环」和「微任务」两个关键词。
- 产出一个别人可以检查的结果。
- 写出一个仍不确定的问题和验证方法。

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Event Loop Illustrated

**Summary:** Execution order, rendering timing and long-task blocking.

**Category:** Visual Guide  
**Level:** 进阶  
**Key terms:** 事件循环, 微任务, 宏任务, Promise, 渲染

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：通用图解与系统原理
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：事件循环、微任务、宏任务、Promise、渲染
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [RFC Editor](https://www.rfc-editor.org/) | 协议与状态机 |
| [MDN Web Docs](https://developer.mozilla.org/) | 浏览器与网络流程 |

> 本课主题：用时间线讲清执行顺序、渲染时机与长任务卡顿的原因。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

