# 构建、调试与工程实践

> 内容更新时间：2026-10-06 · 学习阶段：进阶 · 预计用时：55 分钟

![C++ 工程工具链的五个环节](images/diagram_cpp_tooling.webp)

![构建、调试与工程实践](images/remaining_cpp_tooling.webp)

## 本节知识框架

**课程定位**：所属分类为「C++」，课程主题为「构建、调试与工程实践」，学习阶段为「进阶」，建议用时 55 分钟。

**本课要解决的主问题**：CMake/Ninja、vcpkg/conan、gdb、sanitizer 与单元测试。

| 学习层次 | 要回答的问题 | 完成判据 |
| --- | --- | --- |
| 概念层 | 「构建、调试与工程实践」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |
| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |
| 应用层 | 什么场景适合使用「构建、调试与工程实践」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |
| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |
| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |

### 阅读路线

1. 先读「核心概念定义」，建立「CMake」等对象的精确定义。
2. 再读「原理与运行机制」，把定义串成可重复的过程。
3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。
4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。

**前置知识**：《现代 C++ 特性》

**学习位置**：本课位于《现代 C++ 特性》之后；如果前一课的自测不能通过，应先回补再继续。

**后续衔接**：下一课《实战：CMake 多文件项目》会继续使用本课术语，学完后建议立即完成一次自测。

**教材衔接：学习目标**

- 能用自己的话解释构建、调试与工程实践解决了什么问题，而不是只背术语。
- 能说清 「CMake」、「Ninja」、「vcpkg」、「gdb」 之间的关系，并分别举出一个例子。
- 能把 CMake 放回「构建、调试与工程实践」的知识体系，说明它和 Ninja 的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：CMake/Ninja、vcpkg/conan、gdb、sanitizer 与单元测试。

**教材衔接：前置知识**

- 先完成上一课《现代 C++ 特性》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先完成「现代 C++ 特性」，或确认自己能独立跑通正文里的 CMAKE_CXX_STANDARD_REQUIRED 示例。
- 开始前先复习：CMake、Ninja、vcpkg。
- 如果 编译与构建系统 这一步看不懂，先记录具体卡点，再用 CMAKE_CXX_STANDARD_REQUIRED 复现一遍。

**教材衔接：本课小结**

工程化的关键是可复现：**CMake 统一构建、包管理器锁定依赖、sanitizer + 单测守住质量、clang-tidy 统一风格**。

## 核心概念定义

> 阅读约定：本课先给「构建、调试与工程实践」相关术语的操作性定义与适用边界；正文里的口语化说法与定义冲突时，以定义和可复现示例为准。

| 术语 | 操作性定义 | 本课中的边界 |
| --- | --- | --- |
| vcpkg.json | 团队中应固定依赖版本（vcpkg.json / conanfile.txt），避免「我这儿能编译」。 | 仅在「构建、调试与工程实践」明确给出的输入、版本与资源条件下成立。 |
| break main | 常用命令：break main、run、next、step、print var、bt（调用栈）。 | 仅在「构建、调试与工程实践」明确给出的输入、版本与资源条件下成立。 |
| 编译数据库 | compile_commands.json 记录每个文件真实的编译命令，供 clangd 等工具做跳转与补全。 | 仅在「构建、调试与工程实践」明确给出的输入、版本与资源条件下成立。 |
| 调试符号 | 编译时加上 -g 生成符号信息，调试器才能把地址映射回函数名与行号。 | 仅在「构建、调试与工程实践」明确给出的输入、版本与资源条件下成立。 |

### 定义如何使用

在「构建、调试与工程实践」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。

## 原理与运行机制

### 机制总览

1. **建立输入**：把「vcpkg.json」按本课定义整理成可观察、可重复的输入条件。
2. **执行转换**：围绕「break main」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。
3. **产生输出**：得到「编译数据库」后，用正文示例或协议/SQL 结果核对输出是否符合预期。
4. **改变一个条件**：只替换一个边界条件或环境参数，观察「构建、调试与工程实践」的结论是否仍然成立。

