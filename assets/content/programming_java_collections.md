# 集合框架与泛型

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：60 分钟

![HashMap 数组、链表与红黑树](images/diagram_java_collections.webp)

![集合框架与泛型](images/remaining_java_collections.webp)

## 本节知识框架

**课程定位**：所属分类 `java`（Java），课程主题 `集合框架与泛型`，学习阶段 进阶，建议用时 55 分钟。

本课主线：List/Set/Map 的选择、遍历方式、泛型与通配符。

**学完本课应当能够**
- 说清 `List` 与 `Set` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `Map` 的行为，记录输入、输出与失败条件。
- 遇到「遍历中删除」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `List`：先掌握 names.add("tom")，再用它解释 `Set` 为什么会出现。
2. `Set`：先掌握 tags.add("java")，再用它解释 `Map` 为什么会出现。
3. `Map`：先掌握 键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择，再用它解释 `HashMap` 为什么会出现。
4. `HashMap`：先掌握 日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap，再用它解释 `类型擦除` 为什么会出现。
5. `类型擦除`：先掌握 泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现，再用它解释 `不可变集合` 为什么会出现。
6. `不可变集合`：先掌握 不可变集合能防止意外修改，适合当返回值或常量，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Java」分类的第 11 课。先修内容：《继承、接口与多态》。《继承、接口与多态》里的 `super`、`继承` 是本课的前提。相关或后续课程：《异常处理与文件 IO》。

### 完成判据

