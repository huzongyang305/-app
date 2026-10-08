# 环境与 JVM

![JDK JRE JVM 与字节码](images/diagram_java_runtime.webp)

![环境与 JVM](images/remaining_java_basics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：50 分钟

## 本节知识框架

**课程定位**：所属分类为「Java」，课程主题为「环境与 JVM」，学习阶段为「基础」，建议用时 50 分钟。

**本课要解决的主问题**：JDK/JRE/JVM 区别、编译运行、包与类路径、JIT 与 GC。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「环境与 JVM」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「环境与 JVM」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Java」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：没有硬性先修课；仍建议先具备本分类的基础阅读与操作能力。

**学习位置**：本课位于《Java 方法入门》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《变量、类型与字符串》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释环境与 JVM解决了什么问题，而不是只背术语。
- 能说清 「Java」、「JVM」、「JDK」、「javac」 之间的关系，并分别举出一个例子。
- 能把 Java 放回「环境与 JVM」的知识体系，说明它和 JVM 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：JDK/JRE/JVM 区别、编译运行、包与类路径、JIT 与 GC。

**教材衔接：前置知识**

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查 Java 的词条。
- 本课阶段：基础。建议先掌握同一分类的基础课程，并能独立运行正文里的 nextLine 示例。
- 开始前先复习：Java、JVM、JDK。
- 卡在 Java 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。

**教材衔接：本课小结**

JDK 提供工具、JVM 负责执行、字节码保证跨平台。理解类加载与 JIT 之后，再看性能与内存问题会清晰得多。

## 核心概念定义

> 阅读约定：本课先给「环境与 JVM」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Java | 编译带包名的代码：javac -d out src/com/example/app/Main.java，运行时用全限定名 java -cp out com.example.app.Main。 | 仅在「环境与 JVM」明确给出的输入、版本与资源条件下成立。 |
| JVM | public static void main(String[] args) 的每个部分都有含义：public 让 JVM 能访问、static 无需实例化、void 无返回值、String[] args 接收命令行参数。 | 仅在「环境与 JVM」明确给出的输入、版本与资源条件下成立。 |
| JDK | Java 开发工具包，包含编译器、运行时和标准工具。 | 仅在「环境与 JVM」明确给出的输入、版本与资源条件下成立。 |
| 字节码 | 源码编译后的中间指令，由虚拟机解释或即时编译执行。 | 仅在「环境与 JVM」明确给出的输入、版本与资源条件下成立。 |
| 包 | 把一组相关类型、函数或模块组织在一起的命名空间单元。 | 仅在「环境与 JVM」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「环境与 JVM」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：环境变量速查**

| 变量 | 作用 | 注意 |
| --- | --- | --- |
| `JAVA_HOME` | 指向 JDK 根目录 | 构建工具依赖它选择版本 |
| `PATH` | 找到 `java` / `javac` | 多版本时注意顺序 |
| `CLASSPATH` | 默认类路径 | 现代项目不设置，统一用 `-cp` 或构建工具 |
| `JAVA_OPTS` | JVM 参数 | 生产环境显式设置堆大小与 GC |

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Java」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「JVM」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「JDK」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「环境与 JVM」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Java | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | JVM | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | JDK | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「环境与 JVM」自己的示例验证。「环境与 JVM」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：JDK、JRE 与 JVM**

| 名称 | 包含内容 | 用途 |
| --- | --- | --- |
| JVM | 字节码执行引擎 | 运行 `.class` 文件 |
| JRE | JVM + 核心类库 | 只运行 Java 程序 |
| JDK | JRE + 编译器 + 工具 | 开发 Java 程序 |

Java 的口号是「一次编写，到处运行」：源码编译成**字节码**，由各平台的 JVM 执行并负责内存管理与即时编译（JIT）。

**教材衔接：程序生命周期**

```text
源码 .java → javac 编译 → 字节码 .class
              ↓ 类加载器（加载 → 链接 → 初始化）
              ↓ 字节码解释执行 + JIT 热点编译
              ↓ 垃圾回收自动回收堆内存
```

`public static void main(String[] args)` 的每个部分都有含义：`public` 让 JVM 能访问、`static` 无需实例化、`void` 无返回值、`String[] args` 接收命令行参数。

**教材衔接：版本与时效**

- Java 25 是当前 LTS，Java 21 仍是大量生产系统的基线；Java 的写法要按目标版本选择。
- 升级收益集中在并发与内存模型；JVM 相关代码需要单独回归。
- 升级前先用 nextLine 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 nextLine 记录构建与运行结果。
- 升级后重点回归 Java 的默认值、警告信息与错误格式。
- 升级完成后记录 Java 的新旧版本差异，并据此调整下次复核时间。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Java、JVM | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「环境与 JVM」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「环境与 JVM」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:java`，用于动手验证《环境与 JVM》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《环境与 JVM》原文中的最小示例。先预测《环境与 JVM》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```java
// Hello.java —— 文件名必须与 public 类名一致
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, Java!");
    }
}
```

**教材衔接：第一个程序**

```java
// Hello.java —— 文件名必须与 public 类名一致
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello, Java!");
    }
}
```

```bash
javac Hello.java     # 生成 Hello.class 字节码
java Hello           # 启动 JVM 执行

