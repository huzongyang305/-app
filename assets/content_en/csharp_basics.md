# C# and .NET platform

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Estimated duration: 14 minutes

## Learning objectives

- I can explain what the "C# and .NET platform" is about, not just words.
- The relationship between "C#", ".NET," "CLR" and "IL" is clear, with one example:
- It's a good way to put this subject back into the "C#" knowledge system, and it shows how much of an adjacent theme is going on.
- It is possible to complete this course and check its results using acceptance standards.

> Summary of sentence: IL with CLR, dotnet CLI, project file and naming space.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Read it first: C#, .NET, CLR.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## What's NET?

C# Runs on the .NET platform: The source code is first translated into an intermediate language (IL), while running by the CLR (when it's run in a public language) through JIT and responsible for garbage recovery and type security.

```text
源码 .cs -> Roslyn 编译 -> IL（dll / exe）-> CLR 加载 + JIT -> 本机代码执行
```

Common application type: console program, ASP.NET Core Web API, desktop (WPF/WinUI), game (Unity) and mobile (MAUI).

## First program.

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

You can also use a top-level statement. The compiler will automatically generate the entry method:

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

## Project documents

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

A new item is proposed to be opened by default.

## Namespace

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

Naming spaces are layered, usually corresponding to the catalogue structure, and is used to avoid class conflicts.

## It's the end of this class.
C# Runs on.NET: ** Compiled into IL, executed by the CLR Trust. ⟦CLI and csproj configuration allows you to start any type of project.

<!-- appendix:v1 -->

## .NET platform quick check

|Concept|Annotations|
| --- | --- |
| CLR |When running public languages, implement IL and memory management|
| IL / MSIL |It's in the program.|
| JIT |Compile ILs into machine codes while running|
| AOT |It's a pre-existing code, fast and big.|
|Assembly|0 / 1 , deployment and version|
| NuGet |Package Manager, dependent on ⟦0|
|Target framework (TFM)|It's like "0" or "1".|
|SDK Style Item|Modern ⟦, default contains source code and hidden using|

## Dotnet CLI, quick.

|Purpose|Command|
| --- | --- |
|View Versions and SDK| `dotnet --info` |
|New Item| `dotnet new console -o Hello` |
|New Web API| `dotnet new webapi -o Api` |
|New Solutions| `dotnet new sln -n App` |
|Add Item to Solutions| `dotnet sln add Api/Api.csproj` |
|Revert it.| `dotnet restore` |
|Compile| `dotnet build -c Release` |
|Run| `dotnet run --project Api` |
|Test| `dotnet test` |
|Release| `dotnet publish -c Release -o out` |
|Add Package| `dotnet add package Serilog` |
|View Expired Packages| `dotnet list package --outdated` |
|Global Tools| `dotnet tool install -g dotnet-ef` |

Common csproj configuration:

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

## Common Error Table

|Misreporting or phenomena|Reason|Treatment|
| --- | --- | --- |
| `The type or namespace name could not be found` |Missing or not packed|Zero or zero.|
|There's a lot of warning.|Exposure to empty values on open analysis|Do it one by one, don't cover up.|
| `Program does not contain a static 'Main'` |Missing entry points|Fill in ⟦, or use the top sentence|
|The result of running after changing the code is unchanged.|Runs old construction|Confirm target frame and configuration after 0|
| `error NETSDK1045` |SDK version below target framework|Install corresponding SDK or lower TargetFramwork|
|Profile missing after release|Not copied to Output Directory|Set ⟦ in csproj|
|_Other Organiser|There's no consistency in the transmission.|Zero, locate and unify.|
|Locally run, server defaults|Servers are running only|Install ASP.NET Core Runtime to include self-distribution|
|Failed to build when open|We've got an alarm.|We'll call the cops and then we'll open the door.|
|We're going to do a production deployment with 0.|Environmental incoherence|We're going to deploy with zero.|

## Self-Detected List

