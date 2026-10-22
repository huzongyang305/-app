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
