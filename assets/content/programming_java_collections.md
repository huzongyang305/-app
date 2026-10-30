# 集合框架与泛型

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：40 分钟

![HashMap 数组、链表与红黑树](images/diagram_java_collections.webp)

![集合框架与泛型](images/remaining_java_collections.webp)

## 本节知识框架

想象你去超市购物：购物清单是有序的（List），会员名册不允许重复名字（Set），而通讯录把姓名映射到电话号码（Map）。Java 的集合框架就是这三类容器的统称，再加上**泛型**让你声明"这个容器只装某种类型"。

**本课你将学到：**
- List、Set、Map 各自适合什么场景
- 遍历集合时为什么不能直接删元素
- 泛型和通配符怎么用
- 线程安全的集合该选哪个

**先修要求：** 学完《继承、接口与多态》即可。

### 复习清单

- [ ] 能说出 ArrayList 和 LinkedList 的区别及选择依据
- [ ] 能解释为什么遍历 List 时直接 remove 会抛异常
- [ ] 能写出 HashMap 的基本用法并说出键的要求

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| List | 有序、可重复的集合，按下标访问。ArrayList 是默认选择。 |
| Set | 不允许重复元素的集合。HashSet 基于 HashMap 实现。 |
| Map | 键值对映射接口。HashMap 不保序，LinkedHashMap 保插入序，TreeMap 按键排序。 |
| 泛型 | 编译期类型检查，运行时类型擦除。不能 new T[] 也不能 instanceof 泛型。 |
| Iterator | 从集合里逐个取元素的游标，`hasNext()` 判断是否还有、`next()` 取值、`remove()` 安全删除当前元素。 |
| Queue / Deque | 队列只允许一端进另一端出；Deque 两端都能进出，`ArrayDeque` 是栈和队列的首选实现。 |
| Comparable / Comparator | 前者是元素"自己会比较"（`compareTo`），后者是外部"帮它们比较"（`compare`），同一类型想有多种排序就用 Comparator。 |
| fail-fast | 集合被结构性修改后迭代器立即抛 `ConcurrentModificationException`， ArrayList/HashMap 都是这种策略。 |
| CopyOnWriteArrayList | 每次写操作复制整个底层数组再替换，读完全无锁，适合"读多写极少"的监听器列表、黑白名单。 |
| 容量与负载因子 | HashMap 默认初始容量 16、负载因子 0.75，元素数超过容量×0.75 就翻倍扩容，这叫 rehash。 |

## 原理与运行机制

### 集合体系总览

```text
Collection ─┬─ List（有序、可重复）→ ArrayList / LinkedList
            ├─ Set（不可重复）    → HashSet / TreeSet / LinkedHashSet
            └─ Queue（队列）     → ArrayDeque / PriorityQueue
Map（键值对）→ HashMap / TreeMap / LinkedHashMap
```

### List：排队队伍

```java
List<String> names = new ArrayList<>();
names.add("tom");
names.add(1, "alice");
names.set(0, "bob");
names.remove("alice");
System.out.println(names.get(0));
names.sort(Comparator.naturalOrder());
```

ArrayList 随机访问快 O(1)，LinkedList 中间插删快但缓存不友好，日常默认选 ArrayList。

### Set：会员名册

```java
Set<String> tags = new HashSet<>();
tags.add("java");
tags.add("java");  // 重复不生效
System.out.println(tags.contains("java"));  // true
```

### Map：通讯录

```java
Map<String, Integer> scores = new HashMap<>();
scores.put("math", 90);
scores.putIfAbsent("english", 85);
System.out.println(scores.getOrDefault("history", 0));
scores.forEach((k, v) -> System.out.println(k + "=" + v));
```

### 泛型与通配符

```java
public class Box<T> {
    private T value;
    public void set(T value) { this.value = value; }
    public T get() { return value; }
}

List<? extends Number> numbers = List.of(1, 2.5);   // 上界：只读
List<? super Integer> sink = new ArrayList<Number>(); // 下界：可写
```

### 遍历与删除

```java
// 正确做法：用 removeIf
names.removeIf(n -> n.startsWith("小"));

// 错误做法：增强 for 里直接删 → ConcurrentModificationException
```

增强 for 只是迭代器的语法糖，编译器会把它展开成 `while (it.hasNext()) { it.next(); ... }`。ArrayList 内部有一个 `modCount` 计数器，每加一次元素就 +1；迭代器创建时记下当时的 `modCount`，每调用一次 `next()` 就把它和当前值对比，对不上就抛异常。你在循环体里直接调 `names.remove(x)`，改的是集合而不是迭代器，所以下一轮就"对不上"了。三条安全的删除路径：

