# Lambda 与 Stream API

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![Lambda 与 Stream 的流水线](images/diagram_java_stream.webp)

![Lambda 与 Stream API](images/remaining_java_lambda_stream.webp)

## 本节知识框架

想象一条工厂流水线：原材料（集合）进来后，经过一道道加工工位（filter、map、sorted），最后在出货口（collect）打包成品。Lambda 就是"把一段行为当参数传进去"，Stream 就是"用链式操作处理集合"。两者配合，能把过去要写十几行的循环压缩成一条清晰的数据流水线。

**本课你将学到：**
- Lambda 表达式和方法引用的写法
- Stream 的中间操作与终止操作
- Optional 如何替代 null
- 并行流的适用场景与陷阱

**先修要求：** 学完《异常处理与文件 IO》即可。

### 复习清单

- [ ] 能区分 Stream 的中间操作和终止操作
- [ ] 能写出 Optional 的安全取值方式
- [ ] 能说出并行流什么时候不该用

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| Lambda | 匿名函数，把一段行为当参数传递。写法：(参数) -> { 方法体 } |
| 函数式接口 | 只有一个抽象方法的接口，可以用 lambda 实现。如 Function、Consumer、Predicate。 |
| Stream | 集合的函数式视图。中间操作惰性求值，终止操作触发执行。流只能消费一次。 |
| Optional | 包装可能为 null 的值，强制你处理"没有值"的情况，避免空指针。 |
| 中间操作 | 只把"要做什么"登记进流水线并返回一个新的 Stream，本身不遍历元素：filter、map、sorted、distinct、limit 都算。 |
| 终止操作 | 让流水线真正跑起来并产出结果：collect、forEach、count、findFirst、reduce。一条流水线通常只有一个终止操作，而且它必须存在。 |
| effectively final | lambda 引用的外部局部变量只能被赋值一次。想改就先把值复制给一个新的 final 变量，或者干脆改用 collect 让框架帮你汇总。 |
| Spliterator | 流的切分器，决定一个数据源能不能被高效拆成多段——这也是并行流快慢的根源。 |

## 原理与运行机制

### Lambda 的四步演化

```java
List<String> names = List.of("小明", "小红", "小刚");

// 1. 匿名内部类（老写法，啰嗦）
names.forEach(new Consumer<String>() {
    @Override public void accept(String s) { System.out.println(s); }
});

// 2. Lambda
names.forEach(s -> System.out.println(s));

// 3. 方法引用（更短）
names.forEach(System.out::println);

// 4. 带条件与方法链
names.stream()
     .filter(s -> s.length() > 1)
     .map(String::toUpperCase)
     .forEach(System.out::println);
```

### 四大内置函数式接口

| 接口 | 签名 | 用途 |
| --- | --- | --- |
| Supplier<T> | () -> T | 提供值 |
| Consumer<T> | T -> void | 消费值 |
| Function<T,R> | T -> R | 转换 |
| Predicate<T> | T -> boolean | 判断 |

### Stream 常用操作

```java
List<String> result = names.stream()
        .filter(n -> n.length() > 3)     // 中间操作：惰性
        .map(String::toUpperCase)        // 转换
        .sorted()                        // 排序
        .distinct()                      // 去重
        .limit(10)
        .collect(Collectors.toList());   // 终止操作：触发执行
```

中间操作（filter/map/sorted）不会立刻执行，只有遇到终止操作（collect/forEach/count）才会遍历。

### 分组与统计

```java
Map<Integer, List<String>> byLength = names.stream()
        .collect(Collectors.groupingBy(String::length));

long count = names.stream().filter(n -> n.startsWith("a")).count();
int totalLength = names.stream().mapToInt(String::length).sum();
```

### Optional：不用再返回 null

```java
Optional<String> maybe = names.stream()
        .filter(n -> n.startsWith("z"))
        .findFirst();

String value = maybe.orElse("默认值");
maybe.ifPresent(System.out::println);
// 不要用 optional.get()，先判断或使用 orElseThrow
```

### 并行流

```java
long total = IntStream.rangeClosed(1, 1_000_000)
        .parallel()
        .filter(n -> n % 2 == 0)
        .count();
```

并行流使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。

### 惰性求值：点完菜不等于开火

