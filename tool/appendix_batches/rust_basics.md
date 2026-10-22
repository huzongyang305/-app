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
