## 前缀和与差分模板

```python
from collections import defaultdict

def build_prefix(nums):
    """一维前缀和：prefix[i] 表示前 i 个元素之和。"""
    prefix = [0] * (len(nums) + 1)
    for i, value in enumerate(nums):
        prefix[i + 1] = prefix[i] + value
    return prefix


def range_sum(prefix, left, right):
    """闭区间 [left, right] 的和，O(1)。"""
    return prefix[right + 1] - prefix[left]


def build_2d_prefix(matrix):
    """二维前缀和：多开一行一列，避免边界判断。"""
    rows, cols = len(matrix), len(matrix[0])
    prefix = [[0] * (cols + 1) for _ in range(rows + 1)]
    for i in range(rows):
        for j in range(cols):
            prefix[i + 1][j + 1] = (
                matrix[i][j]
                + prefix[i][j + 1]
                + prefix[i + 1][j]
                - prefix[i][j]
            )
    return prefix


def sum_region(prefix, r1, c1, r2, c2):
    """子矩阵和（含端点），容斥原理 O(1)。"""
    return (
        prefix[r2 + 1][c2 + 1]
        - prefix[r1][c2 + 1]
        - prefix[r2 + 1][c1]
        + prefix[r1][c1]
    )


def range_add_diff(nums, updates):
    """多次区间加、最后统一求值：差分数组 O(n + q)。"""
    diff = [0] * (len(nums) + 1)
    for left, right, value in updates:
        diff[left] += value
        diff[right + 1] -= value          # 右边界之后要抵消
    result, running = [], 0
    for i, base in enumerate(nums):
        running += diff[i]
        result.append(base + running)
    return result


def subarray_sum_k(nums, k):
    """统计和为 k 的连续子数组个数：前缀和 + 哈希表，O(n)。"""
    seen = defaultdict(int)
    seen[0] = 1                            # 空前缀，处理从头开始的区间
    total = count = 0
    for value in nums:
        total += value
        count += seen[total - k]           # 之前出现过 total - k 的前缀
        seen[total] += 1
    return count
```

## 适用场景速查

| 问题 | 工具 | 复杂度 |
| --- | --- | --- |
| 多次区间求和（数组不变） | 前缀和 | 预处理 O(n)，查询 O(1) |
| 多次区间加、最后读取 | 差分 | 每次 O(1)，最后 O(n) |
| 子矩阵求和 | 二维前缀和 | 预处理 O(mn)，查询 O(1) |
| 和为 k 的连续子数组个数 | 前缀和 + 哈希表 | O(n) |
| 区间加与区间求和混合 | 树状数组 / 线段树 | O(log n) |
| 前缀和与差分互为逆运算 | 可互相还原 | 注意下标偏移 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 前缀和数组不预留第 0 位 | 边界判断复杂、易越界 | 多开一位且 `prefix[0] = 0` |
| 区间和写成 `prefix[r] - prefix[l]` | 结果少算一个元素 | 应为 `prefix[r+1] - prefix[l]` |
| 二维前缀和忘记加回左上角 | 子矩阵和多减了一块 | 容斥：加回 `prefix[r1][c1]` |
| 差分右边界写成 `diff[right] -= v` | 影响范围多一格 | 应为 `diff[right + 1] -= v` |
| 差分数组不预留一位 | 最后一段越界 | 开 n+1 长度 |
| 哈希表忘记 `seen[0] = 1` | 从头开始的区间被漏掉 | 初始化空前缀计数为 1 |
| 用前缀和求最大子数组和 | 不适用（含负数时结论错） | 用 Kadane 算法 |
| 用滑动窗口处理负数数组 | 结果错误 | 用前缀和加哈希表 |
| 前缀和数组越界访问 | 越界异常 | 明确长度是 n+1 |
| 用浮点累积前缀和 | 误差逐渐放大 | 用整数或分段求和 |

## 自测清单

- [ ] 能写出预留第 0 位的一维前缀和。
- [ ] 区间和公式为 `prefix[r+1] - prefix[l]`。
- [ ] 二维子矩阵和用容斥且下标加 1。
- [ ] 差分修改右边界用 `right + 1` 抵消。
- [ ] 统计和为 k 的子数组时初始化 `seen[0] = 1`。
