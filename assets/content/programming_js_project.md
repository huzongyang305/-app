# 实战：Vite + React 待办应用

![Vite 与 React 应用的结构](images/diagram_vite_react.webp)

![实战：Vite + React 待办应用](images/remaining_js_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：120 分钟

## 本节知识框架

**课程定位**：所属分类为「JavaScript」，课程主题为「实战：Vite + React 待办应用」，学习阶段为「高级」，建议用时 120 分钟。

**本课要解决的主问题**：组件状态、不可变更新、异步请求与构建部署。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「实战：Vite + React 待办应用」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「实战：Vite + React 待办应用」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「实战」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《模块化与工程化》

**学习位置**：本课位于《模块化与工程化》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《实战：Node.js + Express REST API》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释实战：Vite + React 待办应用解决了什么问题，而不是只背术语。
- 能说清 「实战」、「React」、「Vite」、「useState」 之间的关系，并分别举出一个例子。
- 能把 实战 放回「实战：Vite + React 待办应用」的知识体系，说明它和 React 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：组件状态、不可变更新、异步请求与构建部署。

**教材衔接：前置知识**

- 先完成上一课《模块化与工程化》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：实战、React、Vite。
- 如果 初始化 这一步看不懂，先记录具体卡点，再用 useState 复现一遍。

**教材衔接：本课小结**

前端工程 = **组件化 UI + 不可变状态 + 异步数据获取 + 构建工具**。把这个小应用跑通，再学 React/Vue 的进阶概念会顺畅很多。

## 核心概念定义

> 阅读约定：本课先给「实战：Vite + React 待办应用」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| prev.map | 关键点：状态用不可变更新（[...prev]、prev.map），不要直接 push；列表必须有稳定 key；事件处理用箭头函数避免 this 问题。 | 仅在「实战：Vite + React 待办应用」明确给出的输入、版本与资源条件下成立。 |
| npm run build | npm run build 产物是纯静态文件，可放 Nginx 或 CDN。 | 仅在「实战：Vite + React 待办应用」明确给出的输入、版本与资源条件下成立。 |
| 实战 | 实战：Vite + React 待办应用解决了什么问题，而不是只背术语。 | 仅在「实战：Vite + React 待办应用」明确给出的输入、版本与资源条件下成立。 |
| 构建脚本 | package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。 | 仅在「实战：Vite + React 待办应用」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「实战：Vite + React 待办应用」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「prev.map」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「npm run build」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「实战」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「实战：Vite + React 待办应用」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | prev.map | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | npm run build | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 实战 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「实战：Vite + React 待办应用」自己的示例验证。「实战：Vite + React 待办应用」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：上线清单**

1. `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN。
2. 接口地址用 `import.meta.env` 注入，不要硬编码。
3. 提交 `package-lock.json`，CI 用 `npm ci`。
4. 先做打包体积分析，再考虑代码分割。

**教材衔接：React 核心速查**

| 概念 | 说明 | 常见写法 |
| --- | --- | --- |
| 组件 | 返回 UI 的函数 | `function Item({ id }) { ... }` |
| Props | 父传子的只读数据 | 解构使用，避免直接修改 |
| State | 组件内部状态 | `const [list, setList] = useState([])` |
| 派生值 | 能从 state 算出来的值 | 直接计算，不要额外存 state |
| 副作用 | 请求、订阅、定时器 | `useEffect(() => { ... }, [deps])` |
| 引用 | 存 DOM 或可变值 | `useRef(null)` |
| 记忆化值 | 昂贵计算缓存 | `useMemo(() => compute(a), [a])` |
| 记忆化函数 | 传给子组件的稳定函数 | `useCallback(fn, [deps])` |
| 上下文 | 跨层级共享 | `createContext` + `useContext` |
| 列表渲染 | 渲染数组 | `list.map((item) => <Item key={item.id} />)` |
| 条件渲染 | 按条件显示 | `{loading ? <Spinner /> : <List />}` |

**教材衔接：工程化速查**

| 目的 | 命令 / 做法 |
| --- | --- |
| 开发调试 | `npm run dev`（Vite 热更新） |
| 生产构建 | `npm run build` |
| 本地预览产物 | `npm run preview` |
| 代码规范 | ESLint + Prettier，接入 CI |
| 单元测试 | Vitest + Testing Library |
| 端到端测试 | Playwright |
| 环境变量 | `.env` 中 `VITE_` 前缀才会暴露给前端 |

**教材衔接：版本与时效**

- 打包与运行时版本会共同影响 React，升级前先固定二者版本。
- 升级前确认 实战 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 实战 的版本变量，记录编译、测试与产物体积的变化。
- 升级后重点回归 实战 的默认值、警告信息与错误格式。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 实战 的版本变化。

**教材衔接：交付评审：评分表、决策记录与证据链**

「实战：Vite + React 待办应用」的验收不能只看功能能不能跑通。下面把正文里的交付物、验证命令和关键设计点整理成一张评审表，按表逐项留下证据即可。

### 一、「实战：Vite + React 待办应用」的交付物评分表

| 交付物 | 权重 | 合格线 | 需要的证据 |
| --- | ---: | --- | --- |
| 核心链路 | 34% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 测试与验收记录 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 运行与回滚说明 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |

「实战：Vite + React 待办应用」的评分先看证据再打分：任意一项只要拿不出可复现的命令或测试，该项按 0 分计，不允许用「基本完成」代替。

### 二、需要写下来的决策（ADR）

| 决策点 | 本课给出的做法 | 备选方案 | 代价与回滚 |
| --- | --- | --- | --- |
| 架构与数据流 | 用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控 | 不做「架构与数据流」，沿用最朴素的实现（需要额外补一次对照实验） | 若「架构与数据流」出问题，回到上一版本并按本课验收场景重跑 |

ADR 不需要长：每个决策三行就够——选了什么、放弃了什么、出问题怎么退。评审时只检查这三行是否和「实战：Vite + React 待办应用」的实际代码一致。

### 三、「实战：Vite + React 待办应用」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：

1. 一条从零开始的环境准备命令。
2. 一条跑通核心链路的命令及其完整输出。
3. 一条触发失败的命令，以及恢复后的验证结果。

把「实战：Vite + React 待办应用」的上表整理成一个 evidence/ 目录：每条命令一个文件，文件名带日期，内容包含版本、命令与输出。评审时直接按目录核对，不再口头确认。

### 四、「实战：Vite + React 待办应用」的验收指标

| 指标 | 目标值 | 测量方式 | 不达标时的动作 |
| --- | --- | --- | --- |
| 实战 的核心路径耗时与失败率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 资源占用峰值与回收情况 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 验收场景的通过率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |

指标必须能用一条命令或一次操作测出来；写不出测量方式的指标，在「实战：Vite + React 待办应用」的评审里一律视为未定义。

### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `js_project` |
| 本次范围 | 说明这一轮交付了「实战：Vite + React 待办应用」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

「实战：Vite + React 待办应用」评审结束后把这张表填完并归档；下一轮迭代直接读上一次的「未完成项」与「风险与回滚」，避免重复讨论同一个问题。
<!-- p1-project-review:end -->

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 实战、React | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「实战：Vite + React 待办应用」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「实战：Vite + React 待办应用」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:javascript`，用于动手验证《实战：Vite + React 待办应用》的机制；实验结论不替代概念定义与复杂度分析。

**教材衔接：零基础详解：从零做一个前端小项目**

### 一句话说清它是什么

一个能交付的前端项目要有：**能跑起来的开发环境、清晰的分层、可打包的构建、可验证的测试**。
下面用一个「图书检索页」把这些串起来。

### 用生活比喻理解

| 目录 | 比喻 | 说明 |
| --- | --- | --- |
| `src/api/` | 采购通道 | 只负责取数据 |
| `src/ui/` | 装修队 | 只负责渲染 |
| `src/state/` | 公告栏 | 共享状态 |
| `src/utils/` | 工具箱 | 纯函数 |
| `public/` | 门面 | 静态资源与入口 HTML |

### 推荐目录结构

```text
bookfinder/
  index.html
  package.json
  vite.config.js
  src/
    main.js          入口：只做组装
    api/books.js     数据获取
    state/store.js   状态与订阅
    ui/list.js       列表渲染
    ui/search.js     搜索框
    utils/format.js  纯函数
  tests/
    format.test.js
```

### 状态与视图分离

```javascript
// state/store.js
export function createStore(initial) {
  let state = initial;
  const listeners = new Set();

  return {
    get state() {
      return state;
    },
    setState(patch) {
      state = { ...state, ...patch };
      listeners.forEach((fn) => fn(state));
    },
    subscribe(fn) {
      listeners.add(fn);
      return () => listeners.delete(fn);      // 返回取消订阅
    },
  };
}
```

```javascript
// main.js —— 只做组装，不写业务细节
import { searchBooks } from "./api/books.js";
import { createStore } from "./state/store.js";
import { renderList } from "./ui/list.js";
import { bindSearch } from "./ui/search.js";

const store = createStore({ status: "idle", keyword: "", items: [], error: null });

store.subscribe((state) => renderList(document.querySelector("#list"), state));

bindSearch(document.querySelector("#search"), async (keyword) => {
  store.setState({ status: "loading", keyword, error: null });
  try {
    const items = await searchBooks(keyword);
    store.setState({ status: "success", items });
  } catch (error) {
    store.setState({ status: "error", error: error.message });
  }
});
```

### 四态渲染：别让页面白屏

```javascript
// ui/list.js
export function renderList(container, state) {
  switch (state.status) {
    case "idle":
      container.replaceChildren(text("输入关键词开始搜索"));
      return;
    case "loading":
      container.replaceChildren(text("加载中……"));
      return;
    case "error":
      container.replaceChildren(text(`出错了：${state.error}`));
      return;
    case "success":
      if (state.items.length === 0) {
        container.replaceChildren(text("没有找到相关书籍"));
        return;
      }
      container.replaceChildren(
        ...state.items.map((book) => {
          const li = document.createElement("li");
          li.textContent = `${book.title} — ${book.author}`;
          li.dataset.id = book.id;
          return li;
        }),
      );
  }
}

function text(message) {
  const p = document.createElement("p");
  p.textContent = message;
  return p;
}
```

**用 `textContent` 而不是 `innerHTML`**：数据来自接口，必须当作不可信内容。

### 数据请求：超时 + 错误归一化

```javascript
// api/books.js
export async function searchBooks(keyword, { timeout = 8000 } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeout);

  try {
    const res = await fetch(`/api/books?q=${encodeURIComponent(keyword)}`, {
      signal: controller.signal,
    });
    if (!res.ok) throw new Error(`服务返回 ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.items)) throw new Error("返回结构不符合预期");
    return data.items;
  } catch (error) {
    if (error.name === "AbortError") throw new Error("请求超时");
    throw error;
  } finally {
    clearTimeout(timer);
  }
}
```

### 纯函数与测试

```javascript
// utils/format.js
export const formatAuthors = (authors = []) =>
  authors.length > 2 ? `${authors[0]} 等 ${authors.length} 人` : authors.join("、");

