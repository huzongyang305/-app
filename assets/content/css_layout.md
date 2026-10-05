# CSS 布局：Flex、Grid 与响应式

![CSS 布局：Flex、Grid 与响应式](images/category_css_layout.webp)

> 内容更新时间：2026-10-03 · 学习阶段：入门 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「CSS 布局：Flex、Grid 与响应式」解决了什么问题，而不是只背术语。
- 能说清 「CSS」、「Flexbox」、「Grid」、「响应式」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「HTML 与 CSS」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：一维 Flex、二维 Grid、定位与移动优先响应式。

## 前置知识

- 先完成上一课《CSS 基础：选择器与盒模型》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：入门。只需要基本计算机操作，不要求编程经验。
- 开始前先复习：CSS、Flexbox、Grid。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## Flexbox：一维布局

适用：导航栏、按钮组、卡片内元素对齐。核心是主轴与交叉轴：

| 属性 | 作用 |
| --- | --- |
| `display: flex` | 开启弹性布局 |
| `flex-direction` | 主轴方向（row/column） |
| `justify-content` | 主轴对齐（center/space-between） |
| `align-items` | 交叉轴对齐 |
| `flex: 1` | 可伸缩占据剩余空间 |
| `gap` | 子项间距（不再用 margin 拼） |

## Grid：二维布局

适用：整页骨架、卡片网格、对齐复杂的表单。`grid-template-columns: repeat(auto-fill, minmax(280px, 1fr))` 一行实现响应式卡片网格；`grid-template-areas` 让页面骨架像画图一样可读。

## 定位与层叠上下文

| 值 | 参照物 | 典型用途 |
| --- | --- | --- |
| static | 正常流 | 默认 |
| relative | 自身原位置 | 微调、作为绝对定位参照 |
| absolute | 最近的非 static 祖先 | 角标、下拉菜单 |
| fixed | 视口 | 悬浮按钮 |
| sticky | 最近滚动容器 | 吸顶导航 |

`z-index` 只在定位元素或层叠上下文中生效；父元素创建了层叠上下文（transform、opacity < 1、filter）会限制子元素层级的比较范围。

## 响应式

1. 移动优先：先写小屏样式，再用 `@media (min-width: 768px)` 增强。
2. 优先用流式布局（%、fr、minmax、clamp）而非写多套断点。
3. `clamp(1rem, 2.5vw, 1.5rem)` 实现字号平滑缩放。
4. 用容器查询 `@container` 让组件按自身宽度适配，而不是按视口。

## 常见坑

1. 忘记 `box-sizing: border-box` 导致宽度计算出错。
2. 用 float 做布局（应用 Flex/Grid）。
3. 固定高度写死导致内容溢出，改用 `min-height`。
4. 移动端 100vh 受地址栏影响，用 `100dvh`。

## 布局问题的定位方法

| 现象 | 常见原因 | 处理 |
| --- | --- | --- |
| 子元素溢出父容器 | 子元素有固定宽度/内容过长 | 用 min-width:0 配合 flex 子项，或 overflow-wrap 断词 |
| 高度塌陷（父容器高度为 0） | 子元素浮动未清除 | 用 Grid/Flex 替代 float，或给父元素 display: flow-root |
| 移动端出现横向滚动条 | 固定宽度、100vw 加滚动条、负边距 | 用 max-width:100%、padding 代替负边距 |
| 元素被遮挡 | z-index 无效（父级创建了层叠上下文） | 调整层级或避免在父级用 transform/opacity |
| sticky 不生效 | 祖先有 overflow 隐藏、未设置 top | 去掉祖先 overflow 或改结构，设置 top/bottom |

调试手段：浏览器 DevTools 的盒子高亮能直接看到 padding/border/margin；Flex/Grid 面板可视化对齐线；用 `outline: 1px solid red` 快速定位溢出元素（比 border 不影响布局）。

## 本课小结
布局选择口诀：**一维用 Flex、二维用 Grid、悬浮用定位、适配用响应式**；配合 gap 与 CSS 变量，现代 CSS 已很少需要 hack。

<!-- appendix:v1 -->

## Flex 与 Grid 选择速查

| 需求 | 首选 | 关键属性 |
| --- | --- | --- |
| 一维排列（导航、按钮组） | Flex | `display: flex`、`gap`、`justify-content` |
| 二维网格（卡片墙） | Grid | `grid-template-columns`、`gap` |
| 居中单个元素 | Flex 或 Grid | `place-items: center` |
| 侧栏 + 主内容 | Grid | `grid-template-columns: 260px 1fr` |
| 自动响应卡片 | Grid | `repeat(auto-fit, minmax(240px, 1fr))` |
| 竖向自适应铺满 | Flex | `flex-direction: column`、`flex: 1` |

## 常用属性速查

