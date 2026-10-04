# Operations: Organize multi-file items with CMake

> Translation status: machine translation (lightweight zh-en model). Technical terms may need review; use the Chinese tutorial as the authoritative version.


I'm sorry.

> Content update time: 2026-10-03 Learning stage: Advanced

## Learning objectives

- It's not just a word that explains what the CMake multi-documentation project is about.
- The relationship between "real battles", "CMake," "CTest" and "sanitizer" is clear, with one example.
- It's a good way to put this subject back into the "C++" knowledge system, which shows how it borders on adjacent themes.
- It is possible to complete this course and check its results using acceptance standards.

> A summary of the sentence: include/src layer, static library, CTest and Sanitizer.

## Pre-knowledge

- The first course, Building, Debugging and Engineering Practice, was completed; if available it could be used for self-measurement.
- This course stage: Advanced. It is recommended to have a complete basis in the same direction, reading longer code, configuration or system design instructions.
- We'll start with a review: real battle, CMake, CTest.
- If you can't read it at a certain step, record the specific card points and then go back to them.


## Project structure

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

It's a deal. Put the file on the outside, put it on the inside, set it off and test it to avoid mixing with the source files.

## Header and Achievement

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

## CMakeLists

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

## Tests and inspections

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

## Engineering habits

1. Compile all warnings and treat them as errors ().
2. Build a directory separately from Release.
3. Third party relies on vcpkg/conan management, locking in.
4. CI runs `ctest`+sanitizer.

## It's the end of this class.
Multifile + CMake + Test + Sanitizer is the smallest skeleton of a modern C++ project; it is consolidated into templates and new items are used directly.

<!-- appendix:v1 -->

## Directory Structure Quick Check

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

|A promise.|Annotations|
| --- | --- |
|Header external, internal|Zero. Exposure, one. Put the details.|
|One file at a time.|0+1, easy to locate|
|There's only one entrance.|⟦0 only parsing and calling|
|Test Separated from Source|Zero independence, access to ctest|
|Build directory not in library|It's all right.|

## Top level CMakeList

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

Test and CI quick check:

|Purpose|Practice|
| --- | --- |
|Unit Test Framework| GoogleTest、Catch2、doctest |
|Run Test| `ctest --test-dir build --output-on-failure` |
|Coverage|⟦ or gcov|
|Static check| clang-tidy + `compile_commands.json` |
|Waterline Steps|Configure, build, test, static, pack.|

## Common Error Table

|phenomena|Reason|Treatment|
| --- | --- | --- |
|Could not close temporary folder: %s|Undeclared|Use Zero.|
|Synchronising "%s"|Dependence Undeclared|Let the target declare header directory|
|It's all about business.|Could not initialise Bonobo|Logically drawn to the library, but only organized.|
|It's in the front file.|Contaminator|Locally in source file, or write full name|
|Define global variables in header files|Multiple definitions|Use ⟦0 or release file+1|
|Directly.|The warehouse's swollen.|Add|
|Reliance on manual downloads|It's not gonna happen again.|Use FetchContent / vcpkg / Conan|
|Only local running tests|There's no sign of it.|Access to CI and set the merge door|
|Do a performance test with Debug|Data doesn't make sense.|Create options with Release|

## Self-Detected List

- [ ] The catalogue is divided into 0, 1 and 2.
- [ ] It's only organized and business logic can be tested in the library.
- [ ] CMake manages header files and options with a target command.
- [ Chuckles ] ctest can run a full-scale test.
- [ ] CI overwhelms construction, testing and static checks.

<!-- appendix:v3 -->

## Zero-basic details: C++ operational skeleton

### What is it?

One deliverable C++ project consists of:** CMake construction, relying management, testing, static inspection, Sanitizer, CI**.
Here's what we need to do with a log-referral.

### It's a life metaphor.

|Tools|A metaphor.|Role|
| --- | --- | --- |
| CMake |Construction|How to compile and link.|
|Preset|Standard Law|Team uses the same set of parameters|
|Reliance on management|Import channels|vcpkg or Conan|
|Test Frame|Receiving and Inspection Officer|Catch2 or GoogleTest|
| Sanitizer |Security|Discovery of cross-border, leakage and data competition|

### Contents structure

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

** Head file separated from implementation**: ⟦ exposure to user,  release only.

### Top CMakeLists.txt

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

### CMakePresets.json: Uniting Parameters

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

### Reliance on management

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

### Test: Pure function first

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

