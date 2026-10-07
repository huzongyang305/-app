# Rust 并发与 Cargo 工程

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：35 分钟

![Rust 并发与工程工具](images/diagram_rust_concurrency.webp)

![Rust 并发与 Cargo 工程](images/remaining_rust_concurrency_cargo.webp)

## 学习目标

- 能用自己的话解释Rust 并发与 Cargo 工程解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「Send」、「Sync」、「Cargo」 之间的关系，并分别举出一个例子。
- 能把 Rust 放回「Rust 并发与 Cargo 工程」的知识体系，说明它和 Send 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Send/Sync、Arc+Mutex、tokio 与 Cargo 工作流。

## 前置知识

- 先完成上一课《Rust 类型系统：Option、Result 与 trait》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Rust 类型系统：Option、Result 与 trait」，或确认自己能独立跑通正文里的 features 示例。
- 开始前先复习：Rust、Send、Sync。
- 看不懂就直接缩小例子：只保留 Rust 相关的两行输入，跑通后再加回其余部分。

## 线程安全靠类型

Rust 用两个标记 trait 保证并发安全：`Send`（可在线程间转移所有权）、`Arc<Mutex<T>>` 是跨线程共享可变状态的经典组合。

| 工具 | 场景 |
| --- | --- |
| `thread::spawn` + `join` | 基础线程 |
| `std::sync::mpsc` | 线程间消息传递（多生产者单消费者） |
| `Mutex<T>` / `RwLock<T>` | 共享可变状态 |
| `Arc<T>` | 多线程共享所有权 |
| `atomic` 类型 | 无锁计数器与标志位 |
| `rayon`（生态） | 数据并行，把 `iter()` 换成 `par_iter()` |

编译期即可发现数据竞争：忘记加锁的共享可变状态**根本编译不过**。

## Cargo：依赖、构建与测试

| 命令 | 作用 |
| --- | --- |
| `cargo new` / `cargo init` | 创建项目 |
| `cargo build --release` | 优化构建 |
| `cargo test` | 单元测试 + 集成测试 + 文档测试 |
| `cargo fmt` / `cargo clippy` | 格式化 / 静态检查 |
| `cargo doc --open` | 生成文档 |
| `cargo bench` | 基准测试（nightly 或 criterion） |

`Cargo.toml` 声明依赖与 feature；`Cargo.lock` 锁定版本（可执行程序应提交，库一般不提交）。工作区（workspace）可管理多 crate 单仓库。

## 异步生态

`async/await` 由编译器生成状态机，需要运行时（最常用 tokio）。要点：异步函数返回 Future，必须被 await 或 spawn 才会执行；CPU 密集任务不要放在异步任务里阻塞运行时，应用 `spawn_blocking`。

## 本课小结

Rust 并发的价值是**把数据竞争变成编译错误**；工程上则以 Cargo 为中心完成依赖、测试、文档与发布，clippy 与 fmt 保证团队风格一致。

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

## 常见错误与排查

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

## 复习与自测

- [ ] 跨线程闭包使用 `move` 转移所有权。
- [ ] 共享可变状态使用 `Arc<Mutex<T>>`，并注意中毒处理。
- [ ] 能解释 `Send` 与 `Sync` 的区别。
- [ ] 二进制项目提交 `Cargo.lock`，库项目一般不提交。
- [ ] CI 跑 `cargo fmt --check`、`clippy -D warnings`、`test`、`audit`。

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

## 动手练习

> 本课练习重点：围绕「Rust、Send、Sync」完成复述、实验和交付，每个结果都要能被别人检查。

写一个只包含 Rust 的最小程序，先验证正常路径，再制造一次失败。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Rust 并发与 Cargo 工程解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Send」是什么关系？

验收标准：用自己的话解释 Rust，并给出一个它不成立的反例。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：五步记录要写进笔记——原例是 features，改动落在Rust上，结论必须能被他人在同一环境里复现。

### 练习 3：交付一个小结果（30 分钟）

