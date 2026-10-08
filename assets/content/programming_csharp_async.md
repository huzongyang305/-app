# 异步编程与异常处理

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![async/await 的调用链与取消](images/diagram_cs_async.webp)

![异步编程与异常处理](images/remaining_csharp_async.webp)

## 本节知识框架

**课程定位**：所属分类为「C#」，课程主题为「异步编程与异常处理」，学习阶段为「进阶」，建议用时 55 分钟。

**本课要解决的主问题**：async/await、Task 并发、CancellationToken、异常与 using。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「异步编程与异常处理」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「异步编程与异常处理」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「async」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《集合、委托与 LINQ》

**学习位置**：本课位于《集合、委托与 LINQ》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《生态、测试与 Web 开发》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释异步编程与异常处理解决了什么问题，而不是只背术语。
- 能说清 「async」、「await」、「Task」、「CancellationToken」 之间的关系，并分别举出一个例子。
- 能把 async 放回「异步编程与异常处理」的知识体系，说明它和 await 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：async/await、Task 并发、CancellationToken、异常与 using。

**教材衔接：前置知识**

- 先完成上一课《集合、委托与 LINQ》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「集合、委托与 LINQ」，或确认自己能独立跑通正文里的 HttpRequestException 示例。
- 开始前先复习：async、await、Task。
- 如果 async / await 这一步看不懂，先记录具体卡点，再用 HttpRequestException 复现一遍。

**教材衔接：本课小结**

异步的目标是**不阻塞线程**：IO 用 `async/await`、并发用 `Task.WhenAll`、可取消用 `CancellationToken`，异常与资源交给 try/catch 与 using。

## 核心概念定义

> 阅读约定：本课先给「异步编程与异常处理」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| async | async 方法返回 Task / Task<T>；await 在等待期间释放线程，因此特别适合 IO 密集场景。 | 仅在「异步编程与异常处理」明确给出的输入、版本与资源条件下成立。 |
| CancellationTokenSource | 用 CancellationTokenSource 实现超时： | 仅在「异步编程与异常处理」明确给出的输入、版本与资源条件下成立。 |
| IDisposable | 实现 IDisposable 的对象用 using 自动释放： | 仅在「异步编程与异常处理」明确给出的输入、版本与资源条件下成立。 |
| 配置等待 | 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁。 | 仅在「异步编程与异常处理」明确给出的输入、版本与资源条件下成立。 |
| 取消 | 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消 | 仅在「异步编程与异常处理」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「异步编程与异常处理」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「async」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「CancellationTokenSource」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「IDisposable」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「异步编程与异常处理」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | async | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | CancellationTokenSource | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | IDisposable | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「异步编程与异常处理」自己的示例验证。「异步编程与异常处理」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

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

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 async、await | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「异步编程与异常处理」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「异步编程与异常处理」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:csharp`，用于动手验证《异步编程与异常处理》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《异步编程与异常处理》原文中的最小示例。先预测《异步编程与异常处理》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

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

## 时间/空间复杂度或性能分析

**复杂度证据**：「异步编程与异常处理」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「异步编程与异常处理」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「异步编程与异常处理」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：并发与取消**

```csharp
Task<string> a = LoadAsync(urlA, token);
Task<string> b = LoadAsync(urlB, token);
string[] results = await Task.WhenAll(a, b);      // 并行等待全部完成

