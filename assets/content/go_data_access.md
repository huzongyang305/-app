# Go 数据访问与连接池

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![database/sql 的事务与连接池](images/diagram_go_data_access.webp)

![Go 数据访问与连接池](images/remaining_go_data_access.webp)

## 本节知识框架

**课程定位**：所属分类为「Go」，课程主题为「Go 数据访问与连接池」，学习阶段为「进阶」，建议用时 50 分钟。

**本课要解决的主问题**：database/sql 事务模板、连接池参数与批量写入。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Go 数据访问与连接池」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Go 数据访问与连接池」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「database/sql」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Go 测试进阶：基准、模糊与集成》

**学习位置**：本课位于《Go 测试进阶：基准、模糊与集成》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Go 泛型与标准库实战》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Go 数据访问与连接池解决了什么问题，而不是只背术语。
- 能说清 「database/sql」、「连接池」、「事务」、「批量插入」 之间的关系，并分别举出一个例子。
- 能把 database/sql 放回「Go 数据访问与连接池」的知识体系，说明它和 连接池 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：database/sql 事务模板、连接池参数与批量写入。

**教材衔接：前置知识**

- 先完成上一课《Go 测试进阶：基准、模糊与集成》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Go 测试进阶：基准、模糊与集成」，或确认自己能独立跑通正文里的 SetConnMaxLifetime 示例。
- 开始前先复习：database/sql、连接池、事务。
- 看不懂就直接缩小例子：只保留 database/sql 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

- 核心问题：Go 数据访问与连接池不是孤立术语，而是在「Go」中解决一类具体问题。
- 关键关系：先分清「database/sql」与「连接池」的职责，再理解「事务」的适用边界。
- 判断标准：能解释 database/sql 的正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后写下 database/sql 的 3 条要点，再去做本课测验。

## 核心概念定义

> 阅读约定：本课先给「Go 数据访问与连接池」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| 连接池 | 复用一组已建立的数据库连接，避免每次请求都握手；需要配好最大连接数与超时。 | 仅在「Go 数据访问与连接池」明确给出的输入、版本与资源条件下成立。 |
| 事务 | 一组要么全部成功要么全部回滚的数据库操作。 | 仅在「Go 数据访问与连接池」明确给出的输入、版本与资源条件下成立。 |
| 批量插入 | 把多行数据合并成多值 INSERT 或批量语句，减少往返次数，是导入数据的基本优化。 | 仅在「Go 数据访问与连接池」明确给出的输入、版本与资源条件下成立。 |
| 参数化查询 | 用占位符绑定参数而不是拼接 SQL，既防注入也让数据库复用执行计划。 | 仅在「Go 数据访问与连接池」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Go 数据访问与连接池」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「连接池」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「事务」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「批量插入」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Go 数据访问与连接池」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | 连接池 | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | 事务 | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 批量插入 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Go 数据访问与连接池」自己的示例验证。「Go 数据访问与连接池」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：方案选型速查**

| 方案 | 类型安全 | 学习成本 | 适用 |
| --- | --- | --- | --- |
| `database/sql` | 手写扫描 | 低 | 简单查询、完全掌控 SQL |
| sqlc | 由 SQL 生成类型安全代码 | 中 | 想要类型安全又不想写 ORM |
| GORM | 链式 API + 自动迁移 | 中 | 快速开发 CRUD |
| ent | 代码生成 + 图查询 | 中高 | 复杂关系模型 |

要点：**无论用哪种方案，SQL 与索引设计仍是性能的决定因素**，ORM 只改变写法。

**教材衔接：必守规则速查**

| 规则 | 原因 |
| --- | --- |
| 永远用参数化查询 | 防止 SQL 注入 |
| 每个查询带 context 超时 | 避免慢查询拖垮服务 |
| 用 `rows.Close()` 与检查 `rows.Err()` | 释放连接并发现遍历中的错误 |
| 只取需要的列 | 减少网络与内存开销 |
| 分页用游标而非大 OFFSET | 深分页会扫描大量行 |
| 不要在循环里单条查询 | N+1 问题，改批量或 JOIN |
| 事务保持短小 | 长事务持锁、放大主从延迟 |
| 连接池与数据库上限对齐 | 连接打满会导致整体不可用 |

