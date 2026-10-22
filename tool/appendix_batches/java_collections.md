## 集合选型速查

| 需求 | 首选实现 | 关键复杂度 | 备注 |
| --- | --- | --- | --- |
| 有序、按下标访问 | `ArrayList` | 访问 O(1)、中间插入 O(n) | 绝大多数场景的默认选择 |
| 频繁头尾插入删除 | `ArrayDeque` / `LinkedList` | 两端 O(1) | 当队列或栈用优先 `ArrayDeque` |
| 去重且不关心顺序 | `HashSet` | 平均 O(1) | 依赖 `hashCode` 与 `equals` |
| 去重且要排序 | `TreeSet` | O(log n) | 元素需可比较或传 `Comparator` |
| 键值映射 | `HashMap` | 平均 O(1) | 允许一个 null 键 |
| 键有序 | `TreeMap` | O(log n) | 适合范围查询 `subMap`、`headMap` |
| 保留插入顺序 | `LinkedHashMap` | 平均 O(1) | 做 LRU 缓存的常见基础 |
| 线程安全 | `ConcurrentHashMap` | 平均 O(1) | 比 `Collections.synchronizedMap` 并发更高 |
| 不可变集合 | `List.of` / `Map.of` | 只读 | 写入抛 `UnsupportedOperationException` |

## 常用方法对照

| 操作 | List | Set | Map |
| --- | --- | --- | --- |
| 增 | `add` / `add(index, e)` | `add` | `put` / `putIfAbsent` / `computeIfAbsent` |
| 删 | `remove(index)` / `remove(obj)` | `remove` | `remove(key)` |
| 查 | `get(index)` | `contains` | `get` / `getOrDefault` |
| 判空 | `isEmpty()` | `isEmpty()` | `isEmpty()` |
| 遍历 | `for (E e : list)` | `for (E e : set)` | `for (var e : map.entrySet())` |
| 大小 | `size()` | `size()` | `size()` |
| 排序 | `Collections.sort` / `list.sort` | `TreeSet` | `TreeMap` |
| 转换 | `List.copyOf` / `toArray` | `Set.copyOf` | `Map.copyOf` |

```java
// 统计词频：computeIfAbsent 比「先判断再 put」更简洁
Map<String, Integer> counter = new HashMap<>();
for (String word : words) {
    counter.merge(word, 1, Integer::sum);
}

// 分组：一行完成「按部门归类员工」
Map<String, List<Employee>> byDept = employees.stream()
        .collect(Collectors.groupingBy(Employee::dept));
```

## 常见错误对照表

| 容易写错的写法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `list.remove(1)` 想删元素 1 | 删掉的是下标 1 | 参数是 `int` 时按下标删除；删对象要写 `list.remove(Integer.valueOf(1))` |
| 遍历 List 时 `list.remove(e)` | `ConcurrentModificationException` | 用 `Iterator.remove()` 或 `removeIf(...)` |
| `map.get(key)` 后直接 `+1` | `NullPointerException` | 用 `getOrDefault(key, 0)` 或 `merge` |
| 只用 `equals` 不重写 `hashCode` | `HashSet` 里出现「重复」元素 | 两者必须成对重写，或用 `record` 自动生成 |
| `Arrays.asList(...)` 后 `add` | `UnsupportedOperationException` | 它返回固定大小的视图，改成 `new ArrayList<>(Arrays.asList(...))` |
| `List.of(...)` 里放 null | `NullPointerException` | 不可变工厂不允许 null，用 `Collections.singletonList` 或 `ArrayList` |
| `HashMap` 在多线程下并发写 | 数据错乱甚至死循环 | 改用 `ConcurrentHashMap`，或用 `computeIfAbsent` 做原子初始化 |
| 遍历 `keySet()` 再 `get` | 多一次查找 | 遍历 `entrySet()` 一次拿键值 |
| 用可变对象作 `HashMap` 的键 | 改字段后查不到 | 键应使用不可变对象（`String`、`record`） |

## 自测清单

- [ ] 能根据「是否去重、是否需要顺序、是否并发」选定集合类型。
- [ ] 记得 `ArrayList` 随机访问快、`LinkedList` 两端操作快。
- [ ] 遍历 Map 时使用 `entrySet()`。
- [ ] 自定义对象放进 `HashSet` 或做 `HashMap` 键时，重写 `equals` + `hashCode`。
- [ ] 多线程共享 Map 时优先用 `ConcurrentHashMap`。
