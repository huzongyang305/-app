## 现代特性速查

| 特性 | 作用 | 示例 |
| --- | --- | --- |
| 自定义属性 | 主题变量与运行时切换 | `--brand: #2563eb` |
| `:is()` / `:where()` | 简化选择器，`where` 零特异性 | `:is(h1, h2, h3)` |
| `:has()` | 父级按子元素状态匹配 | `.card:has(img)` |
| `:focus-visible` | 键盘聚焦才显示样式 | 焦点可访问性 |
| `@layer` | 显式层叠顺序 | 第三方与自有样式分层 |
| `clamp()` | 弹性取值 | 流体字号 |
| `color-mix()` | 颜色混合 | 生成悬停色 |
| 容器查询 | 组件按自身宽度适配 | `@container (min-width: 30rem)` |
| 逻辑属性 | 支持书写方向 | `margin-inline`、`padding-block` |
| `scroll-snap` | 滚动吸附 | 轮播与长图 |

```css
/* 主题变量：一套变量支持浅色与深色 */
:root {
  --brand: #2563eb;
  --surface: #ffffff;
  --text: #111827;
  --radius: 8px;
  --space: clamp(0.75rem, 2vw, 1.5rem);
}

@media (prefers-color-scheme: dark) {
  :root {
    --brand: #60a5fa;
    --surface: #0f172a;
    --text: #e5e7eb;
  }
}

/* 用层管理优先级：重置 < 基础 < 组件 < 工具类 */
@layer reset, base, components, utilities;

@layer components {
  .card {
    background: var(--surface);
    color: var(--text);
    border-radius: var(--radius);
    padding: var(--space);
    transition: transform 160ms ease;
  }

  .card:hover {
    transform: translateY(-2px);
  }

  /* 只在包含图片时加额外内边距：父级选择更精准 */
  .card:has(img) {
    padding: 0;
  }
}

/* 容器查询：组件按自身可用宽度切换布局 */
@container (min-width: 30rem) {
  .card-body {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space);
  }
}

/* 键盘聚焦可见，鼠标点击不显示描边 */
.card:focus-visible {
  outline: 2px solid var(--brand);
  outline-offset: 2px;
}
```

## 变量与层叠速查

| 场景 | 做法 |
| --- | --- |
| 主题色 | 定义在 `:root`，组件只引用变量 |
| 组件局部变量 | 定义在组件选择器上，可被覆盖 |
| 变量兜底 | `var(--brand, #2563eb)` |
| 覆盖顺序 | 用 `@layer` 声明层顺序 |
| 降低特异性 | 用 `:where()` 包裹 |
| 深色模式 | `prefers-color-scheme` 覆盖变量 |
| 用户主题切换 | 通过 `data-theme` 属性覆盖变量 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 到处用 `!important` | 无法维护 | 用 `@layer` 与 `:where()` |
| 变量定义在组件内却期望全局 | 取不到值 | 全局放 `:root` |
| 忘记变量兜底 | 值未定义时样式崩 | `var(--x, fallback)` |
| 用 `:has()` 做重逻辑 | 性能与兼容问题 | 用于局部状态样式，注意浏览器支持 |
| 深色模式只改背景 | 对比度不足 | 同时调整文字、边框与状态色 |
| 容器查询未声明容器 | 不生效 | 父级加 `container-type: inline-size` |
| 用 `px` 写所有间距 | 不随字号缩放 | 与 `rem`/`clamp` 混用 |
| 忽略颜色对比度 | 无障碍不达标 | 正文对比度至少 4.5:1 |
| 依赖最新特性不做回退 | 老浏览器布局崩 | 用 `@supports` 或渐进增强 |
| 变量命名混乱 | 难以维护 | 用统一的语义命名 |

## 自测清单

- [ ] 主题通过 CSS 变量管理，支持深色模式切换。
- [ ] 用 `@layer` 与 `:where()` 控制层叠而非加 `!important`。
- [ ] 会用 `:has()`、容器查询等现代特性做局部适配。
- [ ] 文字与背景对比度满足无障碍要求。
- [ ] 新特性有回退或渐进增强方案。
