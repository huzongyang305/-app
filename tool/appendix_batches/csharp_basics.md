## .NET 平台速查

| 概念 | 说明 |
| --- | --- |
| CLR | 公共语言运行时，负责执行 IL 与内存管理 |
| IL / MSIL | 编译后的中间语言，存放在程序集里 |
| JIT | 运行时把 IL 编译成机器码 |
| AOT | 提前编译成原生代码，启动快、体积大 |
| 程序集（Assembly） | `.dll` / `.exe`，部署与版本单位 |
| NuGet | 包管理器，依赖写在 `.csproj` |
| 目标框架（TFM） | 如 `net8.0`、`net8.0-windows` |
| SDK 样式项目 | 现代 `.csproj`，默认包含源码与隐式 using |

## dotnet CLI 速查

| 目的 | 命令 |
| --- | --- |
| 查看版本与 SDK | `dotnet --info` |
| 新建项目 | `dotnet new console -o Hello` |
| 新建 Web API | `dotnet new webapi -o Api` |
| 新建解决方案 | `dotnet new sln -n App` |
| 添加项目到解决方案 | `dotnet sln add Api/Api.csproj` |
| 还原依赖 | `dotnet restore` |
| 编译 | `dotnet build -c Release` |
| 运行 | `dotnet run --project Api` |
| 测试 | `dotnet test` |
| 发布 | `dotnet publish -c Release -o out` |
| 添加包 | `dotnet add package Serilog` |
| 查看过期包 | `dotnet list package --outdated` |
| 全局工具 | `dotnet tool install -g dotnet-ef` |

常用 csproj 配置：

```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>              <!-- 开启可空引用类型分析 -->
    <ImplicitUsings>enable</ImplicitUsings>  <!-- 隐式 using -->
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <InvariantGlobalization>false</InvariantGlobalization>
  </PropertyGroup>
</Project>
```

## 常见错误对照表

| 报错或现象 | 原因 | 处理方式 |
| --- | --- | --- |
| `The type or namespace name could not be found` | 缺 using 或没装包 | 补 `using` 或 `dotnet add package` |
| `Nullable` 警告大量出现 | 开启可空分析后暴露空值风险 | 逐个处理，不要用 `!` 掩盖 |
| `Program does not contain a static 'Main'` | 入口点缺失 | 补 `Main`，或用顶级语句 |
| 修改代码后运行结果没变 | 运行了旧构建 | `dotnet build` 后确认目标框架与配置 |
| `error NETSDK1045` | SDK 版本低于目标框架 | 安装对应 SDK 或降低 TargetFramework |
| 发布后缺少配置文件 | 未复制到输出目录 | 在 csproj 中设置 `CopyToOutputDirectory` |
| 依赖版本冲突 | 传递依赖不一致 | `dotnet list package --include-transitive` 定位并统一 |
| 本地能跑、服务器报缺运行时 | 服务器只装运行时 | 安装 ASP.NET Core Runtime 或改为自包含发布 |
| `TreatWarningsAsErrors` 打开后构建失败 | 已有告警 | 先清零告警再开启门禁 |
| 用 `dotnet run` 做生产部署 | 环境不一致 | 用 `dotnet publish` 产物部署 |

## 自测清单

- [ ] 能说清 CLR、IL、JIT 与程序集的关系。
- [ ] 会用 `dotnet new`、`build`、`run`、`test`、`publish`。
- [ ] 项目开启 `<Nullable>enable</Nullable>` 并处理告警。
- [ ] 依赖用 NuGet 管理，版本集中在 csproj。
- [ ] 部署使用 `dotnet publish` 的产物。
