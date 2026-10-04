## 树状数组模板

```python
class Fenwick:
    """单点修改 + 区间求和，代码短、常数小。"""

    def __init__(self, n: int):
        self.n = n
        self.tree = [0] * (n + 1)

    def add(self, index: int, delta: int) -> None:
        i = index + 1                     # 内部下标从 1 开始
        while i <= self.n:
            self.tree[i] += delta
            i += i & -i                   # lowbit：跳到下一个管辖区间

    def prefix_sum(self, index: int) -> int:
        """前 index 个元素之和（下标 0..index-1）。"""
        total, i = 0, index
        while i > 0:
            total += self.tree[i]
            i -= i & -i
        return total

    def range_sum(self, left: int, right: int) -> int:
        """闭区间 [left, right] 的和。"""
        return self.prefix_sum(right + 1) - self.prefix_sum(left)
```

## 线段树模板（含懒标记）

```python
class SegmentTree:
    """区间加 + 区间求和：懒标记把修改延迟到必要时下推。"""

    def __init__(self, nums):
        self.n = len(nums)
        self.tree = [0] * (4 * self.n)
        self.lazy = [0] * (4 * self.n)
        if self.n:
            self._build(1, 0, self.n - 1, nums)

    def _build(self, node, left, right, nums):
        if left == right:
            self.tree[node] = nums[left]
            return
        mid = (left + right) // 2
        self._build(node * 2, left, mid, nums)
        self._build(node * 2 + 1, mid + 1, right, nums)
        self.tree[node] = self.tree[node * 2] + self.tree[node * 2 + 1]

    def _apply(self, node, left, right, value):
        self.tree[node] += value * (right - left + 1)
        self.lazy[node] += value

    def _push(self, node, left, right):
        if self.lazy[node] == 0 or left == right:
            return
        mid = (left + right) // 2
        value = self.lazy[node]
        self._apply(node * 2, left, mid, value)
        self._apply(node * 2 + 1, mid + 1, right, value)
        self.lazy[node] = 0

    def update(self, ql, qr, value, node=1, left=0, right=None):
        right = self.n - 1 if right is None else right
        if qr < left or right < ql:
            return
        if ql <= left and right <= qr:
            self._apply(node, left, right, value)
            return
        self._push(node, left, right)
        mid = (left + right) // 2
        self.update(ql, qr, value, node * 2, left, mid)
        self.update(ql, qr, value, node * 2 + 1, mid + 1, right)
        self.tree[node] = self.tree[node * 2] + self.tree[node * 2 + 1]

    def query(self, ql, qr, node=1, left=0, right=None):
        right = self.n - 1 if right is None else right
        if qr < left or right < ql:
            return 0
        if ql <= left and right <= qr:
            return self.tree[node]
        self._push(node, left, right)
        mid = (left + right) // 2
        return (
            self.query(ql, qr, node * 2, left, mid)
            + self.query(ql, qr, node * 2 + 1, mid + 1, right)
        )
```

## 选型速查

| 需求 | 结构 | 复杂度 |
| --- | --- | --- |
| 单点改 + 区间和 | 树状数组 | O(log n) |
| 单点改 + 区间最值 | 树状数组（不可逆运算需变体）或线段树 | O(log n) |
| 区间改 + 区间和 | 线段树 + 懒标记 | O(log n) |
| 区间改 + 区间最值 | 线段树 + 懒标记 | O(log n) |
| 可持久化历史版本 | 可持久化线段树 | O(log n) |
| 二维区间查询 | 二维树状数组 / 线段树 | O(log² n) |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 树状数组下标从 0 开始 | 死循环（`i += 0`） | 内部统一用 1 起始下标 |
| lowbit 写成 `i & i - 1` | 结果错误 | 是 `i & -i` |
| 线段树数组只开 n | 越界 | 递归版开 4n |
| 懒标记忘记下推 | 查询结果过旧 | 访问子区间前先 `push` |
| 下推后不清零标记 | 重复累加 | 下推后把 `lazy[node] = 0` |
| 区间改时长度算错 | 求和结果偏大或偏小 | 乘以 `right - left + 1` |
| 区间边界不判断相交 | 死循环或错误结果 | 先判无交集直接返回 |
| 用线段树解决树状数组能解决的问题 | 代码冗余易错 | 只做单点改与区间和时用树状数组 |
| 更新后忘记回溯更新父节点 | 上层数据陈旧 | 递归返回时重新合并 |
| 忘记处理空数组 | 初始化越界 | 长度为 0 时跳过建树 |

## 自测清单

- [ ] 能默写树状数组的 add 与 prefix_sum。
- [ ] 记得 lowbit 是 `i & -i`，内部下标从 1 开始。
- [ ] 线段树用 4n 开数组并维护懒标记。
- [ ] 能按需求在树状数组与线段树之间选择。
- [ ] 测试覆盖单点、区间、边界与全区间操作。
