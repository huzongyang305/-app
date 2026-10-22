# SQL Foundation

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Foundations -- Expected duration: 16 minutes

## Learning objectives

- I can explain what the SQL Foundation is about, not just words.
- The relationship between SQL, SELECT, INSERT and UPDATE is clear.
- It's a way to put the knowledge back in "the database" and show it at its borders with each other.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: tabulation, additions and deletions, grouping and connection queries.

## Pre-knowledge

- The basic file, command line or browser operation is performed; the key words of this course are checked first when there are unfamiliar terms.
- This course stage: Foundation. It is recommended to read and write simple codes or commands, with basic concepts such as variables, input output, etc.
- Before we begin: SQL, SELECT, INSERT.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## What's SQL?

SQL (Structive Query Language) is the standard language for an operational relationship database.

- New
- Query
- Zero change.
- Remove

## Form

```sql
CREATE TABLE students (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT    NOT NULL,
    age     INTEGER CHECK (age >= 0),
    city    TEXT    DEFAULT '未知',
    score   REAL
);
```

Common limits: ⟦ 0 primary key, 1 non-empty, ̄2 sole, ́3 value check and the default value of 4.

## Add & Delete

```sql
INSERT INTO students (name, age, city, score)
VALUES ('小明', 18, '上海', 92.5);

UPDATE students
SET score = 95
WHERE name = '小明';

DELETE FROM students
WHERE id = 1;
```

** Important**: 0 and 1 must write 2 or it will work on the whole table.

## Query

```sql
-- 查询指定列
SELECT name, score FROM students;

-- 条件、排序、分页
SELECT name, score
FROM students
WHERE age >= 18 AND city = '上海'
ORDER BY score DESC
LIMIT 10 OFFSET 20;

-- 聚合与分组
SELECT city, COUNT(*) AS total, AVG(score) AS avg_score
FROM students
GROUP BY city
HAVING COUNT(*) > 5;
```

## Connect Query

```sql
-- 内连接：只保留两边都匹配的行
SELECT s.name, c.title
FROM students AS s
JOIN courses AS c ON s.course_id = c.id;

-- 左连接：保留左表全部行，右表没有匹配则为 NULL
SELECT s.name, c.title
FROM students AS s
LEFT JOIN courses AS c ON s.course_id = c.id;
```

## Implementation order

SQL has a different writing order and implementation sequence, which helps to sort out problems:

```text
书写：SELECT -> FROM -> WHERE -> GROUP BY -> HAVING -> ORDER BY -> LIMIT
执行：FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT
```

## JOIN & Sub-Query Examples

```sql
-- 每个用户的订单数与总金额（只统计有订单的用户）
SELECT u.id, u.name, COUNT(o.id) AS orders, COALESCE(SUM(o.amount), 0) AS total
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id, u.name;

-- 找出消费最高的用户（子查询写法）
SELECT * FROM users
WHERE id = (SELECT user_id FROM orders GROUP BY user_id ORDER BY SUM(amount) DESC LIMIT 1);

-- 用 EXISTS 判断「下过单的用户」（通常比 IN 更快且不受 NULL 影响）
SELECT * FROM users u WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

Three formulations:** IN** for small results set,** EXISTS** for large tables and** JOIN** for two table fields at the same time.After the count, be careful to use one and not two; otherwise a user without an order is counted as one.

## Actual impact of the order of implementation

1. ⟦ Filter lines before grouping, 1 filter groups after grouping - spelling errors in aggregation conditions are common sources of error reporting.
2. The aliases in the ⟦0 are usually not available for use in a 1 (because WERE is first executed), but they can be used in two.
3. ⟦ final execution, so make a page in the sub-Quest carefully and sort it out.
4. The polymer function cannot be written directly in `HAVING`.

## It's the end of this class.
The list of CRD + WHERE conditions, combined groups and JOIN will be used to cover most daily needs.

<!-- appendix:v1 -->

## SQL Catalog

|Category|Role|Common statement|
| --- | --- | --- |
| DDL |Define Structure| `CREATE`、`ALTER`、`DROP`、`TRUNCATE` |
| DML |Modify Data| `INSERT`、`UPDATE`、`DELETE` |
| DQL |Query Data| `SELECT` |
| DCL |Permission Controls| `GRANT`、`REVOKE` |
| TCL |Service control| `BEGIN`、`COMMIT`、`ROLLBACK`、`SAVEPOINT` |

## Query Subsequence

```text
FROM / JOIN  →  WHERE  →  GROUP BY  →  HAVING  →  SELECT  →  DISTINCT
    →  ORDER BY  →  LIMIT / OFFSET
