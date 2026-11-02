# 人工复核批次台账

- 生成时间：2026-11-02T04:34:14.732860Z
- 批次大小：每批最多 24 门课
- 记录入口：`docs/content_review_records.json` 的 `human_reviews`

> 复核完成后，把复核人、日期、范围与结论写入记录文件，再重跑本工具刷新台账。

## gamedev-1 · 图形与游戏开发

- 课程数：9 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 1 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 该批存在模板命中记录，优先核对正文与解析的机械句残留。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 2D 渲染管线与坐标系（gamedev_2d_rendering） | medium | 12135 | 5 | 2 | 待复核 |
| 动画状态机与混合（gamedev_animation_fsm） | low | 8672 | 5 | 2 | 待复核 |
| 资产管线与热更新（gamedev_asset_pipeline） | low | 9743 | 5 | 2 | 待复核 |
| 碰撞检测与物理基础（gamedev_collision_physics） | low | 9365 | 5 | 2 | 待复核 |
| 实体组件系统与性能剖析（gamedev_ecs_profiling） | low | 10232 | 5 | 2 | 待复核 |
| 游戏循环与帧时间（gamedev_game_loop） | low | 9601 | 5 | 1 | 待复核 |
| 多人同步与延迟处理（gamedev_multiplayer_sync） | low | 10005 | 5 | 2 | 待复核 |
| 移动端性能与功耗优化（gamedev_performance_mobile） | low | 10580 | 5 | 2 | 待复核 |
| 渲染管线与批次合并（gamedev_render_pipeline） | low | 10854 | 5 | 1 | 待复核 |

## security-1 · 安全与合规

- 课程数：15 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 1 · 低 14
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 安全建议与威胁模型对应，示例不鼓励真实环境中的危险操作。
  - 该批存在模板命中记录，优先核对正文与解析的机械句残留。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 安全开发生命周期实战（security_sdl） | medium | 13207 | 5 | 2 | 待复核 |
| 密码与哈希入门（password_hash_intro） | low | 12136 | 6 | 2 | 待复核 |
| 认证、会话与令牌安全（security_auth_session） | low | 11262 | 6 | 2 | 待复核 |
| 云安全与 IAM（security_cloud） | low | 10106 | 5 | 2 | 待复核 |
| 安全概念入门（security_concept_intro） | low | 9877 | 6 | 2 | 待复核 |
| 容器与 Kubernetes 安全（security_container_k8s） | low | 10996 | 5 | 2 | 待复核 |
| 模糊测试与漏洞验证（security_fuzzing） | low | 10908 | 5 | 2 | 待复核 |
| 安全事件响应（security_incident） | low | 10139 | 5 | 2 | 待复核 |
| OWASP Top 10 实战（security_owasp_top10） | low | 10793 | 6 | 2 | 待复核 |
| 隐私合规与数据分级（security_privacy） | low | 10654 | 5 | 2 | 待复核 |
| 实战：安全审计与漏洞修复（security_project） | low | 12582 | 5 | 2 | 待复核 |
| 密钥与配置安全（security_secrets） | low | 9990 | 5 | 2 | 待复核 |
| 安全编码与输入校验（security_secure_coding） | low | 10539 | 6 | 2 | 待复核 |
| 软件供应链安全（security_supply_chain） | low | 9506 | 5 | 2 | 待复核 |
| 威胁建模与 STRIDE（security_threat_model） | low | 9808 | 6 | 2 | 待复核 |

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
| Agent 成本与性能优化（agent_cost_performance） | low | 9592 | 6 | 2 | 待复核 |
| Agent 记忆系统（agent_memory） | low | 11142 | 6 | 2 | 待复核 |
| A2A Agent 协作协议（ai_a2a） | low | 11875 | 6 | 2 | 待复核 |
| AI Agent 基础（ai_agent_basics） | low | 11347 | 6 | 3 | 待复核 |
| Agent 评测实战（ai_agent_evaluation） | low | 14156 | 6 | 2 | 待复核 |
| Agent 安全、权限与沙箱（ai_agent_security） | low | 12021 | 5 | 2 | 待复核 |
| AI、机器学习与生成式 AI（ai_basics） | low | 11494 | 6 | 2 | 待复核 |
| 浏览器 Agent（ai_browser_agent） | low | 11020 | 5 | 2 | 待复核 |
| 代码 Agent 与软件工程自动化（ai_coding_agent） | low | 11578 | 5 | 2 | 待复核 |
| AI 编程助手与代码生成（ai_coding_assistant） | low | 10579 | 6 | 2 | 待复核 |
| Computer Use 与桌面自动化（ai_computer_use） | low | 11752 | 5 | 2 | 待复核 |
| AI 概念入门（ai_concept_intro） | low | 10099 | 6 | 2 | 待复核 |
| 上下文工程（ai_context_engineering） | low | 11542 | 6 | 2 | 待复核 |
| 数据工程与标注（ai_data_engineering） | low | 11503 | 6 | 2 | 待复核 |
| 深度学习与大语言模型（ai_deep_learning_llm） | low | 12677 | 6 | 3 | 待复核 |
| 扩散模型与图像生成（ai_diffusion） | low | 10791 | 5 | 2 | 待复核 |
| 嵌入、向量检索与 RAG（ai_embeddings_rag） | low | 12513 | 6 | 2 | 待复核 |
| AI 应用工程化（ai_engineering） | low | 12132 | 6 | 2 | 待复核 |
| 模型微调与本地部署（ai_fine_tuning_deployment） | low | 13295 | 6 | 2 | 待复核 |
| AI 治理、合规与风险（ai_governance） | low | 10587 | 5 | 2 | 待复核 |
| GraphRAG 与知识图谱检索（ai_graphrag） | low | 11525 | 5 | 2 | 待复核 |
| 安全护栏与内容审核（ai_guardrails） | low | 10787 | 5 | 2 | 待复核 |
| MCP 模型上下文协议（ai_mcp） | low | 9440 | 6 | 2 | 待复核 |
| MLOps 与模型上线（ai_mlops） | low | 11255 | 5 | 2 | 待复核 |

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
| 大模型推理服务与 GPU 优化（ai_model_serving） | low | 9524 | 5 | 2 | 待复核 |
| 多智能体与编排（ai_multi_agent） | low | 10861 | 6 | 2 | 待复核 |
| 多模态 AI：图像、语音与视频（ai_multimodal） | low | 12618 | 6 | 2 | 待复核 |
| 提示工程（ai_prompt_engineering） | low | 11326 | 6 | 2 | 待复核 |
| 实战：文档问答助手（RAG + Agent）（ai_rag_agent_project） | low | 14705 | 6 | 2 | 待复核 |
| Realtime API 与语音交互（ai_realtime_api） | low | 10995 | 5 | 2 | 待复核 |
| 实时语音对话（ai_realtime_voice） | low | 11342 | 6 | 2 | 待复核 |
| 推荐系统基础与排序（ai_recommender） | low | 10509 | 5 | 2 | 待复核 |
| 强化学习基础（ai_reinforcement_learning） | low | 11309 | 5 | 2 | 待复核 |
| 时间序列预测（ai_time_series） | low | 10450 | 5 | 2 | 待复核 |
| 工具调用与结构化输出（ai_tool_calling） | low | 12629 | 5 | 2 | 待复核 |
| 模型训练与分布式（ai_training） | low | 11710 | 6 | 2 | 待复核 |
| 视觉语言模型 VLM（ai_vlm） | low | 9948 | 5 | 2 | 待复核 |
| 机器学习核心概念（ml_fundamentals） | low | 12106 | 6 | 2 | 待复核 |
| 模型评测与选型（model_evaluation） | low | 11334 | 6 | 2 | 待复核 |
| 多模态 RAG（multimodal_rag） | low | 9586 | 6 | 2 | 待复核 |
| 提示词入门（prompt_intro） | low | 11681 | 6 | 2 | 待复核 |
| 向量数据库选型与调优（vector_db） | low | 11418 | 6 | 2 | 待复核 |

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
| 计算几何基础（algo_computational_geometry） | low | 10852 | 5 | 2 | 待复核 |
| 最小生成树与图剪枝（algo_mst） | low | 9576 | 6 | 2 | 待复核 |
| NP 完全性与近似算法（algo_np_approximation） | low | 10810 | 5 | 2 | 待复核 |
| 持久化数据结构与并行算法（algo_persistent_parallel） | low | 9506 | 5 | 2 | 待复核 |
| 最短路算法专题（algo_shortest_paths） | low | 11160 | 6 | 2 | 待复核 |
| 拓扑排序与 DAG 应用（algo_topological） | low | 10598 | 5 | 2 | 待复核 |
| 算法入门（algorithm_intro） | low | 10176 | 5 | 2 | 待复核 |
| 实战：把数据结构用起来（algorithms_project） | low | 13375 | 6 | 2 | 待复核 |
| 回溯算法（backtracking） | low | 11126 | 6 | 2 | 待复核 |
| 平衡树实现（balanced_tree） | low | 12616 | 6 | 2 | 待复核 |
| 二分答案（binary_answer） | low | 9951 | 6 | 2 | 待复核 |
| 二分查找（binary_search） | low | 11296 | 6 | 2 | 待复核 |
| 位运算技巧（bit_manipulation） | low | 11281 | 6 | 2 | 待复核 |
| 冒泡排序（bubble_sort） | low | 11458 | 6 | 2 | 待复核 |
| 缓存淘汰算法（cache_eviction） | low | 12452 | 6 | 2 | 待复核 |
| 动态规划入门（dynamic_programming） | low | 10451 | 6 | 2 | 待复核 |
| 图与图算法（graph） | low | 13538 | 6 | 2 | 待复核 |
| 贪心算法（greedy） | low | 11540 | 6 | 2 | 待复核 |
| 哈希表（hash_table） | low | 12069 | 6 | 3 | 待复核 |
| 线性查找入门（linear_search_intro） | low | 10594 | 6 | 2 | 待复核 |
| 链表（linked_list） | low | 11266 | 6 | 2 | 待复核 |
| 单调栈与单调队列（monotonic_stack） | low | 11109 | 6 | 2 | 待复核 |
| 网络流与二分图匹配（network_flow） | low | 12115 | 6 | 2 | 待复核 |
| 前缀和与差分（prefix_sum） | low | 12778 | 6 | 2 | 待复核 |

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
| 概率数据结构（probabilistic_structures） | low | 11647 | 6 | 2 | 待复核 |
| 树状数组与线段树（segment_tree） | low | 12639 | 6 | 2 | 待复核 |
| 排序算法家族（sorting） | low | 11156 | 6 | 2 | 待复核 |
| 基数排序、桶排序与外部排序（sorting_advanced） | low | 12993 | 6 | 2 | 待复核 |
| 栈与队列（stack_queue） | low | 12575 | 6 | 2 | 待复核 |
| 字符串匹配（string_matching） | low | 10426 | 6 | 2 | 待复核 |
| 时间复杂度（time_complexity） | low | 11015 | 6 | 3 | 待复核 |
| 树与二叉搜索树（tree_bst） | low | 10999 | 6 | 2 | 待复核 |
| 字典树（Trie）（trie） | low | 12804 | 6 | 2 | 待复核 |
| 双指针与滑动窗口（two_pointers） | low | 11047 | 6 | 2 | 待复核 |
| 并查集（union_find） | low | 10594 | 6 | 2 | 待复核 |

