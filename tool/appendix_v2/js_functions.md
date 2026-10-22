## 零基础详解：函数、作用域与闭包

### 一句话说清它是什么

函数是「可以反复使用的代码块」。在 JavaScript 里函数是**一等公民**：
能赋给变量、当参数传、当返回值——这也是回调、Promise、React 的根基。

### 四种写法对照

```javascript
function add(a, b) { return a + b; }        // 函数声明，会被提升
const sub = function (a, b) { return a - b; };   // 函数表达式
const mul = (a, b) => a * b;                // 箭头函数（表达式体）

const obj = {
  value: 1,
  getValue() { return this.value; },        // 方法简写
};
```

| 写法 | `this` 绑定 | 能否当构造函数 | 提升 |
| --- | --- | --- | --- |
| 函数声明 | 调用时决定 | 能 | 是 |
| 函数表达式 | 调用时决定 | 能 | 否 |
| 箭头函数 | **继承外层** | 不能 | 否 |
| 方法简写 | 指向调用对象 | 不能 | —— |

### 箭头函数为什么不适合做对象方法

```javascript
const counter = {
  count: 0,
  bad() {
    setTimeout(() => this.count++, 10);   // 箭头函数继承外层 this：正确
  },
  wrong: () => {
    // 这里的 this 不是 counter，而是定义时的外层
  },
};
```

记忆：**箭头函数没有自己的 `this`，它借用外层的。** 该用它写回调，不该用它写对象方法。

### 参数的三件套

```javascript
function greet(name = "朋友", ...tags) {   // 默认值 + 剩余参数
  return `你好，${name}${tags.length ? "（" + tags.join("/") + "）" : ""}`;
}

greet();                     // 你好，朋友
greet("小明", "VIP", "新用户");   // 你好，小明（VIP/新用户）

// 解构参数：调用时传对象，顺序无关
function createUser({ name, age = 18 } = {}) {
  return { name, age };
}
createUser({ name: "小红" });   // { name: '小红', age: 18 }
```

### 作用域与闭包

```javascript
function makeCounter() {
  let count = 0;              // 外部访问不到
  return function () {
    count += 1;               // 但内部函数一直记得它
    return count;
  };
}

const next = makeCounter();
next();   // 1
next();   // 2
```

**闭包 = 函数 + 它出生时能看到的变量。** 哪怕外层函数已经执行完，
这些变量依然被保留。常见用途：计数器、缓存、防抖节流。

### 同步、回调与 Promise

```javascript
// 回调：容易嵌套过深
readFile("a.txt", (err, data) => {
  if (err) return console.error(err);
  console.log(data);
});

// Promise + async/await：像写同步代码一样
async function load() {
  try {
    const data = await readFileAsync("a.txt");
    console.log(data);
  } catch (error) {
    console.error("读取失败：", error);
  }
}
```

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忘写 `return` | 得到 undefined | 检查所有分支 |
| 箭头函数当方法 | `this` 指错 | 用方法简写 |
| 循环里创建函数用 `var` | 全部拿到最后一个值 | 用 `let` |
| 忘写 `await` | 拿到 Promise 对象 | 在 `async` 函数里 await |
| 参数顺序记错 | 传错值还查不出来 | 超过两个参数改用对象解构 |
| 以为对象赋值是复制 | 改副本影响原对象 | 展开拷贝 `{...obj}` |
| 递归无出口 | `RangeError: Maximum call stack size exceeded` | 先写终止条件 |

### 手把手练习：防抖函数

```javascript
function debounce(fn, delay = 300) {
  let timer = null;              // 闭包保存计时器
  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => fn.apply(this, args), delay);
  };
}

const search = debounce((keyword) => {
  console.log("搜索：", keyword);
}, 500);

search("a");
search("ab");
search("abc");   // 只有最后一次会被执行
```

### 学完自测

- [ ] 能说出箭头函数与普通函数在 `this` 上的区别。
- [ ] 能解释闭包为什么能「记住」外层变量。
- [ ] 能写出带默认值和剩余参数的函数。
- [ ] 能说出 `await` 用在非 `async` 函数里会发生什么。
- [ ] 能自己写出一个防抖或节流函数。
