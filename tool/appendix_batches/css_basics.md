## 选择器特异性速查

| 选择器 | 特异性 | 说明 |
| --- | --- | --- |
| 行内样式 | 1,0,0,0 | 最高（除 `!important`） |
| `#id` | 0,1,0,0 | 尽量少用 |
| `.class`、`[attr]`、`:hover` | 0,0,1,0 | 日常主力 |
| 元素、伪元素 | 0,0,0,1 | 低特异性 |
| `*`、组合器 | 0,0,0,0 | 无特异性 |
| `!important` | 覆盖一切 | 只作最后手段 |

规则：**优先用类选择器，保持特异性扁平**，避免为了覆盖而不断加权重。

## 盒模型与单位速查

| 概念 | 说明 |
| --- | --- |
| `content-box` | 宽高只含内容，padding 与 border 额外增加 |
| `border-box` | 宽高包含 padding 与 border（推荐全局设置） |
| `margin` 塌陷 | 相邻块级元素的垂直外边距会合并 |
| `px` | 绝对单位 |
| `rem` | 相对根字号，适合整体缩放 |
| `em` | 相对当前字号，嵌套会累乘 |
| `%` | 相对父元素对应尺寸 |
| `vw` / `vh` | 相对视口（注意移动端地址栏变化） |
| `clamp()` | 在最小与最大之间弹性取值 |

```css
/* 现代基础重置：统一盒模型并尊重系统字号 */
*,
*::before,
*::after {
  box-sizing: border-box;
}

html {
  font-size: 100%;          /* 尊重用户浏览器设置 */
  line-height: 1.5;
  -webkit-text-size-adjust: 100%;
}

body {
  margin: 0;
  font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
  color: #1f2937;
  background: #ffffff;
}

img,
svg,
video {
  max-width: 100%;
  height: auto;
  display: block;
}

/* 用 clamp 做流体排版，避免正文字号随视口无限放大 */
article {
  max-width: 68ch;
  margin-inline: auto;
  padding-inline: clamp(1rem, 4vw, 2.5rem);
}

h1 {
  font-size: clamp(1.75rem, 1.2rem + 2vw, 2.75rem);
  line-height: 1.25;
}

/* 焦点可见：鼠标点击不显示，键盘操作必须显示 */
button:focus-visible,
a:focus-visible {
  outline: 2px solid #2563eb;
  outline-offset: 2px;
}
```

## 层叠与继承速查

| 因素 | 优先级 |
| --- | --- |
| 来源与重要性 | 用户 `!important` 大于作者 `!important` |
| 层（`@layer`） | 后声明的层优先 |
| 特异性 | 高者优先 |
| 出现顺序 | 同特异性时后出现者优先 |

可继承属性：`color`、`font-*`、`line-height`、`visibility`、`cursor` 等；`margin`、`padding`、`border`、`width` 默认不继承。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 不设 `box-sizing` | 宽度计算总是超出预期 | 全局设 `border-box` |
| 用 `!important` 解决覆盖 | 特异性战争 | 降低特异性或用层 |
| 用 `px` 设所有字号 | 用户放大字号无效 | 用 `rem` 与系统字号 |
| 给 `html` 设固定 `font-size: 62.5%` | 影响可访问性 | 用 `100%` 并按需换算 |
| 用 `em` 层层嵌套 | 字号被累乘放大 | 改用 `rem` |
| 忘记移动端图片自适应 | 图片溢出 | 全局 `max-width: 100%` |
| 用 `height: 100vh` 做移动端满屏 | 地址栏导致跳动 | 用 `100dvh` 或 `min-height` |
| 去掉 `outline` | 键盘不可用 | 用 `:focus-visible` 自定义 |
| 依赖元素选择器 | 一处结构变更全站样式崩 | 用类名 |
| 内联样式写业务样式 | 无法复用与覆盖 | 交给样式表与类 |

## 自测清单

- [ ] 能按特异性高低排列常见选择器。
- [ ] 全局使用 `border-box`，图片自适应。
- [ ] 字号用 `rem` 并尊重系统设置。
- [ ] 焦点样式用 `:focus-visible` 保留可见性。
- [ ] 尽量不用 `!important`，用层与低特异性解决冲突。
