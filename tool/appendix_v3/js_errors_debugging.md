## 零基础详解：错误处理与调试方法

### 一句话说清它是什么

错误处理让程序在出错时走可预期的分支，调试则是「在不知道原因时，用工具一步步缩小范围」。
关键在于：**先看报错类型，再定位行号，最后用断点验证猜测**。

### 用生活比喻理解

| 工具 | 比喻 | 说明 |
| --- | --- | --- |
| `try/catch` | 安全网 | 出问题时不至于整个掉下去 |
| `throw` | 主动报警 | 自己发现异常时上报 |
| `Error` 对象 | 病历 | 含类型、消息与调用栈 |
| 断点 | 暂停键 | 停在关键位置检查现场 |
| `console` 家族 | 记录仪 | 不同级别留痕 |

### 错误处理的完整结构

```javascript
class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = "ValidationError";
  }
}

function parseAge(raw) {
  const n = Number(raw);
  if (!Number.isInteger(n) || n < 0 || n > 150) {
    throw new ValidationError(`年龄不合法：${raw}`);
  }
  return n;
}

try {
  console.log(parseAge("abc"));
} catch (error) {
  if (error instanceof ValidationError) {
    console.warn("输入问题：", error.message);
  } else {
    console.error("意外错误：", error);       // 保留完整堆栈
    throw error;                              // 处理不了就继续往上抛
  }
} finally {
  console.log("处理结束");
}
```

### 异步代码的错误处理

```javascript
// Promise 方式
fetch("/api/user")
  .then((res) => {
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  })
  .catch((error) => console.error("请求失败：", error.message));

// async/await 方式（推荐）
async function loadUser() {
  try {
    const res = await fetch("/api/user");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch (error) {
    console.error("请求失败：", error.message);
    return null;
  }
}
```

**注意**：`await` 之后如果不加 `try/catch`，错误会变成未处理的 Promise 拒绝。

### console 家族与调试工具

| 方法 | 用途 |
| --- | --- |
| `console.log` | 普通输出 |
| `console.warn` / `error` | 警告与错误，可在面板过滤 |
| `console.table` | 数组或对象以表格展示 |
| `console.group` / `groupEnd` | 分组折叠 |
| `console.time` / `timeEnd` | 测量耗时 |
| `console.trace` | 打印调用栈 |
| `debugger` | 代码里直接下断点 |

```javascript
const users = [{ id: 1, name: "小明" }, { id: 2, name: "小红" }];
console.table(users);

console.time("解析");
// 一些耗时操作
console.timeEnd("解析");
```

### 断点调试的标准流程

1. **复现**：先找到稳定复现的步骤。
2. **定位**：在可疑函数入口打断点，看参数对不对。
3. **二分**：范围太大时，在中间位置验证，排除一半。
4. **验证**：看调用栈与作用域变量，确认是「数据错」还是「逻辑错」。
5. **收尾**：修完补一个测试或断言，避免复发。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `catch {}` 什么都不做 | 问题被完全掩盖 | 至少记录日志 |
| 只 `catch` 不 `throw` | 上层以为成功了 | 处理不了就继续抛 |
| 把 `console.log` 留在生产 | 泄露信息、性能损耗 | 提交前清理或用日志库 |
| 直接打印对象 | 看不到当前值 | 打印副本 `{...obj}` 或 `JSON.stringify` |
| 捕获了但丢掉了 `error` | 失去堆栈 | 打印 `error` 本身而不是 `error.message` |
| 在循环里吞异常 | 部分数据静默丢失 | 记录失败的条目与原因 |
| 依赖字符串比较错误信息 | 文案一变就失效 | 用自定义错误类与 `instanceof` |
| 忘了异步错误也需处理 | 出现未处理的拒绝 | 加 `try/catch` 或 `.catch` |

### 手把手练习：带容错的批量处理

```javascript
class DataError extends Error {
  constructor(index, reason) {
    super(`第 ${index} 条数据有问题：${reason}`);
    this.name = "DataError";
    this.index = index;
  }
}

function processAll(rows) {
  const ok = [];
  const failed = [];

  rows.forEach((row, i) => {
    try {
      const value = Number(row.value);
      if (!Number.isFinite(value)) throw new Error("不是数字");
      ok.push({ id: row.id, value });
    } catch (error) {
      failed.push(new DataError(i, error.message));
    }
  });

  return { ok, failed };
}

const result = processAll([
  { id: 1, value: "10" },
  { id: 2, value: "abc" },
  { id: 3, value: "30" },
]);

console.log(`成功 ${result.ok.length} 条，失败 ${result.failed.length} 条`);
for (const e of result.failed) console.warn(e.message);
```

### 学完自测

- [ ] 能写出自定义错误类并区分处理。
- [ ] 知道为什么不能写空的 `catch`。
- [ ] 能说出 `console.table`、`time`、`trace` 各自的用途。
- [ ] 知道断点调试的五步流程。
- [ ] 能说出异步代码里错误容易被漏掉的原因。
