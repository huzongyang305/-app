## 短码生成方案速查

| 方案 | 做法 | 优点 | 缺点 |
| --- | --- | --- | --- |
| 发号器 + 进制转换 | 全局自增 ID 转 62 进制 | 无冲突、实现简单 | 短码可枚举 |
| 哈希 + 冲突检测 | 长链哈希取前几位 | 相同长链可复用 | 需查重、冲突重试 |
| 预生成短码池 | 提前生成写入池 | 写入快、可打乱 | 需要池管理 |
| 随机字符串 | 随机生成后查重 | 不可枚举 | 冲突概率与重试 |

推荐组合：**发号器（趋势递增）＋ 打乱映射 ＋ 校验位**，既难枚举又便于排查。

## 关键设计速查

| 主题 | 做法 |
| --- | --- |
| 跳转码 | 用 302 保留统计与改链能力（301 会被长期缓存） |
| 读多写少 | 多级缓存：本地缓存 + Redis + 数据库 |
| 缓存穿透 | 短码不存在时缓存空值，防刷 |
| 数据量 | 按年新增量估算存储与短码长度 |
| 分片 | 按短码哈希分片，尽量让查询命中单分片 |
| 统计 | 跳转埋点异步写入，避免拖慢重定向 |
| 风控 | 长链校验、域名黑名单、频率限制 |
| 过期 | 支持 TTL 与回收，过期后返回 410 |

```python
import hashlib
import string
from dataclasses import dataclass, field

ALPHABET = string.digits + string.ascii_lowercase + string.ascii_uppercase

def encode_base62(number: int, min_length: int = 6) -> str:
    """自增 ID 转 62 进制短码。"""
    if number < 0:
        raise ValueError("ID 必须非负")
    chars = []
    base = len(ALPHABET)
    while number > 0:
        number, remainder = divmod(number, base)
        chars.append(ALPHABET[remainder])
    code = "".join(reversed(chars)) or ALPHABET[0]
    return code.rjust(min_length, ALPHABET[0])

def checksum(code: str) -> str:
    """追加校验位，用于快速识别非法或伪造短码。"""
    value = int(hashlib.sha256(code.encode()).hexdigest(), 16)
    return ALPHABET[value % len(ALPHABET)]

def make_short_code(sequence: int, min_length: int = 6) -> str:
    base = encode_base62(sequence, min_length)
    return f"{base}{checksum(base)}"

@dataclass
class CapacityEstimate:
    """容量估算：按年新增量决定短码长度与分片数。"""

    writes_per_day: int
    years: int = 5
    shards: int = 16

    def total_keys(self) -> int:
        return self.writes_per_day * 365 * self.years

    def code_space(self, length: int) -> int:
        return len(ALPHABET) ** length

    def required_length(self) -> int:
        length = 1
        while self.code_space(length) < self.total_keys() * 10:   # 留 10 倍余量
            length += 1
        return length

    def keys_per_shard(self) -> int:
        return self.total_keys() // self.shards

@dataclass
class ClickStats:
    """跳转统计：异步聚合，避免阻塞重定向路径。"""

    counters: dict = field(default_factory=dict)

    def record(self, code: str) -> None:
        self.counters[code] = self.counters.get(code, 0) + 1

    def top(self, limit: int = 3) -> list:
        ordered = sorted(self.counters.items(), key=lambda item: -item[1])
        return ordered[:limit]

estimate = CapacityEstimate(writes_per_day=200_000)
print(estimate.total_keys(), estimate.required_length(), estimate.keys_per_shard())
print(make_short_code(1_000_000), encode_base62(62))
stats = ClickStats()
for code in ["a1", "a1", "b2"]:
    stats.record(code)
print(stats.top())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用随机短码且查重缺失 | 出现冲突覆盖 | 唯一索引兜底并重试 |
| 短码可枚举 | 被批量爬取数据 | 打乱映射或用不可预测随机码 |
| 跳转用 301 | 改链后用户仍访问旧地址 | 用 302 或 307 |
| 重定向路径写数据库 | 延迟高、易被打垮 | 多级缓存优先 |
| 统计同步写库 | 跳转变慢 | 异步埋点与批量写入 |
| 短码长度估算不足 | 提前耗尽码空间 | 按年增量预留至少 10 倍余量 |
| 分片键设计不当 | 查询跨所有分片 | 按短码哈希分片并保证查询带短码 |
| 无限速与风控 | 被批量刷接口 | 按 IP 与用户限流，域名黑名单 |
| 不做过期回收 | 存储无限增长 | 支持 TTL 与归档 |
| 只压测跳转不压测写入 | 生成瓶颈上线才暴露 | 读写路径都压测 |

## 自测清单

- [ ] 短码方案兼顾唯一性、不可枚举与可扩展。
- [ ] 跳转走多级缓存，302 保留统计与改链能力。
- [ ] 统计埋点异步化，不阻塞跳转。
- [ ] 容量估算包含年增量与码空间余量。
- [ ] 有风控、限流与过期回收策略。
