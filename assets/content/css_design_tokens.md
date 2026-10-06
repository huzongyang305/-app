# 设计令牌与样式架构

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：25 分钟

![设计令牌的三层结构](images/diagram_web_design_tokens.webp)

![设计令牌与样式架构](images/category_css_design_tokens.webp)

## 学习目标

- 能用自己的话解释设计令牌与样式架构解决了什么问题，而不是只背术语。
- 能说清 「设计令牌」、「CSS变量」、「主题」、「设计系统」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「HTML 与 CSS」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：令牌三层结构、命名约定与对比度自动校验。

## 前置知识

- 先完成上一课《前端性能优化实战》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：设计令牌、CSS变量、主题。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 什么是设计令牌

设计令牌（Design Token）是把颜色、间距、字号、圆角、阴影等**设计决策**抽成命名变量，让设计与代码共享同一套事实来源。它的价值不是「少写几行 CSS」，而是：改一处、全站一致、可被工具校验。

## 令牌分层速查

| 层 | 作用 | 示例 |
| --- | --- | --- |
| 原始令牌 | 与业务无关的调色板与刻度 | `--blue-600: #2563eb` |
| 语义令牌 | 表达用途，随主题切换 | `--color-primary`、`--color-surface` |
| 组件令牌 | 组件内部专用 | `--button-padding-x` |

原则：**组件只引用语义令牌，语义令牌引用原始令牌。** 这样换主题只需改语义层映射。

```css
:root {
  /* 1. 原始令牌：完整色阶与刻度 */
  --blue-500: #3b82f6;
  --blue-600: #2563eb;
  --gray-100: #f1f5f9;
  --gray-900: #0f172a;
  --white: #ffffff;

  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-6: 1.5rem;

  --radius-sm: 4px;
  --radius-md: 8px;
  --font-size-sm: 0.875rem;
  --font-size-md: 1rem;
  --font-size-lg: 1.25rem;

  /* 2. 语义令牌：表达用途 */
  --color-primary: var(--blue-600);
  --color-primary-hover: var(--blue-500);
  --color-surface: var(--white);
  --color-text: var(--gray-900);
  --color-muted: var(--gray-100);
  --space-inline: var(--space-4);
}

@media (prefers-color-scheme: dark) {
  :root {
    /* 只改映射，不改组件 */
    --color-surface: #0b1220;
    --color-text: #e5e7eb;
    --color-muted: #1e293b;
  }
}

/* 3. 组件令牌：组件内部细节 */
.btn {
  --button-padding-x: var(--space-4);
  --button-padding-y: var(--space-2);

  display: inline-flex;
  gap: var(--space-2);
  padding: var(--button-padding-y) var(--button-padding-x);
  border-radius: var(--radius-md);
  background: var(--color-primary);
  color: var(--white);
  font-size: var(--font-size-md);
  transition: background 160ms ease;
}

.btn:hover {
  background: var(--color-primary-hover);
}
```

## 命名约定速查

| 类别 | 命名模式 | 示例 |
| --- | --- | --- |
| 颜色 | `--color-{用途}` | `--color-danger` |
| 背景 | `--color-surface` / `--color-bg` | `--color-bg-raised` |
| 间距 | `--space-{刻度}` | `--space-4` |
| 字号 | `--font-size-{尺寸}` | `--font-size-lg` |
| 圆角 | `--radius-{尺寸}` | `--radius-md` |
| 层级 | `--z-{用途}` | `--z-modal`、`--z-toast` |
| 动效 | `--duration-{速度}` / `--ease-{类型}` | `--duration-fast` |

## 与设计工具协作

设计侧与代码侧共享同一份令牌 JSON，构建时生成 CSS 变量与多端常量（如 Flutter、Android、iOS），避免「设计稿改了、代码没跟上」。

```python
import json

TOKENS = {
    "color": {
        "primary": "#2563eb",
        "surface": "#ffffff",
        "text": "#0f172a",
    },
    "space": {"sm": "0.5rem", "md": "1rem", "lg": "1.5rem"},
    "radius": {"sm": "4px", "md": "8px"},
}

def flatten(prefix: str, node: dict) -> list:
    """把嵌套令牌拍平成 CSS 变量列表，便于生成样式表。"""
    items = []
    for key, value in node.items():
        name = f"{prefix}-{key}" if prefix else key
        if isinstance(value, dict):
            items.extend(flatten(name, value))
        else:
            items.append((name, value))
    return items

def to_css(tokens: dict) -> str:
    lines = [":root {"]
    for name, value in flatten("", tokens):
        lines.append(f"  --{name}: {value};")
    lines.append("}")
    return "\n".join(lines)

def validate_contrast(foreground: str, background: str) -> float:
    """对比度检查：正文需达到 4.5:1，大字号需 3:1。"""
    def luminance(hex_color: str) -> float:
        raw = hex_color.lstrip("#")
        channels = [int(raw[i:i + 2], 16) / 255 for i in (0, 2, 4)]
        adjusted = [(c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4)
                    for c in channels]
        return 0.2126 * adjusted[0] + 0.7152 * adjusted[1] + 0.0722 * adjusted[2]

    l1, l2 = luminance(foreground), luminance(background)
    lighter, darker = max(l1, l2), min(l1, l2)
    return round((lighter + 0.05) / (darker + 0.05), 2)

print(to_css(TOKENS).splitlines()[1])
print(validate_contrast("#0f172a", "#ffffff"), validate_contrast("#94a3b8", "#ffffff"))
```

