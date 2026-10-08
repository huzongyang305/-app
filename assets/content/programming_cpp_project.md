# 实战：CMake 多文件项目

![CMake 多文件项目的组织方式](images/diagram_cpp_project.webp)

![实战：CMake 多文件项目](images/remaining_cpp_project.webp)

> 内容更新时间：2026-10-06 · 学习阶段：高级 · 预计用时：120 分钟

## 本节知识框架

**课程定位**：所属分类 `cpp`（C++），课程主题 `实战：CMake 多文件项目`，学习阶段 高级，建议用时 140 分钟。

本课主线：include/src 分层、静态库、CTest 与 sanitizer。

**学完本课应当能够**
- 说清 `ctest` 与 `实战` 的含义与区别，并各举一个正例和一个反例。
- 用本课示例验证 `CMake 目标` 的行为，记录输入、输出与失败条件。
- 遇到「头文件里 `using namespace std`」这类问题时，能说出触发条件与修复顺序。

### 从概念到验证的学习链条

1. `ctest`：先掌握 CI 中跑 `cmake --build` + `ctest` + sanitizer，再用它解释 `实战` 为什么会出现。
2. `实战`：先掌握 实战：CMake 多文件项目解决了什么问题，而不是只背术语，再用它解释 `CMake 目标` 为什么会出现。
3. `CMake 目标`：先掌握 用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位，再用它解释 `断言` 为什么会出现。
4. `断言`：先掌握 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位，再用它解释 本课示例的观察结果 为什么会出现。

**先修与衔接**：本课是「C++」分类的第 16 课。先修内容：《构建、调试与工程实践》。《构建、调试与工程实践》里的 `vcpkg.json`、`break main` 是本课的前提。相关或后续课程：《实战：C++ HTTP JSON 服务》。

### 完成判据

- **定义关**：不看正文也能说明 `ctest` 是 CI 中跑 `cmake --build` + `ctest` + sanitizer，并指出一个反例。
- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `实战：CMake 多文件项目`，而不是只背结论。
- **示例关**：能运行或推演 `实战：CMake 多文件项目` 的 `cpp` 示例，并说明一个真实出现的标识符或字面量。
- **证据关**：能指出 `实战：CMake 多文件项目` 示例里的 调用了 `mean()`，并说明它支持或反驳了本课的哪一条结论。
- **排错关**：能复现 头文件里 `using namespace std`，记录现象并按 写全限定名 修复。
- **迁移关**：能把 `实战`、`CMake`、`CTest`、`sanitizer` 放进一个与 `实战：CMake 多文件项目` 不同的项目场景，并保持输入与验证条件可追踪。
- **复盘关**：学完 `实战：CMake 多文件项目` 后，用一句话写下仍然不确定的结论，并列出下一次验证需要的输入、环境和成功判据。

### 复习清单

- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。
- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。
- [ ] 能完成一次自测，并把错题对照错误表定位原因。

## 核心概念定义

| 术语 | 操作性定义 | 常见边界与风险 |
| --- | --- | --- |
| ctest | CI 中跑 cmake --build + ctest + sanitizer。 | 只在「CI 中跑 cmake --build + ctest + sanitizer」这一前提下成立，换输入或换环境要重新验证。 |
| 实战 | 实战：CMake 多文件项目解决了什么问题，而不是只背术语。 | 只在「实战：CMake 多文件项目解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。 |
| CMake 目标 | 用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位。 | 不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。 |
| 断言 | 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位。 | 易错：断言被优化掉；正确做法是Debug 与 Release 都跑。 |

## 原理与运行机制

### 机制总览

**教材衔接：头文件与实现**

```cpp
// include/stats.h
#pragma once
#include <vector>

double mean(const std::vector<double>& values);
double median(std::vector<double> values);
double stddev(const std::vector<double>& values);
```

```cpp
// src/stats.cpp
#include "stats.h"
#include <algorithm>
#include <cmath>
#include <numeric>
#include <stdexcept>

double mean(const std::vector<double>& values) {
    if (values.empty()) throw std::invalid_argument("empty");
    return std::accumulate(values.begin(), values.end(), 0.0) / values.size();
}

double median(std::vector<double> values) {
    if (values.empty()) throw std::invalid_argument("empty");
    std::sort(values.begin(), values.end());
    const auto n = values.size();
    return n % 2 ? values[n / 2] : (values[n / 2 - 1] + values[n / 2]) / 2.0;
}

double stddev(const std::vector<double>& values) {
    const double m = mean(values);
    double sum = 0.0;
    for (double v : values) sum += (v - m) * (v - m);
    return std::sqrt(sum / values.size());
}
```

**教材衔接：工程习惯**

1. 编译警告全开并当作错误（`-Werror`）。
2. Debug 与 Release 分开构建目录。
3. 第三方依赖用 vcpkg/Conan 管理，锁定版本。
4. CI 中跑 `cmake --build` + `ctest` + sanitizer。

**教材衔接：目录结构速查**

```text
project/
├── CMakeLists.txt          # 顶层构建脚本
├── include/app/            # 对外头文件
│   └── calculator.h
├── src/
│   ├── calculator.cpp      # 实现
│   └── main.cpp            # 程序入口
├── tests/
│   └── calculator_test.cpp
├── third_party/            # 第三方依赖（或由包管理器管理）
└── build/                  # 构建产物（加入 .gitignore）
```

