# Action: Vite + React to-do

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It is possible to explain, in its own words, what problems were solved by the "Vite + React To-do" application rather than simply using terminology.
- The relationship between "act", "Vite" and "usestate" is clear, with one example.
- It's a way to put back the knowledge of JavaScript, which is how it works with each other.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the composition status, non-modifiable requests and build deployments.

## Pre-knowledge

- The first course, Modularization and Engineering, was completed; if available it could be used for self-measurement.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we start, let's review the war.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Initialize

```bash
npm create vite@latest todo-app -- --template react-ts
cd todo-app
npm install
npm run dev          # 本地开发服务器，支持热更新
npm run build        # 产出 dist/ 静态文件
npm run preview      # 本地预览构建结果
```

Justification for the TypeScript template: Component props and interface data have a type of hint to recreate.

## Component and Status

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

Key points: The state is non-modifiable (0, ), not directly 2⟧; the list must be stable 3⟧; event handling avoids 4 with an arrow function.

## Request Backend Data

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

## Project Configuration

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

Avoid cross-domain by proxy:

```ts
export default defineConfig({
  server: { proxy: { '/api': 'http://localhost:8080' } },
});
```

## Online.

1. ⟦O is a pure static file that can be placed on Nginx or CDN.
2. The interface address is injected with ⟦0, not coded hard.
3. Give it to me.
4. We'll do a volume analysis, then consider the division of codes.

## It's the end of this class.
Front-end project ** Component UI+ Unchangeable + Instant Data Acquisition + Build Tool**. Run through this small application and learn the react/Vue evolution concept much easier.

<!-- appendix:v1 -->

## React Quick

|Concept|Annotations|Common|
| --- | --- | --- |
|Component|Returns the UI function| `function Item({ id }) { ... }` |
| Props |Only reading data for fathers and sons|Disassembly, avoid direct modifications|
| State |Component Internal Status| `const [list, setList] = useState([])` |
|Derivative value|Value from state|Directly calculate, no additional state|
|Side effects|Request, subscription, timer| `useEffect(() => { ... }, [deps])` |
|References|Save DOM or Variable| `useRef(null)` |
|Memory value|Expensive Calculator| `useMemo(() => compute(a), [a])` |
|Memory Functions|Stable function for subcomponents| `useCallback(fn, [deps])` |
|Context|Sharing across levels| `createContext` + `useContext` |
|List Rendering|Rendering arrays| `list.map((item) => <Item key={item.id} />)` |
|Conditional rendering|Show by Condition| `{loading ? <Spinner /> : <List />}` |

## Status update quick check (non-change)

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

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|I'll be right back.|Quotes are the same, interfaces aren't new.|Generate new arrays with ⟦0|
|Directly, zero.|No Rendering Component|Generate new objects with an open or non-changeable tool|
|Use the array to mark ⟦0|Error after Remove Middle|Use the only stable ID as key|
|Zero depends on the array default variable|Read expired closed value|Write All, or Update in Function|
|I'll call you back.|Return Promise, React Warning|Internalise async function and call|
|Forget subscriptions or timers|Memory leaks, repeat requests|⟦Phonebackclean function|
|Request in Rendering|♪ Every time I ask ♪|Put it in.|
|We'll save the derivatives.|Both data are not synchronized|Directly calculate derivatives|
|It's a two-time call.|Add only 1|Update with function|
|It's like a potion.|It's more complicated than that.|We'll do it first. Only when we have expenses.|

## Engineering quick check.

|Purpose|Command / Practice|
| --- | --- |
|Develop debugging|⟦ (Vite Hot Update)|
|Production Construction| `npm run build` |
|Local Preview| `npm run preview` |
|Code Instructions|ESLint + Prettier, access to CI|
|Unit Test| Vitest + Testing Library |
|End-to-end testing| Playwright |
|Environmental variables|You're not gonna be exposed until you have a prefix.|

## Self-Detected List

- [ ] Status updates are always non-variable.
- [ ] List render with the only stable key.
- [ ] ⟦ depends on the whole and has clean logic.
- [ ] No additional data are available.
- [ ] Run prior to testing, environment variable not written in code.

<!-- appendix:v3 -->

## Zero basic details: a front-end project from zero

### What is it?

A front-end project that can be delivered requires:** a running development environment, clear layers, packaged construction and verifiable testing.**
Here's a book search page.

### It's a life metaphor.

|Contents|A metaphor.|Annotations|
| --- | --- | --- |
| `src/api/` |Procurement corridors|It's only for data.|
| `src/ui/` |Renovation team.|It's only for rendering.|
| `src/state/` |Publicity Bar|Share Status|
| `src/utils/` |Toolbox|Pure Functions|
| `public/` |The front.|Static Resources and Entry HTML|

### Recommended Directory Structure

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

### Separate Status from View

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

### Four-state rendering: don't let the white screen

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

** With 0 instead of 1**: data from interface must be treated as untrustworthy.

### Data request: Timeout + Error Normalization

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

### Pure Functions and Tests

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

### Build & Check

```bash
npm ci
npm run lint
npm test -- --run
npm run build          # 产出 dist/
npm run preview        # 本地预览产物，而不是只看 dev
```

