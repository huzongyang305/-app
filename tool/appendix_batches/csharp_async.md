## async / await 速查

| 写法 | 含义 | 建议 |
| --- | --- | --- |
| `async Task FooAsync()` | 无返回值的异步方法 | 默认选择 |
| `async Task<T> FooAsync()` | 有返回值的异步方法 | 默认选择 |
| `async void FooAsync()` | 只能用于事件处理器 | 异常无法捕获，尽量不用 |
| `await task` | 异步等待，不阻塞线程 | 首选 |
| `task.Result` / `task.Wait()` | 同步阻塞等待 | 容易死锁，禁止在 UI/请求线程使用 |
| `Task.Run(() => ...)` | 把 CPU 密集工作丢到线程池 | IO 操作不需要它 |
| `Task.Delay(ms)` | 异步等待 | 别用 `Thread.Sleep` 阻塞线程 |
| `Task.WhenAll(tasks)` | 并发等待全部完成 | 注意收集每个任务的异常 |
| `Task.WhenAny(tasks)` | 等待最快完成的一个 | 常用于超时控制 |
| `CancellationToken` | 协作式取消 | 逐层传递，定期检查 |
| `ConfigureAwait(false)` | 不回到原同步上下文 | 库代码常用；UI 层一般不需要 |
| `await using` | 异步释放资源 | 适用于 `IAsyncDisposable` |

超时 + 取消的常见写法：

```csharp
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(3));
try
{
    var data = await client.GetStringAsync(url, cts.Token);
    Console.WriteLine(data.Length);
}
catch (OperationCanceledException)
{
    Console.WriteLine("请求超时或被取消");
}
```

并发执行多个请求：

```csharp
var tasks = urls.Select(u => client.GetStringAsync(u)).ToList();
string[] results = await Task.WhenAll(tasks);   // 总耗时接近最慢的一个
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `var s = FooAsync();` 没有 `await` | 拿到的是 `Task`，异常被吞 | 加上 `await`，或明确保存任务稍后处理 |
| `task.Result` | 可能死锁、线程被占满 | 改成 `await task` |
| `async void` 抛异常 | 进程可能直接崩溃 | 只用于事件处理器，并在内部 `try/catch` 全部包住 |
| `Thread.Sleep(1000)` 在异步方法里 | 阻塞线程 | 改成 `await Task.Delay(1000)` |
| `foreach` 里逐个 `await` | 串行执行，总耗时相加 | 无依赖时先收集任务，再 `WhenAll` |
| 忘记传 `CancellationToken` | 用户取消后请求仍在跑 | 逐层传递 token 并检查 |
| 在 `finally` 里 `await` 释放资源 | 代码冗长 | 用 `await using` |
| 并发访问同一个 `DbContext` | `InvalidOperationException` | DbContext 不是线程安全的，每个请求一个实例 |
| `.Wait()` 在 ASP.NET Core 请求线程 | 线程池饥饿 | 全链路异步：`async` 到底 |
| `Task.Run` 包住 IO 调用 | 白白占用线程池线程 | IO 本身是异步的，直接 `await` 即可 |

## 自测清单

- [ ] 默认返回 `Task` / `Task<T>`，只有事件处理器才用 `async void`。
- [ ] 全程 `await`，不使用 `.Result` 与 `.Wait()`。
- [ ] IO 密集用异步 API，CPU 密集才考虑 `Task.Run`。
- [ ] 对外方法都接受并传递 `CancellationToken`。
- [ ] 多个独立任务用 `Task.WhenAll` 并发执行。
