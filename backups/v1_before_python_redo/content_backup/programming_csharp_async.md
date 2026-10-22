# 异步编程与异常处理

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：60 分钟

![async/await 的调用链与取消](images/diagram_cs_async.webp)

![异步编程与异常处理](images/remaining_csharp_async.webp)

## 本节知识框架

**课程定位**：所属分类 `csharp`（C#），课程主题 `异步编程与异常处理`，学习阶段 进阶，建议用时 55 分钟。

本课主线：async/await、Task 并发、CancellationToken、异常与 using。

**学完本课应当能够**
- 说清 `async` 与 `CancellationTokenSource` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `IDisposable` 的行为，记录输入、输出与失败条件。
- 遇到「用 `.Result` 或 `.Wait()`」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `async`：先掌握 `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景，再用它解释 `CancellationTokenSource` 为什么会出现。
2. `CancellationTokenSource`：先掌握 用 `CancellationTokenSource` 实现超时：，再用它解释 `IDisposable` 为什么会出现。
3. `IDisposable`：先掌握 实现 `IDisposable` 的对象用 `using` 自动释放：，再用它解释 `配置等待` 为什么会出现。
4. `配置等待`：先掌握 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁，再用它解释 `取消` 为什么会出现。
5. `取消`：先掌握 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「C#」分类的第 12 课。先修内容：《集合、委托与 LINQ》。《集合、委托与 LINQ》里的 `List`、`Dictionary` 是本课的前提。相关或后续课程：《生态、测试与 Web 开发》、《Swift 并发与 async/await》、《异步编程》。

### 完成判据

- **定义关**：不看正文也能说明 `async` 是 `async` 方法返回 `Task` / `Task<T>`，`await` 在等待期间释放线程，因此特别适合 IO 密集场景，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `异步编程与异常处理`，而不是只背结论。
- **示例关**：能运行或推演 `异步编程与异常处理` 的 `csharp` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `异步编程与异常处理` 示例里的 调用了 `LoadAsync()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 用 `.Result` 或 `.Wait()`，记录现象并按 一路 `await` 到底 修复。
- **迁移关**：能把 `async`、`await`、`Task`、`CancellationToken` 放进一个与 `异步编程与异常处理` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `异步编程与异常处理` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| async | async 方法返回 Task / Task<T>；await 在等待期间释放线程，因此特别适合 IO 密集场景。 | 易错：异常无法捕获，进程崩溃；正确做法是除事件处理器外都用 `Task`。 |
| CancellationTokenSource | 用 CancellationTokenSource 实现超时： | 网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。 |
| IDisposable | 实现 IDisposable 的对象用 using 自动释放： | 越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。 |
| 配置等待 | 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁。 | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |
| 取消 | 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消 | 易错：取消失效；正确做法是参数一路传到底。 |

## 原理与运行机制

### 机制总览

**教材衔接：版本与时效**

- 先确认 SDK 版本，再决定 HttpRequestException 是否可以使用新语法或新 API。
- 升级重点在语法与裁剪行为；先为 await 补一组回归用例。
- 升级前先用 HttpRequestException 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。
- 官方说明：https://learn.microsoft.com/dotnet/core/whats-new/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 async 相关的差异单独记成一条结论。
- 升级后重点回归 async 的默认值、警告信息与错误格式。
- 升级后把 HttpRequestException 的实测版本写进「内容元数据」，再更新复核日期。

**失败路径（来自本课错误表）**
- 用 `.Result` 或 `.Wait()` → 可能死锁、线程被占用 → 一路 `await` 到底。
- `async void` → 异常无法捕获，进程崩溃 → 除事件处理器外都用 `Task`。
- 循环里逐个 await → 慢几倍 → 收集任务后用 `WhenAll`。
- 忘了传 `CancellationToken` → 取消失效 → 参数一路传到底。
### 机制拆解：每一步的输入、动作与输出

