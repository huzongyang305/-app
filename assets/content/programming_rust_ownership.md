# Rust 所有权、借用与生命周期

![所有权、借用与生命周期的关系](images/diagram_rust_ownership.webp)

![Rust 所有权、借用与生命周期](images/remaining_rust_ownership.webp)

> 内容更新时间：2026-10-03 · 学习阶段：入门 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「Rust 所有权、借用与生命周期」解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「所有权」、「借用」、「生命周期」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Rust」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：Move/Copy、借用规则与生命周期标注。

## 前置知识

- 先完成上一课《Rust 基础》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：入门。只需要基本计算机操作，不要求编程经验。
- 开始前先复习：Rust、所有权、借用。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## 所有权三条规则

1. 每个值有且只有一个所有者。
2. 同一时刻只能有一个所有者。
3. 所有者离开作用域，值被释放（自动调用 Drop）。

因此赋值与传参默认是**移动（Move）**，原变量失效；`Copy` 类型（整数、布尔、字符、仅含 Copy 字段的结构体）按值复制。

## 借用与借用检查

| 形式 | 规则 |
| --- | --- |
| `&T` 不可变借用 | 可同时存在多个 |
| `&mut T` 可变借用 | 同一作用域只能有一个，且不能与不可变借用共存 |
| 生命周期 `'a` | 标注引用的有效范围，保证不出悬垂引用 |

借用检查器把**数据竞争与悬垂指针**消灭在编译期，代价是初学时经常与它"搏斗"。

## 常见解法

1. 需要共享只读：多个 `&T`。
2. 需要修改：缩小可变借用范围，或改成返回值传递。
3. 结构体自引用很麻烦：改用索引（如 `Vec` 下标）或 `Rc<RefCell<T>>`（单线程）/`Arc<Mutex<T>>`（多线程）。
4. 生命周期标注只在编译器需要帮助时写，先写代码再让编译器提示补标注。

## 与 GC 语言的对比

GC 语言在运行时回收，Rust 在编译期决定释放点：**没有停顿、没有额外内存开销**，但要求程序员显式表达所有权关系。这也是 Rust 适合系统编程与高性能服务的原因。

## 常见编译错误与修复

| 错误信息关键词 | 含义 | 修复方式 |
| --- | --- | --- |
| `value borrowed here after move` | 值已被移动，原变量失效 | 用 `.clone()`、改为传引用 `&T`，或调整所有权归属 |
| `cannot borrow as mutable` | 同时存在不可变与可变借用 | 缩小可变借用作用域，或用 `RefCell`/`Mutex` 做运行时检查 |
| `does not live long enough` | 引用的生命周期短于使用处 | 延长数据所有者作用域、返回拥有所有权的值 |
| `cannot move out of ... which is behind a shared reference` | 试图从不可变借用中移出值 | 使用 `Clone`、`std::mem::take` 或改为可变借用 |
| `borrowed value does not live long enough` | 临时值在语句结束即释放 | 先用变量绑定，再取引用 |

调试套路：**先读编译器给出的帮助（help: ...），它经常直接给出改法**；再看生命周期标注建议；最后才考虑引入 `Rc/Arc/RefCell`。绝大多数错误通过"传引用而不是传值""缩小借用范围"即可解决。

## 何时需要 Clone

`clone()` 是让代码先跑通的合法手段，但要点在于**知道自己在复制什么**：小对象复制成本可忽略；大 `Vec`/`String` 在热点路径反复 clone 会显著变慢。做法是先用 clone 理顺逻辑，再用 pprof/benchmark 找出真正的热点，逐步改成借用或 `Cow`。

## 场景化选择：该传值、传引用还是共享

| 场景 | 推荐写法 | 理由 |
| --- | --- | --- |
| 小且实现了 Copy 的类型（i32、bool） | 直接传值 | 复制成本极低，代码最简洁 |
| 只读的大对象（String、Vec、结构体） | 传 `&T` | 避免复制，且不转移所有权 |
| 需要修改调用方的数据 | 传 `&mut T` | 明确可变意图，独占借用 |
| 函数需要长期持有该数据 | 传值（取得所有权） | 生命周期最清晰 |
| 多处共享只读 | `Rc<T>` / `Arc<T>` | 引用计数共享所有权 |
| 多处共享可变（单线程 / 多线程） | `RefCell<T>` / `Mutex<T>` | 运行时借用检查 / 互斥 |
| 结构体内部互相引用 | 改用索引或 ID | 自引用结构在 Rust 中极难表达 |

