# C# 与 .NET 平台

![C# 从源码到 CLR 运行的分层](images/diagram_cs_platform.webp)

![C# 与 .NET 平台](images/remaining_csharp_basics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：40 分钟

## 学习目标

- 能用自己的话解释C# 与 .NET 平台解决了什么问题，而不是只背术语。
- 能说清 「C#」、「.NET」、「CLR」、「IL」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「C#」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：IL 与 CLR、dotnet CLI、项目文件与命名空间。

## 前置知识

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：C#、.NET、CLR。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## .NET 是什么

C# 运行在 .NET 平台之上：源码先编译成中间语言（IL），运行时由 CLR（公共语言运行时）通过 JIT 编译成本机代码，并负责垃圾回收与类型安全。

```text
源码 .cs -> Roslyn 编译 -> IL（dll / exe）-> CLR 加载 + JIT -> 本机代码执行
```

常见应用类型：控制台程序、ASP.NET Core Web API、桌面（WPF/WinUI）、游戏（Unity）、移动（MAUI）。

## 第一个程序

```csharp
// Program.cs
namespace Demo;

public class Program
{
    public static void Main(string[] args)
    {
        Console.WriteLine("Hello, C#!");
    }
}
```

也可以使用顶层语句，编译器会自动生成入口方法：

```csharp
Console.WriteLine("Hello, C#!");
```

## dotnet CLI

```bash
dotnet new console -o Hello          # 新建控制台项目
dotnet run                           # 编译并运行
dotnet build -c Release              # Release 配置构建
dotnet publish -c Release -o out     # 发布产物
dotnet add package Newtonsoft.Json   # 添加 NuGet 包
```

## 项目文件

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
</Project>
```

开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开。

## 命名空间

```csharp
using System.Text;

namespace Demo.Utils
{
    public static class TextHelper
    {
        public static string Repeat(string value, int times) => string.Concat(Enumerable.Repeat(value, times));
    }
}
```

命名空间用点号分层，通常与目录结构对应，用来避免类名冲突。

## 本课小结

C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。

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

## 常见错误与排查

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

## 复习与自测

- [ ] 能说清 CLR、IL、JIT 与程序集的关系。
- [ ] 会用 `dotnet new`、`build`、`run`、`test`、`publish`。
- [ ] 项目开启 `<Nullable>enable</Nullable>` 并处理告警。
- [ ] 依赖用 NuGet 管理，版本集中在 csproj。
- [ ] 部署使用 `dotnet publish` 的产物。

## 零基础详解：.NET、CLI 与第一个 C# 程序

### 一句话说清它是什么

C# 是运行在 **.NET** 平台上的编译型语言：源码编译成中间语言（IL），
再由运行时（CLR）在目标机器上即时编译并执行，兼顾性能与跨平台。

### 四个名词一次讲清

| 名词 | 全称 | 比喻 | 说明 |
| --- | --- | --- | --- |
| .NET | 平台 | 一整套工具箱 + 工厂 | 含运行时、类库与工具 |
| CLR | 公共语言运行时 | 工厂里的发动机 | 负责加载、JIT、垃圾回收 |
| IL | 中间语言 | 通用图纸 | 所有 .NET 语言都编译成它 |
| NuGet | 包管理器 | 零件商店 | 装第三方库的地方 |

### 两个文件撑起一个项目

```csharp
// Program.cs
Console.WriteLine("Hello, World!");
```

```xml
<!-- Demo.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
</Project>
```

| 配置 | 作用 | 建议 |
| --- | --- | --- |
| `OutputType` | 生成可执行程序还是库 | 控制台程序用 `Exe` |
| `TargetFramework` | 目标框架版本 | 按团队统一，别随意跳 |
| `Nullable` | 开启可空引用类型检查 | **一定开启** |
| `ImplicitUsings` | 自动引入常用命名空间 | 开启后代码更短 |

### 常用命令

```bash
dotnet new console -o Demo     # 新建控制台项目
cd Demo
dotnet run                     # 编译并运行
dotnet build -c Release        # 发布配置构建
dotnet publish -c Release -r linux-x64 --self-contained false
```

### 类、命名空间与入口

```csharp
namespace Demo;                 // 文件作用域命名空间，省一层缩进

public class Greeter
{
    public string Build(string name) => $"你好，{name}！";
}

public static class Program
{
    public static void Main()
    {
        var greeter = new Greeter();
        Console.WriteLine(greeter.Build("小明"));
    }
}
```

顶层语句（直接写 `Console.WriteLine`）适合小脚本；
项目变大后，显式写 `Main` 更清楚。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 顶层语句与 `Main` 混用 | 报「已定义多个入口点」 | 二选一 |
| 忘写 `using` | 找不到类型 | 补命名空间或开启隐式 using |
| 可空警告被忽略 | 运行时空引用崩溃 | 认真处理 `?` 与 `!` |
| 值类型与引用类型混淆 | 改了副本没生效 | 明确 struct / class 语义 |
| 中文标点 | 编译错误 | 全用英文半角 |
| 命名空间与文件夹不一致 | 类型找不到 | 目录结构跟命名空间对齐 |
| 忘记 `Nullable enable` | 空引用问题逃过检查 | 在 csproj 中开启 |
| 用 `==` 比较字符串 | 结果不确定 | C# 中 `==` 对 string 已重载为比值，但仍要注意 null |

### 手把手练习：命令行小工具

```csharp
using System.Globalization;

Console.Write("请输入摄氏温度：");
var raw = Console.ReadLine();

if (!double.TryParse(raw, CultureInfo.InvariantCulture, out var celsius))
{
    Console.WriteLine("请输入数字，例如 25.5");
    return;
}

var fahrenheit = celsius * 9 / 5 + 32;
Console.WriteLine($"{celsius:F1}℃ = {fahrenheit:F1}℉");
```

`TryParse` 模式是 C# 处理用户输入的规范写法：不抛异常、直接得到布尔结果。

### 学完自测

- [ ] 能说出 .NET、CLR、IL、NuGet 各自是什么。
- [ ] 知道 `dotnet run`、`dotnet build`、`dotnet publish` 的区别。
- [ ] 能解释为什么要开启 `Nullable`。
- [ ] 能说出顶层语句和显式 `Main` 的取舍。
- [ ] 会用 `TryParse` 安全地解析用户输入。

## 动手练习

> 本课练习重点：围绕「C#、.NET、CLR」完成复述、实验和交付，每个结果都要能被别人检查。

先建最小控制台程序，再补类型、异步和异常路径，最后用 dotnet test 验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. C# 与 .NET 平台解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「.NET」是什么关系？

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
- 至少覆盖「C#」和「.NET」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

```bash
dotnet new console -o Hello          # 新建控制台项目
dotnet run                           # 编译并运行
dotnet build -c Release              # Release 配置构建
dotnet publish -c Release -o out     # 发布产物
dotnet add package Newtonsoft.Json   # 添加 NuGet 包
```

### 任务 2：只改一个条件

把「C# 与 .NET 平台」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把C#的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「C# 与 .NET 平台」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响C#。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 C# 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 C# 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 C# 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“C# 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 C# 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 .NET 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 .NET 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 .NET 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“.NET 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 .NET 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，C# 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

- .NET 10 是当前 LTS 主线，C# 版本随 SDK 一起演进
- 主构造函数、集合表达式、模式匹配与 AOT/裁剪是升级重点
- 升级前检查 NuGet 依赖、序列化行为与运行时标识
- 官方说明：https://learn.microsoft.com/dotnet/core/whats-new/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「C# 源码编译后生成什么？」的判断依据。
- [ ] 不看解析，能说出「dotnet run 的作用是？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 不看解析，能说出「C# 中 using 指令与 using 语句的区别是？」的判断依据。
- [ ] 不看解析，能说出「.NET SDK 与运行时的区别是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Nullable` | 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开。 |
| `dotnet` | C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。 |
| `.dll` | \| 程序集（Assembly） \| `.dll` / `.exe`，部署与版本单位 \| |
| `.exe` | \| 程序集（Assembly） \| `.dll` / `.exe`，部署与版本单位 \| |
| `.csproj` | \| NuGet \| 包管理器，依赖写在 `.csproj` \| |
| `net8.0` | \| 目标框架（TFM） \| 如 `net8.0`、`net8.0-windows` \| |

## 考点精讲

### 考点 1：代码补全·C#

- **题目**：阅读「C# 与 .NET 平台」正文里的这段 C# 代码，下面哪一项判断是正确的？
- **判断依据**：题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「C# 与 .NET 平台」里封装边界决定C#从哪一步开始生效。这段代码出自「C# 与 .NET 平台」的正文示例，围绕C#、.NET、CLR展开；把输入或边界换成空值、极值或失败情况后，结论要以「C# 与 .NET 平台」的实际运行结果为准。“.NET”与「C# 与 .NET 平台」的术语表相呼应，只有符合C#、.NET、CLR约束的“这段代码把主要逻辑封装在函数或方法里”才是正文支持的结论。

### 考点 2：概念判断·C#

- **题目**：dotnet run 的作用是？
- **判断依据**：dotnet run 会先构建再运行。在「C# 与 .NET 平台」里，作答时，先用C#建立输入与输出的基线，再把编译并运行当前项目代入边界条件核对，结论才能复现。回到「C# 与 .NET 平台」的正文示例，用“dotnet run 的作用是”走一遍C#、.NET、CLR的完整流程，能复现的结论才可以保留。

### 考点 3：多选辨析·C#

- **题目**：围绕“C# 与 .NET 平台”中的 C#、.NET、CLR，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把C# 与 .NET 平台拆成概念、示例与故障现场三部分，因此判断 C# 时必须同时交代输入、输出和失败路径，这使“学习 C# 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在C# 与 .NET 平台里，判断 .NET 时要固定版本与边界输入，所以“验证 .NET 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 4：概念判断·C#

- **题目**：C# 中 using 指令与 using 语句的区别是？
- **判断依据**：在「C# 与 .NET 平台」里，结论应落在「using 指令引入命名空间」。using 语句会编译成 try/finally 调用 Dispose，是 C# 资源管理的标准写法。在「C# 与 .NET 平台」里，这道题要求区分概念与边界，「using 指令引入命名空间」只有在题干给出的前提下才成立，而「using 语句只能用于文件 IO」、「两者完全一样」缺少同一组条件。

### 考点 5：概念判断·C#

- **题目**：.NET SDK 与运行时的区别是？
- **判断依据**：在「C# 与 .NET 平台」里，SDK 包含编译器与 CLI 工具可以开发，运行时只能执行已编译程序。服务器部署可以只装 ASP.NET Core 运行时，开发机则装 SDK。这道题的关键在「C# 与 .NET 平台」的C#、.NET、CLR：先确认题干“.NET SDK 与运行时的区别是”问的是哪一步，再排除偷换前提的选项。

### 考点 6：填空·C#

- **题目**：补全代码：「C# 与 .NET 平台」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `Console.____($"{celsius:F1}℃ = {fahrenheit:F1}℉");`
- **判断依据**：在「C# 与 .NET 平台」里，WriteLine。在「C# 与 .NET 平台」里判断这道题，要把C#、.NET、CLR的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“.NET”与「C# 与 .NET 平台」的术语表相呼应，只有符合C#、.NET、CLR约束的“WriteLine”才是正文支持的结论。

## English Overview

**Title:** C# & .NET

**Summary:** IL/CLR, dotnet CLI, project files and namespaces.

**Category:** C#
**Level:** 基础
**Key terms:** C#, .NET, CLR, IL, dotnet, csproj

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：.NET 9 / C# 13
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：C#、.NET、CLR、IL、dotnet、csproj
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**C# & .NET** focuses on IL/CLR, dotnet CLI, project files and namespaces.

### Learning Outcomes

- Explain what **C# & .NET** solves and when it should be used.

### Glossary

- Topic: **C# & .NET**
- Related terms: C#, .NET, CLR, IL

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| .NET 是什么 | .NET 是什么 |
| 第一个程序 | 第一个程序 |
| dotnet CLI | dotnet CLI |
| 项目文件 | 项目文件 |
| 命名空间 | 命名空间 |
| 本课小结 | Summary |
| .NET 平台速查 | .NET 平台速查 |
| dotnet CLI 速查 | dotnet CLI 速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [dotnet CLI](https://learn.microsoft.com/dotnet/core/tools/) | 构建、运行与发布命令 |
| [.NET 文档](https://learn.microsoft.com/dotnet/) | 运行时、库与工具链 |
| [C# 指南](https://learn.microsoft.com/dotnet/csharp/) | 语言语法与类型系统 |

> 「C# 与 .NET 平台」的链接用于离线阅读后的延伸核对；App 不会自动联网。
