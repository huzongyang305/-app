# 异常处理与文件 IO

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

<!-- appendix:v1 -->

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

<!-- appendix:v3 -->

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

<!-- practice-diversified:v1 -->

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

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

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

<!-- p2-references:v1 -->

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

