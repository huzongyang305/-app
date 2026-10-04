## 三种架构对照

| 维度 | 数据仓库 | 数据湖 | 湖仓一体 |
| --- | --- | --- | --- |
| 数据 | 结构化、schema-on-write | 任意格式、schema-on-read | 开放格式 + 表格式 |
| 事务 | 强 | 弱 | 支持 ACID |
| schema 演进 | 成本高 | 灵活但易失控 | 受控演进 |
| 分析性能 | 好 | 取决于引擎 | 好（含索引与统计） |
| 典型 | Snowflake、Redshift | S3 + Hive | Iceberg、Hudi、Delta Lake |

## 表格式对照

| 能力 | Iceberg | Hudi | Delta Lake |
| --- | --- | --- | --- |
| 快照与时间旅行 | 支持 | 支持 | 支持 |
| 增量读取 | 支持 | 强（增量拉取） | 支持 |
| 行级更新 | 支持（merge-on-read） | 强（copy-on-write / merge-on-read） | 支持 |
| 引擎中立 | 强 | 中 | 偏 Spark 生态 |
| 适合场景 | 通用湖仓、引擎多样 | 近实时入湖与 CDC | Databricks / Spark 生态 |

共识：三者都提供 ACID、schema 演进、时间旅行与元数据管理，差异在写入模式与生态侧重。

```sql
-- Iceberg：按天分区并做元数据维护
CREATE TABLE lake.orders (
    order_id   BIGINT,
    user_id    BIGINT,
    amount     DECIMAL(12, 2),
    created_at TIMESTAMP
)
USING iceberg
PARTITIONED BY (days(created_at))
TBLPROPERTIES (
    'write.target-file-size-bytes' = '134217728'   -- 目标文件 128 MB
);

-- 小文件治理：合并数据文件与清单文件
CALL catalog.system.rewrite_data_files(table => 'lake.orders');
CALL catalog.system.rewrite_manifests(table => 'lake.orders');
CALL catalog.system.expire_snapshots(table => 'lake.orders', older_than => TIMESTAMP '2025-09-01 00:00:00');

-- 时间旅行：排查某天的数据状态
SELECT COUNT(*) FROM lake.orders VERSION AS OF '2025-09-01-snapshot';
```

## 湖仓落地要点

| 要点 | 做法 |
| --- | --- |
| 文件大小 | 目标 128 到 512 MB，定期 compaction |
| 分区设计 | 按时间 + 高基数列组合，避免过度分区 |
| 元数据 | 定期 expire 快照与清单，控制元数据膨胀 |
| CDC 入湖 | 用 upsert / merge 策略，保证主键唯一 |
| 权限 | 表级与列级权限 + 存储层访问控制 |
| 质量 | 入湖前后做行数、主键、枚举值校验 |
| 血缘 | 记录上下游依赖，便于影响分析 |

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 把湖仓当纯湖使用 | 小文件与元数据爆炸 | 开启 compaction 与元数据清理 |
| 分区字段基数过高 | 目录与元数据膨胀 | 用时间分区 + 桶或排序键 |
| 不清理快照 | 存储成本持续上升 | 配置快照过期策略 |
| 直接覆盖写全表 | 成本高且不可回溯 | 用增量 merge 或分区覆盖 |
| 忽略 schema 演进策略 | 下游读取失败 | 用向后兼容的加列方式 |
| 无主键约束的 upsert | 出现重复数据 | 明确主键并做去重校验 |
| 权限只在表层 | 敏感列泄漏 | 加列级权限与脱敏视图 |
| 不记录血缘 | 影响分析困难 | 采集血缘并在变更前评估 |
| 只测小数据量 | 上线后性能不达标 | 用接近生产的数据量验证 |
| 缺少数据质量门禁 | 脏数据进入下游 | 入湖与出湖都设校验规则 |

## 自测清单

- [ ] 能说清数据仓库、数据湖与湖仓一体的区别。
- [ ] 知道 Iceberg、Hudi、Delta Lake 的共性与侧重。
- [ ] 会配置 compaction 与快照过期策略。
- [ ] 分区设计避免高基数。
- [ ] 有表级与列级权限和数据质量门禁。
