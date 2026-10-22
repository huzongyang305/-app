## 遍历速查

| 遍历 | 顺序 | 典型用途 | 实现方式 |
| --- | --- | --- | --- |
| 前序 | 根 → 左 → 右 | 复制树、序列化 | 递归 / 栈 |
| 中序 | 左 → 根 → 右 | BST 得到升序序列 | 递归 / 栈 |
| 后序 | 左 → 右 → 根 | 释放树、计算子树聚合 | 递归 / 栈 |
| 层序 | 逐层从左到右 | 求深度、按层处理 | 队列 |

```python
from collections import deque

class TreeNode:
    __slots__ = ("value", "left", "right")

    def __init__(self, value, left=None, right=None):
        self.value, self.left, self.right = value, left, right


def inorder(root):
    """迭代版中序遍历：BST 上得到升序序列。"""
    result, stack = [], []
    cur = root
    while cur or stack:
        while cur:              # 一路向左压栈
            stack.append(cur)
            cur = cur.left
        cur = stack.pop()
        result.append(cur.value)
        cur = cur.right
    return result


def level_order(root):
    """层序遍历，按层返回列表。"""
    if not root:
        return []
    levels, queue = [], deque([root])
    while queue:
        level = []
        for _ in range(len(queue)):     # 固定当前层长度
            node = queue.popleft()
            level.append(node.value)
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        levels.append(level)
    return levels


def insert(root, value):
    """BST 插入：小于走左、大于走右，重复值不插入。"""
    if root is None:
        return TreeNode(value)
    if value < root.value:
        root.left = insert(root.left, value)
    elif value > root.value:
        root.right = insert(root.right, value)
    return root
```

## BST 操作与平衡

| 操作 | 平均 | 最坏（退化成链） |
| --- | --- | --- |
| 查找 | O(log n) | O(n) |
| 插入 | O(log n) | O(n) |
| 删除 | O(log n) | O(n) |
| 中序遍历 | O(n) | O(n) |

| 平衡结构 | 平衡条件 | 特点 |
| --- | --- | --- |
| AVL 树 | 左右子树高度差 ≤ 1 | 查询更快，旋转更频繁 |
| 红黑树 | 颜色性质约束黑高 | 插入删除旋转少，工程常用 |
| B+ 树 | 多路平衡 | 磁盘索引，扇出大、树矮 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 有序数据依次插入 BST | 退化成链表，O(n) | 使用平衡树或先打乱插入 |
| 层序遍历不固定层长度 | 无法区分层级 | `for _ in range(len(queue))` |
| 删除双子节点直接删除 | 树结构被破坏 | 用中序后继或前驱替换后再删 |
| 递归遍历没有终止条件 | 无限递归 | 以 `if not node: return` 开头 |
| 递归深度过大 | 栈溢出 | 树很深时改迭代或增大栈 |
| 认为 BST 一定平衡 | 最坏性能退化 | 明确是「平均」还是「保证」 |
| 用 `<=` 插入重复值 | 重复元素堆在同一侧 | 明确重复值策略（计数、丢弃、右子树） |
| 释放树用前序 | 访问已释放节点 | 用后序或迭代 |
| 遍历时修改树结构 | 行为不确定 | 先收集结果再修改 |
| 用数组下标表示任意二叉树 | 稀疏树浪费大量空间 | 用节点指针或哈希表 |

## 自测清单

- [ ] 能写出三种深度优先遍历的递归与迭代版本。
- [ ] 层序遍历会按层分组。
- [ ] 知道 BST 退化场景与平衡树的作用。
- [ ] 删除双子节点用中序后继替换。
- [ ] 知道数据库索引用 B+ 树而非二叉树的原因。