## android_development-1 · Android 开发

- 课程数：8 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Android 发布工程：签名、包体与上架轨道（android_flutter_release） | low | 16748 | 6 | 1 | 待复核 |
| Android 后台服务与 WorkManager（mobile_android_background） | low | 15796 | 6 | 1 | 待复核 |
| Android 数据存储（Room/SharedPreferences）（mobile_android_data） | low | 13624 | 6 | 1 | 待复核 |
| Android 网络编程与 Retrofit（mobile_android_networking） | low | 12603 | 6 | 1 | 待复核 |
| Android 测试（Espresso/UI Automator）（mobile_android_testing） | low | 17907 | 6 | 1 | 待复核 |
| Jetpack Compose 声明式 UI（mobile_compose） | low | 10427 | 6 | 1 | 待复核 |
| Android Jetpack Compose进阶（mobile_jetpack_compose_advanced） | low | 16984 | 6 | 1 | 待复核 |
| Kotlin 与 Android 开发（mobile_kotlin） | low | 17895 | 6 | 2 | 待复核 |

## backend_development-1 · 后端开发

- 课程数：8 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 认证授权（JWT/OAuth2）（backend_auth_jwt_oauth） | low | 21918 | 6 | 1 | 待复核 |
| 数据库集成（SQL/NoSQL）（backend_database_integration） | low | 26794 | 6 | 1 | 待复核 |
| Python FastAPI异步Web开发（backend_fastapi_async） | low | 17523 | 6 | 1 | 待复核 |
| Go语言Gin/Echo框架实战（backend_gin_echo） | low | 20455 | 6 | 1 | 待复核 |
| GraphQL入门与Apollo Server（backend_graphql_apollo） | low | 17014 | 6 | 1 | 待复核 |
| 微服务架构模式（backend_microservices_patterns） | low | 22723 | 6 | 1 | 待复核 |
| Node.js与Express/Koa框架实战（backend_nodejs_express） | low | 15242 | 6 | 1 | 待复核 |
| RESTful API设计最佳实践（backend_restful_api） | low | 16285 | 6 | 1 | 待复核 |

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
| 区块链基础与密码学原语（blockchain_basics） | low | 12527 | 5 | 2 | 待复核 |
| 比特币、UTXO 与工作量证明（blockchain_bitcoin_consensus） | low | 12743 | 5 | 2 | 待复核 |
| DeFi 风险与智能合约审计（blockchain_defi_security） | low | 12072 | 5 | 2 | 待复核 |
| 以太坊、EVM 与智能合约（blockchain_ethereum_smart_contract） | low | 12687 | 5 | 2 | 待复核 |
| 扩容、Rollup 与跨链桥（blockchain_scaling_layer2） | low | 12863 | 5 | 2 | 待复核 |
| 项目：智能合约审计实战（chain_audit_project） | low | 13645 | 5 | 2 | 待复核 |
| 预言机与跨链桥（chain_oracle_bridge） | low | 11400 | 5 | 2 | 待复核 |
| 代币标准与合约接口（chain_token_standards） | low | 11373 | 5 | 2 | 待复核 |
| 钱包、密钥与签名（chain_wallet_keys） | low | 10941 | 5 | 2 | 待复核 |
| 零知识与链上隐私（chain_zk_privacy） | low | 11204 | 5 | 2 | 待复核 |

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
| C 数组、字符串与缓冲区（c_arrays_strings） | low | 13075 | 6 | 2 | 待复核 |
| C 基础语法与编译流程（c_basics） | low | 12158 | 6 | 2 | 待复核 |
| C 条件判断（c_conditions） | low | 10643 | 5 | 2 | 待复核 |
| C 控制流、函数与作用域（c_control_functions） | low | 10941 | 6 | 2 | 待复核 |
| C 调试、Sanitizer 与性能（c_debugging） | low | 10711 | 6 | 2 | 待复核 |
| C 文件、错误处理与资源管理（c_files） | low | 12461 | 6 | 2 | 待复核 |
| C 第一个程序（c_first_program） | low | 10988 | 5 | 2 | 待复核 |
| C 函数入门（c_functions_intro） | low | 10749 | 5 | 2 | 待复核 |
| C 循环入门（c_loops） | low | 10533 | 5 | 2 | 待复核 |
| C 指针与内存模型（c_pointers） | low | 10159 | 6 | 2 | 待复核 |
| C 预处理、宏与头文件（c_preprocessor） | low | 11756 | 6 | 2 | 待复核 |
| 实战：C 命令行任务管理器（c_project） | low | 11216 | 5 | 2 | 待复核 |
| 实战：C 语言 TCP 服务端（c_project_tcp_server） | low | 12907 | 5 | 2 | 待复核 |
| C 结构体、联合体与内存布局（c_structs） | low | 10097 | 6 | 2 | 待复核 |
| C 类型、运算符与转换（c_types） | low | 9524 | 6 | 2 | 待复核 |
| C 变量与输入输出（c_variables_io） | low | 10522 | 5 | 2 | 待复核 |

## cloud-1 · 云计算与云原生

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 容器与 Kubernetes 编排（cloud_containers_kubernetes） | low | 13063 | 5 | 2 | 待复核 |
| 云成本治理与容量规划（cloud_cost_finops） | low | 11206 | 5 | 2 | 待复核 |
| 云计算基础与资源模型（cloud_fundamentals） | low | 12185 | 5 | 2 | 待复核 |
| 基础设施即代码（cloud_iac_terraform） | low | 10857 | 5 | 2 | 待复核 |
| Kubernetes 运维实战（cloud_k8s_operations） | low | 14026 | 5 | 2 | 待复核 |
| 多集群与容灾演练（cloud_multicluster_dr） | low | 10633 | 5 | 2 | 待复核 |
| 可观测性与 SRE 实践（cloud_observability_sre） | low | 12640 | 5 | 2 | 待复核 |
| 云安全与最小权限（cloud_security_iam） | low | 11242 | 5 | 2 | 待复核 |
| 无服务器与事件驱动架构（cloud_serverless） | low | 12048 | 5 | 2 | 待复核 |
| 监控告警体系搭建（devops_monitoring） | low | 30841 | 6 | 1 | 待复核 |

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
| 字节码与虚拟机实现（compiler_bytecode_vm） | low | 11260 | 5 | 2 | 待复核 |
| 代码生成与栈式虚拟机（compiler_codegen_vm） | low | 11795 | 5 | 2 | 待复核 |
| 诊断系统与错误恢复（compiler_diagnostics） | low | 10960 | 5 | 2 | 待复核 |
| 垃圾回收算法与实现（compiler_gc） | low | 11099 | 5 | 2 | 待复核 |
| 中间表示与优化（compiler_ir_optimization） | low | 11877 | 5 | 2 | 待复核 |
| 即时编译与内联优化（compiler_jit_inlining） | low | 11029 | 5 | 2 | 待复核 |
| 词法分析与语法分析（compiler_lexer_parser） | low | 11490 | 5 | 2 | 待复核 |
| 编译流程与解释执行概览（compiler_overview） | low | 12510 | 5 | 2 | 待复核 |
| 项目：实现一门迷你语言（compiler_project_minilang） | low | 13845 | 5 | 2 | 待复核 |
| 语义分析与类型系统（compiler_semantic_types） | low | 12082 | 5 | 2 | 待复核 |

