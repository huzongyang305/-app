## 拆分原则速查

| 依据 | 说明 | 反例 |
| --- | --- | --- |
| 业务能力 | 按领域边界拆分 | 按技术分层拆（所有 DAO 一个服务） |
| 变更频率 | 改动频繁的独立 | 每次改都要同时发布多个服务 |
| 数据所有权 | 每个服务独占自己的库 | 多服务直连同一个库 |
| 团队边界 | 与团队结构对齐 | 一个服务跨多个团队 |
| 扩展需求 | 不同负载分别扩容 | 全部拆成小服务增加运维成本 |

## 通信与治理速查

| 主题 | 做法 |
| --- | --- |
| 同步调用 | 只用于必须即时返回的场景，链路尽量短 |
| 异步消息 | 解耦与削峰，事件驱动 |
| 超时与重试 | 明确超时、退避与重试上限 |
| 熔断与降级 | 快速失败，保核心功能 |
| 幂等 | 所有写接口支持幂等键 |
| 服务发现 | 注册中心或 DNS，避免硬编码地址 |
| 配置管理 | 集中配置 + 变更审计 |
| 版本兼容 | 只做向后兼容变更，字段先加后用 |
| 数据一致性 | 避免跨服务事务，用事件与补偿 |

```python
from dataclasses import dataclass, field

@dataclass
class ServiceContract:
    """服务契约：显式声明依赖与 SLO，便于容量与故障分析。"""

    name: str
    dependencies: list
    timeout_ms: int = 800
    retries: int = 1
    slo_availability: float = 0.999

    def worst_case_latency_ms(self) -> int:
        """最坏路径：自身耗时 + 依赖超时 ×（重试次数 + 1）。"""
        per_dep = self.timeout_ms * (self.retries + 1)
        return self.timeout_ms + per_dep * len(self.dependencies)

    def availability_estimate(self, dep_availability: list) -> float:
        """串行依赖下可用性相乘，用于识别级联失败风险。"""
        value = self.slo_availability
        for dep in dep_availability:
            value *= dep
        return round(value, 6)

@dataclass
class CallChain:
    """调用链健康检查：识别过长链路与单点依赖。"""

    services: list = field(default_factory=list)

    def depth(self) -> int:
        return len(self.services)

    def risk(self) -> str:
        if self.depth() >= 5:
            return "链路过长：考虑合并、缓存或异步化"
        if self.depth() >= 3:
            return "链路偏长：评估降级策略"
        return "链路健康"

contract = ServiceContract("order", ["user", "inventory", "payment"])
print(contract.worst_case_latency_ms())
print(contract.availability_estimate([0.999, 0.995, 0.999]))
print(CallChain(["gateway", "order", "user", "inventory", "payment"]).risk())
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 过早微服务化 | 复杂度暴涨、交付变慢 | 先用单体 + 模块化，必要时再拆 |
| 服务共享数据库 | 耦合无法独立演进 | 每个服务独占数据，通过 API 交换 |
| 同步调用链过长 | 延迟叠加、级联失败 | 缩短链路、异步化、加缓存 |
| 无超时 | 线程被拖死 | 每层都设超时 |
| 服务数量爆炸 | 运维与排障成本高 | 按业务边界合并过细服务 |
| 无契约测试 | 接口变更导致线上故障 | 消费方契约测试 |
| 日志分散无追踪 | 排障困难 | 全链路 trace ID |
| 配置硬编码 | 换环境要重新构建 | 集中配置 + 注入 |
| 没有降级方案 | 依赖故障全站不可用 | 设计降级与兜底数据 |
| 忽略服务等级 | 核心与非核心同等对待 | 明确 SLO 与优先级 |

## 自测清单

- [ ] 拆分依据以业务边界为主，而非技术分层。
- [ ] 每个服务独占数据，通过接口交换。
- [ ] 调用链有超时、重试上限、熔断与降级。
- [ ] 有契约测试与全链路追踪。
- [ ] 明确各服务 SLO 与优先级。