export const truncate = (s, max = 40) =>
  s.length <= max ? s : `${s.slice(0, max - 1)}…`;
```

```javascript
// tests/format.test.js（vitest）
import { describe, expect, it } from "vitest";
import { formatAuthors, truncate } from "../src/utils/format.js";

describe("formatAuthors", () => {
  it("两位作者用顿号连接", () => {
    expect(formatAuthors(["A", "B"])).toBe("A、B");
  });

  it("超过两位显示等几人", () => {
    expect(formatAuthors(["A", "B", "C"])).toBe("A 等 3 人");
  });

  it("空数组返回空串", () => {
    expect(formatAuthors([])).toBe("");
  });
});

describe("truncate", () => {
  it("超长文本截断并加省略号", () => {
    expect(truncate("a".repeat(50), 10)).toHaveLength(10);
  });
});
```

### 构建与检查

```bash
npm ci
npm run lint
npm test -- --run
npm run build          # 产出 dist/
npm run preview        # 本地预览产物，而不是只看 dev
```

**务必预览 `dist`**：很多问题（相对路径、环境变量）只在产物里出现。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 入口文件写满业务 | 无法维护 | 入口只做组装 |
| 用 `innerHTML` 渲染接口数据 | XSS 风险 | 用 `textContent` |
| 没有四态 | 出错时白屏 | 加载、成功、空、失败都写 |
| 请求没有超时 | 一直转圈 | `AbortController` 加超时 |
| 只在 dev 测 | 上线才发现问题 | 预览 `dist` 产物 |
| 状态直接改对象 | 视图不更新 | 用统一的 `setState` |
| 忘记清理定时器 | 报错与内存泄漏 | `finally` 里 `clearTimeout` |
| 只测工具函数 | 交互出错没人发现 | 补组件或 E2E 测试 |

### 学完自测

- [ ] 能说出 api、state、ui、utils 各自的职责。
- [ ] 知道四态渲染为什么能消除白屏。
- [ ] 能说出请求超时的实现方式。
- [ ] 知道为什么必须预览构建产物。
- [ ] 能说出纯函数为什么最容易测试。

**教材衔接：项目专属规格：实战：Vite + React 待办应用**

### 核心场景

组件状态、不可变更新、异步请求与构建部署。 项目目标是把「实战、React、Vite、useState、useEffect」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | 实战、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：把 useState 的输入推到上下限，确认返回结果可解释。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：实战 回滚后数据一致，且能说明恢复时间和影响范围。

**教材衔接：项目交付物**

### 建议仓库结构

```text
src/
  routes/
  services/
  repositories/
