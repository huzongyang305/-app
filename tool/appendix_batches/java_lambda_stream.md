## Stream 操作速查

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

## 常见错误对照表

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

## 自测清单

- [ ] 能列出常用中间操作与终止操作，并知道流是惰性的。
- [ ] 会用 `Collectors.groupingBy` 做分组统计。
- [ ] `toMap` 时提供合并函数避免重复键异常。
- [ ] 用 `Optional` 的 `orElse` / `orElseThrow` 替代 `get()`。
- [ ] 并行流只用于纯 CPU 计算，且先做性能验证。
