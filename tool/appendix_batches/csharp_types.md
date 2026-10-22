## 类型速查

| 类型 | 大小 | 说明 | 字面量示例 |
| --- | --- | --- | --- |
| `bool` | 1 字节 | 真假 | `true` |
| `char` | 2 字节 | UTF-16 字符 | `'a'` |
| `int` | 4 字节 | 最常用整数 | `42` |
| `long` | 8 字节 | 大整数，需后缀 | `42L` |
| `double` | 8 字节 | 默认浮点 | `3.14` |
| `float` | 4 字节 | 需后缀 | `3.14f` |
| `decimal` | 16 字节 | 金额，精度高 | `19.99m` |
| `string` | 引用类型 | 不可变字符串 | `"hello"` |
| `DateTime` | 结构体 | 时间点 | `DateTime.UtcNow` |
| `Guid` | 结构体 | 唯一标识 | `Guid.NewGuid()` |
| `object` | 引用类型 | 所有类型的基类 | 装箱后使用 |

值类型与引用类型对照：

| 维度 | 值类型（struct / int） | 引用类型（class / string） |
| --- | --- | --- |
| 赋值 | 复制内容 | 复制引用 |
| 存储位置 | 通常在栈或内联 | 托管堆 |
| 可为 null | 需 `int?` 等可空类型 | 默认可为 null（开启可空注解后需声明） |
| 相等比较 | 默认按内容 | 默认按引用，`string` 重写为按内容 |

## 字符串与格式化速查

| 目的 | 写法 |
| --- | --- |
| 插值 | `$"你好 {name}"` |
| 格式化数字 | `$"{price:F2}"`、`$"{count:N0}"` |
| 对齐 | `$"{name,-10}\|"`（左对齐 10 位） |
| 逐字字符串 | `@"C:\temp\a.txt"` |
| 多行字符串 | `"""..."""`（C# 11+） |
| 拼接大文本 | `StringBuilder` |
| 拆分与连接 | `string.Split(',')`、`string.Join(",", list)` |
| 忽略大小写比较 | `string.Equals(a, b, StringComparison.OrdinalIgnoreCase)` |
| 判空 | `string.IsNullOrWhiteSpace(s)` |

```csharp
decimal price = 19.9m;
int count = 3;
Console.WriteLine($"总价：{price * count:F2}");      // 总价：59.70

string? input = null;
int value = int.TryParse(input, out var parsed) ? parsed : 0;   // 不抛异常

if (string.IsNullOrWhiteSpace(input))
{
    Console.WriteLine("请填写内容");
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `double` 算金额 | 出现 0.30000000000000004 之类的误差 | 金额一律用 `decimal`，并明确舍入模式 |
| `int.Parse("abc")` | `FormatException` | 用户输入用 `int.TryParse` |
| `left == right` 比较字符串 | 大多数情况可用，但受文化影响 | 明确指定 `StringComparison.Ordinal` 或 `OrdinalIgnoreCase` |
| 循环里用 `+=` 拼字符串 | 生成大量临时对象 | 用 `StringBuilder` |
| 大量修改 `string` | 每次都是新对象 | 需要可变时用 `Span<char>` 或 `StringBuilder` |
| 溢出未检查 | 结果静默回绕 | 用 `checked` 块，或使用 `long` / `BigInteger` |
| `int?` 直接参与运算 | 编译错误或结果为 null | 用 `?? 0` 或先判 `HasValue` |
| 忽略可空引用警告 | 运行时 `NullReferenceException` | 开启 `<Nullable>enable</Nullable>` 并处理警告 |
| 用 `==` 比较浮点 | 结果不稳定 | 用容差比较，或改用 `decimal` |
| 隐式类型转换丢精度 | 数据被截断 | 显式 `checked` 转换或用更大类型 |

## 自测清单

- [ ] 金额一律用 `decimal`，不用 `double`。
- [ ] 用户输入用 `TryParse`，不依赖异常控制流程。
- [ ] 字符串比较明确指定 `StringComparison`。
- [ ] 知道值类型与引用类型在赋值时的差异。
- [ ] 开启了可空引用类型并认真对待警告。
