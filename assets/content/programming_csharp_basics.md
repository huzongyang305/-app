# C# 与 .NET 平台

![C# 与 .NET 平台](images/remaining_csharp_basics.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：14 分钟

## 学习目标

- 能用自己的话解释「C# 与 .NET 平台」解决了什么问题，而不是只背术语。
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

1. 「C# 与 .NET 平台」解决了什么问题？
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



## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：C# 源码编译后生成什么？

- **正确判断**：中间语言 IL
- **判断依据**：C# 编译成 IL，运行时由 CLR 通过 JIT 转成本机代码执行。其他选项：C# 编译成 IL 中间语言，再由 CLR 在运行时 JIT 为机器码。它不直接产出机器码，也不是 Python 字节码或汇编源码。正确项「中间语言 IL」正面回答了题目所问，符合课程给出的定义与适用范围。错误项「直接是机器码」只看到了表面现象，没有解释题干真正考查的机制。把题干「C# 源码编译后生成什么？」放回《C# 与 .NET 平台》的「IL 与 CLR、dotnet CLI、项目文件与命名空间」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：dotnet run 的作用是？

- **正确判断**：编译并运行当前项目
- **判断依据**：dotnet run 会先构建再运行；dotnet build 只构建，dotnet publish 生成发布产物。 其他选项：dotnet run 会先构建再运行；还原依赖、发布包、启动数据库分别是 restore、publish 与其他工具的职责。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：在 csproj 中开启 <Nullable>enable</Nullable> 的好处是？

- **正确判断**：编译期提示可能的空引用
- **判断依据**：可空引用类型让编译器对可能为 null 的解引用给出警告，显著减少空指针异常。其他选项：开启可空分析能在编译期提示潜在空引用，与运行速度、GC、测试生成无关。正确项「编译期提示可能的空引用」正面回答了题目所问，符合课程给出的定义与适用范围。错误项「提高运行速度」属于相邻主题的说法，范围与本题要求不一致。错误项「启用垃圾回收」把不同概念混在一起，缺少题干限定的前提。错误项「自动生成单元测试」与课程给出的定义相冲突，不能回答题目所问。把题干「在 csproj 中开启 <Nullable>enable</Nullable> 的好处是？」放回《C# 与 .NET 平台》的「IL 与 CLR、dotnet CLI、项目文件与命名空间」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：C# 中 using 指令与 using 语句的区别是？

- **正确判断**：using 指令引入命名空间
- **判断依据**：using 语句会编译成 try/finally 调用 Dispose，是 C# 资源管理的标准写法。其他选项：using 指令只引入命名空间。using 语句才负责在作用域结束时释放 IDisposable 资源，且不限于文件 IO。正确项「using 指令引入命名空间」抓住了题干的核心条件，是经得起边界检验的表述。错误项「using 语句只能用于文件 IO」把不同概念混在一起，缺少题干限定的前提。错误项「两者完全一样」与课程给出的定义相冲突，不能回答题目所问。错误项「using 指令会自动释放资源」在边界或失败路径上会得出错误结果。把题干「C# 中 using 指令与 using 语句的区别是？」放回《C# 与 .NET 平台》的「IL 与 CLR、dotnet CLI、项目文件与命名空间」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：.NET SDK 与运行时的区别是？

- **正确判断**：SDK 包含编译器与 CLI 工具可以开发，运行时只能执行已编译程序
- **判断依据**：服务器部署可以只装 ASP.NET Core 运行时，开发机则装 SDK。其他选项：运行时包含执行程序所需组件，SDK 额外包含编译器与 CLI。只部署运行时就能跑已编译程序。正确项「SDK 包含编译器与 CLI 工具可以开发，运行时只能执行已编译程序」正面回答了题目所问，符合课程给出的定义与适用范围。错误项「运行时包含编译器」把不同概念混在一起，缺少题干限定的前提。错误项「两者都必须安装才能运行程序（混淆了相邻概念，不能回答本题）」与课程给出的定义相冲突，不能回答题目所问。错误项「SDK 不能运行程序」只看到了表面现象，没有解释题干真正考查的机制。把题干「.NET SDK 与运行时的区别是？」放回《C# 与 .NET 平台》的「IL 与 CLR、dotnet CLI、项目文件与命名空间」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「C# 源码编译后生成什么？」的判断依据。
- [ ] 不看解析，能说出「dotnet run 的作用是？」的判断依据。
- [ ] 不看解析，能说出「在 csproj 中开启 <Nullable>enable</Nullable>…」的判断依据。
- [ ] 不看解析，能说出「C# 中 using 指令与 using 语句的区别是？」的判断依据。
- [ ] 不看解析，能说出「.NET SDK 与运行时的区别是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** C# & .NET

**Summary:** IL/CLR, dotnet CLI, project files and namespaces.

**Category:** C#  
**Level:** 基础  
**Key terms:** C#, .NET, CLR, IL, dotnet, csproj

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
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

- Topic: **C# & .NET**
- Related terms: C#, .NET, CLR, IL
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


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

> 本课主题：IL 与 CLR、dotnet CLI、项目文件与命名空间。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

