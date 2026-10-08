# Rust 错误处理、迭代器与异步

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：35 分钟

![错误处理、迭代器与异步的配合](images/diagram_rust_errors_iterators.webp)

![Rust 错误处理、迭代器与异步](images/remaining_rust_errors_iterators.webp)

## 学习目标

- 能用自己的话解释Rust 错误处理、迭代器与异步解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「thiserror」、「anyhow」、「迭代器」 之间的关系，并分别举出一个例子。
- 能把 Rust 放回「Rust 错误处理、迭代器与异步」的知识体系，说明它和 thiserror 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：thiserror/anyhow、零开销迭代器与 tokio 异步要点。

## 前置知识

- 先完成上一课《Rust 并发与 Cargo 工程》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「Rust 并发与 Cargo 工程」，或确认自己能独立跑通正文里的 ParseIntError 示例。
- 开始前先复习：Rust、thiserror、anyhow。
- 如果 错误处理分层 这一步看不懂，先记录具体卡点，再用 ParseIntError 复现一遍。

## 错误处理分层

| 场景 | 推荐 |
| --- | --- |
| 库代码 | 自定义错误类型（thiserror），让调用方可判定 |
| 应用代码 | anyhow::Result 简化传播，`?` 一路向上 |
| 可恢复错误 | Result；不可恢复才 panic |

关键是**保留错误上下文**（`.context("加载配置失败")?`），同时避免把内部实现细节泄露成公开 API。

## 迭代器：零开销抽象

Rust 迭代器是惰性的，链式调用会被编译优化成普通循环，没有额外开销。常用组合：`map`/`filter`/`filter_map`/`fold`/`collect`/`enumerate`/`zip`/`flat_map`/`take_while`。

经验：能用迭代器表达就别写手写循环；`collect::<Result<Vec<_>, _>>()` 可以把一组 Result 收敛成 Result<Vec>，错误处理非常优雅。

## 宏

声明式宏 `macro_rules!` 做模式匹配式代码生成；过程宏（derive/attribute/function-like）由 proc-macro crate 实现，`#[derive(Debug)]` 就是过程宏。宏强大但会降低可读性，优先用函数与泛型，宏用于消除模板化重复。

## 异步与 tokio

`async fn` 返回 Future，需要运行时驱动（tokio 最常用）。要点：

1. Future 是惰性的，必须 await 或 spawn 才会推进。
2. 不要阻塞异步运行时：CPU 密集或同步 IO 用 `spawn_blocking`。
3. 并发用 `tokio::join!`、`try_join!`、`FuturesUnordered`；`select!` 做竞速与超时。
4. 取消是安全的（drop 掉 Future 即取消），但要注意资源清理与副作用。

## 本课小结

Rust 的工程三件套：**分层的错误处理、零开销迭代器、以 tokio 为核心的异步并发**。

## 错误处理策略速查

| 场景 | 推荐做法 |
| --- | --- |
| 库对外 API | 自定义 `thiserror` 枚举错误，类型精确、可匹配 |
| 应用 / 二进制 | `anyhow::Result<T>`，快速传播并附加上下文 |
| 需要上下文 | `.context("读取配置失败")?`（anyhow） |
| 需要错误链 | `#[source]`（thiserror）/ `anyhow::Error` 的链式打印 |
| 一次性错误 | `Err(MyError::Empty)?` |
| 明确不可恢复 | `panic!` / `expect`，仅用于程序缺陷 |

```rust
use thiserror::Error;

#[derive(Debug, Error)]
enum StoreError {
    #[error("键 {0} 不存在")]
    Missing(String),

    #[error("解析失败")]
    Parse(#[from] std::num::ParseIntError),
}

// 使用 ? 自动把 ParseIntError 转成 StoreError
fn load(map: &std::collections::HashMap<String, String>, key: &str) -> Result<u32, StoreError> {
    let raw = map.get(key).ok_or_else(|| StoreError::Missing(key.to_string()))?;
    Ok(raw.parse::<u32>()?)
}
```

## 迭代器速查

