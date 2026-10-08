# 生态、测试与 Web 开发

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：65 分钟

![.NET 生态的关键组成](images/diagram_cs_ecosystem.webp)

![生态、测试与 Web 开发](images/remaining_csharp_ecosystem.webp)

## 本节知识框架

**课程定位**：所属分类为「C#」，课程主题为「生态、测试与 Web 开发」，学习阶段为「进阶」，建议用时 65 分钟。

**本课要解决的主问题**：NuGet、xUnit 测试、ASP.NET Core 最小 API 与 EF Core。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「生态、测试与 Web 开发」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「生态、测试与 Web 开发」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「NuGet」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《异步编程与异常处理》

**学习位置**：本课位于《异步编程与异常处理》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《实战：Web API + EF Core》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释生态、测试与 Web 开发解决了什么问题，而不是只背术语。
- 能说清 「NuGet」、「xUnit」、「ASP.NET Core」、「EF Core」 之间的关系，并分别举出一个例子。
- 能把 NuGet 放回「生态、测试与 Web 开发」的知识体系，说明它和 xUnit 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：NuGet、xUnit 测试、ASP.NET Core 最小 API 与 EF Core。

**教材衔接：前置知识**

- 先完成上一课《异步编程与异常处理》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「异步编程与异常处理」，或确认自己能独立跑通正文里的 Add_WorksForManyCases 示例。
- 开始前先复习：NuGet、xUnit、ASP.NET Core。
- 卡在 NuGet 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

C# 的工程能力 = **NuGet 管依赖、xUnit 写测试、ASP.NET Core 做服务、EF Core 访问数据库**。先把这几件用熟，再按业务扩展。

## 核心概念定义

> 阅读约定：本课先给「生态、测试与 Web 开发」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| dotnet restore | 版本号尽量显式固定；dotnet restore 会按 lock 文件还原依赖，保证 CI 与本地一致。 | 仅在「生态、测试与 Web 开发」明确给出的输入、版本与资源条件下成立。 |
| Add-Migration | EF Core 把 LINQ 翻译成 SQL，配合迁移（Add-Migration / Database.Migrate()）管理表结构。 | 仅在「生态、测试与 Web 开发」明确给出的输入、版本与资源条件下成立。 |
| EF Core | EF Core 把 LINQ 翻译成 SQL，配合迁移（Add-Migration / Database.Migrate()）管理表结构。 | 仅在「生态、测试与 Web 开发」明确给出的输入、版本与资源条件下成立。 |
| NuGet | .NET 的包管理器，restore 按项目文件解析并下载依赖，锁文件用于固定版本。 | 仅在「生态、测试与 Web 开发」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「生态、测试与 Web 开发」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「dotnet restore」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「Add-Migration」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「EF Core」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「生态、测试与 Web 开发」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | dotnet restore | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | Add-Migration | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | EF Core | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「生态、测试与 Web 开发」自己的示例验证。「生态、测试与 Web 开发」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：常用生态速览**

| 领域 | 常用选择 |
| --- | --- |
| Web / API | ASP.NET Core、Minimal API、Blazor |
| ORM | EF Core、Dapper |
| 日志 | Serilog、NLog、内置 ILogger |
| 测试 | xUnit、NUnit、Moq |
| 序列化 | System.Text.Json、Newtonsoft.Json |
| 桌面 / 移动 | WPF、WinUI、MAUI |

**教材衔接：EF Core 速查**

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

**教材衔接：版本与时效**

