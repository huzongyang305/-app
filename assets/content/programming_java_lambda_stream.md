# Lambda 与 Stream API

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![Lambda 与 Stream 的流水线](images/diagram_java_stream.webp)

![Lambda 与 Stream API](images/remaining_java_lambda_stream.webp)

## 本节知识框架

**课程定位**：所属分类为「Java」，课程主题为「Lambda 与 Stream API」，学习阶段为「进阶」，建议用时 50 分钟。

**本课要解决的主问题**：函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Lambda 与 Stream API」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Lambda 与 Stream API」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「lambda」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《异常处理与文件 IO》

**学习位置**：本课位于《异常处理与文件 IO》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《构建、测试与生态》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Lambda 与 Stream API解决了什么问题，而不是只背术语。
- 能说清 「lambda」、「Stream」、「Optional」、「函数式接口」 之间的关系，并分别举出一个例子。
- 能把 lambda 放回「Lambda 与 Stream API」的知识体系，说明它和 Stream 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。

**教材衔接：前置知识**

- 先完成上一课《异常处理与文件 IO》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「异常处理与文件 IO」，或确认自己能独立跑通正文里的 FunctionalInterface 示例。
- 开始前先复习：lambda、Stream、Optional。
- 看不懂就直接缩小例子：只保留 lambda 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

Lambda + Stream 让集合处理变成声明式：**先说做什么（filter/map），再收集结果（collect）**。代码更短，但要注意惰性求值与副作用。

## 核心概念定义

> 阅读约定：本课先给「Lambda 与 Stream API」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Optional | .findFirst()。 | 仅在「Lambda 与 Stream API」明确给出的输入、版本与资源条件下成立。 |
| 函数式接口 | 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。 | 仅在「Lambda 与 Stream API」明确给出的输入、版本与资源条件下成立。 |
| 并行流 | 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。 | 仅在「Lambda 与 Stream API」明确给出的输入、版本与资源条件下成立。 |
| 方法引用 | 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。 | 仅在「Lambda 与 Stream API」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Lambda 与 Stream API」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Optional」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「函数式接口」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「并行流」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Lambda 与 Stream API」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Optional | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 函数式接口 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 并行流 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Lambda 与 Stream API」自己的示例验证。「Lambda 与 Stream API」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：版本与时效**

- 版本基线会影响 lambda 的可用 API，升级前先用编译与测试验证。
- 虚拟线程与结构化并发对 lambda 的影响最大，升级前先确认线程模型。
- 升级「Lambda 与 Stream API」涉及的依赖前，先用 FunctionalInterface 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 lambda 相关的差异单独记成一条结论。
- 升级后重点回归 lambda 的默认值、警告信息与错误格式。
- 升级后把 FunctionalInterface 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 lambda、Stream | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Lambda 与 Stream API」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Lambda 与 Stream API」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:java`，用于动手验证《Lambda 与 Stream API》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Lambda 与 Stream API》原文中的最小示例。先预测《Lambda 与 Stream API》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

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

```java
@FunctionalInterface
interface Calculator {
    int apply(int a, int b);
}

Calculator add = (a, b) -> a + b;
Calculator max = Integer::max;          // 方法引用

