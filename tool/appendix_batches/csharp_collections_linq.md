## 集合选型速查

| 需求 | 首选 | 关键复杂度 | 说明 |
| --- | --- | --- | --- |
| 有序、可重复、按下标访问 | `List<T>` | 访问 O(1) | 默认选择 |
| 去重且不关心顺序 | `HashSet<T>` | 平均 O(1) | 判存在最快 |
| 有序去重 | `SortedSet<T>` | O(log n) | 需要范围查询时用 |
| 键值映射 | `Dictionary<TKey,TValue>` | 平均 O(1) | 键必须可哈希 |
| 有序键值 | `SortedDictionary<TKey,TValue>` | O(log n) | 需要按键排序遍历 |
| 先进先出 | `Queue<T>` | O(1) | 队列 |
| 后进先出 | `Stack<T>` | O(1) | 栈 |
| 双端操作 | `LinkedList<T>` / `Deque`（第三方） | O(1) | 中间插删才考虑链表 |
| 不可变 | `ImmutableArray<T>` / `ImmutableList<T>` | 复制换安全 | 并发共享场景 |
| 线程安全字典 | `ConcurrentDictionary<TKey,TValue>` | 平均 O(1) | 多线程共享 |

## LINQ 速查

| 目的 | 写法 |
| --- | --- |
| 过滤 | `Where(x => x.Active)` |
| 映射 | `Select(x => x.Name)` |
| 展平 | `SelectMany(x => x.Items)` |
| 排序 | `OrderBy(x => x.Age).ThenBy(x => x.Name)` |
| 取前 N | `Take(10)`、`Skip(20).Take(10)` |
| 判断存在 | `Any()`、`Any(x => x.Age > 18)` |
| 全部满足 | `All(x => x.Active)` |
| 首个匹配 | `FirstOrDefault(x => x.Id == id)` |
| 聚合 | `Sum()`、`Average()`、`Max()`、`Count()` |
| 归约 | `Aggregate(seed, (acc, x) => ...)` |
| 分组 | `GroupBy(x => x.Category)` |
| 去重 | `Distinct()`、`DistinctBy(x => x.Id)` |
| 转集合 | `ToList()`、`ToArray()`、`ToDictionary(x => x.Id)` |
| 连接 | `Join`、`GroupJoin` |
| 集合运算 | `Union`、`Intersect`、`Except` |

```csharp
// 分组统计：每个类目的总额与数量
var summary = orders
    .Where(o => o.Paid)
    .GroupBy(o => o.Category)
    .Select(g => new
    {
        Category = g.Key,
        Count = g.Count(),
        Total = g.Sum(o => o.Amount),
    })
    .OrderByDescending(x => x.Total)
    .ToList();

// 用字典做 O(1) 查找，避免嵌套循环
var usersById = users.ToDictionary(u => u.Id);
foreach (var order in orders)
{
    if (usersById.TryGetValue(order.UserId, out var user))
    {
        Console.WriteLine($"{user.Name}: {order.Amount}");
    }
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 反复枚举同一个 `IEnumerable` | 重复查询数据库，性能差 | 用 `ToList()` 物化一次 |
| 忘记 LINQ 是延迟执行 | 数据变化后才执行、异常延后抛出 | 明确物化时机 |
| 在循环里 `FirstOrDefault` 查数据库 | N+1 查询 | 先批量取回，再用字典查找 |
| 用 `Count() > 0` 判存在 | 可能遍历整个序列 | 用 `Any()` |
| `SingleOrDefault` 用在可能多条的场景 | 抛 `InvalidOperationException` | 需要首条用 `FirstOrDefault` |
| `First()` 找不到时 | 抛异常 | 用 `FirstOrDefault` 并判空 |
| `Dictionary` 用 `[]` 取不存在的键 | `KeyNotFoundException` | 用 `TryGetValue` |
| 修改正在遍历的集合 | `InvalidOperationException` | 先收集改动或遍历副本 |
| 自定义类型做 `HashSet` 元素 | 去重失效 | 重写 `Equals` + `GetHashCode`，或用 record |
| 多线程共享 `Dictionary` | 数据损坏或异常 | 用 `ConcurrentDictionary` |

## 自测清单

- [ ] 能按「是否去重、是否有序、是否并发」选对集合。
- [ ] 会用 `GroupBy` + `Select` 做分组统计。
- [ ] 知道 LINQ 延迟执行，必要时 `ToList()` 物化。
- [ ] 查找用字典 `TryGetValue`，避免嵌套循环。
- [ ] 判存在用 `Any()` 而不是 `Count() > 0`。
