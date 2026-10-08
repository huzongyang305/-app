# Rust 并发与 Cargo 工程

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：50 分钟

![Rust 并发与工程工具](images/diagram_rust_concurrency.webp)

![Rust 并发与 Cargo 工程](images/remaining_rust_concurrency_cargo.webp)

## 本节知识框架

**课程定位**：所属分类为「Rust」，课程主题为「Rust 并发与 Cargo 工程」，学习阶段为「进阶」，建议用时 50 分钟。

**本课要解决的主问题**：Send/Sync、Arc+Mutex、tokio 与 Cargo 工作流。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「Rust 并发与 Cargo 工程」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「Rust 并发与 Cargo 工程」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「Rust」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《Rust 类型系统：Option、Result 与 trait》

**学习位置**：本课位于《Rust 类型系统：Option、Result 与 trait》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《Rust 错误处理、迭代器与异步》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释Rust 并发与 Cargo 工程解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「Send」、「Sync」、「Cargo」 之间的关系，并分别举出一个例子。
- 能把 Rust 放回「Rust 并发与 Cargo 工程」的知识体系，说明它和 Send 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Send/Sync、Arc+Mutex、tokio 与 Cargo 工作流。

**教材衔接：前置知识**

- 先完成上一课《Rust 类型系统：Option、Result 与 trait》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Rust 类型系统：Option、Result 与 trait」，或确认自己能独立跑通正文里的 features 示例。
- 开始前先复习：Rust、Send、Sync。
- 看不懂就直接缩小例子：只保留 Rust 相关的两行输入，跑通后再加回其余部分。

**教材衔接：本课小结**

Rust 并发的价值是**把数据竞争变成编译错误**；工程上则以 Cargo 为中心完成依赖、测试、文档与发布，clippy 与 fmt 保证团队风格一致。

## 核心概念定义

> 阅读约定：本课先给「Rust 并发与 Cargo 工程」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| Send | Rust 用两个标记 trait 保证并发安全：Send（可在线程间转移所有权）、Arc<Mutex<T>> 是跨线程共享可变状态的经典组合。 | 仅在「Rust 并发与 Cargo 工程」明确给出的输入、版本与资源条件下成立。 |
| tokio | Rust 的异步运行时，提供任务调度、异步 I/O、定时器和同步原语。 | 仅在「Rust 并发与 Cargo 工程」明确给出的输入、版本与资源条件下成立。 |
| 所有权 | 每个值只有一个所有者，离开作用域就释放；跨线程共享要用 Arc 与 Mutex。 | 仅在「Rust 并发与 Cargo 工程」明确给出的输入、版本与资源条件下成立。 |
| 互斥锁 | Mutex 提供内部可变性并保证同一时刻只有一个线程访问数据，注意避免死锁与长时间持锁。 | 仅在「Rust 并发与 Cargo 工程」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「Rust 并发与 Cargo 工程」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

**教材衔接：线程安全靠类型**

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

## 原理与运行机制

### 机制总览

1. **建立输入**：把「Send」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「tokio」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「所有权」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「Rust 并发与 Cargo 工程」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | Send | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | tokio | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 所有权 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「Rust 并发与 Cargo 工程」自己的示例验证。「Rust 并发与 Cargo 工程」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：异步生态**

`async/await` 由编译器生成状态机，需要运行时（最常用 tokio）。要点：异步函数返回 Future，必须被 await 或 spawn 才会执行；CPU 密集任务不要放在异步任务里阻塞运行时，应用 `spawn_blocking`。

**教材衔接：Cargo 速查**

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

**教材衔接：版本与时效**

