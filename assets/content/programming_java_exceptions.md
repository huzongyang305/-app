# 异常处理与文件 IO

![Java 异常体系与资源管理](images/diagram_java_exceptions.webp)

![异常处理与文件 IO](images/remaining_java_exceptions.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「异常处理与文件 IO」解决了什么问题，而不是只背术语。
- 能说清 「异常」、「try」、「catch」、「finally」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Java」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：受检/非受检异常、try-with-resources、NIO.2 与自定义异常。

## 前置知识

- 先完成上一课《集合框架与泛型》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：异常、try、catch。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 异常体系

```text
Throwable
├── Error（严重错误，不应捕获，如 OutOfMemoryError）
└── Exception
    ├── RuntimeException（非受检：NullPointerException、IllegalArgumentException）
    └── 其他（受检：IOException、SQLException，必须处理或声明）
```

## 捕获与抛出

```java
public static int parse(String text) {
    try {
        return Integer.parseInt(text);
    } catch (NumberFormatException e) {
        System.err.println("格式错误：" + e.getMessage());
        return 0;
    } finally {
        System.out.println("无论如何都会执行");
    }
}

public void read(String path) throws IOException {   // 受检异常要声明
    if (path == null) {
        throw new IllegalArgumentException("路径不能为空");   // 非受检，无需声明
    }
    // ...
}
```

多异常捕获：`catch (IOException | SQLException e)`。子类异常必须写在父类前面。

## try-with-resources

```java
try (BufferedReader reader = Files.newBufferedReader(Path.of("data.txt"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
} catch (IOException e) {
    e.printStackTrace();
}
```

实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关。

## 读写文件（NIO.2）

```java
import java.nio.file.*;
import java.util.List;

Path path = Path.of("notes.txt");

Files.writeString(path, "第一行\n", StandardOpenOption.CREATE,
                  StandardOpenOption.APPEND);

List<String> lines = Files.readAllLines(path);
lines.forEach(System.out::println);

Files.createDirectories(Path.of("data/cache"));   // 递归创建目录
```

## 自定义异常

```java
public class BalanceException extends RuntimeException {
    public BalanceException(String message) { super(message); }
}

if (balance < amount) {
    throw new BalanceException("余额不足：" + balance);
}
```

## 使用建议

1. 不要用异常控制正常流程。
2. 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续。
3. 记录日志时保留原始异常：`throw new ServiceException("下单失败", e);`
4. 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。

## 本课小结
受检异常强制调用方思考失败路径，运行时异常表达编程错误。资源一律交给 try-with-resources。


## 异常体系速查

| 类型 | 是否受检 | 典型例子 | 处理建议 |
| --- | --- | --- | --- |
| `Error` | 否 | `OutOfMemoryError`、`StackOverflowError` | 不捕获，交给进程处理 |
| 受检异常 | 是 | `IOException`、`SQLException` | 必须捕获或声明抛出 |
| 运行时异常 | 否 | `NullPointerException`、`IllegalArgumentException` | 修代码，少捕获 |

常用写法速查：

| 目的 | 写法 |
| --- | --- |
| 捕获并记录 | `catch (IOException e) { log.error("读取失败", e); }` |
| 多类型同处理 | `catch (IOException \| SQLException e) { ... }` |
| 重新抛出并保留原因 | `throw new ServiceException("下单失败", e);` |
| 自动关闭资源 | `try (var in = new FileInputStream(path)) { ... }` |
| 无异常时执行 | `try { ... } catch (...) { ... }` 之后写正常逻辑 |
| 一定执行的清理 | `finally { ... }` |
| 断言参数 | `Objects.requireNonNull(id, "id 不能为空")` |
| 校验参数合法性 | `if (n < 0) throw new IllegalArgumentException("n 必须非负");` |
| 自定义异常 | `class OrderException extends RuntimeException { ... }` |

```java
public Order createOrder(OrderRequest request) {
    Objects.requireNonNull(request, "request 不能为空");
    if (request.items().isEmpty()) {
        throw new IllegalArgumentException("订单不能为空");
    }
    try {
        return repository.save(request.toEntity());
    } catch (DataAccessException e) {
        // 保留原始异常，便于排查根因
        throw new OrderCreateException("保存订单失败", e);
    }
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `catch (Exception e) { }` | 异常被吞，问题难以发现 | 至少记录日志，只捕获能处理的异常 |
| `e.printStackTrace()` | 日志框架里丢失上下文 | 用 `log.error("上下文", e)` |
| 在 `finally` 里 `return` | 覆盖返回值、吞掉异常 | `finally` 只做资源释放 |
| 用异常控制正常流程 | 性能差、语义混乱 | 用返回值或 `Optional` 表达预期分支 |
| 丢失原始异常 | 只剩一句「失败了」 | 构造新异常时传入 `cause` |
| 捕获后不做处理也不抛 | 上层以为成功 | 记录并重新抛出，或返回明确失败结果 |
| 自定义异常继承 `Throwable` | 语义过重，可能不被常规捕获 | 业务异常继承 `RuntimeException` 或 `Exception` |
| `try` 块里包含大量无关代码 | 误捕获、定位困难 | `try` 只包最小可能失败的片段 |
| 忘记关闭资源 | 文件句柄与连接泄漏 | 用 try-with-resources |
| 受检异常在 `lambda` 里直接抛 | 编译不通过 | 包装成运行时异常，或在 lambda 内处理 |

## 自测清单

- [ ] 分得清受检异常、运行时异常与 `Error` 的处理策略。
- [ ] 捕获时始终传原始异常作为 cause。
- [ ] 用 try-with-resources 管理需要关闭的资源。
- [ ] 参数校验用 `Objects.requireNonNull` 与 `IllegalArgumentException`。
- [ ] 日志用占位符并带上异常对象，不用 `printStackTrace`。


## 零基础详解：异常体系与资源管理

### 一句话说清它是什么

异常是 Java 表达「出问题了」的方式。它分成**受检异常**（必须处理）和**非受检异常**（运行时问题）。
配套的 `try-with-resources` 负责自动关闭文件、连接这类资源。

### 异常家族结构

```text
Throwable
  包含 Error（JVM 级严重问题，不该捕获，如 OutOfMemoryError）
  包含 Exception
     包含 RuntimeException（非受检：空指针、越界、类型转换）
     包含其它受检异常（IOException、SQLException）
```

| 类型 | 是否必须处理 | 典型场景 | 处理建议 |
| --- | --- | --- | --- |
| 受检异常 | 必须 `try` 或声明 `throws` | 读文件、连数据库 | 能恢复就处理，否则向上抛 |
| 非受检异常 | 不强制 | 参数非法、空指针 | 修代码，而不是到处捕获 |
| Error | 不该捕获 | 内存耗尽 | 让程序退出 |

### 完整写法

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Loader {
    public static String load(Path path) throws IOException {
        try {
            return Files.readString(path);
        } catch (IOException e) {
            System.err.println("读取失败：" + path);
            throw e;                       // 记录后再抛出，别吞掉
        }
    }

    public static void main(String[] args) {
        try {
            System.out.println(load(Path.of("config.txt")));
        } catch (IOException e) {
            System.out.println("程序继续运行：" + e.getMessage());
        } finally {
            System.out.println("无论成功失败都会执行");
        }
    }
}
```

### try-with-resources：自动关闭

```java
try (var reader = Files.newBufferedReader(Path.of("data.txt"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
} catch (IOException e) {
    System.out.println("读取出错：" + e.getMessage());
}
```

只要资源实现了 `AutoCloseable`，写在 `try(...)` 里就会自动关闭——**比手写 `finally` 更安全**。

### 抛异常的三条规范

```java
// 1. 参数校验抛非受检，让错误尽早暴露
if (amount <= 0) throw new IllegalArgumentException("金额必须为正");

// 2. 保留原因链，别丢掉原始异常
try {
    parse(text);
} catch (NumberFormatException e) {
    throw new IllegalArgumentException("解析失败：" + text, e);
}

// 3. 自定义异常让调用方精确处理
class InsufficientBalanceException extends RuntimeException {
    InsufficientBalanceException(String message) { super(message); }
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 捕获后什么都不做 | 问题被彻底掩盖 | 至少记录日志，或重新抛出 |
| 捕获 `Exception` 一把抓 | 掩盖真正的 bug | 先捕获具体类型 |
| 用异常做流程控制 | 又慢又难读 | 能用判断就用判断 |
| 忘了关闭资源 | 句柄泄漏 | 用 try-with-resources |
| 在 `finally` 里返回 | 吞掉异常和返回值 | 别在 `finally` 中返回 |
| 空指针只捕获不修 | 崩溃延后发生 | 用 `Optional` 或判空从源头解决 |
| 丢掉 cause | 排查时看不到根因 | 用带 `cause` 的构造方法 |
| 自定义异常太多 | 没人能记住 | 只在调用方需要区别处理时才自定义 |

### 空指针的现代防御

```java
import java.util.Optional;

Optional<String> nickname = Optional.ofNullable(user.getNickname());
String shown = nickname.orElse("匿名用户");

// 链式取值，任何一环为 null 都不会抛异常
String city = Optional.ofNullable(user)
        .map(User::getAddress)
        .map(Address::getCity)
        .orElse("未填写");
```

### 手把手练习：安全解析数字并统计

```java
import java.util.*;

public class ParseDemo {
    static int parseScore(String raw) {
        try {
            int value = Integer.parseInt(raw.trim());
            if (value < 0 || value > 100) {
                throw new IllegalArgumentException("分数必须在 0~100：" + raw);
            }
            return value;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("不是合法数字：" + raw, e);
        }
    }

    public static void main(String[] args) {
        List<String> inputs = List.of("88", " 92 ", "abc", "120");
        List<Integer> scores = new ArrayList<>();
        for (String raw : inputs) {
            try {
                scores.add(parseScore(raw));
            } catch (IllegalArgumentException e) {
                System.out.println("跳过：" + e.getMessage());
            }
        }
        System.out.println("有效分数：" + scores);
    }
}
```

### 学完自测

- [ ] 能说出受检异常与非受检异常的区别。
- [ ] 知道为什么不该写 `catch (Exception e) {}`。
- [ ] 会用 try-with-resources 自动关闭资源。
- [ ] 知道抛异常时如何保留原因链。
- [ ] 能用 `Optional` 写出不抛空指针的链式取值。

## 动手练习


> 本课练习重点：围绕「异常、try、catch」完成复述、实验和交付，每个结果都要能被别人检查。

先跑通最小类与测试，再补异常和并发边界，最后观察线程与资源变化。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「异常处理与文件 IO」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「try」是什么关系？

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
- 至少覆盖「异常」和「try」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 实践任务

本节围绕“异常处理与文件 IO”安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

合上教程，用 5 句话说明“异常处理与文件 IO”解决什么问题、输入是什么、输出是什么、失败时会怎样、与相邻概念的边界在哪里。画一张流程图或状态图，把每个节点标注成“输入 / 处理 / 输出 / 失败路径”之一。

**验收标准**：图里至少有 5 个节点和 1 条失败路径；每个节点都能在正文中找到依据。

### 任务 2：做一次对比实验

从正文里选两个差异最小的方案，列成 4 列表格：方案、前提、代价、适用边界。然后只改变一个条件（数据规模、并发度、精度或资源上限），记录结果变化。

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

把“异常处理与文件 IO”的核心方法用到你熟悉的一个真实场景，写出一份 300 字以内的实施记录：目标、步骤、验证方式、仍然不确定的问题。

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。


## 故障现场

这一节把“异常处理与文件 IO”最常见的失败方式还原成现场记录，练习时按“症状 → 复现 → 定位 → 修复 → 预防”的顺序排查。

### 现场 1：“异常处理与文件 IO”的 异常 常规用例通过，但边界用例失败

**症状**：在“异常处理与文件 IO”的练习或生产场景里出现““异常处理与文件 IO”的 异常 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发““异常处理与文件 IO”的 异常 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“异常 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：为“异常处理与文件 IO”补一条空值或极值用例，把前置条件写成断言，并让失败信息直接指出是哪个输入越界

**预防**：把““异常处理与文件 IO”的 异常 常规用例通过，但边界用例失败”写成一条自动化用例，并在“异常处理与文件 IO”的验收清单里保留对应检查项。


### 现场 2：“异常处理与文件 IO”的 try 结果在两次运行之间不一致

**症状**：在“异常处理与文件 IO”的练习或生产场景里出现““异常处理与文件 IO”的 try 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发““异常处理与文件 IO”的 try 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“try 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：固定“异常处理与文件 IO”使用的版本与随机种子，记录两次运行的完整输入和输出，再逐项消除非确定性来源

**预防**：把““异常处理与文件 IO”的 try 结果在两次运行之间不一致”写成一条自动化用例，并在“异常处理与文件 IO”的验收清单里保留对应检查项。


### 现场 3：“异常处理与文件 IO”的验证只在开发机通过

**症状**：在“异常处理与文件 IO”的练习或生产场景里出现““异常处理与文件 IO”的验证只在开发机通过”。

**复现**：准备一组最小输入，只保留触发““异常处理与文件 IO”的验证只在开发机通过”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，异常 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

**修复**：把“异常处理与文件 IO”的运行环境、输入样本和预期输出写成清单，并在另一套环境复跑同一条命令

**预防**：把““异常处理与文件 IO”的验证只在开发机通过”写成一条自动化用例，并在“异常处理与文件 IO”的验收清单里保留对应检查项。



## 版本与时效

这一节记录“异常处理与文件 IO”涉及的版本基线与升级检查点，避免把某个版本的默认行为当成永久结论。

- Java 25 是当前 LTS，Java 21 仍是大量生产系统的基线
- 虚拟线程、记录模式、结构化并发与分代 ZGC 是升级收益最大的部分
- 升级前重点检查反射、字节码增强、序列化与第三方框架兼容性
- 官方发布说明：https://www.oracle.com/java/technologies/javase/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：受检异常（checked exception）必须如何处理？

- **正确判断**：必须捕获或声明抛出
- **判断依据**：正确答案是「必须捕获或声明抛出」，本课在「本课小结」中说明：受检异常强制调用方思考失败路径，运行时异常表达编程错误。编译器强制要求处理受检异常，这是 Java 区别于运行时异常的显著特征。本课还在「零基础详解：异常体系与资源管理」中说明：它分成受检异常（必须处理）和非受检异常（运行时问题）。本课还在「捕获与抛出」中说明：多异常捕获：catch (IOException | SQLException e)。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：try-with-resources 要求资源对象实现哪个接口？

- **正确判断**：AutoCloseable
- **判断依据**：实现 AutoCloseable（或 Closeable）即可在代码块结束时自动 close。其他选项：try-with-resources 要求资源实现 AutoCloseable（Closeable 是它的子接口）。针对「try-with-resources 要求资源对…」，本课在「零基础详解：异常体系与资源管理」中说明：只要资源实现了 AutoCloseable，写在 try(...) 里就会自动关闭——比手写 finally 更安全。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：多个 catch 子句的书写顺序要求是？

- **正确判断**：子类异常必须在前
- **判断依据**：正确答案是「子类异常必须在前」，本课在「零基础详解：异常体系与资源管理」中说明：知道为什么不该写 catch (Exception e) {}。子类异常先捕获，否则父类分支会先匹配，编译器也会直接报错。本课还在「零基础详解：异常体系与资源管理」中说明：配套的 try-with-resources 负责自动关闭文件、连接这类资源。本课还在「捕获与抛出」中说明：多异常捕获：catch (IOException | SQLException e)。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：在 finally 中写 return 的风险是？

- **正确判断**：会覆盖 try 中的返回值甚至吞掉异常
- **判断依据**：正确答案是「会覆盖 try 中的返回值甚至吞掉异常」，本课在「使用建议」中说明：记录日志时保留原始异常：throw new ServiceException("下单失败", e);。finally 应只做资源释放，避免在里面写 return 或抛出新异常。本课还在「使用建议」中说明：捕获后要么处理、要么包装成业务异常抛出，不要 printStackTrace 后继续。本课还在「使用建议」中说明：尽早失败：参数校验失败立刻抛 IllegalArgumentException。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：抛出异常时想保留原始异常信息，正确做法是？

- **正确判断**：new RuntimeException("处理失败", cause)
- **判断依据**：正确答案是「new RuntimeException("处理失败", cause)」，本课在「使用建议」中说明：记录日志时保留原始异常：throw new ServiceException("下单失败", e);。传入 cause 能保留完整调用链，排查时不会丢失根因。本课还在「本课小结」中说明：资源一律交给 try-with-resources。本课还在「零基础详解：异常体系与资源管理」中说明：只要资源实现了 AutoCloseable，写在 try(...) 里就会自动关闭——比手写 finally 更安全。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 6：补全代码：「异常处理与文件 IO」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `if (amount <= 0) throw new ____("金额必须为正");`

- **正确判断**：IllegalArgumentException / illegalargumentexception
- **判断依据**：正确答案是「IllegalArgumentException」，本课在「使用建议」中说明：尽早失败：参数校验失败立刻抛 IllegalArgumentException。本课还在「try-with-resources」中说明：实现 AutoCloseable 的资源会在代码块结束时自动关闭，异常也不会漏关。本课还在「零基础详解：异常体系与资源管理」中说明：会用 try-with-resources 自动关闭资源。
- **迁移检查**：如果填成相近的另一个函数或关键字，程序会在哪一步出错？

### 补充自测（2 题）

1. 围绕“异常处理与文件 IO”中的 异常、try、catch，下列哪两项是本课强调的实践判断？
2. 下面这段 Java 代码复现了“异常处理与文件 IO”中 异常、try、catch 相关的一个常见故障，哪一项最准确地解释了问题？

这些题按“先定位概念、再排除边界错误、最后核对答案”的顺序作答；每题解析都给出了判断依据。


## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「受检异常（checked exception）必须如何处理？」的判断依据。
- [ ] 不看解析，能说出「try-with-resources 要求资源对象实现哪个接口？」的判断依据。
- [ ] 不看解析，能说出「多个 catch 子句的书写顺序要求是？」的判断依据。
- [ ] 不看解析，能说出「在 finally 中写 return 的风险是？」的判断依据。
- [ ] 不看解析，能说出「抛出异常时想保留原始异常信息，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「异常处理与文件 IO」示例中，下面这行代码缺少哪个关键字或函数名？请…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `catch (IOException | SQLException e)` | 多异常捕获：`catch (IOException \| SQLException e)`。子类异常必须写在父类前面。 |
| `AutoCloseable` | 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关。 |
| `printStackTrace` | 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续。 |
| `IllegalArgumentException` | 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。 |
| `Error` | \| `Error` \| 否 \| `OutOfMemoryError`、`StackOverflowError` \| 不捕获，交给进程处理 \| |
| `OutOfMemoryError` | \| `Error` \| 否 \| `OutOfMemoryError`、`StackOverflowError` \| 不捕获，交给进程处理 \| |
| `StackOverflowError` | \| `Error` \| 否 \| `OutOfMemoryError`、`StackOverflowError` \| 不捕获，交给进程处理 \| |
| `IOException` | \| 受检异常 \| 是 \| `IOException`、`SQLException` \| 必须捕获或声明抛出 \| |
| `SQLException` | \| 受检异常 \| 是 \| `IOException`、`SQLException` \| 必须捕获或声明抛出 \| |
| `NullPointerException` | \| 运行时异常 \| 否 \| `NullPointerException`、`IllegalArgumentException` \| 修代码，少捕获 \| |
| `try { ... } catch (...) { ... }` | \| 无异常时执行 \| `try { ... } catch (...) { ... }` 之后写正常逻辑 \| |
| `finally { ... }` | \| 一定执行的清理 \| `finally { ... }` \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：受检异常（checked exception）必须如何处理？

**参考回答**：正确答案是「必须捕获或声明抛出」，本课在「本课小结」中说明：受检异常强制调用方思考失败路径，运行时异常表达编程错误。编译器强制要求处理受检异常，这是 Java 区别于运行时异常的显著特征。本课还在「零基础详解·异常体系与资源管理」中说明：它分成受检异常（必须处理）和非受检异常（运行时问题）。本课还在「捕获与抛出」中说明：多异常捕获：catch (IOException | SQLException e)。

### 追问 2：try-with-resources 要求资源对象实现哪个接口？

**参考回答**：实现 AutoCloseable（或 Closeable）即可在代码块结束时自动 close。其他选项：try-with-resources 要求资源实现 AutoCloseable（Closeable 是它的子接口）。针对「try-with-resources 要求资源对…」，本课在「零基础详解·异常体系与资源管理」中说明：只要资源实现了 AutoCloseable，写在 try(...) 里就会自动关闭——比手写 finally 更安全。

### 追问 3：多个 catch 子句的书写顺序要求是？

**参考回答**：正确答案是「子类异常必须在前」，本课在「零基础详解·异常体系与资源管理」中说明：知道为什么不该写 catch (Exception e) {}。子类异常先捕获，否则父类分支会先匹配，编译器也会直接报错。本课还在「零基础详解·异常体系与资源管理」中说明：配套的 try-with-resources 负责自动关闭文件、连接这类资源。本课还在「捕获与抛出」中说明：多异常捕获：catch (IOException | SQLException e)。

### 追问 4：在 finally 中写 return 的风险是？

**参考回答**：正确答案是「会覆盖 try 中的返回值甚至吞掉异常」，本课在「使用建议」中说明：记录日志时保留原始异常：throw new ServiceException("下单失败", e);。finally 应只做资源释放，避免在里面写 return 或抛出新异常。本课还在「使用建议」中说明：捕获后要么处理、要么包装成业务异常抛出，不要 printStackTrace 后继续。本课还在「使用建议」中说明：尽早失败：参数校验失败立刻抛 IllegalArgumentException。

### 追问 5：抛出异常时想保留原始异常信息，正确做法是？

**参考回答**：正确答案是「new RuntimeException("处理失败", cause)」，本课在「使用建议」中说明：记录日志时保留原始异常：throw new ServiceException("下单失败", e);。传入 cause 能保留完整调用链，排查时不会丢失根因。本课还在「本课小结」中说明：资源一律交给 try-with-resources。本课还在「零基础详解·异常体系与资源管理」中说明：只要资源实现了 AutoCloseable，写在 try(...) 里就会自动关闭——比手写 finally 更安全。

## English Overview

**Title:** Exceptions & IO

**Summary:** Checked exceptions, try-with-resources, NIO.2.

**Category:** Java  
**Level:** 进阶  
**Key terms:** 异常, try, catch, finally, AutoCloseable, Files

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：异常、try、catch、finally、AutoCloseable、Files
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

> 本课主题：受检/非受检异常、try-with-resources、NIO.2 与自定义异常。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
