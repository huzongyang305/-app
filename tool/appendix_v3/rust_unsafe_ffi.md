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
