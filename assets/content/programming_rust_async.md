# Rust 异步编程与 tokio

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：35 分钟

![Rust Future 状态机与 tokio 调度](images/diagram_rust_async.webp)

![Rust 异步编程与 tokio](images/remaining_rust_async_tokio.webp)

## 学习目标

- 能用自己的话解释Rust 异步编程与 tokio解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「异步」、「tokio」、「Future」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Rust」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Future/executor 模型、tokio API 与五个高频坑。

## 前置知识

- 先完成上一课《Rust 实战：命令行工具》；如果已经掌握，可以直接用本课练习自测。
- 开始前先复习：Rust、异步、tokio。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 异步模型要点

Rust 的 `async fn` 由编译器生成状态机，返回 `Future`；Future 是**惰性**的，必须被 `await` 或被 executor 驱动才会推进。标准库只提供 Future trait，运行时由生态提供（tokio 最常用）。

| 概念 | 说明 |
| --- | --- |
| Future | 表示"未来会完成的计算"，poll 一次推进一次 |
| executor | 负责调度 Future（tokio 的多线程/当前线程运行时） |
| Waker | Future 就绪时通知 executor 重新 poll |
| Send 约束 | 跨线程 spawn 的 Future 必须 Send，持有非 Send 类型会编译失败 |

## tokio 常用 API

| 需求 | API |
| --- | --- |
| 启动运行时 | `#[tokio::main]` 或手动构建 Runtime |
| 并发等待全部 | `tokio::join!` 或 `futures::future::join_all` |
| 竞速与超时 | `tokio::select!`、`tokio::time::timeout` |
| 后台任务 | `tokio::spawn`（要求 Future: Send + 'static） |
| 同步原语 | `tokio::sync::{Mutex, RwLock, mpsc, oneshot, Semaphore}` |
| 阻塞任务隔离 | `tokio::task::spawn_blocking` |

## 常见错误与排查

1. **在异步任务里做阻塞操作**（同步 IO、CPU 密集），会卡住整个执行线程，应用 `spawn_blocking` 或限制线程数。
2. **用 std 的 Mutex 跨 await 持有**，会导致死锁或编译错误；应使用 `tokio::sync::Mutex`，且尽量缩短持锁范围。
3. **忘记 spawn 或 await**，Future 根本不会执行（惰性）。
4. **spawn 的 Future 捕获了非 'static 引用**，编译失败；用 `Arc` 共享所有权或 `move` 闭包。
5. **取消语义**：drop 掉 Future 即取消，但已发生的副作用不会回滚；关键操作要考虑取消后的清理与幂等。
| 容易踩的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 在 async 里调用阻塞 API | 整个运行时被卡住 | 用异步版本或 `spawn_blocking` |
| 用 `std::sync::Mutex` 跨 `.await` | 编译错误或死锁风险 | 改用 `tokio::sync::Mutex` |
| 忘记 `await` future | 任务从未执行（编译器会告警） | 补 `.await` |
| `tokio::spawn` 捕获非 `'static` 引用 | 编译错误 | 用 `Arc` 共享或改用 `join!` |
| 无限制 `spawn` | 内存暴涨 | 用 `Semaphore` 限制并发 |
| 任务 panic 未观察 | 错误被静默丢弃 | 保存 `JoinHandle` 并处理 `Err` |
| 在 `select!` 分支里做重活 | 阻塞运行时 | 只做轻量处理 |
| 用 `thread::sleep` 做异步延迟 | 阻塞线程 | 用 `tokio::time::sleep` |
| 单线程运行时跑阻塞任务 | 所有任务停摆 | 换多线程运行时或 `spawn_blocking` |
| 不设超时 | 依赖故障时任务堆积 | 统一加 `timeout` 与取消 |

## 与线程模型的选择

| 场景 | 选择 |
| --- | --- |
| 高并发网络 IO | 异步 + tokio 多线程运行时 |
| CPU 密集计算 | 线程池（rayon）或 spawn_blocking |
| 简单脚本与命令行工具 | 直接同步写法，避免引入运行时 |
| 需要极低延迟 | 当前线程运行时 + 减少任务切换 |

经验：**不要为了异步而异步**。异步的收益来自大量并发等待的场景；纯计算任务用 rayon 更简单直接。

## 本课小结

Rust 异步的三句话：**Future 惰性需被驱动、阻塞操作必须隔离、跨 await 的共享状态要用 tokio 同步原语**。

## tokio 速查