System.out.println(add.apply(1, 2));
```

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

## 时间/空间复杂度或性能分析

**复杂度证据**：「Lambda 与 Stream API」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Lambda 与 Stream API」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Lambda 与 Stream API」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：Stream 常见误用与性能提示**

| 误用 | 后果 | 正确做法 |
| --- | --- | --- |
| 在 forEach 里修改外部集合 | 并发修改异常或结果不确定 | 用 collect 生成新集合 |
| 中途忘记终止操作 | 代码根本不执行（流是惰性的） | 以 collect/forEach/reduce 收尾 |
| 在流里做重 IO 或远程调用 | 延迟叠加、线程池被打满 | 外提为批量操作或异步任务 |
| 无脑用 parallelStream | 公共 ForkJoinPool 被占满，拖慢全局 | 仅纯计算且数据量大时用，或自定义池 |
| 反复遍历同一个流 | 流只能消费一次，第二次抛异常 | 需要多次使用先 collect 成集合 |

性能取舍：小数据量（几百条）用普通循环往往更快——流有对象创建与装箱开销；可读性收益明显时用流，热点路径则实测后决定。基本类型流用 `IntStream/LongStream` 避免装箱，`mapToInt` + `sum` 比 `map` + `reduce` 更高效。

## 常见误区与易错点

> 复核《Lambda 与 Stream API》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Lambda 与 Stream API」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
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

**教材衔接：故障现场**

### 现场 1：流被重复消费

**症状**：在《Lambda 与 Stream API》的复现场景中，IllegalStateException: stream has already been operated upon or closed。

**根因**：当出现“流被重复消费”时，执行路径已经绕过了《Lambda 与 Stream API》的关键约束，最终以“IllegalStateException: stream has already been operated upon or closed”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Lambda 与 Stream API》的问题，流只能消费一次，需要复用就重新 stream()。

**验证**：先在《Lambda 与 Stream API》中记录“流被重复消费”留下的失败证据，再执行“流只能消费一次，需要复用就重新 stream()”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：忘记写终止操作

**症状**：在《Lambda 与 Stream API》的复现场景中，什么都不执行。

**根因**：“什么都不执行”只是表层结果。向上追溯会落到“忘记写终止操作”这一步，因为它省略了《Lambda 与 Stream API》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Lambda 与 Stream API》的问题，filter、map 都是惰性的，必须 collect、forEach 等触发。

**验证**：保留《Lambda 与 Stream API》里触发“什么都不执行”的输入、版本和日志，按“filter、map 都是惰性的，必须 collect、forEach 等触发”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：在 forEach 里修改外部集合

**症状**：在《Lambda 与 Stream API》的复现场景中，代码难以推理，并行时出错。

**根因**：“代码难以推理，并行时出错”只是表层结果。向上追溯会落到“在 forEach 里修改外部集合”这一步，因为它省略了《Lambda 与 Stream API》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Lambda 与 Stream API》的问题，用 collect 生成结果，避免副作用。

**验证**：先在《Lambda 与 Stream API》中记录“在 forEach 里修改外部集合”留下的失败证据，再执行“用 collect 生成结果，避免副作用”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《异常处理与文件 IO》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《多线程与并发》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《异常处理与文件 IO》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《构建、测试与生态》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Lambda 与 Stream API」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Lambda 与 Stream API》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

Stream 的中间操作（filter/map）什么时候真正执行？

A. JVM 空闲时
B. 调用时立即执行
C. 遇到终止操作时才执行
D. 创建 Stream 时

**参考答案**：遇到终止操作时才执行

**解析**：在「Lambda 与 Stream API」里，遇到终止操作时才执行。中间操作是惰性的，只有 collect/forEach/count 等终止操作才会触发一次遍历。回到「Lambda 与 Stream API」的正文示例，用“Stream 的中间操作（filte”走一遍lambda、Stream、Optional的完整流程，能复现的结论才可以保留。

### 自测 2

下面这段 Java 代码摘自「Lambda 与 Stream API」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？

```java
Optional<String> maybe = names.stream()
        .filter(n -> n.startsWith("z"))
        .findFirst();

String value = maybe.orElse("默认值");
maybe.ifPresent(System.out::println);

// 不要用 optional.get()，先判断或使用 orElseThrow
```

A. 这段代码包含条件分支，不同输入会走不同的执行路径。
B. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
C. 这段代码会产生可观察的输出，运行后能看到结果。
D. 这段代码包含循环结构，同一段逻辑会被重复执行。

**参考答案**：这段代码会产生可观察的输出，运行后能看到结果。

**解析**：在「Lambda 与 Stream API」里，这段代码会产生可观察的输出，运行后能看到结果。这段代码出自「Lambda 与 Stream API」的正文示例，围绕lambda、Stream、Optional展开；把输入或边界换成空值、极值或失败情况后，结论要以「Lambda 与 Stream API」的实际运行结果为准。

### 自测 3

围绕“Lambda 与 Stream API”中的 lambda、Stream、Optional，下列哪两项是本课强调的实践判断？

A. 只要 lambda 的常规示例通过，就可以跳过边界与异常路径
B. 验证 Stream 时要固定版本并覆盖边界输入，结论才可复现
C. 把 Stream 的单次运行结果当成所有版本和规模都成立
D. 学习 lambda 时要同时说明输入、输出和失败路径，不能只看正常流程

**参考答案**：验证 Stream 时要固定版本并覆盖边界输入，结论才可复现；学习 lambda 时要同时说明输入、输出和失败路径，不能只看正常流程

**解析**：本课把Lambda 与 Stream API拆成概念、示例与故障现场三部分，因此判断 lambda 时必须同时交代输入、输出和失败路径，这使“学习 lambda 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Lambda 与 Stream API里，判断 Stream 时要固定版本与边界输入，所以“验证 Stream 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 能列出常用中间操作与终止操作，并知道流是惰性的。
- [ ] 会用 `Collectors.groupingBy` 做分组统计。
- [ ] `toMap` 时提供合并函数避免重复键异常。
- [ ] 用 `Optional` 的 `orElse` / `orElseThrow` 替代 `get()`。
- [ ] 并行流只用于纯 CPU 计算，且先做性能验证。

**教材衔接：动手练习**

> 本课练习重点：围绕「lambda、Stream、Optional」完成复述、实验和交付，每个结果都要能被别人检查。

先把 Stream 的正常路径测通，再引入并发与异常。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Lambda 与 Stream API解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Stream」是什么关系？

验收标准：回答里必须出现 lambda，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：围绕「函数式接口」小节做一次五步记录，原例取自 FunctionalInterface，改动只允许动一处lambda，原因要能指回正文的判断依据。

### 练习 3：交付一个小结果（30 分钟）

写一个可运行的小类，补一个普通测试和一个边界输入测试。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「lambda」和「Stream」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕Lambda 与 Stream API安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Lambda 与 Stream API」的结构，画完再对照骨架：

- 主干：函数式接口 → Stream 常用操作 → 并行流与注意事项 → Stream 常见误用与性能提示
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明lambda与Stream的关系？

### 任务 2：做一次对比实验

**验收标准**：写出换方案的触发条件——当Stream的规模、精度或资源上限变化到什么程度时，「函数式接口」里的结论不再成立。

### 任务 3：迁移到自己的场景

**验收标准**：用自己的话复述 lambda，并配一个反例；只写定义不算通过。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Stream 的中间操作（filter/map）什么时候真正执行？」的判断依据。
- [ ] 不看解析，能说出「函数式接口的判断标准是？」的判断依据。
- [ ] 不看解析，能说出「关于 Optional，推荐的做法是？」的判断依据。
- [ ] 不看解析，能说出「Stream 的 collect 与 forEach 的区别是？」的判断依据。
- [ ] 不看解析，能说出「方法引用 String::length 等价于哪个 lambda？」的判断依据。
- [ ] 用 lambda 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Optional` | .findFirst()。 |
| `函数式接口` | 只有一个抽象方法的接口就是函数式接口，可以用 lambda 实现。 |
| `并行流` | 并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。 |
| `方法引用` | 用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。 |

