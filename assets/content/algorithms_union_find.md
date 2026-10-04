# 并查集

![并查集](images/remaining_union_find.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「并查集」解决了什么问题，而不是只背术语。
- 能说清 「并查集」、「DSU」、「连通性」、「Kruskal」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「算法与数据结构」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：路径压缩、按秩合并与连通性判定。

## 前置知识

- 先完成上一课《前缀和与差分》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：并查集、DSU、连通性。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 解决什么问题

并查集（Disjoint Set Union，DSU）维护一组不相交的集合，支持两种操作：

```text
find(x)          查询 x 属于哪个集合（返回代表元）
union(x, y)      合并 x 与 y 所在的两个集合
```

几乎以 O(1) 的均摊代价完成，常用于连通性判断、朋友圈计数、Kruskal 最小生成树、动态连通图。

## 基础实现

```python
class DSU:
    def __init__(self, n):
        self.parent = list(range(n))   # 每个元素自成一个集合
        self.rank = [1] * n            # 按秩合并：记录树高/大小

    def find(self, x):
        while self.parent[x] != x:
            self.parent[x] = self.parent[self.parent[x]]   # 路径压缩（隔代压缩）
            x = self.parent[x]
        return x

    def union(self, a, b):
        root_a, root_b = self.find(a), self.find(b)
        if root_a == root_b:
            return False               # 已经同集合，可用于判环
        if self.rank[root_a] < self.rank[root_b]:
            root_a, root_b = root_b, root_a
        self.parent[root_b] = root_a
        self.rank[root_a] += self.rank[root_b]
        return True

    def connected(self, a, b):
        return self.find(a) == self.find(b)
```

递归版 `find` 更简洁，但链很长时可能爆栈，工程中推荐上面的迭代写法。

## 两个优化

| 优化 | 做法 | 效果 |
| --- | --- | --- |
| 路径压缩 | find 时把节点直接挂到根上 | 查询接近 O(1) |
| 按秩/按大小合并 | 小树接到大树下 | 树高保持对数级 |

两者结合后，单次操作的均摊复杂度是 `O(α(n))`（反阿克曼函数），实际可视为常数。

## 典型应用一：岛屿数量

```python
def count_islands(grid):
    if not grid:
        return 0
    rows, cols = len(grid), len(grid[0])
    dsu = DSU(rows * cols)
    water = 0
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == "0":
                water += 1
                continue
            for dr, dc in ((1, 0), (0, 1)):       # 只向右、向下合并
                nr, nc = r + dr, c + dc
                if nr < rows and nc < cols and grid[nr][nc] == "1":
                    dsu.union(r * cols + c, nr * cols + nc)
    roots = {dsu.find(i) for i in range(rows * cols)}
    return len(roots) - water
```

## 典型应用二：Kruskal 最小生成树

```python
def kruskal(n, edges):
    dsu, total, used = DSU(n), 0, 0
    for weight, u, v in sorted(edges):        # 按权重升序
        if dsu.union(u, v):                   # 不成环才选用
            total += weight
            used += 1
            if used == n - 1:
                break
    return total if used == n - 1 else -1
```

## 常见变体

- **带权并查集**：维护节点到根的相对关系（如距离、比例），用于「食物链」「等式方程可满足性」。
- **可撤销并查集**：按秩合并 + 不压缩路径，支持回滚，配合线段树分治。

## 本课小结
并查集的代码只有三十行，但能解决一大类连通性问题。记住两点：**find 负责路径压缩，union 负责按秩合并**；需要判环时 union 返回 false 即说明成环。

<!-- appendix:v1 -->

## 模板（路径压缩 + 按秩合并）

```python
class UnionFind:
    """近乎 O(1) 的合并与查询：路径压缩 + 按大小合并。"""

    def __init__(self, n: int):
        self.parent = list(range(n))
        self.size = [1] * n          # 用大小代替秩，效果相同
        self.count = n               # 连通分量个数

    def find(self, x: int) -> int:
        root = x
        while self.parent[root] != root:      # 先找根
            root = self.parent[root]
        while self.parent[x] != root:         # 再压缩路径
            self.parent[x], x = root, self.parent[x]
        return root

    def union(self, a: int, b: int) -> bool:
        ra, rb = self.find(a), self.find(b)
        if ra == rb:
            return False                      # 已在同一集合，说明这条边成环
        if self.size[ra] < self.size[rb]:
            ra, rb = rb, ra                   # 小树挂到大树上
        self.parent[rb] = ra
        self.size[ra] += self.size[rb]
        self.count -= 1
        return True

    def connected(self, a: int, b: int) -> bool:
        return self.find(a) == self.find(b)


def kruskal(n, edges):
    """最小生成树：按边权升序加边，不成环即选。"""
    uf = UnionFind(n)
    total = 0
    used = 0
    for weight, u, v in sorted(edges):
        if uf.union(u, v):
            total += weight
            used += 1
            if used == n - 1:
                break
    return total if used == n - 1 else -1     # -1 表示图不连通
```

## 应用速查

| 问题 | 并查集的用法 |
| --- | --- |
| 连通分量个数 | 维护 `count`，每次成功合并减一 |
| 判断无向图是否有环 | 遍历边，若两端已同集合则有环 |
| 最小生成树（Kruskal） | 按边权升序尝试加边 |
| 账户合并、好友关系 | 把同组元素 union 起来 |
| 等式方程可满足性 | 等式 union，不等式判断是否冲突 |
| 网格连通、岛屿问题 | 把相邻格子 union |

## 复杂度与优化

| 组合 | 单次操作复杂度 |
| --- | --- |
| 朴素实现 | 最坏 O(n) |
| 仅路径压缩 | 均摊 O(log n) |
| 仅按秩合并 | O(log n) |
| 路径压缩 + 按秩合并 | 均摊 O(α(n))，可视作常数 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `find` 只查一层不递归到根 | 结果错误 | 必须一路找到根节点 |
| 合并时直接改 `parent[a] = b` | 树退化成链 | 先 `find` 找根再合并 |
| 忘记路径压缩 | 大数据超时 | 在 `find` 中压缩路径 |
| 按大小合并时比较写反 | 树越合越高 | 小树挂到大树上 |
| 用并查集处理有向图可达性 | 结果错误 | 有向图用 SCC 或 DFS |
| 想删除元素或分裂集合 | 无法支持 | 用带撤销并查集或换数据结构 |
| Kruskal 不检查连通性 | 得到局部森林 | 检查使用边数是否为 n-1 |
| 下标从 1 开始但初始化为 `range(n)` | 越界或漏点 | 大小为 n+1 并 `range(n+1)` |
| 把「成环」当作错误 | 逻辑判断反了 | 无向图判环时这正是判断依据 |
| 递归 `find` 在深链上溢出 | 栈溢出 | 改迭代版本 |

## 自测清单

- [ ] 能默写路径压缩与按大小合并的 `find` 和 `union`。
- [ ] 知道并查集均摊复杂度接近常数。
- [ ] 会用并查集判无向图环与 Kruskal。
- [ ] 明确并查集不支持删除与分裂。
- [ ] 下标范围与初始化长度保持一致。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「并查集、DSU、连通性」完成复述、实验和交付，每个结果都要能被别人检查。

先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「并查集」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「DSU」是什么关系？

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
- 至少覆盖「并查集」和「DSU」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Union-Find (DSU)

**Summary:** Path compression, union by rank and connectivity.

**Category:** Algorithms  
**Level:** 进阶  
**Key terms:** 并查集, DSU, 连通性, Kruskal

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：任意主流语言（伪代码与复杂度为主）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：并查集、DSU、连通性、Kruskal
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [CP-Algorithms](https://cp-algorithms.com/) | 算法实现与复杂度 |
| [MIT OpenCourseWare 6.006](https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/) | 算法设计与分析 |

> 本课主题：路径压缩、按秩合并与连通性判定。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

