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
