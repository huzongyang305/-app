## 所有权与借用速查

| 概念 | 规则 | 示例 |
| --- | --- | --- |
| 所有权 | 每个值有唯一所有者，所有者离开作用域即释放 | `let s = String::from("a");` |
| 移动 | 赋值或传参后原变量失效 | `let t = s;` 之后 `s` 不可用 |
| 复制 | 实现 `Copy` 的类型按位复制 | `let y = x;` 后 `x` 仍可用 |
| 不可变借用 | 可以同时存在多个 | `let a = &s; let b = &s;` |
| 可变借用 | 同一时刻只能有一个，且不能与不可变借用共存 | `let m = &mut s;` |
| 生命周期 | 标注借用关系，保证引用不悬空 | `fn f<'a>(x: &'a str) -> &'a str` |
| 切片 | 借用容器的一部分 | `&v[1..3]` |

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

fn main() {
    let mut data = String::from("hello");

    {
        let r1 = &data;              // 不可变借用
        let r2 = &data;              // 可以同时有多个
        println!("{r1} {r2}");
    }                                // 借用在这里结束

    data.push_str(" world");         // 现在可以可变借用

    let s = String::from("abc");
    let t = s;                       // 所有权移动
    // println!("{s}");              // 编译错误：s 已被移动
    println!("{t}");
}
```

## 常见错误对照表

| 编译错误 | 含义 | 处理方式 |
| --- | --- | --- |
| `borrow of moved value` | 值被移动后又使用 | 改成借用（`&x`）或 `clone()`，或调整生命周期 |
| `cannot borrow as mutable, as it is also borrowed as immutable` | 可变与不可变借用冲突 | 缩短借用作用域，或先结束不可变借用 |
| `cannot borrow as mutable more than once` | 同时存在两个可变借用 | 用作用域分隔，或用 `RefCell` / `Mutex` |
| `missing lifetime specifier` | 编译器无法推断返回引用与哪个入参相关 | 显式标注生命周期 |
| `does not live long enough` | 引用的对象提前销毁 | 交出所有权、延长作用域或用 `Arc` |
| `cannot move out of borrowed content` | 试图从借用中移出值 | 用 `clone()`，或用 `mem::take` / `Option` 取出 |
| `value borrowed here after move` | 在移动之后又使用 | 提前 `clone` 或改为传引用 |
| `cannot assign twice to immutable variable` | 未声明 `mut` | 加 `mut` 或改成重新绑定 |

## 何时选择什么

| 需求 | 选择 |
| --- | --- |
| 只读访问字符串参数 | `&str` |
| 需要拥有并修改字符串 | `String` |
| 只读访问序列 | `&[T]` |
| 需要拥有、可增长 | `Vec<T>` |
| 共享不可变数据 | `&T` 或 `Arc<T>`（跨线程） |
| 需要内部可变性 | `Cell` / `RefCell`（单线程）、`Mutex` / `RwLock`（多线程） |
| 可能没有值 | `Option<T>` |
| 可能失败 | `Result<T, E>` |

## 自测清单

- [ ] 能说清「移动」与「复制」的区别，并知道哪些类型实现 `Copy`。
- [ ] 记得同一作用域内「可变借用独占」的规则。
- [ ] 会用作用域收缩解决借用冲突，而不是无脑 `clone`。
- [ ] 能读懂 `does not live long enough` 并定位生命周期问题。
- [ ] 需要跨线程共享时使用 `Arc<Mutex<T>>`。
