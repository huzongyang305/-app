## 零基础详解：类、对象、封装与接口

### 一句话说清它是什么

Java 是纯面向对象语言：**所有代码都写在类里**。
类是模板，对象是实例；封装负责保护数据，接口负责约定能力。

### 用生活比喻理解

| 概念 | 比喻 | 代码 |
| --- | --- | --- |
| 类 | 图纸 | `class User {}` |
| 对象 | 造出来的实物 | `new User()` |
| 字段 | 内部零件 | `private String name;` |
| 方法 | 对外提供的操作 | `public String getName()` |
| 封装 | 外壳，不让人随便拆 | `private` + 公开方法 |
| 接口 | 岗位说明书 | `interface Payable {}` |

### 逐行拆解第一个类

```java
public class Account {
    private double balance;                 // 私有字段，外部不能直接改

    public Account(double initial) {        // 构造方法，与类同名，无返回值
        if (initial < 0) throw new IllegalArgumentException("初始金额不能为负");
        this.balance = initial;             // this 区分字段与参数
    }

    public double getBalance() {            // 只读访问
        return balance;
    }

    public void deposit(double amount) {    // 通过方法修改，才能校验
        if (amount <= 0) throw new IllegalArgumentException("金额必须为正");
        balance += amount;
    }

    @Override
    public String toString() {              // 打印对象时的文本
        return "Account(balance=%.2f)".formatted(balance);
    }
}
```

| 关键字 | 作用 |
| --- | --- |
| `private` | 只有本类能访问，是封装的基础 |
| `this` | 指向当前对象，用来区分同名字段与参数 |
| `@Override` | 声明「我在重写父类方法」，写错编译器会提醒 |
| `static` | 属于类而不是对象，如工具方法 |

### 四种访问修饰符

| 修饰符 | 本类 | 同包 | 子类 | 其它包 |
| --- | --- | --- | --- | --- |
| `private` | 是 | 否 | 否 | 否 |
| 默认（不写） | 是 | 是 | 否 | 否 |
| `protected` | 是 | 是 | 是 | 否 |
| `public` | 是 | 是 | 是 | 是 |

经验法则：**字段一律 `private`，方法尽量收窄，只有对外 API 才 `public`。**

### 接口与抽象类怎么选

| 对比 | 接口 `interface` | 抽象类 `abstract class` |
| --- | --- | --- |
| 表达 | 「能做什么」能力约定 | 「是什么」的公共部分 |
| 多继承 | 一个类可实现多个接口 | 只能继承一个 |
| 字段 | 只能是常量 | 可以有实例字段 |
| 方法 | 抽象方法 + 默认方法 | 抽象方法 + 普通方法 |
| 何时用 | 需要跨类型统一能力 | 需要共享实现与状态 |

```java
interface Payable {
    double amount();                       // 隐含 public abstract
}

class Order implements Payable {
    private final double total;
    Order(double total) { this.total = total; }
    @Override public double amount() { return total; }
}
```

### 三个必须记住的「Java 惯例」

1. **字段私有、通过方法访问**，需要改数据时在方法里校验。
2. **继承用于「是一种」**，只是为了复用代码就用组合。
3. **面向接口编程**：变量类型写接口，实例写具体类，方便替换与测试。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 字段公开 | 外部随意改，难以排查 | 改 `private` + 方法 |
| 构造方法写返回类型 | 变成普通方法 | 构造方法不能有返回类型 |
| 忘了 `new` | 空引用 `NullPointerException` | `Account a = new Account(0);` |
| 用 `==` 比较对象 | 比的是地址 | 重写 `equals` 或按业务键比较 |
| 忘了 `@Override` | 拼错方法名变成新方法 | 加上注解让编译器检查 |
| 继承层次过深 | 牵一发动全身 | 优先组合 |
| 静态方法里用实例字段 | 编译错误 | 静态方法只能访问静态成员 |

### 手把手练习：图书与借阅

```java
interface Borrowable {
    boolean borrow();
    void giveBack();
}

class Book implements Borrowable {
    private final String title;
    private boolean borrowed = false;

    Book(String title) { this.title = title; }

    @Override
    public boolean borrow() {
        if (borrowed) return false;
        borrowed = true;
        return true;
    }

    @Override
    public void giveBack() { borrowed = false; }

    @Override
    public String toString() {
        return title + (borrowed ? "（已借出）" : "（在架）");
    }
}

public class Library {
    public static void main(String[] args) {
        Borrowable item = new Book("Java 编程思想");
        System.out.println(item.borrow());     // true
        System.out.println(item.borrow());     // false
        System.out.println(item);
    }
}
```

### 学完自测

- [ ] 能说出类与对象的区别。
- [ ] 能解释封装为什么要求字段私有。
- [ ] 能说出接口与抽象类的三点差别。
- [ ] 知道 `@Override` 帮你避免什么错误。
- [ ] 能判断一个场景该用继承还是组合。
