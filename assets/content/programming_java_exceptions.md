# 异常处理与文件 IO

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![Java 异常体系与资源管理](images/diagram_java_exceptions.webp)

![异常处理与文件 IO](images/remaining_java_exceptions.webp)

## 本节知识框架

**课程定位**：所属分类 `java`（Java），课程主题 `异常处理与文件 IO`，学习阶段 进阶，建议用时 50 分钟。

本课主线：受检/非受检异常、try-with-resources、NIO.2 与自定义异常。

**学完本课应当能够**
- 说清 `AutoCloseable` 与 `printStackTrace` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `IllegalArgumentException` 的行为，记录输入、输出与失败条件。
- 遇到「捕获后什么都不做」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `AutoCloseable`：先掌握 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关，再用它解释 `printStackTrace` 为什么会出现。
2. `printStackTrace`：先掌握 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续，再用它解释 `IllegalArgumentException` 为什么会出现。
3. `IllegalArgumentException`：先掌握 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`，再用它解释 `异常` 为什么会出现。
4. `异常`：先掌握 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Java」分类的第 12 课。先修内容：《集合框架与泛型》。《集合框架与泛型》里的 `List`、`Set` 是本课的前提。相关或后续课程：《Lambda 与 Stream API》、《异常处理与文件操作》、《错误处理与调试》。

### 完成判据

- **定义关**：不看正文也能说明 `AutoCloseable` 是 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `异常处理与文件 IO`，而不是只背结论。
- **示例关**：能运行或推演 `异常处理与文件 IO` 的 `java` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `异常处理与文件 IO` 示例里的 调用了 `BalanceException()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 捕获后什么都不做，记录现象并按 至少记录日志，或重新抛出 修复。
- **迁移关**：能把 `异常`、`try`、`catch`、`finally` 放进一个与 `异常处理与文件 IO` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `异常处理与文件 IO` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| AutoCloseable | 实现 AutoCloseable 的资源会在代码块结束时自动关闭，异常也不会漏关。 | 只在「实现 AutoCloseable 的资源会在代码块结束时自动关闭，异常也不会漏关」这一前提下成立，换输入或换环境要重新验证。 |
| printStackTrace | 捕获后要么处理、要么包装成业务异常抛出，不要 printStackTrace 后继续。 | 易错：日志框架里丢失上下文；正确做法是用 `log.error("上下文", e)`。 |
| IllegalArgumentException | 尽早失败：参数校验失败立刻抛 IllegalArgumentException。 | 结果依赖数据分布、模型版本与算力预算，换数据集或换硬件都要重新评估。 |
| 异常 | 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。 | 易错：又慢又难读；正确做法是能用判断就用判断。 |

## 原理与运行机制

### 机制总览

**教材衔接：使用建议**

1. 不要用异常控制正常流程。
2. 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续。
3. 记录日志时保留原始异常：`throw new ServiceException("下单失败", e);`
4. 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。

**教材衔接：版本与时效**

- 先确认运行环境是 Java 21 还是 25，再决定 OutOfMemoryError 能否使用新语法。
- 虚拟线程与结构化并发对 异常 的影响最大，升级前先确认线程模型。
- 升级前确认 异常 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 异常 相关的差异单独记成一条结论。
- 升级后重点回归 异常 的默认值、警告信息与错误格式。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 异常 的版本变化。

### 机制拆解：每一步的输入、动作与输出

#### 1. `AutoCloseable`
- 输入：`异常`；本步把 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关 当作判断规则。
- 动作：围绕 `AutoCloseable` 保留中间状态，并记录它与 `printStackTrace` 的对应关系。
- 输出：`printStackTrace`，它可以被下一段代码、测试或记录继续使用。
- `AutoCloseable` 的失败条件：只在「实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关」这一前提下成立，换输入或换环境要重新验证。

#### 2. `printStackTrace`
- 输入：`AutoCloseable`；本步把 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续 当作判断规则。
- 动作：围绕 `printStackTrace` 保留中间状态，并记录它与 `IllegalArgumentException` 的对应关系。
- 输出：`IllegalArgumentException`，它可以被下一段代码、测试或记录继续使用。
- `printStackTrace` 的失败条件：当`e.printStackTrace()`时，会出现日志框架里丢失上下文。

