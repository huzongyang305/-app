## 结构选型速查

| 结构 | 解决的问题 | 误差方向 | 空间 |
| --- | --- | --- | --- |
| 布隆过滤器 | 判断元素「可能存在 / 一定不存在」 | 只会假阳性 | 每元素约 10 bit（1% 误判） |
| 计数布隆过滤器 | 支持删除的布隆变体 | 假阳性 | 每位换成计数器 |
| Cuckoo Filter | 支持删除且空间更省 | 假阳性 | 比布隆更紧凑 |
| Count-Min Sketch | 频率估计 | 只会高估 | O(1/ε · log(1/δ)) |
| HyperLogLog | 基数（去重计数）估计 | 双向小误差（约 0.81%） | 每个基数约 12KB 上限 |
| 跳表 | 有序集合、范围查询 | 无 | O(n) |
| 最小哈希 | 集合相似度（Jaccard） | 估计误差 | 取决于签名长度 |

## 参数速查

| 目标误判率 | 位数组 m/n | 哈希函数个数 k |
| --- | --- | --- |
| 10% | 4.8 | 3 |
| 1% | 9.6 | 7 |
| 0.1% | 14.4 | 10 |
| 0.01% | 19.2 | 13 |

公式：`m/n = -ln(p) / (ln2)²`，`k = (m/n)·ln2`。

```python
import hashlib
import math

class BloomFilter:
    """布隆过滤器：只会假阳性，绝不会有假阴性。"""

    def __init__(self, capacity: int, error_rate: float = 0.01):
        self.m = max(1, int(-capacity * math.log(error_rate) / (math.log(2) ** 2)))
        self.k = max(1, int((self.m / capacity) * math.log(2)))
        self.bits = bytearray((self.m + 7) // 8)
        self.count = 0

    def _positions(self, item: str):
        data = item.encode("utf-8")
        for i in range(self.k):
            digest = hashlib.blake2b(data, digest_size=8, salt=str(i).encode()).digest()
            yield int.from_bytes(digest, "big") % self.m

    def add(self, item: str) -> None:
        for pos in self._positions(item):
            self.bits[pos >> 3] |= 1 << (pos & 7)
        self.count += 1

    def might_contain(self, item: str) -> bool:
        return all(
            self.bits[pos >> 3] & (1 << (pos & 7)) for pos in self._positions(item)
        )


def hll_estimate_precision() -> None:
    """HyperLogLog 的相对标准误差约为 1.04 / sqrt(m)。"""
    for m in (2**10, 2**12, 2**14):
        print(m, f"{1.04 / math.sqrt(m):.2%}")
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把布隆过滤器的「可能存在」当「一定存在」 | 误判数据存在 | 后面必须用精确结构复核 |
| 用布隆过滤器删除元素 | 误删其他元素 | 用计数布隆或 Cuckoo Filter |
| 容量估算过小 | 误判率远高于预期 | 按预期元素数与目标误判率计算 m 与 k |
| 元素数超容量后不扩容 | 误判率急剧上升 | 监控插入量并重建扩容 |
| 哈希函数相关性高 | 误判率上升 | 用独立或双哈希组合 |
| 用 HLL 做精确计数 | 结果有误差 | 明确可接受误差再用 |
| 用 Count-Min 估计热 key 却当精确值 | 高估频率 | 结合精确计数校验 |
| 用跳表替代哈希做精确查找 | 复杂度更高 | 精确查存在性用哈希，需要有序用跳表 |
| 认为概率结构节省空间无代价 | 空间换误差 | 明确误差预算与复核策略 |
| 存储哈希值当数据 | 无法还原原值 | 它只回答「是否可能存在」 |

## 自测清单

- [ ] 能说出布隆过滤器只有假阳性、没有假阴性。
- [ ] 会按目标误判率估算 m 与 k。
- [ ] 知道布隆默认不能删除，需要计数版本。
- [ ] 清楚 HLL 用于基数估计且存在固定误差。
- [ ] 概率结构后面总要接精确校验。
