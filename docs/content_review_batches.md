# 人工复核批次台账

- 生成时间：2026-10-08T04:44:10.584556Z
- 批次大小：每批最多 24 门课
- 记录入口：`docs/content_review_records.json` 的 `human_reviews`

> 复核完成后，把复核人、日期、范围与结论写入记录文件，再重跑本工具刷新台账。

## ai-1 · AI 与智能体

- 课程数：24 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 24
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 模型、工具与成本结论注明适用前提，避免把演示效果当成生产结论。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Agent 成本与性能优化（agent_cost_performance） | low | 9893 | 6 | 2 | 待复核 |
| Agent 记忆系统（agent_memory） | low | 9971 | 6 | 2 | 待复核 |
| A2A Agent 协作协议（ai_a2a） | low | 11873 | 6 | 2 | 待复核 |
| AI Agent 基础（ai_agent_basics） | low | 10009 | 6 | 3 | 待复核 |
| Agent 评测实战（ai_agent_evaluation） | low | 13891 | 6 | 2 | 待复核 |
| Agent 安全、权限与沙箱（ai_agent_security） | low | 11661 | 5 | 2 | 待复核 |
| AI、机器学习与生成式 AI（ai_basics） | low | 9801 | 6 | 2 | 待复核 |
| 浏览器 Agent（ai_browser_agent） | low | 11241 | 5 | 2 | 待复核 |
| 代码 Agent 与软件工程自动化（ai_coding_agent） | low | 11412 | 5 | 2 | 待复核 |
| AI 编程助手与代码生成（ai_coding_assistant） | low | 10027 | 6 | 2 | 待复核 |
| Computer Use 与桌面自动化（ai_computer_use） | low | 11869 | 5 | 2 | 待复核 |
| AI 概念入门（ai_concept_intro） | low | 10518 | 6 | 2 | 待复核 |
| 上下文工程（ai_context_engineering） | low | 9784 | 6 | 2 | 待复核 |
| 数据工程与标注（ai_data_engineering） | low | 10267 | 6 | 2 | 待复核 |
| 深度学习与大语言模型（ai_deep_learning_llm） | low | 10707 | 6 | 3 | 待复核 |
| 扩散模型与图像生成（ai_diffusion） | low | 11444 | 5 | 2 | 待复核 |
| 嵌入、向量检索与 RAG（ai_embeddings_rag） | low | 11950 | 6 | 2 | 待复核 |
| AI 应用工程化（ai_engineering） | low | 10753 | 6 | 2 | 待复核 |
| 模型微调与本地部署（ai_fine_tuning_deployment） | low | 10935 | 6 | 2 | 待复核 |
| AI 治理、合规与风险（ai_governance） | low | 11276 | 5 | 2 | 待复核 |
| GraphRAG 与知识图谱检索（ai_graphrag） | low | 11926 | 5 | 2 | 待复核 |
| 安全护栏与内容审核（ai_guardrails） | low | 11523 | 5 | 2 | 待复核 |
| MCP 模型上下文协议（ai_mcp） | low | 12994 | 6 | 2 | 待复核 |
| MLOps 与模型上线（ai_mlops） | low | 10601 | 5 | 2 | 待复核 |

## ai-2 · AI 与智能体

- 课程数：18 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 18
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 模型、工具与成本结论注明适用前提，避免把演示效果当成生产结论。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 大模型推理服务与 GPU 优化（ai_model_serving） | low | 11422 | 5 | 2 | 待复核 |
| 多智能体与编排（ai_multi_agent） | low | 10617 | 6 | 2 | 待复核 |
| 多模态 AI：图像、语音与视频（ai_multimodal） | low | 9491 | 6 | 2 | 待复核 |
| 提示工程（ai_prompt_engineering） | low | 9537 | 6 | 2 | 待复核 |
| 实战：文档问答助手（RAG + Agent）（ai_rag_agent_project） | low | 14669 | 6 | 2 | 待复核 |
| Realtime API 与语音交互（ai_realtime_api） | low | 12006 | 5 | 2 | 待复核 |
| 实时语音对话（ai_realtime_voice） | low | 10138 | 6 | 2 | 待复核 |
| 推荐系统基础与排序（ai_recommender） | low | 10295 | 5 | 2 | 待复核 |
| 强化学习基础（ai_reinforcement_learning） | low | 10734 | 5 | 2 | 待复核 |
| 时间序列预测（ai_time_series） | low | 10573 | 5 | 2 | 待复核 |
| 工具调用与结构化输出（ai_tool_calling） | low | 11964 | 5 | 2 | 待复核 |
| 模型训练与分布式（ai_training） | low | 9705 | 6 | 2 | 待复核 |
| 视觉语言模型 VLM（ai_vlm） | low | 11501 | 5 | 2 | 待复核 |
| 机器学习核心概念（ml_fundamentals） | low | 11366 | 6 | 2 | 待复核 |
| 模型评测与选型（model_evaluation） | low | 9953 | 6 | 2 | 待复核 |
| 多模态 RAG（multimodal_rag） | low | 9188 | 6 | 2 | 待复核 |
| 提示词入门（prompt_intro） | low | 11685 | 6 | 2 | 待复核 |
| 向量数据库选型与调优（vector_db） | low | 9977 | 6 | 2 | 待复核 |

## algorithms-1 · 算法与数据结构

- 课程数：24 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 24
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 计算几何基础（algo_computational_geometry） | low | 10890 | 5 | 2 | 待复核 |
| 最小生成树与图剪枝（algo_mst） | low | 12767 | 6 | 2 | 待复核 |
| NP 完全性与近似算法（algo_np_approximation） | low | 10257 | 5 | 2 | 待复核 |
| 持久化数据结构与并行算法（algo_persistent_parallel） | low | 10666 | 5 | 2 | 待复核 |
| 最短路算法专题（algo_shortest_paths） | low | 12639 | 6 | 2 | 待复核 |
| 拓扑排序与 DAG 应用（algo_topological） | low | 10757 | 5 | 2 | 待复核 |
| 算法入门（algorithm_intro） | low | 10724 | 5 | 2 | 待复核 |
| 实战：把数据结构用起来（algorithms_project） | low | 11153 | 6 | 2 | 待复核 |
| 回溯算法（backtracking） | low | 8311 | 6 | 2 | 待复核 |
| 平衡树实现（balanced_tree） | low | 9340 | 6 | 2 | 待复核 |
| 二分答案（binary_answer） | low | 11042 | 6 | 2 | 待复核 |
| 二分查找（binary_search） | low | 9298 | 6 | 2 | 待复核 |
| 位运算技巧（bit_manipulation） | low | 10579 | 6 | 2 | 待复核 |
| 冒泡排序（bubble_sort） | low | 10182 | 6 | 2 | 待复核 |
| 缓存淘汰算法（cache_eviction） | low | 9306 | 6 | 2 | 待复核 |
| 动态规划入门（dynamic_programming） | low | 10628 | 6 | 2 | 待复核 |
| 图与图算法（graph） | low | 10646 | 6 | 2 | 待复核 |
| 贪心算法（greedy） | low | 10954 | 6 | 2 | 待复核 |
| 哈希表（hash_table） | low | 10235 | 6 | 3 | 待复核 |
| 线性查找入门（linear_search_intro） | low | 11000 | 6 | 2 | 待复核 |
| 链表（linked_list） | low | 9066 | 6 | 2 | 待复核 |
| 单调栈与单调队列（monotonic_stack） | low | 9771 | 6 | 2 | 待复核 |
| 网络流与二分图匹配（network_flow） | low | 9886 | 6 | 2 | 待复核 |
| 前缀和与差分（prefix_sum） | low | 10759 | 6 | 2 | 待复核 |

## algorithms-2 · 算法与数据结构

- 课程数：11 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 11
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 概率数据结构（probabilistic_structures） | low | 10361 | 6 | 2 | 待复核 |
| 树状数组与线段树（segment_tree） | low | 9443 | 6 | 2 | 待复核 |
| 排序算法家族（sorting） | low | 11345 | 6 | 2 | 待复核 |
| 基数排序、桶排序与外部排序（sorting_advanced） | low | 10043 | 6 | 2 | 待复核 |
| 栈与队列（stack_queue） | low | 11539 | 6 | 2 | 待复核 |
| 字符串匹配（string_matching） | low | 8435 | 6 | 2 | 待复核 |
| 时间复杂度（time_complexity） | low | 11642 | 6 | 3 | 待复核 |
| 树与二叉搜索树（tree_bst） | low | 9464 | 6 | 2 | 待复核 |
| 字典树（Trie）（trie） | low | 10503 | 6 | 2 | 待复核 |
| 双指针与滑动窗口（two_pointers） | low | 9565 | 6 | 2 | 待复核 |
| 并查集（union_find） | low | 9648 | 6 | 2 | 待复核 |