Task<Task<string>> first = await Task.WhenAny(a, b);   // 谁先完成用谁
```

用 `CancellationTokenSource` 实现超时：

```csharp
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
await LoadAsync(url, cts.Token);
```

**教材衔接：并发控制与常见误用**

| 需求 | 做法 |
| --- | --- |
| 限制并发数 | `SemaphoreSlim` 控制同时执行数（如限制 10 个并发请求） |
| 批量并行 | `Task.WhenAll`；不要用 `Task.WaitAll`（同步阻塞） |
| 超时 | `CancellationTokenSource(TimeSpan.FromSeconds(5))` |
| 顺序流式处理 | `await foreach` 配合 `IAsyncEnumerable` |
| 周期性后台任务 | `PeriodicTimer` 或 `BackgroundService` |

**五种常见误用**：① `.Result` / `.Wait()` 阻塞异步代码导致死锁；② `async void`（除事件处理器外无法捕获异常）；③ 忘记 `ConfigureAwait(false)` 在库代码中（非 UI 场景可减少上下文切换，但要看具体框架约定）；④ 在循环里逐个 await 造成串行（应收集 Task 后 WhenAll）；⑤ 忘了传 CancellationToken，导致请求取消后后台仍继续算。

**线程安全**：多个 Task 修改共享状态要用锁（`lock`/`SemaphoreSlim`）或并发集合（`ConcurrentDictionary`）；跨线程更新 UI 必须回到 UI 上下文（在 WPF/WinForms 中通过 Dispatcher/Invoke）。

## 常见误区与易错点

> 复核《异步编程与异常处理》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「异步编程与异常处理」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

1. 用 `.Result` 或 `.Wait()` 阻塞异步代码，容易死锁，应一路 `await`。
2. `async void` 只用于事件处理器，异常无法被捕获。
3. 忘记 `await` 会让异常被吞掉，任务在后台失败。
4. 大量并发要限制数量，可用 `SemaphoreSlim`。
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

**教材衔接：故障现场**

### 现场 1：var s = FooAsync(); 没有 await

**症状**：在《异步编程与异常处理》的复现场景中，拿到的是 Task，异常被吞。

**根因**：“拿到的是 Task，异常被吞”只是表层结果。向上追溯会落到“var s = FooAsync(); 没有 await”这一步，因为它省略了《异步编程与异常处理》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《异步编程与异常处理》的问题，加上 await，或明确保存任务稍后处理。

**验证**：保留《异步编程与异常处理》里触发“拿到的是 Task，异常被吞”的输入、版本和日志，按“加上 await，或明确保存任务稍后处理”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：task.Result

**症状**：在《异步编程与异常处理》的复现场景中，可能死锁、线程被占满。

**根因**：触发点是把“task.Result”当成安全做法。它没有满足《异步编程与异常处理》要求的前提，因此先表现为“可能死锁、线程被占满”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《异步编程与异常处理》的问题，改成 await task。

**验证**：先在《异步编程与异常处理》中记录“task.Result”留下的失败证据，再执行“改成 await task”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：async void 抛异常

**症状**：在《异步编程与异常处理》的复现场景中，进程可能直接崩溃。

**根因**：“进程可能直接崩溃”只是表层结果。向上追溯会落到“async void 抛异常”这一步，因为它省略了《异步编程与异常处理》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《异步编程与异常处理》的问题，只用于事件处理器，并在内部 try/catch 全部包住。

**验证**：保留《异步编程与异常处理》里触发“进程可能直接崩溃”的输入、版本和日志，按“只用于事件处理器，并在内部 try/catch 全部包住”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《集合、委托与 LINQ》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《生态、测试与 Web 开发》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 关联 | 《Swift 并发与 async/await》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 关联 | 《异步编程》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《集合、委托与 LINQ》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《生态、测试与 Web 开发》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「异步编程与异常处理」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《异步编程与异常处理》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

使用 await 等待 IO 的主要好处是？

A. 自动重试
B. 代码更短
C. 提升 CPU 主频
D. 等待期间不阻塞线程

**参考答案**：等待期间不阻塞线程

**解析**：在「异步编程与异常处理」里，等待期间不阻塞线程。await 在等待期间释放当前线程，线程可以去处理其他请求，从而提高吞吐量。这道题的关键在「异步编程与异常处理」的async、await、Task：先确认题干“使用 await 等待 IO 的主要”问的是哪一步，再排除偷换前提的选项。

### 自测 2

阅读「异步编程与异常处理」正文里的这段 C# 代码，下面哪一项判断是正确的？

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

A. 这段代码会读取外部输入，结果依赖传入的数据。
B. 这段代码会产生可观察的输出，运行后能看到结果。
C. 这段代码只做静态声明，没有循环、分支或可观察输出。
D. 这段代码包含异常处理分支，失败时会走专门的补救路径。

**参考答案**：这段代码包含异常处理分支，失败时会走专门的补救路径。

**解析**：在「异步编程与异常处理」里，题干的正确项是这段代码包含异常处理分支，失败时会走专门的补救路径。把输入或边界换成空值、极值或失败情况后，结论要以「异步编程与异常处理」的实际运行结果为准。「异步编程与异常处理」要求先交代async、await、Task的前提再下结论，所以“这段代码包含异常处理分支”只在题干“阅读异步编程与异常处理正文里的这段 C 代码”给定的条件下成立。

### 自测 3

围绕“异步编程与异常处理”中的 async、await、Task，下列哪两项是本课强调的实践判断？

A. 验证 await 时要固定版本并覆盖边界输入，结论才可复现
B. 把 await 的单次运行结果当成所有版本和规模都成立
C. 学习 async 时要同时说明输入、输出和失败路径，不能只看正常流程
D. 只要 async 的常规示例通过，就可以跳过边界与异常路径

**参考答案**：验证 await 时要固定版本并覆盖边界输入，结论才可复现；学习 async 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：结论应落在验证 await 时要固定版本并覆盖边界输入。本课把异步编程与异常处理拆成概念、示例与故障现场三部分，因此判断 async 时必须同时交代输入、输出和失败路径，这使“学习 async 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在异步编程与异常处理里，判断 await 时要固定版本与边界输入，所以“验证 await 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 默认返回 `Task` / `Task<T>`，只有事件处理器才用 `async void`。
- [ ] 全程 `await`，不使用 `.Result` 与 `.Wait()`。
- [ ] IO 密集用异步 API，CPU 密集才考虑 `Task.Run`。
- [ ] 对外方法都接受并传递 `CancellationToken`。
- [ ] 多个独立任务用 `Task.WhenAll` 并发执行。

**教材衔接：动手练习**

### 练习 1：概念复述（10 分钟）

合上教程，用 3～5 句话解释异步编程与异常处理解决什么问题，并写出一个边界条件。

**验收标准**：至少使用一个本课关键词，并给出一个反例。

### 练习 2：示例改写（20 分钟）

改动 HttpRequestException 的一个输入并预测输出，然后运行核对。

**验收标准**：先原样跑通正文里的 `HttpRequestException`，再只改async相关的输入，按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。

### 练习 3：迁移任务（30 分钟）

写一个控制台小程序，补一个正例、一个边界值和一个异常路径。

- 至少覆盖「async」和「await」两个关键词。
- 产出一个别人可以检查的结果。
- 写出一个仍不确定的问题和验证方法。

**教材衔接：可运行练习**

本节围绕异步编程与异常处理安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「异步编程与异常处理」的结构，画完再对照骨架：

- 主干：并发与取消 → 异常与资源释放 → 常见陷阱 → 并发控制与常见误用
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明async与await的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案的差异必须落在「异步编程与异常处理」的实际约束上；写清当async越过哪条边界时应该换方案。

### 任务 3：迁移到自己的场景

**验收标准**：至少给出一个命令或数据样例，让读者能独立复现 await 的结论。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「使用 await 等待 IO 的主要好处是？」的判断依据。
- [ ] 不看解析，能说出「在异步代码中使用 .Result 或 .Wait() 的风险是？」的判断依据。
- [ ] 不看解析，能说出「async void 只适合用在什么场景？」的判断依据。
- [ ] 不看解析，能说出「CancellationToken 的作用是？」的判断依据。
- [ ] 不看解析，能说出「Task.WhenAll 相比逐个 await 的优势是？」的判断依据。
- [ ] 用 async 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `async` | `async` 方法返回 `Task` / `Task<T>`；`await` 在等待期间释放线程，因此特别适合 IO 密集场景。 |
| `CancellationTokenSource` | 用 `CancellationTokenSource` 实现超时： |
| `IDisposable` | 实现 `IDisposable` 的对象用 `using` 自动释放： |
| `配置等待` | 决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁。 |
| `取消` | 取消要一路传下去：只在外层判断 token.IsCancellationRequested 而不传给底层调用，是无效取消 |

## 考点精讲

### 考点 1：概念判断·async

- **题目**：使用 await 等待 IO 的主要好处是？
- **判断依据**：在「异步编程与异常处理」里，等待期间不阻塞线程。await 在等待期间释放当前线程，线程可以去处理其他请求，从而提高吞吐量。这道题的关键在「异步编程与异常处理」的async、await、Task：先确认题干“使用 await 等待 IO 的主要”问的是哪一步，再排除偷换前提的选项。

### 考点 2：概念判断·async

- **题目**：在异步代码中使用 .Result 或 .Wait 的风险是？
- **判断依据**：在「异步编程与异常处理」里，可能死锁并阻塞线程。同步阻塞等待异步任务容易造成死锁，正确做法是一路 await 到底。这道题的关键在「异步编程与异常处理」的async、await、Task：先确认题干“在异步代码中使用 .Result 或”问的是哪一步，再排除偷换前提的选项。把“可能死锁并阻塞线程”代回「异步编程与异常处理」里“在异步代码中使用 .Result 或 .Wait 的风险是”的例子核对，条件一旦改变，结论就要用async、await、Task重新推导。

### 考点 3：代码补全·async

- **题目**：阅读「异步编程与异常处理」正文里的这段 C# 代码，下面哪一项判断是正确的？
- **判断依据**：在「异步编程与异常处理」里，题干的正确项是这段代码包含异常处理分支，失败时会走专门的补救路径。把输入或边界换成空值、极值或失败情况后，结论要以「异步编程与异常处理」的实际运行结果为准。「异步编程与异常处理」要求先交代async、await、Task的前提再下结论，所以“这段代码包含异常处理分支”只在题干“阅读异步编程与异常处理正文里的这段 C 代码”给定的条件下成立。

### 考点 4：多选辨析·async

- **题目**：围绕“异步编程与异常处理”中的 async、await、Task，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在验证 await 时要固定版本并覆盖边界输入。本课把异步编程与异常处理拆成概念、示例与故障现场三部分，因此判断 async 时必须同时交代输入、输出和失败路径，这使“学习 async 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在异步编程与异常处理里，判断 await 时要固定版本与边界输入，所以“验证 await 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 5：概念判断·async

- **题目**：Task.WhenAll 相比逐个 await 的优势是？
- **判断依据**：在「异步编程与异常处理」里，多个任务同时进行。多个异常会被包装在 AggregateException 中，需要逐个检查各任务的异常。「异步编程与异常处理」要求先交代async、await、Task的前提再下结论，所以“多个任务同时进行”只在题干“Task.WhenAll 相比逐个 await 的优势是”给定的条件下成立。

### 考点 6：填空·async

- **题目**：补全代码：「异步编程与异常处理」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `using var cts = new ____(TimeSpan.FromSeconds(5));`
- **判断依据**：空格应填写「CancellationTokenSource」、「cancellationtokensource」。在「异步编程与异常处理」里判断这道题，要把async、await、Task的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。回到「异步编程与异常处理」的正文示例，用“补全代码”走一遍async、await、Task的完整流程，能复现的结论才可以保留。

## English Overview

**Title:** Async & Exceptions

**Summary:** async/await, Task concurrency, cancellation and exceptions.

**Category:** C#
**Level:** 进阶
**Key terms:** async, await, Task, CancellationToken, IDisposable

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：.NET 9 / C# 13
；本课聚焦 async。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：async、await、Task、CancellationToken、IDisposable
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**Async & Exceptions** focuses on async/await, Task concurrency, cancellation and exceptions.

### Learning Outcomes

- Explain what **Async & Exceptions** solves and when it should be used.

### Glossary

- Topic: **Async & Exceptions**
- Related terms: async, await, Task, CancellationToken

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| async / await | async / await |
| 并发与取消 | Concurrency与取消 |
| 异常与资源释放 | 异常与资源释放 |
| 常见陷阱 | 常见陷阱 |
| 并发控制与常见误用 | Concurrency控制与常见误用 |
| 本课小结 | Summary |
| async / await 速查 | async / await 速查 |
| 常见错误对照表 | Common mistakes对照表 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [C# 异步编程](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/) | async/await 与取消 |
| [Blazor 文档](https://learn.microsoft.com/aspnet/core/blazor/) | 组件、状态与交互 |
| [C# 指南](https://learn.microsoft.com/dotnet/csharp/) | 语言语法与类型系统 |

> 「异步编程与异常处理」的链接用于离线阅读后的延伸核对；App 不会自动联网。
