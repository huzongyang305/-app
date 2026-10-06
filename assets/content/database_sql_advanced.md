# SQL 高级查询

![窗口函数与 CTE 的能力对比](images/diagram_db_sql_advanced.webp)

![SQL 高级查询](images/remaining_sql_advanced.webp)

> 内容更新时间：2026-10-03 · 学习阶段：高级 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释本课主题解决了什么问题，而不是只背术语。
- 能说清 「窗口函数」、「CTE」、「条件聚合」、「分析查询」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「数据库」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：窗口函数、CTE、条件聚合与性能要点。

## 前置知识

- 先完成上一课《数据库运维：备份、迁移与分库分表》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：窗口函数、CTE、条件聚合。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 窗口函数

窗口函数在**不折叠行**的前提下做聚合与排名，是分析类查询的主力。

| 函数族 | 示例 | 用途 |
| --- | --- | --- |
| 排名 | ROW_NUMBER、RANK、DENSE_RANK | 分组内排名、去重取最新 |
| 偏移 | LAG、LEAD | 同比环比、相邻行比较 |
| 聚合窗口 | SUM / AVG / COUNT OVER | 累计值、移动平均 |
| 分布 | NTILE、PERCENT_RANK | 分桶、百分位 |

最高频的写法是 `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC)` 再在外层筛选序号等于 1，即「每个用户的最新一条」。

## 公共表表达式 CTE

CTE（WITH 子句）把复杂查询拆成可读的步骤；递归 CTE 可展开树形结构，如组织架构、评论树、物料清单。写法为 `WITH 名称 AS (查询) SELECT ... FROM 名称`，递归时用 `WITH RECURSIVE` 并在内部包含终止条件。

## 集合运算与高级聚合

UNION 会去重，UNION ALL 保留重复且性能更好（能用就用）；INTERSECT 取交集、EXCEPT 取差集。高级聚合包括 GROUPING SETS、ROLLUP、CUBE，可一次查询产出多层级汇总，适合报表场景。

## 条件聚合

用 CASE WHEN 配合 SUM / COUNT 实现「一行多指标」的透视：对不同状态分别求和与计数，再按维度分组，即可用一条语句产出汇总表，避免多次扫描。

## JSON 与全文检索

PostgreSQL 的 jsonb、MySQL 的 JSON 类型支持按路径查询与索引；全文检索可用 MATCH AGAINST 或 tsvector。它们适合半结构化数据与站内搜索，但复杂分析仍建议规范化到关系表。

## 性能要点

1. 窗口函数在数据量大时开销明显，先用 WHERE 缩小结果集。
2. 避免 SELECT *，只取需要的列以利用覆盖索引。
3. 相关子查询通常可改写成 JOIN 或窗口函数，往往更快。
4. 递归 CTE 必须有终止条件并限制深度，防止失控。
5. 所有优化都用执行计划验证，而不是凭直觉。

## 窗口函数四个实战场景

| 场景 | 写法要点 |
| --- | --- |
| 每组取最新一条 | `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC)` 后外层筛 rn=1 |
| 组内 Top3 | 同上取 rn<=3；注意并列名次用 `RANK()`（并列会跳号）或 `DENSE_RANK()`（不跳号） |
| 同比环比 | `LAG(amount, 1) OVER (ORDER BY month)` 取上月值，再做差值或比值 |
| 累计与移动平均 | `SUM(amount) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`；移动平均用 `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` |

注意：`ROWS` 按物理行数，`RANGE` 按排序值的范围——有并列值时两者结果不同，做累计统计时要明确选哪个。

## 执行计划对比：窗口函数 vs 自连接

| 方案 | 计划特征 | 复杂度 | 建议 |
| --- | --- | --- | --- |
| 窗口函数 | 出现 WindowAgg，只扫描一次数据 | O(n log n)（排序） | 首选，可读性与性能都更好 |
| 自连接 | 出现两次扫描或 Nested Loop | O(n²) | 仅在不支持窗口函数的老版本使用 |
| 相关子查询 | 每行执行一次内层查询 | O(n²) | 尽量改写为 JOIN 或窗口函数 |

