# 控制流与方法

![Java 分支、循环与方法](images/diagram_java_control.webp)

![控制流与方法](images/remaining_java_control_methods.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：40 分钟

## 学习目标

- 能用自己的话解释控制流与方法解决了什么问题，而不是只背术语。
- 能说清 「if」、「switch」、「for」、「重载」 之间的关系，并分别举出一个例子。
- 能把 if 放回「控制流与方法」的知识体系，说明它和 switch 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：分支循环、方法重载、可变参数与「只有值传递」的本质。

## 前置知识

- 先完成上一课《变量、类型与字符串》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：基础。建议先完成「变量、类型与字符串」，或确认自己能独立跑通正文里的 IllegalArgumentException 示例。
- 开始前先复习：if、switch、for。
- 卡在 if 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

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

## 常见错误与排查

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

## 复习与自测

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

为 IllegalArgumentException 写一个可运行的最小对象，再补线程安全的用例。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 控制流与方法解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「switch」是什么关系？

验收标准：说明 if 与 switch 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「分支与循环」小节做一次五步记录，原例取自 IllegalArgumentException，改动只允许动一处if，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小类，补一个普通测试和一个边界输入测试。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「if」和「switch」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

本节围绕控制流与方法安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「控制流与方法」的结构，画完再对照骨架：

- 主干：分支与循环 → 方法定义与重载 → 值传递 → 方法设计建议
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明if与switch的关系？

### 任务 2：做一次对比实验

**验收标准**：对照表里只能用 IllegalArgumentException 这类可观察的指标做结论，并给出switch从优到劣的转折条件。

### 任务 3：迁移到自己的场景

**验收标准**：把自己的判断写成可检查的形式——输入、步骤、输出、差异各一条，其中输入必须包含 if。

## 故障现场

### 现场 1：switch 忘记 break

**症状**：在《控制流与方法》的复现场景中，穿透执行后续分支。

**根因**：当出现“switch 忘记 break”时，执行路径已经绕过了《控制流与方法》的关键约束，最终以“穿透执行后续分支”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《控制流与方法》的问题，用 -> 表达式或补 break。

**验证**：在《控制流与方法》中按“用 -> 表达式或补 break”调整后，从“switch 忘记 break”的触发条件重放同一条路径，确认“穿透执行后续分支”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：遍历 List 时 list.remove(x)

**症状**：在《控制流与方法》的复现场景中，ConcurrentModificationException。

**根因**：触发点是把“遍历 List 时 list.remove(x)”当成安全做法。它没有满足《控制流与方法》要求的前提，因此先表现为“ConcurrentModificationException”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《控制流与方法》的问题，用 removeIf 或迭代器。

**验证**：在《控制流与方法》中按“用 removeIf 或迭代器”调整后，从“遍历 List 时 list.remove(x)”的触发条件重放同一条路径，确认“ConcurrentModificationException”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 3：重载只看返回值不同

**症状**：在《控制流与方法》的复现场景中，编译错误：方法重复定义。

**根因**：触发点是把“重载只看返回值不同”当成安全做法。它没有满足《控制流与方法》要求的前提，因此先表现为“编译错误：方法重复定义”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《控制流与方法》的问题，重载必须参数列表不同。

**验证**：在《控制流与方法》中按“重载必须参数列表不同”调整后，从“重载只看返回值不同”的触发条件重放同一条路径，确认“编译错误：方法重复定义”不再出现，并补一个相邻边界用例检查没有引入新问题。

## 版本与时效

- 先确认运行环境是 Java 21 还是 25，再决定 IllegalArgumentException 能否使用新语法。
- 升级收益集中在并发与内存模型；switch 相关代码需要单独回归。
- 升级「控制流与方法」涉及的依赖前，先用 IllegalArgumentException 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 IllegalArgumentException 记录构建与运行结果。
- 先回归 if 与 switch 的默认行为和错误信息，再扩大测试范围。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 if 的版本变化。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Java 的参数传递方式是？」的判断依据。
- [ ] 不看解析，能说出「可变参数（int... nums）必须放在？」的判断依据。
- [ ] 不看解析，能说出「方法重载的判定依据是？」的判断依据。
- [ ] 不看解析，能说出「Java 14+ 的 switch 表达式相比传统 switch 的优势是？」的判断依据。
- [ ] 不看解析，能说出「带标签的 break（break outer;）的作用是？」的判断依据。
- [ ] 用 if 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `break` | 用 `break` 跳出、`continue` 跳过本轮；带标签的 `break outer;` 可以跳出多层循环。 |
| `final` | 用 `@Override`、`final`、`private` 表达意图。 |
| `可变参数` | int sum(int... nums) { // 调用时可以传 0 个或多个。 |
| `值传递` | Java 只有值传递：基本类型传副本，对象传的是引用的副本。 |

## 考点精讲

### 考点 1：多选辨析·if

- **题目**：围绕“控制流与方法”中的 if、switch、for，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把控制流与方法拆成概念、示例与故障现场三部分，因此判断 if 时必须同时交代输入、输出和失败路径，这使“学习 if 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在控制流与方法里，判断 switch 时要固定版本与边界输入，所以“验证 switch 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·if

- **题目**：可变参数（int... nums）必须放在？
- **判断依据**：可变参数必须是最后一个参数，一个方法最多只有一个。其他选项：可变参数必须是参数列表最后一个，否则编译器无法判断参数边界。在「控制流与方法」里判断这道题，要把if、switch、for的条件、过程与失败路径逐项对齐，换成“可变参数（int... nums）必”这个场景，只有满足前提的结论才成立。

### 考点 3：概念判断·if

- **题目**：方法重载的判定依据是？
- **判断依据**：重载只看方法名和参数列表，返回值不同不构成重载。在「控制流与方法」里，作答时，先用if建立输入与输出的基线，再把方法名 + 参数列表代入边界条件核对，结论才能复现。在「控制流与方法」里，如果只凭关键词作答，很容易把「访问修饰符」、「是否 static」与「方法名 + 参数列表」混在一起；

### 考点 4：代码补全·if

- **题目**：阅读「控制流与方法」正文里的这段 Java 代码，下面哪一项判断是正确的？
- **判断依据**：在「控制流与方法」里，题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「控制流与方法」里封装边界决定if从哪一步开始生效。把输入或边界换成空值、极值或失败情况后，结论要以「控制流与方法」的实际运行结果为准。把“这段代码把主要逻辑封装在函数或方法里”代回「控制流与方法」里“阅读控制流与方法正文里的这段 Java 代码”的例子核对，条件一旦改变，结论就要用if、switch、for重新推导。

### 考点 5：概念判断·if

- **题目**：带标签的 break（break outer;）的作用是？
- **判断依据**：在「控制流与方法」里，跳出被标记的外层循环。嵌套循环中需要一次性退出时要靠标签，但多数情况可重构为提取方法 + return。「控制流与方法」要求先交代if、switch、for的前提再下结论，所以“跳出被标记的外层循环”只在题干“带标签的 break（break outer;）的作用是”给定的条件下成立。

### 考点 6：填空·if

- **题目**：补全代码：「控制流与方法」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____ -> System.out.println("C");`
- **判断依据**：回到「控制流与方法」的正文示例，用“补全代码”走一遍if、switch、for的完整流程，能复现的结论才可以保留。「控制流与方法」要求先交代if、switch、for的前提再下结论，所以“default”只在题干“控制流与方法示例中”给定的条件下成立。回到正文示例，用“default”走一遍if、switch、for的完整流程，能复现的结论才可以保留。

## English Overview

**Title:** Control Flow & Methods

**Summary:** Branches, loops, overloads, varargs and pass-by-value.

**Category:** Java
**Level:** 基础
**Key terms:** if, switch, for, 重载, 可变参数, 值传递

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Java 21+ / Maven 或 Gradle
；本课聚焦 if。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：if、switch、for、重载、可变参数、值传递
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Gradle 文档](https://docs.gradle.org/current/userguide/userguide.html) | 构建脚本与依赖管理 |
| [Java SE API](https://docs.oracle.com/en/java/javase/21/docs/api/) | 标准库 API |
| [Java 并发教程](https://docs.oracle.com/javase/tutorial/essential/concurrency/) | 线程、同步与并发工具 |

> 「控制流与方法」的链接用于离线阅读后的延伸核对；App 不会自动联网。
