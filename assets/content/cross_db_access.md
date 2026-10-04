# 数据库访问与 ORM：九种生态横向对照

![数据库访问与 ORM：九种生态横向对照](images/category_cross_db_access.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：20 分钟

## 学习目标

- 能用自己的话解释「数据库访问与 ORM：九种生态横向对照」解决了什么问题，而不是只背术语。
- 能说清 「数据库」、「ORM」、「连接池」、「参数化查询」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「跨语言对照」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：驱动、查询构建器与 ORM 的取舍，参数化查询、连接池与 N+1。

## 前置知识

- 先完成上一课《依赖安全与密钥管理：九种生态横向对照》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：数据库、ORM、连接池。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 一句话说清

访问数据库只有三层选择：**原生驱动、查询构建器、ORM**。
各生态的方案名字不同，但「参数化查询、连接池、事务边界」三条纪律完全一致。

## 三种访问方式对照

| 方式 | 代表 | 优点 | 代价 |
| --- | --- | --- | --- |
| 原生驱动 | Python DB-API、Go database/sql、JDBC | 最可控、性能最好 | 手写 SQL 与映射 |
| 查询构建器 | MyBatis、jOOQ、Knex、sqlc | 兼顾可控与安全 | 需要维护 SQL 与代码同步 |
| ORM | SQLAlchemy、Hibernate、EF Core、GORM、Diesel | 开发快、模型清晰 | 易产生 N+1 与隐式查询 |

## 九种生态的主流方案

| 语言 | 原生驱动 | 查询构建/SQL 生成 | ORM |
| --- | --- | --- | --- |
| Python | `psycopg` / `sqlite3` | SQLAlchemy Core | SQLAlchemy ORM、Django ORM |
| JavaScript | `pg` / `mysql2` | Knex | Prisma、Sequelize |
| TypeScript | 同上 | Kysely、Drizzle | Prisma、TypeORM |
| Java | JDBC | jOOQ、MyBatis | JPA/Hibernate |
| C# | ADO.NET | Dapper | EF Core |
| C++ | libpq、sqlite3 | 手写 | sqlpp11、ODB |
| Go | database/sql | sqlc | GORM、Ent |
| Rust | tokio-postgres、rusqlite | sqlx（编译期校验） | Diesel、SeaORM |
| Shell | `psql` / `mysql` 客户端 | —— | —— |

## 三条不可妥协的纪律

```text
① 一律参数化查询，永不拼接 SQL
   ✗ f"SELECT * FROM users WHERE name = '{name}'"
   ✓ cursor.execute("SELECT * FROM users WHERE name = %s", (name,))

② 连接池必须显式配置
   · 最大连接数、空闲数、连接寿命、超时
   · 池太小会排队，池太大会压垮数据库

③ 事务边界要短
   · 事务里不做网络调用、不发消息、不等待用户
   · 长事务会持锁并阻碍回收
```

```python
# Python：参数化与连接池
import psycopg
from psycopg_pool import ConnectionPool

pool = ConnectionPool(conninfo=dsn, min_size=2, max_size=10)

def find_user(name: str):
    with pool.connection() as conn:                 # 自动归还连接
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name FROM users WHERE name = %s",
                (name,),                            # 参数单独传
            )
            return cur.fetchone()
```

```typescript
// TypeScript + Prisma：注意 N+1
const users = await prisma.user.findMany({ where: { active: true } });

// 反例：循环里再查一次 → N+1
for (const u of users) {
  u.posts = await prisma.post.findMany({ where: { userId: u.id } });
}

// 正例：一次带出关联
const withPosts = await prisma.user.findMany({
  where: { active: true },
  include: { posts: true },
});
```

```java
// Java + JDBC：连接池交给 HikariCP，事务显式提交
try (Connection conn = dataSource.getConnection()) {
    conn.setAutoCommit(false);
    try (PreparedStatement ps = conn.prepareStatement(
            "UPDATE accounts SET balance = balance - ? WHERE id = ?")) {
        ps.setBigDecimal(1, amount);
        ps.setLong(2, fromId);
        ps.executeUpdate();
    }
    conn.commit();
} catch (SQLException e) {
    // 回滚与日志
}
```

```csharp
// C# + EF Core：只读查询关掉跟踪
var users = await db.Users
    .AsNoTracking()
    .Where(u => u.Active)
    .OrderBy(u => u.Id)
    .Take(50)
    .ToListAsync(ct);
```

```go
// Go + database/sql：QueryContext 与 rows.Close 都不能省
rows, err := db.QueryContext(ctx,
    `SELECT id, name FROM users WHERE age >= $1 ORDER BY id LIMIT 100`, minAge)
if err != nil {
    return nil, fmt.Errorf("查询用户: %w", err)
}
defer rows.Close()

var users []User
for rows.Next() {
    var u User
    if err := rows.Scan(&u.ID, &u.Name); err != nil {
        return nil, fmt.Errorf("扫描: %w", err)
    }
    users = append(users, u)
}
if err := rows.Err(); err != nil {                 // 容易漏掉
    return nil, fmt.Errorf("遍历: %w", err)
}
```

```rust
// Rust + sqlx：编译期校验 SQL（需连接数据库）
let users = sqlx::query_as::<_, User>(
    "SELECT id, name FROM users WHERE active = $1 ORDER BY id LIMIT $2",
)
.bind(true)
.bind(50i64)
.fetch_all(&pool)
.await?;
```

## N+1 查询：ORM 最大的坑

```text
需求：列出 10 个订单及其用户名

N+1 写法（11 次查询）
  ① SELECT * FROM orders LIMIT 10        ← 1 次
  ② 对每个订单再查一次用户                  ← 10 次
  ┌────┐ ┌────┐ ┌────┐        ┌────┐
  │查1 │ │查2 │ │查3 │  ...    │查10│
  └────┘ └────┘ └────┘        └────┘

正确写法（1 次或 2 次查询）
  ① SELECT o.*, u.name
     FROM orders o JOIN users u ON u.id = o.user_id
     LIMIT 10
  或者先批量取用户：WHERE id = ANY($1)
```

| 症状 | 判断方式 |
| --- | --- |
| 接口随数据量线性变慢 | 打开 SQL 日志数查询次数 |
| 单次请求 SQL 数远超预期 | 用 APM 或日志统计 |
| 加上分页后仍很慢 | 检查关联是否逐条查询 |

## 事务与并发控制

| 场景 | 建议 |
| --- | --- |
| 转账、扣库存 | 短事务 + 行锁或乐观锁 |
| 只读查询 | 不加事务或只读事务 |
| 批量导入 | 分批提交，避免长事务 |
| 外部调用 | 移出事务，用状态机补偿 |

```sql
-- 乐观锁：版本号控制
UPDATE orders SET status = 'paid', version = version + 1
 WHERE id = 1001 AND version = 7;
-- 影响行数为 0 说明并发冲突，需要重读并重试
```

## 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 拼接 SQL | 注入漏洞 | 参数化查询 |
| ORM 循环查询 | N+1，越用越慢 | 预加载或批量查询 |
| 连接池用默认值 | 高峰排队或压垮库 | 按压测配置池参数 |
| 长事务里调外部接口 | 持锁时间不可控 | 移出事务 |
| 忘了关闭结果集 | 连接泄漏 | `defer close` 或 try-with-resources |
| 只读查询也开事务 | 无谓开销 | 用只读或不开 |
| 迁移脚本不进版本库 | 环境结构漂移 | 迁移纳入版本控制 |
| 忽略慢查询日志 | 问题积累 | 开启并定期分析 |

## 本课小结
- 三种方式按需选择：**要控制力用驱动，要效率用 ORM，但都要守住三条纪律**。
- ORM 的头号风险是 **N+1 查询**，用 SQL 日志或 APM 数查询次数即可发现。
- 连接池与事务边界是生产稳定的两根支柱。

## 动手练习

<!-- practice-diversified:v1 -->

> 本课练习重点：围绕「数据库、ORM、连接池」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「数据库访问与 ORM：九种生态横向对照」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「ORM」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

选两种语言实现同一行为，列出语法、错误处理、性能和生态差异。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「数据库」和「ORM」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

<!-- scaffold:v1 -->

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Database Access and ORMs

**Summary:** Drivers, query builders, ORMs, pooling and the N+1 problem.

**Category:** Cross-Language Comparison  
**Level:** 进阶  
**Key terms:** 数据库, ORM, 连接池, 参数化查询, N+1

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：数据库、ORM、连接池、参数化查询、N+1
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

<!-- p2-references:v1 -->

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [DevDocs](https://devdocs.io/) | 多语言 API 快速检索 |
| [官方语言文档](https://developer.mozilla.org/docs/Web) | 跨语言语义对照 |

> 本课主题：驱动、查询构建器与 ORM 的取舍，参数化查询、连接池与 N+1。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

