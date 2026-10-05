# 控制流与方法

![控制流与方法](images/remaining_java_control_methods.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：14 分钟

## 学习目标

- 能用自己的话解释「控制流与方法」解决了什么问题，而不是只背术语。
- 能说清 「if」、「switch」、「for」、「重载」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Java」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：分支循环、方法重载、可变参数与「只有值传递」的本质。

## 前置知识

- 先完成上一课《变量、类型与字符串》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：if、switch、for。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 分支与循环

```java
int score = 78;
if (score >= 90) {
    System.out.println("优秀");
} else if (score >= 60) {
    System.out.println("及格");
} else {
    System.out.println("不及格");
}

switch (score / 10) {
    case 10, 9 -> System.out.println("A");     // 箭头语法不会有贯穿问题
    case 8 -> System.out.println("B");
    default -> System.out.println("C");
}

for (int i = 0; i < 5; i++) { }
for (String name : names) { }                  // 增强 for
while (condition) { }
do { } while (condition);                      // 至少执行一次
```

用 `break` 跳出、`continue` 跳过本轮；带标签的 `break outer;` 可以跳出多层循环。

## 方法定义与重载

```java
public static int add(int a, int b) {
    return a + b;
}

public static double add(double a, double b) {   // 重载：参数列表不同
    return a + b;
}

public static int sum(int... numbers) {           // 可变参数
    int total = 0;
    for (int n : numbers) total += n;
    return total;
}

public static void printAll(String... names) { }
```

重载只看方法名 + 参数列表，与返回值无关；可变参数必须是最后一个参数。

## 值传递

Java **只有值传递**：基本类型传副本，对象传的是引用的副本。

```java
static void change(int x) { x = 100; }              // 不影响调用方

static void addItem(List<String> list) {
    list.add("new");                                // 修改对象内容：有效
}

static void reassign(List<String> list) {
    list = new ArrayList<>();                       // 重新赋值引用：无效
}
```

## 方法设计建议

1. 一个方法只做一件事，命名用动词短语。
2. 参数不超过 4 个，过多时封装成对象。
3. 尽早返回，减少嵌套层级。
4. 用 `@Override`、`final`、`private` 表达意图。

## 本课小结
控制流决定逻辑走向，方法决定复用粒度。牢记「Java 只有值传递，但对象内容是共享的」，能避免大量误解。


## 控制流速查

| 结构 | 写法 | 注意 |
| --- | --- | --- |
| `if / else if / else` | 条件分支 | 条件必须是 `boolean` |
| `switch` 语句 | 传统分支 | 别忘 `break`，否则穿透 |
| `switch` 表达式 | `case X -> value;` | Java 14+，无穿透且可赋值 |
| `for` | 计次循环 | 注意边界 `i < n` |
| 增强 `for` | `for (String s : list)` | 遍历中不能改集合结构 |
| `while` / `do...while` | 条件循环 | `do...while` 至少执行一次 |
| 标签 + `break` | `break outer;` | 跳出多层循环 |
| `continue` | 跳过本次 | 配合条件过滤 |
| `try / catch / finally` | 异常处理 | 见异常章节 |

```java
// switch 表达式：直接返回值，编译期检查是否覆盖所有分支
String level = switch (score / 10) {
    case 10, 9 -> "优秀";
    case 8 -> "良好";
    case 7 -> "中等";
    default -> "需努力";
};

// 需要多行逻辑时用 yield 返回值
int fee = switch (type) {
    case "vip" -> 0;
    case "normal" -> {
        int base = 10;
        yield base * 2;
    }
    default -> throw new IllegalArgumentException("未知类型：" + type);
};
```

## 方法速查

| 概念 | 规则 |
| --- | --- |
| 重载（Overload） | 同名不同参数列表，返回值不参与判断 |
| 重写（Override） | 子类重新实现父类方法，签名一致 |
| 参数传递 | Java 只有值传递，对象传的是引用的副本 |
| 可变参数 | `int... nums` 必须是最后一个参数 |
| 默认值 | Java 不支持默认参数，用重载或建造者替代 |
| 返回值 | 所有分支都要有返回，或用 `throw` |
| `static` 方法 | 属于类，不能用实例成员 |
| `final` 参数 | 方法内不能重新赋值 |

```java
// 用重载替代默认参数
public void log(String msg) {
    log(msg, false);
}

public void log(String msg, boolean verbose) {
    System.out.println(verbose ? "[DEBUG] " + msg : msg);
}

// 可变参数 + 边界校验
public int sum(int first, int... rest) {
    int total = first;
    for (int n : rest) {
        total += n;
    }
    return total;
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `switch` 忘记 `break` | 穿透执行后续分支 | 用 `->` 表达式或补 `break` |
| 遍历 List 时 `list.remove(x)` | `ConcurrentModificationException` | 用 `removeIf` 或迭代器 |
| 用 `==` 比较字符串 | 结果不可靠 | 用 `equals` |
| 方法写了返回值却有分支没 `return` | 编译错误 | 所有路径都要返回或抛异常 |
| 重载只看返回值不同 | 编译错误：方法重复定义 | 重载必须参数列表不同 |
| 可变参数前面再加普通参数顺序错 | 编译错误 | 可变参数必须在最后 |
| `for (int i = 0; i <= list.size(); i++)` | `IndexOutOfBoundsException` | 用 `<` 或增强 `for` |
| 循环里修改 `i` 造成跳步 | 漏处理元素 | 让循环变量只由一个地方推进 |
| 用浮点数做循环判断 | 死循环或次数不对 | 用整数计数 |
| `while (true)` 没有退出条件 | 程序卡死 | 明确退出条件或 `break` |

## 自测清单

- [ ] 会用 `switch` 表达式和 `yield`。
- [ ] 知道重载与重写的区别。
- [ ] 明白 Java 只有值传递。
- [ ] 可变参数放在参数列表最后。
- [ ] 遍历集合时不在循环里结构性修改。


## 零基础详解：分支、循环与方法

### 一句话说清它是什么

方法把逻辑打包并命名，分支处理不同情况，循环重复执行。
Java 的方法**必须写在类里面**，这是它和 C 系语言最直观的差别。

### 分支：`if` 与 `switch` 的分工

| 场景 | 推荐 | 原因 |
| --- | --- | --- |
| 范围判断（分数段、金额区间） | `if / else if` | 天然支持范围与组合条件 |
| 对固定值分流（枚举、状态码） | `switch` | 结构清晰、编译器能查漏 |
| 少数几个分支 | 三元运算符 `? :` | 一行写完，但别嵌套 |

```java
// 传统 switch
switch (day) {
    case 1: System.out.println("周一"); break;
    case 2: System.out.println("周二"); break;
    default: System.out.println("其它");
}

// 新式 switch 表达式：不会穿透，还能直接赋值
String type = switch (day) {
    case 1, 2, 3, 4, 5 -> "工作日";
    case 6, 7 -> "周末";
    default -> throw new IllegalArgumentException("非法日期");
};
```

### 循环三兄弟

| 循环 | 适合场景 | 注意 |
| --- | --- | --- |
| `for` | 次数明确、遍历数组 | 最常用 |
| 增强 `for` | 遍历集合/数组，不需要下标 | 不能边遍历边删元素 |
| `while` | 条件驱动，可能一次都不执行 | 别忘更新条件变量 |
| `do...while` | 至少执行一次 | 例如重试输入 |

```java
for (int i = 0; i < 3; i++) System.out.println(i);

int[] nums = {1, 2, 3};
for (int n : nums) System.out.println(n);

int n = 0;
while (n < 3) { System.out.println(n); n++; }
```

### 方法签名：每一部分都有用

```java
public static int add(int a, int b) { return a + b; }
//  |      |      |    |        |
//  |      |      |    |        └─ 参数列表
//  |      |      |    └────────── 返回类型
//  |      |      └─────────────── 方法名
//  |      └────────────────────── static：属于类，不需要 new
//  └───────────────────────────── 访问修饰符
```

### 方法重载：同名不同参

```java
int add(int a, int b) { return a + b; }
double add(double a, double b) { return a + b; }
int add(int a, int b, int c) { return a + b + c; }
```

判定依据只有**方法名 + 参数列表**；只改返回类型不算重载，编译不过。

### Java 只有值传递

这是最容易被绕晕的点：**Java 传的永远是值的副本**，只不过引用类型复制的是「地址」。

```java
void change(int x) { x = 99; }              // 外面不变
void change(int[] arr) { arr[0] = 99; }     // 外面会变，因为改的是堆里同一个数组
```

记忆方法：**改副本本身无效，改副本指向的对象有效。**

### 可变参数

```java
int sum(int... nums) {          // 调用时可以传 0 个或多个
    int total = 0;
    for (int n : nums) total += n;
    return total;
}
sum();                // 0
sum(1, 2, 3);         // 6
```

可变参数必须放在参数列表最后，一个方法只能有一个。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `if (a = b)` | 编译报错或逻辑错 | 比较写 `==` |
| 循环里删集合元素 | `ConcurrentModificationException` | 用 `Iterator.remove()` 或 `removeIf` |
| 增强 `for` 里改数组 | 改了副本没效果 | 需要下标时用普通 `for` |
| 递归无终止条件 | `StackOverflowError` | 先写出口 |
| 方法名相同但只有返回类型不同 | 编译错误 | 改参数列表 |
| 方法太长 | 难测试难复用 | 按单一职责拆分 |
| 忽略返回值 | 以为对象被改了 | 接收返回值或改用可变对象 |

### 手把手练习：数字猜谜 + 素数统计

```java
public class Demo {
    static boolean isPrime(int n) {
        if (n < 2) return false;
        for (int d = 2; d * d <= n; d++) {
            if (n % d == 0) return false;
        }
        return true;
    }

    static int countPrimes(int limit) {
        int count = 0;
        for (int i = 2; i <= limit; i++) {
            if (isPrime(i)) count++;
        }
        return count;
    }

    public static void main(String[] args) {
        System.out.println("100 以内素数有 " + countPrimes(100) + " 个");
    }
}
```

### 学完自测

- [ ] 能说出新式 `switch` 表达式相比传统写法的两个好处。
- [ ] 能解释为什么增强 `for` 里删除元素会抛异常。
- [ ] 能说清「Java 只有值传递」这句话的含义。
- [ ] 能写出一个用可变参数求和的静态方法。
- [ ] 知道方法重载的判定依据是什么。

## 动手练习


> 本课练习重点：围绕「if、switch、for」完成复述、实验和交付，每个结果都要能被别人检查。

先跑通最小类与测试，再补异常和并发边界，最后观察线程与资源变化。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「控制流与方法」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「switch」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小类，补一个普通测试和一个边界输入测试。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「if」和「switch」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Java 的参数传递方式是？

- **正确判断**：全部值传递
- **判断依据**：Java 只有值传递：对象传递的是引用的副本，所以能改对象内容，但重新赋值引用不影响调用方。其他选项：Java 只有值传递：对象传的是引用的副本，所以「对象按引用传递」是常见误说。正确项「全部值传递」描述正确，能够解释题干场景中的现象与结果。错误项「全部引用传递」与课程给出的定义相冲突，不能回答题目所问。错误项「由编译器决定」只看到了表面现象，没有解释题干真正考查的机制。错误项「基本类型值传递、对象引用传递」适用于其他场景，但与本题的前提不匹配。把题干「Java 的参数传递方式是？」放回《控制流与方法》的「分支循环、方法重载、可变参数与「只有值传递」的本质」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：可变参数（int... nums）必须放在？

- **正确判断**：参数列表最后
- **判断依据**：可变参数必须是最后一个参数，一个方法最多只有一个。其他选项：可变参数必须是参数列表最后一个，否则编译器无法判断参数边界。正确项「参数列表最后」抓住了题干的核心条件，是经得起边界检验的表述。错误项「方法名前面」与课程给出的定义相冲突，不能回答题目所问。错误项「任意位置」只看到了表面现象，没有解释题干真正考查的机制。错误项「参数列表最前面」在边界或失败路径上会得出错误结果。把题干「可变参数（int... nums）必须放在？」放回《控制流与方法》的「分支循环、方法重载、可变参数与「只有值传递」的本质」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：方法重载的判定依据是？

- **正确判断**：方法名 + 参数列表
- **判断依据**：重载只看方法名和参数列表，返回值不同不构成重载。其他选项：重载只看方法名与参数列表。返回值类型与访问修饰符不同并不构成重载。正确项「方法名 + 参数列表」与本课示例和结论一致，可以直接用于实际编码。错误项「是否 static」在边界或失败路径上会得出错误结果。把题干「方法重载的判定依据是？」放回《控制流与方法》的「分支循环、方法重载、可变参数与「只有值传递」的本质」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：Java 14+ 的 switch 表达式相比传统 switch 的优势是？

- **正确判断**：用 -> 避免 case 穿透
- **判断依据**：多分支用 yield 返回值，编译期还能检查是否覆盖所有枚举常量。其他选项：switch 表达式不能做范围判断，也仍需覆盖必要分支。它的价值是避免穿透并可直接返回值。正确项「用 -> 避免 case 穿透」与本课示例和结论一致，可以直接用于实际编码。错误项「支持字符串以外的任意类型」只看到了表面现象，没有解释题干真正考查的机制。错误项「可以替代 if-else 的范围判断」在边界或失败路径上会得出错误结果。错误项「不再需要 default 分支」把因果关系颠倒了，不能作为正确结论。把题干「Java 14+ 的 switch 表达式相比传统 switch 的优势是？」放回《控制流与方法》的「分支循环、方法重载、可变参数与「只有值传递」的本质」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：带标签的 break（break outer;）的作用是？

- **正确判断**：跳出被标记的外层循环
- **判断依据**：嵌套循环中需要一次性退出时要靠标签，但多数情况可重构为提取方法 + return。其他选项：标签 break 用于跳出多层嵌套循环，与 switch、方法返回、异常都无关。正确项「跳出被标记的外层循环」既符合定义也满足题干限定的场景，因此应当选择。错误项「跳出方法」把因果关系颠倒了，不能作为正确结论。错误项「抛出异常」忽略了题目中的限制条件，因此不成立。错误项「跳出 switch」属于相邻主题的说法，范围与本题要求不一致。把题干「带标签的 break（break outer;）的作用是？」放回《控制流与方法》的「分支循环、方法重载、可变参数与「只有值传递」的本质」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Java 的参数传递方式是？」的判断依据。
- [ ] 不看解析，能说出「可变参数（int... nums）必须放在？」的判断依据。
- [ ] 不看解析，能说出「方法重载的判定依据是？」的判断依据。
- [ ] 不看解析，能说出「Java 14+ 的 switch 表达式相比传统 switch 的优势是？」的判断依据。
- [ ] 不看解析，能说出「带标签的 break（break outer;）的作用是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Control Flow & Methods

**Summary:** Branches, loops, overloads, varargs and pass-by-value.

**Category:** Java  
**Level:** 基础  
**Key terms:** if, switch, for, 重载, 可变参数, 值传递

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Java 21+ / Maven 或 Gradle
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：if、switch、for、重载、可变参数、值传递
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE API](https://docs.oracle.com/en/java/javase/) | 语言、标准库与 JVM |
| [dev.java](https://dev.java/learn/) | 现代 Java 官方教程 |

> 本课主题：分支循环、方法重载、可变参数与「只有值传递」的本质。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

