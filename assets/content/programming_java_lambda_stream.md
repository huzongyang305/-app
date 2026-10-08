# Lambda 与 Stream API

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![Lambda 与 Stream 的流水线](images/diagram_java_stream.webp)

![Lambda 与 Stream API](images/remaining_java_lambda_stream.webp)

## 本节知识框架

**课程定位**：所属分类 `java`（Java），课程主题 `Lambda 与 Stream API`，学习阶段 进阶，建议用时 50 分钟。

本课主线：函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。

**学完本课应当能够**
- 说清 `Optional` 与 `函数式接口` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `并行流` 的行为，记录输入、输出与失败条件。
- 遇到「把 Stream 当集合复用」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `Optional`：先掌握 .findFirst()，再用它解释 `函数式接口` 为什么会出现。
2. `函数式接口`：先掌握 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现，再用它解释 `并行流` 为什么会出现。
3. `并行流`：先掌握 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用，再用它解释 `方法引用` 为什么会出现。
4. `方法引用`：先掌握 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Java」分类的第 13 课。先修内容：《异常处理与文件 IO》。《异常处理与文件 IO》里的 `AutoCloseable`、`printStackTrace` 是本课的前提。相关或后续课程：《多线程与并发》。

### 完成判据

- **定义关**：不看正文也能说明 `Optional` 是 .findFirst()，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `Lambda 与 Stream API`，而不是只背结论。
- **示例关**：能运行或推演 `Lambda 与 Stream API` 的 `java` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `Lambda 与 Stream API` 示例里的 调用了 `apply()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 把 Stream 当集合复用，记录现象并按 每条流水线只用一个流 修复。
- **迁移关**：能把 `lambda`、`Stream`、`Optional`、`函数式接口` 放进一个与 `Lambda 与 Stream API` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `Lambda 与 Stream API` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| Optional | .findFirst()。 | 易错：直接 `get()` 抛异常；正确做法是用 `orElse`、`ifPresent`。 |
| 函数式接口 | 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。 | 只在「只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现」这一前提下成立，换输入或换环境要重新验证。 |
| 并行流 | 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。 | 易错：结果错乱或更慢；正确做法是只在数据量大且无副作用时用。 |
| 方法引用 | 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。 | 只在「用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读」这一前提下成立，换输入或换环境要重新验证。 |

## 原理与运行机制

### 机制总览

**教材衔接：版本与时效**

- 版本基线会影响 lambda 的可用 API，升级前先用编译与测试验证。
- 虚拟线程与结构化并发对 lambda 的影响最大，升级前先确认线程模型。
- 升级「Lambda 与 Stream API」涉及的依赖前，先用 FunctionalInterface 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 lambda 相关的差异单独记成一条结论。
- 升级后重点回归 lambda 的默认值、警告信息与错误格式。
- 升级后把 FunctionalInterface 的实测版本写进「内容元数据」，再更新复核日期。

**失败路径（来自本课错误表）**
- 把 Stream 当集合复用 → `IllegalStateException: stream has already been operated upon` → 每条流水线只用一个流。
- 中间操作不触发执行 → 什么也没发生 → 必须有终止操作。
- Lambda 里改变量 → 编译错误 → 捕获的局部变量必须是事实上的 final。
- 在循环里反复建流 → 性能变差 → 一次流水线完成。
### 机制拆解：每一步的输入、动作与输出

#### 1. `Optional`
- 输入：`lambda`；本步把 .findFirst() 当作判断规则。
- 动作：围绕 `Optional` 保留中间状态，并记录它与 `函数式接口` 的对应关系。
- 输出：`函数式接口`，它可以被下一段代码、测试或记录继续使用。
- `Optional` 的失败条件：当忘记处理 Optional时，会出现直接 `get()` 抛异常。

#### 2. `函数式接口`
- 输入：`Optional`；本步把 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现 当作判断规则。
- 动作：围绕 `函数式接口` 保留中间状态，并记录它与 `并行流` 的对应关系。
- 输出：`并行流`，它可以被下一段代码、测试或记录继续使用。
- `函数式接口` 的失败条件：只在「只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现」这一前提下成立，换输入或换环境要重新验证。

#### 3. `并行流`
- 输入：`函数式接口`；本步把 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用 当作判断规则。
- 动作：围绕 `并行流` 保留中间状态，并记录它与 `方法引用` 的对应关系。
- 输出：`方法引用`，它可以被下一段代码、测试或记录继续使用。
- `并行流` 的失败条件：当乱用并行流时，会出现结果错乱或更慢。

#### 4. `方法引用`
- 输入：`并行流`；本步把 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读 当作判断规则。
- 动作：围绕 `方法引用` 保留中间状态，并记录它与 `apply` 的对应关系。
- 输出：`apply`，它可以被下一段代码、测试或记录继续使用。
- `方法引用` 的失败条件：只在「用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读」这一前提下成立，换输入或换环境要重新验证。

### 示例中的可观察事实

1. 调用了 `apply()`；它对应的课程主题是 `Lambda 与 Stream API`。
2. 调用了 `println()`；它对应的课程主题是 `Lambda 与 Stream API`。
3. 调用了 `stream()`；它对应的课程主题是 `Lambda 与 Stream API`。
4. 调用了 `filter()`；它对应的课程主题是 `Lambda 与 Stream API`。
5. 调用了 `length()`；它对应的课程主题是 `Lambda 与 Stream API`。
6. 调用了 `map()`；它对应的课程主题是 `Lambda 与 Stream API`。
7. 调用了 `sorted()`；它对应的课程主题是 `Lambda 与 Stream API`。
8. 调用了 `distinct()`；它对应的课程主题是 `Lambda 与 Stream API`。

### 复现实验记录

- 环境：`Lambda 与 Stream API` 使用 `java` 示例，固定 `lambda`、`Stream`、`Optional`、`函数式接口` 作为第一组条件。
- 首轮输入：先确认 调用了 `apply()`，预测 `Optional` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `lambda`，观察 `方法引用` 是否仍满足定义。
- 失败注入：复现 把 Stream 当集合复用，确认现象是 `IllegalStateException: stream has already been operated upon`。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `Lambda 与 Stream API` 时才能区分概念错误与实现错误。

## 典型应用场景

- **把 Stream 当集合复用**：典型现象是`IllegalStateException: stream has already been operated upon`；正确做法是每条流水线只用一个流。
- **中间操作不触发执行**：典型现象是什么也没发生；正确做法是必须有终止操作。
- **Lambda 里改变量**：典型现象是编译错误；正确做法是捕获的局部变量必须是事实上的 final。
- **在循环里反复建流**：典型现象是性能变差；正确做法是一次流水线完成。

### 最小验证场景

- 准备：保留 `java` 示例的原始输入，先记录 `Lambda 与 Stream API` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `apply()`，再改变一个与 `Optional` 相关的条件。
- 判定：新结果与 `Lambda 与 Stream API` 的基线不同不等于错误；只有当差异破坏了 `Optional` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `Optional` 时，先满足它的定义：.findFirst()；易错：直接 `get()` 抛异常；正确做法是用 `orElse`、`ifPresent`。
- 使用 `函数式接口` 时，先满足它的定义：只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现；只在「只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现」这一前提下成立，换输入或换环境要重新验证。
- 使用 `并行流` 时，先满足它的定义：并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用；易错：结果错乱或更慢；正确做法是只在数据量大且无副作用时用。
- 使用 `方法引用` 时，先满足它的定义：用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读；只在「用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读」这一前提下成立，换输入或换环境要重新验证。

## 代码/协议/SQL 示例

### 最小可验证示例

```java
@FunctionalInterface
interface Calculator {
    int apply(int a, int b);
}