- **定义关**：不看正文也能说明 `List` 是 names.add("tom")，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `集合框架与泛型`，而不是只背结论。
- **示例关**：能运行或推演 `集合框架与泛型` 的 `text` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `集合框架与泛型` 示例里的 调用了 `add()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 遍历中删除，记录现象并按 用 `removeIf` 或迭代器 修复。
- **迁移关**：能把 `List`、`Set`、`Map`、`HashMap` 放进一个与 `集合框架与泛型` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `集合框架与泛型` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| List | names.add("tom")。 | 易错：`UnsupportedOperationException`；正确做法是先 `new ArrayList<>(...)`。 |
| Set | tags.add("java")。 | 易错：List 判存在很慢；正确做法是改用 `HashSet`。 |
| Map | 键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择。 | 易错：改完后查不到；正确做法是键用不可变类型。 |
| HashMap | 日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap。 | 易错：改完后查不到；正确做法是键用不可变类型。 |
| 类型擦除 | 泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现。 | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |
| 不可变集合 | 不可变集合能防止意外修改，适合当返回值或常量 | 只在「不可变集合能防止意外修改，适合当返回值或常量」这一前提下成立，换输入或换环境要重新验证。 |

## 原理与运行机制

### 机制总览

**教材衔接：集合选型速查**

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

**教材衔接：版本与时效**

- 版本基线会影响 List 的可用 API，升级前先用编译与测试验证。
- 若 LinkedHashSet 依赖线程或 GC 行为，升级时要重点验证并发与停顿指标。
- 升级前确认 List 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 List 相关的差异单独记成一条结论。
- 先回归 List 与 Set 的默认行为和错误信息，再扩大测试范围。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 List 的版本变化。

### 机制拆解：每一步的输入、动作与输出

#### 1. `List`
- 输入：`List`；本步把 names.add("tom") 当作判断规则。
- 动作：围绕 `List` 保留中间状态，并记录它与 `Set` 的对应关系。
- 输出：`Set`，它可以被下一段代码、测试或记录继续使用。
- `List` 的失败条件：当`List.of` 后添加时，会出现`UnsupportedOperationException`。

#### 2. `Set`
- 输入：`List`；本步把 tags.add("java") 当作判断规则。
- 动作：围绕 `Set` 保留中间状态，并记录它与 `Map` 的对应关系。
- 输出：`Map`，它可以被下一段代码、测试或记录继续使用。
- `Set` 的失败条件：当`contains` 用错集合时，会出现List 判存在很慢。

#### 3. `Map`
- 输入：`Set`；本步把 键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择 当作判断规则。
- 动作：围绕 `Map` 保留中间状态，并记录它与 `HashMap` 的对应关系。
- 输出：`HashMap`，它可以被下一段代码、测试或记录继续使用。
- `Map` 的失败条件：当`HashMap` 的键是可变对象时，会出现改完后查不到。

#### 4. `HashMap`
- 输入：`Map`；本步把 日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap 当作判断规则。
- 动作：围绕 `HashMap` 保留中间状态，并记录它与 `类型擦除` 的对应关系。
- 输出：`类型擦除`，它可以被下一段代码、测试或记录继续使用。
- `HashMap` 的失败条件：当`HashMap` 的键是可变对象时，会出现改完后查不到。

#### 5. `类型擦除`
- 输入：`HashMap`；本步把 泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现 当作判断规则。
- 动作：围绕 `类型擦除` 保留中间状态，并记录它与 `不可变集合` 的对应关系。
- 输出：`不可变集合`，它可以被下一段代码、测试或记录继续使用。
- `类型擦除` 的失败条件：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

#### 6. `不可变集合`
- 输入：`类型擦除`；本步把 不可变集合能防止意外修改，适合当返回值或常量 当作判断规则。
- 动作：围绕 `不可变集合` 保留中间状态，并记录它与 `add` 的对应关系。
- 输出：`add`，它可以被下一段代码、测试或记录继续使用。
- `不可变集合` 的失败条件：只在「不可变集合能防止意外修改，适合当返回值或常量」这一前提下成立，换输入或换环境要重新验证。

### 示例中的可观察事实

1. 调用了 `add()`；它对应的课程主题是 `集合框架与泛型`。
2. 调用了 `set()`；它对应的课程主题是 `集合框架与泛型`。
3. 调用了 `remove()`；它对应的课程主题是 `集合框架与泛型`。
4. 调用了 `println()`；它对应的课程主题是 `集合框架与泛型`。
5. 调用了 `get()`；它对应的课程主题是 `集合框架与泛型`。
6. 调用了 `size()`；它对应的课程主题是 `集合框架与泛型`。
7. 调用了 `sort()`；它对应的课程主题是 `集合框架与泛型`。
8. 调用了 `naturalOrder()`；它对应的课程主题是 `集合框架与泛型`。

### 复现实验记录

- 环境：`集合框架与泛型` 使用 `text` 示例，固定 `List`、`Set`、`Map`、`HashMap` 作为第一组条件。
- 首轮输入：先确认 调用了 `add()`，预测 `List` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `List`，观察 `不可变集合` 是否仍满足定义。
- 失败注入：复现 遍历中删除，确认现象是 `ConcurrentModificationException`。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `集合框架与泛型` 时才能区分概念错误与实现错误。

## 典型应用场景

- **遍历中删除**：典型现象是`ConcurrentModificationException`；正确做法是用 `removeIf` 或迭代器。
- **`List.of` 后添加**：典型现象是`UnsupportedOperationException`；正确做法是先 `new ArrayList<>(...)`。
- **用 `==` 比较元素**：典型现象是结果不确定；正确做法是用 `equals`。
- **`HashMap` 的键是可变对象**：典型现象是改完后查不到；正确做法是键用不可变类型。

### 最小验证场景

- 准备：保留 `text` 示例的原始输入，先记录 `集合框架与泛型` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `add()`，再改变一个与 `List` 相关的条件。
- 判定：新结果与 `集合框架与泛型` 的基线不同不等于错误；只有当差异破坏了 `List` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `List` 时，先满足它的定义：names.add("tom")；易错：`UnsupportedOperationException`；正确做法是先 `new ArrayList<>(...)`。
- 使用 `Set` 时，先满足它的定义：tags.add("java")；易错：List 判存在很慢；正确做法是改用 `HashSet`。
- 使用 `Map` 时，先满足它的定义：键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择；易错：改完后查不到；正确做法是键用不可变类型。
- 使用 `HashMap` 时，先满足它的定义：日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap；易错：改完后查不到；正确做法是键用不可变类型。
- 使用 `类型擦除` 时，先满足它的定义：泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现；共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

## 代码/协议/SQL 示例

### 最小可验证示例

```text
Collection ─┬─ List（有序、可重复）→ ArrayList / LinkedList
            ├─ Set（不可重复）      → HashSet / TreeSet / LinkedHashSet
            └─ Queue（队列）        → ArrayDeque / PriorityQueue
Map（键值对）→ HashMap / TreeMap / LinkedHashMap
```

**教材衔接：集合体系**

**教材衔接：List**

```java
List<String> names = new ArrayList<>();
names.add("tom");
names.add(1, "alice");            // 指定位置插入
names.set(0, "bob");              // 修改
names.remove("alice");

