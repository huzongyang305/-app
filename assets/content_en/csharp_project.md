# Operation: ASP.NET Cob API + EF Core

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It is possible to explain in its own words what web API + EF Core solves, not just the term.
- The relationship between "activism", "ASP.NET Core," "EF Core" and "xUnit" is clear, with one example:
- It's a good way to put this subject back into the "C#" knowledge system, and it shows how much of an adjacent theme is going on.
- It is possible to complete this course and check its results using acceptance standards.

> Summary of sentence: Minimum API, DebContext, memory database testing and engineering practice.

## Pre-knowledge

- The first lesson is " Ecology, Testing and Web Development " ; if available, you can practice self-measures directly from this course.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- Before we start, let's review: real battles, ASP.NET Core, EF Core.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Create Item

```bash
dotnet new webapi -o TodoApi --use-minimal-apis
cd TodoApi
dotnet add package Microsoft.EntityFrameworkCore.Sqlite
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet new xunit -o ../TodoApi.Tests
dotnet add ../TodoApi.Tests reference ../TodoApi
```

## Data model and DbContext

```csharp
public record Todo(int Id, string Title, bool Done, DateTime CreatedAt);
public record TodoRequest(string Title);
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<Todo> Todos => Set<Todo>();
}
```

## Registration services

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<AppDbContext>(o => o.UseSqlite("Data Source=todo.db"));
builder.Services.AddEndpointsApiExplorer();
var app = builder.Build();
using (var scope = app.Services.CreateScope())
{
    scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.EnsureCreated();
}
```

The production environment should be EF Core (0) instead of 1⟧.

## Interface achieved

```csharp
app.MapGet("/api/todos", async (AppDbContext db) =>
    await db.Todos.OrderByDescending(t => t.CreatedAt).ToListAsync());
app.MapPost("/api/todos", async (TodoRequest request, AppDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Title))
    {
        return Results.ValidationProblem(new Dictionary<string, string[]>
        {
            ["title"] = new[] { "标题不能为空" }
        });
    }
    var todo = new Todo(0, request.Title.Trim(), false, DateTime.UtcNow);
    db.Todos.Add(todo);
    await db.SaveChangesAsync();
    return Results.Created($"/api/todos/{todo.Id}", todo);
});
app.MapDelete("/api/todos/{id:int}", async (int id, AppDbContext db) =>
{
    var todo = await db.Todos.FindAsync(id);
    if (todo is null) return Results.NotFound();
    db.Todos.Remove(todo);
    await db.SaveChangesAsync();
    return Results.NoContent();
});
```

## Test

```csharp
public class TodoTests
{
    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }
    [Fact]
    public async Task AddsTodo()
    {
        await using var db = CreateDb();
        db.Todos.Add(new Todo(0, "学习 C#", false, DateTime.UtcNow));
        await db.SaveChangesAsync();
        Assert.Equal(1, await db.Todos.CountAsync());
    }
}
```

## Engineering practice

1. Use DTO to isolate database entities from API contracts and avoid direct exposure of surface structures.
2. The entry is for validation (DataAnnotations / FluentValidation), and the operating rules are on the service level.
3. Configure the sub-environment, with a key or an environment variable.
4. Add ⟦0 for unified error response, log with ILogger.
5. CI executes `dotnet test`.

## It's the end of this class.
Minimum available .NET backend = **EF Core Endurance + Minimal API Route + Dependence on Injection + xUnit test**;Run and deploy as necessary with authentication, cache and containerization.

<!-- appendix:v1 -->

## Web API Spacing

|Layer|Duties|Something you shouldn't have done.|
| --- | --- | --- |
| Controller / Endpoint |Parameter binding, verification, status code|Write business rules, directly operate databases|
| Service |Organization of business rules and services|Reliance HTTP Details|
| Repository / DbContext |Data access|Write business judgement.|
| DTO |Structure of external requests and responses|Exposure Entity and Sensitive Fields|
| Entity |Endurance model|Return type as interface|

```csharp
[ApiController]
[Route("api/orders")]
public sealed class OrdersController : ControllerBase
{
    private readonly OrderService _service;
    private readonly ILogger<OrdersController> _logger;

