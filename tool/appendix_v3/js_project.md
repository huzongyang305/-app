## 零基础详解：从零做一个前端小项目

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
