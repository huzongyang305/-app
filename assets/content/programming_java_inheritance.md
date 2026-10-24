# 继承、接口与多态

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：40 分钟

![类、抽象类、接口与多态](images/diagram_java_inheritance.webp)

![继承、接口与多态](images/remaining_java_inheritance.webp)

## 本节知识框架

上一课你学会了用 class 创建对象。但现实世界里事物之间往往有"是一种"的关系——猫是动物，电动车是交通工具。Java 用**继承**表达这种关系，用**接口**约定能力，用**多态**让同一句代码在不同对象上表现不同。

打个比方：你家的猫和邻居家的狗都会"叫"，但叫法不同。喊一声"叫！"，猫会喵喵、狗会汪汪——这就是多态。

**本课你将学到：**
- 用 extends 让子类继承父类
- 用 abstract class 和 interface 定义抽象模板
- 理解多态如何让代码更灵活
- 用 record 和 enum 简化常见场景

**先修要求：** 学完《类与对象》即可。

### 复习清单

- [ ] 能画出本课示例的类继承关系图
- [ ] 能说出抽象类和接口的三个区别
- [ ] 能解释 super 关键字的两种用法

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| 继承（extends） | 子类自动拥有父类的字段和方法，还能重写父类行为。Java 只支持单继承。 |
| 抽象类 | 不能被 new 的类，可包含抽象方法，强制子类去实现。 |
| 接口 | 一组能力约定，Java 8+ 可以有默认实现。一个类可实现多个接口。 |
| 多态 | 父类引用指向子类对象，调用被重写的方法时执行子类版本。 |
| 重写 / 重载 | 重写是子类替换父类的同名同参方法（运行时决定）；重载是同类里同名不同参的多个版本（编译时按形参列表决定），两者互不相干。 |
| Object | 所有类的隐式根父类，equals、hashCode、toString、getClass 都从这里来。 |
| final | 修饰类表示不可被继承，修饰方法表示不可被重写，修饰字段表示只能赋值一次。 |
| sealed | Java 17 的受限制父类，用 permits 精确列出允许继承它的子类，让类型分支可穷尽。 |
| instanceof 模式匹配 | `if (obj instanceof Circle c)` 一步完成类型判断和安全转型，c 只在分支内有效。 |
| 组合 | 把能力对象作为字段持有并转发调用，不与继承纠缠，是复用代码的首选手段。 |

## 原理与运行机制

### 用生活场景理解

1. **继承** — "易碎品包裹"继承了"包裹"的属性，额外加了 fragile 标记
2. **抽象类** — "包裹"本身是抽象概念，你不会寄一个"纯包裹"
3. **接口** — "可追踪"是一个能力，跟继承无关
4. **多态** — 分拣员对所有包裹说"称重"，不同包裹表现不同

### 继承的基本用法

```java
public class Animal {
    protected String name;
    public Animal(String name) { this.name = name; }
    public void speak() { System.out.println(name + "发出声音"); }
}

public class Cat extends Animal {
    public Cat(String name) { super(name); }
    @Override
    public void speak() { System.out.println(name + "喵喵叫"); }
}

Animal a = new Cat("咪咪");
a.speak();  // 咪咪喵喵叫 ← 多态！
```

### 抽象类 vs 接口

```text
对比维度      抽象类                 接口
──────────────────────────────────────────────
关键字       abstract class         interface
继承         只能单继承              可以多实现
字段         可以有实例字段           只能有 static final
方法         可以有具体实现           Java 8+ 有 default 方法
适用         "是一种"关系            "有某种能力"
```

```java
public abstract class Shape {
    protected String color;
    public Shape(String color) { this.color = color; }
    public abstract double area();
}

public interface Resizable {
    void resize(double factor);
}

public class Circle extends Shape implements Resizable {
    private double radius;
    public Circle(String color, double radius) {
        super(color);
        this.radius = radius;
    }
    @Override public double area() { return Math.PI * radius * radius; }
    @Override public void resize(double factor) { radius *= factor; }
}
```

### @Override 与 equals/hashCode