**教材衔接：版本与时效**

- 升级前确认 database/sql 的兼容范围，把不可回退的改动单独拆成一次提交。
- 模块校验、最小版本选择与供应链安全是生产升级的重点
- 官方发布说明：https://go.dev/doc/devel/release

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 升级时只动一个依赖版本，用 SetConnMaxLifetime 记录构建与运行结果。
- 回归范围锁定 SetConnMaxLifetime 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级后把 SetConnMaxLifetime 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 database/sql、连接池 | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Go 数据访问与连接池」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Go 数据访问与连接池」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:go`，用于动手验证《Go 数据访问与连接池》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Go 数据访问与连接池》原文中的最小示例。先预测《Go 数据访问与连接池》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```go
// 初始化连接池：显式设置参数并验证连通性
func NewDB(ctx context.Context, dsn string) (*sql.DB, error) {
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return nil, fmt.Errorf("打开数据库: %w", err)
	}
	db.SetMaxOpenConns(20)
	db.SetMaxIdleConns(20)
	db.SetConnMaxLifetime(30 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)

	pingCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	if err := db.PingContext(pingCtx); err != nil {
		return nil, fmt.Errorf("连接检测失败: %w", err)
	}
	return db, nil
}

// 事务模板：用 defer 保证回滚，提交失败也回滚
func Transfer(ctx context.Context, db *sql.DB, from, to int64, cents int64) error {
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return fmt.Errorf("开启事务: %w", err)
	}
	defer func() {
		_ = tx.Rollback()               // 已提交时返回 ErrTxDone，可忽略
	}()

	if _, err := tx.ExecContext(ctx,
		`UPDATE accounts SET balance = balance - $1 WHERE id = $2 AND balance >= $1`,
		cents, from); err != nil {
		return fmt.Errorf("扣款: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		`UPDATE accounts SET balance = balance + $1 WHERE id = $2`,
		cents, to); err != nil {
		return fmt.Errorf("入账: %w", err)
	}
	return tx.Commit()
}

// 批量插入：预编译语句 + 单事务，避免 N 次往返
func BatchInsert(ctx context.Context, db *sql.DB, rows [][]any) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	stmt, err := tx.PrepareContext(ctx, `INSERT INTO orders(user_id, amount_cents) VALUES ($1, $2)`)
	if err != nil {
		return err
	}
	defer stmt.Close()

	for _, row := range rows {
		if _, err := stmt.ExecContext(ctx, row...); err != nil {
			return fmt.Errorf("插入失败: %w", err)
		}
	}
	return tx.Commit()
}
```

**教材衔接：连接池参数速查**

| 参数 | 含义 | 建议 |
| --- | --- | --- |
| `SetMaxOpenConns` | 最大连接数 | 按数据库承载能力设定，避免打满 |
| `SetMaxIdleConns` | 空闲连接数 | 与最大连接数接近，减少频繁建连 |
| `SetConnMaxLifetime` | 连接最长存活 | 几分钟到半小时，避开数据库侧超时 |
| `SetConnMaxIdleTime` | 空闲多久回收 | 与负载波动匹配 |
| `context` 超时 | 单次查询超时 | 每个查询都要设 |

```go
// 初始化连接池：显式设置参数并验证连通性
func NewDB(ctx context.Context, dsn string) (*sql.DB, error) {
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		return nil, fmt.Errorf("打开数据库: %w", err)
	}
	db.SetMaxOpenConns(20)
	db.SetMaxIdleConns(20)
	db.SetConnMaxLifetime(30 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)

	pingCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	if err := db.PingContext(pingCtx); err != nil {
		return nil, fmt.Errorf("连接检测失败: %w", err)
	}
	return db, nil
}

