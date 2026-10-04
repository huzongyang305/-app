# Index

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: progress

## Learning objectives

- I can explain what the index solves, not just a word.
- The relationship between Index, B+ Tree, Composite Index and Leftmost Prefix is clear.
- It's a way to put the knowledge back in "the database" and show it at its borders with each other.
- It is possible to complete this course and check its results using acceptance standards.

> Summary of sentence: B+ tree, leftmost prefix principle and when the index will expire.

## Pre-knowledge

- First, the SQL Foundation; if available, you can practice your own studies.
- This course stage: Progress. It is recommended to have a basic curriculum for the same classification and to be able to run the smallest examples in the text independently.
- Study before starting: Index, B+ Tree, Composite Index.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## What's the index for?

When there is no index, the database can only be scanned ** full table,** line-by-line. The index is like a directory of books that enables it to quickly locate its target data and drops the search from zero to one.

## B+ Tree Index

The index base of the mainstream relationship database is used more **B+ tree**:

- All data are at the leaf node and linked sequentially with a chain table.
- Non-leaf nodes are keyed, allowing for more branches and shorter trees.
- The leaf node table is well suited for range query and sorting.

```text
              [30 | 60]
            /     |      \
     [10|20]   [40|50]   [70|90]
        ↓          ↓          ↓
     叶子节点按顺序双向链表相连
```

Three times the disk I/O will be able to locate a line of data in tens of thousands.

## Create & Use

```sql
CREATE INDEX idx_students_city ON students(city);

-- 走索引：条件列是索引列
SELECT * FROM students WHERE city = '上海';

-- 复合索引遵循最左前缀原则
CREATE INDEX idx_name_age ON students(name, age);
-- 可用：WHERE name = ? / WHERE name = ? AND age = ?
-- 不可用：WHERE age = ?
```

## When's the index gonna expire?

```sql
-- 在索引列上做运算或函数调用
SELECT * FROM students WHERE YEAR(created_at) = 2024;

-- 以 % 开头的模糊查询无法使用普通索引
SELECT * FROM students WHERE name LIKE '%明';

-- 类型隐式转换
SELECT * FROM students WHERE phone = 13800000000;  -- phone 是字符串
```

Rewriting proposal: Move the calculation to one side of the constant, or use an index that covers the full text.

## Cost of indexing

The more the index, the better.

1. Use extra disk space.
2. You're gonna have to keep the index running.
3. Optimizer selects the wrong index more slowly.

Indexes are generally made only for **high frequency query conditions, connecting columns and sorting column**.

## Verify with EXPLAIN

```sql
EXPLAIN QUERY PLAN
SELECT * FROM students WHERE city = '上海';
```

Concerned about the presence of ⟦ (full table scanning) or ⟦1 (indexing).

## Example of the B+ tree search

