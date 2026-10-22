## 对象操作速查

| 目的 | 写法 | 说明 |
| --- | --- | --- |
| 读取可能不存在的属性 | `obj?.a?.b` | 短路返回 `undefined` |
| 取默认值 | `obj.a ?? "默认"` | 只有 `null` / `undefined` 才用默认值 |
| 解构并重命名 | `const { a: x, b = 1 } = obj` | 便于避免命名冲突 |
| 剩余属性 | `const { a, ...rest } = obj` | 常用于剔除字段 |
| 合并对象 | `{ ...a, ...b }` | 后面的同名字段覆盖前面 |
| 复制并改字段 | `{ ...user, name: "新名字" }` | 不可变更新的常用写法 |
| 安全修改嵌套字段 | `{ ...s, user: { ...s.user, age: 18 } }` | 逐层展开，避免直接改原对象 |
| 取键 / 值 / 键值对 | `Object.keys/values/entries` | 返回数组，可继续链式处理 |
| 转成 Map | `new Map(Object.entries(obj))` | 键可以是任意类型 |
| 冻结对象 | `Object.freeze(obj)` | 浅冻结，嵌套对象仍需处理 |
| 判断自有属性 | `Object.hasOwn(obj, "key")` | 比 `in` 更精确（不查原型链） |

## class 与原型速查

| 概念 | 说明 |
| --- | --- |
| `class Dog extends Animal` | 语法糖，底层仍是原型链 |
| `super()` | 子类构造器中必须先调用，才能使用 `this` |
| `#field` | 真正的私有字段，外部无法访问 |
| `static` | 挂在类本身而非实例上 |
| `get` / `set` | 属性访问器，可做校验 |
| `instanceof` | 沿原型链判断类型 |
| `Object.getPrototypeOf(obj)` | 查看原型对象 |
| `obj.hasOwnProperty(k)` | 是否为自身属性（推荐 `Object.hasOwn`） |

```js
class Counter {
  #count = 0;                       // 私有字段
  static created = 0;

  constructor() {
    Counter.created += 1;
  }

  increment() {
    this.#count += 1;
    return this;
  }

  get value() {
    return this.#count;
  }
}

new Counter().increment().increment().value;   // 2，支持链式调用
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `{ a: 1 } + { b: 2 }` | `"[object Object][object Object]"` | 对象相加会转字符串，用 `{ ...a, ...b }` |
| `Object.keys(null)` | `TypeError` | 先判空：`obj ? Object.keys(obj) : []` |
| 用 `for...in` 遍历对象 | 会带上原型链上的可枚举属性 | 用 `Object.entries` 或 `Object.hasOwn` 过滤 |
| 直接改 `state.user.name` | 引用未变，React 不刷新 | 逐层展开生成新对象，或用不可变库 |
| `const obj = { a: 1 }; Object.freeze(obj); obj.a = 2` | 静默失败（严格模式抛错） | 冻结只作用于当前层，嵌套结构要递归处理 |
| 用对象当 Map | 键会被转成字符串，`1` 与 `"1"` 冲突 | 需要任意键类型时用 `new Map()` |
| `JSON.parse(JSON.stringify(obj))` 深拷贝 | 丢失 `Date`、`undefined`、函数 | 需要完整深拷贝时用 `structuredClone` |
| `obj.constructor` 判断类型 | 容易被伪造 | 用 `instanceof` 或 `Object.getPrototypeOf` |
| 展开运算符拷贝嵌套对象 | 内层仍是共享引用 | 浅拷贝只复制第一层，嵌套要另行处理 |

## 自测清单

- [ ] 会用可选链与 `??` 处理缺失字段。
- [ ] 知道展开运算符是浅拷贝，能写出不可变更新的写法。
- [ ] 需要任意类型键时使用 `Map` 而不是普通对象。
- [ ] 记得子类构造器中先调用 `super()`。
- [ ] 用 `Object.hasOwn` 判断自有属性，避免原型链干扰。