## computer_organization-1 · 计算机组成原理

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 总线、中断与 I/O 系统（co_bus_io） | low | 10119 | 6 | 1 | 待复核 |
| CPU 数据通路与控制（co_cpu_datapath） | low | 8984 | 6 | 1 | 待复核 |
| 数据表示与编码（co_data_representation） | low | 9104 | 6 | 1 | 待复核 |
| 指令系统与汇编基础（co_instruction_system） | low | 9375 | 6 | 1 | 待复核 |
| 计算机组成原理导论（co_intro） | low | 9164 | 6 | 1 | 待复核 |
| 数字逻辑与电路基础（co_logic_circuits） | low | 9198 | 6 | 1 | 待复核 |
| 存储层次与 Cache（co_memory_hierarchy） | low | 11008 | 6 | 1 | 待复核 |
| 指令流水线（co_pipeline） | low | 9090 | 6 | 1 | 待复核 |
| 实战项目：搭建一台迷你计算机模拟器（co_project） | low | 14601 | 6 | 1 | 待复核 |
| 虚拟内存与地址转换（co_virtual_memory） | low | 10251 | 6 | 1 | 待复核 |

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
| 环境与编译流程（cpp_basics） | low | 9541 | 6 | 2 | 待复核 |
| C++ Concepts 与 Ranges（cpp_concepts_ranges） | low | 8963 | 6 | 2 | 待复核 |
| C++ 并发、原子操作与内存序（cpp_concurrency_atomics） | low | 9087 | 6 | 2 | 待复核 |
| C++ 条件判断（cpp_conditions） | low | 12507 | 5 | 2 | 待复核 |
| 控制流与函数（cpp_control_functions） | low | 10247 | 6 | 2 | 待复核 |
| C++ 第一个程序（cpp_first_program） | low | 9620 | 5 | 2 | 待复核 |
| C++ 函数入门（cpp_functions_intro） | low | 12822 | 5 | 2 | 待复核 |
| C++ 循环入门（cpp_loops） | low | 9760 | 5 | 2 | 待复核 |
| 内存管理与智能指针（cpp_memory） | low | 9521 | 6 | 2 | 待复核 |
| 现代 C++ 特性（cpp_modern） | low | 9742 | 6 | 2 | 待复核 |
| C++ 移动语义与右值引用（cpp_move_semantics） | low | 10913 | 6 | 2 | 待复核 |
| 类与面向对象（cpp_oop） | low | 12698 | 6 | 2 | 待复核 |
| 指针与引用（cpp_pointers） | low | 11496 | 6 | 2 | 待复核 |
| 实战：CMake 多文件项目（cpp_project） | low | 11088 | 6 | 2 | 待复核 |
| 实战：C++ HTTP JSON 服务（cpp_project_http） | low | 10913 | 6 | 2 | 待复核 |
| 实战：C++ 任务数据库 CLI（cpp_project_taskdb） | low | 8819 | 6 | 2 | 待复核 |
| STL 容器与算法（cpp_stl） | low | 12864 | 6 | 2 | 待复核 |
| 模板与泛型编程（cpp_templates） | low | 11036 | 6 | 2 | 待复核 |
| 构建、调试与工程实践（cpp_tooling） | low | 10107 | 6 | 2 | 待复核 |
| 变量、类型与运算符（cpp_types） | low | 8975 | 6 | 2 | 待复核 |
| C++ 变量与输入输出（cpp_variables_io） | low | 12700 | 5 | 2 | 待复核 |

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
| 接口文档与契约测试：跨生态对照（cross_api_contract） | low | 12809 | 5 | 2 | 待复核 |
| 构建与发布产物：九种生态横向对照（cross_build_release） | low | 10536 | 6 | 2 | 待复核 |
| CI 流水线配置：九种生态横向对照（cross_ci_config） | low | 13055 | 5 | 2 | 待复核 |
| 命令行参数解析：九种语言横向对照（cross_cli_args） | low | 12650 | 5 | 2 | 待复核 |
| 集合类型：九种语言横向对照（cross_collections） | low | 11847 | 6 | 2 | 待复核 |
| 并发写法：九种语言横向对照（cross_concurrency） | low | 13240 | 6 | 2 | 待复核 |
| 数据库访问与 ORM：九种生态横向对照（cross_db_access） | low | 11789 | 5 | 2 | 待复核 |
| 错误处理与测试：九种语言横向对照（cross_errors_testing） | low | 11965 | 6 | 2 | 待复核 |
| 九种语言的第一个程序（cross_first_program） | low | 13861 | 6 | 2 | 待复核 |
| 国际化与本地化：跨生态对照（cross_i18n） | low | 12754 | 5 | 2 | 待复核 |
| 日志与可观测性：九种生态横向对照（cross_logging_observability） | low | 11421 | 5 | 2 | 待复核 |
| 包管理与依赖：九种生态横向对照（cross_package_manage） | low | 14417 | 6 | 2 | 待复核 |
| 性能剖析与基准测试：九种生态横向对照（cross_performance_profiling） | low | 10226 | 5 | 2 | 待复核 |
| 依赖安全与密钥管理：九种生态横向对照（cross_security_ecosystem） | low | 10867 | 5 | 2 | 待复核 |
| 序列化格式：JSON、YAML、Protobuf 横向对照（cross_serialization） | low | 12255 | 5 | 2 | 待复核 |
| 字符串与正则：九种语言横向对照（cross_string_regex） | low | 11499 | 5 | 2 | 待复核 |
| 时间与时区：九种语言横向对照（cross_time_timezone） | low | 12181 | 5 | 2 | 待复核 |
| 类型与变量：九种语言横向对照（cross_types_variables） | low | 12788 | 6 | 2 | 待复核 |

## cross_platform-1 · 跨平台开发

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Flutter 跨平台开发（cross_platform_flutter） | low | 10396 | 6 | 1 | 待复核 |
| Kotlin Multiplatform（cross_platform_kmp） | low | 9569 | 6 | 1 | 待复核 |
| 跨平台状态管理（cross_platform_state_management） | low | 12147 | 6 | 1 | 待复核 |
| 跨平台架构对比与选型（mobile_cross_platform_comparison） | low | 12125 | 6 | 1 | 待复核 |
| 鸿蒙 ArkTS 应用开发（mobile_harmony） | low | 9026 | 6 | 2 | 待复核 |
| 小程序开发要点（mobile_miniprogram） | low | 11227 | 6 | 2 | 待复核 |
| 离线优先架构与数据同步（mobile_offline_first） | low | 17867 | 6 | 1 | 待复核 |
| React Native 跨平台开发（mobile_react_native） | low | 8688 | 6 | 2 | 待复核 |
| React Native深度实践与原生模块（mobile_react_native_deep） | low | 17207 | 6 | 1 | 待复核 |
| 移动安全最佳实践（mobile_security） | low | 16175 | 6 | 1 | 待复核 |

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
| 异步编程与异常处理（csharp_async） | low | 15576 | 6 | 2 | 待复核 |
| C# 异步流与取消（csharp_async_streams） | low | 12787 | 6 | 2 | 待复核 |
| C# 与 .NET 平台（csharp_basics） | low | 14448 | 6 | 2 | 待复核 |
| 集合、委托与 LINQ（csharp_collections_linq） | low | 16521 | 6 | 2 | 待复核 |
| C# 条件判断（csharp_conditions） | low | 10113 | 6 | 2 | 待复核 |
| 控制流与方法（csharp_control_methods） | low | 14915 | 6 | 2 | 待复核 |
| C# 与 .NET 第一个程序（csharp_dotnet_first） | low | 11207 | 5 | 2 | 待复核 |
| 生态、测试与 Web 开发（csharp_ecosystem） | low | 18701 | 6 | 2 | 待复核 |
| C# GC、Span 与性能优化（csharp_gc_performance） | low | 9605 | 6 | 2 | 待复核 |
| 继承、接口与多态（csharp_inheritance） | low | 14787 | 6 | 2 | 待复核 |
| C# 循环入门（csharp_loops） | low | 10851 | 5 | 2 | 待复核 |
| C# 方法入门（csharp_methods_intro） | low | 12233 | 5 | 2 | 待复核 |
| 类、属性与对象（csharp_oop） | low | 14059 | 6 | 2 | 待复核 |
| 实战：Web API + EF Core（csharp_project） | low | 19653 | 6 | 2 | 待复核 |
| 实战：C# Blazor 管理后台（csharp_project_blazor_admin） | low | 12040 | 6 | 2 | 待复核 |
| 实战：C# 库存管理 CLI（csharp_project_inventory_cli） | low | 12388 | 6 | 2 | 待复核 |
| C# Record、模式匹配与不可变数据（csharp_records_patterns） | low | 12799 | 6 | 2 | 待复核 |
| 变量、类型与字符串（csharp_types） | low | 14046 | 6 | 2 | 待复核 |
| C# 变量与输入（csharp_variables_input） | low | 10466 | 5 | 2 | 待复核 |

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
| 批处理与 Spark 实践（de_batch_processing） | low | 11715 | 5 | 2 | 待复核 |
| CDC 与增量同步（de_cdc_incremental） | low | 11593 | 5 | 2 | 待复核 |
| 数据契约与质量门禁（de_data_contract） | low | 11259 | 5 | 2 | 待复核 |
| 数据建模与数仓分层（de_data_modeling） | low | 11420 | 5 | 2 | 待复核 |
| 数据质量与数据治理（de_data_quality） | low | 11668 | 5 | 2 | 待复核 |
| Flink 流处理与窗口（de_flink_windowing） | low | 11622 | 5 | 2 | 待复核 |
| 湖仓治理与表维护（de_lakehouse_governance） | low | 10935 | 5 | 2 | 待复核 |
| 任务编排与数据血缘（de_orchestration_lineage） | low | 11238 | 5 | 2 | 待复核 |
| Spark 执行模型与调优（de_spark_tuning） | low | 11798 | 5 | 2 | 待复核 |
| 流处理与 Kafka 实践（de_stream_processing） | low | 12132 | 5 | 2 | 待复核 |

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
| Airflow 调度与数据质量（airflow_quality） | low | 12536 | 6 | 2 | 待复核 |
| 大数据与批流处理（bigdata_batch_stream） | low | 12770 | 6 | 2 | 待复核 |
| 数据湖与湖仓一体（data_lakehouse） | low | 13489 | 6 | 2 | 待复核 |
| 实战：设计并优化一个订单库（database_project） | low | 15073 | 6 | 2 | 待复核 |
| 数据库备份与恢复演练（db_backup_recovery） | low | 10493 | 5 | 2 | 待复核 |
| 数据库设计与范式（db_design） | low | 13133 | 6 | 2 | 待复核 |
| 图数据库与关系查询（db_graph） | low | 11543 | 6 | 2 | 待复核 |
| 数据库迁移与 Schema 治理（db_migration_governance） | low | 11462 | 6 | 2 | 待复核 |
| 数据库运维：备份、迁移与分库分表（db_ops） | low | 11492 | 6 | 2 | 待复核 |
| 数据库权限与安全（db_permissions_security） | low | 10230 | 5 | 2 | 待复核 |
| PostgreSQL 深入实践（db_postgresql_deep） | low | 11110 | 6 | 2 | 待复核 |
| 查询优化与执行计划（db_query_optimization） | low | 10916 | 6 | 2 | 待复核 |
| 时序数据库与监控数据（db_time_series） | low | 10606 | 6 | 2 | 待复核 |
| 分布式事务与共识（distributed_transaction） | low | 10963 | 6 | 2 | 待复核 |
| 索引（index） | low | 14110 | 6 | 2 | 待复核 |
| MySQL 锁与 MVCC（mysql_lock_mvcc） | low | 13855 | 6 | 2 | 待复核 |
| NoSQL 数据库（nosql） | low | 11607 | 6 | 2 | 待复核 |
| OLAP 与列式存储（olap_columnar） | low | 14823 | 6 | 2 | 待复核 |
| 实时数仓：从 Kafka 到 Flink（realtime_warehouse） | low | 13167 | 6 | 2 | 待复核 |
| Redis 实战（redis） | low | 13896 | 6 | 2 | 待复核 |
| 倒排索引与搜索（search_index） | low | 12855 | 6 | 2 | 待复核 |
| SQL 高级查询（sql_advanced） | low | 12381 | 6 | 2 | 待复核 |
| SQL 基础（sql_basics） | low | 12805 | 6 | 2 | 待复核 |
| SQL 查询入门（sql_query_intro） | low | 11177 | 5 | 2 | 待复核 |

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
| 表与 SQL 入门（sql_table_intro） | low | 11190 | 5 | 2 | 待复核 |
| 存储引擎与 B+ 树实现（storage_engine） | low | 13418 | 6 | 2 | 待复核 |
| 事务（transaction） | low | 11103 | 6 | 3 | 待复核 |

