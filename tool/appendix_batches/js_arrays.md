## 数组方法速查（是否修改原数组）

| 方法 | 作用 | 返回值 | 改动原数组 |
| --- | --- | --- | --- |
| `push` / `pop` | 尾部增删 | 新长度 / 被删元素 | 是 |
| `unshift` / `shift` | 头部增删 | 新长度 / 被删元素 | 是 |
| `splice` | 任意位置增删 | 被删元素数组 | 是 |
| `sort` / `reverse` | 排序 / 反转 | 原数组引用 | 是 |
| `fill` / `copyWithin` | 填充 / 内部复制 | 原数组引用 | 是 |
| `slice` | 截取子数组 | 新数组 | 否 |
| `concat` | 拼接 | 新数组 | 否 |
| `map` / `filter` | 映射 / 过滤 | 新数组 | 否 |
| `flat` / `flatMap` | 展平 | 新数组 | 否 |
| `toSorted` / `toReversed` | 排序 / 反转的不可变版本 | 新数组 | 否 |
| `find` / `findIndex` | 首个匹配元素 / 下标 | 元素或 `undefined` / -1 | 否 |
| `some` / `every` | 是否存在 / 是否全部满足 | 布尔值 | 否 |
| `reduce` | 归约成单个值 | 任意类型 | 否 |
| `join` | 转成字符串 | 字符串 | 否 |
| `includes` / `indexOf` | 是否存在 / 下标 | 布尔值 / 下标 | 否 |

```js
const nums = [3, 1, 2];

// 不可变写法：得到新数组，原数组不变
const sorted = nums.toSorted((a, b) => a - b);   // [1, 2, 3]

// 常见组合：过滤后映射，再求和
const total = items
  .filter((item) => item.active)
  .map((item) => item.price)
  .reduce((sum, price) => sum + price, 0);

// 按字段分组：一行得到 { 类目: [商品...] }
const grouped = items.reduce((acc, item) => {
  (acc[item.category] ??= []).push(item);
  return acc;
}, {});
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `[10, 9, 1].sort()` | 得到 `[1, 10, 9]` | 默认按字符串比较，数字要传 `(a, b) => a - b` |
| `sort()` 后原数组被改 | 依赖原顺序的代码出 bug | 用 `toSorted()` 或先 `[...arr].sort()` |
| `forEach` 里 `return` 想跳出 | 循环继续执行 | `forEach` 不能中断，改用 `for...of` 或 `some` |
| `map` 里没写 `return` | 得到一堆 `undefined` | 显式返回，或改用 `forEach` 做副作用 |
| `find` 结果直接用 | 可能是 `undefined` | 先判空或用可选链 |
| `includes(NaN)` | `false` | 判 `NaN` 用 `Number.isNaN` 或 `some` |
| 用 `==` 判断元素存在 | 类型被隐式转换 | 用 `includes`（内部按 `SameValueZero` 比较） |
| `reduce` 不传初始值 | 空数组报错，类型可能与预期不同 | 传初始值，如 `reduce(fn, 0)` |
| `delete arr[i]` | 留下 `empty` 空洞 | 用 `splice` 或 `filter` |
| 直接改 `array.length` 截断 | 元素被永久丢弃 | 需要副本时用 `slice` |
| `push(...bigArray)` 传超大数组 | `RangeError: Maximum call stack size exceeded` | 大数据量用循环或 `concat` |
| 用 `for...in` 遍历数组 | 拿到字符串下标，还可能带上自定义属性 | 用 `for...of` 或 `forEach` |

## 自测清单

- [ ] 能说出哪些方法会修改原数组，哪些返回新数组。
- [ ] 数字排序一定传比较函数。
- [ ] 会用 `filter` + `map` + `reduce` 组合处理数据。
- [ ] 知道 `find` 可能返回 `undefined`，会做判空。
- [ ] 需要不可变操作时使用 `toSorted`、`toReversed` 或展开复制。
