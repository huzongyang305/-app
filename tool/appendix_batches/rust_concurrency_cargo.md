## 并发速查

| 目的 | 工具 |
| --- | --- |
| 启动线程 | `std::thread::spawn` |
| 等待线程 | `handle.join()` |
| 共享只读数据 | `Arc<T>` |
| 共享可变数据 | `Arc<Mutex<T>>` / `Arc<RwLock<T>>` |
| 消息传递 | `std::sync::mpsc::channel` |
| 跨线程转移所有权 | 类型需实现 `Send` |
| 多线程共享引用 | 类型需实现 `Sync` |
| 异步任务 | `tokio::spawn` |
| 原子操作 | `AtomicUsize`、`AtomicBool` |

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    let counter = Arc::new(Mutex::new(0));
    let mut handles = Vec::new();

    for _ in 0..4 {
        let counter = Arc::clone(&counter);
        handles.push(thread::spawn(move || {
            for _ in 0..1000 {
                let mut value = counter.lock().unwrap();
                *value += 1;
            }
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }
    println!("{}", *counter.lock().unwrap());   // 4000
}
```

注意：`Mutex` 存在**中毒（poisoning）** 机制，持锁线程 panic 后 `lock()` 会返回 `Err`，可用 `into_inner()` 或 `unwrap_or_else` 处理。

## Cargo 速查

| 文件 / 命令 | 说明 |
| --- | --- |
| `Cargo.toml` | 包元数据与依赖声明 |
| `Cargo.lock` | 精确锁定版本，**二进制项目应提交**，库项目一般不提交 |
| `[dependencies]` | 运行时依赖 |
| `[dev-dependencies]` | 测试与示例依赖 |
| `[features]` | 可选功能开关 |
| `cargo add serde --features derive` | 添加依赖 |
| `cargo tree -i crate_name` | 查看谁依赖了某个 crate |
| `cargo audit` | 依赖漏洞扫描 |
| `cargo deny` | 许可证与依赖策略检查 |
| `cargo bench` | 基准测试 |

## 常见错误对照表

| 编译错误或现象 | 含义 | 处理方式 |
| --- | --- | --- |
| `cannot be sent between threads safely` | 类型不是 `Send` | 用 `Arc<Mutex<T>>` 或改数据结构 |
| `cannot be shared between threads safely` | 类型不是 `Sync` | 同上，或改用消息传递 |
| `borrowed value does not live long enough` | 跨线程借用逃逸 | 用 `move` 闭包转移所有权 |
| 忘写 `move` | 闭包借用局部变量 | 线程闭包用 `move` |
| 死锁 | 两个锁交叉获取 | 统一加锁顺序，或用单锁保护多数据 |
| `Mutex` 中毒后 `unwrap()` panic | 前一个持锁者已 panic | 处理 `Err` 或 `into_inner()` 恢复 |
| 依赖版本冲突 | 编译错误或行为不一致 | `cargo tree` 定位并统一版本 |
| 提交了库项目的 `Cargo.lock` | 使用者被强绑版本 | 库不提交，二进制提交 |
| 未固定工具链 | 不同机器行为不同 | 提交 `rust-toolchain.toml` |
| 忘记开 `--release` 做基准 | 数据偏慢 | 性能测试必须 `--release` |

## 自测清单

- [ ] 跨线程闭包使用 `move` 转移所有权。
- [ ] 共享可变状态使用 `Arc<Mutex<T>>`，并注意中毒处理。
- [ ] 能解释 `Send` 与 `Sync` 的区别。
- [ ] 二进制项目提交 `Cargo.lock`，库项目一般不提交。
- [ ] CI 跑 `cargo fmt --check`、`clippy -D warnings`、`test`、`audit`。