写一个只包含 Rust 的最小程序，先验证正常路径，再制造一次失败。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Rust」和「Send」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

### 任务 1：先跑通，再解释

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

### 任务 2：只改一个条件

把「Rust 并发与 Cargo 工程」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 Send 换成边界值，其他输入保持原样。
- 预测：先写下「Rust 并发与 Cargo 工程」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响Rust。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的 Rust 数据，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：cannot be sent between threads safely

**症状**：在《Rust 并发与 Cargo 工程》的复现场景中，类型不是 Send。

**根因**：“类型不是 Send”只是表层结果。向上追溯会落到“cannot be sent between threads safely”这一步，因为它省略了《Rust 并发与 Cargo 工程》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Rust 并发与 Cargo 工程》的问题，用 Arc<Mutex<T>> 或改数据结构。

**验证**：先在《Rust 并发与 Cargo 工程》中记录“cannot be sent between threads safely”留下的失败证据，再执行“用 Arc<Mutex<T>> 或改数据结构”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 2：cannot be shared between threads safely

**症状**：在《Rust 并发与 Cargo 工程》的复现场景中，类型不是 Sync。

**根因**：触发点是把“cannot be shared between threads safely”当成安全做法。它没有满足《Rust 并发与 Cargo 工程》要求的前提，因此先表现为“类型不是 Sync”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Rust 并发与 Cargo 工程》的问题，同上，或改用消息传递。

**验证**：保留《Rust 并发与 Cargo 工程》里触发“类型不是 Sync”的输入、版本和日志，按“同上，或改用消息传递”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：borrowed value does not live long enough

**症状**：在《Rust 并发与 Cargo 工程》的复现场景中，跨线程借用逃逸。

**根因**：触发点是把“borrowed value does not live long enough”当成安全做法。它没有满足《Rust 并发与 Cargo 工程》要求的前提，因此先表现为“跨线程借用逃逸”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Rust 并发与 Cargo 工程》的问题，用 move 闭包转移所有权。

**验证**：先在《Rust 并发与 Cargo 工程》中记录“borrowed value does not live long enough”留下的失败证据，再执行“用 move 闭包转移所有权”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

## 版本与时效

