## 零基础详解：async/await 与任务并行

### 一句话说清它是什么

`async/await` 让「等待 IO」的代码写起来像同步代码，但线程不会被卡住。
核心区别只有一句话：**IO 密集用 async，CPU 密集用并行任务**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| `Task` | 取件凭条 | 代表一件正在做的事 |
| `await` | 等叫号 | 等待期间可以去做别的 |
| `Task.WhenAll` | 一起等所有单子 | 并发而不是串行 |
| `CancellationToken` | 取消按钮 | 让任务可以中途停止 |
| `ConfigureAwait(false)` | 不指定回到原岗位 | 库代码里减少上下文切换 |

### 从阻塞到异步

```csharp
// 阻塞写法：线程被占用，无法处理其它请求
string text = File.ReadAllText("data.txt");

// 异步写法：等待期间线程可以去做别的事
string text2 = await File.ReadAllTextAsync("data.txt");
```

**口诀**：方法名以 `Async` 结尾、返回 `Task` 或 `Task<T>`、内部有 `await`。

### 三种返回类型

| 返回类型 | 何时用 |
| --- | --- |
| `Task` | 异步但没有返回值 |
| `Task<T>` | 异步且有返回值 |
| `ValueTask<T>` | 高频调用且常常同步完成（进阶） |
| `async void` | **只用于事件处理器**，异常无法被捕获 |

### 串行与并发的差别

```csharp
// 串行：总耗时约等于各任务之和
var a = await FetchAsync("a");
var b = await FetchAsync("b");
var c = await FetchAsync("c");

// 并发：总耗时约等于最慢的那个
var tasks = new[] { FetchAsync("a"), FetchAsync("b"), FetchAsync("c") };
var results = await Task.WhenAll(tasks);
```

| 方法 | 行为 |
| --- | --- |
| `Task.WhenAll` | 等全部完成；任一失败则抛异常 |
| `Task.WhenAny` | 等第一个完成 |
| `Task.WhenEach` | 完成一个就处理一个（.NET 9+） |
| `Task.Run` | 把 CPU 密集工作丢到线程池 |

### 取消与超时

```csharp
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(3));

try
{
    var data = await FetchAsync(url, cts.Token);
    Console.WriteLine(data);
}
catch (OperationCanceledException)
{
    Console.WriteLine("请求超时或被取消");
}

static async Task<string> FetchAsync(string url, CancellationToken token)
{
    using var http = new HttpClient();
    var res = await http.GetStringAsync(url, token);     // 把 token 传到底
    return res;
}
```

**取消要一路传下去**：只在外层判断 `token.IsCancellationRequested` 而不传给底层调用，是无效取消。

### 什么时候不需要 async

```csharp
// 只是转发：不用 async，直接返回 Task 更省一次状态机
public Task<string> GetAsync() => _client.GetStringAsync("/api");

// 反例：包一层却没有任何额外逻辑
public async Task<string> GetAsyncBad()
    => await _client.GetStringAsync("/api");
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 `.Result` 或 `.Wait()` | 可能死锁、线程被占用 | 一路 `await` 到底 |
| `async void` | 异常无法捕获，进程崩溃 | 除事件处理器外都用 `Task` |
| 循环里逐个 await | 慢几倍 | 收集任务后用 `WhenAll` |
| 忘了传 `CancellationToken` | 取消失效 | 参数一路传到底 |
| 在锁里 `await` | 死锁或异常 | 不在锁内等待异步 |
| 并发访问 `HttpClient` 时反复 new | 端口耗尽 | 复用静态 `HttpClient` 或工厂 |
| 把 CPU 密集任务直接 async | 那只是同步阻塞 | 用 `Task.Run` 放到线程池 |
| 库代码到处 `ConfigureAwait(true)` | 上下文切换开销 | 库内用 `ConfigureAwait(false)` |

### 手把手练习：并发抓取并容错

```csharp
using System.Net.Http.Json;

record Post(int Id, string Title);

static async Task Main()
{
    using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
    using var http = new HttpClient { BaseAddress = new Uri("https://example.com") };

    var ids = Enumerable.Range(1, 5);
    var tasks = ids.Select(async id =>
    {
        try
        {
            var post = await http.GetFromJsonAsync<Post>(
                $"/api/posts/{id}", cts.Token);
            return (Id: id, Title: post?.Title ?? "无标题", Error: (string?)null);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            return (Id: id, Title: "", Error: ex.Message);
        }
    });

    var results = await Task.WhenAll(tasks);
    foreach (var r in results)
    {
        Console.WriteLine(r.Error is null
            ? $"{r.Id}: {r.Title}"
            : $"{r.Id}: 失败 - {r.Error}");
    }
}
```

### 学完自测

- [ ] 能说出同步阻塞与异步等待的区别。
- [ ] 知道 `async void` 为什么危险。
- [ ] 能说出串行 await 与 `Task.WhenAll` 的性能差异。
- [ ] 知道取消为什么要一路传递 `CancellationToken`。
- [ ] 能判断一个场景该用 async 还是 `Task.Run`。
