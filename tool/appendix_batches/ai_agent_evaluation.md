## 评测维度速查

| 维度 | 指标 | 说明 |
| --- | --- | --- |
| 结果正确性 | 任务成功率 | 是否达成目标 |
| 轨迹合理性 | 步数、无效调用率 | 是否绕路、重复调用 |
| 工具使用 | 调用成功率、参数正确率 | 工具层能力 |
| 效率 | Token 成本、耗时 | 与成功率一起看 |
| 稳定性 | 多次运行方差 | 是否随机失败 |
| 安全性 | 越权与危险操作次数 | 必须为零容忍 |
| 用户体验 | 澄清次数、可读性 | 人工评分 |

## 评测集设计速查

| 类型 | 占比建议 | 例子 |
| --- | --- | --- |
| 典型任务 | 50% | 日常高频请求 |
| 边界输入 | 20% | 空输入、超长输入 |
| 对抗样例 | 15% | 提示注入、诱导越权 |
| 工具失败 | 10% | 超时、返回异常 |
| 未见场景 | 5% | 检验泛化 |

```python
from dataclasses import dataclass, field

@dataclass
class RunRecord:
    case_id: str
    success: bool
    steps: int
    tool_calls: int
    failed_tool_calls: int
    tokens: int
    latency_ms: float
    unsafe: bool = False

@dataclass
class Evaluation:
    records: list = field(default_factory=list)

    def add(self, record: RunRecord) -> None:
        self.records.append(record)

    def summary(self) -> dict:
        total = len(self.records)
        if total == 0:
            return {"cases": 0}
        latencies = sorted(r.latency_ms for r in self.records)
        return {
            "cases": total,
            "success_rate": round(sum(r.success for r in self.records) / total, 4),
            "avg_steps": round(sum(r.steps for r in self.records) / total, 2),
            "tool_error_rate": round(
                sum(r.failed_tool_calls for r in self.records)
                / max(1, sum(r.tool_calls for r in self.records)), 4
            ),
            "avg_tokens": round(sum(r.tokens for r in self.records) / total, 1),
            "p95_ms": latencies[int(total * 0.95) - 1],
            "unsafe_cases": sum(r.unsafe for r in self.records),
        }

    def regressions(self, baseline: "Evaluation") -> list:
        """对比基线，找出由通过变为失败的用例。"""
        before = {r.case_id: r.success for r in baseline.records}
        return [
            r.case_id for r in self.records
            if before.get(r.case_id, True) and not r.success
        ]


eval_run = Evaluation()
eval_run.add(RunRecord("t1", True, 4, 3, 0, 5200, 3100))
eval_run.add(RunRecord("t2", False, 8, 7, 2, 12800, 9100, unsafe=False))
print(eval_run.summary())
```

## LLM-as-Judge 速查

| 偏差 | 表现 | 缓解 |
| --- | --- | --- |
| 位置偏差 | 偏好靠前的答案 | 交换顺序各评一次取平均 |
| 长度偏差 | 偏好更长的回答 | 在评分标准中约束长度 |
| 自我偏好 | 偏好同族模型的输出 | 用多个不同评委 |
| 标准漂移 | 不同批次分数不可比 | 固定评分标准与校准样例 |
| 宽松倾向 | 分数普遍偏高 | 引入明确的反例与扣分项 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看最终答案 | 忽略危险操作与绕路 | 同时评测轨迹与工具调用 |
| 评测集与线上分布不符 | 上线后效果差 | 用真实流量构造评测集 |
| 用例太少 | 结论不可靠 | 每个维度至少数十条 |
| 用同一模型自评 | 分数虚高 | 多评委 + 人工抽检 |
| 改提示后不回归 | 悄悄退化 | 每次改动跑完整评测 |
| 只统计平均 | 掩盖长尾 | 报告 P95 与最差用例 |
| 不固定随机性 | 结果无法比较 | 固定 seed 或多次运行取分布 |
| 忽略成本与延迟 | 质量提升但不可用 | 成功率与成本一起看 |
| 无安全用例 | 越权无人发现 | 对抗样例纳入必测 |
| 评测结果不入库 | 无法追踪趋势 | 结果与配置版本一起保存 |

## 自测清单

- [ ] 评测覆盖结果、轨迹、工具、成本与安全。
- [ ] 评测集含典型、边界、对抗与工具失败场景。
- [ ] 每次提示或模型变更都跑回归并对比基线。
- [ ] 使用多评委并缓解位置与长度偏差。
- [ ] 评测结果与配置版本一起入库可追溯。