@Override 让编译器检查方法签名是否与父类一致，防止拼写错误。重写 equals() 必须同时重写 hashCode()，否则 HashMap/HashSet 出问题。

### record：不可变数据快捷写法

```java
public record Point(int x, int y) {}
Point p = new Point(3, 4);
System.out.println(p.x());  // 3
```

### 重写必须守住的三条规则

`@Override` 不是装饰，它把三条隐含约束变成编译期检查：

1. **方法名与形参列表必须一模一样。** 父类是 `speak()`，子类写 `speak(String)` 就变成重载而不是重写，父类版本仍在，调用时执行的是父类实现——这类 bug 编译器不报错，加上 `@Override` 立刻暴露。
2. **访问权限只能放宽不能收紧。** 父类 `protected` 的方法，子类不能改成 `private`，否则破坏"子类对象一定能当父类对象用"的前提。
3. **返回值可以是更具体的类型**（协变返回），`Cat copy()` 覆盖 `Animal copy()` 合法；抛出的受检异常也不能比父类更宽。

### 对象创建时到底按什么顺序初始化

```java
class Base {
    int b = 1;
    Base() { System.out.println("Base 构造器, b=" + b); }
}
class Sub extends Base {
    int s = 2;
    Sub() { System.out.println("Sub 构造器, s=" + s); }
}
new Sub();   // 先 Base 构造器, b=1 → 再 Sub 构造器, s=2
```

顺序永远是：父类字段赋值 → 父类构造器 → 子类字段赋值 → 子类构造器。这条链解释了那条易错点：如果父类构造器里调用了被子类重写的方法，此时子类字段还没赋值，方法里读到的是 0 或 null，且没有任何报错提示。方法调用按对象的运行时类型分派，而对象运行时类型从第一行构造器执行时起就已经是子类了，所以父类构造器里那句 `speak()` 真的会跳到子类版本。把构造器里调用的方法写成 `private` 或 `final` 就能彻底封死这条路。

### 编译时看引用类型，运行时看对象类型

```java
Animal a = new Cat("咪咪");
a.speak();          // 咪咪喵喵叫：方法按对象实际类型选（多态）
// a.purr();        // 编译失败：Cat 独有的方法，Animal 引用看不见
if (a instanceof Cat c) c.purr();   // 需要子类专属能力时先判型再调
```

一句话记牢：**引用类型决定"能写哪些调用"，对象类型决定"这次调用执行谁的代码"。** 字段没有多态——`a.name` 取的是引用类型可见的字段，父类与子类同名字段并存时，`super.name` 和 `this.name` 指向不同存储位置，这也是易错表里"子类重复声明父类字段"的根因。静态方法同理：它按引用类型绑定，`Animal.compare(x,y)` 即使子类"重写"了也仍是两个互相独立的方法。

### 抽象类与接口：先问要不要持有状态

| 你在权衡的事 | 选抽象类 | 选接口 |
| --- | --- | --- |
| 需要实例字段保存共用状态 | 可以 | 只能 static final 常量 |
| 需要带参数的构造器 | 可以 | 不允许构造器 |
| 一个类要同时具备多种能力 | 单继承限制 | 可 implements 多个 |
| 想给方法提供默认实现后又统一改动 | 子类自动跟随 | default 方法可被子类覆盖，改动不保证一致 |
| 想让外部无法伪造实现 | 可以用受限构造器 | 接口天然开放（或靠 sealed 接口收窄） |

Java 8 起接口可以有 `default` 与 `static` 方法，Java 9 起还能写 `private` 方法给 default 实现复用；Java 17 补上了 `sealed`，`sealed interface Shape permits Circle, Square {}` 配合 `switch (shape) { case Circle c -> ...; case Square s -> ...; }` 就能得到"类型分支可穷尽、新增子类时编译器提醒你补全"的效果，这是 record + sealed 组合最常见的用法（switch 模式匹配在 Java 21 转正，Java 17 里需要 `--enable-preview`）。

### equals 与 hashCode 的契约怎么落地