Calculator add = (a, b) -> a + b;
Calculator max = Integer::max;          // 方法引用

System.out.println(add.apply(1, 2));
```

**教材衔接：函数式接口**

只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。

JDK 内置四大接口：

| 接口 | 签名 | 用途 |
| --- | --- | --- |
| `Supplier<T>` | `() -> T` | 提供值 |
| `Consumer<T>` | `T -> void` | 消费值 |
| `Function<T,R>` | `T -> R` | 转换 |
| `Predicate<T>` | `T -> boolean` | 判断 |

**教材衔接：Stream 常用操作**

```java
import java.util.*;
import java.util.stream.*;

List<String> names = List.of("tom", "alice", "bob", "anna");

List<String> result = names.stream()
        .filter(n -> n.length() > 3)          // 中间操作：惰性
        .map(String::toUpperCase)            // 转换
        .sorted()                            // 排序
        .distinct()                          // 去重
        .limit(10)
        .collect(Collectors.toList());       // 终止操作：触发执行

System.out.println(result);

// 分组与统计
Map<Integer, List<String>> byLength = names.stream()
        .collect(Collectors.groupingBy(String::length));

long count = names.stream().filter(n -> n.startsWith("a")).count();
int totalLength = names.stream().mapToInt(String::length).sum();
```

中间操作（`filter`/`map`/`sorted`）不会立刻执行，只有遇到终止操作（`collect`/`forEach`/`count`/`reduce`）才会遍历一次。

**教材衔接：Optional**

```java
Optional<String> maybe = names.stream()
        .filter(n -> n.startsWith("z"))
        .findFirst();

