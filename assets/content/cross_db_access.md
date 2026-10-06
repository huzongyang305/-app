# 本课主题

> 内容更新时间：2026-10-03

![原生驱动、ORM、查询构建器的对照](images/diagram_cross_db.webp)

![本课主题](images/category_cross_db_access.webp)

## 学习目标

- 能用自己的话解释本课主题解决了什么问题，而不是只背术语。
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

> 本课练习重点：围绕「数据库、ORM、连接池」完成复述、实验和交付，每个结果都要能被别人检查。

用两种语言实现同一行为，再对比语法、错误、性能和生态差异。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 本课主题解决了什么问题？
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

## 可运行练习

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 数据库 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 数据库 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 数据库 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“数据库 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 数据库 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 ORM 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 ORM 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 ORM 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“ORM 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 ORM 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，数据库 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 深入补充：本课主题 的取舍与边界

### 一、把概念放回真实约束

学习本课主题时，最容易只记住结论而忽略前提。先写出三个约束：数据规模、时间预算、可接受的失败方式；再判断 数据库 与 ORM 在这些约束下是否仍然成立。只要约束改变，原来的最优解就可能变成错误解。

| 维度 | 数据库 的典型写法 | 另一种语言的等价写法 | 迁移时最易踩的坑 |
| --- | --- | --- | --- |
| 错误处理 | 显式返回或抛出 | 异常或结果类型 | 错误被静默吞掉 |
| 并发模型 | 线程、协程或事件循环 | 运行时调度不同 | 共享状态与取消语义 |
| 依赖管理 | 官方包管理器 | 生态与锁文件不同 | 版本解析结果不一致 |

### 二、三个容易混淆的边界

2. **把“平均值”当成“全部”**：数据库 的指标好看，不代表尾部请求、冷启动或失败重试也好看。
3. **把“当前版本”当成“永久行为”**：ORM 依赖的默认值、API 或性能特征都可能随版本变化，需要固定版本并保留回归用例。

### 三、一个生产场景

假设团队要在真实系统里使用本课主题：第一周先做小流量验证，记录 数据库 的基线与异常；第二周扩大输入规模，观察 ORM 是否成为瓶颈；第三周再做故障演练，主动注入超时、重复请求和依赖不可用，确认系统能降级、能重试、能恢复。每一步都要留下指标、日志和结论，而不是只留下“感觉更快了”。

### 四、自测清单

- 能否用一句话说出本课主题解决的核心问题与不适用场景？
- 能否画出 数据库 的数据流或状态变化，并标出失败路径？
- 能否给出一个反例，证明某个看似合理的结论在边界条件下不成立？
- 能否写出一条可复现的验证命令，让别人独立得到相同结论？

### 五、跨语言迁移清单

