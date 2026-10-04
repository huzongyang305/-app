## 类型判断速查

| 表达式 | 结果 | 说明 |
| --- | --- | --- |
| `typeof "a"` | `"string"` | 原始类型判断可靠 |
| `typeof 1` | `"number"` | 整数与小数同一类型 |
| `typeof 1n` | `"bigint"` | 大整数 |
| `typeof true` | `"boolean"` |  |
| `typeof undefined` | `"undefined"` | 变量未赋值 |
| `typeof null` | `"object"` | 历史遗留问题，判空用 `x === null` |
| `typeof []` | `"object"` | 数组要 `Array.isArray(x)` |
| `typeof function(){}` | `"function"` |  |
| `typeof Symbol()` | `"symbol"` |  |
| `Number.isNaN(NaN)` | `true` | 判 NaN 用 `Number.isNaN`，别用 `x === NaN` |
| `Array.isArray([])` | `true` | 判断数组的标准写法 |
| `x instanceof Date` | 布尔值 | 判断对象的类，跨 iframe 可能失效 |

## 类型转换速查

| 写法 | 结果 | 备注 |
| --- | --- | --- |
| `Number("12")` | `12` | 空字符串是 `0`，非法字符是 `NaN` |
| `parseInt("12px", 10)` | `12` | 从头解析到非法字符为止，务必带基数 |
| `parseFloat("3.14abc")` | `3.14` | 同上 |
| `String(12)` | `"12"` | 显式转换，推荐 |
| `Boolean("")` | `false` | 假值：`""`、`0`、`-0`、`NaN`、`null`、`undefined`、`false` |
| `Boolean("0")` | `true` | 非空字符串一律为真，表单校验常踩 |
| `[1, 2] + ""` | `"1,2"` | 隐式转换，可读性差 |
| `0.1 + 0.2` | `0.30000000000000004` | 浮点误差，比较用 `Math.abs(a - b) < 1e-9` |
| `null == undefined` | `true` | 两者互相宽松相等，其他都为假 |
| `null === undefined` | `false` | `===` 不做类型转换，推荐始终使用 |
| `"5" - 1` | `4` | `-` 会转数字，而 `"5" + 1` 是 `"51"` |

## 常见错误对照表

| 容易写错的写法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `if (obj.name)` | 空字符串或 0 被当成缺失 | 明确判断：`obj.name !== undefined && obj.name !== null` 或 `obj.name ?? ""` |
| `const obj = {}; obj.a = 1` | 正常，能改属性 | `const` 只锁变量绑定，不改对象内容；要冻结用 `Object.freeze(obj)` |
| `{ a: 1 } === { a: 1 }` | `false` | 对象比较的是引用；比较内容要逐字段或用深比较函数 |
| `JSON.parse(undefined)` | `SyntaxError` | 先判断空值：`text ? JSON.parse(text) : null` |
| `Number("")` | `0` | 空输入要先校验，别直接转换 |
| `[] == false` | `true` | 宽松相等会做隐式转换，规则复杂，统一用 `===` |
| `let x; x.toFixed(2)` | `TypeError` | `let` 声明未赋值是 `undefined`，先赋数字 |
| 用 `==` 比较 `null` 与 `0` | `false`，但 `0 == ""` 是 `true` | 宽松相等陷阱多，直接上 `===` |

## 自测清单

- [ ] 能用 `typeof` 正确判断六种原始类型，知道 `typeof null` 是 `"object"`。
- [ ] 判断数组用 `Array.isArray()` 而不是 `typeof`。
- [ ] 判断 `NaN` 用 `Number.isNaN()` 而不是 `=== NaN`。
- [ ] 记住七个假值，知道 `"0"` 和 `[]` 都是真值。
- [ ] 默认使用 `===` / `!==`，除非明确需要宽松相等。