// 事务模板：用 defer 保证回滚，提交失败也回滚
func Transfer(ctx context.Context, db *sql.DB, from, to int64, cents int64) error {
	tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return fmt.Errorf("开启事务: %w", err)
	}
	defer func() {
		_ = tx.Rollback()               // 已提交时返回 ErrTxDone，可忽略
	}()

	if _, err := tx.ExecContext(ctx,
		`UPDATE accounts SET balance = balance - $1 WHERE id = $2 AND balance >= $1`,
		cents, from); err != nil {
		return fmt.Errorf("扣款: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		`UPDATE accounts SET balance = balance + $1 WHERE id = $2`,
		cents, to); err != nil {
		return fmt.Errorf("入账: %w", err)
	}
	return tx.Commit()
}

// 批量插入：预编译语句 + 单事务，避免 N 次往返
func BatchInsert(ctx context.Context, db *sql.DB, rows [][]any) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	stmt, err := tx.PrepareContext(ctx, `INSERT INTO orders(user_id, amount_cents) VALUES ($1, $2)`)
	if err != nil {
		return err
	}
	defer stmt.Close()

	for _, row := range rows {
		if _, err := stmt.ExecContext(ctx, row...); err != nil {
			return fmt.Errorf("插入失败: %w", err)
		}
	}
	return tx.Commit()
}
```

**教材衔接：零基础详解：Go 访问数据库**

### 一句话说清它是什么

Go 用 `database/sql` 统一访问各种数据库：**连接池 + 预编译语句 + context + 事务** 是四块基石。
用 ORM 也可以，但先理解这四块，出问题时才知道从哪查。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 连接池 | 车队的车辆 | 复用连接，避免每次新建 |
| 预编译语句 | 固定模具 | SQL 结构与数据分离，防注入 |
| context | 任务时限 | 超时就取消，别一直等 |
| 事务 | 打包操作 | 要么全成功，要么全回滚 |
| N+1 查询 | 来回跑仓库 | 一次能取的别拆成 N 次 |

### 连接池的四个关键参数

```go
db, err := sql.Open("postgres", dsn)     // 注意：Open 不会真的连库
if err != nil {
    return err
}

db.SetMaxOpenConns(25)                   // 最大连接数
db.SetMaxIdleConns(10)                   // 空闲连接数
db.SetConnMaxLifetime(30 * time.Minute)  // 连接最长寿命
db.SetConnMaxIdleTime(5 * time.Minute)   // 空闲多久回收

ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
defer cancel()
if err := db.PingContext(ctx); err != nil {   // 真正验证连通性
    return fmt.Errorf("数据库不可用: %w", err)
}
```

| 参数 | 设太小 | 设太大 |
| --- | --- | --- |
| MaxOpenConns | 请求排队 | 压垮数据库 |
| MaxIdleConns | 频繁建连 | 占用连接 |
| ConnMaxLifetime | 用到被服务端断开的连接 | 连接复用不足 |

### 查询三步：Query、Scan、Close

```go
func ListUsers(ctx context.Context, db *sql.DB, minAge int) ([]User, error) {
    const query = `
        SELECT id, name, age
        FROM users
        WHERE age >= $1
        ORDER BY id
        LIMIT 100`

    rows, err := db.QueryContext(ctx, query, minAge)   // 参数化，别拼接
    if err != nil {
        return nil, fmt.Errorf("查询用户: %w", err)
    }
    defer rows.Close()                                  // 必须关闭

    var users []User
    for rows.Next() {
        var u User
        if err := rows.Scan(&u.ID, &u.Name, &u.Age); err != nil {
            return nil, fmt.Errorf("扫描行: %w", err)
        }
        users = append(users, u)
    }
    if err := rows.Err(); err != nil {                  // 别漏掉这一步
        return nil, fmt.Errorf("遍历结果: %w", err)
    }
    return users, nil
}
```

**三个必须做的动作**：`defer rows.Close()`、检查 `rows.Err()`、用 `QueryContext` 传 context。

### 单行查询与「没找到」

```go
var u User
err := db.QueryRowContext(ctx, query, id).Scan(&u.ID, &u.Name, &u.Age)
switch {
case errors.Is(err, sql.ErrNoRows):
    return User{}, ErrNotFound        // 业务错误，不是系统错误
case err != nil:
    return User{}, fmt.Errorf("查询用户 %d: %w", id, err)
}
```

不要把 `sql.ErrNoRows` 当成 500 错误返回给用户。

### 事务：三步不能少

```go
func Transfer(ctx context.Context, db *sql.DB, from, to int, amount int) error {
    tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
    if err != nil {
        return fmt.Errorf("开启事务: %w", err)
    }
    defer func() {
        if err != nil {                 // 出错就回滚
            _ = tx.Rollback()
        }
    }()

    if _, err = tx.ExecContext(ctx, `UPDATE accounts SET balance = balance - $1 WHERE id = $2`, amount, from); err != nil {
        return fmt.Errorf("扣款: %w", err)
    }
    if _, err = tx.ExecContext(ctx, `UPDATE accounts SET balance = balance + $1 WHERE id = $2`, amount, to); err != nil {
        return fmt.Errorf("入账: %w", err)
    }
    if err = tx.Commit(); err != nil {
        return fmt.Errorf("提交: %w", err)
    }
    return nil
}
```

注意 `defer` 里闭合的是外层的 `err` 变量，所以要用 `err =` 而不是 `:=`。

### 避免 N+1 查询

```go
// 反例：先查 100 个订单，再为每个订单查一次用户 —— 共 101 次查询
for _, o := range orders {
    _ = db.QueryRow("SELECT name FROM users WHERE id = $1", o.UserID)
}