Take the example of ⟦0 (assuming 100 keys per page, tree height:

```text
根节点（第 1 次 IO）：比较 42 落在哪个区间 → 定位到中间节点
中间节点（第 2 次 IO）：继续比较 → 定位到叶子页
叶子节点（第 3 次 IO）：页内二分查找 → 命中记录，返回
```

Ten million-degree data only ** 3 disks**, which is the reason why the index is faster than a full-scale scan. Range queries (⟦0) are read in chain order at leaf nodes and therefore range scanning is equally efficient.

## Index lapses

|Writing|Whether to go with the index|Reasons and changes|
| --- | --- | --- |
|Zero.|Come on.|Direct comparison of index columns|
| `WHERE YEAR(created_at) = 2024` |I'm not leaving.|There's a function in the column.|
|Zero.|I'm not leaving.|For prefix unknown read ⟦0 or full text index|
|⟦ (phone is string)|Maybe not.|Invisible type conversion to 0|
|⟦ (indexed to a)|Sorting|Build composite index, ⟦0 and let the filters and sorting go.|
|⟦ (index onlya)|Maybe not.|Disable into two queries, or create separate indexes|
|Composite index, zero. Up, one.|I'm not leaving.|Consider separate indexing for a leftmost prefix|

The verification method is always ⟦: see if type is a ⟦, key is hit and the number ofrows scan lines has dropped significantly.

## Override Indexes & Pushes

** Covering index**: All columns required for queries are included in the index and do not need to be returned.

|Query|Index|Whether to return the watch or not|
| --- | --- | --- |
|Zero.| `(city)` |Return Table (to take name)|
|Ibid.| `(city, name)` |** Not Return Table** Extra displays Using index|
|Zero.| `(city)` |Return table (all required)|

This is also a specific reason to slow down the search: it almost always leads back to tables.

** Indexed (ICP, MySQL 5.6+)**: The columns in the index are used to filter off unsatisfactory records and reduce the number of returns.

|Query|Is there an ICP?|Effects|
| --- | --- | --- |
|It's an index.|Yeah.|The engine layer is double filtered with the name and page before returning to the table|
|Ibid.|None (old version)|Press name to filter, and then sift all tables|

The presence of Extra means that an index push is enabled; the emergence of ⟦2=over-indexes; and the appearance of <3⟧ or 4 is a signal which needs optimization.

## It's the end of this class.
The index is "Spatial and Write Speed for Query".

<!-- appendix:v1 -->

## Index lapses and hits table

|SQL|Can I use the index?|Reason and rewrite proposal|
| --- | --- | --- |
| `WHERE name = 'abc'` |Yes.|Equivalent Query, Perfect|
| `WHERE name LIKE 'abc%'` |Yes.|Prefix to walk index|
| `WHERE name LIKE '%abc'` |I can't.|Left compatibility is not available; full text indexing or backwards|
| `WHERE YEAR(created_at) = 2024` |I can't.|column to function package;renumbered as ⟦0|
| `WHERE id + 1 = 10` |I can't.|column to calculate;to 0|
| `WHERE status = 1 OR user_id = 2` |Could be a full-scale scan.|Open with ⟦0 or create a joint index|
|⟦ (indexed to 1⟧)|Use only a|Violation of leftmost prefix; indexing column in search order|
|⟦ (listed as string)|I can't.|Invisible type conversion to function|
|⟦ (with index)|Yes.|The index is natural. It saves the order.|
|⟦ (indexed to 1⟧)|Yes.|Sort in the same order as the index column|
|I'm gonna need a watch.|Take the index, but return it.|Check only the necessary columns, or build an index|
| `WHERE deleted = 0 AND user_id = 5` |Yes, but it's low.|Low Differentiation Column to the Right|

## Indexing

|Scenes|Recommendations|
| --- | --- |
|HF equivalent query|Single or joint index, equal to above|
|HF range queries|The last in the range index.|
|Sort + Filter|Let the index order match ⟦0+1|
|Only a few columns|Build Index to Avoid Returning Table|
|Write very often.|The less index, the better. Every one of them.|
|Very Low Distinction Column (Sex, Status)|It doesn't make any sense to build a single index.|
|Long prefix string|Save space with prefix|
|Large Table and Index|Use an online DDL tool to avoid peaks|

## Check it out.

```sql
-- 1. 看优化器怎么执行，重点看 type / key / rows / Extra
EXPLAIN SELECT id, name FROM users WHERE email = 'a@b.com';

-- 2. 看真实耗时与扫描行数（MySQL 8）
EXPLAIN ANALYZE SELECT id, name FROM users WHERE email = 'a@b.com';

-- 3. 看表的索引清单与区分度
SHOW INDEX FROM users;
SELECT COUNT(DISTINCT email) / COUNT(*) AS selectivity FROM users;
```

The alarmous signals are: ⟦1 (full screen scan), 2 (no index) and 3 more than expected, 4 appears 5 or 6.

## Self-Detected List

- [ ] The maximum left prefix can be stated and the joint index column ordered accordingly.
- [ ] Knows that adding a function to the column, an implicit type conversion, causes the index to expire.
- [ ] Read the four fields of ⟦1, 2 and 4.
- [ ] Knows that low-differentiated columns are not suitable for separate indexing.
- [ ] Designing index coverage for high frequency queries to avoid returns.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of practice: Repeating, experimenting and delivering around Indexes, B+ Trees, each result being checked.

Write schema and query, fill in the border and fail data, and lastly watch implementation plans and locks.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with Index?
2. Without it, what concrete consequences would there be?
3. What's it got to do with the "B" tree?

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
- It's not like we have to be able to use the word "indicator" or "B+tree."
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Indexes

**Summary:** B+ trees, leftmost prefix and when indexes fail.

**Category:** Database  
**Level:** Progress
**Key terms:** Index, B+ Tree, Complex Index, Left Prefix, EXPLAIN

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: progress
- Applicable environment: mainstream databases such as PostgreSQL/ MySQl / SQLite
- Source: Internal structured curriculum and engineering practices
- Related themes: Index, B+ Tree, Composite Index, Left Prefix, EXPLAIN
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

<!-- top50-rewrite:v1 -->

## Course exclusive excellence: Index

### I. KNOWLEDGE

- **The index solves the problem**: if there is no index, the database can only be scanned in full** and cross-referenced. The index is like a directory of books that allows the database to quickly locate target data and reduces the search for ⟦0 to 1⟧.
- **B+ tree index**: Index base for mainstream relationship database**
- ** Created and used**: CREATE INDEX idx_students_city ON students (city);
- ** When the index will expire**
- **The price of the index is not as good:
- ** Validate with EXPLAIN**: EXPLAIN QUERY PLAN
- ** Example of the tree search process**: for example, ⟦0 (assuming 100 keys per page and 3 layers of trees):
- ** Cross-reference to index failure**: understand its definition, input, output and failed boundary.

### II. MECHANISMS AND VERIFICATION

|Theme|Questions to answer|Authentication Method|
| --- | --- | --- |
|What's the index for?|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|B+ Tree Index|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Create & Use|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|When's the index gonna expire?|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Cost of indexing|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Verify with EXPLAIN|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Example of the B+ tree search|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|
|Index lapses|What does it solve, what is the input and output?|Minimal example, boundary input, log or indicator|

### III. EXCHANGE ISSUES

1. What kind of problem does the index solve with an adjacent subject?
2. What's the B+ tree index with an adjacent theme?
3. What's the border between creating and using an adjacent theme?
4. When's the index going off with the adjacent subject?
5. What's the price of an index to a neighbouring subject?
6. Use EXPLAIN to verify the borders with each other?
7. B+ Examples of tree search processes. What are the boundaries with adjacent themes?
8. What is the boundary between index failure and adjacent subject?

### IV. FUNCTIONS CLASSING

1. Fixed input and environment, confirming problem recurrence.
2. Find the first anomaly, don't guess from the end.
3. Only one variable is changed, and projections and real results are recorded.
4. Rehabilitate borders, fail and repeat tests.

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
- Related terms: Index, B+ Tree, Composite Index, Left Prefix
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|What's the index for?|What does Index solve?|
|B+ Tree Index|B+Index|
|Create & Use|Create & Use|
|When's the index gonna expire?|When will Index fail?|
|Cost of indexing|Index's price.|
|Verify with EXPLAIN|Verify with EXPLAIN|
|Example of the B+ tree search|Example of the B+ tree search|
|Index lapses|Comparison of Index failures|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