** It is important to preview ⟦: many problems (relative path, environmental variables) only occur in the product.

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|The entry documents are full of business.|Unable to maintain|The entrance is only for assembly.|
|Render interface data with ⟦0|XSS Risk|Use Zero.|
|There's nothing wrong with that.|Whitescreen for error|Load, succeed, empty, fail.|
|There's no timeout.|Turn around.|I'm sorry, sir.|
|dev only|It's not until we get on the line.|Preview of ⟦|
|Change Status Directly|View does not update|With a single zero.|
|Forget to clean the timer.|Misreporting and memory leaks|I'll be right back.|
|Tool-only|There's been an error.|E2E test|

### Learn how to measure yourself.

- [ ] Can say the respective responsibilities of api, state, ui, utils.
- [ Laughs ] Know why four-state rendering removes the white screen.
- [ ] The manner in which requests can be realized over time.
- [ ] Know why it has to be previewed.
- [ ] Tell me why pure functions are the easiest to test.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around "Performance, React, Vite" each result is subject to scrutiny.

Either the Node or the browser is active first, and then rewrite between steps and errors.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with "Vite + React" applications?
2. Without it, what concrete consequences would there be?
3. What's it got to do with React?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a minimum example of at least 3 group inputs in the browser console or Node.js.

Mission requests:

- The result must be checked, not just “I understand”.
- I'm not sure if you're going to be able to do this.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## Validation command and expected output

The project code does not read only " Compilable " , but repeats the results by a fixed command.

|Phase|Command|Expected output|
| --- | --- | --- |
|Installation Dependence| `npm ci` |Lock file installation, no missing dependents|
|Run Test| `npm test` |All tests passed.|
|Build| `npm run build` |Generate distribution without an error|

### Evidence of acceptance

- [ ] Save the complete output relying on installation and start-up orders.
- [ ] Run at least 3 tests containing an illegal input or failure path.
- [ ] Repeat the same operation twice and confirm that there are no duplicates or side effects.
- [ ] Record a failure code, wrong log and recovery steps.
- [ ] Provide an environmental version, start-up and rollback in README.

### Return and Roll

1. Start with an abandoned directory or temporary database to avoid contamination of real data.
2. Rerun all authentication orders after a logical change to confirm that they are not returned.
3. If you fail, roll back to the previous runable version and keep the failed log.
4. The reason for the location is supplemented by an automated test and re-execution process.
5. The lessons are included in the project ' s repertoire or in a note, which will form the next inspection.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Project: React Todo App

**Summary:** Components, immutable state, async data and build.

**Category:** JavaScript  
**Level:** Advanced
**Key terms:** Action, Vite, usestate, useEffect

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable context: Node.js 22+/ Modern Browser
- Source: Internal structured curriculum and engineering practices
- Related themes: field, React, Vite, usestate, useEffect
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

## Specifications for the project: field: Vite + React

### Core scene

Component status, non-modifiable request and build deployment.The goal of the project is to translate "act, Vite, usestate, useEffect" into operational, testable and rolling deliverables.

### Structures and data flows

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### Minimum Data Model

|Object|Key Fields|Constraints|
| --- | --- | --- |
|Enter entity|Actual, time and source|Keys to verify, limit the length, etc.|
|Task entity|Status, priority, creation|It's legal, it can't be repeated|
|Result entity|Output, Error Code, Time|Sequencable. Errors.|
|Audit records|Operator, action, result, time|It's unmovable, searchable and dissensitive.|

### Receiving scenes

1. Normal path: The minimum input receives the expected output, leaving a log and an indicator.
2. Boundary path: Empty, maximum, duplicated data and super-long content are explicitly addressed.
3. Failed path: fast failure, retest or downgrade if you rely on excess time.
4. Paths, etc.: The execution of the same request will not have repeated side effects.
5. Rollback path: Backroll data are consistent and indicate recovery time and impact.

<!-- project-delivery:v1 -->

## Project delivery

### Suggested warehouse structure

```text
src/
  routes/
  services/
  repositories/
tests/
package.json
```

### Test Matrix

|Level|Overwrite|Minimum|Adoption of standards|
| --- | --- | ---: | --- |
|Unit Test|Field rules, boundaries and misclassification| 8 |It's normal. The border, the path to failure.|
|Integrated testing|Database, network, document or platform boundary| 3 |Use real boundaries and run again|
|End-to-end testing|Core User Path| 1 |Full run from input to output|
|Manually.|5 scenes listed in the document| 5 |Orders, output and conclusion records|

### Receiving and Inspection Data

```json
{
  "project": "js_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### Duplicate Template

|Problem|Records|
| --- | --- |
|What was the original target?|I'll give you a description of the acceptable target.|
|What's going on?|Timeline, indicators and key logs|
|Which assumption was overturned?|Root causes and contributing factors|
|How do you roll back?|Steps, time-consuming and data validation|
|What's next?|Responsible persons, duration and certification|

> Project acceptance revolves around "act, Vite": at least one normal route, one border entry, one failed recovery and another check.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Project: React Todo App** focuses on Components, immutable state, async data and build.

### Learning Outcomes

- Explain what **Project: React Todo App** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Project: React Todo App**
- Relayed terms: Real, Vite, use State
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Initialize|Initialize|
|Component and Status|Component and Status|
|Request Backend Data|Request Backend Data|
|Project Configuration|Project Configuration|
|Online.|Online.|
|It's the end of this class.| Summary |
|React Quick|React Quick|
|Status update quick check (non-change)|Status update quick check (non-change)|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

