# Rust unsafe、FFI 与生态

![Rust unsafe、FFI 与生态](images/remaining_rust_unsafe_ffi.webp)

> 内容更新时间：2026-10-03 · 学习阶段：进阶 · 预计用时：16 分钟

## 学习目标

- 能用自己的话解释「Rust unsafe、FFI 与生态」解决了什么问题，而不是只背术语。
- 能说清 「Rust」、「unsafe」、「FFI」、「serde」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「Rust」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：unsafe 的四种能力、C 互操作与常用 crate。

## 前置知识

- 先完成上一课《Rust 错误处理、迭代器与异步》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：Rust、unsafe、FFI。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。


## unsafe 能做什么

`unsafe` 只解锁四件能力：解引用裸指针、调用 unsafe 函数、访问/修改可变静态变量、实现 unsafe trait。它**不关闭借用检查器的其余规则**，而是把责任交给程序员：必须写 `// SAFETY:` 注释说明前置条件。

原则：把 unsafe 封装在最小范围内，对外暴露安全 API，并用测试与 Miri 验证。

## FFI：与 C 互操作

| 场景 | 做法 |
| --- | --- |
| 调用 C 库 | `extern "C" { fn foo(x: c_int) -> c_int; }` + `#[link(name="foo")]` |
| 导出给 C 用 | `#[no_mangle] pub extern "C" fn bar(...)` |
| 自动生成绑定 | bindgen（C 头文件 → Rust 声明） |
| C++ 互操作 | cxx / autocxx 提供更安全的桥接 |

注意：跨 FFI 边界的字符串与结构体布局必须显式约定（CString、repr(C)），panic 不能跨边界传播（用 catch_unwind 兜住）。

## 常用 crate 生态

| 领域 | 常用 crate |
| --- | --- |
| 序列化 | serde / serde_json |
| 异步运行时 | tokio |
| HTTP 客户端 | reqwest |
| Web 框架 | axum / actix-web |
| 命令行 | clap |
| 错误处理 | thiserror / anyhow |
| 日志与追踪 | tracing / tracing-subscriber |
| 时间 | chrono / time |

Cargo 的 feature 机制能裁剪依赖体积，发布前用 `cargo tree` 检查依赖膨胀。

## 何时该用 unsafe

只有三种情况值得：与 C 互操作、实现底层数据结构（自定义分配器、无锁结构）、性能极致优化且已被基准证明。其余场景用安全抽象替代，收益远大于风险。

## 本课小结
unsafe 是**把编译器无法验证的契约写进注释与封装**；FFI 是 Rust 融入现有生态的桥梁；日常开发优先使用成熟 crate，把 unsafe 留在边界层。


## unsafe 能力与边界速查

| unsafe 允许做的事 | 说明 |
| --- | --- |
| 解引用裸指针 | `*const T` / `*mut T` |
| 调用 unsafe 函数 | 包括外部 C 函数 |
| 访问可变静态变量 | `static mut` |
| 实现 unsafe trait | 如 `Send` / `Sync` |
| 访问联合体字段 | `union` |
| 内联汇编 | `asm!` |

unsafe **不会**改变的事：

| 仍然受检查 | 说明 |
| --- | --- |
| 借用规则 | unsafe 块内依然有借用检查 |
| 类型检查 | 类型错误照样编译失败 |
| 生命周期 | 悬空引用仍需自行保证正确 |
| 越界检查 | 切片索引仍会 panic（除非用裸指针） |

```rust
use std::os::raw::c_char;

// 与 C 交互：结构体使用 C 布局
#[repr(C)]
pub struct Config {
    pub id: u32,
    pub name: *const c_char,
}

extern "C" {
    fn read_config(out: *mut Config) -> i32;
}

/// # Safety
/// 调用者必须保证 `out` 指向可写且对齐的 `Config`，
/// 并且在函数返回前保持有效。
pub unsafe fn read_config_checked() -> Result<Config, i32> {
    let mut config = Config { id: 0, name: std::ptr::null() };
    let code = unsafe { read_config(&mut config) };
    if code == 0 { Ok(config) } else { Err(code) }
}
```

## FFI 注意点速查

