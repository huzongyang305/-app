## 零基础详解：继承、接口与多态

### 一句话说清它是什么

继承表达「是一种」，接口表达「能做什么」。C# 只允许单继承类，但可以实现多个接口。
多态让父类变量在运行时表现出子类的行为。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 基类 | 通用说明书 | 所有子类共有的部分 |
| 抽象类 | 未完成的说明书 | 不能直接使用，必须补全 |
| 接口 | 岗位要求 | 谁满足谁就能上岗，可多个 |
| `virtual` / `override` | 允许改写 | 子类可以给出自己的实现 |
| `sealed` | 到此为止 | 禁止继续被继承或重写 |

### 抽象类与接口的取舍

| 对比 | 抽象类 `abstract class` | 接口 `interface` |
| --- | --- | --- |
| 数量限制 | 只能继承一个 | 可以实现多个 |
| 字段 | 可以有实例字段 | 只能有常量，属性可以用默认实现 |
| 方法 | 抽象方法 + 具体实现 | 抽象成员 + 默认实现 |
| 表达 | 「是什么」 | 「能做什么」 |
| 何时用 | 子类共享状态与实现 | 跨类型统一能力 |

### 完整示例：形状与面积

```csharp
public interface IShape
{
    string Name { get; }
    double Area();
}

public abstract class Shape : IShape
{
    protected Shape(string name) => Name = name;

    public string Name { get; }

    public abstract double Area();                 // 子类必须实现

    public virtual string Describe() => $"{Name} 面积 {Area():F2}";
}

public sealed class Circle : Shape
{
    private readonly double _radius;
    public Circle(double radius) : base("圆形") => _radius = radius;
    public override double Area() => Math.PI * _radius * _radius;
}

public sealed class Rectangle : Shape
{
    private readonly double _w, _h;
    public Rectangle(double w, double h) : base("矩形") => (_w, _h) = (w, h);
    public override double Area() => _w * _h;
    public override string Describe() => base.Describe() + "（四边形）";
}

var shapes = new List<Shape> { new Circle(2), new Rectangle(3, 4) };
foreach (var shape in shapes)
{
    Console.WriteLine(shape.Describe());           // 多态调用
}
```

### 五种关键修饰符

| 修饰符 | 作用 | 使用建议 |
| --- | --- | --- |
| `abstract` | 声明必须由子类实现 | 只放真正共有的成员 |
| `virtual` | 允许子类重写 | 需要扩展点时使用 |
| `override` | 重写父类成员 | 总是写上，让编译器检查 |
| `sealed` | 禁止继续继承或重写 | 明确不希望被扩展时 |
| `new` | 隐藏父类成员 | **尽量别用**，容易造成困惑 |

### 用模式匹配替代类型判断

```csharp
static string Describe(Shape shape) => shape switch
{
    Circle c => $"半径圆，面积 {c.Area():F2}",
    Rectangle { } r => $"矩形，面积 {r.Area():F2}",
    _ => shape.Describe(),
};
```

比一串 `if (x is Circle)` 更清晰，编译器还能检查是否漏了情况。

### 扩展方法与默认接口实现

```csharp
public static class ShapeExtensions
{
    public static bool IsLarge(this IShape shape) => shape.Area() > 100;
}

// 调用时像实例方法一样
if (shape.IsLarge()) Console.WriteLine("大图形");
```

扩展方法必须写在静态类里，第一个参数带 `this`。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忘了 `override` | 变成新方法，多态失效 | 加 `override` 让编译器检查 |
| 用 `new` 隐藏成员 | 行为依赖变量类型 | 改成 `override` |
| 继承层次过深 | 牵一发动全身 | 优先组合，层次不过两层 |
| 在构造函数里调虚方法 | 子类字段还没初始化 | 构造完再调用 |
| 抽象类放太多实现 | 子类被迫继承不需要的成员 | 抽小接口 |
| 接口太大 | 实现类要写一堆空方法 | 按能力拆小 |
| 用 `as` 后不判空 | 空引用异常 | 用 `is` 模式匹配 |
| 把可空引用警告当噪音 | 运行时空引用 | 认真处理 `?` 与判空 |

### 手把手练习：支付方式多态

```csharp
public interface IPayment
{
    string Name { get; }
    decimal Fee(decimal amount);
}

public sealed class Alipay : IPayment
{
    public string Name => "支付宝";
    public decimal Fee(decimal amount) => Math.Round(amount * 0.006m, 2);
}

public sealed class BankCard : IPayment
{
    public string Name => "银行卡";
    public decimal Fee(decimal amount) => amount >= 1000m ? 0m : 2m;
}

var methods = new List<IPayment> { new Alipay(), new BankCard() };
decimal amount = 800m;

foreach (var m in methods)
{
    Console.WriteLine($"{m.Name} 手续费 {m.Fee(amount):C}，实收 {amount - m.Fee(amount):C}");
}
```

### 学完自测

- [ ] 能说出抽象类与接口的三点区别。
- [ ] 知道 `virtual` 与 `override` 必须成对出现。
- [ ] 能解释为什么不该用 `new` 隐藏父类成员。
- [ ] 能用 `switch` 模式匹配替代类型判断。
- [ ] 能说出扩展方法的定义要求。