## blockchain-1 · 区块链与 Web3

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 区块链基础与密码学原语（blockchain_basics） | low | 12420 | 5 | 2 | 待复核 |
| 比特币、UTXO 与工作量证明（blockchain_bitcoin_consensus） | low | 12041 | 5 | 2 | 待复核 |
| DeFi 风险与智能合约审计（blockchain_defi_security） | low | 11620 | 5 | 2 | 待复核 |
| 以太坊、EVM 与智能合约（blockchain_ethereum_smart_contract） | low | 11988 | 5 | 2 | 待复核 |
| 扩容、Rollup 与跨链桥（blockchain_scaling_layer2） | low | 12435 | 5 | 2 | 待复核 |
| 项目：智能合约审计实战（chain_audit_project） | low | 13210 | 5 | 2 | 待复核 |
| 预言机与跨链桥（chain_oracle_bridge） | low | 10855 | 5 | 2 | 待复核 |
| 代币标准与合约接口（chain_token_standards） | low | 11514 | 5 | 2 | 待复核 |
| 钱包、密钥与签名（chain_wallet_keys） | low | 10256 | 5 | 2 | 待复核 |
| 零知识与链上隐私（chain_zk_privacy） | low | 10423 | 5 | 2 | 待复核 |

## c-1 · C 语言

- 课程数：16 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 16
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| C 数组、字符串与缓冲区（c_arrays_strings） | low | 11624 | 6 | 2 | 待复核 |
| C 基础语法与编译流程（c_basics） | low | 14659 | 6 | 2 | 待复核 |
| C 条件判断（c_conditions） | low | 12395 | 5 | 2 | 待复核 |
| C 控制流、函数与作用域（c_control_functions） | low | 11266 | 6 | 2 | 待复核 |
| C 调试、Sanitizer 与性能（c_debugging） | low | 11507 | 6 | 2 | 待复核 |
| C 文件、错误处理与资源管理（c_files） | low | 12100 | 6 | 2 | 待复核 |
| C 第一个程序（c_first_program） | low | 12718 | 5 | 2 | 待复核 |
| C 函数入门（c_functions_intro） | low | 13848 | 5 | 2 | 待复核 |
| C 循环入门（c_loops） | low | 14303 | 5 | 2 | 待复核 |
| C 指针与内存模型（c_pointers） | low | 12692 | 6 | 2 | 待复核 |
| C 预处理、宏与头文件（c_preprocessor） | low | 11783 | 6 | 2 | 待复核 |
| 实战：C 命令行任务管理器（c_project） | low | 12394 | 5 | 2 | 待复核 |
| 实战：C 语言 TCP 服务端（c_project_tcp_server） | low | 12041 | 5 | 2 | 待复核 |
| C 结构体、联合体与内存布局（c_structs） | low | 11323 | 6 | 2 | 待复核 |
| C 类型、运算符与转换（c_types） | low | 11523 | 6 | 2 | 待复核 |
| C 变量与输入输出（c_variables_io） | low | 12769 | 5 | 2 | 待复核 |

## cloud-1 · 云计算与云原生

- 课程数：9 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 9
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 容器与 Kubernetes 编排（cloud_containers_kubernetes） | low | 12615 | 5 | 2 | 待复核 |
| 云成本治理与容量规划（cloud_cost_finops） | low | 10642 | 5 | 2 | 待复核 |
| 云计算基础与资源模型（cloud_fundamentals） | low | 11583 | 5 | 2 | 待复核 |
| 基础设施即代码（cloud_iac_terraform） | low | 10129 | 5 | 2 | 待复核 |
| Kubernetes 运维实战（cloud_k8s_operations） | low | 13480 | 5 | 2 | 待复核 |
| 多集群与容灾演练（cloud_multicluster_dr） | low | 10312 | 5 | 2 | 待复核 |
| 可观测性与 SRE 实践（cloud_observability_sre） | low | 12069 | 5 | 2 | 待复核 |
| 云安全与最小权限（cloud_security_iam） | low | 10546 | 5 | 2 | 待复核 |
| 无服务器与事件驱动架构（cloud_serverless） | low | 11898 | 5 | 2 | 待复核 |

## compiler-1 · 编译原理与语言实现

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 字节码与虚拟机实现（compiler_bytecode_vm） | low | 10735 | 5 | 2 | 待复核 |
| 代码生成与栈式虚拟机（compiler_codegen_vm） | low | 11294 | 5 | 2 | 待复核 |
| 诊断系统与错误恢复（compiler_diagnostics） | low | 10459 | 5 | 2 | 待复核 |
| 垃圾回收算法与实现（compiler_gc） | low | 10337 | 5 | 2 | 待复核 |
| 中间表示与优化（compiler_ir_optimization） | low | 11225 | 5 | 2 | 待复核 |
| 即时编译与内联优化（compiler_jit_inlining） | low | 10537 | 5 | 2 | 待复核 |
| 词法分析与语法分析（compiler_lexer_parser） | low | 11186 | 5 | 2 | 待复核 |
| 编译流程与解释执行概览（compiler_overview） | low | 12266 | 5 | 2 | 待复核 |
| 项目：实现一门迷你语言（compiler_project_minilang） | low | 13408 | 5 | 2 | 待复核 |
| 语义分析与类型系统（compiler_semantic_types） | low | 11408 | 5 | 2 | 待复核 |

## cpp-1 · C++

- 课程数：21 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 21
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 环境与编译流程（cpp_basics） | low | 10544 | 6 | 2 | 待复核 |
| C++ Concepts 与 Ranges（cpp_concepts_ranges） | low | 11196 | 6 | 2 | 待复核 |
| C++ 并发、原子操作与内存序（cpp_concurrency_atomics） | low | 11892 | 6 | 2 | 待复核 |
| C++ 条件判断（cpp_conditions） | low | 12701 | 5 | 2 | 待复核 |
| 控制流与函数（cpp_control_functions） | low | 10203 | 6 | 2 | 待复核 |
| C++ 第一个程序（cpp_first_program） | low | 13009 | 5 | 2 | 待复核 |
| C++ 函数入门（cpp_functions_intro） | low | 14657 | 5 | 2 | 待复核 |
| C++ 循环入门（cpp_loops） | low | 14325 | 5 | 2 | 待复核 |
| 内存管理与智能指针（cpp_memory） | low | 11216 | 6 | 2 | 待复核 |
| 现代 C++ 特性（cpp_modern） | low | 12205 | 6 | 2 | 待复核 |
| C++ 移动语义与右值引用（cpp_move_semantics） | low | 10980 | 6 | 2 | 待复核 |
| 类与面向对象（cpp_oop） | low | 12645 | 6 | 2 | 待复核 |
| 指针与引用（cpp_pointers） | low | 9588 | 6 | 2 | 待复核 |
| 实战：CMake 多文件项目（cpp_project） | low | 16829 | 6 | 2 | 待复核 |
| 实战：C++ HTTP JSON 服务（cpp_project_http） | low | 13816 | 6 | 2 | 待复核 |
| 实战：C++ 任务数据库 CLI（cpp_project_taskdb） | low | 13190 | 6 | 2 | 待复核 |
| STL 容器与算法（cpp_stl） | low | 12509 | 6 | 2 | 待复核 |
| 模板与泛型编程（cpp_templates） | low | 11706 | 6 | 2 | 待复核 |
| 构建、调试与工程实践（cpp_tooling） | low | 11489 | 6 | 2 | 待复核 |
| 变量、类型与运算符（cpp_types） | low | 9795 | 6 | 2 | 待复核 |
| C++ 变量与输入输出（cpp_variables_io） | low | 10421 | 5 | 2 | 待复核 |

## cross_language-1 · 跨语言对照

