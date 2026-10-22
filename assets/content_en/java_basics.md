# Java Environment and JVM

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundation = Estimated duration: 14 minutes

## Learning objectives

- It is possible to explain in its own words what the environment and JVM are dealing with, not just a word.
- The relationship between Java, JVM, JDK and javac is clear.
- It's a way to put the knowledge back into Java, and it tells us how much of this is going on.
- It is possible to complete this course and check its results using acceptance standards.

> Summary of sentence: JDK/JRE/JVM distinction, compilation operation, package and class path, JIT and GC.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Before we begin: Java, JVM and JDK.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## JDK, JRE and JVM

|Name|Include|Purpose|
| --- | --- | --- |
| JVM |Byte Executing Engine|Run ⟦ files|
| JRE |JVM + Core Library|Run Java only|
| JDK |JRE+ Compiler + Tool|Develop Java Program|

Java has the slogan "Done at once, running everywhere": The source code is translated into ** bytes** and executed by JVM of each platform with responsibility for memory management and instant compilation (JIT).

## First program.

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

## Package & Class Path

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

Compiles the code with a package name: ⟦, run by an all-defined name.

## Process life cycle

```text
源码 .java → javac 编译 → 字节码 .class
              ↓ 类加载器（加载 → 链接 → 初始化）
              ↓ 字节码解释执行 + JIT 热点编译
              ↓ 垃圾回收自动回收堆内存
```

Each part of the ⟦0 means that JVM can access, 2 without exemplifying, <3 with no return value and 4 command line parameters.

## Garbage Recycler and Modified Parameters

|Recycler|Features|Application|
| --- | --- | --- |
| Serial |One-way, clear.|Client applets, very small pile of containers|
| Parallel |Multi-wire swallowing priority|Batch, Swallow Priority|
| CMS |And we're gonna get rid of it.|Old version of low delay scenario (disused)|
| G1 |Sub-regional recycling, with standstill targets|Service Default (JDK 9+)|
| ZGC / Shenandoah |It's a millisecond stop. Support the piles.|It's too big, it's late for very sensitive services.|

Common parameters: ⟦ 0 sets initial and maximum stacks (recommended for production to avoid dynamic scaling up); ⟦ 1  new generation size;  2 metaspace; < 3  auto-export snapshots at OOM;⟦4 sets a standstill target for G1; ⟦5 output GC log.

Checking ideas: See GC frequencies and time-consuming first; find big objects with ⟦1; analyze dumps using MAT when OOM.** Fractional Full GCs are usually memory leaks or stacking is too small.

## It's the end of this class.
JDK provides tools, is responsible for the implementation of JVMs and ensures that it crosses a platform. Once you understand how to load with Jit, then look at performance and memory issues much clearer.

<!-- appendix:v1 -->

## JDK Composition and Command Quick Check

|Terminology|Meaning|
| --- | --- |
| JVM |Java Virtual Machine for Byte Codes|
| JRE |Operating environment (JVM + core library), only running applications|
| JDK |Development of toolkit (JRE+ compiler + diagnostic tool)|
|Bytes|⟦ File, JVM Execution Format|
|Class path|Path to the JVM search class, specified by ⟦0|

|Purpose|Command|
| --- | --- |
|View Version| `java -version`、`javac -version` |
|Compile| `javac -d out src/Main.java` |
|Run| `java -cp out com.example.Main` |
|Pack up.| `jar --create --file app.jar --main-class com.example.Main -C out .` |
|Run jar| `java -jar app.jar` |
|View bytes| `javap -c -p out/com/example/Main.class` |
|View Modules| `java --list-modules` |
|Diagnosis| `jstack <pid>` |
|View Stacks| `jmap -heap <pid>` |
|Unified log| `java -Xlog:gc*:file=gc.log` |

Version and characterization:

|Version|Key Features|
| --- | --- |
| Java 8 | Lambda、Stream、`java.time` |
| Java 11 |⟦ Local variable extrapolation, built-in HTTP Clinic|
| Java 17 |Record, Seal, Switch Mode Match (Preview)|
| Java 21 |Virtual thread, pattern matching enhancement, record mode|
|Java 25 (LTS orientation)|Continuous evolution, focus on long-term support|

## Quick check of environmental variables

|Variables|Role|Attention.|
| --- | --- | --- |
| `JAVA_HOME` |Point to JDK Roots|Build tool relies on it to select a version|
| `PATH` |Found 0 / 1|Watch out for multiple versions.|
| `CLASSPATH` |Default Class Path|Do not set modern items, use ⟦ or build tools|
| `JAVA_OPTS` |JVM Arguments|Production environment visible stack size and GC|

## Common Error Table

|Wrong.|Reason|Treatment|
| --- | --- | --- |
| `Could not find or load main class` |Class name or package is not correct, class path error|Use a full name with the bag. Check for zero.|
| `NoClassDefFoundError` |Synchronising folder|Reliance group path or package with construction tool|
| `ClassNotFoundException` |Reflect or drive class missing|Check Dependency and Spelling|
| `UnsupportedClassVersionError` |Compiled version over run version|Unified JDK version or downgraded ⟦|
|It doesn't match the file name.|I'm sorry.|File name must be consistent with public|
| `package ... does not exist` |Lack of dependency or wrong path|Reliance and check directory structure|
| `error: cannot find symbol` |Not Imported, Spelled or Incorrect|Fill or Spell|
| `OutOfMemoryError: Java heap space` |Inadequate or memory leaks|We're gonna do a leak.|
| `StackOverflowError` |Overwhelming|Add termination or change of name|
|Program Output Chinese Spelling|The code doesn't match.|UTF-8 (0)|

