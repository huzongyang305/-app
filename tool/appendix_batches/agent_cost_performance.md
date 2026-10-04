## 成本构成速查

| 来源 | 说明 | 优化手段 |
| --- | --- | --- |
| 输入 Token | 系统提示 + 资料 + 历史 | 精简提示、前缀缓存、只传必要上下文 |
| 输出 Token | 生成内容 | 限制长度、要求结构化输出 |
| 多步循环 | 每步都调用模型 | 减少步数、并行化、合并调用 |
| 工具调用 | 外部 API 费用 | 缓存、批量、限流 |
| 重试 | 失败重试翻倍成本 | 只重试可恢复错误并设上限 |
| 检索 | 向量库与嵌入调用 | 缓存嵌入、批量更新 |

## 优化顺序速查

| 优先级 | 手段 | 典型收益 |
| --- | --- | --- |
| 1 | 减少无效步骤与重复调用 | 高 |
| 2 | 精简提示与上下文 | 高 |
| 3 | 前缀缓存与结果缓存 | 中高 |
| 4 | 小模型优先 + 大模型升级路由 | 中高 |
| 5 | 限制输出长度与格式 | 中 |
| 6 | 批量与并行 | 中 |
| 7 | 自建推理或量化部署 | 视规模而定 |

原则：**先降低无用消耗，再优化单价**。多数项目第一步能砍掉一半成本。

```python
from dataclasses import dataclass, field

@dataclass
class CallCost:
    model: str
    input_tokens: int
    output_tokens: int
    input_price: float = 0.003      # 每千 Token 单价示例
    output_price: float = 0.015

    @property
    def total(self) -> float:
        return (
            self.input_tokens / 1000 * self.input_price
            + self.output_tokens / 1000 * self.output_price
        )


@dataclass
class TaskCost:
    task_id: str
    calls: list = field(default_factory=list)
    cached_calls: int = 0

    def add(self, call: CallCost) -> None:
        self.calls.append(call)

    def total(self) -> float:
        return round(sum(call.total for call in self.calls), 6)

    def cache_hit_rate(self) -> float:
        total = len(self.calls) + self.cached_calls
        return round(self.cached_calls / total, 4) if total else 0.0

    def optimization_hint(self) -> str:
        if not self.calls:
            return "无调用记录"
        steps = len(self.calls)
        avg_output = sum(c.output_tokens for c in self.calls) / steps
        if steps > 6:
            return "步骤过多：检查是否可以合并或并行"
        if avg_output > 800:
            return "输出过长：限制长度并要求结构化输出"
        if self.cache_hit_rate() < 0.2:
            return "缓存命中偏低：考虑前缀缓存或结果缓存"
        return "成本结构合理"


task = TaskCost("t-1001")
task.add(CallCost("small", 800, 200))
task.add(CallCost("large", 4200, 1200))
print(round(task.total(), 5), task.cache_hit_rate(), task.optimization_hint())
```

## 性能压测速查

| 指标 | 说明 | 目标示例 |
| --- | --- | --- |
| 单任务 P50 / P95 延迟 | 端到端耗时 | P95 小于 8 秒 |
| 吞吐 | 每秒完成任务数 | 按容量规划 |
| 并发上限 | 同时可运行任务数 | 受下游配额限制 |
| 错误率 | 失败任务占比 | 小于 1% |
| 单任务成本 | 平均 Token 费用 | 按业务设定预算 |
| 工具失败率 | 外部依赖稳定性 | 小于 2% |

压测要点：用真实任务分布（不是全部简单请求）、固定模型与参数、逐步加压观察拐点，并同步监控下游配额与限流。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 先换小模型再优化提示 | 质量下降且没省钱 | 先减少无效步骤与精简上下文 |
| 只统计总费用 | 无法定位大头 | 按任务、租户、模型分别统计 |
| 无缓存直接扩容 | 成本线性增长 | 加前缀缓存与结果缓存 |
| 输出无长度限制 | Token 费用不可控 | 明确长度与结构化格式 |
| 无脑重试 | 失败成本翻倍 | 只重试可恢复错误并设上限 |
| 压测只用简单请求 | 结论偏乐观 | 按真实任务分布压测 |
| 忽略下游配额 | 高峰被限流 | 提前评估并为关键路径预留 |
| 缓存不设失效 | 结果过期 | 明确 TTL 与更新触发条件 |
| 路由规则写死 | 无法随场景演进 | 规则可配置并按评测调优 |
| 上线后不监控成本趋势 | 成本缓慢失控 | 设成本告警与预算上限 |

## 自测清单

- [ ] 成本按任务、模型与租户可归因。
- [ ] 优化顺序是「先减浪费，再降单价」。
- [ ] 有前缀缓存与结果缓存，并明确失效策略。
- [ ] 复杂请求才升级到大模型。
- [ ] 压测使用真实任务分布并设成本告警。
