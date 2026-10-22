# 人工复核批次台账

- 生成时间：2026-10-08T09:59:44.036918Z
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
| Agent 成本与性能优化（agent_cost_performance） | low | 14229 | 6 | 2 | 待复核 |
| Agent 记忆系统（agent_memory） | low | 14149 | 6 | 2 | 待复核 |
| A2A Agent 协作协议（ai_a2a） | low | 15958 | 6 | 2 | 待复核 |
| AI Agent 基础（ai_agent_basics） | low | 14386 | 6 | 3 | 待复核 |
| Agent 评测实战（ai_agent_evaluation） | low | 18706 | 6 | 2 | 待复核 |
| Agent 安全、权限与沙箱（ai_agent_security） | low | 16069 | 5 | 2 | 待复核 |
| AI、机器学习与生成式 AI（ai_basics） | low | 14006 | 6 | 2 | 待复核 |
| 浏览器 Agent（ai_browser_agent） | low | 15536 | 5 | 2 | 待复核 |
| 代码 Agent 与软件工程自动化（ai_coding_agent） | low | 15814 | 5 | 2 | 待复核 |
| AI 编程助手与代码生成（ai_coding_assistant） | low | 14281 | 6 | 2 | 待复核 |
| Computer Use 与桌面自动化（ai_computer_use） | low | 16443 | 5 | 2 | 待复核 |
| AI 概念入门（ai_concept_intro） | low | 14329 | 6 | 2 | 待复核 |
| 上下文工程（ai_context_engineering） | low | 13722 | 6 | 2 | 待复核 |
| 数据工程与标注（ai_data_engineering） | low | 14431 | 6 | 2 | 待复核 |
| 深度学习与大语言模型（ai_deep_learning_llm） | low | 15117 | 6 | 3 | 待复核 |
| 扩散模型与图像生成（ai_diffusion） | low | 15859 | 5 | 2 | 待复核 |
| 嵌入、向量检索与 RAG（ai_embeddings_rag） | low | 16440 | 6 | 2 | 待复核 |
| AI 应用工程化（ai_engineering） | low | 15123 | 6 | 2 | 待复核 |
| 模型微调与本地部署（ai_fine_tuning_deployment） | low | 15323 | 6 | 2 | 待复核 |
| AI 治理、合规与风险（ai_governance） | low | 15648 | 5 | 2 | 待复核 |
| GraphRAG 与知识图谱检索（ai_graphrag） | low | 16439 | 5 | 2 | 待复核 |
| 安全护栏与内容审核（ai_guardrails） | low | 15882 | 5 | 2 | 待复核 |
| MCP 模型上下文协议（ai_mcp） | low | 17295 | 6 | 2 | 待复核 |
| MLOps 与模型上线（ai_mlops） | low | 14548 | 5 | 2 | 待复核 |

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
| 大模型推理服务与 GPU 优化（ai_model_serving） | low | 15805 | 5 | 2 | 待复核 |
| 多智能体与编排（ai_multi_agent） | low | 14709 | 6 | 2 | 待复核 |
| 多模态 AI：图像、语音与视频（ai_multimodal） | low | 14032 | 6 | 2 | 待复核 |
| 提示工程（ai_prompt_engineering） | low | 13688 | 6 | 2 | 待复核 |
| 实战：文档问答助手（RAG + Agent）（ai_rag_agent_project） | low | 19241 | 6 | 2 | 待复核 |
| Realtime API 与语音交互（ai_realtime_api） | low | 16483 | 5 | 2 | 待复核 |
| 实时语音对话（ai_realtime_voice） | low | 14471 | 6 | 2 | 待复核 |
| 推荐系统基础与排序（ai_recommender） | low | 14173 | 5 | 2 | 待复核 |
| 强化学习基础（ai_reinforcement_learning） | low | 14625 | 5 | 2 | 待复核 |
| 时间序列预测（ai_time_series） | low | 14360 | 5 | 2 | 待复核 |
| 工具调用与结构化输出（ai_tool_calling） | low | 16505 | 5 | 2 | 待复核 |
| 模型训练与分布式（ai_training） | low | 13946 | 6 | 2 | 待复核 |
| 视觉语言模型 VLM（ai_vlm） | low | 15914 | 5 | 2 | 待复核 |
| 机器学习核心概念（ml_fundamentals） | low | 15527 | 6 | 2 | 待复核 |
| 模型评测与选型（model_evaluation） | low | 14145 | 6 | 2 | 待复核 |
| 多模态 RAG（multimodal_rag） | low | 13301 | 6 | 2 | 待复核 |
| 提示词入门（prompt_intro） | low | 15580 | 6 | 2 | 待复核 |
| 向量数据库选型与调优（vector_db） | low | 14264 | 6 | 2 | 待复核 |

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
| 计算几何基础（algo_computational_geometry） | low | 15341 | 5 | 2 | 待复核 |
| 最小生成树与图剪枝（algo_mst） | low | 17185 | 6 | 2 | 待复核 |
| NP 完全性与近似算法（algo_np_approximation） | low | 14763 | 5 | 2 | 待复核 |
| 持久化数据结构与并行算法（algo_persistent_parallel） | low | 15154 | 5 | 2 | 待复核 |
| 最短路算法专题（algo_shortest_paths） | low | 17037 | 6 | 2 | 待复核 |
| 拓扑排序与 DAG 应用（algo_topological） | low | 15183 | 5 | 2 | 待复核 |
| 算法入门（algorithm_intro） | low | 14781 | 5 | 2 | 待复核 |
| 实战：把数据结构用起来（algorithms_project） | low | 16802 | 6 | 2 | 待复核 |
| 回溯算法（backtracking） | low | 12827 | 6 | 2 | 待复核 |
| 平衡树实现（balanced_tree） | low | 14882 | 6 | 2 | 待复核 |
| 二分答案（binary_answer） | low | 15228 | 6 | 2 | 待复核 |
| 二分查找（binary_search） | low | 13686 | 6 | 2 | 待复核 |
| 位运算技巧（bit_manipulation） | low | 14718 | 6 | 2 | 待复核 |
| 冒泡排序（bubble_sort） | low | 14306 | 6 | 2 | 待复核 |
| 缓存淘汰算法（cache_eviction） | low | 15020 | 6 | 2 | 待复核 |
| 动态规划入门（dynamic_programming） | low | 15112 | 6 | 2 | 待复核 |
| 图与图算法（graph） | low | 14870 | 6 | 2 | 待复核 |
| 贪心算法（greedy） | low | 15565 | 6 | 2 | 待复核 |
| 哈希表（hash_table） | low | 14390 | 6 | 3 | 待复核 |
| 线性查找入门（linear_search_intro） | low | 15182 | 6 | 2 | 待复核 |
| 链表（linked_list） | low | 14142 | 6 | 2 | 待复核 |
| 单调栈与单调队列（monotonic_stack） | low | 14880 | 6 | 2 | 待复核 |
| 网络流与二分图匹配（network_flow） | low | 16230 | 6 | 2 | 待复核 |
| 前缀和与差分（prefix_sum） | low | 15195 | 6 | 2 | 待复核 |

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
| 概率数据结构（probabilistic_structures） | low | 16131 | 6 | 2 | 待复核 |
| 树状数组与线段树（segment_tree） | low | 14267 | 6 | 2 | 待复核 |
| 排序算法家族（sorting） | low | 15611 | 6 | 2 | 待复核 |
| 基数排序、桶排序与外部排序（sorting_advanced） | low | 15866 | 6 | 2 | 待复核 |
| 栈与队列（stack_queue） | low | 15906 | 6 | 2 | 待复核 |
| 字符串匹配（string_matching） | low | 13633 | 6 | 2 | 待复核 |
| 时间复杂度（time_complexity） | low | 15730 | 6 | 3 | 待复核 |
| 树与二叉搜索树（tree_bst） | low | 14204 | 6 | 2 | 待复核 |
| 字典树（Trie）（trie） | low | 15385 | 6 | 2 | 待复核 |
| 双指针与滑动窗口（two_pointers） | low | 14571 | 6 | 2 | 待复核 |
| 并查集（union_find） | low | 13882 | 6 | 2 | 待复核 |

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
| 区块链基础与密码学原语（blockchain_basics） | low | 16713 | 5 | 2 | 待复核 |
| 比特币、UTXO 与工作量证明（blockchain_bitcoin_consensus） | low | 16606 | 5 | 2 | 待复核 |
| DeFi 风险与智能合约审计（blockchain_defi_security） | low | 16086 | 5 | 2 | 待复核 |
| 以太坊、EVM 与智能合约（blockchain_ethereum_smart_contract） | low | 16465 | 5 | 2 | 待复核 |
| 扩容、Rollup 与跨链桥（blockchain_scaling_layer2） | low | 16808 | 5 | 2 | 待复核 |
| 项目：智能合约审计实战（chain_audit_project） | low | 17462 | 5 | 2 | 待复核 |
| 预言机与跨链桥（chain_oracle_bridge） | low | 14924 | 5 | 2 | 待复核 |
| 代币标准与合约接口（chain_token_standards） | low | 15627 | 5 | 2 | 待复核 |
| 钱包、密钥与签名（chain_wallet_keys） | low | 14316 | 5 | 2 | 待复核 |
| 零知识与链上隐私（chain_zk_privacy） | low | 14513 | 5 | 2 | 待复核 |

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
| C 数组、字符串与缓冲区（c_arrays_strings） | low | 16172 | 6 | 2 | 待复核 |
| C 基础语法与编译流程（c_basics） | low | 18860 | 6 | 2 | 待复核 |
| C 条件判断（c_conditions） | low | 18089 | 5 | 2 | 待复核 |
| C 控制流、函数与作用域（c_control_functions） | low | 15581 | 6 | 2 | 待复核 |
| C 调试、Sanitizer 与性能（c_debugging） | low | 15887 | 6 | 2 | 待复核 |
| C 文件、错误处理与资源管理（c_files） | low | 16541 | 6 | 2 | 待复核 |
| C 第一个程序（c_first_program） | low | 18475 | 5 | 2 | 待复核 |
| C 函数入门（c_functions_intro） | low | 17386 | 5 | 2 | 待复核 |
| C 循环入门（c_loops） | low | 20013 | 5 | 2 | 待复核 |
| C 指针与内存模型（c_pointers） | low | 17004 | 6 | 2 | 待复核 |
| C 预处理、宏与头文件（c_preprocessor） | low | 15968 | 6 | 2 | 待复核 |
| 实战：C 命令行任务管理器（c_project） | low | 17162 | 5 | 2 | 待复核 |
| 实战：C 语言 TCP 服务端（c_project_tcp_server） | low | 16478 | 5 | 2 | 待复核 |
| C 结构体、联合体与内存布局（c_structs） | low | 15910 | 6 | 2 | 待复核 |
| C 类型、运算符与转换（c_types） | low | 15809 | 6 | 2 | 待复核 |
| C 变量与输入输出（c_variables_io） | low | 18740 | 5 | 2 | 待复核 |

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
| 容器与 Kubernetes 编排（cloud_containers_kubernetes） | low | 17096 | 5 | 2 | 待复核 |
| 云成本治理与容量规划（cloud_cost_finops） | low | 14660 | 5 | 2 | 待复核 |
| 云计算基础与资源模型（cloud_fundamentals） | low | 15686 | 5 | 2 | 待复核 |
| 基础设施即代码（cloud_iac_terraform） | low | 14025 | 5 | 2 | 待复核 |
| Kubernetes 运维实战（cloud_k8s_operations） | low | 17705 | 5 | 2 | 待复核 |
| 多集群与容灾演练（cloud_multicluster_dr） | low | 14193 | 5 | 2 | 待复核 |
| 可观测性与 SRE 实践（cloud_observability_sre） | low | 16216 | 5 | 2 | 待复核 |
| 云安全与最小权限（cloud_security_iam） | low | 14540 | 5 | 2 | 待复核 |
| 无服务器与事件驱动架构（cloud_serverless） | low | 16208 | 5 | 2 | 待复核 |

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
| 字节码与虚拟机实现（compiler_bytecode_vm） | low | 14834 | 5 | 2 | 待复核 |
| 代码生成与栈式虚拟机（compiler_codegen_vm） | low | 15442 | 5 | 2 | 待复核 |
| 诊断系统与错误恢复（compiler_diagnostics） | low | 14556 | 5 | 2 | 待复核 |
| 垃圾回收算法与实现（compiler_gc） | low | 14410 | 5 | 2 | 待复核 |
| 中间表示与优化（compiler_ir_optimization） | low | 15369 | 5 | 2 | 待复核 |
| 即时编译与内联优化（compiler_jit_inlining） | low | 14603 | 5 | 2 | 待复核 |
| 词法分析与语法分析（compiler_lexer_parser） | low | 15362 | 5 | 2 | 待复核 |
| 编译流程与解释执行概览（compiler_overview） | low | 16452 | 5 | 2 | 待复核 |
| 项目：实现一门迷你语言（compiler_project_minilang） | low | 17643 | 5 | 2 | 待复核 |
| 语义分析与类型系统（compiler_semantic_types） | low | 15624 | 5 | 2 | 待复核 |

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
| 环境与编译流程（cpp_basics） | low | 14922 | 6 | 2 | 待复核 |
| C++ Concepts 与 Ranges（cpp_concepts_ranges） | low | 15854 | 6 | 2 | 待复核 |
| C++ 并发、原子操作与内存序（cpp_concurrency_atomics） | low | 16308 | 6 | 2 | 待复核 |
| C++ 条件判断（cpp_conditions） | low | 18413 | 5 | 2 | 待复核 |
| 控制流与函数（cpp_control_functions） | low | 14828 | 6 | 2 | 待复核 |
| C++ 第一个程序（cpp_first_program） | low | 18856 | 5 | 2 | 待复核 |
| C++ 函数入门（cpp_functions_intro） | low | 20500 | 5 | 2 | 待复核 |
| C++ 循环入门（cpp_loops） | low | 19951 | 5 | 2 | 待复核 |
| 内存管理与智能指针（cpp_memory） | low | 15426 | 6 | 2 | 待复核 |
| 现代 C++ 特性（cpp_modern） | low | 16920 | 6 | 2 | 待复核 |
| C++ 移动语义与右值引用（cpp_move_semantics） | low | 15571 | 6 | 2 | 待复核 |
| 类与面向对象（cpp_oop） | low | 17606 | 6 | 2 | 待复核 |
| 指针与引用（cpp_pointers） | low | 13805 | 6 | 2 | 待复核 |
| 实战：CMake 多文件项目（cpp_project） | low | 21446 | 6 | 2 | 待复核 |
| 实战：C++ HTTP JSON 服务（cpp_project_http） | low | 18636 | 6 | 2 | 待复核 |
| 实战：C++ 任务数据库 CLI（cpp_project_taskdb） | low | 17720 | 6 | 2 | 待复核 |
| STL 容器与算法（cpp_stl） | low | 17513 | 6 | 2 | 待复核 |
| 模板与泛型编程（cpp_templates） | low | 16379 | 6 | 2 | 待复核 |
| 构建、调试与工程实践（cpp_tooling） | low | 16257 | 6 | 2 | 待复核 |
| 变量、类型与运算符（cpp_types） | low | 14348 | 6 | 2 | 待复核 |
| C++ 变量与输入输出（cpp_variables_io） | low | 14310 | 5 | 2 | 待复核 |

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
| 接口文档与契约测试：跨生态对照（cross_api_contract） | low | 13844 | 5 | 2 | 待复核 |
| 构建与发布产物：九种生态横向对照（cross_build_release） | low | 14085 | 6 | 2 | 待复核 |
| CI 流水线配置：九种生态横向对照（cross_ci_config） | low | 14905 | 5 | 2 | 待复核 |
| 命令行参数解析：九种语言横向对照（cross_cli_args） | low | 14741 | 5 | 2 | 待复核 |
| 集合类型：九种语言横向对照（cross_collections） | low | 13870 | 6 | 2 | 待复核 |
| 并发写法：九种语言横向对照（cross_concurrency） | low | 13687 | 6 | 2 | 待复核 |
| 数据库访问与 ORM：九种生态横向对照（cross_db_access） | low | 14173 | 5 | 2 | 待复核 |
| 错误处理与测试：九种语言横向对照（cross_errors_testing） | low | 13922 | 6 | 2 | 待复核 |
| 九种语言的第一个程序（cross_first_program） | low | 14861 | 6 | 2 | 待复核 |
| 国际化与本地化：跨生态对照（cross_i18n） | low | 15602 | 5 | 2 | 待复核 |
| 日志与可观测性：九种生态横向对照（cross_logging_observability） | low | 16533 | 5 | 2 | 待复核 |
| 包管理与依赖：九种生态横向对照（cross_package_manage） | low | 15843 | 6 | 2 | 待复核 |
| 性能剖析与基准测试：九种生态横向对照（cross_performance_profiling） | low | 13840 | 5 | 2 | 待复核 |
| 依赖安全与密钥管理：九种生态横向对照（cross_security_ecosystem） | low | 16285 | 5 | 2 | 待复核 |
| 序列化格式：JSON、YAML、Protobuf 横向对照（cross_serialization） | low | 14749 | 5 | 2 | 待复核 |
| 字符串与正则：九种语言横向对照（cross_string_regex） | low | 14681 | 5 | 2 | 待复核 |
| 时间与时区：九种语言横向对照（cross_time_timezone） | low | 15361 | 5 | 2 | 待复核 |
| 类型与变量：九种语言横向对照（cross_types_variables） | low | 14383 | 6 | 2 | 待复核 |

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
| 异步编程与异常处理（csharp_async） | low | 17657 | 6 | 2 | 待复核 |
| C# 异步流与取消（csharp_async_streams） | low | 17026 | 6 | 2 | 待复核 |
| C# 与 .NET 平台（csharp_basics） | low | 14877 | 6 | 2 | 待复核 |
| 集合、委托与 LINQ（csharp_collections_linq） | low | 16703 | 6 | 2 | 待复核 |
| C# 条件判断（csharp_conditions） | low | 18148 | 6 | 2 | 待复核 |
| 控制流与方法（csharp_control_methods） | low | 15620 | 6 | 2 | 待复核 |
| C# 与 .NET 第一个程序（csharp_dotnet_first） | low | 18790 | 5 | 2 | 待复核 |
| 生态、测试与 Web 开发（csharp_ecosystem） | low | 17998 | 6 | 2 | 待复核 |
| C# GC、Span 与性能优化（csharp_gc_performance） | low | 17062 | 6 | 2 | 待复核 |
| 继承、接口与多态（csharp_inheritance） | low | 15721 | 6 | 2 | 待复核 |
| C# 循环入门（csharp_loops） | low | 19454 | 5 | 2 | 待复核 |
| C# 方法入门（csharp_methods_intro） | low | 20110 | 5 | 2 | 待复核 |
| 类、属性与对象（csharp_oop） | low | 15435 | 6 | 2 | 待复核 |
| 实战：Web API + EF Core（csharp_project） | low | 22437 | 6 | 2 | 待复核 |
| 实战：C# Blazor 管理后台（csharp_project_blazor_admin） | low | 18275 | 6 | 2 | 待复核 |
| 实战：C# 库存管理 CLI（csharp_project_inventory_cli） | low | 18173 | 6 | 2 | 待复核 |
| C# Record、模式匹配与不可变数据（csharp_records_patterns） | low | 13939 | 6 | 2 | 待复核 |
| 变量、类型与字符串（csharp_types） | low | 15174 | 6 | 2 | 待复核 |
| C# 变量与输入（csharp_variables_input） | low | 13821 | 5 | 2 | 待复核 |

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
| 批处理与 Spark 实践（de_batch_processing） | low | 15408 | 5 | 2 | 待复核 |
| CDC 与增量同步（de_cdc_incremental） | low | 15143 | 5 | 2 | 待复核 |
| 数据契约与质量门禁（de_data_contract） | low | 15215 | 5 | 2 | 待复核 |
| 数据建模与数仓分层（de_data_modeling） | low | 15268 | 5 | 2 | 待复核 |
| 数据质量与数据治理（de_data_quality） | low | 15218 | 5 | 2 | 待复核 |
| Flink 流处理与窗口（de_flink_windowing） | low | 15419 | 5 | 2 | 待复核 |
| 湖仓治理与表维护（de_lakehouse_governance） | low | 14565 | 5 | 2 | 待复核 |
| 任务编排与数据血缘（de_orchestration_lineage） | low | 15086 | 5 | 2 | 待复核 |
| Spark 执行模型与调优（de_spark_tuning） | low | 15859 | 5 | 2 | 待复核 |
| 流处理与 Kafka 实践（de_stream_processing） | low | 16060 | 5 | 2 | 待复核 |

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
| Airflow 调度与数据质量（airflow_quality） | low | 14642 | 6 | 2 | 待复核 |
| 大数据与批流处理（bigdata_batch_stream） | low | 14887 | 6 | 2 | 待复核 |
| 数据湖与湖仓一体（data_lakehouse） | low | 17089 | 6 | 2 | 待复核 |
| 实战：设计并优化一个订单库（database_project） | low | 19430 | 6 | 2 | 待复核 |
| 数据库备份与恢复演练（db_backup_recovery） | low | 15118 | 5 | 2 | 待复核 |
| 数据库设计与范式（db_design） | low | 15920 | 6 | 2 | 待复核 |
| 图数据库与关系查询（db_graph） | low | 16640 | 6 | 2 | 待复核 |
| 数据库迁移与 Schema 治理（db_migration_governance） | low | 15182 | 6 | 2 | 待复核 |
| 数据库运维：备份、迁移与分库分表（db_ops） | low | 15646 | 6 | 2 | 待复核 |
| 数据库权限与安全（db_permissions_security） | low | 15148 | 5 | 2 | 待复核 |
| PostgreSQL 深入实践（db_postgresql_deep） | low | 15636 | 6 | 2 | 待复核 |
| 查询优化与执行计划（db_query_optimization） | low | 14200 | 6 | 2 | 待复核 |
| 时序数据库与监控数据（db_time_series） | low | 15918 | 6 | 2 | 待复核 |
| 分布式事务与共识（distributed_transaction） | low | 15896 | 6 | 2 | 待复核 |
| 索引（index） | low | 13905 | 6 | 2 | 待复核 |
| MySQL 锁与 MVCC（mysql_lock_mvcc） | low | 17094 | 6 | 2 | 待复核 |
| NoSQL 数据库（nosql） | low | 14755 | 6 | 2 | 待复核 |
| OLAP 与列式存储（olap_columnar） | low | 17099 | 6 | 2 | 待复核 |
| 实时数仓：从 Kafka 到 Flink（realtime_warehouse） | low | 14835 | 6 | 2 | 待复核 |
| Redis 实战（redis） | low | 17337 | 6 | 2 | 待复核 |
| 倒排索引与搜索（search_index） | low | 13677 | 6 | 2 | 待复核 |
| SQL 高级查询（sql_advanced） | low | 14925 | 6 | 2 | 待复核 |
| SQL 基础（sql_basics） | low | 14132 | 6 | 2 | 待复核 |
| SQL 查询入门（sql_query_intro） | low | 14610 | 5 | 2 | 待复核 |

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
| 表与 SQL 入门（sql_table_intro） | low | 15108 | 5 | 2 | 待复核 |
| 存储引擎与 B+ 树实现（storage_engine） | low | 15409 | 6 | 2 | 待复核 |
| 事务（transaction） | low | 13698 | 6 | 3 | 待复核 |

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
| 事件溯源与读写分离（dist_event_sourcing） | low | 14815 | 5 | 2 | 待复核 |
| 分布式事务与一致性（dist_transaction） | low | 14770 | 5 | 2 | 待复核 |
| 分布式缓存架构（distributed_cache） | low | 15208 | 6 | 2 | 待复核 |
| 共识与复制：Raft 实战要点（distributed_consensus） | low | 17422 | 6 | 2 | 待复核 |
| 分布式系统原理（distributed_fundamentals） | low | 14795 | 6 | 3 | 待复核 |
| 分布式 ID 与发号器（distributed_id） | low | 15266 | 6 | 2 | 待复核 |
| 单元化与多活架构（distributed_multisite） | low | 13777 | 6 | 2 | 待复核 |
| 限流与熔断算法专题（distributed_rate_limit） | low | 14080 | 6 | 2 | 待复核 |
| 实战：设计一个短链服务（distributed_short_url_project） | low | 15944 | 6 | 2 | 待复核 |
| 高可用与容量规划（high_availability） | low | 14563 | 6 | 2 | 待复核 |
| 消息队列与事件驱动（messaging_events） | low | 15806 | 6 | 2 | 待复核 |
| 微服务拆分与治理（microservices） | low | 14026 | 6 | 2 | 待复核 |

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
| Bootloader 与固件升级（embedded_bootloader） | low | 16677 | 5 | 2 | 待复核 |
| UART、SPI 与 I2C 通信实战（embedded_bus_protocols） | low | 18105 | 5 | 2 | 待复核 |
| 嵌入式调试与追踪（embedded_debug_trace） | low | 14377 | 5 | 2 | 待复核 |
| 外设编程：GPIO、中断与定时器（embedded_gpio_interrupt） | low | 16259 | 5 | 2 | 待复核 |
| IoT 设备安全基础（embedded_iot_security） | low | 14631 | 5 | 2 | 待复核 |
| 低功耗与电池续航设计（embedded_low_power） | low | 14674 | 5 | 2 | 待复核 |
| 单片机与嵌入式系统基础（embedded_mcu_basics） | low | 15714 | 5 | 2 | 待复核 |
| 项目：环境监测节点（embedded_project_env_monitor） | low | 16945 | 5 | 2 | 待复核 |
| RTOS 任务、调度与同步（embedded_rtos_tasks） | low | 16434 | 5 | 2 | 待复核 |
| 传感器采集与信号调理（embedded_sensor_signal） | low | 14300 | 5 | 2 | 待复核 |

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
| Flutter 基础与 Widget 树（flutter_basics） | low | 17234 | 6 | 2 | 待复核 |
| Flutter 布局入门（flutter_layout_intro） | low | 18135 | 6 | 2 | 待复核 |
| 实战：Flutter 打包发布 Android（flutter_release） | low | 19741 | 6 | 2 | 待复核 |
| Flutter 状态管理与性能（flutter_state） | low | 17818 | 6 | 2 | 待复核 |
| Flutter Widget 入门（flutter_widget_intro） | low | 18150 | 6 | 2 | 待复核 |
| Jetpack Compose 声明式 UI（mobile_compose） | low | 16642 | 6 | 2 | 待复核 |
| 鸿蒙 ArkTS 应用开发（mobile_harmony） | low | 14904 | 6 | 2 | 待复核 |
| Kotlin 与 Android 开发（mobile_kotlin） | low | 17561 | 6 | 2 | 待复核 |
| 小程序开发要点（mobile_miniprogram） | low | 14305 | 6 | 2 | 待复核 |
| 移动端性能优化实战（mobile_performance） | low | 17908 | 6 | 2 | 待复核 |
| React Native 跨平台开发（mobile_react_native） | low | 16039 | 6 | 2 | 待复核 |
| Swift 与 iOS 开发（mobile_swift） | low | 16936 | 6 | 2 | 待复核 |

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
| 指令集与汇编入门（assembly） | low | 15032 | 6 | 2 | 待复核 |
| 二进制与进制转换（binary） | low | 14584 | 6 | 2 | 待复核 |
| 二进制入门（binary_intro） | low | 13598 | 5 | 2 | 待复核 |
| 总线与 I/O 设备（bus_io） | low | 14931 | 6 | 2 | 待复核 |
| 代码生成与寄存器分配（codegen_registers） | low | 14355 | 6 | 2 | 待复核 |
| 编译与程序运行原理（compiler） | low | 15871 | 6 | 2 | 待复核 |
| 编译前端：词法与语法分析（compiler_frontend） | low | 14681 | 6 | 2 | 待复核 |
| 计算理论入门（computation_theory） | low | 15226 | 6 | 2 | 待复核 |
| 计算机组成入门（computer_organization_intro） | low | 14834 | 5 | 2 | 待复核 |
| CPU 工作原理（cpu） | low | 14240 | 6 | 2 | 待复核 |
| 密码学原语（cryptography） | low | 17038 | 6 | 2 | 待复核 |
| 数字逻辑与布尔代数（digital_logic） | low | 13781 | 6 | 2 | 待复核 |
| 离散数学与逻辑（discrete_math） | low | 14038 | 6 | 2 | 待复核 |
| 字符编码与 Unicode（encoding） | low | 15652 | 6 | 2 | 待复核 |
| 浮点数与校验码（float_and_check） | low | 14566 | 6 | 2 | 待复核 |
| 计算机体系结构综合案例（fundamentals_architecture_case） | low | 15080 | 6 | 2 | 待复核 |
| 缓存一致性、内存模型与 NUMA（fundamentals_cache_coherence） | low | 15418 | 6 | 2 | 待复核 |
| 嵌入式与 IoT 基础（fundamentals_embedded_iot） | low | 14883 | 6 | 2 | 待复核 |
| CPU 流水线与指令级并行（fundamentals_pipeline） | low | 15138 | 6 | 2 | 待复核 |
| 实战：追踪程序的全生命周期（fundamentals_project） | low | 16985 | 6 | 2 | 待复核 |
| SIMD 与向量化计算（fundamentals_simd） | low | 14654 | 6 | 2 | 待复核 |
| SSD、存储栈与持久化（fundamentals_storage_stack） | low | 16760 | 6 | 2 | 待复核 |
| 计算机图形学与多媒体（graphics_media） | low | 15858 | 6 | 2 | 待复核 |
| 中断、异常与 DMA（interrupt_exception） | low | 13683 | 6 | 2 | 待复核 |

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
| 中间代码与优化（ir_optimization） | low | 16096 | 6 | 2 | 待复核 |
| 链接与加载（linking_loading） | low | 15241 | 6 | 2 | 待复核 |
| 内存与缓存（memory_cache） | low | 14638 | 6 | 3 | 待复核 |
| 性能度量与并行体系结构（performance_metrics） | low | 13885 | 6 | 2 | 待复核 |
| 概率统计基础（probability） | low | 14177 | 6 | 2 | 待复核 |
| 语义分析与符号表（semantics_analysis） | low | 14592 | 6 | 2 | 待复核 |

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
| 2D 渲染管线与坐标系（gamedev_2d_rendering） | low | 16092 | 5 | 2 | 待复核 |
| 动画状态机与混合（gamedev_animation_fsm） | low | 14608 | 5 | 2 | 待复核 |
| 资产管线与热更新（gamedev_asset_pipeline） | low | 14216 | 5 | 2 | 待复核 |
| 碰撞检测与物理基础（gamedev_collision_physics） | low | 15501 | 5 | 2 | 待复核 |
| 实体组件系统与性能剖析（gamedev_ecs_profiling） | low | 15363 | 5 | 2 | 待复核 |
| 游戏循环与帧时间（gamedev_game_loop） | low | 15045 | 5 | 2 | 待复核 |
| 多人同步与延迟处理（gamedev_multiplayer_sync） | low | 14483 | 5 | 2 | 待复核 |
| 移动端性能与功耗优化（gamedev_performance_mobile） | low | 14380 | 5 | 2 | 待复核 |
| 渲染管线与批次合并（gamedev_render_pipeline） | low | 14762 | 5 | 2 | 待复核 |

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
| Go 基础（go_basics） | low | 15044 | 6 | 2 | 待复核 |
| Go 云原生服务安全与可靠性（go_cloud_native_security） | low | 15339 | 6 | 2 | 待复核 |
| Go 并发：goroutine、channel 与 context（go_concurrency） | low | 15976 | 6 | 2 | 待复核 |
| Go 并发模式与 errgroup（go_concurrency_patterns） | low | 15798 | 6 | 2 | 待复核 |
| Go 条件判断（go_conditions） | low | 18065 | 6 | 2 | 待复核 |
| Go 数据访问与连接池（go_data_access） | low | 17667 | 6 | 2 | 待复核 |
| Go 第一个程序（go_first_program） | low | 18306 | 6 | 2 | 待复核 |
| Go 函数入门（go_functions_intro） | low | 17420 | 5 | 2 | 待复核 |
| Go 泛型深入与约束设计（go_generics_deep） | low | 15438 | 6 | 2 | 待复核 |
| Go 泛型与标准库实战（go_generics_stdlib） | low | 18657 | 6 | 2 | 待复核 |
| gRPC 与 Protobuf 实践（go_grpc） | low | 16674 | 6 | 2 | 待复核 |
| Go 接口与错误处理（go_interfaces_errors） | low | 14198 | 6 | 2 | 待复核 |
| Go 循环入门（go_loops） | low | 19884 | 6 | 2 | 待复核 |
| Go 微服务与可观测（go_microservice） | low | 15590 | 6 | 2 | 待复核 |
| Go 性能优化与内存（go_performance） | low | 15470 | 6 | 2 | 待复核 |
| Go 性能剖析与调优实战（go_pprof） | low | 18348 | 6 | 2 | 待复核 |
| Go 性能剖析与调优（进阶）（go_profiling_deep） | low | 16969 | 6 | 2 | 待复核 |
| Go 工程实践（go_project） | low | 18812 | 6 | 2 | 待复核 |
| 实战：Go REST API 服务（go_project_rest_api） | low | 18112 | 6 | 2 | 待复核 |
| 实战：Go 并发抓取与 Worker Pool（go_project_worker_pool） | low | 19520 | 6 | 2 | 待复核 |
| Go 测试进阶：基准、模糊与集成（go_testing） | low | 15825 | 6 | 2 | 待复核 |
| Go 变量与输入（go_variables_input） | low | 18468 | 6 | 2 | 待复核 |

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
| 可访问性与 ARIA 实战（a11y_aria） | low | 17430 | 6 | 2 | 待复核 |
| 浏览器渲染与事件循环深入（browser_rendering） | low | 13830 | 6 | 2 | 待复核 |
| CSS 进阶：变量、伪类与现代特性（css_advanced） | low | 15892 | 6 | 2 | 待复核 |
| CSS 基础：选择器与盒模型（css_basics） | low | 15254 | 6 | 2 | 待复核 |
| 设计令牌与样式架构（css_design_tokens） | low | 14353 | 6 | 2 | 待复核 |
| CSS 布局：Flex、Grid 与响应式（css_layout） | low | 16898 | 6 | 2 | 待复核 |
| 浏览器渲染与 CSS 动画（css_render_animation） | low | 14013 | 6 | 2 | 待复核 |
| CSS 选择器入门（css_selectors_intro） | low | 17286 | 6 | 2 | 待复核 |
| HTML 基础与语义化（html_basics） | low | 15053 | 6 | 2 | 待复核 |
| 实战：响应式落地页（html_css_project） | low | 16190 | 6 | 2 | 待复核 |
| HTML 标签入门（html_tags_intro） | low | 15372 | 6 | 2 | 待复核 |
| Web Components 实战（web_components） | low | 19649 | 6 | 2 | 待复核 |
| 前端性能优化实战（web_performance） | low | 18348 | 6 | 2 | 待复核 |
| PWA 与离线能力（web_pwa_offline） | low | 18047 | 6 | 2 | 待复核 |

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
| 环境与 JVM（java_basics） | low | 15305 | 6 | 2 | 待复核 |
| 集合框架与泛型（java_collections） | low | 17263 | 6 | 2 | 待复核 |
| 多线程与并发（java_concurrency） | low | 18332 | 6 | 2 | 待复核 |
| Java 条件判断（java_conditions） | low | 19055 | 5 | 2 | 待复核 |
| 控制流与方法（java_control_methods） | low | 14894 | 6 | 2 | 待复核 |
| 异常处理与文件 IO（java_exceptions） | low | 16115 | 6 | 2 | 待复核 |
| Java 第一个类（java_first_class） | low | 19047 | 5 | 2 | 待复核 |
| JVM 垃圾回收与性能调优（java_gc_tuning） | low | 15016 | 5 | 2 | 待复核 |
| 继承、接口与多态（java_inheritance） | low | 15525 | 6 | 2 | 待复核 |
| Lambda 与 Stream API（java_lambda_stream） | low | 17497 | 6 | 2 | 待复核 |
| Java 循环入门（java_loops） | low | 20627 | 5 | 2 | 待复核 |
| Java 方法入门（java_methods_intro） | low | 20710 | 5 | 2 | 待复核 |
| 现代 Java：Record、Sealed 与模式匹配（java_modern_features） | low | 14915 | 6 | 2 | 待复核 |
| 类与对象（java_oop） | low | 14945 | 6 | 2 | 待复核 |
| 实战：Spring Boot REST API（java_project） | low | 23490 | 6 | 2 | 待复核 |
| 实战：Java 库存管理 REST 服务（java_project_inventory） | low | 18743 | 6 | 2 | 待复核 |
| 实战：Java 并发订单处理服务（java_project_order_concurrency） | low | 18731 | 6 | 2 | 待复核 |
| 构建、测试与生态（java_tooling） | low | 18346 | 6 | 2 | 待复核 |
| 变量、类型与字符串（java_types） | low | 15172 | 6 | 2 | 待复核 |
| Java 变量与输出（java_variables_output） | low | 14254 | 5 | 2 | 待复核 |
| Java 虚拟线程与结构化并发（java_virtual_threads） | low | 15963 | 5 | 2 | 待复核 |

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
| 数组与常用方法（js_arrays） | low | 15660 | 6 | 2 | 待复核 |
| 异步编程（js_async） | low | 17829 | 6 | 2 | 待复核 |
| JavaScript 与运行环境（js_basics） | low | 15322 | 6 | 2 | 待复核 |
| JavaScript 条件与循环（js_conditions_loops） | low | 14976 | 5 | 2 | 待复核 |
| JavaScript 控制台入门（js_console_start） | low | 21654 | 5 | 2 | 待复核 |
| DOM 与事件（js_dom_events） | low | 17595 | 6 | 2 | 待复核 |
| JavaScript DOM 入门（js_dom_intro） | low | 16181 | 5 | 2 | 待复核 |
| 错误处理与调试（js_errors_debugging） | low | 15918 | 6 | 2 | 待复核 |
| JavaScript 执行上下文与闭包（js_execution_context） | low | 16439 | 6 | 2 | 待复核 |
| 函数、作用域与 this（js_functions） | low | 14729 | 6 | 2 | 待复核 |
| JavaScript 函数入门（js_functions_intro） | low | 18779 | 5 | 2 | 待复核 |
| JavaScript 内存管理与垃圾回收（js_memory_gc） | low | 17127 | 6 | 2 | 待复核 |
| 模块化与工程化（js_modules_tooling） | low | 16652 | 6 | 2 | 待复核 |
| Node.js 后端工程（js_node_backend） | low | 15625 | 5 | 2 | 待复核 |
| 对象、原型与类（js_objects） | low | 15878 | 6 | 2 | 待复核 |
| 运算符与控制流（js_operators_control） | low | 14568 | 6 | 2 | 待复核 |
| 实战：Vite + React 待办应用（js_project） | low | 21110 | 6 | 2 | 待复核 |
| 实战：Node.js + Express REST API（js_project_node_api） | low | 19467 | 6 | 2 | 待复核 |
| 实战：JavaScript 实时聊天室（js_project_realtime_chat） | low | 19229 | 6 | 2 | 待复核 |
| 变量、类型与类型转换（js_types） | low | 14593 | 6 | 2 | 待复核 |
| JavaScript 变量与类型入门（js_variables_types_intro） | low | 19194 | 5 | 2 | 待复核 |

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
| Kotlin Android 架构（kotlin_android） | low | 17059 | 6 | 2 | 待复核 |
| Kotlin 基础与空安全（kotlin_basics） | low | 18897 | 6 | 2 | 待复核 |
| Kotlin 集合、序列与函数式操作（kotlin_collections） | low | 16712 | 6 | 2 | 待复核 |
| Kotlin 条件判断（kotlin_conditions） | low | 19031 | 5 | 2 | 待复核 |
| Kotlin 协程与 Flow（kotlin_coroutines） | low | 17236 | 6 | 2 | 待复核 |
| Kotlin 第一个程序（kotlin_first_program） | low | 18931 | 5 | 2 | 待复核 |
| Kotlin 函数、Lambda 与扩展（kotlin_functions） | low | 16466 | 6 | 2 | 待复核 |
| Kotlin 函数入门（kotlin_functions_intro） | low | 20799 | 5 | 2 | 待复核 |
| Kotlin 循环入门（kotlin_loops） | low | 20925 | 5 | 2 | 待复核 |
| Kotlin 类、对象与属性（kotlin_oop） | low | 15728 | 6 | 2 | 待复核 |
| 实战：Kotlin Android 客户端（kotlin_project） | low | 17404 | 5 | 2 | 待复核 |
| 实战：Kotlin 命令行记账工具（kotlin_project_cli_ledger） | low | 16285 | 5 | 2 | 待复核 |
| Kotlin 测试与协程测试（kotlin_testing） | low | 16433 | 5 | 2 | 待复核 |
| Kotlin 变量与空值（kotlin_variables_null） | low | 19262 | 5 | 2 | 待复核 |

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
| 微积分与梯度下降（math_calculus_gradient） | low | 14750 | 6 | 2 | 待复核 |
| 凸优化与约束优化（math_convex_optimization） | low | 13845 | 6 | 2 | 待复核 |
| 特征值、SVD 与降维（math_eigen_svd） | low | 14875 | 6 | 2 | 待复核 |
| 图论与组合数学（math_graph_combinatorics） | low | 13338 | 6 | 2 | 待复核 |
| 信息论：熵与交叉熵（math_information_theory） | low | 13925 | 6 | 2 | 待复核 |
| 数值线性代数（math_numerical_linear_algebra） | low | 12649 | 6 | 2 | 待复核 |
| 概率统计与假设检验（math_probability_stats） | low | 14419 | 6 | 2 | 待复核 |
| 集合与函数入门（math_set_function_intro） | low | 15684 | 6 | 2 | 待复核 |
| 线性代数：向量与矩阵（math_vectors_matrices） | low | 14764 | 6 | 2 | 待复核 |

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
| 认证与授权（auth_oauth） | low | 16729 | 6 | 2 | 待复核 |
| CDN、代理与缓存（cdn_proxy） | low | 15297 | 6 | 2 | 待复核 |
| DNS 域名解析（dns） | low | 15168 | 6 | 3 | 待复核 |
| HTTP/2 与 HTTP/3（http2_http3） | low | 15565 | 6 | 2 | 待复核 |
| HTTP 基础（http_basics） | low | 13932 | 6 | 2 | 待复核 |
| IP 与端口入门（ip_port_intro） | low | 17109 | 6 | 2 | 待复核 |
| IP、子网与传输层深入（ip_transport） | low | 15927 | 6 | 2 | 待复核 |
| 链路层：以太网、ARP 与交换机（link_layer） | low | 13736 | 6 | 2 | 待复核 |
| 网络攻击与防护（network_attacks） | low | 17853 | 6 | 2 | 待复核 |
| BGP 与互联网路由（network_bgp） | low | 14310 | 5 | 2 | 待复核 |
| IPv6 原理与迁移（network_ipv6） | low | 14505 | 6 | 2 | 待复核 |
| 网络分层入门（network_layers_intro） | low | 15810 | 5 | 2 | 待复核 |
| NAT、隧道与 VPN（network_nat_vpn） | low | 16653 | 5 | 2 | 待复核 |
| P2P 网络与 NAT 穿透（network_p2p） | low | 14204 | 5 | 2 | 待复核 |
| 网络性能调优（network_performance） | low | 13695 | 5 | 2 | 待复核 |
| 实战：抓包分析一次真实请求（network_project） | low | 19993 | 6 | 2 | 待复核 |
| SMTP、邮件协议与反垃圾（network_smtp） | low | 14449 | 5 | 2 | 待复核 |
| 渗透测试基础（pentest_basics） | low | 15121 | 6 | 2 | 待复核 |
| Socket 编程实战（socket_programming） | low | 17730 | 6 | 2 | 待复核 |
| TCP/IP 协议栈（tcp_ip） | low | 13943 | 6 | 3 | 待复核 |
| HTTPS 与 TLS（tls） | low | 15000 | 6 | 2 | 待复核 |
| Web 安全攻防（web_security） | low | 16089 | 6 | 2 | 待复核 |
| WebSocket 与实时通信（websocket） | low | 14835 | 6 | 2 | 待复核 |
| 无线与移动网络（wireless_mobile） | low | 16030 | 6 | 2 | 待复核 |

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
| 死锁（deadlock） | low | 13219 | 6 | 3 | 待复核 |
| 文件系统基础（file_system） | low | 14242 | 6 | 2 | 待复核 |
| 进程间通信与 IO 模型（ipc_io） | low | 14542 | 6 | 2 | 待复核 |
| 系统启动与权限安全（os_boot_security） | low | 14008 | 6 | 2 | 待复核 |
| cgroups、namespaces 与容器（os_cgroups_namespaces） | low | 15238 | 6 | 2 | 待复核 |
| 文件系统实现与 RAID（os_filesystem_impl） | low | 13688 | 6 | 2 | 待复核 |
| I/O 调度与块设备（os_io_scheduling） | low | 14904 | 6 | 2 | 待复核 |
| io_uring 与异步 I/O（os_io_uring） | low | 13918 | 5 | 2 | 待复核 |
| 操作系统内核架构（os_kernel_arch） | low | 16442 | 6 | 2 | 待复核 |
| Linux 性能与故障排查（os_linux_troubleshooting） | low | 15089 | 5 | 2 | 待复核 |
| 实战：实现一个多线程任务队列（os_project） | low | 15962 | 6 | 2 | 待复核 |
| 实时操作系统与确定性（os_rtos） | low | 16761 | 5 | 2 | 待复核 |
| 同步机制与经典问题（os_synchronization） | low | 13516 | 6 | 2 | 待复核 |
| 进程与线程（process_thread） | low | 15321 | 6 | 3 | 待复核 |
| 进程与线程入门（process_thread_intro） | low | 14976 | 6 | 2 | 待复核 |
| 进程调度（scheduling） | low | 14854 | 6 | 2 | 待复核 |
| 虚拟内存与分页（virtual_memory） | low | 12860 | 6 | 3 | 待复核 |

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
| 算法工程化与性能验证实战（project_algorithm_engineering） | low | 18875 | 5 | 2 | 待复核 |
| 编码工作流：小步提交与可评审的改动（project_coding_workflow） | low | 15862 | 6 | 2 | 待复核 |
| 操作系统与并发实战（project_concurrency_runtime） | low | 18669 | 5 | 2 | 待复核 |
| 数据工程 ETL 与质量治理实战（project_data_etl） | low | 18845 | 5 | 2 | 待复核 |
| 数据库性能调优实战（project_database_tuning） | low | 18013 | 5 | 2 | 待复核 |
| 实战：慢接口调试与性能定位（project_debug_performance_triage） | low | 17286 | 5 | 2 | 待复核 |
| 部署与运维：稳定发布与快速回滚（project_deploy_ops） | low | 15966 | 5 | 2 | 待复核 |
| DevOps CI/CD 流水线实战（project_devops_pipeline） | low | 19062 | 5 | 2 | 待复核 |
| 面试冲刺：算法编码与系统设计高频题（project_interview_coding_system_design） | low | 17245 | 5 | 2 | 待复核 |
| 移动端离线优先 App 实战（project_mobile_offline_app） | low | 19092 | 5 | 2 | 待复核 |
| 网络抓包与协议分析实战（project_network_capture_analysis） | low | 19545 | 5 | 2 | 待复核 |
| 实战：Python CLI 待办工具（project_python_cli_todo） | low | 17344 | 5 | 2 | 待复核 |
| 实战：本地 RAG 客服 Agent（project_rag_agent_service） | low | 17337 | 5 | 2 | 待复核 |
| 需求到设计：把想法拆成可交付任务（project_requirements_design） | low | 15504 | 6 | 2 | 待复核 |
| 实战：REST API 与 SQLite 事务服务（project_rest_api_sqlite） | low | 18106 | 5 | 2 | 待复核 |
| 复盘与改进：让团队一次比一次快（project_retro_improve） | low | 16901 | 5 | 2 | 待复核 |
| 安全攻防与防御实战（project_security_lab） | low | 17445 | 5 | 2 | 待复核 |
| 测试与质量门禁：把问题挡在上线前（project_testing_quality） | low | 16244 | 5 | 2 | 待复核 |