## 常见错误与排查

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 组件里写死颜色值 | 换主题要改几十个文件 | 组件只引用语义令牌 |
| 只有原始令牌没有语义层 | 深色模式要逐条覆盖 | 增加语义层做映射 |
| 令牌命名按外观（`--blue`） | 换品牌色后名字含义错乱 | 按用途命名（`--color-primary`） |
| 令牌层级混用 | 组件直接引用原始令牌 | 约定「组件只引用语义令牌」 |
| 设计侧与代码侧各维护一套 | 数值不一致 | 共享令牌 JSON 并自动生成 |
| 忘记对比度校验 | 深色模式下文字看不清 | 自动化检查对比度 |
| 令牌数量爆炸 | 无人知道该用哪个 | 保持刻度收敛，定期合并 |

## 复习与自测

- [ ] 令牌分原始、语义、组件三层。
- [ ] 组件不写死颜色与尺寸，只引用语义令牌。
- [ ] 深色模式通过改语义层映射实现。
- [ ] 令牌与设计工具共享同一份数据源。
- [ ] 有对比度自动校验。

## 动手练习

> 本课练习重点：围绕「设计令牌、CSS变量、主题」完成复述、实验和交付，每个结果都要能被别人检查。

先写最小语义结构，再调整布局与样式，最后检查键盘、窄屏和对比度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 设计令牌与样式架构解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「CSS变量」是什么关系？

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
- 至少覆盖「设计令牌」和「CSS变量」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：设计令牌与样式架构不是孤立术语，而是在「HTML 与 CSS」中解决一类具体问题。
- 关键关系：先分清「设计令牌」与「CSS变量」的职责，再理解「主题」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。

## 可运行练习

### 任务 1：先跑通，再解释

```python
import json

TOKENS = {
    "color": {
        "primary": "#2563eb",
        "surface": "#ffffff",
        "text": "#0f172a",
    },
    "space": {"sm": "0.5rem", "md": "1rem", "lg": "1.5rem"},
    "radius": {"sm": "4px", "md": "8px"},
}

def flatten(prefix: str, node: dict) -> list:
    """把嵌套令牌拍平成 CSS 变量列表，便于生成样式表。"""
    items = []
    for key, value in node.items():
        name = f"{prefix}-{key}" if prefix else key
        if isinstance(value, dict):
            items.extend(flatten(name, value))
        else:
            items.append((name, value))
    return items

def to_css(tokens: dict) -> str:
    lines = [":root {"]
    for name, value in flatten("", tokens):
        lines.append(f"  --{name}: {value};")
    lines.append("}")
    return "\n".join(lines)

def validate_contrast(foreground: str, background: str) -> float:
    """对比度检查：正文需达到 4.5:1，大字号需 3:1。"""
    def luminance(hex_color: str) -> float:
        raw = hex_color.lstrip("#")
        channels = [int(raw[i:i + 2], 16) / 255 for i in (0, 2, 4)]
        adjusted = [(c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4)
                    for c in channels]
        return 0.2126 * adjusted[0] + 0.7152 * adjusted[1] + 0.0722 * adjusted[2]

    l1, l2 = luminance(foreground), luminance(background)
    lighter, darker = max(l1, l2), min(l1, l2)
    return round((lighter + 0.05) / (darker + 0.05), 2)

print(to_css(TOKENS).splitlines()[1])
print(validate_contrast("#0f172a", "#ffffff"), validate_contrast("#94a3b8", "#ffffff"))
```

### 任务 2：只改一个条件