It's better to say "may have failed" than to return a special value.

### Three. What do you want to know?

| Sanitizer |Inspection|Compile parameters|
| --- | --- | --- |
| AddressSanitizer |Cross-border, post-release use, leakage| `-fsanitize=address` |
| UndefinedBehaviorSanitizer |Integer, empty pointer, unmatched.| `-fsanitize=undefined` |
| ThreadSanitizer |Data competition| `-fsanitize=thread` |

**Note: ASan cannot drive at the same time, split into two presets.

### C. Waterline

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

### Static Analysis and Formatting

```bash
clang-format -i src/*.cpp include/**/*.hpp     # 统一格式
clang-tidy src/parser.cpp -- -std=c++20 -Iinclude
cppcheck --enable=warning,performance src
```

Send `.clang-tidy` to the warehouse so that it can be formatted.

### The eight most easy pits for freshmen.

|The pit.|phenomena|The right thing to do.|
| --- | --- | --- |
|It's in the front file.|Contaminated User|Write Full Name|
|Catalog breakdown|No header found.|Zero and one.|
|Compute parameters manually each time|The results are not consistent.|CMakePresets|
|No warning.|There's something going on.| `-Wall -Wextra -Werror` |
|Release only|The claim is optimized.|Debug and Release both|
|Don't run, Sanitizer.|Cross-border and leak detection|CI plus asan preset|
|_Other Organiser|Not today, not tomorrow.|Fix tag or use vcpkg list|
|I forgot to submit it.|Write in each format|Submit Profile|

### Learn how to measure yourself.

- [ Laughs ] Can you tell me the benefits of separation?
- [ ] Know what CMakePresets solve.
- [ Chuckles ] Can you tell me what the Sanitizers are looking for?
- [ Chuckles ] Know why ASan and Tsan can't drive at the same time.
- [ ] Can list at least three configurations in the CI.

## Let's practice.

<!-- practice-diversified:v1 -->

> Focus of this course: Repeats, experiments and deliveries around "Performance, CMake, CTest" each result is subject to scrutiny.

Start with the minimum program to compile warnings, then verify memory and boundaries, and run it again in Sanitizer.

### Practice 1: Build mental models (10 minutes)

Join the program and answer in three or five words:

1. What's the problem with the CMake Multi-Documentation Project?
2. Without it, what concrete consequences would there be?
3. What's it got to do with CMake?

**Standard of acceptance: at least one keyword appears and a reverse example, boundary conditions or lapse scenario is written.

### Practice 2: A controlled experiment (20 minutes)

Select a minimum example from the text to do the following:

1. Forecasts the result of a modification of an parameter, input or step.
2. It's actually being implemented or progressively, and the results are going to be real.
3. If results differ from projections, the reasons for differences are stated.

**Receiving standard**: leave a five-step record of "Previously changing the predictions and causes".

### Practice 3: Delivery of a small result (30 minutes)

Write a program that can be compiled on its own, open ⟦ and make sure there is no warning.

Mission requests:

- The result must be checked, not just “I understand”.
- I'm not sure if it's true.
- Writes one question that is still uncertain and how it will be verified.

> Tip: Practice 1 and practice 2 when time is limited; Exercise 3 can be broken down twice.

<!-- scaffold:v1 -->

<!-- project-verification:v1 -->

## Validation command and expected output

The project code does not read only " Compilable " , but repeats the results by a fixed command.

|Phase|Command|Expected output|
| --- | --- | --- |
|Configure Build| `cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug` |Generate CMake Cache without Error|
|Compile| `cmake --build build --parallel` |All targets compiled successfully and without warning|
|Run Test| `ctest --test-dir build --output-on-failure` |All CTest pass.|

### Evidence of acceptance

- [ ] Save the complete output relying on installation and start-up orders.
- [ ] Run at least 3 tests containing an illegal input or failure path.
- [ ] Repeat the same operation twice and confirm that there are no duplicates or side effects.
- [ ] Record a failure code, wrong log and recovery steps.
- [ ] Provide an environmental version, start-up and rollback in README.

### Return and Roll

1. Start with an abandoned directory or temporary database to avoid contamination of real data.
2. Rerun all authentication orders after a logical change to confirm that they are not returned.
3. If you fail, roll back to the previous runable version and keep the failed log.
4. The reason for the location is supplemented by an automated test and re-execution process.
5. The lessons are included in the project ' s repertoire or in a note, which will form the next inspection.

