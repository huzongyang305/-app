# 代码块验证报告

生成时间：2026-10-06T14:47:55.071663

> 片段是课程里有意截取、无法独立编译的示例，不计入硬失败；
> 排错练习是课程里有意保留错误的代码，同样不计入硬失败；
> 告警多为多行 Shell 命令或依赖演示环境导致的结构提示，
> 硬失败为 0 表示所有可执行代码块都能通过验证或已明确标注为片段。

| 语言 | 通过 | 片段 | 排错练习 | 失败 |
| --- | ---: | ---: | ---: | ---: |
| `markdown | 1 | 0 | 0 | 0 |
| asm | 5 | 1 | 0 | 0 |
| awk | 1 | 0 | 0 | 0 |
| bash | 337 | 2 | 0 | 0 |
| c | 88 | 0 | 0 | 0 |
| cmake | 6 | 0 | 0 | 0 |
| cpp | 177 | 0 | 0 | 0 |
| cron | 1 | 0 | 0 | 0 |
| csharp | 157 | 0 | 0 | 0 |
| css | 7 | 0 | 0 | 0 |
| dart | 19 | 0 | 0 | 0 |
| dockerfile | 7 | 0 | 0 | 0 |
| gitignore | 1 | 0 | 0 | 0 |
| go | 127 | 1 | 6 | 0 |
| groovy | 1 | 0 | 0 | 0 |
| hcl | 1 | 0 | 0 | 0 |
| html | 13 | 0 | 0 | 0 |
| http | 7 | 0 | 0 | 0 |
| java | 166 | 1 | 7 | 0 |
| javascript | 190 | 0 | 6 | 0 |
| js | 8 | 0 | 0 | 0 |
| json | 112 | 0 | 0 | 0 |
| jsonc | 3 | 0 | 0 | 0 |
| jsx | 1 | 0 | 0 | 0 |
| kotlin | 70 | 0 | 6 | 0 |
| lua | 3 | 0 | 0 | 0 |
| markdown | 1 | 0 | 0 | 0 |
| nginx | 3 | 0 | 0 | 0 |
| powershell | 2 | 0 | 0 | 0 |
| properties | 5 | 0 | 0 | 0 |
| protobuf | 4 | 0 | 0 | 0 |
| python | 736 | 0 | 0 | 0 |
| rust | 111 | 1 | 0 | 0 |
| sql | 76 | 0 | 0 | 0 |
| swift | 65 | 0 | 0 | 0 |
| text | 1192 | 0 | 0 | 0 |
| toml | 4 | 0 | 0 | 0 |
| ts | 9 | 0 | 0 | 0 |
| tsx | 7 | 0 | 0 | 0 |
| typescript | 122 | 2 | 3 | 0 |
| verilog | 1 | 0 | 0 | 0 |
| xml | 14 | 0 | 0 | 0 |
| yaml | 36 | 2 | 0 | 0 |

## 片段与依赖提示

- cross_cli_args:100 java 已标注片段
- flutter_release:114 yaml 已标注片段
- fundamentals_assembly:159 asm 已标注片段
- go_cloud_native_security:249 go 已标注片段
- go_testing:273 yaml 已标注片段
- programming_rust_cli_project:213 rust 已标注片段
- programming_ts_narrowing_generics:222 typescript 已标注片段
- shell_ci_templates:100 bash 已标注片段
- shell_ci_templates:363 bash 已标注片段
- ts_type_challenges:125 typescript 已标注片段
- go_conditions:513 go 代码排错练习（有意保留错误）
- go_first_program:522 go 代码排错练习（有意保留错误）
- go_functions_intro:831 go 代码排错练习（有意保留错误）
- go_loops:527 go 代码排错练习（有意保留错误）
- go_variables_input:521 go 代码排错练习（有意保留错误）
- java_conditions:502 java 代码排错练习（有意保留错误）
- java_first_class:493 java 代码排错练习（有意保留错误）
- java_loops:505 java 代码排错练习（有意保留错误）
- java_methods_intro:505 java 代码排错练习（有意保留错误）
- java_variables_output:796 java 代码排错练习（有意保留错误）
- js_conditions_loops:792 javascript 代码排错练习（有意保留错误）
- js_console_start:489 javascript 代码排错练习（有意保留错误）
- js_functions_intro:780 javascript 代码排错练习（有意保留错误）
- js_variables_types_intro:790 javascript 代码排错练习（有意保留错误）
- kotlin_basics:532 kotlin 代码排错练习（有意保留错误）
- kotlin_conditions:501 kotlin 代码排错练习（有意保留错误）
- kotlin_first_program:498 kotlin 代码排错练习（有意保留错误）
- kotlin_functions_intro:504 kotlin 代码排错练习（有意保留错误）
- kotlin_loops:510 kotlin 代码排错练习（有意保留错误）
- kotlin_variables_null:501 kotlin 代码排错练习（有意保留错误）
- programming_go_basics:769 go 代码排错练习（有意保留错误）
- programming_java_control_methods:706 java 代码排错练习（有意保留错误）
- programming_java_types:673 java 代码排错练习（有意保留错误）
- programming_js_operators_control:649 javascript 代码排错练习（有意保留错误）
- programming_js_types:618 javascript 代码排错练习（有意保留错误）
- ts_basic_types:784 typescript 代码排错练习（有意保留错误）
- ts_first_types:468 typescript 代码排错练习（有意保留错误）
- ts_function_types:485 typescript 代码排错练习（有意保留错误）
- cross_collections:153 bash 结构不平衡
- cross_collections:267 bash 结构不平衡
- fundamentals_assembly:250 bash 结构不平衡
- go_pprof:161 bash 结构不平衡
- go_pprof:362 bash 结构不平衡
- programming_cpp_tooling:308 bash 结构不平衡
- programming_cpp_types:28 cpp 结构不平衡
- programming_cpp_types:122 cpp 结构不平衡
- programming_cpp_types:315 cpp 结构不平衡
- programming_shell_flow:193 bash 结构不平衡
- shell_json_yaml:55 bash 结构不平衡
- shell_json_yaml:221 bash 结构不平衡
- shell_json_yaml:259 bash 结构不平衡
- shell_ops_scripts:74 bash 结构不平衡
- shell_ops_scripts:232 bash 结构不平衡
- shell_security:171 bash 结构不平衡
- shell_security:272 bash 结构不平衡
- visual_concurrency_schedule:218 bash 结构不平衡
- visual_concurrency_schedule:310 bash 结构不平衡

## 失败明细

无