## 考点精讲

### 考点 1：概念判断·lambda

- **题目**：Stream 的中间操作（filter/map）什么时候真正执行？
- **判断依据**：在「Lambda 与 Stream API」里，遇到终止操作时才执行。中间操作是惰性的，只有 collect/forEach/count 等终止操作才会触发一次遍历。回到「Lambda 与 Stream API」的正文示例，用“Stream 的中间操作（filte”走一遍lambda、Stream、Optional的完整流程，能复现的结论才可以保留。

### 考点 2：代码补全·lambda

- **题目**：下面这段 Java 代码摘自「Lambda 与 Stream API」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「Lambda 与 Stream API」里，这段代码会产生可观察的输出，运行后能看到结果。这段代码出自「Lambda 与 Stream API」的正文示例，围绕lambda、Stream、Optional展开；把输入或边界换成空值、极值或失败情况后，结论要以「Lambda 与 Stream API」的实际运行结果为准。

### 考点 3：多选辨析·lambda

- **题目**：围绕“Lambda 与 Stream API”中的 lambda、Stream、Optional，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把Lambda 与 Stream API拆成概念、示例与故障现场三部分，因此判断 lambda 时必须同时交代输入、输出和失败路径，这使“学习 lambda 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Lambda 与 Stream API里，判断 Stream 时要固定版本与边界输入，所以“验证 Stream 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 4：概念判断·lambda

- **题目**：Stream 的 collect 与 forEach 的区别是？
- **判断依据**：在「Lambda 与 Stream API」里，结论应落在「collect 是终止操作」。结论应落在collect 是终止操作。在流里修改外部状态是常见坏味道，能 collect 就优先 collect。在「Lambda 与 Stream API」里，这道题要求区分概念与边界，「collect 是终止操作」只有在题干给出的前提下才成立，而「collect 只能用于并行流」、「两者都返回 Stream」缺少同一组条件。

### 考点 5：概念判断·lambda

- **题目**：方法引用 String::length 等价于哪个 lambda？
- **判断依据**：方法引用是 lambda 的语法糖，可读性更好，也能表达构造器引用 Class::new。在「Lambda 与 Stream API」里，其他选项：方法引用把接收者作为隐式参数传入，因此 String::length 等价于 s -> s.length。「Lambda 与 Stream API」要求先交代lambda、Stream、Optional的前提再下结论，所以“s -> s.length”只在题干“方法引用 String”给定的条件下成立。

### 考点 6：填空·@____

- **题目**：补全代码：「Lambda 与 Stream API」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `@____`
- **判断依据**：空格应填写「FunctionalInterface」、「functionalinterface」。在「Lambda 与 Stream API」里判断这道题，要把lambda、Stream、Optional的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。

## English Overview

**Title:** Lambda & Streams

**Summary:** Functional interfaces, streams, Optional and parallel streams.

**Category:** Java
**Level:** 进阶
**Key terms:** lambda, Stream, Optional, 函数式接口, collect, 并行流

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
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE API](https://docs.oracle.com/en/java/javase/21/docs/api/) | 标准库 API |
| [dev.java 学习](https://dev.java/learn/) | 现代 Java 官方教程 |
| [Maven 指南](https://maven.apache.org/guides/) | 依赖、生命周期与构建 |

> 「Lambda 与 Stream API」的链接用于离线阅读后的延伸核对；App 不会自动联网。
