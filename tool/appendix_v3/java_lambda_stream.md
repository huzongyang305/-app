## 零基础详解：Lambda 与 Stream 流水线

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
