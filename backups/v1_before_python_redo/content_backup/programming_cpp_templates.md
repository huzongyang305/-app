# 模板与泛型编程

![C++ 模板编程的五个层次](images/diagram_cpp_templates.webp)

![模板与泛型编程](images/remaining_cpp_templates.webp)

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：60 分钟

## 本节知识框架

想象你有一个做饼干的**模具**。你只需要做一套模具（模板），就能用不同口味的面团（int、double、string）压出形状相同但口味不同的饼干。C++ 编译器会在编译期帮你「批量生产」这些代码——每种类型一份，零运行时开销。

但模具也有代价：每换一种面团，烤箱就要多烤一份（编译时间变长、代码体积变大）。如果面团不合适（类型不满足要求），报错信息可能长达几百行。C++20 的 Concepts 就像给模具加了「使用说明」，让报错变得清晰。

本课主线：**函数与类模板、特化、type traits、可变参数与 Concepts**。

学完这课你会：
- 写出自己的函数模板和类模板
- 理解模板特化和 type_traits 的作用
- 用 C++20 Concepts 给模板参数加约束，告别几百行报错

## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| template | C++ 声明模板的关键字，让函数或类按类型和值参数生成具体版本。就像饼干模具。 |
| 泛型 | 把类型作为参数复用同一套逻辑，同时让编译器保留类型检查。 |
| 特化 | 为特定类型提供更高效或更合适的实现。比如对 `bool` 类型单独处理输出 "true"/"false"。 |
| type_traits | C++ 标准库头文件 `<type_traits>`，用模板在编译期查询和变换类型属性。 |
| Concepts | C++20 的编译期约束：用命名要求限定模板参数，让报错指向真正不满足的条件。 |
| CRTP | 派生类作为模板参数传回基类，实现零开销的静态多态（接口复用）。 |

## 原理与运行机制

### 函数模板：一套逻辑，多种类型

函数模板就像一个「万能函数」——你写一份逻辑，编译器按实际类型生成多份具体实现。

```cpp
#include <iostream>

template <typename T>
T max_of(T a, T b) {
    return a > b ? a : b;
}

int main() {
    std::cout << max_of(3, 7);          // 推导 T = int，输出 7
    std::cout << max_of(3.5, 1.2);      // 推导 T = double，输出 3.5
    std::cout << max_of<int>(3, 7);     // 显式指定 T = int
}
```

编译器在编译期为每种类型生成一份代码，所以**零运行时开销**，但也可能让编译变慢、体积变大。

### 类模板：写一个自己的容器

```cpp
template <typename T, std::size_t N>
class Array {
public:
    T& operator[](std::size_t index) { return data_[index]; }
    constexpr std::size_t size() const { return N; }
private:
    T data_[N]{};
};

Array<int, 4> values;   // T = int, N = 4
```

`std::array` 就是这个思路的工业级实现。

### 模板特化：特殊类型特殊处理

```cpp
template <typename T>
struct Printer {
    static void print(const T& value) { std::cout << value; }
};

template <>                                    // 全特化
struct Printer<bool> {
    static void print(bool value) { std::cout << (value ? "true" : "false"); }
};

#include <type_traits>
static_assert(std::is_integral_v<int>);        // true
static_assert(!std::is_integral_v<double>);    // true
```

常见 traits：`is_integral`、`is_same`、`is_base_of`、`enable_if`。它们让模板根据类型属性选择不同实现。

### 可变参数模板与折叠表达式

```cpp
template <typename... Args>
void print_all(const Args&... args) {
    ((std::cout << args << ' '), ...);        // C++17 折叠表达式
}
```

### Concepts（C++20）：让报错看得懂

```cpp
#include <concepts>

template <typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::convertible_to<T>;
};

template <Addable T>
T add(T a, T b) { return a + b; }
```

传不支持的类型时，报错会明确指出「不满足 Addable」，而不是几百行模板栈。

### 静态多态与 CRTP

模板实现的是**编译期多态**（静态多态），虚函数是运行期多态。CRTP 让派生类作为模板参数传回基类，实现零开销的接口复用：

```cpp
template <typename Derived>
struct Comparable {
    bool operator!=(const Derived& other) const {
        return !(static_cast<const Derived&>(*this) == other);
    }
};
```

## 典型应用场景

