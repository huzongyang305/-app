# Web Components 实战

![Web Components 的核心能力](images/diagram_web_components.webp)

![Web Components 实战](images/category_web_components.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：60 分钟

## 本节知识框架

**课程定位**：所属分类 `html_css`（HTML 与 CSS），课程主题 `Web Components 实战`，学习阶段 高级，建议用时 60 分钟。

本课主线：自定义元素生命周期、Shadow DOM 隔离与事件穿透。

**学完本课应当能够**
- 说清 `Web Components` 与 `Custom Elements` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `Shadow DOM` 的行为，记录输入、输出与失败条件。
- 遇到「在 `constructor` 里访问子节点或属性」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `Web Components`：先掌握 浏览器原生提供的可复用自定义元素标准集合，再用它解释 `Custom Elements` 为什么会出现。
2. `Custom Elements`：先掌握 定义和注册自定义 HTML 标签及其生命周期的 API，再用它解释 `Shadow DOM` 为什么会出现。
3. `Shadow DOM`：先掌握 给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏，再用它解释 `HTML Template` 为什么会出现。
4. `HTML Template`：先掌握 用 template 标签保存可克隆但不立即渲染的 DOM 片段，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「HTML 与 CSS」分类的第 14 课。先修内容：《PWA 与离线能力》。《PWA 与离线能力》里的 `PWA`、`ServiceWorker` 是本课的前提。相关或后续课程：《HTML 标签入门》。

### 完成判据

- **定义关**：不看正文也能说明 `Web Components` 是 浏览器原生提供的可复用自定义元素标准集合，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `Web Components 实战`，而不是只背结论。
- **示例关**：能运行或推演 `Web Components 实战` 的 `javascript` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `Web Components 实战` 示例里的 调用了 `createElement()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 在 `constructor` 里访问子节点或属性，记录现象并按 放到 `connectedCallback` 修复。
- **迁移关**：能把 `WebComponents`、`自定义元素`、`ShadowDOM`、`slot` 放进一个与 `Web Components 实战` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `Web Components 实战` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| Web Components | 浏览器原生提供的可复用自定义元素标准集合。 | 只在「浏览器原生提供的可复用自定义元素标准集合」这一前提下成立，换输入或换环境要重新验证。 |
| Custom Elements | 定义和注册自定义 HTML 标签及其生命周期的 API。 | 不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 |
| Shadow DOM | 给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏。 | 隔离级别与并发事务会影响可见性，换级别或换存储引擎后要重新验证。 |
| HTML Template | 用 template 标签保存可克隆但不立即渲染的 DOM 片段。 | 只在「用 template 标签保存可克隆但不立即渲染的 DOM 片段」这一前提下成立，换输入或换环境要重新验证。 |
| constructor | 元素创建时 | 易错：报错或取不到值；正确做法是放到 `connectedCallback`。 |
| connectedCallback | 插入文档 | 易错：报错或取不到值；正确做法是放到 `connectedCallback`。 |
| disconnectedCallback | 从文档移除 | 易错：内存泄漏；正确做法是成对绑定与解绑。 |
| attributeChangedCallback | 监听属性变化 | 只在「监听属性变化」这一前提下成立，换输入或换环境要重新验证。 |
| adoptedCallback | 移动到新文档 | 只在「移动到新文档」这一前提下成立，换输入或换环境要重新验证。 |

## 原理与运行机制

### 机制总览

**教材衔接：四大组成速查**

| 技术 | 作用 |
| --- | --- |
| 自定义元素 | 通过 `customElements.define` 注册新标签 |
| Shadow DOM | 封装内部结构与样式，隔离外部 CSS |
| `<template>` | 声明可复用的 DOM 片段，克隆后使用 |
| `<slot>` | 允许外部插入内容（内容分发） |

核心价值：**框架无关、样式隔离、可长期维护**——适合做设计系统与跨项目复用的基础组件。

**教材衔接：样式隔离与定制速查**

| 需求 | 手段 |
| --- | --- |
| 外部控制主题 | CSS 自定义属性（变量可穿透 Shadow） |
| 暴露指定内部结构给外部改样式 | `part="name"` + `::part(name)` |
| 插槽内容样式 | `::slotted(selector)` |
| 组件自身样式 | `:host`、`:host([attr])` |
| 全局样式覆盖 | 默认隔离，需用变量或 `::part` 显式开放 |

**教材衔接：交付评审：评分表、决策记录与证据链**



### 三、「Web Components 实战」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：


### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `web_components` |
| 本次范围 | 说明这一轮交付了「Web Components 实战」的哪些部分 |
| 未完成项 | 列出与 WebComponents 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

### 机制拆解：每一步的输入、动作与输出

#### 1. `Web Components`
- 输入：`WebComponents`；本步把 浏览器原生提供的可复用自定义元素标准集合 当作判断规则。
- 动作：围绕 `Web Components` 保留中间状态，并记录它与 `Custom Elements` 的对应关系。
- 输出：`Custom Elements`，它可以被下一段代码、测试或记录继续使用。
- `Web Components` 的失败条件：只在「浏览器原生提供的可复用自定义元素标准集合」这一前提下成立，换输入或换环境要重新验证。

#### 2. `Custom Elements`
- 输入：`Web Components`；本步把 定义和注册自定义 HTML 标签及其生命周期的 API 当作判断规则。
- 动作：围绕 `Custom Elements` 保留中间状态，并记录它与 `Shadow DOM` 的对应关系。
- 输出：`Shadow DOM`，它可以被下一段代码、测试或记录继续使用。
- `Custom Elements` 的失败条件：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

#### 3. `Shadow DOM`
- 输入：`Custom Elements`；本步把 给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏 当作判断规则。
- 动作：围绕 `Shadow DOM` 保留中间状态，并记录它与 `HTML Template` 的对应关系。
- 输出：`HTML Template`，它可以被下一段代码、测试或记录继续使用。
- `Shadow DOM` 的失败条件：隔离级别与并发事务会影响可见性，换级别或换存储引擎后要重新验证。

#### 4. `HTML Template`
- 输入：`Shadow DOM`；本步把 用 template 标签保存可克隆但不立即渲染的 DOM 片段 当作判断规则。
- 动作：围绕 `HTML Template` 保留中间状态，并记录它与 `createElement` 的对应关系。
- 输出：`createElement`，它可以被下一段代码、测试或记录继续使用。
- `HTML Template` 的失败条件：只在「用 template 标签保存可克隆但不立即渲染的 DOM 片段」这一前提下成立，换输入或换环境要重新验证。

### 示例中的可观察事实

1. 调用了 `createElement()`；它对应的课程主题是 `Web Components 实战`。
2. 调用了 `var()`；它对应的课程主题是 `Web Components 实战`。
3. 调用了 `host()`；它对应的课程主题是 `Web Components 实战`。
4. 调用了 `translateY()`；它对应的课程主题是 `Web Components 实战`。
5. 调用了 `observedAttributes()`；它对应的课程主题是 `Web Components 实战`。
6. 调用了 `constructor()`；它对应的课程主题是 `Web Components 实战`。
7. 调用了 `super()`；它对应的课程主题是 `Web Components 实战`。
8. 调用了 `attachShadow()`；它对应的课程主题是 `Web Components 实战`。

### 复现实验记录

- 环境：`Web Components 实战` 使用 `javascript` 示例，固定 `WebComponents`、`自定义元素`、`ShadowDOM`、`slot` 作为第一组条件。
- 首轮输入：先确认 调用了 `createElement()`，预测 `Web Components` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `WebComponents`，观察 `HTML Template` 是否仍满足定义。
- 失败注入：复现 在 `constructor` 里访问子节点或属性，确认现象是 报错或取不到值。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `Web Components 实战` 时才能区分概念错误与实现错误。

## 典型应用场景

**教材衔接：项目专属规格：Web Components 实战**

### 核心场景

自定义元素生命周期、Shadow DOM 隔离与事件穿透。 项目目标是把「WebComponents、自定义元素、ShadowDOM、slot、设计系统」落实为可运行、可测试、可回滚的交付物。



### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：把 createElement 的输入推到上下限，确认返回结果可解释。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：撤掉 createElement 的变更后，数据与资源都回到变更前的状态。

**教材衔接：项目交付物**

### 建议仓库结构

```text
src/
tests/
docs/
README.md
```


### 验收数据

```json
{
  "project": "web_components",
  "scenario": "WebComponents的正常路径",
  "input": {"case": "normal", "value": "createElement"},
  "expected": {"ok": true, "checks": ["WebComponents可复现", "自定义元素有记录"]},
  "failure_case": {"case": "自定义元素越界或缺失", "error": "validation_error"},
  "idempotency_key": "web_components-001"
}
```

### 复盘模板

- **在 `constructor` 里访问子节点或属性**：典型现象是报错或取不到值；正确做法是放到 `connectedCallback`。
- **元素名不用连字符**：典型现象是注册失败；正确做法是必须形如 `my-component`。
- **重复注册同名元素**：典型现象是抛错；正确做法是注册前判断或集中注册。
- **`disconnectedCallback` 不解绑事件**：典型现象是内存泄漏；正确做法是成对绑定与解绑。

### 最小验证场景

- 准备：保留 `javascript` 示例的原始输入，先记录 `Web Components 实战` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `createElement()`，再改变一个与 `Web Components` 相关的条件。
- 判定：新结果与 `Web Components 实战` 的基线不同不等于错误；只有当差异破坏了 `Web Components` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `Web Components` 时，先满足它的定义：浏览器原生提供的可复用自定义元素标准集合；只在「浏览器原生提供的可复用自定义元素标准集合」这一前提下成立，换输入或换环境要重新验证。
- 使用 `Custom Elements` 时，先满足它的定义：定义和注册自定义 HTML 标签及其生命周期的 API；不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。
- 使用 `Shadow DOM` 时，先满足它的定义：给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏；隔离级别与并发事务会影响可见性，换级别或换存储引擎后要重新验证。
- 使用 `HTML Template` 时，先满足它的定义：用 template 标签保存可克隆但不立即渲染的 DOM 片段；只在「用 template 标签保存可克隆但不立即渲染的 DOM 片段」这一前提下成立，换输入或换环境要重新验证。

## 代码/协议/SQL 示例

### 最小可验证示例

```javascript
// lesson-card.js：带 Shadow DOM 与属性监听的卡片组件
const template = document.createElement("template");
template.innerHTML = `
  <style>
    :host {
      display: block;
      --card-radius: var(--radius-md, 8px);
    }
    :host([hidden]) { display: none; }
    .card {
      background: var(--color-surface, #fff);
      border-radius: var(--card-radius);
      padding: 16px;
      transition: transform 160ms ease;
    }
    .card:hover { transform: translateY(-2px); }
    .title { font-weight: 600; margin: 0 0 4px; }
    .meta { color: #64748b; font-size: 0.875rem; margin: 0; }
  </style>
  <article class="card" part="card">
    <h3 class="title"><slot name="title">未命名课程</slot></h3>
    <p class="meta"><slot name="meta"></slot></p>
  </article>
`;

class LessonCard extends HTMLElement {
  static get observedAttributes() {
    return ["minutes", "disabled"];
  }

  constructor() {
    super();
    this.attachShadow({ mode: "open" });        // open 便于调试，closed 更严格
    this.shadowRoot.appendChild(template.content.cloneNode(true));
  }

  connectedCallback() {
    if (!this.hasAttribute("role")) this.setAttribute("role", "listitem");
    this.addEventListener("click", this.#onClick);
  }

  disconnectedCallback() {
    // 必须解绑，避免内存泄漏
    this.removeEventListener("click", this.#onClick);
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (oldValue === newValue) return;
    if (name === "minutes") {
      this.shadowRoot.querySelector(".meta").textContent = `${newValue} 分钟`;
    }
    if (name === "disabled") {
      this.setAttribute("aria-disabled", String(newValue !== null));
    }
  }

  #onClick = () => {
    if (this.hasAttribute("disabled")) return;
    this.dispatchEvent(
      new CustomEvent("lesson-open", {
        bubbles: true,      // 允许父级监听
        composed: true,     // 穿透 Shadow 边界
        detail: { id: this.getAttribute("lesson-id") },
      }),
    );
  };
}

customElements.define("lesson-card", LessonCard);
```

**教材衔接：验证命令与预期输出**

「Web Components 实战」不能只看「能编译」，还要能按固定命令复现结果。下表给出最低验证集：

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条 WebComponents 相关测试，其中一条是非法输入或失败路径。
- [ ] 连续两次触发 自定义元素，检查数据与计数是否被重复累加。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 交付说明包含版本、启动、验证与回滚四部分。

### 回归与回滚

1. 先在可丢弃的目录或临时库里跑 WebComponents，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

**教材衔接：原文最小示例**

**运行方式**：运行 `Web Components 实战` 的示例时，保存为 `.js` 后用 `node 文件名.js` 运行；涉及浏览器 API 的示例要放到页面里执行。

### 示例精读：先找证据，再改一个条件

1. 调用了 `createElement()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `var()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `host()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `translateY()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `observedAttributes()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `constructor()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `super()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `attachShadow()`；它出现在 `Web Components 实战` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `Web Components 实战` 中与 `Web Components` 对照：示例必须能支持 浏览器原生提供的可复用自定义元素标准集合，否则说明这一段还缺少实现或验证步骤。
- 在 `Web Components 实战` 中与 `Custom Elements` 对照：示例必须能支持 定义和注册自定义 HTML 标签及其生命周期的 API，否则说明这一段还缺少实现或验证步骤。
- 在 `Web Components 实战` 中与 `Shadow DOM` 对照：示例必须能支持 给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏，否则说明这一段还缺少实现或验证步骤。
- 在 `Web Components 实战` 中与 `HTML Template` 对照：示例必须能支持 用 template 标签保存可克隆但不立即渲染的 DOM 片段，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（Web Components 实战）**：浏览器渲染是关键路径：关注首屏时间、重排与重绘次数、资源体积。

**测量方法**：以 `Web Components 实战` 的 `WebComponents` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `Web Components 实战` 的 `WebComponents`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Web Components 实战` 的 `自定义元素`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Web Components 实战` 的 `ShadowDOM`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Web Components 实战` 的 `slot`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Web Components 实战` 的 `设计系统`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Web Components 实战` 中 `Web Components` 的边界：只在「浏览器原生提供的可复用自定义元素标准集合」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `Web Components 实战` 中 `Custom Elements` 的边界：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。达到边界时不要外推，必须重新测量。
- `Web Components 实战` 中 `Shadow DOM` 的边界：隔离级别与并发事务会影响可见性，换级别或换存储引擎后要重新验证。达到边界时不要外推，必须重新测量。
- `Web Components 实战` 中 `HTML Template` 的边界：只在「用 template 标签保存可克隆但不立即渲染的 DOM 片段」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `Web Components 实战` 的代码证据：先验证 调用了 `createElement()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 `constructor` 里访问子节点或属性 | 报错或取不到值 | 放到 `connectedCallback` |
| 元素名不用连字符 | 注册失败 | 必须形如 `my-component` |
| 重复注册同名元素 | 抛错 | 注册前判断或集中注册 |
| `disconnectedCallback` 不解绑事件 | 内存泄漏 | 成对绑定与解绑 |
| 直接给 Shadow 内部元素加外部类名 | 样式不生效 | 用 CSS 变量或 `::part` |
| 事件不设 `composed: true` | 跨 Shadow 边界收不到 | 明确是否需要穿透 |
| 在属性里传复杂对象 | 只能传字符串 | 用属性传 JSON 或直接设 JS 属性 |
| 用 `innerHTML` 插用户输入 | XSS 风险 | 用 `textContent` 或转义 |
| 在 constructor 里访问子节点或属性 | 报错或取不到值。 | 放到 connectedCallback。 |
| 事件不设 composed: true | 跨 Shadow 边界收不到。 | 明确是否需要穿透。 |

### 现场 1：在 `constructor` 里访问子节点或属性

**症状**：报错或取不到值。

**根因与修复**：放到 `connectedCallback`。

**自检**：在本课示例里复现「在 `constructor` 里访问子节点或属性」，改成放到 `connectedCallback`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：元素名不用连字符

**症状**：注册失败。

**根因与修复**：必须形如 `my-component`。

**自检**：在本课示例里复现「元素名不用连字符」，改成必须形如 `my-component`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：重复注册同名元素

**症状**：抛错。

**根因与修复**：注册前判断或集中注册。

**自检**：在本课示例里复现「重复注册同名元素」，改成注册前判断或集中注册后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：`disconnectedCallback` 不解绑事件

**症状**：内存泄漏。

**根因与修复**：成对绑定与解绑。

**自检**：在本课示例里复现「`disconnectedCallback` 不解绑事件」，改成成对绑定与解绑后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：直接给 Shadow 内部元素加外部类名

**症状**：样式不生效。

**根因与修复**：用 CSS 变量或 `::part`。

**自检**：在本课示例里复现「直接给 Shadow 内部元素加外部类名」，改成用 CSS 变量或 `::part`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：事件不设 `composed: true`

**症状**：跨 Shadow 边界收不到。

**根因与修复**：明确是否需要穿透。

**自检**：在本课示例里复现「事件不设 `composed: true`」，改成明确是否需要穿透后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：在属性里传复杂对象

**症状**：只能传字符串。

**根因与修复**：用属性传 JSON 或直接设 JS 属性。

**自检**：在本课示例里复现「在属性里传复杂对象」，改成用属性传 JSON 或直接设 JS 属性后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：用 `innerHTML` 插用户输入

**症状**：XSS 风险。

**根因与修复**：用 `textContent` 或转义。

**自检**：在本课示例里复现「用 `innerHTML` 插用户输入」，改成用 `textContent` 或转义后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：在 constructor 里访问子节点或属性

**症状**：报错或取不到值。

**根因与修复**：放到 connectedCallback。

**自检**：在本课示例里复现「在 constructor 里访问子节点或属性」，改成放到 connectedCallback后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《PWA 与离线能力》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《HTML 标签入门》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《PWA 与离线能力》 | 同分类中安排在本课之前，建议先完成其自测。 |

**教材衔接：与框架的关系**

| 维度 | Web Components | React / Vue 组件 |
| --- | --- | --- |
| 复用范围 | 跨框架、跨项目 | 同框架内 |
| 样式隔离 | Shadow DOM 原生隔离 | 依赖工具与约定 |
| 数据传递 | 属性与事件 | props 与状态 |
| 复杂度 | 需自己处理渲染与状态 | 框架提供响应式 |
| 适用 | 设计系统、嵌入式组件 | 业务应用界面 |

经验：**设计系统的底层组件适合做成 Web Components，业务页面继续用框架。**

- **先修**：`PWA 与离线能力`。本课默认这些内容已经掌握。
- **相关或后续**：`HTML 标签入门`。本课术语会在这些课程里继续使用。
- **术语归属**：`Web Components`、`Custom Elements`、`Shadow DOM` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《设计令牌与样式架构》也涉及 `设计系统`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `HTML 标签入门`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `PWA 与离线能力`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `Web Components` 与 `Custom Elements`：前者强调 浏览器原生提供的可复用自定义元素标准集合；后者强调 定义和注册自定义 HTML 标签及其生命周期的 API。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `Custom Elements` 与 `Shadow DOM`：前者强调 定义和注册自定义 HTML 标签及其生命周期的 API；后者强调 给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `Shadow DOM` 与 `HTML Template`：前者强调 给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏；后者强调 用 template 标签保存可克隆但不立即渲染的 DOM 片段。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `Web Components` 的操作性定义，并说明它与 `Custom Elements` 的区别。

**参考答案**：浏览器原生提供的可复用自定义元素标准集合。

`Custom Elements` 的定位是：定义和注册自定义 HTML 标签及其生命周期的 API；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「在 `constructor` 里访问子节点或属性」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是报错或取不到值；正确做法是放到 `connectedCallback`。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `javascript` 示例，把其中的 `"template"` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `javascript` 示例应当复现正文给出的结果；把 `"template"` 换成边界值后，如果结果改变或报错，先核对它是否满足 `Web Components 实战` 中`Web Components` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `javascript` 示例，说明它体现了`Web Components` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`Web Components` 的定义是 浏览器原生提供的可复用自定义元素标准集合，示例正是在实现这条定义。改动与 `Web Components` 有关的一个输入后，如果结果不再符合 `Web Components 实战` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `Web Components 实战` 的方法迁移到自己的项目：围绕 `Web Components` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「事件不设 composed: true」，它会导致跨 Shadow 边界收不到；检验方式是按明确是否需要穿透改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `Web Components` 与 `Custom Elements`：各写一行适用场景、一行失败表现。

**参考答案**：`Web Components` 的定义是浏览器原生提供的可复用自定义元素标准集合；`Custom Elements` 的定义是定义和注册自定义 HTML 标签及其生命周期的 API。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「在 `constructor` 里访问子节点或属性」引发的问题，请把“复现 报错或取不到值 → 保留证据 → 放到 `connectedCallback` → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按报错或取不到值复现；第二步记录输入、版本与完整报错；第三步按放到 `connectedCallback`只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `HTML Template`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：只在「用 template 标签保存可克隆但不立即渲染的 DOM 片段」这一前提下成立，换输入或换环境要重新验证。 同时要把 `HTML Template` 的定义 用 template 标签保存可克隆但不立即渲染的 DOM 片段 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `Web Components` → `Custom Elements` → `Shadow DOM` → `HTML Template` 的作用链。

**参考答案**：起点是 `Web Components` 的定义 浏览器原生提供的可复用自定义元素标准集合；中间每一步都保留可观察状态；终点由 `HTML Template` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `Web Components 实战` 中，现象是 跨 Shadow 边界收不到。请围绕 事件不设 composed: true 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 事件不设 composed: true，记录输入与完整错误；再按 明确是否需要穿透 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `Web Components 实战`：先给主问题，再按顺序说出 `Web Components`、`Custom Elements`、`Shadow DOM`、`HTML Template`，最后给一个失败案例。

**自评标准**：主问题必须对应 自定义元素生命周期、Shadow DOM 隔离与事件穿透；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Web Components` | 浏览器原生提供的可复用自定义元素标准集合。 |
| `Custom Elements` | 定义和注册自定义 HTML 标签及其生命周期的 API。 |
| `Shadow DOM` | 给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏。 |
| `HTML Template` | 用 template 标签保存可克隆但不立即渲染的 DOM 片段。 |

**术语关系**：`Web Components`（浏览器原生提供的可复用自定义元素标准集合） → `Custom Elements`（定义和注册自定义 HTML 标签及其生命周期的 API） → `Shadow DOM`（给元素附加隔离的 DOM 与样式作用域） → `HTML Template`（用 template 标签保存可克隆但不立即渲染的 DOM 片段）。

## 考点精讲

`Web Components 实战` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：注册自定义元素时，标签名必须满足？
- **正确项**：包含连字符
- **判断依据**：这道题检验本课主问题：自定义元素生命周期、Shadow DOM 隔离与事件穿透。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 2：第 2 题

- **题目**：为什么不应在 constructor 中访问子节点或属性？
- **正确项**：此时元素尚未插入文档
- **判断依据**：这道题检验本课主问题：自定义元素生命周期、Shadow DOM 隔离与事件穿透。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 3：第 3 题

- **题目**：围绕“Web Components 实战”中的 WebComponents、自定义元素、ShadowDOM，下列哪两项是本课强调的实践判断？
- **正确项**：学习 WebComponents 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 自定义元素 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `Web Components` 上：浏览器原生提供的可复用自定义元素标准集合。复习时把 `Web Components` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：按“Web Components 实战”中 WebComponents、自定义元素、ShadowDOM 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。
- **正确项**：先明确 WebComponents 的输入、输出与约束 → 写出最小示例并核对 自定义元素 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把“Web Components 实战”的结论写成可复现记录
- **判断依据**：这道题落在术语 `Web Components` 上：浏览器原生提供的可复用自定义元素标准集合。复习时把 `Web Components` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：组件被移除后必须做什么以避免内存泄漏？
- **正确项**：在 disconnectedCallback 中解绑事件并清理定时器
- **判断依据**：这道题检验本课主问题：自定义元素生命周期、Shadow DOM 隔离与事件穿透。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：`Web Components 实战` 的示例代码服务于“自定义元素生命周期、Shadow DOM 隔离与事件穿透。”。哪一条判断是正确的？
- **正确项**：包含连字符
- **判断依据**：这道题落在术语 `Web Components` 上：浏览器原生提供的可复用自定义元素标准集合。复习时把 `Web Components` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`Web Components`

- **要点**：浏览器原生提供的可复用自定义元素标准集合。
- **Web Components 的边界**：只在「浏览器原生提供的可复用自定义元素标准集合」这一前提下成立，换输入或换环境要重新验证。

### 考点 8：`Custom Elements`

- **要点**：定义和注册自定义 HTML 标签及其生命周期的 API。
- **Custom Elements 的边界**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 考点 9：`Shadow DOM`

- **要点**：给元素附加隔离的 DOM 与样式作用域，避免外部样式泄漏。
- **Shadow DOM 的边界**：隔离级别与并发事务会影响可见性，换级别或换存储引擎后要重新验证。

### 考点 10：`HTML Template`

- **要点**：用 template 标签保存可克隆但不立即渲染的 DOM 片段。
- **HTML Template 的边界**：只在「用 template 标签保存可克隆但不立即渲染的 DOM 片段」这一前提下成立，换输入或换环境要重新验证。

### 考点 11：排错——在 `constructor` 里访问子节点或属性

- **现象**：报错或取不到值。
- **处理**：放到 `connectedCallback`。

### 考点 12：排错——元素名不用连字符

- **现象**：注册失败。
- **处理**：必须形如 `my-component`。

### 考点 13：综合辨析——`Web Components` 与 `HTML Template`

- **辨析点**：`Web Components` 的定义是 浏览器原生提供的可复用自定义元素标准集合；`HTML Template` 的定义是 用 template 标签保存可克隆但不立即渲染的 DOM 片段。
- **答题要求**：面对 `Web Components 实战` 的题目，先判断描述的是 `Web Components` 还是 `HTML Template`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 报错或取不到值，而不是只写“程序有错”。
- **证据分**：保留触发 在 `constructor` 里访问子节点或属性 的输入、版本和错误原文。
- **修复分**：按 放到 `connectedCallback` 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：现代浏览器（Chrome/Firefox/Safari）
；本课聚焦 WebComponents。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：WebComponents、自定义元素、ShadowDOM、slot、设计系统
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-08-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：WebComponents、自定义元素、ShadowDOM、slot、设计系统。

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN DOM](https://developer.mozilla.org/docs/Web/API/Document_Object_Model) | DOM 树与浏览器 API |
| [W3C Web 标准](https://www.w3.org/TR/) | HTML、CSS 与 Web 标准 |
| [MDN CSS](https://developer.mozilla.org/docs/Web/CSS) | CSS 布局、选择器与动画 |

| [本课术语索引：Web Components 实战](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「Web Components 实战」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->