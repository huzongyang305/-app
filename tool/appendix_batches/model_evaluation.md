## 选型维度速查

| 维度 | 关注点 | 权重示例 |
| --- | --- | --- |
| 任务质量 | 在你的评测集上的表现 | 40% |
| 成本 | 每千 Token 价格与实际用量 | 20% |
| 延迟 | P95 首 Token 与总时长 | 15% |
| 上下文长度 | 是否满足资料规模 | 10% |
| 工具与结构化输出 | 函数调用与 Schema 支持 | 10% |
| 合规与部署 | 数据出境、私有化能力 | 5% |
| 稳定性 | 限流、可用性与版本策略 | 附加项 |

## 评测集设计速查

| 要求 | 说明 |
| --- | --- |
| 来自真实流量 | 用线上请求构造，避免凭空想象 |
| 覆盖切片 | 按业务线、语言、长度、难度分层 |
| 答案可判定 | 有明确的标准答案或评分标准 |
| 保密 | 不进公开数据，避免污染 |
| 规模 | 每类至少数十条，关键场景上百条 |
| 可扩展 | 支持持续新增与版本管理 |
| 双向 | 含应该拒答与应该澄清的样例 |

```python
from dataclasses import dataclass, field

@dataclass
class ModelScore:
    name: str
    quality: float          # 0 到 1
    cost_per_1k: float      # 相对成本
    p95_latency_ms: float
    context_tokens: int
    tool_support: float     # 0 到 1
    compliance: float = 1.0

    def weighted(self, weights: dict) -> float:
        normalized_latency = 1 - min(1.0, self.p95_latency_ms / 5000)
        normalized_cost = 1 - min(1.0, self.cost_per_1k / 0.05)
        normalized_context = min(1.0, self.context_tokens / 200_000)
        parts = {
            "quality": self.quality,
            "cost": normalized_cost,
            "latency": normalized_latency,
            "context": normalized_context,
            "tool": self.tool_support,
            "compliance": self.compliance,
        }
        return round(sum(parts[key] * weights[key] for key in weights), 4)


WEIGHTS = {
    "quality": 0.40, "cost": 0.20, "latency": 0.15,
    "context": 0.10, "tool": 0.10, "compliance": 0.05,
}


def rank(models: list, weights: dict = WEIGHTS) -> list:
    scored = [(m, m.weighted(weights)) for m in models]
    return sorted(scored, key=lambda item: -item[1])


def equivalent_cost(input_tokens: int, output_tokens: int, in_price: float, out_price: float) -> float:
    """按真实用量算等效成本，比单价更有意义。"""
    return round(input_tokens / 1000 * in_price + output_tokens / 1000 * out_price, 6)


candidates = [
    ModelScore("model-a", 0.82, 0.010, 1200, 128_000, 0.9),
    ModelScore("model-b", 0.88, 0.030, 900, 200_000, 0.95),
    ModelScore("model-c", 0.75, 0.004, 1600, 64_000, 0.7),
]
print([(m.name, s) for m, s in rank(candidates)])
print(equivalent_cost(3000, 800, 0.01, 0.03))
```

## 公开基准的局限

| 局限 | 说明 |
| --- | --- |
| 数据污染 | 测试集可能进入训练数据 |
| 与业务无关 | 高分不代表适合你的任务 |
| 指标单一 | 忽略成本、延迟与安全 |
| 版本漂移 | 模型悄悄更新导致分数变化 |
| 可刷分 | 针对基准优化而非真实能力 |

结论：公开基准用于初筛，**最终决策必须基于自建评测集与线上灰度**。

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看公开榜单 | 上线后效果不符 | 自建评测集 + 灰度验证 |
| 只看单价 | 实际成本更高 | 用真实用量算等效成本 |
| 评测集与业务脱节 | 结论无参考价值 | 从真实请求构造 |
| 用测试集反复调参 | 指标虚高 | 划分验证与测试集 |
| 忽略拒答与澄清样例 | 上线后乱答 | 评测集包含应拒答用例 |
| 不看延迟分位 | 高并发下体验差 | 关注 P95 与首 Token 延迟 |
| 忽略合规与部署要求 | 无法落地 | 先过合规与部署门槛 |
| 模型静默升级不做回归 | 质量突变 | 固定版本并定期回归 |
| 只评估单一模型 | 错过更优组合 | 评估「小模型 + 升级路由」组合 |
| 不记录评测配置 | 结果不可复现 | 记录模型版本与参数 |

## 自测清单

- [ ] 选型以自建评测集为主，公开榜单仅作初筛。
- [ ] 成本用真实用量计算而非单价比较。
- [ ] 评测集来自真实流量且覆盖关键切片。
- [ ] 评测包含拒答、澄清与安全用例。
- [ ] 记录模型版本与参数，可复现、可回归。