## devops-1 · DevOps 工程

- 课程数：8 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| CI/CD 流水线设计与实现（devops_cicd_pipeline） | low | 25205 | 6 | 1 | 待复核 |
| 蓝绿部署与金丝雀发布（devops_deployment_strategies） | low | 23787 | 6 | 1 | 待复核 |
| 容器镜像构建与仓库管理（devops_docker_registry） | low | 17953 | 6 | 1 | 待复核 |
| GitHub Actions 自动化实战（devops_github_actions） | low | 23620 | 6 | 1 | 待复核 |
| GitOps 与 ArgoCD 实战（devops_gitops_argocd） | low | 30169 | 6 | 1 | 待复核 |
| 日志聚合与链路追踪（devops_logging_tracing） | low | 18254 | 6 | 1 | 待复核 |
| 告警工程：分组路由、错误预算与燃速阈值（devops_monitoring_alert） | low | 21753 | 6 | 1 | 待复核 |
| 基础设施即代码（Terraform）（devops_terraform） | low | 21721 | 6 | 1 | 待复核 |

## discrete_mathematics-1 · 离散数学

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 布尔代数与逻辑电路（discrete_boolean_algebra） | low | 9067 | 6 | 1 | 待复核 |
| 生成函数（discrete_generating_functions） | low | 10169 | 6 | 1 | 待复核 |
| 离散数学与逻辑（discrete_math） | low | 10653 | 6 | 2 | 待复核 |
| 组合数学（discrete_math_combinatorics） | low | 9008 | 6 | 1 | 待复核 |
| 图论基础（discrete_math_graph_theory） | low | 8258 | 6 | 1 | 待复核 |
| 命题逻辑与谓词逻辑（discrete_math_logic） | low | 9857 | 6 | 1 | 待复核 |
| 关系与函数（discrete_math_relations_functions） | low | 8498 | 6 | 1 | 待复核 |
| 集合论基础（discrete_math_set_theory） | low | 10428 | 6 | 1 | 待复核 |
| 数论基础（密码学应用）（discrete_number_theory） | low | 9747 | 6 | 1 | 待复核 |
| 递归与递推关系（discrete_recursion） | low | 9763 | 6 | 1 | 待复核 |

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
| 事件溯源与读写分离（dist_event_sourcing） | low | 11248 | 5 | 2 | 待复核 |
| 分布式事务与一致性（dist_transaction） | low | 10985 | 5 | 2 | 待复核 |
| 分布式缓存架构（distributed_cache） | low | 12443 | 6 | 2 | 待复核 |
| 共识与复制：Raft 实战要点（distributed_consensus） | low | 15397 | 6 | 2 | 待复核 |
| 分布式系统原理（distributed_fundamentals） | low | 11947 | 6 | 3 | 待复核 |
| 分布式 ID 与发号器（distributed_id） | low | 13530 | 6 | 2 | 待复核 |
| 单元化与多活架构（distributed_multisite） | low | 12138 | 6 | 2 | 待复核 |
| 限流与熔断算法专题（distributed_rate_limit） | low | 12186 | 6 | 2 | 待复核 |
| 实战：设计一个短链服务（distributed_short_url_project） | low | 14196 | 6 | 2 | 待复核 |
| 高可用与容量规划（high_availability） | low | 11851 | 6 | 2 | 待复核 |
| 消息队列与事件驱动（messaging_events） | low | 13221 | 6 | 2 | 待复核 |
| 微服务拆分与治理（microservices） | low | 12550 | 6 | 2 | 待复核 |

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
| Bootloader 与固件升级（embedded_bootloader） | low | 12452 | 5 | 2 | 待复核 |
| UART、SPI 与 I2C 通信实战（embedded_bus_protocols） | low | 13703 | 5 | 2 | 待复核 |
| 嵌入式调试与追踪（embedded_debug_trace） | low | 11171 | 5 | 2 | 待复核 |
| 外设编程：GPIO、中断与定时器（embedded_gpio_interrupt） | low | 11874 | 5 | 2 | 待复核 |
| IoT 设备安全基础（embedded_iot_security） | low | 11147 | 5 | 2 | 待复核 |
| 低功耗与电池续航设计（embedded_low_power） | low | 11042 | 5 | 2 | 待复核 |
| 单片机与嵌入式系统基础（embedded_mcu_basics） | low | 12095 | 5 | 2 | 待复核 |
| 项目：环境监测节点（embedded_project_env_monitor） | low | 13463 | 5 | 2 | 待复核 |
| RTOS 任务、调度与同步（embedded_rtos_tasks） | low | 12456 | 5 | 2 | 待复核 |
| 传感器采集与信号调理（embedded_sensor_signal） | low | 10916 | 5 | 2 | 待复核 |

## flutter-1 · Flutter 开发

- 课程数：8 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Flutter 基础与 Widget 树（flutter_basics） | low | 8395 | 6 | 2 | 待复核 |
| Flutter 布局入门（flutter_layout_intro） | low | 9230 | 6 | 1 | 待复核 |
| 实战：Flutter 打包发布 Android（flutter_release） | low | 9789 | 6 | 2 | 待复核 |
| Flutter 状态管理与性能（flutter_state） | low | 11250 | 6 | 2 | 待复核 |
| Flutter Widget 入门（flutter_widget_intro） | low | 9126 | 6 | 2 | 待复核 |
| Flutter高级主题（动画、自定义渲染、平台通道）（mobile_flutter_advanced） | low | 14105 | 6 | 1 | 待复核 |
| 移动端性能优化实战（mobile_performance） | low | 10264 | 6 | 1 | 待复核 |
| 移动端性能优化（mobile_performance_optimization） | low | 12143 | 6 | 1 | 待复核 |

## frontend_frameworks-1 · 前端框架专题

- 课程数：8 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Angular基础与依赖注入（frontend_angular_basics） | low | 20185 | 5 | 1 | 待复核 |
| 框架对比与选型指南（frontend_framework_comparison） | low | 21831 | 6 | 1 | 待复核 |
| Next.js服务端渲染（frontend_nextjs_ssr） | low | 17058 | 5 | 1 | 待复核 |
| 性能优化最佳实践（frontend_performance_optimization） | low | 21201 | 5 | 1 | 待复核 |
| React核心概念与Hooks（frontend_react_hooks） | low | 10916 | 5 | 1 | 待复核 |
| 状态管理深入（frontend_state_management） | low | 27775 | 6 | 1 | 待复核 |
| Svelte响应式编程（frontend_svelte_reactive） | low | 18482 | 5 | 1 | 待复核 |
| Vue 3组合式API（frontend_vue_composition） | low | 13955 | 5 | 1 | 待复核 |

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
| 指令集与汇编入门（assembly） | low | 13033 | 6 | 2 | 待复核 |
| 二进制与进制转换（binary） | low | 12764 | 6 | 2 | 待复核 |
| 二进制入门（binary_intro） | low | 11344 | 5 | 2 | 待复核 |
| 总线与 I/O 设备（bus_io） | low | 12978 | 6 | 2 | 待复核 |
| 代码生成与寄存器分配（codegen_registers） | low | 13086 | 6 | 2 | 待复核 |
| 编译与程序运行原理（compiler） | low | 10263 | 6 | 2 | 待复核 |
| 编译前端：词法与语法分析（compiler_frontend） | low | 13770 | 6 | 2 | 待复核 |
| 计算理论入门（computation_theory） | low | 11515 | 6 | 2 | 待复核 |
| 计算机组成入门（computer_organization_intro） | low | 11897 | 5 | 2 | 待复核 |
| CPU 工作原理（cpu） | low | 11086 | 6 | 2 | 待复核 |
| 密码学原语（cryptography） | low | 12086 | 6 | 2 | 待复核 |
| 数字逻辑与布尔代数（digital_logic） | low | 10814 | 6 | 2 | 待复核 |
| 字符编码与 Unicode（encoding） | low | 12906 | 6 | 2 | 待复核 |
| 浮点数与校验码（float_and_check） | low | 10802 | 6 | 2 | 待复核 |
| 计算机体系结构综合案例（fundamentals_architecture_case） | low | 11269 | 6 | 2 | 待复核 |
| 缓存一致性、内存模型与 NUMA（fundamentals_cache_coherence） | low | 9586 | 6 | 2 | 待复核 |
| 嵌入式与 IoT 基础（fundamentals_embedded_iot） | low | 10880 | 6 | 2 | 待复核 |
| CPU 流水线与指令级并行（fundamentals_pipeline） | low | 11098 | 6 | 2 | 待复核 |
| 实战：追踪程序的全生命周期（fundamentals_project） | low | 13053 | 6 | 2 | 待复核 |
| SIMD 与向量化计算（fundamentals_simd） | low | 10827 | 6 | 2 | 待复核 |
| SSD、存储栈与持久化（fundamentals_storage_stack） | low | 10781 | 6 | 2 | 待复核 |
| 计算机图形学与多媒体（graphics_media） | low | 14051 | 6 | 2 | 待复核 |
| 中断、异常与 DMA（interrupt_exception） | low | 12822 | 6 | 2 | 待复核 |
| 中间代码与优化（ir_optimization） | low | 10799 | 6 | 2 | 待复核 |