jshell               # JDK 9+ 交互式 REPL，适合快速试验
```

**教材衔接：包与类路径**

```java
package com.example.app;      // 包名通常用倒置域名

import java.util.List;        // 导入其他包的类

public class Main {
    public static void main(String[] args) {
        List<String> names = List.of("tom", "alice");
        System.out.println(names);
    }
}
```

编译带包名的代码：`javac -d out src/com/example/app/Main.java`，运行时用全限定名 `java -cp out com.example.app.Main`。

**教材衔接：JDK 组成与命令速查**

| 术语 | 含义 |
| --- | --- |
| JVM | Java 虚拟机，负责执行字节码 |
| JRE | 运行环境（JVM + 核心类库），只能运行程序 |
| JDK | 开发工具包（JRE + 编译器 + 诊断工具） |
| 字节码 | `.class` 文件，JVM 的执行格式 |
| 类路径 | JVM 查找类的路径，由 `-cp` 指定 |

| 目的 | 命令 |
| --- | --- |
| 查看版本 | `java -version`、`javac -version` |
| 编译 | `javac -d out src/Main.java` |
| 运行 | `java -cp out com.example.Main` |
| 打包 | `jar --create --file app.jar --main-class com.example.Main -C out .` |
| 运行 jar | `java -jar app.jar` |
| 查看字节码 | `javap -c -p out/com/example/Main.class` |
| 查看模块 | `java --list-modules` |
| 诊断线程 | `jstack <pid>` |
| 查看堆 | `jmap -heap <pid>` |
| 统一日志 | `java -Xlog:gc*:file=gc.log` |

版本与特性速查：

| 版本 | 关键特性 |
| --- | --- |
| Java 8 | Lambda、Stream、`java.time` |
| Java 11 | `var` 局部变量推断、内置 HTTP Client |
| Java 17 | record、密封类、switch 模式匹配（预览） |
| Java 21 | 虚拟线程、模式匹配增强、record 模式 |
| Java 25（LTS 方向） | 持续演进，关注长期支持版本 |

**教材衔接：零基础详解：Java 程序为什么既要编译又要解释**

### 一句话说清它是什么

Java 先把源码编译成**字节码**（`.class`），再由 JVM 在运行时翻译成机器指令。
这叫「一次编写，到处运行」：只要有对应平台的 JVM，同一份字节码就能跑。

### 用生活比喻理解三个缩写

| 缩写 | 全称 | 比喻 | 你要不要装 |
| --- | --- | --- | --- |
| JVM | Java 虚拟机 | 会读字节码的翻译官 | 随 JRE/JDK 一起装 |
| JRE | 运行环境 | 翻译官 + 词典 | 只想运行程序时够用 |
| JDK | 开发工具包 | 翻译官 + 词典 + 写作工具 | **开发者必须装这个** |

### 逐行拆解第一个程序

```java
package demo;                       // 声明所在包，可选但推荐