把 Stream 想成一张菜单。`filter`、`map`、`sorted` 只是往单子上加菜名，厨房（JVM）看到单子不会动；只有服务员喊"上菜"——也就是调用终止操作——才真正开始炒。所以下面这段代码跑完，屏幕上什么都不会打印：

```java
List<String> names = List.of("Tom", "Ann", "Bob");
names.stream().filter(n -> {
    System.out.println("检查 " + n);   // 没有终止操作，这行一次也不执行
    return n.length() > 2;
});
```

补一个 `.count()` 或 `.collect(Collectors.toList())`，`检查 Tom` 之类才会出现。这也是本课最容易写出"看起来没错、其实什么都没干"的地方：编译器不会提醒你一个没有终止操作的流水线。

惰性还带来一个额外好处——短路。`findFirst()` 和 `limit(3)` 只要凑够数量就停止取元素，因此对着无限流 `Stream.iterate(1, n -> n + 1).limit(5)` 也能正常结束；换成 `for` 循环写法就得自己记得 `break`。

### 方法引用的四种形态

方法引用用双冒号把已经存在的方法当作函数式接口的实现，读起来比 lambda 更贴近"你要干什么"。常见的四类：

```java
Function<String, Integer> len = String::length;        // s -> s.length()
BinaryOperator<Integer> max = Integer::max;            // (a, b) -> Integer.max(a, b)
BiPredicate<String, String> eq = String::equalsIgnoreCase; // (a, b) -> a.equalsIgnoreCase(b)
Supplier<List<String>> factory = ArrayList::new;       // () -> new ArrayList<>()
```

第一种最容易写错：`String::length` 的接收者会变成 lambda 的第一个参数，等价写法是 `s -> s.length()`。教材和题库里常把它简写成 `s -> s.length`，真实代码里括号不能省，否则那是访问字段的语法，编译不过。

### collect 与 forEach：一个交货，一个只干活

两者都是终止操作，区别在返回值和意图。`collect` 把元素归拢成一个容器交回给你，后续还能再接 `.stream()` 继续加工；`forEach` 返回 `void`，只负责把副作用（打印、写日志、塞进外部集合）做完。

```java
List<String> upper = names.stream().map(String::toUpperCase).collect(Collectors.toList());
upper.forEach(System.out::println);   // 这里 forEach 是终点，没有返回值
```

写库代码时优先 `collect`：结果可验证、可传递、在并行流里由框架负责归并；`forEach` 留给最外层"我真的只要执行一遍"的场合。要注意 `parallel()` 之后 `forEach` 不保证顺序，需要顺序就换成 `forEachOrdered`。

### 流是一次性的

Stream 内部记着"我已经跑过了"，同一个流变量消费两次会抛异常：

```java
Stream<String> pipeline = names.stream().filter(n -> n.length() > 2);
long a = pipeline.count();
long b = pipeline.count();   // IllegalStateException: stream has already been operated upon or closed
```

正确做法是把"流水线配方"存成函数，每次从源集合现场开一个新的流：

```java
Function<List<String>, Stream<String>> recipe =
        list -> list.stream().filter(n -> n.length() > 2);
long a = recipe.apply(names).count();
long b = recipe.apply(names).count();
```

### 并行流的三条安全线

`parallel()` 借用的是整个 JVM 共享的公共 ForkJoinPool，默认线程数是可用核数减一。判断能不能开并行，看三条线：元素处理是否只依赖入参（无共享可变状态）、单个元素是否足够便宜（不含阻塞 IO 或锁）、数据源是否容易切分（`ArrayList`、`IntStream.range` 好切，`BufferedReader.lines()`、`LinkedList` 难切）。

```java
// 危险：多个线程往同一个 ArrayList 里加
List<String> bad = new ArrayList<>();
names.parallelStream().filter(n -> n.length() > 2).forEach(bad::add);

// 稳妥：归并交给框架，顺序也保得住
List<String> good = names.parallelStream()
        .filter(n -> n.length() > 2)
        .collect(Collectors.toList());
```

## 典型应用场景

| 场景 | 推荐做法 | 为什么 |
| --- | --- | --- |
| 集合数据过滤转换 | Stream filter + map + collect | 声明式，可读性好 |
| 分组统计 | Collectors.groupingBy | 一行完成分组 |
| 可能为 null 的返回值 | Optional | 强制处理空值情况 |
| 大数据量纯计算 | 并行流 parallel() | 自动利用多核 |

