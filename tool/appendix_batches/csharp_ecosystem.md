## 依赖注入速查

| 生命周期 | 行为 | 适用 |
| --- | --- | --- |
| `AddSingleton` | 整个应用一个实例 | 无状态服务、配置、缓存 |
| `AddScoped` | 每个请求一个实例 | `DbContext`、请求级服务 |
| `AddTransient` | 每次解析都新建 | 轻量无状态工具类 |

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<IClock, SystemClock>();
builder.Services.AddScoped<IOrderRepository, EfOrderRepository>();
builder.Services.AddScoped<OrderService>();          // 构造器注入依赖
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Db")));

var app = builder.Build();

app.UseExceptionHandler("/error");                   // 中间件顺序很关键
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.Run();
```

## 测试速查（xUnit）

| 目的 | 写法 |
| --- | --- |
| 定义测试 | `[Fact]` |
| 参数化 | `[Theory]` + `[InlineData]` / `[MemberData]` |
| 断言相等 | `Assert.Equal(expected, actual)` |
| 断言异常 | `Assert.Throws<InvalidOperationException>(() => ...)` |
| 断言集合包含 | `Assert.Contains(item, list)` |
| 断言区间 | `Assert.InRange(value, low, high)` |
| 异步测试 | `async Task` + `await Assert.ThrowsAsync<...>(...)` |
| 共享夹具 | `IClassFixture<T>` |
| 跳过测试 | `[Fact(Skip = "待实现")]` |

```csharp
public class PriceTests
{
    [Theory]
    [InlineData(100, 10)]
    [InlineData(300, 0)]
    public void ShippingFee_ByAmount(int amount, int expected)
    {
        var calculator = new PriceCalculator();
        Assert.Equal(expected, calculator.ShippingFee("normal", amount));
    }
}
```

## EF Core 速查

| 目的 | 写法 |
| --- | --- |
| 定义实体 | `public class Order { public int Id { get; set; } }` |
| 查询 | `await db.Orders.Where(o => o.Paid).ToListAsync()` |
| 单条查询 | `await db.Orders.FindAsync(id)` |
| 只读查询 | `.AsNoTracking()` 减少跟踪开销 |
| 分页 | `.OrderBy(o => o.Id).Skip(20).Take(10)` |
| 投影 | `.Select(o => new OrderDto { Id = o.Id })` |
| 预加载关联 | `.Include(o => o.Items)` |
| 避免 N+1 | `Include` / `Select` 投影一次取回 |
| 模型配置 | `IEntityTypeConfiguration<T>` 或 Fluent API |
| 迁移 | `dotnet ef migrations add Init`、`dotnet ef database update` |
| 并发控制 | 并发令牌（`[ConcurrencyCheck]` / `RowVersion`） |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `DbContext` 注册为 Singleton | 并发访问异常、状态错乱 | 必须用 `AddScoped` |
| 在后台线程用请求内的 `DbContext` | `ObjectDisposedException` | 每个作用域解析自己的实例 |
| 生命周期倒挂（Singleton 依赖 Scoped） | 启动时报错 | 检查依赖方向，必要时用工厂 |
| 中间件顺序错误 | 认证/授权不生效 | 按框架推荐顺序注册 |
| 在循环里查询数据库 | N+1 查询 | 批量查询或 `Include` |
| 修改实体后忘记 `SaveChangesAsync` | 数据没保存 | 明确提交点 |
| 用 `FirstOrDefault` 后不判空 | `NullReferenceException` | 判空或返回 404 |
| 测试里连真实数据库 | 慢且不稳定 | 用内存库、容器或测试替身 |
| 直接用 `Console.WriteLine` | 生产日志无法收集 | 用 `ILogger<T>` 结构化日志 |
| 连接字符串写死在代码里 | 泄漏与无法切换环境 | 用配置与环境变量 |

## 自测清单

- [ ] 能说清 Singleton / Scoped / Transient 的取舍。
- [ ] `DbContext` 使用 Scoped 生命周期。
- [ ] 会用 `AsNoTracking` 优化只读查询，并避免 N+1。
- [ ] 单元测试覆盖正常、边界与异常路径。
- [ ] 日志用 `ILogger<T>`，配置来自环境变量。