工程建议：**先按「传引用」写，只有编译器要求所有权时才改为传值或共享**。这样能避免一上来就到处 clone 或 Arc，代码更贴近 Rust 的惯用法。遇到难以表达的自引用结构，优先重构数据结构（用索引关联）而不是硬上 `unsafe`。

## 本课小结
掌握所有权只需记住一句话：**一个值一个所有者，借用不夺权，可变借用独占**；其余规则都是它的推论。


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

## 动手练习


> 本课练习重点：围绕「Rust、所有权、借用」完成复述、实验和交付，每个结果都要能被别人检查。

先让 cargo check 通过，再补所有权、错误和并发边界，最后运行 clippy。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Rust 所有权、借用与生命周期」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「所有权」是什么关系？

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
- 至少覆盖「Rust」和「所有权」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。



## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：Rust 中把变量赋值给另一个变量，默认行为是？

- **正确判断**：移动（Move）
- **判断依据**：正确答案是「移动（Move）」，本课在「所有权三条规则」中说明：因此赋值与传参默认是移动（Move），原变量失效。除非类型实现了 Copy，否则所有权转移，原变量失效。本课还在「常见解法」中说明：生命周期标注只在编译器需要帮助时写，先写代码再让编译器提示补标注。本课还在「与 GC 语言的对比」中说明：GC 语言在运行时回收，Rust 在编译期决定释放点：没有停顿、没有额外内存开销，但要求程序员显式表达所有权关系。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 2：以下哪组操作会转移所有权？

- **正确判断**：把 String 直接赋给另一个变量
- **判断依据**：正确答案是「把 String 直接赋给另一个变量」，本课在「常见解法」中说明：生命周期标注只在编译器需要帮助时写，先写代码再让编译器提示补标注。Rust 中 String 这类拥有堆数据的值在赋值或按值传参时会发生移动，原变量随后不能继续使用。本课还在「本课小结」中说明：掌握所有权只需记住一句话：一个值一个所有者，借用不夺权，可变借用独占。本课还在「零基础详解：所有权，用「借书」理解 Rust 最核心的规则」中说明：函数参数用 &T 而不是 T，可以避免调用处失去所有权。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 3：生命周期标注的作用是？

- **正确判断**：向编译器说明引用的有效范围
- **判断依据**：正确答案是「向编译器说明引用的有效范围」，本课在「场景化选择：该传值、传引用还是共享」中说明：工程建议：先按「传引用」写，只有编译器要求所有权时才改为传值或共享。它不改变运行期行为，只是让借用检查可验证。本课还在「与 GC 语言的对比」中说明：GC 语言在运行时回收，Rust 在编译期决定释放点：没有停顿、没有额外内存开销，但要求程序员显式表达所有权关系。本课还在「零基础详解：所有权，用「借书」理解 Rust 最核心的规则」中说明：所有权是 Rust 管理内存的方式：每个值有且只有一个所有者。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：为什么把 String 赋给另一个变量会「移动」，而 i32 是复制？

- **正确判断**：i32 等实现了 Copy 的类型按位复制，String 持有堆内存只能移动所有权
- **判断依据**：正确答案是「i32 等实现了 Copy 的类型按位复制，String 持有堆内存只能移动所有权」，本课在「常见编译错误与修复」中说明：调试套路：先读编译器给出的帮助（help: ...），它经常直接给出改法。如果 String 也复制，就会出现两处释放同一块内存的问题，这正是 Rust 要避免的。本课还在「零基础详解：所有权，用「借书」理解 Rust 最核心的规则」中说明：知道为什么 i32 赋值后原变量还能用，而 String 不行。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 5：String 与 &str 的关系是？

- **正确判断**：String 拥有堆上的字符串
- **判断依据**：正确答案是「String 拥有堆上的字符串」，本课在「本课小结」中说明：掌握所有权只需记住一句话：一个值一个所有者，借用不夺权，可变借用独占。函数参数用 &str 更通用，String 可通过 &s 或 s.asstr() 借用。本课还在「零基础详解：所有权，用「借书」理解 Rust 最核心的规则」中说明：所有权是 Rust 管理内存的方式：每个值有且只有一个所有者。本课还在「场景化选择：该传值、传引用还是共享」中说明：工程建议：先按「传引用」写，只有编译器要求所有权时才改为传值或共享。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 6：补全代码：「Rust 所有权、借用与生命周期」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `let s3 = s2.____(); // 深拷贝，两边都能用`