public class Hello {                // 类名必须与文件名 Hello.java 一致
    public static void main(String[] args) {   // 程序入口
        System.out.println("Hello, World!");   // 输出并换行
    }
}
```

| 部分 | 含义 | 少写会怎样 |
| --- | --- | --- |
| `package demo;` | 这个类属于 `demo` 包 | 类多了会重名冲突 |
| `public class Hello` | 公开类，名字要和文件名一致 | 不一致直接编译不过 |
| `public static void main` | 入口方法，签名固定 | JVM 找不到入口，报「找不到主方法」 |
| `String[] args` | 命令行参数 | 少写就不是合法入口 |
| `System.out.println` | 打印并换行 | 用 `print` 则不换行 |

### 编译与运行的两条命令

```bash
javac -d out src/demo/Hello.java     # 编译，字节码输出到 out 目录
java -cp out demo.Hello              # 运行，写全限定类名
```

注意运行时要写 `demo.Hello`（包名 + 类名），而不是 `Hello`。

### 新手最容易踩的八个坑

| 坑 | 报错信息 | 正确做法 |
| --- | --- | --- |
| 类名与文件名不一致 | `class X is public, should be declared in a file named X.java` | 文件名改成与类名完全一致 |
| 忘写分号 | `';' expected` | 语句结尾加分号 |
| 方法写在 `main` 里面 | `illegal start of expression` | 方法要写在类里、`main` 外 |
| 用了中文标点 | `illegal character` | 全部换成英文半角 |
| 变量未初始化 | `variable x might not have been initialized` | 声明时给初值 |
| 字符串比较用 `==` | 结果时对时错 | 内容比较用 `.equals()` |
| 找不到主方法 | `Main method not found` | 检查签名是否完全一致 |
| 包名与目录不一致 | `package does not exist` | 目录结构与包名一一对应 |

### 变量与常量：`var`、`final`

```java
var count = 10;                 // 局部变量类型推断（Java 10+）
final double PI = 3.14159;      // 常量，赋值后不能改
```

`var` 只是省了写类型，编译期类型就确定了，不是动态类型。

### 输入输出：Scanner 的正确姿势

```java
import java.util.Scanner;

public class Greet {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("请输入姓名：");
        String name = sc.nextLine();
        System.out.printf("你好，%s！%n", name);
        sc.close();
    }
}
```

`nextInt()` 之后紧接 `nextLine()` 会读到空串，这是最经典的坑：
读数字后要多调用一次 `nextLine()` 吃掉换行符。

### 代码规范速查

| 元素 | 规范 | 例子 |
| --- | --- | --- |
| 类名 | 大驼峰 | `UserService` |
| 方法与变量 | 小驼峰 | `calcTotal()`、`userName` |
| 常量 | 全大写加下划线 | `MAX_RETRY` |
| 包名 | 全小写，域名倒写 | `com.example.demo` |
| 缩进 | 4 个空格 | 不要用 Tab |

### 手把手练习：命令行计算器

```java
import java.util.Scanner;

public class Calculator {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        System.out.print("输入表达式（如 3 + 4）：");
        double a = sc.nextDouble();
        String op = sc.next();
        double b = sc.nextDouble();

