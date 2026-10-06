# 构建、调试与工程实践

> 内容更新时间：2026-10-03

![C++ 工程工具链的五个环节](images/diagram_cpp_tooling.webp)

![构建、调试与工程实践](images/remaining_cpp_tooling.webp)

## 学习目标

- 能用自己的话解释构建、调试与工程实践解决了什么问题，而不是只背术语。
- 能说清 「CMake」、「Ninja」、「vcpkg」、「gdb」 之间的关系，并分别举出一个例子。
- 能把本课知识放回「C++」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：CMake/Ninja、vcpkg/conan、gdb、sanitizer 与单元测试。

## 前置知识

- 先完成上一课《现代 C++ 特性》；如果已经掌握，可以直接用本课练习自测。
- 本课阶段：进阶。建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。
- 开始前先复习：CMake、Ninja、vcpkg。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。

## 编译与构建系统

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

## 包管理

```bash
vcpkg install fmt spdlog            # 微软生态常用
conan install . --build=missing     # 另一种主流方案
```

团队中应固定依赖版本（`vcpkg.json` / `conanfile.txt`），避免「我这儿能编译」。

## 调试

```bash
g++ -g -O0 main.cpp -o main
gdb ./main
```

常用命令：`break main`、`run`、`next`、`step`、`print var`、`bt`（调用栈）。

崩溃时先看调用栈；段错误优先怀疑空指针、越界、悬垂指针、栈溢出。

## 动态分析工具

```bash
g++ -fsanitize=address,undefined -g main.cpp -o main    # AddressSanitizer + UBSan
g++ -fsanitize=thread -g main.cpp -o main               # ThreadSanitizer
valgrind --leak-check=full ./main
```

建议在 CI 中始终跑一遍 sanitizer 构建，很多内存与并发问题只有它能发现。

## 测试与静态检查

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

## 本课小结
工程化的关键是可复现：**CMake 统一构建、包管理器锁定依赖、sanitizer + 单测守住质量、clang-tidy 统一风格**。

## 编译器与告警速查

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

## 调试与诊断速查

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

## CMake 速查

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

## 常见错误对照表

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

## 自测清单

- [ ] 开发期开启 `-Wall -Wextra -Werror -g` 与 sanitizer。
- [ ] 会用 gdb 看栈与变量，会读 core dump。
- [ ] CMake 用 target 系列指令而非全局变量。
- [ ] ctest 已接入 CI 并覆盖核心用例。
- [ ] clang-format 与 clang-tidy 纳入流水线。

## 零基础详解：C++ 工具链全景

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

## 动手练习

> 本课练习重点：围绕「CMake、Ninja、vcpkg」完成复述、实验和交付，每个结果都要能被别人检查。

先开启警告编译最小程序，再验证内存与边界，最后用 Sanitizer 跑一遍。

### 练习 1：建立心智模型（10 分钟）

合上教程，用 3～5 句话回答：

1. 构建、调试与工程实践解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「Ninja」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：做一次可控实验（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：交付一个小结果（30 分钟）

写一个可独立编译的小程序，开启 `-Wall -Wextra`，确保没有警告。

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「CMake」和「Ninja」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。

## 可运行练习

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

- 改动点：只把CMake的输入换成空值、极值或错误输入，其余保持不变。
- 预测：先写下「构建、调试与工程实践」在改动后的输出或错误信息，再运行。
- 记录：对照改动前后的结果，指出差异出在哪一步。
- 验收：换回原条件能复现原结果，改动只影响CMake。

### 任务 3：迁移到自己的数据

用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。

## 故障现场

### 现场 1：本课的 CMake 常规用例通过，但边界用例失败

**症状**：在本课的练习或生产场景里出现“本课的 CMake 常规用例通过，但边界用例失败”。

**复现**：准备一组最小输入，只保留触发“本课的 CMake 常规用例通过，但边界用例失败”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“CMake 的前置条件与取值边界没有写进代码，默认值掩盖了空值和极值”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 CMake 常规用例通过，但边界用例失败”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 2：本课的 Ninja 结果在两次运行之间不一致

**症状**：在本课的练习或生产场景里出现“本课的 Ninja 结果在两次运行之间不一致”。

**复现**：准备一组最小输入，只保留触发“本课的 Ninja 结果在两次运行之间不一致”的必要条件，连续运行两次确认结果稳定。