| 主题 | 要求 |
| --- | --- |
| 结构体布局 | 必须 `#[repr(C)]` |
| 字符串 | C 使用 NUL 结尾，用 `CString` / `CStr` 转换 |
| 内存所有权 | 明确谁分配、谁释放，禁止跨语言混用分配器 |
| panic 跨界 | 禁止 panic 穿过 FFI 边界，用 `catch_unwind` 包裹 |
| 错误传递 | 用返回码 + 输出参数，或 `thread_local` 存最后错误 |
| 空指针 | C 指针可能为 null，传给 Rust 引用前必须检查 |
| 文档 | `unsafe fn` 必须写 `# Safety` 说明前置条件 |

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 用 unsafe 当成「关闭检查」 | 仍然报借用或类型错误 | unsafe 只解锁特定能力 |
| `unsafe fn` 不写安全说明 | 调用者不知道前置条件 | 补 `# Safety` 文档 |
| 把 C 指针直接转 `&T` 不判空 | 未定义行为 | 先 `is_null()` 检查 |
| 结构体没有 `#[repr(C)]` | 字段顺序不一致，读取错乱 | 加 `#[repr(C)]` |
| 跨 FFI 抛 panic | 未定义行为或进程崩溃 | `catch_unwind` 兜住并转成错误码 |
| 用 Rust 的分配器释放 C 内存 | 堆损坏 | 由分配方提供释放函数 |
| 假设指针一定是 UTF-8 | 非法字符导致未定义行为 | 用 `CStr::to_str()` 检查返回 `Result` |
| 直接 `unsafe impl Send` | 数据竞争 | 只有充分验证后才实现并写明理由 |
| 为性能滥用 unsafe | 逻辑错误难以定位 | 先测量，确认瓶颈再优化 |
| 缺少 Miri / sanitizer 验证 | 隐藏的内存错误 | 用 Miri、ASan 验证 unsafe 代码 |

## 自测清单

- [ ] 清楚 unsafe 解锁与不解锁的能力边界。
- [ ] 所有 `unsafe fn` 都有 `# Safety` 文档。
- [ ] FFI 结构体使用 `#[repr(C)]`，指针使用前判空。
- [ ] panic 不穿越 FFI 边界。
- [ ] unsafe 代码用 Miri 或 sanitizer 验证。


## 零基础详解：unsafe 与 FFI

### 一句话说清它是什么

`unsafe` 不是「关掉安全检查」，而是「**你向编译器承诺：这块代码由我来保证安全**」。
它只解锁五种额外能力，其余规则照旧；FFI 则是用它调用 C 语言写的库。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 安全 Rust | 有护栏的高速路 | 编译器帮你把关 |
| `unsafe` | 拆掉护栏的路段 | 更快或能到别处，但要自己小心 |
| 安全抽象 | 给护栏外再修一段护栏 | 把 unsafe 关在小函数里 |
| FFI | 与外国团队对接 | 需要统一接口约定（ABI） |
| `unsafe` 块 | 临时许可 | 只在这一小块生效 |

### unsafe 解锁的五种能力

```rust
// 1. 解引用裸指针
let x = 42;
let p: *const i32 = &x;
let value = unsafe { *p };

// 2. 调用 unsafe 函数
unsafe fn dangerous() {}
unsafe { dangerous() }

// 3. 访问或修改可变静态变量
static mut COUNTER: u32 = 0;
unsafe { COUNTER += 1 }

// 4. 实现 unsafe trait
unsafe trait Marker {}
unsafe impl Marker for MyType {}

// 5. 访问 union 的字段
union U { a: u32, b: f32 }
let u = U { a: 1 };
let f = unsafe { u.b };
```

**记住：`unsafe` 只解锁这五件事，它不会让所有权与借用检查消失。**

### 正确姿势：把 unsafe 关进小盒子

```rust
pub struct SafeBuffer {
    ptr: *mut u8,
    len: usize,
}

impl SafeBuffer {
    /// 对外暴露安全接口：任何输入都不会造成未定义行为
    pub fn get(&self, index: usize) -> Option<u8> {
        if index >= self.len || self.ptr.is_null() {
            return None;
        }
        // SAFETY: 上面已检查索引范围与指针非空
        Some(unsafe { *self.ptr.add(index) })
    }
}
```

**API 设计规则**：`unsafe` 只能出现在函数体内；对外暴露的函数应当是安全的。

### FFI：调用 C 函数

```rust
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

// 1. 声明外部函数签名（必须与 C 完全一致）
extern "C" {
    fn strlen(s: *const c_char) -> usize;
}

// 2. 安全包装：把裸指针的复杂度留在内部
pub fn str_len(text: &str) -> usize {
    let c_string = CString::new(text).expect("字符串不能包含空字节");
    // SAFETY: c_string 在本函数内一直存活，指针有效
    unsafe { strlen(c_string.as_ptr()) }
}
```

| 类型对照 | Rust | C |
| --- | --- | --- |
| 整数 | `i32` / `u64` | `int32_t` / `uint64_t` |
| 字符 | `c_char` | `char` |
| 字符串 | `CString` / `CStr` | `char*` |
| 数组 | `*mut T` 加长度 | `T*` 加 `size_t` |
| 结构体 | `#[repr(C)] struct` | `struct` |

