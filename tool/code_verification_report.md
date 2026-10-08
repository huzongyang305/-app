# 代码块验证报告

生成时间：2026-10-08T17:51:33.381506

> 片段是课程里有意截取、无法独立编译的示例，不计入硬失败；
> 排错练习是课程里有意保留错误的代码，同样不计入硬失败；
> 告警多为多行 Shell 命令或依赖演示环境导致的结构提示，
> 硬失败为 0 表示所有可执行代码块都能通过验证或已明确标注为片段。

| 语言 | 通过 | 片段 | 排错练习 | 失败 |
| --- | ---: | ---: | ---: | ---: |
| `markdown | 1 | 0 | 0 | 0 |
| asm | 8 | 2 | 0 | 0 |
| awk | 1 | 0 | 0 | 0 |
| bash | 395 | 2 | 0 | 0 |
| c | 102 | 0 | 0 | 0 |
| cmake | 7 | 0 | 0 | 0 |
| cpp | 181 | 0 | 0 | 0 |
| cron | 1 | 0 | 0 | 0 |
| csharp | 163 | 0 | 0 | 0 |
| css | 18 | 0 | 0 | 0 |
| dart | 28 | 0 | 0 | 0 |
| dockerfile | 7 | 0 | 0 | 0 |
| gitignore | 1 | 0 | 0 | 0 |
| go | 140 | 2 | 0 | 0 |
| groovy | 1 | 0 | 0 | 0 |
| hcl | 4 | 0 | 0 | 0 |
| html | 23 | 0 | 0 | 0 |
| http | 10 | 0 | 0 | 0 |
| java | 178 | 1 | 0 | 0 |
| javascript | 233 | 1 | 0 | 0 |
| js | 8 | 0 | 0 | 0 |
| json | 115 | 0 | 0 | 0 |
| jsonc | 5 | 0 | 0 | 0 |
| jsx | 1 | 0 | 0 | 0 |
| kotlin | 74 | 0 | 0 | 0 |
| lua | 4 | 0 | 0 | 0 |
| markdown | 1 | 0 | 0 | 0 |
| nginx | 4 | 0 | 0 | 0 |
| powershell | 2 | 0 | 0 | 0 |
| properties | 6 | 0 | 0 | 0 |
| protobuf | 5 | 0 | 0 | 0 |
| python | 1012 | 3 | 0 | 0 |
| rust | 118 | 1 | 0 | 0 |
| shell | 19 | 1 | 0 | 0 |
| solidity | 12 | 0 | 0 | 0 |
| sql | 121 | 1 | 0 | 0 |
| swift | 57 | 0 | 0 | 0 |
| text | 1684 | 0 | 0 | 0 |
| toml | 4 | 0 | 0 | 0 |
| ts | 17 | 0 | 0 | 0 |
| tsx | 8 | 0 | 0 | 0 |
| typescript | 145 | 4 | 0 | 0 |
| verilog | 3 | 0 | 0 | 0 |
| xml | 15 | 0 | 0 | 0 |
| yaml | 45 | 2 | 0 | 0 |

## 片段与依赖提示

- cross_cli_args:191 java 已标注片段
- database_olap:337 sql 已标注片段
- de_data_contract:398 python 已标注片段
- de_data_contract:467 python 已标注片段
- distributed_cache:328 python 已标注片段
- flutter_release:316 yaml 已标注片段
- fundamentals_assembly:222 asm 已标注片段
- fundamentals_assembly:512 asm 已标注片段
- go_cloud_native_security:474 go 已标注片段
- go_cloud_native_security:568 go 已标注片段
- go_testing:407 yaml 已标注片段
- programming_rust_cli_project:446 rust 已标注片段
- programming_ts_narrowing_generics:205 typescript 已标注片段
- programming_ts_narrowing_generics:483 typescript 已标注片段
- shell_ci_templates:244 bash 已标注片段
- shell_ci_templates:540 shell 已标注片段
- shell_ci_templates:625 bash 已标注片段
- ts_type_challenges:142 typescript 已标注片段
- ts_type_challenges:476 typescript 已标注片段
- web_pwa_offline:205 javascript 已标注片段
- 未找到 Python 解释器，Python 代码块降级为结构校验（可设置 PYTHON 环境变量）
- ai_engineering:248 python 结构不平衡
- ai_engineering:510 python 结构不平衡
- ai_multimodal:235 python 结构不平衡
- algorithms_probabilistic_structures:156 python 结构不平衡
- algorithms_probabilistic_structures:202 python 结构不平衡
- algorithms_probabilistic_structures:389 python 结构不平衡
- algorithms_probabilistic_structures:496 python 结构不平衡
- algorithms_sorting_advanced:135 python 结构不平衡
- algorithms_sorting_advanced:196 python 结构不平衡
- algorithms_sorting_advanced:543 python 结构不平衡
- cross_collections:250 bash 结构不平衡
- cross_collections:493 bash 结构不平衡
- fundamentals_assembly:313 bash 结构不平衡
- fundamentals_storage_stack:188 python 结构不平衡
- fundamentals_storage_stack:485 python 结构不平衡
- fundamentals_storage_stack:535 python 结构不平衡
- go_pprof:391 bash 结构不平衡
- go_pprof:718 bash 结构不平衡
- programming_cpp_tooling:389 bash 结构不平衡
- programming_cpp_types:73 cpp 结构不平衡
- programming_cpp_types:137 cpp 结构不平衡
- programming_cpp_types:307 cpp 结构不平衡
- programming_cpp_types:531 cpp 结构不平衡
- programming_python_variables:93 python 结构不平衡
- programming_python_variables:131 python 结构不平衡
- programming_python_variables:502 python 结构不平衡
- programming_shell_flow:264 bash 结构不平衡
- se_test_design:181 python 结构不平衡
- se_test_design:444 python 结构不平衡
- shell_json_yaml:192 bash 结构不平衡
- shell_json_yaml:230 bash 结构不平衡
- shell_json_yaml:301 bash 结构不平衡
- shell_json_yaml:349 bash 结构不平衡
- shell_ops_scripts:266 bash 结构不平衡
- shell_ops_scripts:528 bash 结构不平衡
- shell_security:285 bash 结构不平衡
- shell_security:386 bash 结构不平衡
- visual_concurrency_schedule:267 bash 结构不平衡
- visual_concurrency_schedule:564 bash 结构不平衡

## 失败明细

无