- 课程数：18 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 18
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 接口文档与契约测试：跨生态对照（cross_api_contract） | low | 9253 | 5 | 2 | 待复核 |
| 构建与发布产物：九种生态横向对照（cross_build_release） | low | 9945 | 6 | 2 | 待复核 |
| CI 流水线配置：九种生态横向对照（cross_ci_config） | low | 10528 | 5 | 2 | 待复核 |
| 命令行参数解析：九种语言横向对照（cross_cli_args） | low | 10203 | 5 | 2 | 待复核 |
| 集合类型：九种语言横向对照（cross_collections） | low | 9494 | 6 | 2 | 待复核 |
| 并发写法：九种语言横向对照（cross_concurrency） | low | 9343 | 6 | 2 | 待复核 |
| 数据库访问与 ORM：九种生态横向对照（cross_db_access） | low | 9456 | 5 | 2 | 待复核 |
| 错误处理与测试：九种语言横向对照（cross_errors_testing） | low | 9527 | 6 | 2 | 待复核 |
| 九种语言的第一个程序（cross_first_program） | low | 10940 | 6 | 2 | 待复核 |
| 国际化与本地化：跨生态对照（cross_i18n） | low | 11165 | 5 | 2 | 待复核 |
| 日志与可观测性：九种生态横向对照（cross_logging_observability） | low | 12164 | 5 | 2 | 待复核 |
| 包管理与依赖：九种生态横向对照（cross_package_manage） | low | 11468 | 6 | 2 | 待复核 |
| 性能剖析与基准测试：九种生态横向对照（cross_performance_profiling） | low | 9273 | 5 | 2 | 待复核 |
| 依赖安全与密钥管理：九种生态横向对照（cross_security_ecosystem） | low | 11791 | 5 | 2 | 待复核 |
| 序列化格式：JSON、YAML、Protobuf 横向对照（cross_serialization） | low | 9910 | 5 | 2 | 待复核 |
| 字符串与正则：九种语言横向对照（cross_string_regex） | low | 10288 | 5 | 2 | 待复核 |
| 时间与时区：九种语言横向对照（cross_time_timezone） | low | 10905 | 5 | 2 | 待复核 |
| 类型与变量：九种语言横向对照（cross_types_variables） | low | 10236 | 6 | 2 | 待复核 |

## csharp-1 · C#

- 课程数：19 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 19
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 异步编程与异常处理（csharp_async） | low | 12530 | 6 | 2 | 待复核 |
| C# 异步流与取消（csharp_async_streams） | low | 12327 | 6 | 2 | 待复核 |
| C# 与 .NET 平台（csharp_basics） | low | 10591 | 6 | 2 | 待复核 |
| 集合、委托与 LINQ（csharp_collections_linq） | low | 11903 | 6 | 2 | 待复核 |
| C# 条件判断（csharp_conditions） | low | 12795 | 6 | 2 | 待复核 |
| 控制流与方法（csharp_control_methods） | low | 10747 | 6 | 2 | 待复核 |
| C# 与 .NET 第一个程序（csharp_dotnet_first） | low | 13060 | 5 | 2 | 待复核 |
| 生态、测试与 Web 开发（csharp_ecosystem） | low | 13350 | 6 | 2 | 待复核 |
| C# GC、Span 与性能优化（csharp_gc_performance） | low | 12778 | 6 | 2 | 待复核 |
| 继承、接口与多态（csharp_inheritance） | low | 10732 | 6 | 2 | 待复核 |
| C# 循环入门（csharp_loops） | low | 13919 | 5 | 2 | 待复核 |
| C# 方法入门（csharp_methods_intro） | low | 14518 | 5 | 2 | 待复核 |
| 类、属性与对象（csharp_oop） | low | 10518 | 6 | 2 | 待复核 |
| 实战：Web API + EF Core（csharp_project） | low | 17345 | 6 | 2 | 待复核 |
| 实战：C# Blazor 管理后台（csharp_project_blazor_admin） | low | 13621 | 6 | 2 | 待复核 |
| 实战：C# 库存管理 CLI（csharp_project_inventory_cli） | low | 13393 | 6 | 2 | 待复核 |
| C# Record、模式匹配与不可变数据（csharp_records_patterns） | low | 9408 | 6 | 2 | 待复核 |
| 变量、类型与字符串（csharp_types） | low | 10651 | 6 | 2 | 待复核 |
| C# 变量与输入（csharp_variables_input） | low | 10369 | 5 | 2 | 待复核 |

## data_engineering-1 · 数据工程

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 批处理与 Spark 实践（de_batch_processing） | low | 11174 | 5 | 2 | 待复核 |
| CDC 与增量同步（de_cdc_incremental） | low | 10949 | 5 | 2 | 待复核 |
| 数据契约与质量门禁（de_data_contract） | low | 11072 | 5 | 2 | 待复核 |
| 数据建模与数仓分层（de_data_modeling） | low | 11190 | 5 | 2 | 待复核 |
| 数据质量与数据治理（de_data_quality） | low | 11189 | 5 | 2 | 待复核 |
| Flink 流处理与窗口（de_flink_windowing） | low | 11152 | 5 | 2 | 待复核 |
| 湖仓治理与表维护（de_lakehouse_governance） | low | 10523 | 5 | 2 | 待复核 |
| 任务编排与数据血缘（de_orchestration_lineage） | low | 11052 | 5 | 2 | 待复核 |
| Spark 执行模型与调优（de_spark_tuning） | low | 11540 | 5 | 2 | 待复核 |
| 流处理与 Kafka 实践（de_stream_processing） | low | 11696 | 5 | 2 | 待复核 |

## database-1 · 数据库

- 课程数：24 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 24
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Airflow 调度与数据质量（airflow_quality） | low | 9125 | 6 | 2 | 待复核 |
| 大数据与批流处理（bigdata_batch_stream） | low | 9486 | 6 | 2 | 待复核 |
| 数据湖与湖仓一体（data_lakehouse） | low | 11921 | 6 | 2 | 待复核 |
| 实战：设计并优化一个订单库（database_project） | low | 13229 | 6 | 2 | 待复核 |
| 数据库备份与恢复演练（db_backup_recovery） | low | 10756 | 5 | 2 | 待复核 |
| 数据库设计与范式（db_design） | low | 10995 | 6 | 2 | 待复核 |
| 图数据库与关系查询（db_graph） | low | 12375 | 6 | 2 | 待复核 |
| 数据库迁移与 Schema 治理（db_migration_governance） | low | 10882 | 6 | 2 | 待复核 |
| 数据库运维：备份、迁移与分库分表（db_ops） | low | 10366 | 6 | 2 | 待复核 |
| 数据库权限与安全（db_permissions_security） | low | 10702 | 5 | 2 | 待复核 |
| PostgreSQL 深入实践（db_postgresql_deep） | low | 11300 | 6 | 2 | 待复核 |
| 查询优化与执行计划（db_query_optimization） | low | 9676 | 6 | 2 | 待复核 |
| 时序数据库与监控数据（db_time_series） | low | 11675 | 6 | 2 | 待复核 |
| 分布式事务与共识（distributed_transaction） | low | 9941 | 6 | 2 | 待复核 |
| 索引（index） | low | 9595 | 6 | 2 | 待复核 |
| MySQL 锁与 MVCC（mysql_lock_mvcc） | low | 12157 | 6 | 2 | 待复核 |
| NoSQL 数据库（nosql） | low | 9793 | 6 | 2 | 待复核 |
| OLAP 与列式存储（olap_columnar） | low | 11639 | 6 | 2 | 待复核 |
| 实时数仓：从 Kafka 到 Flink（realtime_warehouse） | low | 9655 | 6 | 2 | 待复核 |
| Redis 实战（redis） | low | 12505 | 6 | 2 | 待复核 |
| 倒排索引与搜索（search_index） | low | 9300 | 6 | 2 | 待复核 |
| SQL 高级查询（sql_advanced） | low | 10127 | 6 | 2 | 待复核 |
| SQL 基础（sql_basics） | low | 9675 | 6 | 2 | 待复核 |
| SQL 查询入门（sql_query_intro） | low | 10346 | 5 | 2 | 待复核 |

## database-2 · 数据库

- 课程数：3 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 3
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 表与 SQL 入门（sql_table_intro） | low | 10787 | 5 | 2 | 待复核 |
| 存储引擎与 B+ 树实现（storage_engine） | low | 9500 | 6 | 2 | 待复核 |
| 事务（transaction） | low | 9420 | 6 | 3 | 待复核 |

## distributed-1 · 分布式与架构

- 课程数：12 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 12
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 事件溯源与读写分离（dist_event_sourcing） | low | 10868 | 5 | 2 | 待复核 |
| 分布式事务与一致性（dist_transaction） | low | 10803 | 5 | 2 | 待复核 |
| 分布式缓存架构（distributed_cache） | low | 11194 | 6 | 2 | 待复核 |
| 共识与复制：Raft 实战要点（distributed_consensus） | low | 13404 | 6 | 2 | 待复核 |
| 分布式系统原理（distributed_fundamentals） | low | 10539 | 6 | 3 | 待复核 |
| 分布式 ID 与发号器（distributed_id） | low | 11040 | 6 | 2 | 待复核 |
| 单元化与多活架构（distributed_multisite） | low | 9775 | 6 | 2 | 待复核 |
| 限流与熔断算法专题（distributed_rate_limit） | low | 9895 | 6 | 2 | 待复核 |
| 实战：设计一个短链服务（distributed_short_url_project） | low | 11934 | 6 | 2 | 待复核 |
| 高可用与容量规划（high_availability） | low | 10182 | 6 | 2 | 待复核 |
| 消息队列与事件驱动（messaging_events） | low | 11480 | 6 | 2 | 待复核 |
| 微服务拆分与治理（microservices） | low | 9791 | 6 | 2 | 待复核 |

