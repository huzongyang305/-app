## 零基础详解：类型是「给内存规定一个解读方式」

### 一句话说清它是什么

计算机里只有 0 和 1。类型告诉编译器：**这段二进制要按整数读、按小数读、还是按字符读**，
同时决定它占多少字节、能做哪些运算。

### 常用类型速览

| 类型 | 典型大小 | 表示范围（约） | 常见用途 |
| --- | --- | --- | --- |
| `bool` | 1 字节 | `true` / `false` | 条件判断 |
| `char` | 1 字节 | -128 ~ 127 | 单个字符、原始字节 |
| `int` | 4 字节 | ±21 亿 | 一般计数 |
| `long long` | 8 字节 | ±9.2×10¹⁸ | 大整数、时间戳 |
| `float` | 4 字节 | 约 7 位有效数字 | 图形计算（省内存） |
| `double` | 8 字节 | 约 15 位有效数字 | 默认浮点选择 |
| `std::string` | 动态 | 不定 | 文本 |

用 `sizeof(类型)` 可以在自己机器上验证大小，别死记。

### 有无符号：最容易出事故的一对

```cpp
unsigned int a = 0;
a = a - 1;              // 不是 -1，而是 4294967295
```

原因是无符号数用「回绕」规则：减到 0 之后绕回最大值。
**经验法则：计数和下标用 `size_t`，需要负数的场景一律用有符号类型。**

### 浮点数的真相

```cpp
double x = 0.1 + 0.2;
std::cout << (x == 0.3);            // 0（false）
std::cout << std::setprecision(17) << x;   // 0.30000000000000004
```

浮点是二进制近似表示，所以：

- 永远不要用 `==` 比较两个浮点数。
- 判断相等要设误差：`std::abs(a - b) < 1e-9`。
- 涉及金额用整数分存储，或用定点数/高精度库。

### 四种类型转换：优先用 `static_cast`

| 写法 | 名称 | 使用场景 | 风险 |
| --- | --- | --- | --- |
| `static_cast<double>(n)` | 静态转换 | 数值互转，最常用 | 低 |
| `const_cast<T*>(p)` | 去常量 | 兼容旧接口 | 高，能改坏常量 |
| `reinterpret_cast<T*>(p)` | 重新解释 | 底层二进制处理 | 很高 |
| `dynamic_cast<T*>(p)` | 动态转换 | 多态类型安全向下转换 | 需要 RTTI |

```cpp
int total = 7, count = 2;
double avg = static_cast<double>(total) / count;   // 3.5，而不是 3
```

### `const` 与 `auto`：现代 C++ 的两个好习惯

```cpp
const double PI = 3.14159;        // 常量，编译期就防止被改
const int& ref = bigObject;       // 常量引用，避免拷贝又不允许修改
auto count = users.size();        // 让编译器推导类型，写起来更省事
```

`auto` 不是「动态类型」，推导在编译期完成，运行时没有额外开销。

### 新手最容易踩的七个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 整数除法丢小数 | `5 / 2 == 2` | 至少一侧转成 `double` |
| 有符号与无符号混用 | 比较结果反直觉 | 统一类型，或用 `std::ssize` |
| 整数溢出 | 结果变成负数 | 换 `long long`，或提前判断范围 |
| 未初始化变量 | 输出垃圾值 | 定义即赋初值 |
| 字符串用 `==` | 比较的是地址 | `std::string` 用 `==`，C 风格字符串用 `strcmp` |
| `char` 当整数用 | 输出成乱码字符 | 需要数值时先 `static_cast<int>` |
| 忘记包含头文件 | 找不到 `std::string` | 加上 `#include <string>` |

### 手把手练习：安全计算平均分

```cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> scores{88, 92, 79};
    if (scores.empty()) {
        std::cout << "没有成绩\n";
        return 0;
    }

    long long total = 0;
    for (int s : scores) total += s;

    double average = static_cast<double>(total) / scores.size();
    std::cout << "总分 " << total << "，平均 " << average << '\n';
    return 0;
}
```

注意 `total` 用 `long long` 防溢出，除法前先转 `double`——这两点就是类型意识。

### 学完自测

- [ ] 能说出 `int`、`long long`、`double` 大致占用多少字节。
- [ ] 能解释为什么 `0.1 + 0.2 != 0.3`。
- [ ] 知道整数除法丢小数的原因和修法。
- [ ] 能说出 `const` 和 `constexpr` 的区别。
- [ ] 遇到类型转换时，优先写 `static_cast`。
