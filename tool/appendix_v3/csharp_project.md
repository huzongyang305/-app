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
