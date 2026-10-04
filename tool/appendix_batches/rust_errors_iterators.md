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