| 适配器 | 作用 | 是否惰性 |
| --- | --- | --- |
| `map` | 转换每个元素 | 是 |
| `filter` | 过滤 | 是 |
| `filter_map` | 过滤并转换（返回 `Option`） | 是 |
| `flat_map` | 展平 | 是 |
| `take` / `skip` | 取前 n / 跳过 n | 是 |
| `chain` | 串联两个迭代器 | 是 |
| `zip` | 成对组合 | 是 |
| `enumerate` | 带下标 | 是 |
| `peekable` | 可预看下一个 | 是 |
| `collect` | 收集成集合 | 否（消费） |
| `fold` / `reduce` | 归约 | 否 |
| `sum` / `product` | 求和 / 求积 | 否 |
| `any` / `all` | 条件判断（短路） | 否 |
| `find` / `position` | 查找 | 否 |
| `min` / `max` / `min_by_key` | 最值 | 否 |
| `count` | 计数 | 否 |

```rust
// 迭代器链：过滤、映射、求和一次完成，无额外中间集合
let total: u32 = orders
    .iter()
    .filter(|o| o.paid)
    .map(|o| o.amount)
    .sum();

// 收集为 Result：遇到第一个 Err 就提前返回
let numbers: Result<Vec<i32>, _> = inputs
    .iter()
    .map(|s| s.parse::<i32>())
    .collect();
```

## 常见错误与排查

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 迭代器不调用消费方法 | 什么都不执行 | 加 `collect` / `for` / `sum` |
| 在热点路径反复 `collect` | 多余分配 | 保持迭代器链，最后再收集 |
| `unwrap()` 处理外部输入 | 运行时 panic | 用 `?` 或匹配处理 |
| 只用 `Box<dyn Error>` 丢类型 | 无法针对错误分支处理 | 库中用自定义枚举错误 |
| 错误信息缺少上下文 | 线上无法定位 | `context("读取 xx 文件")` |
| `?` 在 `main` 中直接使用 | 编译错误（返回类型不符） | `main` 返回 `Result<(), E>` 或显式处理 |
| `filter_map` 里吞掉错误 | 失败被静默忽略 | 需要错误时用 `map` 收集 `Result` |
| 索引遍历代替迭代器 | 可能越界、可读性差 | 用迭代器组合子 |
| 忘记 `iter()` 与 `into_iter()` 区别 | 所有权被移动或类型不符 | `&v` 借用迭代，`v` 消耗迭代 |
| 在循环里 `clone()` 大对象 | 性能下降 | 传引用或调整所有权 |

## 复习与自测

- [ ] 库用 `thiserror`，应用用 `anyhow`，并能说明理由。
- [ ] 错误传播时补充上下文信息。
- [ ] 迭代器链保持惰性，最后一步才 `collect`。
- [ ] 用 `collect::<Result<Vec<_>, _>>()` 处理批量解析。
- [ ] 外部输入绝不 `unwrap()`。

## 零基础详解：错误处理与迭代器

### 一句话说清它是什么

Rust 把错误分成两类：**可恢复的用 `Result`**，**不可恢复的用 `panic!`**。
迭代器则是「惰性流水线」：`map`、`filter` 只是搭好管道，真正计算发生在 `collect` 或 `for` 的时候。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| `Result<T, E>` | 快递单 | 要么签收成功，要么写明失败原因 |
| `panic!` | 拉闸 | 程序缺陷，直接终止 |
| `?` | 遇到问题就上交 | 自动把错误往上传递 |
| 迭代器 | 流水线 | 每个工位处理一道工序 |
| 惰性求值 | 订单确认后才开工 | 不调用 collect 就不计算 |

### 错误处理的四个层次

```rust
use std::num::ParseIntError;

// 1. 直接传播：最常用
fn parse_port(text: &str) -> Result<u16, ParseIntError> {
    text.trim().parse::<u16>()
}

// 2. 转换错误类型，让调用方只面对一种错误
fn parse_port_ctx(text: &str) -> Result<u16, String> {
    text.trim()
        .parse::<u16>()
        .map_err(|e| format!("端口不合法 {text}: {e}"))
}

// 3. 自定义错误类型，配合 thiserror 更省事
#[derive(Debug)]
enum ConfigError {
    Missing(String),
    Invalid { key: String, reason: String },
}

// 4. main 里允许返回 Result，出错会自动打印
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let port = parse_port("8080")?;
    println!("端口 {port}");
    Ok(())
}
```

### `Option` 与 `Result` 的常用方法

| 方法 | 作用 | 例子 |
| --- | --- | --- |
| `unwrap_or` | 取不到就给默认值 | `x.unwrap_or(0)` |
| `unwrap_or_else` | 默认值需要计算 | `x.unwrap_or_else(默认函数)` |
| `map` | 有值就变换 | `opt.map(\|v\| v * 2)` |
| `and_then` | 继续返回 Option 的操作 | `opt.and_then(find_next)` |
| `ok_or` | Option 转 Result | `opt.ok_or("缺失")?` |
| `is_ok` / `is_err` | 判断成功或失败 | 日志分支 |