```rust
#[repr(C)]                 // 必须加，否则字段布局不确定
pub struct Point {
    pub x: f64,
    pub y: f64,
}
```

### 导出给 C 调用

```rust
#[no_mangle]
pub extern "C" fn add(a: i32, b: i32) -> i32 {
    a + b
}

// 必须提供配套的释放函数，否则调用方会内存泄漏
#[no_mangle]
pub extern "C" fn make_string() -> *mut c_char {
    CString::new("hello").unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        // SAFETY: 指针来自本库的 CString::into_raw
        drop(unsafe { CString::from_raw(ptr) });
    }
}
```

**谁分配谁释放**：跨语言传递所有权时，必须成对提供释放函数。

### unsafe 代码检查清单

| 检查项 | 问题 |
| --- | --- |
| 指针是否可能为空 | 空指针解引用是未定义行为 |
| 指针是否仍然有效 | 悬垂指针是未定义行为 |
| 是否有别名冲突 | 同时存在 `&mut` 与 `&` 是未定义行为 |
| 索引是否越界 | 越界读写是未定义行为 |
| 对齐是否正确 | 未对齐访问是未定义行为 |
| 生命周期是否足够 | 数据在引用前被释放是未定义行为 |
| 是否跨线程共享 | 违反 `Send` 与 `Sync` 是未定义行为 |
| 释放是否成对 | 双重释放或泄漏 |

### 用工具兜底

```bash
cargo miri test          # 检测未定义行为（需要 nightly）
cargo clippy -- -D warnings
cargo test --release
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 用 unsafe 图省事 | 埋下未定义行为 | 先想能不能用安全写法 |
| unsafe 范围太大 | 难以审查 | 缩小到最小语句 |
| 忘记 `#[repr(C)]` | 结构体布局不匹配 | FFI 结构体必须加 |
| 字符串含空字节 | `CString::new` 失败 | 提前校验或替换 |
| 忘了释放跨语言内存 | 内存泄漏 | 成对提供 free 函数 |
| 假设 C 指针一定非空 | 段错误 | 先判空 |
| 在 unsafe 里忽略错误码 | 静默出错 | 检查返回值并转成 `Result` |
| 没跑 Miri | 未定义行为逃过测试 | CI 里加 `cargo miri` |

### 手把手练习：用 FFI 调用 libc 获取时间

```rust
use std::mem::MaybeUninit;
use std::os::raw::c_long;

#[repr(C)]
struct CTimespec {
    tv_sec: c_long,
    tv_nsec: c_long,
}

extern "C" {
    fn clock_gettime(clk_id: i32, tp: *mut CTimespec) -> i32;
}

const CLOCK_REALTIME: i32 = 0;

pub fn now_seconds() -> Result<i64, String> {
    let mut ts = MaybeUninit::<CTimespec>::uninit();
    // SAFETY: 传入的指针指向本地有效内存，函数会写满该结构体
    let rc = unsafe { clock_gettime(CLOCK_REALTIME, ts.as_mut_ptr()) };
    if rc != 0 {
        return Err("clock_gettime 调用失败".into());
    }
    // SAFETY: 上面已确认调用成功，结构体已初始化
    let ts = unsafe { ts.assume_init() };
    Ok(ts.tv_sec as i64)
}
```

### 学完自测

- [ ] 能说出 unsafe 解锁的五种能力。
- [ ] 知道为什么要把 unsafe 关在小函数里。
- [ ] 能说出 FFI 结构体为什么必须加 `#[repr(C)]`。
- [ ] 知道跨语言内存的释放原则。
- [ ] 能列出 unsafe 检查清单中的至少四项。

## 动手练习


> 本课练习重点：围绕「Rust、unsafe、FFI」完成复述、实验和交付，每个结果都要能被别人检查。

先让 cargo check 通过，再补所有权、错误和并发边界，最后运行 clippy。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 「Rust unsafe、FFI 与生态」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「unsafe」是什么关系？

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
- 至少覆盖「Rust」和「unsafe」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。


## 考点精讲：把测验题还原成判断过程

本课有 6 个判断点。先自己作答，再看「判断依据」；如果结论正确但理由不完整，回到正文对应章节补足概念。

### 考点 1：unsafe 解锁的能力不包括？

- **正确判断**：跳过借用检查的所有规则
- **判断依据**：正确答案是「跳过借用检查的所有规则」，本课在「unsafe 能做什么」中说明：unsafe 只解锁四件能力：解引用裸指针、调用 unsafe 函数、访问/修改可变静态变量、实现 unsafe trait。unsafe 只解锁四类操作，其余规则仍然生效。本课还在「零基础详解：unsafe 与 FFI」中说明：记住：unsafe 只解锁这五件事，它不会让所有权与借用检查消失。本课还在「unsafe 能做什么」中说明：它不关闭借用检查器的其余规则，而是把责任交给程序员：必须写 // SAFETY: 注释说明前置条件。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 2：跨 FFI 边界时必须注意？

