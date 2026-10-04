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

## 常见错误对照表

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

## 自测清单

- [ ] 异步链路中不出现阻塞调用。
- [ ] 跨 `.await` 的共享状态使用 `tokio::sync` 原语。
- [ ] 所有外部调用都有超时与取消。
- [ ] 并发任务数量受信号量限制。
- [ ] 任务错误被记录，不被静默丢弃。
