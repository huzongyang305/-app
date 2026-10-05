# 动态规划入门

![动态规划入门](images/remaining_dynamic_programming.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：18 分钟

## 学习目标

- 能用自己的话解释「动态规划入门」解决了什么问题，而不是只背术语。
- 能说清 「动态规划」、「DP」、「背包」、「LIS」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「算法与数据结构」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：状态定义、转移方程、背包与最长递增子序列。

## 前置知识

- 先完成上一课《排序算法家族》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：动态规划、DP、背包。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 两个前提

- **最优子结构**：大问题的最优解由子问题的最优解构成。
- **重叠子问题**：不同分支会重复计算同一子问题。

若只有最优子结构而没有重叠子问题，那叫分治（如归并排序）。

## 两种写法

```python
# 记忆化搜索（自顶向下）：逻辑直观
from functools import lru_cache

@lru_cache(maxsize=None)
def fib(n):
    return n if n < 2 else fib(n - 1) + fib(n - 2)

# 递推（自底向上）：无递归开销
def fib_iter(n):
    if n < 2:
        return n
    prev, curr = 0, 1
    for _ in range(2, n + 1):
        prev, curr = curr, prev + curr
    return curr
```

## 解题四步

1. **定义状态**：`dp[i]` 表示什么？（最关键的一步）
2. **写转移方程**：`dp[i]` 从哪些更小的状态来？
3. **确定初始条件与边界**。
4. **确定遍历顺序**，必要时用滚动数组压缩空间。

## 经典一：0/1 背包

```python
def knapsack(weights, values, capacity):
    dp = [0] * (capacity + 1)
    for i in range(len(weights)):
        for c in range(capacity, weights[i] - 1, -1):   # 逆序：每个物品只用一次
            dp[c] = max(dp[c], dp[c - weights[i]] + values[i])
    return dp[capacity]
```

完全背包（物品可重复用）只需把内层改为正序遍历。

## 经典二：最长递增子序列（LIS）

```python
def lis_length(nums):
    if not nums:
        return 0
    dp = [1] * len(nums)                 # dp[i]：以 nums[i] 结尾的最长长度
    for i in range(len(nums)):
        for j in range(i):
            if nums[j] < nums[i]:
                dp[i] = max(dp[i], dp[j] + 1)
    return max(dp)
```

复杂度 `O(n²)`；用「贪心 + 二分」可以降到 `O(n log n)`。

## 常见题型地图

| 类型 | 例子 |
| --- | --- |
| 序列型 | LIS、最大子数组和 |
| 区间型 | 最长回文子串、石子合并 |
| 背包型 | 0/1 背包、完全背包、零钱兑换 |
| 路径型 | 不同路径、最小路径和 |
| 状态压缩 | 旅行商问题、棋盘覆盖 |

## 常见误区

1. 状态定义含糊，导致转移方程写不出来——先想清楚 dp 的含义。
2. 忘记边界，数组越界或结果偏小。
3. 空间开得过大，可用滚动数组降维。
4. 能用贪心解决的题硬套 DP（如区间调度）。

## 四类经典问题的状态定义

| 问题 | 状态定义 | 转移方程 | 答案位置 |
| --- | --- | --- | --- |
| 爬楼梯 | f[i] = 到第 i 阶的方法数 | f[i] = f[i-1] + f[i-2] | f[n] |
| 0/1 背包 | f[j] = 容量 j 内的最大价值 | f[j] = max(f[j], f[j-w]+v)（j 逆序） | f[容量] |
| 最长递增子序列 | f[i] = 以 i 结尾的最长长度 | f[i] = max(f[j]+1) 且 a[j]<a[i] | max(f) |
| 编辑距离 | f[i][j] = 前 i 与前 j 个字符的最小操作数 | 相同取 f[i-1][j-1]；否则 1+min(删/插/改) | f[n][m] |

写转移方程的检查清单：**状态含义能否一句话说清**、**每个状态是否只依赖更小的状态**、**边界是否覆盖空串/零容量**、**遍历顺序是否让依赖先算出来**（背包逆序、区间 DP 按长度递增）。

## 从记忆化到递推的改写步骤

1. 先写暴力递归，确认状态参数与终止条件。
2. 加缓存（记忆化），得到自顶向下版本，此时正确性已验证。
3. 把递归改成按依赖顺序填表（自底向上）。
4. 观察是否只依赖前几行/前几个状态，用滚动数组压缩空间（0/1 背包从二维压到一维）。

调试技巧：把 dp 表打印出来与小规模暴力枚举的结果逐项对比，能在几分钟内定位转移方程错误。

## 本课小结
动态规划 = **定义状态 + 状态转移 + 边界 + 顺序**。先写出记忆化版本验证正确性，再改写为递推与空间优化。

<!-- appendix:v1 -->

## 常见 DP 模型速查

| 模型 | 状态定义 | 转移要点 | 复杂度 |
| --- | --- | --- | --- |
| 爬楼梯 | `dp[i]` 到第 i 阶的方案数 | `dp[i] = dp[i-1] + dp[i-2]` | O(n) |
| 0/1 背包 | `dp[j]` 容量 j 的最大价值 | 容量逆序遍历 | O(nW) |
| 完全背包 | 同上 | 容量正序遍历 | O(nW) |
| 最长递增子序列 | `dp[i]` 以 i 结尾的 LIS 长度 | 枚举前驱，或配合二分 | O(n²) / O(n log n) |
| 最长公共子序列 | `dp[i][j]` 前 i、前 j 的 LCS | 相同则左上 +1，否则取上/左最大 | O(nm) |
| 编辑距离 | `dp[i][j]` 最少操作数 | 增、删、改三种取最小 | O(nm) |
| 区间 DP | `dp[i][j]` 区间最优值 | 按长度从小到大枚举 | O(n³) 常见 |
| 状态压缩 | 用位表示集合 | 枚举子集与合法转移 | 视状态数而定 |
| 树形 DP | 以节点为根的子树最优 | 后序遍历合并子节点 | O(n) |

```python
# 0/1 背包：一维数组 + 容量逆序
def knapsack(weights, values, capacity):
    dp = [0] * (capacity + 1)
    for w, v in zip(weights, values):
        for j in range(capacity, w - 1, -1):   # 逆序：保证每件物品只用一次
            dp[j] = max(dp[j], dp[j - w] + v)
    return dp[capacity]


# 最长递增子序列：贪心 + 二分，O(n log n)
from bisect import bisect_left

def lis(nums):
    tails = []
    for x in nums:
        pos = bisect_left(tails, x)
        if pos == len(tails):
            tails.append(x)
        else:
            tails[pos] = x
    return len(tails)
```

## 解题四步速查

| 步骤 | 要回答的问题 |
| --- | --- |
| 1. 定义状态 | `dp[i]` / `dp[i][j]` 到底表示什么？边界怎么取？ |
| 2. 写转移方程 | 当前状态由哪些更小的状态得来？ |
| 3. 确定遍历顺序 | 谁先算？为什么这样能保证依赖已就绪？ |
| 4. 处理边界与答案 | 初始值是什么？最终答案是 `dp[n]` 还是所有状态的最值？ |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 0/1 背包容量正序遍历 | 同一物品被重复使用，结果偏大 | 0/1 背包必须逆序，完全背包才用正序 |
| `dp` 数组初始化为 0 求「恰好装满」 | 得到非法解 | 恰好装满时用 `-inf` 表示不可达，`dp[0] = 0` |
| 状态定义含糊 | 转移写不出来或答案错误 | 先把 `dp` 的含义写成一句话 |
| 忘记处理边界 | 下标越界或首行首列错误 | 多开一行一列并初始化 |
| 只写记忆化但 key 不全 | 结果错乱 | 缓存键必须覆盖所有影响结果的参数 |
| 递归深度过大 | `RecursionError` | 改自底向上递推 |
| 状态数估算错误 | 内存超限 | 用滚动数组压缩空间，或减少维度 |
| 把「子序列」当「子数组」 | 答案偏小 | 子序列可不连续，子数组必须连续 |
| 区间 DP 按 i 从小到大枚举 | 依赖未就绪 | 按区间长度从小到大枚举 |
| 用 DP 解贪心可解的问题 | 复杂度不必要地高 | 先验证贪心是否成立，再决定是否 DP |

## 自测清单

- [ ] 能写出解题四步：状态、转移、顺序、边界。
- [ ] 记得 0/1 背包逆序、完全背包正序。
- [ ] 会用滚动数组把二维 DP 压成一维。
- [ ] 知道 LIS 有 O(n log n) 解法。
- [ ] 遇到「恰好」与「至多」时能正确设置初始值。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「动态规划、DP、背包」完成复述、实验和交付，每个结果都要能被别人检查。

先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「动态规划入门」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「DP」是什么关系？

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
- 至少覆盖「动态规划」和「DP」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Dynamic Programming

**Summary:** States, transitions, knapsack and LIS.

**Category:** Algorithms  
**Level:** 高级  
**Key terms:** 动态规划, DP, 背包, LIS, 记忆化

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：任意主流语言（伪代码与复杂度为主）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：动态规划、DP、背包、LIS、记忆化
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：动态规划入门

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| 两个前提 | 最优子结构：大问题的最优解由子问题的最优解构成。 | 复述要点 + 举一个反例 |
| 两种写法 | # 记忆化搜索（自顶向下）：逻辑直观 from functools import lrucache | 运行示例 + 换一个边界输入 |
| 解题四步 | 定义状态：dp[i] 表示什么？ | 复述要点 + 举一个反例 |
| 经典一：0/1 背包 | def knapsack(weights, values, capacity): dp = [0] (capacity + 1) for i in range(len(weig… | 运行示例 + 换一个边界输入 |
| 经典二：最长递增子序列（LIS） | def lislength(nums): if not nums: return 0 dp = [1] len(nums) # dp[i]：以 nums[i] 结尾的最长长度 … | 运行示例 + 换一个边界输入 |
| 常见题型地图 | 类型：序列型；例子：LIS、最大子数组和 | 复述要点 + 举一个反例 |

### 二、机制与验证

1. **两个前提**：最优子结构：大问题的最优解由子问题的最优解构成。 验证方式：先复述要点，再举一个反例说明边界。
2. **两种写法**：# 记忆化搜索（自顶向下）：逻辑直观 from functools import lrucache 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
3. **解题四步**：定义状态：dp[i] 表示什么？ 验证方式：先复述要点，再举一个反例说明边界。
4. **经典一：0/1 背包**：def knapsack(weights, values, capacity): dp = [0] (capacity + 1) for i in range(len(weig… 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
5. **经典二：最长递增子序列（LIS）**：def lislength(nums): if not nums: return 0 dp = [1] len(nums) # dp[i]：以 nums[i] 结尾的最长长度 … 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
6. **常见题型地图**：类型：序列型；例子：LIS、最大子数组和 验证方式：先复述要点，再举一个反例说明边界。

### 三、专属检查问题

1. 「两个前提」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「两种写法」的输入和输出分别是什么？
3. 「解题四步」最常见的失败方式是什么？如何定位？
4. 「经典一：0/1 背包」的适用边界在哪里？什么情况下不该使用？
5. 「经典二：最长递增子序列（LIS）」和相邻主题相比，最关键的差别是什么？
6. 「常见题型地图」如何验证自己真的掌握了？写出一个可执行的检查步骤。

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：两个前提的核心要点是什么？**

答：最优子结构：大问题的最优解由子问题的最优解构成。

**问：两种写法的核心要点是什么？**

答：# 记忆化搜索（自顶向下）：逻辑直观 from functools import lrucache

**问：解题四步的核心要点是什么？**

答：定义状态：dp[i] 表示什么？

**问：经典一：0/1 背包的核心要点是什么？**

答：def knapsack(weights, values, capacity): dp = [0] (capacity + 1) for i in range(len(weig…

**问：经典二：最长递增子序列（LIS）的核心要点是什么？**

答：def lislength(nums): if not nums: return 0 dp = [1] len(nums) # dp[i]：以 nums[i] 结尾的最长长度 …

**问：常见题型地图的核心要点是什么？**

答：类型：序列型；例子：LIS、最大子数组和

## 逐步练习：动态规划入门

### 练习 1：两个前提

1. 不看原文，用自己的话复述：最优子结构：大问题的最优解由子问题的最优解构成。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：两种写法

1. 不看原文，用自己的话复述：# 记忆化搜索（自顶向下）：逻辑直观 from functools import lrucache
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：解题四步

1. 不看原文，用自己的话复述：定义状态：dp[i] 表示什么？
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 4：经典一：0/1 背包

1. 不看原文，用自己的话复述：def knapsack(weights, values, capacity): dp = [0] (capacity + 1) for i in range(len(weig…
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 5：经典二：最长递增子序列（LIS）

1. 不看原文，用自己的话复述：def lislength(nums): if not nums: return 0 dp = [1] len(nums) # dp[i]：以 nums[i] 结尾的最长长度 …
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 6：常见题型地图

1. 不看原文，用自己的话复述：类型：序列型；例子：LIS、最大子数组和
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：动态规划入门

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「两个前提」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「两种写法」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「解题四步」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「经典一：0/1 背包」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「经典二：最长递增子序列（LIS）」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「常见题型地图」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：动态规划入门

1. 「两个前提」的输入和输出分别是什么？
2. 「两种写法」最常见的失败方式是什么？如何定位？
3. 「解题四步」的适用边界在哪里？什么情况下不该使用？
4. 「经典一：0/1 背包」和相邻主题相比，最关键的差别是什么？
5. 「经典二：最长递增子序列（LIS）」如何验证自己真的掌握了？写出一个可执行的检查步骤。
6. 「常见题型地图」要解决什么问题？请用一句话说明，并给出一个具体例子。

## 专属进阶任务 5：动态规划入门

把本课 6 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

### 验收标准

- 例子可以独立运行，输出与预期一致。
- 两条边界用例都说清了输入、预期与实际结果。
- 验证结论用一句话写清，不依赖“感觉正确”。

<!-- full-english-guide:v1 -->
## Full English Study Guide

### Overview

**Dynamic Programming** focuses on States, transitions, knapsack and LIS.

### Learning Outcomes

- Explain what **Dynamic Programming** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Dynamic Programming**
- Related terms: 动态规划, DP, 背包, LIS
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 两个前提 | 两个前提 |
| 两种写法 | 两种写法 |
| 解题四步 | 解题四步 |
| 经典一：0/1 背包 | 经典一：0/1 背包 |
| 经典二：最长递增子序列（LIS） | 经典二：最长递增子序列（LIS） |
| 常见题型地图 | 常见题型地图 |
| 常见误区 | 常见误区 |
| 四类经典问题的状态定义 | 四类经典问题的状态定义 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。

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

> 本课主题：状态定义、转移方程、背包与最长递增子序列。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