## embedded-1 · 嵌入式与物联网

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Bootloader 与固件升级（embedded_bootloader） | low | 12326 | 5 | 2 | 待复核 |
| UART、SPI 与 I2C 通信实战（embedded_bus_protocols） | low | 13835 | 5 | 2 | 待复核 |
| 嵌入式调试与追踪（embedded_debug_trace） | low | 10501 | 5 | 2 | 待复核 |
| 外设编程：GPIO、中断与定时器（embedded_gpio_interrupt） | low | 11897 | 5 | 2 | 待复核 |
| IoT 设备安全基础（embedded_iot_security） | low | 10610 | 5 | 2 | 待复核 |
| 低功耗与电池续航设计（embedded_low_power） | low | 10638 | 5 | 2 | 待复核 |
| 单片机与嵌入式系统基础（embedded_mcu_basics） | low | 11569 | 5 | 2 | 待复核 |
| 项目：环境监测节点（embedded_project_env_monitor） | low | 12952 | 5 | 2 | 待复核 |
| RTOS 任务、调度与同步（embedded_rtos_tasks） | low | 12152 | 5 | 2 | 待复核 |
| 传感器采集与信号调理（embedded_sensor_signal） | low | 10312 | 5 | 2 | 待复核 |

## flutter-1 · 移动开发

- 课程数：12 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 12
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Flutter 基础与 Widget 树（flutter_basics） | low | 11903 | 6 | 2 | 待复核 |
| Flutter 布局入门（flutter_layout_intro） | low | 13271 | 6 | 2 | 待复核 |
| 实战：Flutter 打包发布 Android（flutter_release） | low | 14883 | 6 | 2 | 待复核 |
| Flutter 状态管理与性能（flutter_state） | low | 12508 | 6 | 2 | 待复核 |
| Flutter Widget 入门（flutter_widget_intro） | low | 13464 | 6 | 2 | 待复核 |
| Jetpack Compose 声明式 UI（mobile_compose） | low | 11068 | 6 | 2 | 待复核 |
| 鸿蒙 ArkTS 应用开发（mobile_harmony） | low | 9884 | 6 | 2 | 待复核 |
| Kotlin 与 Android 开发（mobile_kotlin） | low | 11975 | 6 | 2 | 待复核 |
| 小程序开发要点（mobile_miniprogram） | low | 9450 | 6 | 2 | 待复核 |
| 移动端性能优化实战（mobile_performance） | low | 12315 | 6 | 2 | 待复核 |
| React Native 跨平台开发（mobile_react_native） | low | 10659 | 6 | 2 | 待复核 |
| Swift 与 iOS 开发（mobile_swift） | low | 11622 | 6 | 2 | 待复核 |

## fundamentals-1 · 计算机基础

- 课程数：24 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 24
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 指令集与汇编入门（assembly） | low | 10683 | 6 | 2 | 待复核 |
| 二进制与进制转换（binary） | low | 10223 | 6 | 2 | 待复核 |
| 二进制入门（binary_intro） | low | 9641 | 5 | 2 | 待复核 |
| 总线与 I/O 设备（bus_io） | low | 9395 | 6 | 2 | 待复核 |
| 代码生成与寄存器分配（codegen_registers） | low | 9928 | 6 | 2 | 待复核 |
| 编译与程序运行原理（compiler） | low | 11563 | 6 | 2 | 待复核 |
| 编译前端：词法与语法分析（compiler_frontend） | low | 9611 | 6 | 2 | 待复核 |
| 计算理论入门（computation_theory） | low | 10356 | 6 | 2 | 待复核 |
| 计算机组成入门（computer_organization_intro） | low | 10694 | 5 | 2 | 待复核 |
| CPU 工作原理（cpu） | low | 9954 | 6 | 2 | 待复核 |
| 密码学原语（cryptography） | low | 10207 | 6 | 2 | 待复核 |
| 数字逻辑与布尔代数（digital_logic） | low | 9544 | 6 | 2 | 待复核 |
| 离散数学与逻辑（discrete_math） | low | 8800 | 6 | 2 | 待复核 |
| 字符编码与 Unicode（encoding） | low | 10999 | 6 | 2 | 待复核 |
| 浮点数与校验码（float_and_check） | low | 9580 | 6 | 2 | 待复核 |
| 计算机体系结构综合案例（fundamentals_architecture_case） | low | 10982 | 6 | 2 | 待复核 |
| 缓存一致性、内存模型与 NUMA（fundamentals_cache_coherence） | low | 11024 | 6 | 2 | 待复核 |
| 嵌入式与 IoT 基础（fundamentals_embedded_iot） | low | 10824 | 6 | 2 | 待复核 |
| CPU 流水线与指令级并行（fundamentals_pipeline） | low | 10943 | 6 | 2 | 待复核 |
| 实战：追踪程序的全生命周期（fundamentals_project） | low | 11621 | 6 | 2 | 待复核 |
| SIMD 与向量化计算（fundamentals_simd） | low | 10535 | 6 | 2 | 待复核 |
| SSD、存储栈与持久化（fundamentals_storage_stack） | low | 12583 | 6 | 2 | 待复核 |
| 计算机图形学与多媒体（graphics_media） | low | 11206 | 6 | 2 | 待复核 |
| 中断、异常与 DMA（interrupt_exception） | low | 9520 | 6 | 2 | 待复核 |

## fundamentals-2 · 计算机基础

- 课程数：6 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 6
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 中间代码与优化（ir_optimization） | low | 11207 | 6 | 2 | 待复核 |
| 链接与加载（linking_loading） | low | 10903 | 6 | 2 | 待复核 |
| 内存与缓存（memory_cache） | low | 10320 | 6 | 3 | 待复核 |
| 性能度量与并行体系结构（performance_metrics） | low | 9702 | 6 | 2 | 待复核 |
| 概率统计基础（probability） | low | 9083 | 6 | 2 | 待复核 |
| 语义分析与符号表（semantics_analysis） | low | 9619 | 6 | 2 | 待复核 |

## gamedev-1 · 图形与游戏开发

- 课程数：9 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 9
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 2D 渲染管线与坐标系（gamedev_2d_rendering） | low | 11817 | 5 | 2 | 待复核 |
| 动画状态机与混合（gamedev_animation_fsm） | low | 10493 | 5 | 2 | 待复核 |
| 资产管线与热更新（gamedev_asset_pipeline） | low | 10192 | 5 | 2 | 待复核 |
| 碰撞检测与物理基础（gamedev_collision_physics） | low | 11214 | 5 | 2 | 待复核 |
| 实体组件系统与性能剖析（gamedev_ecs_profiling） | low | 11169 | 5 | 2 | 待复核 |
| 游戏循环与帧时间（gamedev_game_loop） | low | 10986 | 5 | 2 | 待复核 |
| 多人同步与延迟处理（gamedev_multiplayer_sync） | low | 10395 | 5 | 2 | 待复核 |
| 移动端性能与功耗优化（gamedev_performance_mobile） | low | 10258 | 5 | 2 | 待复核 |
| 渲染管线与批次合并（gamedev_render_pipeline） | low | 10670 | 5 | 2 | 待复核 |

## go-1 · Go

- 课程数：22 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 22
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Go 基础（go_basics） | low | 10233 | 6 | 2 | 待复核 |
| Go 云原生服务安全与可靠性（go_cloud_native_security） | low | 10926 | 6 | 2 | 待复核 |
| Go 并发：goroutine、channel 与 context（go_concurrency） | low | 10744 | 6 | 2 | 待复核 |
| Go 并发模式与 errgroup（go_concurrency_patterns） | low | 10394 | 6 | 2 | 待复核 |
| Go 条件判断（go_conditions） | low | 12697 | 6 | 2 | 待复核 |
| Go 数据访问与连接池（go_data_access） | low | 11558 | 6 | 2 | 待复核 |
| Go 第一个程序（go_first_program） | low | 12877 | 6 | 2 | 待复核 |
| Go 函数入门（go_functions_intro） | low | 14058 | 5 | 2 | 待复核 |
| Go 泛型深入与约束设计（go_generics_deep） | low | 10823 | 6 | 2 | 待复核 |
| Go 泛型与标准库实战（go_generics_stdlib） | low | 13627 | 6 | 2 | 待复核 |
| gRPC 与 Protobuf 实践（go_grpc） | low | 11530 | 6 | 2 | 待复核 |
| Go 接口与错误处理（go_interfaces_errors） | low | 9541 | 6 | 2 | 待复核 |
| Go 循环入门（go_loops） | low | 14470 | 6 | 2 | 待复核 |
| Go 微服务与可观测（go_microservice） | low | 10606 | 6 | 2 | 待复核 |
| Go 性能优化与内存（go_performance） | low | 10256 | 6 | 2 | 待复核 |
| Go 性能剖析与调优实战（go_pprof） | low | 13166 | 6 | 2 | 待复核 |
| Go 性能剖析与调优（进阶）（go_profiling_deep） | low | 12303 | 6 | 2 | 待复核 |
| Go 工程实践（go_project） | low | 14049 | 6 | 2 | 待复核 |
| 实战：Go REST API 服务（go_project_rest_api） | low | 13465 | 6 | 2 | 待复核 |
| 实战：Go 并发抓取与 Worker Pool（go_project_worker_pool） | low | 14498 | 6 | 2 | 待复核 |
| Go 测试进阶：基准、模糊与集成（go_testing） | low | 10364 | 6 | 2 | 待复核 |
| Go 变量与输入（go_variables_input） | low | 12776 | 6 | 2 | 待复核 |