```java
// 1) removeIf —— 内部帮你处理好了，最简洁
names.removeIf(n -> n.length() < 2);

// 2) 显式迭代器 —— 需要边遍历边做复杂判断时用
Iterator<String> it = names.iterator();
while (it.hasNext()) {
    if (it.next().equals("tmp")) {
        it.remove();      // 注意是迭代器的 remove，不是集合的
    }
}

// 3) 倒序下标删除 —— 删的是位置，不涉及迭代器
for (int i = names.size() - 1; i >= 0; i--) {
    if (names.get(i).isEmpty()) names.remove(i);
}
```

### HashMap 存一个键值对到底做了什么

把 `HashMap` 想成一层楼的一排储物柜：数组下标决定"柜号"，哈希值决定"该开哪个柜"。`put(k, v)` 的真实流程是：

1. 先算 `k.hashCode()`，再把它的高 16 位和低 16 位异或（源码里叫 `hash()`），目的是让高位也参与定位，减少冲突。
2. 用 `hash & (capacity - 1)` 求出数组下标。容量必须是 2 的幂，这样按位与就等价于取模但更快。
3. 柜子空着就直接放进去；不空就顺着链表比 `hashCode`，再比 `equals`——**hashCode 相同不代表是同一个键，还要 equals 说了算**。
4. 链表长度到 8 且数组长度 ≥ 64 时，该桶转成红黑树，把最坏查找从 O(n) 压回 O(log n)。
5. 元素总数超过 `容量 × 0.75` 时整个数组翻倍，所有元素重新分配柜号。

```java
Map<String, Integer> m = new HashMap<>(16);   // 已知要放 100 个键就别用默认值
m.put("张三", 88);
// 自定义对象作键：两个都必须重写
record Student(String id, int grade) {}        // record 自带 equals/hashCode，最省心
Map<Student, String> books = new HashMap<>();
books.put(new Student("S01", 90), "算法导论");
System.out.println(books.get(new Student("S01", 90)));  // 算法导论：靠 equals 命中
```

### HashSet 靠什么判重

`HashSet` 内部就是一个 `HashMap`，元素当键、值统一塞一个固定的占位对象。因此"Set 去重"和"Map 判键相同"是同一条规则：先比 `hashCode()`，再比 `equals()`。这也是为什么 `Set.of` 遇到重复元素会直接抛 `IllegalArgumentException`，而 `HashSet.add` 只是安静地返回 `false`。

```java
Set<String> seen = new HashSet<>();
for (String line : lines) {
    if (seen.add(line)) {           // add 返回 true 表示这是第一次出现
        System.out.println("新记录：" + line);
    }
}
```

### 泛型与通配符的选择口诀

声明容器时用最具体的类型；写方法参数时才考虑通配符。判断标准只有一句话：**这个参数我是只从里面读，还是只往里面写？**

```java
// 只读 → 上界 extends（PECS 里的 Producer Extends）
double sumOfNumbers(List<? extends Number> src) {
    double s = 0;
    for (Number n : src) s += n.doubleValue();   // 读没问题
    // src.add(1);   // 编译不过：编译器不知道 src 到底是 List<Integer> 还是 List<Double>
    return s;
}

// 只写 → 下界 super（PECS 里的 Consumer Super）
void fillIntegers(List<? super Integer> sink) {
    sink.add(1);                     // Integer 一定能安全放进 List<Number>
}
```

不写通配符的 `List<T>` 表示"我既读又写，且类型要精确匹配"。类型擦除让 `List<String>` 与 `List<Integer>` 在运行时是同一个 `List`，所以 `instanceof List<String>` 是非法语法，也只能写 `instanceof List`。

### 并发容器怎么选

`ArrayList` 和 `HashMap` 完全没有同步措施，两个线程同时写可能丢数据，HashMap 老版本在 JDK 7 甚至可能因扩容形成环形链表导致死循环。JDK 提供的替代方案有三种档次：

| 需求 | 用什么 | 代价 |
| --- | --- | --- |
| 并发读写都要快 | ConcurrentHashMap | 键值都不能为 null，size() 是近似值 |
| 读极多、写极少，且要保证遍历快照稳定 | CopyOnWriteArrayList | 每次写复制整个数组，写放大严重 |
| 只是想让旧代码线程安全 | `Collections.synchronizedList(...)` | 全表加一把锁，遍历仍需手动 synchronized |

```java
ConcurrentHashMap<String, LongAdder> hits = new ConcurrentHashMap<>();
hits.computeIfAbsent("首页", k -> new LongAdder()).increment();  // 原子计数，不用自己加锁
```

## 典型应用场景

| 场景 | 推荐做法 | 为什么 |
| --- | --- | --- |
| 有序列表、按下标访问 | ArrayList | 默认选择，读多写少 |
| 去重 | HashSet | 平均 O(1) 查找 |
| 键值映射 | HashMap | 日常首选 |
| 需要排序 | TreeMap | 按键有序 |
| 多线程并发 | ConcurrentHashMap | 分段锁，并发高 |
| 不可变集合 | List.of / Map.of | 防止意外修改 |

