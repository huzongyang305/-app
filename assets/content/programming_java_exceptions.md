# 异常处理与文件 IO

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![Java 异常体系与资源管理](images/diagram_java_exceptions.webp)

![异常处理与文件 IO](images/remaining_java_exceptions.webp)

## 本节知识框架

想象你在做饭：正常流程是洗菜、切菜、炒菜。但可能出意外——刀切到手（异常）、煤气没了（资源耗尽）、锅烧干了（文件不存在）。Java 的异常处理就是告诉你：出了事怎么办，以及怎么保证不管出不出事，最后都要关火（关闭资源）。

**本课你将学到：**
- 受检异常和非受检异常的区别
- try-catch-finally 和 try-with-resources 的写法
- 自定义异常的正确姿势
- NIO.2 读写文件

**先修要求：** 学完《集合框架与泛型》即可。

### 复习清单

- [ ] 能说出受检异常和非受检异常的区别及各自的处理方式
- [ ] 能用 try-with-resources 写出安全的文件读取代码
- [ ] 能解释为什么 finally 里不应该写 return

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| 受检异常 | 编译器强制你处理的异常（IOException 等），必须 try-catch 或 throws 声明。 |
| 非受检异常 | RuntimeException 及其子类，编译器不强制处理，通常是编程错误。 |
| try-with-resources | 自动关闭实现了 AutoCloseable 的资源，比手写 finally 更安全。 |
| 自定义异常 | 继承 RuntimeException 或 Exception，让调用方能精确区分不同错误。 |
| throws 声明 | 写在方法签名上，告诉调用方"这个方法可能抛这些受检异常，你得处理"。 |
| 异常链（cause） | 重新抛出时挂在里面的原始异常，getCause() 能一层层追到最早出错的那一步。 |
| 被抑制异常 | try-with-resources 关闭资源时又抛出的异常，它会作为 suppressed 附在主异常上，不会顶掉主异常。 |
| 联合 catch | `catch (IOException \| SQLException e)` 一条子句接多种异常，Java 7 起可用，注意各异常类型之间不能有继承关系。 |

## 原理与运行机制

### 异常家族结构

```text
Throwable
├── Error（严重错误，不应捕获，如 OutOfMemoryError）
└── Exception
    ├── RuntimeException（非受检：NullPointerException、IllegalArgumentException）
    └── 其他（受检：IOException、SQLException，必须处理或声明）
```