tests/
package.json
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
  "project": "js_project",
  "scenario": "实战的正常路径",
  "input": {"case": "normal", "value": "useState"},
  "expected": {"ok": true, "checks": ["实战可复现", "React有记录"]},
  "failure_case": {"case": "React越界或缺失", "error": "validation_error"},
  "idempotency_key": "js_project-001"
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

> 项目验收围绕「实战、React、Vite」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《实战：Vite + React 待办应用》原文中的最小示例。先预测《实战：Vite + React 待办应用》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```bash
npm create vite@latest todo-app -- --template react-ts
cd todo-app
npm install
npm run dev          # 本地开发服务器，支持热更新
npm run build        # 产出 dist/ 静态文件
npm run preview      # 本地预览构建结果
```

**教材衔接：初始化**

```bash
npm create vite@latest todo-app -- --template react-ts
cd todo-app
npm install
npm run dev          # 本地开发服务器，支持热更新
npm run build        # 产出 dist/ 静态文件
npm run preview      # 本地预览构建结果
```

选 TypeScript 模板的理由：组件 props 与接口数据都有类型提示，重构更安全。

**教材衔接：组件与状态**

```tsx
import { useState } from 'react';
type Todo = { id: number; text: string; done: boolean };
export default function App() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [text, setText] = useState('');
  function addTodo() {
    const trimmed = text.trim();
    if (!trimmed) return;
    setTodos(prev => [...prev, { id: Date.now(), text: trimmed, done: false }]);
    setText('');
  }
  function toggle(id: number) {
    setTodos(prev => prev.map(t => (t.id === id ? { ...t, done: !t.done } : t)));
  }
  return (
    <main>
      <h1>待办清单</h1>
      <input value={text} onChange={e => setText(e.target.value)} placeholder="输入任务" />
      <button onClick={addTodo}>添加</button>
      <ul>
        {todos.map(todo => (
          <li key={todo.id} onClick={() => toggle(todo.id)}
              style={{ textDecoration: todo.done ? 'line-through' : 'none' }}>
            {todo.text}
          </li>
        ))}
      </ul>
    </main>
  );
}
```

