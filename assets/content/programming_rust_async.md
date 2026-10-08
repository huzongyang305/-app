# Rust 异步编程与 tokio

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：55 分钟

![Rust Future 状态机与 tokio 调度](images/diagram_rust_async.webp)

![Rust 异步编程与 tokio](images/remaining_rust_async_tokio.webp)

## 本节知识框架

**课程定位**：所属分类 `rust`（Rust），课程主题 `Rust 异步编程与 tokio`，学习阶段 高级，建议用时 50 分钟。

本课主线：Future/executor 模型、tokio API 与五个高频坑。

**学完本课应当能够**
- 说清 `Rust` 与 `异步` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `tokio` 的行为，记录输入、输出与失败条件。
- 遇到「创建 Future 不 `.await`」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `Rust`：先掌握 Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进，再用它解释 `异步` 为什么会出现。
2. `异步`：先掌握 async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程，再用它解释 `tokio` 为什么会出现。
3. `tokio`：先掌握 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围，再用它解释 `spawn_blocking` 为什么会出现。
4. `spawn_blocking`：先掌握 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数，再用它解释 `Tokio` 为什么会出现。
5. `Tokio`：先掌握 Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「Rust」分类的第 13 课。先修内容：《Rust 实战：命令行工具》。《Rust 实战：命令行工具》里的 `Rust`、`Cargo` 是本课的前提。相关或后续课程：《实战：Rust + Axum REST API》。

### 完成判据

- **定义关**：不看正文也能说明 `Rust` 是 Rust 的 async fn 由编译器生成状态机，返回 Future，Future 是惰性的，必须被 await 或被 executor 驱动才会推进，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `Rust 异步编程与 tokio`，而不是只背结论。
- **示例关**：能运行或推演 `Rust 异步编程与 tokio` 的 `rust` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `Rust 异步编程与 tokio` 示例里的 调用了 `main()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 创建 Future 不 `.await`，记录现象并按 记得 await 或 spawn 修复。
- **迁移关**：能把 `Rust`、`异步`、`tokio`、`Future` 放进一个与 `Rust 异步编程与 tokio` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `Rust 异步编程与 tokio` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| Rust | Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进。 | 静态检查只在编译期成立，运行期输入仍需校验。 |
| 异步 | async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。 | 易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。 |
| tokio | 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围。 | 易错：可能死锁；正确做法是用 `tokio::sync::Mutex`。 |
| spawn_blocking | 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数。 | 易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。 |
| Tokio | Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序 | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |
| Future | 表示"未来会完成的计算"，poll 一次推进一次 | 易错：什么也没执行；正确做法是记得 await 或 spawn。 |
| executor | 负责调度 Future（tokio 的多线程/当前线程运行时） | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |
| Waker | Future 就绪时通知 executor 重新 poll | 只在「Future 就绪时通知 executor 重新 poll」这一前提下成立，换输入或换环境要重新验证。 |
| Send 约束 | 跨线程 spawn 的 Future 必须 Send，持有非 Send 类型会编译失败 | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |
| 高并发网络 IO | 异步 + tokio 多线程运行时 | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |
| CPU 密集计算 | 线程池（rayon）或 spawn_blocking | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |
| 简单脚本与命令行工具 | 直接同步写法，避免引入运行时 | 只在「直接同步写法，避免引入运行时」这一前提下成立，换输入或换环境要重新验证。 |
| 需要极低延迟 | 当前线程运行时 + 减少任务切换 | 共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 |

## 原理与运行机制

### 机制总览

**教材衔接：版本与时效**

- 版本提示：Rust 的行为在最近几个大版本里有过调整，升级「Rust 异步编程与 tokio」前先用 spawn_blocking 复现当前输出，再对照官方发布说明逐条核对。
- 把 异步 的编译告警当作错误处理，升级后才能避免行为漂移。
- 升级前确认 Rust 的兼容范围，把不可回退的改动单独拆成一次提交。
- 官方发布说明：https://blog.rust-lang.org/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 Rust 相关的差异单独记成一条结论。
- 回归范围锁定 spawn_blocking 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 Rust 的新旧版本差异，并据此调整下次复核时间。

**失败路径（来自本课错误表）**
- 创建 Future 不 `.await` → 什么也没执行 → 记得 await 或 spawn。
- 在 async 里写阻塞调用 → 运行时被卡住 → 用异步版本或 `spawn_blocking`。
- 用 `std::sync::Mutex` 跨 await → 可能死锁 → 用 `tokio::sync::Mutex`。
- 忘了 `#[tokio::main]` → 编译报错 → 加在 main 上。
### 机制拆解：每一步的输入、动作与输出