### 场景一：读配置行，正常与异常路径都要交代

配置文件中夹着注释、空行和缺等号的坏行。用 Stream 处理时，"输入是什么、输出是什么、坏输入走哪条路"要分开写清楚，而不是只让正常样本通过就宣布完成：

```java
List<String> raw = List.of("# 端口配置", "port=8080", "", "timeout", "retry=3");

Map<String, String> settings = raw.stream()
        .map(String::trim)
        .filter(s -> !s.isEmpty() && !s.startsWith("#"))
        .filter(s -> s.contains("="))          // 缺等号的坏行在这里被挡下
        .collect(Collectors.toMap(
                s -> s.substring(0, s.indexOf('=')),
                s -> s.substring(s.indexOf('=') + 1),
                (oldValue, newValue) -> oldValue));   // 键重复时保留先出现的
```

过滤链负责"输入到输出"，`toMap` 的第三个参数负责"失败路径"：少了它，一旦重复键就直接抛 `IllegalStateException`。这类合并函数是 `toMap` 最常被漏掉的部分。

### 场景二：分组统计与"取第一名"

```java
record Student(String name, String team, int score) {}

List<Student> students = List.of(
        new Student("小明", "A", 88),
        new Student("小红", "B", 95),
        new Student("小刚", "A", 59));

Map<String, Double> avgByTeam = students.stream()
        .collect(Collectors.groupingBy(Student::team, Collectors.averagingInt(Student::score)));

Optional<Student> top = students.stream().max(Comparator.comparingInt(Student::score));
top.ifPresent(s -> System.out.println(s.name() + " 是最高分 " + s.score()));
```

`max` 返回的是 `Optional`，因为空集合根本没有"最高分"。用 `ifPresent` 或 `orElse` 处理，别对着它直接 `.get()`——集合为空时那是 `NoSuchElementException`，等于把 null 检查换了个更隐蔽的写法。

### 什么时候反而该回到 for 循环

三类信号：需要下标（`IntStream.range` 之外的复杂索引推进）、需要中途 `break` 或多重 `return`、循环体里有多个相互依赖的累加状态。这时流水线要写成绕弯的 `reduce`，读的人反而更累。Stream 的价值在于"一条链只做一件明确的事"，链一长、分支一杂，就该拆开。

## 代码/协议/SQL 示例

### 最小可运行示例

一个文件跑通"lambda → 方法引用 → Stream 终止操作"这条最短链路：

```java
import java.util.List;

public class Demo {
    public static void main(String[] args) {
        List<String> names = List.of("Tom", "Ann", "Bob");

        long over2 = names.stream()
                .filter(n -> n.length() > 2)   // 中间操作，此时还没遍历
                .count();                     // 终止操作，这里才真的算

        System.out.println("长度大于 2 的有 " + over2 + " 个");
        names.stream().map(String::toUpperCase).forEach(System.out::println);
    }
}
```

```bash
javac Demo.java && java Demo
```

输出：

```text
长度大于 2 的有 3 个
TOM
ANN
BOB
```

三行关键处的分工：`filter` 里那个 `n -> n.length() > 2` 只是"配方"，`count()` 才是按下开关；`String::toUpperCase` 是方法引用，等价于 `s -> s.toUpperCase()`；最后那句 `forEach` 同样是终止操作，它没有返回值，只负责打印。

### 函数式接口与方法引用

```java
@FunctionalInterface
interface Calculator {
    int apply(int a, int b);
}

Calculator add = (a, b) -> a + b;
Calculator max = Integer::max;
System.out.println(add.apply(1, 2));
```

### Stream 流水线练习

```java
record Student(String name, String team, int score) {}

var students = List.of(
    new Student("小明", "A", 88),
    new Student("小红", "B", 95),
    new Student("小刚", "A", 59)
);

List<String> passed = students.stream()
    .filter(s -> s.score() >= 60)
    .map(Student::name)
    .toList();

Map<String, List<Student>> byTeam = students.stream()
    .collect(Collectors.groupingBy(Student::team));
```

### 收集器速查

```text
目的            写法
───────────────────────────────────────────────────
收集成 List      .collect(Collectors.toList())
收集成 Set       .collect(Collectors.toSet())
收集成 Map       .collect(Collectors.toMap(K::get, V::get, (a,b) -> a))
分组             .collect(Collectors.groupingBy(Item::category))
拼接字符串       .collect(Collectors.joining(", ", "[", "]"))
```