### 三个真实场景的选型推演

**场景一：班级成绩登记表。** 需要按学号查成绩、需要按分数从高到低打印榜单。一个 `HashMap<String, Integer>` 负责查（O(1)），另建一个 `TreeMap` 反向按分数排序会把逻辑拆散，更好的做法是把数据放 `ArrayList`，需要榜单时 `list.sort(Comparator.comparingInt(Student::score).reversed())` 现排现用。

**场景二：接口访问计数。** 单机内存里统计每个 URL 被访问多少次，用 `merge` 最省事：`counter.merge(url, 1, Integer::sum)`。一旦部署多实例或有并发线程，立刻换成 `ConcurrentHashMap<String, LongAdder>`，因为 `map.put(k, map.get(k)+1)` 这种"读—改—写"在并发下必丢更新。

**场景三：配置项白名单。** 一份几乎不改、每秒被读几千次的允许域名清单，用 `Set.copyOf(List.of(...))` 做只读集合最安全；如果偶尔要在运行期热更新且必须让正在遍历的线程不出错，`CopyOnWriteArrayList` 的快照迭代正合适。

**场景四：需要保留录入顺序的报表表头。** `LinkedHashMap` 是唯一同时给你 O(1) 查找和插入顺序的实现；`TreeMap` 会按 Comparator 重排，把"先录的列"打散成字典序。

## 代码/协议/SQL 示例

### 集合选型速查

```text
需求              首选实现            关键复杂度
─────────────────────────────────────────────────
有序、按下标        ArrayList          访问 O(1)、中间插入 O(n)
去重不关心顺序      HashSet           平均 O(1)
去重且要排序        TreeSet           O(log n)
键值映射            HashMap           平均 O(1)
键有序              TreeMap           O(log n)
线程安全            ConcurrentHashMap  平均 O(1)
不可变              List.of / Map.of   只读
```

### 词频统计练习

```java
Map<String, Integer> counts = new HashMap<>();
for (String w : text.split(" ")) {
    counts.merge(w, 1, Integer::sum);
}
```

### 不可变集合

```java
List<String> fixed = List.of("a", "b");
List<String> copy = new ArrayList<>(fixed);  // 需要改就拷一份
```

## 时间/空间复杂度或性能分析

| 容器 | 随机访问 | 插入删除 | 适用 |
| --- | --- | --- | --- |
| ArrayList | O(1) | 尾部 O(1)，中间 O(n) | 默认选择 |
| LinkedList | O(n) | 已知位置 O(1) | 频繁两端操作 |
| HashMap | 平均 O(1) | 平均 O(1) | 键值查找 |
| TreeMap | O(log n) | O(log n) | 有序遍历 |
| ConcurrentHashMap | 平均 O(1) | 平均 O(1) | 并发读写 |

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 遍历中删除 | ConcurrentModificationException | 用 removeIf 或迭代器 |
| List.of 后添加 | UnsupportedOperationException | 先 new ArrayList<>(...) |
| 用 == 比较元素 | 结果不确定 | 用 equals |
| HashMap 键是可变对象 | 改完后查不到 | 键用不可变类型 |
| list.remove(1) 想删元素 1 | 删掉的是下标 1 | 删对象写 remove(Integer.valueOf(1)) |
| Arrays.asList 当可变列表 | 长度固定增删报错 | 包一层 new ArrayList<> |
| HashMap 多线程并发写 | 数据错乱 | 改用 ConcurrentHashMap |

### 三条最容易在面试和作业里翻车的细节

**其一，`hashCode` 与 `equals` 只改一个。** 约定是"equals 判为相同的两个对象，hashCode 必须相同"。若你只重写 `equals`，两个内容一样的对象会落到不同桶里，`set.contains(x)` 返回 `false`；反过来只重写 `hashCode` 会让不同对象挤进同一桶后靠 `Object.equals` 判错。用 `record` 或让 IDE 生成可以一次配对生成。

**其二，把可变对象当键还改它。** `map.put(user, score)` 之后执行 `user.setName(...)`，该对象所在桶是按旧哈希算出来的，新哈希指向别的桶，这条记录就"查不到但仍在 map 里"，`size()` 看着正常却永远取不出值。键类型应该 `final` 字段或用 record。

**其三，误以为 `Arrays.asList` 和 `List.of` 是一回事。** 前者是数组的视图：`set` 可以，`add/remove` 抛 `UnsupportedOperationException`，且改数组会反映到列表；后者是真正的不可变集合，连 `set` 都不行，也不允许 `null`。要可变就老老实实 `new ArrayList<>(...)` 包一层。

## 与其他知识点的关系

