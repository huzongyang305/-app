## 零基础详解：模板与泛型编程

### 一句话说清它是什么

模板是「让编译器替你生成代码的模具」：
你写一份逻辑，编译器按实际类型生成多份具体实现，所以既通用又快（零运行时开销）。

### 用生活比喻理解

| 概念 | 比喻 | 说明 |
| --- | --- | --- |
| 函数模板 | 可调模具 | 一份逻辑适配多种类型 |
| 类模板 | 通用容器图纸 | `vector<T>`、`map<K,V>` |
| 模板参数 | 模具的尺寸规格 | `T`、`N`、`typename` |
| 特化 | 特殊订单特殊处理 | 对特定类型给不同实现 |
| 概念（concepts） | 模具的使用条件 | 限定 T 必须具备什么能力 |

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
    std::cout << maxOf(3, 7) << '\n';               // T 推导为 int
    std::cout << maxOf(std::string("a"), std::string("b")) << '\n';
    printAll(std::vector{1, 2, 3});                 // C++17 类模板参数推导
}
```

**注意**：模板的定义通常要放在头文件里，因为编译器需要在实例化时看到完整实现。

### 类模板：写一个自己的容器

```cpp
#include <array>
#include <cstddef>

template <typename T, std::size_t N>
class FixedArray {
public:
    constexpr std::size_t size() const { return N; }
    T& operator[](std::size_t i) { return data_[i]; }
    const T& operator[](std::size_t i) const { return data_[i]; }

private:
    T data_[N]{};
};

FixedArray<int, 5> nums;
nums[0] = 1;
```

`std::array` 就是这个思路的工业级实现。

### 可变参数模板与折叠表达式

```cpp
template <typename... Args>
auto sum(Args... args) {
    return (args + ...);            // C++17 折叠表达式，一行搞定
}

std::cout << sum(1, 2, 3, 4);       // 10
std::cout << sum(1.5, 2.5);         // 4
```

### 概念（C++20）：让报错看得懂

```cpp
#include <concepts>

template <typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::same_as<T>;
};

template <Addable T>
T addTwice(T a, T b) { return a + b; }
```

传不支持的类型时，报错会明确指出「不满足 Addable」，而不是几百行模板栈。

| 约束写法 | 可读性 | 报错质量 |
| --- | --- | --- |
| 只用 `typename T` | 一般 | 很差 |
| `enable_if` 技巧 | 差 | 差 |
| `std::integral` 等标准概念 | 好 | 好 |
| 自定义 `concept` | 最好 | 最好 |

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 模板定义放 `.cpp` | 链接错误 | 放头文件或显式实例化 |
| 忘写 `typename` | 依赖名解析失败 | 模板内的嵌套类型前加 `typename` |
| 报错几百行 | 找不到真正原因 | 从最上面第一条错误看起 |
| 模板参数推导失败 | 提示没有匹配的函数 | 显式指定类型或加约束 |
| 过度使用模板 | 编译慢、难调试 | 能用普通函数就别模板 |
| 递归模板太深 | 编译期爆栈 | 用折叠表达式或循环 |
| 特化与主模板不一致 | 行为诡异 | 保持接口一致 |
| 头文件里用 `using namespace` | 污染使用方 | 写全限定名 |

### 手把手练习：泛型统计函数

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
    if (data.empty()) throw std::invalid_argument("数据不能为空");

    const auto [lo, hi] = std::minmax_element(data.begin(), data.end());
    const double avg =
        static_cast<double>(std::accumulate(data.begin(), data.end(), T{0})) /
        static_cast<double>(data.size());
    return {*lo, *hi, avg};
}

int main() {
    const auto s = analyze(std::vector{88, 92, 79, 95});
    std::cout << "最小 " << s.min << " 最大 " << s.max
              << " 平均 " << s.average << '\n';
}
```

### 学完自测

- [ ] 能解释模板为什么没有运行时开销。
- [ ] 知道模板定义为什么通常放头文件。
- [ ] 能写出一个带 `concept` 约束的模板函数。
- [ ] 能说出折叠表达式解决什么问题。
- [ ] 知道模板报错时应该从哪一条开始看。
