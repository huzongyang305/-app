## 四层与七层对照

| 维度 | 四层（L4） | 七层（L7） |
| --- | --- | --- |
| 依据 | IP + 端口 | URL、Header、Cookie |
| 性能 | 更高、延迟更低 | 略低但功能强 |
| 能力 | 转发、连接保持 | 路由、鉴权、改写、限流 |
| 典型 | LVS、NLB | Nginx、Envoy、ALB |
| TLS | 透传或终止 | 终止并可做内容检查 |

## 负载均衡算法速查

| 算法 | 特点 | 适用 |
| --- | --- | --- |
| 轮询 | 简单均匀 | 后端同质 |
| 加权轮询 | 按能力分配 | 机器规格不同 |
| 最少连接 | 按当前负载 | 请求耗时差异大 |
| 一致性哈希 | 同一 key 固定后端 | 缓存命中与有状态服务 |
| 最短响应时间 | 按实测延迟 | 延迟敏感 |
| 随机 | 实现简单 | 后端数量多且同质 |

## 弹性策略速查

| 策略 | 作用 | 关键参数 |
| --- | --- | --- |
| 超时 | 防止无限等待 | 连接、读写分开设置 |
| 重试 | 处理瞬时故障 | 仅幂等、退避、上限 |
| 熔断 | 快速失败保护下游 | 错误率阈值、半开探测 |
| 限流 | 保护自身与下游 | 令牌桶、按用户维度 |
| 降级 | 保核心功能 | 返回缓存或默认值 |
| 隔离 | 防相互影响 | 线程池或连接池隔离 |

```python
import time
from collections import deque
from dataclasses import dataclass, field
from enum import Enum

class State(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

@dataclass
class CircuitBreaker:
    """熔断器：连续失败打开，冷却后放少量请求探测。"""

    failure_threshold: int = 5
    cooldown_seconds: float = 10.0
    half_open_probes: int = 3
    state: State = State.CLOSED
    failures: int = 0
    probes: int = 0
    opened_at: float = 0.0

    def allow(self, now: float | None = None) -> bool:
        now = time.monotonic() if now is None else now
        if self.state is State.OPEN:
            if now - self.opened_at >= self.cooldown_seconds:
                self.state = State.HALF_OPEN
                self.probes = 0
            else:
                return False
        if self.state is State.HALF_OPEN and self.probes >= self.half_open_probes:
            return False
        return True

    def record(self, success: bool, now: float | None = None) -> None:
        now = time.monotonic() if now is None else now
        if success:
            if self.state is State.HALF_OPEN:
                self.state = State.CLOSED
                self.failures = 0
            else:
                self.failures = 0
            return
        if self.state is State.HALF_OPEN:
            self.probes += 1
            self.state = State.OPEN
            self.opened_at = now
            return
        self.failures += 1
        if self.failures >= self.failure_threshold:
            self.state = State.OPEN
            self.opened_at = now

@dataclass
class Backoff:
    """指数退避 + 抖动，避免重试风暴。"""

    base: float = 0.1
    factor: float = 2.0
    max_delay: float = 5.0
    history: deque = field(default_factory=lambda: deque(maxlen=32))

    def next_delay(self, attempt: int, jitter: float = 0.3) -> float:
        delay = min(self.max_delay, self.base * (self.factor ** attempt))
        return round(delay * (1 + jitter * ((attempt % 3) - 1)), 4)

breaker = CircuitBreaker()
for _ in range(6):
    breaker.record(False)
print(breaker.state, breaker.allow())
print([Backoff().next_delay(i) for i in range(5)])
```

## 发布与下线速查

| 阶段 | 动作 |
| --- | --- |
| 预热 | 新实例先接少量流量 |
| 就绪检查 | 通过后才注册到负载均衡 |
| 灰度 | 按比例放量并观察指标 |
| 下线 | 先从负载均衡摘除，再等在途请求结束 |
| 回滚 | 指标异常立即切回上一版本 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 重试非幂等请求 | 重复下单或扣款 | 只重试幂等方法，或用幂等键 |
| 重试无退避 | 故障放大 | 指数退避 + 抖动 + 上限 |
| 超时设置过长 | 线程与连接被占满 | 连接与读取超时分开设 |
| 熔断无半开探测 | 恢复后仍不可用 | 冷却后放少量探测请求 |
| 下线直接杀进程 | 用户看到 502 | 先摘流量再等在途结束 |
| 一致性哈希无虚拟节点 | 数据倾斜 | 加虚拟节点或调权重 |
| 限流只按 IP | NAT 后误伤 | 叠加用户与接口维度 |
| 忽略健康检查频率 | 故障实例仍接流量 | 合理间隔 + 连续失败阈值 |
| 所有服务共用一个连接池 | 相互影响 | 按依赖隔离 |
| 无灰度直接全量 | 故障影响全站 | 灰度 + 自动回滚 |

## 自测清单

- [ ] 能按需求选择四层或七层网关。
- [ ] 负载均衡算法与后端特性匹配。
- [ ] 重试仅用于幂等请求且有退避上限。
- [ ] 熔断、限流、降级、隔离策略齐备。
- [ ] 发布与下线都有优雅过渡。