## html_css-1 · HTML 与 CSS

- 课程数：14 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 14
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 可访问性与 ARIA 实战（a11y_aria） | low | 12508 | 6 | 2 | 待复核 |
| 浏览器渲染与事件循环深入（browser_rendering） | low | 9323 | 6 | 2 | 待复核 |
| CSS 进阶：变量、伪类与现代特性（css_advanced） | low | 10637 | 6 | 2 | 待复核 |
| CSS 基础：选择器与盒模型（css_basics） | low | 10288 | 6 | 2 | 待复核 |
| 设计令牌与样式架构（css_design_tokens） | low | 9229 | 6 | 2 | 待复核 |
| CSS 布局：Flex、Grid 与响应式（css_layout） | low | 11308 | 6 | 2 | 待复核 |
| 浏览器渲染与 CSS 动画（css_render_animation） | low | 9209 | 6 | 2 | 待复核 |
| CSS 选择器入门（css_selectors_intro） | low | 12995 | 6 | 2 | 待复核 |
| HTML 基础与语义化（html_basics） | low | 10095 | 6 | 2 | 待复核 |
| 实战：响应式落地页（html_css_project） | low | 10944 | 6 | 2 | 待复核 |
| HTML 标签入门（html_tags_intro） | low | 11190 | 6 | 2 | 待复核 |
| Web Components 实战（web_components） | low | 12144 | 6 | 2 | 待复核 |
| 前端性能优化实战（web_performance） | low | 12159 | 6 | 2 | 待复核 |
| PWA 与离线能力（web_pwa_offline） | low | 11875 | 6 | 2 | 待复核 |

## java-1 · Java

- 课程数：21 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 21
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 环境与 JVM（java_basics） | low | 10973 | 6 | 2 | 待复核 |
| 集合框架与泛型（java_collections） | low | 12480 | 6 | 2 | 待复核 |
| 多线程与并发（java_concurrency） | low | 13389 | 6 | 2 | 待复核 |
| Java 条件判断（java_conditions） | low | 13107 | 5 | 2 | 待复核 |
| 控制流与方法（java_control_methods） | low | 10242 | 6 | 2 | 待复核 |
| 异常处理与文件 IO（java_exceptions） | low | 11284 | 6 | 2 | 待复核 |
| Java 第一个类（java_first_class） | low | 12995 | 5 | 2 | 待复核 |
| JVM 垃圾回收与性能调优（java_gc_tuning） | low | 10496 | 5 | 2 | 待复核 |
| 继承、接口与多态（java_inheritance） | low | 11041 | 6 | 2 | 待复核 |
| Lambda 与 Stream API（java_lambda_stream） | low | 12833 | 6 | 2 | 待复核 |
| Java 循环入门（java_loops） | low | 14666 | 5 | 2 | 待复核 |
| Java 方法入门（java_methods_intro） | low | 14776 | 5 | 2 | 待复核 |
| 现代 Java：Record、Sealed 与模式匹配（java_modern_features） | low | 10136 | 6 | 2 | 待复核 |
| 类与对象（java_oop） | low | 10202 | 6 | 2 | 待复核 |
| 实战：Spring Boot REST API（java_project） | low | 18221 | 6 | 2 | 待复核 |
| 实战：Java 库存管理 REST 服务（java_project_inventory） | low | 13919 | 6 | 2 | 待复核 |
| 实战：Java 并发订单处理服务（java_project_order_concurrency） | low | 13960 | 6 | 2 | 待复核 |
| 构建、测试与生态（java_tooling） | low | 13607 | 6 | 2 | 待复核 |
| 变量、类型与字符串（java_types） | low | 10664 | 6 | 2 | 待复核 |
| Java 变量与输出（java_variables_output） | low | 10367 | 5 | 2 | 待复核 |
| Java 虚拟线程与结构化并发（java_virtual_threads） | low | 11258 | 5 | 2 | 待复核 |

## javascript-1 · JavaScript

- 课程数：21 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 21
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 数组与常用方法（js_arrays） | low | 10960 | 6 | 2 | 待复核 |
| 异步编程（js_async） | low | 13044 | 6 | 2 | 待复核 |
| JavaScript 与运行环境（js_basics） | low | 10743 | 6 | 2 | 待复核 |
| JavaScript 条件与循环（js_conditions_loops） | low | 10918 | 5 | 2 | 待复核 |
| JavaScript 控制台入门（js_console_start） | low | 15422 | 5 | 2 | 待复核 |
| DOM 与事件（js_dom_events） | low | 12471 | 6 | 2 | 待复核 |
| JavaScript DOM 入门（js_dom_intro） | low | 12234 | 5 | 2 | 待复核 |
| 错误处理与调试（js_errors_debugging） | low | 11394 | 6 | 2 | 待复核 |
| JavaScript 执行上下文与闭包（js_execution_context） | low | 11833 | 6 | 2 | 待复核 |
| 函数、作用域与 this（js_functions） | low | 9979 | 6 | 2 | 待复核 |
| JavaScript 函数入门（js_functions_intro） | low | 14954 | 5 | 2 | 待复核 |
| JavaScript 内存管理与垃圾回收（js_memory_gc） | low | 12722 | 6 | 2 | 待复核 |
| 模块化与工程化（js_modules_tooling） | low | 11836 | 6 | 2 | 待复核 |
| Node.js 后端工程（js_node_backend） | low | 11049 | 5 | 2 | 待复核 |
| 对象、原型与类（js_objects） | low | 11269 | 6 | 2 | 待复核 |
| 运算符与控制流（js_operators_control） | low | 9915 | 6 | 2 | 待复核 |
| 实战：Vite + React 待办应用（js_project） | low | 16255 | 6 | 2 | 待复核 |
| 实战：Node.js + Express REST API（js_project_node_api） | low | 14444 | 6 | 2 | 待复核 |
| 实战：JavaScript 实时聊天室（js_project_realtime_chat） | low | 14055 | 6 | 2 | 待复核 |
| 变量、类型与类型转换（js_types） | low | 10222 | 6 | 2 | 待复核 |
| JavaScript 变量与类型入门（js_variables_types_intro） | low | 15176 | 5 | 2 | 待复核 |

## kotlin-1 · Kotlin

- 课程数：14 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 14
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Kotlin Android 架构（kotlin_android） | low | 12406 | 6 | 2 | 待复核 |
| Kotlin 基础与空安全（kotlin_basics） | low | 14682 | 6 | 2 | 待复核 |
| Kotlin 集合、序列与函数式操作（kotlin_collections） | low | 12185 | 6 | 2 | 待复核 |
| Kotlin 条件判断（kotlin_conditions） | low | 13152 | 5 | 2 | 待复核 |
| Kotlin 协程与 Flow（kotlin_coroutines） | low | 12802 | 6 | 2 | 待复核 |
| Kotlin 第一个程序（kotlin_first_program） | low | 13195 | 5 | 2 | 待复核 |
| Kotlin 函数、Lambda 与扩展（kotlin_functions） | low | 12012 | 6 | 2 | 待复核 |
| Kotlin 函数入门（kotlin_functions_intro） | low | 14935 | 5 | 2 | 待复核 |
| Kotlin 循环入门（kotlin_loops） | low | 15036 | 5 | 2 | 待复核 |
| Kotlin 类、对象与属性（kotlin_oop） | low | 11198 | 6 | 2 | 待复核 |
| 实战：Kotlin Android 客户端（kotlin_project） | low | 12604 | 5 | 2 | 待复核 |
| 实战：Kotlin 命令行记账工具（kotlin_project_cli_ledger） | low | 11670 | 5 | 2 | 待复核 |
| Kotlin 测试与协程测试（kotlin_testing） | low | 11659 | 5 | 2 | 待复核 |
| Kotlin 变量与空值（kotlin_variables_null） | low | 13189 | 5 | 2 | 待复核 |

