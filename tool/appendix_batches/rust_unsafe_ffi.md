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
