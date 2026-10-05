# Rust 基础

![Rust 基础](images/remaining_rust_basics.webp)

> 内容更新时间：2026-10-03 · 学习阶段：基础 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「Rust 基础」解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「所有权」、「借用」、「生命周期」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Rust」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：所有权、借用检查、Result 与并发安全。

## 前置知识

- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。
- 本课阶段：基础。建议会读写简单代码或命令，并理解变量、输入输出等基本概念。
- 开始前先复习：Rust、所有权、借用。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 语言定位

Rust 是系统级语言，用**编译期检查**替代垃圾回收，做到内存安全与零成本抽象。它适合操作系统、嵌入式、网络中间件与高性能 CLI（Firefox、Linux 内核、Deno 都有 Rust 代码）。

## 所有权：核心中的核心

三条规则：每个值有唯一所有者；同一时刻只能有一个所有者；所有者离开作用域时值被释放。

| 概念 | 说明 |
| --- | --- |
| Move | 赋值或传参会转移所有权，原变量失效 |
| Borrow | `&T` 不可变借用，`&mut T` 可变借用 |
| 借用规则 | 要么多个不可变借用，要么一个可变借用，二者不能同时存在 |
| 生命周期 | 用标注告诉编译器引用的有效范围 |

这套规则在编译期消灭了悬垂指针、重复释放与数据竞争。

## 类型系统

| 类型 | 用途 |
| --- | --- |
| Option<T> | 表示可能没有值，替代 null |
| Result<T, E> | 表示可能失败，配合 `?` 传播错误 |
| struct / enum | 数据建模，enum 可携带数据（类似代数数据类型） |
| trait | 定义共享行为，可静态分发（泛型）或动态分发（dyn） |
| 智能指针 | Box、Rc、Arc、RefCell，用于堆分配与共享所有权 |

模式匹配（match）配合 enum 是 Rust 表达业务状态的常用方式，要求穷尽所有分支。

## 并发安全

Rust 用类型系统保证线程安全：`Send` 表示可跨线程转移，`Sync` 表示可被多线程共享引用。标准库提供 thread、channel（mpsc）、Mutex、RwLock 与原子类型；`Arc<Mutex<T>>` 是跨线程共享可变状态的经典组合。

## 工程实践

1. Cargo 一体化管理依赖、构建、测试与文档（Cargo.toml）。
2. 错误处理：库用 thiserror 定义错误类型，应用用 anyhow 简化传播。
3. `cargo fmt`、`cargo clippy`、`cargo test` 是标准三件套。
4. 与 C 互操作用 FFI / bindgen；嵌入式用 no_std。
5. 性能敏感场景可用 unsafe，但必须写清安全前提并尽量封装在小范围内。

## 学习曲线提示

初学者最容易卡在「借用检查器」。建议：先理解所有权与借用规则，再学生命周期；遇到编译错误先读完整提示（Rust 的错误信息质量很高），必要时用 clone 让代码先跑通，再逐步消除不必要的拷贝。

## 本课小结
Rust 用**所有权 + 借用检查 + 类型系统**把内存与并发错误前移到编译期。前期学习成本高，换来的是运行期几乎零开销的安全保障。


## 基础语法速查

| 概念 | 写法 | 说明 |
| --- | --- | --- |
| 不可变绑定 | `let x = 1;` | 默认不可变 |
| 可变绑定 | `let mut x = 1;` | 需要修改时显式声明 |
| 常量 | `const MAX: u32 = 100;` | 必须标注类型 |
| 静态变量 | `static NAME: &str = "app";` | 全程存活 |
| 元组 | `let (a, b) = (1, "x");` | 可解构 |
| 数组 | `let a = [1, 2, 3];` | 固定长度 |
| 切片 | `&a[1..3]` | 借用一部分 |
| 字符串 | `String` / `&str` | 拥有 vs 借用 |
| 枚举 | `enum Status { Ok, Err(String) }` | 可携带数据 |
| 模式匹配 | `match value { ... }` | 必须穷尽 |
| `if let` | 只关心一个分支 | 简化 match |

```rust
#[derive(Debug, Clone, PartialEq)]
enum Command {
    Quit,
    Echo(String),
    Move { x: i32, y: i32 },
}

fn run(cmd: Command) -> String {
    match cmd {
        Command::Quit => "退出".to_string(),
        Command::Echo(text) => text,
        Command::Move { x, y } => format!("移动到 ({x}, {y})"),
    }
}

fn main() {
    println!("{}", run(Command::Move { x: 1, y: 2 }));

    // 错误处理不用异常，用 Result
    let parsed: Result<i32, _> = "42".parse();
    match parsed {
        Ok(n) => println!("解析成功：{n}"),
        Err(e) => eprintln!("解析失败：{e}"),
    }
}
```

