## 零基础详解：结构体、枚举与 trait

### 一句话说清它是什么

`struct` 把相关数据组合起来，`enum` 表达「几种可能之一」，`trait` 定义「共有的能力」。
三者配合 `match` 与 `Option`，让 Rust 把「忘记处理某种情况」变成编译错误。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| `struct` | 一张信息卡 | 各字段都同时存在 |
| `enum` | 单选题 | 同一时刻只能是其中一个选项 |
| `trait` | 岗位能力要求 | 谁实现了这些方法就有这项能力 |
| `impl` | 给类型装能力 | 实现方法或 trait |
| `match` | 分类处理窗口 | 必须覆盖所有情况 |

### 结构体与枚举

```rust
#[derive(Debug, Clone, PartialEq)]
struct User {
    id: u64,
    name: String,
    email: Option<String>,       // 可能没有邮箱
}

#[derive(Debug)]
enum Shape {
    Circle { radius: f64 },
    Square { side: f64 },
    Triangle { base: f64, height: f64 },
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
            Shape::Square { side } => side * side,
            Shape::Triangle { base, height } => base * height / 2.0,
        }
    }
}
```

`match` 少写一个分支编译器就会报错——这是 Rust 最值钱的安全网之一。

### `Option` 与 `Result`

```rust
fn find_user(id: u64) -> Option<User> {
    if id == 0 {
        None
    } else {
        Some(User { id, name: "小明".into(), email: None })
    }
}

fn parse_age(text: &str) -> Result<u8, String> {
    text.trim()
        .parse::<u8>()
        .map_err(|_| format!("不是合法年龄：{text}"))
}

// 用 ? 传播错误，比层层 match 干净得多
fn load(text: &str) -> Result<u8, String> {
    let age = parse_age(text)?;
    Ok(age)
}
```

| 类型 | 含义 | 用法 |
| --- | --- | --- |
| `Option<T>` | 有或无 | `Some(x)` / `None` |
| `Result<T, E>` | 成功或失败 | `Ok(x)` / `Err(e)` |
| `?` | 出错就提前返回 | 只能在返回 Result 或 Option 的函数里用 |

### trait：能力约定与实际使用

```rust
trait Summary {
    fn summarize(&self) -> String;

    fn preview(&self) -> String {            // 默认实现，可以不写
        format!("{}…", &self.summarize()[..10])
    }
}

impl Summary for User {
    fn summarize(&self) -> String {
        format!("{}（{}）", self.name, self.id)
    }
}

fn print_summary(item: &impl Summary) {      // 静态分发：编译期确定
    println!("{}", item.summarize());
}

fn print_dyn(item: &dyn Summary) {           // 动态分发：运行时确定
    println!("{}", item.preview());
}
```

| 写法 | 分发方式 | 适用场景 |
| --- | --- | --- |
| `impl Trait` 或泛型 `T: Trait` | 静态 | 追求性能，类型在编译期确定 |
| `dyn Trait` | 动态 | 需要把不同类型放进同一个容器 |

### 常用派生宏

| 派生 | 得到什么 |
| --- | --- |
| `Debug` | 可用 `{:?}` 打印 |
| `Clone` | 可调用 `.clone()` |
| `Copy` | 赋值时不移动（仅限简单类型） |
| `PartialEq` / `Eq` | 可用 `==` 比较 |
| `Default` | 可调用 `Default::default()` |
| `Hash` | 可作为 HashMap 的键 |

### 新手最容易踩的八个坑

| 坑 | 报错关键词 | 正确做法 |
| --- | --- | --- |
| `match` 漏分支 | non-exhaustive patterns | 补齐或用 `_ =>` |
| 对 `Option` 直接取值 | 类型不匹配 | 用 `unwrap_or`、`?` 或 `match` |
| 到处 `unwrap()` | 运行时 panic | 用 `?`、`unwrap_or_else` 处理 |
| 忘记 `#[derive(Debug)]` | 无法打印 | 加上派生宏 |
| trait 方法签名不一致 | does not match trait | 保证参数与返回类型一致 |
| 把 `String` 当 `&str` | 期望引用但给了值 | 传 `&s` 或改签名 |
| 结构体字段默认私有 | 其它模块访问不到 | 需要公开就加 `pub` |
| `dyn` 忘了引用 | 编译期大小未知 | 用 `&dyn Trait` 或 `Box<dyn Trait>` |

### 手把手练习：形状面积与错误处理

```rust
use std::fmt;

#[derive(Debug)]
enum ShapeError {
    Negative(f64),
    Unknown,
}

impl fmt::Display for ShapeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ShapeError::Negative(v) => write!(f, "边长不能为负：{v}"),
            ShapeError::Unknown => write!(f, "未知形状"),
        }
    }
}

fn area(kind: &str, a: f64) -> Result<f64, ShapeError> {
    if a < 0.0 {
        return Err(ShapeError::Negative(a));
    }
    match kind {
        "square" => Ok(a * a),
        "circle" => Ok(std::f64::consts::PI * a * a),
        _ => Err(ShapeError::Unknown),
    }
}

fn main() {
    for (kind, a) in [("square", 3.0), ("circle", 2.0), ("blob", 1.0)] {
        match area(kind, a) {
            Ok(v) => println!("{kind} 面积 {v:.2}"),
            Err(e) => println!("{kind} 出错：{e}"),
        }
    }
}
```

### 学完自测

- [ ] 能说出 struct 与 enum 的区别。
- [ ] 能解释 `Option` 与 `Result` 各自解决什么问题。
- [ ] 知道 `?` 运算符的作用与使用前提。
- [ ] 能说出静态分发与动态分发的差别。
- [ ] 能列出至少四个常用派生宏。
