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