- [ ] Can explain the relationship between CLR, IL and JIT.
- [ ] It's gonna be 0, 1 , 2 , 3 and 4.
- [ ] The project opens ⟦ and handles the alarm.
- [ ] Reliance on NuGet management, version concentrated in csproj.
- [ ] Deployment of the product using ⟦0.

<!-- appendix:v2 -->

## Zero base details: .NET, CLI and the first C# program

### What is it?

C# is a translation language running on **.NET** platform: source code translated into an IL
It is then compiled and implemented instantaneously on the target machine, taking into account performance and cross-platforms.

### Four words at once.

|Terminology|Full|A metaphor.|Annotations|
| --- | --- | --- | --- |
| .NET |Platform|Set of toolboxes + plant|Include running time, library and tools|
| CLR |When running in a public language|The engine in the factory.|Loading, JIT, garbage collection.|
| IL |Intermediate languages|Generic drawings|All .NET languages are compiled into it|
| NuGet |Package Manager|The spare parts store.|The third-party vault.|

### Two files to support the project.

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

|Configure|Role|Recommendations|
| --- | --- | --- |
| `OutputType` |Generate Executables or Libraries|Console program with ⟦0|
| `TargetFramework` |Target framework version|We're on the same team. Don't jump at all.|
| `Nullable` |Open empty reference type check|** I'm sure it will.**|
| `ImplicitUsings` |Automatically introduce common naming spaces|Shorter code when it's on.|

### Common commands

```bash
dotnet new console -o Demo     # 新建控制台项目
cd Demo
dotnet run                     # 编译并运行
dotnet build -c Release        # 发布配置构建
dotnet publish -c Release -r linux-x64 --self-contained false
```

### Classes, Named Spaces and Entry

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

A top-level statement (directly ⟦) suitable for small scripts;
When the project gets bigger, it's more explicit.

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|Convergence with ⟦0|"More points of entry defined"|Two or two.|
|Forget it.|No type found|Namespace or Open Hidden Using|
|But empty warning ignored|Runtime reference crash|Take care of that.|
|The value type is confused with the reference type|It's not working.|Specify / class semantics|
|Chinese Punction|Compiler error|All in English.|
|Namespace does not match the folder|Type not found|Directory structure aligned to namespace|
|Forget it.|Empty Quote Skipped|Open in csproj|
|Compare string with ⟦0|I don't know.|C# Medium Zero-Type|

### Hand hands practice: Small command line tool

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

⟦ mode is the standard formula used by C# to process user input: do not drop abnormality and get a boolean result.

### Learn how to measure yourself.

- [ Chuckles ] Can you tell me what... NET, CLR, IL and NuGet are?
- [ ] Knows the difference between ⟦,  and .
- [ Chuckles ] Can explain why it's on.
- [ ] It's a trade-off between the top and visible.
- [ ] The user input is interpreted safely with ⟦0.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around C#, .NET, CLR, each result being checked by someone else.

Create a minimum console program, then fill in the type, walk and abnormal path, which will be verified with dotnet test.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with "C# and .NET" platform?
2. Without it, what concrete consequences would there be?
3. What's it got to do with NET?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a console applet to add a regular, one boundary value and an abnormal path.

Mission requests:

- The result must be checked, not just “I understand”.
- "C#" and ".NET" are at least covered.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** C# & .NET

**Summary:** IL/CLR, dotnet CLI, project files and namespaces.

**Category:** C#  
**Level:** Foundation
**Key terms:** C#, .NET, CLR, IL, dotnet, csproj

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: .NET 9/C#13
- Source: Internal structured curriculum and engineering practices
- Related themes: C#, .NET, CLR, IL, dotnet, csproj
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

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

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|What's NET?|What's NET?|
|First program.|First program.|
| dotnet CLI | dotnet CLI |
|Project documents|Project documents|
|Namespace|Namespace|
|It's the end of this class.| Summary |
|.NET platform quick check|.NET platform quick check|
|Dotnet CLI, quick.|Dotnet CLI, quick.|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

