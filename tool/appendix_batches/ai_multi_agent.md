## 拓扑模式对照

| 模式 | 结构 | 优点 | 缺点 |
| --- | --- | --- | --- |
| 单 Agent | 一个循环 + 工具 | 简单可控、成本低 | 复杂任务容易失控 |
| 主管（Supervisor） | 一个协调者分派 | 流程清晰、易观测 | 主管成瓶颈 |
| 流水线（Pipeline） | 固定阶段串联 | 可预测、易测试 | 不够灵活 |
| 辩论（Debate） | 多角色互评 | 提升推理质量 | 成本高、可能不收敛 |
| 群体（Swarm） | 动态交接 | 灵活 | 难以调试与限流 |
| 层级（Hierarchical） | 多层主管 | 支持超大任务 | 状态传递复杂 |

经验法则：**先尝试单 Agent + 好工具；只有当职责确实可分离、且并行能带来明显收益时才引入多智能体。**

## 角色分工速查

| 角色 | 职责 | 输出 |
| --- | --- | --- |
| 规划者 | 拆解任务与顺序 | 步骤清单 |
| 执行者 | 调用工具完成任务 | 结果与证据 |
| 评审者 | 检查正确性与完整性 | 通过或修改意见 |
| 汇总者 | 整合结果与格式化 | 最终答复 |
| 守卫者 | 检查安全与合规 | 拦截或放行 |

```python
from dataclasses import dataclass, field
from enum import Enum

class Status(Enum):
    OK = "ok"
    NEEDS_FIX = "needs_fix"
    BLOCKED = "blocked"

@dataclass
class Handoff:
    """Agent 之间的结构化交接：只传结论与证据，不传完整对话。"""

    task: str
    summary: str
    artifacts: dict
    open_questions: list = field(default_factory=list)
    step: int = 0


@dataclass
class Orchestrator:
    """主管模式：限制最大步数、防止循环、汇总成本。"""

    max_steps: int = 8
    steps: int = 0
    history: list = field(default_factory=list)

    def can_continue(self) -> bool:
        return self.steps < self.max_steps

    def dispatch(self, handoff: Handoff, worker) -> Handoff:
        if not self.can_continue():
            raise RuntimeError("超过最大步数，交由人工处理")
        self.steps += 1
        result = worker(handoff)
        self.history.append({"task": handoff.task, "status": result.artifacts.get("status")})
        return result

    def detect_loop(self, window: int = 3) -> bool:
        """连续多次相同任务视为循环，需要打断。"""
        if len(self.history) < window:
            return False
        recent = [item["task"] for item in self.history[-window:]]
        return len(set(recent)) == 1


def planner(handoff: Handoff) -> Handoff:
    return Handoff(
        task="规划",
        summary="拆成三步：检索、计算、汇总",
        artifacts={"status": Status.OK.value, "plan": ["检索", "计算", "汇总"]},
    )


orch = Orchestrator()
print(orch.dispatch(Handoff("分析销售数据", "", {}), planner).artifacts["plan"])
print(orch.detect_loop())
```

## 通信与状态速查

| 问题 | 做法 |
| --- | --- |
| 上下文膨胀 | 只传摘要与结构化结果 |
| 任务重复 | 用任务 ID 去重，记录已完成步骤 |
| 无限循环 | 最大步数 + 相同动作检测 + 超时 |
| 责任不清 | 每个角色有明确输入输出契约 |
| 结果冲突 | 设裁决规则（评审优先或投票） |
| 成本失控 | 每步记录 Token 与耗时，设总预算 |
| 可观测性 | 记录每次交接的输入、输出与决策 |
| 失败恢复 | 保存中间产物，支持从某步重跑 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 一上来就上多智能体 | 复杂度高、效果不如单 Agent | 先用单 Agent + 好工具验证 |
| Agent 之间传完整对话 | 上下文爆炸、成本翻倍 | 传摘要与结构化产物 |
| 没有步数上限 | 无限循环烧钱 | 设最大步数与总预算 |
| 角色职责重叠 | 相互推诿或重复劳动 | 明确输入输出契约 |
| 无裁决机制 | 意见冲突无法收敛 | 设评审优先或投票规则 |
| 不做中间产物持久化 | 失败后全部重跑 | 保存每步产物与状态 |
| 不记录交接轨迹 | 出问题无法定位 | 记录每次交接的决策依据 |
| 依赖单一模型 | 单点故障 | 关键角色支持模型降级切换 |
| 让 Agent 直接改生产数据 | 事故风险 | 写操作必须人工确认或灰度 |
| 忽略并行收益评估 | 成本翻倍但没提速 | 先测串行与并行的实际差异 |

## 自测清单

- [ ] 能说明何时才需要多智能体（职责可分离 + 并行有收益）。
- [ ] Agent 之间只传摘要与结构化结果。
- [ ] 有最大步数、循环检测与总预算限制。
- [ ] 每个角色有明确输入输出契约与裁决规则。
- [ ] 交接轨迹与中间产物可持久化、可重跑。
