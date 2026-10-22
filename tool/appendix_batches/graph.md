## 图表示与算法选型

| 目的 | 算法 | 复杂度 | 前提 |
| --- | --- | --- | --- |
| 遍历所有节点 | DFS / BFS | O(V+E) | 无 |
| 无权最短路 | BFS | O(V+E) | 边权相等 |
| 非负权最短路 | Dijkstra | O((V+E)log V) | 边权非负 |
| 含负权最短路 | Bellman-Ford | O(VE) | 可检测负环 |
| 多源最短路 | Floyd-Warshall | O(V³) | 小图 |
| 最小生成树 | Kruskal / Prim | O(E log E) | 无向连通图 |
| 拓扑排序 | Kahn / DFS | O(V+E) | 有向无环图 |
| 连通分量 | DFS / 并查集 | O(V+E) | 无向图 |
| 强连通分量 | Tarjan / Kosaraju | O(V+E) | 有向图 |
| 二分图判定 | 染色 BFS | O(V+E) | 无向图 |

存储方式对照：

| 方式 | 空间 | 适合 | 判断两点相邻 |
| --- | --- | --- | --- |
| 邻接矩阵 | O(V²) | 稠密图、需快速查边 | O(1) |
| 邻接表 | O(V+E) | 稀疏图（大多数场景） | O(deg(v)) |
| 边列表 | O(E) | 只需要遍历边（Kruskal） | O(E) |

```python
from collections import deque
import heapq

def dijkstra(graph, start):
    """graph: {节点: [(邻居, 权重), ...]}，返回最短距离字典。"""
    dist = {start: 0}
    heap = [(0, start)]
    while heap:
        d, node = heapq.heappop(heap)
        if d > dist.get(node, float("inf")):
            continue                       # 过期条目，跳过
        for nxt, weight in graph.get(node, []):
            nd = d + weight
            if nd < dist.get(nxt, float("inf")):
                dist[nxt] = nd
                heapq.heappush(heap, (nd, nxt))
    return dist


def topo_sort(graph, indegree):
    """Kahn 算法：入度为 0 入队，逐个出队削减邻居入度。"""
    queue = deque([n for n in indegree if indegree[n] == 0])
    order = []
    while queue:
        node = queue.popleft()
        order.append(node)
        for nxt in graph.get(node, []):
            indegree[nxt] -= 1
            if indegree[nxt] == 0:
                queue.append(nxt)
    return order if len(order) == len(indegree) else []   # 空表示有环
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| BFS 用栈实现 | 变成 DFS，最短路不成立 | BFS 必须用队列 |
| 访问标记在出队时才加 | 同一节点重复入队 | 入队时立即标记 |
| Dijkstra 处理负权 | 结果错误 | 负权用 Bellman-Ford 或 SPFA |
| Dijkstra 不跳过过期堆元素 | 复杂度上升、可能错 | 比较弹出距离与记录距离 |
| 无向图只加一条边 | 反向不可达 | 两个方向都要加 |
| 邻接矩阵用于稀疏大图 | 内存爆掉 | 用邻接表 |
| 拓扑排序不检测环 | 结果缺少节点却当成合法 | 检查输出长度是否等于节点数 |
| 递归 DFS 在深图溢出 | 栈溢出 | 改迭代或增大递归深度 |
| 并查集用于有向图连通性 | 结果错误 | 有向图用 SCC 算法 |
| 忘记孤立节点 | 遍历漏节点 | 从每个未访问节点启动遍历 |

## 自测清单

- [ ] 能按权重与图规模选对最短路算法。
- [ ] BFS 一定用队列并在入队时标记访问。
- [ ] Dijkstra 用优先队列并跳过过期条目。
- [ ] 会根据稠密/稀疏选择邻接矩阵或邻接表。
- [ ] 拓扑排序会检查是否存在环。
