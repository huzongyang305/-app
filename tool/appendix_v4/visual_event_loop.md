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