- 先确认 SDK 版本，再决定 Add_WorksForManyCases 是否可以使用新语法或新 API。
- 若使用 AOT 或裁剪，Add_WorksForManyCases 的反射与动态加载路径需要重点验证。
- 升级「生态、测试与 Web 开发」涉及的依赖前，先用 Add_WorksForManyCases 复现当前行为，再逐项核对版本说明与破坏性变更。
- 官方说明：https://learn.microsoft.com/dotnet/core/whats-new/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 NuGet 的版本变量，记录编译、测试与产物体积的变化。
- 先回归 NuGet 与 xUnit 的默认行为和错误信息，再扩大测试范围。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 NuGet 的版本变化。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 NuGet、xUnit | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「生态、测试与 Web 开发」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「生态、测试与 Web 开发」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:csharp`，用于动手验证《生态、测试与 Web 开发》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《生态、测试与 Web 开发》原文中的最小示例。先预测《生态、测试与 Web 开发》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```bash
dotnet add package Serilog              # 添加依赖
dotnet list package                    # 查看已安装包
dotnet remove package Serilog
```

**教材衔接：NuGet 包管理**

```bash
dotnet add package Serilog              # 添加依赖
dotnet list package                    # 查看已安装包
dotnet remove package Serilog
```

项目文件中的引用：

```xml
<ItemGroup>
  <PackageReference Include="Serilog" Version="3.1.1" />
</ItemGroup>
```

版本号尽量显式固定；`dotnet restore` 会按 lock 文件还原依赖，保证 CI 与本地一致。

**教材衔接：单元测试**

```csharp
// 使用 xUnit
public class CalculatorTests
{
    [Fact]
    public void Add_ReturnsSum()
    {
        Assert.Equal(5, Calculator.Add(2, 3));
    }

    [Theory]
    [InlineData(1, 2, 3)]
    [InlineData(-1, 1, 0)]
    public void Add_WorksForManyCases(int a, int b, int expected)
    {
        Assert.Equal(expected, Calculator.Add(a, b));
    }
}
```

```bash
dotnet new xunit -o Tests
dotnet test --collect:"XPlat Code Coverage"
```

测试命名建议「方法_场景_期望」，一个测试只验证一件事。

**教材衔接：ASP.NET Core 最小 API**

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<ITodoService, TodoService>();   // 依赖注入

var app = builder.Build();

app.MapGet("/todos/{id:int}", (int id, ITodoService service) =>
    service.Find(id) is { } todo ? Results.Ok(todo) : Results.NotFound());

app.MapPost("/todos", (Todo todo, ITodoService service) =>
{
    service.Add(todo);
    return Results.Created($"/todos/{todo.Id}", todo);
});

app.Run();
```

内置依赖注入、配置、日志与中间件管道，是 .NET 后端开发的主流框架。

**教材衔接：EF Core 数据访问**

```csharp
public class AppDbContext : DbContext
{
    public DbSet<User> Users => Set<User>();
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
}

var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id);
db.Users.Add(new User { Name = "tom" });
await db.SaveChangesAsync();
```

EF Core 把 LINQ 翻译成 SQL，配合迁移（`Add-Migration` / `Database.Migrate()`）管理表结构。

**教材衔接：依赖注入速查**

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

**教材衔接：测试速查（xUnit）**

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

**教材衔接：零基础详解：.NET 生态与工程实践**

### 一句话说清它是什么

.NET 生态的日常可以概括为四件事：**建项目、装依赖、跑测试、发布**。
`dotnet` 命令把这四件事串起来，不用装额外的构建工具。

### 用生活比喻理解

| 组件 | 比喻 | 说明 |
| --- | --- | --- |
| SDK | 整套车间 | 编译、运行、模板、包管理 |
| NuGet | 零件超市 | 第三方库来源 |
| NuGet.config | 指定去哪家超市 | 配置私服镜像 |
| `dotnet test` | 验收 | 跑单元测试 |
| `dotnet publish` | 打包发货 | 生成可部署产物 |

### 常用命令速查

```bash
dotnet --info                       # 查看 SDK 与运行时版本
dotnet new list                     # 列出可用模板
dotnet new webapi -o MyApi          # 新建 Web API 项目
dotnet new xunit -o MyApi.Tests     # 新建测试项目
dotnet new sln -n MyApp             # 新建解决方案
dotnet sln add src/MyApi            # 把项目加进解决方案

dotnet restore                      # 还原依赖
dotnet build -c Release             # 构建
dotnet test --collect:"XPlat Code Coverage"   # 测试 + 覆盖率
dotnet run --project src/MyApi      # 运行
dotnet publish -c Release -o out    # 发布
dotnet add package Serilog          # 添加依赖
dotnet list package --outdated      # 检查可升级包
```

