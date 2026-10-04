## 现代 C++ 特性速查

| 特性 | 标准 | 一句话说明 | 典型写法 |
| --- | --- | --- | --- |
| `auto` | C++11 | 编译期类型推导 | `auto it = v.begin();` |
| 范围 for | C++11 | 遍历容器 | `for (const auto& x : v)` |
| 智能指针 | C++11 | 自动管理生命周期 | `auto p = std::make_unique<T>();` |
| `nullptr` | C++11 | 类型安全的空指针 | `T* p = nullptr;` |
| lambda | C++11 | 就地定义匿名函数 | `[](int x) { return x * 2; }` |
| 右值引用与移动 | C++11 | 避免不必要的深拷贝 | `v.push_back(std::move(s));` |
| 结构化绑定 | C++17 | 一次解包多个值 | `for (const auto& [k, v] : map)` |
| `std::optional` | C++17 | 表达「可能没有值」 | `std::optional<int> f();` |
| `std::string_view` | C++17 | 不拥有内存的字符串视图 | `void log(std::string_view s);` |
| `if constexpr` | C++17 | 编译期分支 | 模板里按类型走不同逻辑 |
| 折叠表达式 | C++17 | 简化可变参数展开 | `(args + ...)` |
| concepts | C++20 | 给模板参数加约束 | `template <std::integral T>` |
| ranges | C++20 | 组合式序列操作 | `v \| std::views::filter(...)` |
| `std::span` | C++20 | 连续内存视图 | `void f(std::span<int> data);` |
| `std::format` | C++20 | 类型安全的格式化 | `std::format("{} {}", a, b)` |
| `std::expected` | C++23 | 表达成功值或错误 | 类似 Rust 的 `Result` |

## 类型推导与移动语义速查

| 写法 | 含义 | 注意点 |
| --- | --- | --- |
| `auto x = expr;` | 按值推导，会拷贝 | 大对象加 `&` |
| `const auto& x = expr;` | 只读引用，不拷贝 | 最常用的遍历写法 |
| `auto&& x = expr;` | 转发引用 | 模板中配合 `std::forward` |
| `std::move(x)` | 转成右值，触发移动 | 之后 `x` 状态未定义，别再读 |
| `std::forward<T>(x)` | 保持原始值类别转发 | 只用在模板转发场景 |
| `decltype(x)` | 取表达式的声明类型 | 与 `auto` 的推导规则不同 |
| 返回值优化（RVO） | 编译器直接构造返回对象 | 别写 `return std::move(local);`，会阻碍优化 |

```cpp
#include <optional>
#include <string>
#include <string_view>

std::optional<int> parse_int(std::string_view text) {
    try {
        return std::stoi(std::string{text});
    } catch (...) {
        return std::nullopt;                 // 明确表达「解析失败」
    }
}

if (auto value = parse_int("42")) {
    // 只有成功时才进入
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `auto` 接住 `vector<bool>` 的元素 | 拿到的是代理对象而非 `bool` | 需要真值写 `bool b = v[i];` |
| `return std::move(local);` | 反而阻止返回值优化 | 直接 `return local;` |
| 忘了 `std::forward` | 右值语义丢失，多一次拷贝 | 转发模板参数时用 `std::forward<T>(x)` |
| `std::move` 后继续使用对象 | 值不确定 | move 之后只能重新赋值 |
| `string_view` 指向临时字符串 | 悬空视图 | 确保底层字符串生命周期更长 |
| `optional` 直接 `*opt` 取值 | 未判空时是未定义行为 | 先 `if (opt)` 或用 `value_or` |
| lambda 按值捕获大对象 | 多余的拷贝 | 明确捕获列表，只捕获需要的变量 |
| lambda 里 `[&]` 捕获局部变量并异步使用 | 悬空引用 | 异步场景按值捕获或 `shared_ptr` |
| `if constexpr` 分支里写非法代码 | 仍可能实例化失败 | 两个分支都必须对相应类型合法 |
| 用 `std::format` 但未开启 C++20 | 编译失败 | 检查编译器版本与标准选项 |

## 自测清单

- [ ] 会写 `const auto&` 遍历，知道 `auto` 会拷贝。
- [ ] 能用 `std::optional` 表达「可能没有值」，并正确判空。
- [ ] 会用结构化绑定遍历 `map`。
- [ ] 知道 `std::move` 之后源对象不能再读。
- [ ] 了解 concepts、ranges、`std::span` 各自的用途。