String value = maybe.orElse("默认值");
maybe.ifPresent(System.out::println);

// 不要用 optional.get()，先判断或使用 orElseThrow
```

**教材衔接：并行流与注意事项**

```java
long total = IntStream.rangeClosed(1, 1_000_000)
        .parallel()
        .filter(n -> n % 2 == 0)
        .count();
```

并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。

**教材衔接：Stream 操作速查**

| 类别 | 方法 | 作用 |
| --- | --- | --- |
| 创建 | `list.stream()`、`Stream.of(...)`、`IntStream.range(0, n)` | 生成流 |
| 中间操作 | `filter` | 过滤 |
| 中间操作 | `map` / `mapToInt` | 映射（后者避免装箱） |
| 中间操作 | `flatMap` | 一个元素展开成多个 |
| 中间操作 | `distinct` / `sorted` / `limit` / `skip` | 去重、排序、截断、跳过 |
| 中间操作 | `peek` | 调试用，正式代码慎用 |
| 终止操作 | `collect(Collectors.toList())` | 收集成集合 |
| 终止操作 | `toList()`（Java 16+） | 更简洁的收集 |
| 终止操作 | `count` / `sum` / `average` / `max` / `min` | 统计 |
| 终止操作 | `anyMatch` / `allMatch` / `noneMatch` | 条件判断（可短路） |
| 终止操作 | `findFirst` / `findAny` | 取元素，返回 `Optional` |
| 终止操作 | `forEach` | 副作用，避免在流里改外部状态 |
| 终止操作 | `reduce` | 归约成单个值 |

收集器速查：

| 目的 | 写法 |
| --- | --- |
| 收集成 List | `.collect(Collectors.toList())` |
| 收集成 Set | `.collect(Collectors.toSet())` |
| 收集成 Map | `.collect(Collectors.toMap(Key::get, Value::get, (a, b) -> a))` |
| 分组 | `.collect(Collectors.groupingBy(Item::category))` |
| 分组后计数 | `.collect(Collectors.groupingBy(Item::cat, Collectors.counting()))` |
| 分组后求平均 | `.collect(Collectors.groupingBy(Item::cat, Collectors.averagingInt(Item::price)))` |
| 分区（按布尔） | `.collect(Collectors.partitioningBy(Item::active))` |
| 拼接字符串 | `.collect(Collectors.joining(", ", "[", "]"))` |

```java
// 常见组合：过滤 -> 去重 -> 排序 -> 取前 3 -> 转列表
List<String> top = orders.stream()
        .filter(Order::paid)
        .map(Order::userId)
        .distinct()
        .sorted()
        .limit(3)
        .toList();