**定位**：围绕“Ninja 依赖了当前版本、执行顺序或共享状态，单次运行无法暴露差异”检查调用链、输入数据和环境配置，先验证假设再改代码。

**预防**：把“本课的 Ninja 结果在两次运行之间不一致”写成一条自动化用例，并在本课的验收清单里保留对应检查项。

### 现场 3：本课的验证只在开发机通过

**症状**：在本课的练习或生产场景里出现“本课的验证只在开发机通过”。

**定位**：围绕“环境版本、配置和输入规模与目标环境不同，CMake 缺少可重复的验证记录”检查调用链、输入数据和环境配置，先验证假设再改代码。

## 版本与时效

- C++23 已在主流工具链落地，C++26 进入定稿阶段
- 升级前先统一编译器与标准库版本，再逐模块打开新标准

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 只改一个版本变量，记录编译、测试、性能与产物体积的变化。
- 重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。
- 升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。

## 本课复习清单

离开本课前，逐项确认：

- [ ] 不看解析，能说出「CMake 的定位是？」的判断依据。
- [ ] 不看解析，能说出「AddressSanitizer 能发现哪类问题？」的判断依据。
- [ ] 不看解析，能说出「用 gdb 调试时，编译需要加哪个选项？」的判断依据。
- [ ] 不看解析，能说出「clang-format 的典型用途是？」的判断依据。
- [ ] 不看解析，能说出「clang-tidy 与 AddressSanitizer 的区别是？」的判断依据。
- [ ] 不看解析，能说出的判断依据。
- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。
- [ ] 把本课最容易混淆的两个概念写成一句话对照。

| 复盘项 | 记录 |
| --- | --- |
| 已经能独立解释的考点 |  |
| 仍然说不清的概念 |  |
| 下一步验证动作 |  |

## 术语速查

| 术语 | 本课语境 |
| --- | --- |
| `vcpkg.json` | 团队中应固定依赖版本（`vcpkg.json` / `conanfile.txt`），避免「我这儿能编译」。 |
| `conanfile.txt` | 团队中应固定依赖版本（`vcpkg.json` / `conanfile.txt`），避免「我这儿能编译」。 |
| `break main` | 常用命令：`break main`、`run`、`next`、`step`、`print var`、`bt`（调用栈）。 |
| `run` | 常用命令：`break main`、`run`、`next`、`step`、`print var`、`bt`（调用栈）。 |
| `next` | 常用命令：`break main`、`run`、`next`、`step`、`print var`、`bt`（调用栈）。 |
| `step` | 常用命令：`break main`、`run`、`next`、`step`、`print var`、`bt`（调用栈）。 |

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
- **判断依据**：在「构建、调试与工程实践」里，结论应落在「按统一配置自动格式化代码风格」。把 .clang-format 提交到仓库并接入 CI，能省掉大量风格争论。在「构建、调试与工程实践」里，这道题要求区分概念与边界，「按统一配置自动格式化代码风格」只有在题干给出的前提下才成立，而「生成单元测试（仅部分场景成立）」、「检查内存越界」缺少同一组条件。

### 考点 5：概念判断·CMake

- **题目**：clang-tidy 与 AddressSanitizer 的区别是？
- **判断依据**：在「构建、调试与工程实践」里，clang-tidy 做静态检查（不运行程序）。静态检查 + 运行时检测互补，配合使用覆盖的问题面更广。回到「构建、调试与工程实践」的正文示例，用“clang-tidy 与 Addre”走一遍CMake、Ninja、vcpkg的完整流程，能复现的结论才可以保留。

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
- 最后更新：2026-10-03
- 学习阶段：进阶
- 适用环境：C++20 / GCC 13+ 或 Clang 17+
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：CMake、Ninja、vcpkg、gdb、sanitizer、Catch2
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-04-04
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；正文为离线教学重组

| 参考资料 | 本课用途 |
| --- | --- |
| [CMake 文档](https://cmake.org/documentation/) | 跨平台构建与依赖管理 |
| [Google C++ 风格指南](https://google.github.io/styleguide/cppguide.html) | 命名、接口与工程约束 |
| [C++ 模板](https://en.cppreference.com/w/cpp/language/templates) | 模板、推导与泛型编程 |

> 「构建、调试与工程实践」的链接用于离线阅读后的延伸核对；App 不会自动联网。
