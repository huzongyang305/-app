## 目录结构速查

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

## 顶层 CMakeLists 参考

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

## 常见错误对照表

| 现象 | 原因 | 处理方式 |
| --- | --- | --- |
| 测试可执行文件找不到头文件 | 未声明 include 目录 | 用 `target_include_directories` |
| 修改头文件后没有重新编译 | 依赖未声明 | 让目标正确声明头文件目录 |
| `main.cpp` 里塞满业务逻辑 | 无法测试 | 逻辑抽到库，`main` 只做编排 |
| 头文件里 `using namespace std;` | 污染所有包含者 | 在源文件局部使用，或写全限定名 |
| 在头文件定义全局变量 | 多重定义 | 用 `inline` 或放源文件 + `extern` |
| 直接提交 `build/` | 仓库臃肿 | 加入 `.gitignore` |
| 依赖靠手工下载 | 环境不可复现 | 用 FetchContent / vcpkg / Conan |
| 只在本地跑测试 | 回归无人发现 | 接入 CI 并设为合并门禁 |
| 用 Debug 构建做性能测试 | 数据无意义 | 用 Release 并固定编译选项 |

## 自测清单

- [ ] 目录分为 `include/`、`src/`、`tests/`。
- [ ] `main.cpp` 只做编排，业务逻辑在库里可被测试。
- [ ] CMake 用 target 指令管理头文件与选项。
- [ ] ctest 能一条命令跑完全部测试。
- [ ] CI 覆盖构建、测试与静态检查。