// 正例：一次查回来，在内存里做映射
// SELECT id, name FROM users WHERE id = ANY($1)
nameByID := make(map[int]string, len(userIDs))
// ... 填充
```

### database/sql、sqlc、GORM 怎么选

| 方案 | 特点 | 适合 |
| --- | --- | --- |
| `database/sql` | 手写 SQL，最可控 | 追求性能与可控性 |
| `sqlc` | 写 SQL 自动生成类型安全代码 | **推荐的中间路线** |
| `GORM` | 全功能 ORM，上手快 | 快速开发、CRUD 多 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 以为 `sql.Open` 会连库 | 错误延后暴露 | 用 `PingContext` 验证 |
| 忘了 `rows.Close()` | 连接泄漏，池被耗尽 | 拿到 rows 立刻 defer |
| 漏检查 `rows.Err()` | 遍历中途的错误被吞 | 循环后必须检查 |
| 用字符串拼 SQL | SQL 注入 | 一律用参数占位 |
| 事务里用 `:=` 重新声明 err | 回滚不生效 | 用 `err =` |
| 把 `sql.ErrNoRows` 当系统错误 | 用户看到 500 | 转成业务错误 |
| 请求级操作不带 context | 无法取消，慢查询拖垮服务 | 全部传 `ctx` |
| 循环里查数据库 | N+1，性能极差 | 批量查询 + 内存映射 |

### 手把手练习：带分页与批量查询

```go
type User struct {
    ID   int
    Name string
}

