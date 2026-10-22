## 批处理与流处理对照

| 维度 | 批处理 | 流处理 |
| --- | --- | --- |
| 输入 | 有界数据集 | 无界数据流 |
| 延迟 | 分钟到小时 | 毫秒到秒 |
| 典型引擎 | Spark、Hive、MapReduce | Flink、Kafka Streams、Spark Structured Streaming |
| 语义 | 一次处理全量 | 持续处理增量 |
| 状态 | 任务级 | 需要状态管理与容错 |
| 适用 | 报表、回溯、离线特征 | 实时监控、风控、实时特征 |

## 架构模式速查

| 模式 | 结构 | 优点 | 缺点 |
| --- | --- | --- | --- |
| Lambda | 批处理 + 流处理两条链路 | 结果准确、可回溯 | 两套代码口径易不一致 |
| Kappa | 只保留流处理，靠重放历史 | 一套代码、口径统一 | 依赖消息保留与重放能力 |
| 流批一体 | 同一引擎两种模式 | 代码复用 | 引擎与运维要求高 |

## 数仓分层速查

| 层 | 职责 | 示例 |
| --- | --- | --- |
| ODS | 原始数据，尽量不加工 | 业务库 binlog 落地 |
| DWD | 清洗、去重、明细 | 下单明细事实表 |
| DWS | 轻度汇总，主题宽表 | 用户日粒度行为汇总 |
| ADS | 面向应用的结果层 | 报表指标表 |
| DIM | 公共维度 | 用户、商品、门店维表 |

```python
from dataclasses import dataclass, field

@dataclass
class TimeWatermark:
    """水位线：判断事件时间进度，处理乱序数据。"""

    max_event_time: int = 0
    allowed_lateness: int = 5    # 允许迟到 5 个单位

    def update(self, event_time: int) -> None:
        self.max_event_time = max(self.max_event_time, event_time)

    @property
    def watermark(self) -> int:
        return self.max_event_time - self.allowed_lateness

    def is_late(self, event_time: int) -> bool:
        return event_time < self.watermark


def deduplicate_by_key(events, key):
    """流处理中的去重：按业务键保留首次出现。"""
    seen = set()
    for event in events:
        k = key(event)
        if k in seen:
            continue
        seen.add(k)
        yield event


wm = TimeWatermark()
wm.update(100)
print(wm.watermark, wm.is_late(90), wm.is_late(96))
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只按处理时间统计 | 结果随到达顺序波动 | 用事件时间 + 水位线 |
| 不允许迟到数据 | 指标偏低 | 设置允许迟到并配侧输出 |
| 批流两套口径不一致 | 同一指标两个数 | 统一口径，必要时改为 Kappa |
| 不做幂等写入 | 重跑产生重复数据 | 用主键 upsert 或分区覆盖 |
| 忽略数据倾斜 | 个别任务极慢 | 加盐打散或两阶段聚合 |
| 分区过多或过少 | 小文件或并行度不足 | 按数据量估算并定期合并 |
| 状态不设过期 | 状态无限增长 | 配置 TTL 与状态清理 |
| 依赖默认并行度 | 资源利用率低 | 按分区数与数据量设置并行度 |
| 不做 checkpoint | 故障后数据丢失 | 开启 checkpoint 并验证恢复 |
| 只跑通流程不看监控 | 出问题无感知 | 监控延迟、积压与失败率 |

## 自测清单

- [ ] 能按延迟与数据边界选择批或流处理。
- [ ] 流处理统一使用事件时间与水位线。
- [ ] 数仓分层职责清晰（ODS / DWD / DWS / ADS）。
- [ ] 关键任务有 checkpoint、幂等与监控。
- [ ] 会处理数据倾斜与状态膨胀。
