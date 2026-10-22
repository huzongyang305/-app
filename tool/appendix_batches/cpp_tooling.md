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