| 阶段 | 关注对象 | 失败时应检查 |
| --- | --- | --- |
| 输入 | vcpkg.json | 类型、范围、编码、版本或前置状态是否满足定义。 |
| 处理 | break main | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |
| 输出 | 编译数据库 | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |

本课的机制结论要用「构建、调试与工程实践」自己的示例验证。「构建、调试与工程实践」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，不从相邻主题外推。

**教材衔接：编译器与告警速查**

| 选项 | 作用 |
| --- | --- |
| `-std=c++20` | 指定语言标准 |
| `-Wall -Wextra` | 打开常用告警 |
| `-Werror` | 告警视为错误（CI 推荐） |
| `-g` | 生成调试信息 |
| `-O0` / `-O2` / `-O3` | 优化级别 |
| `-fsanitize=address` | 内存错误检测 |
| `-fsanitize=undefined` | 未定义行为检测 |
| `-fno-omit-frame-pointer` | 保留栈帧，便于性能分析 |
| `-pthread` | 启用线程支持 |
| `-I path` | 头文件搜索路径 |
| `-L path` / `-lname` | 库路径与库名 |

**教材衔接：CMake 速查**

| 指令 | 作用 |
| --- | --- |
| `cmake_minimum_required(VERSION 3.20)` | 声明最低版本 |
| `project(app LANGUAGES CXX)` | 定义项目 |
| `add_executable(app src/main.cpp)` | 生成可执行目标 |
| `add_library(util STATIC src/util.cpp)` | 生成静态库 |
| `target_link_libraries(app PRIVATE util)` | 链接库 |
| `target_include_directories(app PRIVATE include)` | 头文件目录 |
| `target_compile_features(app PRIVATE cxx_std_20)` | 要求 C++20 |
| `target_compile_options(app PRIVATE -Wall -Wextra)` | 编译选项 |
| `set(CMAKE_BUILD_TYPE Release)` | 构建类型 |
| `enable_testing()` + `add_test(...)` | 注册测试 |
| `find_package(fmt REQUIRED)` | 查找依赖 |

常用命令：

| 目的 | 命令 |
| --- | --- |
| 配置（生成构建文件） | `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release` |
| 构建 | `cmake --build build -j` |
| 运行测试 | `ctest --test-dir build --output-on-failure` |
| 安装 | `cmake --install build --prefix dist` |
| 清理 | `rm -rf build` |

**教材衔接：版本与时效**

- C++23 已在主流工具链落地；升级 CMake 相关代码前先确认标准库实现情况。
- 升级「构建、调试与工程实践」涉及的依赖前，先用 CMAKE_CXX_STANDARD_REQUIRED 复现当前行为，再逐项核对版本说明与破坏性变更。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改 CMake 的版本变量，记录编译、测试与产物体积的变化。
- 回归范围锁定 CMAKE_CXX_STANDARD_REQUIRED 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级后把 CMAKE_CXX_STANDARD_REQUIRED 的实测版本写进「内容元数据」，再更新复核日期。

## 典型应用场景

| 场景 | 典型输入或前提 | 期望产物 |
| --- | --- | --- |
| 学习验证 | 使用本课最小示例和 CMake、Ninja | 能复现正文结论，并解释每一步。 |
| 工程落地 | 把「构建、调试与工程实践」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |
| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |

判断「构建、调试与工程实践」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。

**课程内置实验入口**：`sandbox:cpp`，用于动手验证《构建、调试与工程实践》的机制；实验结论不替代概念定义与复杂度分析。

## 代码/协议/SQL 示例

### 最小可验证示例

