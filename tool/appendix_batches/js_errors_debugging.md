## 错误类型速查

| 类型 | 典型原因 | 示例 |
| --- | --- | --- |
| `SyntaxError` | 语法错误 | 少括号、少逗号 |
| `ReferenceError` | 使用未声明的变量 | 拼写错误、作用域外访问 |
| `TypeError` | 类型不匹配或访问空值 | `undefined.foo`、调用非函数 |
| `RangeError` | 数值越界或栈溢出 | 递归过深、`new Array(-1)` |
| `URIError` | URI 编解码错误 | `decodeURIComponent("%")` |
| `AggregateError` | 多个错误聚合 | `Promise.any` 全部失败 |

调试手段速查：

| 手段 | 用法 | 适用场景 |
| --- | --- | --- |
| 断点 | 源码面板打断点 | 逐行观察变量 |
| 条件断点 | 设置表达式为真时暂停 | 循环中特定迭代 |
| `debugger` 语句 | 代码里直接写 | 快速定位入口 |
| 调用栈 | 面板查看 Call Stack | 找到真正的触发点 |
| 网络面板 | 查看请求与响应 | 接口问题 |
| `try / catch` | 捕获并记录 | 预期可能失败的代码 |
| 全局兜底 | `window.onerror`、`unhandledrejection` | 上报未捕获错误 |
| Source Map | 构建时生成并上传 | 定位压缩后的线上报错 |

```js
// 统一错误上报：捕获同步与异步未处理错误
window.addEventListener("error", (event) => {
  report(event.error ?? new Error(event.message), { type: "sync" });
});

window.addEventListener("unhandledrejection", (event) => {
  report(event.reason instanceof Error ? event.reason : new Error(String(event.reason)),
         { type: "promise" });
});

function report(error, extra) {
  // 生产环境只上报必要字段，避免泄露用户数据
  console.error(error, extra);
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `catch (e) { console.log("出错") }` | 丢失堆栈与原因 | 打印 `e` 本身，并上报到监控 |
| `throw "字符串"` | 没有堆栈 | 抛 `Error` 实例 |
| 自定义错误不继承 `Error` | 拿不到堆栈与 `instanceof` 判断 | `class MyError extends Error {}` |
| `catch` 后返回 `null` | 调用方继续访问字段报错 | 明确返回失败结果或重新抛出 |
| 用 `try` 包住整个函数 | 误捕获无关错误 | 只包可能失败的最小片段 |
| 异步错误用同步 `try` 包 | 捕获不到 | 需要 `await`，或 `.catch()` |
| `finally` 里 `return` | 覆盖 try 的返回值 | `finally` 只做清理 |
| 只在本地复现不了就放线上 | 用户先遇到问题 | 加 source map 与错误上报 |
| 报错日志不含上下文 | 无法定位用户与操作 | 带上请求 ID、用户标识与关键参数 |
| 生产环境打印完整对象 | 泄露敏感信息 | 只记录必要字段并脱敏 |

## 自测清单

- [ ] 能区分 `TypeError` 与 `ReferenceError` 的常见原因。
- [ ] 会用条件断点与调用栈定位偶发问题。
- [ ] 自定义错误继承 `Error` 并保留堆栈。
- [ ] 捕获异步错误时使用 `await` 或 `.catch()`。
- [ ] 生产环境接入了错误上报与 source map。