## fundamentals-2 · 计算机基础

- 课程数：5 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 5
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 链接与加载（linking_loading） | low | 14275 | 6 | 2 | 待复核 |
| 内存与缓存（memory_cache） | low | 11275 | 6 | 3 | 待复核 |
| 性能度量与并行体系结构（performance_metrics） | low | 11803 | 6 | 2 | 待复核 |
| 概率统计基础（probability） | low | 12795 | 6 | 2 | 待复核 |
| 语义分析与符号表（semantics_analysis） | low | 13711 | 6 | 2 | 待复核 |

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
| Go 基础（go_basics） | low | 12632 | 6 | 2 | 待复核 |
| Go 云原生服务安全与可靠性（go_cloud_native_security） | low | 11861 | 6 | 2 | 待复核 |
| Go 并发：goroutine、channel 与 context（go_concurrency） | low | 12637 | 6 | 2 | 待复核 |
| Go 并发模式与 errgroup（go_concurrency_patterns） | low | 11261 | 6 | 2 | 待复核 |
| Go 条件判断（go_conditions） | low | 10183 | 6 | 2 | 待复核 |
| Go 数据访问与连接池（go_data_access） | low | 14902 | 6 | 2 | 待复核 |
| Go 第一个程序（go_first_program） | low | 10547 | 6 | 2 | 待复核 |
| Go 函数入门（go_functions_intro） | low | 11033 | 5 | 2 | 待复核 |
| Go 泛型深入与约束设计（go_generics_deep） | low | 10362 | 6 | 2 | 待复核 |
| Go 泛型与标准库实战（go_generics_stdlib） | low | 15537 | 6 | 2 | 待复核 |
| gRPC 与 Protobuf 实践（go_grpc） | low | 15024 | 6 | 2 | 待复核 |
| Go 接口与错误处理（go_interfaces_errors） | low | 13268 | 6 | 2 | 待复核 |
| Go 循环入门（go_loops） | low | 10663 | 6 | 2 | 待复核 |
| Go 微服务与可观测（go_microservice） | low | 14217 | 6 | 2 | 待复核 |
| Go 性能优化与内存（go_performance） | low | 11603 | 6 | 2 | 待复核 |
| Go 性能剖析与调优实战（go_pprof） | low | 13618 | 6 | 2 | 待复核 |
| Go 性能剖析与调优（进阶）（go_profiling_deep） | low | 12023 | 6 | 2 | 待复核 |
| Go 工程实践（go_project） | low | 16186 | 6 | 2 | 待复核 |
| 实战：Go REST API 服务（go_project_rest_api） | low | 13517 | 6 | 2 | 待复核 |
| 实战：Go 并发抓取与 Worker Pool（go_project_worker_pool） | low | 14139 | 6 | 2 | 待复核 |
| Go 测试进阶：基准、模糊与集成（go_testing） | low | 14324 | 6 | 2 | 待复核 |
| Go 变量与输入（go_variables_input） | low | 10379 | 6 | 2 | 待复核 |

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
| 可访问性与 ARIA 实战（a11y_aria） | low | 13018 | 6 | 2 | 待复核 |
| 浏览器渲染与事件循环深入（browser_rendering） | low | 11118 | 6 | 2 | 待复核 |
| CSS 进阶：变量、伪类与现代特性（css_advanced） | low | 12953 | 6 | 2 | 待复核 |
| CSS 基础：选择器与盒模型（css_basics） | low | 10026 | 6 | 2 | 待复核 |
| 设计令牌与样式架构（css_design_tokens） | low | 8930 | 6 | 2 | 待复核 |
| CSS 布局：Flex、Grid 与响应式（css_layout） | low | 10894 | 6 | 2 | 待复核 |
| 浏览器渲染与 CSS 动画（css_render_animation） | low | 10960 | 6 | 2 | 待复核 |
| CSS 选择器入门（css_selectors_intro） | low | 10020 | 6 | 2 | 待复核 |
| HTML 基础与语义化（html_basics） | low | 9075 | 6 | 1 | 待复核 |
| 实战：响应式落地页（html_css_project） | low | 12175 | 6 | 2 | 待复核 |
| HTML 标签入门（html_tags_intro） | low | 9430 | 6 | 1 | 待复核 |
| Web Components 实战（web_components） | low | 13813 | 6 | 2 | 待复核 |
| 前端性能优化实战（web_performance） | low | 14055 | 6 | 2 | 待复核 |
| PWA 与离线能力（web_pwa_offline） | low | 12362 | 6 | 2 | 待复核 |

## ios_development-1 · iOS 开发

- 课程数：8 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| App Store 上架流程（mobile_ios_appstore） | low | 14592 | 6 | 1 | 待复核 |
| iOS 架构设计模式（mobile_ios_architecture） | low | 14569 | 6 | 1 | 待复核 |
| iOS 网络编程与数据持久化（mobile_ios_networking） | low | 11875 | 6 | 1 | 待复核 |
| iOS 推送通知与后台任务（mobile_ios_notifications） | low | 12739 | 6 | 1 | 待复核 |
| iOS 性能优化与调试（mobile_ios_performance） | low | 12106 | 6 | 1 | 待复核 |
| iOS 测试与 CI/CD（mobile_ios_testing） | low | 12147 | 6 | 1 | 待复核 |
| Swift 与 iOS 开发（mobile_swift） | low | 8337 | 6 | 1 | 待复核 |
| iOS SwiftUI完整教程（mobile_swiftui_complete） | low | 11848 | 6 | 1 | 待复核 |

## java-1 · Java

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
| 环境与 JVM（java_basics） | low | 9734 | 6 | 2 | 待复核 |
| 集合框架与泛型（java_collections） | low | 9588 | 6 | 2 | 待复核 |
| 多线程与并发（java_concurrency） | low | 9306 | 6 | 2 | 待复核 |
| Java 条件判断（java_conditions） | low | 8684 | 5 | 2 | 待复核 |
| 控制流与方法（java_control_methods） | low | 9094 | 6 | 2 | 待复核 |
| 数据访问与持久化（java_data_access） | low | 15340 | 6 | 1 | 待复核 |
| 部署与容器化（java_deployment） | low | 15471 | 6 | 1 | 待复核 |
| 异常处理与文件 IO（java_exceptions） | low | 13550 | 6 | 2 | 待复核 |
| Java 第一个类（java_first_class） | low | 9341 | 5 | 2 | 待复核 |
| JVM 垃圾回收与性能调优（java_gc_tuning） | low | 13096 | 5 | 2 | 待复核 |
| 继承、接口与多态（java_inheritance） | low | 10524 | 6 | 2 | 待复核 |
| Lambda 与 Stream API（java_lambda_stream） | low | 13966 | 6 | 2 | 待复核 |
| Java 循环入门（java_loops） | low | 12139 | 5 | 2 | 待复核 |
| Java 方法入门（java_methods_intro） | low | 11639 | 5 | 2 | 待复核 |
| 微服务架构设计（java_microservices） | low | 12681 | 6 | 1 | 待复核 |
| 现代 Java：Record、Sealed 与模式匹配（java_modern_features） | low | 9549 | 6 | 2 | 待复核 |
| 类与对象（java_oop） | low | 9402 | 6 | 2 | 待复核 |
| 性能监控与调优（java_performance_monitoring） | low | 13417 | 6 | 1 | 待复核 |
| 实战：Spring Boot REST API（java_project） | low | 11322 | 6 | 2 | 待复核 |
| 实战：完整电商系统（java_project_ecommerce） | low | 23520 | 6 | 2 | 待复核 |
| 实战：Java 并发订单处理服务（java_project_order_concurrency） | low | 13462 | 6 | 2 | 待复核 |
| Java 测试与质量（java_testing） | low | 15379 | 6 | 1 | 待复核 |
| 构建、测试与生态（java_tooling） | low | 13124 | 6 | 2 | 待复核 |
| 变量、类型与字符串（java_types） | low | 8463 | 6 | 2 | 待复核 |

## java-2 · Java

- 课程数：2 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 2
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| Java 变量与输出（java_variables_output） | low | 11419 | 5 | 2 | 待复核 |
| Java 虚拟线程与结构化并发（java_virtual_threads） | low | 10127 | 5 | 2 | 待复核 |

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
| 数组与常用方法（js_arrays） | low | 15055 | 6 | 2 | 待复核 |
| 异步编程（js_async） | low | 16505 | 6 | 2 | 待复核 |
| JavaScript 与运行环境（js_basics） | low | 14275 | 6 | 2 | 待复核 |
| JavaScript 条件与循环（js_conditions_loops） | low | 11348 | 5 | 2 | 待复核 |
| JavaScript 控制台入门（js_console_start） | low | 11581 | 5 | 2 | 待复核 |
| DOM 与事件（js_dom_events） | low | 16937 | 6 | 2 | 待复核 |
| JavaScript DOM 入门（js_dom_intro） | low | 11512 | 5 | 2 | 待复核 |
| 错误处理与调试（js_errors_debugging） | low | 14852 | 6 | 2 | 待复核 |
| JavaScript 执行上下文与闭包（js_execution_context） | low | 11056 | 6 | 2 | 待复核 |
| 函数、作用域与 this（js_functions） | low | 13964 | 6 | 2 | 待复核 |
| JavaScript 函数入门（js_functions_intro） | low | 11005 | 5 | 2 | 待复核 |
| JavaScript 内存管理与垃圾回收（js_memory_gc） | low | 10106 | 6 | 2 | 待复核 |
| 模块化与工程化（js_modules_tooling） | low | 15994 | 6 | 2 | 待复核 |
| Node.js 后端工程（js_node_backend） | low | 10867 | 5 | 2 | 待复核 |
| 对象、原型与类（js_objects） | low | 14587 | 6 | 2 | 待复核 |
| 运算符与控制流（js_operators_control） | low | 13885 | 6 | 2 | 待复核 |
| 实战：Vite + React 待办应用（js_project） | low | 18381 | 6 | 2 | 待复核 |
| 实战：Node.js + Express REST API（js_project_node_api） | low | 13166 | 6 | 2 | 待复核 |
| 实战：JavaScript 实时聊天室（js_project_realtime_chat） | low | 14038 | 6 | 2 | 待复核 |
| 变量、类型与类型转换（js_types） | low | 14515 | 6 | 2 | 待复核 |
| JavaScript 变量与类型入门（js_variables_types_intro） | low | 11794 | 5 | 2 | 待复核 |