// 分组统计：每个类目的订单总额
Map<String, Integer> amountByCategory = orders.stream()
        .collect(Collectors.groupingBy(
                Order::category,
                Collectors.summingInt(Order::amount)));
```

**教材衔接：零基础详解：Lambda 与 Stream 流水线**

### 一句话说清它是什么

Lambda 是「把一小段行为当成参数传进去」，Stream 是「用一串链式操作处理集合」。
两者配合，能把过去要写十几行的循环压缩成一条清晰的数据流水线。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 函数式接口 | 只干一件事的岗位 | 只有一个抽象方法，才能用 Lambda |
| Lambda | 临时工 | 现场写一段行为，不用新建类 |
| 方法引用 | 直接派老员工上 | 已有方法可复用，写法更短 |
| Stream | 流水线 | 一环一环加工数据 |
| 中间操作 | 加工工位 | `filter`、`map`，返回新流 |
| 终止操作 | 出货口 | `collect`、`sum`，触发实际计算 |

### Lambda 的四步演化

```java
List<String> names = List.of("小明", "小红", "小刚");

// 1. 匿名内部类（老写法，啰嗦）
names.forEach(new Consumer<String>() {
    @Override
    public void accept(String s) { System.out.println(s); }
});

// 2. Lambda
names.forEach(s -> System.out.println(s));

// 3. 方法引用（更短）
names.forEach(System.out::println);

// 4. 带条件与方法链
names.stream()
     .filter(s -> s.startsWith("小"))
     .map(String::toUpperCase)
     .forEach(System.out::println);
```

### 四个内置函数式接口

| 接口 | 输入 | 输出 | 典型用途 |
| --- | --- | --- | --- |
| `Function<T,R>` | T | R | 映射变换 |
| `Consumer<T>` | T | 无 | 遍历打印、写库 |
| `Supplier<T>` | 无 | T | 延迟创建对象 |
| `Predicate<T>` | T | boolean | 条件过滤 |

### Stream 常用操作

```java
record Student(String name, String team, int score) {}

var students = List.of(
    new Student("小明", "A", 88),
    new Student("小红", "B", 95),
    new Student("小刚", "A", 59),
    new Student("小美", "B", 72)
);

// 过滤 + 映射 + 收集
List<String> passed = students.stream()
    .filter(s -> s.score() >= 60)
    .map(Student::name)
    .toList();

// 分组
Map<String, List<Student>> byTeam = students.stream()
    .collect(Collectors.groupingBy(Student::team));

// 聚合
double average = students.stream()
    .mapToInt(Student::score)
    .average()
    .orElse(0);

// 转成映射表
Map<String, Integer> scoreMap = students.stream()
    .collect(Collectors.toMap(Student::name, Student::score));
```

| 操作 | 类型 | 作用 |
| --- | --- | --- |
| `filter` | 中间 | 按条件筛选 |
| `map` / `mapToInt` | 中间 | 转换元素或转基本类型流 |
| `sorted` / `distinct` / `limit` | 中间 | 排序、去重、截断 |
| `collect` / `toList` | 终止 | 收集结果 |
| `reduce` | 终止 | 自定义聚合 |
| `anyMatch` / `allMatch` | 终止 | 条件判断 |
| `findFirst` | 终止 | 取第一个（配合 Optional） |

### Optional：不用再返回 null

```java
Optional<Student> top = students.stream()
    .max(Comparator.comparingInt(Student::score));

String name = top.map(Student::name).orElse("无数据");
top.ifPresent(s -> System.out.println("最高分：" + s.name()));

// 注意：orElse 无论是否需要都会执行参数；需要延迟创建用 orElseGet
String value = top.map(Student::name).orElseGet(() -> "计算出来的默认值");
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 把 Stream 当集合复用 | `IllegalStateException: stream has already been operated upon` | 每条流水线只用一个流 |
| 中间操作不触发执行 | 什么也没发生 | 必须有终止操作 |
| Lambda 里改变量 | 编译错误 | 捕获的局部变量必须是事实上的 final |
| 在循环里反复建流 | 性能变差 | 一次流水线完成 |
| 乱用并行流 | 结果错乱或更慢 | 只在数据量大且无副作用时用 |
| `toMap` 键重复 | `IllegalStateException` | 提供合并函数 |
| 用 `orElse` 做重计算 | 每次都白算 | 改用 `orElseGet` |
| 忘记处理 Optional | 直接 `get()` 抛异常 | 用 `orElse`、`ifPresent` |

