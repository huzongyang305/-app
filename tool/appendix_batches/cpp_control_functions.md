## 控制流速查

| 结构 | 写法 | 注意 |
| --- | --- | --- |
| `if / else` | 条件分支 | 条件必须是 `bool` |
| `switch` | 多等值分支 | 忘了 `break` 会穿透 |
| `for` | 计次循环 | 用 `size_t` 遍历时注意 `i >= 0` 恒真 |
| 范围 for | `for (const auto& x : v)` | 只读加 `const&`，修改加 `&` |
| `while` / `do...while` | 条件循环 | `do...while` 至少执行一次 |
| `break` / `continue` | 跳出 / 跳过 | 只影响最近一层循环 |
| `goto` | 跳转 | 仅用于跳出多层循环的少数场景 |

## 函数参数与返回速查

| 目的 | 写法 | 说明 |
| --- | --- | --- |
| 小类型只读 | `void f(int x)` | 复制成本低 |
| 大对象只读 | `void f(const std::string& s)` | 避免拷贝 |
| 需要修改实参 | `void f(std::string& s)` | 明确可写 |
| 需要转移所有权 | `void f(std::string s)` + `std::move` | 值传递 + 移动语义 |
| 返回大对象 | `std::vector<int> make()` | 依赖 RVO，不要 `std::move` 局部变量 |
| 可能失败 | `std::optional<T>` / `bool` + 出参 | 比抛异常更显式 |
| 不抛异常承诺 | `void f() noexcept` | 供容器与优化使用 |
| 默认参数 | `void f(int a, int b = 1)` | 默认值只能写在声明处 |

```cpp
#include <algorithm>
#include <cctype>
#include <string>
#include <vector>

// 只读大对象用 const 引用，避免拷贝
double average(const std::vector<int>& nums) {
    if (nums.empty()) return 0.0;
    long long sum = 0;
    for (int n : nums) sum += n;
    return static_cast<double>(sum) / nums.size();
}

// 就地修改传入对象
void trim(std::string& s) {
    const auto notSpace = [](unsigned char c) { return !std::isspace(c); };
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), notSpace));
}
```

## 常见错误对照表

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| `switch` 忘记 `break` | 穿透执行多个分支 | 每个分支结束加 `break` 或 `return` |
| 范围 for 里 `auto x` 修改 | 改的是副本 | 需要修改写 `auto& x` |
| 范围 for 遍历时修改容器 | 迭代器失效、崩溃 | 先收集要改的内容，循环结束后统一处理 |
| `size_t i` 写 `i >= 0` 作条件 | 死循环 | 无符号不会小于 0，改用有符号或改判断 |
| 大对象按值传参 | 多余的深拷贝 | 用 `const&` |
| 返回局部变量的引用 | 悬空引用 | 按值返回，或返回智能指针 |
| 默认参数写在定义处并重复 | 编译错误 | 只在声明里写一次 |
| 函数声明与定义签名不一致 | 链接错误 | 保持完全一致，开 `-Wall` 及早发现 |
| 忘记 `#include <algorithm>` | 找不到 `std::find_if` | 补头文件 |
| 在头文件定义非 inline 函数 | 多重定义 | 加 `inline`，或放源文件 |

## 自测清单

- [ ] 大对象参数一律用 `const&`，需要修改用 `&`。
- [ ] 范围 for 中只读用 `const auto&`，修改用 `auto&`。
- [ ] 不再用 `i >= 0` 作为无符号循环条件。
- [ ] 返回局部对象时直接 `return obj;`。
- [ ] 编译打开 `-Wall -Wextra` 并清零告警。
