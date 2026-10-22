## 零基础详解：并发安全与 Cargo 工作流

### 一句话说清它是什么

Rust 的并发靠两条防线：**编译期的所有权检查**（阻止数据竞争）和**标准库的同步原语**（Arc、Mutex、channel）。
Cargo 则把这套能力串成完整工作流：建项目、装依赖、测试、格式化、检查。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| `thread::spawn` | 新开一个办事窗口 | 每个线程独立栈 |
| `move` 闭包 | 把资料交给新窗口 | 所有权转移过去 |
| `Arc` | 共享钥匙 | 多线程共享同一份只读数据 |
| `Mutex` | 房间门锁 | 同一时刻只有一个人能进 |
| channel | 传送带 | 线程之间传消息 |

**口诀：多线程共享只读用 Arc，共享可写用 Arc 加 Mutex。**

### 一个完整示例：多线程计数

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = Vec::new();

    for _ in 0..10 {
        let counter = Arc::clone(&counter);      // 先克隆句柄再 move
        handles.push(thread::spawn(move || {
            let mut num = counter.lock().unwrap();   // 拿到锁才能改
            *num += 1;
        }));                                     // 锁在这里自动释放
    }

    for handle in handles {
        handle.join().unwrap();                  // 等所有线程结束
    }
    println!("结果 {}", *counter.lock().unwrap());
}
```

### 通道：更符合直觉的并发

```rust
use std::sync::mpsc;
use std::thread;

let (tx, rx) = mpsc::channel();

for id in 0..3 {
    let tx = tx.clone();
    thread::spawn(move || {
        tx.send(format!("任务 {id} 完成")).unwrap();
    });
}
drop(tx);                       // 关闭最后一个发送端，循环才能结束

for msg in rx {                 // 逐个接收
    println!("{msg}");
}
```

### Cargo 日常命令

```bash
cargo new demo             # 新建可执行项目
cargo new --lib mylib      # 新建库
cargo add serde --features derive   # 添加依赖
cargo run                  # 编译并运行
cargo test                 # 跑测试
cargo fmt                  # 统一格式
cargo clippy -- -D warnings # lint，并让警告变成错误
cargo build --release      # 发布构建
cargo doc --open           # 生成并打开文档
```

| 命令 | 什么时候用 |
| --- | --- |
| `cargo fmt` | 每次提交前 |
| `cargo clippy` | 每次提交前，能发现常见坏味道 |
| `cargo test` | 本地与 CI |
| `cargo tree` | 排查依赖来源与版本冲突 |
| `cargo audit` | 检查依赖的已知漏洞 |

### 测试放在哪里

```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adds_two_numbers() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    #[should_panic(expected = "溢出")]
    fn panics_on_overflow() {
        panic!("溢出");
    }
}
```

### 新手最容易踩的八个坑

| 坑 | 报错关键词 | 正确做法 |
| --- | --- | --- |
| 闭包忘了 `move` | 生命周期不够长 | 加 `move` 转移所有权 |
| 直接共享 `Rc` | `Rc` 不能跨线程 | 改 `Arc` |
| 忘了 `Arc::clone` | 所有权被移走 | 循环内先克隆句柄 |
| 锁使用过久 | 性能差甚至死锁 | 缩小临界区，尽早释放 |
| 在同一线程重复加锁 | 死锁 | 拆分作用域或换数据结构 |
| 忘了 `drop(tx)` | 接收循环不结束 | 主动关闭发送端 |
| 忽略 `join` 结果 | 线程 panic 被吞掉 | 检查 `join` 返回值 |
| 手动拼依赖版本 | 冲突难查 | 用 `cargo add` 与 `cargo tree` |

### 手把手练习：并发求和并汇总结果

```rust
use std::sync::mpsc;
use std::thread;

fn parallel_sum(data: Vec<i32>, chunks: usize) -> i32 {
    let (tx, rx) = mpsc::channel();
    let size = data.len().div_ceil(chunks);

    for chunk in data.chunks(size).map(|c| c.to_vec()) {
        let tx = tx.clone();
        thread::spawn(move || {
            let sum: i32 = chunk.iter().sum();
            tx.send(sum).unwrap();
        });
    }
    drop(tx);

    rx.iter().sum()
}

fn main() {
    let data: Vec<i32> = (1..=100).collect();
    println!("总和 {}", parallel_sum(data, 4));
}
```

### 学完自测

- [ ] 能说出 `Arc` 与 `Mutex` 各自解决什么问题。
- [ ] 知道 `move` 闭包为什么在 `thread::spawn` 里几乎必需。
- [ ] 能解释为什么要在循环内 `Arc::clone`。
- [ ] 知道 `join` 的作用与失败时的表现。
- [ ] 能在提交前跑 `fmt`、`clippy`、`test` 三件套。