- 版本提示：Rust 的行为在最近几个大版本里有过调整，升级「Rust 并发与 Cargo 工程」前先用 features 复现当前输出，再对照官方发布说明逐条核对。
- 把 Send 的编译告警当作错误处理，升级后才能避免行为漂移。
- 升级前先用 features 建立基线：记录版本、命令和输出，升级后只比较这些可观察量。
- 官方发布说明：https://blog.rust-lang.org/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 Rust 相关的差异单独记成一条结论。
- 回归范围锁定 features 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 Rust 的版本变化。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 Rust、Send | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「Rust 并发与 Cargo 工程」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「Rust 并发与 Cargo 工程」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:rust`，用于动手验证《Rust 并发与 Cargo 工程》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《Rust 并发与 Cargo 工程》原文中的最小示例。先预测《Rust 并发与 Cargo 工程》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

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

**教材衔接：Cargo：依赖、构建与测试**

| 命令 | 作用 |
| --- | --- |
| `cargo new` / `cargo init` | 创建项目 |
| `cargo build --release` | 优化构建 |
| `cargo test` | 单元测试 + 集成测试 + 文档测试 |
| `cargo fmt` / `cargo clippy` | 格式化 / 静态检查 |
| `cargo doc --open` | 生成文档 |
| `cargo bench` | 基准测试（nightly 或 criterion） |

`Cargo.toml` 声明依赖与 feature；`Cargo.lock` 锁定版本（可执行程序应提交，库一般不提交）。工作区（workspace）可管理多 crate 单仓库。

**教材衔接：原文最小示例**

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

## 时间/空间复杂度或性能分析

**复杂度证据**：「Rust 并发与 Cargo 工程」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「Rust 并发与 Cargo 工程」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「Rust 并发与 Cargo 工程」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

**教材衔接：并发速查**

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

**教材衔接：零基础详解：并发安全与 Cargo 工作流**

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

## 常见误区与易错点

> 复核《Rust 并发与 Cargo 工程》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「Rust 并发与 Cargo 工程」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

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

**教材衔接：故障现场**

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

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《Rust 类型系统：Option、Result 与 trait》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《Rust 错误处理、迭代器与异步》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《Rust 类型系统：Option、Result 与 trait》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《Rust 错误处理、迭代器与异步》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「Rust 并发与 Cargo 工程」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《Rust 并发与 Cargo 工程》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

围绕“Rust 并发与 Cargo 工程”中的 Rust、Send、Sync，下列哪两项是本课强调的实践判断？

A. 把 Send 的单次运行结果当成所有版本和规模都成立
B. 学习 Rust 时要同时说明输入、输出和失败路径，不能只看正常流程
C. 只要 Rust 的常规示例通过，就可以跳过边界与异常路径
D. 验证 Send 时要固定版本并覆盖边界输入，结论才可复现

**参考答案**：学习 Rust 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Send 时要固定版本并覆盖边界输入，结论才可复现

**解析**：在「Rust 并发与 Cargo 工程」里，题干的正确项是学习 Rust 时要同时说明输入、输出和失败路径，不能只看正常流程。在Rust 并发与 Cargo 工程里，判断 Send 时要固定版本与边界输入，所以“验证 Send 时要固定版本并覆盖边界输入，结论才可复现”才可复现。把“学习 Rust 时要同时说明输入”代回「Rust 并发与 Cargo 工程」里“围绕Rust 并发与 Cargo 工程中的 Rust、Sen”的例子核对，条件一旦改变，结论就要用Rust、Send、Sync重新推导。

### 自测 2

多线程共享可变状态的经典组合是？

A. Box<T>
B. Cow<T>
C. Rc<RefCell<T>>
D. Arc<Mutex<T>>

**参考答案**：Arc<Mutex<T>>

**解析**：在「Rust 并发与 Cargo 工程」里，Arc<Mutex<T>>。Arc 提供共享所有权，Mutex 保证互斥访问。回到「Rust 并发与 Cargo 工程」的正文示例，用“多线程共享可变状态的经典组合是”走一遍Rust、Send、Sync的完整流程，能复现的结论才可以保留。

### 自测 3

下面这段 Rust 代码摘自「Rust 并发与 Cargo 工程」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？

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

A. 这段代码只做静态声明，没有循环、分支或可观察输出。
B. 这段代码包含循环结构，同一段逻辑会被重复执行。
C. 这段代码会读取外部输入，结果依赖传入的数据。
D. 这段代码会产生可观察的输出，运行后能看到结果。

**参考答案**：这段代码包含循环结构，同一段逻辑会被重复执行。

**解析**：在「Rust 并发与 Cargo 工程」里，这段代码包含循环结构，同一段逻辑会被重复执行。这段代码出自「Rust 并发与 Cargo 工程」的正文示例，围绕Rust、Send、Sync展开；把输入或边界换成空值、极值或失败情况后，结论要以「Rust 并发与 Cargo 工程」的实际运行结果为准。

**教材衔接：复习与自测**

- [ ] 跨线程闭包使用 `move` 转移所有权。
- [ ] 共享可变状态使用 `Arc<Mutex<T>>`，并注意中毒处理。
- [ ] 能解释 `Send` 与 `Sync` 的区别。
- [ ] 二进制项目提交 `Cargo.lock`，库项目一般不提交。
- [ ] CI 跑 `cargo fmt --check`、`clippy -D warnings`、`test`、`audit`。

**教材衔接：动手练习**

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

**教材衔接：可运行练习**

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

**教材衔接：本课复习清单**

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

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `Send` | Rust 用两个标记 trait 保证并发安全：`Send`（可在线程间转移所有权）、`Arc<Mutex<T>>` 是跨线程共享可变状态的经典组合。 |
| `tokio` | Rust 的异步运行时，提供任务调度、异步 I/O、定时器和同步原语。 |
| `所有权` | 每个值只有一个所有者，离开作用域就释放；跨线程共享要用 Arc 与 Mutex。 |
| `互斥锁` | Mutex 提供内部可变性并保证同一时刻只有一个线程访问数据，注意避免死锁与长时间持锁。 |

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
- **判断依据**：在「Rust 并发与 Cargo 工程」里，结论应落在「Send 表示所有权可安全转移到别的线程」。Rc 既不是 Send 也不是 Sync，Arc 两者都满足，所以跨线程共享要用 Arc。在「Rust 并发与 Cargo 工程」里，这道题要求区分概念与边界，「Send 表示所有权可安全转移到别的线程」只有在题干给出的前提下才成立，而「Send 只用于值类型」、「Sync 表示可以发送到线程，但这会加重锁竞争」缺少同一组条件。

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
- 下次复核：2027-06-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Cargo Book](https://doc.rust-lang.org/cargo/) | 依赖、工作区与发布 |
| [Rust Async Book](https://rust-lang.github.io/async-book/) | 异步运行时与 Future |
| [Clippy 文档](https://doc.rust-lang.org/clippy/) | Lint 与惯用写法 |

> 「Rust 并发与 Cargo 工程」的链接用于离线阅读后的延伸核对；App 不会自动联网。