### 手把手练习：生成成绩报表

```java
import java.util.*;
import java.util.stream.*;

public class Report {
    record Student(String name, String team, int score) {}

    public static void main(String[] args) {
        var students = List.of(
            new Student("小明", "A", 88),
            new Student("小红", "B", 95),
            new Student("小刚", "A", 59),
            new Student("小美", "B", 72)
        );

        Map<String, IntSummaryStatistics> stats = students.stream()
            .collect(Collectors.groupingBy(
                Student::team,
                Collectors.summarizingInt(Student::score)));

        stats.forEach((team, s) -> System.out.printf(
            "%s 队：%d 人，均分 %.1f，最高 %d%n",
            team, s.getCount(), s.getAverage(), s.getMax()));

        String topNames = students.stream()
            .filter(s -> s.score() >= 80)
            .sorted(Comparator.comparingInt(Student::score).reversed())
            .map(Student::name)
            .collect(Collectors.joining("、"));
        System.out.println("80 分以上：" + topNames);
    }
}
```

### 学完自测

- [ ] 能说出 Lambda 与匿名内部类的关系。
- [ ] 能区分 Stream 的中间操作与终止操作。
- [ ] 知道为什么中间操作不写终止操作就不会执行。
- [ ] 能说出 `orElse` 与 `orElseGet` 的差别。
- [ ] 会用 `groupingBy` 加 `summarizingInt` 生成分组统计。

**运行方式**：运行 `Lambda 与 Stream API` 的示例时，保存为 `.java` 后用 `javac` 编译、`java` 运行；注意类名与文件名一致。

### 示例精读：先找证据，再改一个条件

