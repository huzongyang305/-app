## 补充：令牌桶实现、分布式限流与熔断参数

### 令牌桶的最小实现

```python
import time

class TokenBucket:
    """按固定速率补充令牌，允许一定突发（桶容量）。"""

    def __init__(self, rate: float, capacity: int) -> None:
        self.rate = rate              # 每秒补充多少令牌
        self.capacity = capacity      # 桶容量 = 允许的最大突发
        self.tokens = float(capacity)
        self.updated = time.monotonic()

    def allow(self, cost: int = 1) -> bool:
        now = time.monotonic()
        self.tokens = min(self.capacity, self.tokens + (now - self.updated) * self.rate)
        self.updated = now
        if self.tokens >= cost:
            self.tokens -= cost
            return True
        return False
```

| 参数 | 含义 | 取值建议 |
| --- | --- | --- |
| rate | 长期平均速率 | 按下游承载能力设定 |
| capacity | 允许的突发量 | 通常为 rate 的 1~2 倍 |
| cost | 单次消耗 | 重接口可设为 2~5，实现按成本限流 |

### 分布式限流：Redis + Lua

```lua
-- 固定窗口计数器：原子地自增并在首次设置过期时间
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])

local current = redis.call('INCR', key)
if current == 1 then
  redis.call('EXPIRE', key, window)
end
if current > limit then
  return 0
end
return 1
```

```text
为什么必须用 Lua
  · INCR 与 EXPIRE 分开执行会产生竞态：可能只自增而没设过期，key 永久驻留
  · Lua 脚本在 Redis 中原子执行，避免这个问题

本地限流 + 全局限流的组合
  ① 每个实例先做本地令牌桶（挡住突发、零网络开销）
  ② 再查一次全局配额（保证总量不超）
  ③ 全局存储不可用时降级为纯本地限流，保证服务不被打垮
```

### 限流维度的选择

| 维度 | 适用 | 风险 |
| --- | --- | --- |
| 用户 ID | 防单用户刷接口 | 未登录用户需要 IP 兜底 |
| IP | 防爬虫与攻击 | NAT 环境下会误伤整栋楼 |
| 接口 + 租户 | 多租户 SaaS | 需要租户标识透传 |
| 全局 | 保护脆弱下游 | 一个热点接口会拖累全部 |

**推荐组合**：用户维度 + 接口维度，并对未登录请求使用 IP 维度兜底。

### 熔断参数怎么定

| 参数 | 含义 | 建议初值 | 调整方向 |
| --- | --- | --- | --- |
| 统计窗口 | 多久滚动一次 | 10 秒 | 抖动大就拉长 |
| 最小请求数 | 样本门槛 | 20 | 流量小就降低 |
| 失败率阈值 | 触发打开 | 50% | 核心链路可降到 30% |
| 冷却时间 | 打开后等多久试探 | 10~30 秒 | 下游恢复慢就拉长 |
| 半开试探数 | 允许通过的请求 | 3~5 | 保守取小 |

```text
必须同时配置的三件事
  · 超时：没有超时，熔断只是等死
  · 重试：只对幂等接口重试，并限制次数 + 退避
  · 降级：熔断打开时返回什么（缓存值 / 默认值 / 友好提示）
```

### 降级开关的设计

```text
要求
  · 能在不发布的情况下动态开关（配置中心或数据库）
  · 开关粒度到「功能」，而不是全局总开关
  · 默认值安全：拿不到配置时按「关闭非核心功能」处理

优先级（越靠前越核心，降级时从后往前关）
  支付 > 下单 > 浏览 > 搜索 > 推荐 > 评论
```

### 自查清单

- [ ] 限流有明确的维度与阈值，而不是全局一把梭
- [ ] 分布式限流用 Lua 保证原子性
- [ ] 全局存储不可用时有本地降级方案
- [ ] 每个下游都配置了超时与熔断
- [ ] 降级开关可动态生效，且按业务优先级分级