### 迭代器流水线

```rust
let nums = vec![1, 2, 3, 4, 5, 6];
let result: i32 = nums
    .iter()                        // 借用遍历，不消费 vec
    .filter(|&&n| n % 2 == 0)      // 只留偶数
    .map(|&n| n * n)               // 平方
    .sum();                        // 求和
println!("{result}");              // 4 + 16 + 36 = 56
```

| 方法 | 作用 | 是否惰性 |
| --- | --- | --- |
| `map` / `filter` / `take` | 变换与筛选 | 是 |
| `collect` | 收集成集合 | 否，触发计算 |
| `sum` / `count` / `max` | 聚合 | 否 |
| `find` / `position` | 查找 | 否 |
| `chain` / `zip` | 组合两个迭代器 | 是 |
| `fold` | 自定义聚合 | 否 |

### `iter`、`iter_mut`、`into_iter` 的区别

| 写法 | 拿到什么 | 原集合还能用吗 |
| --- | --- | --- |
| `.iter()` | `&T` 不可变引用 | 能 |
| `.iter_mut()` | `&mut T` 可变引用 | 借出期间不能 |
| `.into_iter()` | `T` 所有权 | 不能（被消费） |

### 新手最容易踩的八个坑

| 坑 | 报错关键词 | 正确做法 |
| --- | --- | --- |
| 到处 `unwrap()` | 运行时 panic | 用 `?` 或 `unwrap_or` |
| 忘了 `?` 的使用前提 | 问号运算符报错 | 函数返回类型改成 Result |
| 迭代器没触发计算 | 什么也没发生 | 加 `collect` 或 `for` |
| 混用 `iter` 与 `into_iter` | 所有权被移动 | 需要保留原集合就用 `iter` |
| `collect` 不写目标类型 | 类型无法推断 | 写 `let v: Vec<_> = ...` |
| 闭包里重复借用 | 借用冲突 | 缩短借用范围或用 `iter_mut` |
| 用索引遍历 | 容易越界且不优雅 | 用迭代器方法 |
| 忘处理 `Err` 分支 | 逻辑静默跳过 | 用 `match` 或 `if let` |

### 手把手练习：读取并解析一列数字

```rust
fn parse_all(input: &str) -> Result<Vec<i32>, String> {
    input
        .lines()
        .filter(|l| !l.trim().is_empty())
        .map(|l| {
            l.trim()
                .parse::<i32>()
                .map_err(|e| format!("无法解析 {l:?}: {e}"))
        })
        .collect()                     // 把 Vec<Result<..>> 收成 Result<Vec<..>>
}

fn main() {
    let text = "10\n20\nabc\n40";
    match parse_all(text) {
        Ok(nums) => {
            let sum: i32 = nums.iter().sum();
            let max = nums.iter().max().copied().unwrap_or(0);
            println!("{} 个数，和 {sum}，最大 {max}", nums.len());
        }
        Err(e) => println!("解析失败：{e}"),
    }
}
```

`collect` 能把 `Vec<Result<T, E>>` 直接收成 `Result<Vec<T>, E>`，这是 Rust 里非常常用的技巧。

### 学完自测

- [ ] 能说出什么时候用 `Result`、什么时候用 `panic!`。
- [ ] 知道 `?` 的使用前提。
- [ ] 能解释迭代器「惰性」是什么意思。
- [ ] 能说出 `iter`、`iter_mut`、`into_iter` 的区别。
- [ ] 会用 `collect` 把一批 `Result` 合成一个 `Result`。

## 动手练习

> 本课练习重点：围绕「Rust、thiserror、anyhow」完成复述、实验和交付，每个结果都要能被别人检查。

围绕 Rust 写一个最小示例，先用 ParseIntError 跑通，再补一个边界输入。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. Rust 错误处理、迭代器与异步解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「thiserror」是什么关系？

验收标准：说明 Rust 与 thiserror 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「错误处理分层」里找一个可运行的最小输入，再按五步法记录Rust的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

围绕 Rust 写一个最小示例，先用 ParseIntError 跑通，再补一个边界输入。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「Rust」和「thiserror」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

本节围绕Rust 错误处理、迭代器与异步安排 3 个可交付任务，每个任务都要求留下可以复查的记录。

### 任务 1：用自己的话画出结构