关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题。

**教材衔接：请求后端数据**

```tsx
import { useEffect, useState } from 'react';
function useTodos() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    const controller = new AbortController();
    fetch('/api/todos', { signal: controller.signal })
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then(setTodos)
      .catch(err => { if (err.name !== 'AbortError') setError(err.message); })
      .finally(() => setLoading(false));
    return () => controller.abort();
  }, []);
  return { todos, loading, error };
}
```

**教材衔接：工程配置**

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "eslint .",
    "test": "vitest"
  }
}
```

用代理避免跨域：

```ts
export default defineConfig({
  server: { proxy: { '/api': 'http://localhost:8080' } },
});
```

**教材衔接：状态更新速查（不可变）**

```jsx
// 数组：增、删、改都返回新数组
setTodos((prev) => [...prev, newTodo]);
setTodos((prev) => prev.filter((t) => t.id !== id));
setTodos((prev) => prev.map((t) => (t.id === id ? { ...t, done: !t.done } : t)));

// 对象：展开后覆盖字段
setUser((prev) => ({ ...prev, name: "新名字" }));

// 嵌套结构：逐层展开，避免直接改原对象
setState((prev) => ({
  ...prev,
  profile: { ...prev.profile, age: 18 },
}));
```

**教材衔接：验证命令与预期输出**

「实战：Vite + React 待办应用」不能只看「能编译」，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 安装依赖 | `npm ci` | 按锁文件安装，无缺失依赖 |
| 运行测试 | `npm test` | 测试全部通过 |
| 构建 | `npm run build` | 生成 dist 目录且没有构建错误 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 测试覆盖 React 的核心规则，并包含一次可预期的失败。
- [ ] 重复执行 实战 的操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明 实战 所需的环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在副本上执行 React，并记录前后差异。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

## 时间/空间复杂度或性能分析

**复杂度证据**：「实战：Vite + React 待办应用」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「实战：Vite + React 待办应用」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「实战：Vite + React 待办应用」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《实战：Vite + React 待办应用》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「实战：Vite + React 待办应用」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `list.push(item)` 后 `setList(list)` | 引用没变，界面不刷新 | 用 `[...list, item]` 生成新数组 |
| 直接改 `user.name = "x"` | 组件不重渲染 | 用展开或不可变工具生成新对象 |
| 用数组下标当 `key` | 删除中间项后状态错位 | 用稳定唯一 ID 作 key |
| `useEffect` 依赖数组漏写变量 | 读到过期闭包值 | 写全依赖，或用函数式更新 |
| `useEffect` 里 `async` 直接回调 | 返回 Promise，React 报警告 | 内部再定义 async 函数并调用 |
| 忘记清理订阅或定时器 | 内存泄漏、重复请求 | `useEffect` 返回清理函数 |
| 在渲染函数里发请求 | 每次渲染都请求 | 放进 `useEffect` |
| 派生数据也存 state | 两份数据不同步 | 直接计算派生值 |
| `setCount(count + 1)` 连续调用两次 | 只加 1 | 用函数式更新 `setCount((c) => c + 1)` |
| 把 `useMemo` 当性能万能药 | 代码更复杂但没有收益 | 先测量，只在确有开销时使用 |

**教材衔接：故障现场**

### 现场 1：list.push(item) 后 setList(list)

**症状**：在《实战：Vite + React 待办应用》的复现场景中，引用没变，界面不刷新。

**根因**：当出现“list.push(item) 后 setList(list)”时，执行路径已经绕过了《实战：Vite + React 待办应用》的关键约束，最终以“引用没变，界面不刷新”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：Vite + React 待办应用》的问题，用 [...list, item] 生成新数组。

**验证**：先在《实战：Vite + React 待办应用》中记录“list.push(item) 后 setList(list)”留下的失败证据，再执行“用 [...list, item] 生成新数组”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：直接改 user.name = "x"

**症状**：在《实战：Vite + React 待办应用》的复现场景中，组件不重渲染。

**根因**：当出现“直接改 user.name = "x"”时，执行路径已经绕过了《实战：Vite + React 待办应用》的关键约束，最终以“组件不重渲染”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：Vite + React 待办应用》的问题，用展开或不可变工具生成新对象。

**验证**：在《实战：Vite + React 待办应用》中按“用展开或不可变工具生成新对象”调整后，从“直接改 user.name = "x"”的触发条件重放同一条路径，确认“组件不重渲染”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：用数组下标当 key

**症状**：在《实战：Vite + React 待办应用》的复现场景中，删除中间项后状态错位。

**根因**：当出现“用数组下标当 key”时，执行路径已经绕过了《实战：Vite + React 待办应用》的关键约束，最终以“删除中间项后状态错位”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：Vite + React 待办应用》的问题，用稳定唯一 ID 作 key。

**验证**：先在《实战：Vite + React 待办应用》中记录“用数组下标当 key”留下的失败证据，再执行“用稳定唯一 ID 作 key”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《模块化与工程化》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《实战：Node.js + Express REST API》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《模块化与工程化》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《实战：Node.js + Express REST API》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「实战：Vite + React 待办应用」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《实战：Vite + React 待办应用》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

这段 JavaScript 代码是「实战：Vite + React 待办应用」的示例片段，下面哪一项描述与它一致？

```javascript
// utils/format.js
export const formatAuthors = (authors = []) =>
  authors.length > 2 ? `${authors[0]} 等 ${authors.length} 人` : authors.join("、");