- 版本提示：Rust 的行为在最近几个大版本里有过调整，升级「Rust 并发与 Cargo 工程」前先用 features 复现当前输出，再对照官方发布说明逐条核对。
- 把 Send 的编译告警当作错误处理，升级后才能避免行为漂移。
- 升级前先用 features 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。
- 官方发布说明：https://blog.rust-lang.org/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 Rust 相关的差异单独记成一条结论。
- 回归范围锁定 features 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 Rust 的版本变化。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「标记类型可安全跨线程转移所有权的 trait 是？」的判断依据。
- [ ] 不看解析，能说出「多线程共享可变状态的经典组合是？」的判断依据。
- [ ] 不看解析，能说出「关于 Cargo.lock，正确做法是？」的判断依据。
- [ ] 不看解析，能说出「Send 与 Sync 两个 auto trait 的区别是？」的判断依据。
- [ ] 不看解析，能说出「cargo build --release 相比默认开发构建的差别是？」的判断依据。
- [ ] 用 Rust 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Send` | Rust 用两个标记 trait 保证并发安全：`Send`（可在线程间转移所有权）、`Arc<Mutex<T>>` 是跨线程共享可变状态的经典组合。 |
| `tokio` | Rust 的异步运行时，提供任务调度、异步 I/O、定时器和同步原语。 |
| `一句话说清它是什么` | Rust 的并发靠两条防线：编译期的所有权检查（阻止数据竞争）和标准库的同步原语（Arc、Mutex、channel）。 |
| `用生活比喻理解` | 口诀：多线程共享只读用 Arc，共享可写用 Arc 加 Mutex。 |

## 考点精讲

### 考点 1：多选辨析·Rust

- **题目**：围绕“Rust 并发与 Cargo 工程”中的 Rust、Send、Sync，下列哪两项是本课强调的实践判断？
- **判断依据**：在「Rust 并发与 Cargo 工程」里，题干的正确项是学习 Rust 时要同时说明输入、输出和失败路径，不能只看正常流程。在Rust 并发与 Cargo 工程里，判断 Send 时要固定版本与边界输入，所以“验证 Send 时要固定版本并覆盖边界输入，结论才可复现”才可复现。把“学习 Rust 时要同时说明输入”代回「Rust 并发与 Cargo 工程」里“围绕Rust 并发与 Cargo 工程中的 Rust、Sen”的例子核对，条件一旦改变，结论就要用Rust、Send、Sync重新推导。

### 考点 2：概念判断·Rust

- **题目**：多线程共享可变状态的经典组合是？
- **判断依据**：在「Rust 并发与 Cargo 工程」里，Arc<Mutex<T>>。Arc 提供共享所有权，Mutex 保证互斥访问。回到「Rust 并发与 Cargo 工程」的正文示例，用“多线程共享可变状态的经典组合是”走一遍Rust、Send、Sync的完整流程，能复现的结论才可以保留。

### 考点 3：代码补全·Rust

- **题目**：下面这段 Rust 代码摘自「Rust 并发与 Cargo 工程」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？
- **判断依据**：在「Rust 并发与 Cargo 工程」里，这段代码包含循环结构，同一段逻辑会被重复执行。这段代码出自「Rust 并发与 Cargo 工程」的正文示例，围绕Rust、Send、Sync展开；把输入或边界换成空值、极值或失败情况后，结论要以「Rust 并发与 Cargo 工程」的实际运行结果为准。

### 考点 4：概念判断·Rust

- **题目**：Send 与 Sync 两个 auto trait 的区别是？
- **判断依据**：在「Rust 并发与 Cargo 工程」里，结论应落在「Send 表示所有权可安全转移到别的线程」。Rc 既不是 Send 也不是 Sync，Arc 两者都满足，所以跨线程共享要用 Arc。在「Rust 并发与 Cargo 工程」里，这道题要求区分概念与边界，「Send 表示所有权可安全转移到别的线程」只有在题干给出的前提下才成立，而「Send 只用于值类型」、「Sync 表示可以发送到线程」缺少同一组条件。

### 考点 5：概念判断·Rust

- **题目**：cargo build --release 相比默认开发构建的差别是？
- **判断依据**：基准测试与性能分析必须用 --release，否则数据没有参考价值。在「Rust 并发与 Cargo 工程」里，其他选项：release 开启优化并关闭调试断言，运行更快、编译更慢。“cargo”与「Rust 并发与 Cargo 工程」的术语表相呼应，只有符合Rust、Send、Sync约束的“开启优化并关闭调试断言”才是正文支持的结论。

### 考点 6：填空·Rust

- **题目**：补全代码：「Rust 并发与 Cargo 工程」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `let mut value = counter.lock.____;`
- **判断依据**：在「Rust 并发与 Cargo 工程」里，unwrap。回到「Rust 并发与 Cargo 工程」的正文示例，用“补全代码”走一遍Rust、Send、Sync的完整流程，能复现的结论才可以保留。回到Rust、Send、Sync本身再看一遍：只有“unwrap”与题干“Rust”的前提一致，结论才成立。

## English Overview

**Title:** Rust Concurrency & Cargo

**Summary:** Send/Sync, Arc+Mutex, tokio and Cargo.

**Category:** Rust
**Level:** 进阶
**Key terms:** Rust, Send, Sync, Cargo, tokio

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Rust 1.85+ / Cargo
；本课聚焦 Rust。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、Send、Sync、Cargo、tokio
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-06-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Cargo Book](https://doc.rust-lang.org/cargo/) | 依赖、工作区与发布 |
| [Rust Async Book](https://rust-lang.github.io/async-book/) | 异步运行时与 Future |
| [Clippy 文档](https://doc.rust-lang.org/clippy/) | Lint 与惯用写法 |

> 「Rust 并发与 Cargo 工程」的链接用于离线阅读后的延伸核对；App 不会自动联网。