- **正确判断**：clone
- **判断依据**：正确答案是「clone」，本课在「何时需要 Clone」中说明：clone() 是让代码先跑通的合法手段，但要点在于知道自己在复制什么：小对象复制成本可忽略。本课还在「何时需要 Clone」中说明：做法是先用 clone 理顺逻辑，再用 pprof/benchmark 找出真正的热点，逐步改成借用或 Cow。本课还在「场景化选择：该传值、传引用还是共享」中说明：这样能避免一上来就到处 clone 或 Arc，代码更贴近 Rust 的惯用法。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「Rust 中把变量赋值给另一个变量，默认行为是？」的判断依据。
- [ ] 不看解析，能说出「以下哪组操作会转移所有权？」的判断依据。
- [ ] 不看解析，能说出「生命周期标注的作用是？」的判断依据。
- [ ] 不看解析，能说出「为什么把 String 赋给另一个变量会「移动」，而 i32 是复制？」的判断依据。
- [ ] 不看解析，能说出「String 与 &str 的关系是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「Rust 所有权、借用与生命周期」示例中，下面这行代码缺少哪个关键字…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。

| 术语 | 本课语境 |
| --- | --- |
| `Copy` | 因此赋值与传参默认是**移动（Move）**，原变量失效；`Copy` 类型（整数、布尔、字符、仅含 Copy 字段的结构体）按值复制。 |
| `&T` | \| `&T` 不可变借用 \| 可同时存在多个 \| |
| `&mut T` | \| `&mut T` 可变借用 \| 同一作用域只能有一个，且不能与不可变借用共存 \| |
| `'a` | \| 生命周期 `'a` \| 标注引用的有效范围，保证不出悬垂引用 \| |
| `Vec` | 结构体自引用很麻烦：改用索引（如 `Vec` 下标）或 `Rc<RefCell<T>>`（单线程）/`Arc<Mutex<T>>`（多线程）。 |
| `Rc<RefCell<T>>` | 结构体自引用很麻烦：改用索引（如 `Vec` 下标）或 `Rc<RefCell<T>>`（单线程）/`Arc<Mutex<T>>`（多线程）。 |
| `Arc<Mutex<T>>` | 结构体自引用很麻烦：改用索引（如 `Vec` 下标）或 `Rc<RefCell<T>>`（单线程）/`Arc<Mutex<T>>`（多线程）。 |
| `value borrowed here after move` | \| `value borrowed here after move` \| 值已被移动，原变量失效 \| 用 `.clone()`、改为传引用 `&T`，或调整所有权归属 \| |
| `.clone()` | \| `value borrowed here after move` \| 值已被移动，原变量失效 \| 用 `.clone()`、改为传引用 `&T`，或调整所有权归属 \| |
| `cannot borrow as mutable` | \| `cannot borrow as mutable` \| 同时存在不可变与可变借用 \| 缩小可变借用作用域，或用 `RefCell`/`Mutex` 做运行时检查 \| |
| `RefCell` | \| `cannot borrow as mutable` \| 同时存在不可变与可变借用 \| 缩小可变借用作用域，或用 `RefCell`/`Mutex` 做运行时检查 \| |
| `Mutex` | \| `cannot borrow as mutable` \| 同时存在不可变与可变借用 \| 缩小可变借用作用域，或用 `RefCell`/`Mutex` 做运行时检查 \| |

## 面试问答与自测

下面把本课考点换成面试追问。先口述自己的答案，
再对照参考回答检查是否遗漏了前提、边界或失败路径。

### 追问 1：Rust 中把变量赋值给另一个变量，默认行为是？

**参考回答**：正确答案是「移动（Move）」，本课在「所有权三条规则」中说明：因此赋值与传参默认是移动（Move），原变量失效。除非类型实现了 Copy，否则所有权转移，原变量失效。本课还在「常见解法」中说明：生命周期标注只在编译器需要帮助时写，先写代码再让编译器提示补标注。本课还在「与 GC 语言的对比」中说明：GC 语言在运行时回收，Rust 在编译期决定释放点：没有停顿、没有额外内存开销，但要求程序员显式表达所有权关系。

### 追问 2：以下哪组操作会转移所有权？