## 常用命令速查

| 目的 | 命令 |
| --- | --- |
| 新建项目 | `cargo new app` / `cargo init` |
| 编译 | `cargo build` / `cargo build --release` |
| 运行 | `cargo run -- args` |
| 测试 | `cargo test` |
| 格式检查 | `cargo fmt --check` |
| 静态检查 | `cargo clippy -- -D warnings` |
| 更新依赖 | `cargo update` |
| 查看依赖树 | `cargo tree` |
| 文档 | `cargo doc --open` |
| 检查不产出二进制 | `cargo check` |

## 常见错误对照表

| 编译错误 | 含义 | 处理方式 |
| --- | --- | --- |
| `cannot find value x in this scope` | 变量未定义或作用域外 | 检查拼写与作用域 |
| `cannot assign twice to immutable variable` | 未加 `mut` | 加 `mut` 或改为重新绑定 |
| `mismatched types` | 类型不一致 | 显式转换（`as`、`parse`、`into`） |
| `expected &str, found String` | 需要借用 | 传 `&s` 或 `s.as_str()` |
| `non-exhaustive patterns` | `match` 未覆盖所有情况 | 补分支或加 `_ =>` |
| `unused variable` 告警 | 变量未使用 | 用 `_` 前缀或删除 |
| `cannot borrow as mutable` | 借用冲突 | 缩短作用域或调整可变性 |
| `the trait bound ... is not satisfied` | 类型缺少所需 trait | 实现 trait 或改用满足约束的类型 |
| 整数溢出（debug） | panic | 用 `checked_add` / `wrapping_add` 明确行为 |
| 忘记 `use` 导入 | `cannot find` 错误 | 补 `use` 语句 |

## 自测清单

- [ ] 变量默认不可变，需要修改时显式 `mut`。
- [ ] 会用 `match` 与 `if let` 处理枚举。
- [ ] 错误处理用 `Result` 而不是异常。
- [ ] 常用命令中 `cargo check` 用于快速反馈。
- [ ] 提交前跑 `cargo fmt` 与 `cargo clippy`。


## 零基础详解：Cargo、变量与第一个 Rust 程序

### 一句话说清它是什么

Rust 是一门**编译期就把内存安全问题查出来**的系统级语言。
它不靠垃圾回收，而是靠所有权规则在编译阶段保证不出现空指针、数据竞争这类问题。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| Cargo | 项目经理 | 建项目、装依赖、编译、测试、发布全管 |
| crate | 一个交付单元 | 可执行程序或库 |
| `fn main` | 大门 | 程序入口 |
| 所有权 | 物品只有一个主人 | 值被移动后，原变量不能再使用 |
| 借用 | 借出去用一下 | 用 `&` 临时借，用完归还 |

### 逐行拆解第一个程序

```rust
fn main() {                       // 入口函数，无返回值
    let name = "小明";             // 不可变变量（默认就不可变）
    let mut count = 0;            // 需要修改要显式加 mut
    count += 1;

    println!("你好，{name}，计数 {count}");   // 宏，末尾带感叹号
}
```

| 语法点 | 说明 |
| --- | --- |
| `let name = ...` | 默认不可变，**想改变量必须写 `mut`** |
| `{name}` | 内联变量，比写参数更直观 |
| `println!` | 这是宏不是函数，所以有 `!` |
| 语句结尾 | 表达式后面不加分号会作为返回值，这点很关键 |

### Cargo 常用命令

```bash
cargo new demo          # 新建可执行项目
cargo new --lib mylib   # 新建库项目
cargo run               # 编译并运行
cargo build --release   # 发布构建，开优化
cargo test              # 跑测试
cargo clippy            # 官方 lint，强烈建议每次提交前跑
cargo fmt               # 统一格式
```

### 变量、常量与遮蔽

```rust
const MAX_RETRY: u32 = 3;      // 常量：全大写、必须标类型

let x = 5;
let x = x + 1;                 // 遮蔽（shadowing）：可以换类型
let x = "现在是字符串";          // 合法，因为是新的绑定

let mut y = 5;
y = 6;                         // 同一个变量，类型不能变
```

