## 零基础详解：现代 C++ 的十个好习惯

### 一句话说清它是什么

现代 C++（C++11 之后）的目标是：**少写裸指针、少写循环、让编译器替你检查**。
下面十条是日常写得最多、收益最直接的实践。

### 十个习惯速览

| 习惯 | 替代的旧写法 | 收益 |
| --- | --- | --- |
| 用 `auto` 推导 | 手写复杂类型 | 简洁、不易写错 |
| 用范围 for | 下标循环 | 不易越界 |
| 用 `nullptr` | `NULL` 或 `0` | 类型安全 |
| 用 `enum class` | 裸 `enum` | 不污染作用域 |
| 用智能指针 | `new` 与 `delete` | 自动释放 |
| 用 `constexpr` | `#define` 常量 | 有类型、可调试 |
| 用结构化绑定 | 手动取 `.first` | 可读性高 |
| 用 `std::optional` | 特殊值表示「无」 | 语义明确 |
| 用 `std::string_view` | `const char*` | 零拷贝只读字符串 |
| 用 `override` | 靠命名巧合 | 编译器检查重写 |

### 一段代码展示八种新写法

```cpp
#include <iostream>
#include <memory>
#include <optional>
#include <string_view>
#include <vector>

enum class Status { Ok, Warn, Error };            // 1. enum class
constexpr double kPi = 3.14159;                   // 2. constexpr
struct Point { double x; double y; };

std::optional<Point> parsePoint(std::string_view text) {
    if (text.empty()) return std::nullopt;        // 3. 明确表达「没有值」
    return Point{1.0, 2.0};
}

int main() {
    auto items = std::vector{1, 2, 3, 4};         // 4. auto 与类模板推导
    int total = 0;
    for (const auto& n : items) total += n;       // 5. 范围 for

    auto ptr = std::make_unique<Point>(Point{1, 2});   // 6. 智能指针

    if (auto p = parsePoint("1,2")) {             // 7. if 带初始化
        auto [x, y] = *p;                         // 8. 结构化绑定
        std::cout << x << ',' << y << '\n';
    }

    const Status st = Status::Warn;
    if (st == Status::Warn) std::cout << "警告\n";
    std::cout << "π = " << kPi << "，合计 " << total << '\n';
}
```

### `std::optional` 与 `std::variant`

| 类型 | 表达 | 适用 |
| --- | --- | --- |
| `T` | 一定有值 | 常规返回 |
| `optional<T>` | 可能有，可能没有 | 查找、解析 |
| `variant<A,B>` | 是 A 或 B 之一 | 替代 union，类型安全 |

```cpp
#include <variant>

std::variant<int, std::string> v = 42;
if (std::holds_alternative<int>(v)) {
    std::cout << std::get<int>(v);
}
std::visit([](const auto& x) { std::cout << x; }, v);
```

### `string_view`：只读字符串的零拷贝参数

```cpp
void log(std::string_view msg);       // 不需要拷贝，也不关心谁拥有

log("字面量");                         // 不产生临时 std::string
std::string s = "abc";
log(s);
```

**注意**：`string_view` 不持有数据，不能返回指向已销毁数据的视图。

### 移动语义：把资源「搬」过去

```cpp
std::vector<int> makeData() {
    std::vector<int> v(1'000'000, 1);
    return v;                          // 编译器自动移动，不拷贝
}

std::vector<int> data = makeData();
std::vector<int> moved = std::move(data);   // 转移所有权
// 此后不要再读 data 的内容
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `std::move` 后继续用原对象 | 内容不确定 | 只把它当「已完成使命」 |
| 返回局部变量的 `string_view` | 悬垂引用 | 返回 `std::string` |
| `auto` 推导出意外类型 | 悄悄发生拷贝 | 需要引用时写 `const auto&` |
| `optional` 直接解引用 | 空值未定义行为 | 先判断或用 `value_or` |
| `enum` 不带 class | 名字冲突 | 用 `enum class` |
| `constexpr` 函数里做 IO | 编译不过 | 保持纯计算 |
| 头文件里写 `using namespace std;` | 污染使用方 | 写全限定名 |
| 盲目用新特性 | 团队编译器不支持 | 先确认标准版本 |

### 手把手练习：现代写法重写统计

```cpp
#include <algorithm>
#include <iostream>
#include <optional>
#include <span>
#include <vector>

std::optional<double> average(std::span<const int> data) {
    if (data.empty()) return std::nullopt;
    double sum = 0;
    for (int n : data) sum += n;
    return sum / static_cast<double>(data.size());
}

int main() {
    const std::vector<int> scores{88, 92, 79, 95};

    if (const auto avg = average(scores)) {
        std::cout << "平均分 " << *avg << '\n';
    } else {
        std::cout << "没有数据\n";
    }

    const auto [lo, hi] = std::ranges::minmax(scores);
    std::cout << "范围 " << lo << " ~ " << hi << '\n';
}
```

### 学完自测

- [ ] 能说出 `nullptr` 比 `NULL` 好在哪。
- [ ] 知道 `optional` 与返回特殊值相比的优势。
- [ ] 能说出 `string_view` 的使用禁忌。
- [ ] 能解释 `std::move` 之后为什么不该再用原对象。
- [ ] 能列出至少六条现代 C++ 习惯。
