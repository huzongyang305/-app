# Rust 错误处理、迭代器与异步

![Rust 错误处理、迭代器与异步](images/remaining_rust_errors_iterators.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「Rust 错误处理、迭代器与异步」解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「thiserror」、「anyhow」、「迭代器」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Rust」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：thiserror/anyhow、零开销迭代器与 tokio 异步要点。

## 前置知识

- 先完成上一课《Rust 并发与 Cargo 工程》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Rust、thiserror、anyhow。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


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

## 常见错误对照表

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

## 自测清单

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

先让 cargo check 通过，再补所有权、错误和并发边界，最后运行 clippy。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Rust 错误处理、迭代器与异步」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「thiserror」是什么关系？

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
- 至少覆盖「Rust」和「thiserror」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 5 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：库代码与应用代码的错误处理，推荐组合是？

- **正确判断**：库用 thiserror 定义错误类型，应用用 anyhow 简化传播
- **判断依据**：库需要让调用方可判定错误，应用更关注传播与上下文。其他选项：库需要精确错误类型供调用方匹配（thiserror），应用层更关注传播与上下文（anyhow）。全用 panic 或忽略错误都不可取。正确项「库用 thiserror 定义错误类型，应用用 anyhow 简化传播」抓住了题干的核心条件，是经得起边界检验的表述。错误项「都用 panic」把不同概念混在一起，缺少题干限定的前提。错误项「都用 anyhow（混淆了相邻概念，也没有覆盖题干给出的全部条件）」只看到了表面现象，没有解释题干真正考查的机制。把题干「库代码与应用代码的错误处理，推荐组合是？」放回《Rust 错误处理、迭代器与异步》的「thiserror/anyhow、零开销迭代器与 tokio 异步要点」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：Rust 迭代器链会有运行时开销吗？

- **正确判断**：基本没有，会被优化成普通循环
- **判断依据**：迭代器是零开销抽象，编译后与手写循环等价。其他选项：迭代器适配器是零成本抽象，通常会被优化成与手写循环相当的机器码，也不会额外分配堆内存。正确项「基本没有，会被优化成普通循环」抓住了题干的核心条件，是经得起边界检验的表述。错误项「有明显开销」把不同概念混在一起，缺少题干限定的前提。错误项「比手写循环慢 10 倍」与课程给出的定义相冲突，不能回答题目所问。错误项「会分配堆内存」在边界或失败路径上会得出错误结果。把题干「Rust 迭代器链会有运行时开销吗？」放回《Rust 错误处理、迭代器与异步》的「thiserror/anyhow、零开销迭代器与 tokio 异步要点」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 3：在异步运行时中执行 CPU 密集任务应该？

- **正确判断**：用 spawn_blocking 交给阻塞线程池
- **判断依据**：阻塞异步线程会拖慢整个运行时。其他选项：CPU 密集任务会阻塞异步执行器，应交给 spawn_blocking 或专门的线程池。正确项「用 spawn_blocking 交给阻塞线程池」与题干要求一致，是本课知识点的准确定义。错误项「直接 await（仅部分场景成立）」忽略了题目中的限制条件，因此不成立。错误项「提高优先级」把不同概念混在一起，缺少题干限定的前提。错误项「加锁」与课程给出的定义相冲突，不能回答题目所问。把题干「在异步运行时中执行 CPU 密集任务应该？」放回《Rust 错误处理、迭代器与异步》的「thiserror/anyhow、零开销迭代器与 tokio 异步要点」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：Rust 迭代器是「惰性」的，这意味着？

- **正确判断**：不调用消费方法（collect/sum/for）就不会真正执行
- **判断依据**：适配器如 map/filter 只是构建新迭代器，零成本抽象正来源于这种惰性组合。其他选项：迭代器是惰性的：没有 collect、sum、for 等消费方法就不会执行。这也让链式组合几乎没有额外成本。正确项「不调用消费方法（collect/sum/for）就不会真正执行」与题干要求一致，是本课知识点的准确定义。错误项「只能遍历一次」忽略了题目中的限制条件，因此不成立。错误项「每次调用都要分配内存（混淆了相邻概念，不能回答本题）」属于相邻主题的说法，范围与本题要求不一致。错误项「不能链式调用」与课程给出的定义相冲突，不能回答题目所问。把题干「Rust 迭代器是「惰性」的，这意味着？」放回《Rust 错误处理、迭代器与异步》的「thiserror/anyhow、零开销迭代器与 tokio 异步要点」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：collect::<Result<Vec<_>, _>>() 的作用是？

- **正确判断**：把一组 Result 收集成 Result<Vec<_>, _>，遇到 Err 就短路返回错误
- **判断依据**：这是把「逐个解析可能失败的元素」写成一行的常用技巧。其他选项：收集 Result 时遇到第一个 Err 就短路返回，适合逐项解析可能失败的数据。正确项「把一组 Result 收集成 Result<Vec<_>, _>，遇到 Err 就短路返回错误」既符合定义也满足题干限定的场景，因此应当选择。错误项「把 Result 转成字符串（混淆了相邻概念，也没有覆盖题干给出的全部条件，不能作为答案）」把因果关系颠倒了，不能作为正确结论。错误项「忽略所有错误」忽略了题目中的限制条件，因此不成立。错误项「统计成功数量」属于相邻主题的说法，范围与本题要求不一致。把题干「collect::<Result<Vec<_>, _>>() 的作用是？」放回《Rust 错误处理、迭代器与异步》的「thiserror/anyhow、零开销迭代器与 tokio 异步要点」语境，逐项对照定义与边界条件，就能排除其余说法。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「库代码与应用代码的错误处理，推荐组合是？」的判断依据。
- [ ] 不看解析，能说出「Rust 迭代器链会有运行时开销吗？」的判断依据。
- [ ] 不看解析，能说出「在异步运行时中执行 CPU 密集任务应该？」的判断依据。
- [ ] 不看解析，能说出「Rust 迭代器是「惰性」的，这意味着？」的判断依据。
- [ ] 不看解析，能说出「collect::<Result<Vec<_>, _>>() 的作用是？」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** Errors, Iterators & Async

**Summary:** thiserror/anyhow, iterators and tokio.

**Category:** Rust  
**Level:** 进阶  
**Key terms:** Rust, thiserror, anyhow, 迭代器, tokio

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Rust 1.85+ / Cargo
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、thiserror、anyhow、迭代器、tokio
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [The Rust Book](https://doc.rust-lang.org/book/) | 所有权、类型与工程实践 |
| [Rust 标准库](https://doc.rust-lang.org/std/) | 标准库与并发 API |

> 本课主题：thiserror/anyhow、零开销迭代器与 tokio 异步要点。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