## python-1 · Python

- 课程数：24 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 24
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Python asyncio 异步编程：任务、超时与取消（python_asyncio） | low | 21243 | 5 | 1 | 待复核 |
| Python 基础语法（python_basics） | low | 18389 | 6 | 2 | 待复核 |
| Python CLI 与自动化实战（python_cli_automation） | low | 20706 | 5 | 1 | 待复核 |
| 并发与异步（python_concurrency） | low | 16584 | 6 | 2 | 待复核 |
| Python 并发模型、GIL 与线程进程选型（python_concurrency_model） | low | 20210 | 5 | 1 | 待复核 |
| Python 容器进阶、拷贝与默认参数（python_containers_copy） | low | 19114 | 5 | 1 | 待复核 |
| Python 上下文管理器与迭代器协议（python_context_iterators） | low | 14064 | 6 | 2 | 待复核 |
| 控制流与推导式（python_control_flow） | low | 13493 | 6 | 2 | 待复核 |
| Python 数据处理：NumPy、pandas 与 Polars（python_data_processing） | low | 20274 | 5 | 1 | 待复核 |
| 列表、元组、字典与集合（python_data_structures） | low | 14494 | 6 | 2 | 待复核 |
| Python 数据库与 SQLAlchemy 2.x（python_database_sqlalchemy） | low | 21125 | 5 | 1 | 待复核 |
| Python 装饰器与生成器（python_decorators_generators） | low | 17164 | 6 | 2 | 待复核 |
| 异常处理与文件操作（python_errors_files） | low | 16296 | 6 | 2 | 待复核 |
| Python 异常、日志与文件 I/O 进阶（python_errors_logging_files） | low | 15919 | 5 | 1 | 待复核 |
| Python 第一个脚本（python_first_script） | low | 13926 | 5 | 2 | 待复核 |
| 函数（python_functions） | low | 14413 | 6 | 2 | 待复核 |
| Python GUI 开发：Tkinter 与 PySide6（python_gui） | low | 19198 | 5 | 1 | 待复核 |
| Python HTTP 客户端工程：超时、重试与认证（python_http_clients） | low | 19516 | 5 | 1 | 待复核 |
| Python 条件判断（python_if_else） | low | 13537 | 5 | 2 | 待复核 |
| Python 输入与输出（python_input_output） | low | 19512 | 5 | 2 | 待复核 |
| Python 与 C、C++、Rust 互操作（python_interop） | low | 19420 | 5 | 1 | 待复核 |
| Python 面试专题：原理、编码与工程判断（python_interview） | low | 17822 | 5 | 1 | 待复核 |
| Python 列表与字典入门（python_list_dict_basics） | low | 18098 | 5 | 2 | 待复核 |
| Python 循环入门（python_loops） | low | 18181 | 5 | 2 | 待复核 |

