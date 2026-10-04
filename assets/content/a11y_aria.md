# 可访问性与 ARIA 实战

![可访问性与 ARIA 实战](images/category_a11y_aria.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「可访问性与 ARIA 实战」解决了什么问题，而不是只背术语。
- 能说清 「可访问性」、「ARIA」、「无障碍」、「键盘」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「HTML 与 CSS」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：原生优先原则、常用 ARIA 属性与键盘焦点管理。

## 前置知识

- 先完成上一课《设计令牌与样式架构》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：可访问性、ARIA、无障碍。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 基本原则速查

| 原则 | 含义 |
| --- | --- |
| 优先用原生元素 | `<button>` 自带键盘与语义，比 `div` 加 ARIA 更可靠 |
| 语义第一、ARIA 补充 | 能用原生语义就不用 ARIA |
| 键盘可达 | 所有交互都能用键盘完成 |
| 焦点可见 | 键盘操作时必须看到焦点位置 |
| 足够对比度 | 正文 4.5:1，大字号 3:1 |
| 不依赖颜色传达信息 | 错误提示同时给出图标或文字 |

**ARIA 第一条规则：能不用 ARIA 就不用 ARIA。** 用错的 ARIA 比没有 ARIA 更糟。

## 常用 ARIA 属性速查

| 属性 | 作用 | 示例 |
| --- | --- | --- |
| `aria-label` | 提供不可见名称 | 图标按钮 `aria-label="关闭"` |
| `aria-labelledby` | 关联已有文本作为名称 | 对话框标题 |
| `aria-describedby` | 关联补充说明 | 输入框提示与错误 |
| `aria-expanded` | 展开状态 | 折叠面板、菜单按钮 |
| `aria-controls` | 关联被控制元素 | 按钮与面板 |
| `aria-current` | 当前项 | 导航当前页 |
| `aria-live` | 动态内容播报 | 表单提交结果 |
| `aria-hidden` | 从无障碍树移除 | 纯装饰图标 |
| `role` | 补充角色 | 自定义组件的角色声明 |
| `tabindex` | 控制键盘可聚焦 | 一般不用，避免 `tabindex>0` |

```html
<!-- 图标按钮：必须给可访问名称 -->
<button type="button" aria-label="关闭对话框">
  <svg aria-hidden="true" focusable="false" viewBox="0 0 24 24">
    <path d="M6 6l12 12M18 6L6 18" />
  </svg>
</button>

<!-- 表单：标签、说明与错误三者关联 -->
<form>
  <label for="email">邮箱</label>
  <input
    id="email"
    name="email"
    type="email"
    autocomplete="email"
    required
    aria-describedby="email-hint email-error"
    aria-invalid="true"
  />
  <p id="email-hint">用于接收通知，不会公开。</p>
  <p id="email-error" role="alert">请输入有效的邮箱地址。</p>
</form>

<!-- 折叠面板：状态与关联 -->
<button type="button" aria-expanded="false" aria-controls="panel-1" id="trigger-1">
  高级设置
</button>
<div id="panel-1" role="region" aria-labelledby="trigger-1" hidden>
  <p>面板内容</p>
</div>

<!-- 动态结果播报：不打断用户，但会被读屏读出 -->
<div role="status" aria-live="polite">已保存 3 项修改</div>
```

```python
from dataclasses import dataclass, field

@dataclass
class A11yIssue:
    selector: str
    rule: str
    severity: str        # blocker / major / minor
    suggestion: str

def audit_nodes(nodes: list) -> list:
    """极简可访问性审计：检查常见阻断项。"""
    issues = []
    for node in nodes:
        tag = node.get("tag", "")
        if tag == "img" and "alt" not in node:
            issues.append(A11yIssue(node["id"], "图片缺少 alt", "blocker", "补充 alt 或标记为装饰"))
        if tag == "div" and node.get("clickable"):
            issues.append(A11yIssue(node["id"], "可点击的 div", "blocker", "改用 button 或补 role/tabindex/键盘事件"))
        if node.get("iconOnlyButton") and not node.get("ariaLabel"):
            issues.append(A11yIssue(node["id"], "图标按钮缺少名称", "major", "添加 aria-label"))
        if node.get("input") and not node.get("hasLabel"):
            issues.append(A11yIssue(node["id"], "输入框没有标签", "major", "用 label for 关联"))
        if node.get("outlineNone") and not node.get("focusVisibleStyle"):
            issues.append(A11yIssue(node["id"], "移除了焦点样式", "major", "用 :focus-visible 自定义"))
        if node.get("contrast", 10) < 4.5 and not node.get("largeText"):
            issues.append(A11yIssue(node["id"], "对比度不足", "major", "提高对比度到 4.5:1"))
    return issues

def summary(issues: list) -> dict:
    counts = {}
    for issue in issues:
        counts[issue.severity] = counts.get(issue.severity, 0) + 1
    return {
        "counts": counts,
        "blocking": [i.selector for i in issues if i.severity == "blocker"],
    }

nodes = [
    {"id": "hero-img", "tag": "img"},
    {"id": "card", "tag": "div", "clickable": True},
    {"id": "close-btn", "iconOnlyButton": True},
]
print(summary(audit_nodes(nodes)))
```

## 键盘与焦点速查

| 场景 | 要求 |
| --- | --- |
| Tab 顺序 | 与视觉顺序一致，避免 `tabindex` 正值 |
| 对话框 | 打开时焦点移入，关闭后回到触发元素，并限制焦点在内部 |
| 菜单与下拉 | 支持方向键、Esc 关闭、回车确认 |
| 跳过链接 | 长导航前列提供「跳到主内容」 |
| 焦点陷阱 | 只在模态组件内使用，不可全局 |
| 自定义组件 | 补齐 role、状态属性与键盘交互 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `div` 当按钮 | 键盘无法聚焦、读屏不识别 | 用 `<button>`，必要时补 role 与键盘事件 |
| 图标按钮不写名称 | 读屏只念「按钮」 | 加 `aria-label` |
| 把装饰图标暴露给读屏 | 噪声多 | 加 `aria-hidden="true"` |
| `outline: none` 去掉焦点 | 键盘用户迷路 | 用 `:focus-visible` 自定义样式 |
| 用颜色单独表示错误 | 色盲用户无法识别 | 同时给图标与文字提示 |
| 滥用 `role` 覆盖原生语义 | 行为与语义不符 | 优先原生元素，ARIA 只做补充 |
| 模态框不管理焦点 | 焦点跑到背景内容 | 焦点移入、循环、关闭后归还 |

## 自测清单

- [ ] 交互元素优先使用原生标签。
- [ ] 所有图标按钮都有可访问名称。
- [ ] 表单控件都有关联标签，错误提示可被播报。
- [ ] 键盘可完整操作且焦点可见。
- [ ] 对比度达标，信息不只靠颜色传达。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「可访问性、ARIA、无障碍」完成复述、实验和交付，每个结果都要能被别人检查。

先写最小语义结构，再调整布局与样式，最后检查键盘、窄屏和对比度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「可访问性与 ARIA 实战」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ARIA」是什么关系？

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
- 至少覆盖「可访问性」和「ARIA」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 本课小结

- 核心问题：「可访问性与 ARIA 实战」不是孤立术语，而是在「HTML 与 CSS」中解决一类具体问题。
- 关键关系：先分清「可访问性」与「ARIA」的职责，再理解「无障碍」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 安装依赖 | `python -m pip install -r requirements.txt` | 依赖安装完成，没有版本冲突 |
| 语法检查 | `python -m compileall .` | 所有模块编译通过 |
| 运行测试 | `python -m pytest -q` | 测试全部通过，失败用例数为 0 |
| 启动示例 | `python main.py` | 服务启动并输出监听地址 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条测试，其中包含一条非法输入或失败路径。
- [ ] 重复执行同一操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Accessibility & ARIA

**Summary:** Semantic-first, ARIA attributes and focus management.

**Category:** HTML & CSS  
**Level:** 进阶  
**Key terms:** 可访问性, ARIA, 无障碍, 键盘, 焦点, 对比度

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：现代浏览器（Chrome/Firefox/Safari）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：可访问性、ARIA、无障碍、键盘、焦点、对比度
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：可访问性与 ARIA 实战

### 核心场景

原生优先原则、常用 ARIA 属性与键盘焦点管理。 项目目标是把「可访问性、ARIA、无障碍、键盘、焦点、对比度」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | 可访问性、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。

<!-- project-delivery:v1 -->

## 项目交付物

### 建议仓库结构

```text
src/
tests/
docs/
README.md
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "a11y_aria",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「可访问性、ARIA、无障碍」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

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

> 本课主题：原生优先原则、常用 ARIA 属性与键盘焦点管理。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