#### 1. `Rust`
- 输入：`Rust`；本步把 Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进 当作判断规则。
- 动作：围绕 `Rust` 保留中间状态，并记录它与 `异步` 的对应关系。
- 输出：`异步`，它可以被下一段代码、测试或记录继续使用。
- `Rust` 的失败条件：静态检查只在编译期成立，运行期输入仍需校验。

#### 2. `异步`
- 输入：`Rust`；本步把 async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程 当作判断规则。
- 动作：围绕 `异步` 保留中间状态，并记录它与 `tokio` 的对应关系。
- 输出：`tokio`，它可以被下一段代码、测试或记录继续使用。
- `异步` 的失败条件：当在 async 里写阻塞调用时，会出现运行时被卡住。

#### 3. `tokio`
- 输入：`异步`；本步把 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围 当作判断规则。
- 动作：围绕 `tokio` 保留中间状态，并记录它与 `spawn_blocking` 的对应关系。
- 输出：`spawn_blocking`，它可以被下一段代码、测试或记录继续使用。
- `tokio` 的失败条件：当用 `std::sync::Mutex` 跨 await时，会出现可能死锁。

#### 4. `spawn_blocking`
- 输入：`tokio`；本步把 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数 当作判断规则。
- 动作：围绕 `spawn_blocking` 保留中间状态，并记录它与 `Tokio` 的对应关系。
- 输出：`Tokio`，它可以被下一段代码、测试或记录继续使用。
- `spawn_blocking` 的失败条件：当在 async 里写阻塞调用时，会出现运行时被卡住。

#### 5. `Tokio`
- 输入：`spawn_blocking`；本步把 Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序 当作判断规则。
- 动作：围绕 `Tokio` 保留中间状态，并记录它与 `main` 的对应关系。
- 输出：`main`，它可以被下一段代码、测试或记录继续使用。
- `Tokio` 的失败条件：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

### 示例中的可观察事实

1. 调用了 `main()`；它对应的课程主题是 `Rust 异步编程与 tokio`。
2. 调用了 `let()`；它对应的课程主题是 `Rust 异步编程与 tokio`。
3. 调用了 `fetch()`；它对应的课程主题是 `Rust 异步编程与 tokio`。
4. 调用了 `timeout()`；它对应的课程主题是 `Rust 异步编程与 tokio`。
5. 调用了 `from_secs()`；它对应的课程主题是 `Rust 异步编程与 tokio`。
6. 调用了 `Err()`；它对应的课程主题是 `Rust 异步编程与 tokio`。
7. 调用了 `spawn_blocking()`；它对应的课程主题是 `Rust 异步编程与 tokio`。
8. 调用了 `fold()`；它对应的课程主题是 `Rust 异步编程与 tokio`。

### 复现实验记录

- 环境：`Rust 异步编程与 tokio` 使用 `rust` 示例，固定 `Rust`、`异步`、`tokio`、`Future` 作为第一组条件。
- 首轮输入：先确认 调用了 `main()`，预测 `Rust` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `Rust`，观察 `Tokio` 是否仍满足定义。
- 失败注入：复现 创建 Future 不 `.await`，确认现象是 什么也没执行。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `Rust 异步编程与 tokio` 时才能区分概念错误与实现错误。

## 典型应用场景

**课程内置实验入口**：`sandbox:rust`，用于动手验证《Rust 异步编程与 tokio》的机制；实验结论不替代概念定义与复杂度分析。

