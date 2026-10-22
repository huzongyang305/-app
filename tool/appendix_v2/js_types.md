## 零基础详解：JavaScript 的类型与「隐式转换」

### 一句话说清它是什么

JavaScript 有 7 种**原始类型**和 1 种**引用类型**（Object）。
它既灵活又容易出错，因为运算时会自动做类型转换——**看懂转换规则，就躲开了大半的坑**。

### 类型总览

| 类型 | 例子 | `typeof` 结果 | 说明 |
| --- | --- | --- | --- |
| number | `1`、`3.14`、`NaN` | `"number"` | 不分整数和小数 |
| string | `"hi"`、`` `hi` `` | `"string"` | 不可变 |
| boolean | `true` / `false` | `"boolean"` | 真假值 |
| undefined | `let x;` | `"undefined"` | 声明了但没赋值 |
| null | `let y = null;` | `"object"` | **历史遗留 bug**，表示「空」 |
| symbol | `Symbol("id")` | `"symbol"` | 唯一标识 |
| bigint | `10n` | `"bigint"` | 超大整数 |
| object | `{}`、`[]`、函数 | `"object"` / `"function"` | 引用类型 |

### `null` 与 `undefined` 怎么区分

| 对比 | undefined | null |
| --- | --- | --- |
| 含义 | 还没有值 | 有意置空 |
| 谁产生的 | JS 引擎自动 | 程序员手动 |
| 典型场景 | 未赋值、函数无返回、属性不存在 | 主动清空、接口约定为空 |

```javascript
let a;
console.log(a);                 // undefined
let b = null;
console.log(b);                 // null
console.log(a == b, a === b);   // true false
```

### 真假值：哪些东西是 false

只有这 8 个值是「假」的：`false`、`0`、`-0`、`0n`、`""`、`null`、`undefined`、`NaN`。
其它一切（包括 `[]`、`{}`、`"0"`）都是真。

```javascript
if ([]) console.log("空数组也是真");   // 会打印
if ("0") console.log("字符串 0 也是真");
```

### `==` 与 `===` 的转换规则

```javascript
0 == ""            // true    两边都转成数字
0 == false         // true
null == undefined  // true    规定如此
NaN == NaN         // false   判断 NaN 要用 Number.isNaN()
"1" == 1           // true    字符串被转成数字

"1" === 1          // false   类型不同，直接不相等
```

**规则：日常一律用 `===`；只有判断「null 或 undefined」时，`== null` 可以当作简写。**

### 常见转换速查

| 表达式 | 结果 | 说明 |
| --- | --- | --- |
| `Number("12")` | `12` | 转数字，失败得 `NaN` |
| `Number("")` | `0` | 空串转成 0 |
| `parseInt("12px")` | `12` | 从头解析，遇到非数字停 |
| `String(12)` | `"12"` | 转字符串 |
| `Boolean("")` | `false` | 空串为假 |
| `Boolean("false")` | `true` | 非空字符串都为真 |
| `"1" + 2` | `"12"` | `+` 遇到字符串就拼接 |
| `"3" * 2` | `6` | 其它运算符会转数字 |

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `==` | 结果反直觉 | 用 `===` |
| 把 `NaN` 当相等 | `NaN === NaN` 是 false | 用 `Number.isNaN(x)` |
| 直接调 `parseInt` 忘传进制 | 老浏览器把 `08` 当八进制 | 写 `parseInt(s, 10)` |
| 数字精度 | `0.1 + 0.2 !== 0.3` | 用误差比较，金额用整数分 |
| 字符串拼数字 | `"1" + 2` 得到 `"12"` | 先 `Number()` 转 |
| 判断属性是否存在 | `if (obj.name)` 漏掉 0 和 "" | 用 `"name" in obj` 或 `??` |
| 引用赋值当复制 | 改一处全变 | 用展开运算符浅拷贝 |

### 手把手练习：安全地处理用户输入

```javascript
function toPositiveInt(raw) {
  const n = Number.parseInt(String(raw ?? "").trim(), 10);
  if (!Number.isFinite(n) || n <= 0) {
    throw new Error("请输入一个正整数");
  }
  return n;
}

try {
  console.log(toPositiveInt(" 42 "));   // 42
  console.log(toPositiveInt("abc"));    // 抛错
} catch (error) {
  console.log("捕获到：", error.message);
}
```

### 学完自测

- [ ] 能说出 7 种原始类型。
- [ ] 能解释 `null == undefined` 为 true、`===` 为 false。
- [ ] 能说出 8 个假值。
- [ ] 知道为什么要用 `Number.isNaN` 而不是 `=== NaN`。
- [ ] 能解释 `"1" + 2` 和 `"3" * 2` 为什么结果不同。
