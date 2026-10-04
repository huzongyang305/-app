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