func ListByIDs(ctx context.Context, db *sql.DB, ids []int) ([]User, error) {
    if len(ids) == 0 {
        return nil, nil
    }

    // PostgreSQL 用 ANY($1)；MySQL 可用 IN (?,?,?) 动态占位
    rows, err := db.QueryContext(ctx,
        `SELECT id, name FROM users WHERE id = ANY($1)`, pq.Array(ids))
    if err != nil {
        return nil, fmt.Errorf("批量查询: %w", err)
    }
    defer rows.Close()

    users := make([]User, 0, len(ids))
    for rows.Next() {
        var u User
        if err := rows.Scan(&u.ID, &u.Name); err != nil {
            return nil, fmt.Errorf("扫描: %w", err)
        }
        users = append(users, u)
    }
    if err := rows.Err(); err != nil {
        return nil, fmt.Errorf("遍历: %w", err)
    }
    return users, nil
}
```

### 学完自测

- [ ] 能说出连接池四个参数各自的作用。
- [ ] 知道 `sql.Open` 与 `PingContext` 的区别。
- [ ] 能说出查询结果必须做的三个收尾动作。
- [ ] 知道事务里为什么要注意 `err` 的声明方式。
- [ ] 能说出 N+1 查询的成因与解决思路。

## 时间/空间复杂度或性能分析

**复杂度证据**：「Go 数据访问与连接池」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Go 数据访问与连接池」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Go 数据访问与连接池」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《Go 数据访问与连接池》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Go 数据访问与连接池」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用字符串拼接 SQL | 注入漏洞 | 一律参数化 |
| 忘记 `rows.Close()` | 连接泄漏、池被耗尽 | `defer rows.Close()` |
| 不检查 `rows.Err()` | 中途错误被忽略 | 遍历后必须检查 |
| 事务里做网络调用 | 长事务、锁等待 | 外部调用放事务外 |
| 连接池设得过大 | 数据库连接打满 | 按数据库承载能力设定 |
| `sql.Open` 返回即认为连通 | 首次查询才报错 | 用 `PingContext` 验证 |
| 循环里逐条插入 | 极慢 | 预编译语句加单事务批处理 |
| 用 `SELECT *` | 列变更导致扫描错位 | 显式列出列 |

**教材衔接：故障现场**

### 现场 1：忘记 rows.Close()

**症状**：在《Go 数据访问与连接池》的复现场景中，连接泄漏、池被耗尽。

**根因**：当出现“忘记 rows.Close()”时，执行路径已经绕过了《Go 数据访问与连接池》的关键约束，最终以“连接泄漏、池被耗尽”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Go 数据访问与连接池》的问题，defer rows.Close()。

**验证**：在《Go 数据访问与连接池》中按“defer rows.Close()”调整后，从“忘记 rows.Close()”的触发条件重放同一条路径，确认“连接泄漏、池被耗尽”不再出现，并补一个相邻边界用例检查没有引入新问题。

### 现场 2：不检查 rows.Err()

**症状**：在《Go 数据访问与连接池》的复现场景中，中途错误被忽略。

**根因**：触发点是把“不检查 rows.Err()”当成安全做法。它没有满足《Go 数据访问与连接池》要求的前提，因此先表现为“中途错误被忽略”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Go 数据访问与连接池》的问题，遍历后必须检查。

**验证**：保留《Go 数据访问与连接池》里触发“中途错误被忽略”的输入、版本和日志，按“遍历后必须检查”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：事务里做网络调用

**症状**：在《Go 数据访问与连接池》的复现场景中，长事务、锁等待。

**根因**：触发点是把“事务里做网络调用”当成安全做法。它没有满足《Go 数据访问与连接池》要求的前提，因此先表现为“长事务、锁等待”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Go 数据访问与连接池》的问题，外部调用放事务外。

**验证**：保留《Go 数据访问与连接池》里触发“长事务、锁等待”的输入、版本和日志，按“外部调用放事务外”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Go 测试进阶：基准、模糊与集成》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《实战：Go REST API 服务》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 关联 | 《数据库访问与 ORM：九种生态横向对照》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Go 测试进阶：基准、模糊与集成》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Go 泛型与标准库实战》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Go 数据访问与连接池」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Go 数据访问与连接池》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

阅读「Go 数据访问与连接池」正文里的这段 Go 代码，下面哪一项判断是正确的？

```go
func Transfer(ctx context.Context, db *sql.DB, from, to int, amount int) error {
    tx, err := db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelSerializable})
    if err != nil {
        return fmt.Errorf("开启事务: %w", err)
    }
    defer func() {
        if err != nil {                 // 出错就回滚
            _ = tx.Rollback()
        }
    }()

    if _, err = tx.ExecContext(ctx, `UPDATE accounts SET balance = balance - $1 WHERE id = $2`, amount, from); err != nil {
        return fmt.Errorf("扣款: %w", err)
    }
    if _, err = tx.ExecContext(ctx, `UPDATE accounts SET balance = balance + $1 WHERE id = $2`, amount, to); err != nil {
        return fmt.Errorf("入账: %w", err)
    }
    if err = tx.Commit(); err != nil {
        return fmt.Errorf("提交: %w", err)
    }
    return nil
}
```

A. 这段代码包含异常处理分支，失败时会走专门的补救路径。
B. 这段代码会读取外部输入，结果依赖传入的数据。
C. 这段代码会产生可观察的输出，运行后能看到结果。
D. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：在「Go 数据访问与连接池」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「Go 数据访问与连接池」的正文示例，围绕database/sql、连接池、事务展开；把输入或边界换成空值、极值或失败情况后，结论要以「Go 数据访问与连接池」的实际运行结果为准。

### 自测 2

遍历 Query 结果集后，必须做什么？

A. 不需要任何处理
B. 只需要 rows.Close
C. 关闭 rows 并检查 rows.Err
D. 重新执行一次查询，但这会带来额外的维护成本

**参考答案**：关闭 rows 并检查 rows.Err

**解析**：在「Go 数据访问与连接池」里，关闭 rows 并检查 rows.Err。Close 释放连接，Err 能发现遍历过程中发生的错误，两者缺一不可。这道题的关键在「Go 数据访问与连接池」的database/sql、连接池、事务：先确认题干“遍历 Query 结果集后”问的是哪一步，再排除偷换前提的选项。

### 自测 3

围绕“Go 数据访问与连接池”中的 database/sql、连接池、事务，下列哪两项是本课强调的实践判断？

A. 学习 database/sql 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 database/sql 的常规示例通过，就可以跳过边界与异常路径
C. 验证 连接池 时要固定版本并覆盖边界输入，结论才可复现
D. 把 连接池 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 database/sql 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 连接池 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把Go 数据访问与连接池拆成概念、示例与故障现场三部分，因此判断 database/sql 时必须同时交代输入、输出和失败路径，这使“学习 database/sql 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Go 数据访问与连接池里，判断 连接池 时要固定版本与边界输入，所以“验证 连接池 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

**教材衔接：复习与自测**

- [ ] 所有 SQL 使用参数化查询并带 context 超时。
- [ ] 连接池四个参数按数据库能力显式配置。
- [ ] 事务短小、用 defer 回滚、外部调用放事务外。
- [ ] 批量写入使用预编译语句加单事务。
- [ ] `rows` 正确关闭并检查 `Err()`。

**教材衔接：动手练习**

> 本课练习重点：围绕「database/sql、连接池、事务」完成复述、实验和交付，每个结果都要能被别人检查。

用 SetConnMaxLifetime 构造最小可运行示例，并把输出与「方案选型速查」的结论对照。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Go 数据访问与连接池解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「连接池」是什么关系？

验收标准：用自己的话解释 database/sql，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先原样跑通正文里的 `SetConnMaxLifetime`，再只改database/sql相关的输入，按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。

### 练习 3：交付一个小结果（30 分钟）

用 SetConnMaxLifetime 构造最小可运行示例，并把输出与「方案选型速查」的结论对照。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「database/sql」和「连接池」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

本节围绕Go 数据访问与连接池安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Go 数据访问与连接池」的结构，画完再对照骨架：

- 主干：方案选型速查 → 连接池参数速查 → 必守规则速查 → 零基础详解：Go 访问数据库
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明database/sql与连接池的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案至少在一个输入上给出不同结果；把差异归因到database/sql，而不是笼统地写「性能更好」。

### 任务 3：迁移到自己的场景

**验收标准**：至少给出一个命令或数据样例，让读者能独立复现 连接池 的结论。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「数据库连接池的 SetMaxOpenConns 设置过大，会有什么后果？」的判断依据。
- [ ] 不看解析，能说出「遍历 Query 结果集后，必须做什么？」的判断依据。
- [ ] 不看解析，能说出「批量插入大量数据，性能最好的写法是？」的判断依据。
- [ ] 不看解析，能说出「关于事务，正确的做法是？」的判断依据。
- [ ] 不看解析，能说出「防止 SQL 注入的根本做法是？」的判断依据。
- [ ] 跑通「Go 数据访问与连接池」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `连接池` | 复用一组已建立的数据库连接，避免每次请求都握手；需要配好最大连接数与超时。 |
| `事务` | 一组要么全部成功要么全部回滚的数据库操作。 |
| `批量插入` | 把多行数据合并成多值 INSERT 或批量语句，减少往返次数，是导入数据的基本优化。 |
| `参数化查询` | 用占位符绑定参数而不是拼接 SQL，既防注入也让数据库复用执行计划。 |

## 考点精讲

### 考点 1：代码补全·database/sql

- **题目**：阅读「Go 数据访问与连接池」正文里的这段 Go 代码，下面哪一项判断是正确的？
- **判断依据**：在「Go 数据访问与连接池」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「Go 数据访问与连接池」的正文示例，围绕database/sql、连接池、事务展开；把输入或边界换成空值、极值或失败情况后，结论要以「Go 数据访问与连接池」的实际运行结果为准。

### 考点 2：概念判断·database/sql

- **题目**：遍历 Query 结果集后，必须做什么？
- **判断依据**：在「Go 数据访问与连接池」里，关闭 rows 并检查 rows.Err。Close 释放连接，Err 能发现遍历过程中发生的错误，两者缺一不可。这道题的关键在「Go 数据访问与连接池」的database/sql、连接池、事务：先确认题干“遍历 Query 结果集后”问的是哪一步，再排除偷换前提的选项。

### 考点 3：概念判断·database/sql

- **题目**：批量插入大量数据，性能最好的写法是？
- **判断依据**：在「Go 数据访问与连接池」里，预编译语句加单个事务批量执行。预编译减少解析开销，单事务减少提交与日志刷盘次数。这道题的关键在「Go 数据访问与连接池」的database/sql、连接池、事务：先确认题干“批量插入大量数据”问的是哪一步，再排除偷换前提的选项。把“预编译语句加单个事务批量执行”代回「Go 数据访问与连接池」里“批量插入大量数据”的例子核对，条件一旦改变，结论就要用database/sql、连接池、事务重新推导。

### 考点 4：概念判断·database/sql

- **题目**：关于事务，正确的做法是？
- **判断依据**：在「Go 数据访问与连接池」里，结论应落在「事务尽量短小，外部调用放在事务外」。长事务会长期持锁并放大主从延迟，外部调用应移到事务外。在「Go 数据访问与连接池」里，这道题要求区分概念与边界，「事务尽量短小，外部调用放在事务外」只有在题干给出的前提下才成立，而「用 defer 回滚会导致提交失败」、「事务里调用外部 HTTP 接口」缺少同一组条件。

### 考点 5：多选辨析·database/sql

- **题目**：围绕“Go 数据访问与连接池”中的 database/sql、连接池、事务，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把Go 数据访问与连接池拆成概念、示例与故障现场三部分，因此判断 database/sql 时必须同时交代输入、输出和失败路径，这使“学习 database/sql 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在Go 数据访问与连接池里，判断 连接池 时要固定版本与边界输入，所以“验证 连接池 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 6：填空·database/sql

- **题目**：补全代码：「Go 数据访问与连接池」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `db.____(30 * time.Minute)`
- **判断依据**：空格应填写「SetConnMaxLifetime」、「setconnmaxlifetime」。在「Go 数据访问与连接池」里判断这道题，要把database/sql、连接池、事务的条件、过程与失败路径逐项对齐，换成“补全代码”这个场景，只有满足前提的结论才成立。“数据访问与连接池示例中”与「Go 数据访问与连接池」的术语表相呼应，只有符合database/sql、连接池、事务约束的“SetConnMaxLifetime”才是正文支持的结论。

## English Overview

**Title:** Data Access in Go

**Summary:** database/sql transactions, connection pool and batch writes.

**Category:** Go
**Level:** 进阶
**Key terms:** database/sql, 连接池, 事务, 批量插入, N+1, 参数化查询

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Go 1.24+
；本课聚焦 database/sql。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：database/sql、连接池、事务、批量插入、N+1、参数化查询
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [database/sql](https://pkg.go.dev/database/sql) | 数据库连接、事务与预编译 |
| [Go Modules](https://go.dev/doc/modules/) | 模块、版本与依赖 |
| [Go 官方教程](https://go.dev/tour/) | 语言基础与并发入门 |

> 「Go 数据访问与连接池」的链接用于离线阅读后的延伸核对；App 不会自动联网。