1. 调用了 `apply()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `println()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `stream()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `filter()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `length()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `map()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `sorted()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `distinct()`；它出现在 `Lambda 与 Stream API` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `Lambda 与 Stream API` 中与 `Optional` 对照：示例必须能支持 .findFirst()，否则说明这一段还缺少实现或验证步骤。
- 在 `Lambda 与 Stream API` 中与 `函数式接口` 对照：示例必须能支持 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现，否则说明这一段还缺少实现或验证步骤。
- 在 `Lambda 与 Stream API` 中与 `并行流` 对照：示例必须能支持 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用，否则说明这一段还缺少实现或验证步骤。
- 在 `Lambda 与 Stream API` 中与 `方法引用` 对照：示例必须能支持 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

| 误用 | 后果 | 正确做法 |
| --- | --- | --- |
| 在 forEach 里修改外部集合 | 并发修改异常或结果不确定 | 用 collect 生成新集合 |
| 中途忘记终止操作 | 代码根本不执行（流是惰性的） | 以 collect/forEach/reduce 收尾 |
| 在流里做重 IO 或远程调用 | 延迟叠加、线程池被打满 | 外提为批量操作或异步任务 |
| 无脑用 parallelStream | 公共 ForkJoinPool 被占满，拖慢全局 | 仅纯计算且数据量大时用，或自定义池 |
| 反复遍历同一个流 | 流只能消费一次，第二次抛异常 | 需要多次使用先 collect 成集合 |

**测量方法**：以 `Lambda 与 Stream API` 的 `lambda` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `Lambda 与 Stream API` 的 `lambda`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Lambda 与 Stream API` 的 `Stream`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Lambda 与 Stream API` 的 `Optional`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Lambda 与 Stream API` 的 `函数式接口`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Lambda 与 Stream API` 的 `collect`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Lambda 与 Stream API` 中 `Optional` 的边界：易错：直接 `get()` 抛异常；正确做法是用 `orElse`、`ifPresent`。达到边界时不要外推，必须重新测量。
- `Lambda 与 Stream API` 中 `函数式接口` 的边界：只在「只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `Lambda 与 Stream API` 中 `并行流` 的边界：易错：结果错乱或更慢；正确做法是只在数据量大且无副作用时用。达到边界时不要外推，必须重新测量。
- `Lambda 与 Stream API` 中 `方法引用` 的边界：只在「用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `Lambda 与 Stream API` 的代码证据：先验证 调用了 `apply()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把 Stream 当集合复用 | `IllegalStateException: stream has already been operated upon` | 每条流水线只用一个流 |
| 中间操作不触发执行 | 什么也没发生 | 必须有终止操作 |
| Lambda 里改变量 | 编译错误 | 捕获的局部变量必须是事实上的 final |
| 在循环里反复建流 | 性能变差 | 一次流水线完成 |
| 乱用并行流 | 结果错乱或更慢 | 只在数据量大且无副作用时用 |
| `toMap` 键重复 | `IllegalStateException` | 提供合并函数 |
| 用 `orElse` 做重计算 | 每次都白算 | 改用 `orElseGet` |
| 忘记处理 Optional | 直接 `get()` 抛异常 | 用 `orElse`、`ifPresent` |
| 在 forEach 里修改外部集合 | 并发修改异常或结果不确定 | 用 collect 生成新集合 |
| 中途忘记终止操作 | 代码根本不执行（流是惰性的） | 以 collect/forEach/reduce 收尾 |
| 在流里做重 IO 或远程调用 | 延迟叠加、线程池被打满 | 外提为批量操作或异步任务 |
| 无脑用 parallelStream | 公共 ForkJoinPool 被占满，拖慢全局 | 仅纯计算且数据量大时用，或自定义池 |
| 反复遍历同一个流 | 流只能消费一次，第二次抛异常 | 需要多次使用先 collect 成集合 |
| 流被重复消费 | `IllegalStateException: stream has already been operated upon or closed` | 流只能消费一次，需要复用就重新 `stream()` |
| 忘记写终止操作 | 什么都不执行 | `filter`、`map` 都是惰性的，必须 `collect`、`forEach` 等触发 |
| 在 `forEach` 里修改外部集合 | 代码难以推理，并行时出错 | 用 `collect` 生成结果，避免副作用 |
| 用并行流处理 IO | 线程池被占满，性能更差 | 并行流适合纯 CPU 计算，IO 用专门的线程池 |
| `toMap` 遇到重复键 | `IllegalStateException: Duplicate key` | 提供合并函数 `(a, b) -> a` |
| `toMap` 的 value 为 null | `NullPointerException` | 先过滤或改用 `HashMap` 手动填充 |
| `Optional.get()` 直接取值 | `NoSuchElementException` | 用 `orElse`、`orElseThrow`、`ifPresent` |
| `map` 里返回 `null` | 后续出现空指针 | 用 `flatMap` + `Optional` 过滤空值 |
| 在 `peek` 里做核心逻辑 | 可能被优化掉或跳过 | `peek` 只用于调试 |
| 大量装箱操作 | 性能下降 | 用 `mapToInt`、`IntStream` 等原始类型流 |
| 用 `sorted()` 排大集合 | 慢且占内存 | 数据量大时考虑数据库排序或 TopK 结构 |

### 现场 1：把 Stream 当集合复用

**症状**：`IllegalStateException: stream has already been operated upon`。

**根因与修复**：每条流水线只用一个流。

**自检**：在本课示例里复现「把 Stream 当集合复用」，改成每条流水线只用一个流后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：中间操作不触发执行

**症状**：什么也没发生。

**根因与修复**：必须有终止操作。

**自检**：在本课示例里复现「中间操作不触发执行」，改成必须有终止操作后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：Lambda 里改变量

**症状**：编译错误。

**根因与修复**：捕获的局部变量必须是事实上的 final。

**自检**：在本课示例里复现「Lambda 里改变量」，改成捕获的局部变量必须是事实上的 final后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：在循环里反复建流

**症状**：性能变差。

**根因与修复**：一次流水线完成。

**自检**：在本课示例里复现「在循环里反复建流」，改成一次流水线完成后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：乱用并行流

**症状**：结果错乱或更慢。

**根因与修复**：只在数据量大且无副作用时用。

**自检**：在本课示例里复现「乱用并行流」，改成只在数据量大且无副作用时用后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：`toMap` 键重复

**症状**：`IllegalStateException`。

**根因与修复**：提供合并函数。

**自检**：在本课示例里复现「`toMap` 键重复」，改成提供合并函数后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：用 `orElse` 做重计算

**症状**：每次都白算。

**根因与修复**：改用 `orElseGet`。

**自检**：在本课示例里复现「用 `orElse` 做重计算」，改成改用 `orElseGet`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：忘记处理 Optional

**症状**：直接 `get()` 抛异常。

**根因与修复**：用 `orElse`、`ifPresent`。

**自检**：在本课示例里复现「忘记处理 Optional」，改成用 `orElse`、`ifPresent`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：在 forEach 里修改外部集合

**症状**：并发修改异常或结果不确定。

**根因与修复**：用 collect 生成新集合。

**自检**：在本课示例里复现「在 forEach 里修改外部集合」，改成用 collect 生成新集合后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`异常处理与文件 IO`。本课默认这些内容已经掌握。
- **相关或后续**：`多线程与并发`。本课术语会在这些课程里继续使用。
- **术语归属**：`Optional`、`函数式接口`、`并行流` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。

### 先修与后续术语接口

- `异常处理与文件 IO`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `多线程与并发`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `Optional` 与 `函数式接口`：前者强调 .findFirst()；后者强调 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `函数式接口` 与 `并行流`：前者强调 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现；后者强调 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `并行流` 与 `方法引用`：前者强调 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用；后者强调 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `Optional` 的操作性定义，并说明它与 `函数式接口` 的区别。

**参考答案**：.findFirst()。

`函数式接口` 的定位是：只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「把 Stream 当集合复用」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是`IllegalStateException: stream has already been operated upon`；正确做法是每条流水线只用一个流。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `java` 示例，把其中的 `1` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `java` 示例应当复现正文给出的结果；把 `1` 换成边界值后，如果结果改变或报错，先核对它是否满足 `Lambda 与 Stream API` 中`Optional` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `java` 示例，说明它体现了`Optional` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`Optional` 的定义是 .findFirst()，示例正是在实现这条定义。改动与 `Optional` 有关的一个输入后，如果结果不再符合 `Lambda 与 Stream API` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `Lambda 与 Stream API` 的方法迁移到自己的项目：围绕 `Optional` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「用 `sorted()` 排大集合」，它会导致慢且占内存；检验方式是按数据量大时考虑数据库排序或 TopK 结构改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `Optional` 与 `函数式接口`：各写一行适用场景、一行失败表现。

**参考答案**：`Optional` 的定义是.findFirst()；`函数式接口` 的定义是只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「把 Stream 当集合复用」引发的问题，请把“复现 `IllegalStateException: stream has already been operated upon` → 保留证据 → 每条流水线只用一个流 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按`IllegalStateException: stream has already been operated upon`复现；第二步记录输入、版本与完整报错；第三步按每条流水线只用一个流只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `方法引用`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：只在「用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读」这一前提下成立，换输入或换环境要重新验证。 同时要把 `方法引用` 的定义 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `Optional` → `函数式接口` → `并行流` → `方法引用` 的作用链。

**参考答案**：起点是 `Optional` 的定义 .findFirst()；中间每一步都保留可观察状态；终点由 `方法引用` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `Lambda 与 Stream API` 中，现象是 慢且占内存。请围绕 用 `sorted()` 排大集合 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 用 `sorted()` 排大集合，记录输入与完整错误；再按 数据量大时考虑数据库排序或 TopK 结构 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `Lambda 与 Stream API`：先给主问题，再按顺序说出 `Optional`、`函数式接口`、`并行流`、`方法引用`，最后给一个失败案例。

**自评标准**：主问题必须对应 函数式接口、方法引用、Stream 惰性求值、Optional 与并行流；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Optional` | .findFirst()。 |
| `函数式接口` | 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。 |
| `并行流` | 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。 |
| `方法引用` | 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。 |