export const truncate = (s, max = 40) =>
  s.length <= max ? s : `${s.slice(0, max - 1)}…`;
```

A. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
B. 这段代码包含异常处理分支，失败时会走专门的补救路径。
C. 这段代码会读取外部输入，结果依赖传入的数据。
D. 这段代码会产生可观察的输出，运行后能看到结果。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「实战：Vite + React 待办应用」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「实战：Vite + React 待办应用」的正文示例，围绕实战、React、Vite展开；把输入或边界换成空值、极值或失败情况后，结论要以「实战：Vite + React 待办应用」的实际运行结果为准。

### 自测 2

列表渲染时 key 的作用是？

A. 帮助 diff 算法识别元素，避免复用错位
B. 只在列表渲染时声明元素的数据类型信息，但这会让抖动更明显
C. 排序
D. 设置样式

**参考答案**：帮助 diff 算法识别元素，避免复用错位

**解析**：在「实战：Vite + React 待办应用」里，帮助 diff 算法识别元素，避免复用错位。稳定唯一的 key 能让 React 正确复用节点，使用下标会在增删时出问题。把“帮助 diff 算法识别元素”代回「实战：Vite + React 待办应用」里“列表渲染时 key 的作用是”的例子核对，条件一旦改变，结论就要用实战、React、Vite重新推导。

### 自测 3

围绕“实战：Vite + React 待办应用”中的 实战、React、Vite，下列哪两项是本课强调的实践判断？

A. 只要 实战 的常规示例通过，就可以跳过边界与异常路径
B. 验证 React 时要固定版本并覆盖边界输入，结论才可复现
C. 把 React 的单次运行结果当成所有版本和规模都成立
D. 学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 React 时要固定版本并覆盖边界输入，结论才可复现；学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：在「实战：Vite + React 待办应用」里，学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程。结论应落在验证 React 时要固定版本并覆盖边界输入。在实战：Vite + React 待办应用里，判断 React 时要固定版本与边界输入，所以“验证 React 时要固定版本并覆盖边界输入，结论才可复现”才可复现。在「实战：Vite + React 待办应用」里，这道题要求区分概念与边界，验证 React 时要固定版本并覆盖边界输入，结论才可复现。

**教材衔接：复习与自测**

- [ ] 状态更新一律使用不可变写法。
- [ ] 列表渲染使用稳定唯一 key。
- [ ] `useEffect` 依赖写全，并有清理逻辑。
- [ ] 派生数据不额外存 state。
- [ ] 提交前跑 lint 与测试，环境变量不写进代码。

**教材衔接：动手练习**

> 本课练习重点：围绕「实战、React、Vite」完成复述、实验和交付，每个结果都要能被别人检查。

先在 Node 或浏览器复现 实战 的行为，再改写异步与错误路径，最后补测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 实战：Vite + React 待办应用解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「React」是什么关系？

验收标准：回答里必须出现 实战，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：五步记录要写进笔记——原例是 useState，改动落在实战上，结论必须能被他人在同一环境里复现。

### 练习 3：交付一个小结果（30 分钟）

在运行时里验证 React 的行为，记录三组输入与对应输出。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「实战」和「React」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```typescript
export default defineConfig({
  server: { proxy: { '/api': 'http://localhost:8080' } },
});
```

### 任务 2：只改一个条件

把「实战：Vite + React 待办应用」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把 实战 的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「实战：Vite + React 待办应用」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响实战。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 实战 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「React 中更新数组状态为什么不能直接 push？」的判断依据。
- [ ] 不看解析，能说出「列表渲染时 key 的作用是？」的判断依据。
- [ ] 不看解析，能说出「npm run build 之后产物是什么？」的判断依据。
- [ ] 不看解析，能说出「React 中 useEffect 的依赖数组传空数组表示？」的判断依据。
- [ ] 不看解析，能说出「Vite 相比传统打包器在开发时的优势是？」的判断依据。
- [ ] 至少运行一次 useState 的示例，记录输入、输出和 实战 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `prev.map` | 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题。 |
| `npm run build` | `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN。 |
| `实战` | 实战：Vite + React 待办应用解决了什么问题，而不是只背术语。 |
| `构建脚本` | package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。 |

