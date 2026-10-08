# 实战：Web API + EF Core

![Web API 与 EF Core 的请求链路](images/diagram_cs_webapi_project.webp)

![实战：Web API + EF Core](images/remaining_csharp_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：120 分钟

## 本节知识框架

**课程定位**：所属分类为「C#」，课程主题为「实战：Web API + EF Core」，学习阶段为「高级」，建议用时 120 分钟。

**本课要解决的主问题**：最小 API、DbContext、内存数据库测试与工程实践。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「实战：Web API + EF Core」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「实战：Web API + EF Core」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「实战」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《生态、测试与 Web 开发》

**学习位置**：本课位于《生态、测试与 Web 开发》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《实战：C# 库存管理 CLI》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释实战：Web API + EF Core解决了什么问题，而不是只背术语。
- 能说清 「实战」、「ASP.NET Core」、「EF Core」、「xUnit」 之间的关系，并分别举出一个例子。
- 能把 实战 放回「实战：Web API + EF Core」的知识体系，说明它和 ASP.NET Core 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：最小 API、DbContext、内存数据库测试与工程实践。

**教材衔接：前置知识**

- 先完成上一课《生态、测试与 Web 开发》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：实战、ASP.NET Core、EF Core。
- 如果 创建项目 这一步看不懂，先记录具体卡点，再用 EntityFrameworkCore 复现一遍。

**教材衔接：本课小结**

最小可用的 .NET 后端 = **EF Core 持久化 + 最小 API 路由 + 依赖注入 + xUnit 测试**；跑通后再按需要加认证、缓存与容器化部署。

## 核心概念定义

> 阅读约定：本课先给「实战：Web API + EF Core」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| dotnet ef migrations add Init | 生产环境应使用 EF Core 迁移（dotnet ef migrations add Init）而不是 EnsureCreated。 | 仅在「实战：Web API + EF Core」明确给出的输入、版本与资源条件下成立。 |
| UseExceptionHandler | 加 UseExceptionHandler 统一错误响应，日志用 ILogger。 | 仅在「实战：Web API + EF Core」明确给出的输入、版本与资源条件下成立。 |
| dotnet test | CI 中执行 dotnet format --verify-no-changes 与 dotnet test。 | 仅在「实战：Web API + EF Core」明确给出的输入、版本与资源条件下成立。 |
| 实战 | 实战：Web API + EF Core解决了什么问题，而不是只背术语。 | 仅在「实战：Web API + EF Core」明确给出的输入、版本与资源条件下成立。 |
| 错误处理 | 识别、传播并恢复异常或失败路径，避免错误被吞掉或扩大影响 | 仅在「实战：Web API + EF Core」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「实战：Web API + EF Core」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：数据模型与 DbContext**

```csharp
public record Todo(int Id, string Title, bool Done, DateTime CreatedAt);
public record TodoRequest(string Title);
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<Todo> Todos => Set<Todo>();
}
```

## 原理与运行机制

### 机制总览

1. **建立输入**：把「dotnet ef migrations add Init」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「UseExceptionHandler」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「dotnet test」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「实战：Web API + EF Core」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | dotnet ef migrations add Init | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | UseExceptionHandler | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | dotnet test | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「实战：Web API + EF Core」自己的示例验证。「实战：Web API + EF Core」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：接口实现**

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

**教材衔接：工程实践**

1. 用 DTO 隔离数据库实体与 API 契约，避免直接暴露表结构。
2. 入口做校验（DataAnnotations / FluentValidation），业务规则放服务层。
3. 配置分环境，密钥用 User Secrets 或环境变量。
4. 加 `UseExceptionHandler` 统一错误响应，日志用 ILogger。
5. CI 中执行 `dotnet format --verify-no-changes` 与 `dotnet test`。

**教材衔接：实践要点速查**

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

**教材衔接：版本与时效**

- C# 版本随 SDK 演进，升级前把 ASP.NET Core 的兼容性纳入检查清单。
- 升级重点在语法与裁剪行为；先为 ASP.NET Core 补一组回归用例。
- 升级前先用 EntityFrameworkCore 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。
- 官方说明：https://learn.microsoft.com/dotnet/core/whats-new/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 实战 的版本变量，记录编译、测试与产物体积的变化。
- 升级后重点回归 实战 的默认值、警告信息与错误格式。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 实战 的版本变化。

**教材衔接：交付评审：评分表、决策记录与证据链**

「实战：Web API + EF Core」的验收不能只看功能能不能跑通。下面把正文里的交付物、验证命令和关键设计点整理成一张评审表，按表逐项留下证据即可。

### 一、「实战：Web API + EF Core」的交付物评分表

| 交付物 | 权重 | 合格线 | 需要的证据 |
| --- | ---: | --- | --- |
| 核心链路 | 34% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 测试与验收记录 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |
| 运行与回滚说明 | 33% | 能在干净环境复现，且失败路径有明确处理 | 命令与输出、对应测试、一次失败与恢复记录 |

「实战：Web API + EF Core」的评分先看证据再打分：任意一项只要拿不出可复现的命令或测试，该项按 0 分计，不允许用「基本完成」代替。

### 二、需要写下来的决策（ADR）

| 决策点 | 本课给出的做法 | 备选方案 | 代价与回滚 |
| --- | --- | --- | --- |
| 架构与数据流 | 用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控 | 不做「架构与数据流」，沿用最朴素的实现（需要额外补一次对照实验） | 若「架构与数据流」出问题，回到上一版本并按本课验收场景重跑 |

ADR 不需要长：每个决策三行就够——选了什么、放弃了什么、出问题怎么退。评审时只检查这三行是否和「实战：Web API + EF Core」的实际代码一致。

### 三、「实战：Web API + EF Core」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：

1. 一条从零开始的环境准备命令。
2. 一条跑通核心链路的命令及其完整输出。
3. 一条触发失败的命令，以及恢复后的验证结果。

把「实战：Web API + EF Core」的上表整理成一个 evidence/ 目录：每条命令一个文件，文件名带日期，内容包含版本、命令与输出。评审时直接按目录核对，不再口头确认。

### 四、「实战：Web API + EF Core」的验收指标

| 指标 | 目标值 | 测量方式 | 不达标时的动作 |
| --- | --- | --- | --- |
| 实战 的核心路径耗时与失败率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 资源占用峰值与回收情况 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |
| 验收场景的通过率 | 用本课正文给出的阈值，没有就写实测基线 | 固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |

指标必须能用一条命令或一次操作测出来；写不出测量方式的指标，在「实战：Web API + EF Core」的评审里一律视为未定义。

### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `csharp_project` |
| 本次范围 | 说明这一轮交付了「实战：Web API + EF Core」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

「实战：Web API + EF Core」评审结束后把这张表填完并归档；下一轮迭代直接读上一次的「未完成项」与「风险与回滚」，避免重复讨论同一个问题。
<!-- p1-project-review:end -->

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 实战、ASP.NET Core | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「实战：Web API + EF Core」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「实战：Web API + EF Core」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:csharp`，用于动手验证《实战：Web API + EF Core》的机制；实验结论不替代概念定义与复杂度分析。

**教材衔接：创建项目**

```bash
dotnet new webapi -o TodoApi --use-minimal-apis
cd TodoApi
dotnet add package Microsoft.EntityFrameworkCore.Sqlite
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet new xunit -o ../TodoApi.Tests
dotnet add ../TodoApi.Tests reference ../TodoApi
```

**教材衔接：零基础详解：ASP.NET Core 项目实战**

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

**教材衔接：项目专属规格：实战：Web API + EF Core**

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
2. 边界路径：把 EntityFrameworkCore 的输入推到上下限，确认返回结果可解释。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：撤掉 EntityFrameworkCore 的变更后，数据与资源都回到变更前的状态。

**教材衔接：项目交付物**

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
  "scenario": "实战的正常路径",
  "input": {"case": "normal", "value": "EntityFrameworkCore"},
  "expected": {"ok": true, "checks": ["实战可复现", "ASP.NET Core有记录"]},
  "failure_case": {"case": "ASP.NET Core越界或缺失", "error": "validation_error"},
  "idempotency_key": "csharp_project-001"
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

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《实战：Web API + EF Core》原文中的最小示例。先预测《实战：Web API + EF Core》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```bash
dotnet new webapi -o TodoApi --use-minimal-apis
cd TodoApi
dotnet add package Microsoft.EntityFrameworkCore.Sqlite
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet new xunit -o ../TodoApi.Tests
dotnet add ../TodoApi.Tests reference ../TodoApi
```

**教材衔接：注册服务**

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

**教材衔接：测试**

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

**教材衔接：Web API 分层速查**

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

**教材衔接：验证命令与预期输出**

「实战：Web API + EF Core」不能只看「能编译」，还要能按固定命令复现结果。下表给出最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 还原依赖 | `dotnet restore` | 依赖还原成功 |
| 运行测试 | `dotnet test` | 所有 xUnit 测试通过 |
| 启动示例 | `dotnet run` | 应用启动并输出预期结果 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 至少运行 3 条 实战 相关测试，其中一条是非法输入或失败路径。
- [ ] 连续两次触发 ASP.NET Core，检查数据与计数是否被重复累加。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 交付说明包含版本、启动、验证与回滚四部分。

### 回归与回滚

1. 先在可丢弃的目录或临时库里跑 实战，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

## 时间/空间复杂度或性能分析

**复杂度证据**：「实战：Web API + EF Core」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「实战：Web API + EF Core」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「实战：Web API + EF Core」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《实战：Web API + EF Core》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「实战：Web API + EF Core」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

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

**教材衔接：故障现场**

### 现场 1：返回实体而不是 DTO

**症状**：在《实战：Web API + EF Core》的复现场景中，泄漏字段、循环引用。

**根因**：当出现“返回实体而不是 DTO”时，执行路径已经绕过了《实战：Web API + EF Core》的关键约束，最终以“泄漏字段、循环引用”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《实战：Web API + EF Core》的问题，用 DTO 投影。

**验证**：先在《实战：Web API + EF Core》中记录“返回实体而不是 DTO”留下的失败证据，再执行“用 DTO 投影”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：Controller 里写业务逻辑

**症状**：在《实战：Web API + EF Core》的复现场景中，无法复用与测试。

**根因**：触发点是把“Controller 里写业务逻辑”当成安全做法。它没有满足《实战：Web API + EF Core》要求的前提，因此先表现为“无法复用与测试”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《实战：Web API + EF Core》的问题，移到 Service。

**验证**：先在《实战：Web API + EF Core》中记录“Controller 里写业务逻辑”留下的失败证据，再执行“移到 Service”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：用异常做正常流程控制

**症状**：在《实战：Web API + EF Core》的复现场景中，性能差、语义混乱。

**根因**：触发点是把“用异常做正常流程控制”当成安全做法。它没有满足《实战：Web API + EF Core》要求的前提，因此先表现为“性能差、语义混乱”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《实战：Web API + EF Core》的问题，用返回值或 TryXxx。

**验证**：在《实战：Web API + EF Core》中按“用返回值或 TryXxx”调整后，从“用异常做正常流程控制”的触发条件重放同一条路径，确认“性能差、语义混乱”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《生态、测试与 Web 开发》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《实战：C# 库存管理 CLI》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《生态、测试与 Web 开发》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《实战：C# 库存管理 CLI》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「实战：Web API + EF Core」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《实战：Web API + EF Core》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

下面这段 C# 代码摘自「实战：Web API + EF Core」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？

```csharp
public record Todo(int Id, string Title, bool Done, DateTime CreatedAt);
public record TodoRequest(string Title);
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<Todo> Todos => Set<Todo>();
}
```

A. 这段代码只做静态声明，没有循环、分支或可观察输出。
B. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
C. 这段代码会读取外部输入，结果依赖传入的数据。
D. 这段代码会产生可观察的输出，运行后能看到结果。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「实战：Web API + EF Core」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「实战：Web API + EF Core」的正文示例，围绕实战、ASP.NET Core、EF Core展开；把输入或边界换成空值、极值或失败情况后，结论要以「实战：Web API + EF Core」的实际运行结果为准。

### 自测 2

使用 DTO 而不是直接暴露实体，主要好处是？

A. 提高并发
B. 隔离数据库结构与 API 契约
C. 只是为了减少重复代码量，但这会引入新的复杂度
D. 自动加密

**参考答案**：隔离数据库结构与 API 契约

**解析**：在「实战：Web API + EF Core」里，隔离数据库结构与 API 契约。DTO 让接口契约与表结构解耦，避免字段泄露与破坏性变更。“而不是直接暴露实体”与「实战：Web API + EF Core」的术语表相呼应，只有符合实战、ASP.NET Core、EF Core约束的“隔离数据库结构与 API 契约”才是正文支持的结论。

### 自测 3

围绕“实战：Web API + EF Core”中的 实战、ASP.NET Core、EF Core，下列哪两项是本课强调的实践判断？

A. 把 ASP.NET Core 的单次运行结果当成所有版本和规模都成立
B. 学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 实战 的常规示例通过，就可以跳过边界与异常路径
D. 验证 ASP.NET Core 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 ASP.NET Core 时要固定版本并覆盖边界输入，结论才可复现

**解析**：结论应落在学习 实战 时要同时说明输入、输出和失败路径。在实战：Web API + EF Core里，判断 ASP.NET Core 时要固定版本与边界输入，所以“验证 ASP.NET Core 时要固定版本并覆盖边界输入，结论才可复现”才可复现。在「实战：Web API + EF Core」里，这道题要求区分概念与边界，学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程。

**教材衔接：复习与自测**

- [ ] 分层清晰，Controller 只做协议转换。
- [ ] 请求与响应都使用 DTO 并做校验。
- [ ] 所有异步方法透传 `CancellationToken`。
- [ ] 数据库结构由迁移脚本管理并接入 CI。
- [ ] 统一错误响应格式，日志脱敏且带请求 ID。

**教材衔接：动手练习**

> 本课练习重点：围绕「实战、ASP.NET Core、EF Core」完成复述、实验和交付，每个结果都要能被别人检查。

先建最小控制台程序演示 实战，再补异常路径，最后用 dotnet test 验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 实战：Web API + EF Core解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ASP.NET Core」是什么关系？

验收标准：回答里必须出现 实战，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：用 EntityFrameworkCore 复现原例后，把ASP.NET Core改成边界值，五步记录缺一不可，其中「原因」一栏要写明「实战：Web API + EF Core」里哪条规则被触发。

### 练习 3：交付一个小结果（30 分钟）

写一个控制台小程序，补一个正例、一个边界值和一个异常路径。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「实战」和「ASP.NET Core」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```bash
dotnet ef migrations add AddOrderIndex
dotnet ef database update
dotnet ef migrations script --idempotent -o migrate.sql   # 生产用脚本
```

### 任务 2：只改一个条件

把「实战：Web API + EF Core」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 ASP.NET Core 换成边界值，其他输入保持原样。
- 预测：先写下「实战：Web API + EF Core」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响实战。

### 任务 3：迁移到自己的数据

把 EntityFrameworkCore 换成你自己的输入，先保持步骤不变，再比较输出差异。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「生产环境管理数据库结构应优先使用？」的判断依据。
- [ ] 不看解析，能说出「使用 DTO 而不是直接暴露实体，主要好处是？」的判断依据。
- [ ] 不看解析，能说出「在分层架构中，Repository 与 Service 的职责划分通常是？」的判断依据。
- [ ] 用 实战 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
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
| `dotnet ef migrations add Init` | 生产环境应使用 EF Core 迁移（`dotnet ef migrations add Init`）而不是 `EnsureCreated`。 |
| `UseExceptionHandler` | 加 `UseExceptionHandler` 统一错误响应，日志用 ILogger。 |
| `dotnet test` | CI 中执行 `dotnet format --verify-no-changes` 与 `dotnet test`。 |
| `实战` | 实战：Web API + EF Core解决了什么问题，而不是只背术语。 |
| `错误处理` | 识别、传播并恢复异常或失败路径，避免错误被吞掉或扩大影响 |

## 考点精讲

### 考点 1：代码补全·实战

- **题目**：下面这段 C# 代码摘自「实战：Web API + EF Core」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「实战：Web API + EF Core」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「实战：Web API + EF Core」的正文示例，围绕实战、ASP.NET Core、EF Core展开；把输入或边界换成空值、极值或失败情况后，结论要以「实战：Web API + EF Core」的实际运行结果为准。

### 考点 2：概念判断·实战

- **题目**：使用 DTO 而不是直接暴露实体，主要好处是？
- **判断依据**：在「实战：Web API + EF Core」里，隔离数据库结构与 API 契约。DTO 让接口契约与表结构解耦，避免字段泄露与破坏性变更。“而不是直接暴露实体”与「实战：Web API + EF Core」的术语表相呼应，只有符合实战、ASP.NET Core、EF Core约束的“隔离数据库结构与 API 契约”才是正文支持的结论。

### 考点 3：概念判断·实战

- **题目**：ASP.NET Core 中注册在依赖注入容器里的 DbContext 默认生命周期是？
- **判断依据**：Scoped 保证一次请求内共享同一上下文，避免跨请求状态与线程问题。在「实战：Web API + EF Core」里，其他选项：DbContext 默认是 Scoped（每请求一个），因为它不是线程安全的。这道题的关键在「实战：Web API + EF Core」的实战、ASP.NET Core、EF Core：先确认题干“ASP.NET Core 中注册在依”问的是哪一步，再排除偷换前提的选项。

### 考点 4：多选辨析·实战

- **题目**：围绕“实战：Web API + EF Core”中的 实战、ASP.NET Core、EF Core，下列哪两项是本课强调的实践判断？
- **判断依据**：结论应落在学习 实战 时要同时说明输入、输出和失败路径。在实战：Web API + EF Core里，判断 ASP.NET Core 时要固定版本与边界输入，所以“验证 ASP.NET Core 时要固定版本并覆盖边界输入，结论才可复现”才可复现。在「实战：Web API + EF Core」里，这道题要求区分概念与边界，学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程。

### 考点 5：概念判断·实战

- **题目**：创建资源成功后返回 201 Created 并结合 CreatedAtAction 的好处是？
- **判断依据**：在「实战：Web API + EF Core」里，既符合 REST 语义。201 表示创建成功，Location 头让客户端知道下一步该请求哪个地址。在「实战：Web API + EF Core」里判断这道题，要把实战、ASP.NET Core、EF Core的条件、过程与失败路径逐项对齐，换成“创建资源成功后返回 201 Crea”这个场景，只有满足前提的结论才成立。

### 考点 6：填空·实战

- **题目**：补全代码：「实战：Web API + EF Core」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `app.____; // 统一转成 ProblemDetails`
- **判断依据**：空格应填写「UseExceptionHandler」、「useexceptionhandler」。// 统一转成 ProblemDetails 这样的用法，说明该关键字在本课代码中承担实际功能。在「实战：Web API + EF Core」里判断这道题，要把实战、ASP.NET Core、EF Core的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。

## English Overview

**Title:** Project: Web API + EF Core

**Summary:** Minimal APIs, DbContext, tests and practices.

**Category:** C#
**Level:** 高级
**Key terms:** 实战, ASP.NET Core, EF Core, xUnit, DTO

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：.NET 9 / C# 13
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、ASP.NET Core、EF Core、xUnit、DTO
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**Project: Web API + EF Core** focuses on Minimal APIs, DbContext, tests and practices.

### Learning Outcomes

- Explain what **Project: Web API + EF Core** solves and when it should be used.

### Glossary

- Topic: **Project: Web API + EF Core**
- Related terms: 实战, ASP.NET Core, EF Core, xUnit

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

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [.NET 文档](https://learn.microsoft.com/dotnet/) | 运行时、库与工具链 |
| [.NET 测试文档](https://learn.microsoft.com/dotnet/core/testing/) | 单元测试与集成测试 |
| [EF Core 文档](https://learn.microsoft.com/ef/core/) | ORM、迁移与并发 |

> 「实战：Web API + EF Core」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->