#### 1. `async`
- 输入：`async`；本步把 `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景 当作判断规则。
- 动作：围绕 `async` 保留中间状态，并记录它与 `CancellationTokenSource` 的对应关系。
- 输出：`CancellationTokenSource`，它可以被下一段代码、测试或记录继续使用。
- `async` 的失败条件：当`async void`时，会出现异常无法捕获，进程崩溃。

#### 2. `CancellationTokenSource`
- 输入：`async`；本步把 用 `CancellationTokenSource` 实现超时： 当作判断规则。
- 动作：围绕 `CancellationTokenSource` 保留中间状态，并记录它与 `IDisposable` 的对应关系。
- 输出：`IDisposable`，它可以被下一段代码、测试或记录继续使用。
- `CancellationTokenSource` 的失败条件：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。

#### 3. `IDisposable`
- 输入：`CancellationTokenSource`；本步把 实现 `IDisposable` 的对象用 `using` 自动释放： 当作判断规则。
- 动作：围绕 `IDisposable` 保留中间状态，并记录它与 `配置等待` 的对应关系。
- 输出：`配置等待`，它可以被下一段代码、测试或记录继续使用。
- `IDisposable` 的失败条件：越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。

#### 4. `配置等待`
- 输入：`IDisposable`；本步把 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁 当作判断规则。
- 动作：围绕 `配置等待` 保留中间状态，并记录它与 `取消` 的对应关系。
- 输出：`取消`，它可以被下一段代码、测试或记录继续使用。
- `配置等待` 的失败条件：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

#### 5. `取消`
- 输入：`配置等待`；本步把 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消 当作判断规则。
- 动作：围绕 `取消` 保留中间状态，并记录它与 `LoadAsync` 的对应关系。
- 输出：`LoadAsync`，它可以被下一段代码、测试或记录继续使用。
- `取消` 的失败条件：当忘了传 `CancellationToken`时，会出现取消失效。

### 示例中的可观察事实

1. 调用了 `LoadAsync()`；它对应的课程主题是 `异步编程与异常处理`。
2. 调用了 `HttpClient()`；它对应的课程主题是 `异步编程与异常处理`。
3. 调用了 `GetStringAsync()`；它对应的课程主题是 `异步编程与异常处理`。
4. 调用了 `RunAsync()`；它对应的课程主题是 `异步编程与异常处理`。
5. 调用了 `WriteLine()`；它对应的课程主题是 `异步编程与异常处理`。
6. 出现字面量 `https://example.com`；它对应的课程主题是 `异步编程与异常处理`。
7. 出现字面量 `网络错误：{ex.Message}`；它对应的课程主题是 `异步编程与异常处理`。
8. 调用了 `ProcessAsync()`；它对应的课程主题是 `异步编程与异常处理`。

### 复现实验记录

- 环境：`异步编程与异常处理` 使用 `csharp` 示例，固定 `async`、`await`、`Task`、`CancellationToken` 作为第一组条件。
- 首轮输入：先确认 调用了 `LoadAsync()`，预测 `async` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `async`，观察 `取消` 是否仍满足定义。
- 失败注入：复现 用 `.Result` 或 `.Wait()`，确认现象是 可能死锁、线程被占用。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `异步编程与异常处理` 时才能区分概念错误与实现错误。

## 典型应用场景

**课程内置实验入口**：`sandbox:csharp`，用于动手验证《异步编程与异常处理》的机制；实验结论不替代概念定义与复杂度分析。

- **用 `.Result` 或 `.Wait()`**：典型现象是可能死锁、线程被占用；正确做法是一路 `await` 到底。
- **`async void`**：典型现象是异常无法捕获，进程崩溃；正确做法是除事件处理器外都用 `Task`。
- **循环里逐个 await**：典型现象是慢几倍；正确做法是收集任务后用 `WhenAll`。
- **忘了传 `CancellationToken`**：典型现象是取消失效；正确做法是参数一路传到底。

### 最小验证场景

