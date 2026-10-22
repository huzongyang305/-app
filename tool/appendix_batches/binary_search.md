## 三种模板速查

| 目标 | 模板要点 | 返回值 |
| --- | --- | --- |
| 找任意一个等于 target 的下标 | `while (lo <= hi)`，相等即返回 | 下标或 -1 |
| 找第一个 >= target 的位置 | `while (lo < hi)`，`hi = mid` | 插入位置（`lower_bound`） |
| 找最后一个 <= target 的位置 | `while (lo < hi)`，`lo = mid` 需上取整 | 下标或 -1 |

```python
def lower_bound(nums, target):
    """返回第一个 >= target 的下标；不存在时返回 len(nums)。"""
    lo, hi = 0, len(nums)          # 左闭右开区间
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] < target:
            lo = mid + 1
        else:
            hi = mid
    return lo


def upper_bound(nums, target):
    """返回第一个 > target 的下标。"""
    lo, hi = 0, len(nums)
    while lo < hi:
        mid = (lo + hi) // 2
        if nums[mid] <= target:
            lo = mid + 1
        else:
            hi = mid
    return lo


# 统计 target 出现次数：两个边界相减即可
count = upper_bound(nums, target) - lower_bound(nums, target)
```

## 边界与复杂度速查

| 项目 | 说明 |
| --- | --- |
| 时间复杂度 | O(log n)，10 亿数据最多比较约 30 次 |
| 空间复杂度 | 迭代写法 O(1)，递归写法 O(log n) |
| 前置条件 | 数据有序（或满足单调性） |
| `mid` 写法 | `lo + (hi - lo) // 2` 避免整数溢出（Java / C++ 尤其重要） |
| 区间风格 | 左闭右开 `[lo, hi)` 最不易出错，统一到底 |
| 循环条件 | 用 `lo < hi` 时循环结束即 `lo == hi`，直接返回 |
| 死循环排查 | 出现 `lo = mid` 时必须改用上取整 `mid = (lo + hi + 1) // 2` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `while lo <= hi` 里写 `hi = mid` | 死循环 | 闭区间与半开区间的收缩方式必须配套 |
| `lo = mid` 而不上取整 | 死循环（lo 与 hi 相邻时 mid 恒等于 lo） | 改成 `mid = (lo + hi + 1) // 2` |
| `hi = len(nums)` 却写 `nums[hi]` | `IndexError` | 右开区间不能取 `nums[hi]` |
| 循环里 `lo = mid - 1` 配 `lo < hi` | 漏掉候选解 | 明确用闭区间 `<=` 模板 |
| 有重复元素时用「找到即返回」 | 返回的不是第一个/最后一个 | 用 `lower_bound` / `upper_bound` |
| 对无序数据二分 | 结果随机 | 先排序，或确认题目具备单调性 |
| 对浮点数用 `lo <= hi` | 精度问题、死循环 | 固定循环次数（如 100 次）或设误差阈值 |
| 二分答案时 check 不单调 | 结果不正确 | 先证明可行性随答案单调，再二分 |
| 用递归但没考虑栈深 | 极大规模下递归过深 | 数据量大时改迭代 |

## 自测清单

- [ ] 能默写 `lower_bound` 与 `upper_bound`。
- [ ] 知道什么时候必须用上取整避免死循环。
- [ ] 记得 `mid = lo + (hi - lo) // 2` 的作用。
- [ ] 遇到「找边界」问题优先想到二分边界而不是线性扫描。
- [ ] 能说明二分答案的适用前提是单调性。
