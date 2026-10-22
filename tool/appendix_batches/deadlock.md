## 四个必要条件速查

| 条件 | 含义 | 破坏方式 |
| --- | --- | --- |
| 互斥 | 资源同一时刻只能被一个进程占用 | 用可共享资源或无锁结构 |
| 占有并等待 | 持有资源同时等待其他资源 | 一次性申请全部资源 |
| 不可抢占 | 资源只能主动释放 | 允许抢占或超时释放 |
| 循环等待 | 存在进程与资源的等待环 | 统一加锁顺序 |

## 处理策略对照

| 策略 | 做法 | 代价 |
| --- | --- | --- |
| 预防 | 破坏四个条件之一 | 资源利用率下降 |
| 避免 | 银行家算法等动态检查 | 需预知最大需求 |
| 检测与恢复 | 定期查环并回滚 | 实现复杂、有额外开销 |
| 忽略 | 假设不会发生 | 一旦发生需人工干预 |

```python
import threading
import time
from contextlib import contextmanager

class OrderedLocks:
    """按全局固定顺序加锁，破坏循环等待条件。"""

    def __init__(self, count: int):
        self.locks = [threading.Lock() for _ in range(count)]
        self.order_violations = 0

    @contextmanager
    def acquire(self, *indexes):
        ordered = sorted(indexes)                 # 统一按编号升序
        if list(indexes) != ordered:
            self.order_violations += 1            # 记录违规调用便于修复
        for index in ordered:
            self.locks[index].acquire()
        try:
            yield
        finally:
            for index in reversed(ordered):
                self.locks[index].release()


def try_lock_all(locks, timeout: float = 0.5) -> bool:
    """尝试一次性获取全部锁，超时则全部释放并重试。"""
    acquired = []
    deadline = time.monotonic() + timeout
    try:
        for lock in locks:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not lock.acquire(timeout=remaining):
                return False
            acquired.append(lock)
        return True
    finally:
        if len(acquired) != len(locks):
            for lock in acquired:
                lock.release()
            acquired.clear()


def wait_for_graph(graph: dict) -> list:
    """检测资源分配图中的环，返回构成环的进程链。"""
    visited, stack, path = set(), set(), []

    def dfs(node):
        if node in stack:
            return path[path.index(node):] + [node]
        if node in visited:
            return []
        visited.add(node)
        stack.add(node)
        path.append(node)
        for nxt in graph.get(node, []):
            cycle = dfs(nxt)
            if cycle:
                return cycle
        stack.discard(node)
        path.pop()
        return []

    for node in graph:
        cycle = dfs(node)
        if cycle:
            return cycle
    return []

print(wait_for_graph({"P1": ["P2"], "P2": ["P3"], "P3": ["P1"]}))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 加锁顺序不统一 | 偶发死锁 | 全局固定顺序或用有序锁封装 |
| 嵌套加锁且持有时做耗时操作 | 锁等待时间变长 | 只锁临界区，耗时操作移到锁外 |
| 无超时获取锁 | 永久阻塞 | `tryLock` 带超时并重试或放弃 |
| 锁内调用外部服务 | 事务与锁时间不可控 | 外部调用放锁外 |
| 只靠人工排查 | 定位困难 | 记录锁持有者与等待链 |
| 数据库死锁不重试 | 请求失败 | 捕获死锁错误并有限重试 |
| 认为加锁越多越安全 | 并发度骤降 | 减少共享状态与锁粒度 |
| 忽略锁顺序在重构中被破坏 | 新代码引入死锁 | 封装加锁接口并加静态检查 |
| 忘记释放锁 | 其他线程永久等待 | 用 `with`/RAII 自动释放 |
| 单实例资源图结论套用到多实例 | 误判死锁 | 多实例需结合可用数量判断 |

## 自测清单

- [ ] 能背出死锁的四个必要条件。
- [ ] 会用固定加锁顺序或一次性申请来预防。
- [ ] 加锁都有超时与释放保障。
- [ ] 会用等待图或 `jstack` 等工具检测死锁。
- [ ] 数据库死锁有重试与监控。