| 目的 | 写法 |
| --- | --- |
| 异步入口 | `#[tokio::main]` + `async fn main()` |
| 启动任务 | `tokio::spawn(async { ... })` |
| 并发等待 | `tokio::join!`（固定数量）/ `futures::future::join_all`（集合） |
| 竞速 | `tokio::select!` |
| 延时 | `tokio::time::sleep` |
| 超时 | `tokio::time::timeout(dur, fut)` |
| 阻塞任务 | `tokio::task::spawn_blocking` |
| 多线程运行时 | `#[tokio::main(flavor = "multi_thread")]` |
| 单线程运行时 | `#[tokio::main(flavor = "current_thread")]` |
| 同步原语 | `tokio::sync::Mutex` / `RwLock` / `Semaphore` / `mpsc` |
| 取消 | 丢弃 future，或用 `CancellationToken`（tokio-util） |

```rust
use std::time::Duration;
use tokio::time::{sleep, timeout};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // 并发执行两个任务，总耗时接近较慢的那个
    let (a, b) = tokio::join!(fetch("a"), fetch("b"));
    println!("{a} {b}");

    // 超时控制：超过 1 秒即放弃
    match timeout(Duration::from_secs(1), fetch("slow")).await {
        Ok(value) => println!("成功：{value}"),
        Err(_) => eprintln!("超时"),
    }

    // CPU 密集或阻塞操作放到阻塞线程池
    let hash = tokio::task::spawn_blocking(|| {
        // 假设这是一个耗时计算
        (0..1_000_000u64).fold(0u64, |acc, x| acc.wrapping_add(x))
    })
    .await?;
    println!("{hash}");

    Ok(())
}

async fn fetch(name: &str) -> String {
    sleep(Duration::from_millis(300)).await;
    format!("{name} 完成")
}
```

## 并发原语选择速查

| 需求 | 选择 | 理由 |
| --- | --- | --- |
| 计数 / 限流 | `tokio::sync::Semaphore` | 异步友好的并发上限 |
| 任务间传递消息 | `tokio::sync::mpsc` | 生产者消费者 |
| 共享可变状态（跨 await） | `tokio::sync::Mutex` | 可跨 `.await` 持有 |
| 共享状态（不跨 await） | `std::sync::Mutex` | 更快，但不可跨 await |
| 广播 | `tokio::sync::broadcast` | 一对多 |
| 单次初始化 | `tokio::sync::OnceCell` | 异步初始化 |
| 取消传播 | `CancellationToken` | 统一取消一组任务 |

## 复习与自测

- [ ] 异步链路中不出现阻塞调用。
- [ ] 跨 `.await` 的共享状态使用 `tokio::sync` 原语。
- [ ] 所有外部调用都有超时与取消。
- [ ] 并发任务数量受信号量限制。
- [ ] 任务错误被记录，不被静默丢弃。

## 零基础详解：async/await 与 Tokio

### 一句话说清它是什么

Rust 的 `async fn` 返回的是一个**惰性的 Future**：不 `.await` 就什么都不会发生。
Tokio 负责提供运行时，把这些 Future 调度起来并发执行——适合大量网络 IO。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| `async fn` | 写好的待办条 | 只是记录要做的事，还没开始做 |
| `.await` | 去做并等结果 | 真正驱动它执行 |
| Future | 未完成的订单 | 完成前可以被反复「推进」 |
| 运行时 | 调度中心 | 决定谁先跑、谁来唤醒 |
| `join!` | 同时等几张单子 | 并发执行 |
| `select!` | 谁先回来听谁的 | 竞速或超时 |

### 从阻塞到异步

```rust
// 阻塞：整个线程停下来等
let resp = reqwest::blocking::get(url)?;

// 异步：等待期间线程可以去处理别的任务
let resp = reqwest::get(url).await?;
```

### 最小可运行示例

```toml
# Cargo.toml
[dependencies]
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.12", features = ["json"] }
```

```rust
use std::time::Duration;

async fn fetch_status(url: &str) -> Result<u16, reqwest::Error> {
    let resp = reqwest::get(url).await?;
    Ok(resp.status().as_u16())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let status = fetch_status("https://example.com").await?;
    println!("状态码 {status}");

    // 超时控制
    let result = tokio::time::timeout(Duration::from_secs(3), fetch_status("https://example.com")).await;
    match result {
        Ok(Ok(code)) => println!("超时前返回 {code}"),
        Ok(Err(e)) => println!("请求失败：{e}"),
        Err(_) => println!("请求超时"),
    }
    Ok(())
}
```

### 串行、并发与竞速

```rust
use tokio::join;

// 串行：约等于两者之和
let a = fetch_status(url1).await?;
let b = fetch_status(url2).await?;

// 并发：约等于较慢的那个
let (a, b) = join!(fetch_status(url1), fetch_status(url2));

// 竞速：谁先返回就用谁
tokio::select! {
    res = fetch_status(url1) => println!("第一个返回：{:?}", res),
    _ = tokio::time::sleep(Duration::from_secs(2)) => println!("超时"),
}
```

