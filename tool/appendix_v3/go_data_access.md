## 零基础详解：Go 访问数据库

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