**术语关系**：`Optional`（.findFirst()） → `函数式接口`（只有一个抽象方法的接口就是函数式接口） → `并行流`（并行流使用公共 ForkJoinPool） → `方法引用`（用双冒号语法把已有方法当作函数式接口的实现）。

## 考点精讲

`Lambda 与 Stream API` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：Stream 的中间操作（filter/map）什么时候真正执行？
- **正确项**：遇到终止操作时才执行
- **判断依据**：这道题检验本课主问题：函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 2：第 2 题

- **题目**：代码语言为 `java`，选自 `Lambda 与 Stream API` 的 `Optional` 部分。课程问题为函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。哪一项描述与代码一致？
- **正确项**：调用了 `length()`
- **判断依据**：这道题落在术语 `Optional` 上：.findFirst()。复习时把 `Optional` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：围绕“Lambda 与 Stream API”中的 lambda、Stream、Optional，下列哪两项是本课强调的实践判断？
- **正确项**：验证 Stream 时要固定版本并覆盖边界输入，结论才可复现；学习 lambda 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `Optional` 上：.findFirst()。复习时把 `Optional` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：Stream 的 collect 与 forEach 的区别是？
- **正确项**：collect 是终止操作
- **判断依据**：这道题检验本课主问题：函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 5：第 5 题

