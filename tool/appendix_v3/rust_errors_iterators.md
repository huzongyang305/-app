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
