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