在本课的迁移练习里，先列出 数据库 在两种语言中的类型、错误处理、并发模型和内存管理差异；再用同一个输入各写一版最小实现，比较编译或运行时的错误信息。最后记录 ORM 在两种语言里的性能与可读性差异，避免只凭语法熟悉度做选型。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「使用 ORM 时最容易被忽略的性能问题是？」的判断依据。
- [ ] 不看解析，能说出「使用 ORM 读取订单列表后再逐条查询用户，出现 N+1 查询，最直接的修复方式…」的判断依据。
- [ ] 不看解析，能说出「连接池参数配置不当会带来什么？」的判断依据。
- [ ] 不看解析，能说出「`UPDATE ... WHERE id = ? AND version = ?…」的判断依据。
- [ ] 不看解析，能说出「补全代码：本课主题示例中，下面这行代码缺少哪个…」的判断依据。
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
| `psycopg` | \| Python \| `psycopg` / `sqlite3` \| SQLAlchemy Core \| SQLAlchemy ORM、Django ORM \| |
| `sqlite3` | \| Python \| `psycopg` / `sqlite3` \| SQLAlchemy Core \| SQLAlchemy ORM、Django ORM \| |
| `pg` | \| JavaScript \| `pg` / `mysql2` \| Knex \| Prisma、Sequelize \| |
| `mysql2` | \| JavaScript \| `pg` / `mysql2` \| Knex \| Prisma、Sequelize \| |
| `psql` | \| Shell \| `psql` / `mysql` 客户端 \| —— \| —— \| |
| `mysql` | \| Shell \| `psql` / `mysql` 客户端 \| —— \| —— \| |
| `defer close` | \| 忘了关闭结果集 \| 连接泄漏 \| `defer close` 或 try-with-resources \| |
| `UPDATE...WHEREid=?ANDversion=?` | 判断依据**：正确答案是「乐观锁，冲突时影响行数为 0，需要重试」，这道题在问`UPDATE...WHEREid=?ANDversion=?`这种写法属于，判断时要把题干限定的输入、边界与目标逐项对齐。用版本号做条件更新… |
| `.____(u=>u.Active)` | 判断依据**：正确答案是「Where」，这道题在问补全代码：数据库访问与ORM：九种生态横向对照示例中…`.____(u=>u.Active)`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `.Wh… |
| `.Where(u => u.Active)` | 判断依据**：正确答案是「Where」，这道题在问补全代码：数据库访问与ORM：九种生态横向对照示例中…`.____(u=>u.Active)`，判断时要把题干限定的输入、边界与目标逐项对齐。本课示例中还能看到 `.Wh… |

## 考点精讲

### 考点 1：围绕“数据库访问与 ORM：九种生态横向对照”中的 数据库、ORM、连接池，下列哪两项是本课强调的实践判断？

- **判断依据**：正确答案包括「学习 数据库 时要同时说明输入、输出和失败路径，不能只看正常流程」、「验证 ORM 时要固定版本并覆盖边界输入，结论才可复现」。正确答案是学习 数据库 时要同时说明输入、输出和失败路径。本课把本课主题拆成概念、示例与故障现场三部分，因此判断 数据库 时必须同时交代输入、输出和失败路径，这使“学习 数据库 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在本课主题里，判断 ORM 时要固定版本与边界输入，所以“验证 ORM 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：使用 ORM 读取订单列表后再逐条查询用户，出现 N+1 查询，最直接的修复方式是？

- **判断依据**：本题应选「使用批量查询」。N+1 的根因是父查询一次、每个子项再查一次，数据量增大后数据库往返次数线性上升。解题的关键不是记住孤立术语，而是确认「使用批量查询」是否完整覆盖题干的输入、输出和失败路径，并排除「把循环改成递归」、「关闭数据库连接池」这类相邻概念。

### 考点 3：连接池参数配置不当会带来什么？

- **判断依据**：符合题干条件的是「池太小导致请求排队」。连接池过小会造成排队与超时，过大则会把压力直接传给数据库。正确的判断需要逐项核对定义、版本和适用条件（crossdbaccess 第 3 题）。正确的判断需要逐项核对定义、版本和适用条件（cross_db_access 第 3 题）。

### 考点 4：下面这段 Python 代码复现了“数据库访问与 ORM：九种生态横向对照”中 数据库、ORM、连接池 相关的一个常见故障，哪一项最准确地解释了问题？

- **判断依据**：结合数据库、ORM来看，结论应落在「默认参数 bucket=[] 只在定义时创建一次，两次调用共享同一个列表」。结论应落在默认参数 bucket=[] 只在定义时创建一次，两次调用共享同一个列表（crossdbaccess 第 4 题）。结合数据库、ORM来看，结论应落在默认参数 bucket=[] 只在定义时创建一次。

### 考点 5：补全代码：「数据库访问与 ORM：九种生态横向对照」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。

`.____(u => u.Active)`

- **判断依据**：围绕 补全代码：本课主题示例中，下面这行… 作答时，先用数据库建立输入与输出的基线，再把Where 或 where代入边界条件核对，结论才能复现。判断这类题时，要把「Where 或 where」放回题干限定的对象、输入和边界， 等说法虽然包含相关术语，但范围或前提与本题不一致。

## English Overview

**Title:** Database Access and ORMs

**Summary:** Drivers, query builders, ORMs, pooling and the N+1 problem.

**Category:** Cross-Language Comparison
**Level:** 进阶
**Key terms:** 数据库, ORM, 连接池, 参数化查询, N+1

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：九种主流语言生态横向对照
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：数据库、ORM、连接池、参数化查询、N+1
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Programming Languages DB](https://pldb.io/) | 语言特性与生态对照 |
| [Compiler Explorer](https://godbolt.org/) | 不同编译器与汇编对照 |
| [Exercism](https://exercism.org/docs) | 多语言练习与反馈 |

> 「数据库访问与 ORM：九种生态横向对照」的链接用于离线阅读后的延伸核对；App 不会自动联网。
