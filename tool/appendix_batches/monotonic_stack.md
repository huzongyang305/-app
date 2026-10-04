## 模板

```python
from collections import deque

def next_greater(nums):
    """下一个更大元素的下标；不存在记 -1。"""
    result = [-1] * len(nums)
    stack = []                       # 存下标，对应值单调递减
    for i, value in enumerate(nums):
        while stack and nums[stack[-1]] < value:
            result[stack.pop()] = i
        stack.append(i)
    return result


def largest_rectangle(heights):
    """柱状图中最大矩形：单调递增栈，两端补 0 作哨兵。"""
    stack, best = [], 0
    for i, h in enumerate(list(heights) + [0]):
        while stack and heights[stack[-1]] > h:
            height = heights[stack.pop()]
            width = i if not stack else i - stack[-1] - 1
            best = max(best, height * width)
        stack.append(i)
    return best


def sliding_window_max(nums, k):
    """滑动窗口最大值：单调递减队列，队首即最大值。"""
    queue = deque()                  # 存下标
    result = []
    for i, value in enumerate(nums):
        while queue and nums[queue[-1]] <= value:
            queue.pop()              # 比新元素小的都不可能是最大值
        queue.append(i)
        if queue[0] <= i - k:        # 队首已滑出窗口
            queue.popleft()
        if i >= k - 1:
            result.append(nums[queue[0]])
    return result
```

## 题型速查

| 题目类型 | 结构 | 单调方向 |
| --- | --- | --- |
| 下一个更大元素 | 栈 | 递减（栈顶最小） |
| 下一个更小元素 | 栈 | 递增 |
| 每日温度 | 栈 | 递减 |
| 柱状图最大矩形 | 栈 | 递增 |
| 接雨水 | 栈 / 双指针 | 递增 |
| 滑动窗口最大值 | 队列 | 递减 |
| 滑动窗口最小值 | 队列 | 递增 |
| 去除重复字母（字典序最小） | 栈 + 计数 | 递增 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 栈里存值而不存下标 | 无法计算宽度或距离 | 存下标，用时再取值 |
| 比较符号写反 | 得到「更小」而不是「更大」 | 明确单调方向并按题型验证 |
| 弹出条件用 `<=` 还是 `<` 混淆 | 相等元素的处理不同 | 按题意决定是否保留相等元素 |
| 忘记处理栈中剩余元素 | 结果缺少尾部答案 | 遍历结束后清栈或加哨兵 |
| 单调队列忘记移除过期下标 | 结果取到窗口外的值 | 检查 `queue[0] <= i - k` |
| 用双重循环求下一个更大 | O(n²) 超时 | 改成单调栈 O(n) |
| 认为单调栈需要排序 | 多此一举 | 单调性由栈维护，输入无需有序 |
| 复杂度过高 | 误以为每个元素多次入栈 | 每个元素最多入栈出栈各一次，均摊 O(n) |
| 柱状图宽度算错 | 结果偏差 | 宽度为 `i - stack[-1] - 1`，栈空时为 `i` |
| 忘加哨兵 | 边界判断复杂、易错 | 首尾补 0 简化逻辑 |

## 自测清单

- [ ] 会用单调栈求下一个更大元素。
- [ ] 会用单调队列求滑动窗口最大值。
- [ ] 能说明单调栈均摊 O(n) 的原因。
- [ ] 记得栈内存下标而不是值。
- [ ] 会用哨兵简化边界处理。