- **题目**：方法引用 String::length 等价于哪个 lambda？
- **正确项**：s -> s.length
- **判断依据**：这道题落在术语 `方法引用` 上：用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。复习时把 `方法引用` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。`，这段说明是：`____`使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。空缺处应填哪个术语？
- **正确项**：并行流
- **判断依据**：这道题落在术语 `Optional` 上：.findFirst()。复习时把 `Optional` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`Optional`

- **要点**：.findFirst()。
- **Optional 的边界**：易错：直接 `get()` 抛异常；正确做法是用 `orElse`、`ifPresent`。

### 考点 8：`函数式接口`

- **要点**：只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。
- **函数式接口 的边界**：只在「只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现」这一前提下成立，换输入或换环境要重新验证。

### 考点 9：`并行流`

- **要点**：并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。
- **并行流 的边界**：易错：结果错乱或更慢；正确做法是只在数据量大且无副作用时用。

### 考点 10：`方法引用`

- **要点**：用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。
- **方法引用 的边界**：只在「用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读」这一前提下成立，换输入或换环境要重新验证。

### 考点 11：排错——把 Stream 当集合复用

- **现象**：`IllegalStateException: stream has already been operated upon`。
- **处理**：每条流水线只用一个流。

### 考点 12：排错——中间操作不触发执行

- **现象**：什么也没发生。
- **处理**：必须有终止操作。

### 考点 13：综合辨析——`Optional` 与 `方法引用`

- **辨析点**：`Optional` 的定义是 .findFirst()；`方法引用` 的定义是 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。
- **答题要求**：面对 `Lambda 与 Stream API` 的题目，先判断描述的是 `Optional` 还是 `方法引用`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 `IllegalStateException: stream has already been operated upon`，而不是只写“程序有错”。
- **证据分**：保留触发 把 Stream 当集合复用 的输入、版本和错误原文。
- **修复分**：按 每条流水线只用一个流 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
；本课聚焦 lambda。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：lambda、Stream、Optional、函数式接口、collect、并行流
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：lambda、Stream、Optional、函数式接口、collect、并行流。

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE API](https://docs.oracle.com/en/java/javase/21/docs/api/) | 标准库 API |
| [dev.java 学习](https://dev.java/learn/) | 现代 Java 官方教程 |
| [Maven 指南](https://maven.apache.org/guides/) | 依赖、生命周期与构建 |

| [本课术语索引：Lambda 与 Stream API](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「Lambda 与 Stream API」的链接用于离线阅读后的延伸核对；App 不会自动联网。