| 工具 | 作用 |
| --- | --- |
| `join!` | 等全部完成 |
| `try_join!` | 等全部成功，任一失败立即返回 |
| `select!` | 等第一个完成 |
| `spawn` | 起一个独立任务，返回 `JoinHandle` |
| `timeout` | 给任意 Future 加时限 |

### 并发限制：别一次开一万个请求

```rust
use std::sync::Arc;
use tokio::sync::Semaphore;

let limit = Arc::new(Semaphore::new(10));      // 最多 10 个并发
let mut handles = Vec::new();

for url in urls {
    let permit = limit.clone().acquire_owned().await?;
    handles.push(tokio::spawn(async move {
        let code = fetch_status(&url).await.unwrap_or(0);
        drop(permit);                          // 释放许可
        code
    }));
}

for handle in handles {
    println!("{}", handle.await?);
}
```

### CPU 密集任务不要放在 async 里

```rust
// 错误：会卡住整个运行时
async fn bad() {
    let sum: u64 = (0..10_000_000).sum();
    println!("{sum}");
}

// 正确：丢到阻塞线程池
async fn good() -> u64 {
    tokio::task::spawn_blocking(|| (0..10_000_000u64).sum())
        .await
        .unwrap()
}
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 创建 Future 不 `.await` | 什么也没执行 | 记得 await 或 spawn |
| 在 async 里写阻塞调用 | 运行时被卡住 | 用异步版本或 `spawn_blocking` |
| 用 `std::sync::Mutex` 跨 await | 可能死锁 | 用 `tokio::sync::Mutex` |
| 忘了 `#[tokio::main]` | 编译报错 | 加在 main 上 |
| 循环里逐个 await | 慢几倍 | 用 `join_all` 或 `FuturesUnordered` |
| 无限并发 | 连接被耗尽 | 用 `Semaphore` 限流 |
| 忽略 `JoinHandle` 的结果 | 任务 panic 被吞 | 检查 `handle.await` |
| 忘了 `Send` 约束 | 跨任务编译不过 | 避免在 await 期间持有非 Send 数据 |

### 手把手练习：并发抓取并限流

```rust
use std::sync::Arc;
use tokio::sync::Semaphore;

async fn fetch_status(url: String) -> (String, u16) {
    let code = match reqwest::get(&url).await {
        Ok(resp) => resp.status().as_u16(),
        Err(_) => 0,
    };
    (url, code)
}

#[tokio::main]
async fn main() {
    let urls: Vec<String> = vec!["https://example.com".into(); 20];
    let limit = Arc::new(Semaphore::new(5));
    let mut handles = Vec::new();

    for url in urls {
        let permit = limit.clone().acquire_owned().await.unwrap();
        handles.push(tokio::spawn(async move {
            let result = fetch_status(url).await;
            drop(permit);
            result
        }));
    }

    let mut ok = 0;
    for handle in handles {
        let (url, code) = handle.await.unwrap();
        if code == 200 { ok += 1; }
        println!("{code} {url}");
    }
    println!("成功 {ok} 个");
}
```

### 学完自测

- [ ] 能解释「Future 是惰性的」是什么意思。
- [ ] 知道什么时候用 `join!`、什么时候用 `select!`。
- [ ] 能说出为什么不能在 async 里做 CPU 密集计算。
- [ ] 知道 `tokio::sync::Mutex` 与标准库 Mutex 的使用差别。
- [ ] 能用 `Semaphore` 给并发请求限流。

## 动手练习

> 本课练习重点：围绕「Rust、异步、tokio」完成复述、实验和交付，每个结果都要能被别人检查。

先让 cargo check 通过，再补所有权、错误和并发边界，最后运行 clippy。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Rust 异步编程与 tokio解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「异步」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个最小 Cargo 示例，先用 `cargo check`，再补一个边界测试。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Rust」和「异步」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

本节围绕Rust 异步编程与 tokio安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Rust 异步编程与 tokio」的结构，画完再对照骨架：

- 主干：异步模型要点 → tokio 常用 API → 五个高频坑 → 与线程模型的选择
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Rust与异步的关系？

### 任务 2：做一次对比实验

**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。

### 任务 3：迁移到自己的场景

**验收标准**：至少有一个可复现的命令、代码片段或数据样例；结论能被别人独立检查。

## 故障现场

### 现场 1：本课的 Rust 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 Rust 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 Rust 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“Rust 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 Rust 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 异步 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 异步 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 异步 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“异步 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 异步 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，Rust 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

