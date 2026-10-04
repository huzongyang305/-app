## 三大支柱速查

| 支柱 | 内容 | 回答的问题 | 成本 |
| --- | --- | --- | --- |
| 指标（Metrics） | 数值型聚合 | 现在健康吗 | 低 |
| 日志（Logs） | 事件明细 | 到底发生了什么 | 高 |
| 链路（Traces） | 请求调用树 | 慢在哪一环 | 中 |

## 方法论速查

| 方法 | 关注点 | 指标 |
| --- | --- | --- |
| RED | 服务视角 | 请求速率、错误率、耗时 |
| USE | 资源视角 | 利用率、饱和度、错误 |
| 四个黄金信号 | 综合 | 延迟、流量、错误、饱和度 |

| 信号 | 说明 |
| --- | --- |
| 流量 | QPS 或每秒事件数 |
| 延迟 | P50 / P95 / P99，区分成功与失败 |
| 错误 | 显式错误与隐式错误（如返回 200 但内容错误） |
| 饱和度 | 队列长度、CPU 排队、连接池占用 |

```python
from dataclasses import dataclass, field

def percentile(values: list, p: float) -> float:
    """分位数计算，报表口径统一。"""
    if not values:
        raise ValueError("空集合")
    ordered = sorted(values)
    if len(ordered) == 1:
        return float(ordered[0])
    position = (len(ordered) - 1) * p
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1 - weight) + ordered[upper] * weight

@dataclass
class SloWindow:
    """SLO 与错误预算：用滑动窗口评估达标情况。"""

    target: float                 # 例如 0.999
    total: int = 0
    bad: int = 0
    samples: list = field(default_factory=list)

    def record(self, latency_ms: float, error: bool, threshold_ms: float = 300) -> None:
        self.total += 1
        if error or latency_ms > threshold_ms:
            self.bad += 1
        self.samples.append(latency_ms)

    @property
    def availability(self) -> float:
        return 1.0 if self.total == 0 else round(1 - self.bad / self.total, 6)

    def error_budget_left(self) -> float:
        """剩余错误预算比例：耗尽意味着要冻结变更。"""
        allowed = 1 - self.target
        used_ratio = (self.bad / self.total) / allowed if self.total else 0.0
        return round(max(0.0, 1 - used_ratio), 4)

    def report(self) -> dict:
        return {
            "availability": self.availability,
            "target": self.target,
            "error_budget_left": self.error_budget_left(),
            "p95_ms": round(percentile(self.samples, 0.95), 2) if self.samples else 0,
            "total": self.total,
        }

window = SloWindow(target=0.999)
for latency in [120, 150, 200, 900, 130]:
    window.record(latency, error=False, threshold_ms=300)
print(window.report())
```

## 告警设计速查

| 原则 | 说明 |
| --- | --- |
| 面向症状 | 告警用户可感知的问题，而非单个指标 |
| 基于 SLO | 用错误预算消耗速率触发 |
| 可执行 | 每条告警都有明确处理步骤 |
| 分级 | P1 立即处理、P2 当日、P3 观察 |
| 降噪 | 合并同类告警，抑制抖动 |
| 防疲劳 | 定期清理长期无效告警 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只加日志不做指标 | 无法实时发现问题 | 指标告警 + 日志定位 |
| 平均延迟当唯一指标 | 长尾被掩盖 | 用 P95/P99 与错误率 |
| 指标维度太高 | 存储与查询成本爆炸 | 控制标签基数 |
| 告警基于单点阈值 | 频繁误报 | 用持续时长与错误预算 |
| 采样率过高 | 成本失控 | 按级别采样，错误全采 |
| 日志不带 trace ID | 无法串联 | 全链路透传 |
| 只监控基础设施 | 业务问题漏掉 | 加业务指标与关键路径 |
| 无 SLO | 无法判断是否该发版 | 定义 SLO 与错误预算策略 |
| 告警无处理手册 | 收到后不知做什么 | 每条告警配 runbook |
| 不清理旧告警 | 告警疲劳 | 定期评审删减 |

## 自测清单

- [ ] 指标、日志、链路三者齐备并互相引用。
- [ ] 延迟报告使用分位数而非平均值。
- [ ] 定义了 SLO 与错误预算，并据此决定变更节奏。
- [ ] 告警面向症状、可执行且有分级。
- [ ] 标签基数与采样策略受控。
