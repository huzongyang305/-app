## 零基础详解：类、属性与封装

### 一句话说清它是什么

C# 的类把数据和行为打包，属性（property）是它最优雅的封装手段：
对外看起来像字段，内部其实可以带校验、只读或计算逻辑。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 类 | 图纸 | 定义有哪些字段与方法 |
| 对象 | 实物 | `new` 出来的实例 |
| 字段 | 内部零件 | 通常 private |
| 属性 | 带门禁的窗口 | 读写可控，可加校验 |
| 方法 | 能做的事 | 对外提供的操作 |
| record | 一次性信息卡 | 天生带比较与打印 |

### 从字段到属性的三种写法

```csharp
public class Account
{
    private decimal _balance;                         // 1. 字段：内部存储
    public decimal Balance => _balance;               // 2. 只读计算属性
    public string Owner { get; private set; } = "";   // 3. 对外只读、类内可写

    public Account(string owner, decimal initial)
    {
        Owner = owner;
        Deposit(initial);
    }

    public void Deposit(decimal amount)
    {
        if (amount <= 0) throw new ArgumentOutOfRangeException(nameof(amount));
        _balance += amount;
    }
}
```

| 写法 | 含义 |
| --- | --- |
| `{ get; set; }` | 可读可写 |
| `{ get; private set; }` | 外部只能读，类内可写 |
| `=> _balance` | 只读计算属性，没有存储 |
| 带 `init` | 只在对象初始化时赋值 |

### 带校验的属性

```csharp
public class User
{
    private string _email = "";

    public required string Email
    {
        get => _email;
        set
        {
            if (string.IsNullOrWhiteSpace(value) || !value.Contains('@'))
                throw new ArgumentException("邮箱格式不正确", nameof(value));
            _email = value.Trim().ToLowerInvariant();
        }
    }

    public string Display { get; init; } = "";
}
```

`required` 让编译器强制调用方初始化该属性，`init` 让属性只在创建时能赋值。

### record：数据搬运的首选

```csharp
public record User(string Name, int Age)
{
    public bool IsAdult => Age >= 18;
}

var a = new User("小明", 18);
var b = a with { Age = 19 };                     // 非破坏性修改
Console.WriteLine(a == new User("小明", 18));    // True：按值比较
Console.WriteLine(b);                            // User { Name = 小明, Age = 19 }
```

| 类型 | 比较方式 | 适用场景 |
| --- | --- | --- |
| `class` | 默认引用比较 | 有身份与生命周期的实体 |
| `record` | 按值比较 | DTO、消息、配置、不可变数据 |
| `struct` | 按值比较 | 小且短命的数据 |

### 静态成员与常量

```csharp
public static class MathTools
{
    public const double Epsilon = 1e-9;                        // 编译期常量
    public static readonly DateTime Start = DateTime.UtcNow;    // 运行时只读

    public static bool NearlyEqual(double a, double b)
        => Math.Abs(a - b) < Epsilon;
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 字段公开 | 外部随意改，校验被绕过 | 用属性封装 |
| 在属性 getter 里做重活 | 调试时反复触发 | 用方法或缓存 |
| 忘了 `required` | 对象可能缺关键字段 | 关键字段加 `required` |
| 用 `==` 比较普通 class | 比的是引用 | 需要值语义就用 `record` |
| 在 struct 里放大对象 | 频繁复制，性能差 | 改 class 或 record |
| 静态可变状态 | 并发问题难查 | 尽量用只读静态 |
| 不校验构造参数 | 错误延后暴露 | 尽早校验并明确异常类型 |
| 属性与字段同名 | 语法冲突 | 字段加下划线前缀 |

### 手把手练习：订单与金额校验

```csharp
public record OrderLine(string Name, decimal UnitPrice, int Quantity)
{
    public decimal Subtotal => UnitPrice * Quantity;
}

public class Order
{
    private readonly List<OrderLine> _lines = new();

    public required string Customer { get; init; }
    public IReadOnlyList<OrderLine> Lines => _lines;
    public decimal Total => _lines.Sum(l => l.Subtotal);

    public void Add(string name, decimal price, int quantity)
    {
        if (price < 0) throw new ArgumentOutOfRangeException(nameof(price));
        if (quantity <= 0) throw new ArgumentOutOfRangeException(nameof(quantity));
        _lines.Add(new OrderLine(name, price, quantity));
    }
}

var order = new Order { Customer = "小明" };
order.Add("键盘", 199m, 1);
order.Add("鼠标", 89.5m, 2);

Console.WriteLine($"{order.Customer} 合计 {order.Total:C}");
foreach (var line in order.Lines)
{
    Console.WriteLine($"  {line.Name} x{line.Quantity} = {line.Subtotal:C}");
}
```

### 学完自测

- [ ] 能说出字段与属性的区别。
- [ ] 知道 `private set` 与 `init` 分别限制了什么。
- [ ] 能说出 class 与 record 在比较语义上的差别。
- [ ] 知道 `required` 帮你避免什么问题。
- [ ] 能写一个带校验的只读属性。
