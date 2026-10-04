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
