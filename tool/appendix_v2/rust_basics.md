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