        double result = switch (op) {
            case "+" -> a + b;
            case "-" -> a - b;
            case "*" -> a * b;
            case "/" -> b == 0 ? Double.NaN : a / b;
            default -> Double.NaN;
        };
        System.out.printf("结果：%.2f%n", result);
        sc.close();
    }
}
```

### 学完自测

- [ ] 能说出 JDK、JRE、JVM 的区别。
- [ ] 能解释为什么类名和文件名必须一致。
- [ ] 知道 `java` 命令后面要写全限定类名。
- [ ] 能说出 `==` 与 `.equals()` 的区别。
- [ ] 能独立用 `javac` 和 `java` 跑起来一个带包名的类。

## 时间/空间复杂度或性能分析

**复杂度证据**：「环境与 JVM」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「环境与 JVM」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「环境与 JVM」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：垃圾回收器与调优参数**

| 回收器 | 特点 | 适用 |
| --- | --- | --- |
| Serial | 单线程，停顿明显 | 客户端小程序、容器内极小堆 |
| Parallel | 多线程吞吐优先 | 批处理、吞吐优先场景 |
| CMS | 并发标记清除，低停顿 | 老版本低延迟场景（已废弃） |
| G1 | 分区域回收，可设定停顿目标 | 服务端默认（JDK 9+） |
| ZGC / Shenandoah | 亚毫秒级停顿，支持大堆 | 超大堆、延迟极敏感服务 |

常用参数：`-Xms/-Xmx` 设初始与最大堆（生产建议设成相同值，避免动态扩缩）；`-Xmn` 新生代大小；`-XX:MetaspaceSize` 元空间；`-XX:+HeapDumpOnOutOfMemoryError` 在 OOM 时自动导出堆快照；`-XX:MaxGCPauseMillis` 给 G1 设定停顿目标；`-Xlog:gc*` 输出 GC 日志。

排查思路：先用 `jstat -gc <pid> 1000` 观察 GC 频率与耗时；用 `jmap -histo` 找大对象；OOM 时用 MAT 分析堆转储。**频繁 Full GC 通常是内存泄漏或堆设置过小**，不要一上来就换回收器。

## 常见误区与易错点

> 复核《环境与 JVM》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「环境与 JVM」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 报错 | 原因 | 处理方式 |
| --- | --- | --- |
| `Could not find or load main class` | 类名或包名不对、类路径错误 | 用带包名的全限定名，检查 `-cp` |
| `NoClassDefFoundError` | 运行时缺依赖 | 把依赖加入类路径或用构建工具打包 |
| `ClassNotFoundException` | 反射或驱动类缺失 | 检查依赖与拼写 |
| `UnsupportedClassVersionError` | 编译版本高于运行版本 | 统一 JDK 版本或降级 `--release` |
| `public class` 与文件名不一致 | `javac` 报错 | 文件名必须与公共类名一致 |
| `package ... does not exist` | 缺少依赖或包路径不对 | 加依赖并检查目录结构 |
| `error: cannot find symbol` | 未导入、拼写错误或作用域不对 | 补 import 或修拼写 |
| `OutOfMemoryError: Java heap space` | 堆不足或内存泄漏 | 调 `-Xmx` 并排查泄漏 |
| `StackOverflowError` | 递归过深 | 加终止条件或改迭代 |
| 程序输出中文乱码 | 编码不一致 | 统一 UTF-8（`-Dfile.encoding=UTF-8`） |

**教材衔接：故障现场**

### 现场 1：Could not find or load main class

**症状**：在《环境与 JVM》的复现场景中，类名或包名不对、类路径错误。

**根因**：“类名或包名不对、类路径错误”只是表层结果。向上追溯会落到“Could not find or load main class”这一步，因为它省略了《环境与 JVM》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《环境与 JVM》的问题，用带包名的全限定名，检查 -cp。

**验证**：在《环境与 JVM》中按“用带包名的全限定名，检查 -cp”调整后，从“Could not find or load main class”的触发条件重放同一条路径，确认“类名或包名不对、类路径错误”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：NoClassDefFoundError

**症状**：在《环境与 JVM》的复现场景中，运行时缺依赖。

**根因**：触发点是把“NoClassDefFoundError”当成安全做法。它没有满足《环境与 JVM》要求的前提，因此先表现为“运行时缺依赖”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《环境与 JVM》的问题，把依赖加入类路径或用构建工具打包。

**验证**：先在《环境与 JVM》中记录“NoClassDefFoundError”留下的失败证据，再执行“把依赖加入类路径或用构建工具打包”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：ClassNotFoundException

**症状**：在《环境与 JVM》的复现场景中，反射或驱动类缺失。

**根因**：“反射或驱动类缺失”只是表层结果。向上追溯会落到“ClassNotFoundException”这一步，因为它省略了《环境与 JVM》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《环境与 JVM》的问题，检查依赖与拼写。

**验证**：保留《环境与 JVM》里触发“反射或驱动类缺失”的输入、版本和日志，按“检查依赖与拼写”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 关联 | 《变量、类型与字符串》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Java 方法入门》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《变量、类型与字符串》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「环境与 JVM」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《环境与 JVM》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“环境与 JVM”中的 Java、JVM、JDK，下列哪两项是本课强调的实践判断？

A. 学习 Java 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 Java 的常规示例通过，就可以跳过边界与异常路径
C. 验证 JVM 时要固定版本并覆盖边界输入，结论才可复现
D. 把 JVM 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 Java 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 JVM 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把环境与 JVM拆成概念、示例与故障现场三部分，因此判断 Java 时必须同时交代输入、输出和失败路径，这使“学习 Java 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在环境与 JVM里，判断 JVM 时要固定版本与边界输入，所以“验证 JVM 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 2

public class Hello 的源文件名必须是？

A. 任意名字
B. Hello.java
C. hello.java
D. Main.java

**参考答案**：Hello.java

**解析**：在「环境与 JVM」里，Hello.java。public 类的文件名必须与类名完全一致，包括大小写。「环境与 JVM」要求先交代Java、JVM、JDK的前提再下结论，所以“Hello.java”只在题干“public class Hello 的源文件名必须是”给定的条件下成立。

### 自测 3

这段代码是「环境与 JVM」的示例片段，下面哪一项描述与它一致？

```java
javac Hello.java     # 生成 Hello.class 字节码
java Hello           # 启动 JVM 执行

