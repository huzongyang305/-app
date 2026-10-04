## EXPLAIN 字段速查

| 字段 | 关注值 | 含义 |
| --- | --- | --- |
| `type` | const、eq_ref、ref、range、index、ALL | 访问方式，从好到差；`ALL` 是全表扫描 |
| `key` | 实际使用的索引 | 为 `NULL` 表示没用索引 |
| `key_len` | 使用到的索引字节数 | 判断联合索引用了几列 |
| `rows` | 预估扫描行数 | 越小越好 |
| `filtered` | 过滤后剩余百分比 | 越低说明扫描效率越差 |
| `Extra` | Using index / filesort / temporary | `index` 表示覆盖索引；`filesort`、`temporary` 需警惕 |

```sql
-- 1. 估算（不改数据）
EXPLAIN SELECT id, amount FROM orders WHERE user_id = 42 ORDER BY created_at DESC LIMIT 20;

-- 2. 看真实耗时与行数（MySQL 8.0.18+）
EXPLAIN ANALYZE SELECT id, amount FROM orders WHERE user_id = 42;

-- 3. 建立覆盖查询与排序的联合索引
ALTER TABLE orders ADD INDEX idx_user_created_amount (user_id, created_at, amount);

-- 4. 需要看优化器代价与候选索引
EXPLAIN FORMAT = JSON SELECT ...;
-- 运行期统计（MySQL 8）
SELECT * FROM sys.statements_with_full_table_scans LIMIT 10;
```

## 改写清单速查

| 原写法 | 问题 | 改写 |
| --- | --- | --- |
| `WHERE YEAR(created_at) = 2025` | 列上函数导致索引失效 | `created_at >= '2025-01-01' AND created_at < '2026-01-01'` |
| `WHERE id + 1 = 100` | 列参与运算 | `id = 99` |
| `LIKE '%abc'` | 左模糊无法用索引 | 前缀搜索或全文索引 |
| `LIMIT 20 OFFSET 100000` | 深分页扫描大量行 | 基于游标：`WHERE id > last_id ORDER BY id LIMIT 20` |
| `OR` 连接不同列 | 可能全表扫描 | 拆成 `UNION ALL` 或建联合索引 |
| `SELECT *` | 无法覆盖索引 | 只选需要的列 |
| 子查询返回大量行 | 物化开销大 | 改 `JOIN` 或 `EXISTS` |
| `ORDER BY` 与索引顺序不一致 | 需要额外排序 | 调整索引顺序匹配排序 |
| `JOIN` 大表无索引 | 全表扫描 | 关联列必须建索引 |
| 统计信息过期 | 选错执行计划 | `ANALYZE TABLE` 更新统计 |

## 优化流程速查

| 步骤 | 动作 |
| --- | --- |
| 1 | 用慢查询日志找出真正慢的语句 |
| 2 | `EXPLAIN` 看访问方式、索引与行数 |
| 3 | 判断是索引问题、SQL 写法问题还是数据量问题 |
| 4 | 优先改 SQL 或加合适索引（而不是增加硬件） |
| 5 | 回归对比：执行时间、扫描行数、CPU 与 IO |
| 6 | 上线后持续监控慢查询 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 只看 `type` 忽略 `rows` | 低估扫描量 | 两者结合看 |
| 认为加了索引就一定用 | 优化器可能不选 | 看 `key` 与代价估计，必要时强制验证 |
| 索引列上加函数 | 索引失效 | 改写条件让列保持「裸」状态 |
| 联合索引列顺序随意 | 部分查询用不上 | 按等值在前、范围在后、排序匹配设计 |
| 索引建太多 | 写入变慢、空间膨胀 | 只保留被真实查询使用的索引 |
| 用 `EXPLAIN` 估算值当真实值 | 判断偏差 | 用 `EXPLAIN ANALYZE` 看真实行数 |
| 深分页只调大 `LIMIT` 缓存 | 问题依旧 | 改游标分页或覆盖索引 + 延迟关联 |
| 排序字段方向不一致 | 无法利用索引排序 | 索引与排序方向保持一致 |
| 忽略数据分布 | 优化效果不稳定 | 用真实数据量与分布验证 |
| 改完不上监控 | 回归无人发现 | 加慢查询与执行时间监控 |

## 自测清单

- [ ] 会读 `EXPLAIN` 的 `type`、`key`、`rows`、`Extra`。
- [ ] 知道列上加函数会让索引失效。
- [ ] 深分页改用基于游标的方式。
- [ ] 联合索引按等值、范围、排序的顺序设计。
- [ ] 优化前后用真实数据量做对比验证。