| 概念 | 关键字 | 能否改 | 能否换类型 |
| --- | --- | --- | --- |
| 不可变变量 | `let` | 不能 | 通过遮蔽可以 |
| 可变变量 | `let mut` | 能 | 不能 |
| 常量 | `const` | 不能 | 不能，必须标类型 |

### 类型与整数家族

| 类型 | 说明 | 默认 |
| --- | --- | --- |
| `i32` / `i64` | 有符号整数 | `i32` |
| `u32` / `usize` | 无符号整数 | `usize` 用于下标 |
| `f64` | 浮点数 | `f64` |
| `bool` | 布尔 | 不能与数字互转 |
| `char` | 4 字节 Unicode 字符 | 单引号 |
| `String` / `&str` | 可变字符串 / 字符串切片 | 见所有权一篇 |

### 新手最容易踩的八个坑

| 坑 | 报错信息 | 正确做法 |
| --- | --- | --- |
| 忘记 `mut` | `cannot assign twice to immutable variable` | 加 `mut`，或改用新绑定 |
| 用 `!` 取反整数 | `cannot apply unary operator` | Rust 的 `!` 是按位取反，逻辑非是 `!` 只用于 bool |
| 整数与浮点混算 | `mismatched types` | 显式 `as f64` 或改用同类型 |
| 字符串用 `==` 比较不同类型 | 类型不匹配 | `String` 与 `&str` 比较可用 `==`，但要注意解引用 |
| 忘加分号导致类型错 | `expected ()` | 检查表达式是否意外成了返回值 |
| 下标越界 | 运行时 panic | 用 `get(i)` 返回 `Option` |
| 整数溢出 | debug 下 panic，release 下回绕 | 用 `checked_add` 等显式处理 |
| 忘记 `;` 在宏调用后 | 语法错误 | `println!(...);` 要加分号 |

### 手把手练习：猜数字的纯逻辑版

```rust
use std::cmp::Ordering;

fn compare(secret: i32, guess: i32) -> &'static str {
    match guess.cmp(&secret) {
        Ordering::Less => "小了",
        Ordering::Greater => "大了",
        Ordering::Equal => "猜对了",
    }
}

fn main() {
    let secret = 7;
    for guess in [3, 9, 7] {
        println!("猜 {guess}：{}", compare(secret, guess));
    }
}
```

`match` 必须覆盖所有情况，编译器会检查是否漏了分支——这就是 Rust 的安全感来源。

### 学完自测

- [ ] 能说出 `let`、`let mut`、`const` 的区别。
- [ ] 能解释为什么 Rust 里 `println!` 带感叹号。
- [ ] 知道变量遮蔽与重新赋值的区别。
- [ ] 能说出 `cargo run` 与 `cargo build --release` 的差别。
- [ ] 遇到编译错误时，先读编译器给的「help」建议。

## 动手练习


> 本课练习重点：围绕「Rust、所有权、借用」完成复述、实验和交付，每个结果都要能被别人检查。

先让 cargo check 通过，再补所有权、错误和并发边界，最后运行 clippy。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Rust 基础」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「所有权」是什么关系？

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
- 至少覆盖「Rust」和「所有权」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Rust 在编译期保证内存安全依靠什么？

- **正确判断**：所有权与借用检查
- **判断依据**：所有权规则在编译期消灭悬垂指针、重复释放与数据竞争。其他选项：Rust 用所有权与借用检查在编译期消除悬垂引用与数据竞争，不依赖 GC。针对「Rust 在编译期保证内存安全依靠什么，」，本课在「学习曲线提示」中说明：建议：先理解所有权与借用规则，再学生命周期。本课还在「语言定位」中说明：Rust 是系统级语言，用编译期检查替代垃圾回收，做到内存安全与零成本抽象。本课还在「本课小结」中说明：Rust 用所有权 + 借用检查 + 类型系统把内存与并发错误前移到编译期。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：Rust 的借用规则是？

- **正确判断**：要么多个不可变借用
- **判断依据**：正确答案是「要么多个不可变借用」，本课在「学习曲线提示」中说明：建议：先理解所有权与借用规则，再学生命周期。这条规则从类型层面杜绝了数据竞争。本课还在「零基础详解：Cargo、变量与第一个 Rust 程序」中说明：它不靠垃圾回收，而是靠所有权规则在编译阶段保证不出现空指针、数据竞争这类问题。本课还在「本课小结」中说明：Rust 用所有权 + 借用检查 + 类型系统把内存与并发错误前移到编译期。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：Rust 中表示可能失败的操作使用什么类型？