jshell               # JDK 9+ 交互式 REPL，适合快速试验
```

A. 这段代码包含条件分支，不同输入会走不同的执行路径。
B. 这段代码只做静态声明，没有循环、分支或可观察输出。
C. 这段代码会产生可观察的输出，运行后能看到结果。
D. 这段代码包含循环结构，同一段逻辑会被重复执行。

**参考答案**：这段代码只做静态声明，没有循环、分支或可观察输出。

**解析**：在「环境与 JVM」里，题干的正确项是这段代码只做静态声明，没有循环、分支或可观察输出，在「环境与 JVM」里它只能证明Java相关约束存在，不能替代真实运行证据。把输入或边界换成空值、极值或失败情况后，结论要以「环境与 JVM」的实际运行结果为准。「环境与 JVM」要求先交代Java、JVM、JDK的前提再下结论，所以“这段代码只做静态声明，没有循环”只在题干“这段代码是环境与 JVM的示例片段”给定的条件下成立。

**教材衔接：复习与自测**

- [ ] 能说清 JDK、JRE、JVM 的关系。
- [ ] 会用 `javac -d` 与 `java -cp` 手动编译运行。
- [ ] 知道 `JAVA_HOME` 与 `PATH` 的作用。
- [ ] 遇到 `UnsupportedClassVersionError` 先查版本一致性。
- [ ] 会用 `jstack`、`jmap` 做基础诊断。

**教材衔接：动手练习**

> 本课练习重点：围绕「Java、JVM、JDK」完成复述、实验和交付，每个结果都要能被别人检查。

先把 JVM 的正常路径测通，再引入并发与异常。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 环境与 JVM解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「JVM」是什么关系？

验收标准：回答里必须出现 Java，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：把 nextLine 当作原例，改动一次JVM的取值，记录命令、输出与差异原因；五步里缺任意一步都算未完成。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小类，补一个普通测试和一个边界输入测试。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Java」和「JVM」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```bash
javac Hello.java     # 生成 Hello.class 字节码
java Hello           # 启动 JVM 执行