#### 3. `IllegalArgumentException`
- 输入：`printStackTrace`；本步把 尽早失败：参数校验失败立刻抛 `IllegalArgumentException` 当作判断规则。
- 动作：围绕 `IllegalArgumentException` 保留中间状态，并记录它与 `异常` 的对应关系。
- 输出：`异常`，它可以被下一段代码、测试或记录继续使用。
- `IllegalArgumentException` 的失败条件：结果依赖数据分布、模型版本与算力预算，换数据集或换硬件都要重新评估。

#### 4. `异常`
- 输入：`IllegalArgumentException`；本步把 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换 当作判断规则。
- 动作：围绕 `异常` 保留中间状态，并记录它与 `BalanceException` 的对应关系。
- 输出：`BalanceException`，它可以被下一段代码、测试或记录继续使用。
- `异常` 的失败条件：当用异常做流程控制时，会出现又慢又难读。

### 示例中的可观察事实

1. 调用了 `BalanceException()`；它对应的课程主题是 `异常处理与文件 IO`。
2. 调用了 `super()`；它对应的课程主题是 `异常处理与文件 IO`。
3. 出现字面量 `余额不足：`；它对应的课程主题是 `异常处理与文件 IO`。

### 复现实验记录

- 环境：`异常处理与文件 IO` 使用 `java` 示例，固定 `异常`、`try`、`catch`、`finally` 作为第一组条件。
- 首轮输入：先确认 调用了 `BalanceException()`，预测 `AutoCloseable` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `异常`，观察 `异常` 是否仍满足定义。
- 失败注入：复现 捕获后什么都不做，确认现象是 问题被彻底掩盖。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `异常处理与文件 IO` 时才能区分概念错误与实现错误。

## 典型应用场景

- **捕获后什么都不做**：典型现象是问题被彻底掩盖；正确做法是至少记录日志，或重新抛出。
- **捕获 `Exception` 一把抓**：典型现象是掩盖真正的 bug；正确做法是先捕获具体类型。
- **用异常做流程控制**：典型现象是又慢又难读；正确做法是能用判断就用判断。
- **忘了关闭资源**：典型现象是句柄泄漏；正确做法是用 try-with-resources。

### 最小验证场景

- 准备：保留 `java` 示例的原始输入，先记录 `异常处理与文件 IO` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `BalanceException()`，再改变一个与 `AutoCloseable` 相关的条件。
- 判定：新结果与 `异常处理与文件 IO` 的基线不同不等于错误；只有当差异破坏了 `AutoCloseable` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `AutoCloseable` 时，先满足它的定义：实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关；只在「实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关」这一前提下成立，换输入或换环境要重新验证。
- 使用 `printStackTrace` 时，先满足它的定义：捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续；易错：日志框架里丢失上下文；正确做法是用 `log.error("上下文", e)`。
- 使用 `IllegalArgumentException` 时，先满足它的定义：尽早失败：参数校验失败立刻抛 `IllegalArgumentException`；结果依赖数据分布、模型版本与算力预算，换数据集或换硬件都要重新评估。
- 使用 `异常` 时，先满足它的定义：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换；易错：又慢又难读；正确做法是能用判断就用判断。

## 代码/协议/SQL 示例

### 最小可验证示例

```text
Throwable
├── Error（严重错误，不应捕获，如 OutOfMemoryError）
└── Exception
    ├── RuntimeException（非受检：NullPointerException、IllegalArgumentException）
    └── 其他（受检：IOException、SQLException，必须处理或声明）
```

**教材衔接：异常体系**

**教材衔接：捕获与抛出**

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

**教材衔接：try-with-resources**

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

**教材衔接：读写文件（NIO.2）**

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

**教材衔接：异常体系速查**

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

**教材衔接：零基础详解：异常体系与资源管理**

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

**运行方式**：运行 `异常处理与文件 IO` 的示例时，保存为 `.java` 后用 `javac` 编译、`java` 运行；注意类名与文件名一致。

### 示例精读：先找证据，再改一个条件