- **创建 Future 不 `.await`**：典型现象是什么也没执行；正确做法是记得 await 或 spawn。
- **在 async 里写阻塞调用**：典型现象是运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。
- **用 `std::sync::Mutex` 跨 await**：典型现象是可能死锁；正确做法是用 `tokio::sync::Mutex`。
- **忘了 `#[tokio::main]`**：典型现象是编译报错；正确做法是加在 main 上。

### 最小验证场景

- 准备：保留 `rust` 示例的原始输入，先记录 `Rust 异步编程与 tokio` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `main()`，再改变一个与 `Rust` 相关的条件。
- 判定：新结果与 `Rust 异步编程与 tokio` 的基线不同不等于错误；只有当差异破坏了 `Rust` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `Rust` 时，先满足它的定义：Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进；静态检查只在编译期成立，运行期输入仍需校验。
- 使用 `异步` 时，先满足它的定义：async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程；易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。
- 使用 `tokio` 时，先满足它的定义：用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围；易错：可能死锁；正确做法是用 `tokio::sync::Mutex`。
- 使用 `spawn_blocking` 时，先满足它的定义：在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数；易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。
- 使用 `Tokio` 时，先满足它的定义：Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序；共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

## 代码/协议/SQL 示例

### 最小可验证示例

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

**教材衔接：tokio 常用 API**

| 需求 | API |
| --- | --- |
| 启动运行时 | `#[tokio::main]` 或手动构建 Runtime |
| 并发等待全部 | `tokio::join!` 或 `futures::future::join_all` |
| 竞速与超时 | `tokio::select!`、`tokio::time::timeout` |
| 后台任务 | `tokio::spawn`（要求 Future: Send + 'static） |
| 同步原语 | `tokio::sync::{Mutex, RwLock, mpsc, oneshot, Semaphore}` |
| 阻塞任务隔离 | `tokio::task::spawn_blocking` |

**教材衔接：tokio 速查**

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

**教材衔接：零基础详解：async/await 与 Tokio**

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

**运行方式**：运行 `Rust 异步编程与 tokio` 的示例时，用 `cargo run` 运行；编译期报错会直接指出所有权或类型问题。

### 示例精读：先找证据，再改一个条件

1. 调用了 `main()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `let()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `fetch()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `timeout()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `from_secs()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `Err()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `spawn_blocking()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `fold()`；它出现在 `Rust 异步编程与 tokio` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `Rust 异步编程与 tokio` 中与 `Rust` 对照：示例必须能支持 Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进，否则说明这一段还缺少实现或验证步骤。
- 在 `Rust 异步编程与 tokio` 中与 `异步` 对照：示例必须能支持 async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程，否则说明这一段还缺少实现或验证步骤。
- 在 `Rust 异步编程与 tokio` 中与 `tokio` 对照：示例必须能支持 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围，否则说明这一段还缺少实现或验证步骤。
- 在 `Rust 异步编程与 tokio` 中与 `spawn_blocking` 对照：示例必须能支持 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（Rust 异步编程与 tokio）**：零成本抽象不等于零开销：记录运行时间、内存峰值与编译时间。

**本课特有开销（Rust 异步编程与 tokio · Rust）**：并发度提高后要观察是否出现拐点：延迟上升而吞吐不增，说明瓶颈已转移。

**测量方法**：以 `Rust 异步编程与 tokio` 的 `Rust` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `Rust 异步编程与 tokio` 的 `Rust`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Rust 异步编程与 tokio` 的 `异步`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Rust 异步编程与 tokio` 的 `tokio`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Rust 异步编程与 tokio` 的 `Future`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Rust 异步编程与 tokio` 的 `spawn_blocking`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `Rust 异步编程与 tokio` 中 `Rust` 的边界：静态检查只在编译期成立，运行期输入仍需校验。达到边界时不要外推，必须重新测量。
- `Rust 异步编程与 tokio` 中 `异步` 的边界：易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。达到边界时不要外推，必须重新测量。
- `Rust 异步编程与 tokio` 中 `tokio` 的边界：易错：可能死锁；正确做法是用 `tokio::sync::Mutex`。达到边界时不要外推，必须重新测量。
- `Rust 异步编程与 tokio` 中 `spawn_blocking` 的边界：易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。达到边界时不要外推，必须重新测量。
- `Rust 异步编程与 tokio` 中 `Tokio` 的边界：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。达到边界时不要外推，必须重新测量。
- `Rust 异步编程与 tokio` 的代码证据：先验证 调用了 `main()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 创建 Future 不 `.await` | 什么也没执行 | 记得 await 或 spawn |
| 在 async 里写阻塞调用 | 运行时被卡住 | 用异步版本或 `spawn_blocking` |
| 用 `std::sync::Mutex` 跨 await | 可能死锁 | 用 `tokio::sync::Mutex` |
| 忘了 `#[tokio::main]` | 编译报错 | 加在 main 上 |
| 循环里逐个 await | 慢几倍 | 用 `join_all` 或 `FuturesUnordered` |
| 无限并发 | 连接被耗尽 | 用 `Semaphore` 限流 |
| 忽略 `JoinHandle` 的结果 | 任务 panic 被吞 | 检查 `handle.await` |
| 忘了 `Send` 约束 | 跨任务编译不过 | 避免在 await 期间持有非 Send 数据 |
| 在 async 里调用阻塞 API | 整个运行时被卡住。 | 用异步版本或 spawn_blocking。 |
| 用 std::sync::Mutex 跨 .await | 编译错误或死锁风险。 | 改用 tokio::sync::Mutex。 |
| 忘记 await future | 任务从未执行（编译器会告警）。 | 补 .await。 |

