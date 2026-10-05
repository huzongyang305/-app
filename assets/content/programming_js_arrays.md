# 数组与常用方法

![数组与常用方法](images/remaining_js_arrays.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：14 分钟

## 学习目标

- 能用自己的话解释「数组与常用方法」解决了什么问题，而不是只背术语。
- 能说清 「数组」、「map」、「filter」、「reduce」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「JavaScript」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：增删改查、map/filter/reduce、排序陷阱与不可变操作。

## 前置知识

- 先完成上一课《对象、原型与类》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：数组、map、filter。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 增删改查

```javascript
const nums = [3, 1, 2];

nums.push(4);            // 末尾添加
nums.pop();              // 删除末尾
nums.unshift(0);         // 头部添加
nums.shift();            // 删除头部
nums.splice(1, 1, 9);    // 从下标 1 删除 1 个并插入 9
nums.slice(1, 3);        // 截取子数组，不改变原数组
nums.includes(2);        // 是否包含
nums.indexOf(2);         // 下标，找不到返回 -1
```

`slice` 不改原数组，`splice` 会改；这是最容易混淆的一对方法。

## 函数式方法

```javascript
const users = [
  { name: 'tom', age: 18 },
  { name: 'alice', age: 25 },
  { name: 'bob', age: 30 },
];

users.map(u => u.name);                     // ['tom','alice','bob']
users.filter(u => u.age >= 20);             // 筛选
users.find(u => u.name === 'alice');        // 第一个匹配项
users.some(u => u.age > 60);                // 是否存在
users.every(u => u.age > 0);                // 是否全部满足
users.reduce((sum, u) => sum + u.age, 0);   // 归约求和 = 73
users.sort((a, b) => a.age - b.age);        // 排序（会改原数组）
users.flatMap(u => u.name.split(''));       // 映射后展平
```

注意：`sort` 默认按字符串比较，数字排序必须传比较函数，且它会修改原数组，需要副本可用 `[...users].sort(...)`。

## 不可变操作

```javascript
const added = [...nums, 5];                 // 追加
const removed = nums.filter(n => n !== 1);  // 删除
const updated = nums.map(n => (n === 2 ? 20 : n));
const merged = [...a, ...b];
const [[first], ...others] = [[1, 2], [3], [4]];
```

React / Redux 等状态管理要求「不直接改原数组」，用展开与 map/filter 生成新数组。

## 迭代与生成器

```javascript
for (const n of nums) { }

function* range(start, end) {      // 生成器：按需产出
  for (let i = start; i < end; i++) yield i;
}
console.log([...range(1, 4)]);     // [1, 2, 3]
```

## 本课小结
数组是 JS 最常用的结构：**查询用 find/filter、转换用 map、聚合用 reduce、排序记得传比较函数**。


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


## 零基础详解：数组方法与「不改原数组」的写法

### 一句话说清它是什么

数组是有序列表。JavaScript 的数组方法很多，但要先分清两类：
**会修改原数组的**（`push`、`sort`、`splice`）和**返回新数组的**（`map`、`filter`、`slice`）。

### 用生活比喻理解

| 方法 | 比喻 | 是否改原数组 |
| --- | --- | --- |
| `push` / `pop` | 队伍尾部进出 | 改 |
| `shift` / `unshift` | 队伍头部进出 | 改 |
| `map` | 每个都加工一遍，交新名单 | 不改 |
| `filter` | 按条件筛选，交新名单 | 不改 |
| `reduce` | 把所有项汇总成一个结果 | 不改 |
| `slice` | 复印一段 | 不改 |
| `splice` | 就地剪接 | 改 |

### 查看与修改

```javascript
const arr = ["a", "b", "c"];

arr[0];                    // "a"
arr.at(-1);                // "c"，负数取倒数第几项
arr.length;                // 3

arr.push("d");             // 尾部加，返回新长度
arr.pop();                 // 尾部删，返回被删的值
arr.unshift("z");          // 头部加
arr.shift();               // 头部删

arr.includes("b");         // true
arr.indexOf("b");          // 1，找不到返回 -1
```

### 五个高频「函数式」方法

```javascript
const nums = [1, 2, 3, 4, 5];

const doubled = nums.map((n) => n * 2);          // [2,4,6,8,10]
const evens = nums.filter((n) => n % 2 === 0);   // [2,4]
const total = nums.reduce((sum, n) => sum + n, 0);   // 15
const found = nums.find((n) => n > 3);           // 4
const allPositive = nums.every((n) => n > 0);    // true
```

| 方法 | 一句话 | 返回 |
| --- | --- | --- |
| `map` | 每个元素变一个 | 等长新数组 |
| `filter` | 挑出符合条件的 | 可能更短的新数组 |
| `reduce` | 压缩成一个值 | 任意类型 |
| `find` / `findIndex` | 找第一个满足的 | 元素或下标 |
| `some` / `every` | 是否存在 / 是否全部 | 布尔值 |
| `flat` / `flatMap` | 拍平嵌套 | 新数组 |

### 排序：默认行为是个坑

```javascript
const nums = [10, 9, 100];
nums.sort();                        // [10, 100, 9]，按字符串比较！
nums.sort((a, b) => a - b);         // [9, 10, 100]，数字升序

const users = [{ age: 30 }, { age: 20 }];
users.sort((a, b) => a.age - b.age);      // 按字段排序
```

数字数组排序**必须传比较函数**，否则默认按字符串比较。

### 不改原数组的现代写法

```javascript
const source = [3, 1, 2];

const sorted = source.toSorted((a, b) => a - b);   // 排序但不改原数组
const reversed = source.toReversed();              // 反转但不改原数组
const spliced = source.toSpliced(0, 1);            // 删除但不改原数组
const withNew = source.with(0, 99);                // 替换指定下标

console.log(source);        // [3, 1, 2] 原样不变
```

### 去重与分组

```javascript
const list = [1, 2, 2, 3, 3, 3];
const unique = [...new Set(list)];                 // [1,2,3]

const people = [
  { name: "小明", team: "A" },
  { name: "小红", team: "B" },
  { name: "小刚", team: "A" },
];

const byTeam = Object.groupBy(people, (p) => p.team);
console.log(byTeam.A.length);                       // 2
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 数字排序不传比较函数 | 10 排在 9 前面 | 传 `(a, b) => a - b` |
| `forEach` 里 `break` | 报错或无效 | 改 `for...of` |
| `map` 里忘 `return` | 一堆 undefined | 用表达式体箭头函数 |
| 用 `delete arr[i]` | 留下空洞，长度不变 | 用 `splice` 或 `filter` |
| 把 `slice` 当 `splice` | 一个不改一个改，结果混乱 | 记住 slice 是复印 |
| 直接比较数组 | `[1] === [1]` 是 false | 逐项比较或转字符串 |
| 浅拷贝嵌套数组 | 内层互相影响 | 用 `structuredClone` |
| 用下标删中间元素 | 顺序错乱 | 用 `filter` 重建 |

### 手把手练习：成绩统计

```javascript
const students = [
  { name: "小明", score: 88 },
  { name: "小红", score: 95 },
  { name: "小刚", score: 59 },
  { name: "小美", score: 72 },
];

const passed = students.filter((s) => s.score >= 60);
const average =
  students.reduce((sum, s) => sum + s.score, 0) / students.length;
const ranked = students.toSorted((a, b) => b.score - a.score);
const names = ranked.map((s) => `${s.name}(${s.score})`).join(", ");

console.log(`及格 ${passed.length} 人，平均 ${average.toFixed(1)} 分`);
console.log("排名：", names);

// 按分数段分组
const groups = Object.groupBy(
  students,
  (s) => (s.score >= 90 ? "优秀" : s.score >= 60 ? "及格" : "不及格"),
);
console.log(Object.keys(groups));
```

### 学完自测

- [ ] 能说出哪些方法会改原数组。
- [ ] 知道数字排序为什么必须传比较函数。
- [ ] 能用 `map` + `filter` + `reduce` 完成一段统计。
- [ ] 能说出 `slice` 与 `splice` 的区别。
- [ ] 知道 `toSorted`、`with` 这些新方法的意义。

## 动手练习


> 本课练习重点：围绕「数组、map、filter」完成复述、实验和交付，每个结果都要能被别人检查。

先在 Node 或浏览器复现行为，再改写异步与错误路径，最后补测试。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「数组与常用方法」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「map」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在浏览器控制台或 Node.js 中写一个最小示例，列出至少 3 组输入输出。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「数组」和「map」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：下面哪个方法不会修改原数组？

- **正确判断**：filter
- **判断依据**：filter/map/slice 返回新数组。splice、sort、push 会修改原数组。其他选项：sort、splice、push 都会原地修改数组。正确项「filter」是该问题的规范说法，换成其他表述都会丢失条件。把题干「下面哪个方法不会修改原数组？」放回《数组与常用方法》的「增删改查、map/filter/reduce、排序陷阱与不可变操作」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：对数字数组正确排序的写法是？

- **正确判断**：nums.sort((a, b) => a - b)
- **判断依据**：sort 默认按字符串比较，[10, 9] 会排成 [10, 9]。其他选项：默认 sort 按字符串比较，10 会排在 9 前面，必须传入比较函数。正确项「nums.sort((a, b) => a - b)」描述正确，能够解释题干场景中的现象与结果。错误项「nums.orderBy()（仅部分场景成立）」与课程给出的定义相冲突，不能回答题目所问。错误项「nums.reverse()」只看到了表面现象，没有解释题干真正考查的机制。错误项「nums.sort()」在边界或失败路径上会得出错误结果。把题干「对数字数组正确排序的写法是？」放回《数组与常用方法》的「增删改查、map/filter/reduce、排序陷阱与不可变操作」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：reduce 的典型用途是？

- **正确判断**：把数组归约为单个值（求和、分组等）
- **判断依据**：reduce 用累加器把数组折叠成一个结果，是求和、计数、分组的通用工具。其他选项：reduce 把数组归约成单个值，求和、分组、计数都能做。筛选与排序应交给 filter 与 sort。正确项「把数组归约为单个值（求和、分组等）」与题干要求一致，是本课知识点的准确定义。错误项「筛选元素（仅部分场景成立）」属于相邻主题的说法，范围与本题要求不一致。错误项「去重」与课程给出的定义相冲突，不能回答题目所问。把题干「reduce 的典型用途是？」放回《数组与常用方法》的「增删改查、map/filter/reduce、排序陷阱与不可变操作」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：find 与 filter 的区别是？

- **正确判断**：find 返回第一个匹配的元素（或 undefined）
- **判断依据**：只要一个结果就用 find 提前短路，需要全部结果才用 filter。其他选项：find 返回元素本身（找不到是 undefined），filter 返回数组。两者的关键区别是：find 返回第一个匹配的元素（或 undefined） 直接描述了定义差异。正确项「find 返回第一个匹配的元素（或 undefined）」描述正确，能够解释题干场景中的现象与结果。错误项「两者都修改原数组」与课程给出的定义相冲突，不能回答题目所问。错误项「find 会排序后再查找」只看到了表面现象，没有解释题干真正考查的机制。错误项「find 返回数组，filter 返回单个元素」适用于其他场景，但与本题的前提不匹配。把题干「find 与 filter 的区别是？」放回《数组与常用方法》的「增删改查、map/filter/reduce、排序陷阱与不可变操作」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：arr.flatMap(fn) 相当于？

- **正确判断**：先 map 再 flat(1)，把每个元素映射成的数组展平一层
- **判断依据**：flatMap 常用来「一对多」展开，例如把订单列表展开成商品项列表。其他选项：flatMap 等价于先 map 再 flat(1)，适合一对多展开。正确项「先 map 再 flat(1)，把每个元素映射成的数组展平一层」与本课示例和结论一致，可以直接用于实际编码。错误项「先排序再映射（只在边界情况下成立，不能回答本题）」在边界或失败路径上会得出错误结果。错误项「只做去重」适用于其他场景，但与本题的前提不匹配。错误项「把数组反转」把因果关系颠倒了，不能作为正确结论。把题干「arr.flatMap(fn) 相当于？」放回《数组与常用方法》的「增删改查、map/filter/reduce、排序陷阱与不可变操作」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「下面哪个方法不会修改原数组？」的判断依据。
- [ ] 不看解析，能说出「对数字数组正确排序的写法是？」的判断依据。
- [ ] 不看解析，能说出「reduce 的典型用途是？」的判断依据。
- [ ] 不看解析，能说出「find 与 filter 的区别是？」的判断依据。
- [ ] 不看解析，能说出「arr.flatMap(fn) 相当于？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Arrays & Methods

**Summary:** Array CRUD, map/filter/reduce, sorting and immutability.

**Category:** JavaScript  
**Level:** 进阶  
**Key terms:** 数组, map, filter, reduce, sort, 展开运算符

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Node.js 22+ / 现代浏览器
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：数组、map、filter、reduce、sort、展开运算符
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [MDN JavaScript](https://developer.mozilla.org/docs/Web/JavaScript) | 语言、DOM 与运行时 |
| [ECMAScript](https://ecma-international.org/publications-and-standards/standards/ecma-262/) | 语言标准 |

> 本课主题：增删改查、map/filter/reduce、排序陷阱与不可变操作。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