1. 调用了 `BalanceException()`；它出现在 `异常处理与文件 IO` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `super()`；它出现在 `异常处理与文件 IO` 的示例中，阅读时先确认它前后各发生了什么。
3. 出现字面量 `余额不足：`；它出现在 `异常处理与文件 IO` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `异常处理与文件 IO` 中与 `AutoCloseable` 对照：示例必须能支持 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关，否则说明这一段还缺少实现或验证步骤。
- 在 `异常处理与文件 IO` 中与 `printStackTrace` 对照：示例必须能支持 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续，否则说明这一段还缺少实现或验证步骤。
- 在 `异常处理与文件 IO` 中与 `IllegalArgumentException` 对照：示例必须能支持 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`，否则说明这一段还缺少实现或验证步骤。
- 在 `异常处理与文件 IO` 中与 `异常` 对照：示例必须能支持 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（异常处理与文件 IO）**：JVM 预热与 GC 影响测量：记录吞吐、P99 延迟与堆占用，先跑预热再采样。

**本课特有开销（异常处理与文件 IO · 异常）**：小文件看元数据开销，大文件看吞吐，两者要分别测量。

**测量方法**：以 `异常处理与文件 IO` 的 `异常` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `异常处理与文件 IO` 的 `异常`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异常处理与文件 IO` 的 `try`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异常处理与文件 IO` 的 `catch`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异常处理与文件 IO` 的 `finally`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异常处理与文件 IO` 的 `AutoCloseable`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `异常处理与文件 IO` 中 `AutoCloseable` 的边界：只在「实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `异常处理与文件 IO` 中 `printStackTrace` 的边界：易错：日志框架里丢失上下文；正确做法是用 `log.error("上下文", e)`。达到边界时不要外推，必须重新测量。
- `异常处理与文件 IO` 中 `IllegalArgumentException` 的边界：结果依赖数据分布、模型版本与算力预算，换数据集或换硬件都要重新评估。达到边界时不要外推，必须重新测量。
- `异常处理与文件 IO` 中 `异常` 的边界：易错：又慢又难读；正确做法是能用判断就用判断。达到边界时不要外推，必须重新测量。
- `异常处理与文件 IO` 的代码证据：先验证 调用了 `BalanceException()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 捕获后什么都不做 | 问题被彻底掩盖 | 至少记录日志，或重新抛出 |
| 捕获 `Exception` 一把抓 | 掩盖真正的 bug | 先捕获具体类型 |
| 用异常做流程控制 | 又慢又难读 | 能用判断就用判断 |
| 忘了关闭资源 | 句柄泄漏 | 用 try-with-resources |
| 在 `finally` 里返回 | 吞掉异常和返回值 | 别在 `finally` 中返回 |
| 空指针只捕获不修 | 崩溃延后发生 | 用 `Optional` 或判空从源头解决 |
| 丢掉 cause | 排查时看不到根因 | 用带 `cause` 的构造方法 |
| 自定义异常太多 | 没人能记住 | 只在调用方需要区别处理时才自定义 |
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
| catch (Exception e) { } | 异常被吞，问题难以发现。 | 至少记录日志，只捕获能处理的异常。 |
| e.printStackTrace() | 日志框架里丢失上下文。 | 用 log.error("上下文", e)。 |
| 在 finally 里 return | 覆盖返回值、吞掉异常。 | finally 只做资源释放。 |

### 现场 1：捕获后什么都不做

**症状**：问题被彻底掩盖。

**根因与修复**：至少记录日志，或重新抛出。

**自检**：在本课示例里复现「捕获后什么都不做」，改成至少记录日志，或重新抛出后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：捕获 `Exception` 一把抓

**症状**：掩盖真正的 bug。

**根因与修复**：先捕获具体类型。

**自检**：在本课示例里复现「捕获 `Exception` 一把抓」，改成先捕获具体类型后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：用异常做流程控制

**症状**：又慢又难读。

**根因与修复**：能用判断就用判断。

**自检**：在本课示例里复现「用异常做流程控制」，改成能用判断就用判断后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：忘了关闭资源

**症状**：句柄泄漏。

**根因与修复**：用 try-with-resources。

**自检**：在本课示例里复现「忘了关闭资源」，改成用 try-with-resources后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：在 `finally` 里返回

**症状**：吞掉异常和返回值。

**根因与修复**：别在 `finally` 中返回。

**自检**：在本课示例里复现「在 `finally` 里返回」，改成别在 `finally` 中返回后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：空指针只捕获不修

**症状**：崩溃延后发生。

**根因与修复**：用 `Optional` 或判空从源头解决。