## python-2 · Python

- 课程数：17 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 17
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 现代 Python 特性与版本升级（python_modern_features） | low | 19900 | 5 | 1 | 待复核 |
| 模块、包与虚拟环境（python_modules_stdlib） | low | 16592 | 6 | 2 | 待复核 |
| 类与对象（python_oop） | low | 15729 | 6 | 2 | 待复核 |
| Python 面向对象进阶：继承、组合与魔术方法（python_oop_advanced） | low | 20988 | 5 | 1 | 待复核 |
| Python 打包、发布与性能（python_packaging_performance） | low | 15742 | 6 | 2 | 待复核 |
| 实战：爬虫与数据分析（python_project） | low | 21492 | 6 | 2 | 待复核 |
| 实战：FastAPI 订单服务（python_project_api） | low | 18550 | 6 | 2 | 待复核 |
| Python 项目架构：分层、配置与依赖注入（python_project_architecture） | low | 19940 | 5 | 1 | 待复核 |
| 实战：CSV 到 SQLite 的 ETL 流水线（python_project_etl） | low | 18048 | 6 | 2 | 待复核 |
| Python pytest 测试实战（python_pytest） | low | 20656 | 5 | 1 | 待复核 |
| Python 内存、性能与解释器原理（python_runtime_memory_performance） | low | 19513 | 5 | 1 | 待复核 |
| Python 安全基础：密码、随机数与不可信输入（python_security） | low | 20749 | 5 | 1 | 待复核 |
| Python 标准库实战工具箱（python_stdlib） | low | 16484 | 5 | 1 | 待复核 |
| Python 字符串、Unicode 与格式化（python_strings_encoding） | low | 19738 | 5 | 1 | 待复核 |
| 类型注解与测试（python_typing_testing） | low | 15853 | 6 | 2 | 待复核 |
| 变量与数据类型（python_variables） | low | 13674 | 6 | 2 | 待复核 |
| Python Web 部署：WSGI、ASGI 与容器化（python_web_deployment） | low | 19945 | 5 | 1 | 待复核 |

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
| Rust 异步编程与 tokio（rust_async_tokio） | low | 17060 | 6 | 2 | 待复核 |
| Rust 基础（rust_basics） | low | 15200 | 6 | 2 | 待复核 |
| Rust Cargo 第一个程序（rust_cargo_first） | low | 18965 | 6 | 2 | 待复核 |
| Rust 实战：命令行工具（rust_cli_project） | low | 21026 | 6 | 2 | 待复核 |
| Rust 并发与 Cargo 工程（rust_concurrency_cargo） | low | 15869 | 6 | 2 | 待复核 |
| Rust 条件判断（rust_conditions） | low | 14318 | 5 | 2 | 待复核 |
| Rust 错误处理、迭代器与异步（rust_errors_iterators） | low | 16000 | 6 | 2 | 待复核 |
| Rust 函数入门（rust_functions_intro） | low | 17620 | 5 | 2 | 待复核 |
| Rust 循环入门（rust_loops） | low | 17730 | 5 | 2 | 待复核 |
| Rust 宏、WASM 与跨平台（rust_macros_wasm） | low | 15314 | 6 | 2 | 待复核 |
| Rust 所有权、借用与生命周期（rust_ownership） | low | 16425 | 6 | 2 | 待复核 |
| 实战：Rust + Axum REST API（rust_project_axum_api） | low | 18623 | 6 | 2 | 待复核 |
| 实战：Rust 并发下载器（rust_project_downloader） | low | 18636 | 6 | 2 | 待复核 |
| Rust 智能指针与内部可变性（rust_smart_pointers） | low | 15498 | 6 | 2 | 待复核 |
| Rust trait、泛型与关联类型（rust_traits_generics） | low | 15822 | 6 | 2 | 待复核 |
| Rust 类型系统：Option、Result 与 trait（rust_types_traits） | low | 16751 | 6 | 2 | 待复核 |
| Rust unsafe、FFI 与生态（rust_unsafe_ffi） | low | 15857 | 6 | 2 | 待复核 |
| Rust 变量与可变性（rust_variables_mutability） | low | 18586 | 6 | 2 | 待复核 |

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
| 密码与哈希入门（password_hash_intro） | low | 15112 | 6 | 2 | 待复核 |
| 认证、会话与令牌安全（security_auth_session） | low | 15550 | 6 | 2 | 待复核 |
| 云安全与 IAM（security_cloud） | low | 14908 | 5 | 2 | 待复核 |
| 安全概念入门（security_concept_intro） | low | 15285 | 6 | 2 | 待复核 |
| 容器与 Kubernetes 安全（security_container_k8s） | low | 16100 | 5 | 2 | 待复核 |
| 模糊测试与漏洞验证（security_fuzzing） | low | 15161 | 5 | 2 | 待复核 |
| 安全事件响应（security_incident） | low | 14900 | 5 | 2 | 待复核 |
| OWASP Top 10 实战（security_owasp_top10） | low | 16185 | 6 | 2 | 待复核 |
| 隐私合规与数据分级（security_privacy） | low | 15262 | 5 | 2 | 待复核 |
| 实战：安全审计与漏洞修复（security_project） | low | 16815 | 5 | 2 | 待复核 |
| 安全开发生命周期实战（security_sdl） | low | 16420 | 5 | 2 | 待复核 |
| 密钥与配置安全（security_secrets） | low | 14821 | 5 | 2 | 待复核 |
| 安全编码与输入校验（security_secure_coding） | low | 15459 | 6 | 2 | 待复核 |
| 软件供应链安全（security_supply_chain） | low | 16910 | 5 | 2 | 待复核 |
| 威胁建模与 STRIDE（security_threat_model） | low | 16946 | 6 | 2 | 待复核 |

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
| Shell 高级自动化与可观测性（shell_automation_advanced） | low | 16018 | 6 | 2 | 待复核 |
| Shell 与 Bash 脚本（shell_bash） | low | 14955 | 6 | 2 | 待复核 |
| CI 脚本模板库（shell_ci_templates） | low | 15830 | 6 | 2 | 待复核 |
| Shell 条件判断（shell_conditions） | low | 13801 | 5 | 2 | 待复核 |
| Shell 与 Docker/K8s 交互（shell_container） | low | 16554 | 6 | 2 | 待复核 |
| Shell 第一个脚本（shell_first_script） | low | 18675 | 6 | 2 | 待复核 |
| Shell 流程控制与函数（shell_flow） | low | 14758 | 6 | 2 | 待复核 |
| 结构化数据处理：jq 与 yq（shell_json_yaml） | low | 16489 | 6 | 2 | 待复核 |
| Shell 循环入门（shell_loops） | low | 20519 | 5 | 2 | 待复核 |
| 系统运维脚本实战（shell_ops_scripts） | low | 19185 | 6 | 2 | 待复核 |
| Shell 文本处理流水线（shell_pipeline） | low | 14594 | 6 | 2 | 待复核 |
| Shell 管道入门（shell_pipeline_intro） | low | 17818 | 5 | 2 | 待复核 |
| Shell 可移植性与 POSIX 兼容（shell_portability） | low | 15743 | 6 | 2 | 待复核 |
| Shell 进程控制、定时任务与日志（shell_process_cron） | low | 14722 | 6 | 2 | 待复核 |
| 实战：Shell 零停机部署脚本（shell_project_deploy） | low | 17665 | 6 | 2 | 待复核 |
| 实战：Shell 日志分析与告警（shell_project_log_analysis） | low | 18630 | 6 | 2 | 待复核 |
| 健壮与可移植的 Shell 脚本（shell_robust） | low | 14921 | 6 | 2 | 待复核 |
| Shell 脚本工程化（shell_script_engineering） | low | 14931 | 6 | 2 | 待复核 |
| Shell 脚本安全加固（shell_security） | low | 16044 | 6 | 2 | 待复核 |
| Shell 脚本安全加固（进阶）（shell_security_hardening） | low | 15640 | 6 | 2 | 待复核 |
| 文本处理进阶：awk、sed 与正则（shell_text_advanced） | low | 14738 | 6 | 2 | 待复核 |
| Shell 变量与参数（shell_variables_args） | low | 18798 | 6 | 2 | 待复核 |

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
| 设计模式与 SOLID（design_patterns） | low | 16107 | 6 | 2 | 待复核 |
| 需求分析与建模（requirements_modeling） | low | 13448 | 6 | 2 | 待复核 |
| 安全开发生命周期（SDL）（sdl_security） | low | 13881 | 6 | 2 | 待复核 |
| 代码评审方法与实践（se_code_review） | low | 14156 | 6 | 2 | 待复核 |
| On-Call 与告警治理（se_oncall） | low | 14287 | 6 | 2 | 待复核 |
| 故障复盘与事故管理（se_postmortem） | low | 15252 | 6 | 2 | 待复核 |
| 质量度量与工程门禁（se_quality_metrics） | low | 14575 | 6 | 2 | 待复核 |
| TDD 与重构（se_tdd_refactor） | low | 13800 | 6 | 2 | 待复核 |
| 技术债务管理（se_tech_debt） | low | 14207 | 6 | 2 | 待复核 |
| 技术写作与文档工程（se_tech_writing） | low | 14171 | 6 | 2 | 待复核 |
| 测试用例设计方法（se_test_design） | low | 13919 | 6 | 2 | 待复核 |
| 测试策略（testing_strategy） | low | 13750 | 6 | 2 | 待复核 |

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
| Swift 并发与 async/await（swift_async） | low | 17549 | 6 | 2 | 待复核 |
| Swift 基础与可选类型（swift_basics） | low | 19036 | 6 | 2 | 待复核 |
| Swift 集合与泛型（swift_collections） | low | 16049 | 6 | 2 | 待复核 |
| Swift 条件判断（swift_conditions） | low | 18572 | 5 | 2 | 待复核 |
| Swift 常量与变量（swift_constants_variables） | low | 14730 | 5 | 2 | 待复核 |
| Swift 第一个程序（swift_first_program） | low | 14188 | 5 | 2 | 待复核 |
| Swift 函数、闭包与协议（swift_functions） | low | 16064 | 6 | 2 | 待复核 |
| Swift 函数入门（swift_functions_intro） | low | 20552 | 5 | 2 | 待复核 |
| Swift 循环入门（swift_loops） | low | 20365 | 5 | 2 | 待复核 |
| Swift 结构体、类与 ARC（swift_oop） | low | 15733 | 6 | 2 | 待复核 |
| 实战：SwiftUI iOS 客户端（swift_project） | low | 16869 | 5 | 2 | 待复核 |
| 实战：Swift 命令行指标分析工具（swift_project_cli_metrics） | low | 16601 | 5 | 2 | 待复核 |
| SwiftUI 与状态管理（swift_swiftui） | low | 13887 | 6 | 2 | 待复核 |
| Swift 测试与性能（swift_testing） | low | 16284 | 5 | 2 | 待复核 |

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
| CI/CD 与 GitHub Actions（ci_cd） | low | 13204 | 6 | 2 | 待复核 |
| 命令行基础（cli） | low | 14919 | 6 | 2 | 待复核 |
| 命令行入门（cli_intro） | low | 14631 | 6 | 2 | 待复核 |
| 调试与日志（debugging） | low | 15049 | 6 | 2 | 待复核 |
| Docker 容器基础（docker） | low | 13886 | 6 | 2 | 待复核 |
| API 网关与负载均衡（gateway） | low | 13816 | 6 | 2 | 待复核 |
| Git 版本控制（git_basics） | low | 14810 | 6 | 2 | 待复核 |
| Git 入门（git_intro） | low | 16245 | 6 | 2 | 待复核 |
| GitOps 与 ArgoCD（gitops_argocd） | low | 13405 | 6 | 2 | 待复核 |
| Kubernetes 基础（kubernetes） | low | 15029 | 6 | 2 | 待复核 |
| Linux 性能分析（linux_performance） | low | 13647 | 6 | 2 | 待复核 |
| 可观测性：日志、指标与链路（observability） | low | 13823 | 6 | 2 | 待复核 |
| Terraform 与基础设施即代码（terraform） | low | 15161 | 6 | 2 | 待复核 |
| 实战：搭一条完整 CI/CD 流水线（toolchain_project） | low | 16966 | 6 | 2 | 待复核 |

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
| TypeScript 数组与对象（ts_arrays_objects） | low | 16326 | 5 | 2 | 待复核 |
| TypeScript 基础类型（ts_basic_types） | low | 19165 | 5 | 2 | 待复核 |
| 类型检查与构建性能优化（ts_build_performance） | low | 14837 | 6 | 2 | 待复核 |
| TypeScript 构建工具链与测试（ts_build_test） | low | 15910 | 6 | 2 | 待复核 |
| TypeScript 进阶类型与框架实践（ts_decorators_pro） | low | 17375 | 6 | 2 | 待复核 |
| TypeScript 第一个类型（ts_first_types） | low | 19449 | 6 | 2 | 待复核 |
| TypeScript 实战：全栈类型安全（ts_fullstack_project） | low | 20078 | 6 | 2 | 待复核 |
| TypeScript 函数类型（ts_function_types） | low | 20012 | 5 | 2 | 待复核 |
| TypeScript 接口入门（ts_interface_intro） | low | 15658 | 5 | 2 | 待复核 |
| Monorepo 工程实践（ts_monorepo） | low | 14759 | 6 | 2 | 待复核 |
| TypeScript 类型收窄与泛型（ts_narrowing_generics） | low | 17526 | 6 | 2 | 待复核 |
| TypeScript Node 后端开发（ts_node_backend） | low | 17442 | 6 | 2 | 待复核 |
| TypeScript 编译与运行性能（ts_performance） | low | 14061 | 6 | 2 | 待复核 |
| TypeScript 工程配置与实践（ts_project） | low | 18965 | 6 | 2 | 待复核 |
| 实战：TypeScript 类型安全 CLI（ts_project_cli） | low | 19293 | 6 | 2 | 待复核 |
| 实战：TypeScript 实时监控面板（ts_project_websocket_dashboard） | low | 19671 | 6 | 2 | 待复核 |
| TypeScript 运行时校验与边界（ts_runtime_validation） | low | 16877 | 6 | 2 | 待复核 |
| TypeScript 测试策略（ts_testing） | low | 16897 | 6 | 2 | 待复核 |
| TypeScript 类型体操进阶（ts_type_challenges） | low | 16737 | 6 | 2 | 待复核 |
| TypeScript 类型级编程（ts_type_level） | low | 16007 | 6 | 2 | 待复核 |
| TypeScript 工具类型与声明文件（ts_utility_types） | low | 16938 | 6 | 2 | 待复核 |
| TypeScript 类型系统（typescript） | low | 16400 | 6 | 2 | 待复核 |

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
| 图解 B+ 树与数据库索引（visual_btree_index） | low | 14702 | 5 | 2 | 待复核 |
| 图解调用栈与递归（visual_call_stack） | low | 14863 | 6 | 2 | 待复核 |
| 图解 CDN 缓存与回源（visual_cdn_cache） | low | 13413 | 5 | 2 | 待复核 |
| 图解并发调度：线程、协程与 Goroutine（visual_concurrency_schedule） | low | 15162 | 5 | 2 | 待复核 |
| 图解一致性哈希与数据分片（visual_consistent_hashing） | low | 15430 | 5 | 2 | 待复核 |
| 图解数据库事务隔离级别（visual_db_isolation） | low | 14836 | 5 | 2 | 待复核 |
| 图解事件循环：同步、微任务与宏任务（visual_event_loop） | low | 13680 | 6 | 2 | 待复核 |
| 图解 Git 三区与提交流转（visual_git_states） | low | 12990 | 5 | 2 | 待复核 |
| 图解一次网页请求的完整链路（visual_http_timeline） | low | 13660 | 5 | 2 | 待复核 |
| 图解 HTTPS 证书链与 TLS 握手（visual_https_cert） | low | 14867 | 5 | 2 | 待复核 |
| 图解 JVM 内存模型与垃圾回收（visual_jvm_memory） | low | 14359 | 5 | 2 | 待复核 |
| 图解 Kubernetes 调度与探针（visual_k8s_scheduling） | low | 13485 | 5 | 2 | 待复核 |
| 图解 Kafka 分区、副本与再平衡（visual_kafka_partition） | low | 14230 | 5 | 2 | 待复核 |
| 图解大模型推理与显存占用（visual_llm_inference） | low | 14950 | 5 | 2 | 待复核 |
| 图解内存布局：栈、堆与引用（visual_memory_layout） | low | 12935 | 6 | 2 | 待复核 |
| 图解消息队列投递语义（visual_mq_delivery） | low | 15470 | 5 | 2 | 待复核 |
| 图解 OAuth 2.0 授权码流程与 PKCE（visual_oauth_flow） | low | 14721 | 5 | 2 | 待复核 |
| 图解 RAG 检索增强生成流程（visual_rag_pipeline） | low | 15764 | 5 | 2 | 待复核 |
| 图解限流、熔断与降级（visual_rate_limit_circuit） | low | 13458 | 5 | 2 | 待复核 |
| 图解 TCP 握手、挥手与拥塞控制（visual_tcp_handshake） | low | 14623 | 5 | 2 | 待复核 |
| 图解向量检索与 HNSW 索引（visual_vector_index） | low | 13230 | 5 | 2 | 待复核 |

