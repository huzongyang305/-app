## 投递语义速查

| 语义 | 说明 | 消费者要求 |
| --- | --- | --- |
| 至多一次 | 可能丢消息，不重复 | 可接受丢失 |
| 至少一次 | 不丢，但可能重复 | 必须幂等 |
| 精确一次 | 端到端不丢不重 | 需要事务或幂等加去重 |

实践结论：**默认按至少一次设计，消费端保证幂等**，这是成本最低的可靠方案。

## 顺序与分区速查

| 需求 | 做法 |
| --- | --- |
| 同一业务顺序 | 用业务键作为分区键，保证同分区有序 |
| 全局顺序 | 代价极高，通常不需要 |
| 并发消费 | 分区数决定并行度上限 |
| 顺序与吞吐取舍 | 增大分区提升吞吐，但跨分区无序 |
| 重复消费 | 用业务唯一键去重 |
| 消息堆积 | 提升消费能力、增加分区、优化单条处理 |

```python
import hashlib
from collections import defaultdict
from dataclasses import dataclass, field

def partition_for(key: str, partitions: int) -> int:
    """按业务键分区：同一键永远落在同一分区，保证局部有序。"""
    digest = hashlib.md5(key.encode()).hexdigest()
    return int(digest, 16) % partitions

@dataclass
class IdempotentConsumer:
    """幂等消费者：用去重表保证重复消息不产生副作用。"""

    processed: set = field(default_factory=set)
    applied: list = field(default_factory=list)

    def handle(self, message_id: str, payload: dict) -> bool:
        if message_id in self.processed:
            return False                     # 重复消息直接跳过
        # 业务处理与去重记录应在同一事务中提交
        self.applied.append(payload)
        self.processed.add(message_id)
        return True

@dataclass
class RetryQueue:
    """重试与死信：超过次数进入死信队列并告警。"""

    max_attempts: int = 3
    counters: dict = field(default_factory=lambda: defaultdict(int))
    dead_letters: list = field(default_factory=list)

    def fail(self, message_id: str) -> str:
        self.counters[message_id] += 1
        if self.counters[message_id] >= self.max_attempts:
            self.dead_letters.append(message_id)
            return "dead_letter"
        return "retry"

consumer = IdempotentConsumer()
print(consumer.handle("m1", {"amount": 10}), consumer.handle("m1", {"amount": 10}))
print([partition_for(k, 4) for k in ["user-1", "user-1", "user-2"]])
queue = RetryQueue()
print([queue.fail("m2") for _ in range(3)])
```

## 事件设计速查

| 要点 | 做法 |
| --- | --- |
| 事件命名 | 用过去式描述已发生事实（`OrderPaid`） |
| 载荷 | 包含事件 ID、时间、业务键与必要字段 |
| 版本 | 事件结构带版本，向后兼容演进 |
| 大小 | 大对象存对象存储，消息只带引用 |
| 幂等键 | 事件 ID 或业务唯一键 |
| 顺序键 | 聚合根 ID 作为分区键 |
| 保留期 | 支持重放，按补数需求设置 |
| 死信 | 失败超限进入死信队列并告警 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 消费者不幂等 | 重试导致重复扣款 | 幂等键加去重表或唯一索引 |
| 位点先提交再处理 | 处理失败丢消息 | 处理成功后再提交位点 |
| 分区键随机 | 同一业务消息乱序 | 用业务键作分区键 |
| 无限重试 | 毒消息阻塞队列 | 限制次数并转死信 |
| 消息体过大 | 吞吐下降、超限失败 | 存对象存储，消息传引用 |
| 无死信告警 | 失败消息无人发现 | 死信监控与人工处理流程 |
| 事件用命令式命名 | 语义混乱 | 用过去式描述事实 |
| 无版本字段 | 演进时解析失败 | 事件带版本并保持兼容 |
| 消费无监控 | 积压不可见 | 监控积压、处理速率与失败率 |
| 依赖全局顺序 | 无法水平扩展 | 只保证同一聚合根有序 |

## 自测清单

- [ ] 消费端默认按至少一次设计并保证幂等。
- [ ] 同一业务键使用相同分区键保证局部有序。
- [ ] 位点在处理成功后提交。
- [ ] 有重试上限与死信队列告警。
- [ ] 事件结构带版本与幂等键，支持重放。