**自检**：在本课示例里复现「空指针只捕获不修」，改成用 `Optional` 或判空从源头解决后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：丢掉 cause

**症状**：排查时看不到根因。

**根因与修复**：用带 `cause` 的构造方法。

**自检**：在本课示例里复现「丢掉 cause」，改成用带 `cause` 的构造方法后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：自定义异常太多

**症状**：没人能记住。

**根因与修复**：只在调用方需要区别处理时才自定义。

**自检**：在本课示例里复现「自定义异常太多」，改成只在调用方需要区别处理时才自定义后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`catch (Exception e) { }`

**症状**：异常被吞，问题难以发现。

**根因与修复**：至少记录日志，只捕获能处理的异常。

**自检**：在本课示例里复现「`catch (Exception e) { }`」，改成至少记录日志，只捕获能处理的异常后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`集合框架与泛型`。本课默认这些内容已经掌握。
- **相关或后续**：`Lambda 与 Stream API`、`异常处理与文件操作`、`错误处理与调试`。本课术语会在这些课程里继续使用。
- **术语归属**：`AutoCloseable`、`printStackTrace`、`IllegalArgumentException` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。

### 先修与后续术语接口

- `异常处理与文件操作`：共享术语 `异常`，共同关键词 `异常`、`try`。
- `集合框架与泛型`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `Lambda 与 Stream API`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `错误处理与调试`：共享术语 `异常`，共同关键词 `异常`、`try`、`catch`。

### 容易混淆的相邻概念

