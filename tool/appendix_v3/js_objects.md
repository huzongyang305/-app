## 零基础详解：对象、原型与解构

### 一句话说清它是什么

对象是「键值对的集合」，用来描述一个东西的多个属性。
JavaScript 的对象还很特别：**它通过原型链继承属性**，这是理解 `this`、`class`、继承的关键。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 对象 | 一张信息卡 | 上面写着姓名、年龄等字段 |
| 属性 | 卡片上的条目 | `user.name` |
| 方法 | 卡片能做的事 | `user.greet()` |
| 原型 | 家族遗传 | 自己没有的属性，去祖先那里找 |
| 解构 | 按需摘取 | `const { name } = user` |

### 创建对象的四种写法

```javascript
// 1. 字面量：最常用
const user = { id: 1, name: "小明", greet() { return `你好，${this.name}`; } };

// 2. 构造函数
function Point(x, y) { this.x = x; this.y = y; }
const p = new Point(1, 2);

// 3. class 语法（本质仍是原型）
class Person {
  constructor(name) { this.name = name; }
  greet() { return `你好，${this.name}`; }
}

// 4. Object.create：显式指定原型
const base = { kind: "animal" };
const cat = Object.create(base);
```

### 属性访问与键的三种情况

```javascript
const user = { name: "小明", "user-id": 7 };

user.name;                  // 点号：键是合法标识符时用
user["user-id"];            // 方括号：键含横线、空格或来自变量
const key = "name";
user[key];                  // 动态键只能用方括号

user.age;                   // undefined，不报错
user.address?.city;         // 可选链，避免报错
user.age ?? 18;             // 空值合并给默认值
```

### 解构与展开

```javascript
const user = { id: 1, name: "小明", role: "admin" };

const { name, role = "guest" } = user;        // 解构 + 默认值
const { name: userName } = user;              // 改名
const { address: { city } = {} } = user;      // 嵌套解构并兜底

const copy = { ...user, role: "user" };       // 浅拷贝并覆盖字段
const merged = { ...defaults, ...options };   // 合并配置，后者优先
```

### 原型链：找不到就往上找

```javascript
const animal = { eats: true };
const rabbit = Object.create(animal);
rabbit.jumps = true;

console.log(rabbit.jumps);   // true，自己的属性
console.log(rabbit.eats);    // true，来自原型
console.log("eats" in rabbit);            // true，含原型链
console.log(Object.hasOwn(rabbit, "eats"));   // false，只查自己
```

属性查找顺序：**自己 → 原型 → 原型的原型 → … → null**。

### `this` 的四条规则

| 调用方式 | `this` 指向 |
| --- | --- |
| `obj.method()` | `obj` 本身 |
| `fn()` 直接调用 | 严格模式下是 `undefined` |
| `new Fn()` | 新建的对象 |
| 箭头函数 | 继承定义时的外层 `this`，不受调用方式影响 |

```javascript
const counter = {
  count: 0,
  inc() { this.count += 1; },                  // 正常：this 是 counter
};
counter.inc();

const bad = counter.inc;
// bad();   // 严格模式下报错，因为 this 丢了
const safe = counter.inc.bind(counter);        // 绑定后可以单独传
```

### 判断属性是否存在

| 写法 | 是否含原型 | 值为 0 或 "" 时的表现 |
| --- | --- | --- |
| `"k" in obj` | 含 | 正确返回 true |
| `Object.hasOwn(obj, "k")` | 只查自身 | 正确返回 true |
| `obj.k !== undefined` | 含（沿链） | 正确返回 true |
| `if (obj.k)` | 含 | **误判为 false** |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `if (obj.k)` 判存在 | 0、空串被当成不存在 | 用 `in` 或 `Object.hasOwn` |
| 对象赋值当复制 | 改一处全变 | 用展开做浅拷贝 |
| 浅拷贝嵌套对象 | 内层仍互相影响 | 用 `structuredClone` |
| 方法被单独取出 | `this` 丢失 | 用 `bind` 或箭头函数 |
| 遍历时用 `for...in` | 拿到继承来的键 | 用 `Object.keys` 或 `entries` |
| 用对象当 Map | 键只能是字符串或 Symbol | 需要任意类型键就用 `Map` |
| 删除属性用 `= undefined` | 键还在 | 用 `delete obj.k` |
| 比较对象用 `===` | 比的是引用 | 逐字段比较或用 `JSON.stringify` |

### 手把手练习：合并配置与安全取值

```javascript
const defaults = { theme: "light", pageSize: 20, features: { dark: false } };
const userConfig = { pageSize: 50 };

const config = { ...defaults, ...userConfig };
console.log(config.pageSize);            // 50

// 嵌套合并要手动处理，展开是浅拷贝
const merged = {
  ...defaults,
  ...userConfig,
  features: { ...defaults.features, ...(userConfig.features ?? {}) },
};

// 安全取深层属性
const darkEnabled = merged?.features?.dark ?? false;
console.log(darkEnabled);

// 遍历并过滤
const entries = Object.entries(merged).filter(([, v]) => typeof v !== "object");
console.log(entries);
```

### 学完自测

- [ ] 能说出对象属性查找的顺序。
- [ ] 能解释 `in` 与 `Object.hasOwn` 的区别。
- [ ] 知道为什么展开运算符做的是浅拷贝。
- [ ] 能说出 `this` 在四种调用方式下的指向。
- [ ] 需要任意类型作键时，知道该用 `Map` 而不是对象。