| 约定 | 说明 |
| --- | --- |
| 头文件对外、实现对内 | `include/` 暴露接口，`src/` 放细节 |
| 一个类一个文件对 | `foo.h` + `foo.cpp`，便于定位 |
| 入口只有一处 | `main.cpp` 只做参数解析与调用 |
| 测试与源码分离 | `tests/` 独立，接入 ctest |
| 构建目录不入库 | `build/` 写进 `.gitignore` |

**教材衔接：版本与时效**

- 标准版本会影响 实战 的写法与可用库，升级前先用现有工具链编译一次。
- 升级前确认 实战 的兼容范围，把不可回退的改动单独拆成一次提交。

### 升级检查清单

- 先固定当前版本，跑通全部示例与测验，再升级工具链。
- 一次只改一个版本条件，把 实战 相关的差异单独记成一条结论。
- 回归范围锁定 CMAKE_CXX_STANDARD 的默认行为，并确认弃用警告是否出现在构建输出里。
- 升级完成后更新本课「最后复核 / 下次复核」日期，并记录 实战 的版本变化。

**教材衔接：交付评审：评分表、决策记录与证据链**



### 三、「实战：CMake 多文件项目」的交付证据链

本课未给出可执行命令，用下面的最小证据集代替：


### 五、评审记录模板

| 记录项 | 填写要求 |
| --- | --- |
| 项目标识 | `cpp_project` |
| 本次范围 | 说明这一轮交付了「实战：CMake 多文件项目」的哪些部分 |
| 未完成项 | 列出与 实战 相关但本轮未做的内容 |
| 证据位置 | 指向 evidence/ 目录下的具体文件 |
| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |
| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |

### 机制拆解：每一步的输入、动作与输出

#### 1. `ctest`
- 输入：`实战`；本步把 CI 中跑 `cmake --build` + `ctest` + sanitizer 当作判断规则。
- 动作：围绕 `ctest` 保留中间状态，并记录它与 `实战` 的对应关系。
- 输出：`实战`，它可以被下一段代码、测试或记录继续使用。
- `ctest` 的失败条件：只在「CI 中跑 `cmake --build` + `ctest` + sanitizer」这一前提下成立，换输入或换环境要重新验证。

#### 2. `实战`
- 输入：`ctest`；本步把 实战：CMake 多文件项目解决了什么问题，而不是只背术语 当作判断规则。
- 动作：围绕 `实战` 保留中间状态，并记录它与 `CMake 目标` 的对应关系。
- 输出：`CMake 目标`，它可以被下一段代码、测试或记录继续使用。
- `实战` 的失败条件：只在「实战：CMake 多文件项目解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。

#### 3. `CMake 目标`
- 输入：`实战`；本步把 用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位 当作判断规则。
- 动作：围绕 `CMake 目标` 保留中间状态，并记录它与 `断言` 的对应关系。
- 输出：`断言`，它可以被下一段代码、测试或记录继续使用。
- `CMake 目标` 的失败条件：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

#### 4. `断言`
- 输入：`CMake 目标`；本步把 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位 当作判断规则。
- 动作：围绕 `断言` 保留中间状态，并记录它与 `mean` 的对应关系。
- 输出：`mean`，它可以被下一段代码、测试或记录继续使用。
- `断言` 的失败条件：当只在 Release 测时，会出现断言被优化掉。

### 示例中的可观察事实

1. 调用了 `mean()`；它对应的课程主题是 `实战：CMake 多文件项目`。
2. 调用了 `median()`；它对应的课程主题是 `实战：CMake 多文件项目`。
3. 调用了 `stddev()`；它对应的课程主题是 `实战：CMake 多文件项目`。
4. 调用了 `empty()`；它对应的课程主题是 `实战：CMake 多文件项目`。
5. 调用了 `invalid_argument()`；它对应的课程主题是 `实战：CMake 多文件项目`。
6. 调用了 `accumulate()`；它对应的课程主题是 `实战：CMake 多文件项目`。
7. 调用了 `begin()`；它对应的课程主题是 `实战：CMake 多文件项目`。
8. 调用了 `end()`；它对应的课程主题是 `实战：CMake 多文件项目`。

### 复现实验记录

- 环境：`实战：CMake 多文件项目` 使用 `cpp` 示例，固定 `实战`、`CMake`、`CTest`、`sanitizer` 作为第一组条件。
- 首轮输入：先确认 调用了 `mean()`，预测 `ctest` 会怎样变化。
- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。
- 单变量修改：只改变 `实战`，观察 `断言` 是否仍满足定义。
- 失败注入：复现 头文件里 `using namespace std`，确认现象是 污染使用方。
- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，这样复盘 `实战：CMake 多文件项目` 时才能区分概念错误与实现错误。

## 典型应用场景

**教材衔接：项目结构**

```text
project/
├── CMakeLists.txt
├── include/
│   └── stats.h
├── src/
│   ├── main.cpp
│   └── stats.cpp
└── tests/
    └── stats_test.cpp
```

约定：`include/` 放对外头文件，`src/` 放实现，`tests/` 放测试，避免头文件与源文件混在一起。

**教材衔接：零基础详解：C++ 项目实战骨架**