System.out.println(names.get(0));
System.out.println(names.size());
names.sort(Comparator.naturalOrder());

List<String> fixed = List.of("a", "b");   // 不可变列表
```

`ArrayList` 随机访问快，`LinkedList` 中间插删快但实际使用较少（缓存不友好）。

**教材衔接：Set**

```java
Set<String> tags = new HashSet<>();
tags.add("java");
tags.add("java");                 // 重复元素不会被加入
System.out.println(tags.contains("java"));

Set<String> ordered = new LinkedHashSet<>();   // 保留插入顺序
Set<Integer> sorted = new TreeSet<>();         // 自动排序
```

**教材衔接：Map**

```java
Map<String, Integer> scores = new HashMap<>();
scores.put("math", 90);
scores.putIfAbsent("english", 85);

System.out.println(scores.getOrDefault("history", 0));   // 不存在时返回默认值

for (Map.Entry<String, Integer> entry : scores.entrySet()) {
    System.out.println(entry.getKey() + "=" + entry.getValue());
}

scores.forEach((subject, score) -> System.out.println(subject + score));
```

**教材衔接：泛型**

```java
public class Box<T> {                  // 泛型类
    private T value;
    public void set(T value) { this.value = value; }
    public T get() { return value; }
}

public static <T extends Comparable<T>> T max(List<T> items) {   // 泛型方法 + 上界
    T result = items.get(0);
    for (T item : items) if (item.compareTo(result) > 0) result = item;
    return result;
}

List<? extends Number> numbers = List.of(1, 2.5);    // 上界通配符：只读
List<? super Integer> sink = new ArrayList<Number>(); // 下界通配符：可写
```

泛型在编译后会**类型擦除**，因此不能 `new T[]`，也不能对泛型做 `instanceof`。

**教材衔接：零基础详解：List、Set、Map 怎么选**

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

### 示例精读：先找证据，再改一个条件

1. 调用了 `add()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `set()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `remove()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `println()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `get()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `size()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `sort()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `naturalOrder()`；它出现在 `集合框架与泛型` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `集合框架与泛型` 中与 `List` 对照：示例必须能支持 names.add("tom")，否则说明这一段还缺少实现或验证步骤。
- 在 `集合框架与泛型` 中与 `Set` 对照：示例必须能支持 tags.add("java")，否则说明这一段还缺少实现或验证步骤。
- 在 `集合框架与泛型` 中与 `Map` 对照：示例必须能支持 键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择，否则说明这一段还缺少实现或验证步骤。
- 在 `集合框架与泛型` 中与 `HashMap` 对照：示例必须能支持 日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**复杂度证据**：本课正文出现 `O(1)`、`O(n)`、`O(log n)` 等量级表达式；使用前要同时确认输入规模、最好/平均/最坏情况以及常数项来源。

| 容器 | 随机访问 | 插入删除 | 适用 |
| --- | --- | --- | --- |
| ArrayList | O(1) | 尾部均摊 O(1)，中间 O(n) | 默认选择，读多写少 |
| LinkedList | O(n) | 已知位置 O(1) | 频繁在两端操作（多数场景仍不如 ArrayDeque） |
| HashMap | 平均 O(1) | 平均 O(1) | 键值查找，需正确实现 equals/hashCode |
| TreeMap | O(log n) | O(log n) | 需要有序遍历或范围查询 |
| ArrayDeque | 两端 O(1) | 两端 O(1) | 栈与队列的首选 |