### 现场 1：创建 Future 不 `.await`

**症状**：什么也没执行。

**根因与修复**：记得 await 或 spawn。

**自检**：在本课示例里复现「创建 Future 不 `.await`」，改成记得 await 或 spawn后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：在 async 里写阻塞调用

**症状**：运行时被卡住。

**根因与修复**：用异步版本或 `spawn_blocking`。

**自检**：在本课示例里复现「在 async 里写阻塞调用」，改成用异步版本或 `spawn_blocking`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：用 `std::sync::Mutex` 跨 await

**症状**：可能死锁。

**根因与修复**：用 `tokio::sync::Mutex`。

**自检**：在本课示例里复现「用 `std::sync::Mutex` 跨 await」，改成用 `tokio::sync::Mutex`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：忘了 `#[tokio::main]`

**症状**：编译报错。

**根因与修复**：加在 main 上。

**自检**：在本课示例里复现「忘了 `#[tokio::main]`」，改成加在 main 上后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：循环里逐个 await

**症状**：慢几倍。

**根因与修复**：用 `join_all` 或 `FuturesUnordered`。

**自检**：在本课示例里复现「循环里逐个 await」，改成用 `join_all` 或 `FuturesUnordered`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：无限并发

**症状**：连接被耗尽。

**根因与修复**：用 `Semaphore` 限流。

**自检**：在本课示例里复现「无限并发」，改成用 `Semaphore` 限流后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：忽略 `JoinHandle` 的结果

**症状**：任务 panic 被吞。

**根因与修复**：检查 `handle.await`。

**自检**：在本课示例里复现「忽略 `JoinHandle` 的结果」，改成检查 `handle.await`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：忘了 `Send` 约束

**症状**：跨任务编译不过。

**根因与修复**：避免在 await 期间持有非 Send 数据。

**自检**：在本课示例里复现「忘了 `Send` 约束」，改成避免在 await 期间持有非 Send 数据后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：在 async 里调用阻塞 API

**症状**：整个运行时被卡住。

**根因与修复**：用异步版本或 spawn_blocking。

**自检**：在本课示例里复现「在 async 里调用阻塞 API」，改成用异步版本或 spawn_blocking后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`Rust 实战：命令行工具`。本课默认这些内容已经掌握。
- **相关或后续**：`实战：Rust + Axum REST API`。本课术语会在这些课程里继续使用。
- **术语归属**：`Rust`、`异步`、`tokio` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《Rust Cargo 第一个程序》也涉及 `Rust`；两课衔接时先确认这个术语的定义是否一致。
- 同一分类的《Rust 变量与可变性》也涉及 `Rust`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `Rust 实战：命令行工具`：共享术语 `Rust`，共同关键词 `Rust`。
- `实战：Rust + Axum REST API`：共享术语 `Rust`、`异步`，共同关键词 `Rust`、`异步`。

