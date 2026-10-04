# Isotroprogramming and Abnormal Treatment

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- It is possible to explain, in its own words, what the problem was of "showing and dealing with abnormalities" rather than simply using terminology.
- The relationship between "async", "await," "Task" and "Cancellation Token" is clear, with one example.
- It's a good way to put this subject back into the "C#" knowledge system, and it shows how much of an adjacent theme is going on.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: async/await, Task and Cancellation Token.

## Pre-knowledge

- One lesson, Gathering, Entrusting and LINQ, is completed; if available, this course can be used for self-assessment.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Before we begin: async, wait, Task.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## async / await

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

The ⟦0 method returns 1⟧/ 2⟧; 3 releases threads during the waiting period and is therefore particularly suitable for an IO-intensive scene.

## Merge with Cancel

```csharp
Task<string> a = LoadAsync(urlA, token);
Task<string> b = LoadAsync(urlB, token);
string[] results = await Task.WhenAll(a, b);      // 并行等待全部完成

Task<Task<string>> first = await Task.WhenAny(a, b);   // 谁先完成用谁
```

Use ⟦0 to achieve timeout:

```csharp
using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
await LoadAsync(url, cts.Token);
```

## Unusual and resource release

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

To achieve the automatic release of `using`:

```csharp
using var stream = File.OpenRead("data.txt");
using var reader = new StreamReader(stream);
string? line;
while ((line = await reader.ReadLineAsync()) != null)
{
    Console.WriteLine(line);
}
```

## Common trap.

1. Using ⟦0 or 1⟧ to block the walk code, it's easy to lock and should go 2⟧.
2. It's only for event processors, and it can't be captured.
3. Forget about the gills and let them swallow up. The mission is out of control.
4. It's a lot to limit, and it can be used for zero.

## Combined Control and Common Misuse

|Requirements|Practice|
| --- | --- |
|Limit the number of rounds|Controls the number of simultaneous operations (e.g., limit 10 requests)|
|Batch|⟦ 0;do not use 1⟧ (synchronous blocking)|
|Timeout| `CancellationTokenSource(TimeSpan.FromSeconds(5))` |
|Sequenced Streaming|I'm not going anywhere.|
|Periodical back-office tasks|Zero or one.|

** Five common misuses**: 1 ⟦/ 1 blocking the walk code resulting in a dead lock; 2 ⟦2 (unable to capture abnormalities other than incident handlers);3 Forget ⟦3 in the library code (non-UI scenes reduce context switching, depending on specific frame engagement);Four, one by one in the loop (which should be collected after Task WenAll); and five, which led to Cancellation Token's request for cancellation continues.

**Line security**: multiple Task modifications to share are either locked (0/1⟧) or combined (2⟧);UI must return to the UI context (through Dispatcher/Invoke in WPF/WinForms).

## It's the end of this class.
The goal of the walk** is not to block threads**: IO uses ⟦1 and can cancel 2 , with abnormality and resources given to try/catch and using.

<!-- appendix:v1 -->

## Async / Wait

|Writing|Meaning|Recommendations|
| --- | --- | --- |
| `async Task FooAsync()` |No Back Value Step|Default Selection|
| `async Task<T> FooAsync()` |A different way to return value|Default Selection|
| `async void FooAsync()` |Only for event handlers|It's impossible to catch.|
| `await task` |We'll wait, we're not blocking.|Preferred|
| `task.Result` / `task.Wait()` |Synchronize block.|It's easy to lock, no use in UI/request.|
| `Task.Run(() => ...)` |Throwing the CPU in a thread pool.|IO doesn't need it.|
| `Task.Delay(ms)` |Waiting.|Don't use Zero to block the line.|
| `Task.WhenAll(tasks)` |And wait for all of it to be done.|Keep an eye on the anomaly of each mission.|
| `Task.WhenAny(tasks)` |Waiting for the quickest.|Often used for timeout control|
| `CancellationToken` |Collaboration Cancel|It's on the floor. Check it regularly.|
| `ConfigureAwait(false)` |Do not return to the original context|Library codes are common; UI level is not normally required|
| `await using` |Distant release of resources|For ⟦0|

Timeout + Canceled Usage:

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

And I've made a number of requests:

```csharp
var tasks = urls.Select(u => client.GetStringAsync(u)).ToList();
string[] results = await Task.WhenAll(tasks);   // 总耗时接近最慢的一个
```

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|No, no, no.|It's got a zero, and it's been swallowed.|Add ⟦0 or explicitly save the task later.|
| `task.Result` |It's probably a dead lock.|Change to "0"|
|It's not normal.|The process could collapse.|It's only for event handlers, and it's all wrapped up inside.|
|It's in the stairway.|Blocking threads|Change to "0"|
|I'll take it from there.|Serial execution, total time added|Collect tasks without dependence, then zero.|
|Forget about it.|The request is still running after it's cancelled.|Token and check|
|It's in the middle of nowhere, and it releases resources.|It's long.|Use Zero.|
|I'll send you the same one.| `InvalidOperationException` |DbContext is not a secure thread.|
|Zero in ASP.NET Core|Thread pool hunger.|It's a long walk.|
|Zero, wrap it up.|White Loop Pool Thread|The IO itself is an alien. It's fine.|

## Self-Detected List