**测量方法**：以 `集合框架与泛型` 的 `List` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `集合框架与泛型` 的 `List`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `集合框架与泛型` 的 `Set`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `集合框架与泛型` 的 `Map`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `集合框架与泛型` 的 `HashMap`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `集合框架与泛型` 的 `泛型`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `集合框架与泛型` 中 `List` 的边界：易错：`UnsupportedOperationException`；正确做法是先 `new ArrayList<>(...)`。达到边界时不要外推，必须重新测量。
- `集合框架与泛型` 中 `Set` 的边界：易错：List 判存在很慢；正确做法是改用 `HashSet`。达到边界时不要外推，必须重新测量。
- `集合框架与泛型` 中 `Map` 的边界：易错：改完后查不到；正确做法是键用不可变类型。达到边界时不要外推，必须重新测量。
- `集合框架与泛型` 中 `HashMap` 的边界：易错：改完后查不到；正确做法是键用不可变类型。达到边界时不要外推，必须重新测量。
- `集合框架与泛型` 中 `类型擦除` 的边界：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。达到边界时不要外推，必须重新测量。
- `集合框架与泛型` 的代码证据：先验证 调用了 `add()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 遍历中删除 | `ConcurrentModificationException` | 用 `removeIf` 或迭代器 |
| `List.of` 后添加 | `UnsupportedOperationException` | 先 `new ArrayList<>(...)` |
| 用 `==` 比较元素 | 结果不确定 | 用 `equals` |
| `HashMap` 的键是可变对象 | 改完后查不到 | 键用不可变类型 |
| 返回 `null` 集合 | 调用方空指针 | 返回空集合 |
| `Arrays.asList` 当可变列表 | 长度固定，增删报错 | 包一层 `new ArrayList<>` |
| 只看接口不选实现 | 顺序或性能不达标 | 按需求挑实现类 |
| `contains` 用错集合 | List 判存在很慢 | 改用 `HashSet` |
| `list.remove(1)` 想删元素 1 | 删掉的是下标 1 | 参数是 `int` 时按下标删除；删对象要写 `list.remove(Integer.valueOf(1))` |
| 遍历 List 时 `list.remove(e)` | `ConcurrentModificationException` | 用 `Iterator.remove()` 或 `removeIf(...)` |
| `map.get(key)` 后直接 `+1` | `NullPointerException` | 用 `getOrDefault(key, 0)` 或 `merge` |
| 只用 `equals` 不重写 `hashCode` | `HashSet` 里出现「重复」元素 | 两者必须成对重写，或用 `record` 自动生成 |
| `Arrays.asList(...)` 后 `add` | `UnsupportedOperationException` | 它返回固定大小的视图，改成 `new ArrayList<>(Arrays.asList(...))` |
| `List.of(...)` 里放 null | `NullPointerException` | 不可变工厂不允许 null，用 `Collections.singletonList` 或 `ArrayList` |
| `HashMap` 在多线程下并发写 | 数据错乱甚至死循环 | 改用 `ConcurrentHashMap`，或用 `computeIfAbsent` 做原子初始化 |
| 遍历 `keySet()` 再 `get` | 多一次查找 | 遍历 `entrySet()` 一次拿键值 |
| 用可变对象作 `HashMap` 的键 | 改字段后查不到 | 键应使用不可变对象（`String`、`record`） |
| list.remove(1) 想删元素 1 | 删掉的是下标 1。 | 参数是 int 时按下标删除；删对象要写 list.remove(Integer.valueOf(1))。 |
| 遍历 List 时 list.remove(e) | ConcurrentModificationException。 | 用 Iterator.remove() 或 removeIf(...)。 |
| map.get(key) 后直接 +1 | NullPointerException。 | 用 getOrDefault(key, 0) 或 merge。 |

### 现场 1：遍历中删除

**症状**：`ConcurrentModificationException`。

**根因与修复**：用 `removeIf` 或迭代器。

**自检**：在本课示例里复现「遍历中删除」，改成用 `removeIf` 或迭代器后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：`List.of` 后添加

**症状**：`UnsupportedOperationException`。

**根因与修复**：先 `new ArrayList<>(...)`。

**自检**：在本课示例里复现「`List.of` 后添加」，改成先 `new ArrayList<>(...)`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：用 `==` 比较元素

**症状**：结果不确定。

**根因与修复**：用 `equals`。

**自检**：在本课示例里复现「用 `==` 比较元素」，改成用 `equals`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：`HashMap` 的键是可变对象

**症状**：改完后查不到。

**根因与修复**：键用不可变类型。

**自检**：在本课示例里复现「`HashMap` 的键是可变对象」，改成键用不可变类型后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：返回 `null` 集合

**症状**：调用方空指针。

**根因与修复**：返回空集合。

**自检**：在本课示例里复现「返回 `null` 集合」，改成返回空集合后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：`Arrays.asList` 当可变列表

**症状**：长度固定，增删报错。

**根因与修复**：包一层 `new ArrayList<>`。

**自检**：在本课示例里复现「`Arrays.asList` 当可变列表」，改成包一层 `new ArrayList<>`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：只看接口不选实现

**症状**：顺序或性能不达标。

**根因与修复**：按需求挑实现类。

**自检**：在本课示例里复现「只看接口不选实现」，改成按需求挑实现类后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：`contains` 用错集合

**症状**：List 判存在很慢。

**根因与修复**：改用 `HashSet`。

**自检**：在本课示例里复现「`contains` 用错集合」，改成改用 `HashSet`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：`list.remove(1)` 想删元素 1

**症状**：删掉的是下标 1。

**根因与修复**：参数是 `int` 时按下标删除；删对象要写 `list.remove(Integer.valueOf(1))`。

**自检**：在本课示例里复现「`list.remove(1)` 想删元素 1」，改成参数是 `int` 时按下标删除；删对象要写 `list.remove(Integer.valueOf(1))`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

**教材衔接：常用方法对照**

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

- **先修**：`继承、接口与多态`。本课默认这些内容已经掌握。
- **相关或后续**：`异常处理与文件 IO`。本课术语会在这些课程里继续使用。
- **术语归属**：`List`、`Set`、`Map` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。

### 先修与后续术语接口

- `继承、接口与多态`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。
- `异常处理与文件 IO`：两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件。

### 容易混淆的相邻概念

- `List` 与 `Set`：前者强调 names.add("tom")；后者强调 tags.add("java")。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `Set` 与 `Map`：前者强调 tags.add("java")；后者强调 键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `Map` 与 `HashMap`：前者强调 键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择；后者强调 日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `HashMap` 与 `类型擦除`：前者强调 日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap；后者强调 泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `类型擦除` 与 `不可变集合`：前者强调 泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现；后者强调 不可变集合能防止意外修改，适合当返回值或常量。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `List` 的操作性定义，并说明它与 `Set` 的区别。

**参考答案**：names.add("tom")。

`Set` 的定位是：tags.add("java")；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「遍历中删除」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是`ConcurrentModificationException`；正确做法是用 `removeIf` 或迭代器。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `text` 示例，改动其中一个输入后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `text` 示例应当复现正文给出的结果；改动输入后，如果结果改变或报错，先核对它是否满足 `集合框架与泛型` 中`List` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `text` 示例，说明它体现了`List` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`List` 的定义是 names.add("tom")，示例正是在实现这条定义。改动与 `List` 有关的一个输入后，如果结果不再符合 `集合框架与泛型` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `集合框架与泛型` 的方法迁移到自己的项目：围绕 `List` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「map.get(key) 后直接 +1」，它会导致NullPointerException；检验方式是按用 getOrDefault(key, 0) 或 merge改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `List` 与 `Set`：各写一行适用场景、一行失败表现。

**参考答案**：`List` 的定义是names.add("tom")；`Set` 的定义是tags.add("java")。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「遍历中删除」引发的问题，请把“复现 `ConcurrentModificationException` → 保留证据 → 用 `removeIf` 或迭代器 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按`ConcurrentModificationException`复现；第二步记录输入、版本与完整报错；第三步按用 `removeIf` 或迭代器只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `不可变集合`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：只在「不可变集合能防止意外修改，适合当返回值或常量」这一前提下成立，换输入或换环境要重新验证。 同时要把 `不可变集合` 的定义 不可变集合能防止意外修改，适合当返回值或常量 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `List` → `Set` → `Map` → `HashMap` 的作用链。

**参考答案**：起点是 `List` 的定义 names.add("tom")；中间每一步都保留可观察状态；终点由 `不可变集合` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `集合框架与泛型` 中，现象是 NullPointerException。请围绕 map.get(key) 后直接 +1 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 map.get(key) 后直接 +1，记录输入与完整错误；再按 用 getOrDefault(key, 0) 或 merge 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `集合框架与泛型`：先给主问题，再按顺序说出 `List`、`Set`、`Map`、`HashMap`，最后给一个失败案例。

**自评标准**：主问题必须对应 List/Set/Map 的选择、遍历方式、泛型与通配符；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `List` | names.add("tom")。 |
| `Set` | tags.add("java")。 |
| `Map` | 键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择。 |
| `HashMap` | 日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap。 |
| `类型擦除` | 泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现。 |
| `不可变集合` | 不可变集合能防止意外修改，适合当返回值或常量。 |

**术语关系**：`List`（names.add("tom")） → `Set`（tags.add("java")） → `Map`（键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序） → `HashMap`（日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景）。

## 考点精讲

`集合框架与泛型` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：不允许重复元素的集合是？
- **正确项**：Set
- **判断依据**：这道题落在术语 `Set` 上：tags.add("java")。复习时把 `Set` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：以下哪组集合类型更适合多线程并发访问？
- **正确项**：ConcurrentHashMap
- **判断依据**：这道题落在术语 `Map` 上：键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择。复习时把 `Map` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：这段 `java` 代码对应 `集合框架与泛型` 的 `List`。课程要解决的是List/Set/Map 的选择、遍历方式、泛型与通配符。关于代码内容，哪一项说法准确？
- **正确项**：调用了 `remove()`
- **判断依据**：这道题落在术语 `List` 上：names.add("tom")。复习时把 `List` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：ArrayList 与 LinkedList 的选择依据是？
- **正确项**：随机访问多用 ArrayList
- **判断依据**：这道题落在术语 `List` 上：names.add("tom")。复习时把 `List` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：下列哪些集合实现更适合高并发读写场景？请选择所有正确答案。
- **正确项**：ConcurrentHashMap；CopyOnWriteArrayList
- **判断依据**：这道题落在术语 `List` 上：names.add("tom")。复习时把 `List` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：下面几项都与 `List` 有关，请按 `集合框架与泛型` 的正文顺序排列；该课主线是List/Set/Map 的选择、遍历方式、泛型与通配符。
- **正确项**：集合体系 → List → Set → Map
- **判断依据**：这道题落在术语 `List` 上：names.add("tom")。复习时把 `List` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`List`

- **要点**：names.add("tom")。
- **List 的边界**：易错：`UnsupportedOperationException`；正确做法是先 `new ArrayList<>(...)`。

### 考点 8：`Set`

- **要点**：tags.add("java")。
- **Set 的边界**：易错：List 判存在很慢；正确做法是改用 `HashSet`。

### 考点 9：`Map`

- **要点**：键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择。
- **Map 的边界**：易错：改完后查不到；正确做法是键用不可变类型。

### 考点 10：`HashMap`

- **要点**：日常组合：ArrayList + HashMap + HashSet 覆盖 90% 场景；需要排序用 TreeMap/TreeSet，需要线程安全用 ConcurrentHashMap。
- **HashMap 的边界**：易错：改完后查不到；正确做法是键用不可变类型。

### 考点 11：`类型擦除`

- **要点**：泛型类型参数在运行时被擦除，使不同参数化类型共享同一份实现。
- **类型擦除 的边界**：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

### 考点 12：`不可变集合`

- **要点**：不可变集合能防止意外修改，适合当返回值或常量
- **不可变集合 的边界**：只在「不可变集合能防止意外修改，适合当返回值或常量」这一前提下成立，换输入或换环境要重新验证。

### 考点 13：排错——遍历中删除

- **现象**：`ConcurrentModificationException`。
- **处理**：用 `removeIf` 或迭代器。

### 考点 14：排错——`List.of` 后添加

- **现象**：`UnsupportedOperationException`。
- **处理**：先 `new ArrayList<>(...)`。

### 考点 15：综合辨析——`List` 与 `不可变集合`

- **辨析点**：`List` 的定义是 names.add("tom")；`不可变集合` 的定义是 不可变集合能防止意外修改，适合当返回值或常量。
- **答题要求**：面对 `集合框架与泛型` 的题目，先判断描述的是 `List` 还是 `不可变集合`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 16：排错评分点

- **现象分**：能写出 `ConcurrentModificationException`，而不是只写“程序有错”。
- **证据分**：保留触发 遍历中删除 的输入、版本和错误原文。
- **修复分**：按 用 `removeIf` 或迭代器 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Java 21+ / Maven 或 Gradle；本课聚焦 List。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：List、Set、Map、HashMap、泛型、类型擦除
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-02-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：List、Set、Map、HashMap、泛型、类型擦除。

| 参考资料 | 本课用途 |
| --- | --- |
| [Java SE API](https://docs.oracle.com/en/java/javase/21/docs/api/) | 标准库 API |
| [dev.java 学习](https://dev.java/learn/) | 现代 Java 官方教程 |
| [JDBC 教程](https://docs.oracle.com/javase/tutorial/jdbc/) | 数据库连接与事务 |

| [本课术语索引：集合框架与泛型](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「集合框架与泛型」的链接用于离线阅读后的延伸核对；App 不会自动联网。