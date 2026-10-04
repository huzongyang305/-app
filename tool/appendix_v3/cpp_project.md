## 零基础详解：C++ 项目实战骨架

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
      - uses: actions/checkout@v4
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