- **写通用容器或算法**：类模板让你写一份逻辑适配多种类型。
- **编译期类型判断**：type_traits 让你在编译期查询类型属性。
- **约束模板参数**：Concepts 让报错信息从「几百行模板栈」变成一行「T 不满足 Addable」。
- **零开销抽象**：模板在编译期展开，运行时没有额外开销。

## 代码/协议/SQL 示例

### 函数模板与类型推导

```cpp
#include <iostream>
#include <string>
#include <vector>

template <typename T>
T maxOf(const T& a, const T& b) {
    return a > b ? a : b;
}

template <typename T>
void printAll(const std::vector<T>& items) {
    for (const auto& item : items) std::cout << item << ' ';
    std::cout << '\n';
}

int main() {
    std::cout << maxOf(3, 7) << '\n';
    std::cout << maxOf(std::string("a"), std::string("b")) << '\n';
    printAll(std::vector{1, 2, 3});
}
```

**注意**：模板的定义通常要放在头文件里，因为编译器需要在实例化时看到完整实现。

### 可变参数与折叠表达式

```cpp
template <typename... Args>
auto sum(Args... args) {
    return (args + ...);            // C++17 折叠表达式
}

std::cout << sum(1, 2, 3, 4);       // 10
std::cout << sum(1.5, 2.5);         // 4
```

### C++20 Concepts 实战

```cpp
#include <concepts>
#include <string>
#include <type_traits>

template <std::integral T>
T gcd(T a, T b) {
    while (b != 0) {
        T t = a % b;
        a = b;
        b = t;
    }
    return a;
}

template <typename T>
concept Printable = requires(const T& value, std::ostream& os) {
    { os << value } -> std::same_as<std::ostream&>;
};

template <Printable T>
void printAll(const std::vector<T>& items) {
    for (const auto& item : items) std::cout << item << '\n';
}
```

### 泛型统计函数练习

```cpp
#include <concepts>
#include <iostream>
#include <numeric>
#include <vector>

template <typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

template <Numeric T>
struct Stats {
    T min;
    T max;
    double average;
};

template <Numeric T>
Stats<T> analyze(const std::vector<T>& data) {
    if (data.empty()) throw std::invalid_argument("data cannot be empty");
    const auto [lo, hi] = std::minmax_element(data.begin(), data.end());
    const double avg =
        static_cast<double>(std::accumulate(data.begin(), data.end(), T{0})) /
        static_cast<double>(data.size());
    return {*lo, *hi, avg};
}

int main() {
    const auto s = analyze(std::vector{88, 92, 79, 95});
    std::cout << "min " << s.min << " max " << s.max
              << " avg " << s.average << '\n';
}
```

编译运行：`g++ -std=c++20 stats.cpp -o stats && ./stats`

## 时间/空间复杂度或性能分析

模板的性能特点：

- **运行时无开销**：模板在编译期展开，生成的代码和手写具体类型一样快。
- **编译时间增加**：每实例化一种类型，编译器就要多做一份工作。大量模板嵌套会让编译显著变慢。
- **代码体积增大**：每种类型生成一份代码，二进制体积可能变大。
- **优化建议**：把与类型无关的逻辑抽到非模板函数，减少实例化份数。

测量方法：固定输入跑一遍记录基线编译时间，再增加模板实例化的类型数量复测。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 模板定义放 `.cpp` | 链接错误 undefined reference | 放头文件或显式实例化 |
| 忘写 `typename` | 依赖名解析失败 | 模板内的嵌套类型前加 `typename` |
| 报错几百行 | 找不到真正原因 | 从最上面第一条错误看起 |
| 模板参数推导失败 | 提示没有匹配的函数 | 显式指定类型或加约束 |
| 过度使用模板 | 编译慢、难调试 | 能用普通函数就别模板 |
| 递归模板太深 | 编译期爆栈 | 用折叠表达式或循环 |
| 特化与主模板不一致 | 行为诡异 | 保持接口一致 |
| 头文件里用 `using namespace` | 污染使用方 | 写全限定名 |

## 与其他知识点的关系

- **先修**：《类与面向对象》——本课会用到 class、继承等概念。
- **后续**：《STL 容器与算法》——STL 的容器和算法全是模板实现的。
- **术语衔接**：本课的 `template`、`泛型`、`特化` 在 STL 课程中会继续使用。
- **关联**：《C++ Concepts 与 Ranges》——本课是 Concepts 入门，那课是深入。