- 准备：保留 `csharp` 示例的原始输入，先记录 `异步编程与异常处理` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `LoadAsync()`，再改变一个与 `async` 相关的条件。
- 判定：新结果与 `异步编程与异常处理` 的基线不同不等于错误；只有当差异破坏了 `async` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `async` 时，先满足它的定义：`async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景；易错：异常无法捕获，进程崩溃；正确做法是除事件处理器外都用 `Task`。
- 使用 `CancellationTokenSource` 时，先满足它的定义：用 `CancellationTokenSource` 实现超时：；网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。
- 使用 `IDisposable` 时，先满足它的定义：实现 `IDisposable` 的对象用 `using` 自动释放：；越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。
- 使用 `配置等待` 时，先满足它的定义：决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁；共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。
- 使用 `取消` 时，先满足它的定义：取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消；易错：取消失效；正确做法是参数一路传到底。

## 代码/协议/SQL 示例

### 最小可验证示例

```csharp
public async Task<string> LoadAsync(string url, CancellationToken token)
{
    using var client = new HttpClient();
    string content = await client.GetStringAsync(url, token);
    return content;
}

public async Task RunAsync()
{
    try
    {
        string data = await LoadAsync("https://example.com", CancellationToken.None);
        Console.WriteLine(data.Length);
    }
    catch (HttpRequestException ex)
    {
        Console.WriteLine($"网络错误：{ex.Message}");
    }
}
```

**教材衔接：async / await**

`async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景。

**教材衔接：异常与资源释放**

```csharp
try
{
    await ProcessAsync();
}
catch (InvalidOperationException ex) when (ex.Message.Contains("retry"))
{
    // 异常筛选器：只处理特定情况
}
catch (Exception ex)
{
    Console.Error.WriteLine(ex);
    throw;                       // 保留原始堆栈重新抛出
}
finally
{
    Console.WriteLine("清理完成");
}
```

实现 `IDisposable` 的对象用 `using` 自动释放：

```csharp
using var stream = File.OpenRead("data.txt");
using var reader = new StreamReader(stream);
string? line;
while ((line = await reader.ReadLineAsync()) != null)
{
    Console.WriteLine(line);
}
```

**教材衔接：async / await 速查**

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

**教材衔接：零基础详解：async/await 与任务并行**

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

**运行方式**：运行 `异步编程与异常处理` 的示例时，用 `dotnet run` 运行；先确认 SDK 版本与项目文件一致。

### 示例精读：先找证据，再改一个条件

