# SQL 基础

![SQL JOIN 四种连接方式](images/diagram_sql_join.webp)

![SQL 基础](images/remaining_sql_basics.webp)

> 内容更新时间：2026-10-06 · 学习阶段：基础 · 预计用时：45 分钟

## 本节知识框架

**课程定位**：所属分类为「数据库」，课程主题为「SQL 基础」，学习阶段为「基础」，建议用时 45 分钟。

**本课要解决的主问题**：建表、增删改查、聚合分组与连接查询。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「SQL 基础」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「SQL 基础」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「SQL」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：没有硬性先修课；仍建议先具备本分类的基础阅读与操作能力。

**学习位置**：本课位于《SQL 查询入门》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《索引》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释SQL 基础解决了什么问题，而不是只背术语。
- 能说清 「SQL」、「SELECT」、「INSERT」、「UPDATE」 之间的关系，并分别举出一个例子。
- 能把 SQL 放回「SQL 基础」的知识体系，说明它和 SELECT 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：建表、增删改查、聚合分组与连接查询。

**教材衔接：前置知识**

- 能独立打开与保存文件即可；SELECT 会在正文中从零解释。
- 本课阶段：基础。建议先掌握同一分类的基础课程，并能独立运行正文里的 AUTOINCREMENT 示例。
- 开始前先复习：SQL、SELECT、INSERT。
- 如果 SQL 是什么 这一步看不懂，先记录具体卡点，再用 AUTOINCREMENT 复现一遍。

**教材衔接：本课小结**

先掌握「单表 CRUD + WHERE 条件 + 聚合分组 + JOIN」，就能覆盖大部分日常需求。

## 核心概念定义

> 阅读约定：本课先给「SQL 基础」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| SQL | 用于查询和修改关系数据库的结构化查询语言。 | 仅在「SQL 基础」明确给出的输入、版本与资源条件下成立。 |
| SELECT | 理解顺序能解释两个常见疑问：为什么 WHERE 不能用 SELECT 里定义的别名（多数数据库），为什么聚合条件必须写 HAVING。 | 仅在「SQL 基础」明确给出的输入、版本与资源条件下成立。 |
| INSERT | SQL 中向表中新增一行或多行数据的语句。 | 仅在「SQL 基础」明确给出的输入、版本与资源条件下成立。 |
| UPDATE | SQL 中修改表中已存在行的语句。 | 仅在「SQL 基础」明确给出的输入、版本与资源条件下成立。 |
| DELETE | 重要：UPDATE 和 DELETE 一定要写 WHERE，否则会作用到整张表。 | 仅在「SQL 基础」明确给出的输入、版本与资源条件下成立。 |
| JOIN | 三种写法的选择：IN 适合小结果集，EXISTS 适合大表相关判断，JOIN 适合同时取两张表的字段。 | 仅在「SQL 基础」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「SQL 基础」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：JOIN 类型速查**

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

## 原理与运行机制

### 机制总览

1. **建立输入**：把「SQL」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「SELECT」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「INSERT」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「SQL 基础」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | SQL | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | SELECT | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | INSERT | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「SQL 基础」自己的示例验证。「SQL 基础」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：执行顺序的实际影响**

1. `WHERE` 在分组前过滤行，`HAVING` 在分组后过滤组——聚合条件的写法错误是常见报错来源。
2. `SELECT` 中的别名通常不能在 `WHERE` 里使用（因为 WHERE 先执行），但在 `ORDER BY` 中可用。
3. `LIMIT` 最后执行，所以在子查询里做分页要小心与外层排序的配合。
4. 聚合函数不能直接写在 `WHERE` 中（应用 `HAVING`）。

**教材衔接：常用函数速查**

| 类别 | 函数 |
| --- | --- |
| 聚合 | `COUNT`、`SUM`、`AVG`、`MIN`、`MAX`、`GROUP_CONCAT` |
| 字符串 | `CONCAT`、`SUBSTRING`、`TRIM`、`UPPER`、`LIKE` |
| 数值 | `ROUND`、`CEIL`、`FLOOR`、`ABS`、`MOD` |
| 日期 | `NOW`、`CURDATE`、`DATE_ADD`、`DATEDIFF`、`DATE_FORMAT` |
| 条件 | `CASE WHEN`、`IFNULL`、`COALESCE`、`NULLIF` |
| 窗口 | `ROW_NUMBER`、`RANK`、`LAG`、`SUM() OVER` |

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 SQL、SELECT | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「SQL 基础」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「SQL 基础」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`system_database`，用于动手验证《SQL 基础》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《SQL 基础》原文中的最小示例。先预测《SQL 基础》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```sql
CREATE TABLE students (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT    NOT NULL,
    age     INTEGER CHECK (age >= 0),
    city    TEXT    DEFAULT '未知',
    score   REAL
);
```

