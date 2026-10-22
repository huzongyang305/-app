## 零基础详解：值类型、引用类型与可空类型

### 一句话说清它是什么

C# 把类型分成两类：**值类型**（数据直接放在变量里）和**引用类型**（变量存地址，数据在堆上）。
再配上可空类型 `?`，空引用问题就能在编译期被大量拦下。

### 值类型 vs 引用类型

| 对比 | 值类型 | 引用类型 |
| --- | --- | --- |
| 常见类型 | `int`、`double`、`bool`、`char`、`struct`、`enum` | `string`、`class`、`array`、`record`、委托 |
| 存放 | 变量本身含数据 | 变量存引用，对象在堆上 |
| 赋值 | 复制一份，互不影响 | 复制引用，指向同一对象 |
| 能否为 null | 默认不能（可加 `?`） | 可以 |
| 释放 | 随作用域结束 | 由垃圾回收器管理 |

```csharp
int a = 1;
int b = a;
b = 2;                 // a 仍是 1

var list1 = new List<int> { 1 };
var list2 = list1;
list2.Add(2);          // list1 也变成 [1, 2]
```

### 可空类型：让编译器帮你防空

```csharp
string? maybeName = null;

// 1. 判空
if (maybeName is not null)
{
    Console.WriteLine(maybeName.Length);
}

// 2. 空合并与空条件
var name = maybeName ?? "匿名";
var length = maybeName?.Length ?? 0;
```

| 写法 | 含义 |
| --- | --- |
| `string?` | 这个变量可能为 null |
| `?.` | 为空就返回 null，不再往下取 |
| `??` | 为空时取右边的默认值 |
| `??=` | 为空时赋值 |
| `!` | 告诉编译器「我确定不为空」（慎用） |

### `var`、`dynamic`、`object` 三者别混

| 关键字 | 类型确定时机 | 类型安全 | 建议 |
| --- | --- | --- | --- |
| `var` | 编译期（由右侧推导） | 安全 | **日常首选** |
| `object` | 编译期（基类） | 需要拆箱转换 | 少用 |
| `dynamic` | 运行时 | 不安全 | 只在互操作时用 |

### 常用类型与精度

| 类型 | 用途 | 注意 |
| --- | --- | --- |
| `int` / `long` | 整数 | 默认 int，超大用 long |
| `double` | 科学计算 | 有精度误差，别比相等 |
| `decimal` | **金额** | 精度高、范围小，金融场景首选 |
| `char` / `string` | 字符与文本 | string 不可变 |
| `DateTime` / `DateTimeOffset` | 时间 | 跨时区用 Offset |
| `Guid` | 唯一标识 | 分布式 ID 常用 |

```csharp
decimal price = 19.99m;        // 金额必须加 m 后缀
double ratio = 1.0 / 3;
Console.WriteLine(price * 3);            // 59.97
Console.WriteLine($"{ratio:F4}");        // 0.3333
```

### 字符串处理三件套

```csharp
string raw = "  Hello, C#  ";
var trimmed = raw.Trim();                       // 去首尾空格
var upper = trimmed.ToUpperInvariant();         // 大写
var parts = trimmed.Split(", ");                // 拆分

// 大量拼接用 StringBuilder，避免产生大量临时字符串
var sb = new System.Text.StringBuilder();
foreach (var p in parts) sb.Append(p).Append('|');
Console.WriteLine(sb);
```

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 金额用 `double` | 出现 0.30000000000000004 | 改用 `decimal` 并加 `m` |
| 浮点直接比相等 | 条件几乎不成立 | 用误差或 `decimal` |
| 忘了 `?` | 可空警告或运行时空引用 | 声明可空类型并显式处理 |
| 滥用 `!` | 掩盖真实空值风险 | 优先判空或用 `??` |
| `int` 溢出 | 结果异常 | 用 `long` 或 `checked` |
| 字符串循环拼接 | 性能差 | 用 `StringBuilder` |
| `var` 用过头 | 阅读时看不出类型 | 类型不明显时写全类型 |

### 手把手练习：金额结算

```csharp
using System.Globalization;

decimal unitPrice = 19.99m;
int quantity = 3;
decimal discountRate = 0.9m;

decimal total = unitPrice * quantity * discountRate;
decimal rounded = Math.Round(total, 2, MidpointRounding.AwayFromZero);

Console.WriteLine($"原价 {unitPrice * quantity:C}");
Console.WriteLine($"折扣后 {rounded:C}");
Console.WriteLine($"格式化示例 {rounded.ToString("N2", CultureInfo.InvariantCulture)}");
```

### 学完自测

- [ ] 能说出值类型和引用类型在赋值时的差别。
- [ ] 能解释 `?.`、`??`、`??=` 各自的含义。
- [ ] 知道金额为什么必须用 `decimal`。
- [ ] 能说出 `var`、`object`、`dynamic` 的区别。
- [ ] 知道什么时候该用 `StringBuilder`。