## javaweb-1 · Java Web开发

- 课程数：10 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 10
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 实战：Java 库存管理 REST 服务（java_project_inventory） | low | 9289 | 6 | 2 | 待复核 |
| RESTful API 设计与实现（java_restful_api） | low | 16543 | 6 | 1 | 待复核 |
| Servlet 与 JSP 基础（java_servlet_jsp） | low | 10286 | 6 | 1 | 待复核 |
| Spring Boot 入门（java_spring_boot_intro） | low | 14545 | 6 | 1 | 待复核 |
| Spring Framework 核心（java_spring_core） | low | 9682 | 6 | 1 | 待复核 |
| Spring MVC 详解（java_spring_mvc） | low | 16406 | 6 | 1 | 待复核 |
| Spring Security 认证授权（java_spring_security） | low | 14669 | 6 | 1 | 待复核 |
| MyBatis/Hibernate ORM（javaweb_mybatis） | low | 12724 | 6 | 1 | 待复核 |
| Spring Cloud 微服务（javaweb_spring_cloud） | low | 11565 | 6 | 1 | 待复核 |
| Java WebSocket 实时通信（javaweb_websocket） | low | 8729 | 6 | 1 | 待复核 |

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
| Kotlin Android 架构（kotlin_android） | low | 12284 | 6 | 2 | 待复核 |
| Kotlin 基础与空安全（kotlin_basics） | low | 11817 | 6 | 2 | 待复核 |
| Kotlin 集合、序列与函数式操作（kotlin_collections） | low | 11153 | 6 | 2 | 待复核 |
| Kotlin 条件判断（kotlin_conditions） | low | 10900 | 5 | 2 | 待复核 |
| Kotlin 协程与 Flow（kotlin_coroutines） | low | 13441 | 6 | 2 | 待复核 |
| Kotlin 第一个程序（kotlin_first_program） | low | 10990 | 5 | 2 | 待复核 |
| Kotlin 函数、Lambda 与扩展（kotlin_functions） | low | 10714 | 6 | 2 | 待复核 |
| Kotlin 函数入门（kotlin_functions_intro） | low | 11066 | 5 | 2 | 待复核 |
| Kotlin 循环入门（kotlin_loops） | low | 10809 | 5 | 2 | 待复核 |
| Kotlin 类、对象与属性（kotlin_oop） | low | 9671 | 6 | 2 | 待复核 |
| 实战：Kotlin Android 客户端（kotlin_project） | low | 11592 | 5 | 2 | 待复核 |
| 实战：Kotlin 命令行记账工具（kotlin_project_cli_ledger） | low | 13226 | 5 | 2 | 待复核 |
| Kotlin 测试与协程测试（kotlin_testing） | low | 10845 | 5 | 2 | 待复核 |
| Kotlin 变量与空值（kotlin_variables_null） | low | 10707 | 5 | 2 | 待复核 |

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
| 微积分与梯度下降（math_calculus_gradient） | low | 11782 | 6 | 2 | 待复核 |
| 凸优化与约束优化（math_convex_optimization） | low | 11224 | 6 | 2 | 待复核 |
| 特征值、SVD 与降维（math_eigen_svd） | low | 11901 | 6 | 2 | 待复核 |
| 图论与组合数学（math_graph_combinatorics） | low | 11871 | 6 | 2 | 待复核 |
| 信息论：熵与交叉熵（math_information_theory） | low | 12168 | 6 | 2 | 待复核 |
| 数值线性代数（math_numerical_linear_algebra） | low | 11898 | 6 | 2 | 待复核 |
| 概率统计与假设检验（math_probability_stats） | low | 13053 | 6 | 2 | 待复核 |
| 集合与函数入门（math_set_function_intro） | low | 11369 | 6 | 2 | 待复核 |
| 线性代数：向量与矩阵（math_vectors_matrices） | low | 11964 | 6 | 2 | 待复核 |

## ml_practice-1 · 机器学习实战

- 课程数：8 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 8
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 计算机视觉：图像分类与目标检测（ml_computer_vision） | low | 20361 | 6 | 1 | 待复核 |
| 数据预处理与特征工程（ml_data_preprocessing_feature_engineering） | low | 29442 | 6 | 1 | 待复核 |
| 模型部署与MLOps流程（ml_model_deployment_mlops） | low | 25723 | 6 | 1 | 待复核 |
| 模型评估与超参数调优（ml_model_evaluation_hyperparameter_tuning） | low | 27715 | 6 | 1 | 待复核 |
| 自然语言处理：文本分类与情感分析（ml_natural_language_processing） | low | 22338 | 6 | 1 | 待复核 |
| 推荐系统实现（ml_recommendation_systems） | low | 24569 | 6 | 1 | 待复核 |
| TensorFlow与PyTorch框架对比入门（ml_tensorflow_pytorch_intro） | low | 14417 | 6 | 1 | 待复核 |
| 时间序列预测（LSTM/Transformer）（ml_time_series_prediction） | low | 27707 | 6 | 1 | 待复核 |

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
| 认证与授权（auth_oauth） | low | 13675 | 6 | 2 | 待复核 |
| CDN、代理与缓存（cdn_proxy） | low | 11402 | 6 | 2 | 待复核 |
| DNS 域名解析（dns） | low | 13852 | 6 | 3 | 待复核 |
| HTTP/2 与 HTTP/3（http2_http3） | low | 11462 | 6 | 2 | 待复核 |
| HTTP 基础（http_basics） | low | 12585 | 6 | 2 | 待复核 |
| IP 与端口入门（ip_port_intro） | low | 9408 | 6 | 2 | 待复核 |
| IP、子网与传输层深入（ip_transport） | low | 12503 | 6 | 2 | 待复核 |
| 链路层：以太网、ARP 与交换机（link_layer） | low | 13314 | 6 | 2 | 待复核 |
| 网络攻击与防护（network_attacks） | low | 14052 | 6 | 2 | 待复核 |
| BGP 与互联网路由（network_bgp） | low | 15449 | 5 | 2 | 待复核 |
| IPv6 原理与迁移（network_ipv6） | low | 10395 | 6 | 2 | 待复核 |
| 网络分层入门（network_layers_intro） | low | 11092 | 5 | 2 | 待复核 |
| NAT、隧道与 VPN（network_nat_vpn） | low | 12086 | 5 | 2 | 待复核 |
| P2P 网络与 NAT 穿透（network_p2p） | low | 9518 | 5 | 2 | 待复核 |
| 网络性能调优（network_performance） | low | 11405 | 5 | 2 | 待复核 |
| 实战：抓包分析一次真实请求（network_project） | low | 14859 | 6 | 2 | 待复核 |
| SMTP、邮件协议与反垃圾（network_smtp） | low | 13027 | 5 | 2 | 待复核 |
| 渗透测试基础（pentest_basics） | low | 12501 | 6 | 2 | 待复核 |
| Socket 编程实战（socket_programming） | low | 14378 | 6 | 2 | 待复核 |
| TCP/IP 协议栈（tcp_ip） | low | 12940 | 6 | 3 | 待复核 |
| HTTPS 与 TLS（tls） | low | 11896 | 6 | 2 | 待复核 |
| Web 安全攻防（web_security） | low | 12615 | 6 | 2 | 待复核 |
| WebSocket 与实时通信（websocket） | low | 12525 | 6 | 2 | 待复核 |
| 无线与移动网络（wireless_mobile） | low | 14619 | 6 | 2 | 待复核 |

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
| 死锁（deadlock） | low | 10842 | 6 | 3 | 待复核 |
| 文件系统基础（file_system） | low | 11315 | 6 | 2 | 待复核 |
| 进程间通信与 IO 模型（ipc_io） | low | 11826 | 6 | 2 | 待复核 |
| 系统启动与权限安全（os_boot_security） | low | 12916 | 6 | 2 | 待复核 |
| cgroups、namespaces 与容器（os_cgroups_namespaces） | low | 11469 | 6 | 2 | 待复核 |
| 文件系统实现与 RAID（os_filesystem_impl） | low | 12940 | 6 | 2 | 待复核 |
| I/O 调度与块设备（os_io_scheduling） | low | 11380 | 6 | 2 | 待复核 |
| io_uring 与异步 I/O（os_io_uring） | low | 9769 | 5 | 2 | 待复核 |
| 操作系统内核架构（os_kernel_arch） | low | 9789 | 6 | 2 | 待复核 |
| Linux 性能与故障排查（os_linux_troubleshooting） | low | 9531 | 5 | 2 | 待复核 |
| 实战：实现一个多线程任务队列（os_project） | low | 12884 | 6 | 2 | 待复核 |
| 实时操作系统与确定性（os_rtos） | low | 10881 | 5 | 2 | 待复核 |
| 同步机制与经典问题（os_synchronization） | low | 10077 | 6 | 2 | 待复核 |
| 进程与线程（process_thread） | low | 10733 | 6 | 3 | 待复核 |
| 进程与线程入门（process_thread_intro） | low | 11508 | 6 | 2 | 待复核 |
| 进程调度（scheduling） | low | 12861 | 6 | 2 | 待复核 |
| 虚拟内存与分页（virtual_memory） | low | 11277 | 6 | 3 | 待复核 |

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
| 算法工程化与性能验证实战（project_algorithm_engineering） | low | 15147 | 5 | 2 | 待复核 |
| 编码工作流：小步提交与可评审的改动（project_coding_workflow） | low | 13127 | 6 | 2 | 待复核 |
| 操作系统与并发实战（project_concurrency_runtime） | low | 12924 | 5 | 2 | 待复核 |
| 数据工程 ETL 与质量治理实战（project_data_etl） | low | 15660 | 5 | 2 | 待复核 |
| 数据库性能调优实战（project_database_tuning） | low | 12308 | 5 | 2 | 待复核 |
| 实战：慢接口调试与性能定位（project_debug_performance_triage） | low | 12354 | 5 | 2 | 待复核 |
| 部署与运维：稳定发布与快速回滚（project_deploy_ops） | low | 12383 | 5 | 2 | 待复核 |
| DevOps CI/CD 流水线实战（project_devops_pipeline） | low | 17499 | 5 | 2 | 待复核 |
| 面试冲刺：算法编码与系统设计高频题（project_interview_coding_system_design） | low | 12458 | 5 | 2 | 待复核 |
| 移动端离线优先 App 实战（project_mobile_offline_app） | low | 15830 | 5 | 2 | 待复核 |
| 网络抓包与协议分析实战（project_network_capture_analysis） | low | 16489 | 5 | 2 | 待复核 |
| 实战：Python CLI 待办工具（project_python_cli_todo） | low | 13285 | 5 | 2 | 待复核 |
| 实战：本地 RAG 客服 Agent（project_rag_agent_service） | low | 12561 | 5 | 2 | 待复核 |
| 需求到设计：把想法拆成可交付任务（project_requirements_design） | low | 12270 | 6 | 2 | 待复核 |
| 实战：REST API 与 SQLite 事务服务（project_rest_api_sqlite） | low | 14063 | 5 | 2 | 待复核 |
| 复盘与改进：让团队一次比一次快（project_retro_improve） | low | 14498 | 5 | 2 | 待复核 |
| 安全攻防与防御实战（project_security_lab） | low | 14465 | 5 | 2 | 待复核 |
| 测试与质量门禁：把问题挡在上线前（project_testing_quality） | low | 12951 | 5 | 2 | 待复核 |

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
| Python asyncio 异步编程：任务、超时与取消（python_asyncio） | low | 14419 | 5 | 2 | 待复核 |
| Python 基础语法（python_basics） | low | 14543 | 6 | 1 | 待复核 |
| Python CLI 与自动化实战（python_cli_automation） | low | 13963 | 5 | 2 | 待复核 |
| 并发与异步（python_concurrency） | low | 14387 | 6 | 2 | 待复核 |
| Python 并发模型、GIL 与线程进程选型（python_concurrency_model） | low | 13732 | 5 | 2 | 待复核 |
| Python 容器进阶、拷贝与默认参数（python_containers_copy） | low | 12981 | 5 | 2 | 待复核 |
| Python 上下文管理器与迭代器协议（python_context_iterators） | low | 16077 | 6 | 2 | 待复核 |
| 控制流与推导式（python_control_flow） | low | 8396 | 6 | 2 | 待复核 |
| Python 数据处理：NumPy、pandas 与 Polars（python_data_processing） | low | 18370 | 5 | 2 | 待复核 |
| 列表、元组、字典与集合（python_data_structures） | low | 8563 | 6 | 1 | 待复核 |
| Python 数据库与 SQLAlchemy 2.x（python_database_sqlalchemy） | low | 13197 | 5 | 2 | 待复核 |
| Python 装饰器与生成器（python_decorators_generators） | low | 11325 | 6 | 2 | 待复核 |
| Python 异常、日志与文件 I/O 进阶（python_errors_logging_files） | low | 16895 | 5 | 2 | 待复核 |
| Python 第一个脚本（python_first_script） | low | 10552 | 5 | 2 | 待复核 |
| 函数（python_functions） | low | 9269 | 6 | 1 | 待复核 |
| Python GUI 开发：Tkinter 与 PySide6（python_gui） | low | 12965 | 5 | 2 | 待复核 |
| Python HTTP 客户端工程：超时、重试与认证（python_http_clients） | low | 14310 | 5 | 2 | 待复核 |
| Python 条件判断（python_if_else） | low | 8357 | 5 | 1 | 待复核 |
| Python 输入与输出（python_input_output） | low | 11061 | 5 | 2 | 待复核 |
| Python 与 C、C++、Rust 互操作（python_interop） | low | 17416 | 5 | 2 | 待复核 |
| Python 面试专题：原理、编码与工程判断（python_interview） | low | 15355 | 5 | 2 | 待复核 |
| Python 循环入门（python_loops） | low | 13307 | 5 | 2 | 待复核 |
| 现代 Python 特性与版本升级（python_modern_features） | low | 12095 | 5 | 2 | 待复核 |
| 模块、包与虚拟环境（python_modules_stdlib） | low | 12777 | 6 | 2 | 待复核 |

