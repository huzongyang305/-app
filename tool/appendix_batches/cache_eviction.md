## 淘汰策略对照

| 策略 | 淘汰依据 | 优点 | 缺点 |
| --- | --- | --- | --- |
| FIFO | 最早进入 | 实现最简单 | 可能淘汰热点数据 |
| LRU | 最久未使用 | 贴合时间局部性 | 突发扫描会污染缓存 |
| LFU | 使用频率最低 | 保护长期热点 | 新数据难以上位，需老化 |
| LRU-K | 第 K 次最近使用 | 抗扫描 | 实现复杂 |
| CLOCK | 环形指针 + 访问位 | 近似 LRU，开销小 | 精度略低 |
| 2Q | 两个队列 | 抗扫描 | 参数需调 |
| TTL + 随机 | 过期时间 | 简单有效 | 命中率不稳定 |

## LRU 模板

```python
from collections import OrderedDict

class LRUCache:
    """哈希表 + 双向链表：查询与更新都是 O(1)。"""

    def __init__(self, capacity: int):
        if capacity <= 0:
            raise ValueError("容量必须为正")
        self.capacity = capacity
        self.data = OrderedDict()
        self.hits = self.misses = 0

    def get(self, key):
        if key not in self.data:
            self.misses += 1
            return None
        self.data.move_to_end(key)          # 标记为最近使用
        self.hits += 1
        return self.data[key]

    def put(self, key, value) -> None:
        if key in self.data:
            self.data.move_to_end(key)
        self.data[key] = value
        if len(self.data) > self.capacity:
            self.data.popitem(last=False)   # 淘汰最久未使用

    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return 0.0 if total == 0 else self.hits / total


def lru_cache_demo(func):
    """用 functools.lru_cache 做记忆化：注意参数必须可哈希。"""
    from functools import lru_cache
    cached = lru_cache(maxsize=128)(func)
    return cached
```

## 缓存问题与对策速查

| 问题 | 现象 | 对策 |
| --- | --- | --- |
| 缓存穿透 | 查询根本不存在的数据 | 缓存空值、布隆过滤器、参数校验 |
| 缓存击穿 | 热点 key 失效瞬间压到下游 | 互斥重建、逻辑过期、热点不过期 |
| 缓存雪崩 | 大量 key 同时失效 | 过期时间加随机、多级缓存、限流 |
| 缓存污染 | 全表扫描挤掉热点 | 用 2Q / LRU-K / TinyLFU |
| 惊群 | 大量线程同时重建同一 key | 单飞（singleflight）|
| 数据不一致 | 缓存与数据库不同步 | 先更新库再删缓存 + 延迟双删 + 重试 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 容量为 0 或负数 | 无法缓存或异常 | 初始化时校验容量 |
| `get` 命中后不更新位置 | 退化成 FIFO | 命中要移动到最近使用位置 |
| 淘汰时删错端 | 淘汰了热点 | 明确哪端是「最久未使用」 |
| 认为 LRU 一定最优 | 扫描型负载命中率骤降 | 依负载选 LRU-K / TinyLFU |
| 无监控命中率 | 无法判断缓存效果 | 记录命中率与淘汰次数 |
| 大对象进同一缓存 | 挤掉大量小对象 | 分开缓存池或按权重计数 |
| 用可变对象作缓存键 | 查不到或误命中 | 键必须可哈希且稳定 |
| 缓存里存可变对象引用 | 外部修改污染缓存 | 存副本或不可变对象 |
| 过期时间统一 | 同一时刻集体失效 | 加随机抖动 |
| 重建时不加锁 | 惊群、下游被打爆 | 单飞或互斥重建 |

## 自测清单

- [ ] 能手写 LRU（哈希表 + 双向链表 / OrderedDict）。
- [ ] 能说出 LRU、LFU、CLOCK 的差异与取舍。
- [ ] 会区分穿透、击穿、雪崩并给出对策。
- [ ] 缓存键可哈希、值不可变或已拷贝。
- [ ] 监控命中率并按负载选择淘汰策略。
