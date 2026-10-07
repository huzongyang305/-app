# 术语速查待修清单

生成时间：2026-10-07T22:11:03.497212

全库术语速查共 2659 行，其中 278 行需要改写，涉及 189 门课。

问题类型：

- task_term（125）：任务/步骤标题被当成术语：删掉该行，必要时补一条真术语。
- template_desc（54）：说明是模板句：改写成该术语的中文一句话定义。
- english_summary（62）：说明是英文摘要（Summary: ...）：改写成中文一句话定义。
- code_desc（37）：说明是代码行：改写成中文一句话定义。

| 课程 | 待修 | 合格 | 示例 |
| --- | ---: | ---: | --- |
| `csharp_project_inventory_cli` | 4 | 0 | .NET（template_desc）；步骤 1：定义商品和库存变动模型（task_term）；步骤 2：实现 SQLite 数据库初始化（task_term） |
| `go_project_worker_pool` | 4 | 0 | goroutine（template_desc）；步骤 1：定义任务、结果和错误模型（task_term）；步骤 2：创建任务与结果 channel（task_term） |
| `js_project_node_api` | 4 | 0 | Node.js（template_desc）；步骤 1：建立路由、服务和仓储目录（task_term）；步骤 2：定义 Zod 请求模型（task_term） |
| `rust_smart_pointers` | 4 | 0 | Box（english_summary）；任务 1：用自己的话画出结构（task_term）；任务 2：做一次对比实验（task_term） |
| `ai_vector_db` | 3 | 1 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `algorithms_binary_search` | 3 | 1 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `algorithms_prefix_sum` | 3 | 1 | 二维前缀和（code_desc）；任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `algorithms_string_matching` | 3 | 1 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `algorithms_two_pointers` | 3 | 1 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `cross_cli_args` | 3 | 1 | clap（code_desc）；任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `csharp_gc_performance` | 3 | 1 | GC（english_summary）；任务 1：用自己的话画出结构（task_term）；任务 2：做一次对比实验（task_term） |
| `csharp_project_blazor_admin` | 3 | 1 | Blazor（template_desc）；步骤 1：建立订单实体和 DbContext（task_term）；步骤 2：实现分页查询服务（task_term） |
| `db_postgresql_deep` | 3 | 1 | MVCC（english_summary）；执行计划（template_desc）；任务 1：先跑通，再解释（task_term） |
| `go_project_rest_api` | 3 | 1 | Go（template_desc）；步骤 1：定义领域模型和错误（task_term）；步骤 2：实现 SQLite 仓储（task_term） |
| `math_eigen_svd` | 3 | 1 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `mobile_react_native` | 3 | 1 | 用 Hooks 写一个页面（code_desc）；四个最容易出 bug 的 Hooks 用法（code_desc）；平台差异与原生能力（code_desc） |
| `network_http2_http3` | 3 | 1 | 任务 1：用自己的话画出结构（task_term）；任务 2：做一次对比实验（task_term）；任务 3：迁移到自己的场景（task_term） |
| `os_boot_security` | 3 | 1 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `rust_project_axum_api` | 3 | 1 | Rust（template_desc）；步骤 1：定义领域模型和错误类型（task_term）；步骤 2：初始化 SQLx 连接池和迁移（task_term） |
| `toolchain_kubernetes` | 3 | 1 | 任务 1：用自己的话画出结构（task_term）；任务 2：做一次对比实验（task_term）；任务 3：迁移到自己的场景（task_term） |
| `ts_project_websocket_dashboard` | 3 | 1 | TypeScript（template_desc）；步骤 1：定义消息类型和 Zod schema（task_term）；步骤 2：封装 WebSocket 客户端（task_term） |
| `a11y_aria` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `ai_model_serving` | 2 | 2 | KV Cache（english_summary）；量化（template_desc） |
| `algorithms_dynamic_programming` | 2 | 2 | 任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `algorithms_segment_tree` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `algorithms_sorting` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `computer_organization_intro` | 2 | 2 | 实验一：建立基线（task_term）；实验二：只改一个输入（task_term） |
| `cpp_concepts_ranges` | 2 | 2 | Concepts（english_summary）；任务 2：只改一个条件（task_term） |
| `cpp_project_taskdb` | 2 | 2 | SQLite（template_desc）；步骤 1：定义任务模型和数据库 schema（task_term） |
| `cross_collections` | 2 | 2 | 任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `cross_logging_observability` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `cross_serialization` | 2 | 2 | YAML（template_desc）；任务 1：先跑通，再解释（task_term） |
| `cross_string_regex` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `cross_time_timezone` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `css_advanced` | 2 | 3 | 变量（code_desc）；容器查询（code_desc） |
| `database_distributed` | 2 | 2 | Saga（template_desc）；任务 1：先跑通，再解释（task_term） |
| `fundamentals_assembly` | 2 | 2 | 从 C 到汇编：三个对照（code_desc）；任务 2：只改一个条件（task_term） |
| `fundamentals_cache_coherence` | 2 | 2 | NUMA（english_summary）；伪共享（template_desc） |
| `fundamentals_embedded_iot` | 2 | 2 | 低功耗（template_desc）；任务 1：先跑通，再解释（task_term） |
| `fundamentals_storage_stack` | 2 | 2 | ftl（english_summary）；任务 1：先跑通，再解释（task_term） |
| `go_cloud_native_security` | 2 | 2 | mTLS（english_summary）；限流（template_desc） |
| `go_data_access` | 2 | 2 | 连接池（code_desc）；批量插入（code_desc） |
| `java_gc_tuning` | 2 | 2 | GC（english_summary）；停顿（template_desc） |
| `java_modern_features` | 2 | 2 | Sealed（english_summary）；任务 1：用自己的话画出结构（task_term） |
| `java_project_inventory` | 2 | 2 | Spring Boot（template_desc）；步骤 1：建立商品与库存流水实体（task_term） |
| `java_project_order_concurrency` | 2 | 2 | ExecutorService（template_desc）；步骤 1：定义任务和结果模型（task_term） |
| `mobile_harmony` | 2 | 2 | 一个页面的基本结构（code_desc）；五个常用状态装饰器（code_desc） |
| `mobile_miniprogram` | 2 | 2 | 一个页面的完整写法（code_desc）；setData 的三条纪律（code_desc） |
| `network_project` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `network_websocket` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `programming_cpp_control_functions` | 2 | 2 | 三种循环怎么选（code_desc）；声明与定义：编译器和链接器各管一段（code_desc） |
| `programming_rust_errors_iterators_async` | 2 | 2 | thiserror（code_desc）；anyhow（english_summary） |
| `python_project_api` | 2 | 2 | FastAPI（template_desc）；步骤 1：定义 Pydantic 请求模型和统一错误响应（task_term） |
| `python_project_etl` | 2 | 2 | ETL（english_summary）；步骤 1：定义原始记录和目标表结构（task_term） |
| `rust_project_downloader` | 2 | 2 | Tokio（template_desc）；步骤 1：定义任务和结果结构（task_term） |
| `security_container_k8s` | 2 | 2 | RBAC（english_summary）；运行时（template_desc） |
| `shell_project_log_analysis` | 2 | 2 | awk（template_desc）；步骤 1：确定日志格式和字段位置（task_term） |
| `shell_text_advanced` | 2 | 2 | 任务 2：只改一个条件（task_term）；任务 3：迁移到自己的数据（task_term） |
| `toolchain_ci` | 2 | 2 | 任务 1：用自己的话画出结构（task_term）；任务 2：做一次对比实验（task_term） |
| `toolchain_git_basics` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `ts_build_performance` | 2 | 2 | 第二步：项目引用与增量（task_term）；第三步：开发用转译，提交前再检查（task_term） |
| `ts_project_cli` | 2 | 2 | Zod（english_summary）；步骤 1：定义配置 schema 和命令类型（task_term） |
| `visual_k8s_scheduling` | 2 | 2 | 任务 1：先跑通，再解释（task_term）；任务 2：只改一个条件（task_term） |
| `visual_oauth_flow` | 2 | 3 | OAuth（template_desc）；PKCE（english_summary） |
| `ai_a2a` | 1 | 3 | 任务委派（template_desc） |
| `ai_browser_agent` | 1 | 3 | DOM（english_summary） |
| `ai_coding_agent` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `ai_computer_use` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `ai_diffusion` | 1 | 3 | 条件控制（template_desc） |
| `ai_realtime_api` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `ai_tool_calling` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `algo_mst` | 1 | 3 | Prim（english_summary） |
| `algo_np_approximation` | 1 | 3 | NP（english_summary） |
| `algo_shortest_paths` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `algorithms_backtracking` | 1 | 3 | 全排列（code_desc） |
| `algorithms_bit_manipulation` | 1 | 3 | 任务 2：只改一个条件（task_term） |
| `algorithms_graph` | 1 | 4 | DFS（english_summary） |
| `algorithms_greedy` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `algorithms_monotonic_stack` | 1 | 3 | 下一个更大元素（template_desc） |
| `algorithms_network_flow` | 1 | 4 | Dinic（english_summary） |
| `algorithms_time_complexity` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `algorithms_tree_bst` | 1 | 4 | BST（english_summary） |
| `browser_rendering` | 1 | 3 | 强制同步布局：最常见的隐形杀手（code_desc） |
| `c_debugging` | 1 | 3 | GDB（english_summary） |
| `c_files` | 1 | 3 | errno（english_summary） |
| `c_pointers` | 1 | 3 | 解引用（template_desc） |
| `c_project` | 1 | 3 | 文件持久化（template_desc） |
| `c_structs` | 1 | 3 | 填充（template_desc） |
| `c_types` | 1 | 3 | sizeof（english_summary） |
| `cpp_concurrency_atomics` | 1 | 3 | 条件变量（template_desc） |
| `cpp_move_semantics` | 1 | 3 | RVO（english_summary） |
| `cpp_project_http` | 1 | 3 | CMake（template_desc） |
| `cross_db_access` | 1 | 3 | N+1（english_summary） |
| `cross_errors_testing` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `cross_types_variables` | 1 | 3 | 装箱与拆箱：包装类的开销（code_desc） |
| `csharp_async_streams` | 1 | 3 | CancellationToken（template_desc） |
| `csharp_records_patterns` | 1 | 3 | with（english_summary） |
| `css_animation_render` | 1 | 3 | 动画（code_desc） |
| `database_bigdata` | 1 | 5 | Flink（english_summary） |
| `database_nosql` | 1 | 3 | MongoDB（code_desc） |
| `database_query_optimization` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `db_backup_recovery` | 1 | 3 | PITR（english_summary） |
| `db_graph` | 1 | 3 | Cypher（english_summary） |
| `db_migration_governance` | 1 | 3 | Schema（english_summary） |
| `db_time_series` | 1 | 3 | 降采样（template_desc） |
| `distributed_id` | 1 | 3 | 任务 1：用自己的话画出结构（task_term） |
| `distributed_messaging` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `fundamentals_bus_io` | 1 | 4 | 设备（template_desc） |
| `fundamentals_computation_theory` | 1 | 4 | NP 完全（template_desc） |
| `fundamentals_cryptography` | 1 | 3 | 任务 1：用自己的话画出结构（task_term） |
| `fundamentals_encoding` | 1 | 3 | 各语言里的三个易错点（code_desc） |
| `fundamentals_float_check` | 1 | 3 | CRC（template_desc） |
| `fundamentals_project` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `go_testing` | 1 | 3 | 模糊测试（code_desc） |
| `js_execution_context` | 1 | 3 | this（english_summary） |
| `js_project_realtime_chat` | 1 | 3 | WebSocket（template_desc） |
| `kotlin_android` | 1 | 3 | Android（template_desc） |
| `kotlin_basics` | 1 | 3 | 类型推断（template_desc） |
| `kotlin_collections` | 1 | 3 | 集合（template_desc） |
| `kotlin_coroutines` | 1 | 3 | 取消（template_desc） |
| `kotlin_functions` | 1 | 3 | inline（english_summary） |
| `kotlin_oop` | 1 | 3 | 密封类（template_desc） |
| `kotlin_project` | 1 | 3 | 缓存（template_desc） |
| `mobile_compose` | 1 | 3 | 状态提升（code_desc） |
| `mobile_swift` | 1 | 3 | 可选类型：Swift 最核心的安全设计（code_desc） |
| `network_attacks` | 1 | 3 | MITM（english_summary） |
| `network_auth` | 1 | 4 | OAuth2（english_summary） |
| `network_dns` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `network_http_basics` | 1 | 3 | 任务 1：用自己的话画出结构（task_term） |
| `network_ip_transport` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `network_nat_vpn` | 1 | 3 | IPsec（english_summary） |
| `network_p2p` | 1 | 3 | 中继（template_desc） |
| `network_performance` | 1 | 3 | TCP（english_summary） |
| `network_smtp` | 1 | 3 | SPF（english_summary） |
| `network_socket` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `network_tcp_ip` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `network_web_security` | 1 | 4 | CSRF（english_summary） |
| `os_cgroups_namespaces` | 1 | 3 | cgroups（template_desc） |
| `os_filesystem_impl` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `os_ipc_io` | 1 | 3 | 任务 1：用自己的话画出结构（task_term） |
| `os_kernel_arch` | 1 | 3 | 微内核（template_desc） |
| `os_linux_troubleshooting` | 1 | 3 | perf（english_summary） |
| `programming_cpp_templates` | 1 | 5 | Concepts（english_summary） |
| `programming_csharp_basics` | 1 | 3 | 两个文件撑起一个项目（code_desc） |
| `programming_go_generics_stdlib` | 1 | 3 | 泛型三件套（code_desc） |
| `programming_go_interfaces_errors` | 1 | 3 | 接口的两条最佳实践（code_desc） |
| `programming_java_collections` | 1 | 4 | Map（english_summary） |
| `programming_js_dom_events` | 1 | 5 | 事件委托（code_desc） |
| `programming_js_modules_tooling` | 1 | 3 | ESM 的四种导入导出（code_desc） |
| `programming_rust_async` | 1 | 3 | 异步（code_desc） |
| `programming_rust_types_traits` | 1 | 3 | 任务 1：用自己的话画出结构（task_term） |
| `programming_shell_bash` | 1 | 4 | 脚本（template_desc） |
| `programming_shell_flow` | 1 | 3 | 循环（code_desc） |
| `programming_shell_robust` | 1 | 3 | set -euo pipefail（template_desc） |
| `programming_ts_build_test` | 1 | 3 | Vite（english_summary） |
| `programming_ts_project` | 1 | 3 | 路径别名要同时配两处（code_desc） |
| `project_rag_agent_service` | 1 | 3 | RAG（english_summary） |
| `project_rest_api_sqlite` | 1 | 3 | 步骤 1：写清接口资源、请求字段和错误码（task_term） |
| `project_testing_quality` | 1 | 4 | CI（english_summary） |
| `python_context_iterators` | 1 | 3 | with（english_summary） |
| `python_decorators_generators` | 1 | 3 | yield（english_summary） |
| `python_packaging_performance` | 1 | 3 | pyproject（english_summary） |
| `rust_macros_wasm` | 1 | 3 | WASM（english_summary） |
| `rust_traits_generics` | 1 | 3 | trait（english_summary） |
| `se_postmortem` | 1 | 3 | SLO（template_desc） |
| `se_requirements_uml` | 1 | 3 | UML（english_summary） |
| `se_sdl` | 1 | 4 | STRIDE（english_summary） |
| `se_tech_writing` | 1 | 3 | README（english_summary） |
| `security_auth_session` | 1 | 3 | JWT（english_summary） |
| `security_owasp_top10` | 1 | 3 | 注入（template_desc） |
| `security_project` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `shell_automation_advanced` | 1 | 3 | 日志（template_desc） |
| `shell_portability` | 1 | 3 | POSIX（english_summary） |
| `shell_security_hardening` | 1 | 3 | 临时文件（template_desc） |
| `swift_oop` | 1 | 3 | ARC（english_summary） |
| `swift_project` | 1 | 3 | 网络（template_desc） |
| `swift_testing` | 1 | 3 | XCTest（english_summary） |
| `toolchain_cli` | 1 | 3 | 任务 2：只改一个条件（task_term） |
| `ts_monorepo` | 1 | 3 | 内部依赖怎么写（code_desc） |
| `ts_runtime_validation` | 1 | 3 | 任务 1：先跑通，再解释（task_term） |
| `ts_testing` | 1 | 3 | Mock：只在边界用（code_desc） |
| `ts_type_challenges` | 1 | 3 | 五个基础积木（code_desc） |
| `ts_type_level` | 1 | 3 | infer（english_summary） |
| `visual_concurrency_schedule` | 1 | 4 | Goroutine（template_desc） |
| `visual_http_timeline` | 1 | 3 | 任务 1：用自己的话画出结构（task_term） |
| `visual_https_cert` | 1 | 4 | TLS（english_summary） |
| `visual_jvm_memory` | 1 | 4 | OOM（english_summary） |
| `visual_kafka_partition` | 1 | 3 | ISR（english_summary） |
| `visual_vector_index` | 1 | 3 | HNSW（english_summary） |
