# 可观测性：日志、指标与链路

![可观测性：日志、指标与链路](images/category_observability.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「可观测性：日志、指标与链路」解决了什么问题，而不是只背术语。
- 能说清 「可观测性」、「日志」、「指标」、「链路追踪」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「工具链」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：三支柱、结构化日志、SLO 与告警设计。

## 前置知识

- 先完成上一课《Kubernetes 基础》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：高级。建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。
- 开始前先复习：可观测性、日志、指标。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 三大支柱

| 支柱 | 回答的问题 | 典型工具 |
| --- | --- | --- |
| 日志 Logs | 到底发生了什么 | ELK、Loki、CloudWatch |
| 指标 Metrics | 系统整体健康吗、趋势如何 | Prometheus + Grafana |
| 链路 Traces | 一次请求慢在哪一段 | Jaeger、Tempo、SkyWalking |

三者缺一不可：指标告诉你「出问题了」，链路告诉你「慢在哪」，日志告诉你「为什么错」。

## 结构化日志

```json
{"level":"error","ts":"2026-10-02T08:12:33Z","service":"order",
 "trace_id":"a1b2c3","user_id":"u_88","msg":"payment failed",
 "order_id":"o_1001","error":"timeout"}
```

要点：

1. 用 JSON 而不是拼接字符串，便于检索与聚合。
2. 每条日志带 `trace_id`、`service`、`level`，方便串联。
3. 日志分级（debug/info/warn/error），生产默认 info 以上。
4. 绝不记录密码、令牌、身份证号等敏感信息。
5. 关键路径记录耗时与结果，而不是只记「开始/结束」。

## 指标四类

```text
Counter    只增不减：请求总数、错误总数
Gauge      可增可减：当前连接数、队列长度、内存占用
Histogram  分布统计：请求延迟分桶，可算 P50/P95/P99
Summary    分位数统计：客户端计算，聚合性较差
```

**平均值会骗人**：关注 P95 / P99 延迟，以及错误率、饱和度（CPU/内存/队列）。

## 链路追踪

```text
Trace: 一次用户请求
  ├── Span: HTTP GET /orders       120 ms
  │     ├── Span: 查询数据库        35 ms
  │     └── Span: 调用支付服务      70 ms
  └── Span: 写缓存                  5 ms
```

用 OpenTelemetry 统一采集（SDK 埋点 + Collector 转发），避免绑定单一厂商；trace_id 同时写进日志，就能从慢链路直接跳到对应日志。

## SLI、SLO 与错误预算

```text
SLI：可测量的指标，如「请求成功率」「P95 延迟」
SLO：目标，如「99.9% 的请求在 300ms 内成功」
错误预算：1 - SLO，允许的失败额度；用完就冻结新功能、先修稳定性
```

告警要基于**用户可感知的症状**（错误率、延迟），而不是每个内部指标都报警，否则会疲于奔命。

## 落地清单

1. 统一日志格式与 trace 透传（HTTP 头携带 trace_id）。
2. 为每个服务定义 3~5 个黄金指标：延迟、流量、错误、饱和度。
3. 仪表盘按「用户视角 → 服务视角 → 资源视角」分层。
4. 告警分级：P0 电话、P1 群消息、P2 工单，并写清处理手册。
5. 定期演练：故意注入故障，验证监控与告警是否能及时发现。

## 告警规则示例

基于三个黄金信号（延迟、流量、错误）设计，避免"每个指标都报警"：

| 告警 | 表达式（PromQL 思路） | 阈值建议 | 级别 |
| --- | --- | --- | --- |
| 错误率过高 | 5 分钟 5xx 比例 | > 1% 持续 5 分钟 | P0 |
| 延迟劣化 | P95 请求耗时 | > 500ms 持续 10 分钟 | P0 |
| 流量异常下跌 | QPS 同比昨日 | 下降 > 50% | P1 |
| 资源饱和 | CPU 使用率 | > 80% 持续 15 分钟 | P1 |
| 队列积压 | 消息 lag | > 10 万且持续增长 | P1 |
| 依赖超时 | 下游调用超时率 | > 5% | P1 |

设计要点：**用持续时长过滤抖动**（`for: 5m`）、**按症状而非原因告警**（"错误率高"而不是"某台机器 CPU 高"）、**每条告警都要有处置手册**（先看什么、怎么回滚）。

## 从告警到定位的固定动作

1. 先看仪表盘的总体水位（错误率、延迟、流量），确认影响面。
2. 按时间对齐最近的变更（发布、配置、依赖升级）。
3. 用 trace 找最慢的 span，再跳对应服务的日志（靠 trace_id 串联）。
4. 确认是单实例还是全局：单实例先摘除，全局先考虑回滚或降级。

## 本课小结
可观测性不是「装个监控」，而是**让系统内部状态可以被外部推断**。日志给细节、指标给趋势、链路给定位，三者用同一个 trace_id 串起来才真正好用。

<!-- appendix:v1 -->

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

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「可观测性、日志、指标」完成复述、实验和交付，每个结果都要能被别人检查。

先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「可观测性：日志、指标与链路」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「日志」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「可观测性」和「日志」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Observability

**Summary:** Logs, metrics, traces, SLOs and alerting.

**Category:** Toolchain  
**Level:** 高级  
**Key terms:** 可观测性, 日志, 指标, 链路追踪, SLO

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：Git / Docker / Kubernetes / CI 平台
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：可观测性、日志、指标、链路追踪、SLO
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [Git 文档](https://git-scm.com/doc) | 版本控制与协作 |
| [Docker 文档](https://docs.docker.com/) | 容器与镜像 |
| [Kubernetes 文档](https://kubernetes.io/docs/) | 编排与运维 |

> 本课主题：三支柱、结构化日志、SLO 与告警设计。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