**参考回答**：正确答案是「把 String 直接赋给另一个变量」，本课在「常见解法」中说明：生命周期标注只在编译器需要帮助时写，先写代码再让编译器提示补标注。Rust 中 String 这类拥有堆数据的值在赋值或按值传参时会发生移动，原变量随后不能继续使用。本课还在「本课小结」中说明：掌握所有权只需记住一句话：一个值一个所有者，借用不夺权，可变借用独占。本课还在「零基础详解·所有权，用「借书」理解 Rust 最核心的规则」中说明：函数参数用 &T 而不是 T，可以避免调用处失去所有权。

### 追问 3：生命周期标注的作用是？

**参考回答**：正确答案是「向编译器说明引用的有效范围」，本课在「场景化选择·该传值、传引用还是共享」中说明：工程建议：先按「传引用」写，只有编译器要求所有权时才改为传值或共享。它不改变运行期行为，只是让借用检查可验证。本课还在「与 GC 语言的对比」中说明：GC 语言在运行时回收，Rust 在编译期决定释放点：没有停顿、没有额外内存开销，但要求程序员显式表达所有权关系。本课还在「零基础详解·所有权，用「借书」理解 Rust 最核心的规则」中说明：所有权是 Rust 管理内存的方式：每个值有且只有一个所有者。

### 追问 4：为什么把 String 赋给另一个变量会「移动」，而 i32 是复制？

**参考回答**：正确答案是「i32 等实现了 Copy 的类型按位复制，String 持有堆内存只能移动所有权」，本课在「常见编译错误与修复」中说明：调试套路：先读编译器给出的帮助（help: ...），它经常直接给出改法。如果 String 也复制，就会出现两处释放同一块内存的问题，这正是 Rust 要避免的。本课还在「零基础详解·所有权，用「借书」理解 Rust 最核心的规则」中说明：知道为什么 i32 赋值后原变量还能用，而 String 不行。

### 追问 5：String 与 &str 的关系是？

**参考回答**：正确答案是「String 拥有堆上的字符串」，本课在「本课小结」中说明：掌握所有权只需记住一句话：一个值一个所有者，借用不夺权，可变借用独占。函数参数用 &str 更通用，String 可通过 &s 或 s.asstr() 借用。本课还在「零基础详解·所有权，用「借书」理解 Rust 最核心的规则」中说明：所有权是 Rust 管理内存的方式：每个值有且只有一个所有者。本课还在「场景化选择·该传值、传引用还是共享」中说明：工程建议：先按「传引用」写，只有编译器要求所有权时才改为传值或共享。

## English Overview

**Title:** Ownership & Borrowing

**Summary:** Move/Copy, borrow rules and lifetimes.

**Category:** Rust  
**Level:** 入门  
**Key terms:** Rust, 所有权, 借用, 生命周期, Move

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：入门
- 适用环境：Rust 1.85+ / Cargo
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、所有权、借用、生命周期、Move
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全


## Full English Study Guide

### Overview

**Ownership & Borrowing** focuses on Move/Copy, borrow rules and lifetimes.

### Learning Outcomes

- Explain what **Ownership & Borrowing** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Ownership & Borrowing**
- Related terms: Rust, 所有权, 借用, 生命周期
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.


## Bilingual Section Outline

| 中文小节 | English section |
| --- | --- |
| 学习目标 | Learning objectives |
| 前置知识 | Prerequisites |
| 所有权三条规则 | Ownership三条规则 |
| 借用与借用检查 | 借用与借用检查 |
| 常见解法 | 常见解法 |
| 与 GC 语言的对比 | 与 GC 语言的对比 |
| 常见编译错误与修复 | 常见编译错误与修复 |
| 何时需要 Clone | 何时需要 Clone |
| 场景化选择：该传值、传引用还是共享 | 场景化选择：该传值、传引用还是共享 |
| 本课小结 | Summary |

> 该大纲把每个中文小节映射为英文标题，配合 Full English Study Guide 使用。


## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档与标准；本课正文为离线教学重组，不复制原文

| 参考资料 | 本课用途 |
| --- | --- |
| [The Rust Book](https://doc.rust-lang.org/book/) | 所有权、类型与工程实践 |
| [Rust 标准库](https://doc.rust-lang.org/std/) | 标准库与并发 API |

> 本课主题：Move/Copy、借用规则与生命周期标注。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。