**教材衔接：SQL 是什么**

SQL（结构化查询语言）是操作关系型数据库的标准语言。日常使用可以归纳为四类操作，也就是常说的 **CRUD**：

- `INSERT` 新增
- `SELECT` 查询
- `UPDATE` 修改
- `DELETE` 删除

**教材衔接：建表**

```sql
CREATE TABLE students (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT    NOT NULL,
    age     INTEGER CHECK (age >= 0),
    city    TEXT    DEFAULT '未知',
    score   REAL
);
```

常用约束：`PRIMARY KEY` 主键、`NOT NULL` 非空、`UNIQUE` 唯一、`CHECK` 取值检查、`DEFAULT` 默认值。

**教材衔接：增删改**

```sql
INSERT INTO students (name, age, city, score)
VALUES ('小明', 18, '上海', 92.5);

UPDATE students
SET score = 95
WHERE name = '小明';

DELETE FROM students
WHERE id = 1;
```

**重要**：`UPDATE` 和 `DELETE` 一定要写 `WHERE`，否则会作用到整张表。

**教材衔接：查询**

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

**教材衔接：连接查询**

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

**教材衔接：执行顺序**

SQL 的书写顺序和执行顺序不同，理解它有助于排查问题：

```text
书写：SELECT -> FROM -> WHERE -> GROUP BY -> HAVING -> ORDER BY -> LIMIT
执行：FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT
```

**教材衔接：JOIN 与子查询实例**

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

三种写法的选择：**IN** 适合小结果集，**EXISTS** 适合大表相关判断，**JOIN** 适合同时取两张表的字段。`LEFT JOIN` 后统计时注意用 `COUNT(o.id)` 而不是 `COUNT(*)`，否则没有订单的用户也会被算成 1。

**教材衔接：SQL 语句分类速查**

| 类别 | 作用 | 常见语句 |
| --- | --- | --- |
| DDL | 定义结构 | `CREATE`、`ALTER`、`DROP`、`TRUNCATE` |
| DML | 修改数据 | `INSERT`、`UPDATE`、`DELETE` |
| DQL | 查询数据 | `SELECT` |
| DCL | 权限控制 | `GRANT`、`REVOKE` |
| TCL | 事务控制 | `BEGIN`、`COMMIT`、`ROLLBACK`、`SAVEPOINT` |

**教材衔接：查询子句执行顺序**

```text
FROM / JOIN  →  WHERE  →  GROUP BY  →  HAVING  →  SELECT  →  DISTINCT
    →  ORDER BY  →  LIMIT / OFFSET
```

理解顺序能解释两个常见疑问：为什么 `WHERE` 不能用 `SELECT` 里定义的别名（多数数据库），为什么聚合条件必须写 `HAVING`。

## 时间/空间复杂度或性能分析

**复杂度证据**：「SQL 基础」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「SQL 基础」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「SQL 基础」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《SQL 基础》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「SQL 基础」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

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

**教材衔接：故障现场**

### 现场 1：UPDATE / DELETE 不带 WHERE

**症状**：在《SQL 基础》的复现场景中，全表被改或被删。

**根因**：当出现“UPDATE / DELETE 不带 WHERE”时，执行路径已经绕过了《SQL 基础》的关键约束，最终以“全表被改或被删”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《SQL 基础》的问题，先 SELECT 确认范围，再执行并限制影响行数。

**验证**：保留《SQL 基础》里触发“全表被改或被删”的输入、版本和日志，按“先 SELECT 确认范围，再执行并限制影响行数”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：用 SELECT *

**症状**：在《SQL 基础》的复现场景中，传输冗余、索引失效风险。

**根因**：当出现“用 SELECT *”时，执行路径已经绕过了《SQL 基础》的关键约束，最终以“传输冗余、索引失效风险”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《SQL 基础》的问题，明确列出需要的列。

**验证**：保留《SQL 基础》里触发“传输冗余、索引失效风险”的输入、版本和日志，按“明确列出需要的列”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：WHERE amount = NULL

**症状**：在《SQL 基础》的复现场景中，查不到任何行。

**根因**：“查不到任何行”只是表层结果。向上追溯会落到“WHERE amount = NULL”这一步，因为它省略了《SQL 基础》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《SQL 基础》的问题，用 IS NULL / IS NOT NULL。

**验证**：保留《SQL 基础》里触发“查不到任何行”的输入、版本和日志，按“用 IS NULL / IS NOT NULL”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 关联 | 《索引》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《SQL 查询入门》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《索引》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「SQL 基础」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《SQL 基础》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

要删除表中年龄大于 60 的记录，正确的写法是？

A. REMOVE FROM students WHERE age > 60;
B. DROP TABLE students WHERE age > 60;
C. DELETE FROM students;
D. DELETE FROM students WHERE age > 60;

