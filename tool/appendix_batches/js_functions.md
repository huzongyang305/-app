## this 绑定速查

| 调用方式 | `this` 指向 | 示例 |
| --- | --- | --- |
| 普通函数直接调用 | 严格模式下是 `undefined`，否则是全局对象 | `f()` |
| 方法调用 | 调用它的对象 | `obj.f()` |
| 显式绑定 | 传入的对象 | `f.call(obj)`、`f.apply(obj)` |
| 硬绑定 | 永久绑定的对象 | `f.bind(obj)` |
| `new` 调用 | 新创建的实例 | `new F()` |
| 箭头函数 | 定义时外层作用域的 `this` | 不能被 `call` / `bind` 改变 |
| 回调传方法引用后 | 丢失原对象 | `setTimeout(obj.f, 0)` 里的 `this` 不是 `obj` |

```js
const counter = {
  count: 0,
  // 方法简写：this 指向调用者
  increment() {
    this.count += 1;
    return this;
  },
  // 箭头函数继承外层 this，这里的外层是模块作用域，不适合当方法
  // reset: () => { this.count = 0; },
};

// 回调中保持 this 的三种写法
class Timer {
  constructor() { this.seconds = 0; }

  startWithBind() { setInterval(this.tick.bind(this), 1000); }
  startWithArrow() { setInterval(() => this.tick(), 1000); }
  tick() { this.seconds += 1; }
}
```

## 作用域与闭包速查

| 概念 | 说明 |
| --- | --- |
| 函数作用域 | `var` 声明提升到函数顶部 |
| 块级作用域 | `let` / `const` 只在 `{}` 内有效 |
| 暂时性死区 | `let` 声明前访问会 `ReferenceError` |
| 闭包 | 内层函数持有外层变量，外层返回后仍可访问 |
| 提升 | 函数声明整体提升，`var` 只提升声明 |
| 模块作用域 | 模块内变量默认不泄漏到全局 |

```js
// 闭包：计数器工厂
function createCounter() {
  let count = 0;
  return {
    inc: () => ++count,
    value: () => count,
  };
}

// 循环中捕获变量：let 每次迭代都创建新绑定
const fns = [];
for (let i = 0; i < 3; i++) fns.push(() => i);
console.log(fns.map((f) => f()));   // [0, 1, 2]
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把对象方法当回调传递 | `this` 丢失，报 `undefined` | 用箭头函数包一层或 `bind` |
| 给箭头函数用 `call` / `bind` | 不生效 | 箭头函数的 `this` 由定义位置决定 |
| 用普通函数写对象方法却用 `this` | 取决于调用方式 | 用方法简写并确保以 `obj.f()` 调用 |
| 在循环里用 `var` 创建闭包 | 所有闭包共享同一个变量 | 改用 `let` 或把值作为参数传入 |
| 默认参数用了前面的参数但顺序写反 | 得到 `undefined` | 默认参数按从左到右求值，只能引用更靠前的参数 |
| 参数超过 3 个仍按位置传 | 调用处难以理解 | 改用对象参数并解构 |
| 忘记 `return` | 得到 `undefined` | 检查每个分支都有返回值 |
| 箭头函数返回对象漏括号 | `SyntaxError` 或返回 `undefined` | 写成 `() => ({ a: 1 })` |
| 递归函数没有终止条件 | 栈溢出 | 先写基准情形 |
| 闭包长期持有大对象 | 内存占用高 | 用完置空引用或重构作用域 |

## 自测清单

- [ ] 能说出 `this` 的五种绑定规则与优先级。
- [ ] 知道箭头函数没有自己的 `this`、`arguments` 与 `new`。
- [ ] 会用闭包实现计数器或私有变量。
- [ ] 循环里创建闭包时使用 `let` 或参数传值。
- [ ] 参数较多时改用对象参数。
