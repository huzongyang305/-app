## 关键渲染路径速查

| 阶段 | 触发条件 | 代价 |
| --- | --- | --- |
| 解析 HTML 建 DOM | 首次或结构变化 | 高 |
| 样式计算 | 选择器匹配、变量变化 | 中 |
| 布局（Reflow） | 几何属性变化 | 高 |
| 绘制（Paint） | 颜色、阴影、背景变化 | 中 |
| 合成（Composite） | 图层变换、透明度 | 低 |

优化原则：**优先只触发合成的属性（`transform`、`opacity`），避免频繁触发布局。**

## 属性代价对照

| 属性 | 触发布局 | 触发绘制 | 仅合成 |
| --- | --- | --- | --- |
| `width`、`height`、`margin`、`top` | 是 | 是 | 否 |
| `color`、`background-color`、`box-shadow` | 否 | 是 | 否 |
| `transform`、`opacity`、`filter` | 否 | 可能 | 是 |
| `will-change` | 否 | 否 | 提示提升图层 |

## 动画方式速查

| 方式 | 性能 | 适用 |
| --- | --- | --- |
| CSS 过渡与动画 | 高（可走合成） | 大多数交互动画 |
| Web Animations API | 高 | 需要 JS 控制的动画 |
| JS 改样式逐帧 | 低 | 尽量不用 |
| `requestAnimationFrame` | 中 | 需要逐帧计算的场景 |
| SVG 动画 | 中 | 图标与矢量图形 |

```css
/* 只动画 transform 与 opacity：不触发布局与绘制 */
.card {
  transition: transform 200ms ease, box-shadow 200ms ease;
  will-change: transform;         /* 只在动画期间使用 */
}

.card:hover {
  transform: translateY(-4px);
}

/* 入场动画：避免使用 top/left/margin */
@keyframes slide-in {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.list-item {
  animation: slide-in 220ms ease-out both;
}

/* 尊重用户的减少动效偏好 */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## 布局稳定性速查

| 问题 | 原因 | 解决 |
| --- | --- | --- |
| 布局偏移（CLS） | 图片、广告、字体加载后尺寸变化 | 预留宽高、`aspect-ratio`、`font-display` |
| 图片抖动 | 未设置尺寸 | 写 `width`/`height` 或用 `aspect-ratio` |
| 字体闪烁 | 字体文件较晚加载 | `font-display: swap` 并预加载关键字体 |
| 滚动条跳动 | 内容高度变化 | 预留占位或固定容器高度 |
| 长任务卡顿 | 主线程被占用 | 拆分任务、用 `requestIdleCallback` |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `top`/`left` 做动画 | 每帧触发布局，掉帧 | 改用 `transform` |
| 用 `margin` 做位移动画 | 触发布局 | 用 `transform: translate` |
| 长期挂着 `will-change` | 图层过多、显存占用高 | 只在动画前后开启 |
| 图片不设尺寸 | 布局偏移 | 预留宽高或用 `aspect-ratio` |
| 动画不尊重减少动效 | 眩晕用户不适 | 用 `prefers-reduced-motion` |
| 每秒读取 `offsetHeight` | 强制同步布局 | 缓存测量结果、批量读写分离 |
| 频繁改大量 DOM 样式 | 重排重绘刷屏 | 用类切换或 `transform` |
| 忽略合成层数量 | 内存占用升高 | 控制图层数量 |
| 动画时长过长 | 感觉迟钝 | 交互反馈控制在 150 到 300 毫秒 |
| 只在桌面测性能 | 移动端掉帧 | 在低端设备与降频场景实测 |

## 自测清单

- [ ] 知道哪些属性触发布局、绘制与合成。
- [ ] 动画优先使用 `transform` 与 `opacity`。
- [ ] 图片与媒体容器预留尺寸，避免 CLS。
- [ ] 尊重 `prefers-reduced-motion`。
- [ ] 用性能面板确认没有强制同步布局与长任务。
