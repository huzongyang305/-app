# 排序算法家族

![排序算法家族](images/remaining_sorting.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：17 分钟

## 学习目标

- 能用自己的话解释「排序算法家族」解决了什么问题，而不是只背术语。
- 能说清 「排序」、「快排」、「归并」、「稳定性」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「算法与数据结构」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：插入/归并/快排实现、复杂度与稳定性对比。

## 前置知识

- 先完成上一课《图与图算法》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：排序、快排、归并。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 复杂度与稳定性对比

| 算法 | 平均 | 最坏 | 空间 | 稳定 |
| --- | --- | --- | --- | --- |
| 冒泡排序 | O(n²) | O(n²) | O(1) | 是 |
| 插入排序 | O(n²) | O(n²) | O(1) | 是 |
| 选择排序 | O(n²) | O(n²) | O(1) | 否 |
| 归并排序 | O(n log n) | O(n log n) | O(n) | 是 |
| 快速排序 | O(n log n) | O(n²) | O(log n) | 否 |
| 堆排序 | O(n log n) | O(n log n) | O(1) | 否 |
| 计数排序 | O(n + k) | O(n + k) | O(k) | 是 |

稳定性指相等元素排序后相对顺序不变；多关键字排序时会用到这个性质。

## 插入排序：小数组的性能王者

```python
def insertion_sort(nums):
    for i in range(1, len(nums)):
        current, j = nums[i], i - 1
        while j >= 0 and nums[j] > current:
            nums[j + 1] = nums[j]
            j -= 1
        nums[j + 1] = current
    return nums
```

数据接近有序时接近 `O(n)`，因此常被用作大排序算法在小数组上的收尾。

## 归并排序：稳定 + 分治

```python
def merge_sort(nums):
    if len(nums) <= 1:
        return nums
    mid = len(nums) // 2
    left, right = merge_sort(nums[:mid]), merge_sort(nums[mid:])
    merged, i, j = [], 0, 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:      # <= 保证稳定
            merged.append(left[i]); i += 1
        else:
            merged.append(right[j]); j += 1
    merged += left[i:] + right[j:]
    return merged
```

归并排序是**外部排序**与链表排序的基础（不需要随机访问）。

## 快速排序：交换 + 分区

```python
def quick_sort(nums, low=0, high=None):
    high = len(nums) - 1 if high is None else high
    if low >= high:
        return nums
    pivot, i = nums[high], low
    for j in range(low, high):
        if nums[j] < pivot:
            nums[i], nums[j] = nums[j], nums[i]
            i += 1
    nums[i], nums[high] = nums[high], nums[i]
    quick_sort(nums, low, i - 1)
    quick_sort(nums, i + 1, high)
    return nums
```

快排常数小、缓存友好，是通用排序的首选；但取端点作基准遇到有序数据会退化，可用随机基准或三数取中。

## 工程实践

```python
nums = [3, 1, 2]
nums.sort()                        # 原地排序，Timsort：稳定、O(n log n)
sorted(nums, key=lambda x: -x)     # 返回新列表，支持 key 函数
words.sort(key=len)
records.sort(key=lambda r: (r.age, r.name))   # 多关键字
```

Python 的 Timsort 与 Java 的 TimSort 都是「归并 + 插入」的混合算法，对真实数据（部分有序）表现极好。

## 本课小结
面试要能说出各算法的**复杂度、稳定性与适用场景**；工程中直接使用语言内置排序，除非有特殊约束（内存极小、外部排序、只需要 TopK）。

<!-- appendix:v1 -->

## 选择依据速查

| 需求 | 推荐算法 | 原因 |
| --- | --- | --- |
| 通用排序 | 快速排序 / Timsort | 平均最快、缓存友好 |
| 要求稳定 | 归并排序 / Timsort | 相等元素保持原顺序 |
| 空间受限 | 堆排序 | O(1) 额外空间 |
| 近乎有序 | 插入排序 / Timsort | 接近 O(n) |
| 整数且范围小 | 计数排序 | O(n+k) 线性 |
| 多位数整数或字符串 | 基数排序 | 按位稳定排序 |
| 只取 TopK | 堆 / 快速选择 | 不必全排序 |
| 链表排序 | 归并排序 | 不需要随机访问 |
| 外部大文件 | 外部归并排序 | 分块 + 多路归并 |

稳定性速查：

| 稳定 | 不稳定 |
| --- | --- |
| 冒泡、插入、归并、计数、基数、Timsort | 选择、快速、堆、希尔 |

## 快速排序实现要点

```python
import random

def quick_sort(nums):
    """三路快排：处理大量重复元素更高效，最坏情况用随机主元规避。"""
    if len(nums) <= 1:
        return nums[:]

    pivot = random.choice(nums)               # 随机主元降低最坏概率
    less = [x for x in nums if x < pivot]
    equal = [x for x in nums if x == pivot]
    greater = [x for x in nums if x > pivot]
    return quick_sort(less) + equal + quick_sort(greater)


# 原地分区版（Lomuto）：额外空间 O(1)，递归栈 O(log n)
def partition(arr, low, high):
    pivot = arr[high]
    i = low - 1
    for j in range(low, high):
        if arr[j] <= pivot:
            i += 1
            arr[i], arr[j] = arr[j], arr[i]
    arr[i + 1], arr[high] = arr[high], arr[i + 1]
    return i + 1
```

要点：随机或三数取中选主元可避免已排序数据退化成 O(n²)；小数组（<16）切换插入排序更快；重复元素多用三路分区。

## 语言内置排序速查

| 语言 | 调用 | 稳定性 | 备注 |
| --- | --- | --- | --- |
| Python | `sorted(x)` / `x.sort()` | 稳定 | Timsort，`key` 只调用一次 |
| Java | `Arrays.sort` / `Collections.sort` | 对象稳定，基本类型不稳定 | 并行排序 `parallelSort` |
| JavaScript | `arr.sort(cmp)` | 现代引擎稳定 | 默认按字符串比较，数字必须传比较函数 |
| C++ | `std::sort` / `std::stable_sort` | 前者不稳定 | `sort` 平均 O(n log n) |
| Go | `sort.Slice` / `slices.Sort` | 不稳定 | 稳定版 `slices.SortStableFunc` |
| Rust | `sort` / `sort_by` / `sort_unstable` | 前者稳定 | 不稳定版更快 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 对已排序数据用固定主元快排 | O(n²) | 随机主元或三数取中 |
| JS 里 `[10, 9, 1].sort()` | 得到 `[1, 10, 9]` | 传 `(a, b) => a - b` |
| 认为所有排序都稳定 | 结果顺序不符合预期 | 明确算法稳定性 |
| 用比较排序排小范围整数 | 不必要的 O(n log n) | 用计数排序 |
| 排序时比较函数不满足严格弱序 | 崩溃或结果错乱 | 保证 `<` 自洽、不返回 true 表示相等 |
| 用 `key` 里做重计算 | 性能下降 | Python 的 `key` 每元素只调用一次，但重活仍要避免 |
| 需要 TopK 却全量排序 | 浪费时间 | 用堆或快速选择 |
| 原地排序后需要原顺序 | 数据被破坏 | 先复制或用稳定排序 |
| 大文件一次性读入排序 | 内存溢出 | 外部归并排序 |
| 忽略比较成本 | 复杂对象比较很慢 | 先提取 key 再排序（Schwartzian 变换） |

## 自测清单

- [ ] 能按稳定性、空间、数据特征选排序算法。
- [ ] 知道快排最坏 O(n²) 的成因与规避手段。
- [ ] 记得 JS 数字排序必须传比较函数。
- [ ] 会用 `key` 提取排序依据，避免重复计算。
- [ ] TopK 问题优先考虑堆或快速选择。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「排序、快排、归并」完成复述、实验和交付，每个结果都要能被别人检查。

先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「排序算法家族」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「快排」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

给定 8～12 个手工构造的数据，写出每一步状态，并统计比较或交换次数。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「排序」和「快排」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Sorting Algorithms

**Summary:** Insertion, merge, quick sort and trade-offs.

**Category:** Algorithms  
**Level:** 进阶  
**Key terms:** 排序, 快排, 归并, 稳定性, Timsort

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：任意主流语言（伪代码与复杂度为主）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：排序、快排、归并、稳定性、Timsort
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：排序算法家族

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| 复杂度与稳定性对比 | 稳定性指相等元素排序后相对顺序不变；多关键字排序时会用到这个性质。 | 复述要点 + 举一个反例 |
| 插入排序：小数组的性能王者 | def insertionsort(nums): for i in range(1, len(nums)): current, j = nums[i], i - 1 while… | 运行示例 + 换一个边界输入 |
| 归并排序：稳定 + 分治 | def mergesort(nums): if len(nums) <= 1: return nums mid = len(nums) // 2 left, right = m… | 运行示例 + 换一个边界输入 |
| 快速排序：交换 + 分区 | def quicksort(nums, low=0, high=None): high = len(nums) - 1 if high is None else high if… | 运行示例 + 换一个边界输入 |
| 工程实践 | nums = [3, 1, 2] nums.sort() # 原地排序，Timsort：稳定、O(n log n) sorted(nums, key=lambda x: -x)… | 运行示例 + 换一个边界输入 |
| 快速排序实现要点 | import random | 运行示例 + 换一个边界输入 |

### 二、机制与验证

1. **复杂度与稳定性对比**：稳定性指相等元素排序后相对顺序不变；多关键字排序时会用到这个性质。 验证方式：先复述要点，再举一个反例说明边界。
2. **插入排序：小数组的性能王者**：def insertionsort(nums): for i in range(1, len(nums)): current, j = nums[i], i - 1 while… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
3. **归并排序：稳定 + 分治**：def mergesort(nums): if len(nums) <= 1: return nums mid = len(nums) // 2 left, right = m… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
4. **快速排序：交换 + 分区**：def quicksort(nums, low=0, high=None): high = len(nums) - 1 if high is None else high if… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
5. **工程实践**：nums = [3, 1, 2] nums.sort() # 原地排序，Timsort：稳定、O(n log n) sorted(nums, key=lambda x: -x)… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
6. **快速排序实现要点**：import random 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。

### 三、专属检查问题

1. 「复杂度与稳定性对比」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「插入排序：小数组的性能王者」的输入和输出分别是什么？
3. 「归并排序：稳定 + 分治」最常见的失败方式是什么？如何定位？
4. 「快速排序：交换 + 分区」的适用边界在哪里？什么情况下不该使用？
5. 「工程实践」和相邻主题相比，最关键的差别是什么？
6. 「快速排序实现要点」如何验证自己真的掌握了？写出一个可执行的检查步骤。

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：复杂度与稳定性对比的核心要点是什么？**

答：稳定性指相等元素排序后相对顺序不变；多关键字排序时会用到这个性质。

**问：插入排序：小数组的性能王者的核心要点是什么？**

答：def insertionsort(nums): for i in range(1, len(nums)): current, j = nums[i], i - 1 while…

**问：归并排序：稳定 + 分治的核心要点是什么？**

答：def mergesort(nums): if len(nums) <= 1: return nums mid = len(nums) // 2 left, right = m…

**问：快速排序：交换 + 分区的核心要点是什么？**

答：def quicksort(nums, low=0, high=None): high = len(nums) - 1 if high is None else high if…

**问：工程实践的核心要点是什么？**

答：nums = [3, 1, 2] nums.sort() # 原地排序，Timsort：稳定、O(n log n) sorted(nums, key=lambda x: -x)…

**问：快速排序实现要点的核心要点是什么？**

答：import random

## 逐步练习：排序算法家族

### 练习 1：复杂度与稳定性对比

1. 不看原文，用自己的话复述：稳定性指相等元素排序后相对顺序不变；多关键字排序时会用到这个性质。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：插入排序：小数组的性能王者

1. 不看原文，用自己的话复述：def insertionsort(nums): for i in range(1, len(nums)): current, j = nums[i], i - 1 while…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：归并排序：稳定 + 分治

1. 不看原文，用自己的话复述：def mergesort(nums): if len(nums) <= 1: return nums mid = len(nums) // 2 left, right = m…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 4：快速排序：交换 + 分区

1. 不看原文，用自己的话复述：def quicksort(nums, low=0, high=None): high = len(nums) - 1 if high is None else high if…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 5：工程实践

1. 不看原文，用自己的话复述：nums = [3, 1, 2] nums.sort() # 原地排序，Timsort：稳定、O(n log n) sorted(nums, key=lambda x: -x)…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 6：快速排序实现要点

1. 不看原文，用自己的话复述：import random
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：排序算法家族

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「复杂度与稳定性对比」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「插入排序：小数组的性能王者」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「归并排序：稳定 + 分治」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「快速排序：交换 + 分区」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「工程实践」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「快速排序实现要点」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：排序算法家族

1. 「复杂度与稳定性对比」的输入和输出分别是什么？
2. 「插入排序：小数组的性能王者」最常见的失败方式是什么？如何定位？
3. 「归并排序：稳定 + 分治」的适用边界在哪里？什么情况下不该使用？
4. 「快速排序：交换 + 分区」和相邻主题相比，最关键的差别是什么？
5. 「工程实践」如何验证自己真的掌握了？写出一个可执行的检查步骤。
6. 「快速排序实现要点」要解决什么问题？请用一句话说明，并给出一个具体例子。

## 专属进阶任务 5：排序算法家族

把本课 6 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

### 验收标准

- 例子可以独立运行，输出与预期一致。
- 两条边界用例都说清了输入、预期与实际结果。
- 验证结论用一句话写清，不依赖“感觉正确”。

<!-- p2-references:v1 -->
## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [CP-Algorithms](https://cp-algorithms.com/) | 算法实现与复杂度 |
| [MIT OpenCourseWare 6.006](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/) | 算法设计与分析 |

> 本课主题：插入/归并/快排实现、复杂度与稳定性对比。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

