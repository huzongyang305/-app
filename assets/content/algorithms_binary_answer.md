# 二分答案

![二分答案](images/remaining_binary_answer.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「二分答案」解决了什么问题，而不是只背术语。
- 能说清 「二分答案」、「可行性」、「最小化最大值」、「贪心」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「算法与数据结构」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：在答案空间二分，用可行性函数逼近最优解。

## 前置知识

- 先完成上一课《单调栈与单调队列》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：二分答案、可行性、最小化最大值。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 和二分查找的区别

```text
二分查找：在有序数组里找某个值
二分答案：在答案的取值范围内二分，用 check(mid) 判断这个答案是否可行
```

适用条件：答案具有**单调性**——若 x 可行，则所有比 x 更宽松（或更严格）的值也可行，从而可以二分逼近最优解。

## 通用模板

```python
def binary_answer(low, high, feasible):
    """求满足 feasible(x) 的最小 x（feasible 随 x 单调递增为真）"""
    while low < high:
        mid = (low + high) // 2
        if feasible(mid):
            high = mid          # mid 可行，尝试更小
        else:
            low = mid + 1       # mid 不可行，必须更大
    return low
```

求「最大可行值」时把可行分支改成 `low = mid`，并注意 `mid = (low + high + 1) // 2` 避免死循环。

## 例一：分割数组的最大值最小（最小化最大值）

把数组分成 k 段，使各段和的最大值最小：

```python
def split_array(nums, k):
    def feasible(limit):
        count, current = 1, 0
        for value in nums:
            if current + value > limit:
                count += 1
                current = value
                if count > k:
                    return False
            else:
                current += value
        return True
    low, high = max(nums), sum(nums)
    return binary_answer(low, high, feasible)
```

答案范围是 `[max(nums), sum(nums)]`，`feasible` 是贪心地在每段接近 limit 时切分。

## 例二：爱吃香蕉的珂珂

```python
import math

def min_eating_speed(piles, hours):
    def feasible(speed):
        return sum(math.ceil(p / speed) for p in piles) <= hours
    return binary_answer(1, max(piles), feasible)
```

速度越快耗时越短，满足单调性，因此可以二分速度。

## 例三：实数二分

```python
def sqrt_binary(x, eps=1e-10):
    low, high = 0.0, max(1.0, x)
    while high - low > eps:          # 用精度控制迭代
        mid = (low + high) / 2
        if mid * mid >= x:
            high = mid
        else:
            low = mid
    return low
```

实数二分固定迭代 100 次比用 eps 更稳妥。

## 解题步骤

1. 明确答案的含义与取值范围（下界/上界）。
2. 写 `feasible(x)`，通常用贪心或遍历，复杂度 O(n)。
3. 确认单调性：x 变大时 feasible 是「由真变假」还是「由假变真」。
4. 套模板，注意边界与死循环。

总复杂度 `O(n log V)`，V 是答案范围。

## 常见误区

- 单调性不成立却硬套二分（先举反例验证）。
- 上下界取错，导致漏掉最优解。
- `while low < high` 与 `low = mid` 的组合没处理好，造成死循环。
- 可行性函数写错，比二分本身更容易出错——先用暴力验证小数据。

## 三类判定函数的写法对比

| 判定类型 | 典型题 | 判定函数要点 |
| --- | --- | --- |
| 贪心可行性 | 分割数组最大和、装船问题 | 从左往右累加，超限就切一段，统计段数是否 ≤ 限制 |
| 计数可行性 | 学生分糖、最少天数 | 按规则累计需求量，与预算比较 |
| 数学推导 | 开方、最小速度 | 用公式直接算出需要的步数或时间 |

写判定函数的三个要求：**只返回真假**（不要在里面做二分）、**复杂度 O(n) 或 O(log n)**（否则总复杂度会退化）、**边界明确**（空输入、单个元素、limit 为 0 时是否合法）。

两种二分方向的模板区别：求"最小可行值"用 `if feasible(mid) high = mid else low = mid + 1`，mid 取下整；求"最大可行值"用 `if feasible(mid) low = mid else high = mid - 1`，**mid 必须上取整 `(low+high+1)//2`**，否则会死循环——这是二分答案最常踩的坑。

## 本课小结
二分答案 = **在答案空间上二分 + 可行性判定**。看到「最大化的最小值」「最小化的最大值」「至少/至多」这类问法，优先考虑它。

<!-- appendix:v1 -->

## 通用模板

```python
def binary_search_answer(low, high, feasible):
    """在 [low, high] 内寻找「最大可行值」。

    feasible(x) 必须满足单调性：x 可行则更小的 x 也可行（或反之）。
    """
    best = None
    while low <= high:
        mid = low + (high - low) // 2      # 防止整数溢出
        if feasible(mid):
            best = mid
            low = mid + 1                  # 求最大可行值：往右找
        else:
            high = mid - 1
    return best


def can_split(nums, max_sum, k):
    """把数组切成不超过 k 段，每段和不超过 max_sum。"""
    parts, current = 1, 0
    for value in nums:
        if value > max_sum:                # 单个元素就超限，直接不可行
            return False
        if current + value > max_sum:
            parts += 1
            current = value
            if parts > k:
                return False
        else:
            current += value
    return True


def split_array(nums, k):
    """分割数组使最大段和最小：二分答案的经典题。"""
    low, high = max(nums), sum(nums)
    while low < high:
        mid = low + (high - low) // 2
        if can_split(nums, mid, k):
            high = mid                     # 可行：尝试更小的答案
        else:
            low = mid + 1
    return low


def min_days(bloom_day, bouquets, flowers):
    """最少需要多少天才能摘够花束：答案在时间维度上二分。"""
    def feasible(day):
        count = streak = 0
        for d in bloom_day:
            streak = streak + 1 if d <= day else 0
            if streak == flowers:
                count += 1
                streak = 0
        return count >= bouquets

    if len(bloom_day) < bouquets * flowers:
        return -1
    low, high = min(bloom_day), max(bloom_day)
    while low < high:
        mid = low + (high - low) // 2
        if feasible(mid):
            high = mid
        else:
            low = mid + 1
    return low
```

## 适用题型速查

| 题型 | 二分的对象 | 判定函数 |
| --- | --- | --- |
| 分割数组使最大段和最小 | 段和上限 | 能否切出不超过 k 段 |
| 最少天数完成任务 | 天数 | 该天数内是否达标 |
| 运货能力 | 船的最低载重 | 能否在 D 天内运完 |
| 最小速度吃香蕉 | 速度 | 该速度能否按时吃完 |
| 最大化最小值（如牛栏分配） | 最小间距 | 该间距能否放下 k 个 |
| 最小化最大值（如任务分配） | 最大值上限 | 该上限能否完成任务 |
| 容量规划 | 容量 | 是否满足负载 |
| 求第 k 小（值域二分） | 数值 | 不大于该值的元素个数 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 判定函数不具单调性 | 二分结果错误 | 先证明可行性随答案单调 |
| 上下界设得太窄 | 错过正确答案 | 下界取最小可能值，上界取最大可能值 |
| 求最大可行值时用 `high = mid - 1` 且记录方式不一致 | 死循环或漏解 | 统一模板：可行记录并往右 |
| `mid` 用 `(low + high) // 2` 在极大数据溢出 | 整数溢出（C++/Java） | 写 `low + (high - low) // 2` |
| 判定函数写成 O(n²) | 总体超时 | 判定函数应尽量 O(n) 或 O(n log n) |
| 二分浮点用 `low <= high` | 死循环 | 固定迭代次数或设误差阈值 |
| 忘记单元素就超限的剪枝 | 返回错误结果 | 判定函数里先检查最大单元素 |
| 边界条件没覆盖 | 结果差一 | 测试答案等于上下界的情况 |
| 把可行判定写成「严格小于」 | 结果偏小或偏大 | 与题目条件严格对齐 |
| 没有小规模暴力对拍 | 逻辑错误难以发现 | 用暴力解验证前几百组随机数据 |

## 自测清单

- [ ] 能说出二分答案的两个前提：答案有界、可行性单调。
- [ ] 能独立写出判定函数并分析其复杂度。
- [ ] 区分「求最大可行值」与「求最小可行值」的收缩方向。
- [ ] `mid` 计算避免溢出。
- [ ] 用暴力解对小规模数据对拍验证。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「二分答案、可行性、最小化最大值」完成复述、实验和交付，每个结果都要能被别人检查。

先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「二分答案」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「可行性」是什么关系？

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
- 至少覆盖「二分答案」和「可行性」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Binary Search on Answer

**Summary:** Binary search the answer with a feasibility check.

**Category:** Algorithms  
**Level:** 进阶  
**Key terms:** 二分答案, 可行性, 最小化最大值, 贪心

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：任意主流语言（伪代码与复杂度为主）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：二分答案、可行性、最小化最大值、贪心
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

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

> 本课主题：在答案空间二分，用可行性函数逼近最优解。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

