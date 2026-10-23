# 类与对象

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：25 分钟

![Java 类加载与对象创建](images/diagram_java_oop.webp)

![类与对象](images/remaining_java_oop.webp)

## 本节知识框架

欢迎来到 Java 面向对象的世界！想象你在填写一份快递单——收件人姓名、地址、电话，这些就是"属性"；而"打电话通知收件人"就是一个"行为"。在 Java 里，**类**就是这张快递单的模板，**对象**就是填好内容后真正寄出去的那张单子。

**本课你将学到：**
- 用 `class` 定义模板，用构造器初始化对象
- 用 `private` / `public` 控制谁能看到和修改你的数据
- 理解 `static` 到底属于谁——是模板还是具体对象？
- 用 `enum` 替代魔法数字，让代码自己会说话

**先修要求：** 学完《控制流与方法》即可。如果你知道方法怎么定义、参数怎么传，就可以开始了。

### 复习清单

- [ ] 能说出 `class` 和 `object` 的区别，并举一个生活中的类比
- [ ] 能写一个包含 private 字段和 public getter 的最小类
- [ ] 能解释为什么 `static` 方法不能直接访问非 static 字段

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| 类（class） | 对象的模板，定义了"有哪些数据"和"能做什么事"。就像饼干的模具，本身不是饼干。 |
| 构造器 | 创建对象时自动调用的特殊方法，名字和类名一样，没有返回类型。用来给字段赋初始值。 |
| 封装 | 把数据藏起来（private），只通过方法暴露操作入口。就像自动售货机——你按按钮，不碰里面线路。 |
| static | 属于类本身而非某个对象。所有对象共享一份，用 `类名.成员` 直接访问。 |

## 原理与运行机制

### 用生活场景理解类和对象

把类想象成一张"学生信息表"的空白模板：

1. **class** — 模板本身，定义了"姓名""学号""成绩"这些栏位
2. **new** — 拿着模板去复印一张，填上具体内容，这就成了一个对象
3. **构造器** — 复印时自动帮你把日期填好的那个步骤
4. **private / public** — 哪些栏位只有老师能改（private），哪些所有人都能看（public）

### 从一个最简单的类开始

```java
public class Student {
    // 字段——对象的"属性"
    private String name;
    private int age;

    // 构造器——创建对象时自动调用
    public Student(String name, int age) {
        this.name = name;   // this 指"当前这个对象"
        this.age = age;
    }

    // 方法——对象的"行为"
    public void introduce() {
        System.out.println("我叫" + name + "，今年" + age + "岁");
    }
}
```

使用时：

```java
Student s = new Student("小明", 18);
s.introduce();  // 输出：我叫小明，今年18岁
```

### 封装：保护你的数据

为什么要把字段设成 `private`？打个比方：银行不会让你直接进金库改数字，你得通过柜台（方法）来操作。这样银行可以在柜台加上"余额不能为负"的校验。

```java
public class BankAccount {
    private double balance;  // 外面不能直接碰

    public BankAccount(double initial) {
        if (initial < 0) throw new IllegalArgumentException("初始余额不能为负");
        this.balance = initial;
    }

    public double getBalance() {       // 只能看
        return balance;
    }

    public void deposit(double amount) {
        if (amount <= 0) throw new IllegalArgumentException("存款金额必须为正");
        this.balance += amount;
    }
}
```

### static：属于类，不属于某个对象

```java
public class MathHelper {
    public static int max(int a, int b) {   // static：不需要 new
        return a > b ? a : b;
    }
}

// 直接用类名调用
int result = MathHelper.max(3, 7);  // 7
```

`static` 字段所有对象共享一份，改一个全都变。`static` 方法不能访问非 `static` 成员——因为方法执行时可能根本还没有任何对象存在。

### 初始化顺序

对象创建时，Java 按这个顺序赋值：

```text
1. 父类 static 字段       （只加载一次）
2. 本类 static 字段       （只加载一次）
3. 父类实例字段 + 构造器
4. 本类实例字段 + 构造器
```

记住口诀：**先静态后实例，先父类后子类**。

### enum：让常量自己说话

```java
// 不好的写法——魔法数字
int status = 0;  // 0 是什么意思？谁知道呢

// 好的写法——enum
public enum OrderStatus {
    PENDING, PAID, SHIPPED, DONE
}

OrderStatus s = OrderStatus.PAID;
if (s == OrderStatus.PAID) {
    System.out.println("已付款，准备发货");
}
```

enum 的好处：编译器能检查拼写错误、switch 能检查遗漏、调试时打印名字而不是数字。

## 典型应用场景

| 场景 | 推荐做法 | 为什么 |
| --- | --- | --- |
| 描述现实世界的事物 | 定义 class + private 字段 | 数据和行为绑定在一起 |
| 固定取值范围 | 用 enum | 编译器帮你检查，调试友好 |
| 全局共享的工具方法 | static 方法 | 不需要创建对象就能调用 |
| 保护数据完整性 | private 字段 + public getter/setter | 在 setter 里加校验逻辑 |

## 代码/协议/SQL 示例

### 最小可验证示例

```java
public class Account {
    private final String owner;
    private double balance;
    private static int count = 0;

    public Account(String owner, double balance) {
        this.owner = owner;
        this.balance = balance;
        count++;
    }

    public void deposit(double amount) {
        if (amount <= 0) throw new IllegalArgumentException("金额必须为正");
        balance += amount;
    }

    public double getBalance() { return balance; }
    public static int getCount() { return count; }
}
```

### 不可变对象