## 自测题与参考答案

### 自测 1

模板为什么没有运行时开销？

**参考答案**：因为模板在编译期为每种类型生成一份具体代码，运行时执行的就是普通函数/类，没有额外的间接调用或类型擦除。

### 自测 2

模板定义为什么通常要放在头文件里？

**参考答案**：因为编译器在实例化模板时需要看到完整的定义。如果放在 .cpp 文件里，其他翻译单元看不到实现，会导致链接错误。

### 自测 3

Concepts 解决了什么问题？

**参考答案**：Concepts 给模板参数加了明确的约束。当传入不满足约束的类型时，报错信息会直接说「T 不满足 Addable」，而不是展开几百行模板实例化栈。

## 考点精讲

本课的题库有 6 道题，下面逐题讲解。

### 考点 1

- **题目**：围绕“模板与泛型编程”中的 template、泛型、特化，下列哪两项是本课强调的实践判断？

**正确项**：
- 学习 template 时要同时说明输入、输出和失败路径，不能只看正常流程
- 验证 泛型 时要固定版本并覆盖边界输入，结论才可复现

**讲解**：学习模板不能只跑通正常例子。学习 template 时要同时考虑正常流程和失败路径；验证泛型行为时要固定编译器版本、覆盖边界输入。

### 考点 2

**题目**：C++20 中用于给模板参数加约束的特性是？

**正确项**：Concepts

**讲解**：Concepts 是 C++20 引入的特性，用 `concept` 关键字定义一组类型要求，然后用它约束模板参数。比如 `template <std::integral T>` 限制 T 必须是整数类型。

### 考点 3

**题目**：模板的主要代价是？

**正确项**：编译时间变长、代码体积可能变大

**讲解**：模板在编译期为每种类型生成一份代码，所以类型越多，编译时间越长，二进制体积也可能越大。但运行时性能不受影响。

### 考点 4

**题目**：这段 `cpp` 代码对应 `模板与泛型编程` 的 `template`。课程要解决的是函数与类模板、特化、type traits、可变参数与 Concepts。关于代码内容，哪一项说法准确？

**正确项**：调用了 `max_of()`

**讲解**：本课的示例代码中出现了 `max_of()` 函数模板，展示了模板的类型推导和显式指定。

### 考点 5

**题目**：std::vector<int> 在编译过程中属于？

**正确项**：由类模板实例化出来的具体类型

**讲解**：`std::vector` 是一个类模板，`std::vector<int>` 是把 `int` 作为模板参数传入后，编译器生成的具体类型。就像用模具和特定面团做出了一块具体的饼干。

### 考点 6

**题目**：填空：补齐下面这段术语说明中的空缺。课程 `函数与类模板、特化、type traits、可变参数与 Concepts。`，这段说明是：`____`：C++ 声明模板的关键字，让函数或类按类型和值参数生成具体版本。空缺处应填哪个术语？

**正确项**：template

**讲解**：`template` 是 C++ 中声明模板的关键字。你在它后面写 `<typename T>` 或 `<int N>`，告诉编译器这里有个参数化的模具。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| template | C++ 声明模板的关键字，让函数或类按类型和值参数生成具体版本。 |
| 泛型 | 把类型作为参数复用同一套逻辑，同时保留类型检查。 |
| 特化 | 为特定类型提供更高效或更合适的实现。 |
| type_traits | 标准库头文件，用模板在编译期查询和变换类型属性。 |
| Concepts | C++20 的编译期约束，用命名要求限定模板参数。 |
| CRTP | 派生类作为模板参数传回基类，实现零开销的接口复用。 |

## 复习清单

- [ ] 能解释模板为什么没有运行时开销，以及它的编译期代价是什么。
- [ ] 能运行或推演本课的 max_of 和 analyze 示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践

| 参考资料 | 本课用途 |
| --- | --- |
| [C++ 模板](https://en.cppreference.com/w/cpp/language/templates) | 模板语法、推导规则与特化 |
| [cppreference C++ 语言](https://en.cppreference.com/w/cpp/language) | C++ 语言规则与语义 |
| [C++ 标准委员会](https://isocpp.org/) | 标准演进与提案动态 |

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：C++20 / GCC 13+ 或 Clang 17+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：template、泛型、特化、type_traits、Concepts、CRTP
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全