### 容易混淆的相邻概念

- `Rust` 与 `异步`：前者强调 Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进；后者强调 async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `异步` 与 `tokio`：前者强调 async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程；后者强调 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `tokio` 与 `spawn_blocking`：前者强调 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围；后者强调 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `spawn_blocking` 与 `Tokio`：前者强调 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数；后者强调 Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `Rust` 的操作性定义，并说明它与 `异步` 的区别。

**参考答案**：Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进。

`异步` 的定位是：async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「创建 Future 不 `.await`」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是什么也没执行；正确做法是记得 await 或 spawn。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `rust` 示例，把其中的 `"a"` 换成一个边界值后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `rust` 示例应当复现正文给出的结果；把 `"a"` 换成边界值后，如果结果改变或报错，先核对它是否满足 `Rust 异步编程与 tokio` 中`Rust` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `rust` 示例，说明它体现了`Rust` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`Rust` 的定义是 Rust 的 async fn 由编译器生成状态机，返回 Future，Future 是惰性的，必须被 await 或被 executor 驱动才会推进，示例正是在实现这条定义。改动与 `Rust` 有关的一个输入后，如果结果不再符合 `Rust 异步编程与 tokio` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `Rust 异步编程与 tokio` 的方法迁移到自己的项目：围绕 `Rust` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「忘记 await future」，它会导致任务从未执行（编译器会告警）；检验方式是按补 .await改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `Rust` 与 `异步`：各写一行适用场景、一行失败表现。

**参考答案**：`Rust` 的定义是Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进；`异步` 的定义是async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「创建 Future 不 `.await`」引发的问题，请把“复现 什么也没执行 → 保留证据 → 记得 await 或 spawn → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按什么也没执行复现；第二步记录输入、版本与完整报错；第三步按记得 await 或 spawn只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `Tokio`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。 同时要把 `Tokio` 的定义 Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `Rust` → `异步` → `tokio` → `spawn_blocking` 的作用链。

**参考答案**：起点是 `Rust` 的定义 Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进；中间每一步都保留可观察状态；终点由 `Tokio` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `Rust 异步编程与 tokio` 中，现象是 任务从未执行（编译器会告警）。请围绕 忘记 await future 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 忘记 await future，记录输入与完整错误；再按 补 .await 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `Rust 异步编程与 tokio`：先给主问题，再按顺序说出 `Rust`、`异步`、`tokio`、`spawn_blocking`，最后给一个失败案例。

