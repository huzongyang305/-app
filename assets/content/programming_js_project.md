# 实战：Vite + React 待办应用

![Vite 与 React 应用的结构](images/diagram_vite_react.webp)

![实战：Vite + React 待办应用](images/remaining_js_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：100 分钟

## 本节知识框架

**课程定位**：所属分类 `javascript`（JavaScript），课程主题 `实战：Vite + React 待办应用`，学习阶段 高级，建议用时 120 分钟。

本课主线：组件状态、不可变更新、异步请求与构建部署。

**学完本课应当能够**
- 说清 `prev.map` 与 `npm run build` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `实战` 的行为，记录输入、输出与失败条件。
- 遇到「入口文件写满业务」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `prev.map`：先掌握 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题，再用它解释 `npm run build` 为什么会出现。
2. `npm run build`：先掌握 `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN，再用它解释 `实战` 为什么会出现。
3. `实战`：先掌握 实战：Vite + React 待办应用解决了什么问题，而不是只背术语，再用它解释 `构建脚本` 为什么会出现。
4. `构建脚本`：先掌握 package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「JavaScript」分类的第 16 课。先修内容：《模块化与工程化》。《模块化与工程化》里的 `this`、`.mjs` 是本课的前提。相关或后续课程：《实战：Node.js + Express REST API》。

### 完成判据

- **定义关**：不看正文也能说明 `prev.map` 是 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`，列表必须有稳定 `key`，事件处理用箭头函数避免 `this` 问题，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `实战：Vite + React 待办应用`，而不是只背结论。
- **示例关**：能运行或推演 `实战：Vite + React 待办应用` 的 `text` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `实战：Vite + React 待办应用` 示例里的 调用了 `createStore()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 入口文件写满业务，记录现象并按 入口只做组装 修复。
- **迁移关**：能把 `实战`、`React`、`Vite`、`useState` 放进一个与 `实战：Vite + React 待办应用` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `实战：Vite + React 待办应用` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| prev.map | 关键点：状态用不可变更新（[...prev]、prev.map），不要直接 push；列表必须有稳定 key；事件处理用箭头函数避免 this 问题。 | 缓存与状态残留会让结果过期，先明确失效策略再判断正确性。 |
| npm run build | npm run build 产物是纯静态文件，可放 Nginx 或 CDN。 | 静态检查只在编译期成立，运行期输入仍需校验。 |
| 实战 | 实战：Vite + React 待办应用解决了什么问题，而不是只背术语。 | 只在「实战：Vite + React 待办应用解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。 |
| 构建脚本 | package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。 | 只在「package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口」这一前提下成立，换输入或换环境要重新验证。 |

## 原理与运行机制

### 机制总览

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



### 三、「实战：Vite + React 待办应用」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：


### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `js_project` |
| 本次范围 | 说明这一轮交付了「实战：Vite + React 待办应用」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

### 机制拆解：每一步的输入、动作与输出

#### 1. `prev.map`
- 输入：`实战`；本步把 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题 当作判断规则。
- 动作：围绕 `prev.map` 保留中间状态，并记录它与 `npm run build` 的对应关系。
- 输出：`npm run build`，它可以被下一段代码、测试或记录继续使用。
- `prev.map` 的失败条件：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。

#### 2. `npm run build`
- 输入：`prev.map`；本步把 `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN 当作判断规则。
- 动作：围绕 `npm run build` 保留中间状态，并记录它与 `实战` 的对应关系。
- 输出：`实战`，它可以被下一段代码、测试或记录继续使用。
- `npm run build` 的失败条件：静态检查只在编译期成立，运行期输入仍需校验。

#### 3. `实战`
- 输入：`npm run build`；本步把 实战：Vite + React 待办应用解决了什么问题，而不是只背术语 当作判断规则。
- 动作：围绕 `实战` 保留中间状态，并记录它与 `构建脚本` 的对应关系。
- 输出：`构建脚本`，它可以被下一段代码、测试或记录继续使用。
- `实战` 的失败条件：只在「实战：Vite + React 待办应用解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。

#### 4. `构建脚本`
- 输入：`实战`；本步把 package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口 当作判断规则。
- 动作：围绕 `构建脚本` 保留中间状态，并记录它与 `createStore` 的对应关系。
- 输出：`createStore`，它可以被下一段代码、测试或记录继续使用。
- `构建脚本` 的失败条件：只在「package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口」这一前提下成立，换输入或换环境要重新验证。

### 示例中的可观察事实

1. 调用了 `createStore()`；它对应的课程主题是 `实战：Vite + React 待办应用`。
2. 调用了 `Set()`；它对应的课程主题是 `实战：Vite + React 待办应用`。
3. 调用了 `state()`；它对应的课程主题是 `实战：Vite + React 待办应用`。
4. 调用了 `setState()`；它对应的课程主题是 `实战：Vite + React 待办应用`。
5. 调用了 `forEach()`；它对应的课程主题是 `实战：Vite + React 待办应用`。
6. 调用了 `subscribe()`；它对应的课程主题是 `实战：Vite + React 待办应用`。
7. 调用了 `add()`；它对应的课程主题是 `实战：Vite + React 待办应用`。
8. 调用了 `delete()`；它对应的课程主题是 `实战：Vite + React 待办应用`。

### 复现实验记录

- 环境：`实战：Vite + React 待办应用` 使用 `text` 示例，固定 `实战`、`React`、`Vite`、`useState` 作为第一组条件。
- 首轮输入：先确认 调用了 `createStore()`，预测 `prev.map` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `实战`，观察 `构建脚本` 是否仍满足定义。
- 失败注入：复现 入口文件写满业务，确认现象是 无法维护。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `实战：Vite + React 待办应用` 时才能区分概念错误与实现错误。

## 典型应用场景

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

- **入口文件写满业务**：典型现象是无法维护；正确做法是入口只做组装。
- **用 `innerHTML` 渲染接口数据**：典型现象是XSS 风险；正确做法是用 `textContent`。
- **没有四态**：典型现象是出错时白屏；正确做法是加载、成功、空、失败都写。
- **请求没有超时**：典型现象是一直转圈；正确做法是`AbortController` 加超时。

### 最小验证场景

- 准备：保留 `text` 示例的原始输入，先记录 `实战：Vite + React 待办应用` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `createStore()`，再改变一个与 `prev.map` 相关的条件。
- 判定：新结果与 `实战：Vite + React 待办应用` 的基线不同不等于错误；只有当差异破坏了 `prev.map` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `prev.map` 时，先满足它的定义：关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题；缓存与状态残留会让结果过期，先明确失效策略再判断正确性。
- 使用 `npm run build` 时，先满足它的定义：`npm run build` 产物是纯静态文件，可放 Nginx 或 CDN；静态检查只在编译期成立，运行期输入仍需校验。
- 使用 `实战` 时，先满足它的定义：实战：Vite + React 待办应用解决了什么问题，而不是只背术语；只在「实战：Vite + React 待办应用解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。
- 使用 `构建脚本` 时，先满足它的定义：package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口；只在「package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口」这一前提下成立，换输入或换环境要重新验证。

## 代码/协议/SQL 示例

### 最小可验证示例

```bash
npm create vite@latest todo-app -- --template react-ts
cd todo-app
npm install
npm run dev          # 本地开发服务器，支持热更新
npm run build        # 产出 dist/ 静态文件
npm run preview      # 本地预览构建结果
```

**教材衔接：初始化**

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

### 示例精读：先找证据，再改一个条件

1. 调用了 `createStore()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `Set()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `state()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `setState()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `forEach()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `subscribe()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `add()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `delete()`；它出现在 `实战：Vite + React 待办应用` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `实战：Vite + React 待办应用` 中与 `prev.map` 对照：示例必须能支持 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：Vite + React 待办应用` 中与 `npm run build` 对照：示例必须能支持 `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：Vite + React 待办应用` 中与 `实战` 对照：示例必须能支持 实战：Vite + React 待办应用解决了什么问题，而不是只背术语，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：Vite + React 待办应用` 中与 `构建脚本` 对照：示例必须能支持 package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（实战：Vite + React 待办应用）**：事件循环与 DOM 操作是瓶颈来源：记录脚本执行时间、长任务与主线程阻塞时长。

**本课特有开销（实战：Vite + React 待办应用 · 实战）**：小文件看元数据开销，大文件看吞吐，两者要分别测量。

**测量方法**：以 `实战：Vite + React 待办应用` 的 `实战` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `实战：Vite + React 待办应用` 的 `实战`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Vite + React 待办应用` 的 `React`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Vite + React 待办应用` 的 `Vite`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Vite + React 待办应用` 的 `useState`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Vite + React 待办应用` 的 `useEffect`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：Vite + React 待办应用` 中 `prev.map` 的边界：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。达到边界时不要外推，必须重新测量。
- `实战：Vite + React 待办应用` 中 `npm run build` 的边界：静态检查只在编译期成立，运行期输入仍需校验。达到边界时不要外推，必须重新测量。
- `实战：Vite + React 待办应用` 中 `实战` 的边界：只在「实战：Vite + React 待办应用解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `实战：Vite + React 待办应用` 中 `构建脚本` 的边界：只在「package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `实战：Vite + React 待办应用` 的代码证据：先验证 调用了 `createStore()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 入口文件写满业务 | 无法维护 | 入口只做组装 |
| 用 `innerHTML` 渲染接口数据 | XSS 风险 | 用 `textContent` |
| 没有四态 | 出错时白屏 | 加载、成功、空、失败都写 |
| 请求没有超时 | 一直转圈 | `AbortController` 加超时 |
| 只在 dev 测 | 上线才发现问题 | 预览 `dist` 产物 |
| 状态直接改对象 | 视图不更新 | 用统一的 `setState` |
| 忘记清理定时器 | 报错与内存泄漏 | `finally` 里 `clearTimeout` |
| 只测工具函数 | 交互出错没人发现 | 补组件或 E2E 测试 |
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
| list.push(item) 后 setList(list) | 引用没变，界面不刷新。 | 用 [...list, item] 生成新数组。 |
| 直接改 user.name = "x" | 组件不重渲染。 | 用展开或不可变工具生成新对象。 |
| 用数组下标当 key | 删除中间项后状态错位。 | 用稳定唯一 ID 作 key。 |

### 现场 1：入口文件写满业务

**症状**：无法维护。

**根因与修复**：入口只做组装。

**自检**：在本课示例里复现「入口文件写满业务」，改成入口只做组装后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：用 `innerHTML` 渲染接口数据

**症状**：XSS 风险。

**根因与修复**：用 `textContent`。

**自检**：在本课示例里复现「用 `innerHTML` 渲染接口数据」，改成用 `textContent`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：没有四态

**症状**：出错时白屏。

**根因与修复**：加载、成功、空、失败都写。

**自检**：在本课示例里复现「没有四态」，改成加载、成功、空、失败都写后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：请求没有超时

**症状**：一直转圈。

**根因与修复**：`AbortController` 加超时。

**自检**：在本课示例里复现「请求没有超时」，改成`AbortController` 加超时后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：只在 dev 测

**症状**：上线才发现问题。

**根因与修复**：预览 `dist` 产物。

**自检**：在本课示例里复现「只在 dev 测」，改成预览 `dist` 产物后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：状态直接改对象

**症状**：视图不更新。

**根因与修复**：用统一的 `setState`。

**自检**：在本课示例里复现「状态直接改对象」，改成用统一的 `setState`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：忘记清理定时器

**症状**：报错与内存泄漏。

**根因与修复**：`finally` 里 `clearTimeout`。

**自检**：在本课示例里复现「忘记清理定时器」，改成`finally` 里 `clearTimeout`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：只测工具函数

**症状**：交互出错没人发现。

**根因与修复**：补组件或 E2E 测试。

**自检**：在本课示例里复现「只测工具函数」，改成补组件或 E2E 测试后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`list.push(item)` 后 `setList(list)`

**症状**：引用没变，界面不刷新。

**根因与修复**：用 `[...list, item]` 生成新数组。

**自检**：在本课示例里复现「`list.push(item)` 后 `setList(list)`」，改成用 `[...list, item]` 生成新数组后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`模块化与工程化`。本课默认这些内容已经掌握。
- **相关或后续**：`实战：Node.js + Express REST API`。本课术语会在这些课程里继续使用。
- **术语归属**：`prev.map`、`npm run build`、`实战` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《模块化与工程化》也涉及 `Vite`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `模块化与工程化`：共同关键词 `Vite`。
- `实战：Node.js + Express REST API`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `prev.map` 与 `npm run build`：前者强调 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题；后者强调 `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `npm run build` 与 `实战`：前者强调 `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN；后者强调 实战：Vite + React 待办应用解决了什么问题，而不是只背术语。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `实战` 与 `构建脚本`：前者强调 实战：Vite + React 待办应用解决了什么问题，而不是只背术语；后者强调 package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `prev.map` 的操作性定义，并说明它与 `npm run build` 的区别。

**参考答案**：关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题。

`npm run build` 的定位是：`npm run build` 产物是纯静态文件，可放 Nginx 或 CDN；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「入口文件写满业务」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是无法维护；正确做法是入口只做组装。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `text` 示例，改动其中一个输入后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `text` 示例应当复现正文给出的结果；改动输入后，如果结果改变或报错，先核对它是否满足 `实战：Vite + React 待办应用` 中`prev.map` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `text` 示例，说明它体现了`prev.map` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`prev.map` 的定义是 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`，列表必须有稳定 `key`，事件处理用箭头函数避免 `this` 问题，示例正是在实现这条定义。改动与 `prev.map` 有关的一个输入后，如果结果不再符合 `实战：Vite + React 待办应用` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `实战：Vite + React 待办应用` 的方法迁移到自己的项目：围绕 `prev.map` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「用数组下标当 key」，它会导致删除中间项后状态错位；检验方式是按用稳定唯一 ID 作 key改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `prev.map` 与 `npm run build`：各写一行适用场景、一行失败表现。

**参考答案**：`prev.map` 的定义是关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题；`npm run build` 的定义是`npm run build` 产物是纯静态文件，可放 Nginx 或 CDN。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「入口文件写满业务」引发的问题，请把“复现 无法维护 → 保留证据 → 入口只做组装 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按无法维护复现；第二步记录输入、版本与完整报错；第三步按入口只做组装只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `构建脚本`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：只在「package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口」这一前提下成立，换输入或换环境要重新验证。 同时要把 `构建脚本` 的定义 package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `prev.map` → `npm run build` → `实战` → `构建脚本` 的作用链。

**参考答案**：起点是 `prev.map` 的定义 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题；中间每一步都保留可观察状态；终点由 `构建脚本` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `实战：Vite + React 待办应用` 中，现象是 删除中间项后状态错位。请围绕 用数组下标当 key 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 用数组下标当 key，记录输入与完整错误；再按 用稳定唯一 ID 作 key 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `实战：Vite + React 待办应用`：先给主问题，再按顺序说出 `prev.map`、`npm run build`、`实战`、`构建脚本`，最后给一个失败案例。

**自评标准**：主问题必须对应 组件状态、不可变更新、异步请求与构建部署；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `prev.map` | 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题。 |
| `npm run build` | `npm run build` 产物是纯静态文件，可放 Nginx 或 CDN。 |
| `实战` | 实战：Vite + React 待办应用解决了什么问题，而不是只背术语。 |
| `构建脚本` | package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。 |

**术语关系**：`prev.map`（关键点：状态用不可变更新（`[...prev]`、`prev.map`）） → `npm run build`（`npm run build` 产物是纯静态文件） → `实战`（实战：Vite + React 待办应用解决了什么问题） → `构建脚本`（package.json 的 scripts 字段把常用命令命名化）。

## 考点精讲

`实战：Vite + React 待办应用` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：代码语言为 `javascript`，选自 `实战：Vite + React 待办应用` 的 `prev.map` 部分。课程问题为组件状态、不可变更新、异步请求与构建部署。哪一项描述与代码一致？
- **正确项**：调用了 `async()`
- **判断依据**：这道题落在术语 `prev.map` 上：关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`，列表必须有稳定 `key`，事件处理用箭头函数避免 `this` 问题。复习时把 `prev.map` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：列表渲染时 key 的作用是？
- **正确项**：帮助 diff 算法识别元素，避免复用错位
- **判断依据**：这道题检验本课主问题：组件状态、不可变更新、异步请求与构建部署。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 3：第 3 题

- **题目**：npm run build 之后产物是什么？
- **正确项**：静态 HTML/CSS/JS 文件
- **判断依据**：这道题落在术语 `npm run build` 上：`npm run build` 产物是纯静态文件，可放 Nginx 或 CDN。复习时把 `npm run build` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：围绕“实战：Vite + React 待办应用”中的 实战、React、Vite，下列哪两项是本课强调的实践判断？
- **正确项**：验证 React 时要固定版本并覆盖边界输入，结论才可复现；学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `实战` 上：实战：Vite + React 待办应用解决了什么问题，而不是只背术语。复习时把 `实战` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：Vite 相比传统打包器在开发时的优势是？
- **正确项**：基于浏览器原生 ESM 按需编译
- **判断依据**：这道题检验本课主问题：组件状态、不可变更新、异步请求与构建部署。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `组件状态、不可变更新、异步请求与构建部署。`，这段说明是：`____`：package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。空缺处应填哪个术语？
- **正确项**：构建脚本
- **判断依据**：这道题落在术语 `构建脚本` 上：package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。复习时把 `构建脚本` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`prev.map`

- **要点**：关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题。
- **prev.map 的边界**：缓存与状态残留会让结果过期，先明确失效策略再判断正确性。

### 考点 8：`npm run build`

- **要点**：`npm run build` 产物是纯静态文件，可放 Nginx 或 CDN。
- **npm run build 的边界**：静态检查只在编译期成立，运行期输入仍需校验。

### 考点 9：`实战`

- **要点**：实战：Vite + React 待办应用解决了什么问题，而不是只背术语。
- **实战 的边界**：只在「实战：Vite + React 待办应用解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。

### 考点 10：`构建脚本`

- **要点**：package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。
- **构建脚本 的边界**：只在「package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口」这一前提下成立，换输入或换环境要重新验证。

### 考点 11：排错——入口文件写满业务

- **现象**：无法维护。
- **处理**：入口只做组装。

### 考点 12：排错——用 `innerHTML` 渲染接口数据

- **现象**：XSS 风险。
- **处理**：用 `textContent`。

### 考点 13：综合辨析——`prev.map` 与 `构建脚本`

- **辨析点**：`prev.map` 的定义是 关键点：状态用不可变更新（`[...prev]`、`prev.map`），不要直接 `push`；列表必须有稳定 `key`；事件处理用箭头函数避免 `this` 问题；`构建脚本` 的定义是 package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。
- **答题要求**：面对 `实战：Vite + React 待办应用` 的题目，先判断描述的是 `prev.map` 还是 `构建脚本`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 无法维护，而不是只写“程序有错”。
- **证据分**：保留触发 入口文件写满业务 的输入、版本和错误原文。
- **修复分**：按 入口只做组装 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Node.js 22+ / 现代浏览器
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、React、Vite、useState、useEffect
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：实战、React、Vite、useState、useEffect。

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN Promise](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Promise) | Promise 与异步链 |
| [MDN JavaScript 指南](https://developer.mozilla.org/docs/Web/JavaScript/Guide) | 语言基础与浏览器 API |
| [Jest 文档](https://jestjs.io/docs/getting-started) | JavaScript 测试与断言 |

| [本课术语索引：实战：Vite + React 待办应用](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「实战：Vite + React 待办应用」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->