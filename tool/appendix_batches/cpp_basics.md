## 编译流程速查

| 阶段 | 输入 | 输出 | 常见问题 |
| --- | --- | --- | --- |
| 预处理 | `.cpp` + 头文件 | 展开后的源文件 | 宏定义错误、重复包含 |
| 编译 | 预处理结果 | 汇编代码 | 语法错误、类型错误 |
| 汇编 | 汇编代码 | 目标文件 `.o` | 少见 |
| 链接 | 多个 `.o` + 库 | 可执行文件 | `undefined reference`、重复定义 |

常用命令速查：

| 目的 | 命令 |
| --- | --- |
| 一步编译 | `g++ -std=c++20 -Wall -Wextra -O2 main.cpp -o app` |
| 只编译不链接 | `g++ -c main.cpp -o main.o` |
| 多文件链接 | `g++ main.o util.o -o app` |
| 带调试信息 | `g++ -g main.cpp -o app` |
| 预处理后查看 | `g++ -E main.cpp \| less` |
| 生成汇编 | `g++ -S main.cpp` |
| 链接库 | `g++ main.cpp -lm -lpthread` |
| 查看符号 | `nm -C app \| head` |
| 查看动态依赖 | `ldd app` |
| 反汇编 | `objdump -d -M intel app` |
| 静态检查 | `clang-tidy main.cpp -- -std=c++20` |
| 格式化 | `clang-format -i main.cpp` |

## 头文件与工程组织速查

```cpp
// widget.h：声明放头文件，用 include guard 或 #pragma once 防重复包含
#pragma once
#include <string>

class Widget {
public:
    explicit Widget(std::string name);
    void draw() const;

private:
    std::string name_;
};
```

```cpp
// widget.cpp：实现放源文件
#include "widget.h"
#include <iostream>

Widget::Widget(std::string name) : name_(std::move(name)) {}

void Widget::draw() const {
    std::cout << name_ << '\n';
}
```

| 约定 | 说明 |
| --- | --- |
| 声明与实现分离 | 头文件放声明，源文件放实现 |
| 头文件只包含必要内容 | 能用前置声明就少 `#include`，减少编译依赖 |
| 使用 `#pragma once` | 简单可靠，主流编译器都支持 |
| 命名空间 | 避免全局符号冲突，不使用 `using namespace std;` |
| 编译选项 | 开发期 `-Wall -Wextra -Werror -g`，发布期 `-O2` |

## 常见错误对照表

| 报错信息 | 含义 | 处理方式 |
| --- | --- | --- |
| `fatal error: xxx.h: No such file or directory` | 头文件路径不对 | 用 `-I` 指定包含目录 |
| `undefined reference to 'foo()'` | 声明有、实现缺失或没链接库 | 补实现或加库（注意库的顺序） |
| `multiple definition of 'x'` | 同一符号被多次定义 | 变量声明放头文件用 `extern`，定义放源文件 |
| `error: 'x' was not declared in this scope` | 未声明或未包含头文件 | 检查拼写、作用域与包含 |
| `expected ';' after ...` | 语法错误 | 看行号与上一行是否漏分号 |
| `redefinition of 'struct X'` | 头文件没防重复包含 | 加 `#pragma once` |
| `invalid conversion from 'const char*' to 'char*'` | 字符串字面量是只读 | 用 `const char*` 或 `std::string` |
| `warning: comparison of integer expressions of different signedness` | 有符号与无符号比较 | 统一类型，或用 `static_cast` 明确转换 |
| 程序崩溃但编译通过 | 运行时错误 | 用 `-g` + gdb，或 ASan 定位 |

## 自测清单

- [ ] 能说清「预处理、编译、汇编、链接」四个阶段。
- [ ] 会用 `-c` 分离编译，再统一链接。
- [ ] 知道 `undefined reference` 属于链接错误。
- [ ] 头文件用 `#pragma once`，声明与实现分离。
- [ ] 开发期打开 `-Wall -Wextra`，调试期加 `-g`。
