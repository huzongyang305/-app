"""P2 配图补全：为 29 门只有 1 张配图的课程补第二张示意图。

用法：
    python tool/generate_p2_extra_diagrams.py

输出：
    assets/content/images/p2_*.webp

复用 generate_diagrams 的画布、配色与圆角矩形工具，保证与既有配图风格一致。
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import generate_diagrams as base  # noqa: E402


def wrap_cn(text: str, width: int) -> list[str]:
    """按字符宽度折行，保留显式换行。"""
    lines: list[str] = []
    for raw in text.split("\n"):
        raw = raw.strip()
        if not raw:
            lines.append("")
            continue
        lines.extend(raw[i : i + width] for i in range(0, len(raw), width))
    return lines


def draw_header(draw, title: str, subtitle: str) -> None:
    size = 32 if len(title) <= 24 else 28
    draw.text((40, 24), title, font=base.font(size, bold=True), fill=base.INK)
    draw.text((40, 74), subtitle, font=base.font(18), fill=base.MUTED)
    draw.line([(40, 108), (1160, 108)], fill=(229, 231, 235), width=2)


def bullet_block(draw, panel, items: list[str], color) -> None:
    x0, y0, x1, _ = panel
    for index, item in enumerate(items):
        y = y0 + index * 74
        draw.ellipse((x0 + 20, y + 12, x0 + 34, y + 26), fill=color)
        lines = wrap_cn(item, 27)[:2]
        for line_index, line in enumerate(lines):
            draw.text(
                (x0 + 46, y + 6 + line_index * 28),
                line,
                font=base.font(19),
                fill=base.INK,
            )


def compare_diagram(
    name: str,
    title: str,
    subtitle: str,
    left_title: str,
    left: list[str],
    right_title: str,
    right: list[str],
    footers: list[str],
) -> None:
    image, draw = base.new_canvas(1200, 720)
    draw_header(draw, title, subtitle)
    panels = [(40, 168, 580, 540), (620, 168, 1160, 540)]
    colors = [base.PRIMARY, base.ACCENT]
    for panel, heading, items, color in zip(
        panels, [left_title, right_title], [left, right], colors
    ):
        x0, y0, x1, _ = panel
        draw.rounded_rectangle(
            (x0, 128, x1, 168), radius=12, fill=color, outline=color, width=2
        )
        text_width, _ = base.text_size(draw, heading, base.font(21, bold=True))
        draw.text(
            ((x0 + x1) / 2 - text_width / 2, 136),
            heading,
            font=base.font(21, bold=True),
            fill=(255, 255, 255),
        )
        draw.rounded_rectangle(panel, radius=14, outline=(229, 231, 235), width=2)
        bullet_block(draw, (x0, y0 + 16, x1, 540), items, color)
    base.caption(draw, footers[0], 576, 1200)
    if len(footers) > 1:
        base.caption(draw, footers[1], 618, 1200)
    base.caption(draw, "先看结论，再回到正文对应小节验证。", 668, 1200)
    base.save(image, name)


def flow_diagram(
    name: str,
    title: str,
    subtitle: str,
    stages: list[str],
    checks: list[str],
    footers: list[str],
) -> None:
    image, draw = base.new_canvas(1200, 720)
    draw_header(draw, title, subtitle)
    count = len(stages)
    gap = 26
    width = int((1120 - gap * (count - 1)) / count)
    for index, stage in enumerate(stages):
        x = 40 + index * (width + gap)
        fill = [base.PRIMARY_SOFT, base.ACCENT_SOFT, base.GREEN_SOFT, base.WARN_SOFT][
            index % 4
        ]
        outline = [base.PRIMARY, base.ACCENT, base.GREEN, base.WARN][index % 4]
        base.box(
            draw,
            (x, 150, x + width, 262),
            f"{index + 1}\n{stage}",
            fill=fill,
            outline=outline,
            size=20,
            bold=True,
        )
        if index < count - 1:
            base.arrow(draw, (x + width, 206), (x + width + gap, 206), color=base.LINE)
    draw.text((40, 300), "验证关卡", font=base.font(24, bold=True), fill=base.INK)
    for index, check in enumerate(checks[:3]):
        x = 40 + index * 380
        base.box(
            draw,
            (x, 344, x + 350, 470),
            check,
            fill=base.SURFACE,
            outline=base.LINE,
            size=19,
        )
    base.caption(draw, footers[0], 520, 1200)
    if len(footers) > 1:
        base.caption(draw, footers[1], 562, 1200)
    base.caption(draw, "每一步都要留下可复现的命令、指标或记录。", 640, 1200)
    base.save(image, name)


COMPARE: dict[str, dict] = {
    "p2_memory_layout_compare": {
        "title": "栈、堆与静态区：变量到底住在哪",
        "subtitle": "判断依据是语言语义与变量保存的内容，而不是变量类型名",
        "left_title": "值语义",
        "left": [
            "变量本身保存数据内容",
            "赋值或传参等于复制一份",
            "生命周期随作用域结束而回收",
            "典型：C++ 值对象、struct、数组",
        ],
        "right_title": "引用语义",
        "right": [
            "变量保存指向对象的地址",
            "赋值或传参复制的是引用",
            "对象由 GC 或所有者负责释放",
            "典型：Python 对象、Java 对象、Go 指针",
        ],
        "footers": [
            "栈：分配快、空间小、随作用域回收；堆：空间大、分配慢、需要回收策略。",
            "同一个变量名在不同语言里可能落在不同区域，先确认语义再看实现。",
        ],
    },
    "p2_call_stack_compare": {
        "title": "调用栈：一次函数调用发生了什么",
        "subtitle": "栈帧按后进先出推进，崩溃时的调用链就是栈帧序列",
        "left_title": "入栈",
        "left": [
            "压入参数与返回地址",
            "保存调用者的寄存器现场",
            "为局部变量分配栈空间",
            "栈指针下移，进入被调函数",
        ],
        "right_title": "出栈",
        "right": [
            "返回值写入约定位置",
            "恢复调用者寄存器现场",
            "栈指针回到调用前位置",
            "控制权交还调用者继续执行",
        ],
        "footers": [
            "递归过深会耗尽栈空间，表现为栈溢出而不是堆内存不足。",
            "栈帧大小在编译期基本确定，栈上不适合存放超大对象。",
        ],
    },
    "p2_event_loop_compare": {
        "title": "事件循环：宏任务、微任务与渲染",
        "subtitle": "顺序判断法：同步代码 → 微任务 → 渲染 → 下一个宏任务",
        "left_title": "一轮循环",
        "left": [
            "取出一个宏任务执行",
            "清空当前全部微任务队列",
            "按需执行渲染与布局",
            "进入下一轮循环",
        ],
        "right_title": "常见误区",
        "right": [
            "在微任务里递归会饿死渲染",
            "定时器延迟只是最早触发时间",
            "同步长任务会阻塞全部交互",
            "await 之后的代码属于微任务",
        ],
        "footers": [
            "微任务优先于渲染，因此长微任务链会直接掉帧。",
            "把长任务切片或交给 Worker，是恢复响应性的常用手段。",
        ],
    },
    "p2_concurrency_schedule_compare": {
        "title": "并发调度：谁来分配 CPU 时间",
        "subtitle": "调度的目标是平衡吞吐、延迟与公平，而不是单纯提高并发度",
        "left_title": "调度的目标",
        "left": [
            "吞吐量：单位时间完成多少任务",
            "延迟：单个任务等多久",
            "公平性：避免任务被长期饿死",
            "优先级：关键任务先得到资源",
        ],
        "right_title": "切换的代价",
        "right": [
            "上下文切换消耗 CPU 时间",
            "缓存与 TLB 局部性被破坏",
            "锁竞争让线程互相等待",
            "优先级反转可能拖慢高优任务",
        ],
        "footers": [
            "并发度提高后吞吐反而下降，说明已经越过拐点。",
            "先测量再调参：线程数、队列长度和批次大小都要用数据决定。",
        ],
    },
    "p2_http_timeline_compare": {
        "title": "一次请求的耗时都花在哪里",
        "subtitle": "把总耗时拆成阶段，才能判断优化网络还是优化服务端",
        "left_title": "客户端侧",
        "left": [
            "DNS 解析域名",
            "建立 TCP 与 TLS 连接",
            "发送请求并等待首字节",
            "接收与解析响应内容",
        ],
        "right_title": "服务端侧",
        "right": [
            "请求排队与调度",
            "业务逻辑处理",
            "访问数据库或缓存",
            "序列化并写回连接",
        ],
        "footers": [
            "TTFB 高通常是服务端问题，传输时间长才是带宽或链路问题。",
            "复用连接与启用压缩能同时改善多个阶段。",
        ],
    },
    "p2_git_states_compare": {
        "title": "Git 三区与提交对象",
        "subtitle": "改动在不同区之间流转，回退前要先确认它位于哪个区",
        "left_title": "工作区 → 暂存区",
        "left": [
            "git add 把改动写入索引",
            "索引保存的是内容快照引用",
            "可以只暂存文件的一部分改动",
            "git restore 撤销工作区改动",
        ],
        "right_title": "暂存区 → 仓库",
        "right": [
            "git commit 生成提交对象",
            "提交指向一棵树与父提交",
            "分支只是指向提交的指针",
            "git reset 移动指针并可选更新索引",
        ],
        "footers": [
            "已提交的内容几乎都能找回，未提交的改动才最容易丢失。",
            "git status 会分别列出已暂存与未暂存的改动，回退前先读一遍。",
        ],
    },
    "p2_btree_index_compare": {
        "title": "B+ 树索引：为什么查询是 O(log n)",
        "subtitle": "树高决定等值查询代价，叶子链表决定范围查询效率",
        "left_title": "结构特征",
        "left": [
            "非叶子节点只保存键",
            "数据全部存放在叶子层",
            "叶子之间用链表相连",
            "单页容纳更多键，树高更低",
        ],
        "right_title": "收益与代价",
        "right": [
            "等值查询走一次树高",
            "范围查询可顺序扫描叶子",
            "写入要维护页分裂与合并",
            "占用额外磁盘与内存",
        ],
        "footers": [
            "联合索引遵循最左前缀，列顺序决定能否命中。",
            "索引让读更快，但每个写入都要为它买单。",
        ],
    },
    "p2_tcp_handshake_compare": {
        "title": "握手、挥手与状态迁移",
        "subtitle": "建连三次、断连四次，TIME_WAIT 属于正常状态",
        "left_title": "建立连接",
        "left": [
            "客户端发送 SYN",
            "服务端回复 SYN + ACK",
            "客户端再发 ACK",
            "双方进入 ESTABLISHED",
        ],
        "right_title": "断开连接",
        "right": [
            "主动方发送 FIN",
            "对端先回 ACK",
            "对端数据发完再发 FIN",
            "主动方第四次 ACK 后进入 TIME_WAIT",
        ],
        "footers": [
            "TIME_WAIT 保证旧报文消散，不是连接泄漏。",
            "大量 CLOSE_WAIT 才说明应用没有及时关闭连接。",
        ],
    },
    "p2_jvm_memory_compare": {
        "title": "JVM 运行时内存区域",
        "subtitle": "排查内存问题要先区分线程共享与线程私有、堆内与堆外",
        "left_title": "线程共享",
        "left": [
            "堆：对象实例与数组",
            "方法区 / 元空间：类元数据",
            "运行时常量池",
            "直接内存：NIO 缓冲区",
        ],
        "right_title": "线程私有",
        "right": [
            "程序计数器",
            "虚拟机栈：栈帧与局部变量",
            "本地方法栈",
            "线程退出后随之回收",
        ],
        "footers": [
            "堆溢出看对象与引用链，元空间溢出看类加载。",
            "直接内存不受堆上限约束，要单独监控。",
        ],
    },
    "p2_https_cert_compare": {
        "title": "HTTPS 证书链与握手校验",
        "subtitle": "客户端校验的是整条证书链，而不只是服务器那一张证书",
        "left_title": "握手流程",
        "left": [
            "ClientHello 列出支持的套件",
            "ServerHello 返回证书链",
            "校验证书、域名与有效期",
            "协商密钥并切换到加密通信",
        ],
        "right_title": "校验要点",
        "right": [
            "根证书是否在受信列表",
            "中间证书是否完整下发",
            "主机名与 SAN 是否匹配",
            "证书是否被吊销或过期",
        ],
        "footers": [
            "缺少中间证书是线上最常见的握手失败原因。",
            "抓包只能看到握手与证书，正文内容仍然是密文。",
        ],
    },
    "p2_k8s_scheduling_compare": {
        "title": "Pod 从创建到就绪",
        "subtitle": "调度决定落在哪个节点，探针决定是否接流量与是否重启",
        "left_title": "调度过程",
        "left": [
            "过滤资源与约束不满足的节点",
            "按亲和性与负载为节点打分",
            "绑定 Pod 到目标节点",
            "kubelet 拉起容器并上报状态",
        ],
        "right_title": "三类探针",
        "right": [
            "startupProbe 保护启动慢的应用",
            "readinessProbe 决定是否接入流量",
            "livenessProbe 决定是否重启容器",
            "阈值与超时要留足业务余量",
        ],
        "footers": [
            "探针配置过紧会把正常实例踢出或反复重启。",
            "健康检查要覆盖关键依赖，只查进程存活会漏掉真实故障。",
        ],
    },
    "p2_rag_pipeline_compare": {
        "title": "RAG 的离线索引与在线检索",
        "subtitle": "召回质量决定回答上限，提示词只能决定发挥程度",
        "left_title": "离线索引",
        "left": [
            "文档解析与清洗",
            "按语义切块并保留元数据",
            "生成向量并写入向量库",
            "维护版本与增量更新",
        ],
        "right_title": "在线检索",
        "right": [
            "查询改写与扩展",
            "向量召回 Top-K",
            "重排与过滤低质片段",
            "拼接上下文交给模型生成",
        ],
        "footers": [
            "切块过大稀释语义，过小则丢失上下文。",
            "上线前要用评测集量化召回率与答案正确率。",
        ],
    },
    "p2_db_isolation_compare": {
        "title": "事务隔离级别与并发异常",
        "subtitle": "隔离越强并发越低，取舍依据是业务能容忍哪种异常",
        "left_title": "并发异常",
        "left": [
            "脏读：读到未提交的数据",
            "不可重复读：两次读到不同结果",
            "幻读：范围查询多出或少掉行",
            "丢失更新：后写覆盖先写",
        ],
        "right_title": "隔离级别",
        "right": [
            "读未提交：几乎不隔离",
            "读已提交：只读已提交数据",
            "可重复读：同一事务内结果稳定",
            "串行化：最强隔离、并发最低",
        ],
        "footers": [
            "多数数据库默认不是串行化，热点写入要显式加锁或用乐观锁。",
            "隔离级别与锁的行为要在目标数据库上实测确认。",
        ],
    },
    "p2_mq_delivery_compare": {
        "title": "消息投递语义与消费端要求",
        "subtitle": "工程上多数系统选择至少一次投递加幂等消费",
        "left_title": "三种投递语义",
        "left": [
            "至多一次：可能丢消息",
            "至少一次：可能重复投递",
            "恰好一次：成本最高、约束最多",
            "语义由生产、存储与消费共同决定",
        ],
        "right_title": "消费端要求",
        "right": [
            "用业务幂等键去重",
            "处理成功后再手动确认",
            "失败进入重试与死信队列",
            "按分区保证局部顺序",
        ],
        "footers": [
            "重复不可避免时，幂等就是把问题变成可接受的关键。",
            "顺序只在单个分区或队列内成立，跨分区要自行排序。",
        ],
    },
    "p2_llm_inference_compare": {
        "title": "大模型推理的两个阶段",
        "subtitle": "首 token 慢看 Prefill，生成慢看 Decode 与批处理策略",
        "left_title": "Prefill 预填充",
        "left": [
            "整段输入并行计算",
            "计算密集、访存密集",
            "决定首 token 延迟",
            "输入越长耗时越高",
        ],
        "right_title": "Decode 解码",
        "right": [
            "逐个 token 自回归生成",
            "每步只计算一个新 token",
            "受显存带宽限制",
            "批处理能提高吞吐但增加延迟",
        ],
        "footers": [
            "KV 缓存决定显存占用，长上下文会显著抬高成本。",
            "报告指标要区分首 token 延迟与每 token 生成速度。",
        ],
    },
    "p2_oauth_flow_compare": {
        "title": "OAuth 2.0 授权码流程与 PKCE",
        "subtitle": "公共客户端必须使用 PKCE，令牌只能交给可信的持有方",
        "left_title": "授权码流程",
        "left": [
            "客户端跳转授权端点",
            "用户同意后回调返回 code",
            "后端用 code 换取 token",
            "校验 state 防止 CSRF",
        ],
        "right_title": "PKCE 与安全",
        "right": [
            "客户端生成 code_verifier",
            "授权请求携带 code_challenge",
            "换取令牌时校验 verifier",
            "公共客户端必须启用 PKCE",
        ],
        "footers": [
            "授权码只能使用一次，泄露后也应有 PKCE 兜底。",
            "访问令牌不要放在前端可见或可被日志记录的位置。",
        ],
    },
    "p2_cdn_cache_compare": {
        "title": "CDN 缓存与回源",
        "subtitle": "缓存键决定命中率，回源策略决定源站压力",
        "left_title": "请求路径",
        "left": [
            "用户就近接入边缘节点",
            "命中缓存则直接返回",
            "未命中时回源站取内容",
            "按缓存策略写入边缘",
        ],
        "right_title": "缓存策略",
        "right": [
            "Cache-Control 决定新鲜度",
            "ETag 支持协商缓存",
            "查询参数会影响缓存键",
            "动态内容设短 TTL 或不缓存",
        ],
        "footers": [
            "缓存键设计过细会降低命中率，过粗则可能串数据。",
            "发布新版本要用内容哈希或刷新策略避免旧缓存。",
        ],
    },
    "p2_rate_limit_circuit_compare": {
        "title": "限流与熔断的状态机",
        "subtitle": "限流保护自己，熔断保护调用方，两者常配合使用",
        "left_title": "常用限流算法",
        "left": [
            "令牌桶允许一定突发",
            "漏桶把流量平滑输出",
            "固定窗口存在临界突刺",
            "按用户、接口或 IP 分维度",
        ],
        "right_title": "熔断三态",
        "right": [
            "关闭：请求正常放行",
            "打开：快速失败不再调用",
            "半开：少量请求试探恢复",
            "指标恢复后重新闭合",
        ],
        "footers": [
            "限流阈值要按容量压测得出，不能凭感觉设置。",
            "被限流与被熔断要返回可区分的错误码，方便客户端退避。",
        ],
    },
    "p2_kafka_partition_compare": {
        "title": "Kafka 分区、副本与消费组",
        "subtitle": "分区决定并行与顺序，副本决定可靠性，两者职责不同",
        "left_title": "分区",
        "left": [
            "分区是并行与顺序的基本单位",
            "相同 key 落到同一分区",
            "分区数决定消费并行度",
            "分区只能增加不能减少",
        ],
        "right_title": "副本与确认",
        "right": [
            "leader 负责读写",
            "follower 持续同步数据",
            "ISR 记录同步中的副本",
            "acks 决定写入可靠性",
        ],
        "footers": [
            "顺序只在单个分区内保证，跨分区需要业务自行排序。",
            "提高 acks 会增强可靠性，但也会增加写入延迟。",
        ],
    },
    "p2_consistent_hashing_compare": {
        "title": "一致性哈希环",
        "subtitle": "它减少扩容时的数据迁移量，但不保证负载自动均衡",
        "left_title": "基本机制",
        "left": [
            "节点与键都映射到哈希环",
            "键顺时针找到第一个节点",
            "增删节点只影响相邻区间",
            "虚拟节点用于平衡分布",
        ],
        "right_title": "常见问题",
        "right": [
            "节点少时数据倾斜明显",
            "虚拟节点数量需要调优",
            "扩容迁移要限速避免打满",
            "热点键仍需单独拆分",
        ],
        "footers": [
            "没有虚拟节点时，少量节点很容易出现严重倾斜。",
            "迁移期间要同时读写新旧位置，完成后才能清理。",
        ],
    },
    "p2_vector_index_compare": {
        "title": "向量检索与 HNSW 索引",
        "subtitle": "用少量召回率换取数量级的速度提升，参数要用评测集调",
        "left_title": "精确检索",
        "left": [
            "与全部向量逐一计算距离",
            "结果最准确",
            "复杂度随规模线性增长",
            "适合小规模或离线场景",
        ],
        "right_title": "近似检索",
        "right": [
            "分层图结构逐层收敛",
            "先粗搜再精搜候选",
            "ef 参数控制搜索范围",
            "在召回率与延迟之间取舍",
        ],
        "footers": [
            "先测召回率再调性能参数，否则只是更快地给出错误结果。",
            "过滤条件多时，要在召回后过滤与预过滤之间做验证。",
        ],
    },
    "p2_project_network_flow": {
        "title": "抓包排障流程",
        "subtitle": "先选对观测点，再复现问题，最后把延迟拆到具体协议段",
        "stages": ["选定抓包点", "复现并过滤", "分析协议时序", "定位并验证"],
        "checks": [
            "网卡与端口映射\n容器要抓 any 或 docker0",
            "解密条件\n测试环境导出 SSLKEYLOGFILE",
            "延迟分解\n握手、首字节、重传各占多少",
        ],
        "footers": [
            "抓不到包先查抓包点，只看到密文先查 TLS 密钥日志。",
        ],
    },
    "p2_project_database_flow": {
        "title": "数据库性能调优流程",
        "subtitle": "从慢查询出发，用执行计划解释现象，再用压测确认结果",
        "stages": ["采集慢查询", "分析执行计划", "调整索引与 SQL", "压测复验"],
        "checks": [
            "最左前缀\nkey 与 key_len 是否符合预期",
            "覆盖索引\n能否避免回表与排序",
            "稳定性\n固定并发与数据量重复三轮",
        ],
        "footers": [
            "索引不是越多越好，写入成本与优化器选择都要观察。",
        ],
    },
    "p2_project_concurrency_flow": {
        "title": "并发问题定位流程",
        "subtitle": "先建立基线，再找拐点，最后用工具验证可见性与竞争",
        "stages": ["建立基线", "压测找拐点", "剖析锁与切换", "验证正确性"],
        "checks": [
            "临界区\n把 IO 与日志移出锁范围",
            "并发拐点\n吞吐随线程数由升转降的位置",
            "内存可见性\nrace detector 与压力测试",
        ],
        "footers": [
            "并发度越高越慢通常是锁竞争或切换成本超过收益。",
        ],
    },
    "p2_project_security_flow": {
        "title": "安全验证与修复流程",
        "subtitle": "先建模再扫描，先复现再修复，最后用回归与审计闭环",
        "stages": ["资产与威胁建模", "扫描与验证", "最小修复", "回归与审计"],
        "checks": [
            "最小复现\n固定镜像、依赖与配置版本",
            "权限矩阵\n越权用例覆盖水平与垂直方向",
            "回归验证\n正常流程与边界输入都要通过",
        ],
        "footers": [
            "无法复现的告警要留记录与依据，而不是直接关闭。",
        ],
    },
    "p2_project_algorithm_flow": {
        "title": "算法工程化与性能验证流程",
        "subtitle": "先定义可复现的基准，再优化热点，最后用差分测试守住正确性",
        "stages": ["定义基准", "剖析热点", "替换算法与结构", "差分与回归"],
        "checks": [
            "数据版本\n固定随机种子与输入规模",
            "复杂度验证\n替换方案后增长曲线是否下降",
            "边界对拍\n空集、重复值、极值都要覆盖",
        ],
        "footers": [
            "先预热再采样，报告分布而不是单次耗时。",
        ],
    },
    "p2_project_devops_flow": {
        "title": "CI/CD 流水线流程",
        "subtitle": "构建一次、复用制品，用灰度与回滚能力换取发布信心",
        "stages": ["提交触发", "构建与测试", "制品与部署", "灰度与回滚"],
        "checks": [
            "可复现构建\n固定工具链与基础镜像版本",
            "制品标记\n版本号加 commit SHA 可追溯",
            "渐进发布\n按错误率与延迟决定放大流量",
        ],
        "footers": [
            "探针只查进程存活会漏掉真实故障，要加端到端冒烟。",
        ],
    },
    "p2_project_mobile_flow": {
        "title": "离线优先 App 的同步流程",
        "subtitle": "本地先写、队列重试、冲突合并，最后用性能与包体积验收",
        "stages": ["本地优先写入", "队列与同步", "冲突合并", "性能与体积验收"],
        "checks": [
            "幂等标识\n创建操作携带稳定唯一 ID",
            "冲突策略\n按字段合并并保留用户选择",
            "性能验收\n列表滚动帧率与首帧耗时",
        ],
        "footers": [
            "只在收到服务端确认后删除队列项，避免丢数据。",
        ],
    },
    "p2_project_etl_flow": {
        "title": "ETL 幂等与质量门禁流程",
        "subtitle": "抽取、清洗、分区写入与质量校验都要可重跑、可回补",
        "stages": ["抽取与落地", "清洗与校验", "分区幂等写入", "质量门禁与回补"],
        "checks": [
            "临时分区\n按业务主键去重后原子替换",
            "事件时间\n迟到数据按可回填窗口重算",
            "质量规则\n金额守恒与跨表一致性检查",
        ],
        "footers": [
            "重复运行不翻倍、迟到数据能回补，才算真正幂等。",
        ],
    },
};


def is_flow(config: dict) -> bool:
    return "stages" in config


def main() -> None:
    print(f"生成 {len(COMPARE)} 张补全配图：")
    for name, config in COMPARE.items():
        if is_flow(config):
            flow_diagram(name=name, **config)
        else:
            compare_diagram(name=name, **config)
    print("完成")


if __name__ == "__main__":
    main()