约定只有一句：**equals 认为相等的两个对象，hashCode 必须返回同一个整数**（反向不要求）。一旦只重写 equals，把对象放进 HashSet 或当 HashMap 的键，就会出现"contains 找不到但列表里明明有"的诡异现象，因为桶位是按 hashCode 算的。手写时三步走：先用 `instanceof` 判类型（用 `==` 比引用是快速通道）、再逐字段比较（浮点用 `Double.compare`、数组用 `Arrays.equals`）、最后把参与比较的每个字段都喂进 `Objects.hash(...)`。用 record 则这些全部自动生成，是不可变值对象最省心的写法。

## 典型应用场景

| 场景 | 推荐做法 | 为什么 |
| --- | --- | --- |
| 多个类共享代码 | 抽象类 + 继承 | 减少重复 |
| 约定能力 | 接口 | 可以多实现 |
| 同一操作不同表现 | 多态 + @Override | 调用方不需要知道具体类型 |
| 纯数据载体 | record | 自动生成 equals/hashCode/toString |

### 三种典型写法的取舍

**模板流程 + 可变步骤 → 抽象类。** 导出报表这件事，"取数、排版、写文件"的骨架固定，只有"排版"随格式变化。把骨架写进抽象类的 `final void export()`，把 `abstract void layout()` 留给 ExcelExporter、PdfExporter 各自实现，流程就不会被子类偷偷改掉。

**给既有类型贴能力标签 → 接口。** `Comparable`、`Serializable`、`AutoCloseable` 都不关心"你是什么"，只关心"你能做什么"。你自己的类只要 implements 对应接口，就能立刻接进标准库的既有机制（`sort`、序列化、try-with-resources），这是继承永远做不到的：你不能为了获得 `AutoCloseable` 就放弃已有的父类。

**只是不想重复几行代码 → 组合。** 判断标准很硬：如果子类无法通过父类全部测试，即"不是一个真正的 IS-A"，就该改成持有字段并转发。`OrderService` 需要记日志时，注入一个 `Logger` 字段远比继承 `LogBase` 好，因为后者会把日志生命周期和订单服务的生命周期绑死，测试时也换不掉。

## 代码/协议/SQL 示例

### super 的两种用法

```java
public class Base {
    protected int value = 10;
    public Base() { System.out.println("Base 构造器"); }
    public void show() { System.out.println("Base: " + value); }
}

public class Child extends Base {
    private int value = 20;
    public Child() {
        super();  // 1. 调用父类构造器
    }
    @Override
    public void show() {
        super.show();  // 2. 调用父类方法
        System.out.println("Child: " + this.value);
    }
}
```

### 多态验证

```java
Shape shape = new Circle("红色", 2);
System.out.println(shape.area());  // 运行时调用 Circle 的实现
```

### 接口组合

```java
public interface Flyable { void fly(); }
public interface Swimmable { void swim(); }

public class Duck extends Animal implements Flyable, Swimmable {
    public Duck(String name) { super(name); }
    @Override public void speak() { System.out.println(name + "嘎嘎叫"); }
    @Override public void fly() { System.out.println(name + "在飞"); }
    @Override public void swim() { System.out.println(name + "在游泳"); }
}
```

### 抽象模板：把流程锁在父类

```java
public abstract class Report {
    protected final String title;
    public Report(String title) { this.title = title; }

    public final void export() {          // final：子类不得改动流程
        String rows = fetch();
        System.out.println(layout(rows));
        save(rows);
    }

    protected abstract String fetch();
    protected abstract String layout(String rows);
    protected void save(String rows) { System.out.println("写入 " + title); }
}

public class CsvReport extends Report {
    public CsvReport(String title) { super(title); }
    @Override protected String fetch() { return "姓名,分数"; }
    @Override protected String layout(String rows) { return rows; }
}
```

### sealed 类型让分支可穷尽

```java
sealed interface Notice permits Sms, Email, Push {}

record Sms(String phone, String text) implements Notice {}
record Email(String addr, String subject) implements Notice {}
record Push(String token) implements Notice {}

static String describe(Notice n) {
    return switch (n) {                       // 少写一个 case 就编译不过
        case Sms s   -> "短信到 " + s.phone();
        case Email e -> "邮件主题 " + e.subject();
        case Push p  -> "推送到 " + p.token();
    };
}
```

