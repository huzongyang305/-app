## SQL 语句分类速查

| 类别 | 作用 | 常见语句 |
| --- | --- | --- |
| DDL | 定义结构 | `CREATE`、`ALTER`、`DROP`、`TRUNCATE` |
| DML | 修改数据 | `INSERT`、`UPDATE`、`DELETE` |
| DQL | 查询数据 | `SELECT` |
| DCL | 权限控制 | `GRANT`、`REVOKE` |
| TCL | 事务控制 | `BEGIN`、`COMMIT`、`ROLLBACK`、`SAVEPOINT` |

## 查询子句执行顺序

```text
FROM / JOIN  →  WHERE  →  GROUP BY  →  HAVING  →  SELECT  →  DISTINCT
    →  ORDER BY  →  LIMIT / OFFSET
```

理解顺序能解释两个常见疑问：为什么 `WHERE` 不能用 `SELECT` 里定义的别名（多数数据库），为什么聚合条件必须写 `HAVING`。

## JOIN 类型速查

| 类型 | 结果 | 典型用途 |
| --- | --- | --- |
| `INNER JOIN` | 只保留匹配行 | 有关联的数据 |
| `LEFT JOIN` | 保留左表全部 | 主表 + 可选关联 |
| `RIGHT JOIN` | 保留右表全部 | 少见，可用 LEFT 改写 |
| `FULL JOIN` | 两边都保留 | 找两表差异 |
| `CROSS JOIN` | 笛卡尔积 | 生成组合（慎用） |

```sql
-- 建表：类型、约束与注释一次写全
CREATE TABLE orders (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id     BIGINT       NOT NULL,
    amount      DECIMAL(12, 2) NOT NULL,
    status      VARCHAR(16)  NOT NULL DEFAULT 'created',
    created_at  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at  DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                             ON UPDATE CURRENT_TIMESTAMP(3),
    KEY idx_user_created (user_id, created_at),
    KEY idx_status_created (status, created_at),
    CONSTRAINT chk_amount CHECK (amount >= 0)
);

-- 分页查询 + 只取需要列 + 明确的排序
SELECT id, user_id, amount, created_at
FROM orders
WHERE user_id = 42 AND status <> 'canceled'
ORDER BY created_at DESC, id DESC
LIMIT 20;

-- 分组统计并用 HAVING 过滤聚合结果
SELECT user_id, COUNT(*) AS order_count, SUM(amount) AS total
FROM orders
WHERE created_at >= '2025-01-01'
GROUP BY user_id
HAVING SUM(amount) > 1000
ORDER BY total DESC
LIMIT 10;

-- 更新务必带 WHERE，并先用 SELECT 验证影响范围
UPDATE orders SET status = 'paid' WHERE id = 1001 AND status = 'created';
```

## 常用函数速查

| 类别 | 函数 |
| --- | --- |
| 聚合 | `COUNT`、`SUM`、`AVG`、`MIN`、`MAX`、`GROUP_CONCAT` |
| 字符串 | `CONCAT`、`SUBSTRING`、`TRIM`、`UPPER`、`LIKE` |
| 数值 | `ROUND`、`CEIL`、`FLOOR`、`ABS`、`MOD` |
| 日期 | `NOW`、`CURDATE`、`DATE_ADD`、`DATEDIFF`、`DATE_FORMAT` |
| 条件 | `CASE WHEN`、`IFNULL`、`COALESCE`、`NULLIF` |
| 窗口 | `ROW_NUMBER`、`RANK`、`LAG`、`SUM() OVER` |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `UPDATE` / `DELETE` 不带 `WHERE` | 全表被改或被删 | 先 `SELECT` 确认范围，再执行并限制影响行数 |
| 用 `SELECT *` | 传输冗余、索引失效风险 | 明确列出需要的列 |
| `WHERE amount = NULL` | 查不到任何行 | 用 `IS NULL` / `IS NOT NULL` |
| `COUNT(column)` 统计含 NULL 列 | 数量偏少 | 统计行数用 `COUNT(*)` |
| 用 `!=` 过滤含 NULL 的列 | NULL 行被排除 | 显式处理 NULL 条件 |
| 字符串日期直接比较 | 结果不准确 | 用日期类型或显式转换 |
| 隐式类型转换 | 索引失效 | 列与参数类型保持一致 |
| `LIMIT` 不配合 `ORDER BY` | 结果顺序不确定 | 分页必须显式排序 |
| 把聚合条件写进 `WHERE` | 语法错误 | 用 `HAVING` |
| 用字符串拼接构造 SQL | 注入风险 | 使用参数化查询 |

## 自测清单

- [ ] 能背出查询子句的执行顺序。
- [ ] 分得清 `WHERE` 与 `HAVING`、`COUNT(*)` 与 `COUNT(col)`。
- [ ] 写 `UPDATE` / `DELETE` 前先用 `SELECT` 验证影响范围。
- [ ] 分页查询带确定性排序。
- [ ] 全部使用参数化查询，不拼接 SQL 字符串。
