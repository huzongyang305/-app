# 控制流与方法

![控制流与方法](images/remaining_csharp_control_methods.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「控制流与方法」解决了什么问题，而不是只背术语。
- 能说清 「switch」、「模式匹配」、「foreach」、「ref」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「C#」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：switch 表达式与模式匹配、循环、参数修饰符、迭代器。

## 前置知识

- 先完成上一课《变量、类型与字符串》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：switch、模式匹配、foreach。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 分支与模式匹配

```csharp
int score = 78;

if (score >= 90) Console.WriteLine("优秀");
else if (score >= 60) Console.WriteLine("及格");
else Console.WriteLine("不及格");

string grade = score switch
{
    >= 90 => "A",
    >= 60 => "B",
    _ => "C"                 // 兜底分支
};

switch (value)
{
    case int n when n > 0:
        Console.WriteLine($"正整数 {n}");
        break;
    case string s:
        Console.WriteLine($"字符串 {s}");
        break;
    case null:
        break;
}
```

`switch` 表达式更紧凑；模式匹配能同时完成类型判断与变量声明。

## 循环

```csharp
for (int i = 0; i < 5; i++) { }
foreach (var item in items) { }             // 遍历 IEnumerable

int n = 3;
while (n-- > 0) { }
do { } while (false);

foreach (var (key, value) in dictionary) { }   // 解构键值对
```

遍历集合时不要修改集合结构，否则会抛 `InvalidOperationException`；需要增删就遍历副本。

## 方法

```csharp
public static int Add(int a, int b = 0) => a + b;

public static void Swap(ref int a, ref int b) => (a, b) = (b, a);

public static bool TryDivide(int a, int b, out int result)
{
    if (b == 0) { result = 0; return false; }
    result = a / b;
    return true;
}

public static int Sum(params int[] numbers) => numbers.Sum();
```

参数修饰符：`ref` 传入并可能修改、`out` 用于输出、`in` 只读引用（大结构体避免拷贝）、`params` 可变参数。

## 局部函数与迭代器

```csharp
public static IEnumerable<int> Evens(int limit)
{
    return Iterator();

    IEnumerable<int> Iterator()          // 局部函数，可访问外层变量
    {
        for (int i = 0; i < limit; i += 2) yield return i;
    }
}
```

`yield return` 实现惰性求值，数据量大时能显著节省内存。

## 本课小结
现代 C# 的写法：**switch 表达式做分支、表达式主体写短方法、ref/out/params 精确表达参数语义**。

<!-- appendix:v1 -->

## 控制流速查

| 结构 | 写法 | 注意 |
| --- | --- | --- |
| `if / else if / else` | 条件分支 | 条件必须是 `bool` |
| `switch` 语句 | 传统分支 | 每个 `case` 需 `break` / `return` |
| `switch` 表达式 | `value switch { ... }` | 无穿透，支持模式匹配 |
| `for` / `foreach` | 计次与遍历 | `foreach` 中不能修改集合结构 |
| `while` / `do...while` | 条件循环 | `do...while` 至少执行一次 |
| `break` / `continue` | 跳出 / 跳过 | 只影响最近一层循环 |
| `goto case` | 跳到另一个 case | 少数场景使用 |

```csharp
// switch 表达式 + 模式匹配 + when 子句
string Grade(int score) => score switch
{
    >= 90 => "优秀",
    >= 80 => "良好",
    >= 60 when score % 10 == 0 => "及格（整十）",
    >= 60 => "及格",
    _ => "需努力",
};

// 类型模式与属性模式
string Describe(object value) => value switch
{
    int n when n < 0 => "负整数",
    int n => $"整数 {n}",
    string { Length: 0 } => "空字符串",
    string s => $"字符串长度 {s.Length}",
    null => "空值",
    _ => "其他类型",
};
```

## 方法速查

| 概念 | 说明 |
| --- | --- |
| 重载 | 同名不同参数列表 |
| 可选参数 | `void F(int a, int b = 1)`，默认值必须是编译期常量 |
| 命名参数 | `F(b: 2, a: 1)`，提高可读性 |
| `ref` | 传入前必须初始化，方法内可读写 |
| `out` | 不需初始化，方法内必须赋值 |
| `in` | 只读引用，适合较大的结构体 |
| `params` | 可变参数，必须是最后一个 |
| 本地函数 | 方法内的命名函数，可递归、可静态 |
| 表达式体成员 | `int Square(int x) => x * x;` |
| `yield return` | 逐项产出，实现惰性序列 |

```csharp
// out 参数：TryXxx 模式的经典写法
bool TryParseAge(string? text, out int age) =>
    int.TryParse(text, out age) && age is >= 0 and <= 150;

// 本地函数 + yield：惰性读取大文件
IEnumerable<string> ReadNonEmpty(string path)
{
    foreach (var line in File.ReadLines(path))
    {
        if (!string.IsNullOrWhiteSpace(line))
        {
            yield return line.Trim();
        }
    }
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `switch` 分支漏 `break` | 编译错误（C# 禁止隐式穿透） | 加 `break` / `return`，或用 switch 表达式 |
| 可选参数使用非编译期常量 | 编译错误 | 用常量或改用重载 |
| `params` 放在参数中间 | 编译错误 | `params` 必须是最后一个 |
| `out` 参数在方法内没赋值 | 编译错误 | 所有路径都要赋值 |
| `foreach` 中修改集合 | `InvalidOperationException` | 先收集改动，循环后统一处理 |
| 用 `yield` 的方法返回 `List<T>` | 类型错误 | 返回类型应为 `IEnumerable<T>` |
| 忘了 `return` 的分支 | 编译错误：并非所有代码路径都返回值 | 补 `default` 分支或抛异常 |
| `switch` 表达式漏 `_` 而值超出范围 | 运行时抛异常 | 加 `_` 兜底分支 |
| 用 `goto` 跳转控制流程 | 可读性差 | 改用循环 + 条件判断 |
| 方法过长（几百行） | 难以测试与复用 | 拆成多个小方法或服务 |

## 自测清单

- [ ] 会用 `switch` 表达式与模式匹配。
- [ ] 可选参数与命名参数使用得当。
- [ ] 会用 `out` 实现 `TryXxx` 模式，不用异常控制流程。
- [ ] 大数据用 `yield return` 惰性返回。
- [ ] 方法保持短小且职责单一。

<!-- appendix:v2 -->

## 零基础详解：判断、循环与方法

### 一句话说清它是什么

判断决定走哪条分支，循环负责重复，方法把逻辑封装并命名。
C# 在这三块提供了不少「更少代码、更少出错」的现代写法。

### 判断：从 `if` 到 `switch` 表达式

```csharp
// 传统写法
string level;
if (score >= 90) level = "优秀";
else if (score >= 60) level = "及格";
else level = "不及格";

// switch 表达式：把「值 → 结果」写成一张表
string level2 = score switch
{
    >= 90 => "优秀",
    >= 60 => "及格",
    _ => "不及格",          // _ 是兜底
};
```

| 场景 | 推荐写法 |
| --- | --- |
| 范围或复杂条件 | `if / else if` |
| 一个值映射到结果 | `switch` 表达式 |
| 空值兜底 | `??`、`??=` |
| 逐层取属性 | `?.` |

### 循环的四种选择

| 循环 | 适合 | 特点 |
| --- | --- | --- |
| `for` | 需要下标或次数 | 最灵活 |
| `foreach` | 遍历集合 | 不能边遍历边改集合 |
| `while` | 条件驱动 | 可能一次都不执行 |
| `do...while` | 至少执行一次 | 先做后判断 |

```csharp
foreach (var item in items)
{
    if (item.IsSkip) continue;   // 跳过这一项
    if (item.IsStop) break;      // 结束整个循环
    Console.WriteLine(item.Name);
}
```

### 方法的四种参数修饰符

| 修饰符 | 含义 | 例子 |
| --- | --- | --- |
| 无 | 值传递（副本） | `void F(int x)` |
| `ref` | 传入并可能修改原变量 | `void F(ref int x)` |
| `out` | 用于「返回多个值」 | `bool TryParse(string s, out int n)` |
| `in` | 只读引用，避免拷贝大结构 | `void F(in BigStruct s)` |

```csharp
bool TryDivide(int a, int b, out double result)
{
    if (b == 0) { result = 0; return false; }
    result = (double)a / b;
    return true;
}

if (TryDivide(10, 3, out var value))
    Console.WriteLine($"{value:F2}");
```

`TryXxx + out` 是 .NET 的经典模式：不抛异常，用返回值表示成功与否。

### 可选参数、命名参数与重载

```csharp
void Send(string to, string subject = "无主题", bool urgent = false) { }

Send("a@b.com");                                  // 用默认值
Send("a@b.com", urgent: true);                    // 命名参数，跳过中间项

// 重载：同名不同参
int Add(int a, int b) => a + b;
double Add(double a, double b) => a + b;
```

可选参数要放在参数列表末尾；调用处用命名参数能显著提高可读性。

### 表达式体成员：一行写完小方法

```csharp
public int Square(int x) => x * x;
public string Name => _name;                 // 只读属性
public override string ToString() => $"User({Id})";
```

短方法用表达式体更清爽，逻辑一长就换回大括号。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `foreach` 里改集合 | `InvalidOperationException` | 先收集要改的项，循环外处理 |
| `out` 变量没赋值 | 编译错误 | 所有分支都要赋值 |
| 递归无出口 | `StackOverflowException` | 先写终止条件 |
| 参数顺序记错 | 传错值 | 用命名参数 |
| 方法过长 | 难测难改 | 按职责拆分 |
| 忽略返回值 | 以为对象被改了 | 接收返回值或改用可变对象 |
| `switch` 忘兜底 | 运行期没匹配到 | 用 `_` 分支 |

### 手把手练习：成绩统计与素数筛选

```csharp
static bool IsPrime(int n)
{
    if (n < 2) return false;
    for (var d = 2; d * d <= n; d++)
    {
        if (n % d == 0) return false;
    }
    return true;
}

static (int Count, double Average, string Level) Summarize(int[] scores)
{
    if (scores.Length == 0) return (0, 0, "无数据");
    var total = scores.Sum();
    var avg = (double)total / scores.Length;
    var level = avg switch
    {
        >= 90 => "优秀",
        >= 60 => "及格",
        _ => "不及格",
    };
    return (scores.Length, Math.Round(avg, 1), level);
}

Console.WriteLine(string.Join(", ", Enumerable.Range(2, 30).Where(IsPrime)));
var (count, average, level) = Summarize(new[] { 88, 92, 79 });
Console.WriteLine($"{count} 人，平均 {average}，等级 {level}");
```

### 学完自测

- [ ] 能写出一个 `switch` 表达式并说明 `_` 的作用。
- [ ] 能说出 `ref`、`out`、`in` 的区别。
- [ ] 知道 `TryParse` 模式为什么比抛异常更好。
- [ ] 能写出带可选参数与命名参数的调用。
- [ ] 能返回一个元组来同时给出多个结果。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「switch、模式匹配、foreach」完成复述、实验和交付，每个结果都要能被别人检查。

先建最小控制台程序，再补类型、异步和异常路径，最后用 dotnet test 验证。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「控制流与方法」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「模式匹配」是什么关系？

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
- 至少覆盖「switch」和「模式匹配」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Control Flow & Methods

**Summary:** Switch expressions, patterns, loops, parameters and iterators.

**Category:** C#  
**Level:** 基础  
**Key terms:** switch, 模式匹配, foreach, ref, out, yield

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：.NET 9 / C# 13
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：switch、模式匹配、foreach、ref、out、yield
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [C# 官方指南](https://learn.microsoft.com/dotnet/csharp/) | 语言、异步与模式匹配 |
| [.NET 文档](https://learn.microsoft.com/dotnet/) | 运行时、GC 与发布 |

> 本课主题：switch 表达式与模式匹配、循环、参数修饰符、迭代器。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

