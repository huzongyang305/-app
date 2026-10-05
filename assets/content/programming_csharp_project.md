# 实战：ASP.NET Core Web API + EF Core

![Web API 与 EF Core 的请求链路](images/diagram_cs_webapi_project.webp)

![实战：Web API + EF Core](images/remaining_csharp_project.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「实战：Web API + EF Core」解决了什么问题，而不是只背术语。
- 能说清 「实战」、「ASP.NET Core」、「EF Core」、「xUnit」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「C#」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：最小 API、DbContext、内存数据库测试与工程实践。

## 前置知识

- 先完成上一课《生态、测试与 Web 开发》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：实战、ASP.NET Core、EF Core。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 创建项目

```bash
dotnet new webapi -o TodoApi --use-minimal-apis
cd TodoApi
dotnet add package Microsoft.EntityFrameworkCore.Sqlite
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet new xunit -o ../TodoApi.Tests
dotnet add ../TodoApi.Tests reference ../TodoApi
```

## 数据模型与 DbContext

```csharp
public record Todo(int Id, string Title, bool Done, DateTime CreatedAt);
public record TodoRequest(string Title);
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<Todo> Todos => Set<Todo>();
}
```

## 注册服务

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

生产环境应使用 EF Core 迁移（`dotnet ef migrations add Init`）而不是 `EnsureCreated`。

## 接口实现

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

## 测试

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

## 工程实践

1. 用 DTO 隔离数据库实体与 API 契约，避免直接暴露表结构。
2. 入口做校验（DataAnnotations / FluentValidation），业务规则放服务层。
3. 配置分环境，密钥用 User Secrets 或环境变量。
4. 加 `UseExceptionHandler` 统一错误响应，日志用 ILogger。
5. CI 中执行 `dotnet format --verify-no-changes` 与 `dotnet test`。

## 本课小结
最小可用的 .NET 后端 = **EF Core 持久化 + 最小 API 路由 + 依赖注入 + xUnit 测试**；跑通后再按需要加认证、缓存与容器化部署。


## Web API 分层速查

| 层 | 职责 | 不该做的事 |
| --- | --- | --- |
| Controller / Endpoint | 参数绑定、校验、状态码 | 写业务规则、直接操作数据库 |
| Service | 业务规则与事务编排 | 依赖 HTTP 细节 |
| Repository / DbContext | 数据访问 | 写业务判断 |
| DTO | 对外的请求与响应结构 | 暴露实体与敏感字段 |
| Entity | 持久化模型 | 作为接口返回类型 |

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

## 实践要点速查

| 主题 | 建议 |
| --- | --- |
| 请求校验 | `[Required]`、`[Range]` 等数据注解 + `ModelState` |
| 错误响应 | 统一 ProblemDetails，映射业务异常到状态码 |
| 数据库迁移 | `dotnet ef migrations add` 生成脚本，CI 中执行 |
| 事务 | 在 Service 层使用 `IDbContextTransaction` 或 `SaveChanges` 一次提交 |
| 并发 | 乐观并发令牌 + 冲突重试 |
| 分页 | `Skip/Take` + 总数查询，或基于游标 |
| 缓存 | `IMemoryCache` / `IDistributedCache`，注意失效策略 |
| 健康检查 | `AddHealthChecks` 暴露 `/health`（区分 live 与 ready） |
| 配置 | `appsettings.json` + 环境变量覆盖，密钥不进仓库 |
| 可观测 | 结构化日志 + 请求 ID + 指标 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 返回实体而不是 DTO | 泄漏字段、循环引用 | 用 DTO 投影 |
| Controller 里写业务逻辑 | 无法复用与测试 | 移到 Service |
| 用异常做正常流程控制 | 性能差、语义混乱 | 用返回值或 `TryXxx` |
| 忘记 `CancellationToken` | 客户端断开后仍继续执行 | 全链路透传 |
| 事务里发 HTTP 请求 | 事务时间过长、连接被占 | 外部调用放事务外 |
| 迁移脚本手工改数据库 | 环境不一致 | 迁移脚本纳入版本控制与 CI |
| 分页不分页直接返回全部 | 大表拖垮服务 | 强制分页并设上限 |
| 日志记录完整请求体 | 泄漏隐私 | 只记录必要字段并脱敏 |
| 用 `DateTime.Now` 存时间 | 跨时区不一致 | 统一 `DateTimeOffset.UtcNow` |
| 乐观并发冲突不处理 | 用户数据被覆盖 | 捕获冲突并提示重试 |

## 自测清单

- [ ] 分层清晰，Controller 只做协议转换。
- [ ] 请求与响应都使用 DTO 并做校验。
- [ ] 所有异步方法透传 `CancellationToken`。
- [ ] 数据库结构由迁移脚本管理并接入 CI。
- [ ] 统一错误响应格式，日志脱敏且带请求 ID。


## 零基础详解：ASP.NET Core 项目实战

### 一句话说清它是什么

一个可交付的 ASP.NET Core 服务要具备：**分层清晰、依赖注入规范、配置校验、统一错误处理、健康检查、测试、容器化**。

### 用生活比喻理解

| 层 | 比喻 | 职责 |
| --- | --- | --- |
| Endpoints | 前台 | 收请求、返回响应 |
| Services | 后厨 | 业务规则 |
| Repositories | 仓库 | 数据访问 |
| DTO | 表单 | 对外数据结构 |
| Entities | 台账 | 与表结构对应 |

### 项目结构

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

### 最小 API 的规范写法

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

### 统一错误处理

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

**内部堆栈只进日志，响应只给安全信息。**

### 数据访问：EF Core 的三条纪律

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

| 纪律 | 原因 |
| --- | --- |
| 只读查询用 `AsNoTracking` | 减少内存与跟踪开销 |
| 分页一定带 `OrderBy` | 数据库不保证默认顺序 |
| 迁移脚本进版本库 | 环境之间结构一致 |

```bash
dotnet ef migrations add AddOrderIndex
dotnet ef database update
dotnet ef migrations script --idempotent -o migrate.sql   # 生产用脚本
```

### 配置校验与容器化

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

### 测试三层

| 层级 | 方式 | 覆盖 |
| --- | --- | --- |
| 单元 | xUnit 加手写桩 | 业务规则 |
| 集成 | `WebApplicationFactory` | 路由、序列化、DI |
| 端到端 | Testcontainers 起真数据库 | SQL 与迁移 |

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

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| Entity 直接返回 | 泄露字段 | 用 DTO |
| Singleton 注入 Scoped | 启动报错 | 按生命周期匹配 |
| 只读查询未用 AsNoTracking | 性能差 | 显式关闭跟踪 |
| 异常堆栈返回给用户 | 泄露细节 | 统一错误响应 |
| 迁移不版本化 | 环境结构不一致 | 迁移进版本库 |
| 分页不排序 | 结果重复或跳项 | 带 `OrderBy` |
| 存活探针查数据库 | 重启风暴 | 存活与就绪分开 |
| 容器以 root 运行 | 安全风险 | 建普通用户并 `USER` |

### 学完自测

- [ ] 能说出 Api、Core、Infrastructure 的职责。
- [ ] 知道 `ValidateOnStart` 的好处。
- [ ] 能说出 EF Core 的三条纪律。
- [ ] 知道存活探针为什么不检查数据库。
- [ ] 能说出三种测试层级各自覆盖什么。

## 动手练习


> 本课练习重点：围绕「实战、ASP.NET Core、EF Core」完成复述、实验和交付，每个结果都要能被别人检查。

先建最小控制台程序，再补类型、异步和异常路径，最后用 dotnet test 验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「实战：Web API + EF Core」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ASP.NET Core」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个控制台小程序，补一个正例、一个边界值和一个异常路径。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「实战」和「ASP.NET Core」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 验证命令与预期输出

项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 还原依赖 | `dotnet restore` | 依赖还原成功 |
| 运行测试 | `dotnet test` | 所有 xUnit 测试通过 |
| 启动示例 | `dotnet run` | 应用启动并输出预期结果 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条测试，其中包含一条非法输入或失败路径。
- [ ] 重复执行同一操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 在 README 中写明环境版本、启动方式和回滚方式。

### 回归与回滚

1. 先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：生产环境管理数据库结构应优先使用？

- **正确判断**：EF Core 迁移
- **判断依据**：正确答案是「EF Core 迁移」，本课在「注册服务」中说明：生产环境应使用 EF Core 迁移（dotnet ef migrations add Init）而不是 EnsureCreated。迁移可增量演进表结构并有版本记录，EnsureCreated 只适合原型。本课还在「工程实践」中说明：用 DTO 隔离数据库实体与 API 契约，避免直接暴露表结构。本课还在「项目专属规格：实战：Web API + EF Core」中说明：最小 API、DbContext、内存数据库测试与工程实践。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：使用 DTO 而不是直接暴露实体，主要好处是？

- **正确判断**：隔离数据库结构与 API 契约
- **判断依据**：正确答案是「隔离数据库结构与 API 契约」，本课在「工程实践」中说明：用 DTO 隔离数据库实体与 API 契约，避免直接暴露表结构。DTO 让接口契约与表结构解耦，避免字段泄露与破坏性变更。本课还在「项目专属规格：实战：Web API + EF Core」中说明：最小 API、DbContext、内存数据库测试与工程实践。本课还在「零基础详解：ASP.NET Core 项目实战」中说明：知道 ValidateOnStart 的好处。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：ASP.NET Core 中注册在依赖注入容器里的 DbContext 默认生命周期是？

- **正确判断**：Scoped（每请求一个）
- **判断依据**：Scoped 保证一次请求内共享同一上下文，避免跨请求状态与线程问题。其他选项：DbContext 默认是 Scoped（每请求一个），因为它不是线程安全的。针对「ASP.NET Core 中注册在依赖注入容器里…」，本课在「零基础详解：ASP.NET Core 项目实战」中说明：一个可交付的 ASP.NET Core 服务要具备：分层清晰、依赖注入规范、配置校验、统一错误处理、健康检查、测试、容器化。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 4：在分层架构中，Repository 与 Service 的职责划分通常是？

- **正确判断**：Repository 封装数据访问细节
- **判断依据**：正确答案是「Repository 封装数据访问细节」，本课在「零基础详解：ASP.NET Core 项目实战」中说明：能说出 Api、Core、Infrastructure 的职责。把数据访问与业务规则分开，测试时可以替换 Repository 而不依赖真实数据库。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：创建资源成功后返回 201 Created 并结合 CreatedAtAction 的好处是？

- **正确判断**：既符合 REST 语义
- **判断依据**：正确答案是「既符合 REST 语义」，本课在「零基础详解：ASP.NET Core 项目实战」中说明：知道 ValidateOnStart 的好处。201 表示创建成功，Location 头让客户端知道下一步该请求哪个地址。本课还在「工程实践」中说明：加 UseExceptionHandler 统一错误响应，日志用 ILogger。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 6：补全代码：「实战：Web API + EF Core」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `app.____(); // 统一转成 ProblemDetails`

- **正确判断**：UseExceptionHandler / useexceptionhandler
- **判断依据**：正确答案是「UseExceptionHandler」，本课在「工程实践」中说明：加 UseExceptionHandler 统一错误响应，日志用 ILogger。本课示例中还能看到 `app.UseExceptionHandler(); // 统一转成 ProblemDetails` 这样的用法，说明该关键字在本课代码中承担实际功能。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「生产环境管理数据库结构应优先使用？」的判断依据。
- [ ] 不看解析，能说出「使用 DTO 而不是直接暴露实体，主要好处是？」的判断依据。
- [ ] 不看解析，能说出「ASP.NET Core 中注册在依赖注入容器里的 DbContext 默认生命…」的判断依据。
- [ ] 不看解析，能说出「在分层架构中，Repository 与 Service 的职责划分通常是？」的判断依据。
- [ ] 不看解析，能说出「创建资源成功后返回 201 Created 并结合 CreatedAtActio…」的判断依据。
- [ ] 不看解析，能说出「补全代码：「实战：Web API + EF Core」示例中，下面这行代码缺少哪…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `dotnet ef migrations add Init` | 生产环境应使用 EF Core 迁移（`dotnet ef migrations add Init`）而不是 `EnsureCreated`。 |
| `EnsureCreated` | 生产环境应使用 EF Core 迁移（`dotnet ef migrations add Init`）而不是 `EnsureCreated`。 |
| `UseExceptionHandler` | 加 `UseExceptionHandler` 统一错误响应，日志用 ILogger。 |
| `dotnet format --verify-no-changes` | CI 中执行 `dotnet format --verify-no-changes` 与 `dotnet test`。 |
| `dotnet test` | CI 中执行 `dotnet format --verify-no-changes` 与 `dotnet test`。 |
| `[Required]` | \| 请求校验 \| `[Required]`、`[Range]` 等数据注解 + `ModelState` \| |
| `[Range]` | \| 请求校验 \| `[Required]`、`[Range]` 等数据注解 + `ModelState` \| |
| `ModelState` | \| 请求校验 \| `[Required]`、`[Range]` 等数据注解 + `ModelState` \| |
| `dotnet ef migrations add` | \| 数据库迁移 \| `dotnet ef migrations add` 生成脚本，CI 中执行 \| |
| `IDbContextTransaction` | \| 事务 \| 在 Service 层使用 `IDbContextTransaction` 或 `SaveChanges` 一次提交 \| |
| `SaveChanges` | \| 事务 \| 在 Service 层使用 `IDbContextTransaction` 或 `SaveChanges` 一次提交 \| |
| `Skip/Take` | \| 分页 \| `Skip/Take` + 总数查询，或基于游标 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：生产环境管理数据库结构应优先使用？

**参考回答**：正确答案是「EF Core 迁移」，本课在「注册服务」中说明：生产环境应使用 EF Core 迁移（dotnet ef migrations add Init）而不是 EnsureCreated。迁移可增量演进表结构并有版本记录，EnsureCreated 只适合原型。本课还在「工程实践」中说明：用 DTO 隔离数据库实体与 API 契约，避免直接暴露表结构。本课还在「项目专属规格·实战·Web API + EF Core」中说明：最小 API、DbContext、内存数据库测试与工程实践。

### 追问 2：使用 DTO 而不是直接暴露实体，主要好处是？

**参考回答**：正确答案是「隔离数据库结构与 API 契约」，本课在「工程实践」中说明：用 DTO 隔离数据库实体与 API 契约，避免直接暴露表结构。DTO 让接口契约与表结构解耦，避免字段泄露与破坏性变更。本课还在「项目专属规格·实战·Web API + EF Core」中说明：最小 API、DbContext、内存数据库测试与工程实践。本课还在「零基础详解·ASP.NET Core 项目实战」中说明：知道 ValidateOnStart 的好处。

### 追问 3：ASP.NET Core 中注册在依赖注入容器里的 DbContext 默认生命周期是？

**参考回答**：Scoped 保证一次请求内共享同一上下文，避免跨请求状态与线程问题。其他选项：DbContext 默认是 Scoped（每请求一个），因为它不是线程安全的。针对「ASP.NET Core 中注册在依赖注入容器里…」，本课在「零基础详解·ASP.NET Core 项目实战」中说明：一个可交付的 ASP.NET Core 服务要具备：分层清晰、依赖注入规范、配置校验、统一错误处理、健康检查、测试、容器化。

### 追问 4：在分层架构中，Repository 与 Service 的职责划分通常是？

**参考回答**：正确答案是「Repository 封装数据访问细节」，本课在「零基础详解·ASP.NET Core 项目实战」中说明：能说出 Api、Core、Infrastructure 的职责。把数据访问与业务规则分开，测试时可以替换 Repository 而不依赖真实数据库。

### 追问 5：创建资源成功后返回 201 Created 并结合 CreatedAtAction 的好处是？

**参考回答**：正确答案是「既符合 REST 语义」，本课在「零基础详解·ASP.NET Core 项目实战」中说明：知道 ValidateOnStart 的好处。201 表示创建成功，Location 头让客户端知道下一步该请求哪个地址。本课还在「工程实践」中说明：加 UseExceptionHandler 统一错误响应，日志用 ILogger。

## English Overview

**Title:** Project: Web API + EF Core

**Summary:** Minimal APIs, DbContext, tests and practices.

**Category:** C#  
**Level:** 高级  
**Key terms:** 实战, ASP.NET Core, EF Core, xUnit, DTO

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：.NET 9 / C# 13
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、ASP.NET Core、EF Core、xUnit、DTO
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 项目专属规格：实战：Web API + EF Core

### 核心场景

最小 API、DbContext、内存数据库测试与工程实践。 项目目标是把「实战、ASP.NET Core、EF Core、xUnit、DTO」落实为可运行、可测试、可回滚的交付物。

### 架构与数据流

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | 实战、时间、来源 | 必填校验、长度限制、幂等键 |
| 任务实体 | 状态、优先级、创建时间 | 状态迁移合法、不可重复执行 |
| 结果实体 | 输出、错误码、耗时 | 可序列化、错误可解释 |
| 审计记录 | 操作者、动作、结果、时间 | 不可篡改、可查询、脱敏 |

### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：空值、最大值、重复数据和超长内容得到明确处理。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。


## 项目交付物

### 建议仓库结构

```text
src/App/
src/Domain/
tests/App.Tests/
App.sln
README.md
```

### 测试矩阵

| 层级 | 覆盖内容 | 最低数量 | 通过标准 |
| --- | --- | ---: | --- |
| 单元测试 | 领域规则、边界和错误分类 | 8 | 正常、边界、失败路径全部通过 |
| 集成测试 | 数据库、网络、文件或平台边界 | 3 | 使用真实边界且可重复运行 |
| 端到端测试 | 核心用户路径 | 1 | 从输入到输出完整跑通 |
| 手动验收 | 文档中列出的 5 个场景 | 5 | 有命令、输出和结论记录 |

### 验收数据

```json
{
  "project": "csharp_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### 复盘模板

| 问题 | 记录 |
| --- | --- |
| 原目标是什么？ | 用一句话描述可验收目标 |
| 实际发生了什么？ | 时间线、指标和关键日志 |
| 哪个假设被推翻？ | 根因与促成因素 |
| 如何回滚？ | 步骤、耗时和数据校验 |
| 下一步做什么？ | 负责人、期限和验证方式 |

> 项目验收围绕「实战、ASP.NET Core、EF Core」：至少完成一次正常路径、一次边界输入、一次失败恢复和一次幂等检查。


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
- Related terms: 实战, ASP.NET Core, EF Core, xUnit
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning Objectives |
| 前置知识 | Pre-knowledge |
| 创建项目 | Creating a Project Template |
| 数据模型与 DbContext | Data Model and DbContext |
| 注册服务 | Your enrollment, taken care of. |
| 接口实现 | Interface implementation |
| 测试 | Test |
| 工程实践 | Engineering Practice |
| 本课小结 | Lesson Summary |
| Web API 分层速查 | Web API tiered quick lookup |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [C# 官方指南](https://learn.microsoft.com/dotnet/csharp/) | 语言、异步与模式匹配 |
| [.NET 文档](https://learn.microsoft.com/dotnet/) | 运行时、GC 与发布 |

> 本课主题：最小 API、DbContext、内存数据库测试与工程实践。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
