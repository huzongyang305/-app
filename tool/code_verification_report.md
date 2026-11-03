# 代码块验证报告

生成时间：2026-11-03T20:31:23.061764

> 片段是课程里有意截取、无法独立编译的示例，不计入硬失败；
> 排错练习是课程里有意保留错误的代码，同样不计入硬失败；
> 告警多为多行 Shell 命令或依赖演示环境导致的结构提示，
> 硬失败为 0 表示所有可执行代码块都能通过验证或已明确标注为片段。

| 语言 | 通过 | 片段 | 排错练习 | 失败 |
| --- | ---: | ---: | ---: | ---: |
| `markdown | 1 | 0 | 0 | 0 |
| asm | 7 | 1 | 0 | 0 |
| awk | 1 | 0 | 0 | 0 |
| bash | 329 | 1 | 0 | 0 |
| c | 48 | 0 | 0 | 0 |
| cmake | 3 | 0 | 0 | 0 |
| cpp | 262 | 1 | 0 | 0 |
| cron | 1 | 0 | 0 | 0 |
| csharp | 118 | 0 | 0 | 0 |
| css | 42 | 0 | 0 | 0 |
| cypher | 2 | 0 | 0 | 0 |
| dart | 53 | 0 | 0 | 0 |
| dockerfile | 19 | 0 | 0 | 0 |
| dockerignore | 2 | 0 | 0 | 0 |
| gitignore | 1 | 0 | 0 | 0 |
| glsl | 1 | 0 | 0 | 0 |
| go | 96 | 0 | 0 | 0 |
| gotemplate | 1 | 0 | 0 | 0 |
| graphql | 19 | 0 | 0 | 0 |
| groovy | 2 | 0 | 0 | 0 |
| hcl | 24 | 0 | 0 | 0 |
| html | 22 | 0 | 0 | 0 |
| http | 6 | 0 | 0 | 0 |
| ini | 1 | 0 | 0 | 0 |
| java | 315 | 19 | 0 | 0 |
| javascript | 247 | 1 | 0 | 0 |
| js | 7 | 0 | 0 | 0 |
| json | 84 | 0 | 0 | 0 |
| jsonc | 3 | 0 | 0 | 0 |
| jsp | 2 | 0 | 0 | 0 |
| jsx | 35 | 0 | 0 | 0 |
| kotlin | 103 | 0 | 0 | 0 |
| lua | 4 | 0 | 0 | 0 |
| markdown | 2 | 0 | 0 | 0 |
| nginx | 2 | 0 | 0 | 0 |
| objc | 1 | 0 | 0 | 0 |
| powershell | 4 | 0 | 0 | 0 |
| prisma | 1 | 0 | 0 | 0 |
| proguard | 1 | 0 | 0 | 0 |
| promql | 15 | 0 | 0 | 0 |
| properties | 5 | 0 | 0 | 0 |
| protobuf | 4 | 0 | 0 | 0 |
| python | 905 | 5 | 1 | 0 |
| ruby | 2 | 0 | 0 | 0 |
| rust | 68 | 1 | 0 | 0 |
| shell | 1 | 0 | 0 | 0 |
| solidity | 6 | 0 | 0 | 0 |
| sql | 56 | 1 | 0 | 0 |
| svelte | 9 | 0 | 0 | 0 |
| swift | 84 | 0 | 0 | 0 |
| text | 1394 | 0 | 0 | 0 |
| toml | 5 | 0 | 0 | 0 |
| ts | 9 | 0 | 0 | 0 |
| tsx | 2 | 0 | 0 | 0 |
| typescript | 83 | 0 | 0 | 0 |
| verilog | 2 | 0 | 0 | 0 |
| vue | 9 | 0 | 0 | 0 |
| xml | 29 | 0 | 0 | 0 |
| yaml | 176 | 1 | 0 | 0 |

## 片段与依赖提示

- cross_cli_args:132 java 已标注片段
- database_olap:260 sql 已标注片段
- de_data_contract:173 python 已标注片段
- fundamentals_assembly:168 asm 已标注片段
- gamedev_2d_rendering:118 python 已标注片段
- gamedev_2d_rendering:199 python 已标注片段
- gamedev_animation_fsm:124 python 已标注片段
- gamedev_asset_pipeline:213 python 已标注片段
- go_testing:290 yaml 已标注片段
- javaweb_mybatis:264 java 已标注片段
- javaweb_spring_cloud:137 java 已标注片段
- java_data_access:111 java 已标注片段
- java_data_access:331 java 已标注片段
- java_data_access:424 java 已标注片段
- java_microservices:174 java 依赖型示例（缺少框架或同级类）
- java_microservices:204 java 依赖型示例（缺少框架或同级类）
- java_microservices:235 java 依赖型示例（缺少框架或同级类）
- java_microservices:278 java 依赖型示例（缺少框架或同级类）
- java_microservices:298 java 已标注片段
- java_microservices:335 java 依赖型示例（缺少框架或同级类）
- java_modern_features:49 java 已标注片段
- java_project_ecommerce:307 java 已标注片段
- java_project_ecommerce:811 java 依赖型示例（缺少框架或同级类）
- java_restful_api:169 java 已标注片段
- java_spring_core:299 java 依赖型示例（缺少框架或同级类）
- java_spring_security:81 java 已标注片段
- java_virtual_threads:108 java 已标注片段
- programming_cpp_project:299 cpp 已标注片段
- programming_rust_cli_project:287 rust 已标注片段
- shell_ci_templates:145 bash 已标注片段
- web_pwa_offline:149 javascript 已标注片段
- python_first_script:268 python 代码排错练习（有意保留错误）
- 未找到 Python 解释器，Python 代码块降级为结构校验（可设置 PYTHON 环境变量）
- ai_context_engineering:165 python 结构不平衡
- ai_engineering:197 python 结构不平衡
- ai_multimodal:163 python 结构不平衡
- ai_vlm:130 python 结构不平衡
- algorithms_probabilistic_structures:114 python 结构不平衡
- algorithms_sorting_advanced:94 python 结构不平衡
- cross_collections:183 bash 结构不平衡
- devops_logging_tracing:181 ruby 结构不平衡
- devops_logging_tracing:269 ini 结构不平衡
- discrete_number_theory:232 python 结构不平衡
- fundamentals_assembly:259 bash 结构不平衡
- fundamentals_storage_stack:129 python 结构不平衡
- gamedev_2d_rendering:240 python 结构不平衡
- go_pprof:229 bash 结构不平衡
- java_spring_boot_intro:166 java C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_859791b5\DemoApplication.java:3: 错误: 程序包org.springframework.boot不存在 import org.springframework.boot.SpringApplication;                                ^ C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_859791b5\DemoApplication.java:4: 错误: 程序包org.springframework.boot.autoconfigure不存在 import org.springframework.boot.autoconfigure.SpringBootApplication;                                              ^ C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_859791b5\DemoApplication.java:6: 错误: 找不到符号 @SpringBootApplication  // 一个注解搞定：配置 + 自动配置 + 组件扫描  ^   符号: 类 SpringBootApplication C:\Users\m1899\AppData\Local\Temp\code_learn_blocks_859791b5\DemoApplication.java:10: 错误: 找不到符号         SpringApplication.run(DemoApplication.class, args);         ^   符号:   变量 SpringApplication   位置: 类 DemoApplication 4 个错误 
- ml_recommendation_systems:609 python 结构不平衡
- ml_time_series_prediction:365 python 结构不平衡
- mobile_ios_appstore:279 bash 结构不平衡
- mobile_ios_testing:328 bash 结构不平衡
- programming_python_basics:268 python 结构不平衡
- programming_python_basics:576 python 结构不平衡
- programming_shell_flow:176 bash 结构不平衡
- se_test_design:140 python 结构不平衡
- shell_json_yaml:140 bash 结构不平衡
- shell_json_yaml:178 bash 结构不平衡
- shell_json_yaml:249 bash 结构不平衡
- shell_ops_scripts:149 bash 结构不平衡
- shell_ops_scripts:371 bash 结构不平衡
- shell_security:181 bash 结构不平衡
- shell_security:282 bash 结构不平衡
- visual_concurrency_schedule:209 bash 结构不平衡

## 失败明细

无