1. 调用了 `LoadAsync()`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `HttpClient()`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `GetStringAsync()`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `RunAsync()`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `WriteLine()`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
6. 出现字面量 `https://example.com`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
7. 出现字面量 `网络错误：{ex.Message}`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `ProcessAsync()`；它出现在 `异步编程与异常处理` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `异步编程与异常处理` 中与 `async` 对照：示例必须能支持 `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景，否则说明这一段还缺少实现或验证步骤。
- 在 `异步编程与异常处理` 中与 `CancellationTokenSource` 对照：示例必须能支持 用 `CancellationTokenSource` 实现超时：，否则说明这一段还缺少实现或验证步骤。
- 在 `异步编程与异常处理` 中与 `IDisposable` 对照：示例必须能支持 实现 `IDisposable` 的对象用 `using` 自动释放：，否则说明这一段还缺少实现或验证步骤。
- 在 `异步编程与异常处理` 中与 `配置等待` 对照：示例必须能支持 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（异步编程与异常处理）**：GC 与异步调度影响开销：记录吞吐、延迟与分配速率。

**本课特有开销（异步编程与异常处理 · async）**：并发度提高后要观察是否出现拐点：延迟上升而吞吐不增，说明瓶颈已转移。

**测量方法**：以 `异步编程与异常处理` 的 `async` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `异步编程与异常处理` 的 `async`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异步编程与异常处理` 的 `await`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异步编程与异常处理` 的 `Task`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异步编程与异常处理` 的 `CancellationToken`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异步编程与异常处理` 的 `IDisposable`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异步编程与异常处理` 中 `async` 的边界：易错：异常无法捕获，进程崩溃；正确做法是除事件处理器外都用 `Task`。达到边界时不要外推，必须重新测量。
- `异步编程与异常处理` 中 `CancellationTokenSource` 的边界：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。达到边界时不要外推，必须重新测量。
- `异步编程与异常处理` 中 `IDisposable` 的边界：越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。达到边界时不要外推，必须重新测量。
- `异步编程与异常处理` 中 `配置等待` 的边界：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。达到边界时不要外推，必须重新测量。
- `异步编程与异常处理` 中 `取消` 的边界：易错：取消失效；正确做法是参数一路传到底。达到边界时不要外推，必须重新测量。
- `异步编程与异常处理` 的代码证据：先验证 调用了 `LoadAsync()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `.Result` 或 `.Wait()` | 可能死锁、线程被占用 | 一路 `await` 到底 |
| `async void` | 异常无法捕获，进程崩溃 | 除事件处理器外都用 `Task` |
| 循环里逐个 await | 慢几倍 | 收集任务后用 `WhenAll` |
| 忘了传 `CancellationToken` | 取消失效 | 参数一路传到底 |
| 在锁里 `await` | 死锁或异常 | 不在锁内等待异步 |
| 并发访问 `HttpClient` 时反复 new | 端口耗尽 | 复用静态 `HttpClient` 或工厂 |
| 把 CPU 密集任务直接 async | 那只是同步阻塞 | 用 `Task.Run` 放到线程池 |
| 库代码到处 `ConfigureAwait(true)` | 上下文切换开销 | 库内用 `ConfigureAwait(false)` |
| var s = FooAsync(); 没有 await | 拿到的是 Task，异常被吞。 | 加上 await，或明确保存任务稍后处理。 |
| task.Result | 可能死锁、线程被占满。 | 改成 await task。 |
| async void 抛异常 | 进程可能直接崩溃。 | 只用于事件处理器，并在内部 try/catch 全部包住。 |

### 现场 1：用 `.Result` 或 `.Wait()`

**症状**：可能死锁、线程被占用。

**根因与修复**：一路 `await` 到底。

**自检**：在本课示例里复现「用 `.Result` 或 `.Wait()`」，改成一路 `await` 到底后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：`async void`

**症状**：异常无法捕获，进程崩溃。

**根因与修复**：除事件处理器外都用 `Task`。

**自检**：在本课示例里复现「`async void`」，改成除事件处理器外都用 `Task`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：循环里逐个 await

**症状**：慢几倍。

**根因与修复**：收集任务后用 `WhenAll`。

**自检**：在本课示例里复现「循环里逐个 await」，改成收集任务后用 `WhenAll`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：忘了传 `CancellationToken`

**症状**：取消失效。

**根因与修复**：参数一路传到底。

**自检**：在本课示例里复现「忘了传 `CancellationToken`」，改成参数一路传到底后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：在锁里 `await`

**症状**：死锁或异常。

**根因与修复**：不在锁内等待异步。

**自检**：在本课示例里复现「在锁里 `await`」，改成不在锁内等待异步后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：并发访问 `HttpClient` 时反复 new

**症状**：端口耗尽。

**根因与修复**：复用静态 `HttpClient` 或工厂。

**自检**：在本课示例里复现「并发访问 `HttpClient` 时反复 new」，改成复用静态 `HttpClient` 或工厂后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：把 CPU 密集任务直接 async

**症状**：那只是同步阻塞。

**根因与修复**：用 `Task.Run` 放到线程池。

**自检**：在本课示例里复现「把 CPU 密集任务直接 async」，改成用 `Task.Run` 放到线程池后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：库代码到处 `ConfigureAwait(true)`

**症状**：上下文切换开销。

**根因与修复**：库内用 `ConfigureAwait(false)`。

**自检**：在本课示例里复现「库代码到处 `ConfigureAwait(true)`」，改成库内用 `ConfigureAwait(false)`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：var s = FooAsync(); 没有 await

**症状**：拿到的是 Task，异常被吞。

**根因与修复**：加上 await，或明确保存任务稍后处理。

**自检**：在本课示例里复现「var s = FooAsync(); 没有 await」，改成加上 await，或明确保存任务稍后处理后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`集合、委托与 LINQ`。本课默认这些内容已经掌握。
- **相关或后续**：`生态、测试与 Web 开发`、`Swift 并发与 async/await`、`异步编程`。本课术语会在这些课程里继续使用。
- **术语归属**：`async`、`CancellationTokenSource`、`IDisposable` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《C# 异步流与取消》也涉及 `CancellationToken`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `Swift 并发与 async/await`：共享术语 `async`，共同关键词 `async`、`Task`。
- `异步编程`：共享术语 `async`，共同关键词 `async`、`await`。
- `集合、委托与 LINQ`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `生态、测试与 Web 开发`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `async` 与 `CancellationTokenSource`：前者强调 `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景；后者强调 用 `CancellationTokenSource` 实现超时。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `CancellationTokenSource` 与 `IDisposable`：前者强调 用 `CancellationTokenSource` 实现超时：；后者强调 实现 `IDisposable` 的对象用 `using` 自动释放。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `IDisposable` 与 `配置等待`：前者强调 实现 `IDisposable` 的对象用 `using` 自动释放：；后者强调 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `配置等待` 与 `取消`：前者强调 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁；后者强调 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `async` 的操作性定义，并说明它与 `CancellationTokenSource` 的区别。