## math-1 · 数学基础

- 课程数：9 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 9
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 微积分与梯度下降（math_calculus_gradient） | low | 10508 | 6 | 2 | 待复核 |
| 凸优化与约束优化（math_convex_optimization） | low | 9784 | 6 | 2 | 待复核 |
| 特征值、SVD 与降维（math_eigen_svd） | low | 10530 | 6 | 2 | 待复核 |
| 图论与组合数学（math_graph_combinatorics） | low | 9428 | 6 | 2 | 待复核 |
| 信息论：熵与交叉熵（math_information_theory） | low | 9225 | 6 | 2 | 待复核 |
| 数值线性代数（math_numerical_linear_algebra） | low | 8695 | 6 | 2 | 待复核 |
| 概率统计与假设检验（math_probability_stats） | low | 9495 | 6 | 2 | 待复核 |
| 集合与函数入门（math_set_function_intro） | low | 11682 | 6 | 2 | 待复核 |
| 线性代数：向量与矩阵（math_vectors_matrices） | low | 9680 | 6 | 2 | 待复核 |

## network-1 · 网络

- 课程数：24 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 24
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 认证与授权（auth_oauth） | low | 10474 | 6 | 2 | 待复核 |
| CDN、代理与缓存（cdn_proxy） | low | 10516 | 6 | 2 | 待复核 |
| DNS 域名解析（dns） | low | 10818 | 6 | 3 | 待复核 |
| HTTP/2 与 HTTP/3（http2_http3） | low | 10658 | 6 | 2 | 待复核 |
| HTTP 基础（http_basics） | low | 9730 | 6 | 2 | 待复核 |
| IP 与端口入门（ip_port_intro） | low | 12948 | 6 | 2 | 待复核 |
| IP、子网与传输层深入（ip_transport） | low | 11327 | 6 | 2 | 待复核 |
| 链路层：以太网、ARP 与交换机（link_layer） | low | 9149 | 6 | 2 | 待复核 |
| 网络攻击与防护（network_attacks） | low | 11962 | 6 | 2 | 待复核 |
| BGP 与互联网路由（network_bgp） | low | 9925 | 5 | 2 | 待复核 |
| IPv6 原理与迁移（network_ipv6） | low | 10165 | 6 | 2 | 待复核 |
| 网络分层入门（network_layers_intro） | low | 11737 | 5 | 2 | 待复核 |
| NAT、隧道与 VPN（network_nat_vpn） | low | 12031 | 5 | 2 | 待复核 |
| P2P 网络与 NAT 穿透（network_p2p） | low | 9738 | 5 | 2 | 待复核 |
| 网络性能调优（network_performance） | low | 9372 | 5 | 2 | 待复核 |
| 实战：抓包分析一次真实请求（network_project） | low | 13622 | 6 | 2 | 待复核 |
| SMTP、邮件协议与反垃圾（network_smtp） | low | 9934 | 5 | 2 | 待复核 |
| 渗透测试基础（pentest_basics） | low | 9534 | 6 | 2 | 待复核 |
| Socket 编程实战（socket_programming） | low | 13468 | 6 | 2 | 待复核 |
| TCP/IP 协议栈（tcp_ip） | low | 9568 | 6 | 3 | 待复核 |
| HTTPS 与 TLS（tls） | low | 10653 | 6 | 2 | 待复核 |
| Web 安全攻防（web_security） | low | 9906 | 6 | 2 | 待复核 |
| WebSocket 与实时通信（websocket） | low | 9979 | 6 | 2 | 待复核 |
| 无线与移动网络（wireless_mobile） | low | 11252 | 6 | 2 | 待复核 |

## os-1 · 操作系统

- 课程数：17 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 17
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 死锁（deadlock） | low | 9301 | 6 | 3 | 待复核 |
| 文件系统基础（file_system） | low | 9810 | 6 | 2 | 待复核 |
| 进程间通信与 IO 模型（ipc_io） | low | 10397 | 6 | 2 | 待复核 |
| 系统启动与权限安全（os_boot_security） | low | 9497 | 6 | 2 | 待复核 |
| cgroups、namespaces 与容器（os_cgroups_namespaces） | low | 10943 | 6 | 2 | 待复核 |
| 文件系统实现与 RAID（os_filesystem_impl） | low | 9455 | 6 | 2 | 待复核 |
| I/O 调度与块设备（os_io_scheduling） | low | 10761 | 6 | 2 | 待复核 |
| io_uring 与异步 I/O（os_io_uring） | low | 9203 | 5 | 2 | 待复核 |
| 操作系统内核架构（os_kernel_arch） | low | 12295 | 6 | 2 | 待复核 |
| Linux 性能与故障排查（os_linux_troubleshooting） | low | 10778 | 5 | 2 | 待复核 |
| 实战：实现一个多线程任务队列（os_project） | low | 11650 | 6 | 2 | 待复核 |
| 实时操作系统与确定性（os_rtos） | low | 12340 | 5 | 2 | 待复核 |
| 同步机制与经典问题（os_synchronization） | low | 9297 | 6 | 2 | 待复核 |
| 进程与线程（process_thread） | low | 11256 | 6 | 3 | 待复核 |
| 进程与线程入门（process_thread_intro） | low | 11068 | 6 | 2 | 待复核 |
| 进程调度（scheduling） | low | 10977 | 6 | 2 | 待复核 |
| 虚拟内存与分页（virtual_memory） | low | 8906 | 6 | 3 | 待复核 |

## project_practice-1 · 项目实战

- 课程数：18 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 18
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 算法工程化与性能验证实战（project_algorithm_engineering） | low | 14152 | 5 | 2 | 待复核 |
| 编码工作流：小步提交与可评审的改动（project_coding_workflow） | low | 11410 | 6 | 2 | 待复核 |
| 操作系统与并发实战（project_concurrency_runtime） | low | 13841 | 5 | 2 | 待复核 |
| 数据工程 ETL 与质量治理实战（project_data_etl） | low | 14149 | 5 | 2 | 待复核 |
| 数据库性能调优实战（project_database_tuning） | low | 13348 | 5 | 2 | 待复核 |
| 实战：慢接口调试与性能定位（project_debug_performance_triage） | low | 12372 | 5 | 2 | 待复核 |
| 部署与运维：稳定发布与快速回滚（project_deploy_ops） | low | 11330 | 5 | 2 | 待复核 |
| DevOps CI/CD 流水线实战（project_devops_pipeline） | low | 14204 | 5 | 2 | 待复核 |
| 面试冲刺：算法编码与系统设计高频题（project_interview_coding_system_design） | low | 12552 | 5 | 2 | 待复核 |
| 移动端离线优先 App 实战（project_mobile_offline_app） | low | 14134 | 5 | 2 | 待复核 |
| 网络抓包与协议分析实战（project_network_capture_analysis） | low | 14544 | 5 | 2 | 待复核 |
| 实战：Python CLI 待办工具（project_python_cli_todo） | low | 12175 | 5 | 2 | 待复核 |
| 实战：本地 RAG 客服 Agent（project_rag_agent_service） | low | 12389 | 5 | 2 | 待复核 |
| 需求到设计：把想法拆成可交付任务（project_requirements_design） | low | 11290 | 6 | 2 | 待复核 |
| 实战：REST API 与 SQLite 事务服务（project_rest_api_sqlite） | low | 12992 | 5 | 2 | 待复核 |
| 复盘与改进：让团队一次比一次快（project_retro_improve） | low | 12631 | 5 | 2 | 待复核 |
| 安全攻防与防御实战（project_security_lab） | low | 12968 | 5 | 2 | 待复核 |
| 测试与质量门禁：把问题挡在上线前（project_testing_quality） | low | 11706 | 5 | 2 | 待复核 |

## python-1 · Python