- **正确判断**：panic 不能跨越边界
- **判断依据**：正确答案是「panic 不能跨越边界」，本课在「FFI：与 C 互操作」中说明：注意：跨 FFI 边界的字符串与结构体布局必须显式约定（CString、repr(C)），panic 不能跨边界传播（用 catchunwind 兜住）。布局要用 repr(C)，字符串要用 CString 等明确表示。本课还在「本课小结」中说明：日常开发优先使用成熟 crate，把 unsafe 留在边界层。本课还在「unsafe 能做什么」中说明：原则：把 unsafe 封装在最小范围内，对外暴露安全 API，并用测试与 Miri 验证。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 3：下面哪种情况值得使用 unsafe？

- **正确判断**：与 C 互操作
- **判断依据**：正确答案是「与 C 互操作」，本课在「何时该用 unsafe」中说明：只有三种情况值得：与 C 互操作、实现底层数据结构（自定义分配器、无锁结构）、性能极致优化且已被基准证明。其余场景应使用安全抽象替代。本课还在「零基础详解：unsafe 与 FFI」中说明：unsafe 不是「关掉安全检查」，而是「你向编译器承诺：这块代码由我来保证安全」。本课还在「本课小结」中说明：unsafe 是把编译器无法验证的契约写进注释与封装。
- **迁移检查**：如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。

### 考点 4：#[repr(C)] 在 FFI 场景中的作用是？

- **正确判断**：让结构体使用 C 的内存布局
- **判断依据**：正确答案是「让结构体使用 C 的内存布局」，本课在「零基础详解：unsafe 与 FFI」中说明：能说出 FFI 结构体为什么必须加 #[repr(C)]。Rust 默认布局不保证字段顺序，跨语言传递结构体必须显式声明 C 布局。本课还在「FFI：与 C 互操作」中说明：注意：跨 FFI 边界的字符串与结构体布局必须显式约定（CString、repr(C)），panic 不能跨边界传播（用 catchunwind 兜住）。
- **迁移检查**：把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。

### 考点 5：unsafe impl Send for MyType {} 的语义是？

- **正确判断**：由程序员向编译器承诺该类型跨线程使用是安全的
- **判断依据**：正确答案是「由程序员向编译器承诺该类型跨线程使用是安全的」，本课在「零基础详解：unsafe 与 FFI」中说明：unsafe 不是「关掉安全检查」，而是「你向编译器承诺：这块代码由我来保证安全」。这是不受编译器保护的承诺，一旦判断错误就会产生数据竞争。本课还在「本课小结」中说明：unsafe 是把编译器无法验证的契约写进注释与封装。本课还在「unsafe 能做什么」中说明：原则：把 unsafe 封装在最小范围内，对外暴露安全 API，并用测试与 Miri 验证。
- **迁移检查**：遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。

### 考点 6：补全代码：「Rust unsafe、FFI 与生态」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `if index >= self.len || self.ptr.____() {`

- **正确判断**：is_null
- **判断依据**：正确答案是「is_null」，本课在「零基础详解：unsafe 与 FFI」中说明：API 设计规则：unsafe 只能出现在函数体内。本课还在「零基础详解：unsafe 与 FFI」中说明：知道为什么要把 unsafe 关在小函数里。本课还在「零基础详解：unsafe 与 FFI」中说明：能列出 unsafe 检查清单中的至少四项。
- **迁移检查**：把答案换成另一种等价写法，是否仍然正确？说明依据。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「unsafe 解锁的能力不包括？」的判断依据。
- [ ] 不看解析，能说出「跨 FFI 边界时必须注意？」的判断依据。
- [ ] 不看解析，能说出「下面哪种情况值得使用 unsafe？」的判断依据。
- [ ] 不看解析，能说出「#[repr(C)] 在 FFI 场景中的作用是？」的判断依据。
- [ ] 不看解析，能说出「unsafe impl Send for MyType {} 的语义是？」的判断依据。
- [ ] 不看解析，能说出「补全代码：「Rust unsafe、FFI 与生态」示例中，下面这行代码缺少哪个…」的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## English Overview

**Title:** unsafe, FFI & Ecosystem

**Summary:** unsafe capabilities, FFI and key crates.

**Category:** Rust  
**Level:** 进阶  
**Key terms:** Rust, unsafe, FFI, serde, tokio

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：Rust 1.85+ / Cargo
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：Rust、unsafe、FFI、serde、tokio
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

> 本课主题：unsafe 的四种能力、C 互操作与常用 crate。

> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。