### 重写与重载的对照实验

```java
class Parent { String tag() { return "父"; } }
class Kid extends Parent {
    String tag(int unused) { return "子的重载"; }   // 不是重写
    @Override String tag() { return "子"; }          // 这才是重写
}

Parent p = new Kid();
System.out.println(p.tag());          // 子：同参方法被子类覆盖
// System.out.println(p.tag(1));      // 编译失败：Parent 引用看不到Kid 新增的重载
```

## 时间/空间复杂度或性能分析

- **多态调用**：虚方法调用比静态调用慢纳秒级，JIT 会通过内联缓存优化
- **继承层次**：超过 3-4 层影响可维护性，推荐用组合替代
- **record**：和普通类性能一致，编译器生成的代码是最优实现
- **interface default 方法**：运行时解析开销可忽略

### 怎么把"多态慢一点"这件事测准

网上流传的"虚方法调用慢 10 倍"多半来自一次性测试：跑一次计时、没预热、数据规模只有一个点。可靠的口径是四步——固定 JDK 版本（记录 `java -version` 输出），固定输入规模，先空跑若干轮让 JIT 完成内联缓存，再连续跑上万次取中位数；然后把规模提高一个数量级复测一次。只有在同一版本、同一输入分布下，"100 万次 `a.speak()` 与 100 万次直接调用相差不到 5%"这类结论才可复现。把单次运行结果当成所有版本和所有规模都成立，是学习继承与多态时最容易犯的验证错误。

### 验证一段继承代码要覆盖三条路径

写完后不要只看正常流程跑通。按这张清单逐项过一遍：

- **输入路径**：传 null、传空集合、传边界值（半径 0、负数），确认父类引用调用的仍是子类实现而不是抛意外异常。
- **输出路径**：`toString`、`equals`、`hashCode` 三者是否互相一致；两个字段相同但地址不同的对象，放进 HashSet 后 `size()` 是不是 1。
- **失败路径**：子类构造器有没有漏 `super(...)`；重写方法的访问修饰符有没有收紧；把重写签名故意写错一个字母，`@Override` 是否如期报错。

抽象类与接口的差异也建议用同一段最小代码各验证一次，而不是背表格：给抽象类加一个实例字段并在子类里改它，再试着给接口加同名字段——编译器会直接告诉你接口字段只能是 `static final`，这条经验就记住了。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 子类构造器不写 super() | 父类无无参构造时编译报错 | 父类有参构造时必须显式调用 |
| 重写方法签名不一致 | 变成新方法不是重写 | 加 @Override 让编译器检查 |
| 重写 equals 不重写 hashCode | HashMap 行为异常 | 两者必须同时重写 |
| 用继承复用不相关代码 | 耦合过深 | 用组合或接口 |
| 在构造器里调用可重写方法 | 子类字段未初始化 | 构造器里只调 private/final 方法 |
| 强转前不判断类型 | ClassCastException | 用 instanceof 模式匹配 |

### 关于 equals 的一条完整反例

```java
class Book {
    String isbn;
    Book(String isbn) { this.isbn = isbn; }
    @Override public boolean equals(Object o) {
        return o instanceof Book b && b.isbn.equals(isbn);
    }
    // 故意漏掉 hashCode
}
Set<Book> shelf = new HashSet<>();
shelf.add(new Book("978-7"));
System.out.println(shelf.contains(new Book("978-7")));   // false！
System.out.println(shelf.size());                        // 1，两个对象都在集合里
```

`contains` 先用 hashCode 定位桶，没重写 hashCode 就沿用 Object 的实现（按对象身份算），新对象落到另一个空桶，连 equals 都不会被调用。补上 `@Override public int hashCode() { return isbn.hashCode(); }` 才成立。判断"该不该重写"的准绳是：**这个类会不会被放进 Set 或当 Map 的键？会就必须两个一起写。**