- 课程数：21 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 21
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Python 基础语法（python_basics） | low | 13953 | 6 | 2 | 待复核 |
| 并发与异步（python_concurrency） | low | 11493 | 6 | 2 | 待复核 |
| Python 上下文管理器与迭代器协议（python_context_iterators） | low | 9569 | 6 | 2 | 待复核 |
| 控制流与推导式（python_control_flow） | low | 9119 | 6 | 2 | 待复核 |
| 列表、元组、字典与集合（python_data_structures） | low | 10014 | 6 | 2 | 待复核 |
| Python 装饰器与生成器（python_decorators_generators） | low | 12720 | 6 | 2 | 待复核 |
| 异常处理与文件操作（python_errors_files） | low | 11386 | 6 | 2 | 待复核 |
| Python 第一个脚本（python_first_script） | low | 10363 | 5 | 2 | 待复核 |
| 函数（python_functions） | low | 10236 | 6 | 2 | 待复核 |
| Python 条件判断（python_if_else） | low | 10043 | 5 | 2 | 待复核 |
| Python 输入与输出（python_input_output） | low | 13180 | 5 | 2 | 待复核 |
| Python 列表与字典入门（python_list_dict_basics） | low | 14835 | 5 | 2 | 待复核 |
| Python 循环入门（python_loops） | low | 14471 | 5 | 2 | 待复核 |
| 模块、包与虚拟环境（python_modules_stdlib） | low | 12108 | 6 | 2 | 待复核 |
| 类与对象（python_oop） | low | 11190 | 6 | 2 | 待复核 |
| Python 打包、发布与性能（python_packaging_performance） | low | 11358 | 6 | 2 | 待复核 |
| 实战：爬虫与数据分析（python_project） | low | 16542 | 6 | 2 | 待复核 |
| 实战：FastAPI 订单服务（python_project_api） | low | 13866 | 6 | 2 | 待复核 |
| 实战：CSV 到 SQLite 的 ETL 流水线（python_project_etl） | low | 13293 | 6 | 2 | 待复核 |
| 类型注解与测试（python_typing_testing） | low | 11272 | 6 | 2 | 待复核 |
| 变量与数据类型（python_variables） | low | 9451 | 6 | 2 | 待复核 |

## rust-1 · Rust

- 课程数：18 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 18
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Rust 异步编程与 tokio（rust_async_tokio） | low | 11807 | 6 | 2 | 待复核 |
| Rust 基础（rust_basics） | low | 10609 | 6 | 2 | 待复核 |
| Rust Cargo 第一个程序（rust_cargo_first） | low | 13273 | 6 | 2 | 待复核 |
| Rust 实战：命令行工具（rust_cli_project） | low | 15489 | 6 | 2 | 待复核 |
| Rust 并发与 Cargo 工程（rust_concurrency_cargo） | low | 10574 | 6 | 2 | 待复核 |
| Rust 条件判断（rust_conditions） | low | 10837 | 5 | 2 | 待复核 |
| Rust 错误处理、迭代器与异步（rust_errors_iterators） | low | 10905 | 6 | 2 | 待复核 |
| Rust 函数入门（rust_functions_intro） | low | 14361 | 5 | 2 | 待复核 |
| Rust 循环入门（rust_loops） | low | 14457 | 5 | 2 | 待复核 |
| Rust 宏、WASM 与跨平台（rust_macros_wasm） | low | 10969 | 6 | 2 | 待复核 |
| Rust 所有权、借用与生命周期（rust_ownership） | low | 11427 | 6 | 2 | 待复核 |
| 实战：Rust + Axum REST API（rust_project_axum_api） | low | 13867 | 6 | 2 | 待复核 |
| 实战：Rust 并发下载器（rust_project_downloader） | low | 13740 | 6 | 2 | 待复核 |
| Rust 智能指针与内部可变性（rust_smart_pointers） | low | 10943 | 6 | 2 | 待复核 |
| Rust trait、泛型与关联类型（rust_traits_generics） | low | 11358 | 6 | 2 | 待复核 |
| Rust 类型系统：Option、Result 与 trait（rust_types_traits） | low | 11370 | 6 | 2 | 待复核 |
| Rust unsafe、FFI 与生态（rust_unsafe_ffi） | low | 10909 | 6 | 2 | 待复核 |
| Rust 变量与可变性（rust_variables_mutability） | low | 12976 | 6 | 2 | 待复核 |

## security-1 · 安全与合规

- 课程数：15 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 15
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 安全建议与威胁模型对应，示例不鼓励真实环境中的危险操作。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 密码与哈希入门（password_hash_intro） | low | 11028 | 6 | 2 | 待复核 |
| 认证、会话与令牌安全（security_auth_session） | low | 11405 | 6 | 2 | 待复核 |
| 云安全与 IAM（security_cloud） | low | 10600 | 5 | 2 | 待复核 |
| 安全概念入门（security_concept_intro） | low | 11161 | 6 | 2 | 待复核 |
| 容器与 Kubernetes 安全（security_container_k8s） | low | 11514 | 5 | 2 | 待复核 |
| 模糊测试与漏洞验证（security_fuzzing） | low | 10786 | 5 | 2 | 待复核 |
| 安全事件响应（security_incident） | low | 10677 | 5 | 2 | 待复核 |
| OWASP Top 10 实战（security_owasp_top10） | low | 11842 | 6 | 2 | 待复核 |
| 隐私合规与数据分级（security_privacy） | low | 10942 | 5 | 2 | 待复核 |
| 实战：安全审计与漏洞修复（security_project） | low | 12395 | 5 | 2 | 待复核 |
| 安全开发生命周期实战（security_sdl） | low | 12008 | 5 | 2 | 待复核 |
| 密钥与配置安全（security_secrets） | low | 10592 | 5 | 2 | 待复核 |
| 安全编码与输入校验（security_secure_coding） | low | 11282 | 6 | 2 | 待复核 |
| 软件供应链安全（security_supply_chain） | low | 12566 | 5 | 2 | 待复核 |
| 威胁建模与 STRIDE（security_threat_model） | low | 12737 | 6 | 2 | 待复核 |

## shell-1 · Shell

- 课程数：22 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 22
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Shell 高级自动化与可观测性（shell_automation_advanced） | low | 11537 | 6 | 2 | 待复核 |
| Shell 与 Bash 脚本（shell_bash） | low | 10446 | 6 | 2 | 待复核 |
| CI 脚本模板库（shell_ci_templates） | low | 10412 | 6 | 2 | 待复核 |
| Shell 条件判断（shell_conditions） | low | 10401 | 5 | 2 | 待复核 |
| Shell 与 Docker/K8s 交互（shell_container） | low | 11441 | 6 | 2 | 待复核 |
| Shell 第一个脚本（shell_first_script） | low | 13082 | 6 | 2 | 待复核 |
| Shell 流程控制与函数（shell_flow） | low | 10268 | 6 | 2 | 待复核 |
| 结构化数据处理：jq 与 yq（shell_json_yaml） | low | 11179 | 6 | 2 | 待复核 |
| Shell 循环入门（shell_loops） | low | 14781 | 5 | 2 | 待复核 |
| 系统运维脚本实战（shell_ops_scripts） | low | 13943 | 6 | 2 | 待复核 |
| Shell 文本处理流水线（shell_pipeline） | low | 9745 | 6 | 2 | 待复核 |
| Shell 管道入门（shell_pipeline_intro） | low | 14734 | 5 | 2 | 待复核 |
| Shell 可移植性与 POSIX 兼容（shell_portability） | low | 11182 | 6 | 2 | 待复核 |
| Shell 进程控制、定时任务与日志（shell_process_cron） | low | 10083 | 6 | 2 | 待复核 |
| 实战：Shell 零停机部署脚本（shell_project_deploy） | low | 13087 | 6 | 2 | 待复核 |
| 实战：Shell 日志分析与告警（shell_project_log_analysis） | low | 13626 | 6 | 2 | 待复核 |
| 健壮与可移植的 Shell 脚本（shell_robust） | low | 10176 | 6 | 2 | 待复核 |
| Shell 脚本工程化（shell_script_engineering） | low | 10121 | 6 | 2 | 待复核 |
| Shell 脚本安全加固（shell_security） | low | 10681 | 6 | 2 | 待复核 |
| Shell 脚本安全加固（进阶）（shell_security_hardening） | low | 10999 | 6 | 2 | 待复核 |
| 文本处理进阶：awk、sed 与正则（shell_text_advanced） | low | 10011 | 6 | 2 | 待复核 |
| Shell 变量与参数（shell_variables_args） | low | 13029 | 6 | 2 | 待复核 |

## software_engineering-1 · 软件工程

- 课程数：12 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 12
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 设计模式与 SOLID（design_patterns） | low | 11758 | 6 | 2 | 待复核 |
| 需求分析与建模（requirements_modeling） | low | 9478 | 6 | 2 | 待复核 |
| 安全开发生命周期（SDL）（sdl_security） | low | 9440 | 6 | 2 | 待复核 |
| 代码评审方法与实践（se_code_review） | low | 10022 | 6 | 2 | 待复核 |
| On-Call 与告警治理（se_oncall） | low | 10121 | 6 | 2 | 待复核 |
| 故障复盘与事故管理（se_postmortem） | low | 11131 | 6 | 2 | 待复核 |
| 质量度量与工程门禁（se_quality_metrics） | low | 10202 | 6 | 2 | 待复核 |
| TDD 与重构（se_tdd_refactor） | low | 9056 | 6 | 2 | 待复核 |
| 技术债务管理（se_tech_debt） | low | 10099 | 6 | 2 | 待复核 |
| 技术写作与文档工程（se_tech_writing） | low | 10158 | 6 | 2 | 待复核 |
| 测试用例设计方法（se_test_design） | low | 9607 | 6 | 2 | 待复核 |
| 测试策略（testing_strategy） | low | 9434 | 6 | 2 | 待复核 |