- Rust 2024 edition 已成为主流，编译器与标准库保持快速小步演进
- 异步运行时、trait 解析与借用检查规则的变化需要在 CI 中提前暴露
- 升级前用 cargo update、cargo clippy 与 MSRV 矩阵验证
- 官方发布说明：https://blog.rust-lang.org/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Rust 中 Future 的特性是？」的判断依据。
- [ ] 不看解析，能说出「在异步任务中执行 CPU 密集计算应该？」的判断依据。
- [ ] 不看解析，能说出「跨 await 持有共享可变状态时推荐？」的判断依据。
- [ ] 不看解析，能说出「tokio::select! 的作用是？」的判断依据。
- [ ] 不看解析，能说出「#[tokio::main] 宏做的事情是？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「Rust 异步编程与 tokio」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `Rust` | Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进。 |
| `异步` | 围绕“异步 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。 |
| `tokio` | 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围。 |
| `Future` | Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进。 |
| `spawn_blocking` | 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数。 |

## 考点精讲

### 考点 1：概念判断·Rust

- **题目**：Rust 中 Future 的特性是？
- **判断依据**：在「Rust 异步编程与 tokio」里，惰性，必须被 await 或 executor 驱动。Future 是状态机，不驱动就永远不会推进。“Rust”与「Rust 异步编程与 tokio」的术语表相呼应，只有符合Rust、异步、tokio约束的“惰性，必须被 await 或 execu”才是正文支持的结论。

### 考点 2：概念判断·Rust

- **题目**：在异步任务中执行 CPU 密集计算应该？
- **判断依据**：在「Rust 异步编程与 tokio」里，用 spawn_blocking 隔离到阻塞线程池。在「Rust 异步编程与 tokio」里判断这道题，要把Rust、异步、tokio的条件、过程与失败路径逐项对齐，换成“在异步任务中执行 CPU 密集计算应”这个场景，只有满足前提的结论才成立。

### 考点 3：多选辨析·Rust

- **题目**：围绕“Rust 异步编程与 tokio”中的 Rust、异步、tokio，下列哪两项是本课强调的实践判断？
- **判断依据**：在「Rust 异步编程与 tokio」里，学习 Rust 时要同时说明输入、输出和失败路径，不能只看正常流程。在Rust 异步编程与 tokio里，判断 异步 时要固定版本与边界输入，所以“验证 异步 时要固定版本并覆盖边界输入，结论才可复现”才可复现。在「Rust 异步编程与 tokio」里，如果只凭关键词作答，很容易把验证 异步 时要固定版本并覆盖边界输入，结论才可复现、把 异步 的单次运行结果当成所有版本和规模都成立与验证 异步 时要固定版本并覆盖边界输入，结论才可复现。

### 考点 4：概念判断·Rust

- **题目**：tokio::select! 的作用是？
- **判断依据**：常用于「请求 vs 超时 vs 取消信号」的竞争场景。在「Rust 异步编程与 tokio」里，作答时，先用Rust建立输入与输出的基线，再把同时等待多个 future代入边界条件核对，结论才能复现。在「Rust 异步编程与 tokio」里，这道题要求区分概念与边界，「同时等待多个 future」只有在题干给出的前提下才成立，而「按顺序依次等待」、「只能等待超时」缺少同一组条件。

### 考点 5：代码补全·Rust

- **题目**：阅读「Rust 异步编程与 tokio」正文里的这段 Rust 代码，下面哪一项判断是正确的？
- **判断依据**：在「Rust 异步编程与 tokio」里，这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。这段代码出自「Rust 异步编程与 tokio」的正文示例，围绕Rust、异步、tokio展开；把输入或边界换成空值、极值或失败情况后，结论要以「Rust 异步编程与 tokio」的实际运行结果为准。

### 考点 6：填空·Rust

- **题目**：补全代码：「Rust 异步编程与 tokio」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `let hash = tokio::task::____(|| {`
- **判断依据**：空格应填写「spawn_blocking」。这道题的关键在「Rust 异步编程与 tokio」的Rust、异步、tokio：先确认题干“补全代码”问的是哪一步，再排除偷换前提的选项。回到Rust、异步、tokio本身再看一遍：只有“spawnblocking”与题干“Rust”的前提一致，结论才成立。

## English Overview

**Title:** Rust Async & tokio

**Summary:** Futures, executors, tokio APIs and pitfalls.

**Category:** Rust
**Level:** 高级
**Key terms:** Rust, 异步, tokio, Future, spawn_blocking

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Rust 1.85+ / Cargo
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、异步、tokio、Future、spawn_blocking
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Rust Async Book](https://rust-lang.github.io/async-book/) | 异步运行时与 Future |
| [Axum 文档](https://docs.rs/axum/latest/axum/) | Web 路由与提取器 |
| [The Rust Book](https://doc.rust-lang.org/book/) | 所有权、类型与工程实践 |

> 「Rust 异步编程与 tokio」的链接用于离线阅读后的延伸核对；App 不会自动联网。