### 渐进示例：把命令式循环改写成流水线

第一步，原始写法，结果对但状态散落一地：

```java
int total = 0;
int max = Integer.MIN_VALUE;
for (int score : List.of(88, 59, 95)) {
    total += score;
    if (score > max) {
        max = score;
    }
}
System.out.println(total + " / " + max);
```

第二步，拆成两条流水线，每条只负责一件事：

```java
List<Integer> scores = List.of(88, 59, 95);
int total = scores.stream().mapToInt(Integer::intValue).sum();
int max = scores.stream().mapToInt(Integer::intValue).max().orElse(0);
```

`mapToInt` 把 `Integer` 摊平成 `int`，省掉逐个拆箱。`max()` 返回 `OptionalInt`，`orElse(0)` 就是给空集合准备的兜底——这一步等于把"失败路径"写进代码；换成 `getAsInt()`，空列表会让它直接抛异常。

第三步，把边界样本补齐再跑一遍，确认结论不是只在"三个正常成绩"上成立：

```java
List<Integer> none = List.of();
double avg = none.stream().mapToInt(Integer::intValue).average().orElse(Double.NaN);
System.out.println(avg);   // NaN，表示"没有均值可算"而不是 0
```

空集合、单元素、多个并列最大值，这三种输入才算把这条流水线验证完。只跑一组正常数据就写进结论，换到真实数据上往往立刻翻车。

### 动手练一练

- 把上面第二步的 `total` 与 `max` 合成一次遍历：改用 `summaryStatistics()`，一个对象同时给出数量、总和、最小值和最大值
- 给 `List<String>` 写一条 `filter` → `map` → `sorted` → `collect` 的链，然后删掉最后的 `collect`，观察输出如何变成"什么都没发生"
- 让同一个流变量连续 `count()` 两次，把异常信息抄下来，再改回每次从源集合重新开一个流
- 用 `parallel()` 跑一遍本课的分组统计，对比单线程耗时，并记下你的 JDK 版本号

## 时间/空间复杂度或性能分析

- **Stream 创建**：几乎零开销，JIT 会内联 lambda
- **中间操作**：惰性求值，只在终止操作时遍历一次
- **并行流**：使用 ForkJoinPool，数据量大且无副作用时才有加速效果
- **装箱开销**：mapToInt/mapToLong 避免自动装箱，比 map(Integer::valueOf) 快

### 一条流水线到底遍历几趟

`filter` 与 `map` 是"一趟里顺带完成"的：把它们串起来仍然只遍历一次，成本是 O(n)。真正改变内存曲线的是需要记住历史的中间操作——`sorted` 和 `distinct` 要把见过的元素先攒起来，内存占用随之升到 O(n)，`sorted` 的比较成本是 O(n log n)。写链式代码时把 `filter` 放前面通常更划算：越早把元素丢掉，后面排序要处理的就越少。

`limit` 与 `findFirst` 是短路操作，遇到它们流水线会提前收工；反过来 `count()` 虽然只返回一个数字，仍然要把源走满一趟。

### 并行流的快与慢

并行不是"加了个开关就加速"。固定开销包括把源切分成子任务、为每个工作线程建结果容器、最后做归并（`Collectors` 的 combiner）。数据量小的时候这些开销比遍历本身还贵，`parallel()` 往往更慢；经验起点是"元素处理是纯计算且总量在万级以上"再考虑。

还有两个容易忽略的间接成本：公共 ForkJoinPool 整个 JVM 共用一个，你的并行流会被同进程里别人的并行流排队；并行流里做阻塞 IO 会把工作线程占住，看起来只是"这一处变慢"，实际上拖累的是全部并行任务。这类场景应该用《多线程与并发》里的显式线程池，而不是 `parallel()`。

### 让性能结论可复现

想说明"这个流比那个流快"，至少固定三件事：`java -version` 记录的 JDK 版本、同一份输入规模、以及预热后的多次运行（JIT 会把热点 lambda 内联，第一次运行的数字没有参考价值）。严肃一点的对比用 JMH，随手验证就用十万、一百万两档规模各跑三次，看趋势而不是单次读数。