不看书，用一张图说清「Rust 错误处理、迭代器与异步」的结构，画完再对照骨架：

- 主干：错误处理分层 → 迭代器：零开销抽象 → 宏 → 异步与 tokio
- 连接线：在每条边上标出输入、输出与失败路径。
- 自检：能否用一句话说明Rust与thiserror的关系？

### 任务 2：做一次对比实验

**验收标准**：两个方案至少在一个输入上给出不同结果；把差异归因到Rust，而不是笼统地写「性能更好」。

### 任务 3：迁移到自己的场景

**验收标准**：结论要能追溯到「错误处理分层」的具体段落，并说明它和 thiserror 的边界。

## 故障现场

### 现场 1：迭代器不调用消费方法

**症状**：在《Rust 错误处理、迭代器与异步》的复现场景中，什么都不执行。

**根因**：触发点是把“迭代器不调用消费方法”当成安全做法。它没有满足《Rust 错误处理、迭代器与异步》要求的前提，因此先表现为“什么都不执行”；排查时先完整复现这一段，再核对输入、配置与依赖。

**修复**：针对《Rust 错误处理、迭代器与异步》的问题，加 collect / for / sum。

**验证**：保留《Rust 错误处理、迭代器与异步》里触发“什么都不执行”的输入、版本和日志，按“加 collect / for / sum”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：unwrap() 处理外部输入

**症状**：在《Rust 错误处理、迭代器与异步》的复现场景中，运行时 panic。

**根因**：“运行时 panic”只是表层结果。向上追溯会落到“unwrap() 处理外部输入”这一步，因为它省略了《Rust 错误处理、迭代器与异步》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《Rust 错误处理、迭代器与异步》的问题，用 ? 或匹配处理。

**验证**：保留《Rust 错误处理、迭代器与异步》里触发“运行时 panic”的输入、版本和日志，按“用 ? 或匹配处理”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 3：只用 Box<dyn Error> 丢类型

**症状**：在《Rust 错误处理、迭代器与异步》的复现场景中，无法针对错误分支处理。

**根因**：当出现“只用 Box<dyn Error> 丢类型”时，执行路径已经绕过了《Rust 错误处理、迭代器与异步》的关键约束，最终以“无法针对错误分支处理”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《Rust 错误处理、迭代器与异步》的问题，库中用自定义枚举错误。

**验证**：保留《Rust 错误处理、迭代器与异步》里触发“无法针对错误分支处理”的输入、版本和日志，按“库中用自定义枚举错误”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 版本与时效

- 版本提示：Rust 的行为在最近几个大版本里有过调整，升级「Rust 错误处理、迭代器与异步」前先用 ParseIntError 复现当前输出，再对照官方发布说明逐条核对。
- 异步运行时与借用检查规则的变化会影响 Rust，要在 CI 中提前暴露。
- 升级「Rust 错误处理、迭代器与异步」涉及的依赖前，先用 ParseIntError 复现当前行为，再逐项核对版本说明与破坏性变更。
- 官方发布说明：https://blog.rust-lang.org/

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 Rust 相关的差异单独记成一条结论。
- 回归范围锁定 ParseIntError 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后记录 Rust 的新旧版本差异，并据此调整下次复核时间。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「库代码与应用代码的错误处理，推荐组合是？」的判断依据。
- [ ] 不看解析，能说出「Rust 迭代器链会有运行时开销吗？」的判断依据。
- [ ] 不看解析，能说出「在异步运行时中执行 CPU 密集任务应该？」的判断依据。
- [ ] 不看解析，能说出「Rust 迭代器是「惰性」的，这意味着？」的判断依据。
- [ ] 不看解析，能说出「collect::<Result<Vec<_>, _>>() 的作用是？」的判断依据。
- [ ] 用 Rust 构造一个正常输入和一个边界输入，分别记录输出与判断依据。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把「Rust 错误处理、迭代器与异步」里反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 一句话说明 |
| --- | --- |
| `Rust` | collect 能把 Vec<Result<T, E>> 直接收成 Result<Vec<T>, E>，这是 Rust 里非常常用的技巧。 |
| `thiserror` | 用派生宏为枚举生成 Error 实现，适合给库定义结构化的错误类型。 |
| `anyhow` | 面向应用的错误库：用 anyhow::Result 加错误上下文快速传播错误，适合二进制程序而非库。 |
| `迭代器适配器` | map、filter、collect 等惰性组合子，只在被消费时才真正执行，不产生中间集合。 |
| `迭代器` | iter()、into_iter() 配合 map、filter 完成声明式遍历 |
| `tokio` | Rust 的异步运行时，提供任务调度、异步 I/O、定时器和同步原语 |

