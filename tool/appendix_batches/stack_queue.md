## 应用场景速查

| 结构 | 特性 | 典型应用 |
| --- | --- | --- |
| 栈 | 后进先出 | 括号匹配、表达式求值、DFS、撤销、调用栈 |
| 队列 | 先进先出 | BFS、任务调度、缓冲区 |
| 双端队列 | 两端 O(1) | 单调队列、滑动窗口最大值 |
| 优先队列 / 堆 | 按优先级出队 | TopK、任务优先级、Dijkstra |
| 循环队列 | 固定空间复用 | 环形缓冲区、生产者消费者 |

```python
from collections import deque

# 括号匹配：栈的经典用法
def is_balanced(text: str) -> bool:
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for ch in text:
        if ch in "([{":
            stack.append(ch)
        elif ch in pairs:
            if not stack or stack.pop() != pairs[ch]:
                return False
    return not stack

# 队列用 deque，两端都是 O(1)
def bfs(graph, start):
    queue = deque([start])
    visited = {start}
    order = []
    while queue:
        node = queue.popleft()       # 不要用 list.pop(0)
        order.append(node)
        for nxt in graph.get(node, []):
            if nxt not in visited:
                visited.add(nxt)
                queue.append(nxt)
    return order
```

## 实现方式对照

| 实现 | 栈 | 队列 |
| --- | --- | --- |
| 动态数组 | `append` / `pop()` 都 O(1) | `pop(0)` 是 O(n)，不可取 |
| 链表 | 头插头取 O(1) | 头取尾插 O(1) |
| `collections.deque` | 两端 O(1) | 两端 O(1)，首选 |
| 固定数组（环形） | 需管理下标 | 空间固定，适合流式数据 |
| 两个栈 | 可实现 | 入队 O(1)，出队均摊 O(1) |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `list.pop(0)` 当队列 | 数据量大时极慢 | 用 `deque.popleft()` |
| 空栈上 `pop()` | `IndexError` | 先判空或捕获异常 |
| 括号匹配只看开括号计数 | 会把 `([)]` 判为合法 | 必须检查类型匹配 |
| 入队与出队混用同一端 | 变成栈 | 明确 FIFO 语义 |
| 循环队列不判空与满 | 覆盖数据 | 用 `size` 计数或留一个空位区分 |
| BFS 忘记标记已访问 | 死循环或重复入队 | 入队时立刻标记 |
| DFS 递归深度过大 | 栈溢出 | 改用显式栈 |
| 优先队列用排序列表实现 | 每次插入 O(n) | 用堆（`heapq` / `PriorityQueue`） |
| `heapq` 存自定义对象 | 无法比较报错 | 存元组 `(priority, counter, item)` |
| 多线程共享队列用普通列表 | 竞态 | 用 `queue.Queue` 或加锁 |

## 自测清单

- [ ] 能用栈解决括号匹配与逆序问题。
- [ ] 队列一律用 `deque`，不用 `list.pop(0)`。
- [ ] BFS 入队即标记已访问。
- [ ] 需要优先级时使用堆而不是排序列表。
- [ ] 知道循环队列如何区分空与满。
