# 树与二叉搜索树

![树与二叉搜索树](images/remaining_tree_bst.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「树与二叉搜索树」解决了什么问题，而不是只背术语。
- 能说清 「二叉树」、「遍历」、「BST」、「红黑树」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「算法与数据结构」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：四种遍历、BST 查找插入与平衡树家族。

## 前置知识

- 先完成上一课《链表》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：二叉树、遍历、BST。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 二叉树基础

每个节点最多两个子节点（left / right）。常见术语：根节点、叶子节点、深度、高度、子树。

```python
class TreeNode:
    def __init__(self, value, left=None, right=None):
        self.value = value
        self.left = left
        self.right = right
```

## 四种遍历

```python
def preorder(node):        # 根 -> 左 -> 右
    if not node:
        return []
    return [node.value] + preorder(node.left) + preorder(node.right)

def inorder(node):         # 左 -> 根 -> 右：二叉搜索树得到升序
    if not node:
        return []
    return inorder(node.left) + [node.value] + inorder(node.right)

def postorder(node):       # 左 -> 右 -> 根：适合释放资源
    if not node:
        return []
    return postorder(node.left) + postorder(node.right) + [node.value]

from collections import deque

def level_order(root):     # 层序遍历（BFS）
    if not root:
        return []
    result, queue = [], deque([root])
    while queue:
        level = []
        for _ in range(len(queue)):
            node = queue.popleft()
            level.append(node.value)
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        result.append(level)
    return result
```

## 二叉搜索树（BST）

性质：任意节点的左子树全部小于它，右子树全部大于它。

```python
def search(node, target):
    while node:
        if target == node.value:
            return node
        node = node.left if target < node.value else node.right
    return None

def insert(node, value):
    if not node:
        return TreeNode(value)
    if value < node.value:
        node.left = insert(node.left, value)
    elif value > node.value:
        node.right = insert(node.right, value)
    return node
```

平均查找 `O(log n)`，但插入有序数据会退化成链表，最坏 `O(n)`。

## 平衡树家族

| 结构 | 特点 |
| --- | --- |
| AVL 树 | 严格平衡，查找快，旋转较频繁 |
| 红黑树 | 近似平衡，插入删除代价低（Java TreeMap、C++ map） |
| B / B+ 树 | 多路平衡，磁盘友好（数据库索引） |
| 堆 | 完全二叉树，取最值 O(1)，常配合优先队列 |

## 本课小结
树的价值在于**分层与对数复杂度**。掌握四种遍历与 BST 查找插入，再看平衡树与堆就不会吃力。


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

## 动手练习


> 本课练习重点：围绕「二叉树、遍历、BST」完成复述、实验和交付，每个结果都要能被别人检查。

先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「树与二叉搜索树」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「遍历」是什么关系？

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
- 至少覆盖「二叉树」和「遍历」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：对二叉搜索树做哪种遍历能得到升序序列？

- **正确判断**：中序
- **判断依据**：中序遍历顺序是左-根-右，正好符合 BST 左小右大的性质。其他选项：中序遍历按「左、根、右」访问，正好得到升序。前序、后序、层序都不保证有序。正确项「中序」既符合定义也满足题干限定的场景，因此应当选择。把题干「对二叉搜索树做哪种遍历能得到升序序列？」放回《树与二叉搜索树》的「四种遍历、BST 查找插入与平衡树家族」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 2：层序遍历需要借助哪种数据结构？

- **正确判断**：队列
- **判断依据**：层序是广度优先，用队列保证按层顺序访问。其他选项：层序需要先进先出，因此用队列。栈对应深度优先，堆用于优先级场景。正确项「队列」正面回答了题目所问，符合课程给出的定义与适用范围。错误项「哈希表」与课程给出的定义相冲突，不能回答题目所问。把题干「层序遍历需要借助哪种数据结构？」放回《树与二叉搜索树》的「四种遍历、BST 查找插入与平衡树家族」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：向二叉搜索树依次插入有序数据会怎样？

- **正确判断**：退化成链表
- **判断依据**：这正是需要 AVL、红黑树等平衡树的原因。其他选项：有序插入会让 BST 退化成链表，查找退化为 O(n)，所以需要平衡树或随机化插入。正确项「退化成链表」描述正确，能够解释题干场景中的现象与结果。错误项「保持平衡」与课程给出的定义相冲突，不能回答题目所问。错误项「报错」只看到了表面现象，没有解释题干真正考查的机制。错误项「自动排序」在边界或失败路径上会得出错误结果。把题干「向二叉搜索树依次插入有序数据会怎样？」放回《树与二叉搜索树》的「四种遍历、BST 查找插入与平衡树家族」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：平衡二叉搜索树能把查找、插入、删除的复杂度控制在？

- **正确判断**：O(log n)
- **判断依据**：AVL 与红黑树通过旋转维持高度在 O(log n)，避免退化成链表。其他选项：平衡后树高是 O(log n)，三种操作都是这个量级。O(n) 是退化后的结果。正确项「O(log n)」既符合定义也满足题干限定的场景，因此应当选择。错误项「O(n log n)」忽略了题目中的限制条件，因此不成立。错误项「O(1)」把不同概念混在一起，缺少题干限定的前提。把题干「平衡二叉搜索树能把查找、插入、删除的复杂度控制在？」放回《树与二叉搜索树》的「四种遍历、BST 查找插入与平衡树家族」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 5：删除二叉搜索树中「有两个孩子」的节点，常用做法是？

- **正确判断**：用中序后继（右子树最小）或中序前驱替换后递归删除
- **判断依据**：替换后仍满足 BST 的有序性质，是标准的删除实现。其他选项：用中序后继（右子树最小）或中序前驱替换可保持 BST 性质。直接删除或重建都不是标准做法。正确项「用中序后继（右子树最小）或中序前驱替换后递归删除」正面回答了题目所问，符合课程给出的定义与适用范围。错误项「直接删除并断开子树（仅部分场景成立）」属于相邻主题的说法，范围与本题要求不一致。错误项「整棵树重建」与课程给出的定义相冲突，不能回答题目所问。错误项「把它移到根节点」只看到了表面现象，没有解释题干真正考查的机制。把题干「删除二叉搜索树中「有两个孩子」的节点，常用做法是？」放回《树与二叉搜索树》的「四种遍历、BST 查找插入与平衡树家族」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「对二叉搜索树做哪种遍历能得到升序序列？」的判断依据。
- [ ] 不看解析，能说出「层序遍历需要借助哪种数据结构？」的判断依据。
- [ ] 不看解析，能说出「向二叉搜索树依次插入有序数据会怎样？」的判断依据。
- [ ] 不看解析，能说出「平衡二叉搜索树能把查找、插入、删除的复杂度控制在？」的判断依据。
- [ ] 不看解析，能说出「删除二叉搜索树中「有两个孩子」的节点，常用做法是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Trees & BST

**Summary:** Traversals, BST operations and balanced trees.

**Category:** Algorithms  
**Level:** 进阶  
**Key terms:** 二叉树, 遍历, BST, 红黑树, 堆

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：任意主流语言（伪代码与复杂度为主）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：二叉树、遍历、BST、红黑树、堆
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [CP-Algorithms](https://cp-algorithms.com/) | 算法实现与复杂度 |
| [MIT OpenCourseWare 6.006](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/) | 算法设计与分析 |

> 本课主题：四种遍历、BST 查找插入与平衡树家族。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