```

Understanding the order explains two common questions: why ⟦0 cannot use an alias (mostly in a database) as defined, and why aggregation conditions have to be written.

## JOIN type quick check

|Type|Result|Typical uses|
| --- | --- | --- |
| `INNER JOIN` |Keep Only Lines|Associated data|
| `LEFT JOIN` |Keep Left Table All|Main Table + Optional Association|
| `RIGHT JOIN` |Keep Right Table All|Very rare, rewritten with LEFT|
| `FULL JOIN` |Keep it both.|Look for a difference.|
| `CROSS JOIN` |Carteco.|Generate combinations (practically)|

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

## Frequent Functions Scanning

|Category|Functions|
| --- | --- |
|Aggregation| `COUNT`、`SUM`、`AVG`、`MIN`、`MAX`、`GROUP_CONCAT` |
|String| `CONCAT`、`SUBSTRING`、`TRIM`、`UPPER`、`LIKE` |
|Value| `ROUND`、`CEIL`、`FLOOR`、`ABS`、`MOD` |
|Date| `NOW`、`CURDATE`、`DATE_ADD`、`DATEDIFF`、`DATE_FORMAT` |
|Conditions| `CASE WHEN`、`IFNULL`、`COALESCE`、`NULLIF` |
|Window| `ROW_NUMBER`、`RANK`、`LAG`、`SUM() OVER` |

## Common Error Table

|It's easy to write the wrong thing.|Actual|Reasons and correct practices|
| --- | --- | --- |
|0/ 1 without 2|The whole watch was changed or deleted.|First, you'll have to confirm the range and then implement it with a limit on the number of lines.|
|Use Zero.|Transfer redundancy, index failure risk|Clear list of required columns|
| `WHERE amount = NULL` |I can't find anything.|Use ⟦0/ 1|
|⟦Statistics|Low number|Number of Statistics Lines|
|Filter columns containing NULL|NULL Line excluded|Visible processing of NULL conditions|
|String Date Direct Comparison|It's not accurate.|Use date type or visible|
|Invisible Type Conversion|Index Invalid|Align column with parameter type|
|I don't think so.|The sequence is not clear.|Page Breaks must be visible|
|Put the aggregator in a zero.|Syntax Error|Use Zero.|
|Construct SQL with String|Infusion of risk|Use Parametric Query|

## Self-Detected List

- [ ] Can reverse the order of execution of the query sub-rules.
- [ Chuckles ] Distinguished with one, two and three.
- [ ] Write ⟦/ 1⟧ to verify the impact.
- [ ] Page-by-page Query Sequence.
- [ ] Use all parameterized queries and do not spell SQL strings.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeat, experiment and deliver around SQL, SELECT, each result to be checked.

Write schema and query, fill in the border and fail data, and lastly watch implementation plans and locks.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the "SQL Base"?
2. Without it, what concrete consequences would there be?
3. What's it got to do with SELECT?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Write a query on the SQLite or paper table structure to verify normal data, empty values and boundary data respectively.

Mission requests:

- The result must be checked, not just “I understand”.
- "SQL" and "SELEECT," at least.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** SQL Basics

**Summary:** DDL, CRUD, aggregation, grouping and joins.

**Category:** Database  
**Level:** Foundation
**Key terms:** SQL, SELECT, INSERT, UPDATE, DELETE, JOIN

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: Foundation
- Applicable environment: mainstream databases such as PostgreSQL/ MySQl / SQLite
- Source: Internal structured curriculum and engineering practices
- Related topics: SQL, SELEECT, INSERT, UPDATE, DELETE, JOIN
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**SQL Basics** focuses on DDL, CRUD, aggregation, grouping and joins.

### Learning Outcomes

- Explain what **SQL Basics** solves and when it should be used.
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

- Topic: **SQL Basics**
- Related terms: SQL, SELECT, INSERT, UPDATE
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning Objectives |
|Pre-knowledge| Pre-knowledge |
|What's SQL?| What is SQL |
|Form| Build Table |
|Add & Delete| Addition, deletion and modification |
|Query| Querying MusicBrainz... |
|Connect Query| Connection Query |
|Implementation order| Execution Order |
|JOIN & Sub-Query Examples| Join and Subquery Instances |
|Actual impact of the order of implementation| Actual Impact of Execution Order |

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

