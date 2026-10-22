// 术语速查行的人工修复指令（供 tool/repair_glossary_rows.dart 使用）。
//
// 每条指令针对「课程 ID + 现有术语名」：
//   GlossaryFix(description: '...')            只改说明；
//   GlossaryFix(term: '新术语', description:)   术语名是从正文小节标题里
//                                              漏进来的短语时，改名并补定义；
//   GlossaryFix(remove: true)                  整行不是术语，直接删除，
//                                              缺的行数由修复工具补足。
class GlossaryFix {
  const GlossaryFix({this.term, this.description, this.remove = false});

  final String? term;
  final String? description;
  final bool remove;
}

/// 修完脏行后不足 4 条术语的课：这里人工指定补哪些术语（[术语, 一句话说明]）。
/// 没有条目的课由修复工具按「正文出现次数 + 小节标题命中」自动挑选。
const Map<String, List<List<String>>> glossaryTopUps =
    <String, List<List<String>>>{
  'a11y_aria': <List<String>>[
    <String>['ARIA', '无障碍富互联网应用规范：用 role 与 aria-* 属性给自定义控件补上屏幕阅读器需要的语义。'],
    <String>['可访问名称', '控件对外播报的名字，图标按钮要用 aria-label 或可见文本提供，否则读屏只会念出「按钮」。'],
    <String>['焦点管理', '用可见的焦点样式和合理的 Tab 顺序把键盘用户的位置说清楚，不要用 outline: none 抹掉它。'],
  ],
  'ai_coding_agent': <List<String>>[
    <String>['验证命令', 'Agent 改完代码必须跑通的构建、测试或类型检查命令，是判断这份补丁是否可用的证据。'],
  ],
  'ai_computer_use': <List<String>>[
    <String>['动作闭环', '截图、识别、执行、再截图确认的循环，每一步都用新画面验证上一步是否真的生效。'],
  ],
  'ai_realtime_api': <List<String>>[
    <String>['打断', '用户随时开口就立刻停掉当前播报并切换到新问题，是实时语音链路最关键的体验指标。'],
  ],
  'ai_tool_calling': <List<String>>[
    <String>['幂等键', '写操作的唯一标识，服务端据此识别重复请求，避免重试变成重复下单。'],
  ],
  'ai_vector_db': <List<String>>[
    <String>['嵌入向量', '把文本或图片映射成的高维数值数组，语义相近的内容在向量空间里距离更近。'],
    <String>['近似最近邻', '用图索引或量化换取速度的检索方式，牺牲少量召回率把全量比对的延迟压到可接受范围。'],
    <String>['元数据过滤', '在向量比对前后按时间、来源等字段筛掉不合格数据，避免只凭相似度召回无关结果。'],
    <String>['召回率', '检索结果里真正相关的比例，用来判断索引参数与过滤条件有没有漏掉本该命中的文档。'],
  ],
  'algo_shortest_paths': <List<String>>[
    <String>['松弛', '对每条边检查「经由它绕行是否更短」，是 Dijkstra 与 Bellman-Ford 共用的核心步骤。'],
  ],
  'algorithms_binary_search': <List<String>>[
    <String>['二分查找', '在有序序列里每次砍掉一半区间，把查找从 O(n) 降到 O(log n)。'],
    <String>['循环不变量', '每轮开始都成立的性质，例如答案始终落在 [lo, hi] 内，用它推导边界写法是否正确。'],
    <String>['上取整中点', 'mid = (lo + hi + 1) // 2；当区间只剩两个元素且 lo = mid 会死循环时必须用它。'],
  ],
  'algorithms_bit_manipulation': <List<String>>[
    <String>['位掩码', '用一个整数的若干二进制位表示集合的开关状态，配合与、或、异或完成集合运算。'],
  ],
  'algorithms_bubble_sort': <List<String>>[
    <String>['稳定性', '相等元素在排序前后相对顺序不变；冒泡只在严格逆序时交换，所以是稳定的。'],
    <String>['交换排序', '通过反复比较相邻元素并交换来消除逆序对的排序思路，冒泡与鸡尾酒排序都属于这一类。'],
    <String>['提前退出', '某一轮没有发生任何交换就说明序列已经有序，可以直接结束循环。'],
  ],
  'algorithms_dynamic_programming': <List<String>>[
    <String>['状态定义', '用 dp[i] 表示「前 i 个元素的最优值」这类明确含义，定义不清后面的转移全错。'],
    <String>['状态转移方程', '由小状态推出大状态的递推式，写清它才能确定遍历顺序与边界处理。'],
  ],
  'algorithms_greedy': <List<String>>[
    <String>['贪心选择性质', '每一步取局部最优仍能得到全局最优的前提；不成立时（如任意面额硬币）就得回到动态规划。'],
  ],
  'algorithms_hash_table': <List<String>>[
    <String>['哈希冲突', '不同键映射到同一个桶的现象，用链地址法或开放寻址解决，冲突率由哈希质量与负载因子决定。'],
  ],
  'algorithms_prefix_sum': <List<String>>[
    <String>['差分数组', '记录相邻元素的差值，让区间加操作变成两次单点修改，最后求前缀和还原。'],
    <String>['第 0 位哨兵', '前缀和数组多留一位并令 prefix[0] = 0，区间和就能统一写成 prefix[r+1] - prefix[l]。'],
  ],
  'algorithms_segment_tree': <List<String>>[
    <String>['懒标记', '区间修改先记在节点上，等真正访问子区间时再下推，把区间更新降到 O(log n)。'],
    <String>['树状数组', '用 lowbit 分层维护前缀和的轻量结构，单点改与区间查都快，但能做的操作比线段树少。'],
  ],
  'algorithms_sorting': <List<String>>[
    <String>['比较函数', '告诉排序「谁在前」的回调，必须满足严格弱序，否则结果未定义。'],
    <String>['外部排序', '数据量超过内存时先分块排序写盘，再做多路归并，是日志与大表排序的常用手段。'],
  ],
  'algorithms_string_matching': <List<String>>[
    <String>['KMP', '利用模式串自身的前后缀信息，失配时只移动模式串、不回退主串下标的匹配算法。'],
    <String>['失配指针', 'next 数组记录每个位置最长相等前后缀的长度，决定失配后跳到哪一位继续比较。'],
    <String>['滚动哈希', '把子串映射成可增量更新的数值，用哈希比较代替逐字符比较，需要处理碰撞。'],
  ],
  'algorithms_time_complexity': <List<String>>[
    <String>['摊还复杂度', '把偶发的高成本操作平摊到一串操作上，例如动态数组扩容，描述的是平均每次的代价。'],
  ],
  'algorithms_two_pointers': <List<String>>[
    <String>['对撞指针', '两个指针从两端向中间收拢，用于有序数组的两数之和、去重与收缩判定。'],
    <String>['单调性', '指针移动后答案只可能朝一个方向变化，这是滑动窗口能不回头的前提。'],
    <String>['快慢指针', '一快一慢两个指针同向推进，用来判环、找中点或定位倒数第 k 个节点。'],
  ],
  'browser_rendering': <List<String>>[
    <String>['渲染管线', '样式计算、布局、绘制、合成四步；改几何属性要走完整流程，改 transform 与 opacity 可以只做合成。'],
  ],
  'c_arrays_strings': <List<String>>[
    <String>['越界访问', '下标超出数组范围时读到相邻内存，是 C 里最常见的内存错误来源，编译器通常不会拦。'],
    <String>['字符串终止符', 'C 字符串以 \\0 结尾，长度靠扫描终止符得到，忘记留这一位就会越界或截断。'],
  ],
  'c_control_functions': <List<String>>[
    <String>['栈帧', '每次函数调用在栈上建立的记录，保存返回地址、参数与局部变量，返回时整体弹出。'],
  ],
  'c_debugging': <List<String>>[
    <String>['最小复现', '能稳定触发问题的最短输入与步骤，配合断点可以把排查范围缩到最小。'],
    <String>['地址消毒器', 'ASan、UBSan 一类的编译期插桩工具，在越界、悬垂指针和未定义行为发生时就报出位置。'],
  ],
  'c_files': <List<String>>[
    <String>['文件描述符', '内核给进程打开的文件、管道、套接字分配的小整数，用完必须 close，否则会泄漏。'],
  ],
  'c_preprocessor': <List<String>>[
    <String>['条件编译', '用 #ifdef、#ifndef 让同一份源码在不同平台或配置下编译出不同代码，头文件守卫也靠它。'],
  ],
  'c_project': <List<String>>[
    <String>['编译单元', '一个 .c 文件连同它包含的头文件，各自独立编译成目标文件后再链接成可执行程序。'],
  ],
  'computer_organization_intro': <List<String>>[
    <String>['存储层次', '寄存器、缓存、内存、磁盘按容量与速度分层，上层缓存下层的数据来缩小速度差。'],
    <String>['局部性原理', '程序倾向重复访问刚用过的数据与相邻数据，缓存因此才有效。'],
  ],
  'cpp_concepts_ranges': <List<String>>[
    <String>['惰性求值', 'Ranges 视图只在遍历到元素时才计算，省掉中间容器，但要留意底层数据的生命周期。'],
  ],
  'cpp_project_taskdb': <List<String>>[
    <String>['参数化 SQL', '用占位符绑定参数而不是拼接字符串，既避免注入也便于数据库复用执行计划。'],
  ],
  'cross_build_release': <List<String>>[
    <String>['制品签名', '发布前对二进制或安装包签名、安装时校验，用来证明产物没有被替换过。'],
  ],
  'cross_ci_config': <List<String>>[
    <String>['缓存键', '决定缓存能否命中的字符串，通常包含依赖锁文件的哈希，写错就会复用到过期的依赖。'],
  ],
  'cross_cli_args': <List<String>>[
    <String>['退出码', '进程结束时返回的整数，0 表示成功、非 0 表示失败，脚本与 CI 据此判断结果。'],
    <String>['帮助信息', '--help 输出的用法说明，要覆盖子命令、必填参数与默认值，是命令行工具的说明书。'],
  ],
  'cross_collections': <List<String>>[
    <String>['哈希表', '用键的哈希值定位桶，平均 O(1) 完成插入与查找，代价是冲突处理与额外内存。'],
    <String>['值语义与引用语义', '赋值与传参时复制整份数据还是共享同一块内存，决定了修改会不会互相影响。'],
  ],
  'cross_errors_testing': <List<String>>[
    <String>['错误链', '抛错时保留底层错误与上下文，调用方才能既知道发生了什么，也知道是哪一层发生的。'],
  ],
  'cross_first_program': <List<String>>[
    <String>['入口函数', '程序启动后第一个被调用的函数，它的返回值会成为进程退出码。'],
    <String>['编译与链接', '编译器把源码翻译成目标文件，链接器再合并库与符号，两步都可能报错。'],
    <String>['标准输出', '程序默认的输出通道，与标准错误分开，方便脚本分别重定向。'],
  ],
  'cross_i18n': <List<String>>[
    <String>['语言标记', 'zh-CN 这类「语言-地区」标签，决定用哪套文案以及日期、数字的格式。'],
  ],
  'cross_logging_observability': <List<String>>[
    <String>['结构化日志', '用键值对或 JSON 记录字段而不是拼字符串，便于检索、聚合和告警。'],
    <String>['日志级别', 'debug、info、warn、error 等严重程度分级，决定默认输出多少、线上保留多少。'],
  ],
  'cross_serialization': <List<String>>[
    <String>['schema 演进', '数据格式升级时保持新旧兼容，新增字段给默认值、不复用字段编号，否则老客户端会直接解析失败。'],
  ],
  'cross_string_regex': <List<String>>[
    <String>['贪婪与懒惰匹配', '量词默认尽可能多匹配，加问号后尽可能少匹配，决定 .* 这类写法的边界。'],
    <String>['捕获组', '用括号把匹配的一部分单独取出来，在替换或后续逻辑里按序号引用。'],
  ],
  'cross_time_timezone': <List<String>>[
    <String>['UTC', '全球统一的时间基准，存储与传输用它，只在展示时换算成本地时区。'],
    <String>['时间戳', '从固定起点开始计的秒数或毫秒数，不含时区信息，比较和排序最省事。'],
  ],
  'cross_types_variables': <List<String>>[
    <String>['隐式转换', '编译器自动完成的类型转换，可能静默丢精度或改变比较结果，跨类型运算时要显式写清。'],
  ],
  'csharp_gc_performance': <List<String>>[
    <String>['分代回收', '.NET GC 按对象存活时间分成 0、1、2 代，优先回收短命对象，减少全堆扫描。'],
    <String>['大对象堆', '大于 85 KB 的对象单独存放且默认不压缩，容易产生碎片并抬高回收成本。'],
  ],
  'csharp_project_blazor_admin': <List<String>>[
    <String>['EF Core', '.NET 的对象关系映射框架，用 DbContext 跟踪实体并把 LINQ 翻译成 SQL。'],
    <String>['SignalR', '在服务端与浏览器之间维持长连接的实时通信库，用来推送订单状态变化。'],
  ],
  'csharp_project_inventory_cli': <List<String>>[
    <String>['System.CommandLine', '.NET 的命令行解析库，用命令、选项与参数描述定义 CLI 的行为。'],
    <String>['xUnit', '.NET 生态常用的单元测试框架，用事实与理论特性组织用例并输出断言结果。'],
    <String>['参数校验', '在命令入口检查参数组合与取值范围，不合格时给出用法提示并以非 0 退出码结束。'],
  ],
  'database_distributed': <List<String>>[
    <String>['幂等补偿', '补偿操作重复执行也不产生额外副作用，这是对账与重试能够安全进行的前提。'],
  ],
  'database_lakehouse': <List<String>>[
    <String>['时间旅行', '借助快照查询历史版本的数据，用于回溯口径变化和排查错误写入。'],
  ],
  'database_project': <List<String>>[
    <String>['慢查询日志', '数据库记录超过阈值语句的日志，是定位全表扫描与缺失索引的入口。'],
  ],
  'database_query_optimization': <List<String>>[
    <String>['覆盖索引', '索引里已经包含查询需要的全部列，不必回表，能显著减少随机 I/O。'],
  ],
  'database_realtime_warehouse': <List<String>>[
    <String>['事件时间', '数据里记录的业务发生时间，与处理时间分开，是窗口计算正确性的基础。'],
    <String>['水位线', '流处理里表示「该时间之前的数据已经到齐」的进度标记，用它决定窗口何时触发。'],
  ],
  'db_postgresql_deep': <List<String>>[
    <String>['VACUUM', '回收 MVCC 留下的死元组并更新统计信息，长期不跑会导致表膨胀与执行计划退化。'],
  ],
  'distributed_consensus': <List<String>>[
    <String>['日志复制', 'leader 把日志条目同步给多数派之后才提交，保证各副本按同一顺序推进状态。'],
  ],
  'distributed_id': <List<String>>[
    <String>['时钟回拨', '机器时间倒退会让基于时间戳的 ID 生成器重复或乱序，需要检测并等待或切换到备用位。'],
  ],
  'distributed_messaging': <List<String>>[
    <String>['死信队列', '重试多次仍然处理失败的消息转存到的地方，避免坏消息阻塞消费并方便人工排查。'],
  ],
  'flutter_basics': <List<String>>[
    <String>['热重载', '保存后把代码改动注入正在运行的应用并尽量保留状态，用来快速验证界面改动。'],
  ],
  'fundamentals_assembly': <List<String>>[
    <String>['寄存器', 'CPU 内部最快的存储单元，用来暂存操作数与地址，不同架构的分工各不相同。'],
    <String>['栈帧', '函数调用时在栈上建立的记录，保存返回地址、参数与局部变量，返回时整体弹出。'],
    <String>['指令集', 'CPU 支持的指令与寄存器约定，比如 x86-64 与 ARM64，决定了汇编代码的写法与可移植性。'],
  ],
  'fundamentals_binary': <List<String>>[
    <String>['进制转换', '二进制、八进制、十六进制与十进制之间的换算，十六进制只是二进制的紧凑写法。'],
    <String>['位运算', '与、或、异或、取反与移位，直接操作二进制位，常用于掩码、压缩与协议解析。'],
    <String>['溢出', '定点整数超出表示范围后的行为，无符号数会回绕，有符号数在 C 里属于未定义行为。'],
  ],
  'fundamentals_cryptography': <List<String>>[
    <String>['口令哈希', '用 bcrypt、scrypt、Argon2 这类慢速算法加盐保存口令，而不是 MD5、SHA 这类快速摘要。'],
  ],
  'fundamentals_discrete_math': <List<String>>[
    <String>['归纳法', '先证明基础情形，再由 n 成立推出 n+1 成立，用来证明与递归结构相关的命题。'],
  ],
  'fundamentals_embedded_iot': <List<String>>[
    <String>['中断', '外设或定时器打断主循环去执行的短程序，通常只做标记，把耗时处理放回主循环。'],
  ],
  'fundamentals_encoding': <List<String>>[
    <String>['码点', '字符在 Unicode 中的编号，例如 U+4E2D，编码才是它在内存里的字节表示。'],
    <String>['UTF-8', '变长编码，ASCII 占一字节、常用汉字占三字节，是文件与网络传输的事实标准。'],
    <String>['字形', '字符在字体里对应的图形，同一个码点在三种字体下字形并不相同。'],
    <String>['BOM', '文件开头的字节顺序标记，UTF-8 场景通常不需要，带上反而会让某些解析器多读出一个字符。'],
  ],
  'fundamentals_probability': <List<String>>[
    <String>['条件概率', '在已知某事件发生的前提下另一事件发生的概率，是理解独立与相关的基础。'],
    <String>['期望', '随机变量按概率加权的平均值，用来衡量长期收益或成本的量级。'],
    <String>['贝叶斯定理', '用先验概率与新证据推导后验概率，是垃圾邮件过滤与 A/B 判断的常用框架。'],
  ],
  'fundamentals_project': <List<String>>[
    <String>['系统调用追踪', '用 strace、perf 观察进程发起的系统调用与耗时，判断卡在文件、网络还是锁上。'],
    <String>['火焰图', '把采样到的调用栈按宽度堆叠成的图，越宽的栈占用 CPU 越多，用来找热点函数。'],
  ],
  'fundamentals_storage_stack': <List<String>>[
    <String>['页缓存', '内核把最近读写的文件页留在内存里的缓存，写入先进缓存，fsync 才保证落盘。'],
  ],
  'go_concurrency_patterns': <List<String>>[
    <String>['worker 池', '固定数量的 goroutine 从 channel 取任务，用有界并发保护下游与本地资源。'],
    <String>['fan-in 与 fan-out', '把任务分发给多个 goroutine，再把结果汇聚回一个 channel 的经典并发结构。'],
    <String>['限流', '用带缓冲 channel 或 rate.Limiter 控制单位时间放行的任务数，避免把下游打垮。'],
  ],
  'go_data_access': <List<String>>[
    <String>['参数化查询', '用占位符绑定参数而不是拼接 SQL，既防注入也让数据库复用执行计划。'],
  ],
  'go_grpc': <List<String>>[
    <String>['Protocol Buffers', 'gRPC 默认的接口定义与序列化格式，用 .proto 描述消息与服务之后生成代码。'],
    <String>['一元 RPC', '一次请求对应一次响应的调用模型，最简单也最常用。'],
    <String>['流式 RPC', '客户端流、服务端流或双向流，用同一条连接连续发送多条消息。'],
  ],
  'go_project_rest_api': <List<String>>[
    <String>['中间件', '在 handler 前后统一处理日志、鉴权、超时等横切逻辑的函数包装。'],
    <String>['httptest', '标准库提供的测试工具，不启真实端口就能构造请求并断言响应。'],
  ],
  'go_project_worker_pool': <List<String>>[
    <String>['errgroup', '把一组 goroutine 的错误与取消统一管理，任何一个失败都可以整体取消。'],
    <String>['有界并发', '用固定 worker 数或信号量限制同时运行的任务，防止内存与下游被打满。'],
    <String>['任务取消', '通过 context 向下传递取消信号，让超时或用户中断时在途任务尽快退出。'],
  ],
  'go_testing': <List<String>>[
    <String>['基准测试', '用 testing.B 反复运行同一段代码并测量耗时与内存，用来验证优化是否真的有效。'],
  ],
  'java_modern_features': <List<String>>[
    <String>['模式匹配', '用 instanceof 或 switch 直接完成类型判断、变量绑定与结构解构，减少样板判断。'],
  ],
  'java_project_inventory': <List<String>>[
    <String>['乐观锁', '更新时带上版本号条件，冲突就重试而不是提前加锁，适合读多写少的场景。'],
  ],
  'java_project_order_concurrency': <List<String>>[
    <String>['指数退避', '重试间隔按 2 的幂增长并加随机抖动，避免下游故障时被重试打垮。'],
  ],
  'js_project_node_api': <List<String>>[
    <String>['参数化查询', '用占位符绑定参数而不是拼接 SQL 字符串，从根上杜绝注入。'],
    <String>['请求校验', '在入口用 schema 校验外部输入并收窄类型，编译期类型保护不了网络数据。'],
    <String>['错误中间件', '集中把异常转成统一错误响应，避免每个路由各写一套。'],
  ],
  'kotlin_android': <List<String>>[
    <String>['协程', 'Kotlin 的轻量并发单元，用挂起函数顺序书写异步逻辑，由调度器决定跑在哪个线程。'],
    <String>['空安全', '类型系统区分可空与非空，编译期就要求处理空值，减少空指针崩溃。'],
  ],
  'kotlin_collections': <List<String>>[
    <String>['扩展函数', '在不修改类的前提下为它添加新方法，标准库的集合操作大量基于它实现。'],
  ],
  'math_convex_optimization': <List<String>>[
    <String>['梯度下降', '沿负梯度方向逐步逼近极小值，每次前进的步长由学习率控制。'],
    <String>['学习率', '每次更新的步长系数，太大来回震荡不收敛，太小则收敛过慢。'],
    <String>['KKT 条件', '带约束优化问题取得最优解的必要条件，用乘子把约束并进目标函数。'],
  ],
  'math_eigen_svd': <List<String>>[
    <String>['特征值', '特征方程 Av = λv 里的 λ，表示矩阵在该特征方向上只缩放不旋转的比例。'],
    <String>['奇异值分解', '把任意矩阵拆成旋转、缩放、旋转三步，奇异值刻画各方向的重要程度。'],
    <String>['主成分分析', '先把数据中心化再做 SVD 取前几个主方向来降维，常用于可视化与去噪。'],
  ],
  'math_graph_combinatorics': <List<String>>[
    <String>['欧拉路径', '恰好经过每条边一次的路径，存在与否同奇度顶点的个数直接相关。'],
    <String>['并查集', '维护元素所属集合的结构，带路径压缩与按秩合并后接近常数时间。'],
    <String>['连通分量', '无向图里互相可达的极大顶点集合，可以用 DFS、BFS 或并查集求出。'],
  ],
  'math_information_theory': <List<String>>[
    <String>['交叉熵', '用预测分布去编码真实分布所需的代价，是分类任务最常用的损失函数。'],
    <String>['KL 散度', '衡量两个分布差异的度量，恒非负且不对称，最小化它与最小化交叉熵等价。'],
  ],
  'math_numerical_linear_algebra': <List<String>>[
    <String>['数值稳定', '算法对输入扰动与浮点误差不敏感，否则误差会随步骤被放大到结果不可用。'],
    <String>['选主元', '高斯消元时挑绝对值最大的元素当枢轴，避免除以极小数放大误差。'],
    <String>['条件数', '最大奇异值与最小奇异值之比，衡量问题本身对扰动有多敏感。'],
    <String>['迭代法', '从初值出发逐步逼近解，比如共轭梯度，适合大规模稀疏矩阵。'],
  ],
  'mobile_compose': <List<String>>[
    <String>['可组合函数', '用 @Composable 标注的界面函数，描述「给定状态界面长什么样」。'],
    <String>['重组', '状态变化后 Compose 只重新执行受影响的可组合函数，而不是整棵界面树。'],
    <String>['单向数据流', '状态向下传、事件向上抛，界面不直接改数据，便于测试与推理。'],
  ],
  'mobile_harmony': <List<String>>[
    <String>['Stage 模型', 'HarmonyOS 的应用模型：每个 UIAbility 是可独立启动的入口，页面在它的窗口里组织。'],
    <String>['状态装饰器', '用 @State、@Prop、@Link 标注数据的流向，决定状态变化如何触发界面刷新。'],
    <String>['ArkTS', 'HarmonyOS 的 TypeScript 系开发语言，在 TS 基础上加了声明式界面与静态约束。'],
    <String>['UIAbility', '应用的能力单元，负责一个可启动的界面以及它的生命周期回调。'],
  ],
  'mobile_kotlin': <List<String>>[
    <String>['构建变体', 'debug、release 等不同配置的产物，用变体维度管理签名、混淆与接口地址。'],
  ],
  'mobile_miniprogram': <List<String>>[
    <String>['分包', '把非首屏页面拆到子包里按需下载，用来控制主包体积以通过平台限制。'],
    <String>['渲染层', '小程序把视图渲染放在独立线程，逻辑层通过 setData 把数据同步过去。'],
  ],
  'mobile_react_native': <List<String>>[
    <String>['桥接', 'JavaScript 与原生之间传递调用与数据的通道，跨线程通信是性能开销的主要来源。'],
    <String>['平台差异', 'iOS 与 Android 在组件、权限、手势上的不一致，需要用 Platform 判断或平台后缀文件分别处理。'],
  ],
  'mobile_swift': <List<String>>[
    <String>['ARC', 'Swift 的自动引用计数，在编译期插入引用计数的增减，循环引用要用 weak 或 unowned 打破。'],
  ],
  'network_dns': <List<String>>[
    <String>['TTL', '解析结果在各级缓存里的存活时间，调大省查询、调小便于快速切换记录。'],
  ],
  'network_http2_http3': <List<String>>[
    <String>['多路复用', '一条连接上并发交错传输多个请求，省掉重复建连与连接排队。'],
    <String>['队头阻塞', '前面的响应或丢包卡住后续数据；HTTP/2 在 TCP 层仍有这个问题，HTTP/3 用 QUIC 消除。'],
    <String>['QUIC', '基于 UDP 的传输协议，把加密、流控与多路复用做进协议本身，支持独立流与快速建连。'],
    <String>['0-RTT', '复用会话票据让首个请求随握手一起发出，代价是存在被重放的风险。'],
  ],
  'network_http_basics': <List<String>>[
    <String>['幂等性', '同一请求重复执行结果一致，GET、PUT、DELETE 应当幂等，重试前必须先判断这一点。'],
  ],
  'network_ip_transport': <List<String>>[
    <String>['MTU', '链路层单次能承载的最大数据长度，超过就要分片，分片丢失会拖垮整包重传。'],
  ],
  'network_project': <List<String>>[
    <String>['抓包过滤', '用 host、port、tcp 等表达式只抓关注的流量，避免把磁盘写满。'],
    <String>['时间戳对照', '把两侧抓包或抓包与应用日志的时间对齐，才能判断延迟发生在哪一段。'],
    <String>['双向抓包', '同时抓客户端与服务端，用序列号与时间差区分丢包、重传还是应用处理慢。'],
  ],
  'network_smtp': <List<String>>[
    <String>['DMARC', '结合 SPF 与 DKIM 告诉收件方如何处理未通过校验的邮件，并提供报告地址。'],
  ],
  'network_socket': <List<String>>[
    <String>['粘包', 'TCP 是字节流，多次发送可能被合并或拆分，接收方要按长度字段或分隔符切分消息。'],
    <String>['非阻塞 I/O', '调用立刻返回并靠就绪通知推进，EAGAIN 表示暂时没有数据而不是出错。'],
  ],
  'network_tcp_ip': <List<String>>[
    <String>['三次握手', 'SYN、SYN+ACK、ACK 三步建立连接并交换初始序列号，连接卡住经常就卡在这一步。'],
  ],
  'network_websocket': <List<String>>[
    <String>['心跳', '定期收发探活帧，用来及时发现半开连接并触发重连。'],
    <String>['重连退避', '断线后按指数增长的间隔重试并加随机抖动，避免同时重连打垮服务端。'],
  ],
  'os_boot_security': <List<String>>[
    <String>['Secure Boot', '固件逐级校验引导程序与内核的签名，阻止被篡改的启动链加载。'],
    <String>['SELinux', '内核的强制访问控制，按策略限制进程能碰哪些文件和端口，缩小漏洞的影响面。'],
    <String>['SUID', '让普通用户以文件属主权限执行的位，是最小权限原则下要重点审查的对象。'],
  ],
  'os_filesystem_impl': <List<String>>[
    <String>['RAID 5', '带分布式校验的条带阵列，能扛一块盘故障，但重建窗口长、写惩罚明显。'],
  ],
  'os_ipc_io': <List<String>>[
    <String>['管道', '内核提供的单向字节流，写满会阻塞、读端关闭会触发 SIGPIPE，适合父子进程串流。'],
  ],
  'os_kernel_arch': <List<String>>[
    <String>['上下文切换', '保存当前执行现场并恢复另一个线程或进程的现场，频繁切换会吃掉可观的性能。'],
  ],
  'os_project': <List<String>>[
    <String>['线程栈采样', '周期性抓取线程调用栈，用来判断 CPU 热点或阻塞点落在哪个函数上。'],
  ],
  'programming_cpp_control_functions': <List<String>>[
    <String>['函数重载', '同名函数按参数列表区分，编译器在调用点选择最匹配的一个。'],
    <String>['引用传递', '形参是实参的别名，避免拷贝且能写回原值；只读场景应当传常量引用。'],
  ],
  'programming_cpp_memory': <List<String>>[
    <String>['移动语义', '用右值引用把资源的所有权转移出去而不是深拷贝，这是 unique_ptr 能放进容器的原因。'],
  ],
  'programming_cpp_pointers': <List<String>>[
    <String>['悬垂指针', '指向已释放内存的指针，解引用属于未定义行为，是崩溃与安全漏洞的常见来源。'],
    <String>['智能指针', 'unique_ptr 独占、shared_ptr 共享、weak_ptr 观察，用所有权表达生命周期。'],
  ],
  'programming_cpp_project': <List<String>>[
    <String>['CMake 目标', '用 target 描述可执行文件、库以及它们之间的依赖，是现代 CMake 的组织单位。'],
    <String>['断言', '测试里用断言表达期望，失败时输出实际值与期望值，便于快速定位。'],
  ],
  'programming_cpp_tooling': <List<String>>[
    <String>['编译数据库', 'compile_commands.json 记录每个文件真实的编译命令，供 clangd 等工具做跳转与补全。'],
    <String>['调试符号', '编译时加上 -g 生成符号信息，调试器才能把地址映射回函数名与行号。'],
  ],
  'programming_cpp_types': <List<String>>[
    <String>['类型推导', 'auto 与模板按初始化表达式推断类型，注意引用与常量限定会被剥掉一部分。'],
  ],
  'programming_csharp_async': <List<String>>[
    <String>['配置等待', '决定 await 恢复时是否需要回到原来的同步上下文，库代码里通常传 false 以避免死锁。'],
  ],
  'programming_csharp_collections_linq': <List<String>>[
    <String>['延迟执行', 'LINQ 查询在枚举时才真正执行，多次枚举会重复查询，必要时先物化成集合。'],
  ],
  'programming_csharp_ecosystem': <List<String>>[
    <String>['NuGet', '.NET 的包管理器，restore 按项目文件解析并下载依赖，锁文件用于固定版本。'],
  ],
  'programming_csharp_inheritance': <List<String>>[
    <String>['抽象类与接口', '抽象类复用实现并约束继承层次，接口只约定能力，一个类型可以实现多个接口。'],
  ],
  'programming_csharp_types': <List<String>>[
    <String>['值类型与引用类型', '结构体赋值复制整份数据，类赋值共享同一个对象，装箱会把值类型搬到堆上。'],
  ],
  'programming_go_basics': <List<String>>[
    <String>['零值', 'Go 的变量声明后自动取该类型的零值，结构体的零值通常可以直接使用。'],
    <String>['错误处理', '函数把 error 作为最后一个返回值显式返回，调用方逐层判断而不是使用异常。'],
  ],
  'programming_go_concurrency': <List<String>>[
    <String>['数据竞争', '多个 goroutine 无同步地读写同一变量，用 -race 检测，靠互斥锁或 channel 消除。'],
  ],
  'programming_go_generics_stdlib': <List<String>>[
    <String>['类型约束', '用接口描述类型参数必须支持的操作，比如 comparable，决定泛型函数内部能写什么。'],
    <String>['结构体标签', '字段后面的 json:"name" 之类元数据，由反射在序列化与校验时读取。'],
  ],
  'programming_go_interfaces_errors': <List<String>>[
    <String>['错误包装', '用 %w 把底层错误包进新错误，保留调用链并支持 errors.Is 与 errors.As 判断。'],
    <String>['panic 与 recover', 'panic 用于不可恢复的编程错误，只能在 defer 里 recover，不要拿它当异常机制。'],
  ],
  'programming_java_lambda_stream': <List<String>>[
    <String>['方法引用', '用双冒号语法把已有方法当作函数式接口的实现，比 lambda 更短也更易读。'],
  ],
  'programming_java_tooling': <List<String>>[
    <String>['依赖坐标', 'groupId 加 artifactId 加版本号唯一确定一个构件，冲突时按最近优先规则解析。'],
  ],
  'programming_java_types': <List<String>>[
    <String>['自动装箱', '基本类型与包装类型之间的隐式转换，超出缓存范围的比较必须用 equals 而不是等号。'],
  ],
  'programming_js_arrays': <List<String>>[
    <String>['变异方法', 'push、splice、sort 这类直接修改原数组的方法，要和返回新数组的 slice、filter 区分开。'],
  ],
  'programming_js_basics': <List<String>>[
    <String>['事件循环', '先执行同步代码与微任务，再取宏任务，它决定了 setTimeout 与 Promise 的执行顺序。'],
    <String>['严格模式', '用 use strict 或在 ES 模块中默认启用，禁止隐式全局变量与部分静默失败的行为。'],
  ],
  'programming_js_modules_tooling': <List<String>>[
    <String>['具名导出与默认导出', '具名导出要用同名导入，默认导出可以任意命名，两者混用最容易写错。'],
  ],
  'programming_js_objects': <List<String>>[
    <String>['原型链', '属性查找会沿原型向上追溯，class 只是原型继承的语法糖。'],
  ],
  'programming_js_operators_control': <List<String>>[
    <String>['短路求值', '与、或运算符在结果已经确定时不再计算右侧，常用它写默认值与条件调用。'],
  ],
  'programming_js_project': <List<String>>[
    <String>['构建脚本', 'package.json 的 scripts 字段把常用命令命名化，让 CI 与本地共用同一入口。'],
  ],
  'programming_python_basics': <List<String>>[
    <String>['动态类型', '变量的类型由运行时的值决定，类型错误只有在执行到那一行时才会暴露。'],
  ],
  'programming_python_data_structures': <List<String>>[
    <String>['列表推导式', '用一行表达式生成新列表，比循环加 append 更简洁，通常也更快。'],
    <String>['字典', '按键值对存储的哈希表，查找是常数时间，键必须是可哈希对象。'],
    <String>['可变与不可变', '列表可变，元组与字符串不可变；默认参数用可变对象会在多次调用之间共享状态。'],
  ],
  'programming_python_errors_files': <List<String>>[
    <String>['上下文管理器', 'with 语句在进入与退出时自动获取和释放资源，文件与锁都靠它保证释放。'],
    <String>['异常链', '用 raise ... from 保留原始异常，traceback 里才能看到真正的起因。'],
  ],
  'programming_python_modules_stdlib': <List<String>>[
    <String>['相对导入', '用点号表示包内层级，只在包被导入时可用，直接运行脚本会失败。'],
  ],
  'programming_python_oop': <List<String>>[
    <String>['实例属性与类属性', '实例属性存在各自对象里，类属性被所有实例共享，可变的类属性最容易被误改。'],
  ],
  'programming_python_variables': <List<String>>[
    <String>['类型注解', '在参数与返回值上标注期望类型，解释器不强制，但检查器与编辑器会据此提示。'],
    <String>['作用域', 'LEGB 规则决定名字从局部、闭包、全局到内置的查找顺序，global 与 nonlocal 用来写外层变量。'],
  ],
  'programming_rust_cli_project': <List<String>>[
    <String>['Cargo', 'Rust 的构建与包管理工具，用 Cargo.toml 声明依赖，提供 build、test、run 等子命令。'],
    <String>['命令解析', 'clap 用派生宏把结构体变成参数定义，自动生成帮助信息与输入校验。'],
    <String>['错误传播', '用问号运算符把底层错误向上抛出，配合 anyhow 与 thiserror 保留上下文。'],
  ],
  'programming_rust_concurrency_cargo': <List<String>>[
    <String>['所有权', '每个值只有一个所有者，离开作用域就释放；跨线程共享要用 Arc 与 Mutex。'],
    <String>['互斥锁', 'Mutex 提供内部可变性并保证同一时刻只有一个线程访问数据，注意避免死锁与长时间持锁。'],
  ],
  'programming_rust_errors_iterators_async': <List<String>>[
    <String>['迭代器适配器', 'map、filter、collect 等惰性组合子，只在被消费时才真正执行，不产生中间集合。'],
  ],
  'programming_rust_types_traits': <List<String>>[
    <String>['Option 与 Result', '用类型表达「可能没有值」和「可能失败」，编译器强制调用方处理这两种情况。'],
    <String>['trait', '描述类型必须实现的能力集合，既能当泛型约束，也能做动态分发。'],
    <String>['派生宏', '用 derive 自动生成 Debug、Clone、PartialEq 等实现，减少样板代码。'],
  ],
  'programming_rust_unsafe_ffi': <List<String>>[
    <String>['unsafe', '放开借用检查以调用 FFI 或操作裸指针，安全性由开发者自己保证，应当封装在小而清晰的边界里。'],
  ],
  'programming_shell_container': <List<String>>[
    <String>['镜像分层', '每条 Dockerfile 指令生成一层并被缓存，把少变的依赖放前面能显著加快构建。'],
  ],
  'programming_shell_flow': <List<String>>[
    <String>['条件判断', 'if 与 test 按退出码判断条件，字符串与数字的比较写法不同，变量要加引号。'],
  ],
  'programming_shell_pipeline': <List<String>>[
    <String>['PIPESTATUS', '数组形式记录管道每一段的退出码，只看管道整体退出码会漏掉中间环节的失败。'],
  ],
  'programming_shell_script_engineering': <List<String>>[
    <String>['trap', '捕获 EXIT、ERR 等信号做清理或上报，是脚本保证临时文件与锁被释放的标准做法。'],
  ],
  'programming_ts_build_test': <List<String>>[
    <String>['转译与类型检查分离', 'esbuild、swc 只做语法转换，类型错误要靠 tsc --noEmit 单独把关。'],
  ],
  'programming_ts_decorators_types_pro': <List<String>>[
    <String>['类型守卫', '用 is 或断言函数把运行时校验的结果告诉编译器，替代不安全的 as 断言。'],
  ],
  'programming_ts_project': <List<String>>[
    <String>['严格模式', 'tsconfig 里的 strict 打开空值、隐式 any 等检查，是团队类型一致性的底线。'],
    <String>['声明文件', '.d.ts 描述没有类型的 JavaScript 模块，让编译器知道它的形状。'],
  ],
  'project_coding_workflow': <List<String>>[
    <String>['分支策略', '约定主干、特性分支与发布分支各自的职责，决定合并方式与回滚成本。'],
    <String>['原子提交', '一次提交只做一件事并且能独立通过测试，出问题时可以安全回退。'],
  ],
  'project_deploy_ops': <List<String>>[
    <String>['可观测性', '用日志、指标与链路追踪还原线上状态，灰度与回滚都要靠它判断是否恶化。'],
  ],
  'project_rest_api_sqlite': <List<String>>[
    <String>['幂等键', '客户端为写请求生成的唯一标识，服务端据此识别重复提交，避免重复扣减。'],
  ],
  'python_project_api': <List<String>>[
    <String>['依赖注入', 'FastAPI 用 Depends 声明路由需要的会话、配置与鉴权，便于替换与测试。'],
  ],
  'python_project_etl': <List<String>>[
    <String>['拒绝记录', '校验失败的行写入拒绝文件并附上原因，保证任务可重跑、坏数据可追溯。'],
  ],
  'rust_project_axum_api': <List<String>>[
    <String>['提取器', 'Axum 从请求里解析 JSON、路径参数或状态并注入 handler，解析失败直接返回错误响应。'],
    <String>['连接池', '复用一批数据库连接，池大小要与数据库的承载能力匹配，过大会把数据库压垮。'],
  ],
  'rust_project_downloader': <List<String>>[
    <String>['信号量', '用许可证限制同时进行的任务数，是异步并发里最常见的限流手段。'],
  ],
  'rust_smart_pointers': <List<String>>[
    <String>['Rc 与 Arc', '引用计数智能指针，Rc 用于单线程共享，Arc 用原子计数以便跨线程。'],
    <String>['内部可变性', '在共享引用下也能修改数据，借用检查从编译期挪到运行期或锁里。'],
    <String>['Weak', '不增加引用计数的弱引用，用来打破 Rc 与 Arc 之间的循环引用。'],
  ],
  'se_tech_writing': <List<String>>[
    <String>['变更日志', '按版本记录新增、修改与修复，让使用者判断升级影响，写作面向读者而不是提交历史。'],
  ],
  'security_incident': <List<String>>[
    <String>['时间线', '把告警、日志与处置动作按时间排列，用来确认影响范围与根因，也是复盘的基础。'],
  ],
  'security_owasp_top10': <List<String>>[
    <String>['越权', '已登录用户访问了不属于自己的资源，属于访问控制缺陷，必须在服务端按归属校验。'],
  ],
  'security_project': <List<String>>[
    <String>['信任边界', '数据从低信任区进入高信任区的接口，校验与鉴权都必须落在这一层。'],
  ],
  'shell_ci_templates': <List<String>>[
    <String>['幂等发布', '同一个版本重复执行不产生额外副作用，这是流水线可以安全重跑的前提。'],
    <String>['失败回滚', '发布失败时把副本与配置切回上一个可用版本，并且要有明确的判定条件。'],
  ],
  'shell_json_yaml': <List<String>>[
    <String>['jq', '在命令行里过滤、提取和重组 JSON 的工具，配合管道处理接口响应最方便。'],
    <String>['YAML 缩进', 'YAML 用缩进表达层级，空格数量不一致或混用制表符是最常见的解析失败原因。'],
  ],
  'shell_ops_scripts': <List<String>>[
    <String>['锁文件', '用 flock 或 pid 文件避免同一脚本并发执行，防止备份互相覆盖。'],
    <String>['保留策略', '按日、周、月分层保留并自动清理过期备份，兼顾恢复窗口与磁盘成本。'],
  ],
  'shell_project_log_analysis': <List<String>>[
    <String>['阈值告警', '对错误率、P95 等指标设置阈值并在越界时通知，阈值要能区分噪声与真实故障。'],
  ],
  'shell_security': <List<String>>[
    <String>['临时文件', '用 mktemp 生成不可预测的文件名并设好权限，避免被符号链接攻击或泄漏数据。'],
  ],
  'shell_text_advanced': <List<String>>[
    <String>['sed', '面向行的流编辑器，用替换等脚本做抽取与改写，适合大文件一次扫过。'],
    <String>['正则捕获组', '用括号把匹配的一部分单独提取出来，在替换里按序号引用。'],
    <String>['awk 字段', 'awk 默认按空白把每行切成若干字段并按列编号，适合直接统计日志中的某一列。'],
    <String>['排序去重', 'sort 与 uniq 组合统计频次，uniq 只能处理相邻重复，所以必须先排序。'],
  ],
  'swift_basics': <List<String>>[
    <String>['可选绑定', '用 if let 或 guard let 解包可选值并绑定非空变量，替代危险的强制解包。'],
  ],
  'swift_functions': <List<String>>[
    <String>['参数标签', 'Swift 在调用点使用外部标签表达语义，用下划线可以省略，用来提升可读性。'],
  ],
  'swift_project': <List<String>>[
    <String>['视图模型', '把界面状态与业务逻辑从视图里抽出来，视图只负责渲染与转发事件。'],
  ],
  'swift_testing': <List<String>>[
    <String>['测试替身', '用 mock 或 stub 模拟网络与存储，让单元测试可重复且不依赖外部服务。'],
    <String>['覆盖率', '衡量被测试执行到的代码比例，只看数字会漏掉断言质量，要配合边界用例一起看。'],
  ],
  'toolchain_ci': <List<String>>[
    <String>['缓存', '把依赖与构建产物按 key 复用，key 要包含锁文件哈希，否则会用到过期依赖。'],
    <String>['密钥管理', '密钥只在运行时注入且不回显，令牌按最小权限发放并定期轮换。'],
  ],
  'toolchain_cli': <List<String>>[
    <String>['退出码', '命令用 0 表示成功、非 0 表示失败，脚本与 CI 都靠它判断，别让错误悄悄返回 0。'],
  ],
  'toolchain_git_basics': <List<String>>[
    <String>['暂存区', 'git add 之后、commit 之前的那份快照，决定这次提交到底包含哪些改动。'],
    <String>['强制推送', '强制推送会覆盖远端历史，在共享分支上会丢掉别人的提交，只能配合保护规则谨慎使用。'],
  ],
  'toolchain_kubernetes': <List<String>>[
    <String>['探针', 'liveness、readiness、startup 三种健康检查，配置不当会误杀容器或过早导入流量。'],
    <String>['资源请求与限制', 'requests 决定调度时的预留量，limits 决定运行时的上限，两者共同决定 Pod 的服务质量等级。'],
    <String>['调度', 'kube-scheduler 按资源、污点与亲和性把 Pod 放到合适的节点上，Pending 多半卡在这一步。'],
  ],
  'toolchain_project': <List<String>>[
    <String>['发布清单', '上线前逐项确认的检查表，包含数据库迁移、开关、监控与回滚脚本，把经验固化成流程。'],
  ],
  'ts_build_performance': <List<String>>[
    <String>['增量编译', '复用上次的构建信息只重编译改动的部分，注意及时清理缓存避免脏产物。'],
    <String>['转译器', 'esbuild、swc 这类只做语法转换的高速工具，负责开发期速度而不做类型检查。'],
    <String>['类型检查门禁', '在 CI 里单独运行 tsc --noEmit，保证类型错误不会被转译器吞掉。'],
  ],
  'ts_monorepo': <List<String>>[
    <String>['任务编排', '用 Turborepo 或 Nx 描述任务之间的依赖与缓存，只重建受影响的包。'],
  ],
  'ts_node_backend': <List<String>>[
    <String>['运行时校验', '在请求入口用 schema 校验外部数据并收窄类型，编译期类型保护不了网络输入。'],
  ],
  'ts_project_cli': <List<String>>[
    <String>['shebang', '脚本首行的解释器声明，决定它被当成可执行文件时用哪个运行时来跑。'],
  ],
  'ts_project_websocket_dashboard': <List<String>>[
    <String>['消息协议', '前后端约定的消息类型与字段，带版本号并做运行时校验之后再进界面。'],
    <String>['窗口裁剪', '图表只保留最近若干数据点，避免长时间运行后内存与渲染开销无限增长。'],
  ],
  'ts_runtime_validation': <List<String>>[
    <String>['类型收窄', '校验通过后把未知类型收窄成具体类型，用类型守卫替代 as 断言。'],
  ],
  'ts_testing': <List<String>>[
    <String>['单元测试边界', '优先覆盖空值、越界与错误分支，只测正常路径的覆盖率没有意义。'],
    <String>['快照测试', '把输出与基线快照比对，适合稳定的结构化输出，更新快照必须经过评审。'],
  ],
  'ts_type_challenges': <List<String>>[
    <String>['infer', '在条件类型里声明待推断的类型变量，用来实现 ReturnType 一类工具类型。'],
    <String>['模板字面量类型', '用反引号把字符串类型拼起来，可以对路由参数或事件名做类型约束。'],
  ],
  'visual_consistent_hashing': <List<String>>[
    <String>['哈希环', '把节点与键都映射到同一个环上，键顺时针找到的第一个节点就是归属，扩缩容只影响相邻区间。'],
    <String>['虚拟节点', '给每个物理节点在环上放多个副本，缓解数据分布不均与热点问题。'],
  ],
  'visual_git_states': <List<String>>[
    <String>['工作区', '你正在编辑的文件状态，与暂存区和最后一次提交三者可能各不相同。'],
    <String>['HEAD', '指向当前分支最新提交的引用，切换分支或回退时它随之移动。'],
  ],
  'visual_http_timeline': <List<String>>[
    <String>['DNS 解析', '把域名换成 IP 的第一步，解析慢会直接推后后面的所有阶段。'],
    <String>['首字节时间', '从发出请求到收到第一个字节的时间，包含网络往返与服务端处理。'],
    <String>['缓存协商', '用 Cache-Control 与 ETag 决定是否复用本地副本，命中时返回 304 省掉重复传输。'],
  ],
  'visual_k8s_scheduling': <List<String>>[
    <String>['探针', '存活与就绪探针的判定决定容器是否重启、是否接收流量，慢启动应用要配启动探针。'],
    <String>['资源请求', 'requests 决定 Pod 被调度到哪个节点以及服务质量等级，设置过低会在高峰期被驱逐。'],
  ],
  'visual_memory_layout': <List<String>>[
    <String>['栈', '存放函数调用与局部变量的区域，随调用自动分配释放，速度快但生命周期只在函数内。'],
  ],
  'visual_mq_delivery': <List<String>>[
    <String>['至少一次投递', '消息可能重复但不会丢失，消费端必须幂等才能安全重试。'],
    <String>['死信队列', '重试仍然失败的消息转存到的地方，避免坏消息阻塞消费并方便排查。'],
  ],
  'visual_rag_pipeline': <List<String>>[
    <String>['重排序', '先粗召回再用交叉编码器精排，能明显提升答案引用到正确文档的概率。'],
    <String>['引用溯源', '答案带上原文片段与出处，便于用户核对并降低幻觉带来的影响。'],
  ],
};