## 考点精讲

### 考点 1：多选辨析·Rust

- **题目**：围绕“Rust 错误处理、迭代器与异步”中的 Rust、thiserror、anyhow，下列哪两项是本课强调的实践判断？
- **判断依据**：在「Rust 错误处理、迭代器与异步」里，学习 Rust 时要同时说明输入、输出和失败路径，不能只看正常流程。在Rust 错误处理、迭代器与异步里，判断 thiserror 时要固定版本与边界输入，所以“验证 thiserror 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 2：概念判断·Rust

- **题目**：Rust 迭代器链会有运行时开销吗？
- **判断依据**：迭代器是零开销抽象，编译后与手写循环等价。在「Rust 错误处理、迭代器与异步」里，作答时，先用Rust建立输入与输出的基线，再把基本没有，会被优化成普通循环代入边界条件核对，结论才能复现。在「Rust 错误处理、迭代器与异步」里判断这道题，要把Rust、thiserror、anyhow的条件、过程与失败路径逐项对齐，换成“Rust 迭代器链会有运行时开销吗”这个场景，只有满足前提的结论才成立。

### 考点 3：代码补全·Rust

- **题目**：阅读「Rust 错误处理、迭代器与异步」正文里的这段 Rust 代码，下面哪一项判断是正确的？
- **判断依据**：在「Rust 错误处理、迭代器与异步」里，这段代码只做静态声明，没有循环、分支或可观察输出。这段代码出自「Rust 错误处理、迭代器与异步」的正文示例，围绕Rust、thiserror、anyhow展开；把输入或边界换成空值、极值或失败情况后，结论要以「Rust 错误处理、迭代器与异步」的实际运行结果为准。

### 考点 4：概念判断·惰性

- **题目**：Rust 迭代器是「惰性」的，这意味着？
- **判断依据**：在「Rust 错误处理、迭代器与异步」里，结论应落在「不调用消费方法（collect/sum/for）就不会真正执行」。适配器如 map/filter 只是构建新迭代器，零成本抽象正来源于这种惰性组合。在「Rust 错误处理、迭代器与异步」里，这道题要求区分概念与边界，「不调用消费方法（collect/sum/for）就不会真正执行」只有在题干给出的前提下才成立，而「只能遍历一次」、「每次调用都要分配内存，但这会占用更多内存，同时这会引入新的复杂度」缺少同一组条件。

### 考点 5：概念判断·Rust

- **题目**：collect::<Result<Vec<_>, _>> 的作用是？
- **判断依据**：在「Rust 错误处理、迭代器与异步」里，收集成 Result<Vec<_>, _>，遇 Err 短路。这是把「逐个解析可能失败的元素」写成一行的常用技巧。「Rust 错误处理、迭代器与异步」要求先交代Rust、thiserror、anyhow的前提再下结论，所以“把一组 Result 收集成 Resul”只在题干“collect”给定的条件下成立。

### 考点 6：填空·Rust

- **题目**：补全代码：「Rust 错误处理、迭代器与异步」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `let max = nums.iter.max.copied.____(0);`
- **判断依据**：空格应填写「unwrap_or」。同时避免把内部实现细节泄露成公开 API。回到「Rust 错误处理、迭代器与异步」的正文示例，用“补全代码”走一遍Rust、thiserror、anyhow的完整流程，能复现的结论才可以保留。回到Rust、thiserror、anyhow本身再看一遍：只有“unwrapor”与题干“Rust”的前提一致，结论才成立。

## English Overview

**Title:** Errors, Iterators & Async

**Summary:** thiserror/anyhow, iterators and tokio.

**Category:** Rust
**Level:** 进阶
**Key terms:** Rust, thiserror, anyhow, 迭代器, tokio

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：Rust 1.85+ / Cargo；本课聚焦 Rust。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、thiserror、anyhow、迭代器、tokio
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-06-24
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [Rust Async Book](https://rust-lang.github.io/async-book/) | 异步运行时与 Future |
| [Tokio 文档](https://tokio.rs/tokio/tutorial) | 异步运行时与任务 |
| [Clippy 文档](https://doc.rust-lang.org/clippy/) | Lint 与惯用写法 |

> 「Rust 错误处理、迭代器与异步」的链接用于离线阅读后的延伸核对；App 不会自动联网。

