## 页面结构速查

| 区块 | 语义 | 要点 |
| --- | --- | --- |
| 页头 | `header` | 品牌、主导航、语言切换 |
| 主体内容 | `main` | 唯一，包含各 section |
| 特性区 | `section` | 每块有标题与简短说明 |
| 价格或方案 | `section` + 列表 | 用列表而非表格表达选项 |
| 行动号召 | `section` + 按钮 | 主按钮唯一且明显 |
| 页脚 | `footer` | 版权、链接、备案信息 |

## 样式组织速查

| 组织方式 | 适用 |
| --- | --- |
| 按层（reset、base、components、utilities） | 中大型项目 |
| 按组件文件 | 组件库与设计系统 |
| 命名约定（BEM 或语义化类名） | 避免样式冲突 |
| 变量集中定义 | 主题与间距统一 |
| 工具类辅助 | 局部微调，不替代组件样式 |

```css
/* 落地页骨架：响应式特性网格 + 深色模式支持 */
:root {
  --brand: #2563eb;
  --bg: #ffffff;
  --fg: #0f172a;
  --muted: #64748b;
  --card: #f8fafc;
  --radius: 8px;
  --space: clamp(1rem, 3vw, 2rem);
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0b1220;
    --fg: #e5e7eb;
    --muted: #94a3b8;
    --card: #111c31;
  }
}

body {
  margin: 0;
  background: var(--bg);
  color: var(--fg);
  font-family: system-ui, sans-serif;
  line-height: 1.6;
}

.container {
  max-width: 72rem;
  margin-inline: auto;
  padding-inline: var(--space);
}

.features {
  display: grid;
  gap: var(--space);
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
}

.feature {
  background: var(--card);
  border-radius: var(--radius);
  padding: var(--space);
}

.cta {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  border-radius: var(--radius);
  background: var(--brand);
  color: #ffffff;
  text-decoration: none;
  font-weight: 600;
}

.cta:focus-visible {
  outline: 2px solid var(--fg);
  outline-offset: 3px;
}
```

## 质量检查清单

| 类别 | 检查项 |
| --- | --- |
| 结构 | 语义标签、标题层级、唯一 `main` |
| 无障碍 | 对比度、焦点可见、`alt`、表单标签 |
| 响应式 | 320px 到超宽屏无溢出、无横向滚动 |
| 性能 | 图片尺寸与懒加载、字体策略、无布局偏移 |
| 兼容 | 关键特性有回退，主流浏览器验证 |
| 深色模式 | 文字与背景对比度达标 |
| 国际化 | 文案集中管理，支持长文本不溢出 |
| SEO | `title`、`description`、结构化数据、语义化 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 div 堆砌所有区块 | 结构无语义、SEO 差 | 用语义标签 |
| 大小屏共用固定宽度 | 小屏溢出 | `max-width` + 网格自适应 |
| 深色模式只改背景色 | 文字看不清 | 变量统一改文字与边框 |
| 图片直接放原图 | 加载慢、浪费流量 | 响应式图片 + 懒加载 |
| 无对比度检查 | 无障碍不达标 | 用工具检查对比度 |
| 焦点样式被移除 | 键盘不可用 | 保留 `:focus-visible` |
| 文案写死在多处 | 改文案要改多处 | 集中管理或使用变量 |
| 不测长文本 | 多语言溢出 | 用弹性布局与截断 |
| 只测 Chrome | 其他浏览器布局错乱 | 多浏览器验证 |
| 忽略首屏关键样式 | 首屏闪烁 | 内联关键 CSS 并延迟其余 |

## 自测清单

- [ ] 页面使用语义结构且标题层级正确。
- [ ] 320px 到宽屏均无横向滚动与溢出。
- [ ] 深色模式下对比度达标。
- [ ] 图片响应式并启用懒加载，首屏无偏移。
- [ ] 键盘可完整操作，焦点可见。