把「设计令牌与样式架构」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把设计令牌的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「设计令牌与样式架构」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响设计令牌。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 设计令牌 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 设计令牌 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 设计令牌 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“设计令牌 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 设计令牌 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 CSS变量 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 CSS变量 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 CSS变量 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“CSS变量 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 CSS变量 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，设计令牌 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「设计令牌分三层时，组件应该引用哪一层？」的判断依据。
- [ ] 不看解析，能说出「深色模式在令牌体系里应该怎么实现？」的判断依据。
- [ ] 不看解析，能说出「令牌命名按用途还是按外观更好？」的判断依据。
- [ ] 不看解析，能说出「检验文字在背景上是否可读，应使用什么指标？」的判断依据。
- [ ] 不看解析，能说出「设计侧与代码侧各维护一套颜色值会带来什么问题？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 本课语境 |
| --- | --- |
| `--blue-600: #2563eb` | \| 原始令牌 \| 与业务无关的调色板与刻度 \| `--blue-600: #2563eb` \| |
| `--color-primary` | \| 语义令牌 \| 表达用途，随主题切换 \| `--color-primary`、`--color-surface` \| |
| `--color-surface` | \| 语义令牌 \| 表达用途，随主题切换 \| `--color-primary`、`--color-surface` \| |
| `--button-padding-x` | \| 组件令牌 \| 组件内部专用 \| `--button-padding-x` \| |
| `--color-{用途}` | \| 颜色 \| `--color-{用途}` \| `--color-danger` \| |
| `--color-danger` | \| 颜色 \| `--color-{用途}` \| `--color-danger` \| |

## 考点精讲

### 考点 1：概念判断·设计令牌

- **题目**：设计令牌分三层时，组件应该引用哪一层？
- **判断依据**：组件引用语义令牌（如 --color-primary），换主题时只改语义层到原始层的映射，组件无需改动。在「设计令牌与样式架构」里，「三层都不用，直接写死」让主题切换要改遍所有组件。“设计令牌分三层时”与「设计令牌与样式架构」的术语表相呼应，只有符合设计令牌、CSS变量、主题约束的“语义令牌”才是正文支持的结论。

### 考点 2：概念判断·设计令牌

- **题目**：深色模式在令牌体系里应该怎么实现？
- **判断依据**：在「设计令牌与样式架构」里，只改语义层的映射，组件代码不动。深色模式本质是同一套语义令牌换一组取值，组件层完全不用变。在「设计令牌与样式架构」里判断这道题，要把设计令牌、CSS变量、主题的条件、过程与失败路径逐项对齐，换成“深色模式在令牌体系里应该怎么实现”这个场景，只有满足前提的结论才成立。

### 考点 3：多选辨析·设计令牌

- **题目**：围绕“设计令牌与样式架构”中的 设计令牌、CSS变量、主题，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把设计令牌与样式架构拆成概念、示例与故障现场三部分，因此判断 设计令牌 时必须同时交代输入、输出和失败路径，这使“学习 设计令牌 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在设计令牌与样式架构里，判断 CSS变量 时要固定版本与边界输入，所以“验证 CSS变量 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 4：概念判断·设计令牌

- **题目**：「设计令牌与样式架构」的核心结论是什么？
- **判断依据**：题干的正确项是设计令牌与样式架构：令牌三层结构、命名约定与对比度自动校验。“的核心结论是什么”与术语表相呼应，只有符合设计令牌、CSS变量、主题约束的“设计令牌与样式架构：令牌三层结构”才是正文支持的结论。「设计令牌与样式架构」要求先交代设计令牌、CSS变量、主题的前提再下结论，所以“设计令牌与样式架构：令牌三层结构”只在题干“的核心结论是什么”给定的条件下成立。

### 考点 5：概念判断·设计令牌

- **题目**：设计侧与代码侧各维护一套颜色值会带来什么问题？
- **判断依据**：在「设计令牌与样式架构」里，数值逐渐不一致。两套事实来源必然漂移，正确做法是共享同一份令牌数据并自动生成各端产物。「设计令牌与样式架构」要求先交代设计令牌、CSS变量、主题的前提再下结论，所以“数值逐渐不一致”只在题干“设计侧与代码侧各维护一套颜色值会带来什么问题”给定的条件下成立。

### 考点 6：填空·设计令牌

- **题目**：补全代码：「设计令牌与样式架构」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `--color-____: var(--blue-600);`
- **判断依据**：在「设计令牌与样式架构」里，primary。这道题的关键在「设计令牌与样式架构」的设计令牌、CSS变量、主题：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。回到设计令牌、CSS变量、主题本身再看一遍：只有“primary”与题干“primary”的前提一致，结论才成立。

## English Overview

**Title:** Design Tokens

**Summary:** Token layers, naming conventions and contrast validation.

**Category:** HTML & CSS
**Level:** 进阶
**Key terms:** 设计令牌, CSS变量, 主题, 设计系统, 对比度

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：现代浏览器（Chrome/Firefox/Safari）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：设计令牌、CSS变量、主题、设计系统、对比度
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN CSS](https://developer.mozilla.org/docs/Web/CSS) | CSS 布局、选择器与动画 |
| [MDN HTML](https://developer.mozilla.org/docs/Web/HTML) | HTML 语义与文档结构 |
| [MDN 无障碍](https://developer.mozilla.org/docs/Web/Accessibility) | 可访问性与语义 |

> 「设计令牌与样式架构」的链接用于离线阅读后的延伸核对；App 不会自动联网。
