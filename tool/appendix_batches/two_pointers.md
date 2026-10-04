## 三类双指针速查

| 类型 | 移动方式 | 适用问题 | 前提 |
| --- | --- | --- | --- |
| 相向双指针 | 左右向中间靠拢 | 有序数组两数之和、回文判断、盛水容器 | 单调性（通常已排序） |
| 同向双指针 | 一快一慢 | 原地去重、删除元素、链表找中点 | 只需一次扫描 |
| 滑动窗口 | 右扩左缩 | 最长或最短子串、满足条件的连续区间 | 窗口性质随扩张收缩单调 |

```python
def two_sum_sorted(nums, target):
    """有序数组两数之和：相向双指针 O(n)。"""
    left, right = 0, len(nums) - 1
    while left < right:
        total = nums[left] + nums[right]
        if total == target:
            return [left, right]
        if total < target:
            left += 1          # 和太小，左指针右移
        else:
            right -= 1         # 和太大，右指针左移
    return []


def longest_unique_substring(text: str) -> int:
    """最长无重复字符子串：滑动窗口 + 哈希表记录位置。"""
    last_seen = {}
    left = best = 0
    for right, ch in enumerate(text):
        if ch in last_seen and last_seen[ch] >= left:
            left = last_seen[ch] + 1     # 收缩到重复字符之后
        last_seen[ch] = right
        best = max(best, right - left + 1)
    return best


def min_window(nums, target):
    """和大于等于 target 的最短连续子数组长度（均为正数）。"""
    left = total = 0
    best = float("inf")
    for right, value in enumerate(nums):
        total += value
        while total >= target:           # 满足条件就尝试收缩
            best = min(best, right - left + 1)
            total -= nums[left]
            left += 1
    return 0 if best == float("inf") else best
```

## 滑动窗口模板

```text
left = 0
for right in range(n):
    把 nums[right] 加入窗口
    while 窗口不满足条件:
        把 nums[left] 移出窗口
        left += 1
    此时窗口是「以 right 结尾的最优窗口」，更新答案
```

判断能否用滑动窗口：窗口扩大或缩小时，条件是否**单调变化**。含有负数的「和为 k 的子数组」不满足单调性，应改用前缀和加哈希表。

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 对无序数组用相向双指针 | 结果错误 | 先排序，或用哈希表 |
| 收缩用 `if` 而非 `while` | 窗口未完全收缩，答案偏大 | 需要连续收缩时用 `while` |
| 窗口左边界回退 | 复杂度退化为 O(n²) | 左右指针只能单向移动 |
| 记录位置时忘记判断 `>= left` | 左边界被旧位置拉回 | 条件加 `last_seen[ch] >= left` |
| 更新答案时机不对 | 得到次优解 | 明确是扩张后还是收缩后更新 |
| 对含负数的数组用滑窗 | 结果错误 | 用前缀和加哈希表 |
| 忘记处理空数组 | 越界 | 循环前判空 |
| 原地删除却不写回 | 数组未改变 | 用 `slow` 写回并返回新长度 |
| 慢指针移动条件写反 | 保留了不该保留的元素 | 明确保留条件 |
| 回文判断忽略非字母数字 | 判定错误 | 先过滤或跳过非目标字符 |

## 自测清单

- [ ] 能按问题类型选对三种双指针之一。
- [ ] 会写「右扩左缩」的滑动窗口模板。
- [ ] 知道滑动窗口要求条件单调。
- [ ] 明确在哪个时机更新答案。
- [ ] 会用快慢指针原地删除元素并返回新长度。