/// 自动补术语时的兜底定义（正文里没有现成合格行时使用）。
const Map<String, String> glossaryDefinitions = <String, String>{};

const Map<String, Map<String, GlossaryFix>> glossaryFixes =
    <String, Map<String, GlossaryFix>>{
  'ai_a2a': <String, GlossaryFix>{
    '任务委派': GlossaryFix(description: '把子目标连同上下文交给另一个 Agent 执行，再汇总各自结果。'),
  },
  'ai_browser_agent': <String, GlossaryFix>{
    'DOM': GlossaryFix(description: '浏览器把网页解析成的文档对象模型，Agent 靠它定位和操作页面元素。'),
  },
  'ai_diffusion': <String, GlossaryFix>{
    '条件控制': GlossaryFix(description: '在去噪过程中加入文本、深度或姿态等条件，引导模型生成指定内容。'),
  },
  'ai_model_serving': <String, GlossaryFix>{
    '量化': GlossaryFix(description: '用更低位宽表示权重与激活，换取更小显存和更高吞吐，代价是精度略降。'),
    'KV Cache': GlossaryFix(description: '缓存已生成 token 的注意力键值，避免每步重算，直接决定长上下文的显存占用。'),
  },
  'algo_mst': <String, GlossaryFix>{
    'Prim': GlossaryFix(description: '最小生成树的加点算法：每次选连接已选集与外部的最短边，适合稠密图。'),
  },
  'algo_np_approximation': <String, GlossaryFix>{
    'NP': GlossaryFix(description: '非确定性多项式时间：解能在多项式时间内被验证的问题类，NP 完全问题是其中最难的一批。'),
  },
  'algorithms_backtracking': <String, GlossaryFix>{
    '全排列': GlossaryFix(description: '把 n 个元素按所有可能的顺序逐一列出，共 n! 种，常用回溯或交换法生成。'),
  },
  'algorithms_graph': <String, GlossaryFix>{
    'DFS': GlossaryFix(description: '深度优先搜索：沿一条路径走到底再回退，用栈或递归实现，可判连通、找环与拓扑排序。'),
  },
  'algorithms_monotonic_stack': <String, GlossaryFix>{
    '下一个更大元素': GlossaryFix(description: '右边第一个比当前元素大的位置；用单调栈一遍扫完，复杂度 O(n)。'),
  },
  'algorithms_network_flow': <String, GlossaryFix>{
    'Dinic': GlossaryFix(description: '最大流算法：用分层图加阻塞流反复增广，复杂度 O(V²E)，是常用的最大流实现。'),
  },
  'algorithms_prefix_sum': <String, GlossaryFix>{
    '二维前缀和': GlossaryFix(description: '用一张表记录左上角到每个位置的累加值，把任意子矩阵求和降到 O(1)。'),
  },
  'algorithms_tree_bst': <String, GlossaryFix>{
    'BST': GlossaryFix(description: '二叉搜索树：左子树键都小于根、右子树都大于根；平衡时查找 O(log n)，退化成链就是 O(n)。'),
  },
  'browser_rendering': <String, GlossaryFix>{
    '强制同步布局：最常见的隐形杀手': GlossaryFix(
      term: '强制同步布局',
      description: '读写布局属性交替执行时浏览器被迫立即重排，是页面卡顿的常见原因。',
    ),
  },
  'c_debugging': <String, GlossaryFix>{
    'GDB': GlossaryFix(description: 'GNU 调试器：可设断点、单步执行、查看栈帧与变量，是定位 C 程序崩溃的主力工具。'),
  },
  'c_files': <String, GlossaryFix>{
    'errno': GlossaryFix(description: '系统调用失败时写入的全局错误码，必须在调用后立即读取，配合 strerror 转成可读文本。'),
  },
  'c_pointers': <String, GlossaryFix>{
    '解引用': GlossaryFix(description: '用 * 运算符按地址读写目标内存；指针为空或已释放时解引用是未定义行为。'),
  },
  'c_project': <String, GlossaryFix>{
    '文件持久化': GlossaryFix(description: '把内存数据按约定格式写进文件并在下次启动时读回，使程序退出后数据仍然保留。'),
  },
  'c_structs': <String, GlossaryFix>{
    '填充': GlossaryFix(description: '编译器为满足对齐要求插入的空闲字节；它让结构体大于成员之和，影响内存占用与可移植性。'),
  },
  'c_types': <String, GlossaryFix>{
    'sizeof': GlossaryFix(description: '返回类型或对象占用的字节数，在编译期求值；数组与指针上的结果不同是常见陷阱。'),
  },
  'cpp_concepts_ranges': <String, GlossaryFix>{
    'Concepts': GlossaryFix(description: 'C++20 的编译期约束：用命名要求限定模板参数，让报错指向真正不满足的条件。'),
  },
  'cpp_concurrency_atomics': <String, GlossaryFix>{
    '条件变量': GlossaryFix(description: '让线程在条件不满足时挂起、满足时被唤醒的同步原语，必须与互斥量和谓词循环配合。'),
  },
  'cpp_move_semantics': <String, GlossaryFix>{
    'RVO': GlossaryFix(description: '返回值优化：编译器直接在调用方内存里构造返回对象，省掉一次拷贝或移动。'),
  },
  'cpp_project_http': <String, GlossaryFix>{
    'CMake': GlossaryFix(description: '跨平台构建系统生成器：用 CMakeLists.txt 描述目标与依赖，再生成 Makefile 或 Ninja 工程。'),
  },
  'cpp_project_taskdb': <String, GlossaryFix>{
    'SQLite': GlossaryFix(description: '单文件嵌入式关系数据库，无需独立服务进程，通过 C API 直接读写，适合本地存储。'),
  },
  'cross_cli_args': <String, GlossaryFix>{
    'clap': GlossaryFix(description: 'Rust 命令行参数解析库：用派生宏声明结构体，自动生成校验、帮助与补全。'),
  },
  'cross_db_access': <String, GlossaryFix>{
    'N+1': GlossaryFix(description: '先查一次主表再逐行查关联，导致 N+1 次查询；用 JOIN 或批量查询合并成常数次访问。'),
  },
  'cross_serialization': <String, GlossaryFix>{
    'YAML': GlossaryFix(description: '用缩进表达层级的配置格式，可读性好但缩进敏感，适合配置文件而非高频数据交换。'),
  },
  'cross_types_variables': <String, GlossaryFix>{
    '装箱与拆箱：包装类的开销': GlossaryFix(
      term: '装箱与拆箱',
      description: '值类型转成堆上对象再取回，每次都会分配或复制，是循环里常见的隐形开销。',
    ),
  },
  'csharp_async_streams': <String, GlossaryFix>{
    'CancellationToken': GlossaryFix(description: '协作式取消令牌：传进异步方法后，调用方取消时任务在检查点退出，避免白干活。'),
  },
  'csharp_gc_performance': <String, GlossaryFix>{
    'GC': GlossaryFix(description: '垃圾回收器：自动回收不可达对象，按代回收；频繁分配与大对象会推高回收开销。'),
  },
  'csharp_project_blazor_admin': <String, GlossaryFix>{
    'Blazor': GlossaryFix(description: '用 C# 与 Razor 组件构建 Web UI 的框架，可选服务端渲染或 WebAssembly 在浏览器里运行。'),
  },
  'csharp_project_inventory_cli': <String, GlossaryFix>{
    '.NET': GlossaryFix(description: '微软的跨平台运行时与开发平台：C# 编译成 IL，由 CLR 加载并 JIT 执行。'),
  },
  'csharp_records_patterns': <String, GlossaryFix>{
    'with': GlossaryFix(description: 'record 的复制表达式：基于已有实例生成新对象并只改指定属性，体现不可变数据写法。'),
  },
  'css_advanced': <String, GlossaryFix>{
    '变量': GlossaryFix(description: 'CSS 自定义属性（如 --brand），可继承与运行时覆盖，配合 var() 使用，是主题切换的基础。'),
    '容器查询': GlossaryFix(description: '按父容器尺寸而非视口决定样式，用 @container 写规则，让组件在不同容器里自适应。'),
  },
  'css_animation_render': <String, GlossaryFix>{
    '动画': GlossaryFix(description: '用 transition 或 @keyframes 描述属性随时间变化；只动 transform 与 opacity 才能留在合成层。'),
  },
  'database_bigdata': <String, GlossaryFix>{
    'Flink': GlossaryFix(description: '流批一体的分布式计算引擎，以事件时间、水位线和状态管理见长，常用于实时数据处理。'),
  },
  'database_distributed': <String, GlossaryFix>{
    'Saga': GlossaryFix(description: '把长事务拆成一组本地事务并各配补偿动作，失败时反向补偿，换取最终一致性。'),
  },
  'database_nosql': <String, GlossaryFix>{
    'MongoDB': GlossaryFix(description: '面向文档的 NoSQL 数据库：数据以 BSON 文档存储，字段灵活并支持聚合管道。'),
  },
  'db_backup_recovery': <String, GlossaryFix>{
    'PITR': GlossaryFix(description: '时间点恢复：用全量备份加 WAL/binlog 重放，把数据库恢复到任意时刻，常用于误删补救。'),
  },
  'db_graph': <String, GlossaryFix>{
    'Cypher': GlossaryFix(description: '图数据库的声明式查询语言，用 (节点)-[关系]->(节点) 的图形语法描述模式匹配。'),
  },
  'db_migration_governance': <String, GlossaryFix>{
    'Schema': GlossaryFix(description: '数据库模式：表、列、类型、约束与索引的集合；变更要走可回滚、低锁的迁移流程。'),
  },
  'db_postgresql_deep': <String, GlossaryFix>{
    '执行计划': GlossaryFix(description: '优化器给出的算子树与代价估算（EXPLAIN），用来判断扫描方式、连接顺序与索引是否生效。'),
    'MVCC': GlossaryFix(description: '多版本并发控制：写新版本、读旧快照，让读写互不阻塞，代价是版本清理与表膨胀。'),
  },
  'db_time_series': <String, GlossaryFix>{
    '降采样': GlossaryFix(description: '把高频采样点按时间窗口聚合成低频数据（如 1 秒变 1 分钟），用于长期存储与趋势查询。'),
  },
  'fundamentals_assembly': <String, GlossaryFix>{
    '从 C 到汇编：三个对照': GlossaryFix(
      term: '汇编',
      description: '与机器指令一一对应的助记符表示；把编译后的 C 代码反汇编逐条对照，能看清寄存器与栈的使用。',
    ),
  },
  'fundamentals_bus_io': <String, GlossaryFix>{
    '设备': GlossaryFix(description: '通过总线连接的外设；CPU 用内存映射或端口读写它的寄存器，并用中断或 DMA 交换数据。'),
  },
  'fundamentals_cache_coherence': <String, GlossaryFix>{
    '伪共享': GlossaryFix(description: '不同核心写同一缓存行里的不同变量，导致缓存行反复失效；用填充或对齐分开变量可消除。'),
    'NUMA': GlossaryFix(description: '非一致内存访问：每个 CPU 有本地内存，跨节点访问更慢，需按节点绑定线程与内存。'),
  },
  'fundamentals_computation_theory': <String, GlossaryFix>{
    'NP 完全': GlossaryFix(description: 'NP 中最难的一类问题：任何 NP 问题都能多项式归约到它，找到其中一个的多项式解法即可推出 P=NP。'),
  },
  'fundamentals_embedded_iot': <String, GlossaryFix>{
    '低功耗': GlossaryFix(description: '通过睡眠模式、降低主频与外设按需上电，把 MCU 平均电流压到微安级以延长电池寿命。'),
  },
  'fundamentals_encoding': <String, GlossaryFix>{
    '各语言里的三个易错点': GlossaryFix(remove: true),
  },
  'fundamentals_float_check': <String, GlossaryFix>{
    'CRC': GlossaryFix(description: '循环冗余校验：把数据当多项式做除法得到的校验值，用于发现传输或存储中的位错误。'),
  },
  'fundamentals_storage_stack': <String, GlossaryFix>{
    'ftl': GlossaryFix(description: '闪存转换层：把闪存先擦后写、按块擦除的特性抽象成块设备，并负责磨损均衡与垃圾回收。'),
  },
  'go_cloud_native_security': <String, GlossaryFix>{
    '限流': GlossaryFix(description: '按时间窗口限制请求速率（令牌桶或漏桶），保护后端不被突发流量打垮。'),
    'mTLS': GlossaryFix(description: '双向 TLS：客户端与服务端互相验证证书，常用于服务网格中确认双方身份。'),
  },
  'go_data_access': <String, GlossaryFix>{
    '连接池': GlossaryFix(description: '复用一组已建立的数据库连接，避免每次请求都握手；需要配好最大连接数与超时。'),
    '批量插入': GlossaryFix(description: '把多行数据合并成多值 INSERT 或批量语句，减少往返次数，是导入数据的基本优化。'),
  },
  'go_project_rest_api': <String, GlossaryFix>{
    'Go': GlossaryFix(description: '谷歌开源的静态编译语言：goroutine 与 channel 原生支持并发，编译产物是单个二进制文件。'),
  },
  'go_project_worker_pool': <String, GlossaryFix>{
    'goroutine': GlossaryFix(description: 'Go 的轻量协程，由运行时调度到系统线程；创建成本低，优选 channel 通信而非共享内存。'),
  },
  'go_testing': <String, GlossaryFix>{
    '模糊测试': GlossaryFix(description: '由工具自动生成随机输入并持续运行，直到发现让程序崩溃或断言失败的用例。'),
  },
  'java_gc_tuning': <String, GlossaryFix>{
    '停顿': GlossaryFix(description: 'GC 期间应用线程被挂起的时间；调优目标通常是缩短单次停顿并控制 P99 分布。'),
    'GC': GlossaryFix(description: 'JVM 的垃圾回收器：按分代回收不可达对象；G1、ZGC 等实现决定吞吐与停顿的取舍。'),
  },
  'java_modern_features': <String, GlossaryFix>{
    'Sealed': GlossaryFix(description: '密封类型：用 sealed 限定哪些类可以继承或实现，配合 switch 模式匹配可做穷尽性检查。'),
  },
  'java_project_inventory': <String, GlossaryFix>{
    'Spring Boot': GlossaryFix(description: '基于 Spring 的快速开发框架：约定优于配置、内嵌容器，起步依赖即可跑起 Web 服务。'),
  },
  'java_project_order_concurrency': <String, GlossaryFix>{
    'ExecutorService': GlossaryFix(description: '线程池接口：提交任务、批量执行并获取 Future；需按业务设置队列与拒绝策略。'),
  },
  'js_execution_context': <String, GlossaryFix>{
    'this': GlossaryFix(description: '函数调用时的接收者，取值由调用方式决定（方法调用、call/apply、箭头函数继承外层）。'),
  },
  'js_project_node_api': <String, GlossaryFix>{
    'Node.js': GlossaryFix(description: '基于 V8 的服务端 JavaScript 运行时：单线程事件循环加异步 IO，适合 IO 密集型服务。'),
  },
  'js_project_realtime_chat': <String, GlossaryFix>{
    'WebSocket': GlossaryFix(description: '在一条 TCP 连接上做全双工通信的协议：HTTP 握手之后双方可随时推送消息。'),
  },
  'kotlin_android': <String, GlossaryFix>{
    'Android': GlossaryFix(description: '谷歌的移动操作系统：应用以 Activity、Service 等组件运行在 ART 上，权限与生命周期由系统管理。'),
  },
  'kotlin_basics': <String, GlossaryFix>{
    '类型推断': GlossaryFix(description: '编译器根据初始值推断变量类型（val x = 1 即 Int），显式标注只在需要澄清时使用。'),
  },
  'kotlin_collections': <String, GlossaryFix>{
    '集合': GlossaryFix(description: 'Kotlin 区分只读与可变集合（List/MutableList），默认不可变，避免共享状态被意外修改。'),
  },
  'kotlin_coroutines': <String, GlossaryFix>{
    '取消': GlossaryFix(description: '协程的协作式取消：取消会传播到子协程，挂起点抛出取消异常，需在 finally 里释放资源。'),
  },
  'kotlin_functions': <String, GlossaryFix>{
    'inline': GlossaryFix(description: '内联函数：把函数体直接插到调用处，避免高阶函数的 lambda 分配，代价是字节码变大。'),
  },
  'kotlin_oop': <String, GlossaryFix>{
    '密封类': GlossaryFix(description: 'sealed class 限定子类只能定义在同模块内，配合 when 可做穷尽分支检查。'),
  },
  'kotlin_project': <String, GlossaryFix>{
    '缓存': GlossaryFix(description: '把昂贵结果暂存起来复用；要点是键设计、过期策略与并发下的失效处理。'),
  },
  'mobile_compose': <String, GlossaryFix>{
    '状态提升': GlossaryFix(description: '把状态从子组件提到共同父级，让数据单向流动，组件只负责渲染，便于复用与测试。'),
  },
  'mobile_harmony': <String, GlossaryFix>{
    '五个常用状态装饰器': GlossaryFix(remove: true),
    '一个页面的基本结构': GlossaryFix(remove: true),
  },
  'mobile_miniprogram': <String, GlossaryFix>{
    '一个页面的完整写法': GlossaryFix(remove: true),
    'setData 的三条纪律': GlossaryFix(
      term: 'setData',
      description: '小程序把数据从逻辑层同步到视图层的接口；应合并调用、只传变化字段，避免频繁跨层通信。',
    ),
  },
  'mobile_react_native': <String, GlossaryFix>{
    '平台差异与原生能力': GlossaryFix(
      term: '原生模块',
      description: '用平台原生代码封装能力并暴露给 JavaScript 调用，用来抹平权限、组件与 API 差异。',
    ),
    '四个最容易出 bug 的 Hooks 用法': GlossaryFix(
      term: 'Hooks',
      description: 'React 函数组件里管理状态与副作用的 API（useState、useEffect 等），依赖数组写错是常见 bug 来源。',
    ),
    '用 Hooks 写一个页面': GlossaryFix(remove: true),
  },
  'mobile_swift': <String, GlossaryFix>{
    '可选类型：Swift 最核心的安全设计': GlossaryFix(
      term: '可选类型',
      description: 'Optional 表示值可能为 nil，必须显式解包（if let、guard let）才能使用，从类型层面消除空指针。',
    ),
  },
  'network_attacks': <String, GlossaryFix>{
    'MITM': GlossaryFix(description: '中间人攻击：攻击者插在通信双方之间转发并可能篡改流量，靠证书校验与 HSTS 防御。'),
  },
  'network_auth': <String, GlossaryFix>{
    'OAuth2': GlossaryFix(description: '授权框架：第三方应用用授权码换访问令牌，在用户不交出密码的前提下访问受保护资源。'),
  },
  'network_nat_vpn': <String, GlossaryFix>{
    'IPsec': GlossaryFix(description: '网络层安全协议族：用 AH/ESP 提供认证与加密，常用于站点到站点的 VPN 隧道。'),
  },
  'network_p2p': <String, GlossaryFix>{
    '中继': GlossaryFix(description: '双方无法直连时由第三方节点转发流量；代价是带宽与延迟增加，必要时端到端加密。'),
  },
  'network_performance': <String, GlossaryFix>{
    'TCP': GlossaryFix(description: '面向连接的可靠传输协议：握手建连、序号与重传保序，滑动窗口与拥塞控制决定吞吐。'),
  },
  'network_smtp': <String, GlossaryFix>{
    'SPF': GlossaryFix(description: '发信方在 DNS 里声明哪些 IP 有权代表该域名发信，收信方据此识别伪造发件人。'),
  },
  'network_web_security': <String, GlossaryFix>{
    'CSRF': GlossaryFix(description: '跨站请求伪造：借用户已登录的凭据发起非预期请求；用 SameSite Cookie 与 CSRF Token 防御。'),
  },
  'os_cgroups_namespaces': <String, GlossaryFix>{
    'cgroups': GlossaryFix(description: '内核的资源限制与计量机制：按组限制 CPU、内存与 IO，是容器资源隔离的基础。'),
  },
  'os_kernel_arch': <String, GlossaryFix>{
    '微内核': GlossaryFix(description: '只把最核心功能放进内核，驱动与文件系统作为用户态服务运行，换来更好的隔离与可靠性。'),
  },
  'os_linux_troubleshooting': <String, GlossaryFix>{
    'perf': GlossaryFix(description: 'Linux 性能分析工具：采样 CPU、追踪调度与缓存事件，用 perf top/report 定位热点函数。'),
  },
  'programming_cpp_control_functions': <String, GlossaryFix>{
    '三种循环怎么选': GlossaryFix(remove: true),
    '声明与定义：编译器和链接器各管一段': GlossaryFix(
      term: '声明与定义',
      description: '声明告诉编译器名字与类型，定义真正分配存储；分开写才能多文件编译，最后由链接器合并。',
    ),
  },
  'programming_cpp_templates': <String, GlossaryFix>{
    'Concepts': GlossaryFix(description: 'C++20 的编译期约束：用命名要求限定模板参数，让报错指向真正不满足的条件。'),
  },
  'programming_csharp_basics': <String, GlossaryFix>{
    '两个文件撑起一个项目': GlossaryFix(
      term: '.csproj',
      description: 'C# 项目文件：声明目标框架、依赖与编译项，dotnet build 依据它生成程序集。',
    ),
  },
  'programming_go_generics_stdlib': <String, GlossaryFix>{
    '泛型三件套': GlossaryFix(remove: true),
  },
  'programming_go_interfaces_errors': <String, GlossaryFix>{
    '接口的两条最佳实践': GlossaryFix(remove: true),
  },
  'programming_java_collections': <String, GlossaryFix>{
    'Map': GlossaryFix(description: '键值映射接口：HashMap 不保序、LinkedHashMap 保插入序、TreeMap 按键排序，按场景选择。'),
  },
  'programming_js_dom_events': <String, GlossaryFix>{
    '事件委托': GlossaryFix(description: '把监听器挂在父元素上，靠事件冒泡统一处理子元素事件，避免为每个子节点绑定监听。'),
  },
  'programming_js_modules_tooling': <String, GlossaryFix>{
    'ESM 的四种导入导出': GlossaryFix(
      term: 'ESM',
      description: 'ECMAScript 模块：用 import/export 静态声明依赖，支持默认导出与命名导出。',
    ),
  },
  'programming_rust_async': <String, GlossaryFix>{
    '异步': GlossaryFix(description: 'async/await 把等待交给执行器：任务在 await 处让出线程，适合高并发 IO，但不能阻塞线程。'),
  },
  'programming_rust_errors_iterators_async': <String, GlossaryFix>{
    'anyhow': GlossaryFix(description: '面向应用的错误库：用 anyhow::Result 加错误上下文快速传播错误，适合二进制程序而非库。'),
    'thiserror': GlossaryFix(description: '用派生宏为枚举生成 Error 实现，适合给库定义结构化的错误类型。'),
  },
  'programming_shell_bash': <String, GlossaryFix>{
    '脚本': GlossaryFix(description: '把多条命令写进文件按顺序执行，可带参数、判断与循环；首行 shebang 决定用哪个解释器。'),
  },
  'programming_shell_flow': <String, GlossaryFix>{
    '循环': GlossaryFix(description: 'for/while 按列表或条件重复执行命令块，配合 break 与 continue 控制流程。'),
  },
  'programming_shell_robust': <String, GlossaryFix>{
    'set -euo pipefail': GlossaryFix(description: '严格模式：命令失败、用到未定义变量、管道任一环失败都立即退出，避免错误被吞掉继续执行。'),
  },
  'programming_ts_build_test': <String, GlossaryFix>{
    'Vite': GlossaryFix(description: '现代前端构建工具：开发时用原生 ESM 按需编译并热更新，打包时用 Rollup 产出静态资源。'),
  },
  'programming_ts_project': <String, GlossaryFix>{
    '路径别名要同时配两处': GlossaryFix(
      term: '路径别名',
      description: '用 @/ 之类短路径代替相对路径；需要同时配置 TypeScript 的 paths 与打包器或运行时的解析。',
    ),
  },
  'project_rag_agent_service': <String, GlossaryFix>{
    'RAG': GlossaryFix(description: '检索增强生成：先把文档检索成上下文再交给模型作答，能引用外部知识并降低幻觉。'),
  },
  'project_testing_quality': <String, GlossaryFix>{
    'CI': GlossaryFix(description: '持续集成：每次提交自动跑构建与测试，把问题挡在合并之前。'),
  },
  'python_context_iterators': <String, GlossaryFix>{
    'with': GlossaryFix(description: '上下文管理器：__enter__ 与 __exit__ 保证退出时释放资源，中途抛异常也会执行清理。'),
  },
  'python_decorators_generators': <String, GlossaryFix>{
    'yield': GlossaryFix(description: '生成器关键字：函数执行到 yield 暂停并返回值，下次继续，适合流式处理大数据。'),
  },
  'python_packaging_performance': <String, GlossaryFix>{
    'pyproject': GlossaryFix(description: 'Python 项目的标准配置文件：声明构建后端、依赖与工具配置，取代 setup.py 的中心地位。'),
  },
  'python_project_api': <String, GlossaryFix>{
    'FastAPI': GlossaryFix(description: '基于类型注解的 Python Web 框架：自动校验请求并生成 OpenAPI 文档，原生支持异步。'),
  },
  'python_project_etl': <String, GlossaryFix>{
    'ETL': GlossaryFix(description: '抽取-转换-加载：把源数据取出、清洗转换后写入目标存储，是数据管道的基本形态。'),
  },
  'rust_macros_wasm': <String, GlossaryFix>{
    'WASM': GlossaryFix(description: 'WebAssembly：可移植的二进制指令格式，能在浏览器与沙箱里高速执行，常作为 C/C++/Rust 的编译目标。'),
  },
  'rust_project_axum_api': <String, GlossaryFix>{
    'Rust': GlossaryFix(description: '静态编译的系统级语言：所有权与借用检查在编译期消除数据竞争，无 GC，适合高性能服务。'),
  },
  'rust_project_downloader': <String, GlossaryFix>{
    'Tokio': GlossaryFix(description: 'Rust 的异步运行时：提供任务调度、定时器与异步 IO，配合 async/await 写高并发程序。'),
  },
  'rust_smart_pointers': <String, GlossaryFix>{
    'Box': GlossaryFix(description: '把值分配到堆上的智能指针，用于递归类型、大对象或需要稳定地址的场景。'),
  },
  'rust_traits_generics': <String, GlossaryFix>{
    'trait': GlossaryFix(description: 'Rust 的行为抽象：定义一组方法签名，类型实现后即可被泛型约束或作为 dyn 动态调用。'),
  },
  'se_postmortem': <String, GlossaryFix>{
    'SLO': GlossaryFix(description: '服务等级目标：对可用性或延迟设定的可量化目标（如 99.9% 成功），是复盘与告警的基准。'),
  },
  'se_requirements_uml': <String, GlossaryFix>{
    'UML': GlossaryFix(description: '统一建模语言：用类图、时序图等表达设计与交互，重点是沟通而不是图画得多漂亮。'),
  },
  'se_sdl': <String, GlossaryFix>{
    'STRIDE': GlossaryFix(description: '威胁建模清单：从仿冒、篡改、抵赖、信息泄露、拒绝服务、提权六类威胁逐项检查设计。'),
  },
  'se_tech_writing': <String, GlossaryFix>{
    'README': GlossaryFix(description: '项目入口文档：说明这是什么、怎么装、怎么跑、怎么配，决定别人能否快速上手。'),
  },
  'security_auth_session': <String, GlossaryFix>{
    'JWT': GlossaryFix(description: 'JSON Web Token：把声明签名后交给客户端保存；服务端要校验签名、过期时间与算法，且无法直接撤销。'),
  },
  'security_container_k8s': <String, GlossaryFix>{
    '运行时': GlossaryFix(description: '容器运行时：负责拉镜像、创建命名空间与 cgroups 并启动进程，逃逸漏洞多出在这一层。'),
    'RBAC': GlossaryFix(description: '基于角色的访问控制：把权限绑到角色再授予主体，Kubernetes 里按最小权限收敛 ServiceAccount。'),
  },
  'security_owasp_top10': <String, GlossaryFix>{
    '注入': GlossaryFix(description: '把用户输入当成代码或命令执行（SQL、命令、模板注入）；用参数化查询与白名单校验防御。'),
  },
  'shell_automation_advanced': <String, GlossaryFix>{
    '日志': GlossaryFix(description: '脚本执行过程的结构化输出：包含时间、级别与上下文，便于失败后定位与告警。'),
  },
  'shell_portability': <String, GlossaryFix>{
    'POSIX': GlossaryFix(description: '可移植操作系统接口标准：按它写 shell 与系统调用，才能在 bash、dash 等不同实现上通用。'),
  },
  'shell_project_log_analysis': <String, GlossaryFix>{
    'awk': GlossaryFix(description: '按列处理文本的小语言：pattern { action } 逐行匹配，常用于日志统计与字段提取。'),
  },
  'shell_security_hardening': <String, GlossaryFix>{
    '临时文件': GlossaryFix(description: '脚本用的中间文件：要用 mktemp 生成、设好权限并及时清理，否则有被抢占或泄露的风险。'),
  },
  'swift_oop': <String, GlossaryFix>{
    'ARC': GlossaryFix(description: '自动引用计数：编译期插入引用计数管理对象生命周期，循环引用需用 weak 或 unowned 打破。'),
  },
  'swift_project': <String, GlossaryFix>{
    '网络': GlossaryFix(description: '客户端与服务器交换数据的过程：发起请求、处理状态码与超时、解析响应并缓存结果。'),
  },
  'swift_testing': <String, GlossaryFix>{
    'XCTest': GlossaryFix(description: 'Xcode 自带的测试框架：用 XCTestCase 写断言与异步测试，配合依赖注入隔离外部依赖。'),
  },
  'ts_monorepo': <String, GlossaryFix>{
    '内部依赖怎么写': GlossaryFix(
      term: '工作区',
      description: 'monorepo 里用 workspaces 声明各个包，包之间用包名互相引用，由统一工具链解析与构建。',
    ),
  },
  'ts_project_cli': <String, GlossaryFix>{
    'Zod': GlossaryFix(description: 'TypeScript 运行时校验库：用 schema 描述数据形状，解析时校验并推断出静态类型。'),
  },
  'ts_project_websocket_dashboard': <String, GlossaryFix>{
    'TypeScript': GlossaryFix(description: 'JavaScript 的超集：静态类型只在开发期检查，编译时被擦除，运行的是普通 JavaScript。'),
  },
  'ts_testing': <String, GlossaryFix>{
    'Mock：只在边界用': GlossaryFix(
      term: 'Mock',
      description: '测试替身：模拟外部依赖或慢操作，只在边界使用，避免把内部实现也一起 mock。',
    ),
  },
  'ts_type_challenges': <String, GlossaryFix>{
    '五个基础积木': GlossaryFix(remove: true),
  },
  'ts_type_level': <String, GlossaryFix>{
    'infer': GlossaryFix(description: '条件类型里的推断关键字：从待判断类型中提取局部类型变量，用来实现 ReturnType 一类工具类型。'),
  },
  'visual_concurrency_schedule': <String, GlossaryFix>{
    'Goroutine': GlossaryFix(description: 'Go 的协程：由运行时调度到系统线程，切换代价远小于线程，M:N 模型是并发的核心。'),
  },
  'visual_https_cert': <String, GlossaryFix>{
    'TLS': GlossaryFix(description: '传输层安全协议：握手协商密钥并用证书验证身份，之后的数据对称加密传输。'),
  },
  'visual_jvm_memory': <String, GlossaryFix>{
    'OOM': GlossaryFix(description: '内存溢出：堆或元空间耗尽时抛 OutOfMemoryError，需要区分泄漏、堆太小还是元数据过多。'),
  },
  'visual_kafka_partition': <String, GlossaryFix>{
    'ISR': GlossaryFix(description: '同步副本集合：与 leader 保持同步的副本列表；写入按确认策略等待 ISR，掉队的副本会被踢出。'),
  },
  'visual_oauth_flow': <String, GlossaryFix>{
    'OAuth': GlossaryFix(description: '授权框架：资源所有者授权后客户端用令牌访问资源服务器，全程不接触用户密码。'),
    'PKCE': GlossaryFix(description: '授权码流程的扩展：客户端生成并校验 code_verifier，防止授权码被截获后换令牌。'),
  },
  'visual_vector_index': <String, GlossaryFix>{
    'HNSW': GlossaryFix(description: '分层可导航小世界图：近似最近邻索引，上层稀疏用于快速跳转，下层密集用于精确定位。'),
  },
};