### 解决方案结构

```text
MyApp/
  MyApp.sln
  Directory.Build.props        统一编译属性（所有项目共用）
  src/
    MyApp.Api/                 Web API
    MyApp.Core/                业务逻辑
    MyApp.Infrastructure/      数据库与外部服务
  tests/
    MyApp.UnitTests/
    MyApp.IntegrationTests/
```

### Directory.Build.props：一处配置全仓库生效

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
  </PropertyGroup>
</Project>
```

| 配置 | 作用 |
| --- | --- |
| `Nullable` | 开启可空引用类型检查 |
| `TreatWarningsAsErrors` | 警告即失败，防止劣化 |
| `EnforceCodeStyleInBuild` | 构建时执行代码风格规则 |
| `AnalysisLevel` | 启用推荐的分析器规则 |

### 配置文件与选项模式

```json
// appsettings.json
{
  "Database": {
    "Host": "localhost",
    "Port": 5432
  },
  "Logging": { "LogLevel": { "Default": "Information" } }
}
```

```csharp
public sealed class DatabaseOptions
{
    public const string Section = "Database";
    public required string Host { get; init; }
    public int Port { get; init; } = 5432;
}

// Program.cs
builder.Services
    .AddOptions<DatabaseOptions>()
    .Bind(builder.Configuration.GetSection(DatabaseOptions.Section))
    .ValidateDataAnnotations()
    .ValidateOnStart();          // 启动时校验，而不是运行到一半才崩
```

### 日志与依赖注入

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<IClock, SystemClock>();
builder.Services.AddScoped<IUserRepository, UserRepository>();   // 每个请求一个
builder.Services.AddHttpClient<IPaymentClient, PaymentClient>()
    .AddStandardResilienceHandler();      // 内建重试、超时、熔断

var app = builder.Build();

app.MapGet("/users/{id:int}", async (int id, IUserRepository repo, ILogger<Program> logger) =>
{
    logger.LogInformation("查询用户 {UserId}", id);
    var user = await repo.FindAsync(id);
    return user is null ? Results.NotFound() : Results.Ok(user);
});

app.Run();
```

### 生命周期的选择（最常见的坑）

| 生命周期 | 何时创建 | 适用 |
| --- | --- | --- |
| Singleton | 应用启动一次 | 无状态工具、配置 |
| Scoped | 每个请求一个 | 数据库上下文、仓储 |
| Transient | 每次注入都新建 | 轻量无状态服务 |

**规则**：Singleton 不能直接依赖 Scoped，否则捕获了短生命周期对象。

### 测试项目

```csharp
public class PriceTests
{
    [Theory]
    [InlineData(19.9, "19.90")]
    [InlineData(0, "0.00")]
    public void FormatsWithTwoDecimals(decimal value, string expected)
    {
        Assert.Equal(expected, Price.Format(value));
    }

    [Fact]
    public void ThrowsOnNegative()
    {
        var ex = Assert.Throws<ArgumentOutOfRangeException>(() => Price.Format(-1));
        Assert.Contains("不能为负", ex.Message);
    }
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| Singleton 注入 Scoped | 启动时报错或运行异常 | 按生命周期匹配，或注入 `IServiceScopeFactory` |
| 用 `new` 创建服务 | 绕过依赖注入，难以测试 | 全部从容器解析 |
| 配置不校验 | 运行到一半才崩 | `ValidateOnStart()` |
| 忘记 `TreatWarningsAsErrors` | 警告越积越多 | 在 props 里统一开启 |
| 每个项目各写版本 | 版本不一致 | 用 `Directory.Packages.props` 集中管理 |
| 直接 `dotnet publish` 不跑测试 | 带病发布 | CI 先 `dotnet test` |
| 用 `DateTime.Now` | 时区与测试问题 | 注入 `IClock` 或统一用 UTC |
| 大项目不分层 | 业务与基础设施耦合 | 按 Api / Core / Infrastructure 分层 |

### 手把手练习：集中管理依赖版本

```xml
<!-- Directory.Packages.props -->
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Serilog.AspNetCore" Version="8.0.3" />
    <PackageVersion Include="xunit" Version="2.9.2" />
    <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.12.0" />
  </ItemGroup>