## python-2 · Python

- 课程数：15 · 已人工复核：0 · 状态：pending
- 风险分布：高 0 · 中 0 · 低 15
- 复核重点：
  - 正文事实与术语是否准确，有无过时结论或含糊表述。
  - 代码块能否按正文步骤运行，输出与解析是否一致。
  - 测验题干、选项与解析是否自洽，答案下标是否正确。
  - 参考资料链接可访问，且与课程主题匹配。
  - 示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。

| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |
| --- | --- | --- | --- | --- | --- |
| 类与对象（python_oop） | low | 10470 | 6 | 2 | 待复核 |
| Python 面向对象进阶：继承、组合与魔术方法（python_oop_advanced） | low | 16430 | 5 | 2 | 待复核 |
| Python 打包、发布与性能（python_packaging_performance） | low | 12027 | 6 | 2 | 待复核 |
| 实战：爬虫与数据分析（python_project） | low | 12761 | 6 | 2 | 待复核 |
| 实战：FastAPI 订单服务（python_project_api） | low | 14667 | 6 | 2 | 待复核 |
| Python 项目架构：分层、配置与依赖注入（python_project_architecture） | low | 18355 | 5 | 2 | 待复核 |
| 实战：CSV 到 SQLite 的 ETL 流水线（python_project_etl） | low | 13119 | 6 | 2 | 待复核 |
| Python pytest 测试实战（python_pytest） | low | 10896 | 5 | 2 | 待复核 |
| Python 内存、性能与解释器原理（python_runtime_memory_performance） | low | 16848 | 5 | 2 | 待复核 |
| Python 安全基础：密码、随机数与不可信输入（python_security） | low | 13196 | 5 | 2 | 待复核 |
| Python 标准库实战工具箱（python_stdlib） | low | 15590 | 5 | 2 | 待复核 |
| Python 字符串、Unicode 与格式化（python_strings_encoding） | low | 12428 | 5 | 2 | 待复核 |
| 类型注解与测试（python_typing_testing） | low | 13851 | 6 | 2 | 待复核 |
| 变量与数据类型（python_variables） | low | 9311 | 6 | 1 | 待复核 |
| Python Web 部署：WSGI、ASGI 与容器化（python_web_deployment） | low | 18373 | 5 | 2 | 待复核 |

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
| Rust 异步编程与 tokio（rust_async_tokio） | low | 16464 | 6 | 2 | 待复核 |
| Rust 基础（rust_basics） | low | 13997 | 6 | 2 | 待复核 |
| Rust Cargo 第一个程序（rust_cargo_first） | low | 11339 | 6 | 2 | 待复核 |
| Rust 实战：命令行工具（rust_cli_project） | low | 17628 | 6 | 2 | 待复核 |
| Rust 并发与 Cargo 工程（rust_concurrency_cargo） | low | 11659 | 6 | 2 | 待复核 |
| Rust 条件判断（rust_conditions） | low | 10465 | 5 | 2 | 待复核 |
| Rust 错误处理、迭代器与异步（rust_errors_iterators） | low | 15438 | 6 | 2 | 待复核 |
| Rust 函数入门（rust_functions_intro） | low | 12621 | 5 | 2 | 待复核 |
| Rust 循环入门（rust_loops） | low | 11122 | 5 | 2 | 待复核 |
| Rust 宏、WASM 与跨平台（rust_macros_wasm） | low | 11602 | 6 | 2 | 待复核 |
| Rust 所有权、借用与生命周期（rust_ownership） | low | 15738 | 6 | 2 | 待复核 |
| 实战：Rust + Axum REST API（rust_project_axum_api） | low | 12694 | 6 | 2 | 待复核 |
| 实战：Rust 并发下载器（rust_project_downloader） | low | 13994 | 6 | 2 | 待复核 |
| Rust 智能指针与内部可变性（rust_smart_pointers） | low | 11589 | 6 | 2 | 待复核 |
| Rust trait、泛型与关联类型（rust_traits_generics） | low | 9692 | 6 | 2 | 待复核 |
| Rust 类型系统：Option、Result 与 trait（rust_types_traits） | low | 15816 | 6 | 2 | 待复核 |
| Rust unsafe、FFI 与生态（rust_unsafe_ffi） | low | 14931 | 6 | 2 | 待复核 |
| Rust 变量与可变性（rust_variables_mutability） | low | 10308 | 6 | 2 | 待复核 |

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
| Shell 高级自动化与可观测性（shell_automation_advanced） | low | 10969 | 6 | 2 | 待复核 |
| Shell 与 Bash 脚本（shell_bash） | low | 14678 | 6 | 2 | 待复核 |
| CI 脚本模板库（shell_ci_templates） | low | 13433 | 6 | 2 | 待复核 |
| Shell 条件判断（shell_conditions） | low | 10226 | 5 | 2 | 待复核 |
| Shell 与 Docker/K8s 交互（shell_container） | low | 14619 | 6 | 2 | 待复核 |
| Shell 第一个脚本（shell_first_script） | low | 10882 | 6 | 2 | 待复核 |
| Shell 流程控制与函数（shell_flow） | low | 13744 | 6 | 2 | 待复核 |
| 结构化数据处理：jq 与 yq（shell_json_yaml） | low | 14836 | 6 | 2 | 待复核 |
| Shell 循环入门（shell_loops） | low | 10620 | 5 | 2 | 待复核 |
| 系统运维脚本实战（shell_ops_scripts） | low | 15337 | 6 | 2 | 待复核 |
| Shell 文本处理流水线（shell_pipeline） | low | 13349 | 6 | 2 | 待复核 |
| Shell 管道入门（shell_pipeline_intro） | low | 11594 | 5 | 2 | 待复核 |
| Shell 可移植性与 POSIX 兼容（shell_portability） | low | 12011 | 6 | 2 | 待复核 |
| Shell 进程控制、定时任务与日志（shell_process_cron） | low | 13784 | 6 | 2 | 待复核 |
| 实战：Shell 零停机部署脚本（shell_project_deploy） | low | 12687 | 6 | 2 | 待复核 |
| 实战：Shell 日志分析与告警（shell_project_log_analysis） | low | 11949 | 6 | 2 | 待复核 |
| 健壮与可移植的 Shell 脚本（shell_robust） | low | 14731 | 6 | 2 | 待复核 |
| Shell 脚本工程化（shell_script_engineering） | low | 14250 | 6 | 2 | 待复核 |
| Shell 脚本安全加固（shell_security） | low | 12929 | 6 | 2 | 待复核 |
| Shell 脚本安全加固（进阶）（shell_security_hardening） | low | 11174 | 6 | 2 | 待复核 |
| 文本处理进阶：awk、sed 与正则（shell_text_advanced） | low | 13324 | 6 | 2 | 待复核 |
| Shell 变量与参数（shell_variables_args） | low | 9956 | 6 | 2 | 待复核 |

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
| 设计模式与 SOLID（design_patterns） | low | 12666 | 6 | 2 | 待复核 |
| 需求分析与建模（requirements_modeling） | low | 11874 | 6 | 2 | 待复核 |
| 安全开发生命周期（SDL）（sdl_security） | low | 12287 | 6 | 2 | 待复核 |
| 代码评审方法与实践（se_code_review） | low | 11768 | 6 | 2 | 待复核 |
| On-Call 与告警治理（se_oncall） | low | 12991 | 6 | 2 | 待复核 |
| 故障复盘与事故管理（se_postmortem） | low | 10439 | 6 | 2 | 待复核 |
| 质量度量与工程门禁（se_quality_metrics） | low | 11116 | 6 | 2 | 待复核 |
| TDD 与重构（se_tdd_refactor） | low | 9699 | 6 | 2 | 待复核 |
| 技术债务管理（se_tech_debt） | low | 12288 | 6 | 2 | 待复核 |
| 技术写作与文档工程（se_tech_writing） | low | 12281 | 6 | 2 | 待复核 |
| 测试用例设计方法（se_test_design） | low | 10250 | 6 | 2 | 待复核 |
| 测试策略（testing_strategy） | low | 11824 | 6 | 2 | 待复核 |

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
| Swift 并发与 async/await（swift_async） | low | 12099 | 6 | 2 | 待复核 |
| Swift 基础与可选类型（swift_basics） | low | 15130 | 6 | 2 | 待复核 |
| Swift 集合与泛型（swift_collections） | low | 10803 | 6 | 2 | 待复核 |
| Swift 条件判断（swift_conditions） | low | 10670 | 5 | 2 | 待复核 |
| Swift 常量与变量（swift_constants_variables） | low | 10230 | 5 | 2 | 待复核 |
| Swift 第一个程序（swift_first_program） | low | 10500 | 5 | 2 | 待复核 |
| Swift 函数、闭包与协议（swift_functions） | low | 10467 | 6 | 2 | 待复核 |
| Swift 函数入门（swift_functions_intro） | low | 10994 | 5 | 2 | 待复核 |
| Swift 循环入门（swift_loops） | low | 11036 | 5 | 2 | 待复核 |
| Swift 结构体、类与 ARC（swift_oop） | low | 11305 | 6 | 2 | 待复核 |
| 实战：SwiftUI iOS 客户端（swift_project） | low | 11792 | 5 | 2 | 待复核 |
| 实战：Swift 命令行指标分析工具（swift_project_cli_metrics） | low | 13643 | 5 | 2 | 待复核 |
| SwiftUI 与状态管理（swift_swiftui） | low | 9549 | 6 | 2 | 待复核 |
| Swift 测试与性能（swift_testing） | low | 9607 | 5 | 2 | 待复核 |

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
| CI/CD 与 GitHub Actions（ci_cd） | low | 13282 | 6 | 2 | 待复核 |
| 命令行基础（cli） | low | 11373 | 6 | 2 | 待复核 |
| 命令行入门（cli_intro） | low | 11431 | 6 | 2 | 待复核 |
| 调试与日志（debugging） | low | 13716 | 6 | 2 | 待复核 |
| Docker 容器基础（docker） | low | 13120 | 6 | 2 | 待复核 |
| API 网关与负载均衡（gateway） | low | 13265 | 6 | 2 | 待复核 |
| Git 版本控制（git_basics） | low | 14469 | 6 | 2 | 待复核 |
| Git 入门（git_intro） | low | 9471 | 6 | 2 | 待复核 |
| GitOps 与 ArgoCD（gitops_argocd） | low | 12887 | 6 | 2 | 待复核 |
| Kubernetes 基础（kubernetes） | low | 16294 | 6 | 2 | 待复核 |
| Linux 性能分析（linux_performance） | low | 12283 | 6 | 2 | 待复核 |
| 可观测性：日志、指标与链路（observability） | low | 12055 | 6 | 2 | 待复核 |
| Terraform 与基础设施即代码（terraform） | low | 12936 | 6 | 2 | 待复核 |
| 实战：搭一条完整 CI/CD 流水线（toolchain_project） | low | 14158 | 6 | 2 | 待复核 |

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
| TypeScript 数组与对象（ts_arrays_objects） | low | 10914 | 5 | 2 | 待复核 |
| TypeScript 基础类型（ts_basic_types） | low | 11631 | 5 | 2 | 待复核 |
| 类型检查与构建性能优化（ts_build_performance） | low | 13338 | 6 | 2 | 待复核 |
| TypeScript 构建工具链与测试（ts_build_test） | low | 15228 | 6 | 2 | 待复核 |
| TypeScript 进阶类型与框架实践（ts_decorators_pro） | low | 15704 | 6 | 2 | 待复核 |
| TypeScript 第一个类型（ts_first_types） | low | 10699 | 6 | 2 | 待复核 |
| TypeScript 实战：全栈类型安全（ts_fullstack_project） | low | 16621 | 6 | 2 | 待复核 |
| TypeScript 函数类型（ts_function_types） | low | 10542 | 5 | 2 | 待复核 |
| TypeScript 接口入门（ts_interface_intro） | low | 11347 | 5 | 2 | 待复核 |
| Monorepo 工程实践（ts_monorepo） | low | 13318 | 6 | 2 | 待复核 |
| TypeScript 类型收窄与泛型（ts_narrowing_generics） | low | 13731 | 6 | 2 | 待复核 |
| TypeScript Node 后端开发（ts_node_backend） | low | 14415 | 6 | 2 | 待复核 |
| TypeScript 编译与运行性能（ts_performance） | low | 9588 | 6 | 2 | 待复核 |
| TypeScript 工程配置与实践（ts_project） | low | 15201 | 6 | 2 | 待复核 |
| 实战：TypeScript 类型安全 CLI（ts_project_cli） | low | 13196 | 6 | 2 | 待复核 |
| 实战：TypeScript 实时监控面板（ts_project_websocket_dashboard） | low | 13169 | 6 | 2 | 待复核 |
| TypeScript 运行时校验与边界（ts_runtime_validation） | low | 11801 | 6 | 2 | 待复核 |
| TypeScript 测试策略（ts_testing） | low | 13497 | 6 | 2 | 待复核 |
| TypeScript 类型体操进阶（ts_type_challenges） | low | 12513 | 6 | 2 | 待复核 |
| TypeScript 类型级编程（ts_type_level） | low | 9888 | 6 | 2 | 待复核 |
| TypeScript 工具类型与声明文件（ts_utility_types） | low | 14614 | 6 | 2 | 待复核 |
| TypeScript 类型系统（typescript） | low | 15341 | 6 | 2 | 待复核 |

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
| 图解 B+ 树与数据库索引（visual_btree_index） | low | 11944 | 5 | 2 | 待复核 |
| 图解调用栈与递归（visual_call_stack） | low | 10721 | 6 | 2 | 待复核 |
| 图解 CDN 缓存与回源（visual_cdn_cache） | low | 9604 | 5 | 2 | 待复核 |
| 图解并发调度：线程、协程与 Goroutine（visual_concurrency_schedule） | low | 12122 | 5 | 2 | 待复核 |
| 图解一致性哈希与数据分片（visual_consistent_hashing） | low | 12467 | 5 | 2 | 待复核 |
| 图解数据库事务隔离级别（visual_db_isolation） | low | 10942 | 5 | 2 | 待复核 |
| 图解事件循环：同步、微任务与宏任务（visual_event_loop） | low | 11772 | 6 | 2 | 待复核 |
| 图解 Git 三区与提交流转（visual_git_states） | low | 13241 | 5 | 2 | 待复核 |
| 图解一次网页请求的完整链路（visual_http_timeline） | low | 10520 | 5 | 2 | 待复核 |
| 图解 HTTPS 证书链与 TLS 握手（visual_https_cert） | low | 11231 | 5 | 2 | 待复核 |
| 图解 JVM 内存模型与垃圾回收（visual_jvm_memory） | low | 12134 | 5 | 2 | 待复核 |
| 图解 Kubernetes 调度与探针（visual_k8s_scheduling） | low | 11261 | 5 | 2 | 待复核 |
| 图解 Kafka 分区、副本与再平衡（visual_kafka_partition） | low | 11993 | 5 | 2 | 待复核 |
| 图解大模型推理与显存占用（visual_llm_inference） | low | 11168 | 5 | 2 | 待复核 |
| 图解内存布局：栈、堆与引用（visual_memory_layout） | low | 11392 | 6 | 2 | 待复核 |
| 图解消息队列投递语义（visual_mq_delivery） | low | 12482 | 5 | 2 | 待复核 |
| 图解 OAuth 2.0 授权码流程与 PKCE（visual_oauth_flow） | low | 11454 | 5 | 2 | 待复核 |
| 图解 RAG 检索增强生成流程（visual_rag_pipeline） | low | 13662 | 5 | 2 | 待复核 |
| 图解限流、熔断与降级（visual_rate_limit_circuit） | low | 10704 | 5 | 2 | 待复核 |
| 图解 TCP 握手、挥手与拥塞控制（visual_tcp_handshake） | low | 13410 | 5 | 2 | 待复核 |
| 图解向量检索与 HNSW 索引（visual_vector_index） | low | 12103 | 5 | 2 | 待复核 |

