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