正确性也一样：只跑一组正常样本就下结论是不可靠的。空集合、单元素、含 null、全部重复这四类边界输入各跑一遍，才知道这条流水线在真实数据上站不站得住。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把 Stream 当集合复用 | IllegalStateException | 流只能消费一次 |
| 中间操作不写终止操作 | 什么也不执行 | 流是惰性的 |
| Lambda 里改变量 | 编译错误 | 捕获的变量必须 effectively final |
| 乱用并行流 | 结果错乱或更慢 | 只在纯计算大数据量时用 |
| toMap 键重复 | IllegalStateException | 提供合并函数 (a,b) -> a |
| 用 orElse 做重计算 | 每次都白算 | 改用 orElseGet |
| Optional.get() 直接取值 | NoSuchElementException | 用 orElse 或 ifPresent |
| forEach 里修改外部集合 | 并发问题 | 用 collect 生成新集合 |
| 只写中间操作，忘了终止操作 | 程序正常结束却什么都没发生，断点也进不去 | 链尾补 collect、forEach、count 三者之一 |
| lambda 里给外部局部变量重新赋值 | 编译期直接拒绝，要求 final 或 effectively final | 复制一份 final 局部变量，或改用 collect 汇总 |
| 并行流里用 forEach 往共享 List 追加 | 偶发丢数据，重跑一次现象又变了 | 交给 Collectors 归并，要顺序就换 forEachOrdered |
| 依赖并行流元素的处理顺序 | 单元测试随机失败，日志打印次序不稳定 | 先 collect 成有序结果再遍历，或改用 forEachOrdered |

### 现场：一段 lambda 死活编译不过

**症状**：循环里用 `total += score` 累加，随后在 lambda 里引用 `total`，编译器提示 local variables referenced from a lambda expression must be final or effectively final。

**根因与修复**：lambda 捕获的是变量当时的值，语言层面就禁止它在之后被改动。要么把这一轮的值先赋给一个新的 final 局部变量再用，要么把"累加"这件事改写成 `mapToInt(...).sum()`，让收集器自己维护中间状态——后者通常也更短。

### 现场：加了 parallel() 反而慢一倍

**症状**：一万条数据做字符串转换，单线程 20 毫秒，并行 40 毫秒。

**根因与修复**：切分数据源、建中间容器、执行归并这些固定成本，在小数据量上比遍历本身还贵；如果数据来自 `BufferedReader.lines()`，Spliterator 难以均分，收益更差。先留下单线程基线数字，再决定要不要并行；阻塞 IO 密集的环节改用显式线程池，不要占用公共 ForkJoinPool。

## 与其他知识点的关系

- **先修**：《异常处理与文件 IO》——lambda 里抛受检异常需要包装
- **后续**：《构建、测试与生态》——Stream 常用于测试数据准备
- **关联**：《集合框架与泛型》——Stream 就是集合的函数式视图
- **关联**：《多线程与并发》——并行流借用的公共 ForkJoinPool 正是那一课线程池话题的前菜；什么时候该自己建池、什么时候让框架管池，边界就在"有没有共享可变状态和阻塞调用"
- **关联**：《现代 Java：Record、Sealed 与模式匹配》——本课示例里的 `record Student(...)` 和后面要学的解构模式是同一条演化线上来的，数据载体越简洁，lambda 与流读起来就越顺
- **区分**：`Optional` 不是 Stream 的配套语法，而是一个独立的返回值设计。把它当字段类型或方法参数用是坏味道，本课的口径是：只用在"这里确实可能没有值"的返回位置
- **铺垫**：《实战：Java 并发订单处理服务》——订单聚合、去重、分组的写法几乎全是本课的流水线，区别只在于要不要并行以及怎么保证结果有序

## 自测题与参考答案

1. **Stream 的中间操作什么时候执行？** 遇到终止操作时才执行，这是惰性求值。
2. **collect 和 forEach 有什么区别？** collect 收集结果返回新集合，forEach 只执行副作用不返回值。
3. **方法引用 String::length 等价于什么 lambda？** s -> s.length()
4. **并行流什么时候不该用？** 有共享可变状态、IO 操作、数据量小时不要用。
5. **Optional.orElse 和 orElseGet 有什么区别？** orElse 无论是否需要都执行参数，orElseGet 延迟执行。

## 考点精讲

`Lambda 与 Stream API` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据。

### 考点 1：第 1 题

