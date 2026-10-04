## 模板语法速查

| 场景 | 写法 |
| --- | --- |
| 函数模板 | `template <typename T> T max(T a, T b);` |
| 类模板 | `template <typename T> class Box { T value; };` |
| 多个参数 | `template <typename K, typename V> class Map;` |
| 非类型参数 | `template <int N> class FixedArray;` |
| 默认参数 | `template <typename T = int> class Vec;` |
| 特化 | `template <> class Box<bool> { ... };` |
| 可变参数 | `template <typename... Args> void log(Args&&... args);` |
| C++20 约束 | `template <std::integral T> T add(T a, T b);` |
| requires 子句 | `template <typename T> requires requires(T t) { t.size(); }` |

```cpp
#include <concepts>
#include <string>
#include <type_traits>

// C++20 concepts：错误信息更清晰，约束写在接口上
template <std::integral T>
T gcd(T a, T b) {
    while (b != 0) {
        T t = a % b;
        a = b;
        b = t;
    }
    return a;
}

// 自定义 concept
template <typename T>
concept Printable = requires(const T& value, std::ostream& os) {
    { os << value } -> std::same_as<std::ostream&>;
};

template <Printable T>
void printAll(const std::vector<T>& items) {
    for (const auto& item : items) std::cout << item << '\n';
}
```

## 编译期技巧速查

| 目的 | 写法 |
| --- | --- |
| 编译期分支 | `if constexpr (std::is_integral_v<T>) { ... }` |
| 类型萃取 | `std::is_same_v<T, int>`、`std::decay_t<T>` |
| 完美转发 | `std::forward<T>(arg)` |
| 折叠表达式 | `(args + ...)` |
| 编译期常量 | `constexpr`、`consteval` |
| 静态断言 | `static_assert(sizeof(T) >= 4, "T 太小");` |
| 可变参数展开 | `(std::cout << ... << args);` |

## 常见错误对照表

| 报错或现象 | 含义 | 处理方式 |
| --- | --- | --- |
| `undefined reference to Foo<int>::bar()` | 模板定义不可见 | 定义放头文件，或显式实例化 |
| 报错信息长达几百行 | 约束失败被层层展开 | 用 C++20 concepts 前置约束 |
| `template <typename T> T add(T a, T b)` 传入 `1, 2.0` | 推导冲突 | 显式指定类型，或让两个参数独立推导 |
| `>>` 写法在旧标准报错 | 与右移混淆 | 现代 C++ 已修复，升级标准即可 |
| 类模板的静态成员未定义 | 链接错误 | 在头文件内定义，或显式实例化 |
| 依赖模板参数的类型名没用 `typename` | 编译错误 | 写成 `typename T::value_type` |
| 模板代码编译变慢、体积变大 | 每个类型实例化一份 | 抽出与类型无关的逻辑到非模板函数 |
| 用模板做运行时多态 | 代码膨胀 | 运行时多态用虚函数，编译期用模板 |
| 特化写错位置 | 编译错误 | 特化必须与主模板在同一命名空间 |

## 自测清单

- [ ] 模板定义与声明都放在头文件里。
- [ ] 会用 concepts 给模板参数加约束。
- [ ] 会用 `if constexpr` 按类型分支。
- [ ] 知道模板实例化会导致代码膨胀，能抽出公共逻辑。
- [ ] 完美转发场景使用 `std::forward`。