</Project>
```

之后各项目只写包名，不写版本，升级时改一处即可：

```xml
<ItemGroup>
  <PackageReference Include="Serilog.AspNetCore" />
</ItemGroup>
```

```bash
dotnet build -c Release
dotnet test --collect:"XPlat Code Coverage"
dotnet publish src/MyApp.Api -c Release -o out
```

### 学完自测

- [ ] 能说出 SDK 与运行时的区别。
- [ ] 知道三种服务生命周期各自适用什么场景。
- [ ] 能说出 `ValidateOnStart` 的好处。
- [ ] 知道为什么要集中管理包版本。
- [ ] 能说出 Singleton 依赖 Scoped 会有什么问题。

## 时间/空间复杂度或性能分析

**复杂度证据**：「生态、测试与 Web 开发」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「生态、测试与 Web 开发」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「生态、测试与 Web 开发」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《生态、测试与 Web 开发》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「生态、测试与 Web 开发」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

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

**教材衔接：故障现场**

### 现场 1：DbContext 注册为 Singleton

**症状**：在《生态、测试与 Web 开发》的复现场景中，并发访问异常、状态错乱。

**根因**：当出现“DbContext 注册为 Singleton”时，执行路径已经绕过了《生态、测试与 Web 开发》的关键约束，最终以“并发访问异常、状态错乱”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《生态、测试与 Web 开发》的问题，必须用 AddScoped。

**验证**：先在《生态、测试与 Web 开发》中记录“DbContext 注册为 Singleton”留下的失败证据，再执行“必须用 AddScoped”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：在后台线程用请求内的 DbContext

**症状**：在《生态、测试与 Web 开发》的复现场景中，ObjectDisposedException。

**根因**：“ObjectDisposedException”只是表层结果。向上追溯会落到“在后台线程用请求内的 DbContext”这一步，因为它省略了《生态、测试与 Web 开发》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《生态、测试与 Web 开发》的问题，每个作用域解析自己的实例。

**验证**：保留《生态、测试与 Web 开发》里触发“ObjectDisposedException”的输入、版本和日志，按“每个作用域解析自己的实例”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：中间件顺序错误

**症状**：在《生态、测试与 Web 开发》的复现场景中，认证/授权不生效。

**根因**：当出现“中间件顺序错误”时，执行路径已经绕过了《生态、测试与 Web 开发》的关键约束，最终以“认证/授权不生效”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《生态、测试与 Web 开发》的问题，按框架推荐顺序注册。

**验证**：保留《生态、测试与 Web 开发》里触发“认证/授权不生效”的输入、版本和日志，按“按框架推荐顺序注册”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《异步编程与异常处理》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《实战：Web API + EF Core》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《异步编程与异常处理》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《实战：Web API + EF Core》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「生态、测试与 Web 开发」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《生态、测试与 Web 开发》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

这段 C# 代码是「生态、测试与 Web 开发」的示例片段，下面哪一项描述与它一致？

```csharp
// 使用 xUnit
public class CalculatorTests
{
    [Fact]
    public void Add_ReturnsSum()
    {
        Assert.Equal(5, Calculator.Add(2, 3));
    }