## 考点精讲

### 考点 1：代码补全·实战

- **题目**：这段 JavaScript 代码是「实战：Vite + React 待办应用」的示例片段，下面哪一项描述与它一致？
- **判断依据**：在「实战：Vite + React 待办应用」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「实战：Vite + React 待办应用」的正文示例，围绕实战、React、Vite展开；把输入或边界换成空值、极值或失败情况后，结论要以「实战：Vite + React 待办应用」的实际运行结果为准。

### 考点 2：概念判断·实战

- **题目**：列表渲染时 key 的作用是？
- **判断依据**：在「实战：Vite + React 待办应用」里，帮助 diff 算法识别元素，避免复用错位。稳定唯一的 key 能让 React 正确复用节点，使用下标会在增删时出问题。把“帮助 diff 算法识别元素”代回「实战：Vite + React 待办应用」里“列表渲染时 key 的作用是”的例子核对，条件一旦改变，结论就要用实战、React、Vite重新推导。

### 考点 3：概念判断·实战

- **题目**：npm run build 之后产物是什么？
- **判断依据**：在「实战：Vite + React 待办应用」里，静态 HTML/CSS/JS 文件。Vite 产出 dist/ 静态资源，可直接部署到 Nginx 或 CDN。把“静态 HTML/CSS/JS 文件”代回「实战：Vite + React 待办应用」里“npm run build 之后产物是什么”的例子核对，条件一旦改变，结论就要用实战、React、Vite重新推导。

