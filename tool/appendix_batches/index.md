## 索引失效与命中对照表

| SQL 写法 | 能否用上索引 | 原因与改写建议 |
| --- | --- | --- |
| `WHERE name = 'abc'` | 能 | 等值查询，最理想 |
| `WHERE name LIKE 'abc%'` | 能 | 前缀匹配可走索引 |
| `WHERE name LIKE '%abc'` | 不能 | 左侧通配无法定位区间；改用全文索引或倒排方案 |
| `WHERE YEAR(created_at) = 2024` | 不能 | 列被函数包裹；改写为 `created_at >= '2024-01-01' AND created_at < '2025-01-01'` |
| `WHERE id + 1 = 10` | 不能 | 列参与运算；改成 `id = 9` |
| `WHERE status = 1 OR user_id = 2` | 可能退化为全表扫描 | 用 `UNION ALL` 拆开，或建联合索引 |
| `WHERE a = 1 AND c = 3`（索引为 `(a, b, c)`） | 只用到 a | 违反最左前缀；按查询顺序设计索引列 |
| `WHERE name = 123`（列为字符串） | 不能 | 隐式类型转换让列变成函数调用 |
| `ORDER BY created_at LIMIT 10`（有该列索引） | 能 | 索引天然有序，可省掉排序 |
| `ORDER BY a, b`（索引为 `(a, b)`） | 能 | 排序顺序要与索引列顺序一致 |
| `SELECT *` 且需要回表 | 走索引但回表 | 只查必要列，或建覆盖索引 |
| `WHERE deleted = 0 AND user_id = 5` | 能，但区分度低 | 低区分度列放联合索引右侧 |

## 建索引速查

| 场景 | 建议 |
| --- | --- |
| 高频等值查询 | 单列或联合索引，把等值列放前面 |
| 高频范围查询 | 范围列放联合索引最后一位 |
| 排序 + 过滤 | 让索引顺序匹配 `WHERE` + `ORDER BY` |
| 只查少量列 | 建覆盖索引，避免回表 |
| 写入非常频繁的表 | 索引越少越好，每个索引都要维护 |
| 区分度极低的列（性别、状态） | 单独建索引意义不大，考虑组合列 |
| 前缀很长的字符串 | 用前缀索引 `INDEX(url(32))` 省空间 |
| 大表加索引 | 用在线 DDL 工具，避开业务高峰 |

## 排查速查

```sql
-- 1. 看优化器怎么执行，重点看 type / key / rows / Extra
EXPLAIN SELECT id, name FROM users WHERE email = 'a@b.com';

-- 2. 看真实耗时与扫描行数（MySQL 8）
EXPLAIN ANALYZE SELECT id, name FROM users WHERE email = 'a@b.com';

-- 3. 看表的索引清单与区分度
SHOW INDEX FROM users;
SELECT COUNT(DISTINCT email) / COUNT(*) AS selectivity FROM users;
```

`EXPLAIN` 中值得警惕的信号：`type=ALL`（全表扫描）、`key=NULL`（没用索引）、`rows` 远大于预期、`Extra` 出现 `Using filesort` 或 `Using temporary`。

## 自测清单

- [ ] 能说出最左前缀原则，并据此排列联合索引列顺序。
- [ ] 知道列上加函数、隐式类型转换会导致索引失效。
- [ ] 会读 `EXPLAIN` 的 `type`、`key`、`rows`、`Extra` 四个字段。
- [ ] 知道区分度低的列不适合单独建索引。
- [ ] 能给高频查询设计覆盖索引，避免回表。
