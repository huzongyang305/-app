## 实战题型与结构选型

| 需求 | 首选结构 | 复杂度 |
| --- | --- | --- |
| 最近最少使用缓存 | 哈希表 + 双向链表 | get/put O(1) |
| 最高频使用缓存 | 哈希表 + 频次桶 | get/put O(1) |
| 定时过期缓存 | 哈希表 + 最小堆 / 时间轮 | 过期处理 O(log n) |
| TopK 热点 | 大小为 k 的最小堆 | O(n log k) |
| 滑动窗口统计 | 单调队列 / 前缀和 | O(n) |
| 频率统计（海量） | Count-Min Sketch | O(1) 近似 |
| 去重（海量） | 布隆过滤器 + 精确复核 | O(k) |
| 限流（单机） | 令牌桶 / 滑动窗口 | O(1) |
| 限流（分布式） | Redis + Lua | O(1) |
| 排行榜 | 跳表 / 有序集合 | O(log n) |

## 组合示例

```python
import heapq
import time
from collections import OrderedDict, deque

class SlidingWindowLimiter:
    """滑动窗口限流：只保留窗口内的请求时间戳。"""

    def __init__(self, limit: int, window_seconds: float):
        self.limit = limit
        self.window = window_seconds
        self.events: deque[float] = deque()

    def allow(self, now: float | None = None) -> bool:
        now = time.monotonic() if now is None else now
        while self.events and now - self.events[0] >= self.window:
            self.events.popleft()              # 移除过期请求
        if len(self.events) >= self.limit:
            return False
        self.events.append(now)
        return True


class TokenBucket:
    """令牌桶：允许一定突发，平均速率受限于补充速率。"""

    def __init__(self, rate: float, capacity: float):
        self.rate, self.capacity = rate, capacity
        self.tokens = capacity
        self.updated = time.monotonic()

    def allow(self, cost: float = 1.0) -> bool:
        now = time.monotonic()
        elapsed = now - self.updated
        self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
        self.updated = now
        if self.tokens >= cost:
            self.tokens -= cost
            return True
        return False


def top_k(records, k):
    """TopK：只维护大小为 k 的最小堆，内存 O(k)。"""
    heap = []
    for name, score in records:
        if len(heap) < k:
            heapq.heappush(heap, (score, name))
        elif score > heap[0][0]:
            heapq.heapreplace(heap, (score, name))
    return sorted(heap, key=lambda x: -x[0])


class TTLCache:
    """带过期时间的缓存：惰性删除 + 容量上限。"""

    def __init__(self, capacity: int, ttl: float):
        self.capacity, self.ttl = capacity, ttl
        self.data: OrderedDict = OrderedDict()

    def get(self, key):
        item = self.data.get(key)
        if item is None:
            return None
        value, expire_at = item
        if expire_at < time.monotonic():
            self.data.pop(key, None)           # 惰性删除
            return None
        self.data.move_to_end(key)
        return value

    def put(self, key, value) -> None:
        self.data[key] = (value, time.monotonic() + self.ttl)
        self.data.move_to_end(key)
        while len(self.data) > self.capacity:
            self.data.popitem(last=False)
```

## 工程要点速查

| 要点 | 说明 |
| --- | --- |
| 明确不变量 | 如「链表长度等于 map 大小」 |
| 边界测试 | 容量 1、空缓存、重复键、并发访问 |
| 并发安全 | 单机加锁或分段锁，分布式用共享存储 + 原子操作 |
| 内存上限 | 按条数或按权重限制，避免 OOM |
| 监控指标 | 命中率、淘汰数、平均延迟、错误率 |
| 降级策略 | 缓存不可用时直接回落数据库并限流 |
| 幂等 | 重试不会产生副作用 |
| 单元测试 + 压测 | 正确性靠测试，容量靠压测验证 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| LRU 只用哈希表 | 无法维护访问顺序 | 配合双向链表或有序字典 |
| 限流用固定窗口计数 | 窗口边界出现两倍突发 | 用滑动窗口或令牌桶 |
| 分布式限流用本地计数 | 多实例叠加后超限 | 用 Redis 等共享状态 |
| 令牌桶不记录更新时间 | 令牌计算错误 | 每次按时间差补充令牌 |
| TopK 全量排序 | 内存与时间浪费 | 维护大小为 k 的堆 |
| 缓存不设上限 | 内存持续增长 | 明确容量与淘汰策略 |
| 过期键不清理 | 内存泄漏 | 惰性删除 + 定期清理 |
| 无命中率监控 | 无法评估效果 | 记录命中率与延迟 |
| 只做正确性测试不做压测 | 上线后容量不足 | 压测确认 QPS 与延迟 |
| 并发下直接改共享结构 | 数据竞争 | 加锁或使用并发安全结构 |

## 自测清单

- [ ] 能为每个需求选出合适的数据结构并说明复杂度。
- [ ] 手写过 LRU、限流器与 TopK。
- [ ] 明确缓存容量、过期与降级策略。
- [ ] 有边界用例与并发测试。
- [ ] 压测验证容量，并上线监控命中率与延迟。
