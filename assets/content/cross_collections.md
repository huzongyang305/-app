# 集合类型：九种语言横向对照

![集合类型：九种语言横向对照](images/category_cross_collections.webp)

> 内容更新时间：2026-10-03 · 学习阶段：入门 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释「集合类型：九种语言横向对照」解决了什么问题，而不是只背术语。
- 能说清 「列表」、「字典」、「集合」、「复杂度」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「跨语言对照」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：有序列表、键值映射、去重集合在九种语言里的对应实现与复杂度。

## 前置知识

- 先完成上一课《类型与变量：九种语言横向对照》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：入门。只需要基本计算机操作，不要求编程经验。
- 开始前先复习：列表、字典、集合。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话目标

「有序列表、键值映射、去重集合」这三种需求在每门语言里都有对应实现，
只是名字不同、能否变长不同、查找复杂度不同。认准这三类，换语言就不会迷路。

## 三种核心集合的对照

| 语言 | 有序列表 | 键值映射 | 去重集合 |
| --- | --- | --- | --- |
| Python | `list` / `tuple` | `dict` | `set` |
| JavaScript | `Array` | `Object` / `Map` | `Set` |
| TypeScript | `Array<T>` | `Record<K,V>` / `Map` | `Set<T>` |
| Java | `ArrayList` / `List` | `HashMap` / `Map` | `HashSet` / `Set` |
| C# | `List<T>` / 数组 | `Dictionary<K,V>` | `HashSet<T>` |
| C++ | `std::vector` / `std::array` | `std::unordered_map` / `std::map` | `std::unordered_set` |
| Go | `[]T`（切片） | `map[K]V` | 需自己用 `map[T]struct{}` |
| Rust | `Vec<T>` / `[T; N]` | `HashMap<K,V>` / `BTreeMap` | `HashSet<T>` / `BTreeSet` |
| Shell | 数组 `arr=(a b c)` | 关联数组 `declare -A m` | 无原生集合 |

## 增删改查：同一个动作，九种写法

```python
nums = [3, 1, 2]
nums.append(4)                 # 尾部添加
nums.sort()                    # 原地排序
nums[0]                        # 按下标取
3 in nums                      # 判断存在（O(n)）

scores = {"小明": 90}
scores["小红"] = 85            # 新增或覆盖
scores.get("小刚", 0)          # 取不到给默认值
```

```javascript
const nums = [3, 1, 2];
nums.push(4);                  // 尾部添加
const sorted = nums.toSorted((a, b) => a - b);   // 不改原数组
nums[0];
nums.includes(3);

const scores = new Map([["小明", 90]]);
scores.set("小红", 85);
scores.get("小刚") ?? 0;
```

```typescript
const scores = new Map<string, number>();
scores.set("小明", 90);
const list: number[] = [3, 1, 2];
```

```java
List<Integer> nums = new ArrayList<>(List.of(3, 1, 2));
nums.add(4);
Collections.sort(nums);
nums.get(0);
nums.contains(3);

Map<String, Integer> scores = new HashMap<>();
scores.put("小明", 90);
scores.getOrDefault("小刚", 0);
scores.merge("小明", 5, Integer::sum);   // 计数与累加
```

```csharp
var nums = new List<int> { 3, 1, 2 };
nums.Add(4);
nums.Sort();
nums[0];
nums.Contains(3);

var scores = new Dictionary<string, int> { ["小明"] = 90 };
scores["小红"] = 85;
scores.TryGetValue("小刚", out var v);
```

```cpp
#include <algorithm>
#include <unordered_map>
#include <vector>

std::vector<int> nums{3, 1, 2};
nums.push_back(4);
std::sort(nums.begin(), nums.end());
nums[0];
std::find(nums.begin(), nums.end(), 3) != nums.end();

std::unordered_map<std::string, int> scores{{"小明", 90}};
scores["小红"] = 85;
```

```go
nums := []int{3, 1, 2}
nums = append(nums, 4)
slices.Sort(nums)
nums[0]
slices.Contains(nums, 3)

scores := map[string]int{"小明": 90}
scores["小红"] = 85
if v, ok := scores["小刚"]; !ok {
    v = 0
}

// Go 没有内置集合：用 map 模拟
seen := map[int]struct{}{}
seen[3] = struct{}{}
_, exists := seen[3]
```

```rust
use std::collections::{HashMap, HashSet};

let mut nums = vec![3, 1, 2];
nums.push(4);
nums.sort();
nums[0];
nums.contains(&3);

let mut scores = HashMap::new();
scores.insert("小明", 90);
let v = scores.get("小刚").copied().unwrap_or(0);

let mut seen = HashSet::new();
seen.insert(3);
```

```bash
# Shell 数组与关联数组
nums=(3 1 2)
nums+=(4)
echo "${nums[0]}"
echo "${#nums[@]}"                    # 元素个数

declare -A scores
scores[小明]=90
echo "${scores[小明]:-0}"
```

## 复杂度速查

| 操作 | 动态数组 | 哈希表 | 有序树 |
| --- | --- | --- | --- |
| 按下标访问 | O(1) | —— | —— |
| 按键查找 | O(n) | 平均 O(1) | O(log n) |
| 尾部追加 | 均摊 O(1) | —— | —— |
| 中间插入 | O(n) | —— | —— |
| 有序遍历 | 需排序 | 无序 | 天然有序 |

## 一个高频任务：统计词频

```python
from collections import Counter
Counter("a b a c a".split()).most_common(2)
```