jshell               # JDK 9+ 交互式 REPL，适合快速试验
```

### 任务 2：只改一个条件

把「环境与 JVM」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把 Java 的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「环境与 JVM」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Java。

### 任务 3：迁移到自己的数据

换一个 JVM 场景重做一次，确认结论不是只对示例数据成立。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「开发并编译 Java 程序需要安装？」的判断依据。
- [ ] 不看解析，能说出「public class Hello 的源文件名必须是？」的判断依据。
- [ ] 不看解析，能说出「Java 实现「一次编写，到处运行」的关键是？」的判断依据。
- [ ] 不看解析，能说出「javac 与 java 两个命令的分工是？」的判断依据。
- [ ] 不看解析，能说出「Java 程序入口方法的正确签名是？」的判断依据。
- [ ] 用 Java 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「环境与 JVM」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `Java` | 编译带包名的代码：javac -d out src/com/example/app/Main.java，运行时用全限定名 java -cp out com.example.app.Main。 |
| `JVM` | public static void main(String[] args) 的每个部分都有含义：public 让 JVM 能访问、static 无需实例化、void 无返回值、String[] args 接收命令行参数。 |
| `JDK` | Java 开发工具包，包含编译器、运行时和标准工具。 |
| `字节码` | 源码编译后的中间指令，由虚拟机解释或即时编译执行。 |
| `包` | 把一组相关类型、函数或模块组织在一起的命名空间单元。 |

## 考点精讲

### 考点 1：多选辨析·Java

- **题目**：围绕“环境与 JVM”中的 Java、JVM、JDK，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把环境与 JVM拆成概念、示例与故障现场三部分，因此判断 Java 时必须同时交代输入、输出和失败路径，这使“学习 Java 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在环境与 JVM里，判断 JVM 时要固定版本与边界输入，所以“验证 JVM 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·Java

- **题目**：public class Hello 的源文件名必须是？
- **判断依据**：在「环境与 JVM」里，Hello.java。public 类的文件名必须与类名完全一致，包括大小写。「环境与 JVM」要求先交代Java、JVM、JDK的前提再下结论，所以“Hello.java”只在题干“public class Hello 的源文件名必须是”给定的条件下成立。

### 考点 3：概念判断·一次编写，到处运行

- **题目**：Java 实现「一次编写，到处运行」的关键是？
- **判断依据**：源码编译成与平台无关的字节码，具体执行由该平台的 JVM 负责。如果只凭关键词作答，很容易把「使用 C 语言编写」、「每次重新编译」与「编译成字节码」混在一起；回到「环境与 JVM」的正文示例，用“Java 实现一次编写”走一遍Java、JVM、JDK的完整流程，能复现的结论才可以保留。

### 考点 4：代码补全·Java

- **题目**：这段代码是「环境与 JVM」的示例片段，下面哪一项描述与它一致？
- **判断依据**：在「环境与 JVM」里，题干的正确项是这段代码只做静态声明，没有循环、分支或可观察输出，在「环境与 JVM」里它只能证明Java相关约束存在，不能替代真实运行证据。把输入或边界换成空值、极值或失败情况后，结论要以「环境与 JVM」的实际运行结果为准。「环境与 JVM」要求先交代Java、JVM、JDK的前提再下结论，所以“这段代码只做静态声明，没有循环”只在题干“这段代码是环境与 JVM的示例片段”给定的条件下成立。

### 考点 5：概念判断·Java

- **题目**：Java 程序入口方法的正确签名是？
- **判断依据**：在「环境与 JVM」里，public static void main(String[] args)。JVM 需要 public + static 才能在未创建对象时按约定调用入口方法。“Java”与「环境与 JVM」的术语表相呼应，只有符合Java、JVM、JDK约束的“public static void m”才是正文支持的结论。

### 考点 6：填空·Java

- **题目**：补全代码：「环境与 JVM」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `String name = sc.____;`
- **判断依据**：在「环境与 JVM」里，nextLine。在「环境与 JVM」里判断这道题，要把Java、JVM、JDK的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“JVM示例中”与「环境与 JVM」的术语表相呼应，只有符合Java、JVM、JDK约束的“nextLine”才是正文支持的结论。

## English Overview

**Title:** JVM & Environment

**Summary:** JDK/JRE/JVM, compiling, packages and classpath.

**Category:** Java
**Level:** 基础
**Key terms:** Java, JVM, JDK, javac, 字节码, 包

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：Java 21+ / Maven 或 Gradle；本课聚焦 Java。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Java、JVM、JDK、javac、字节码、包
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**JVM & Environment** focuses on JDK/JRE/JVM, compiling, packages and classpath.

### Learning Outcomes

- Explain what **JVM & Environment** solves and when it should be used.

### Glossary

- Topic: **JVM & Environment**
- Related terms: Java, JVM, JDK, javac

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| JDK、JRE 与 JVM | JDK、JRE 与 JVM |
| 第一个程序 | 第一个程序 |
| 包与类路径 | 包与类路径 |
| 程序生命周期 | 程序Lifetime |
| 垃圾回收器与调优参数 | 垃圾回收器与调优参数 |
| 本课小结 | Summary |
| JDK 组成与命令速查 | JDK 组成与命令速查 |
| 环境变量速查 | 环境变量速查 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [JVM 规范](https://docs.oracle.com/javase/specs/jvms/se21/html/index.html) | 字节码与运行时行为 |
| [Java GC 调优](https://docs.oracle.com/en/java/javase/21/gctuning/) | 垃圾回收与性能调优 |
| [dev.java 学习](https://dev.java/learn/) | 现代 Java 官方教程 |

> 「环境与 JVM」的链接用于离线阅读后的延伸核对；App 不会自动联网。