**参考答案**：`async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景。

`CancellationTokenSource` 的定位是：用 `CancellationTokenSource` 实现超时：；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「用 `.Result` 或 `.Wait()`」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是可能死锁、线程被占用；正确做法是一路 `await` 到底。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `csharp` 示例，把其中的 `"https://example.com"` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `csharp` 示例应当复现正文给出的结果；把 `"https://example.com"` 换成边界值后，如果结果改变或报错，先核对它是否满足 `异步编程与异常处理` 中`async` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `csharp` 示例，说明它体现了`async` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`async` 的定义是 `async` 方法返回 `Task` / `Task<T>`，`await` 在等待期间释放线程，因此特别适合 IO 密集场景，示例正是在实现这条定义。改动与 `async` 有关的一个输入后，如果结果不再符合 `异步编程与异常处理` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `异步编程与异常处理` 的方法迁移到自己的项目：围绕 `async` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「async void 抛异常」，它会导致进程可能直接崩溃；检验方式是按只用于事件处理器，并在内部 try/catch 全部包住改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `async` 与 `CancellationTokenSource`：各写一行适用场景、一行失败表现。

**参考答案**：`async` 的定义是`async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景；`CancellationTokenSource` 的定义是用 `CancellationTokenSource` 实现超时。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「用 `.Result` 或 `.Wait()`」引发的问题，请把“复现 可能死锁、线程被占用 → 保留证据 → 一路 `await` 到底 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按可能死锁、线程被占用复现；第二步记录输入、版本与完整报错；第三步按一路 `await` 到底只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `取消`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：易错：取消失效；正确做法是参数一路传到底。 同时要把 `取消` 的定义 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `async` → `CancellationTokenSource` → `IDisposable` → `配置等待` 的作用链。

**参考答案**：起点是 `async` 的定义 `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景；中间每一步都保留可观察状态；终点由 `取消` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `异步编程与异常处理` 中，现象是 进程可能直接崩溃。请围绕 async void 抛异常 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 async void 抛异常，记录输入与完整错误；再按 只用于事件处理器，并在内部 try/catch 全部包住 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `异步编程与异常处理`：先给主问题，再按顺序说出 `async`、`CancellationTokenSource`、`IDisposable`、`配置等待`，最后给一个失败案例。

**自评标准**：主问题必须对应 async/await、Task 并发、CancellationToken、异常与 using；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `async` | `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景。 |
| `CancellationTokenSource` | 用 `CancellationTokenSource` 实现超时。 |
| `IDisposable` | 实现 `IDisposable` 的对象用 `using` 自动释放。 |
| `配置等待` | 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁。 |
| `取消` | 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消。 |

**术语关系**：`async`（`async` 方法返回 `Task` / `Task<T>`） → `CancellationTokenSource`（用 `CancellationTokenSource` 实现超时：） → `IDisposable`（实现 `IDisposable` 的对象用 `using` 自动释放：） → `配置等待`（决定 await 恢复时是否需要回到原来的同步上下文）。

## 考点精讲

