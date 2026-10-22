## 行存与列存对照

| 维度 | 行存（OLTP） | 列存（OLAP） |
| --- | --- | --- |
| 存储方式 | 一行连续存放 | 一列连续存放 |
| 优势场景 | 单行读写、事务 | 大范围扫描、聚合 |
| 压缩率 | 低 | 高（同列类型一致） |
| 写入 | 适合频繁小写入 | 适合批量写入 |
| 典型系统 | MySQL、PostgreSQL | ClickHouse、Doris、Snowflake |
| 向量化 | 有限 | 天然适配 |

## 建模速查

| 模型 | 结构 | 特点 |
| --- | --- | --- |
| 星型模型 | 事实表 + 维度表 | 维度少、JOIN 少、易理解 |
| 雪花模型 | 维度表再规范化 | 省空间、JOIN 多 |
| 宽表 | 打平所有维度 | 查询最快、ETL 成本高 |
| 预聚合 | 提前算好指标 | 查询极快、灵活性差 |

| 技术 | 作用 |
| --- | --- |
| 字典编码 | 低基数列映射为整数 ID |
| 游程编码 | 连续重复值只存一次 |
| 位图索引 | 低基数维度快速过滤 |
| 分区裁剪 | 只扫描相关分区 |
| 排序键 / 主键 | 决定数据有序与跳数索引效率 |
| 物化视图 | 保存预聚合结果 |
| 向量化执行 | 批量处理 + SIMD |

```sql
-- ClickHouse 风格：排序键决定扫描效率
CREATE TABLE events (
    event_date Date,
    user_id    UInt64,
    event_type LowCardinality(String),   -- 低基数列用字典编码
    amount     Decimal(12, 2)
) ENGINE = MergeTree
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_type, event_date, user_id);   -- 高频过滤列放前面

-- 预聚合：把日粒度结果物化，查询时直接扫小表
CREATE MATERIALIZED VIEW daily_sales_mv
ENGINE = SummingMergeTree
PARTITION BY toYYYYMM(day)
ORDER BY (day, category)
AS SELECT
    toDate(created_at) AS day,
    category,
    sum(amount)  AS total_amount,
    count()      AS order_count
FROM orders
GROUP BY day, category;

-- 查询时先看扫描量：分区裁剪是否生效
EXPLAIN SELECT category, sum(total_amount)
FROM daily_sales_mv
WHERE day BETWEEN '2025-09-01' AND '2025-09-30'
GROUP BY category;
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在列存上做高频单行更新 | 性能极差 | 列存面向批量写入，单行更新代价高 |
| 用列存库跑点查业务 | 并发与延迟不达标 | OLTP 用行存，分析用列存 |
| 排序键乱序 | 扫描量大 | 按高频过滤与聚合维度排序 |
| 不分区直接全表扫 | 查询慢、成本高 | 用时间或业务维度分区裁剪 |
| 高基数维度上建位图索引 | 索引膨胀 | 位图适合低基数 |
| 宽表无限膨胀 | 存储与 ETL 成本高 | 分级建模，控制宽表粒度 |
| 预聚合覆盖所有场景 | 维度组合爆炸 | 只预聚合高频查询，其余走明细 |
| 忽视数据倾斜 | 部分节点慢 | 调整分桶键或加盐打散 |
| 只用行数评估成本 | 低估扫描字节数 | 关注扫描数据量与列数 |
| 不做压测就上生产 | 查询超时 | 用真实数据量测试 P95 延迟 |

## 自测清单

- [ ] 能说出行存与列存的适用边界。
- [ ] 会按高频过滤列设计排序键与分区。
- [ ] 低基数列用字典或位图，高基数列用排序或跳数索引。
- [ ] 预聚合只覆盖高频查询，明细保留可回溯。
- [ ] 用扫描数据量与 P95 延迟评估查询成本。