### 考点 4：多选辨析·实战

- **题目**：围绕“实战：Vite + React 待办应用”中的 实战、React、Vite，下列哪两项是本课强调的实践判断？
- **判断依据**：在「实战：Vite + React 待办应用」里，学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程。结论应落在验证 React 时要固定版本并覆盖边界输入。在实战：Vite + React 待办应用里，判断 React 时要固定版本与边界输入，所以“验证 React 时要固定版本并覆盖边界输入，结论才可复现”才可复现。在「实战：Vite + React 待办应用」里，这道题要求区分概念与边界，验证 React 时要固定版本并覆盖边界输入，结论才可复现。

### 考点 5：概念判断·实战

- **题目**：Vite 相比传统打包器在开发时的优势是？
- **判断依据**：在「实战：Vite + React 待办应用」里，基于浏览器原生 ESM 按需编译。开发阶段不整体打包，生产构建仍使用 Rollup 做优化打包。回到「实战：Vite + React 待办应用」的正文示例，用“Vite 相比传统打包器在开发时的优”走一遍实战、React、Vite的完整流程，能复现的结论才可以保留。

### 考点 6：填空·实战

- **题目**：补全代码：「实战：Vite + React 待办应用」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `const controller = new ____;`
- **判断依据**：空格应填写「AbortController」、「abortcontroller」。回到「实战：Vite + React 待办应用」的正文示例，用“补全代码”走一遍实战、React、Vite的完整流程，能复现的结论才可以保留。回到实战、React、Vite本身再看一遍：只有“AbortController”与题干“Vite”的前提一致，结论才成立。

## English Overview

**Title:** Project: React Todo App

**Summary:** Components, immutable state, async data and build.

**Category:** JavaScript
**Level:** 高级
**Key terms:** 实战, React, Vite, useState, useEffect

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Node.js 22+ / 现代浏览器
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、React、Vite、useState、useEffect
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**Project: React Todo App** focuses on Components, immutable state, async data and build.

### Learning Outcomes

- Explain what **Project: React Todo App** solves and when it should be used.

### Glossary

- Topic: **Project: React Todo App**
- Related terms: 实战, React, Vite, useState

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 初始化 | 初始化 |
| 组件与状态 | 组件与状态 |
| 请求后端数据 | 请求后端数据 |
| 工程配置 | 工程配置 |
| 上线清单 | 上线清单 |
| 本课小结 | Summary |
| React 核心速查 | React 核心速查 |
| 状态更新速查（不可变） | 状态更新速查（不可变） |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN Promise](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Promise) | Promise 与异步链 |
| [MDN JavaScript 指南](https://developer.mozilla.org/docs/Web/JavaScript/Guide) | 语言基础与浏览器 API |
| [Jest 文档](https://jestjs.io/docs/getting-started) | JavaScript 测试与断言 |

> 「实战：Vite + React 待办应用」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->
