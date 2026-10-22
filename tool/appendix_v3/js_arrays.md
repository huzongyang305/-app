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
