## 应用分层速查

| 层 | 职责 | 关键点 |
| --- | --- | --- |
| 接入层 | 鉴权、限流、参数校验 | 防止滥用与注入 |
| 编排层 | 提示组装、工具调度、重试 | 版本化与可观测 |
| 模型层 | 调用与降级 | 多模型路由与超时 |
| 检索层 | 向量与关键词检索 | 权限过滤与重排 |
| 数据层 | 会话、反馈、评测集 | 可追溯、可回放 |
| 观测层 | 日志、指标、追踪 | 提示版本与 Token 用量 |

## 可靠性与成本速查

| 关注点 | 手段 |
| --- | --- |
| 超时 | 按模型设请求超时，避免线程被长期占用 |
| 重试 | 只对可重试错误，指数退避 + 上限 |
| 降级 | 主模型失败切备用模型或规则兜底 |
| 限流 | 按用户与租户配额，防单点滥用 |
| 缓存 | 相同请求缓存结果，注意个性化与时效 |
| 幂等 | 写操作带幂等键 |
| 成本 | 记录每次调用的 Token 与费用，按租户汇总 |
| 质量 | 离线评测 + 线上灰度 + 人工抽检 |

```python
import time
from dataclasses import dataclass, field

@dataclass
class ModelCall:
    model: str
    prompt_tokens: int
    completion_tokens: int
    latency_ms: float
    success: bool = True

    def cost(self, price_per_1k_in: float, price_per_1k_out: float) -> float:
        return (
            self.prompt_tokens / 1000 * price_per_1k_in
            + self.completion_tokens / 1000 * price_per_1k_out
        )


@dataclass
class ModelRouter:
    """按难度路由：简单请求走小模型，复杂请求升级到大模型。"""

    small: str = "small-model"
    large: str = "large-model"
    complex_keywords: tuple = ("分析", "推理", "代码", "多步")

    def choose(self, prompt: str) -> str:
        if len(prompt) > 4000 or any(k in prompt for k in self.complex_keywords):
            return self.large
        return self.small


@dataclass
class Metrics:
    calls: list = field(default_factory=list)

    def record(self, call: ModelCall) -> None:
        self.calls.append(call)

    def summary(self) -> dict:
        total = len(self.calls)
        if total == 0:
            return {"calls": 0}
        failures = sum(1 for c in self.calls if not c.success)
        latencies = sorted(c.latency_ms for c in self.calls)
        return {
            "calls": total,
            "error_rate": round(failures / total, 4),
            "p50_ms": latencies[len(latencies) // 2],
            "p95_ms": latencies[int(len(latencies) * 0.95) - 1],
            "avg_completion_tokens": round(
                sum(c.completion_tokens for c in self.calls) / total, 1
            ),
        }


router = ModelRouter()
metrics = Metrics()
metrics.record(ModelCall(router.choose("帮我分析这段日志"), 800, 300, 900))
metrics.record(ModelCall(router.choose("今天几号"), 20, 10, 210))
print(metrics.summary())
```

## 提示与版本管理速查

| 要点 | 做法 |
| --- | --- |
| 存放 | 提示词入库或独立文件，不散落在代码里 |
| 版本 | 每次改动生成版本号并记录变更原因 |
| 灰度 | 按用户或流量比例切分，观察指标 |
| 回滚 | 一键切回上一版本 |
| 评测 | 改动必须跑离线评测 + 小流量验证 |
| 审计 | 记录谁在什么时候改了哪一版 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 提示词硬编码在接口里 | 改动无法追踪 | 集中管理并版本化 |
| 不做超时 | 请求堆积、线程耗尽 | 每层设超时与熔断 |
| 无脑重试 | 放大故障与成本 | 只重试幂等且可恢复的错误 |
| 不做降级 | 单点故障全站不可用 | 备用模型或规则兜底 |
| 不记录 Token 用量 | 账单无法归因 | 按租户与接口统计成本 |
| 只测最终答案 | 忽略轨迹问题 | 评测结果与工具调用 |
| 直接全量发布新提示 | 质量回退无感知 | 先灰度再看指标 |
| 无人工抽检 | 长尾问题漏掉 | 定期抽样人工评估 |
| 把用户输入直接当系统指令 | 提示注入 | 隔离数据与指令 |
| 不做 PII 处理 | 合规风险 | 入参脱敏，日志脱敏 |

## 自测清单

- [ ] 应用分层清晰，编排与模型调用解耦。
- [ ] 每层都有超时、重试上限与降级路径。
- [ ] Token 成本按租户与接口可归因。
- [ ] 提示词版本化并支持灰度与回滚。
- [ ] 观测覆盖输入输出、提示版本与工具轨迹。