验证方式：同一份数据分别用两种写法跑 `EXPLAIN ANALYZE`，对比实际执行时间与扫描行数；数据量大时差异通常是一个数量级。

## 本课小结
高级 SQL 的两个抓手是**窗口函数**（排名、偏移、累计）与 **CTE**（拆解复杂逻辑、递归展开层级）；配合条件聚合就能用一条语句产出完整报表。

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

## 动手练习

> 本课练习重点：围绕「窗口函数、CTE、条件聚合」完成复述、实验和交付，每个结果都要能被别人检查。

先写 schema 与查询，再补边界和失败数据，最后看执行计划与锁等待。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 本课主题解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「CTE」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

在 SQLite 或纸面表结构上写查询，分别验证正常数据、空值和边界数据。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「窗口函数」和「CTE」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 窗口函数 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 窗口函数 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 窗口函数 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“窗口函数 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 窗口函数 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 CTE 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 CTE 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 CTE 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“CTE 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 CTE 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：同一条 SQL 在数据量变大后突然变慢

**症状**：在本课的练习或生产场景里出现“同一条 SQL 在数据量变大后突然变慢”。

**定位**：围绕“执行计划随统计信息或数据分布改变，窗口函数 的索引没有被用上，回表次数反而增加”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「窗口函数与 GROUP BY 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「取「每个用户最新一条订单」的常用写法是？」的判断依据。
- [ ] 不看解析，能说出「UNION 与 UNION ALL 的区别是？」的判断依据。
- [ ] 不看解析，能说出「CTE（WITH 子句）相比嵌套子查询的优势是？」的判断依据。
- [ ] 不看解析，能说出「GROUP BY 之后做条件过滤应使用哪个子句？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 本课语境 |
| --- | --- |
| `WITH 名称 AS (查询) SELECT ... FROM 名称` | CTE（WITH 子句）把复杂查询拆成可读的步骤；递归 CTE 可展开树形结构，如组织架构、评论树、物料清单。写法为 `WITH 名称 AS (查询) SELECT ... FROM 名称`，递归时用 `WITH REC… |
| `WITH RECURSIVE` | CTE（WITH 子句）把复杂查询拆成可读的步骤；递归 CTE 可展开树形结构，如组织架构、评论树、物料清单。写法为 `WITH 名称 AS (查询) SELECT ... FROM 名称`，递归时用 `WITH REC… |
| `RANK()` | \| 组内 Top3 \| 同上取 rn<=3；注意并列名次用 `RANK()`（并列会跳号）或 `DENSE_RANK()`（不跳号） \| |
| `DENSE_RANK()` | \| 组内 Top3 \| 同上取 rn<=3；注意并列名次用 `RANK()`（并列会跳号）或 `DENSE_RANK()`（不跳号） \| |
| `LAG(amount, 1) OVER (ORDER BY month)` | \| 同比环比 \| `LAG(amount, 1) OVER (ORDER BY month)` 取上月值，再做差值或比值 \| |
| `；移动平均用` | \| 累计与移动平均 \| `SUM(amount) OVER (ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`；移动平均用 `ROWS B… |
| `ROWS` | 注意：`ROWS` 按物理行数，`RANGE` 按排序值的范围——有并列值时两者结果不同，做累计统计时要明确选哪个。 |
| `RANGE` | 注意：`ROWS` 按物理行数，`RANGE` 按排序值的范围——有并列值时两者结果不同，做累计统计时要明确选哪个。 |
| `EXPLAIN ANALYZE` | 验证方式：同一份数据分别用两种写法跑 `EXPLAIN ANALYZE`，对比实际执行时间与扫描行数；数据量大时差异通常是一个数量级。 |
| `ROW_NUMBER()` | \| `ROW_NUMBER()` \| 组内连续序号，不重 \| `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC)` \| |
| `RANK() OVER (ORDER BY score DESC)` | \| `RANK()` \| 并列同名次，跳号 \| `RANK() OVER (ORDER BY score DESC)` \| |
| `LAG()` | \| `LAG()` / `LEAD()` \| 取前一行 / 后一行 \| 计算环比、相邻差值 \| |

## 考点精讲

### 考点 1：窗口函数与 GROUP BY 的关键区别是？

- **判断依据**：窗口函数在每行上附加聚合结果，明细不会丢失。其他选项：窗口函数不折叠行，能在保留明细的同时做聚合。围绕 窗口函数与 GROUP BY 的关键区别是。判断这类题时，要把「不折叠行」放回题干限定的对象、输入和边界，「不能排序」、「性能更好」 等说法虽然包含相关术语，但范围或前提与本题不一致。

### 考点 2：围绕“SQL 高级查询”中的 窗口函数、CTE、条件聚合，下列哪两项是本课强调的实践判断？

- **判断依据**：正确答案包括「验证 CTE 时要固定版本并覆盖边界输入，结论才可复现」、「学习 窗口函数 时要同时说明输入、输出和失败路径，不能只看正常流程」。本题应选验证 CTE 时要固定版本并覆盖边界输入。本课把本课主题拆成概念、示例与故障现场三部分，因此判断 窗口函数 时必须同时交代输入、输出和失败路径，这使“学习 窗口函数 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在本课主题里，判断 CTE 时要固定版本与边界输入，所以“验证 CTE 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：下面这段 Python 代码复现了“SQL 高级查询”中 窗口函数、CTE、条件聚合 相关的一个常见故障，哪一项最准确地解释了问题？

- **判断依据**：结合窗口函数、CTE来看，符合题干条件的是「total 只在函数内部赋值，函数外访问会抛出 NameError」。符合题干条件的是total 只在函数内部赋值，函数外访问会抛出 NameError（sqladvanced 第 3 题）。结合窗口函数、CTE来看，符合题干条件的是total 只在函数内部赋值。

### 考点 4：CTE（WITH 子句）相比嵌套子查询的优势是？

- **判断依据**：递归 CTE 可以处理树形结构与图遍历，是替代应用层递归的有效手段。围绕 CTE（WITH 子句）相比嵌套子查询的优势是。作答时，先用窗口函数建立输入与输出的基线，再把结构更清晰，可被多次引用代入边界条件核对，结论才能复现。这道题要求区分概念与边界，「结构更清晰，可被多次引用」只有在题干给出的前提下才成立，而「能替代索引」、「执行速度一定更快」缺少同一组条件。

### 考点 5：GROUP BY 之后做条件过滤应使用哪个子句？

- **判断依据**：正确答案是「HAVING（WHERE 在分组前过滤行）」。先把不需要的行用 WHERE 过滤掉，再聚合，最后用 HAVING 过滤分组结果。判断这类题时，要把「HAVING（WHERE 在分组前过滤行）」放回题干限定的对象、输入和边界，「WHERE」、「ORDER BY（仅部分场景成立）」 等说法虽然包含相关术语，但范围或前提与本题不一致。

### 考点 6：补全代码：「SQL 高级查询」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。

`____() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn`

- **判断依据**：空格应填写「ROW_NUMBER」、「row_number」。围绕 补全代码：本课主题示例中，下面这行代码缺少哪个关键字或函… 作答时，先用窗口函数建立输入与输出的基线，再把ROWNUMBER 或 rownumber代入边界条件核对，结论才能复现。

## English Overview

**Title:** Advanced SQL

**Summary:** Window functions, CTEs and conditional aggregation.

**Category:** Database
**Level:** 高级
**Key terms:** 窗口函数, CTE, 条件聚合, 分析查询

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：高级
- 适用环境：PostgreSQL / MySQL / SQLite 等主流数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：窗口函数、CTE、条件聚合、分析查询
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [SQLite 文档](https://sqlite.org/docs.html) | 嵌入式 SQL 与事务 |
| [Use The Index, Luke](https://use-the-index-luke.com/) | SQL 索引与查询优化 |
| [PostgreSQL 事务教程](https://www.postgresql.org/docs/current/tutorial-transactions.html) | ACID 与隔离级别 |

> 「SQL 高级查询」的链接用于离线阅读后的延伸核对；App 不会自动联网。
