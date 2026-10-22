## 零基础详解：集合选择与 LINQ 查询

### 一句话说清它是什么

集合负责存数据，LINQ 负责查数据。
LINQ 是 C# 的杀手锏：**用一串链式方法描述「我要什么」，而不是写循环描述「怎么找」**。

### 集合怎么选

| 集合 | 特点 | 什么时候用 |
| --- | --- | --- |
| `List<T>` | 有序、可重复、按下标访问 | **默认选择** |
| `Dictionary<K,V>` | 键值对、按 key 查找 O(1) | 需要快速查找或去重 |
| `HashSet<T>` | 不重复、无序 | 去重、判断存在 |
| `Queue<T>` | 先进先出 | 任务队列、广度优先 |
| `Stack<T>` | 后进先出 | 撤销、括号匹配 |
| `LinkedList<T>` | 频繁中间插入删除 | 少用，先测性能 |

```csharp
using System.Collections.Generic;

var names = new List<string> { "小明", "小红" };
names.Add("小刚");
names.Remove("小红");

var ages = new Dictionary<string, int> { ["小明"] = 18 };
ages["小红"] = 20;
if (ages.TryGetValue("小刚", out var age)) { }

var tags = new HashSet<string> { "csharp", "dotnet" };
tags.Add("csharp");                 // 重复，不生效
Console.WriteLine(tags.Count);       // 2
```

### LINQ 的两套写法

```csharp
var scores = new[] { 88, 95, 59, 72, 95 };

// 1. 方法语法（最常用）
var passed = scores.Where(s => s >= 60).OrderByDescending(s => s).ToList();

// 2. 查询语法（贴近 SQL，复杂连接时可读性更好）
var query = from s in scores
            where s >= 60
            orderby s descending
            select s;
```

两种写法完全等价，选一种保持统一即可。

### 常用方法速查

| 方法 | 作用 | 返回 |
| --- | --- | --- |
| `Where` | 过滤 | 序列 |
| `Select` | 映射或投影 | 序列 |
| `OrderBy` / `ThenBy` | 排序 | 序列 |
| `FirstOrDefault` | 取第一个，可能没有 | 元素或默认值 |
| `Any` / `All` | 是否存在或是否全部 | bool |
| `GroupBy` | 分组 | 分组序列 |
| `Sum` / `Average` / `Max` | 聚合 | 数值 |
| `Distinct` | 去重 | 序列 |
| `Take` / `Skip` | 分页 | 序列 |

**LINQ 是延迟执行**：只写 `Where` 不会立刻计算，直到 `foreach`、`ToList()`、`Count()` 之类的操作才真正跑。

### 一个完整的查询例子

```csharp
record Student(string Name, string Team, int Score);

var students = new[]
{
    new Student("小明", "A", 88),
    new Student("小红", "B", 95),
    new Student("小刚", "A", 59),
    new Student("小美", "B", 72),
};

var report = students
    .Where(s => s.Score >= 60)
    .GroupBy(s => s.Team)
    .Select(g => new
    {
        Team = g.Key,
        Count = g.Count(),
        Average = Math.Round(g.Average(s => s.Score), 1),
        Top = g.OrderByDescending(s => s.Score).First().Name,
    })
    .OrderByDescending(x => x.Average)
    .ToList();

foreach (var row in report)
{
    Console.WriteLine($"{row.Team} 队：{row.Count} 人，均分 {row.Average}，最高 {row.Top}");
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 忘了 `ToList()` | 每次遍历都重新查询 | 需要复用结果就固化 |
| 在循环里反复查数据库 | 性能极差 | 一次查出来再遍历，或用 `Contains` 批量 |
| 用 `First()` 取可能为空的数据 | 抛 `InvalidOperationException` | 用 `FirstOrDefault()` |
| `OrderBy` 后想二次排序 | 只按第一个键 | 接 `ThenBy` |
| 修改集合时遍历 | 抛 `InvalidOperationException` | 先 `ToList()` 再改 |
| 用 `Count()` 判空 | 大集合要遍历完整 | 用 `Any()` |
| 以为 LINQ 一定更快 | 有时不如手写循环 | 热点路径实测 |
| 忽略延迟执行 | 数据源变了结果也变 | 需要快照就 `ToList()` |

### 手把手练习：分页与统计

```csharp
var all = Enumerable.Range(1, 53).Select(i => new { Id = i, Score = (i * 37) % 100 });

int pageSize = 10, page = 2;

var pageItems = all
    .OrderByDescending(x => x.Score)
    .Skip((page - 1) * pageSize)
    .Take(pageSize)
    .ToList();

Console.WriteLine($"共 {all.Count()} 条，第 {page} 页 {pageItems.Count} 条");
Console.WriteLine($"最高分 {all.Max(x => x.Score)}，平均 {all.Average(x => x.Score):F1}");
Console.WriteLine($"及格 {all.Count(x => x.Score >= 60)} 人");
```

### 学完自测

- [ ] 能说出 List、Dictionary、HashSet 各自适合的场景。
- [ ] 能写出方法语法和查询语法的等价写法。
- [ ] 知道 LINQ 的延迟执行意味着什么。
- [ ] 知道为什么判空要用 `Any()` 而不是 `Count() > 0`。
- [ ] 能用 `GroupBy` 加 `Select` 生成分组报表。