- [ ] The default returns ⟦/ ⟦1 and only the event processor uses ⟦2.
- [ Chuckles ] All the way, no use for one and two.
- [ ] IO intensive with an apogee, CPU intensely considering ⟦0.
- [ ] External methods are accepted and transmitted.
- [ ] Multiple stand-alone missions are conducted with zero.

<!-- appendix:v3 -->

## Zero basic details: async/await in parallel with the mission

### What is it?

It's like "Waiting for IO" to write the code, but it won't get stuck.
The core distinction is only one sentence:** IO intensive async, CPU intensely parallel tasks.**

### It's a life metaphor.

|Concept|A metaphor.|Annotations|
| --- | --- | --- |
| `Task` |Take the note.|It means something's going on.|
| `await` |Wait for the call.|You can do something else while you're waiting.|
| `Task.WhenAll` |Let's wait for all the lists.|♪ Together, not in a row|
| `CancellationToken` |Cancel the button.|Let the mission stop.|
| `ConfigureAwait(false)` |Not assigned back to your original position.|Reduce Context Switches in Library Code|

### From blocking to moving.

```csharp
// 阻塞写法：线程被占用，无法处理其它请求
string text = File.ReadAllText("data.txt");

// 异步写法：等待期间线程可以去做别的事
string text2 = await File.ReadAllTextAsync("data.txt");
```

**Communication: The method ends at 0°, returns 1° or 2° and has 3° inside.

### Three types of return

|Return Type|When?|
| --- | --- |
| `Task` |Step but no return value|
| `Task<T>` |Heave and return value|
| `ValueTask<T>` |HF calls and often synchronized (steps)|
| `async void` |** Used only for event processor**, abnormally uncapable|

### Distinction between serial and simultaneous

```csharp
// 串行：总耗时约等于各任务之和
var a = await FetchAsync("a");
var b = await FetchAsync("b");
var c = await FetchAsync("c");

// 并发：总耗时约等于最慢的那个
var tasks = new[] { FetchAsync("a"), FetchAsync("b"), FetchAsync("c") };
var results = await Task.WhenAll(tasks);
```

|Methodology|Behaviour|
| --- | --- |
| `Task.WhenAll` |When it's all finished; any failure is out of the ordinary|
| `Task.WhenAny` |When the first one's done.|
| `Task.WhenEach` |One to finish (. NET 9+)|
| `Task.Run` |Throwing the CPU in a thread pool.|

### Cancel and Timeout

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

** Cancel to pass it on. **: It's invalid to judge only from the outside and not to transfer to the bottom.

### When won't it be necessary, async?

```csharp
// 只是转发：不用 async，直接返回 Task 更省一次状态机
public Task<string> GetAsync() => _client.GetStringAsync("/api");

// 反例：包一层却没有任何额外逻辑
public async Task<string> GetAsyncBad()
    => await _client.GetStringAsync("/api");
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Use 0 or 1|Could be dead locks, and the thread's been taken.|All the way.|
| `async void` |Uncapable. Process crashes.|All except the event handlers.|
|One by one in the loop.|How many times?|After collecting the task, use ⟦0.|
|I forgot to tell you.|Undo|Parameters go all the way.|
|It's in the lock.|Dead lock or abnormal.|It's not inside the lock.|
|# When I'm on the same page #|Port's out.|Reuse static ⟦ or plant|
|Put the CPU directly into it, async|It's just a synchronous jam.|Put it in the rim.|
|It's all over the place.|Context Switching Costs|Zero for the library.|

### Hand hands practice: both grab and take.

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

### Learn how to measure yourself.

- [ ] Can tell the difference between synchronous jamming and scrambling.
- [ Chuckles ] Know why it's dangerous.
- [ Laughs ] Can you tell me the difference between a string and a zero?
- [ Chuckles ] Know why the cancellations go all the way.
- [ Chuckles ] Can you judge whether a scene should be async or not?

<!-- scaffold:v1 -->

<!-- exercise-guard:v1 -->

## Let's practice.

### Practice 1: Restatement of Concept (10 mins)

In the course, three or five words are used to explain what's going on in terms of "programming and dealing with anomalies" and write a border condition.

**Acceptance standard: at least one lesson keyword is used and an example given.

### Practice 2: Example rewrite (20 minutes)

Select a minimum example from the text to predict changes in an input before actually verifying and recording differences.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Migration assignment (30 minutes)

Writes a console applet to add a regular, one boundary value and an abnormal path.

- At least the key words "async" and "wait".
- Output of a result that can be checked by others.
- Write about a problem that is still uncertain and how to verify it.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Async & Exceptions

**Summary:** async/await, Task concurrency, cancellation and exceptions.

**Category:** C#  
**Level:** Progress
**Key terms:** async, await, Task, CancellationToken, IDisposable

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable environment: .NET 9/C#13
- Source: Internal structured curriculum and engineering practices
- Related themes: async, await, Task, CancellationToken, IDisposable
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Async & Exceptions** focuses on async/await, Task concurrency, cancellation and exceptions.

### Learning Outcomes

- Explain what **Async & Exceptions** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Async & Exceptions**
- Related terms: async, await, Task, CancellationToken
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
| async / await | async / await |
|Merge with Cancel|Concurency and Cancel|
|Unusual and resource release|Unusual and resource release|
|Common trap.|Common trap.|
|Combined Control and Common Misuse|Concurency Control and Common Misuse|
|It's the end of this class.| Summary |
|Async / Wait|Async / Wait|
|Common Error Table|Common mirrors|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

