## 回溯模板

```text
def backtrack(state, choices, result):
    if 到达终止条件(state):
        result.append(state[:])      # 必须拷贝，否则后续修改会影响已收集结果
        return
    for choice in choices:
        if not 合法(choice):         # 剪枝
            continue
        做选择(choice)
        backtrack(state, 下一步选择, result)
        撤销选择(choice)             # 关键：恢复现场
```

```python
def subsets(nums):
    """子集：每个元素选或不选，共 2 的 n 次方个结果。"""
    result, path = [], []

    def dfs(start):
        result.append(path[:])
        for i in range(start, len(nums)):
            path.append(nums[i])
            dfs(i + 1)
            path.pop()

    dfs(0)
    return result


def permutations(nums):
    """全排列：用 used 数组避免重复使用同一位置。"""
    result, path = [], []
    used = [False] * len(nums)

    def dfs():
        if len(path) == len(nums):
            result.append(path[:])
            return
        for i, value in enumerate(nums):
            if used[i]:
                continue
            used[i] = True
            path.append(value)
            dfs()
            path.pop()
            used[i] = False

    dfs()
    return result


def combination_sum(nums, target):
    """可重复选取的组合之和：排序后剪枝，同层去重。"""
    nums.sort()
    result, path = [], []

    def dfs(start, remain):
        if remain == 0:
            result.append(path[:])
            return
        for i in range(start, len(nums)):
            if nums[i] > remain:                 # 剪枝：后面的更大
                break
            if i > start and nums[i] == nums[i - 1]:
                continue                         # 同层去重
            path.append(nums[i])
            dfs(i, remain - nums[i])
            path.pop()

    dfs(0, target)
    return result
```

## 剪枝手段速查

| 手段 | 说明 |
| --- | --- |
| 排序后提前终止 | 当前值超出限制即 `break` |
| 同层去重 | `i > start and nums[i] == nums[i-1]` 跳过 |
| 可行性上界 | 剩余元素全用上也不够，直接剪掉 |
| 下界剪枝 | 已经凑够目标，立即收集并返回 |
| 使用标记数组 | 避免同一位置被重复选 |
| 记忆化 | 相同子问题只算一次（此时更接近 DP） |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 收集结果时直接 `result.append(path)` | 所有结果都变成最后一次的内容 | 必须 `path[:]` 拷贝 |
| 忘记撤销选择 | 状态污染，结果错乱 | 递归返回后立刻恢复现场 |
| 去重条件漏掉 `i > start` | 合法解被误删 | 加同层限制 |
| 不做剪枝 | 大数据超时 | 排序加越界 `break` |
| 排列问题不用 `used` | 元素被重复使用 | 用标记数组或交换法 |
| 递归终止条件写错 | 死循环或漏解 | 明确「解的长度」或「剩余目标」 |
| 状态对象被多分支共享 | 分支互相影响 | 每分支独立拷贝或成对做与撤销 |
| 用回溯解本可 DP 的问题 | 指数级超时 | 先判断是否可用 DP |
| 忽略重复元素 | 产生重复解 | 先去重或同层跳过 |
| 递归深度过大 | 栈溢出 | 限制深度或改迭代 |

## 自测清单

- [ ] 能默写「选择、递归、撤销」的回溯模板。
- [ ] 收集结果时一定做深拷贝。
- [ ] 会用 `i > start` 去重避免重复解。
- [ ] 排序后用 `break` 做剪枝。
- [ ] 能判断问题该用回溯还是 DP。
