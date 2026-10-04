## 端到端架构速查

| 层 | 组件 | 关键点 |
| --- | --- | --- |
| 接入 | 鉴权、限流、会话 | 用户与租户隔离 |
| 解析 | PDF、表格、图片 | 保留结构与页码 |
| 索引 | 分块、嵌入、向量库 | 元数据含权限与位置 |
| 检索 | 混合检索 + 重排 | 先过滤再打分 |
| 编排 | Agent 循环 + 工具 | 步数上限与超时 |
| 生成 | 提示 + 引用 | 只依据资料作答 |
| 评测 | 召回与作答分开 | 持续回归 |
| 观测 | 日志、指标、追踪 | 记录提示版本与轨迹 |

## 关键指标速查

| 指标 | 说明 | 目标示例 |
| --- | --- | --- |
| 检索 Recall@5 | 前 5 条是否含正确片段 | 大于 0.9 |
| 引用准确率 | 引用是否真的支持结论 | 大于 0.95 |
| 忠实度 | 回答是否只基于资料 | 大于 0.95 |
| 拒答正确率 | 资料不足时是否明确说明 | 大于 0.9 |
| 端到端 P95 延迟 | 从提问到首字 | 小于 3 秒 |
| 单次问答成本 | 平均 Token 费用 | 按预算设定 |

```python
from dataclasses import dataclass, field

@dataclass
class QAResult:
    question: str
    answer: str
    citations: list
    retrieved: int
    steps: int
    tokens: int
    latency_ms: float
    refused: bool = False

@dataclass
class ProjectMetrics:
    results: list = field(default_factory=list)

    def add(self, result: QAResult) -> None:
        self.results.append(result)

    def summary(self) -> dict:
        total = len(self.results)
        if not total:
            return {"cases": 0}
        with_citation = sum(1 for r in self.results if r.citations)
        latencies = sorted(r.latency_ms for r in self.results)
        return {
            "cases": total,
            "citation_rate": round(with_citation / total, 4),
            "refusal_rate": round(sum(r.refused for r in self.results) / total, 4),
            "avg_steps": round(sum(r.steps for r in self.results) / total, 2),
            "avg_tokens": round(sum(r.tokens for r in self.results) / total, 1),
            "p95_ms": latencies[int(total * 0.95) - 1],
        }

    def weak_cases(self, min_citations: int = 1) -> list:
        """挑出引用不足或步骤过多的用例，作为优化输入。"""
        return [
            r.question for r in self.results
            if len(r.citations) < min_citations or r.steps > 6
        ]


def answer_policy(retrieved: int, top_score: float, min_score: float = 0.35) -> str:
    """兜底策略：检索质量不足时直接拒答，避免编造。"""
    if retrieved == 0 or top_score < min_score:
        return "资料不足，建议补充文档或换个问法"
    return "正常作答并要求引用来源"


metrics = ProjectMetrics()
metrics.add(QAResult("报销标准是多少", "按 [1] 说明……", [1], 5, 3, 3200, 2100))
metrics.add(QAResult("明年预算", "无法从现有资料确认", [], 2, 2, 900, 800, refused=True))
print(metrics.summary())
print(metrics.weak_cases())
print(answer_policy(retrieved=0, top_score=0.0))
```

## 上线与运营速查

| 阶段 | 动作 |
| --- | --- |
| 内测 | 用评测集跑通，修复明显问题 |
| 灰度 | 小流量上线，观察指标与反馈 |
| 全量 | 达标后放量，保留回滚开关 |
| 运营 | 收集未命中问题，持续补文档与调参 |
| 迭代 | 提示、分块、模型分别独立实验 |
| 复盘 | 定期看坏例与成本趋势 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只调生成不看检索 | 优化无效 | 先测 Recall@K 定位瓶颈 |
| 检索无权限过滤 | 越权返回他人资料 | 检索阶段强制过滤 |
| 资料不足仍强行作答 | 幻觉 | 设置相似度阈值与拒答策略 |
| 无引用 | 无法核验 | 片段编号 + 引用校验 |
| 无步数上限 | 成本失控 | 限制步数与总 Token |
| 只做端到端评测 | 问题定位困难 | 召回与作答分别评测 |
| 不做坏例分析 | 问题反复出现 | 定期复盘 weak cases |
| 索引更新不及时 | 用户拿到旧答案 | 文档变更触发增量重建 |
| 没有回滚开关 | 出问题只能停服 | 支持一键切回上一版本 |
| 无成本监控 | 预算被突破 | 按租户与接口统计并告警 |

## 自测清单

- [ ] 架构覆盖解析、索引、检索、编排、生成、评测与观测。
- [ ] 检索与作答分别评测，能定位瓶颈。
- [ ] 有拒答策略、引用校验与权限过滤。
- [ ] 有步数与成本上限，支持灰度与回滚。
- [ ] 运营侧持续收集坏例并迭代文档与参数。
