## Option 与 Result 速查

| 目的 | 写法 |
| --- | --- |
| 可能没有值 | `Option<T>`：`Some(v)` / `None` |
| 可能失败 | `Result<T, E>`：`Ok(v)` / `Err(e)` |
| 提供默认值 | `opt.unwrap_or(default)` / `unwrap_or_default()` |
| 延迟计算默认值 | `opt.unwrap_or_else(|| compute())` |
| 转换并保留失败 | `opt.ok_or(MyError::Missing)?` |
| 链式处理 | `opt.map(f).and_then(g)` |
| 过滤 | `opt.filter(|v| v.is_valid())` |
| 提前返回错误 | `let v = result?;` |
| 打印调试信息 | `expect("上下文")` 比 `unwrap()` 更有信息量 |
| 组合多个 Option | `match (a, b) { (Some(x), Some(y)) => ... , _ => ... }` |

```rust
use std::num::ParseIntError;

#[derive(Debug)]
enum ConfigError {
    Missing(&'static str),
    Invalid { key: &'static str, source: ParseIntError },
}

fn read_port(map: &std::collections::HashMap<String, String>) -> Result<u16, ConfigError> {
    let raw = map.get("port").ok_or(ConfigError::Missing("port"))?;
    raw.parse::<u16>().map_err(|source| ConfigError::Invalid {
        key: "port",
        source,
    })
}
```

## trait 速查

| 概念 | 说明 |
| --- | --- |
| 定义 | `trait Summary { fn summary(&self) -> String; }` |
| 默认实现 | trait 内提供方法体，实现者可不重写 |
| 实现 | `impl Summary for Article { ... }` |
| 泛型约束 | `fn f<T: Summary>(x: T)` |
| 动态分发 | `Box<dyn Summary>`，运行时确定实现 |
| 静态分发 | 泛型单态化，无运行时开销但代码膨胀 |
| 派生宏 | `#[derive(Debug, Clone, PartialEq)]` |
| 常用标准 trait | `Debug`、`Clone`、`Copy`、`PartialEq`、`Default`、`From`/`Into` |
| 孤儿规则 | trait 或类型至少有一个属于当前 crate |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `opt.unwrap()` 用在可能为空的路径 | 运行时 panic | 用 `?`、`unwrap_or` 或 `match` |
| `?` 用在返回类型不匹配的函数 | 编译错误 | 返回类型必须是 `Result` / `Option` |
| 到处 `Box<dyn Trait>` | 运行时间接调用与分配 | 性能敏感处用泛型 |
| 泛型一层套一层 | 编译时间与体积暴涨 | 非热点用 `dyn` |
| 忘记 `#[derive(Debug)]` | 无法 `{:?}` 打印 | 派生或手写 `Debug` |
| 为外部类型实现外部 trait | 编译错误（孤儿规则） | 用 newtype 包装 |
| `Copy` 与 `Clone` 混用 | 移动语义不符合预期 | 只有平凡复制语义的类型才 `Copy` |
| 用 `PartialEq` 比较浮点 | 结果不稳定 | 用误差比较 |
| 忘记处理 `None` 分支 | 编译错误（穷尽匹配） | 补分支或用组合子 |
| 把一个巨大的 `Result` 到处传递 | 类型签名冗长 | 用 `anyhow`（应用层）或自定义错误枚举 |

## 自测清单

- [ ] 用 `Option` 表达可能缺失，`Result` 表达可能失败。
- [ ] 优先用 `?` 与组合子，避免 `unwrap()`。
- [ ] 能说出泛型与 `dyn` 的取舍。
- [ ] 会用 `#[derive]` 减少样板代码。
- [ ] 了解孤儿规则并用 newtype 规避。