### 一句话说清它是什么

一个可交付的 C++ 项目要有：**CMake 构建、依赖管理、测试、静态检查、Sanitizer、CI**。
下面用一个「日志解析库」把这些串起来。

### 用生活比喻理解

| 工具 | 比喻 | 作用 |
| --- | --- | --- |
| CMake | 施工图 | 描述怎么编译与链接 |
| 预设 preset | 标准工法 | 团队用同一套参数 |
| 依赖管理 | 进货渠道 | vcpkg 或 Conan |
| 测试框架 | 验收员 | Catch2 或 GoogleTest |
| Sanitizer | 安检仪 | 发现越界、泄漏、数据竞争 |

### 目录结构

```text
logparser/
  CMakeLists.txt
  CMakePresets.json
  include/logparser/parser.hpp     对外头文件
  src/parser.cpp                   实现
  tests/parser_test.cpp
  benchmarks/parse_bench.cpp
  cmake/                           自定义 cmake 模块
```

**头文件与实现分离**：`include/` 暴露给使用方，`src/` 只放实现。

### 顶层 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.24)
project(logparser VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 警告即错误，从源头保证质量
add_library(logparser src/parser.cpp)
target_include_directories(logparser PUBLIC include)
target_compile_options(logparser PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic -Werror>)

# 测试
include(CTest)
if(BUILD_TESTING)
    find_package(Catch2 3 REQUIRED)
    add_executable(parser_test tests/parser_test.cpp)
    target_link_libraries(parser_test PRIVATE logparser Catch2::Catch2WithMain)
    include(CTest)
    include(Catch)
    catch_discover_tests(parser_test)
endif()
```

### CMakePresets.json：团队统一参数

```json
{
  "version": 6,
  "configurePresets": [
    {
      "name": "debug",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/debug",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "release",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/release",
      "cacheVariables": { "CMAKE_BUILD_TYPE": "Release" }
    },
    {
      "name": "asan",
      "inherits": "debug",
      "binaryDir": "${sourceDir}/build/asan",
      "cacheVariables": {
        "CMAKE_CXX_FLAGS": "-fsanitize=address,undefined -fno-omit-frame-pointer"
      }
    }
  ]
}
```

```bash
cmake --preset debug
cmake --build build/debug
ctest --test-dir build/debug --output-on-failure
```

### 依赖管理

```cmake
# 方式一：CMake 自带的 FetchContent（小项目够用）
include(FetchContent)
FetchContent_Declare(
    catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v3.7.0
)
FetchContent_MakeAvailable(catch2)

# 方式二：vcpkg 清单模式（推荐用于中大型项目）
# vcpkg.json 里声明依赖，CMake 用 CMAKE_TOOLCHAIN_FILE 指向 vcpkg
```

```json
{
  "name": "logparser",
  "version": "0.1.0",
  "dependencies": [
    "catch2",
    { "name": "fmt", "version>=": "11.0.2" }
  ]
}
```

### 测试：先测纯函数

```cpp
// tests/parser_test.cpp
#include <catch2/catch_test_macros.hpp>
#include "logparser/parser.hpp"

TEST_CASE("解析合法日志行", "[parser]") {
    const auto entry = logparser::parse("2026-01-01 10:00:00 ERROR 连接失败");
    REQUIRE(entry.has_value());
    CHECK(entry->level == logparser::Level::Error);
    CHECK(entry->message == "连接失败");
}

TEST_CASE("非法行返回空", "[parser]") {
    CHECK_FALSE(logparser::parse("这不是日志").has_value());
}

TEST_CASE("容忍首尾空格", "[parser]") {
    CHECK(logparser::parse("  2026-01-01 10:00:00 INFO 启动  ").has_value());
}
```

用 `std::optional` 表达「可能解析失败」，比返回特殊值更清楚。

### 三种 Sanitizer 各查什么

| Sanitizer | 检查 | 编译参数 |
| --- | --- | --- |
| AddressSanitizer | 越界、释放后使用、泄漏 | `-fsanitize=address` |
| UndefinedBehaviorSanitizer | 整数溢出、空指针、未对齐 | `-fsanitize=undefined` |
| ThreadSanitizer | 数据竞争 | `-fsanitize=thread` |

**注意**：ASan 与 TSan 不能同时开，要分成两个预设跑。

### CI 流水线

```yaml
name: cpp-ci
on: [push, pull_request]

jobs:
  build-and-test:
    strategy:
      matrix:
        preset: [debug, release, asan]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get update && sudo apt-get install -y ninja-build
      - run: cmake --preset ${{ matrix.preset }}
      - run: cmake --build build/${{ matrix.preset }} -j
      - run: ctest --test-dir build/${{ matrix.preset }} --output-on-failure

  format-check:
    runs-on: ubuntu-latest
    steps:
      - run: pip install clang-format
      - run: clang-format --dry-run --Werror src/*.cpp include/**/*.hpp
```

### 静态分析与格式化

```bash
clang-format -i src/*.cpp include/**/*.hpp     # 统一格式
clang-tidy src/parser.cpp -- -std=c++20 -Iinclude
cppcheck --enable=warning,performance src
```

把 `.clang-format` 与 `.clang-tidy` 提交到仓库，团队格式化结果才会一致。

### 新手最容易踩的八个坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| 头文件里 `using namespace std` | 污染使用方 | 写全限定名 |
| 目录结构混乱 | 找不到头文件 | `include/` 与 `src/` 分离 |
| 每次手工敲编译参数 | 结果不一致 | 用 CMakePresets |
| 不开警告 | 隐患积累 | `-Wall -Wextra -Werror` |
| 只在 Release 测 | 断言被优化掉 | Debug 与 Release 都跑 |
| 不跑 Sanitizer | 越界与泄漏漏检 | CI 加 asan 预设 |
| 依赖版本不固定 | 今天能编明天不行 | 固定 tag 或用 vcpkg 清单 |
| 忘记提交 `.clang-format` | 格式各写一套 | 提交配置文件 |

### 学完自测

- [ ] 能说出 `include/` 与 `src/` 分离的好处。
- [ ] 知道 CMakePresets 解决什么问题。
- [ ] 能说出三种 Sanitizer 各自查什么。
- [ ] 知道为什么 ASan 与 TSan 不能同时开。
- [ ] 能列出 CI 里至少要跑的三种配置。

**教材衔接：项目专属规格：实战：CMake 多文件项目**

### 核心场景

include/src 分层、静态库、CTest 与 sanitizer。 项目目标是把「实战、CMake、CTest、sanitizer、工程结构」落实为可运行、可测试、可回滚的交付物。



### 验收场景

1. 正常路径：最小输入得到预期输出，并留下日志与指标。
2. 边界路径：把 CMAKE_CXX_STANDARD 的输入推到上下限，确认返回结果可解释。
3. 失败路径：依赖超时或不可用时能快速失败、重试或降级。
4. 幂等路径：同一请求执行两次不会产生重复副作用。
5. 回滚路径：实战 回滚后数据一致，且能说明恢复时间和影响范围。

**教材衔接：项目交付物**

### 建议仓库结构

```text
src/
include/
tests/
CMakeLists.txt
README.md
```


### 验收数据

```json
{
  "project": "cpp_project",
  "scenario": "实战的正常路径",
  "input": {"case": "normal", "value": "CMAKE_CXX_STANDARD"},
  "expected": {"ok": true, "checks": ["实战可复现", "CMake有记录"]},
  "failure_case": {"case": "CMake越界或缺失", "error": "validation_error"},
  "idempotency_key": "cpp_project-001"
}
```

### 复盘模板

- **头文件里 `using namespace std`**：典型现象是污染使用方；正确做法是写全限定名。
- **目录结构混乱**：典型现象是找不到头文件；正确做法是`include/` 与 `src/` 分离。
- **每次手工敲编译参数**：典型现象是结果不一致；正确做法是用 CMakePresets。
- **不开警告**：典型现象是隐患积累；正确做法是`-Wall -Wextra -Werror`。

### 最小验证场景

- 准备：保留 `cpp` 示例的原始输入，先记录 `实战：CMake 多文件项目` 的基线输出和完整运行命令。
- 观察：先核对 调用了 `mean()`，再改变一个与 `ctest` 相关的条件。
- 判定：新结果与 `实战：CMake 多文件项目` 的基线不同不等于错误；只有当差异破坏了 `ctest` 的定义或错误表中的约束，才判定为失败。

### 选择与边界

- 使用 `ctest` 时，先满足它的定义：CI 中跑 `cmake --build` + `ctest` + sanitizer；只在「CI 中跑 `cmake --build` + `ctest` + sanitizer」这一前提下成立，换输入或换环境要重新验证。
- 使用 `实战` 时，先满足它的定义：实战：CMake 多文件项目解决了什么问题，而不是只背术语；只在「实战：CMake 多文件项目解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。
- 使用 `CMake 目标` 时，先满足它的定义：用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位；不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。
- 使用 `断言` 时，先满足它的定义：测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位；易错：断言被优化掉；正确做法是Debug 与 Release 都跑。

## 代码/协议/SQL 示例

### 最小可验证示例

**教材衔接：CMakeLists**

```cmake
cmake_minimum_required(VERSION 3.20)
project(stats LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(stats_core src/stats.cpp)
target_include_directories(stats_core PUBLIC include)
target_compile_options(stats_core PRIVATE -Wall -Wextra -Wpedantic)

add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE stats_core)

enable_testing()
add_executable(stats_test tests/stats_test.cpp)
target_link_libraries(stats_test PRIVATE stats_core)
add_test(NAME stats_test COMMAND stats_test)
```

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
ctest --test-dir build --output-on-failure
```

**教材衔接：测试与检查**

```cpp
// tests/stats_test.cpp
#include "stats.h"
#include <cassert>
#include <iostream>

int main() {
    assert(std::abs(mean({1, 2, 3}) - 2.0) < 1e-9);
    assert(std::abs(median({3, 1, 2}) - 2.0) < 1e-9);
    assert(std::abs(median({4, 1, 2, 3}) - 2.5) < 1e-9);
    std::cout << "all tests passed\n";
}
```

```bash
g++ -fsanitize=address,undefined -g ...    # 或给 CMake 加编译选项跑 sanitizer
clang-tidy src/*.cpp -- -Iinclude
```

**教材衔接：顶层 CMakeLists 参考**

```cmake
cmake_minimum_required(VERSION 3.20)
project(code_learn LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)      # 供 clangd / clang-tidy 使用

add_library(calc STATIC src/calculator.cpp)
target_include_directories(calc PUBLIC include)
target_compile_options(calc PRIVATE -Wall -Wextra -Werror)

add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE calc)

enable_testing()
add_executable(calc_test tests/calculator_test.cpp)
target_link_libraries(calc_test PRIVATE calc)
add_test(NAME calc_test COMMAND calc_test)
```

测试与 CI 速查：

| 目的 | 做法 |
| --- | --- |
| 单元测试框架 | GoogleTest、Catch2、doctest |
| 运行测试 | `ctest --test-dir build --output-on-failure` |
| 覆盖率 | `-fprofile-instr-generate -fcoverage-mapping` 或 gcov |
| 静态检查 | clang-tidy + `compile_commands.json` |
| 流水线步骤 | 配置 → 构建 → 测试 → 静态检查 → 打包 |

**教材衔接：验证命令与预期输出**

实战 的交付物要能用固定命令复现；下表是本项目的最低验证集：

| 阶段 | 命令 | 预期输出 |
| --- | --- | --- |
| 配置构建 | `cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug` | 生成 CMake 缓存且无错误 |
| 编译 | `cmake --build build --parallel` | 目标全部编译成功且无警告 |
| 运行测试 | `ctest --test-dir build --output-on-failure` | 所有 CTest 用例通过 |

### 验收证据

- [ ] 保存依赖安装和启动命令的完整输出。
- [ ] 测试覆盖 CMake 的核心规则，并包含一次可预期的失败。
- [ ] 重复执行 实战 的操作两次，确认没有重复写入或副作用。
- [ ] 记录一次失败状态码、错误日志和恢复步骤。
- [ ] 记录 CMAKE_CXX_STANDARD 的运行环境与复现命令，并补一段回滚说明。

### 回归与回滚

1. 先在可丢弃的目录或临时库里跑 实战，避免污染真实数据。
2. 修改一处逻辑后重跑全部验证命令，确认没有回归。
3. 若失败，回滚到上一个可运行版本并保留失败日志。
4. 定位原因后补一条自动化测试，再重新执行发布流程。
5. 把教训写入项目复盘或本课笔记，形成下一次的检查项。

**运行方式**：运行 `实战：CMake 多文件项目` 的示例时，用 `g++ -std=c++17 文件名.cpp -o demo` 编译后运行；先看编译器报错的第一条。

### 示例精读：先找证据，再改一个条件

1. 调用了 `mean()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
2. 调用了 `median()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
3. 调用了 `stddev()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
4. 调用了 `empty()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
5. 调用了 `invalid_argument()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
6. 调用了 `accumulate()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
7. 调用了 `begin()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
8. 调用了 `end()`；它出现在 `实战：CMake 多文件项目` 的示例中，阅读时先确认它前后各发生了什么。
- 在 `实战：CMake 多文件项目` 中与 `ctest` 对照：示例必须能支持 CI 中跑 `cmake --build` + `ctest` + sanitizer，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：CMake 多文件项目` 中与 `实战` 对照：示例必须能支持 实战：CMake 多文件项目解决了什么问题，而不是只背术语，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：CMake 多文件项目` 中与 `CMake 目标` 对照：示例必须能支持 用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位，否则说明这一段还缺少实现或验证步骤。
- 在 `实战：CMake 多文件项目` 中与 `断言` 对照：示例必须能支持 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位，否则说明这一段还缺少实现或验证步骤。

## 时间/空间复杂度或性能分析

**性能关注点（实战：CMake 多文件项目）**：编译优化与内存布局决定上限：记录构建时间、运行时间与峰值内存，并区分 Debug 与 Release。

**本课特有开销（实战：CMake 多文件项目 · 实战）**：小文件看元数据开销，大文件看吞吐，两者要分别测量。

**测量方法**：以 `实战：CMake 多文件项目` 的 `实战` 场景为对象，固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；两次结果的差值与波动范围才是结论依据。

### 需要控制的变量与记录项

- `实战：CMake 多文件项目` 的 `实战`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：CMake 多文件项目` 的 `CMake`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：CMake 多文件项目` 的 `CTest`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：CMake 多文件项目` 的 `sanitizer`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：CMake 多文件项目` 的 `工程结构`：固定它的版本、输入范围和资源上限，分别记录速度、内存与失败率的变化。
- `实战：CMake 多文件项目` 中 `ctest` 的边界：只在「CI 中跑 `cmake --build` + `ctest` + sanitizer」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `实战：CMake 多文件项目` 中 `实战` 的边界：只在「实战：CMake 多文件项目解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。达到边界时不要外推，必须重新测量。
- `实战：CMake 多文件项目` 中 `CMake 目标` 的边界：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。达到边界时不要外推，必须重新测量。
- `实战：CMake 多文件项目` 中 `断言` 的边界：易错：断言被优化掉；正确做法是Debug 与 Release 都跑。达到边界时不要外推，必须重新测量。
- `实战：CMake 多文件项目` 的代码证据：先验证 调用了 `mean()`，再记录该路径的输入规模与耗时；只看代码行数不能推出复杂度。

## 常见误区与易错点

| 容易写错的做法 | 实际现象 | 原因与正确做法 |
| --- | --- | --- |
| 头文件里 `using namespace std` | 污染使用方 | 写全限定名 |
| 目录结构混乱 | 找不到头文件 | `include/` 与 `src/` 分离 |
| 每次手工敲编译参数 | 结果不一致 | 用 CMakePresets |
| 不开警告 | 隐患积累 | `-Wall -Wextra -Werror` |
| 只在 Release 测 | 断言被优化掉 | Debug 与 Release 都跑 |
| 不跑 Sanitizer | 越界与泄漏漏检 | CI 加 asan 预设 |
| 依赖版本不固定 | 今天能编明天不行 | 固定 tag 或用 vcpkg 清单 |
| 忘记提交 `.clang-format` | 格式各写一套 | 提交配置文件 |
| 测试可执行文件找不到头文件 | 未声明 include 目录 | 用 `target_include_directories` |
| 修改头文件后没有重新编译 | 依赖未声明 | 让目标正确声明头文件目录 |
| `main.cpp` 里塞满业务逻辑 | 无法测试 | 逻辑抽到库，`main` 只做编排 |
| 头文件里 `using namespace std;` | 污染所有包含者 | 在源文件局部使用，或写全限定名 |
| 在头文件定义全局变量 | 多重定义 | 用 `inline` 或放源文件 + `extern` |
| 直接提交 `build/` | 仓库臃肿 | 加入 `.gitignore` |
| 依赖靠手工下载 | 环境不可复现 | 用 FetchContent / vcpkg / Conan |
| 只在本地跑测试 | 回归无人发现 | 接入 CI 并设为合并门禁 |
| 用 Debug 构建做性能测试 | 数据无意义 | 用 Release 并固定编译选项 |
| 头文件里 using namespace std | 污染所有包含者。 | 在源文件局部使用，或写全限定名。 |

### 现场 1：头文件里 `using namespace std`

**症状**：污染使用方。

**根因与修复**：写全限定名。

**自检**：在本课示例里复现「头文件里 `using namespace std`」，改成写全限定名后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 2：目录结构混乱

**症状**：找不到头文件。

**根因与修复**：`include/` 与 `src/` 分离。

**自检**：在本课示例里复现「目录结构混乱」，改成`include/` 与 `src/` 分离后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 3：每次手工敲编译参数

**症状**：结果不一致。

**根因与修复**：用 CMakePresets。

**自检**：在本课示例里复现「每次手工敲编译参数」，改成用 CMakePresets后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 4：不开警告

**症状**：隐患积累。

**根因与修复**：`-Wall -Wextra -Werror`。

**自检**：在本课示例里复现「不开警告」，改成`-Wall -Wextra -Werror`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 5：只在 Release 测

**症状**：断言被优化掉。

**根因与修复**：Debug 与 Release 都跑。

**自检**：在本课示例里复现「只在 Release 测」，改成Debug 与 Release 都跑后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 6：不跑 Sanitizer

**症状**：越界与泄漏漏检。

**根因与修复**：CI 加 asan 预设。

**自检**：在本课示例里复现「不跑 Sanitizer」，改成CI 加 asan 预设后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 7：依赖版本不固定

**症状**：今天能编明天不行。

**根因与修复**：固定 tag 或用 vcpkg 清单。

**自检**：在本课示例里复现「依赖版本不固定」，改成固定 tag 或用 vcpkg 清单后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 8：忘记提交 `.clang-format`

**症状**：格式各写一套。

**根因与修复**：提交配置文件。

**自检**：在本课示例里复现「忘记提交 `.clang-format`」，改成提交配置文件后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

### 现场 9：测试可执行文件找不到头文件

**症状**：未声明 include 目录。

**根因与修复**：用 `target_include_directories`。

**自检**：在本课示例里复现「测试可执行文件找不到头文件」，改成用 `target_include_directories`后重跑；如果症状消失且失败路径按预期变化，说明定位正确。

## 与其他知识点的关系

- **先修**：`构建、调试与工程实践`。本课默认这些内容已经掌握。
- **相关或后续**：`实战：C++ HTTP JSON 服务`。本课术语会在这些课程里继续使用。
- **术语归属**：`ctest`、`实战`、`CMake 目标` 的定义以本课「核心概念定义」为准，换到其他课程时先确认定义是否被改写。
- 同一分类的《构建、调试与工程实践》也涉及 `CMake`；两课衔接时先确认这个术语的定义是否一致。
- 同一分类的《实战：C++ HTTP JSON 服务》也涉及 `CMake`；两课衔接时先确认这个术语的定义是否一致。

### 先修与后续术语接口

- `构建、调试与工程实践`：共同关键词 `CMake`、`sanitizer`。
- `实战：C++ HTTP JSON 服务`：共同关键词 `CMake`。

### 容易混淆的相邻概念

- `ctest` 与 `实战`：前者强调 CI 中跑 `cmake --build` + `ctest` + sanitizer；后者强调 实战：CMake 多文件项目解决了什么问题，而不是只背术语。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `实战` 与 `CMake 目标`：前者强调 实战：CMake 多文件项目解决了什么问题，而不是只背术语；后者强调 用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。
- `CMake 目标` 与 `断言`：前者强调 用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位；后者强调 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位。判断时分别检查两条定义的适用范围，不要只看名称相似就互换。

## 自测题与参考答案

> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。

### 自测 1（概念复述）

不看正文，写出 `ctest` 的操作性定义，并说明它与 `实战` 的区别。

**参考答案**：CI 中跑 `cmake --build` + `ctest` + sanitizer。

`实战` 的定位是：实战：CMake 多文件项目解决了什么问题，而不是只背术语；两者的差别要从适用对象与失败模式上说明。

### 自测 2（排错）

本课错误表记录了「头文件里 `using namespace std`」这类做法。请写出它会出现的现象、根因，以及修复顺序。

**参考答案**：现象是污染使用方；正确做法是写全限定名。修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。

### 自测 3（动手验证）

运行本课的 `cpp` 示例，改动其中一个输入后重新运行，记录输出与错误信息。

**参考答案**：正常输入下 `cpp` 示例应当复现正文给出的结果；改动输入后，如果结果改变或报错，先核对它是否满足 `实战：CMake 多文件项目` 中`ctest` 的适用范围，再检查错误表里是否有同类现象。

### 自测 4（代码阅读）

阅读本课开头的 `cpp` 示例，说明它体现了`ctest` 的哪一条性质，并指出改动哪个输入会让这条性质不再成立。

**参考答案**：`ctest` 的定义是 CI 中跑 `cmake --build` + `ctest` + sanitizer，示例正是在实现这条定义。改动与 `ctest` 有关的一个输入后，如果结果不再符合 `实战：CMake 多文件项目` 的正文描述，就说明该性质只在当前前提成立。

### 自测 5（迁移）

把 `实战：CMake 多文件项目` 的方法迁移到自己的项目：围绕 `ctest` 写出一个与错误表同类的风险点，并说明触发条件和检验方式。

**参考答案**：例如「头文件里 using namespace std」，它会导致污染所有包含者；检验方式是按在源文件局部使用，或写全限定名改一处再复现，确认现象消失且没有引入新的失败分支。

### 自测 6（对比）

用一个表格对比 `ctest` 与 `实战`：各写一行适用场景、一行失败表现。

**参考答案**：`ctest` 的定义是CI 中跑 `cmake --build` + `ctest` + sanitizer；`实战` 的定义是实战：CMake 多文件项目解决了什么问题，而不是只背术语。两者的失败表现分别对应本课错误表里与本术语相关的行。

### 自测 7（排错顺序）

面对「头文件里 `using namespace std`」引发的问题，请把“复现 污染使用方 → 保留证据 → 写全限定名 → 回归验证”四步写成可执行的检查清单。

**参考答案**：第一步按污染使用方复现；第二步记录输入、版本与完整报错；第三步按写全限定名只改一处；第四步重跑并确认失败路径也按预期变化。

### 自测 8（边界判断）

针对 `断言`，分别写出“可以使用”的条件和“结论不再成立”的条件。

**参考答案**：易错：断言被优化掉；正确做法是Debug 与 Release 都跑。 同时要把 `断言` 的定义 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位 与实际输入逐项对照。

### 自测 9（机制重建）

不看正文，按输入、转换、输出、验证四段重建 `ctest` → `实战` → `CMake 目标` → `断言` 的作用链。

**参考答案**：起点是 `ctest` 的定义 CI 中跑 `cmake --build` + `ctest` + sanitizer；中间每一步都保留可观察状态；终点由 `断言` 检查，失败时回到错误表定位第一个偏离定义的步骤。

### 自测 10（综合排错）

在 `实战：CMake 多文件项目` 中，现象是 污染所有包含者。请围绕 头文件里 using namespace std 写出最小复现、关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。

**参考答案**：先复现 头文件里 using namespace std，记录输入与完整错误；再按 在源文件局部使用，或写全限定名 只改一处。回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。

### 自测 11（一分钟复述）

用每分钟约 200 字的速度复述 `实战：CMake 多文件项目`：先给主问题，再按顺序说出 `ctest`、`实战`、`CMake 目标`、`断言`，最后给一个失败案例。

**自评标准**：主问题必须对应 include/src 分层、静态库、CTest 与 sanitizer；每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，不能用“可能有风险”代替证据。

## 术语速查

| 术语 | 一句话说明 |
| --- | --- |
| `ctest` | CI 中跑 `cmake --build` + `ctest` + sanitizer。 |
| `实战` | 实战：CMake 多文件项目解决了什么问题，而不是只背术语。 |
| `CMake 目标` | 用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位。 |
| `断言` | 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位。 |

**术语关系**：`ctest`（CI 中跑 `cmake --build` + `ctest` + sanitizer） → `实战`（实战：CMake 多文件项目解决了什么问题） → `CMake 目标`（用 target 描述可执行文件、库以及它们之间的依赖） → `断言`（测试里用断言表达期望）。

## 考点精讲

`实战：CMake 多文件项目` 的题库有 6 道题，下面逐题给出题干、正确项与判断依据：先自己作答，再核对正确项，最后回到正文对应小节复核。

### 考点 1：第 1 题

- **题目**：围绕“实战：CMake 多文件项目”中的 实战、CMake、CTest，下列哪两项是本课强调的实践判断？
- **正确项**：学习 实战 时要同时说明输入、输出和失败路径，不能只看正常流程；验证 CMake 时要固定版本并覆盖边界输入，结论才可复现
- **判断依据**：这道题落在术语 `实战` 上：实战：CMake 多文件项目解决了什么问题，而不是只背术语。复习时把 `实战` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 2：第 2 题

- **题目**：这段 `cpp` 代码对应 `实战：CMake 多文件项目` 的 `ctest`。课程要解决的是include/src 分层、静态库、CTest 与 sanitizer。关于代码内容，哪一项说法准确？
- **正确项**：调用了 `begin()`
- **判断依据**：这道题落在术语 `ctest` 上：CI 中跑 `cmake --build` + `ctest` + sanitizer。复习时把 `ctest` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 3：第 3 题

- **题目**：在 CMake 项目中开启 AddressSanitizer 和 UndefinedBehaviorSanitizer，最合理的做法是？
- **正确项**：在 Debug/CI 构建中开启并链接运行时
- **判断依据**：这道题检验本课主问题：include/src 分层、静态库、CTest 与 sanitizer。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 4：第 4 题

- **题目**：CMake 中 target_link_libraries(app PRIVATE fmt) 的作用是？
- **正确项**：给 app 目标声明需要链接的库及其传递属性
- **判断依据**：这道题检验本课主问题：include/src 分层、静态库、CTest 与 sanitizer。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 5：第 5 题

- **题目**：把单元测试接入 CI 的主要价值是？
- **正确项**：每次提交自动验证
- **判断依据**：这道题检验本课主问题：include/src 分层、静态库、CTest 与 sanitizer。复习时先复述本课主问题，再举一个会让结论失效的输入。

### 考点 6：第 6 题

- **题目**：填空：补齐下面这段术语说明中的空缺。课程 `include/src 分层、静态库、CTest 与 sanitizer。`，这段说明是：测试里用`____`表达期望，失败时输出实际值与期望值，便于快速定位。空缺处应填哪个术语？
- **正确项**：断言
- **判断依据**：这道题落在术语 `断言` 上：测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位。复习时把 `断言` 的定义、适用边界和一个反例一起说清楚，再回到「核心概念定义」核对原文。

### 考点 7：`ctest`

- **要点**：CI 中跑 `cmake --build` + `ctest` + sanitizer。
- **ctest 的边界**：只在「CI 中跑 `cmake --build` + `ctest` + sanitizer」这一前提下成立，换输入或换环境要重新验证。

### 考点 8：`实战`

- **要点**：实战：CMake 多文件项目解决了什么问题，而不是只背术语。
- **实战 的边界**：只在「实战：CMake 多文件项目解决了什么问题，而不是只背术语」这一前提下成立，换输入或换环境要重新验证。

### 考点 9：`CMake 目标`

- **要点**：用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位。
- **CMake 目标 的边界**：不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。

### 考点 10：`断言`

- **要点**：测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位。
- **断言 的边界**：易错：断言被优化掉；正确做法是Debug 与 Release 都跑。

### 考点 11：排错——头文件里 `using namespace std`

- **现象**：污染使用方。
- **处理**：写全限定名。

### 考点 12：排错——目录结构混乱

- **现象**：找不到头文件。
- **处理**：`include/` 与 `src/` 分离。

### 考点 13：综合辨析——`ctest` 与 `断言`

- **辨析点**：`ctest` 的定义是 CI 中跑 `cmake --build` + `ctest` + sanitizer；`断言` 的定义是 测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位。
- **答题要求**：面对 `实战：CMake 多文件项目` 的题目，先判断描述的是 `ctest` 还是 `断言`，再归到对应定义，最后写出一个会让该定义失效的边界输入。

### 考点 14：排错评分点

- **现象分**：能写出 污染使用方，而不是只写“程序有错”。
- **证据分**：保留触发 头文件里 `using namespace std` 的输入、版本和错误原文。
- **修复分**：按 写全限定名 只改一处，并同时回归正常路径与边界路径。

## 内容元数据

- 内容版本：v2.0
- 最后更新：2026-10-06
- 学习阶段：高级
- 适用环境：C++20 / GCC 13+ 或 Clang 17+
；本课聚焦 实战。
- 内容来源：内置结构化课程与工程实践整理
- 相关主题：实战、CMake、CTest、sanitizer、工程结构
- 质量版本：P0 测验标准 + P1 覆盖扩展 + P2 体验补全

## 参考资料与复核

- 最后复核：2026-10-04
- 下次复核：2027-05-10
- 复核范围：版本兼容、API 行为、安全建议与工程实践
- 来源性质：官方文档、标准或权威教材；本课核对关键词：实战、CMake、CTest、sanitizer、工程结构。

| 参考资料 | 本课用途 |
| --- | --- |
| [CMake 文档](https://cmake.org/documentation/) | 跨平台构建与依赖管理 |
| [C++ 模板](https://en.cppreference.com/w/cpp/language/templates) | 模板、推导与泛型编程 |
| [cppreference 标准库](https://en.cppreference.com/w/cpp/standard_library) | 标准库组件索引 |

| [本课术语索引：实战：CMake 多文件项目](#核心概念定义) | 按本课输入、术语边界和错误表现逐项核对 |
> 「实战：CMake 多文件项目」的链接用于离线阅读后的延伸核对；App 不会自动联网。

<!-- p1-project-review:start -->