```javascript
const counts = new Map();
for (const w of "a b a c a".split(" ")) counts.set(w, (counts.get(w) ?? 0) + 1);
```

```java
Map<String, Integer> counts = new HashMap<>();
for (String w : "a b a c a".split(" ")) counts.merge(w, 1, Integer::sum);
```

```csharp
var counts = new Dictionary<string, int>();
foreach (var w in "a b a c a".Split(' '))
    counts[w] = counts.GetValueOrDefault(w) + 1;
```

```cpp
std::unordered_map<std::string, int> counts;
// 用 istringstream 逐个读入后 ++counts[word];
```

```go
counts := map[string]int{}
for _, w := range strings.Fields("a b a c a") {
    counts[w]++
}
```

```rust
use std::collections::HashMap;
let mut counts: HashMap<&str, i32> = HashMap::new();
for w in "a b a c a".split_whitespace() {
    *counts.entry(w).or_insert(0) += 1;
}
```

## 新手最容易踩的八个坑

| 坑 | 出现语言 | 正确做法 |
| --- | --- | --- |
| 用列表判存在 | Python、Java、C++ | 换集合或映射 |
| 遍历时删元素 | 多数语言 | 用迭代器安全删除或先复制 |
| 扩容后旧引用失效 | C++、Go、Rust | 扩容后重新获取元素引用 |
| 把数组当值传递 | Java、JavaScript | 注意引用语义，需要副本就显式复制 |
| 误以为 `{}` 是空集合 | Python | 空集合写 `set()` |
| 用 `for...in` 遍历数组 | JavaScript | 用 `for...of` 或下标循环 |
| 向 nil map 写入 | Go | 先 `make` |
| 关联数组未声明 | Shell | `declare -A` |

## 本课小结
- **记住三类需求**：有序列表、键值映射、去重集合，换语言时先找对应实现。
- **查找频繁就换哈希结构**，这是跨语言通用的第一条优化。
- 语言之间的差异主要在「语法糖」与「默认顺序」，复杂度规律是一致的。

<!-- scaffold:v1 -->

<!-- exercise-guard:v1 -->

## 动手练习

### 练习 1：概念复述（10 分钟）

合上教程，用 3～5 句话解释「集合类型：九种语言横向对照」解决什么问题，并写出一个边界条件。

**验收标准**：至少使用一个本课关键词，并给出一个反例。

### 练习 2：示例改写（20 分钟）

从正文选一个最小示例，先预测修改一个输入后的结果，再实际验证并记录差异。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：迁移任务（30 分钟）

选两种语言实现同一行为，列出语法、错误处理、性能和生态差异。

- 至少覆盖「列表」和「字典」两个关键词。
- 产出一个别人可以检查的结果。
- 写出一个仍不确定的问题和验证方法。

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Collections Across Languages

**Summary:** Lists, maps and sets compared with complexity notes.

**Category:** Cross-Language Comparison  
**Level:** 入门  
**Key terms:** 列表, 字典, 集合, 复杂度, 哈希表

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：入门
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：列表、字典、集合、复杂度、哈希表
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：集合类型：九种语言横向对照

### 一、知识地图

- **一句话目标**：「有序列表、键值映射、去重集合」这三种需求在每门语言里都有对应实现，
- **三种核心集合的对照**：理解它的定义、输入、输出和失败边界。
- **增删改查：同一个动作，九种写法**：nums = [3, 1, 2]
- **复杂度速查**：理解它的定义、输入、输出和失败边界。
- **一个高频任务：统计词频**：from collections import Counter
- **新手最容易踩的八个坑**：理解它的定义、输入、输出和失败边界。
- **练习 1：概念复述（10 分钟）**：合上教程，用 3～5 句话解释「集合类型：九种语言横向对照」解决什么问题，并写出一个边界条件。
- **练习 2：示例改写（20 分钟）**：从正文选一个最小示例，先预测修改一个输入后的结果，再实际验证并记录差异。

### 二、机制与验证

| 主题 | 需要回答的问题 | 验证方式 |
| --- | --- | --- |
| 一句话目标 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 三种核心集合的对照 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 增删改查：同一个动作，九种写法 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 复杂度速查 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 一个高频任务：统计词频 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 新手最容易踩的八个坑 | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 练习 1：概念复述（10 分钟） | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |
| 练习 2：示例改写（20 分钟） | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |

### 三、专属检查问题

1. 一句话目标 与相邻主题的边界是什么？
2. 三种核心集合的对照 与相邻主题的边界是什么？
3. 增删改查：同一个动作，九种写法 与相邻主题的边界是什么？
4. 复杂度速查 与相邻主题的边界是什么？
5. 一个高频任务：统计词频 与相邻主题的边界是什么？
6. 新手最容易踩的八个坑 与相邻主题的边界是什么？
7. 练习 1：概念复述（10 分钟） 与相邻主题的边界是什么？
8. 练习 2：示例改写（20 分钟） 与相邻主题的边界是什么？

### 四、故障排查

1. 固定输入和环境，确认问题能复现。
2. 找到第一个异常状态，不从最终错误倒猜。
3. 只改变一个变量，记录预测和真实结果。
4. 修复后补边界、失败和重复执行测试。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [DevDocs](https://devdocs.io/) | 多语言 API 快速检索 |
| [官方语言文档](https://developer.mozilla.org/docs/Web) | 跨语言语义对照 |

> 本课主题：有序列表、键值映射、去重集合在九种语言里的对应实现与复杂度。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

