## 零基础详解：继承、多态与组合

### 一句话说清它是什么

继承表达「是一种」，多态让父类变量在运行时表现子类行为，组合表达「有一个」。
Java 只允许单继承类，但可以实现多个接口——**优先用组合和接口，继承控制在两层内**。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 继承 | 家族血脉 | 子类天然拥有父类能力 |
| `super` | 向父母请教 | 调用父类实现 |
| 抽象类 | 未完成的说明书 | 必须由子类补全 |
| 接口 | 岗位要求 | 谁满足谁上岗，可多个 |
| 组合 | 组装零件 | 用对象当成员，而不是继承 |

### 完整示例：形状与面积

```java
public interface Shape {
    String name();
    double area();

    default String describe() {                 // 接口默认方法
        return "%s 面积 %.2f".formatted(name(), area());
    }
}

public abstract class AbstractShape implements Shape {
    private final String name;

    protected AbstractShape(String name) {
        this.name = name;
    }

    @Override
    public final String name() {
        return name;
    }
}

public final class Circle extends AbstractShape {
    private final double radius;

    public Circle(double radius) {
        super("圆形");
        if (radius <= 0) throw new IllegalArgumentException("半径必须为正");
        this.radius = radius;
    }

    @Override
    public double area() {
        return Math.PI * radius * radius;
    }
}

public final class Rectangle extends AbstractShape {
    private final double width;
    private final double height;

    public Rectangle(double width, double height) {
        super("矩形");
        this.width = width;
        this.height = height;
    }

    @Override
    public double area() {
        return width * height;
    }

    @Override
    public String describe() {
        return Shape.super.describe() + "（四边形）";
    }
}
```

### 多态的三种体现

```java
List<Shape> shapes = List.of(new Circle(2), new Rectangle(3, 4));
for (Shape shape : shapes) {
    System.out.println(shape.describe());       // 同一调用，不同实现
}

// 向上转型：子类对象赋值给父类变量
Shape s = new Circle(1);

// 向下转型：先判断再转，避免 ClassCastException
if (s instanceof Circle c) {                    // 模式匹配（Java 16+）
    System.out.println(c.area());
}
```

### 五个关键修饰符

| 修饰符 | 作用 | 使用建议 |
| --- | --- | --- |
| `abstract` | 必须由子类实现 | 只放真正共有的成员 |
| `final`（类） | 禁止继承 | 工具类、值对象常用 |
| `final`（方法） | 禁止重写 | 关键逻辑不希望被改 |
| `protected` | 子类可访问 | 谨慎使用，容易破坏封装 |
| `@Override` | 声明重写 | **总是写**，让编译器检查 |

### 继承 vs 组合：一个真实判断

```java
// 反例：为了复用代码而继承，结果 Stack 拥有了 List 的全部方法
class BadStack<T> extends ArrayList<T> { }

// 正例：组合 + 只暴露需要的方法
public class GoodStack<T> {
    private final Deque<T> items = new ArrayDeque<>();

    public void push(T item) { items.push(item); }
    public T pop() { return items.pop(); }
    public boolean isEmpty() { return items.isEmpty(); }
}
```

**判断标准**：如果能说出「子类是一种父类」，才考虑继承；否则用组合。

### 抽象类与接口的取舍

| 对比 | 抽象类 | 接口 |
| --- | --- | --- |
| 数量 | 只能继承一个 | 可实现多个 |
| 状态 | 可以有实例字段 | 只能是常量 |
| 构造方法 | 有 | 没有 |
| 方法 | 抽象 + 具体 | 抽象 + 默认 + 静态 |
| 表达 | 「是什么」 | 「能做什么」 |
| 何时用 | 需要共享实现与状态 | 需要跨类型统一能力 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忘了 `@Override` | 拼错方法名变成新方法 | 总是加注解 |
| 用继承复用代码 | 层次深、耦合重 | 优先组合 |
| 在构造方法里调可重写方法 | 子类字段还没初始化 | 构造完再调用 |
| 子类访问 `protected` 字段 | 破坏封装 | 提供 `protected` 方法 |
| 忘记 `super(...)` | 编译错误 | 显式调用父类构造 |
| 用 `==` 比较对象 | 比的是地址 | 重写 `equals` 与 `hashCode` |
| 强转前不判断类型 | `ClassCastException` | 用 `instanceof` 模式匹配 |
| 把可变对象暴露出去 | 外部能改内部状态 | 返回副本或不可变视图 |

### 手把手练习：支付方式多态

```java
public interface Payment {
    String name();
    long feeCents(long amountCents);
}

public final class Alipay implements Payment {
    @Override public String name() { return "支付宝"; }
    @Override public long feeCents(long amountCents) {
        return Math.round(amountCents * 0.006);
    }
}

public final class BankCard implements Payment {
    @Override public String name() { return "银行卡"; }
    @Override public long feeCents(long amountCents) {
        return amountCents >= 100_000 ? 0 : 200;
    }
}

void main() {
    List<Payment> methods = List.of(new Alipay(), new BankCard());
    long amount = 80_000;
    for (Payment p : methods) {
        long fee = p.feeCents(amount);
        System.out.printf("%s 手续费 %.2f 元，实收 %.2f 元%n",
                p.name(), fee / 100.0, (amount - fee) / 100.0);
    }
}
```

### 学完自测

- [ ] 能说出继承与组合的判断标准。
- [ ] 知道为什么 `@Override` 一定要写。
- [ ] 能说出抽象类与接口的三点区别。
- [ ] 知道在构造方法里调可重写方法的风险。
- [ ] 能说出向上转型与向下转型的区别。