<!-- p2-enrichment:v1 -->

## English Overview

**Title:** Project: CMake Layout

**Summary:** Layout, library target, CTest and sanitizers.

**Category:** C++  
**Level:** Advanced
**Key terms:** field, CMake, CTest, engineering structure

> The full tutorial is written in Chinese. This bilingual overview helps English readers identify the topic, scope and key terms before studying the detailed examples.

## Content metadata

- Content version: V2.0
- Final update: 2026-10-03
- Learning stage: advanced
- Applicable environment: C+20/GMC 13+ or Clang 17+
- Source: Internal structured curriculum and engineering practices
- Related themes: field operations, CMake, CTest, Sanitizer, engineering
- Quality: P0 Test +P1 Overwrite Extension + P2 Experience Completion

## Specifications for the project: field operations: CMake Multi-Documentation Project

### Core scene

Include/src Layer, Static Library, CTest and Sanitizer.The goal of the project is to translate "operational, CMake, CTest, Sanitizer and Project Structures" into operational, testable and rolling deliverables.

### Structures and data flows

```text
用户/输入 → 接口或命令 → 领域逻辑 → 存储/外部依赖 → 输出与监控
                         ↘ 失败分类 → 重试/补偿 → 回滚
```

### Minimum Data Model

|Object|Key Fields|Constraints|
| --- | --- | --- |
|Enter entity|Actual, time and source|Keys to verify, limit the length, etc.|
|Task entity|Status, priority, creation|It's legal, it can't be repeated|
|Result entity|Output, Error Code, Time|Sequencable. Errors.|
|Audit records|Operator, action, result, time|It's unmovable, searchable and dissensitive.|

### Receiving scenes

1. Normal path: The minimum input receives the expected output, leaving a log and an indicator.
2. Boundary path: Empty, maximum, duplicated data and super-long content are explicitly addressed.
3. Failed path: fast failure, retest or downgrade if you rely on excess time.
4. Paths, etc.: The execution of the same request will not have repeated side effects.
5. Rollback path: Backroll data are consistent and indicate recovery time and impact.

<!-- project-delivery:v1 -->

## Project delivery

### Suggested warehouse structure

```text
src/
include/
tests/
CMakeLists.txt
README.md
```

### Test Matrix

|Level|Overwrite|Minimum|Adoption of standards|
| --- | --- | ---: | --- |
|Unit Test|Field rules, boundaries and misclassification| 8 |It's normal. The border, the path to failure.|
|Integrated testing|Database, network, document or platform boundary| 3 |Use real boundaries and run again|
|End-to-end testing|Core User Path| 1 |Full run from input to output|
|Manually.|5 scenes listed in the document| 5 |Orders, output and conclusion records|

### Receiving and Inspection Data

```json
{
  "project": "cpp_project",
  "input": {"case": "normal", "value": 5},
  "expected": {"ok": true, "result": 5},
  "failure_case": {"value": -1, "error": "validation_error"},
  "idempotency_key": "demo-001"
}
```

### Duplicate Template

|Problem|Records|
| --- | --- |
|What was the original target?|I'll give you a description of the acceptable target.|
|What's going on?|Timeline, indicators and key logs|
|Which assumption was overturned?|Root causes and contributing factors|
|How do you roll back?|Steps, time-consuming and data validation|
|What's next?|Responsible persons, duration and certification|

> Project acceptance revolved around "activism, CMake, CTest": at least one normal path, one border entry, one failed recovery and one check.

<!-- full-english-guide:v1 -->

## Full English Study Guide

### Overview

**Project: CMake Layout** focuses on Layout, library target, CTest and sanitizers.

### Learning Outcomes

- Explain what **Project: CMake Layout** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **Project: CMake Layout**
- Relayed terms: CMake, CTest, Sanitizer
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.

<!-- bilingual-outline:v1 -->

## Bilingual Section Outline

|Chinese Section| English section |
| --- | --- |
|Learning objectives| Learning objectives |
|Pre-knowledge| Prerequisites |
|Project structure|Project structure|
|Header and Achievement|Header and Achievement|
| CMakeLists | CMakeLists |
|Tests and inspections|Testing and checking.|
|Engineering habits|Engineering habits|
|It's the end of this class.| Summary |
|Directory Structure Quick Check|Directory Structure Quick Check|
|Top level CMakeList|Top level CMakeList|

> The outline maps each Chinese section to the English title, which is used by Full Engineering.

