## 补充：生产端可靠性、再平衡协议与容量估算

### 生产端的三道可靠性开关

```properties
# 1. 确认级别：全部 ISR 确认才算成功
acks=all

# 2. 幂等生产者：避免重试导致重复写入
enable.idempotence=true

# 3. 重试与顺序
retries=2147483647
max.in.flight.requests.per.connection=5   # 幂等开启时可放宽，仍保证顺序
```

| 配置组合 | 丢数据风险 | 重复风险 | 适用 |
| --- | --- | --- | --- |
| `acks=0` | 高 | 低 | 日志采集等可丢场景 |
| `acks=1` | 中（主副本故障即丢） | 中 | 一般业务 |
| `acks=all` + 幂等 | 低 | 低 | **订单、支付等关键数据** |

```text
注意：acks=all 只保证「写入成功」，不保证「消费一次」
  生产者 → 分区（不丢）→ 消费者仍可能重复处理
  因此消费端幂等依然必需
```

### 再平衡的两种协议

| 协议 | 行为 | 代价 |
| --- | --- | --- |
| Eager（传统） | 撤销全部分区再重新分配 | 全组短暂停消费 |
| Cooperative（增量） | 只迁移需要变动的分区 | 停顿更短，可多次轮次完成 |

```properties
# 使用增量再平衡（Kafka 2.4+ 消费者）
partition.assignment.strategy=org.apache.kafka.clients.consumer.CooperativeStickyAssignor
```

```text
减少再平衡的四个参数
  session.timeout.ms            会话超时（默认 45s）：太短会误判掉线
  heartbeat.interval.ms         心跳间隔（默认 3s）：应为会话超时的 1/3
  max.poll.interval.ms          两次 poll 最大间隔（默认 5min）：处理慢就调大
  max.poll.records              单次 poll 拉取条数：调小可降低单批处理时间
```

**排查口诀**：频繁再平衡时先看 `max.poll.interval.ms` 是否小于实际处理时间。

### ISR、HW 与 LEO

```text
LEO（Log End Offset）    某副本最后一条消息的下一个位置
HW（High Watermark）     所有 ISR 都已复制的最高位置

          Partition 0
  LEO(leader)      ─────────────► 120
  LEO(follower-1)  ────────────►  120
  LEO(follower-2)  ───────►       115
  HW               ───────►       115   ← 消费者只能读到 HW 之前的消息

含义：消费者读不到「尚未被足够副本确认」的消息，避免读到将来可能丢失的数据
```

### 分区数估算

```text
按吞吐估算
  目标吞吐 100 MB/s，单分区实测 20 MB/s
  → 至少 5 个分区；留一倍余量 → 10 个

按消费者并行度估算
  消费者数上限 = 分区数
  → 想让 12 个消费者都干活，分区数至少 12

经验补充
  · 分区数只增不减（减少需要重建主题）
  · 分区过多会增加元数据与再平衡开销，单集群常见上限几千个
  · 分区数应结合「峰值吞吐」而不是平均值
```

### 常用运维命令

```bash
# 查看主题分区与副本分布
kafka-topics.sh --describe --topic orders --bootstrap-server localhost:9092

# 查看消费组堆积（lag）
kafka-consumer-groups.sh --describe --group order-worker --bootstrap-server localhost:9092

# 增加分区（注意：会改变 key 的分区映射）
kafka-topics.sh --alter --topic orders --partitions 12 --bootstrap-server localhost:9092
```

```text
增加分区前必须评估
  · 同一 key 的新旧消息可能落到不同分区 → 破坏单键有序
  · 需要停机或做双写迁移才能安全扩容
```

### 自查清单

- [ ] 关键主题启用 `acks=all` 与幂等生产者
- [ ] 消费端实现幂等，不依赖「消息不会重复」
- [ ] 使用增量再平衡，并调好 poll 相关参数
- [ ] 能解释 HW 与 LEO 的关系
- [ ] 扩容分区前评估过 key 映射变化的影响

