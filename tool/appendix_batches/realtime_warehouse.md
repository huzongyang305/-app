## 链路速查

| 环节 | 组件 | 关注点 |
| --- | --- | --- |
| 采集 | Canal / Debezium / Flink CDC | 断点续传、顺序、schema 变更 |
| 消息 | Kafka | 分区数、保留期、副本与幂等生产者 |
| 计算 | Flink | 事件时间、水位线、状态与 checkpoint |
| 存储 | ClickHouse / Doris / Hudi | 写入模式、排序键、分区 |
| 查询 | BI / 应用 | 延迟与并发，物化视图加速 |
| 监控 | 指标 + 告警 | 端到端延迟、积压、失败率 |

## Kafka 关键参数速查

| 参数 | 作用 | 建议 |
| --- | --- | --- |
| `partitions` | 并行度上限 | 按峰值吞吐与消费能力估算，只能增不能减 |
| `replication.factor` | 副本数 | 生产至少 3 |
| `min.insync.replicas` | 最少同步副本 | 与 acks=all 配合保证不丢 |
| `acks` | 写入确认 | 关键数据用 `all` |
| `enable.idempotence` | 幂等生产者 | 开启避免重试重复 |
| `retention.ms` | 保留期 | 支持重放历史，按回溯需求设置 |
| `max.poll.records` | 单次拉取条数 | 控制单批处理时长，避免超时踢出 |

## 端到端精确一次速查

| 环节 | 要求 |
| --- | --- |
| 源端 | 可重放（Kafka 保留 + 消费位点管理） |
| 计算 | 开启 checkpoint，状态后端可靠 |
| 汇端 | 支持事务或幂等写入（两阶段提交 / 主键 upsert） |
| 位点 | 与数据写入在同一事务或同一提交批次内 |

```sql
-- ClickHouse / Doris 风格：实时表按天分区，按查询模式排序
CREATE TABLE dws_user_actions (
    dt          Date,
    user_id     UInt64,
    action_type LowCardinality(String),
    action_cnt  UInt32,
    updated_at  DateTime
) ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY dt
ORDER BY (action_type, user_id);

-- 实时看板：近 5 分钟聚合（配合物化视图或增量表）
SELECT action_type, sum(action_cnt) AS total
FROM dws_user_actions
WHERE dt = today()
GROUP BY action_type
ORDER BY total DESC
LIMIT 10;
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 按处理时间统计 | 结果随延迟波动 | 用事件时间 + 水位线 |
| Kafka 分区数随意加 | key 顺序被打乱 | 评估后再调，必要时新建 topic |
| 消费者处理过慢 | rebalance 反复发生 | 减少 `max.poll.records` 或提升并行度 |
| 不做维表关联缓存 | 每条记录查一次维表 | 用异步 IO + 本地缓存 + TTL |
| 汇端不支持幂等 | 重启后数据重复 | 主键 upsert 或事务写入 |
| 只监控任务是否存活 | 延迟高但无人知 | 监控端到端延迟与积压量 |
| 状态不设 TTL | 状态爆炸 | 配置状态过期与清理 |
| 大促前不压测 | 峰值积压 | 按峰值 QPS × 冗余系数压测 |
| schema 变更无兼容策略 | 作业崩溃 | 用兼容演进（加字段、默认值） |
| 报表直接查明细表 | 查询超时 | 用预聚合或物化视图 |

## 自测清单

- [ ] 链路各环节都有明确的容错与重放策略。
- [ ] Kafka 副本、确认与幂等生产配置正确。
- [ ] 端到端精确一次需要源、计算、汇三方配合。
- [ ] 维表关联使用异步 IO 与缓存。
- [ ] 监控覆盖端到端延迟、积压与失败率。
