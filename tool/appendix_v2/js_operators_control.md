## 零基础详解：运算符、判断与循环

### 一句话说清它是什么

运算符决定「怎么算」，判断决定「走哪条路」，循环决定「重复几次」。
JavaScript 在这三块有几个**独有又好用**的语法，值得专门记住。

### 六个常用运算符

| 运算符 | 名称 | 例子 | 说明 |
| --- | --- | --- | --- |
| `===` | 严格相等 | `a === b` | 类型和值都要相同 |
| `??` | 空值合并 | `a ?? b` | 只在 `null`/`undefined` 时取 b |
| `?.` | 可选链 | `a?.b` | a 为空时直接返回 undefined，不报错 |
| `**` | 幂 | `2 ** 10` | 1024 |
| `...` | 展开/收集 | `[...arr]`、`(...args)` | 复制或收集 |
| `? :` | 三元 | `n > 0 ? "正" : "负"` | 简洁的二分判断 |

```javascript
const name = input ?? "匿名";        // input 为 null/undefined 时才用默认值
const len = user?.profile?.bio?.length ?? 0;   // 逐层安全访问
const [first, ...rest] = [1, 2, 3];   // first=1, rest=[2,3]
```

`??` 与 `||` 的区别很重要：`0 || 5` 得 5，而 `0 ?? 5` 得 0。
**只要 0 和空串是合法值，就必须用 `??`。**

### 判断写法对照

```javascript
// 普通分支
if (score >= 90) {
  level = "优秀";
} else if (score >= 60) {
  level = "及格";
} else {
  level = "不及格";
}

// 单个值分流：switch
switch (status) {
  case "pending":
    handlePending();
    break;                 // 忘了 break 会继续往下执行
  case "done":
    handleDone();
    break;
  default:
    handleUnknown();
}

// 值 → 结果：用映射表更清晰
const LABELS = { pending: "待处理", done: "已完成" };
const label = LABELS[status] ?? "未知";
```

### 四种循环

| 循环 | 适合 | 注意 |
| --- | --- | --- |
| `for` | 需要下标或次数 | 最灵活 |
| `for...of` | 遍历数组、字符串、Map | 拿到的是值 |
| `for...in` | 遍历对象的键 | 谨慎，会包含继承属性 |
| `while` | 条件驱动 | 别忘更新条件 |

```javascript
for (const ch of "abc") console.log(ch);      // a b c

for (const key in { a: 1, b: 2 }) console.log(key);   // a b

// 并行遍历：同时拿下标和值
for (const [i, v] of ["x", "y"].entries()) console.log(i, v);
```

`forEach` 不能 `break`，要提前退出就用 `for...of` 或 `some`。

### 数组三大金刚：map / filter / reduce

```javascript
const nums = [1, 2, 3, 4, 5];

const doubled = nums.map((n) => n * 2);          // [2,4,6,8,10]
const evens = nums.filter((n) => n % 2 === 0);   // [2,4]
const total = nums.reduce((sum, n) => sum + n, 0);   // 15
```

| 方法 | 一句话 | 返回 |
| --- | --- | --- |
| `map` | 每个元素变一个 | 等长新数组 |
| `filter` | 挑出符合条件的 | 可能更短的数组 |
| `reduce` | 把数组压成一个值 | 任意类型的结果 |
| `find` | 找第一个符合条件的 | 元素或 undefined |
| `some` / `every` | 是否存在 / 是否全部 | 布尔值 |

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `0 \|\| 5` 得 5 | 0 被当成空值 | 改用 `??` |
| `forEach` 里 `break` | 报错或无效 | 改 `for...of` |
| 忘写 `break` | 多个 case 都执行 | 用映射表或补 `break` |
| 用 `for...in` 遍历数组 | 拿到字符串下标 | 数组用 `for...of` |
| `map` 里忘 `return` | 得到一堆 undefined | 用表达式体箭头函数或补 `return` |
| 比较浮点 | 精度问题 | 用误差范围 |
| 修改原数组 | 副作用难排查 | 用 `toSorted`、`toReversed` 或先复制 |

### 手把手练习：统计一段文本

```javascript
const text = "the quick brown fox jumps over the lazy dog";

const words = text.split(" ");
const longWords = words.filter((w) => w.length > 3);
const lengths = words.map((w) => w.length);
const maxLen = Math.max(...lengths);
const totalChars = lengths.reduce((sum, n) => sum + n, 0);

console.log(`共 ${words.length} 个词，最长 ${maxLen} 个字母，总字母数 ${totalChars}`);
console.log(`长度超过 3 的词：${longWords.join(", ")}`);
```

### 学完自测

- [ ] 能说出 `??` 与 `||` 的区别，并举例。
- [ ] 能解释 `user?.profile?.name` 为什么不会报错。
- [ ] 知道 `for...of` 与 `for...in` 分别遍历什么。
- [ ] 能写出用 `map` + `filter` + `reduce` 的一段统计代码。
- [ ] 知道 `forEach` 不能 `break`，该用什么替代。