    [Theory]
    [InlineData(1, 2, 3)]
    [InlineData(-1, 1, 0)]
    public void Add_WorksForManyCases(int a, int b, int expected)
    {
        Assert.Equal(expected, Calculator.Add(a, b));
    }
}
```

A. 这段代码会读取外部输入，结果依赖传入的数据。
B. 这段代码会产生可观察的输出，运行后能看到结果。
C. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
D. 这段代码包含异常处理分支，失败时会走专门的补救路径。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「生态、测试与 Web 开发」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「生态、测试与 Web 开发」的正文示例，围绕NuGet、xUnit、ASP.NET Core展开；把输入或边界换成空值、极值或失败情况后，结论要以「生态、测试与 Web 开发」的实际运行结果为准。

### 自测 2

xUnit 中 [Theory] 配合 [InlineData] 用于？

A. 性能测试
B. 异步测试
C. 参数化测试
D. 跳过测试

**参考答案**：参数化测试

**解析**：Theory 表示数据驱动测试，InlineData 提供每组参数，减少重复代码。其他选项：[Theory] 与 [InlineData] 提供参数化测试。在「生态、测试与 Web 开发」里判断这道题，要把NuGet、xUnit、ASP.NET Core的条件、过程与失败路径逐项对齐，换成“xUnit 中 [Theory] 配”这个场景，只有满足前提的结论才成立。

### 自测 3

围绕“生态、测试与 Web 开发”中的 NuGet、xUnit、ASP.NET Core，下列哪两项是本课强调的实践判断？

A. 验证 xUnit 时要固定版本并覆盖边界输入，结论才可复现
B. 把 xUnit 的单次运行结果当成所有版本和规模都成立
C. 学习 NuGet 时要同时说明输入、输出和失败路径，不能只看正常流程
D. 只要 NuGet 的常规示例通过，就可以跳过边界与异常路径

**参考答案**：验证 xUnit 时要固定版本并覆盖边界输入，结论才可复现；学习 NuGet 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：本课把生态、测试与 Web 开发拆成概念、示例与故障现场三部分，因此判断 NuGet 时必须同时交代输入、输出和失败路径，这使“学习 NuGet 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在生态、测试与 Web 开发里，判断 xUnit 时要固定版本与边界输入，所以“验证 xUnit 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 能说清 Singleton / Scoped / Transient 的取舍。
- [ ] `DbContext` 使用 Scoped 生命周期。
- [ ] 会用 `AsNoTracking` 优化只读查询，并避免 N+1。
- [ ] 单元测试覆盖正常、边界与异常路径。
- [ ] 日志用 `ILogger<T>`，配置来自环境变量。

**教材衔接：动手练习**

> 本课练习重点：围绕「NuGet、xUnit、ASP.NET Core」完成复述、实验和交付，每个结果都要能被别人检查。

把 Add_WorksForManyCases 放进一个可运行的 .NET 控制台项目，补测试后再扩展。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 生态、测试与 Web 开发解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「xUnit」是什么关系？

验收标准：用自己的话解释 NuGet，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：把 Add_WorksForManyCases 当作原例，改动一次xUnit的取值，记录命令、输出与差异原因；五步里缺任意一步都算未完成。

### 练习 3：交付一个小结果（30 分钟）

写一个控制台小程序，补一个正例、一个边界值和一个异常路径。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「NuGet」和「xUnit」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```bash
dotnet add package Serilog              # 添加依赖
dotnet list package                    # 查看已安装包
dotnet remove package Serilog
```

### 任务 2：只改一个条件

把「生态、测试与 Web 开发」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 xUnit 换成边界值，其他输入保持原样。
- 预测：先写下「生态、测试与 Web 开发」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响NuGet。

### 任务 3：迁移到自己的数据

换一个 xUnit 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「.NET 的包管理器是？」的判断依据。
- [ ] 不看解析，能说出「xUnit 中 [Theory] 配合 [InlineData] 用于？」的判断依据。
- [ ] 不看解析，能说出「EF Core 的主要作用是？」的判断依据。
- [ ] 不看解析，能说出「ASP.NET Core 中间件的执行方式是？」的判断依据。
- [ ] 跑通「生态、测试与 Web 开发」的最小示例，并记录一次失败输入的处理方式。
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
| `dotnet restore` | 版本号尽量显式固定；`dotnet restore` 会按 lock 文件还原依赖，保证 CI 与本地一致。 |
| `Add-Migration` | EF Core 把 LINQ 翻译成 SQL，配合迁移（`Add-Migration` / `Database.Migrate()`）管理表结构。 |
| `EF Core` | EF Core 把 LINQ 翻译成 SQL，配合迁移（Add-Migration / Database.Migrate()）管理表结构。 |
| `NuGet` | .NET 的包管理器，restore 按项目文件解析并下载依赖，锁文件用于固定版本。 |

## 考点精讲

### 考点 1：代码补全·NuGet

- **题目**：这段 C# 代码是「生态、测试与 Web 开发」的示例片段，下面哪一项描述与它一致？
- **判断依据**：在「生态、测试与 Web 开发」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「生态、测试与 Web 开发」的正文示例，围绕NuGet、xUnit、ASP.NET Core展开；把输入或边界换成空值、极值或失败情况后，结论要以「生态、测试与 Web 开发」的实际运行结果为准。

### 考点 2：概念判断·NuGet

- **题目**：xUnit 中 [Theory] 配合 [InlineData] 用于？
- **判断依据**：Theory 表示数据驱动测试，InlineData 提供每组参数，减少重复代码。其他选项：[Theory] 与 [InlineData] 提供参数化测试。在「生态、测试与 Web 开发」里判断这道题，要把NuGet、xUnit、ASP.NET Core的条件、过程与失败路径逐项对齐，换成“xUnit 中 [Theory] 配”这个场景，只有满足前提的结论才成立。

### 考点 3：概念判断·NuGet

- **题目**：EF Core 的主要作用是？
- **判断依据**：在「生态、测试与 Web 开发」里，ORM：把对象与 LINQ 映射到数据库。EF Core 负责对象关系映射，把 LINQ 翻译成 SQL，并配合迁移管理表结构。回到「生态、测试与 Web 开发」的正文示例，用“EF Core 的主要作用是”走一遍NuGet、xUnit、ASP.NET Core的完整流程，能复现的结论才可以保留。

### 考点 4：概念判断·NuGet

- **题目**：ASP.NET Core 中间件的执行方式是？
- **判断依据**：在「生态、测试与 Web 开发」里，结论应落在「按注册顺序组成管道依次调用」。顺序很关键：异常处理、认证、授权、静态文件、路由都有惯用的注册次序。在「生态、测试与 Web 开发」里，这道题要求区分概念与边界，「按注册顺序组成管道依次调用」只有在题干给出的前提下才成立，而「随机顺序执行」、「只执行最后一个，但这会引入新的复杂度」缺少同一组条件。

### 考点 5：多选辨析·NuGet

- **题目**：围绕“生态、测试与 Web 开发”中的 NuGet、xUnit、ASP.NET Core，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把生态、测试与 Web 开发拆成概念、示例与故障现场三部分，因此判断 NuGet 时必须同时交代输入、输出和失败路径，这使“学习 NuGet 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在生态、测试与 Web 开发里，判断 xUnit 时要固定版本与边界输入，所以“验证 xUnit 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 6：填空·await db.____;

- **题目**：补全代码：「生态、测试与 Web 开发」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `await db.____;`
- **判断依据**：空格应填写「SaveChangesAsync」、「savechangesasync」。回到「生态、测试与 Web 开发」的正文示例，用“补全代码”走一遍NuGet、xUnit、ASP.NET Core的完整流程，能复现的结论才可以保留。回到NuGet、xUnit、ASP.NET Core本身再看一遍：只有“SaveChangesAsync”与题干“开发示例中”的前提一致，结论才成立。

## English Overview

**Title:** Ecosystem & Web

**Summary:** NuGet, xUnit, ASP.NET Core and EF Core.

**Category:** C#
**Level:** 进阶
**Key terms:** NuGet, xUnit, ASP.NET Core, EF Core, 依赖注入

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：.NET 9 / C# 13
；本课聚焦 NuGet。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：NuGet、xUnit、ASP.NET Core、EF Core、依赖注入
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [.NET 文档](https://learn.microsoft.com/dotnet/) | 运行时、库与工具链 |
| [ASP.NET Core 文档](https://learn.microsoft.com/aspnet/core/) | Web API 与中间件 |
| [EF Core 文档](https://learn.microsoft.com/ef/core/) | ORM、迁移与并发 |

> 「生态、测试与 Web 开发」的链接用于离线阅读后的延伸核对；App 不会自动联网。
