# C# 与 .NET 平台

![C# 从源码到 CLR 运行的分层](images/diagram_cs_platform.webp)

![C# 与 .NET 平台](images/remaining_csharp_basics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：55 分钟

## 本节知识框架

**课程定位**：所属分类 `csharp`（C#），课程主题 `C# 与 .NET 平台`，学习阶段 基础，建议用时 50 分钟。

本课主线：IL 与 CLR、dotnet CLI、项目文件与命名空间。

**学完本课应当能够**
- 说清 `Nullable` 与 `dotnet` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `C#` 的行为，记录输入、输出与失败条件。
- 遇到「顶层语句与 `Main` 混用」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `Nullable`：先掌握 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开，再用它解释 `dotnet` 为什么会出现。
2. `dotnet`：先掌握 C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目，再用它解释 `C#` 为什么会出现。
3. `C#`：先掌握 C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL），再用它解释 `.csproj` 为什么会出现。
4. `.csproj`：先掌握 C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「C#」分类的第 6 课。相关或后续课程：《变量、类型与字符串》。

### 完成判据

- **定义关**：不看正文也能说明 `Nullable` 是 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `C# 与 .NET 平台`，而不是只背结论。
- **示例关**：能运行或推演 `C# 与 .NET 平台` 的 `xml` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `C# 与 .NET 平台` 示例里的 出现字面量 `Microsoft.NET.Sdk`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 顶层语句与 `Main` 混用，记录现象并按 二选一 修复。
- **迁移关**：能把 `C#`、`.NET`、`CLR`、`IL` 放进一个与 `C# 与 .NET 平台` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `C# 与 .NET 平台` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| Nullable | 开启 Nullable 后编译器会检查可能的空引用，新项目建议默认打开。 | 易错：空引用问题逃过检查；正确做法是在 csproj 中开启。 |
| dotnet | C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 dotnet CLI 与 csproj 配置即可开始任何类型的项目。 | 易错：缺 using 或没装包；正确做法是补 `using` 或 `dotnet add package`。 |
| C# | C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）。 | 易错：结果不确定；正确做法是C# 中 `==` 对 string 已重载为比值，但仍要注意 null。 |
| .csproj | C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集。 | 不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 |

## 原理与运行机制

### 机制总览

**教材衔接：.NET 平台速查**

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

**教材衔接：版本与时效**

- 先确认 SDK 版本，再决定 TargetFramework 是否可以使用新语法或新 API。
- 若使用 AOT 或裁剪，TargetFramework 的反射与动态加载路径需要重点验证。
- 升级前先用 TargetFramework 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。
- 官方说明：https://learn.microsoft.com/dotnet/core/whats-new/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 C# 的版本变量，记录编译、测试与产物体积的变化。
- 升级后重点回归 C# 的默认值、警告信息与错误格式。
- 升级后把 TargetFramework 的实测版本写进「内容元数据」，再更新复核日期。

### 机制拆解：每一步的输入、动作与输出

#### 1. `Nullable`
- 输入：`C#`；本步把 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开 当作判断规则。
- 动作：围绕 `Nullable` 保留中间状态，并记录它与 `dotnet` 的对应关系。
- 输出：`dotnet`，它可以被下一段代码、测试或记录继续使用。
- `Nullable` 的失败条件：当忘记 `Nullable enable`时，会出现空引用问题逃过检查。

#### 2. `dotnet`
- 输入：`Nullable`；本步把 C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目 当作判断规则。
- 动作：围绕 `dotnet` 保留中间状态，并记录它与 `C#` 的对应关系。
- 输出：`C#`，它可以被下一段代码、测试或记录继续使用。
- `dotnet` 的失败条件：当`The type or namespace name could not be found`时，会出现缺 using 或没装包。

#### 3. `C#`
- 输入：`dotnet`；本步把 C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL） 当作判断规则。
- 动作：围绕 `C#` 保留中间状态，并记录它与 `.csproj` 的对应关系。
- 输出：`.csproj`，它可以被下一段代码、测试或记录继续使用。
- `C#` 的失败条件：当用 `==` 比较字符串时，会出现结果不确定。

#### 4. `.csproj`
- 输入：`C#`；本步把 C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集 当作判断规则。
- 动作：围绕 `.csproj` 保留中间状态，并记录它与 `Microsoft.NET.Sdk` 的对应关系。
- 输出：`Microsoft.NET.Sdk`，它可以被下一段代码、测试或记录继续使用。
- `.csproj` 的失败条件：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 示例中的可观察事实

1. 出现字面量 `Microsoft.NET.Sdk`；它对应的课程主题是 `C# 与 .NET 平台`。

### 复现实验记录

- 环境：`C# 与 .NET 平台` 使用 `xml` 示例，固定 `C#`、`.NET`、`CLR`、`IL` 作为第一组条件。
- 首轮输入：先确认 出现字面量 `Microsoft.NET.Sdk`，预测 `Nullable` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `C#`，观察 `.csproj` 是否仍满足定义。
- 失败注入：复现 顶层语句与 `Main` 混用，确认现象是 报「已定义多个入口点」。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `C# 与 .NET 平台` 时才能区分概念错误与实现错误。

## 典型应用场景

**课程内置实验入口**：`sandbox:csharp`，用于动手验证《C# 与 .NET 平台》的机制；实验结论不替代概念定义与复杂度分析。

**教材衔接：项目文件**

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

- **顶层语句与 `Main` 混用**：典型现象是报「已定义多个入口点」；正确做法是二选一。
- **忘写 `using`**：典型现象是找不到类型；正确做法是补命名空间或开启隐式 using。
- **可空警告被忽略**：典型现象是运行时空引用崩溃；正确做法是认真处理 `?` 与 `!`。
- **值类型与引用类型混淆**：典型现象是改了副本没生效；正确做法是明确 struct / class 语义。

### 最小验证场景

- 准备：保留 `xml` 示例的原始输入，先记录 `C# 与 .NET 平台` 的基线输出和完整运行命令。
- 观察：先核对 出现字面量 `Microsoft.NET.Sdk`，再改变一个与 `Nullable` 相关的条件。
- 判定：新结果与 `C# 与 .NET 平台` 的基线不同不等于错误；只有当差异破坏了 `Nullable` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `Nullable` 时，先满足它的定义：开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开；易错：空引用问题逃过检查；正确做法是在 csproj 中开启。
- 使用 `dotnet` 时，先满足它的定义：C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目；易错：缺 using 或没装包；正确做法是补 `using` 或 `dotnet add package`。
- 使用 `C#` 时，先满足它的定义：C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）；易错：结果不确定；正确做法是C# 中 `==` 对 string 已重载为比值，但仍要注意 null。
- 使用 `.csproj` 时，先满足它的定义：C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集；不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

## 代码/协议/SQL 示例

### 最小可验证示例

```text
源码 .cs -> Roslyn 编译 -> IL（dll / exe）-> CLR 加载 + JIT -> 本机代码执行
```

**教材衔接：.NET 是什么**

C# 运行在 .NET 平台之上：源码先编译成中间语言（IL），运行时由 CLR（公共语言运行时）通过 JIT 编译成本机代码，并负责垃圾回收与类型安全。

```text
源码 .cs -> Roslyn 编译 -> IL（dll / exe）-> CLR 加载 + JIT -> 本机代码执行
```

常见应用类型：控制台程序、ASP.NET Core Web API、桌面（WPF/WinUI）、游戏（Unity）、移动（MAUI）。

**教材衔接：第一个程序**

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

**教材衔接：dotnet CLI**

```bash
dotnet new console -o Hello          # 新建控制台项目
dotnet run                           # 编译并运行
dotnet build -c Release              # Release 配置构建
dotnet publish -c Release -o out     # 发布产物
dotnet add package Newtonsoft.Json   # 添加 NuGet 包
```

**教材衔接：命名空间**

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

**教材衔接：dotnet CLI 速查**

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

**教材衔接：零基础详解：.NET、CLI 与第一个 C# 程序**

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

### 示例精读：先找证据，再改一个条件

1. 出现字面量 `Microsoft.NET.Sdk`；它出现在 `C# 与 .NET 平台` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `C# 与 .NET 平台` 中与 `Nullable` 对照：示例必须能支持 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开，否则说明这一段还缺少实现或验证步骤。
- 在 `C# 与 .NET 平台` 中与 `dotnet` 对照：示例必须能支持 C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目，否则说明这一段还缺少实现或验证步骤。
- 在 `C# 与 .NET 平台` 中与 `C#` 对照：示例必须能支持 C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL），否则说明这一段还缺少实现或验证步骤。
- 在 `C# 与 .NET 平台` 中与 `.csproj` 对照：示例必须能支持 C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（C# 与 .NET 平台）**：GC 与异步调度影响开销：记录吞吐、延迟与分配速率。

**本课特有开销（C# 与 .NET 平台 · C#）**：小文件看元数据开销，大文件看吞吐，两者要分别测量。

**测量方法**：以 `C# 与 .NET 平台` 的 `C#` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `C# 与 .NET 平台` 的 `C#`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `C# 与 .NET 平台` 的 `.NET`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `C# 与 .NET 平台` 的 `CLR`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `C# 与 .NET 平台` 的 `IL`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `C# 与 .NET 平台` 的 `dotnet`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `C# 与 .NET 平台` 中 `Nullable` 的边界：易错：空引用问题逃过检查；正确做法是在 csproj 中开启。达到边界时不要外推，必须重新测量。
- `C# 与 .NET 平台` 中 `dotnet` 的边界：易错：缺 using 或没装包；正确做法是补 `using` 或 `dotnet add package`。达到边界时不要外推，必须重新测量。
- `C# 与 .NET 平台` 中 `C#` 的边界：易错：结果不确定；正确做法是C# 中 `==` 对 string 已重载为比值，但仍要注意 null。达到边界时不要外推，必须重新测量。
- `C# 与 .NET 平台` 中 `.csproj` 的边界：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。达到边界时不要外推，必须重新测量。
- `C# 与 .NET 平台` 的代码证据：先验证 出现字面量 `Microsoft.NET.Sdk`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 顶层语句与 `Main` 混用 | 报「已定义多个入口点」 | 二选一 |
| 忘写 `using` | 找不到类型 | 补命名空间或开启隐式 using |
| 可空警告被忽略 | 运行时空引用崩溃 | 认真处理 `?` 与 `!` |
| 值类型与引用类型混淆 | 改了副本没生效 | 明确 struct / class 语义 |
| 中文标点 | 编译错误 | 全用英文半角 |
| 命名空间与文件夹不一致 | 类型找不到 | 目录结构跟命名空间对齐 |
| 忘记 `Nullable enable` | 空引用问题逃过检查 | 在 csproj 中开启 |
| 用 `==` 比较字符串 | 结果不确定 | C# 中 `==` 对 string 已重载为比值，但仍要注意 null |
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
| The type or namespace name could not be found | 缺 using 或没装包。 | 补 using 或 dotnet add package。 |
| Nullable 警告大量出现 | 开启可空分析后暴露空值风险。 | 逐个处理，不要用 ! 掩盖。 |

### 现场 1：顶层语句与 `Main` 混用

**症状**：报「已定义多个入口点」。

**根因与修复**：二选一。

**自检**：在本课示例里复现「顶层语句与 `Main` 混用」，改成二选一后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：忘写 `using`

**症状**：找不到类型。

**根因与修复**：补命名空间或开启隐式 using。

**自检**：在本课示例里复现「忘写 `using`」，改成补命名空间或开启隐式 using后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：可空警告被忽略

**症状**：运行时空引用崩溃。

**根因与修复**：认真处理 `?` 与 `!`。

**自检**：在本课示例里复现「可空警告被忽略」，改成认真处理 `?` 与 `!`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：值类型与引用类型混淆

**症状**：改了副本没生效。

**根因与修复**：明确 struct / class 语义。

**自检**：在本课示例里复现「值类型与引用类型混淆」，改成明确 struct / class 语义后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：中文标点

**症状**：编译错误。

**根因与修复**：全用英文半角。

**自检**：在本课示例里复现「中文标点」，改成全用英文半角后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：命名空间与文件夹不一致

**症状**：类型找不到。

**根因与修复**：目录结构跟命名空间对齐。

**自检**：在本课示例里复现「命名空间与文件夹不一致」，改成目录结构跟命名空间对齐后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：忘记 `Nullable enable`

**症状**：空引用问题逃过检查。

**根因与修复**：在 csproj 中开启。

**自检**：在本课示例里复现「忘记 `Nullable enable`」，改成在 csproj 中开启后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：用 `==` 比较字符串

**症状**：结果不确定。

**根因与修复**：C# 中 `==` 对 string 已重载为比值，但仍要注意 null。

**自检**：在本课示例里复现「用 `==` 比较字符串」，改成C# 中 `==` 对 string 已重载为比值，但仍要注意 null后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`The type or namespace name could not be found`

**症状**：缺 using 或没装包。

**根因与修复**：补 `using` 或 `dotnet add package`。

**自检**：在本课示例里复现「`The type or namespace name could not be found`」，改成补 `using` 或 `dotnet add package`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **相关或后续**：`变量、类型与字符串`。本课术语会在这些课程里继续使用。
- **术语归属**：`Nullable`、`dotnet`、`C#` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《C# 与 .NET 第一个程序》也涉及 `C#`；两课衔接时先确认这个术语的定义是否一致。
- 同一分类的《C# 变量与输入》也涉及 `C#`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `变量、类型与字符串`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `Nullable` 与 `dotnet`：前者强调 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开；后者强调 C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `dotnet` 与 `C#`：前者强调 C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目；后者强调 C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `C#` 与 `.csproj`：前者强调 C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）；后者强调 C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `Nullable` 的操作性定义，并说明它与 `dotnet` 的区别。

**参考答案**：开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开。

`dotnet` 的定位是：C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「顶层语句与 `Main` 混用」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是报「已定义多个入口点」；正确做法是二选一。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `xml` 示例，把其中的 `"Microsoft.NET.Sdk"` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `xml` 示例应当复现正文给出的结果；把 `"Microsoft.NET.Sdk"` 换成边界值后，如果结果改变或报错，先核对它是否满足 `C# 与 .NET 平台` 中`Nullable` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `xml` 示例，说明它体现了`Nullable` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`Nullable` 的定义是 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开，示例正是在实现这条定义。改动与 `Nullable` 有关的一个输入后，如果结果不再符合 `C# 与 .NET 平台` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `C# 与 .NET 平台` 的方法迁移到自己的项目：围绕 `Nullable` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「Nullable 警告大量出现」，它会导致开启可空分析后暴露空值风险；检验方式是按逐个处理，不要用 ! 掩盖改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `Nullable` 与 `dotnet`：各写一行适用场景、一行失败表现。

**参考答案**：`Nullable` 的定义是开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开；`dotnet` 的定义是C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「顶层语句与 `Main` 混用」引发的问题，请把“复现 报「已定义多个入口点」 → 保留证据 → 二选一 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按报「已定义多个入口点」复现；第二步记录输入、版本与完整报错；第三步按二选一只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `.csproj`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 同时要把 `.csproj` 的定义 C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `Nullable` → `dotnet` → `C#` → `.csproj` 的作用链。

**参考答案**：起点是 `Nullable` 的定义 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开；中间每一步都保留可观察状态；终点由 `.csproj` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `C# 与 .NET 平台` 中，现象是 开启可空分析后暴露空值风险。请围绕 Nullable 警告大量出现 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 Nullable 警告大量出现，记录输入与完整错误；再按 逐个处理，不要用 ! 掩盖 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `C# 与 .NET 平台`：先给主问题，再按顺序说出 `Nullable`、`dotnet`、`C#`、`.csproj`，最后给一个失败案例。

**自评标准**：主问题必须对应 IL 与 CLR、dotnet CLI、项目文件与命名空间；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Nullable` | 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开。 |
| `dotnet` | C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。 |
| `C#` | C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）。 |
| `.csproj` | C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集。 |

**术语关系**：`Nullable`（开启 `Nullable` 后编译器会检查可能的空引用） → `dotnet`（C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**） → `C#`（C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）） → `.csproj`（C# 项目文件：声明目标框架、依赖与编译项）。

## 考点精讲

`C# 与 .NET 平台` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：这段 `csharp` 代码对应 `C# 与 .NET 平台` 的 `Nullable`。课程要解决的是IL 与 CLR、dotnet CLI、项目文件与命名空间。关于代码内容，哪一项说法准确？
- **正确项**：出现字面量 `Microsoft.NET.Sdk`
- **判断依据**：这道题落在术语 `Nullable` 上：开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开。复习时把 `Nullable` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：dotnet run 的作用是？
- **正确项**：编译并运行当前项目
- **判断依据**：这道题落在术语 `dotnet` 上：C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**，掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。复习时把 `dotnet` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：围绕“C# 与 .NET 平台”中的 C#、.NET、CLR，下列哪两项是本课强调的实践判断？
- **正确项**：学习 C# 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 .NET 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `C#` 上：C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）。复习时把 `C#` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：C# 中 using 指令与 using 语句的区别是？
- **正确项**：using 指令引入命名空间
- **判断依据**：这道题落在术语 `C#` 上：C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）。复习时把 `C#` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：.NET SDK 与运行时的区别是？
- **正确项**：SDK 包含编译器与 CLI 工具可以开发，运行时只能执行已编译程序
- **判断依据**：这道题检验本课主问题：IL 与 CLR、dotnet CLI、项目文件与命名空间。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `IL 与 CLR、dotnet CLI、项目文件与命名空间。`，这段说明是：C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 ``____`` CLI 与 csproj 配置即可开始任何类型的项目。空缺处应填哪个术语？
- **正确项**：dotnet
- **判断依据**：这道题落在术语 `dotnet` 上：C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**，掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。复习时把 `dotnet` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`Nullable`

- **要点**：开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开。
- **Nullable 的边界**：易错：空引用问题逃过检查；正确做法是在 csproj 中开启。

### 考点 8：`dotnet`

- **要点**：C# 代码跑在 .NET 上：**编译成 IL、由 CLR 托管执行**。掌握 `dotnet` CLI 与 csproj 配置即可开始任何类型的项目。
- **dotnet 的边界**：易错：缺 using 或没装包；正确做法是补 `using` 或 `dotnet add package`。

### 考点 9：`C#`

- **要点**：C# 是运行在 .NET 平台上的编译型语言：源码编译成中间语言（IL）。
- **C# 的边界**：易错：结果不确定；正确做法是C# 中 `==` 对 string 已重载为比值，但仍要注意 null。

### 考点 10：`.csproj`

- **要点**：C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集。
- **.csproj 的边界**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 考点 11：排错——顶层语句与 `Main` 混用

- **现象**：报「已定义多个入口点」。
- **处理**：二选一。

### 考点 12：排错——忘写 `using`

- **现象**：找不到类型。
- **处理**：补命名空间或开启隐式 using。

### 考点 13：综合辨析——`Nullable` 与 `.csproj`

- **辨析点**：`Nullable` 的定义是 开启 `Nullable` 后编译器会检查可能的空引用，新项目建议默认打开；`.csproj` 的定义是 C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集。
- **答题要求**：面对 `C# 与 .NET 平台` 的题目，先判断描述的是 `Nullable` 还是 `.csproj`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 报「已定义多个入口点」，而不是只写“程序有错”。
- **证据分**：保留触发 顶层语句与 `Main` 混用 的输入、版本和错误原文。
- **修复分**：按 二选一 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：.NET 9 / C# 13
；本课聚焦 C#。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：C#、.NET、CLR、IL、dotnet、csproj
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-03-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：C#、.NET、CLR、IL、dotnet、csproj。

| 参考资料 | 本课用途 |
| --- | --- |
| [dotnet CLI](https://learn.microsoft.com/dotnet/core/tools/) | 构建、运行与发布命令 |
| [.NET 文档](https://learn.microsoft.com/dotnet/) | 运行时、库与工具链 |
| [C# 指南](https://learn.microsoft.com/dotnet/csharp/) | 语言语法与类型系统 |

| [本课术语索引：C# 与 .NET 平台](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「C# 与 .NET 平台」的链接用于离线阅读后的延伸核对；App 不会自动联网。