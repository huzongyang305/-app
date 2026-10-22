## 异常体系速查

| 类型 | 是否受检 | 典型例子 | 处理建议 |
| --- | --- | --- | --- |
| `Error` | 否 | `OutOfMemoryError`、`StackOverflowError` | 不捕获，交给进程处理 |
| 受检异常 | 是 | `IOException`、`SQLException` | 必须捕获或声明抛出 |
| 运行时异常 | 否 | `NullPointerException`、`IllegalArgumentException` | 修代码，少捕获 |

常用写法速查：

| 目的 | 写法 |
| --- | --- |
| 捕获并记录 | `catch (IOException e) { log.error("读取失败", e); }` |
| 多类型同处理 | `catch (IOException \| SQLException e) { ... }` |
| 重新抛出并保留原因 | `throw new ServiceException("下单失败", e);` |
| 自动关闭资源 | `try (var in = new FileInputStream(path)) { ... }` |
| 无异常时执行 | `try { ... } catch (...) { ... }` 之后写正常逻辑 |
| 一定执行的清理 | `finally { ... }` |
| 断言参数 | `Objects.requireNonNull(id, "id 不能为空")` |
| 校验参数合法性 | `if (n < 0) throw new IllegalArgumentException("n 必须非负");` |
| 自定义异常 | `class OrderException extends RuntimeException { ... }` |

```java
public Order createOrder(OrderRequest request) {
    Objects.requireNonNull(request, "request 不能为空");
    if (request.items().isEmpty()) {
        throw new IllegalArgumentException("订单不能为空");
    }
    try {
        return repository.save(request.toEntity());
    } catch (DataAccessException e) {
        // 保留原始异常，便于排查根因
        throw new OrderCreateException("保存订单失败", e);
    }
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `catch (Exception e) { }` | 异常被吞，问题难以发现 | 至少记录日志，只捕获能处理的异常 |
| `e.printStackTrace()` | 日志框架里丢失上下文 | 用 `log.error("上下文", e)` |
| 在 `finally` 里 `return` | 覆盖返回值、吞掉异常 | `finally` 只做资源释放 |
| 用异常控制正常流程 | 性能差、语义混乱 | 用返回值或 `Optional` 表达预期分支 |
| 丢失原始异常 | 只剩一句「失败了」 | 构造新异常时传入 `cause` |
| 捕获后不做处理也不抛 | 上层以为成功 | 记录并重新抛出，或返回明确失败结果 |
| 自定义异常继承 `Throwable` | 语义过重，可能不被常规捕获 | 业务异常继承 `RuntimeException` 或 `Exception` |
| `try` 块里包含大量无关代码 | 误捕获、定位困难 | `try` 只包最小可能失败的片段 |
| 忘记关闭资源 | 文件句柄与连接泄漏 | 用 try-with-resources |
| 受检异常在 `lambda` 里直接抛 | 编译不通过 | 包装成运行时异常，或在 lambda 内处理 |

## 自测清单

- [ ] 分得清受检异常、运行时异常与 `Error` 的处理策略。
- [ ] 捕获时始终传原始异常作为 cause。
- [ ] 用 try-with-resources 管理需要关闭的资源。
- [ ] 参数校验用 `Objects.requireNonNull` 与 `IllegalArgumentException`。
- [ ] 日志用占位符并带上异常对象，不用 `printStackTrace`。