下面保留《构建、调试与工程实践》原文中的最小示例。先预测《构建、调试与工程实践》示例的输出，再按正文步骤运行或推演；示例依赖外部环境时，同时记录版本与输入。

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(code_learn LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(app src/main.cpp src/math_utils.cpp)
target_include_directories(app PRIVATE include)
target_compile_options(app PRIVATE -Wall -Wextra)

find_package(fmt CONFIG REQUIRED)
target_link_libraries(app PRIVATE fmt::fmt)
```

**教材衔接：编译与构建系统**

多文件项目不适合手写 g++ 命令，需要构建系统：

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(code_learn LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(app src/main.cpp src/math_utils.cpp)
target_include_directories(app PRIVATE include)
target_compile_options(app PRIVATE -Wall -Wextra)

find_package(fmt CONFIG REQUIRED)
target_link_libraries(app PRIVATE fmt::fmt)
```

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

常用工具对比：

| 工具 | 定位 |
| --- | --- |
| Make | 经典构建工具，手写规则繁琐 |
| CMake | 跨平台构建生成器，事实标准 |
| Ninja | 快速执行器，常与 CMake 搭配 |
| Bazel | 大型多语言仓库 |

**教材衔接：包管理**

```bash
vcpkg install fmt spdlog            # 微软生态常用
conan install . --build=missing     # 另一种主流方案
```

团队中应固定依赖版本（`vcpkg.json` / `conanfile.txt`），避免「我这儿能编译」。

**教材衔接：调试**

```bash
g++ -g -O0 main.cpp -o main
gdb ./main
```

常用命令：`break main`、`run`、`next`、`step`、`print var`、`bt`（调用栈）。

崩溃时先看调用栈；段错误优先怀疑空指针、越界、悬垂指针、栈溢出。

**教材衔接：动态分析工具**

```bash
g++ -fsanitize=address,undefined -g main.cpp -o main    # AddressSanitizer + UBSan
g++ -fsanitize=thread -g main.cpp -o main               # ThreadSanitizer
valgrind --leak-check=full ./main
```

建议在 CI 中始终跑一遍 sanitizer 构建，很多内存与并发问题只有它能发现。

**教材衔接：测试与静态检查**

```cpp
// 使用 Catch2 的示例
#define CATCH_CONFIG_MAIN
#include <catch2/catch.hpp>

int add(int a, int b) { return a + b; }

TEST_CASE("add works") {
    REQUIRE(add(2, 3) == 5);
}
```

静态分析：`clang-tidy`、`cppcheck`、编译器警告全开（`-Wall -Wextra -Wpedantic`）。

**教材衔接：调试与诊断速查**

| 目的 | 工具 / 命令 |
| --- | --- |
| 断点调试 | `gdb ./app`，`break file:line`、`run`、`bt`、`print var` |
| 查看崩溃栈 | `gdb -batch -ex run -ex bt ./app` |
| 查看 core dump | `coredumpctl gdb` 或 `gdb ./app core` |
| 反汇编 | `objdump -d -M intel app` |
| 查看符号 | `nm -C app` |
| 查看动态依赖 | `ldd app` |
| 静态检查 | `clang-tidy src/*.cpp -- -std=c++20` |
| 格式化 | `clang-format -i src/*.cpp` |
| 内存泄漏 | `valgrind --leak-check=full ./app` |
| 性能剖析 | `perf record ./app` + `perf report` |

```bash
# 推荐的开发期编译命令
g++ -std=c++20 -Wall -Wextra -Werror -g -O0 \
    -fsanitize=address,undefined \
    src/main.cpp src/util.cpp -o build/app

# 发布构建
g++ -std=c++20 -O2 -DNDEBUG src/*.cpp -o build/app
```

**教材衔接：零基础详解：C++ 工具链全景**

### 一句话说清它是什么

C++ 没有「官方全家桶」，工具链由几件独立工具拼成：
**编译器、构建系统、包管理、格式化、静态分析、调试器、Sanitizer**。

### 用生活比喻理解

| 工具 | 比喻 | 作用 |
| --- | --- | --- |
| 编译器 | 翻译官 | 把源码变成机器码 |
| CMake | 施工图 | 描述怎么编译与链接 |
| vcpkg / Conan | 进货渠道 | 管理第三方依赖 |
| clang-format | 排版员 | 统一代码格式 |
| clang-tidy | 审查员 | 静态发现坏味道 |
| gdb / lldb | 现场勘查 | 断点调试 |
| Sanitizer | 安检仪 | 运行时发现越界与竞争 |

### 三个主流编译器怎么选

| 编译器 | 平台 | 特点 |
| --- | --- | --- |
| GCC | Linux 通用 | 兼容性最好，报错偏保守 |
| Clang | 跨平台 | 报错友好，工具链完整 |
| MSVC | Windows | 与 Visual Studio 集成最好 |

**建议**：本地用 Clang 开发（报错清晰），CI 上三个都跑一遍（发现可移植性问题）。

```bash
# 查看编译器与标准支持
g++ --version
clang++ --version
echo | clang++ -std=c++20 -x c++ - -fsyntax-only && echo "支持 C++20"
```

### CMake：最通用的构建系统

```cmake
cmake_minimum_required(VERSION 3.24)
project(demo VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)      # 生成编译数据库，供 clangd 使用

add_library(core src/core.cpp)
target_include_directories(core PUBLIC include)

add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE core)

# 现代写法：按目标设置属性
target_compile_options(core PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic>)
```

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
ctest --test-dir build --output-on-failure
```

### 依赖管理：三种方式

| 方式 | 适合 | 优缺点 |
| --- | --- | --- |
| `FetchContent` | 少量依赖、小项目 | 简单直接，但每次都要下载 |
| vcpkg 清单模式 | 中大型项目 | 版本集中声明，跨平台好 |
| Conan | 复杂依赖与二进制包 | 功能强，学习成本高 |

```json
// vcpkg.json
{
  "name": "demo",
  "version": "0.1.0",
  "dependencies": ["fmt", "spdlog", "catch2"]
}
```

```bash
vcpkg install
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
```

### 格式化与静态分析

```bash
# 统一格式（团队必须提交 .clang-format）
clang-format -i src/*.cpp include/**/*.hpp
clang-format --dry-run --Werror src/*.cpp      # CI 里检查

# 静态分析（需要 compile_commands.json）
clang-tidy -p build src/core.cpp
cppcheck --enable=warning,performance --std=c++20 src

# 编译数据库供编辑器使用
ln -s build/compile_commands.json compile_commands.json
```

### 调试：三种手段配合用

| 手段 | 何时用 | 说明 |
| --- | --- | --- |
| 日志 | 生产与长时间运行 | 结构化输出，能开关 |
| 断点调试 | 本地复现 | gdb 或 IDE，看变量与调用栈 |
| Sanitizer | 崩溃与内存问题 | 越界、泄漏、竞争 |

```bash
# 带调试符号编译，才能看到变量与行号
cmake -S . -B build/debug -DCMAKE_BUILD_TYPE=Debug

# gdb 常用命令
gdb ./build/debug/app
(gdb) break main
(gdb) run
(gdb) bt          # 调用栈
(gdb) print x     # 查看变量
(gdb) continue
```

### 性能工具

```bash
perf record -g ./app && perf report      # Linux 采样分析
valgrind --leak-check=full ./app         # 内存泄漏（较慢）
hyperfine './app --mode fast' './app --mode slow'   # 基准对比
```

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| Debug 与 Release 行为不同 | 只在 Release 崩溃 | 两种配置都测 |
| 忘了 `-g` | 调试看不到变量 | Debug 配置加调试符号 |
| 手工敲编译命令 | 参数不一致 | 全部走 CMake |
| 依赖版本不固定 | 今天能编明天不行 | 固定 tag 或用清单 |
| 不提交 `.clang-format` | 格式各写一套 | 提交配置文件 |
| 只在 GCC 上测 | Clang 或 MSVC 编不过 | CI 跑三种编译器 |
| 忽略警告 | 隐患积累 | `-Wall -Wextra` 并逐步收敛 |
| 不用 compile_commands | 编辑器补全不准 | 开启 `CMAKE_EXPORT_COMPILE_COMMANDS` |

### 学完自测

- [ ] 能说出 GCC、Clang、MSVC 各自的特点。
- [ ] 知道 `CMAKE_EXPORT_COMPILE_COMMANDS` 有什么用处。
- [ ] 能说出三种依赖管理方式的取舍。
- [ ] 知道 Debug 与 Release 都要测的原因。
- [ ] 能说出 clang-format、clang-tidy、Sanitizer 各自的作用。

## 时间/空间复杂度或性能分析

**复杂度证据**：「构建、调试与工程实践」的现有材料没有给出渐近时间或空间复杂度的明确结论，本课只做定性检查，不补写未经验证的 $O$ 记号。

| 维度 | 本课关注点 | 判断依据 |
| --- | --- | --- |
| 时间/延迟 | 「构建、调试与工程实践」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |
| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |
| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |

评估「构建、调试与工程实践」时要区分“正确性成立”和“性能达标”两件事；材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。

## 常见误区与易错点

> 复核《构建、调试与工程实践》的易错点时，优先保留原文的错误表、故障现场与排错路径；每条修正都要能用本课示例复验。

| 易错点 | 常见表现 | 正确做法 |
| --- | --- | --- |
| 只背结论 | 能复述「构建、调试与工程实践」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |
| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |
| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |

**教材衔接：常见错误与排查**

| 现象 | 原因 | 处理方式 |
| --- | --- | --- |
| 编译通过但运行时崩溃 | 未定义行为 | 开启 ASan/UBSan 重新运行 |
| `undefined reference` | 缺源文件或库顺序不对 | 补文件；被依赖的库放在后面 |
| 改了代码但行为没变 | 构建缓存或没重新编译 | 清理 `build/` 重新配置 |
| 本地能编过、CI 失败 | 编译器或标准版本不同 | 固定工具链版本与 `-std` |
| 告警被忽略 | 潜在 bug 被掩盖 | CI 用 `-Werror` |
| 头文件改了却只有部分文件重编 | 依赖关系缺失 | 用 CMake 的 `target_include_directories` 正确声明 |
| `Debug` 版本性能极差 | 未开优化 | 性能测试用 `Release` |
| 静态库与动态库混用混乱 | 链接行为不一致 | 明确 `STATIC` / `SHARED` 并在文档里说明 |
| 直接把所有源文件写死在构建脚本 | 维护困难 | 用 CMake 目标管理 |

**教材衔接：故障现场**

### 现场 1：undefined reference

**症状**：在《构建、调试与工程实践》的复现场景中，缺源文件或库顺序不对。

**根因**：“缺源文件或库顺序不对”只是表层结果。向上追溯会落到“undefined reference”这一步，因为它省略了《构建、调试与工程实践》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《构建、调试与工程实践》的问题，补文件；被依赖的库放在后面。

**验证**：保留《构建、调试与工程实践》里触发“缺源文件或库顺序不对”的输入、版本和日志，按“补文件；被依赖的库放在后面”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

### 现场 2：改了代码但行为没变

**症状**：在《构建、调试与工程实践》的复现场景中，构建缓存或没重新编译。

**根因**：当出现“改了代码但行为没变”时，执行路径已经绕过了《构建、调试与工程实践》的关键约束，最终以“构建缓存或没重新编译”暴露出来；修复前必须先确认约束在哪里失效。

**修复**：针对《构建、调试与工程实践》的问题，清理 build/ 重新配置。

**验证**：先在《构建、调试与工程实践》中记录“改了代码但行为没变”留下的失败证据，再执行“清理 build/ 重新配置”并重放；确认错误路径变为明确结果，且修复没有掩盖同类故障。

### 现场 3：本地能编过、CI 失败

**症状**：在《构建、调试与工程实践》的复现场景中，编译器或标准版本不同。

**根因**：“编译器或标准版本不同”只是表层结果。向上追溯会落到“本地能编过、CI 失败”这一步，因为它省略了《构建、调试与工程实践》的约束，使实现行为和预期模型发生了偏离。

**修复**：针对《构建、调试与工程实践》的问题，固定工具链版本与 -std。

**验证**：保留《构建、调试与工程实践》里触发“编译器或标准版本不同”的输入、版本和日志，按“固定工具链版本与 -std”完成修改后原样重放；只有失败现象消失且相邻场景仍可解释，才保留改动。

## 与其他知识点的关系

| 关系 | 课程 | 为什么 |
| --- | --- | --- |
| 先修 | 《现代 C++ 特性》 | 本课会直接使用它的概念或操作前提。 |
| 关联 | 《实战：CMake 多文件项目》 | 用于横向比较或把本课结论迁移到相邻主题。 |
| 前置顺序 | 《现代 C++ 特性》 | 同分类中安排在本课之前，建议先完成其自测。 |
| 后续顺序 | 《实战：CMake 多文件项目》 | 同分类中安排在本课之后，会继续使用本课术语。 |

把「构建、调试与工程实践」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。

## 自测题与参考答案

> 先独立作答《构建、调试与工程实践》的自测题，再对照答案与解析；每处判断都要能在本课正文或示例中找到依据。

### 自测 1

这段 C++ 代码是「构建、调试与工程实践」的示例片段，下面哪一项描述与它一致？

```cpp
// 使用 Catch2 的示例
#define CATCH_CONFIG_MAIN
#include <catch2/catch.hpp>

int add(int a, int b) { return a + b; }

TEST_CASE("add works") {
    REQUIRE(add(2, 3) == 5);
}
```

A. 这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。
B. 这段代码包含条件分支，不同输入会走不同的执行路径。
C. 这段代码会读取外部输入，结果依赖传入的数据。
D. 这段代码会产生可观察的输出，运行后能看到结果。

**参考答案**：这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。

**解析**：题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「构建、调试与工程实践」里封装边界决定CMake从哪一步开始生效。这段代码出自「构建、调试与工程实践」的正文示例，围绕CMake、Ninja、vcpkg展开；把输入或边界换成空值、极值或失败情况后，结论要以「构建、调试与工程实践」的实际运行结果为准。这道题的关键在「构建、调试与工程实践」的CMake、Ninja、vcpkg：先确认题干“这段 C++ 代码是构建、调试与工程”问的是哪一步，再排除偷换前提的选项。

### 自测 2

围绕“构建、调试与工程实践”中的 CMake、Ninja、vcpkg，下列哪两项是本课强调的实践判断？

A. 学习 CMake 时要同时说明输入、输出和失败路径，不能只看正常流程
B. 只要 CMake 的常规示例通过，就可以跳过边界与异常路径
C. 验证 Ninja 时要固定版本并覆盖边界输入，结论才可复现
D. 把 Ninja 的单次运行结果当成所有版本和规模都成立

**参考答案**：学习 CMake 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 Ninja 时要固定版本并覆盖边界输入，结论才可复现

**解析**：本课把构建、调试与工程实践拆成概念、示例与故障现场三部分，因此判断 CMake 时必须同时交代输入、输出和失败路径，这使“学习 CMake 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在构建、调试与工程实践里，判断 Ninja 时要固定版本与边界输入，所以“验证 Ninja 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 自测 3

用 gdb 调试时，编译需要加哪个选项？

A. -Wall
B. -static
C. -O3
D. -g

**参考答案**：-g

**解析**：-g 生成调试符号，调试构建通常同时使用 -O0 -g。其他选项：-g 生成调试信息，gdb 才能显示源码行号。如果只凭关键词作答，很容易把「-Wall」、「-static」与「-g」混在一起；“编译需要加哪个选项”与「构建、调试与工程实践」的术语表相呼应，只有符合CMake、Ninja、vcpkg约束的“-g”才是正文支持的结论。

**教材衔接：复习与自测**

- [ ] 开发期开启 `-Wall -Wextra -Werror -g` 与 sanitizer。
- [ ] 会用 gdb 看栈与变量，会读 core dump。
- [ ] CMake 用 target 系列指令而非全局变量。
- [ ] ctest 已接入 CI 并覆盖核心用例。
- [ ] clang-format 与 clang-tidy 纳入流水线。

**教材衔接：动手练习**

> 本课练习重点：围绕「CMake、Ninja、vcpkg」完成复述、实验和交付，每个结果都要能被别人检查。

先开启警告编译 CMake 的最小程序，再验证内存与边界，最后用 Sanitizer 复查。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 构建、调试与工程实践解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Ninja」是什么关系？

验收标准：说明 CMake 与 Ninja 的分工，并写出一个失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：先在「编译与构建系统」里找一个可运行的最小输入，再按五步法记录CMake的影响；预测与结果不一致时补写被忽略的前提。

### 练习 3：交付一个小结果（30 分钟）

把 CMAKE_CXX_STANDARD_REQUIRED 抽成一个单文件示例，在开启警告的编译选项下构建。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「CMake」和「Ninja」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

**教材衔接：可运行练习**

### 任务 1：先跑通，再解释

```bash
# 查看编译器与标准支持
g++ --version
clang++ --version
echo | clang++ -std=c++20 -x c++ - -fsyntax-only && echo "支持 C++20"
```

**预期输出**：支持 C++20

### 任务 2：只改一个条件

把「构建、调试与工程实践」的最小示例复制一份，只改一个条件再跑一次：

- 改动点：把 Ninja 换成边界值，其他输入保持原样。
- 预测：先写下「构建、调试与工程实践」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响CMake。

### 任务 3：迁移到自己的数据

把 CMAKE_CXX_STANDARD_REQUIRED 换成你自己的输入，先保持步骤不变，再比较输出差异。

**教材衔接：本课复习清单**

离开本课前，逐项确认：

- [ ] 不看解析，能说出「CMake 的定位是？」的判断依据。
- [ ] 不看解析，能说出「AddressSanitizer 能发现哪类问题？」的判断依据。
- [ ] 不看解析，能说出「用 gdb 调试时，编译需要加哪个选项？」的判断依据。
- [ ] 不看解析，能说出「clang-format 的典型用途是？」的判断依据。
- [ ] 不看解析，能说出「clang-tidy 与 AddressSanitizer 的区别是？」的判断依据。
- [ ] 跑通「构建、调试与工程实践」的最小示例，并记录一次失败输入的处理方式。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

---

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `vcpkg.json` | 团队中应固定依赖版本（`vcpkg.json` / `conanfile.txt`），避免「我这儿能编译」。 |
| `break main` | 常用命令：`break main`、`run`、`next`、`step`、`print var`、`bt`（调用栈）。 |
| `编译数据库` | compile_commands.json 记录每个文件真实的编译命令，供 clangd 等工具做跳转与补全。 |
| `调试符号` | 编译时加上 -g 生成符号信息，调试器才能把地址映射回函数名与行号。 |

## 考点精讲

### 考点 1：代码补全·CMake

- **题目**：这段 C++ 代码是「构建、调试与工程实践」的示例片段，下面哪一项描述与它一致？
- **判断依据**：题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，在「构建、调试与工程实践」里封装边界决定CMake从哪一步开始生效。这段代码出自「构建、调试与工程实践」的正文示例，围绕CMake、Ninja、vcpkg展开；把输入或边界换成空值、极值或失败情况后，结论要以「构建、调试与工程实践」的实际运行结果为准。这道题的关键在「构建、调试与工程实践」的CMake、Ninja、vcpkg：先确认题干“这段 C++ 代码是构建、调试与工程”问的是哪一步，再排除偷换前提的选项。

### 考点 2：多选辨析·CMake

- **题目**：围绕“构建、调试与工程实践”中的 CMake、Ninja、vcpkg，下列哪两项是本课强调的实践判断？
- **判断依据**：本课把构建、调试与工程实践拆成概念、示例与故障现场三部分，因此判断 CMake 时必须同时交代输入、输出和失败路径，这使“学习 CMake 时要同时说明输入、输出和失败路径，不能只看正常流程”成立。在构建、调试与工程实践里，判断 Ninja 时要固定版本与边界输入，所以“验证 Ninja 时要固定版本并覆盖边界输入，结论才可复现”才可复现。

### 考点 3：概念判断·CMake

- **题目**：用 gdb 调试时，编译需要加哪个选项？
- **判断依据**：-g 生成调试符号，调试构建通常同时使用 -O0 -g。其他选项：-g 生成调试信息，gdb 才能显示源码行号。如果只凭关键词作答，很容易把「-Wall」、「-static」与「-g」混在一起；“编译需要加哪个选项”与「构建、调试与工程实践」的术语表相呼应，只有符合CMake、Ninja、vcpkg约束的“-g”才是正文支持的结论。

### 考点 4：概念判断·CMake

- **题目**：clang-format 的典型用途是？
- **判断依据**：在「构建、调试与工程实践」里，结论应落在「按统一配置自动格式化代码风格」。把 .clang-format 提交到仓库并接入 CI，能省掉大量风格争论。在「构建、调试与工程实践」里，这道题要求区分概念与边界，「按统一配置自动格式化代码风格」只有在题干给出的前提下才成立，而「生成单元测试」、「检查内存越界」缺少同一组条件。

### 考点 5：概念判断·CMake

- **题目**：clang-tidy 与 AddressSanitizer 的区别是？
- **判断依据**：在「构建、调试与工程实践」里，clang-tidy 做静态检查。静态检查 + 运行时检测互补，配合使用覆盖的问题面更广。回到「构建、调试与工程实践」的正文示例，用“clang-tidy 与 Addre”走一遍CMake、Ninja、vcpkg的完整流程，能复现的结论才可以保留。

### 考点 6：填空·____(VERSION 3.20)

- **题目**：补全代码：「构建、调试与工程实践」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。 `____(VERSION 3.20)`
- **判断依据**：空格应填写「cmake_minimum_required」。(VERSION 3.20) 限定的语境来判断。「构建、调试与工程实践」要求先交代CMake、Ninja、vcpkg的前提再下结论，所以“cmakeminimumrequired”只在题干“构建、调试与工程实践示例中”给定的条件下成立。

## English Overview

**Title:** Build & Tooling

**Summary:** CMake, package managers, gdb, sanitizers and testing.

**Category:** C++
**Level:** 进阶
**Key terms:** CMake, Ninja, vcpkg, gdb, sanitizer, Catch2

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：进阶
- 适用环境：C++20 / GCC 13+ 或 Clang 17+
；本课聚焦 CMake。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：CMake、Ninja、vcpkg、gdb、sanitizer、Catch2
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [CMake 文档](https://cmake.org/documentation/) | 跨平台构建与依赖管理 |
| [Google C++ 风格指南](https://google.github.io/styleguide/cppguide.html) | 命名、接口与工程约束 |
| [C++ 模板](https://en.cppreference.com/w/cpp/language/templates) | 模板、推导与泛型编程 |

> 「构建、调试与工程实践」的链接用于离线阅读后的延伸核对；App 不会自动联网。