| 属性 | 作用 |
| --- | --- |
| `flex: 1` | 按比例分配剩余空间 |
| `flex-shrink: 0` | 禁止被压缩（图标、按钮） |
| `min-width: 0` | 让 Flex 子项能正确收缩（解决溢出） |
| `align-items` | 交叉轴对齐 |
| `justify-content` | 主轴对齐 |
| `gap` | 只作用于项目之间，不留首尾间距 |
| `grid-auto-flow: dense` | 填补空洞（注意视觉顺序） |
| `position: sticky` | 滚动到阈值后固定 |
| `inset` | `top/right/bottom/left` 简写 |
| `aspect-ratio` | 固定宽高比 |

```css
/* 侧栏布局：小屏堆叠，大屏两列 */
.layout {
  display: grid;
  gap: 1.5rem;
  grid-template-columns: 1fr;
}

@media (min-width: 900px) {
  .layout {
    grid-template-columns: minmax(220px, 280px) 1fr;
    align-items: start;
  }
}

/* 卡片墙：自动决定列数，最小 240px */
.cards {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
}

/* 导航栏：左标题右按钮，中间自动撑开 */
.toolbar {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.toolbar .title {
  flex: 1;
  min-width: 0;               /* 关键：允许文字截断而不是溢出 */
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* 固定宽高比的媒体容器，避免布局偏移 */
.thumb {
  aspect-ratio: 16 / 9;
  overflow: hidden;
  border-radius: 8px;
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
```

## 响应式速查

| 手段 | 适用 |
| --- | --- |
| 媒体查询 `@media` | 断点式布局调整 |
| 容器查询 `@container` | 组件级自适应 |
| `clamp()` | 字号与间距流体变化 |
| `auto-fit` / `auto-fill` | 网格自动列数 |
| `min()` / `max()` | 宽度上限与最小值 |
| 逻辑属性 `margin-inline` | 支持书写方向（RTL） |

移动优先：先写单列基础样式，再用 `min-width` 断点逐步增强。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| Flex 子项溢出却不加 `min-width: 0` | 文字撑破容器 | Flex 项默认 `min-width: auto` |
| 用 `margin` 控制列表间距 | 首尾多余间距 | 用 `gap` |
| 用 `absolute` 做常规布局 | 响应式困难 | 优先 Flex 或 Grid |
| 固定像素宽度 | 小屏溢出 | 用 `max-width` 与相对单位 |
| `position: absolute` 找不到参照 | 定位到视口 | 父级设 `position: relative` |
| `z-index` 乱加 | 层级冲突 | 明确层叠上下文与顺序 |
| 忽略安全区域 | 内容被刘海遮挡 | 用 `env(safe-area-inset-*)` |
| 断点过多 | 维护困难 | 用容器查询与自适应网格减少断点 |
| 用 `vh` 做移动端满屏 | 地址栏导致跳动 | 用 `dvh` 或 `svh` |
| 用 `float` 做布局 | 需要清除浮动 | 用 Flex 或 Grid |

## 自测清单

- [ ] 能按一维或二维需求选择 Flex 与 Grid。
- [ ] 会用 `gap`、`min-width: 0`、`aspect-ratio` 解决常见问题。
- [ ] 移动优先，断点用 `min-width` 逐步增强。
- [ ] 固定格式容器有稳定尺寸，避免布局偏移。
- [ ] 不使用 `float` 与大量 `absolute` 做常规布局。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「CSS、Flexbox、Grid」完成复述、实验和交付，每个结果都要能被别人检查。

先写最小语义结构，再调整布局与样式，最后检查键盘、窄屏和对比度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「CSS 布局：Flex、Grid 与响应式」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Flexbox」是什么关系？

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
- 至少覆盖「CSS」和「Flexbox」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Flex, Grid & Responsive

**Summary:** Flex, Grid, positioning and responsive design.

**Category:** HTML & CSS  
**Level:** 入门  
**Key terms:** CSS, Flexbox, Grid, 响应式, 定位

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：入门
- 适用环境：现代浏览器（Chrome/Firefox/Safari）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：CSS、Flexbox、Grid、响应式、定位
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：CSS 布局：Flex、Grid 与响应式

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| Flexbox：一维布局 | 适用：导航栏、按钮组、卡片内元素对齐。 | 复述要点 + 举一个反例 |
| Grid：二维布局 | 适用：整页骨架、卡片网格、对齐复杂的表单。 | 复述要点 + 举一个反例 |
| 定位与层叠上下文 | z-index 只在定位元素或层叠上下文中生效；父元素创建了层叠上下文（transform、opacity < 1、filter）会限制子元素层级的比较范围。 | 复述要点 + 举一个反例 |
| 响应式 | 移动优先：先写小屏样式，再用 @media (min-width: 768px) 增强。 | 复述要点 + 举一个反例 |
| 常见坑 | 忘记 box-sizing: border-box 导致宽度计算出错。 | 复述要点 + 举一个反例 |
| 布局问题的定位方法 | 调试手段：浏览器 DevTools 的盒子高亮能直接看到 padding/border/margin；Flex/Grid 面板可视化对齐线；用 outline: 1px sol… | 复述要点 + 举一个反例 |