### try-catch-finally

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
```

多条 catch 时，子类异常必须写在父类前面：

```java
try { ... }
catch (FileNotFoundException e) { ... }   // 子类在前
catch (IOException e) { ... }             // 父类在后
```

### try-with-resources

```java
try (BufferedReader reader = Files.newBufferedReader(Path.of("data.txt"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
} catch (IOException e) {
    log.error("读取失败", e);
}
```

只要资源实现了 `AutoCloseable`，写在 try(...) 里就会自动关闭，比手写 finally 更安全。

### 抛异常的三条规范

```java
// 1. 参数校验抛非受检，尽早暴露
if (amount <= 0) throw new IllegalArgumentException("金额必须为正");

// 2. 保留原因链，别丢掉原始异常
throw new ServiceException("下单失败", e);

// 3. 自定义异常让调用方精确处理
class InsufficientBalanceException extends RuntimeException {
    InsufficientBalanceException(String msg) { super(msg); }
}
```

### NIO.2 文件读写

```java
Path path = Path.of("notes.txt");
Files.writeString(path, "第一行\n", StandardOpenOption.CREATE, StandardOpenOption.APPEND);
List<String> lines = Files.readAllLines(path);
Files.createDirectories(Path.of("data/cache"));
```

### throw 之后到底发生了什么

一条 `throw` 语句做的事情像"临时退场"：JVM 在当前方法里停止往下执行，沿着调用栈一层层往回退，把每一层的局部变量销毁，同时看有没有哪一层的 `catch` 能接住这个类型。接住了，就从那一层继续正常执行；一路退到 `main` 还没人接，程序终止并把栈印到标准错误。

关键推论有两条。第一，**退场途中，已经创建但没有交给 try-with-resources 的资源不会自动关闭**，这就是句柄泄漏的来源。第二，**匹配只看异常对象的运行时类型**，所以 `catch (IOException e)` 能接住 `FileNotFoundException`，反过来却不行——这正是多条 catch 必须"子类在前、父类在后"的原因：写反了以后子类那条永远够不着，编译器会直接报"异常的子句已被 catch 覆盖"。

### 受检异常的代价与设计意图

受检异常是 Java 区别于多数现代语言的地方：编译器要求你显式处理，否则不给过。它的意图是好的——"磁盘会满、网络会断"这类**调用方确实能补救**的失败，最好当场想清楚。代价是它会污染方法签名，一旦底层改成受检异常，上层一串方法都得跟着改。

于是实践里出现了一条清晰的分工线：**能恢复的用受检异常（IOException、SQLException），属于代码写错的用非受检异常（NullPointerException、IllegalArgumentException、IndexOutOfBoundsException）**。后者不该被 catch 兜住，应该让它炸出来、把行号印进日志，然后去修代码。把参数校验包装成受检异常，是新手最常见的架构级误用。

### try-with-resources 的关闭次序与 suppressed

```java
static class Room implements AutoCloseable {
    private final String name;
    Room(String name) { this.name = name; }
    @Override public void close() { throw new IllegalStateException(name + " 关不掉了"); }
}

public static void main(String[] args) {
    try (Room a = new Room("A"); Room b = new Room("B")) {
        throw new RuntimeException("业务逻辑先炸了");
    } catch (Exception e) {
        System.out.println(e.getMessage());
        for (Throwable s : e.getSuppressed()) System.out.println("附带：" + s.getMessage());
    }
}
```

三个要点：资源按**声明的反序**关闭（这里先关 b 再关 a）；关闭时抛出的异常**不会顶掉**主体里的异常，而是被 `addSuppressed` 挂在主异常身上；`e.printStackTrace()` 或用 `{}` 把异常对象交给日志框架时，被抑制的异常会一并印出来。反过来说，如果你改回手写 `finally` 并在里面直接 `close()`，那么 close 抛出的异常会把原异常吞掉——这就是 try-with-resources 真正的价值，而不只是少写几行。

### 读懂一段异常栈

生产日志里最常见的是这种三段式：

```text
Exception in thread "main" com.shop.ServiceException: 下单失败
	at com.shop.OrderService.pay(OrderService.java:57)
Caused by: java.net.ConnectException: Connection refused
	at java.net.http.HttpClient.send(HttpClient.java:...)
```

读法是：先看**最上面那行的类型和消息**（决定谁来处理），再从上往下找**第一个属于你自己包名的行**（决定改哪一行代码），最后一定去看 **Caused by**——它才是根因。中间那些 `java.*`、`jdk.*` 框架内部帧通常可以直接略过。自己包装异常时如果丢了 cause，这份栈就只剩第一句"下单失败"，排查会瞬间失去方向。

## 典型应用场景

| 场景 | 推荐做法 | 为什么 |
| --- | --- | --- |
| 参数校验 | 抛 IllegalArgumentException | 尽早失败，错误明确 |
| 读文件 | try-with-resources | 自动关闭，不会泄漏 |
| 业务错误 | 自定义 RuntimeException | 调用方能精确处理 |
| 记录日志 | log.error("上下文", e) | 保留异常栈和上下文 |

### 场景一：把底层异常转成对外可读的错误

服务层调用支付网关，网络超时抛 `ConnectException`。直接把它甩给前端是不合格的：用户看不懂，日志里还混着一堆框架帧。正确做法是在边界层做一次"翻译"，同时把原始异常挂进 cause：

```java
public PayResult pay(long orderId) {
    try {
        return gateway.charge(orderId);
    } catch (IOException e) {
        throw new ServiceException("支付通道暂时不可用，请稍后重试", e);
    }
}
```

这一小段同时满足三条口径：**输入**（一个订单号）、**输出**（成功时的 PayResult）、**失败路径**（底层 I/O 失败会变成带 cause 的业务异常，运维仍然能顺着 Caused by 查到超时）。边界层只 catch 它确实能补救的类型，其余一律放行，让全局异常处理器兜底。

### 场景二：批量导入时跳过坏行而不是整体失败

一次导入一万行 CSV，第 37 行的分数写成 `"八十五"`。此时不该让整个事务崩掉，也不该悄悄忽略——两者都不对。可复现的做法是"逐行解析 + 计数 + 汇总上报"：

```java
int total = 0, bad = 0;
try (BufferedReader reader = Files.newBufferedReader(Path.of("scores.csv"))) {
    String line;
    while ((line = reader.readLine()) != null) {
        total++;
        try {
            importOne(line);
        } catch (IllegalArgumentException e) {
            bad++;
            log.warn("第 {} 行跳过：{}", total, e.getMessage());
        }
    }
}
log.info("共读 {} 行，坏行 {} 条", total, bad);
```

要点有三个：文件本身交给 try-with-resources，坏行只用自己的小 try 包住，异常只在这一层被消化并计数，最后把数字报出来。**边界要单独试**：空文件、只有一行表头、行数是 0 或 100 万，结论都可能不同，别只跑一份"刚好正常"的数据就上线。

## 代码/协议/SQL 示例

### 自定义异常示例

```java
public class BalanceException extends RuntimeException {
    public BalanceException(String message) {
        super("余额不足：" + message);
    }
}

public void withdraw(double amount) {
    if (amount > balance) {
        throw new BalanceException("余额 " + balance);
    }
    balance -= amount;
}
```

### 安全解析数字

```java
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
```

### Optional 防御空指针

```java
Optional<String> nickname = Optional.ofNullable(user.getNickname());
String shown = nickname.orElse("匿名用户");
```

### 最小可运行示例：一个能直接编译跑的 Main

把下面代码存成 `Demo.java`，用 `java Demo.java` 单文件模式即可运行（JDK 11 起支持）：

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Demo {
    static class ConfigException extends Exception {
        ConfigException(String message, Throwable cause) { super(message, cause); }
    }

    static int loadPort(String file) throws ConfigException {
        try {
            String raw = Files.readString(Path.of(file)).trim();
            int port = Integer.parseInt(raw);
            if (port < 1024 || port > 65535) {
                throw new IllegalArgumentException("端口超出可用范围：" + port);
            }
            return port;
        } catch (IOException | NumberFormatException e) {
            throw new ConfigException("配置文件 " + file + " 不可用", e);
        }
    }

    public static void main(String[] args) {
        for (String f : new String[]{"port.txt", "missing.txt", "bad.txt"}) {
            try {
                System.out.println(f + " -> " + loadPort(f));
            } catch (ConfigException e) {
                System.out.println("失败：" + e.getMessage() + "，根因：" + e.getCause());
            }
        }
    }
}
```

这段示例把本课的所有考点串在一条线上：联合 catch 一次接住两种异常类型（互不相干才能并列）；`IOException | NumberFormatException` 被包成有业务含义的 `ConfigException` 且保留 cause；参数越界走的是非受检的 `IllegalArgumentException`，它不会被这个 catch 接住，而是继续向上抛——"尽早失败"和"能补救才捕获"的分界线就在这里。三个输入分别覆盖**正常**（`port.txt` 写 8080）、**缺失**（`missing.txt` 不存在 → NoSuchFileException 是 IOException 子类）、**边界值**（`bad.txt` 写 `abc` 或 `99`），这正是"固定版本并覆盖边界输入"的落地方式。

注意 `catch (ConfigException e)` 里没有再打印栈，因为这是示例；真实项目应写成 `log.error("加载配置失败", e)`，把异常对象本体交给日志框架。

### 手写 finally 关闭资源的两个坑

```java
BufferedReader r = null;
try {
    r = Files.newBufferedReader(Path.of("data.txt"));
    return r.readLine();
} catch (IOException e) {
    throw new UncheckedIOException(e);      // 原异常在这里发生
} finally {
    if (r != null) {
        r.close();                          // 坑 2：close 自己也可能抛异常
    }
}
```

坑 1：`finally` 里的 `close()` 抛出异常时，会**顶掉** try 或 catch 里原本要抛出的那个，你在日志里只看到一句"关不掉"，真正的原因永远看不见。坑 2：`close()` 本身声明 `IOException`，还得再包一层 try 才能编译过。这两条加起来，就是"能用 try-with-resources 就不要手写 finally 关资源"的全部理由。

### 参数校验的标准写法

```java
public void transfer(Account from, Account to, long amountCents) {
    Objects.requireNonNull(from, "转出账户不能为空");
    Objects.requireNonNull(to, "转入账户不能为空");
    if (amountCents <= 0) {
        throw new IllegalArgumentException("金额必须为正整数分：" + amountCents);
    }
    if (from.balanceCents() < amountCents) {
        throw new InsufficientBalanceException(from.id(), amountCents);
    }
    // 到这里可以确信参数全部合法，主逻辑不用再层层判空
}
```

把校验集中在方法开头，失败就立刻抛 `IllegalArgumentException`（空指针场景用 `Objects.requireNonNull`），后面的代码就不必反复防御。消息里带上实际值（这里是 `amountCents`），排查时不用再猜。

## 时间/空间复杂度或性能分析

- **异常创建**：new Exception 会收集调用栈，开销较大（微秒级），所以不要用异常控制正常流程
- **try-with-resources**：编译器生成的关闭代码和手写 finally 性能一致
- **NIO.2**：Files.readAllLines 一次性读入内存，大文件用 BufferedReader 逐行读
- **日志记录**：用占位符 log.error("msg {}", arg) 比字符串拼接快，因为不抛异常时不拼接

### 异常贵在哪一步

`throw new X(...)` 的开销不在"跳转"，而在**构造**：异常对象出生时会调用 `fillInStackTrace()`，沿当前线程栈把每一帧记录下来。栈越深、对象越多，这一步越贵，量级通常在几百纳秒到几微秒；正常的方法调用只要几纳秒。于是"用异常代替 if 判断"在热路径上会放大成肉眼可见的掉速——比如循环里靠 catch `NoSuchElementException` 来判断迭代器是否耗尽，一百万次就是白烧一百万次栈填充。

反过来，如果某个分支本来就极少发生（一年出错一次的配置读取），那点多出的微秒完全不用考虑。**性能取舍的判断依据永远是"这段代码执行多少次"，不是"异常看起来重不重"。**

一个少见但合法的优化：对高频创建、又确实不需要栈的异常（如某些集合内部用于信号的类型），可以覆写 `fillInStackTrace()` 返回 `this`，或用带 `writableStackTrace=false` 的构造方法，让栈填充这一步消失。代价是出事时没有任何现场信息，所以只在被证明是瓶颈、且这个异常属于"预期内的常态"时使用。

### 各写法的相对成本（同一台机器上的量级感受）

- `if (x == null)` 判空后返回：纳秒级，最便宜，也是首选
- 抛一次 `IllegalArgumentException`（栈深 10 层左右）：微秒级
- try-with-resources 相比手写 try + finally：运行时多一段编译器生成的 `addSuppressed` 与判空逻辑，正常情况下差异可以忽略
- `Files.readAllLines(path)`：内存约等于文件字节数放大两到三倍（字符串对象 + 数组），百兆级文件就应当改成 `Files.lines(path)` 流式逐行处理
- 在循环里 `log.error("...", e)`：单条日志的格式化与 IO 会主导耗时，比异常本身贵得多

### 什么时候该换写法而不是换心态

批处理任务里"每条记录都可能失败一次"是很常见的：一百万行、坏行率 3% 就是三万个异常对象和三万次栈填充。此时应该把校验前移——先 `if (!line.contains(","))` 之类快速筛掉明显非法行，把异常留给真正意外的情况。**能预见的失败要用判断表达，不能用异常表达**，这条既是可读性规则，也是性能规则。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 捕获后什么都不做 | 问题被彻底掩盖 | 至少记录日志或重新抛出 |
| catch (Exception e) 一把抓 | 掩盖真正的 bug | 先捕获具体类型 |
| 用异常做流程控制 | 又慢又难读 | 能用判断就用判断 |
| finally 里 return | 覆盖返回值甚至吞掉异常 | finally 只做资源释放 |
| 丢掉 cause | 排查看不到根因 | 用带 cause 的构造方法 |
| 忘了关闭资源 | 句柄泄漏 | 用 try-with-resources |
| 自定义异常太多 | 没人能记住 | 只在需要区别处理时才自定义 |
| 只在 catch 里 `e.printStackTrace()` | 现场信息跑到标准错误，生产上按级别过滤不到，也带不上业务上下文 | 交给日志框架并把异常对象本身传进去，必要时再向上抛 |
| 包装异常时只留一句"处理失败" | 栈里只有一层，根因看不见 | 用 `(message, cause)` 构造，让 Caused by 完整保留 |
| 把可预见的失败写成异常流 | 循环里反复抛接异常，性能与可读性双输 | 能判断就先判断，异常只留给"真的意外" |
| 自定义异常不带 `(String, Throwable)` 构造 | 使用者想保留原因链时只能丢掉 cause | 至少提供无参、带消息、带消息加 cause 三个构造 |
| 以为 try-with-resources 里的变量可随便换 | 关闭时用的可能不是你以为的那个对象 | 资源要么在括号内声明，Java 9 起可传入外部变量，但必须是 final 或事实 final |
| finally 里做耗时清理或再次抛异常 | 原异常被掩盖，主流程还被拖慢 | finally 只承担必要释放；清理自身失败要单独包住 |
| 用返回 null 表示"出错了" | 错误延迟到很远的地方炸成 NullPointerException | 要么抛出有语义的异常，要么返回 Optional |

## 与其他知识点的关系

- **先修**：《集合框架与泛型》——集合操作可能抛异常
- **后续**：《Lambda 与 Stream API》——Stream 操作中的异常处理
- **关联**：《构建、测试与生态》——测试中需要断言异常

**同一套体系里的邻居**：`finally` 解决"一定要做"，`try-with-resources` 解决"一定要关"，`throws` 解决"谁来兜"，自定义异常解决"能不能区分对待"。这四问凑齐，一段文件处理代码的职责就分清了；写的时候按"资源 → 清理 → 传播 → 语义"的顺序逐项回答即可。

**测试视角**：异常也是要测的分支。JUnit 5 用 `assertThrows(IllegalArgumentException.class, () -> svc.transfer(from, to, -1))` 断言类型，接住的返回值还能进一步检查消息与 cause，确保包装时没丢原因链。给坏数据写一条测试，比在正文里读十条规则记得牢。

**版本口径**：本课示例基于 JDK 17 及以上；单文件源码模式（`java Demo.java`）自 JDK 11 起可用，`List<Throwable> getSuppressed()` 自 JDK 9 起取代原来的数组返回，try-with-resources 括号里直接传入外部的 final 或事实 final 变量同样是 JDK 9 才有的写法，而联合 catch 本身要追溯到 JDK 7。换到较低版本 JDK 上编译前先确认这几点，别让"我这能跑"变成别人的排查成本。

## 自测题与参考答案

1. **受检异常和非受检异常有什么区别？** 受检异常编译器强制处理（IOException），非受检异常不强制（NullPointerException）。
2. **为什么 finally 里不该写 return？** 会覆盖 try 中的返回值，甚至吞掉异常。
3. **try-with-resources 比 try-finally 好在哪？** 自动关闭资源，代码更简洁，异常处理更正确。
4. **抛异常时为什么要保留 cause？** 方便排查根因，否则只看到一句"失败了"。
5. **什么时候该自定义异常？** 调用方需要针对不同错误做不同处理时。

## 考点精讲

`异常处理与文件 IO` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据。

### 考点 1：第 1 题

- **题目**：围绕“异常处理与文件 IO”中的 异常、try、catch，下列哪两项是本课强调的实践判断？
- **正确项**：学习 异常 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 try 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：按《异常处理与文件 IO》的正文口径，本题要同时选中「学习 异常 时要同时说明输入、输出和失败路径，不能只看正常流程」、「验证 try 时要固定版本并覆盖边界输入，结论才可复现」，漏掉任一项都算没答全。术语 异常（异常处理与文件 IO）：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换。易错点是捕获后什么都不做，会造成问题被彻底掩盖，改法是至少记录日志或重新抛出。

### 考点 2：第 2 题

- **题目**：这段 `java` 代码对应 `异常处理与文件 IO` 的 `AutoCloseable`。课程要解决的是受检/非受检异常、try-with-resources、NIO.2 与自定义异常。关于代码内容，哪一项说法准确？
- **正确项**：调用了 `BalanceException()`
- **判断依据**：本题正确项是「调用了 `BalanceException()`」。术语 AutoCloseable（异常处理与文件 IO）：实现 `AutoCloseable` 的资源会在代码块结束时自动关闭，异常也不会漏关，本题取「调用了 `BalanceException()`」这条。易错点是catch (Exception e) 一把抓，会造成掩盖真正的 bug，改法是先捕获具体类型。本题干扰项「调用了 `Color()`」不成立：展示代码里找不到 `Color()`。

### 考点 3：第 3 题

- **题目**：多个 catch 子句的书写顺序要求是？
- **正确项**：子类异常必须在前
- **判断依据**：本题正确项是「子类异常必须在前」。术语 异常（异常处理与文件 IO）：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换，本题取「子类异常必须在前」这条。易错点是用异常做流程控制，会造成又慢又难读，改法是能用判断就用判断。易错点是finally 里 return，会造成覆盖返回值甚至吞掉异常，改法是finally 只做资源释放。

### 考点 4：第 4 题

- **题目**：在 finally 中写 return 的风险是？
- **正确项**：会覆盖 try 中的返回值甚至吞掉异常
- **判断依据**：本题正确项是「会覆盖 try 中的返回值甚至吞掉异常」。术语 异常（异常处理与文件 IO）：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换，本题取「会覆盖 try 中的返回值甚至吞掉异常」这条。易错点是finally 里 return，会造成覆盖返回值甚至吞掉异常，改法是finally 只做资源释放。

### 考点 5：第 5 题

- **题目**：抛出异常时想保留原始异常信息，正确做法是？
- **正确项**：new RuntimeException("处理失败", cause)
- **判断依据**：本题正确项是「new RuntimeException("处理失败", cause)」。术语 异常（异常处理与文件 IO）：程序执行中偏离正常控制流的错误事件，需要捕获、传播或转换，本题取「new RuntimeException("处理失败", cause)」这条。易错点是丢掉 cause，会造成排查看不到根因，改法是用带 cause 的构造方法。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `受检/非受检异常、try-with-resources、NIO.2 与自定义异常。`，这段说明是：尽早失败：参数校验失败立刻抛 ``____``。空缺处应填哪个术语？
- **正确项**：IllegalArgumentException
- **判断依据**：正确项：「IllegalArgumentException」。涉及术语 IllegalArgumentException：尽早失败：参数校验失败立刻抛 `IllegalArgumentException`。易错点：捕获后什么都不做会造成问题被彻底掩盖。正确做法：至少记录日志，或重新抛出。本题要填的是「IllegalArgumentException」。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| 受检异常 | 编译器强制处理，如 IOException |
| 非受检异常 | RuntimeException 子类，通常是编程错误 |
| try-with-resources | 自动关闭 AutoCloseable 资源 |
| finally | 无论是否异常都执行的清理代码 |
| cause | 原始异常，保留在异常链中便于排查 |
| IllegalArgumentException | 参数校验失败时抛出的非受检异常 |
| 栈展开 | 异常抛出后沿调用栈逐层回退、寻找匹配 catch 的过程 |
| 联合 catch | 一条 catch 用竖线接住多种互不相干的异常类型 |
| suppressed | 关闭资源时新抛出的异常，被附在主异常上而不顶替它 |
| fillInStackTrace | 异常构造时记录调用栈的步骤，也是异常开销的主要来源 |
| UncheckedIOException | 把 IOException 包进非受检异常的 JDK 标准适配器 |
| assertThrows | JUnit 5 中断言某段代码抛出指定异常的测试工具 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE 官方教程：异常](https://docs.oracle.com/javase/tutorial/essential/exceptions/) | 异常处理基础语法 |
| [Java SE API 文档](https://docs.oracle.com/en/java/javase/21/docs/api/) | NIO.2 与异常类 API 查询 |
| [dev.java 学习路径](https://dev.java/learn/) | 现代 Java 官方入门教程 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：异常、try、catch、finally、AutoCloseable、NIO.2
