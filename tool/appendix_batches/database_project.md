## 订单库设计速查

| 表 | 关键字段 | 关键索引 |
| --- | --- | --- |
| `orders` | id、user_id、status、amount、created_at | `(user_id, created_at)`、`(status, created_at)` |
| `order_items` | order_id、product_id、快照字段、quantity | `(order_id)` |
| `payments` | order_id、channel、status、paid_at | `(order_id)`、`(status, created_at)` |
| `inventory` | product_id、available、reserved、version | 主键 + 版本号 |
| `order_events` | order_id、event_type、payload、created_at | `(order_id, created_at)` |

设计要点：

- 金额用 `DECIMAL(12,2)` 或整数分，禁止浮点
- 状态用受限字符串或字典表，迁移必须走状态机
- 订单项保存商品快照（名称、单价），避免历史订单随商品变更
- 关键查询都要能命中索引，禁止线上出现全表扫描
- 追加事件表记录状态流转，便于排查与对账

```sql
-- 防超卖：条件更新，不依赖先读后写
UPDATE inventory
SET available = available - 1,
    reserved  = reserved + 1,
    version   = version + 1
WHERE product_id = 1001
  AND available >= 1;
-- 影响行数为 0 说明库存不足，业务层据此返回失败

-- 幂等下单：唯一索引兜底防重复提交
CREATE TABLE idempotency_keys (
    key_id VARCHAR(64) PRIMARY KEY,
    user_id BIGINT NOT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    response_body JSON NULL
);

-- 每组取最新一条（用户最近订单）：窗口函数
SELECT *
FROM (
    SELECT o.*,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC, id DESC) AS rn
    FROM orders o
) t
WHERE rn = 1;

-- 订单状态流转审计
INSERT INTO order_events (order_id, event_type, payload)
VALUES (1001, 'paid', JSON_OBJECT('channel', 'alipay', 'amount', 59.70));
```

## 压测与验收速查

| 项 | 目标示例 |
| --- | --- |
| 下单 P95 | < 200 ms |
| 查询订单 P95 | < 100 ms |
| 库存扣减压测 | 并发 500 无超卖、无死锁堆积 |
| 慢查询 | 上线后 0 条全表扫描 |
| 数据一致性 | 对账任务零差异 |
| 备份恢复 | RTO < 30 分钟，演练通过 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 先查库存再更新 | 并发下超卖 | 用条件更新或加锁 |
| 金额用浮点 | 对账出现分位偏差 | 用 `DECIMAL` 或整数分 |
| 没有幂等键 | 重复提交产生多单 | 幂等键 + 唯一索引 |
| 订单项不存快照 | 历史订单金额被改 | 保存下单时的名称与单价 |
| 状态随意更新 | 出现非法状态 | 状态机校验 + 事件表审计 |
| 查询不带分片键 | 跨全部分片 | 设计查询时带上分片键 |
| 无对账任务 | 差异无人发现 | 定时与支付渠道对账 |
| 只压测查询不压测写入 | 上线写入瓶颈 | 写入路径同样压测 |
| 忽略死锁重试 | 偶发下单失败 | 捕获死锁错误并有限重试 |
| 上线后不看慢查询 | 性能逐渐劣化 | 持续监控并定期优化 |

## 自测清单

- [ ] 订单库核心表与索引覆盖主要查询。
- [ ] 扣库存用条件更新，且有幂等保护。
- [ ] 金额、时间、状态字段类型与约束正确。
- [ ] 有状态流转审计与对账机制。
- [ ] 关键路径都有压测数据与监控指标。