### 别用继承来表达"临时借一下代码"

继承一旦建立，父类的每个方法都变成你对外承诺的公共 API，将来父类改签名就是破坏你的调用方。遇到"我只想要父类那两个方法"的需求，正确顺序是：先考虑直接调用工具方法（静态方法），再考虑组合转发（持有字段并暴露自己需要的三个方法），最后才考虑抽象类。判定标准也很实在：如果你写不出"子类的每一个实例都必然是一个合法的父类实例"这句话，就不该 extends。

## 与其他知识点的关系

- **先修**：《类与对象》——继承、重写建立在类定义基础上
- **后续**：《集合框架与泛型》——排序、比较器大量使用接口和多态
- **关联**：《Lambda 与 Stream API》——函数式接口是接口思想的延伸

## 自测题与参考答案

1. **Java 为什么只支持单继承？** 避免菱形继承问题，用接口多实现弥补。
2. **抽象类和接口怎么选？** "是一种"用抽象类，"有某种能力"用接口。
3. **多态的好处？** 调用方只依赖抽象类型，新增子类不改调用方。
4. **super 有什么用途？** 调用父类构造器和父类被重写的方法。
5. **record 和普通类区别？** 自动生成 final 字段、构造器、getter、equals、hashCode、toString。

## 考点精讲

`继承、接口与多态` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据。

### 考点 1：第 1 题

- - **题目**：围绕“继承、接口与多态”中的 继承、接口、多态，下列哪两项是本课强调的实践判断？
- **正确项**：学习 继承 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 接口 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：继承和接口是面向对象设计的核心，必须通过实践来区分。

### 考点 2：第 2 题

- **题目**：`继承、接口与多态` 的示例代码用于验证 `super`，其背景是单继承、抽象类与接口、多态、equals/hashCode、record 与 enum。代码的真实内容是下面哪一项？
- **正确项**：调用了 `Circle()`
- **判断依据**：本课 Circle 类继承 Shape，构造器里使用 super(color) 调用父类构造器。

### 考点 3：第 3 题

- **题目**：抽象类与接口的关系，下面说法正确的是？
- **正确项**：抽象类可以持有状态
- **判断依据**：抽象类可以有实例字段，接口字段只能是 static final。

### 考点 4：第 4 题

- **题目**：@Override 注解的价值是？
- **正确项**：让编译器检查是否真的重写了父类/接口方法，避免拼写错误
- **判断依据**：不加 @Override 时方法名拼错会被当成新方法。

### 考点 5：第 5 题

- **题目**：父类引用指向子类对象并调用被重写的方法时，执行的是？
- **正确项**：子类的实现（运行时多态）
- **判断依据**：运行时根据对象实际类型决定调用哪个方法版本。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `单继承、抽象类与接口、多态、equals/hashCode、record 与 enum。`，这段说明是：Java 只支持单继承；``____`` 调用父类构造器或方法，`final` 修饰的类不能被继承。空缺处应填哪个术语？
- **正确项**：super
- **判断依据**：super 关键字用于子类中调用父类构造器或方法。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| extends | 子类继承父类，Java 只支持单继承 |
| abstract class | 不能被 new，可包含抽象方法 |
| interface | 约定能力的契约，可多实现 |
| @Override | 标记重写方法，编译器检查签名 |
| super | 调用父类构造器或方法 |
| record | 不可变数据快捷类 |
| 重载 | 同名不同参，编译时按形参列表选定版本 |
| sealed / permits | 限定可继承的子类名单，使 switch 分支可穷尽 |
| 组合 | 持有能力对象并转发调用，替代不合理的继承 |
| instanceof 模式匹配 | 判型与安全转型写在一起 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE 官方教程：继承](https://docs.oracle.com/javase/tutorial/java/IandI/) | 继承、接口、多态基础语法 |
| [Java SE API 文档](https://docs.oracle.com/en/java/javase/21/docs/api/) | Object 类与接口 API 查询 |
| [dev.java 学习路径](https://dev.java/learn/) | 现代 Java 官方入门教程 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：继承、接口、多态、抽象类、super、record