**自评标准**：主问题必须对应 Future/executor 模型、tokio API 与五个高频坑；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Rust` | Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进。 |
| `异步` | async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。 |
| `tokio` | 用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围。 |
| `spawn_blocking` | 在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数。 |
| `Tokio` | Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序。 |

**术语关系**：`Rust`（Rust 的 async fn 由编译器生成状态机） → `异步`（async/await 把等待交给执行器：任务在 await 处让出线程） → `tokio`（用 std 的 Mutex 跨 await 持有） → `spawn_blocking`（在异步任务里做阻塞操作（同步 IO、CPU 密集））。

## 考点精讲

`Rust 异步编程与 tokio` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：Rust 中 Future 的特性是？
- **正确项**：惰性，必须被 await 或 executor 驱动
- **判断依据**：这道题落在术语 `Rust` 上：Rust 的 async fn 由编译器生成状态机，返回 Future，Future 是惰性的，必须被 await 或被 executor 驱动才会推进。复习时把 `Rust` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：在异步任务中执行 CPU 密集计算应该？
- **正确项**：用 spawn_blocking 隔离到阻塞线程池
- **判断依据**：这道题落在术语 `异步` 上：async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。复习时把 `异步` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：围绕“Rust 异步编程与 tokio”中的 Rust、异步、tokio，下列哪两项是本课强调的实践判断？
- **正确项**：验证 异步 时要固定版本并覆盖边界输入，结论才可复现；学习 Rust 时要同时说明输入、输出和失败路径，不能只看正常流程
- **判断依据**：这道题落在术语 `Rust` 上：Rust 的 async fn 由编译器生成状态机，返回 Future，Future 是惰性的，必须被 await 或被 executor 驱动才会推进。复习时把 `Rust` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 4：第 4 题

- **题目**：tokio::select! 的作用是？
- **正确项**：同时等待多个 future
- **判断依据**：这道题落在术语 `tokio` 上：用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误，应使用 tokio::sync::Mutex，且尽量缩短持锁范围。复习时把 `tokio` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 5：第 5 题

- **题目**：阅读 `Rust 异步编程与 tokio` 的 `Rust` 示例。它服务于Future/executor 模型、tokio API 与五个高频坑。代码中实际包含下列哪一项？
- **正确项**：调用了 `from_millis()`
- **判断依据**：这道题落在术语 `Rust` 上：Rust 的 async fn 由编译器生成状态机，返回 Future，Future 是惰性的，必须被 await 或被 executor 驱动才会推进。复习时把 `Rust` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `Future/executor 模型、tokio API 与五个高频坑。`，这段说明是：`____`：在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数。空缺处应填哪个术语？
- **正确项**：spawn_blocking
- **判断依据**：这道题落在术语 `异步` 上：async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。复习时把 `异步` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`Rust`

- **要点**：Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进。
- **Rust 的边界**：静态检查只在编译期成立，运行期输入仍需校验。

### 考点 8：`异步`

- **要点**：async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。
- **异步 的边界**：易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。

### 考点 9：`tokio`

- **要点**：用 std 的 Mutex 跨 await 持有，会导致死锁或编译错误；应使用 tokio::sync::Mutex，且尽量缩短持锁范围。
- **tokio 的边界**：易错：可能死锁；正确做法是用 `tokio::sync::Mutex`。

### 考点 10：`spawn_blocking`

- **要点**：在异步任务里做阻塞操作（同步 IO、CPU 密集），会卡住整个执行线程，应用 spawnblocking 或限制线程数。
- **spawn_blocking 的边界**：易错：运行时被卡住；正确做法是用异步版本或 `spawn_blocking`。

### 考点 11：`Tokio`

- **要点**：Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序
- **Tokio 的边界**：共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。

### 考点 12：排错——创建 Future 不 `.await`

- **现象**：什么也没执行。
- **处理**：记得 await 或 spawn。

### 考点 13：排错——在 async 里写阻塞调用

- **现象**：运行时被卡住。
- **处理**：用异步版本或 `spawn_blocking`。

### 考点 14：综合辨析——`Rust` 与 `Tokio`

- **辨析点**：`Rust` 的定义是 Rust 的 async fn 由编译器生成状态机，返回 Future；Future 是惰性的，必须被 await 或被 executor 驱动才会推进；`Tokio` 的定义是 Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序。
- **答题要求**：面对 `Rust 异步编程与 tokio` 的题目，先判断描述的是 `Rust` 还是 `Tokio`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 15：排错评分点

- **现象分**：能写出 什么也没执行，而不是只写“程序有错”。
- **证据分**：保留触发 创建 Future 不 `.await` 的输入、版本和错误原文。
- **修复分**：按 记得 await 或 spawn 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：Rust 1.85+ / Cargo；本课聚焦 Rust。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、异步、tokio、Future、spawn_blocking
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-06-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：Rust、异步、tokio、Future、spawn_blocking。

| 参考资料 | 本课用途 |
| --- | --- |
| [Rust Async Book](https://rust-lang.github.io/async-book/) | 异步运行时与 Future |
| [Axum 文档](https://docs.rs/axum/latest/axum/) | Web 路由与提取器 |
| [The Rust Book](https://doc.rust-lang.org/book/) | 所有权、类型与工程实践 |

| [本课术语索引：Rust 异步编程与 tokio](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「Rust 异步编程与 tokio」的链接用于离线阅读后的延伸核对；App 不会自动联网。