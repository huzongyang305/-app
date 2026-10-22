## 存储引擎对照

| 维度 | InnoDB | MyISAM |
| --- | --- | --- |
| 事务 | 支持 | 不支持 |
| 锁粒度 | 行锁 | 表锁 |
| 外键 | 支持 | 不支持 |
| 崩溃恢复 | 通过 redo 恢复 | 易损坏 |
| 全文索引 | 支持 | 支持 |
| 适用 | 绝大多数在线业务 | 只读历史数据（已不推荐） |

## 日志分工速查

| 日志 | 层级 | 作用 | 特点 |
| --- | --- | --- | --- |
| redo log | InnoDB | 崩溃恢复，保证已提交不丢 | 环形写、顺序 IO |
| undo log | InnoDB | 回滚与 MVCC 旧版本 | 逻辑日志，可清理 |
| binlog | MySQL Server | 主从复制、时间点恢复 | 归档型，需妥善保留 |
| relay log | 从库 | 暂存主库 binlog 事件 | 从库专用 |
| 慢查询日志 | Server | 记录慢 SQL | 用于性能分析 |

WAL 思想：**先写日志再写数据页**，把随机写转换为顺序写，同时保证崩溃后可恢复。

## B+ 树设计要点速查

| 要点 | 说明 |
| --- | --- |
| 页大小 | 默认 16 KB，一个页容纳更多键则树更矮 |
| 聚簇索引 | 叶子节点存整行数据 |
| 二级索引 | 叶子存主键值，需要时回表 |
| 主键选择 | 越短越好，所有二级索引都要存它 |
| 自增主键 | 顺序插入，减少页分裂 |
| 随机主键（UUID） | 页分裂与碎片增加，写入性能下降 |
| 页分裂 | 插入无序数据导致；可用有序主键或预分配缓解 |
| 自适应哈希索引 | InnoDB 自动为热点页建立哈希索引 |

```sql
-- 查看表与索引的物理情况
SHOW TABLE STATUS LIKE 'orders'\G        -- 关注 Data_length、Index_length、Data_free
SHOW INDEX FROM orders;                  -- 关注 Cardinality（区分度估计）

-- 查看 InnoDB 状态：缓冲池命中、页读写、锁等待
SHOW ENGINE INNODB STATUS\G

-- 关键运行指标
SELECT
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status
     WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests') AS read_requests,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status
     WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') AS disk_reads;

-- 缓冲池配置（一般设为物理内存的 50% 到 70%）
SELECT @@innodb_buffer_pool_size / 1024 / 1024 / 1024 AS pool_gb;
```

## 常见错误对照表

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用随机 UUID 作聚簇主键 | 写入慢、页分裂多 | 用趋势递增 ID 或有序 UUID 变体 |
| 主键过长（长字符串） | 所有二级索引膨胀 | 用自增或雪花 ID |
| 认为二级索引查询不用回表 | 低估 IO | 需要非索引列时仍要回表，必要时做覆盖索引 |
| 关闭 binlog 省空间 | 无法做时间点恢复与复制 | 保留并定期归档 |
| 忽视缓冲池大小 | 命中率低、磁盘 IO 高 | 按内存比例设置并监控命中率 |
| 频繁大批量删除 | undo 膨胀、磁盘占用高 | 分批删除并关注表空间回收 |
| 认为 delete 立即释放磁盘 | 空间不回收 | 需 `OPTIMIZE TABLE` 或重建 |
| 无视 undo 保留时长 | 长事务导致膨胀 | 监控最长事务并限制时长 |
| 混用 MyISAM 与 InnoDB | 事务失效、锁粒度混乱 | 统一使用 InnoDB |
| 只看 QPS 不看 IO | 掩盖磁盘瓶颈 | 同时监控 IOPS、延迟与命中率 |

## 自测清单

- [ ] 能说清 redo、undo、binlog 的分工。
- [ ] 记得聚簇索引叶子存整行，二级索引叶子存主键。
- [ ] 主键选择短小且趋势递增。
- [ ] 会看缓冲池命中率与 InnoDB 状态。
- [ ] 长事务与大批量删除有治理方案。