**参考答案**：DELETE FROM students WHERE age > 60;

**解析**：在「SQL 基础」里，DELETE FROM students WHERE age > 60;。DELETE 配合 WHERE 精确删除。「SQL 基础」要求先交代SQL、SELECT、INSERT的前提再下结论，所以“DELETE FROM students”只在题干“要删除表中年龄大于 60 的记录”给定的条件下成立。

### 自测 2

阅读「SQL 基础」正文里的这段 SQL 代码，下面哪一项判断是正确的？

```sql
INSERT INTO students (name, age, city, score)
VALUES ('小明', 18, '上海', 92.5);

UPDATE students
SET score = 95
WHERE name = '小明';

DELETE FROM students
WHERE id = 1;
```

A. 这段代码会产生可观察的输出，运行后能看到结果。
B. 这段代码包含循环结构，同一段逻辑会被重复执行。
C. 这段代码只做静态声明，没有循环、分支或可观察输出。
D. 这段代码会读取外部输入，结果依赖传入的数据。

**参考答案**：这段代码只做静态声明，没有循环、分支或可观察输出。

**解析**：在「SQL 基础」里，题干的正确项是这段代码只做静态声明，没有循环、分支或可观察输出，在「SQL 基础」里它只能证明SQL相关约束存在，不能替代真实运行证据。把输入或边界换成空值、极值或失败情况后，结论要以「SQL 基础」的实际运行结果为准。这道题的关键在「SQL 基础」的SQL、SELECT、INSERT：先确认题干“阅读SQL 基础正文里的这段 SQL”问的是哪一步，再排除偷换前提的选项。

### 自测 3

围绕“SQL 基础”中的 SQL、SELECT、INSERT，下列哪两项是本课强调的实践判断？

A. 学习 SQL 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 SQL 的常规示例通过，就可以跳过边界与异常路径
C. 验证 SELECT 时要固定版本并覆盖边界输入，结论才可复现
D. 把 SELECT 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 SQL 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 SELECT 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把SQL 基础拆成概念、示例与故障现场三部分，因此判断 SQL 时必须同时交代输入、输出和失败路径，这使“学习 SQL 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在SQL 基础里，判断 SELECT 时要固定版本与边界输入，所以“验证 SELECT 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 能背出查询子句的执行顺序。
- [ ] 分得清 `WHERE` 与 `HAVING`、`COUNT(*)` 与 `COUNT(col)`。
- [ ] 写 `UPDATE` / `DELETE` 前先用 `SELECT` 验证影响范围。
- [ ] 分页查询带确定性排序。
- [ ] 全部使用参数化查询，不拼接 SQL 字符串。

**教材衔接：动手练习**

> 本课练习重点：围绕「SQL、SELECT、INSERT」完成复述、实验和交付，每个结果都要能被别人检查。

先确定 SELECT 的约束，再决定索引与事务边界。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. SQL 基础解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「SELECT」是什么关系？

验收标准：回答里必须出现 SQL，并写出一个让结论失效的边界条件。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先原样跑通正文里的 `AUTOINCREMENT`，再只改SQL相关的输入，按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。

### 练习 3：交付一个小结果（30 分钟）

用三类数据验证 SELECT：正常、空值与越界。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「SQL」和「SELECT」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

把「SQL 基础」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：只把 SQL 的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「SQL 基础」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响SQL。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 SQL 数据，保持输出格式与任务 1 一致。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「要删除表中年龄大于 60 的记录，正确的写法是？」的判断依据。
- [ ] 不看解析，能说出「对 GROUP BY 的结果做过滤，应该使用哪个关键字？」的判断依据。
- [ ] 不看解析，能说出「执行 UPDATE 时忘记写 WHERE 会怎样？」的判断依据。
- [ ] 不看解析，能说出「COUNT(*) 与 COUNT(列名) 的关键区别是？」的判断依据。
- [ ] 不看解析，能说出「LEFT JOIN 后统计右表记录数，应该怎么写？」的判断依据。
- [ ] 至少运行一次 AUTOINCREMENT 的示例，记录输入、输出和 SQL 的边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

把「SQL 基础」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `SQL` | 用于查询和修改关系数据库的结构化查询语言。 |
| `SELECT` | 理解顺序能解释两个常见疑问：为什么 WHERE 不能用 SELECT 里定义的别名（多数数据库），为什么聚合条件必须写 HAVING。 |
| `INSERT` | SQL 中向表中新增一行或多行数据的语句。 |
| `UPDATE` | SQL 中修改表中已存在行的语句。 |
| `DELETE` | 重要：UPDATE 和 DELETE 一定要写 WHERE，否则会作用到整张表。 |
| `JOIN` | 三种写法的选择：IN 适合小结果集，EXISTS 适合大表相关判断，JOIN 适合同时取两张表的字段。 |

## 考点精讲

### 考点 1：概念判断·SQL

