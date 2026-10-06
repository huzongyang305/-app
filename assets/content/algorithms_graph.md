# 图与图算法

![邻接矩阵与邻接表对比](images/diagram_graph.webp)

![图与图算法](images/remaining_graph.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：30 分钟

## 学习目标

- 能用自己的话解释图与图算法解决了什么问题，而不是只背术语。
- 能说清 「图」、「BFS」、「DFS」、「拓扑排序」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「算法与数据结构」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：邻接表、BFS/DFS、拓扑排序与 Dijkstra。

## 前置知识

- 先完成上一课《树与二叉搜索树》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：图、BFS、DFS。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 图的表示

```python
# 邻接表：稀疏图首选，空间 O(V + E)
graph = {
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D", "E"],
    "D": ["E"],
    "E": [],
}

# 邻接矩阵：稠密图或需要 O(1) 判断两点是否相邻时使用，空间 O(V²)
matrix = [
    [0, 1, 1, 0, 0],
    [0, 0, 0, 1, 0],
    [0, 0, 0, 1, 1],
    [0, 0, 0, 0, 1],
    [0, 0, 0, 0, 0],
]
```

## 深度优先与广度优先

```python
def dfs(graph, start, visited=None):
    visited = visited or set()
    visited.add(start)
    result = [start]
    for neighbor in graph[start]:
        if neighbor not in visited:
            result += dfs(graph, neighbor, visited)
    return result

from collections import deque

def bfs(graph, start):
    visited, queue, order = {start}, deque([start]), []
    while queue:
        node = queue.popleft()
        order.append(node)
        for neighbor in graph[node]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
    return order
```

- DFS 用栈/递归，适合找路径、连通分量、环检测。
- BFS 用队列，适合无权图最短路、层序遍历。

## 拓扑排序

有向无环图（DAG）的线性排序，用于任务调度与依赖解析：

```python
def topological_sort(graph):
    indegree = {node: 0 for node in graph}
    for neighbors in graph.values():
        for neighbor in neighbors:
            indegree[neighbor] += 1
    queue = deque([n for n, d in indegree.items() if d == 0])
    order = []
    while queue:
        node = queue.popleft()
        order.append(node)
        for neighbor in graph[node]:
            indegree[neighbor] -= 1
            if indegree[neighbor] == 0:
                queue.append(neighbor)
    return order if len(order) == len(graph) else []   # 空表示存在环
```

## 最短路径

```python
import heapq

def dijkstra(graph, start):
    dist = {node: float("inf") for node in graph}
    dist[start] = 0
    heap = [(0, start)]
    while heap:
        d, node = heapq.heappop(heap)
        if d > dist[node]:
            continue
        for neighbor, weight in graph[node]:
            new_dist = d + weight
            if new_dist < dist[neighbor]:
                dist[neighbor] = new_dist
                heapq.heappush(heap, (new_dist, neighbor))
    return dist
```

Dijkstra 要求边权非负；有负权用 Bellman-Ford，多源最短路用 Floyd-Warshall。

## 三种遍历的对比与选择

```python
# BFS：队列，按层扩展
from collections import deque
def bfs(graph, start):
    seen, queue = {start}, deque([start])
    while queue:
        node = queue.popleft()
        for nxt in graph[node]:
            if nxt not in seen:
                seen.add(nxt); queue.append(nxt)

# DFS：递归或显式栈
def dfs(graph, node, seen=None):
    seen = seen or set()
    seen.add(node)
    for nxt in graph[node]:
        if nxt not in seen:
            dfs(graph, nxt, seen)

# Dijkstra：优先队列按距离出队（仅适用于非负权）
import heapq
def dijkstra(graph, start):
    dist = {start: 0}; heap = [(0, start)]
    while heap:
        d, node = heapq.heappop(heap)
        if d > dist.get(node, float("inf")): continue
        for nxt, w in graph[node]:
            nd = d + w
            if nd < dist.get(nxt, float("inf")):
                dist[nxt] = nd; heapq.heappush(heap, (nd, nxt))
    return dist
```

| 算法 | 数据结构 | 复杂度 | 适用 |
| --- | --- | --- | --- |
| BFS | 队列 | O(V+E) | 无权最短路、层序、连通分量 |
| DFS | 栈/递归 | O(V+E) | 路径枚举、环检测、拓扑排序基础 |
| Dijkstra | 优先队列 | O((V+E)log V) | 非负权最短路 |

实现上最常见的三个错误：**忘记标记已访问导致重复入队**（内存暴涨）、**Dijkstra 用普通队列导致复杂度退化**、**在稠密图上用邻接表却仍按 O(V²) 遍历**。

## 本课小结

图算法先分清三件事：**有没有方向、有没有权重、要不要环**。BFS/DFS 是基础，拓扑排序解决依赖，Dijkstra 解决非负权最短路。

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

## 常见错误与排查

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

## 复习与自测

- [ ] 能按权重与图规模选对最短路算法。
- [ ] BFS 一定用队列并在入队时标记访问。
- [ ] Dijkstra 用优先队列并跳过过期条目。
- [ ] 会根据稠密/稀疏选择邻接矩阵或邻接表。
- [ ] 拓扑排序会检查是否存在环。

## 动手练习

> 本课练习重点：围绕「图、BFS、DFS」完成复述、实验和交付，每个结果都要能被别人检查。

先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 图与图算法解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「BFS」是什么关系？

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
- 至少覆盖「图」和「BFS」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

```python
# 邻接表：稀疏图首选，空间 O(V + E)
graph = {
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D", "E"],
    "D": ["E"],
    "E": [],
}

# 邻接矩阵：稠密图或需要 O(1) 判断两点是否相邻时使用，空间 O(V²)
matrix = [
    [0, 1, 1, 0, 0],
    [0, 0, 0, 1, 0],
    [0, 0, 0, 1, 1],
    [0, 0, 0, 0, 1],
    [0, 0, 0, 0, 0],
]
```

### 任务 2：只改一个条件

把「图与图算法」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把图的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「图与图算法」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响图。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 图 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 图 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 图 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“图 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 图 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 BFS 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 BFS 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 BFS 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“BFS 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 BFS 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：小数据规模结果正确，扩大输入后超时或内存溢出

**定位**：围绕“图 的时间或空间复杂度在边界条件下失控，BFS 的常数开销也被低估”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「表示稀疏图通常选择？」的判断依据。
- [ ] 不看解析，能说出「求无权图两点间最短路径应使用？」的判断依据。
- [ ] 不看解析，能说出「Dijkstra 算法的前提是？」的判断依据。
- [ ] 不看解析，能说出「深度优先搜索（DFS）的典型实现方式是？」的判断依据。
- [ ] 不看解析，能说出「拓扑排序存在的必要条件是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「图与图算法」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `图` | 它在「图与图算法」里是理解「图」的关键术语，用来解释定义、适用条件与失败路径；它与BFS、DFS共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |
| `BFS` | 围绕“图 的时间或空间复杂度在边界条件下失控，BFS 的常数开销也被低估”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `DFS` | Summary: Representations, BFS/DFS, topo sort and Dijkstra.。 |
| `拓扑排序` | 它在「图与图算法」里是理解「拓扑排序」的关键术语，用来解释定义、适用条件与失败路径；它与BFS、DFS共同决定这一节的判断边界。复习时回到正文示例核对输入、输出和验证方式。 |
| `Dijkstra` | 实现上最常见的三个错误：忘记标记已访问导致重复入队（内存暴涨）、Dijkstra 用普通队列导致复杂度退化、在稠密图上用邻接表却仍按 O(V²) 遍历。 |

## 考点精讲

### 考点 1：概念判断·图

- **题目**：表示稀疏图通常选择？
- **判断依据**：邻接表空间是 O(V+E)，稀疏图下远小于矩阵的 O(V²)。其他选项：稀疏图边数与点数同阶，邻接表更省空间。回到「图与图算法」的正文示例，用“表示稀疏图通常选择”走一遍图、BFS、DFS的完整流程，能复现的结论才可以保留。回到图、BFS、DFS本身再看一遍：只有“邻接表”与题干“表示稀疏图通常选择”的前提一致，结论才成立。

### 考点 2：多选辨析·图

- **题目**：围绕“图与图算法”中的 图、BFS、DFS，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把图与图算法拆成概念、示例与故障现场三部分，因此判断 图 时必须同时交代输入、输出和失败路径，这使“学习 图 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在图与图算法里，判断 BFS 时要固定版本与边界输入，所以“验证 BFS 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：顺序排列·图

- **题目**：按“图与图算法”中 图、BFS、DFS 的实践顺序，把四个步骤排成从准备到复盘的合理顺序。
- **判断依据**：在「图与图算法」里，在本课的练习里，顺序应当是：先明确 图 的输入、输出与约束 → 写出最小示例并核对 BFS 的基线结果 → 只改一个变量，记录边界与失败路径的变化 → 固定版本与证据，把本课的结论写成可复现记录。这个顺序把 图 的输入、输出和约束放在最前面，在图与图算法里避免概念没对齐就开始调参。第二步用 BFS 建立可核对的基线，在图与图算法里第三步才允许改变一个变量并观察失败路径。

### 考点 4：概念判断·图

- **题目**：深度优先搜索（DFS）的典型实现方式是？
- **判断依据**：图很深时递归可能栈溢出，工程实现常改成显式栈或增大栈空间。在「图与图算法」里，作答时，先用图建立输入与输出的基线，再把递归，或用显式栈模拟递归代入边界条件核对，结论才能复现。在「图与图算法」里，这道题要求区分概念与边界，「递归，或用显式栈模拟递归」只有在题干给出的前提下才成立，而「只能用于有向图」、「必须使用优先队列」缺少同一组条件。

### 考点 5：概念判断·图

- **题目**：拓扑排序存在的必要条件是？
- **判断依据**：在「图与图算法」里，有向图不存在环（是 DAG）。Kahn 算法（不断取出入度为 0 的点）若无法输出全部节点就说明存在环。回到「图与图算法」的正文示例，用“拓扑排序存在的必要条件是”走一遍图、BFS、DFS的完整流程，能复现的结论才可以保留。

### 考点 6：排错·图

- **题目**：阅读「图与图算法」的代码片段，下面哪项判断是正确的？
- **判断依据**：邻接表空间是 O(V+E)，稀疏图下远小于矩阵的 O(V²)。其他选项：稀疏图边数与点数同阶，邻接表更省空间。这道题的关键在「图与图算法」的图、BFS、DFS：先确认题干“阅读图与图算法的代码片段”问的是哪一步，再排除偷换前提的选项。回到图、BFS、DFS本身再看一遍：只有“邻接表”与题干“阅读的代码片段”的前提一致，结论才成立。

## English Overview

**Title:** Graphs

**Summary:** Representations, BFS/DFS, topo sort and Dijkstra.

**Category:** Algorithms
**Level:** 高级
**Key terms:** 图, BFS, DFS, 拓扑排序, Dijkstra

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：任意主流语言（伪代码与复杂度为主）
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：图、BFS、DFS、拓扑排序、Dijkstra
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [GeeksforGeeks 算法](https://www.geeksforgeeks.org/fundamentals-of-algorithms/) | 算法专题与实现 |
| [Princeton Algorithms](https://algs4.cs.princeton.edu/home/) | 经典算法与数据结构教材 |
| [VisuAlgo](https://visualgo.net/en) | 算法可视化与交互 |

> 「图与图算法」的链接用于离线阅读后的延伸核对；App 不会自动联网。