- **先修**：《继承、接口与多态》——集合大量使用接口和泛型
- **后续**：《异常处理与文件 IO》——文件读取结果常存进集合
- **关联**：《Lambda 与 Stream API》——Stream 就是集合的函数式处理方式

### 学完这课后容器会出现在哪些地方

集合几乎串起 Java 后面所有章节：`Comparator` 是函数式接口的第一个实战（`list.sort(Comparator.comparing(...))` 直接传 Lambda）；`Iterator` 的模式匹配写法 `while (it.hasNext())` 依赖《继承、接口与多态》里的"面向接口编程"；泛型通配符会在《异常处理与文件 IO》的 `try (var lines = Files.readAllLines(path))` 里以 `List<String>` 形式回来；并发容器则是后面所有多线程章节的地基。反过来看，泛型与集合绑定得最紧的一条规则是：**方法签名里出现 `? extends T` 意味着你只从参数读，出现 `? super T` 意味着你只往参数写**，这个口径在 Stream 的 `Collector` 里会再次遇到。

## 自测题与参考答案

1. **ArrayList 和 LinkedList 怎么选？** 绝大多数场景选 ArrayList，只有频繁头尾操作才考虑 LinkedList。
2. **为什么遍历 List 时直接 remove 会抛异常？** 内部迭代器检测到集合结构被意外修改，用 removeIf 替代。
3. **HashMap 的键有什么要求？** 必须正确实现 equals 和 hashCode，推荐用不可变类型。
4. **泛型类型擦除是什么意思？** 编译后泛型信息被擦除，运行时 List<String> 和 List<Integer> 是同一个类。
5. **ConcurrentHashMap 为什么比 Hashtable 快？** 分段锁机制，不同段可以并发访问。

## 考点精讲

`集合框架与泛型` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据。

### 考点 1：第 1 题

- **题目**：不允许重复元素的集合是？
- **正确项**：Set
- **判断依据**：Set 的定义就是不允重复元素的集合，HashSet 基于 HashMap 实现。

### 考点 2：第 2 题

- **题目**：以下哪组集合类型更适合多线程并发访问？
- **正确项**：ConcurrentHashMap
- **判断依据**：ConcurrentHashMap 使用分段锁，支持高并发读写。

### 考点 3：第 3 题

- **题目**：这段 `java` 代码对应 `集合框架与泛型` 的 `List`。课程要解决的是List/Set/Map 的选择、遍历方式、泛型与通配符。关于代码内容，哪一项说法准确？
- **正确项**：调用了 `remove()`
- **判断依据**：本课 List 示例中包含 names.remove("alice") 调用。

### 考点 4：第 4 题

- **题目**：ArrayList 与 LinkedList 的选择依据是？
- **正确项**：随机访问多用 ArrayList
- **判断依据**：ArrayList 按下标访问 O(1)，LinkedList 需要 O(n) 遍历。

### 考点 5：第 5 题

- **题目**：下列哪些集合实现更适合高并发读写场景？请选择所有正确答案。
- **正确项**：ConcurrentHashMap；CopyOnWriteArrayList
- **判断依据**：ConcurrentHashMap 分段锁支持并发，CopyOnWriteArrayList 读多写少场景线程安全。

### 考点 6：第 6 题

- **题目**：下面几项都与 `List` 有关，请按 `集合框架与泛型` 的正文顺序排列；该课主线是List/Set/Map 的选择、遍历方式、泛型与通配符。
- **正确项**：集合体系 → List → Set → Map
- **判断依据**：本课按集合体系总览、List、Set、Map 的顺序展开讲解。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| List | 有序可重复集合，ArrayList 是默认选择 |
| Set | 不重复集合，HashSet 基于 HashMap |
| Map | 键值映射，HashMap 日常首选 |
| 泛型 | 编译期类型检查，运行时擦除 |
| ConcurrentHashMap | 线程安全的 HashMap 替代 |
| removeIf | 安全删除集合元素的正确方式 |
| Iterator | 集合游标，hasNext/next/remove 三件套 |
| modCount | 集合结构修改次数，fail-fast 检测靠它 |
| 负载因子 | HashMap 扩容阈值比例，默认 0.75 |
| PECS | Producer-Extends, Consumer-Super 的通配符口诀 |
| ArrayDeque | 栈与队列的首选实现，两端操作均摊 O(1) |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE 官方教程：集合](https://docs.oracle.com/javase/tutorial/collections/) | 集合框架基础语法 |
| [Java SE API 文档](https://docs.oracle.com/en/java/javase/21/docs/api/) | 集合与泛型 API 查询 |
| [dev.java 学习路径](https://dev.java/learn/) | 现代 Java 官方入门教程 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle；本课聚焦 List。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：List、Set、Map、HashMap、泛型、ConcurrentHashMap
