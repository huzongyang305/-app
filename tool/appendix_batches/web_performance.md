## Core Web Vitals 速查

| 指标 | 含义 | 良好阈值 |
| --- | --- | --- |
| LCP | 最大内容绘制（加载体验） | 小于 2.5 秒 |
| INP | 交互到下一次绘制（响应性） | 小于 200 毫秒 |
| CLS | 累计布局偏移（视觉稳定性） | 小于 0.1 |

辅助指标：

| 指标 | 含义 | 目标 |
| --- | --- | --- |
| TTFB | 首字节时间 | 小于 800 毫秒 |
| FCP | 首次内容绘制 | 小于 1.8 秒 |
| TBT | 总阻塞时间（实验室） | 尽量低 |

## 优化清单速查

| 方向 | 手段 |
| --- | --- |
| 减少请求 | 合并关键资源、HTTP/2 多路复用、内联关键 CSS |
| 减小体积 | 代码分割、tree shaking、压缩（brotli/gzip）、图片转 WebP/AVIF |
| 提前加载 | `preload` 关键资源、`preconnect` 关键域名、`fetchpriority="high"` |
| 延迟非关键 | 非首屏图片懒加载、第三方脚本延迟、`defer`/`async` |
| 减少主线程工作 | 拆分长任务、`requestIdleCallback`、Web Worker |
| 缓存 | 强缓存 + 指纹、协商缓存 `ETag` |
| 字体 | `font-display: swap`、子集化、预加载 |
| 布局稳定 | 预留尺寸、`aspect-ratio`、避免动态插入顶栏 |

```html
<!-- 关键资源与首屏图片：明确优先级，避免抢占带宽 -->
<link rel="preconnect" href="https://cdn.example.com" crossorigin />
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin />
<link rel="stylesheet" href="/critical.css" />
<link rel="stylesheet" href="/non-critical.css" media="print" onload="this.media='all'" />

<!-- 首屏图片：高优先级 + 明确尺寸，避免布局偏移 -->
<img
  src="/hero-800.avif"
  srcset="/hero-400.avif 400w, /hero-800.avif 800w, /hero-1600.avif 1600w"
  sizes="(max-width: 600px) 100vw, 800px"
  width="800"
  height="450"
  fetchpriority="high"
  alt="课程界面预览"
/>

<!-- 非首屏图片：懒加载 -->
<img src="/lesson.png" width="640" height="360" loading="lazy" decoding="async" alt="课程章节" />
```

```javascript
// 把长任务拆成小块，避免阻塞交互（INP 优化）
async function processInChunks(items, handle, chunkSize = 200) {
  for (let index = 0; index < items.length; index += chunkSize) {
    const slice = items.slice(index, index + chunkSize);
    slice.forEach(handle);
    // 让出主线程，给渲染与输入事件机会
    await new Promise((resolve) => setTimeout(resolve, 0));
  }
}

// 观察真实用户指标并上报
function reportWebVitals() {
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (entry.entryType === "largest-contentful-paint") {
        console.info("LCP", Math.round(entry.startTime));
      }
      if (entry.entryType === "layout-shift" && !entry.hadRecentInput) {
        console.info("CLS 增量", entry.value.toFixed(4));
      }
    }
  });
  observer.observe({ type: "largest-contentful-paint", buffered: true });
  observer.observe({ type: "layout-shift", buffered: true });
}
```

## 排查流程速查

| 步骤 | 工具 | 关注 |
| --- | --- | --- |
| 1 现状 | Lighthouse、CrUX | 三项指标是否达标 |
| 2 加载 | Network 面板 | 关键路径、体积、串行请求 |
| 3 渲染 | Performance 面板 | LCP 元素、长任务、布局偏移 |
| 4 交互 | Performance 录制 | 输入延迟、事件处理耗时 |
| 5 真实用户 | 字段数据上报 | P75 指标与设备分布 |
| 6 优化验证 | 前后对比 | 同口径、同网络条件 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看实验室数据 | 与真实用户体验脱节 | 结合字段数据（P75） |
| 用平均分代替分布 | 长尾被掩盖 | 看 P75 与低端设备 |
| 首屏加载大量 JS | LCP 与 INP 双差 | 代码分割 + 关键路径优先 |
| 图片不设尺寸 | CLS 超标 | 写宽高或用 `aspect-ratio` |
| 所有图片都懒加载 | 首屏图延迟 | 首屏图高优先级，其余懒加载 |
| 第三方脚本同步加载 | 阻塞渲染 | `defer` / `async` 或延迟加载 |
| 长任务不拆分 | INP 超标 | 分片处理或放进 Worker |
| 无缓存策略 | 重复下载 | 强缓存 + 指纹 |
| 字体未做子集与预加载 | 文字闪烁、延迟 | 子集化 + 预加载 + `swap` |
| 优化不验证 | 收益不明甚至回退 | 前后对比同口径指标 |

## 自测清单

- [ ] 三项核心指标都有真实用户数据（P75）。
- [ ] 首屏关键资源明确优先级，非关键资源延迟。
- [ ] 图片与媒体预留尺寸，CLS 达标。
- [ ] 长任务拆分，INP 达标。
- [ ] 每次优化都有前后对比数据。