## Self-Detected List

- [ ] It makes sense to talk about JDK, JRE, JVM.
- [ ] It's gonna run manually with ⟦0 and 1
- [ ] Knows the role of ⟦0 and 1.
- [ ] Meet ⟦0 and check for consistency first.
- [ ] It's going to be a basic diagnosis.

<!-- appendix:v2 -->

## Zero basis: Why does Java process have to be compiled and explained?

### What is it?

Java translates the source code into ** bytes** (⟦) and JVM into machine commands while running.
It's called "one writing, one running": a JVM with the same byte code.

### Three abbreviations.

|Abbreviations|Full|A metaphor.|Do you want to pretend?|
| --- | --- | --- | --- |
| JVM |Java Virtual Machine|A byte-reading translator.|Load with JRE/JDK|
| JRE |Operating environment|Translator+Dictionary|I just want to run the program.|
| JDK |Development of toolkits|Translator + Dictionary + Writing Tool|** Developer has to install this|

### Dismantling first program by line

```java
package demo;                       // 声明所在包，可选但推荐

public class Hello {                // 类名必须与文件名 Hello.java 一致
    public static void main(String[] args) {   // 程序入口
        System.out.println("Hello, World!");   // 输出并换行
    }
}
```

|Part|Meaning|What happens when you keep it down?|
| --- | --- | --- |
| `package demo;` |This category belongs to the ⟦0 package.|There's more to it than that.|
| `public class Hello` |It's a public category. The name corresponds to the file.|It's not consistent.|
| `public static void main` |Method of entry, fixed signature|JVM can't find the portal. The main method is not found.|
| `String[] args` |Command Line Parameters|It's not a legal entrance.|
| `System.out.println` |Print & Line Break|Use Zero, no change.|

### Compile and run two commands

```bash
javac -d out src/demo/Hello.java     # 编译，字节码输出到 out 目录
java -cp out demo.Hello              # 运行，写全限定类名
```

Note that you want to write ⟦, not .

### The eight most easy pits for freshmen.

|The pit.|Wrong message|The right thing to do.|
| --- | --- | --- |
|Classname does not match file name| `class X is public, should be declared in a file named X.java` |Change file name to the same category|
|Forget the semicolon.| `';' expected` |End of statement with semicolon|
|It's written in the Zero.| `illegal start of expression` |The method is in the class, and it's outside.|
|Use Chinese Punctuation| `illegal character` |It's all in English.|
|Variables Not Initialized| `variable x might not have been initialized` |Opening value at declaration|
|Strings compare with ⟦0|The result is right and wrong.|It's more like a "O"|
|No main method found| `Main method not found` |Check if the signature is identical|
|The package name doesn't match the directory.| `package does not exist` |Directory structure corresponds to package name|

### Variables and constant: ⟦1

```java
var count = 10;                 // 局部变量类型推断（Java 10+）
final double PI = 3.14159;      // 常量，赋值后不能改
```

⟦ just saves the type of writing. The type of translation period is determined, not the dynamic type.

### Input output: Scanner's correct position

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

♪ And then there's the one that reads empty strings, and this is the most classic pit of all:
After reading the numbers, you're going to have to call again and eat a line break.

### Code Scanning

|Elements|Normative|Example:|
| --- | --- | --- |
|Classname|Elephant| `UserService` |
|Methodology and variables|♪ Little camels| `calcTotal()`、`userName` |
|Constant|Underline the whole story.| `MAX_RETRY` |
|Package name|All lowercase. Invert the domain name.| `com.example.demo` |
|Indent|4 Spaces|Don't use it, Tab.|

### Handheld exercise: command line calculator

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

### Learn how to measure yourself.

- [ ] Can you tell the difference between JDK, JRE and JVM?
- [ ] Explain why the category and file names have to be identical.
- [ ] Know that the ⟦0 command is followed by a full class name.
- [ ] Can tell the difference between ⟦ and .
- [ Laughs ] Can run with a bag name on its own.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of the course: Repeating, experimenting and delivering around Java, JVM, each result being checked.

Run through the smallest class and test, then make up for anomalies and parallel borders, and finally observe changes in wiring and resources.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Environment and JVM?
2. Without it, what concrete consequences would there be?
3. What's it got to do with JVM?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Writes a runable subcategory, adds an ordinary test and a border input test.

Mission requests:

- The result must be checked, not just “I understand”.
- It's not like it's a "Java" or "JVM."
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** JVM & Environment

**Summary:** JDK/JRE/JVM, compiling, packages and classpath.

**Category:** Java  
**Level:** Foundation
**Key terms:** Java, JVM, JDK, byte code, package

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable context: Java 21+ / Maven or Gradle
- Source: Internal structured curriculum and engineering practices
- Related topics: Java, JVM, JDK, javac, byte code, bag
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**JVM & Environment** focuses on JDK/JRE/JVM, compiling, packages and classpath.

### Learning Outcomes

- Explain what **JVM & Environment** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **JVM & Environment**
- Related terms: Java, JVM, JDK, javac
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|JDK, JRE and JVM|JDK, JRE and JVM|
|First program.|First program.|
|Package & Class Path|Package & Class Path|
|Process life cycle|Lifetime|
|Garbage Recycler and Modified Parameters|Garbage Recycler and Modified Parameters|
|It's the end of this class.| Summary |
|JDK Composition and Command Quick Check|JDK Composition and Command Quick Check|
|Quick check of environmental variables|Quick check of environmental variables|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