    public OrdersController(OrderService service, ILogger<OrdersController> logger)
    {
        _service = service;
        _logger = logger;
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<OrderDto>> Get(long id, CancellationToken ct)
    {
        var order = await _service.FindAsync(id, ct);
        return order is null ? NotFound() : Ok(order);
    }

    [HttpPost]
    public async Task<ActionResult<OrderDto>> Create(
        [FromBody] CreateOrderRequest request, CancellationToken ct)
    {
        var created = await _service.CreateAsync(request, ct);
        _logger.LogInformation("订单已创建 id={OrderId}", created.Id);
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }
}
```

## Quick check of practical points

|Theme|Recommendations|
| --- | --- |
|Request for validation|1 +2|
|Error Response|Unified ProblemDetails, mapping operations to state code|
|Database Migration|⟦ Generate Script, CI execute|
|Service|Use ⟦0 or 1 at Service|
|Parallel.|Optimistic and Dealing Cards + Conflict Again|
|Page Break|⟦ Total query, or based on cursor|
|Cache|⟦0/11, watch out for failures.|
|Health checkup|⟦ Exposure 1 (distinguishing live with ready)|
|Configure|⟦Eternal variable overwhelms, key not in the repository|
|Observable|Structure log + request ID + indicator|

## Common Error Table

|Easy to step on.|Actual|Reasons and correct practices|
| --- | --- | --- |
|Return Entity instead of DTO|Leak Fields, Loop Reference|Projection with DTO|
|Controller writes business logic.|Could not initialise Bonobo|Move to Service|
|It's normal.|Poor performance and semantic confusion.|With Return Value or ⟦0|
|Forget it.|Continue after client breakup|Full link.|
|Send HTTP Request in Service|It's too long to connect.|External Call Out|
|Move scripts manually to database|Environmental incoherence|Move script into version control and CI|
|Pageless Return All|It's all over the place.|Force page breaks and caps|
|Log Record Full Request|The leak.|Only necessary fields recorded and dissensitized|
|Use ⟦0 to save time|It's not in line.|Unanimously.|
|It's not going to work out.|User data overrided|Capture conflict and hint to try again|

## Self-Detected List

- [ Chuckles ] The layer is clear, the Controller only makes protocol conversions.
- [ ] Requests and responses are verified using DTOs.
- [ Laughs ] All the ways to walk are passed on.
- [ ] The database structure is managed by the migration script and access to CI.
- [ ] Harmonization of error response formats, dissensitivity and requests.

<!-- appendix:v3 -->

## Zero basic details: ASP.NET Core

### What is it?

A deliverable ASP.NET Core service is required to have:** layered, relying on injection specifications, configuration verification, uniform error processing, health check-ups, testing and containerization**

### It's a life metaphor.

|Layer|A metaphor.|Duties|
| --- | --- | --- |
| Endpoints |Front desk.|Request received, return response|
| Services |The chef.|Operational rules|
| Repositories |Warehouse|Data access|
| DTO |Forms|External data structure|
| Entities |It's a desk.|Correspond to Table Structure|

### Project structure

```text
MyApp/
  src/
    MyApp.Api/                Endpoints、DI 装配、中间件
    MyApp.Core/               领域模型与服务接口
    MyApp.Infrastructure/     EF Core、外部服务实现
  tests/
    MyApp.UnitTests/
    MyApp.IntegrationTests/
```

### Standardisation for Minimum API

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy());

builder.Services.AddOptions<DatabaseOptions>()
    .Bind(builder.Configuration.GetSection(DatabaseOptions.Section))
    .ValidateDataAnnotations()
    .ValidateOnStart();

builder.Services.AddScoped<IOrderRepository, OrderRepository>();
builder.Services.AddScoped<OrderService>();

var app = builder.Build();

app.UseExceptionHandler();        // 统一转成 ProblemDetails
app.MapHealthChecks("/healthz/live", new HealthCheckOptions
{
    Predicate = _ => false,        // 只表示进程存活
});
app.MapHealthChecks("/healthz/ready");

app.MapPost("/api/orders", async (
    CreateOrderRequest request,
    OrderService service,
    CancellationToken ct) =>
{
    var order = await service.CreateAsync(request, ct);
    return Results.Created($"/api/orders/{order.Id}", order);
});

app.Run();
```

### Unique error handling

```csharp
public sealed class OrderNotFoundException(int id)
    : Exception($"订单 {id} 不存在");

public sealed class DomainExceptionHandler(ILogger<DomainExceptionHandler> logger)
    : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext context, Exception exception, CancellationToken ct)
    {
        var (status, code) = exception switch
        {
            OrderNotFoundException => (StatusCodes.Status404NotFound, "ORDER_NOT_FOUND"),
            ArgumentException => (StatusCodes.Status400BadRequest, "INVALID_ARGUMENT"),
            _ => (StatusCodes.Status500InternalServerError, "INTERNAL_ERROR"),
        };

        if (status == StatusCodes.Status500InternalServerError)
            logger.LogError(exception, "未预期异常");

        context.Response.StatusCode = status;
        await context.Response.WriteAsJsonAsync(new
        {
            code,
            message = status == StatusCodes.Status500InternalServerError
                ? "服务内部错误"
                : exception.Message,
        }, ct);
        return true;
    }
}
```

** Internal stacks are posted only to security information.**

### Data access: EF Core ' s three disciplines

```csharp
public sealed class OrderRepository(AppDbContext db) : IOrderRepository
{
    public async Task<Order?> FindAsync(int id, CancellationToken ct) =>
        await db.Orders
            .AsNoTracking()                 // 只读查询关掉跟踪，更快
            .FirstOrDefaultAsync(o => o.Id == id, ct);

    public async Task AddAsync(Order order, CancellationToken ct)
    {
        db.Orders.Add(order);
        await db.SaveChangesAsync(ct);
    }
}
```

|Discipline|Reason|
| --- | --- |
|Read Query Only|Reduced memory and tracking costs|
|I'll take the page with me.|Database does not guarantee default order|
|Move Script to Version Library|Environmental coherence|

```bash
dotnet ef migrations add AddOrderIndex
dotnet ef database update
dotnet ef migrations script --idempotent -o migrate.sql   # 生产用脚本
```

### Configure Validation and Containerization

```csharp
public sealed class DatabaseOptions
{
    public const string Section = "Database";
    [Required] public string Host { get; init; } = "";
    [Range(1, 65535)] public int Port { get; init; } = 5432;
}
```

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/MyApp.Api -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /app .
RUN useradd -r -u 1001 appuser && chown -R appuser /app
USER appuser
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "MyApp.Api.dll"]
```

### Three floors.

|Level|Method|Overwrite|
| --- | --- | --- |
|Units|xUnit handwritten|Operational rules|
|Integration| `WebApplicationFactory` |Routes, Sequencing, DI|
|End-to-end|Testcontainers|SQL and Migration|

```csharp
public class OrderEndpointTests(WebApplicationFactory<Program> factory)
    : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task 数量为零时返回 400()
    {
        var client = factory.CreateClient();
        var res = await client.PostAsJsonAsync("/api/orders",
            new { customer = "小明", quantity = 0 });
        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }
}
```

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Enter|Disclosure Fields|Use DTO|
|Singleton Injected|_Other Organiser|Matching by Life Cycle|
|Read-only query not used AsNoTracking|Poor performance.|Visible Close Track|
|Unusual stack back to user|Disclosure of Details|Unify Error Response|
|Migration unversioned|Inconsistent environmental structure|Move to Version Library|
|Unordered Page Break|Repetition or Skipping|I'll take it from here.|
|Surviving probe database|Restart the storm.|Live and get ready.|
|Run in root|Security risks|Create normal user and zero|

### Learn how to measure yourself.

- [ ] Speaking of Api, Core and Infrestructure.
- [ Chuckles ] Know the benefits.
- [ Chuckles ] Can you say the three disciplines of EF Core?
- [ ] Know why the live probe didn't check the database.
- [ ] Can you say what each of the three levels covers?

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeat, experiment and deliver around "The Fields," ASP.NET Core, EF Core, each result being checked by someone else.

Create a minimum console program, then fill in the type, walk and abnormal path, which will be verified with dotnet test.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Web API plus EF Core?
2. Without it, what concrete consequences would there be?
3. What's it got to do with ASP.NET Core?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a console applet to add a regular, a boundary value and an abnormal path.

Mission requests:

- The result must be checked, not just “I understand”.
- It's not like we have to go through it, but I don't know what you want to do.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## Validation command and expected output

The project code does not read only " Compilable " , but repeats the results by a fixed command.

|Phase|Command|Expected output|
| --- | --- | --- |
|Revert it.| `dotnet restore` |Repression Success|
|Run Test| `dotnet test` |All xunit tests passed|
|Example:| `dotnet run` |Apply startup and output expected results|

### Evidence of acceptance

- [ ] Save the complete output relying on installation and start-up orders.
- [ ] Run at least 3 tests containing an illegal input or failure path.
- [ ] Repeat the same operation twice and confirm that there are no duplicates or side effects.
- [ ] Record a failure code, wrong log and recovery steps.
- [ ] Provide an environmental version, start-up and rollback in README.

### Return and Roll

1. Start with an abandoned directory or temporary database to avoid contamination of real data.
2. Rerun all authentication orders after a logical change to confirm that they are not returned.
3. If you fail, roll back to the previous runable version and keep the failed log.
4. The reason for the location is supplemented by an automated test and re-execution process.
5. The lessons are included in the project ' s repertoire or in a note, which will form the next inspection.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Project: Web API + EF Core

**Summary:** Minimal APIs, DbContext, tests and practices.

**Category:** C#  
**Level:** Advanced
**Key terms:**ASP.NET Core, EF Core, xUnit, DTO

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable environment: .NET 9/C#13
- Source: Internal structured curriculum and engineering practices
- Related themes: field operations, ASP.NET Core, EF Core, xUnit, DTO
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

## Specifications for the project: field operations: Web API + EF Core

### Core scene

Minimum API, DbContext, memory database testing and engineering practices.The goal of the project is to make operational, testable and roll-back deliverables from ASP.NET Core, EF Core, xUnit, DTO.

### Structures and data flows

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### Minimum Data Model

|Object|Key Fields|Constraints|
| --- | --- | --- |
|Enter entity|Actual, time and source|Keys to verify, limit the length, etc.|
|Task entity|Status, priority, creation|It's legal, it can't be repeated|
|Result entity|Output, Error Code, Time|Sequencable. Errors.|
|Audit records|Operator, action, result, time|It's unmovable, searchable and dissensitive.|

### Receiving scenes

1. Normal path: The minimum input receives the expected output, leaving a log and an indicator.
2. Boundary path: Empty, maximum, duplicated data and super-long content are explicitly addressed.
3. Failed path: fast failure, retest or downgrade if you rely on excess time.
4. Paths, etc.: The execution of the same request will not have repeated side effects.
5. Rollback path: Backroll data are consistent and indicate recovery time and impact.

<!-- project-delivery:v1 -->

## Project delivery

### Suggested warehouse structure

```text
src/App/
src/Domain/
tests/App.Tests/
App.sln
README.md
```

### Test Matrix

|Level|Overwrite|Minimum|Adoption of standards|
| --- | --- | ---: | --- |
|Unit Test|Field rules, boundaries and misclassification| 8 |It's normal. The border, the path to failure.|
|Integrated testing|Database, network, document or platform boundary| 3 |Use real boundaries and run again|
|End-to-end testing|Core User Path| 1 |Full run from input to output|
|Manually.|5 scenes listed in the document| 5 |Orders, output and conclusion records|

### Receiving and Inspection Data

```json
{
  "project": "csharp_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### Duplicate Template

|Problem|Records|
| --- | --- |
|What was the original target?|I'll give you a description of the acceptable target.|
|What's going on?|Timeline, indicators and key logs|
|Which assumption was overturned?|Root causes and contributing factors|
|How do you roll back?|Steps, time-consuming and data validation|
|What's next?|Responsible persons, duration and certification|

> Project acceptance revolves around "activism, ASP.NET Core": at least one normal route, one border entry, one failed recovery and one stint check.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Project: Web API + EF Core** focuses on Minimal APIs, DbContext, tests and practices.

### Learning Outcomes

- Explain what **Project: Web API + EF Core** solves and when it should be used.
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

- Topic: **Project: Web API + EF Core**
- Related terms: ASP.NET Core, xUnit
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|Create Item| Creating a Project Template |
|Data model and DbContext| Data Model and DbContext |
|Registration services| Your enrollment, taken care of. |
|Interface achieved| Interface implementation |
|Test| Test |
|Engineering practice| Engineering Practice |
|It's the end of this class.| Lesson Summary |
|Web API Spacing| Web API tiered quick lookup |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