`异步编程与异常处理` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：使用 await 等待 IO 的主要好处是？
- **正确项**：等待期间不阻塞线程
- **判断依据**：这道题检验本课主问题：async/await、Task 并发、CancellationToken、异常与 using。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 2：第 2 题

- **题目**：在异步代码中使用 .Result 或 .Wait 的风险是？
- **正确项**：可能死锁并阻塞线程
- **判断依据**：这道题检验本课主问题：async/await、Task 并发、CancellationToken、异常与 using。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 3：第 3 题

- **题目**：代码语言为 `csharp`，选自 `异步编程与异常处理` 的 `async` 部分。课程问题为async/await、Task 并发、CancellationToken、异常与 using。哪一项描述与代码一致？
- **正确项**：出现字面量 `retry`
- **判断依据**：这道题落在术语 `async` 上：`async` 方法返回 `Task` / `Task<T>`，`await` 在等待期间释放线程，因此特别适合 IO 密集场景。复习时把 `async` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：围绕“异步编程与异常处理”中的 async、await、Task，下列哪两项是本课强调的实践判断？
- **正确项**：验证 await 时要固定版本并覆盖边界输入，结论才可复现；学习 async 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `async` 上：`async` 方法返回 `Task` / `Task<T>`，`await` 在等待期间释放线程，因此特别适合 IO 密集场景。复习时把 `async` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：Task.WhenAll 相比逐个 await 的优势是？
- **正确项**：多个任务同时进行
- **判断依据**：这道题检验本课主问题：async/await、Task 并发、CancellationToken、异常与 using。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `async/await、Task 并发、CancellationToken、异常与 using。`，这段说明是：用 ``____`` 实现超时。空缺处应填哪个术语？
- **正确项**：CancellationTokenSource
- **判断依据**：这道题落在术语 `async` 上：`async` 方法返回 `Task` / `Task<T>`，`await` 在等待期间释放线程，因此特别适合 IO 密集场景。复习时把 `async` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`async`

- **要点**：`async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景。
- **async 的边界**：易错：异常无法捕获，进程崩溃；正确做法是除事件处理器外都用 `Task`。

### 考点 8：`CancellationTokenSource`

- **要点**：用 `CancellationTokenSource` 实现超时：
- **CancellationTokenSource 的边界**：网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。

### 考点 9：`IDisposable`

- **要点**：实现 `IDisposable` 的对象用 `using` 自动释放：
- **IDisposable 的边界**：越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。

### 考点 10：`配置等待`

- **要点**：决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁。
- **配置等待 的边界**：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

### 考点 11：`取消`

- **要点**：取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消
- **取消 的边界**：易错：取消失效；正确做法是参数一路传到底。

### 考点 12：排错——用 `.Result` 或 `.Wait()`

- **现象**：可能死锁、线程被占用。
- **处理**：一路 `await` 到底。

### 考点 13：排错——`async void`

- **现象**：异常无法捕获，进程崩溃。
- **处理**：除事件处理器外都用 `Task`。

### 考点 14：综合辨析——`async` 与 `取消`

- **辨析点**：`async` 的定义是 `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景；`取消` 的定义是 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消。
- **答题要求**：面对 `异步编程与异常处理` 的题目，先判断描述的是 `async` 还是 `取消`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 15：排错评分点

- **现象分**：能写出 可能死锁、线程被占用，而不是只写“程序有错”。
- **证据分**：保留触发 用 `.Result` 或 `.Wait()` 的输入、版本和错误原文。
- **修复分**：按 一路 `await` 到底 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：.NET 9 / C# 13
；本课聚焦 async。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：async、await、Task、CancellationToken、IDisposable
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：async、await、Task、CancellationToken、IDisposable。

| 参考资料 | 本课用途 |
| --- | --- |
| [C# 异步编程](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/) | async/await 与取消 |
| [Blazor 文档](https://learn.microsoft.com/aspnet/core/blazor/) | 组件、状态与交互 |
| [C# 指南](https://learn.microsoft.com/dotnet/csharp/) | 语言语法与类型系统 |

| [本课术语索引：异步编程与异常处理](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「异步编程与异常处理」的链接用于离线阅读后的延伸核对；App 不会自动联网。