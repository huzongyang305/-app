## 可用性速查

| 可用性 | 年停机时间 | 说明 |
| --- | --- | --- |
| 99% | 约 3.65 天 | 不可用于核心业务 |
| 99.9% | 约 8.76 小时 | 基础要求 |
| 99.95% | 约 4.38 小时 | 常见生产目标 |
| 99.99% | 约 52.6 分钟 | 高可用要求 |
| 99.999% | 约 5.26 分钟 | 极高要求、成本陡增 |

串行依赖的可用性相乘：`A_total = A1 × A2 × ... × An`。三个 99.9% 串起来只有约 99.7%，这就是**必须缩短同步链路**的原因。

## 容错手段速查

| 手段 | 作用 | 代价 |
| --- | --- | --- |
| 冗余部署 | 单实例故障不影响 | 资源成本 |
| 无状态化 | 便于水平扩展 | 状态需外置 |
| 限流 | 保护自身与下游 | 部分请求被拒 |
| 熔断 | 快速失败避免堆积 | 功能降级 |
| 降级 | 保核心功能 | 体验下降 |
| 隔离 | 故障不扩散 | 资源利用率下降 |
| 重试加幂等 | 处理瞬时故障 | 需幂等设计 |
| 多活与多机房 | 抗机房级故障 | 数据一致性复杂 |
| 混沌演练 | 验证假设 | 需要安全边界 |

```python
from dataclasses import dataclass, field
import math

def availability_chain(availabilities: list) -> float:
    """串行依赖的总体可用性。"""
    result = 1.0
    for value in availabilities:
        result = result * value
    return round(result, 6)

def availability_parallel(availabilities: list) -> float:
    """并行冗余的可用性：1 减去全部同时故障的概率。"""
    failure = 1.0
    for value in availabilities:
        failure = failure * (1 - value)
    return round(1 - failure, 6)

@dataclass
class CapacityPlan:
    """容量规划：峰值流量加冗余系数，估算所需实例数。"""

    peak_qps: float
    qps_per_instance: float
    redundancy: float = 1.5      # 预留突发、故障摘除与发布余量

    def instances(self) -> int:
        required = self.peak_qps * self.redundancy / self.qps_per_instance
        return max(2, math.ceil(required))     # 至少 2 个避免单点

    def fault_tolerance(self) -> int:
        """按 N+1 冗余，可容忍同时故障的实例数。"""
        return max(0, self.instances() - 1)

@dataclass
class ErrorBudget:
    """错误预算：耗尽即冻结变更。"""

    slo: float = 0.999
    total_requests: int = 0
    bad_requests: int = 0
    events: list = field(default_factory=list)

    def record(self, bad: bool) -> None:
        self.total_requests += 1
        if bad:
            self.bad_requests += 1

    def remaining_ratio(self) -> float:
        allowed = 1 - self.slo
        used = self.bad_requests / self.total_requests if self.total_requests else 0.0
        return round(max(0.0, 1 - used / allowed), 4)

    def policy(self) -> str:
        remaining = self.remaining_ratio()
        if remaining <= 0:
            return "冻结变更，优先恢复可靠性"
        if remaining < 0.25:
            return "仅允许修复类变更"
        return "正常运行"

print(availability_chain([0.999, 0.999, 0.999]))
print(availability_parallel([0.99, 0.99]))
print(CapacityPlan(peak_qps=1200, qps_per_instance=150).instances())
budget = ErrorBudget()
for i in range(1000):
    budget.record(bad=i < 3)
print(budget.remaining_ratio(), budget.policy())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把可用性目标写在文档里 | 无实际作用 | 定义 SLO 与错误预算并执行策略 |
| 忽略串行依赖相乘 | 高估整体可用性 | 缩短链路、并行化、加缓存 |
| 只做冗余不做演练 | 故障切换失败 | 定期故障注入验证 |
| 无状态服务存本地状态 | 扩容后行为不一致 | 状态外置到共享存储 |
| 无限流与熔断 | 雪崩 | 全链路限流与熔断 |
| 单实例数据库 | 单点故障 | 主从或集群加备份 |
| 只规划平均流量 | 峰值被打垮 | 按峰值加冗余系数规划 |
| 重试无退避 | 重试风暴 | 指数退避加抖动 |
| 多活不做冲突方案 | 数据错乱 | 明确冲突解决策略 |
| 不做容量压测 | 上线后发现容量不足 | 按峰值压测并留余量 |

## 自测清单

- [ ] 有明确 SLO 与错误预算策略。
- [ ] 知道串行依赖会放大故障率，并尽量缩短链路。
- [ ] 容量按峰值与冗余系数规划，至少 N+1。
- [ ] 全链路有限流、熔断、降级与隔离。
- [ ] 定期做故障注入与切换演练。
