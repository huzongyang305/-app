## 核心定理速查

| 定理 | 结论 | 实践含义 |
| --- | --- | --- |
| CAP | 分区发生时只能在一致性与可用性之间取舍 | 网络分区必然发生，先决定 CP 还是 AP |
| BASE | 基本可用、软状态、最终一致 | 放弃强一致换可用与扩展 |
| 利特尔法则 | 并发 = 吞吐 × 延迟 | 容量与延迟互相约束 |
| 拜占庭容错 | 容忍恶意节点需 3f+1 个节点 | 区块链类场景 |
| 多数派 | 需要 ⌊n/2⌋+1 确认 | 保证已提交数据不丢 |

## 一致性与复制速查

| 模式 | 特点 | 适用 |
| --- | --- | --- |
| 同步复制 | 主从都确认才返回 | 强一致、延迟高 |
| 半同步复制 | 至少一个从库确认 | 平衡方案 |
| 异步复制 | 主库返回后异步同步 | 延迟低、可能丢数据 |
| 读己之写 | 保证用户看到自己的写入 | 用户体验关键路径 |
| 单调读 | 不会读到更旧的数据 | 避免时间倒流 |
| 因果一致 | 保持因果关系 | 评论与回复场景 |

```python
import time
from dataclasses import dataclass, field

def quorum(n: int, level: str = "majority") -> int:
    """多数派数量：n 个副本需要多少确认。"""
    if level == "majority":
        return n // 2 + 1
    if level == "all":
        return n
    if level == "one":
        return 1
    raise ValueError("不支持的级别")

def read_your_writes_ok(write_quorum: int, read_quorum: int, replicas: int) -> bool:
    """读写法定人数有交集才能读到最新写入。"""
    return write_quorum + read_quorum > replicas

@dataclass
class RetryPolicy:
    """重试策略：指数退避 + 抖动 + 上限，避免重试风暴。"""

    base: float = 0.05
    factor: float = 2.0
    max_attempts: int = 5
    max_delay: float = 3.0
    attempts: int = 0

    def can_retry(self) -> bool:
        return self.attempts < self.max_attempts

    def next_delay(self) -> float:
        delay = min(self.max_delay, self.base * (self.factor ** self.attempts))
        self.attempts += 1
        jitter = 0.5 + (self.attempts % 3) * 0.25      # 简单抖动
        return round(delay * jitter, 4)

def idempotency_key(user_id: str, request_id: str) -> str:
    """幂等键：同一业务请求重试时保持稳定，用于服务端去重。"""
    return f"{user_id}:{request_id}"

print(quorum(3), read_your_writes_ok(2, 2, 3))
policy = RetryPolicy()
print([policy.next_delay() for _ in range(3)])
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 假设网络可靠 | 偶发超时导致状态不一致 | 一切远程调用都要超时、重试与幂等 |
| 假设时钟同步 | 事件顺序错乱 | 用逻辑时钟或服务端序号 |
| 用本地事务处理跨服务写入 | 部分成功 | 用 Saga、TCC 或本地消息表 |
| 无限重试 | 故障放大 | 退避 + 上限 + 熔断 |
| 重试非幂等写操作 | 重复下单扣款 | 幂等键 + 唯一索引 |
| 只做读写分离不做延迟处理 | 读到自己刚写的数据缺失 | 关键路径读主库或加等待 |
| 认为最终一致不需要设计 | 用户看到中间态异常 | 前端状态提示 + 补偿任务 |
| 无对账机制 | 差异长期存在 | 定期对账 + 自动修复 |
| 单点协调者 | 协调者故障流程卡住 | 协调者高可用 + 状态持久化 |
| 不做压测与故障演练 | 真故障时手忙脚乱 | 混沌演练 + 定期故障注入 |

## 自测清单

- [ ] 能解释 CAP 与 BASE 的取舍及对业务的影响。
- [ ] 远程调用一律有超时、重试上限与幂等保证。
- [ ] 跨服务一致性方案明确（Saga/TCC/本地消息表）。
- [ ] 有对账与补偿机制处理最终一致。
- [ ] 定期做故障演练验证假设。
