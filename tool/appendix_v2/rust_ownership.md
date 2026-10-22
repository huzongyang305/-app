## 零基础详解：所有权，用「借书」理解 Rust 最核心的规则

### 一句话说清它是什么

所有权是 Rust 管理内存的方式：**每个值有且只有一个所有者**，
所有者离开作用域，值就被自动释放。这样既不需要垃圾回收，也不会内存泄漏。

### 三条规则（背下来就够用）

1. Rust 中每个值都有一个**所有者**变量。
2. 同一时刻**只能有一个所有者**。
3. 所有者离开作用域时，值被自动丢弃（`drop`）。

### 用「借书」理解移动与克隆

| 操作 | 比喻 | 代码 | 之后原变量还能用吗 |
| --- | --- | --- | --- |
| 移动 move | 把书送给别人 | `let b = a;` | 不能 |
| 克隆 clone | 复印一本给对方 | `let b = a.clone();` | 能 |
| 复制 copy | 给对方一张便签（栈上小数据） | `let b = n;`（i32） | 能 |
| 借用 borrow | 借出去看，不转让 | `let b = &a;` | 能 |
| 可变借用 | 借出去改，且一次只能一个人改 | `let b = &mut a;` | 借用期间不能再用 a |

```rust
let s1 = String::from("hello");
let s2 = s1;                    // 所有权移动，s1 失效
// println!("{s1}");            // 编译错误：value borrowed here after move

let s3 = s2.clone();            // 深拷贝，两边都能用
println!("{s2} {s3}");

let n1 = 5;
let n2 = n1;                    // i32 实现了 Copy，n1 仍可用
println!("{n1} {n2}");
```

### 借用规则：一条让人又爱又恨的规则

**在任意时刻，对同一个值只能满足下面之一：**

- 任意多个**不可变借用** `&T`，或
- 恰好一个**可变借用** `&mut T`。

```rust
let mut data = vec![1, 2, 3];

let a = &data;        // 不可变借用
let b = &data;        // 再来一个也可以
println!("{a:?} {b:?}");   // 最后一次使用后，a、b 的借用结束

let c = &mut data;    // 现在可以可变借用了
c.push(4);
println!("{c:?}");
```

这就是为什么 Rust 能**在编译期消灭数据竞争**：读写不能同时发生。

### 引用与解引用

```rust
fn length(s: &str) -> usize { s.len() }        // 借用，不夺走所有权

fn add_one(n: &mut i32) { *n += 1; }           // * 解引用后修改

let mut x = 1;
add_one(&mut x);
println!("{x}");                                // 2
```

函数参数用 `&T` 而不是 `T`，可以避免调用处失去所有权。

### 生命周期的直觉理解

```rust
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}
```

`'a` 的意思是：**返回的引用活得不能比两个输入更久**。
初学阶段只需记住：返回引用时，它必须来自参数，而不是函数内部创建的临时值。

### 新手最容易踩的七个坑

| 坑 | 报错关键词 | 正确做法 |
| --- | --- | --- |
| 移动后继续用 | `borrow of moved value` | 用 `clone()`，或改成借用 |
| 借用期间修改 | `cannot borrow as mutable` | 先结束借用，再修改 |
| 同时存在可变与不可变借用 | `cannot borrow ... more than once` | 缩短借用作用域 |
| 返回局部变量的引用 | `does not live long enough` | 返回所有权（`String`）而不是 `&str` |
| 循环里 `&mut` 冲突 | `already borrowed` | 用下标访问、拆分借用或收集索引 |
| 结构体持有引用 | 缺少生命周期参数 | 加生命周期标注或改持有所有权 |
| 到处 `clone` | 编译过了但性能差 | 先想清楚能否借用 |

### 手把手练习：安全的字符串处理

```rust
fn first_word(s: &str) -> &str {
    match s.find(' ') {
        Some(i) => &s[..i],
        None => s,
    }
}

fn append_excited(mut s: String) -> String {
    s.push('!');
    s
}

fn main() {
    let text = String::from("hello rust world");
    println!("第一个词：{}", first_word(&text));   // 只借用，text 还在

    let owned = text;                              // 移动给 owned
    let owned = append_excited(owned);             // 传进去再返回
    println!("{owned}");
}
```

### 学完自测

- [ ] 能默写所有权的三条规则。
- [ ] 能解释移动、克隆、复制三者的差别。
- [ ] 能说出借用规则的两句话。
- [ ] 知道为什么 `i32` 赋值后原变量还能用，而 `String` 不行。
- [ ] 能把一个「移动后继续用」的错误改成借用或克隆。