- **正确判断**：Result<T, E>
- **判断依据**：Result 表示成功或失败，配合 ? 运算符传播错误。其他选项：Result<T, E> 表达可能失败，Option<T> 只表达可能没有值，Rust 没有异常机制。针对「Rust 中表示可能失败的操作使用什么类型，」，本课在「并发安全」中说明：Rust 用类型系统保证线程安全：Send 表示可跨线程转移，Sync 表示可被多线程共享引用。本课还在「工程实践」中说明：错误处理：库用 thiserror 定义错误类型，应用用 anyhow 简化传播。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 4：Rust 中 mut 关键字的作用是？

- **正确判断**：让绑定可变
- **判断依据**：正确答案是「让绑定可变」，本课在「并发安全」中说明：Arc<Mutex<T>> 是跨线程共享可变状态的经典组合。Rust 默认不可变，mut 是显式声明，编译器据此检查借用冲突。本课还在「并发安全」中说明：Rust 用类型系统保证线程安全：Send 表示可跨线程转移，Sync 表示可被多线程共享引用。本课还在「工程实践」中说明：cargo fmt、cargo clippy、cargo test 是标准三件套。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：rustup 与 cargo 的分工是？

- **正确判断**：rustup 管理工具链与版本
- **判断依据**：常用命令：rustup update 升级工具链，cargo build / test / run 操作项目。其他选项：rustup 管理工具链与版本。针对「rustup 与 cargo 的分工是，」，本课在「零基础详解：Cargo、变量与第一个 Rust 程序」中说明：它不靠垃圾回收，而是靠所有权规则在编译阶段保证不出现空指针、数据竞争这类问题。本课还在「学习曲线提示」中说明：遇到编译错误先读完整提示（Rust 的错误信息质量很高），必要时用 clone 让代码先跑通，再逐步消除不必要的拷贝。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 6：补全代码：「Rust 基础」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `fn ____(secret: i32, guess: i32) -> &'static str {`

- **正确判断**：compare
- **判断依据**：正确答案是「compare」，本课在「零基础详解：Cargo、变量与第一个 Rust 程序」中说明：能说出 cargo run 与 cargo build --release 的差别。本课还在「语言定位」中说明：它适合操作系统、嵌入式、网络中间件与高性能 CLI（Firefox、Linux 内核、Deno 都有 Rust 代码）。本课还在「类型系统」中说明：模式匹配（match）配合 enum 是 Rust 表达业务状态的常用方式，要求穷尽所有分支。
- **迁移检查**：如果填成相近的另一个函数或关键字，程序会在哪一步出错？

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Rust 在编译期保证内存安全依靠什么？」的判断依据。
- [ ] 不看解析，能说出「Rust 的借用规则是？」的判断依据。
- [ ] 不看解析，能说出「Rust 中表示可能失败的操作使用什么类型？」的判断依据。
- [ ] 不看解析，能说出「Rust 中 mut 关键字的作用是？」的判断依据。
- [ ] 不看解析，能说出「rustup 与 cargo 的分工是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「Rust 基础」示例中，下面这行代码缺少哪个关键字或函数名？请填入 …」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Rust Basics

**Summary:** Ownership, borrowing, Result and thread safety.

**Category:** Rust  
**Level:** 基础  
**Key terms:** Rust, 所有权, 借用, 生命周期, Cargo

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：基础
- 适用环境：Rust 1.85+ / Cargo
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、所有权、借用、生命周期、Cargo
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## Full English Study Guide

### Overview

**Rust Basics** focuses on Ownership, borrowing, Result and thread safety.

### Learning Outcomes

- Explain what **Rust Basics** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Rust Basics**
- Related terms: Rust, 所有权, 借用, 生命周期
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning Objectives |
| 前置知识 | Pre-knowledge |
| 语言定位 | Language targeting |
| 所有权：核心中的核心 | Ownership: Core in Core |
| 类型系统 | Type System |
| 并发安全 | Concurrent security |
| 工程实践 | Engineering Practice |
| 学习曲线提示 | Learning Curve Tips |
| 本课小结 | Lesson Summary |
| 基础语法速查 | Basic Grammar Quick Lookup |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [The Rust Book](https://doc.rust-lang.org/book/) | 所有权、类型与工程实践 |
| [Rust 标准库](https://doc.rust-lang.org/std/) | 标准库与并发 API |

> 本课主题：所有权、借用检查、Result 与并发安全。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