```java
public final class Money {
    private final int cents;

    public Money(int cents) {
        if (cents < 0) throw new IllegalArgumentException("金额不能为负");
        this.cents = cents;
    }

    public Money add(Money other) {
        return new Money(this.cents + other.cents);
    }

    public int getCents() { return cents; }
}
```

不可变对象的好处：线程安全（不用加锁）、可以安全做 HashMap 的 key、不用担心被别人偷偷改掉。

### 练习：简易计数器

```java
public class Counter {
    private static int total = 0;
    private int id;

    public Counter() {
        total++;
        this.id = total;
    }

    public static int getTotal() { return total; }
    public int getId() { return id; }
}
```

## 时间/空间复杂度或性能分析

- **对象创建**：`new` 一个对象大约几十纳秒，非常轻量。但如果循环里反复创建大对象，GC 压力会上升。
- **static vs 实例**：static 字段只有一份，内存省；实例字段每个对象一份。
- **final 字段**：JIT 编译器可以对 final 字段做内联优化，访问更快。
- **enum**：本质是 static final 实例，启动时创建，运行时零开销。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 直接 `obj.field` 访问 public 字段 | 数据被外部随意修改 | 用 private + getter/setter |
| 在 static 方法里用 this | 编译报错 | static 不属于任何对象，没有 this |
| 构造器里写返回类型 | 变成普通方法，不是构造器 | 构造器没有返回类型 |
| 用 `==` 比较对象内容 | 比较的是引用地址 | 用 `equals()` |
| 忘记写无参构造器 | 编译器默认生成，但写了有参构造后就不再自动生成 | 需要时显式写出来 |
| enum 用 int 常量替代 | 丢失类型安全和调试信息 | 始终用 enum 表示固定集合 |
| 在构造器里调用可被重写的方法 | 子类字段可能还没初始化 | 构造器里只调 private 或 final 方法 |

## 与其他知识点的关系

- **先修**：《控制流与方法》——本课的方法定义、参数传递都建立在前课基础上
- **后续**：《继承、接口与多态》——类定义好之后，下一步就是让类之间产生关系
- **关联**：《变量、类型与字符串》——String 的不可变性就是本课不可变对象思想的典型应用

## 自测题与参考答案

> 先独立作答，再对照参考答案。

1. **类和对象是什么关系？** 类是模板，对象是根据模板创建的具体实例。一个类可以 new 出多个对象。
2. **为什么要封装？** 保护数据不被外部随意修改，在方法入口加校验逻辑，让代码更健壮。
3. **static 方法能不能访问非 static 字段？** 不能。static 方法属于类，执行时可能还没有任何对象存在。
4. **enum 比 int 常量好在哪？** 类型安全、编译器检查拼写、switch 能查漏、调试打印名字而非数字。
5. **不可变对象有什么好处？** 线程安全、可做 Map 的 key、不用担心被外部修改。

## 考点精讲

`类与对象` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据。

### 考点 1：第 1 题

- **题目**：被 private 修饰的字段可以从哪里访问？
- **正确项**：只能在定义它的类内部访问
- **判断依据**：private 是最严格的访问级别，只允许类内部的方法访问，子类和其他类都不行。

### 考点 2：第 2 题

- - **题目**：围绕“类与对象”中的 class、构造器、封装，下列哪两项是本课强调的实践判断？
- **正确项**：验证封装时要通过 public 方法操作对象，观察内部状态是否受保护；学习 class 时要动手 new 出对象并观察字段初始化顺序
- **判断依据**：面向对象的核心是封装和行为绑定，必须通过实际操作对象来验证。

### 考点 3：第 3 题

- **题目**：不可变对象的主要优势是？
- **正确项**：天然线程安全，可安全共享
- **判断依据**：不可变对象创建后状态不再改变，天然线程安全，hashCode 稳定，适合做 HashMap 的 key。

### 考点 4：第 4 题

- **题目**：阅读 `类与对象` 的 `String` 示例。它服务于构造器、封装与访问控制、static、初始化顺序与不可变对象。代码中实际包含下列哪一项？
- **正确项**：调用了 `getBalance()`
- **判断依据**：本课封装示例中 BankAccount 类包含 `getBalance()` 方法，用于返回 private balance 字段。

### 考点 5：第 5 题

- **题目**：用 enum 替代 int 常量的好处是？
- **正确项**：类型安全，可读性好
- **判断依据**：enum 在编译期就能发现类型错误，switch 能检查遗漏，调试时打印名字而不是数字。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `构造器、封装与访问控制、static、初始化顺序与不可变对象。`，这段说明是：`____`负责保护数据，接口负责约定能力。空缺处应填哪个术语？
- **正确项**：封装
- **判断依据**：封装通过 private 字段 + public 方法来保护数据，接口通过方法签名约定对象的能力。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| class | 对象的模板，定义属性和行为 |
| 构造器 | 创建对象时自动调用，名字和类名相同 |
| private | 只允许类内部访问，外部不能直接碰 |
| static | 属于类本身，所有对象共享一份 |
| enum | 用命名常量替代魔法数字，类型安全 |
| 不可变对象 | 创建后状态不能改，线程安全 |

## 参考资料与复核

- [本课资料锚点 java_oop](https://zh.wikipedia.org/w/index.php?search=java_oop)

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE 官方教程：类和对象](https://docs.oracle.com/javase/tutorial/java/javaOO/) | 类、对象、封装的基础语法 |
| [Java SE API 文档](https://docs.oracle.com/en/java/javase/21/docs/api/) | 标准库 API 查询 |
| [dev.java 学习路径](https://dev.java/learn/) | 现代 Java 官方入门教程 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：class、构造器、封装、static、enum、不可变对象
