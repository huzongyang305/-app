## 窗口函数速查

| 函数 | 作用 | 示例 |
| --- | --- | --- |
| `ROW_NUMBER()` | 组内连续序号，不重 | `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC)` |
| `RANK()` | 并列同名次，跳号 | `RANK() OVER (ORDER BY score DESC)` |
| `DENSE_RANK()` | 并列同排名，不跳号 | 排行榜常用 |
| `LAG()` / `LEAD()` | 取前一行 / 后一行 | 计算环比、相邻差值 |
| `SUM() OVER` | 累计求和 | `SUM(amount) OVER (ORDER BY day)` |
| `AVG() OVER` | 滑动平均 | `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` |
| `FIRST_VALUE()` / `LAST_VALUE()` | 组内首尾值 | 注意默认窗口范围 |
| `NTILE(n)` | 分桶 | 用户分层、百分位 |

```sql
-- 每个用户最近一笔订单（分组取最新）
SELECT *
FROM (
  SELECT o.*,
         ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
  FROM orders o
) t
WHERE rn = 1;

-- 每日新增与环比
SELECT day,
       amount,
       amount - LAG(amount) OVER (ORDER BY day) AS diff_vs_prev_day
FROM daily_sales
ORDER BY day;

-- 近 7 天滑动平均
SELECT day,
       AVG(amount) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_7d
FROM daily_sales;
```

## UNION 与 JOIN 速查

| 操作 | 方向 | 是否去重 | 说明 |
| --- | --- | --- | --- |
| `UNION` | 纵向合并 | 去重（有排序开销） | 列数与类型必须一致 |
| `UNION ALL` | 纵向合并 | 不去重 | 性能更好，优先使用 |
| `INNER JOIN` | 横向关联 | 只保留匹配行 | 两表都有的数据 |
| `LEFT JOIN` | 横向关联 | 保留左表全部 | 右表缺失为 NULL |
| `RIGHT JOIN` | 横向关联 | 保留右表全部 | 可用 LEFT JOIN 改写 |
| `FULL JOIN` | 横向关联 | 两边都保留 | MySQL 需模拟 |
| `CROSS JOIN` | 笛卡尔积 | 全部组合 | 小心行数爆炸 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 `UNION` 合并大数据集 | 比 `UNION ALL` 慢很多 | 确认无重复需求时用 `UNION ALL` |
| 在 `WHERE` 里过滤聚合结果 | 报错或结果不对 | 聚合条件放 `HAVING` |
| `LEFT JOIN` 后在 `WHERE` 过滤右表字段 | 退化成内连接 | 把右表条件写进 `ON`，或改判断 `IS NULL` |
| 用 `NOT IN` 且子查询含 NULL | 结果为空 | 改用 `NOT EXISTS` 或先过滤 NULL |
| 窗口函数写在 `WHERE` 里 | 语法错误 | 先用子查询或 CTE 计算，再在外层过滤 |
| `COUNT(column)` 统计含 NULL 的列 | 数量比预期少 | 统计行数用 `COUNT(*)` |
| `GROUP BY` 选了非聚合列 | 结果不确定或报错 | 只选分组列与聚合列 |
| 用 `LIMIT` 深分页 | 越翻越慢 | 用「上一页最后一条」的游标分页 |
| 隐式连接（逗号 + WHERE） | 可读性差、易漏条件 | 用显式 `JOIN ... ON` |
| 子查询返回多行用于 `=` | `Subquery returns more than 1 row` | 改 `IN` 或加 `LIMIT 1` |
| `ORDER BY` 里用列序号 | 增删列后含义变化 | 明确写列名 |

## 自测清单

- [ ] 能用 `ROW_NUMBER()` 解决「每组取最新一条」。
- [ ] 会用 `LAG` / `LEAD` 计算环比与差值。
- [ ] 知道窗口函数不能直接写在 `WHERE` 中。
- [ ] 分得清 `UNION` 与 `UNION ALL` 的性能差异。
- [ ] 深分页改用基于游标的分页方式。
