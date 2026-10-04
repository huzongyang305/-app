## 零基础详解：List、Set、Map 怎么选

### 一句话说清它是什么

Java 的集合框架解决三件事：**有序列表（List）、去重集合（Set）、键值映射（Map）**。
选对接口，代码又短又快；选错了要自己写一堆判断。

### 三种集合的定位

| 接口 | 比喻 | 特点 | 常用实现 |
| --- | --- | --- | --- |
| `List` | 排队队伍 | 有序、可重复、按下标访问 | `ArrayList`、`LinkedList` |
| `Set` | 会员名册 | 不重复、无下标 | `HashSet`、`TreeSet` |
| `Map` | 通讯录 | 键唯一、按键查找 | `HashMap`、`TreeMap` |

### `ArrayList` 与 `LinkedList` 的选择

| 操作 | ArrayList | LinkedList |
| --- | --- | --- |
| 按下标读 | 快 O(1) | 慢 O(n) |
| 尾部添加 | 快 | 快 |
| 中间插入或删除 | 慢 O(n) | 快 O(1)（已定位时） |
| 内存占用 | 更省 | 每个节点额外指针 |
| 结论 | **默认选它** | 只有在频繁头尾操作时才考虑 |

### `HashMap`、`LinkedHashMap`、`TreeMap`

| 实现 | 顺序 | 查找 | 典型用途 |
| --- | --- | --- | --- |
| `HashMap` | 无序 | O(1) | 默认选择，追求速度 |
| `LinkedHashMap` | 插入顺序 | O(1) | 需要稳定遍历顺序 |
| `TreeMap` | 按键排序 | O(log n) | 需要按顺序遍历或取范围 |

### 常用操作速查

```java
import java.util.*;

List<String> names = new ArrayList<>(List.of("小明", "小红"));
names.add("小刚");
names.set(0, "小美");                    // 改
names.remove("小刚");                     // 按值删
boolean has = names.contains("小红");

Set<String> tags = new HashSet<>();
tags.add("java");
tags.add("java");                        // 重复，不会生效
System.out.println(tags.size());          // 1

Map<String, Integer> counts = new HashMap<>();
counts.put("a", 1);
counts.merge("a", 1, Integer::sum);       // 计数神器：a -> 2
counts.getOrDefault("b", 0);              // 取不到给默认值
for (Map.Entry<String, Integer> e : counts.entrySet()) {
    System.out.println(e.getKey() + "=" + e.getValue());
}
```

### 遍历与删除的正确姿势

```java
// 遍历 List
for (String n : names) System.out.println(n);

// 遍历 Map
counts.forEach((k, v) -> System.out.println(k + "=" + v));

// 边遍历边删：必须用迭代器或 removeIf
names.removeIf(n -> n.startsWith("小"));
```

直接 `for (String n : names) names.remove(n);` 会抛 `ConcurrentModificationException`。

### 不可变集合与空集合

```java
List<String> empty = List.of();                  // 不可变空列表
List<String> fixed = List.of("a", "b");          // 不可变
List<String> copy = new ArrayList<>(fixed);      // 需要改就拷一份
```

不可变集合能防止意外修改，适合当返回值或常量。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 遍历中删除 | `ConcurrentModificationException` | 用 `removeIf` 或迭代器 |
| `List.of` 后添加 | `UnsupportedOperationException` | 先 `new ArrayList<>(...)` |
| 用 `==` 比较元素 | 结果不确定 | 用 `equals` |
| `HashMap` 的键是可变对象 | 改完后查不到 | 键用不可变类型 |
| 返回 `null` 集合 | 调用方空指针 | 返回空集合 |
| `Arrays.asList` 当可变列表 | 长度固定，增删报错 | 包一层 `new ArrayList<>` |
| 只看接口不选实现 | 顺序或性能不达标 | 按需求挑实现类 |
| `contains` 用错集合 | List 判存在很慢 | 改用 `HashSet` |

### 手把手练习：统计与排序

```java
import java.util.*;

public class WordCount {
    public static void main(String[] args) {
        String text = "the quick brown fox jumps over the lazy dog the fox";

        Map<String, Integer> counts = new HashMap<>();
        for (String w : text.split(" ")) {
            counts.merge(w, 1, Integer::sum);
        }

        List<Map.Entry<String, Integer>> top = new ArrayList<>(counts.entrySet());
        top.sort(Comparator.comparingInt(Map.Entry<String, Integer>::getValue)
                           .reversed()
                           .thenComparing(Map.Entry::getKey));

        top.stream().limit(3)
           .forEach(e -> System.out.println(e.getKey() + ": " + e.getValue()));
        System.out.println("不同单词数：" + counts.keySet().size());
    }
}
```

### 学完自测

- [ ] 能说出 List、Set、Map 各自的特点。
- [ ] 知道 `ArrayList` 与 `LinkedList` 的取舍。
- [ ] 能说出 `HashMap`、`LinkedHashMap`、`TreeMap` 的差别。
- [ ] 会用 `merge` 做计数、用 `getOrDefault` 取默认值。
- [ ] 知道遍历集合时删除元素该用什么方法。