### 二、机制与验证

1. **Flexbox：一维布局**：适用：导航栏、按钮组、卡片内元素对齐。 验证方式：先复述要点，再举一个反例说明边界。
2. **Grid：二维布局**：适用：整页骨架、卡片网格、对齐复杂的表单。 验证方式：先复述要点，再举一个反例说明边界。
3. **定位与层叠上下文**：z-index 只在定位元素或层叠上下文中生效；父元素创建了层叠上下文（transform、opacity < 1、filter）会限制子元素层级的比较范围。 验证方式：先复述要点，再举一个反例说明边界。
4. **响应式**：移动优先：先写小屏样式，再用 @media (min-width: 768px) 增强。 验证方式：先复述要点，再举一个反例说明边界。
5. **常见坑**：忘记 box-sizing: border-box 导致宽度计算出错。 验证方式：先复述要点，再举一个反例说明边界。
6. **布局问题的定位方法**：调试手段：浏览器 DevTools 的盒子高亮能直接看到 padding/border/margin；Flex/Grid 面板可视化对齐线；用 outline: 1px sol… 验证方式：先复述要点，再举一个反例说明边界。

### 三、专属检查问题

1. 「Flexbox：一维布局」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「Grid：二维布局」的输入和输出分别是什么？
3. 「定位与层叠上下文」最常见的失败方式是什么？如何定位？
4. 「响应式」的适用边界在哪里？什么情况下不该使用？
5. 「常见坑」和相邻主题相比，最关键的差别是什么？
6. 「布局问题的定位方法」如何验证自己真的掌握了？写出一个可执行的检查步骤。

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：Flexbox：一维布局的核心要点是什么？**

答：适用：导航栏、按钮组、卡片内元素对齐。

**问：Grid：二维布局的核心要点是什么？**

答：适用：整页骨架、卡片网格、对齐复杂的表单。

**问：定位与层叠上下文的核心要点是什么？**

答：z-index 只在定位元素或层叠上下文中生效；父元素创建了层叠上下文（transform、opacity < 1、filter）会限制子元素层级的比较范围。

**问：响应式的核心要点是什么？**

答：移动优先：先写小屏样式，再用 @media (min-width: 768px) 增强。

**问：常见坑的核心要点是什么？**

答：忘记 box-sizing: border-box 导致宽度计算出错。

**问：布局问题的定位方法的核心要点是什么？**

答：调试手段：浏览器 DevTools 的盒子高亮能直接看到 padding/border/margin；Flex/Grid 面板可视化对齐线；用 outline: 1px sol…

## 逐步练习：CSS 布局：Flex、Grid 与响应式

### 练习 1：Flexbox：一维布局

1. 不看原文，用自己的话复述：适用：导航栏、按钮组、卡片内元素对齐。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：Grid：二维布局

1. 不看原文，用自己的话复述：适用：整页骨架、卡片网格、对齐复杂的表单。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：定位与层叠上下文

1. 不看原文，用自己的话复述：z-index 只在定位元素或层叠上下文中生效；父元素创建了层叠上下文（transform、opacity < 1、filter）会限制子元素层级的比较范围。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 4：响应式

1. 不看原文，用自己的话复述：移动优先：先写小屏样式，再用 @media (min-width: 768px) 增强。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 5：常见坑

1. 不看原文，用自己的话复述：忘记 box-sizing: border-box 导致宽度计算出错。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 6：布局问题的定位方法

1. 不看原文，用自己的话复述：调试手段：浏览器 DevTools 的盒子高亮能直接看到 padding/border/margin；Flex/Grid 面板可视化对齐线；用 outline: 1px sol…
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：CSS 布局：Flex、Grid 与响应式

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「Flexbox：一维布局」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「Grid：二维布局」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「定位与层叠上下文」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「响应式」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「常见坑」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「布局问题的定位方法」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：CSS 布局：Flex、Grid 与响应式

1. 「Flexbox：一维布局」的输入和输出分别是什么？
2. 「Grid：二维布局」最常见的失败方式是什么？如何定位？
3. 「定位与层叠上下文」的适用边界在哪里？什么情况下不该使用？
4. 「响应式」和相邻主题相比，最关键的差别是什么？
5. 「常见坑」如何验证自己真的掌握了？写出一个可执行的检查步骤。
6. 「布局问题的定位方法」要解决什么问题？请用一句话说明，并给出一个具体例子。

## 专属进阶任务 5：CSS 布局：Flex、Grid 与响应式

把本课 6 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

### 验收标准

- 例子可以独立运行，输出与预期一致。
- 两条边界用例都说清了输入、预期与实际结果。
- 验证结论用一句话写清，不依赖“感觉正确”。

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

> 本课主题：一维 Flex、二维 Grid、定位与移动优先响应式。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

