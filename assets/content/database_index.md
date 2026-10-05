# 索引

![索引](images/remaining_index.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：15 分钟

## 学习目标

- 能用自己的话解释「索引」解决了什么问题，而不是只背术语。
- 能说清 「索引」、「B+树」、「复合索引」、「最左前缀」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「数据库」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：B+ 树、最左前缀原则，以及索引什么时候失效。

## 前置知识

- 先完成上一课《SQL 基础》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：索引、B+树、复合索引。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 索引解决什么问题

没有索引时，数据库只能**全表扫描**，逐行比对。索引就像书的目录，让数据库快速定位到目标数据，把 `O(n)` 的查找降到 `O(log n)`。

## B+ 树索引

主流关系型数据库的索引底层多用 **B+ 树**：

- 所有数据都在叶子节点，且按顺序用链表相连。
- 非叶子节点只存键，可以容纳更多分支，树更矮。
- 叶子节点链表非常适合范围查询和排序。

```text
              [30 | 60]
            /     |      \
     [10|20]   [40|50]   [70|90]
        ↓          ↓          ↓
     叶子节点按顺序双向链表相连
```

三次磁盘 I/O 左右就能在千万级数据中定位一行记录。

## 创建与使用

```sql
CREATE INDEX idx_students_city ON students(city);

-- 走索引：条件列是索引列
SELECT * FROM students WHERE city = '上海';

-- 复合索引遵循最左前缀原则
CREATE INDEX idx_name_age ON students(name, age);
-- 可用：WHERE name = ? / WHERE name = ? AND age = ?
-- 不可用：WHERE age = ?
```

## 什么时候索引会失效

```sql
-- 在索引列上做运算或函数调用
SELECT * FROM students WHERE YEAR(created_at) = 2024;

-- 以 % 开头的模糊查询无法使用普通索引
SELECT * FROM students WHERE name LIKE '%明';

-- 类型隐式转换
SELECT * FROM students WHERE phone = 13800000000;  -- phone 是字符串
```

改写建议：把运算移到常量一侧，或使用覆盖索引、全文索引。

## 索引的代价

索引不是越多越好：

1. 占用额外磁盘空间。
2. `INSERT / UPDATE / DELETE` 都要同步维护索引，写变慢。
3. 优化器选错索引时反而更慢。

一般只为**高频查询条件、连接列、排序分组列**建立索引。

## 用 EXPLAIN 验证

```sql
EXPLAIN QUERY PLAN
SELECT * FROM students WHERE city = '上海';
```

关注是否出现 `SCAN TABLE`（全表扫描）或 `SEARCH ... USING INDEX`（使用索引）。

## B+ 树查找过程示例

以 `WHERE id = 42` 为例（假设每页存 100 个键、树高 3 层）：

```text
根节点（第 1 次 IO）：比较 42 落在哪个区间 → 定位到中间节点
中间节点（第 2 次 IO）：继续比较 → 定位到叶子页
叶子节点（第 3 次 IO）：页内二分查找 → 命中记录，返回
```

千万级数据只需 **3 次磁盘 IO**，这就是索引快于全表扫描的根本原因。范围查询（`WHERE id BETWEEN 40 AND 60`）在叶子节点沿链表顺序读取，因此范围扫描同样高效。

## 索引失效实例对照

| 写法 | 是否走索引 | 原因与改法 |
| --- | --- | --- |
| `WHERE city = '上海'` | 走 | 索引列直接比较 |
| `WHERE YEAR(created_at) = 2024` | 不走 | 列上有函数，改为 `created_at >= '2024-01-01' AND created_at < '2025-01-01'` |
| `WHERE name LIKE '%明'` | 不走 | 前缀未知，改为 `LIKE '明%'` 或用全文索引 |
| `WHERE phone = 13800000000`（phone 是字符串） | 可能不走 | 隐式类型转换，改为 `phone = '13800000000'` |
| `WHERE a = 1 ORDER BY b`（索引为 a） | 需排序 | 建复合索引 `(a, b)` 让过滤与排序都走索引 |
| `WHERE a = 1 OR b = 2`（只索引 a） | 可能不走 | 拆成两条查询 UNION，或分别建索引 |
| 复合索引 `(a, b, c)` 上 `WHERE b = 2` | 不走 | 违反最左前缀，考虑单独为 b 建索引 |

验证方法始终是 `EXPLAIN`：看 type 是否为 `ref/range`、key 是否命中、rows 扫描行数是否显著下降。

## 覆盖索引与索引下推

**覆盖索引**：查询需要的列全部包含在索引中，无需回表。

| 查询 | 索引 | 是否回表 |
| --- | --- | --- |
| `SELECT name FROM users WHERE city='上海'` | `(city)` | 回表（需取 name） |
| 同上 | `(city, name)` | **不回表**，Extra 显示 Using index |
| `SELECT * FROM users WHERE city='上海'` | `(city)` | 回表（需要全部列） |

这也是 `SELECT *` 拖慢查询的一个具体原因：它几乎必然导致回表。建议列表查询只取需要的列，并为高频组合建复合索引。

**索引下推（ICP, MySQL 5.6+）**：在存储引擎层就利用索引中的列过滤掉不满足条件的记录，减少回表次数。

| 查询 | 有无 ICP | 效果 |
| --- | --- | --- |
| `WHERE name LIKE '张%' AND age = 20`，索引 `(name, age)` | 有 | 引擎层先按 name 与 age 双重过滤，再回表 |
| 同上 | 无（老版本） | 只按 name 过滤，全部回表后再筛 age |

`EXPLAIN` 中 Extra 出现 `Using index condition` 即表示启用了索引下推；出现 `Using index` 表示覆盖索引；出现 `Using filesort` 或 `Using temporary` 则是需要优化的信号。

## 本课小结
索引是「用空间和写入速度换查询速度」。判断是否该建索引，先看查询频率和选择性。

<!-- appendix:v1 -->

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

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「索引、B+树、复合索引」完成复述、实验和交付，每个结果都要能被别人检查。

先写 schema 与查询，再补边界和失败数据，最后看执行计划与锁等待。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「索引」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「B+树」是什么关系？

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
- 至少覆盖「索引」和「B+树」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Indexes

**Summary:** B+ trees, leftmost prefix and when indexes fail.

**Category:** Database  
**Level:** 进阶  
**Key terms:** 索引, B+树, 复合索引, 最左前缀, EXPLAIN

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：PostgreSQL / MySQL / SQLite 等主流数据库
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：索引、B+树、复合索引、最左前缀、EXPLAIN
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- top50-rewrite:v1 -->

## 课程专属精读：索引

### 一、知识地图

| 主题 | 核心要点 | 验证方式 |
| --- | --- | --- |
| 索引解决什么问题 | 没有索引时，数据库只能全表扫描，逐行比对。 | 复述要点 + 举一个反例 |
| B+ 树索引 | 主流关系型数据库的索引底层多用 B+ 树： | 运行示例 + 换一个边界输入 |
| 创建与使用 | CREATE INDEX idxstudentscity ON students(city); | 运行示例 + 换一个边界输入 |
| 什么时候索引会失效 | 在索引列上做运算或函数调用 SELECT FROM students WHERE YEAR(createdat) = 2024; | 运行示例 + 换一个边界输入 |
| 用 EXPLAIN 验证 | EXPLAIN QUERY PLAN SELECT FROM students WHERE city = '上海'; | 运行示例 + 换一个边界输入 |
| B+ 树查找过程示例 | 以 WHERE id = 42 为例（假设每页存 100 个键、树高 3 层）： | 运行示例 + 换一个边界输入 |

### 二、机制与验证

1. **索引解决什么问题**：没有索引时，数据库只能全表扫描，逐行比对。 验证方式：先复述要点，再举一个反例说明边界。
2. **B+ 树索引**：主流关系型数据库的索引底层多用 B+ 树： 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
3. **创建与使用**：CREATE INDEX idxstudentscity ON students(city); 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
4. **什么时候索引会失效**：在索引列上做运算或函数调用 SELECT FROM students WHERE YEAR(createdat) = 2024; 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
5. **用 EXPLAIN 验证**：EXPLAIN QUERY PLAN SELECT FROM students WHERE city = '上海'; 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。
6. **B+ 树查找过程示例**：以 WHERE id = 42 为例（假设每页存 100 个键、树高 3 层）： 验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。

### 三、专属检查问题

1. 「索引解决什么问题」要解决什么问题？请用一句话说明，并给出一个具体例子。
2. 「B+ 树索引」的输入和输出分别是什么？
3. 「创建与使用」最常见的失败方式是什么？如何定位？
4. 「什么时候索引会失效」的适用边界在哪里？什么情况下不该使用？
5. 「用 EXPLAIN 验证」和相邻主题相比，最关键的差别是什么？
6. 「B+ 树查找过程示例」如何验证自己真的掌握了？写出一个可执行的检查步骤。

### 四、故障排查

1. 固定输入和环境，确认问题能稳定复现。
2. 找到第一个异常状态，不从最终错误倒推。
3. 每次只改一个变量，记录预测和真实结果。
4. 修复后补边界、失败与重复执行三类测试。

## 专属复习题库

**问：索引解决什么问题的核心要点是什么？**

答：没有索引时，数据库只能全表扫描，逐行比对。

**问：B+ 树索引的核心要点是什么？**

答：主流关系型数据库的索引底层多用 B+ 树：

**问：创建与使用的核心要点是什么？**

答：CREATE INDEX idxstudentscity ON students(city);

**问：什么时候索引会失效的核心要点是什么？**

答：在索引列上做运算或函数调用 SELECT FROM students WHERE YEAR(createdat) = 2024;

**问：用 EXPLAIN 验证的核心要点是什么？**

答：EXPLAIN QUERY PLAN SELECT FROM students WHERE city = '上海';

**问：B+ 树查找过程示例的核心要点是什么？**

答：以 WHERE id = 42 为例（假设每页存 100 个键、树高 3 层）：

## 逐步练习：索引

### 练习 1：索引解决什么问题

1. 不看原文，用自己的话复述：没有索引时，数据库只能全表扫描，逐行比对。
2. 举一个正例和一个反例，说明边界在哪里。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 2：B+ 树索引

1. 不看原文，用自己的话复述：主流关系型数据库的索引底层多用 B+ 树：
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 3：创建与使用

1. 不看原文，用自己的话复述：CREATE INDEX idxstudentscity ON students(city);
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 4：什么时候索引会失效

1. 不看原文，用自己的话复述：在索引列上做运算或函数调用 SELECT FROM students WHERE YEAR(createdat) = 2024;
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 5：用 EXPLAIN 验证

1. 不看原文，用自己的话复述：EXPLAIN QUERY PLAN SELECT FROM students WHERE city = '上海';
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

### 练习 6：B+ 树查找过程示例

1. 不看原文，用自己的话复述：以 WHERE id = 42 为例（假设每页存 100 个键、树高 3 层）：
2. 跑通本课示例，再把其中一个输入换成边界值，记录输出差异。
3. 把结论写成两行笔记：一行结论，一行验证方式。

## 故障排查手册：索引

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
| 「索引解决什么问题」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「B+ 树索引」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「创建与使用」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「什么时候索引会失效」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「用 EXPLAIN 验证」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |
| 「B+ 树查找过程示例」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | 固定最小复现，只改一个变量并回归 |

## 自测与面试：索引

1. 「索引解决什么问题」的输入和输出分别是什么？
2. 「B+ 树索引」最常见的失败方式是什么？如何定位？
3. 「创建与使用」的适用边界在哪里？什么情况下不该使用？
4. 「什么时候索引会失效」和相邻主题相比，最关键的差别是什么？
5. 「用 EXPLAIN 验证」如何验证自己真的掌握了？写出一个可执行的检查步骤。
6. 「B+ 树查找过程示例」要解决什么问题？请用一句话说明，并给出一个具体例子。

## 专属进阶任务 5：索引

把本课 6 个主题串成一个小练习：选其中一个主题做出可运行的例子，再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。

### 验收标准

- 例子可以独立运行，输出与预期一致。
- 两条边界用例都说清了输入、预期与实际结果。
- 验证结论用一句话写清，不依赖“感觉正确”。

<!-- full-english-guide:v1 -->
## Full English Study Guide

### Overview

**Indexes** focuses on B+ trees, leftmost prefix and when indexes fail.

### Learning Outcomes

- Explain what **Indexes** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Indexes**
- Related terms: 索引, B+树, 复合索引, 最左前缀
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 索引解决什么问题 | Index解决什么问题 |
| B+ 树索引 | B+ 树Index |
| 创建与使用 | 创建与使用 |
| 什么时候索引会失效 | 什么时候Index会失效 |
| 索引的代价 | Index的代价 |
| 用 EXPLAIN 验证 | 用 EXPLAIN 验证 |
| B+ 树查找过程示例 | B+ 树查找过程示例 |
| 索引失效实例对照 | Index失效实例对照 |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [PostgreSQL 文档](https://www.postgresql.org/docs/) | SQL、索引与事务 |
| [SQLite 文档](https://sqlite.org/docs.html) | 嵌入式数据库与 SQL 行为 |

> 本课主题：B+ 树、最左前缀原则，以及索引什么时候失效。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