- `AutoCloseable` 与 `printStackTrace`：前者强调 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关；后者强调 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `printStackTrace` 与 `IllegalArgumentException`：前者强调 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续；后者强调 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `IllegalArgumentException` 与 `异常`：前者强调 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`；后者强调 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `AutoCloseable` 的操作性定义，并说明它与 `printStackTrace` 的区别。

**参考答案**：实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关。

`printStackTrace` 的定位是：捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「捕获后什么都不做」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是问题被彻底掩盖；正确做法是至少记录日志，或重新抛出。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `java` 示例，把其中的 `"余额不足："` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `java` 示例应当复现正文给出的结果；把 `"余额不足："` 换成边界值后，如果结果改变或报错，先核对它是否满足 `异常处理与文件 IO` 中`AutoCloseable` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `java` 示例，说明它体现了`AutoCloseable` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`AutoCloseable` 的定义是 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关，示例正是在实现这条定义。改动与 `AutoCloseable` 有关的一个输入后，如果结果不再符合 `异常处理与文件 IO` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `异常处理与文件 IO` 的方法迁移到自己的项目：围绕 `AutoCloseable` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「在 finally 里 return」，它会导致覆盖返回值、吞掉异常；检验方式是按finally 只做资源释放改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `AutoCloseable` 与 `printStackTrace`：各写一行适用场景、一行失败表现。

**参考答案**：`AutoCloseable` 的定义是实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关；`printStackTrace` 的定义是捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「捕获后什么都不做」引发的问题，请把“复现 问题被彻底掩盖 → 保留证据 → 至少记录日志，或重新抛出 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按问题被彻底掩盖复现；第二步记录输入、版本与完整报错；第三步按至少记录日志，或重新抛出只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `异常`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：易错：又慢又难读；正确做法是能用判断就用判断。 同时要把 `异常` 的定义 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `AutoCloseable` → `printStackTrace` → `IllegalArgumentException` → `异常` 的作用链。

**参考答案**：起点是 `AutoCloseable` 的定义 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关；中间每一步都保留可观察状态；终点由 `异常` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `异常处理与文件 IO` 中，现象是 覆盖返回值、吞掉异常。请围绕 在 finally 里 return 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 在 finally 里 return，记录输入与完整错误；再按 finally 只做资源释放 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `异常处理与文件 IO`：先给主问题，再按顺序说出 `AutoCloseable`、`printStackTrace`、`IllegalArgumentException`、`异常`，最后给一个失败案例。

**自评标准**：主问题必须对应 受检/非受检异常、try-with-resources、NIO.2 与自定义异常；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `AutoCloseable` | 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关。 |
| `printStackTrace` | 捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续。 |
| `IllegalArgumentException` | 尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。 |
| `异常` | 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。 |

**术语关系**：`AutoCloseable`（实现 `AutoCloseable` 的资源会在代码块结束时自动关闭） → `printStackTrace`（捕获后要么处理、要么包装成业务异常抛出） → `IllegalArgumentException`（尽早失败：参数校验失败立刻抛 `IllegalArgumentException`） → `异常`（程序执行中偏离正常控制流的错误事件）。

## 考点精讲

`异常处理与文件 IO` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：围绕“异常处理与文件 IO”中的 异常、try、catch，下列哪两项是本课强调的实践判断？
- **正确项**：学习 异常 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 try 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `异常` 上：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。复习时把 `异常` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：这段 `java` 代码对应 `异常处理与文件 IO` 的 `AutoCloseable`。课程要解决的是受检/非受检异常、try-with-resources、NIO.2 与自定义异常。关于代码内容，哪一项说法准确？
- **正确项**：调用了 `BalanceException()`
- **判断依据**：这道题落在术语 `AutoCloseable` 上：实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关。复习时把 `AutoCloseable` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：多个 catch 子句的书写顺序要求是？
- **正确项**：子类异常必须在前
- **判断依据**：这道题落在术语 `异常` 上：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。复习时把 `异常` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：在 finally 中写 return 的风险是？
- **正确项**：会覆盖 try 中的返回值甚至吞掉异常
- **判断依据**：这道题落在术语 `异常` 上：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。复习时把 `异常` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：抛出异常时想保留原始异常信息，正确做法是？
- **正确项**：new RuntimeException("处理失败", cause)
- **判断依据**：这道题落在术语 `异常` 上：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。复习时把 `异常` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `受检/非受检异常、try-with-resources、NIO.2 与自定义异常。`，这段说明是：尽早失败：参数校验失败立刻抛 ``____``。空缺处应填哪个术语？
- **正确项**：IllegalArgumentException
- **判断依据**：这道题落在术语 `IllegalArgumentException` 上：尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。复习时把 `IllegalArgumentException` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`AutoCloseable`

- **要点**：实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关。
- **AutoCloseable 的边界**：只在「实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关」这一前提下成立，换输入或换环境要重新验证。

### 考点 8：`printStackTrace`

- **要点**：捕获后要么处理、要么包装成业务异常抛出，不要 `printStackTrace` 后继续。
- **printStackTrace 的边界**：易错：日志框架里丢失上下文；正确做法是用 `log.error("上下文", e)`。

### 考点 9：`IllegalArgumentException`

- **要点**：尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。
- **IllegalArgumentException 的边界**：结果依赖数据分布、模型版本与算力预算，换数据集或换硬件都要重新评估。

### 考点 10：`异常`

- **要点**：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。
- **异常 的边界**：易错：又慢又难读；正确做法是能用判断就用判断。

### 考点 11：排错——捕获后什么都不做

- **现象**：问题被彻底掩盖。
- **处理**：至少记录日志，或重新抛出。

### 考点 12：排错——捕获 `Exception` 一把抓

- **现象**：掩盖真正的 bug。
- **处理**：先捕获具体类型。

### 考点 13：综合辨析——`AutoCloseable` 与 `异常`

- **辨析点**：`AutoCloseable` 的定义是 实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关；`异常` 的定义是 程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。
- **答题要求**：面对 `异常处理与文件 IO` 的题目，先判断描述的是 `AutoCloseable` 还是 `异常`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 问题被彻底掩盖，而不是只写“程序有错”。
- **证据分**：保留触发 捕获后什么都不做 的输入、版本和错误原文。
- **修复分**：按 至少记录日志，或重新抛出 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
；本课聚焦 异常。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：异常、try、catch、finally、AutoCloseable、Files
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：异常、try、catch、finally、AutoCloseable、Files。

| 参考资料 | 本课用途 |
| --- | --- |
| [Gradle 文档](https://docs.gradle.org/current/userguide/userguide.html) | 构建脚本与依赖管理 |
| [Java GC 调优](https://docs.oracle.com/en/java/javase/21/gctuning/) | 垃圾回收与性能调优 |
| [Java 语言规范](https://docs.oracle.com/javase/specs/jls/se21/html/index.html) | 语言语义与类型规则 |

| [本课术语索引：异常处理与文件 IO](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「异常处理与文件 IO」的链接用于离线阅读后的延伸核对；App 不会自动联网。