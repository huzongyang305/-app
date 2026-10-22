## 概念速查

| 概念 | 含义 |
| --- | --- |
| 最大流 | 从源点到汇点的最大可行流量 |
| 最小割 | 把源点与汇点分开的最小容量边集 |
| 最大流最小割定理 | 最大流值等于最小割容量 |
| 增广路 | 残余网络中还能增加流量的路径 |
| 残余网络 | 剩余容量与前向、反向边构成的图 |
| 二分图匹配 | 左右两侧各选一个，边不共点 |
| König 定理 | 二分图最大匹配数等于最小顶点覆盖数 |
| 费用流 | 在给定流量下最小化总费用 |

Dinic 算法组成：

| 步骤 | 作用 |
| --- | --- |
| BFS 分层 | 计算每个节点到源点的最短距离（层号） |
| DFS 多路增广 | 只沿层号递增的边推进，一次找出多条增广路 |
| 当前弧优化 | 记录每个节点已尝试的边，避免重复扫描 |
| 重复分层 | 直到汇点不可达 |

复杂度：O(V²E)，单位容量二分图上表现接近 O(E√V)。

```python
from collections import deque

class Dinic:
    """最大流：BFS 分层 + DFS 多路增广 + 当前弧优化。"""

    def __init__(self, n: int):
        self.n = n
        self.graph = [[] for _ in range(n)]      # 每条边存 [to, cap, rev_index]

    def add_edge(self, u: int, v: int, cap: int) -> None:
        self.graph[u].append([v, cap, len(self.graph[v])])
        self.graph[v].append([u, 0, len(self.graph[u]) - 1])   # 反向边容量 0

    def _bfs(self, s: int, t: int) -> bool:
        self.level = [-1] * self.n
        self.level[s] = 0
        queue = deque([s])
        while queue:
            u = queue.popleft()
            for v, cap, _ in self.graph[u]:
                if cap > 0 and self.level[v] < 0:
                    self.level[v] = self.level[u] + 1
                    queue.append(v)
        return self.level[t] >= 0

    def _dfs(self, u: int, t: int, flow: int) -> int:
        if u == t:
            return flow
        while self.it[u] < len(self.graph[u]):
            edge = self.graph[u][self.it[u]]
            v, cap, rev = edge
            if cap > 0 and self.level[v] == self.level[u] + 1:
                pushed = self._dfs(v, t, min(flow, cap))
                if pushed > 0:
                    edge[1] -= pushed
                    self.graph[v][rev][1] += pushed
                    return pushed
            self.it[u] += 1                      # 当前弧：这条边已无用
        return 0

    def max_flow(self, s: int, t: int) -> int:
        total = 0
        while self._bfs(s, t):
            self.it = [0] * self.n
            while True:
                pushed = self._dfs(s, t, float("inf"))
                if pushed == 0:
                    break
                total += pushed
        return int(total)
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 忘记加反向边 | 无法撤销错误流量，结果偏小 | 每条边都建容量为 0 的反向边 |
| 反向边索引记错 | 更新到错误的边 | 存对方列表中的下标并在更新时使用 |
| 分层后不限制层号递增 | 出现环、死循环 | DFS 只走 `level[v] == level[u] + 1` |
| 不做当前弧优化 | 大数据超时 | 用 `it[u]` 记录进度 |
| 用 BFS 单路增广 | 复杂度偏高 | Dinic 一次分层多路增广 |
| 容量用整数但流量用浮点 | 精度问题 | 容量与流量类型统一为整数 |
| 二分图匹配直接建无向边 | 匹配语义错误 | 建源点到左、左到右、右到汇点的有向边 |
| 求最小割却只看最大流值 | 拿不到具体割集 | 分层后 S 侧可达点即最小割一侧 |
| 费用流用最大流算法 | 结果不满足费用最小 | 用连续最短路或消圈法 |
| 节点数与边编号混用 | 越界或错连 | 统一编号规范并写清映射 |

## 自测清单

- [ ] 能解释最大流最小割定理。
- [ ] 记得每条边都要加容量为 0 的反向边。
- [ ] 会用 Dinic 的分层、多路增广与当前弧优化。
- [ ] 会把二分图匹配建模成最大流。
- [ ] 知道费用流与最大流的目标差异。
