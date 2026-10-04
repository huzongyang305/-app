# 浏览器渲染与事件循环深入

![浏览器渲染与事件循环深入](images/category_browser_rendering.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「浏览器渲染与事件循环深入」解决了什么问题，而不是只背术语。
- 能说清 「事件循环」、「微任务」、「渲染管线」、「强制同步布局」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「HTML 与 CSS」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：宏任务微任务顺序、强制同步布局与长任务拆片。

## 前置知识

- 先完成上一课《可访问性与 ARIA 实战》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：事件循环、微任务、渲染管线。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 事件循环速查

| 队列 | 例子 | 执行时机 |
| --- | --- | --- |
| 宏任务（task） | `setTimeout`、事件回调、网络回调 | 每轮取一个执行 |
| 微任务（microtask） | Promise 回调、`queueMicrotask`、`MutationObserver` | 每个宏任务之后清空全部 |
| 渲染步骤 | 样式、布局、绘制、合成 | 需要呈现时在宏任务之间执行 |
| 空闲回调 | `requestIdleCallback` | 帧末尾有空闲时 |

关键结论：**微任务会在渲染之前全部执行完**。如果微任务里再产生微任务，会一直占住主线程，导致页面不刷新。

```javascript
console.log("1 sync");
setTimeout(() => console.log("4 macrotask"), 0);
Promise.resolve().then(() => console.log("3 microtask"));
console.log("2 sync");
// 输出顺序：1 sync → 2 sync → 3 microtask → 4 macrotask
```

## 渲染管线速查

| 阶段 | 何时发生 | 代价 |
| --- | --- | --- |
| 样式计算 | 选择器匹配、变量变化 | 中 |
| 布局 | 几何属性变化 | 高 |
| 绘制 | 颜色、阴影、背景变化 | 中 |
| 合成 | transform、opacity | 低 |

避免布局抖动的关键：**不要把读操作与写操作交错执行**，否则每写一次都会强制同步布局。

```javascript
// 反例：读-写-读-写 交错，触发多次强制同步布局
function bad(elements) {
  for (const el of elements) {
    el.style.height = `${el.offsetHeight + 10}px`;   // 写后立刻读，强制回流
  }
}

// 正例：先批量读，再批量写
function good(elements) {
  const heights = elements.map((el) => el.offsetHeight);   // 只读
  elements.forEach((el, index) => {
    el.style.height = `${heights[index] + 10}px`;          // 只写
  });
}
```

```javascript
// 长任务拆片：把大批量处理切到多帧，保证输入响应（改善 INP）
async function processInIdle(items, handler) {
  const CHUNK = 200;
  for (let index = 0; index < items.length; index += CHUNK) {
    const slice = items.slice(index, index + CHUNK);
    slice.forEach(handler);
    // 让出主线程：下一轮事件循环继续
    await new Promise((resolve) => setTimeout(resolve, 0));
  }
}

// 用 PerformanceObserver 观察长任务
if ("PerformanceObserver" in window) {
  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (entry.duration > 50) {
        console.warn("长任务", Math.round(entry.duration), "ms");
      }
    }
  }).observe({ entryTypes: ["longtask"] });
}
```

## 滚动与布局优化速查

| 问题 | 手段 |
| --- | --- |
| 滚动卡顿 | 用 `transform` 做位移动画，避免监听 `scroll` 改布局 |
| 频繁滚动回调 | 用 `passive: true` 或 `IntersectionObserver` 替代 |
| 图片懒加载 | `loading="lazy"` 或 `IntersectionObserver` |
| 列表过长 | 虚拟滚动，只渲染可见区域 |
| 布局抖动 | 预留尺寸、`contain: layout` 隔离影响范围 |
| 大量 DOM 更新 | 批量写入、`DocumentFragment`、一次性替换 |

## 渲染阻塞速查

| 资源 | 是否阻塞解析 | 建议 |
| --- | --- | --- |
| `<script>` 同步 | 阻塞 | 用 `defer` 或 `type="module"` |
| `<script async>` | 不阻塞 | 无依赖的独立脚本 |
| `<style>` / `<link rel=stylesheet>` | 阻塞渲染 | 关键 CSS 内联，其余异步加载 |
| 字体 | 触发文字延迟 | `font-display: swap` + 预加载 |
| 大图与视频 | 影响 LCP | 压缩、尺寸适配、`fetchpriority` |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 认为 `setTimeout(0)` 立即执行 | 顺序与预期不符 | 宏任务要等当前任务与微任务清空 |
| 在微任务里递归排队 | 页面完全卡死 | 改用宏任务或拆片让出线程 |
| 读写字交错 | 强制同步布局，掉帧严重 | 先批量读、再批量写 |
| 用 `scroll` 事件改布局 | 滚动抖动 | 用 `passive` 监听或观察器替代 |
| 同步脚本放 `<head>` | 首屏空白 | 用 `defer` / `async` / 模块脚本 |
| 关键 CSS 依赖网络 | 首屏样式闪烁 | 内联关键样式 |
| 忽略长任务 | 输入延迟（INP 差） | 拆片、Worker、`requestIdleCallback` |
| 用 `left/top` 做动画 | 每帧布局 | 用 `transform` |

## 自测清单

- [ ] 能准确说出宏任务、微任务与渲染的执行顺序。
- [ ] 知道微任务不结束就不会渲染。
- [ ] 避免读写交错导致的强制同步布局。
- [ ] 长任务会拆片，保证输入响应。
- [ ] 关键 CSS 内联，脚本使用 `defer` 或模块。

<!-- appendix:v4 -->

## 补充：重排重绘与关键渲染路径优化

### 哪些属性会触发什么

| 变更属性 | 触发的阶段 | 代价 |
| --- | --- | --- |
| `width`、`height`、`margin`、`top/left` | 布局 + 绘制 + 合成 | **最高（重排）** |
| `color`、`background`、`box-shadow` | 绘制 + 合成 | 中 |
| `transform`、`opacity` | 仅合成 | **最低** |
| `visibility` | 绘制 + 合成 | 中 |
| `filter`（部分） | 合成（GPU） | 低 |

```text
一句话原则：动画只改 transform 与 opacity
  · 它们可以由合成器单独处理，不触发 layout 与 paint
  · top/left 做动画等价于每帧重排，是典型的性能反模式
```

### 强制同步布局：最常见的隐形杀手

```javascript
// 反例：读 → 写 → 读 → 写，每次都强制浏览器立刻重排
for (const el of items) {
  el.style.width = el.offsetWidth + 10 + "px";   // 读 offsetWidth 触发同步布局
}

// 正例：先批量读，再批量写
const widths = items.map((el) => el.offsetWidth);
items.forEach((el, i) => { el.style.width = widths[i] + 10 + "px"; });
```

| 触发同步布局的属性 | 说明 |
| --- | --- |
| `offsetTop/Left/Width/Height` | 读取即需要最新布局 |
| `scrollTop/scrollHeight` | 同上 |
| `getComputedStyle()` | 强制样式计算 |
| `getBoundingClientRect()` | 强制布局 |

### 关键渲染路径的五步与可优化点

```text
HTML → DOM 树 ┐
              ├→ 渲染树 → 布局 → 绘制 → 合成
CSS  → CSSOM ┘

可优化点
  · HTML：减少嵌套层级、避免巨型 DOM（数千节点以上要考虑虚拟列表）
  · CSS：关键样式内联，非关键样式异步加载
  · 脚本：用 defer/async，避免同步脚本阻塞解析
  · 图片：预留尺寸（width/height 或 aspect-ratio）避免 CLS
  · 字体：font-display: swap，避免文字长时间不可见
```

```html
<!-- 关键 CSS 内联，其余异步加载 -->
<style>/* 首屏必需的最小样式 */</style>
<link rel="preload" as="style" href="/full.css" onload="this.rel='stylesheet'">

<!-- 脚本不阻塞解析 -->
<script src="/app.js" defer></script>

<!-- 图片预留尺寸，避免布局偏移 -->
<img src="/hero.webp" width="800" height="450" alt="产品图">
```

### 合成层与 will-change

```text
把元素提升为独立合成层的常见方式
  · transform: translateZ(0) 或 will-change: transform
  · position: fixed、video、canvas 天然可能独立成层

好处：动画由 GPU 合成，主线程只更新少量属性
代价：每个层都要显存，层过多会拖慢合成与内存

结论：will-change 只在动画开始前短时间加上，结束后移除
```

### 优化前后怎么验证

| 工具 | 看什么 | 结论 |
| --- | --- | --- |
| DevTools Performance | 是否有紫色 Layout 条 | 有则存在重排 |
| Layers 面板 | 合成层数量与大小 | 层过多 → 显存压力 |
| Lighthouse | LCP、CLS、INP | 按指标定位资源或长任务 |
| Rendering → Paint flashing | 绿色闪烁区域 | 闪烁说明发生了重绘 |

```text
三个指标的常见对策
  LCP 高 → 优化首屏图片与关键 CSS，或预加载主图
  CLS 高 → 给图片/广告位预留尺寸，避免动态插入内容
  INP 高 → 拆分长任务，减少主线程占用
```

### 自查清单

- [ ] 动画只使用 transform 与 opacity
- [ ] 没有「读 → 写 → 读 → 写」的强制同步布局
- [ ] 脚本用 defer/async，关键 CSS 内联
- [ ] 图片与广告位预留尺寸，避免 CLS
- [ ] 用 Performance 面板验证过重排与合成层数量

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「事件循环、微任务、渲染管线」完成复述、实验和交付，每个结果都要能被别人检查。

先写最小语义结构，再调整布局与样式，最后检查键盘、窄屏和对比度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「浏览器渲染与事件循环深入」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「微任务」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

做一个只有标题、卡片和按钮的最小页面，并用浏览器设备模式检查窄屏。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「事件循环」和「微任务」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「浏览器渲染与事件循环深入」不是孤立术语，而是在「HTML 与 CSS」中解决一类具体问题。
- 关键关系：先分清「事件循环」与「微任务」的职责，再理解「渲染管线」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Rendering & Event Loop

**Summary:** Task queues, forced reflow and long task splitting.

**Category:** HTML & CSS  
**Level:** 高级  
**Key terms:** 事件循环, 微任务, 渲染管线, 强制同步布局, 长任务, INP

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：现代浏览器（Chrome/Firefox/Safari）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：事件循环、微任务、渲染管线、强制同步布局、长任务、INP
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN Web Docs](https://developer.mozilla.org/docs/Web) | HTML、CSS 与浏览器行为 |
| [W3C Standards](https://www.w3.org/TR/) | Web 标准与可访问性规范 |

> 本课主题：宏任务微任务顺序、强制同步布局与长任务拆片。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