- **题目**：要删除表中年龄大于 60 的记录，正确的写法是？
- **判断依据**：在「SQL 基础」里，DELETE FROM students WHERE age > 60;。DELETE 配合 WHERE 精确删除。「SQL 基础」要求先交代SQL、SELECT、INSERT的前提再下结论，所以“DELETE FROM students”只在题干“要删除表中年龄大于 60 的记录”给定的条件下成立。

### 考点 2：代码补全·SQL

- **题目**：阅读「SQL 基础」正文里的这段 SQL 代码，下面哪一项判断是正确的？
- **判断依据**：在「SQL 基础」里，题干的正确项是这段代码只做静态声明，没有循环、分支或可观察输出，在「SQL 基础」里它只能证明SQL相关约束存在，不能替代真实运行证据。把输入或边界换成空值、极值或失败情况后，结论要以「SQL 基础」的实际运行结果为准。这道题的关键在「SQL 基础」的SQL、SELECT、INSERT：先确认题干“阅读SQL 基础正文里的这段 SQL”问的是哪一步，再排除偷换前提的选项。

### 考点 3：多选辨析·SQL

- **题目**：围绕“SQL 基础”中的 SQL、SELECT、INSERT，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把SQL 基础拆成概念、示例与故障现场三部分，因此判断 SQL 时必须同时交代输入、输出和失败路径，这使“学习 SQL 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在SQL 基础里，判断 SELECT 时要固定版本与边界输入，所以“验证 SELECT 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 4：概念判断·SQL

- **题目**：COUNT(*) 与 COUNT(列名) 的关键区别是？
- **判断依据**：在「SQL 基础」里，结论应落在「COUNT(列名) 会忽略该列的 NULL 值」。统计非空值数量时必须用 COUNT(列名)，否则会把 NULL 行也算进去。在「SQL 基础」里，这道题要求区分概念与边界，「COUNT(列名) 会忽略该列的 NULL 值」只有在题干给出的前提下才成立，而「COUNT(列名) 只能用于主键，但这会引入新的复杂度」、「COUNT(*) 更慢」缺少同一组条件。

### 考点 5：概念判断·SQL

- **题目**：LEFT JOIN 后统计右表记录数，应该怎么写？
- **判断依据**：在「SQL 基础」里，COUNT(右表.主键)。COUNT 会把没有匹配的 NULL 行也计为 1，统计右表要用其主键列。回到「SQL 基础」的正文示例，用“LEFT JOIN 后统计右表记录数”走一遍SQL、SELECT、INSERT的完整流程，能复现的结论才可以保留。

### 考点 6：填空·SQL

- **题目**：补全代码：「SQL 基础」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `SELECT u.id, u.name, COUNT(o.id) AS orders, ____(SUM(o.amount), 0) AS total`
- **判断依据**：在「SQL 基础」里，COALESCE。回到「SQL 基础」的正文示例，用“补全代码”走一遍SQL、SELECT、INSERT的完整流程，能复现的结论才可以保留。回到SQL、SELECT、INSERT本身再看一遍：只有“COALESCE”与题干“基础示例中”的前提一致，结论才成立。

## English Overview

**Title:** SQL Basics

**Summary:** DDL, CRUD, aggregation, grouping and joins.

**Category:** Database
**Level:** 基础
**Key terms:** SQL, SELECT, INSERT, UPDATE, DELETE, JOIN

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：基础
- 适用环境：PostgreSQL / MySQL / SQLite 等主流数据库；本课聚焦其中的 SQL。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：SQL、SELECT、INSERT、UPDATE、DELETE、JOIN
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## Full English Study Guide

### Overview

**SQL Basics** focuses on DDL, CRUD, aggregation, grouping and joins.

### Learning Outcomes

- Explain what **SQL Basics** solves and when it should be used.

### Glossary

- Topic: **SQL Basics**
- Related terms: SQL, SELECT, INSERT, UPDATE

## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning Objectives |
| 前置知识 | Pre-knowledge |
| SQL 是什么 | What is SQL |
| 建表 | Build Table |
| 增删改 | Addition, deletion and modification |
| 查询 | Querying MusicBrainz... |
| 连接查询 | Connection Query |
| 执行顺序 | Execution Order |
| JOIN 与子查询实例 | Join and Subquery Instances |
| 执行顺序的实际影响 | Actual Impact of Execution Order |

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-06-17
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [SQLite 文档](https://sqlite.org/docs.html) | 嵌入式 SQL 与事务 |
| [Use The Index, Luke](https://use-the-index-luke.com/) | SQL 索引与查询优化 |
| [数据库规范化](https://learn.microsoft.com/office/troubleshoot/access/database-normalization-description) | 范式与表设计 |

> 「SQL 基础」的链接用于离线阅读后的延伸核对；App 不会自动联网。
