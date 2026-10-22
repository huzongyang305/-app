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
