## 方案对照速查

| 方案 | 一致性 | 复杂度 | 适用 |
| --- | --- | --- | --- |
| 2PC / XA | 强一致（阻塞式） | 中 | 少量短事务、同构数据库 |
| 3PC | 减少阻塞 | 高 | 少用 |
| TCC | 最终一致 | 高 | 资金、库存等需要预留的业务 |
| Saga | 最终一致 | 中 | 长流程、多服务编排 |
| 本地消息表 | 最终一致 | 低 | 业务与消息的一致性 |
| 事务消息 | 最终一致 | 中 | 支持事务消息的 MQ |
| 最大努力通知 | 最终一致 | 低 | 对账、通知类场景 |

## 共识算法速查

| 算法 | 容错 | 特点 |
| --- | --- | --- |
| Raft | n 个节点容忍 (n-1)/2 故障 | 易理解，主流选主与复制 |
| Paxos | 同上 | 理论经典，实现复杂 |
| ZAB | 同上 | ZooKeeper 使用 |
| 多数派写入 | 需要 ⌊n/2⌋+1 确认 | 保证不丢已提交数据 |

```python
from dataclasses import dataclass, field
from enum import Enum

class SagaStep(Enum):
    PENDING = "pending"
    DONE = "done"
    COMPENSATED = "compensated"

@dataclass
class Saga:
    """Saga 编排：正向依次执行，失败时逆序补偿。"""

    actions: list = field(default_factory=list)       # (名称, 执行函数, 补偿函数)
    executed: list = field(default_factory=list)

    def run(self, context):
        for name, action, compensate in self.actions:
            try:
                action(context)
                self.executed.append((name, compensate))
            except Exception as exc:
                print(f"[{name}] 失败：{exc}，开始补偿")
                self._compensate(context)
                raise
        return context

    def _compensate(self, context):
        while self.executed:
            name, compensate = self.executed.pop()
            try:
                compensate(context)                   # 补偿必须幂等
                print(f"[{name}] 已补偿")
            except Exception as exc:
                print(f"[{name}] 补偿失败，需人工介入：{exc}")


def tolerant_write(acks: int, nodes: int) -> bool:
    """判断写入确认数是否满足多数派。"""
    return acks >= nodes // 2 + 1


print(tolerant_write(2, 3), tolerant_write(1, 3))     # True False
```

## 幂等与对账速查

| 手段 | 说明 |
| --- | --- |
| 幂等键 | 客户端生成唯一 ID，服务端去重表保证只执行一次 |
| 状态机 | 只允许合法状态迁移，重复请求直接返回 |
| 唯一索引 | 数据库层面兜底防重复 |
| 去重表 | 记录已处理的业务 ID 与结果 |
| 对账任务 | 定时比对双方数据，修复差异 |
| 补偿重试 | 指数退避 + 最大次数 + 告警 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 2PC 处理长事务 | 资源长时间被锁 | 长流程用 Saga 或 TCC |
| 补偿逻辑不幂等 | 重试导致重复退款 | 补偿必须可重复执行 |
| 没有对账机制 | 差异长期积累 | 定期对账并自动修复 |
| 只重试不设上限 | 故障放大 | 指数退避 + 上限 + 告警 |
| 忽略悬挂（空补偿） | 补偿先于正向执行到达 | 用状态机与唯一 ID 防悬挂 |
| 认为最终一致不需要设计 | 用户看到中间态异常 | 前端做状态提示与轮询 |
| 单点协调者无高可用 | 协调者挂掉流程卡住 | 协调者集群化并持久化状态 |
| 不记录流程日志 | 失败后无法定位到哪一步 | 每步记录状态与上下文 |
| 混用多种一致性方案无文档 | 维护困难、结论冲突 | 统一方案并写清边界 |
| 忽略时钟依赖 | 顺序判断出错 | 用逻辑时间或服务端序号 |

## 自测清单

- [ ] 能按业务选择 2PC / TCC / Saga / 本地消息表。
- [ ] 所有补偿与重试都保证幂等。
- [ ] 有对账与差异修复机制。
- [ ] 处理空补偿与悬挂问题。
- [ ] 分布式事务流程有完整日志与人工兜底入口。
