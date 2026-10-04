## 平衡结构对照

| 结构 | 平衡条件 | 查找 | 插入删除 | 特点 |
| --- | --- | --- | --- | --- |
| AVL 树 | 左右子树高度差 ≤ 1 | 最快 | 旋转多 | 读多写少 |
| 红黑树 | 颜色性质约束黑高 ≤ 2log(n+1) | 稍慢 | 旋转少 | 增删频繁（std::map、TreeMap） |
| Treap | 堆序 + BST 序 | 期望 O(log n) | 期望快 | 实现简单，随机优先 |
| 跳表 | 多层索引 | 期望 O(log n) | 期望快 | 实现简单，支持范围查询 |
| B 树 | 多路平衡 | O(log n) | 分裂合并 | 磁盘索引 |
| B+ 树 | 数据全在叶子 + 叶子链表 | O(log n) | 同上 | 数据库索引首选 |

## AVL 旋转速查

| 失衡类型 | 判定 | 处理 |
| --- | --- | --- |
| LL | 左子树的左子树过高 | 右旋一次 |
| RR | 右子树的右子树过高 | 左旋一次 |
| LR | 左子树的右子树过高 | 先左旋左子，再右旋根 |
| RL | 右子树的左子树过高 | 先右旋右子，再左旋根 |

```python
class AVLNode:
    __slots__ = ("key", "left", "right", "height")

    def __init__(self, key):
        self.key, self.left, self.right, self.height = key, None, None, 1


def height(node) -> int:
    return node.height if node else 0


def update(node) -> None:
    node.height = 1 + max(height(node.left), height(node.right))


def rotate_right(y):
    x = y.left
    y.left = x.right
    x.right = y
    update(y)
    update(x)
    return x


def rotate_left(x):
    y = x.right
    x.right = y.left
    y.left = x
    update(x)
    update(y)
    return y


def rebalance(node):
    update(node)
    balance = height(node.left) - height(node.right)
    if balance > 1:
        if height(node.left.left) < height(node.left.right):
            node.left = rotate_left(node.left)     # LR
        return rotate_right(node)
    if balance < -1:
        if height(node.right.right) < height(node.right.left):
            node.right = rotate_right(node.right)  # RL
        return rotate_left(node)
    return node
```

## B+ 树为什么适合磁盘

| 特性 | 收益 |
| --- | --- |
| 节点扇出大（一页几百个键） | 树高通常 3 到 4 层，IO 次数少 |
| 数据只在叶子节点 | 内部节点小，能缓存更多索引 |
| 叶子节点链表相连 | 范围查询与排序扫描高效 |
| 所有查询路径等长 | 性能稳定可预测 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 旋转后不更新高度 | 后续平衡判断错误 | 先更新子节点再更新父节点 |
| 平衡因子符号搞反 | 旋转方向错误 | 统一约定（左高为正）并写测试 |
| 插入后只平衡一处 | 树仍然失衡 | 沿递归路径逐层回溯平衡 |
| 删除后忘记平衡 | 树逐渐退化 | 删除同样需要回溯重平衡 |
| 用 AVL 处理写多场景 | 旋转开销大 | 写多用红黑树或跳表 |
| 二叉树做磁盘索引 | IO 次数过多 | 用 B+ 树 |
| 认为平衡树一定比哈希快 | 场景判断错误 | 精确查找哈希平均 O(1) 更快 |
| 手写平衡树用于生产 | 边界 bug 多 | 用标准库的实现 |
| 忽略重复键策略 | 行为不确定 | 明确计数、丢弃或允许重复 |
| 忘记随机化（Treap / 跳表） | 最坏退化 | 用高质量随机数 |

## 自测清单

- [ ] 能说出 AVL 与红黑树的取舍。
- [ ] 能判断 LL / RR / LR / RL 并选对旋转。
- [ ] 旋转后按顺序更新高度。
- [ ] 知道 B+ 树适合磁盘的三个原因。
- [ ] 生产环境优先使用标准库实现。
