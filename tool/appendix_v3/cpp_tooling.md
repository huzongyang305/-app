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