- **题目**：Stream 的中间操作（filter/map）什么时候真正执行？
- **正确项**：遇到终止操作才执行
- **判断依据**：本题正确项是「遇到终止操作时才执行」。术语 Optional（Lambda 与 Stream API）：.findFirst()，本题取「遇到终止操作时才执行」这条。易错点是把 Stream 当集合复用，改法是流只能消费一次。易错点是中间操作不写终止操作，会造成什么也不执行，改法是流是惰性的。

### 考点 2：第 2 题

- **题目**：代码语言为 `java`，选自 `Lambda 与 Stream API` 的 `Optional` 部分。课程问题为函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。哪一项描述与代码一致？
- **正确项**：调用了 `length()`
- **判断依据**：本题正确项是「调用了 `length()`」。术语 Optional（Lambda 与 Stream API）：.findFirst()，本题取「调用了 `length()`」这条。易错点是中间操作不写终止操作，会造成什么也不执行，改法是流是惰性的。本题干扰项「调用了 `ValueError()`」不成立：展示代码里找不到 `ValueError()`。

### 考点 3：第 3 题

- **题目**：围绕“Lambda 与 Stream API”中的 lambda、Stream、Optional，下列哪两项是本课强调的实践判断？
- **正确项**：验证 Stream 时要固定版本并覆盖边界输入，结论才可复现；学习 lambda 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：按《Lambda 与 Stream API》的正文口径，本题要同时选中「验证 Stream 时要固定版本并覆盖边界输入，结论才可复现」、「学习 lambda 时要同时说明输入、输出和失败路径，不能只看正常流程」，漏掉任一项都算没答全。术语 Optional（Lambda 与 Stream API）：.findFirst()。易错点是Lambda 里改变量，会造成编译错误，改法是捕获的变量必须 effectively final。

### 考点 4：第 4 题

- **题目**：Stream 的 collect 与 forEach 的区别是？
- **正确项**：collect 是终止操作
- **判断依据**：本题正确项是「collect 是终止操作」。术语 Optional（Lambda 与 Stream API）：.findFirst()，本题取「collect 是终止操作」这条。易错点是乱用并行流，会造成结果错乱或更慢，改法是只在纯计算大数据量时用。

### 考点 5：第 5 题

- **题目**：方法引用 String::length 等价于哪个 lambda？
- **正确项**：s -> s.length
- **判断依据**：本题正确项是「s -> s.length」。术语 方法引用（Lambda 与 Stream API）：用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读，本题取「s -> s.length」这条。易错点是toMap 键重复，改法是提供合并函数 (a,b) -> a。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `函数式接口、方法引用、Stream 惰性求值、Optional 与并行流。`，这段说明是：`____`使用公共 ForkJoinPool，适合纯计算且数据量大；有共享可变状态、IO 操作时不要用。空缺处应填哪个术语？
- **正确项**：并行流
- **判断依据**：涉及术语 Optional：.findFirst()。易错点：把 Stream 当集合复用会造成`IllegalStateException: stream has already been operated upon`。正确做法：每条流水线只用一个流。本课《Lambda 与 Stream API》要解决的是函数式接口、方法引用、Stream 惰性求值、Optional 与并行流

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| Lambda | 匿名函数，(参数) -> { 方法体 } |
| 函数式接口 | 只有一个抽象方法，可用 lambda 实现 |
| Stream | 集合的函数式视图，惰性求值 |
| Optional | 包装可能为 null 的值 |
| 方法引用 | Class::method 语法，比 lambda 更短 |
| 并行流 | 使用 ForkJoinPool 的并行处理 |
| 中间操作 | filter、map、sorted 这类，只登记步骤并返回新 Stream，本身不遍历 |
| 终止操作 | collect、forEach、count 这类，触发遍历并给出最终结果 |
| effectively final | lambda 引用的外部局部变量只能被赋值一次 |
| 短路操作 | limit、findFirst 这种凑够数量就停止取元素的终止或中间步骤 |
| Spliterator | 流的切分器，决定数据源能否被高效分段，直接影响并行效果 |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE 官方教程：Lambda](https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html) | Lambda 与 Stream 基础语法 |
| [Java SE API 文档](https://docs.oracle.com/en/java/javase/21/docs/api/) | Stream/Optional/Collector API 查询 |
| [dev.java 学习路径](https://dev.java/learn/) | 现代 Java 官方入门教程 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：lambda、Stream、Optional、函数式接口、并行流、方法引用
