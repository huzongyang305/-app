## React 核心速查

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

## 状态更新速查（不可变）

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

## 常见错误对照表

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

## 工程化速查

| 目的 | 命令 / 做法 |
| --- | --- |
| 开发调试 | `npm run dev`（Vite 热更新） |
| 生产构建 | `npm run build` |
| 本地预览产物 | `npm run preview` |
| 代码规范 | ESLint + Prettier，接入 CI |
| 单元测试 | Vitest + Testing Library |
| 端到端测试 | Playwright |
| 环境变量 | `.env` 中 `VITE_` 前缀才会暴露给前端 |

## 自测清单

- [ ] 状态更新一律使用不可变写法。
- [ ] 列表渲染使用稳定唯一 key。
- [ ] `useEffect` 依赖写全，并有清理逻辑。
- [ ] 派生数据不额外存 state。
- [ ] 提交前跑 lint 与测试，环境变量不写进代码。
