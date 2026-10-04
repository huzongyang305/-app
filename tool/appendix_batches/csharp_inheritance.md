## 继承与接口速查

| 概念 | 写法 | 说明 |
| --- | --- | --- |
| 基类继承 | `class Dog : Animal` | C# 只能单继承类 |
| 接口实现 | `class Repo : IRepo, IDisposable` | 可实现多个接口 |
| 抽象类 | `abstract class Shape` | 不能实例化，可含实现 |
| 抽象方法 | `public abstract double Area();` | 子类必须重写 |
| 虚方法 | `public virtual string Name() => "shape";` | 子类可选重写 |
| 重写 | `public override double Area() => ...;` | 强烈建议加 `override` |
| 密封 | `public sealed override void F()` | 禁止继续重写 |
| 接口默认实现 | `void Log() => Console.WriteLine();` | C# 8+ 支持 |
| 显式实现 | `void IDisposable.Dispose() { }` | 避免公开成员污染 |

类型转换与模式速查：

| 目的 | 写法 | 失败行为 |
| --- | --- | --- |
| 类型判断 | `obj is User u` | 返回 `false`，`u` 为 `null` |
| 安全转换 | `obj as User` | 返回 `null` |
| 强制转换 | `(User)obj` | 抛 `InvalidCastException` |
| 空值兜底 | `obj as User ?? fallback` | 使用兜底值 |
| 属性模式 | `obj is User { Age: > 18 }` | `false` |

```csharp
public abstract class Shape
{
    public abstract double Area();

    public virtual string Describe() => $"{GetType().Name}: {Area():F2}";
}

public sealed class Circle : Shape
{
    private readonly double _radius;
    public Circle(double radius) => _radius = radius;

    public override double Area() => Math.PI * _radius * _radius;
}

// 依赖接口而不是具体类，便于替换与测试
public interface IClock
{
    DateTime UtcNow { get; }
}

public sealed class SystemClock : IClock
{
    public DateTime UtcNow => DateTime.UtcNow;
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 重写忘写 `override` | 变成隐藏成员，行为不符合预期 | 加 `override` 并开 `noImplicitOverride` 风格告警 |
| 子类构造器未调用基类构造 | 编译错误 | 用 `: base(...)` 显式调用 |
| 强制转换不判断 | `InvalidCastException` | 用 `is` / `as` 先判断 |
| 接口成员遗漏实现 | 编译错误 | 全部实现，或声明为 abstract |
| 用继承表达「有一个」之外的复用 | 层级僵化 | 优先组合（注入依赖） |
| 基类构造器调用虚方法 | 子类字段未初始化 | 构造器只做本类初始化 |
| 抽象类里塞太多实现 | 子类被迫继承不需要的行为 | 拆成小接口 |
| 用 `new` 隐藏父类成员 | 调用结果取决于引用类型 | 用 `override` 或改名 |
| 忘记 `sealed` 导致被随意继承 | 行为被破坏 | 不打算扩展的类加 `sealed` |
| 自定义 `Equals` 后仍用 `==` 比较 | 结果不一致 | 明确重载 `==` 或统一用 `Equals` |

## 自测清单

- [ ] 能分辨 `abstract` / `virtual` / `override` / `sealed`。
- [ ] 类型转换优先用模式匹配，而不是强制转换。
- [ ] 优先组合而不是继承复用代码。
- [ ] 面向接口编程，便于替换与单元测试。
- [ ] 不打算被继承的类标记 `sealed`。