## swift-1 · Swift

- 课程数：14 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 14
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Swift 并发与 async/await（swift_async） | low | 13034 | 6 | 2 | 待复核 |
| Swift 基础与可选类型（swift_basics） | low | 14702 | 6 | 2 | 待复核 |
| Swift 集合与泛型（swift_collections） | low | 11769 | 6 | 2 | 待复核 |
| Swift 条件判断（swift_conditions） | low | 12910 | 5 | 2 | 待复核 |
| Swift 常量与变量（swift_constants_variables） | low | 11358 | 5 | 2 | 待复核 |
| Swift 第一个程序（swift_first_program） | low | 11050 | 5 | 2 | 待复核 |
| Swift 函数、闭包与协议（swift_functions） | low | 11617 | 6 | 2 | 待复核 |
| Swift 函数入门（swift_functions_intro） | low | 14838 | 5 | 2 | 待复核 |
| Swift 循环入门（swift_loops） | low | 14754 | 5 | 2 | 待复核 |
| Swift 结构体、类与 ARC（swift_oop） | low | 11302 | 6 | 2 | 待复核 |
| 实战：SwiftUI iOS 客户端（swift_project） | low | 12223 | 5 | 2 | 待复核 |
| 实战：Swift 命令行指标分析工具（swift_project_cli_metrics） | low | 11950 | 5 | 2 | 待复核 |
| SwiftUI 与状态管理（swift_swiftui） | low | 9555 | 6 | 2 | 待复核 |
| Swift 测试与性能（swift_testing） | low | 11609 | 5 | 2 | 待复核 |

## toolchain-1 · 工具链

- 课程数：14 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 14
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| CI/CD 与 GitHub Actions（ci_cd） | low | 8816 | 6 | 2 | 待复核 |
| 命令行基础（cli） | low | 10834 | 6 | 2 | 待复核 |
| 命令行入门（cli_intro） | low | 10696 | 6 | 2 | 待复核 |
| 调试与日志（debugging） | low | 10809 | 6 | 2 | 待复核 |
| Docker 容器基础（docker） | low | 9463 | 6 | 2 | 待复核 |
| API 网关与负载均衡（gateway） | low | 9330 | 6 | 2 | 待复核 |
| Git 版本控制（git_basics） | low | 10588 | 6 | 2 | 待复核 |
| Git 入门（git_intro） | low | 12430 | 6 | 2 | 待复核 |
| GitOps 与 ArgoCD（gitops_argocd） | low | 9287 | 6 | 2 | 待复核 |
| Kubernetes 基础（kubernetes） | low | 10325 | 6 | 2 | 待复核 |
| Linux 性能分析（linux_performance） | low | 9106 | 6 | 2 | 待复核 |
| 可观测性：日志、指标与链路（observability） | low | 9594 | 6 | 2 | 待复核 |
| Terraform 与基础设施即代码（terraform） | low | 10131 | 6 | 2 | 待复核 |
| 实战：搭一条完整 CI/CD 流水线（toolchain_project） | low | 12464 | 6 | 2 | 待复核 |

## typescript-1 · TypeScript

- 课程数：22 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 22
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| TypeScript 数组与对象（ts_arrays_objects） | low | 12400 | 5 | 2 | 待复核 |
| TypeScript 基础类型（ts_basic_types） | low | 15080 | 5 | 2 | 待复核 |
| 类型检查与构建性能优化（ts_build_performance） | low | 9958 | 6 | 2 | 待复核 |
| TypeScript 构建工具链与测试（ts_build_test） | low | 10938 | 6 | 2 | 待复核 |
| TypeScript 进阶类型与框架实践（ts_decorators_pro） | low | 11970 | 6 | 2 | 待复核 |
| TypeScript 第一个类型（ts_first_types） | low | 13395 | 6 | 2 | 待复核 |
| TypeScript 实战：全栈类型安全（ts_fullstack_project） | low | 14717 | 6 | 2 | 待复核 |
| TypeScript 函数类型（ts_function_types） | low | 13408 | 5 | 2 | 待复核 |
| TypeScript 接口入门（ts_interface_intro） | low | 11809 | 5 | 2 | 待复核 |
| Monorepo 工程实践（ts_monorepo） | low | 10056 | 6 | 2 | 待复核 |
| TypeScript 类型收窄与泛型（ts_narrowing_generics） | low | 12313 | 6 | 2 | 待复核 |
| TypeScript Node 后端开发（ts_node_backend） | low | 11171 | 6 | 2 | 待复核 |
| TypeScript 编译与运行性能（ts_performance） | low | 9517 | 6 | 2 | 待复核 |
| TypeScript 工程配置与实践（ts_project） | low | 14272 | 6 | 2 | 待复核 |
| 实战：TypeScript 类型安全 CLI（ts_project_cli） | low | 14625 | 6 | 2 | 待复核 |
| 实战：TypeScript 实时监控面板（ts_project_websocket_dashboard） | low | 14427 | 6 | 2 | 待复核 |
| TypeScript 运行时校验与边界（ts_runtime_validation） | low | 12248 | 6 | 2 | 待复核 |
| TypeScript 测试策略（ts_testing） | low | 11201 | 6 | 2 | 待复核 |
| TypeScript 类型体操进阶（ts_type_challenges） | low | 10299 | 6 | 2 | 待复核 |
| TypeScript 类型级编程（ts_type_level） | low | 11496 | 6 | 2 | 待复核 |
| TypeScript 工具类型与声明文件（ts_utility_types） | low | 11148 | 6 | 2 | 待复核 |
| TypeScript 类型系统（typescript） | low | 11432 | 6 | 2 | 待复核 |

## visual_guide-1 · 图解专题

- 课程数：21 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 21
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 图解 B+ 树与数据库索引（visual_btree_index） | low | 10281 | 5 | 2 | 待复核 |
| 图解调用栈与递归（visual_call_stack） | low | 10719 | 6 | 2 | 待复核 |
| 图解 CDN 缓存与回源（visual_cdn_cache） | low | 9045 | 5 | 2 | 待复核 |
| 图解并发调度：线程、协程与 Goroutine（visual_concurrency_schedule） | low | 10583 | 5 | 2 | 待复核 |
| 图解一致性哈希与数据分片（visual_consistent_hashing） | low | 10972 | 5 | 2 | 待复核 |
| 图解数据库事务隔离级别（visual_db_isolation） | low | 10407 | 5 | 2 | 待复核 |
| 图解事件循环：同步、微任务与宏任务（visual_event_loop） | low | 9397 | 6 | 2 | 待复核 |
| 图解 Git 三区与提交流转（visual_git_states） | low | 8765 | 5 | 2 | 待复核 |
| 图解一次网页请求的完整链路（visual_http_timeline） | low | 9254 | 5 | 2 | 待复核 |
| 图解 HTTPS 证书链与 TLS 握手（visual_https_cert） | low | 10208 | 5 | 2 | 待复核 |
| 图解 JVM 内存模型与垃圾回收（visual_jvm_memory） | low | 10050 | 5 | 2 | 待复核 |
| 图解 Kubernetes 调度与探针（visual_k8s_scheduling） | low | 9020 | 5 | 2 | 待复核 |
| 图解 Kafka 分区、副本与再平衡（visual_kafka_partition） | low | 9845 | 5 | 2 | 待复核 |
| 图解大模型推理与显存占用（visual_llm_inference） | low | 10637 | 5 | 2 | 待复核 |
| 图解内存布局：栈、堆与引用（visual_memory_layout） | low | 8824 | 6 | 2 | 待复核 |
| 图解消息队列投递语义（visual_mq_delivery） | low | 11196 | 5 | 2 | 待复核 |
| 图解 OAuth 2.0 授权码流程与 PKCE（visual_oauth_flow） | low | 10123 | 5 | 2 | 待复核 |
| 图解 RAG 检索增强生成流程（visual_rag_pipeline） | low | 11308 | 5 | 2 | 待复核 |
| 图解限流、熔断与降级（visual_rate_limit_circuit） | low | 9051 | 5 | 2 | 待复核 |
| 图解 TCP 握手、挥手与拥塞控制（visual_tcp_handshake） | low | 10191 | 5 | 2 | 待复核 |
| 图解向量检索与 HNSW 索引（visual_vector_index） | low | 8998 | 5 | 2 | 待复核 |

