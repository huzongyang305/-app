// P1 内容广度整改：为仍然没有代码类题目的课程补一道代码阅读 / 排错题。
//
// 用法：
//   dart tool/add_code_questions_p1.dart [--dry-run]
//
// 处理口径：
//   · 每门课替换掉最机械的「核心结论是什么」选择题，题量保持 6 题不变；
//   · Markdown 里对应的「考点精讲」小节同步替换，正文与题库不脱节；
//   · 题目只使用本课已有的概念与代码风格，不引入课外结论；
//   · 已存在同题干时跳过，可重复执行。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 一道待补入的代码题 / 排错题。
class CodeQuestionTarget {
  const CodeQuestionTarget({
    required this.lessonId,
    required this.topic,
    required this.type,
    required this.question,
    required this.options,
    required this.answer,
    required this.code,
    required this.language,
    required this.explanation,
  });

  final String lessonId;
  final String topic;
  final String type;
  final String question;
  final List<String> options;
  final int answer;
  final String code;
  final String language;
  final String explanation;
}

const List<CodeQuestionTarget> targets = <CodeQuestionTarget>[
  CodeQuestionTarget(
    lessonId: 'css_design_tokens',
    topic: '代码阅读·令牌分层',
    type: 'code',
    question: '阅读这段设计令牌定义，下面哪项判断是正确的？',
    options: <String>[
      '组件里直接写 #3b82f6 更好，引用变量只会让样式更难读',
      '三层令牌只是命名习惯，切换主题时仍要逐个组件替换颜色',
      '原始令牌提供取值，语义令牌表达用途，组件只消费语义令牌，换肤时只改一处映射',
      '语义令牌必须写在组件样式文件里，放在 :root 作用域会失效',
    ],
    answer: 2,
    code:
        ':root {\n'
        '  --blue-500: #3b82f6;              /* 原始令牌：只有取值 */\n'
        '  --color-primary: var(--blue-500); /* 语义令牌：表达用途 */\n'
        '  --button-bg: var(--color-primary);/* 组件令牌：只被组件消费 */\n'
        '}\n\n'
        '.button {\n'
        '  background: var(--button-bg);\n'
        '}',
    language: 'css',
    explanation:
        '正确判断是原始令牌提供取值，语义令牌表达用途，组件只消费语义令牌，换肤时只改一处映射。'
        '设计令牌把「取值」与「用途」分层：--blue-500 这类色阶属于原始层，--color-primary 表达语义，'
        '组件只引用组件令牌。这样切换主题只改映射关系，不必在每个组件里替换硬编码色值；'
        '把语义令牌散落到组件文件里会破坏这层约定，也让对比度校验难以集中进行。',
  ),
  CodeQuestionTarget(
    lessonId: 'codegen_registers',
    topic: '代码阅读·寄存器分配',
    type: 'code',
    question: '阅读这段寄存器分配前后的代码，下面哪项判断是正确的？',
    options: <String>[
      '溢出到栈说明分配失败，必须增加物理寄存器才能继续编译',
      '图着色把生命周期重叠的虚拟寄存器连边，颜色不够时挑代价最小的变量溢出到栈',
      '虚拟寄存器数量超过物理寄存器时编译器必须报错，不能生成额外指令',
      '指令调度与寄存器分配相互独立，先后顺序不会影响结果',
    ],
    answer: 1,
    code:
        '; 三个虚拟寄存器同时活跃，物理寄存器只有 R1、R2\n'
        'mov  v1, 10\n'
        'mov  v2, 20\n'
        'add  v3, v1, v2\n'
        'mov  [rsp-8], v1    ; v1 溢出到栈，释放一个物理寄存器\n'
        'add  eax, v2, v3',
    language: 'text',
    explanation:
        '正确判断是图着色把生命周期重叠的虚拟寄存器连边，颜色不够时挑代价最小的变量溢出到栈。'
        '寄存器分配负责把无限多的虚拟寄存器映射到有限的物理寄存器，常用的图着色法给活跃区间重叠的'
        '两个虚拟寄存器连一条边，颜色数不足时按溢出代价挑一个变量写回栈槽。溢出并不代表分配失败，'
        '只是用访存换取寄存器；后续的指令调度还会重排指令以填补流水线气泡。',
  ),
  CodeQuestionTarget(
    lessonId: 'performance_metrics',
    topic: '代码阅读·Amdahl 定律',
    type: 'code',
    question: '阅读这段加速比计算，下面哪项判断是正确的？',
    options: <String>[
      '结果约 1.78 说明串行部分限制了上限，只增加并行度无法继续提速',
      '把并行度从 8 提到 80，加速比就会接近 8 倍',
      'Amdahl 定律只适用于单核程序，多核场景应直接看平均延迟',
      '把可并行比例提高到 0.9 之后，串行部分仍然不是瓶颈',
    ],
    answer: 0,
    code:
        'p, s = 0.5, 8.0                    # 可并行比例 50%，并行度 8\n'
        'speedup = 1 / ((1 - p) + p / s)    # 约等于 1.78',
    language: 'python',
    explanation:
        '正确判断是结果约 1.78 说明串行部分限制了上限，只增加并行度无法继续提速。'
        'Amdahl 定律写成 1 / ((1 - p) + p / s)，串行部分不随并行度缩小，因此把并行度从 8 提到 80 '
        '收益依然有限；只有提高可并行比例，例如进一步拆解串行段或减少同步开销，加速比才会明显上升。'
        '性能度量还要配合 P95 与 P99 与预热后的稳定数据，避免把噪声当成优化成果。',
  ),
  CodeQuestionTarget(
    lessonId: 'sorting_advanced',
    topic: '代码阅读·计数排序',
    type: 'code',
    question: '阅读计数排序实现，下面哪项判断是正确的？',
    options: <String>[
      '逆序回填是为了保持稳定性，相同值的元素仍按原始先后顺序排列',
      '逆序回填没有意义，改成正序遍历后结果完全相同且依然稳定',
      '计数排序的比较次数是 O(n log n)，适合任意大小的整数集合',
      '前缀和之后再回填会破坏计数，导致部分元素丢失',
    ],
    answer: 0,
    code:
        'def counting_sort(nums, top):\n'
        '    counts = [0] * (top + 1)\n'
        '    for value in nums:\n'
        '        counts[value] += 1\n'
        '    for i in range(1, len(counts)):   # 前缀和：得到每个值的结束位置\n'
        '        counts[i] += counts[i - 1]\n'
        '    result = [0] * len(nums)\n'
        '    for value in reversed(nums):      # 逆序回填，保证稳定\n'
        '        counts[value] -= 1\n'
        '        result[counts[value]] = value\n'
        '    return result',
    language: 'python',
    explanation:
        '正确判断是逆序回填是为了保持稳定性，相同值的元素仍按原始先后顺序排列。'
        '计数排序不做元素比较，时间复杂度是 O(n + k)，k 为值域大小，因此只适合值域不大的整数；'
        '前缀和给出每个值的结束位置，逆序回填时后出现的相同值先落到更靠后的位置，稳定性由此成立。'
        '值域远大于元素个数或元素不是整数时，应改用基数排序、外部排序或基于比较的排序。',
  ),
  CodeQuestionTarget(
    lessonId: 'string_matching',
    topic: '代码阅读·前缀函数',
    type: 'code',
    question: '阅读 KMP 的前缀函数构建代码，下面哪项判断是正确的？',
    options: <String>[
      '失配时把游标清零会让匹配退化成 O(n×m)',
      '失配时回退到 lps[length - 1] 才能复用已匹配的前后缀，避免重复比较',
      'lps[i] 保存的是模式串中出现次数最多的字符位置',
      'pattern 为空字符串时这段代码会陷入死循环',
    ],
    answer: 1,
    code:
        'def build_lps(pattern):\n'
        '    lps = [0] * len(pattern)\n'
        '    length, i = 0, 1\n'
        '    while i < len(pattern):\n'
        '        if pattern[i] == pattern[length]:\n'
        '            length += 1\n'
        '            lps[i] = length\n'
        '            i += 1\n'
        '        elif length:\n'
        '            length = lps[length - 1]   # 失配：回退到次长前后缀\n'
        '        else:\n'
        '            i += 1\n'
        '    return lps',
    language: 'python',
    explanation:
        '正确判断是失配时回退到 lps[length - 1] 才能复用已匹配的前后缀，避免重复比较。'
        'lps[i] 记录 pattern 从 0 到 i 的最长相等前后缀长度，失配时按它回退而不是把游标清零，'
        '主串指针因此不必回退，KMP 整体复杂度保持在线性量级。模式串为空时列表长度为零，'
        '循环不执行并直接返回空列表；回退写错才是字符串匹配里最常见的错误来源。',
  ),
  CodeQuestionTarget(
    lessonId: 'network_flow',
    topic: '代码阅读·残量网络',
    type: 'code',
    question: '阅读 Dinic 的建边代码，下面哪项判断是正确的？',
    options: <String>[
      '反向边初始容量为 0，退流时要靠残量网络把容量加回来',
      '反向边属于多余结构，删掉后最大流结果不变',
      '每条边只记录容量即可，互反下标可以省略',
      '当前弧优化会改变最大流的值，只能在调试时开启',
    ],
    answer: 0,
    code:
        'class Dinic:\n'
        '    def add_edge(self, u, v, cap):\n'
        '        self.graph[u].append([v, cap, len(self.graph[v])])    # 正向边\n'
        '        self.graph[v].append([u, 0, len(self.graph[u]) - 1])  # 反向边，容量 0',
    language: 'python',
    explanation:
        '正确判断是反向边初始容量为 0，退流时要靠残量网络把容量加回来。'
        '网络流在残量网络上增广：正向边消耗多少流量，反向边就增加同样多的容量，'
        '于是算法可以撤销先前不理想的分配并最终取到最大流，这也是最大流最小割定理的基础。'
        '反向边缺少互反下标就无法在常数时间内更新残量；当前弧优化只减少重复扫描，不改变最大流的值。',
  ),
  CodeQuestionTarget(
    lessonId: 'auth_oauth',
    topic: '代码阅读·令牌校验',
    type: 'debug',
    question: '阅读这段令牌签发与校验代码，下面哪项判断是正确的？',
    options: <String>[
      '令牌设了 900 秒过期，服务端仍必须校验签名并检查 exp，不能只解码 payload',
      '客户端不会修改令牌，因此服务端可以跳过签名校验来提升性能',
      'HS256 属于非对称算法，服务端只需保管公钥',
      'access token 有效期越长越安全，可以减少刷新次数',
    ],
    answer: 0,
    code:
        'header = {"alg": "HS256", "typ": "JWT"}\n'
        'body = {**payload, "exp": int(time.time()) + 900}\n'
        'signing_input = b64url(json.dumps(header).encode()) + b"." + b64url(json.dumps(body).encode())\n'
        'signature = b64url(hmac.new(secret, signing_input, hashlib.sha256).digest())\n'
        'token = signing_input.decode() + b"." + signature\n\n'
        '# 服务端：固定允许的算法，并校验签名、exp 与签发方\n'
        'claims = jwt.decode(token, secret, algorithms=["HS256"], options={"verify_exp": True})',
    language: 'python',
    explanation:
        '正确判断是令牌设了 900 秒过期，服务端仍必须校验签名并检查 exp，不能只解码 payload。'
        '认证确认调用者身份，授权决定它能访问什么，两者不能混为一谈。JWT 的 payload 只是 Base64 编码'
        '而非加密，任何人都能读取甚至改写，所以服务端必须固定允许的签名算法、校验签名与过期时间，'
        '并核对签发方与受众；HS256 是对称算法，验签方持有同一密钥，泄漏后果等同于签发权限。',
  ),
  CodeQuestionTarget(
    lessonId: 'distributed_transaction',
    topic: '代码阅读·Saga 补偿',
    type: 'debug',
    question: '阅读这段 Saga 编排代码，下面哪项判断是正确的？',
    options: <String>[
      '补偿要按正向执行的逆序进行，并且补偿操作本身必须幂等',
      '补偿失败可以直接忽略，因为业务已经回滚过一次',
      'Saga 保证了隔离性，中间状态不会被其他事务读到',
      '只要每步都包了异常处理，整个流程就等价于两阶段提交',
    ],
    answer: 0,
    code:
        'class Saga:\n'
        '    def run(self, ctx):\n'
        '        for name, action, compensate in self.actions:\n'
        '            try:\n'
        '                action(ctx)\n'
        '                self.executed.append((name, compensate))\n'
        '            except Exception:\n'
        '                self.rollback(ctx)\n'
        '                raise\n\n'
        '    def rollback(self, ctx):\n'
        '        for name, compensate in reversed(self.executed):   # 逆序补偿\n'
        '            compensate(ctx)',
    language: 'python',
    explanation:
        '正确判断是补偿要按正向执行的逆序进行，并且补偿操作本身必须幂等。'
        '分布式事务跨越多个服务与数据库，无法依赖单机锁，Saga 把长事务拆成一串本地事务，'
        '失败时按逆序执行补偿；重试与超时会让补偿被调用多次，因此补偿必须可重复执行。'
        'Saga 不提供隔离性，中间状态可能被其他事务读到，需要配合预留、状态机或语义锁；'
        '两阶段提交依赖协调者与全局锁，阻塞风险与代价都更高。',
  ),
  CodeQuestionTarget(
    lessonId: 'scheduling',
    topic: '代码阅读·轮转调度',
    type: 'code',
    question: '阅读这段时间片轮转的执行记录，下面哪项判断是正确的？',
    options: <String>[
      '轮转按就绪队列依次执行，周转时间取决于到达时间与时间片取值',
      '短作业优先的平均等待时间一定比时间片轮转更差',
      '时间片越小周转时间必然越短，因此应固定为 1 毫秒',
      '抢占只会发生在更高优先级任务到达时，时间片用完不会切换',
    ],
    answer: 0,
    code:
        '任务: A(需要 5) B(需要 3) C(需要 2)，时间片 = 2\n'
        '0-2    A 剩 3\n'
        '2-4    B 剩 1\n'
        '4-6    C 完成\n'
        '6-8    A 剩 1\n'
        '8-10   B 完成\n'
        '10-11  A 完成',
    language: 'text',
    explanation:
        '正确判断是轮转按就绪队列依次执行，周转时间取决于到达时间与时间片取值。'
        '时间片轮转属于抢占式调度，时间片用完就把任务放回队尾，保证交互任务不会长时间等待，'
        '代价是上下文切换开销；时间片过小会让切换占比升高，过大则退化成先来先服务。'
        '短作业优先在平均等待时间上通常更优，但需要预知运行时间并可能饿死长作业，'
        '通用系统因此更常使用多级反馈队列。',
  ),
  CodeQuestionTarget(
    lessonId: 'ipc_io',
    topic: '代码阅读·管道与 EOF',
    type: 'debug',
    question: '阅读这段管道通信代码，下面哪项判断是正确的？',
    options: <String>[
      '父进程要关闭写端，否则 read 可能一直等不到文件结束而阻塞',
      '管道是双向的，父子进程可以同时读写同一端',
      'os.read 会自动超时返回，写端未关闭也不会阻塞',
      '子进程退出后，父进程的 read 一定立即返回完整数据',
    ],
    answer: 0,
    code:
        'read_fd, write_fd = os.pipe()\n'
        'pid = os.fork()\n'
        'if pid == 0:\n'
        '    os.close(read_fd)\n'
        '    os.write(write_fd, b"child message")\n'
        '    os._exit(0)\n'
        'os.close(write_fd)          # 父进程关闭写端，否则读端等不到 EOF\n'
        'data = os.read(read_fd, 1024)',
    language: 'python',
    explanation:
        '正确判断是父进程要关闭写端，否则 read 可能一直等不到文件结束而阻塞。'
        '管道是单向字节流，只要还有进程持有写端就不会产生文件结束标志；'
        '父进程复制了写端描述符，即使子进程退出，read 仍可能挂起等待更多数据。'
        '进程间通信与 IO 模型要一起考虑：管道适合小数据与亲缘进程，大吞吐场景应改用共享内存减少拷贝，'
        '高并发网络服务则用多路复用接口配合非阻塞与边缘触发处理就绪事件。',
  ),
  CodeQuestionTarget(
    lessonId: 'os_synchronization',
    topic: '代码阅读·条件变量',
    type: 'debug',
    question: '阅读有界阻塞队列的写入逻辑，下面哪项判断是正确的？',
    options: <String>[
      '等待时要用 while 重新检查条件，否则被唤醒后可能再次越界',
      '把 wait 放进 if 分支更高效，可以少一次条件判断',
      'notify 会释放锁并让等待线程立刻持锁继续执行',
      '两个条件变量共用一个锁会导致死锁，必须再加一把锁',
    ],
    answer: 0,
    code:
        'class BoundedQueue:\n'
        '    def put(self, item):\n'
        '        with self.not_full:\n'
        '            while len(self.items) == self.capacity:\n'
        '                self.not_full.wait()      # 用 while 重查条件，防止虚假唤醒\n'
        '            self.items.append(item)\n'
        '            self.not_empty.notify()',
    language: 'python',
    explanation:
        '正确判断是等待时要用 while 重新检查条件，否则被唤醒后可能再次越界。'
        '条件变量允许虚假唤醒，被唤醒的线程也不保证立刻拿到锁，所以唤醒后必须重新检查队列是否已满；'
        '只用 if 检查一次，恢复执行时容量可能又被别的线程占满，写入就会越界。'
        'notify 只是把等待者移入就绪队列并释放锁，被唤醒线程仍要重新竞争锁；'
        '读与写各用一个条件变量能减少无谓唤醒，这是生产者消费者问题的常见写法。',
  ),
  CodeQuestionTarget(
    lessonId: 'gateway',
    topic: '代码阅读·熔断状态机',
    type: 'code',
    question: '阅读这段熔断器状态判断，下面哪项判断是正确的？',
    options: <String>[
      '熔断打开时直接拒绝请求，冷却结束后进入半开状态只用少量请求探测',
      '熔断打开后应立刻放行全部请求，方便快速确认下游是否恢复',
      '半开状态与关闭状态等价，只是日志级别不同',
      '加上熔断就不会再出现雪崩，超时与重试策略可以省略',
    ],
    answer: 0,
    code:
        'class CircuitBreaker:\n'
        '    def allow(self, now):\n'
        '        if self.state is State.OPEN:\n'
        '            if now - self.opened_at >= self.cooldown_seconds:\n'
        '                self.state = State.HALF_OPEN\n'
        '                self.probes = 0\n'
        '            else:\n'
        '                return False        # 冷却期内快速失败，避免拖垮下游\n'
        '        return True',
    language: 'python',
    explanation:
        '正确判断是熔断打开时直接拒绝请求，冷却结束后进入半开状态只用少量请求探测。'
        'API 网关承担限流、熔断、重试与优雅下线等职责，熔断器在连续失败后打开，'
        '快速失败可以避免线程与连接被慢依赖耗尽；冷却结束进入半开，只放少量探测请求，成功再恢复。'
        '重试必须配合退避、抖动与重试预算，否则会把瞬时故障放大成重试风暴，'
        '负载均衡也要及时剔除不健康实例。',
  ),
  CodeQuestionTarget(
    lessonId: 'ai_basics',
    topic: '代码阅读·概念层级',
    type: 'code',
    question: '阅读这棵概念关系图，下面哪项判断是正确的？',
    options: <String>[
      '深度学习属于机器学习，生成式 AI 又多建立在深度学习之上，三者是包含关系',
      '生成式 AI 与机器学习是并列关系，不需要训练数据',
      '机器学习就是把规则逐条写进程序，由模型负责执行',
      '决策树与 SVM 属于深度学习分支，需要多层神经网络实现',
    ],
    answer: 0,
    code:
        'AI（让机器表现出智能）\n'
        '└── 机器学习 ML（从数据中学习规律，而不是逐条写规则）\n'
        '    ├── 深度学习 DL（用多层神经网络学习表示）\n'
        '    │   └── 生成式 AI（生成文本、图像、音频、代码）\n'
        '    └── 其他方法（决策树、SVM、聚类）',
    language: 'text',
    explanation:
        '正确判断是深度学习属于机器学习，生成式 AI 又多建立在深度学习之上，三者是包含关系。'
        'AI 是目标，机器学习是实现路径之一，深度学习是机器学习中以多层神经网络学习表示的分支，'
        '生成式 AI 则多建立在深度学习之上，用概率方式生成新内容。'
        '传统编程由人写规则，机器学习由数据决定规则，两者失败模式不同：'
        '前者错在逻辑，后者常常错在数据分布与评测口径。',
  ),
  CodeQuestionTarget(
    lessonId: 'ai_coding_assistant',
    topic: '代码阅读·助手任务说明',
    type: 'code',
    question: '阅读这段写给助手的任务说明，下面哪项判断是正确的？',
    options: <String>[
      '交代上下文、约束、输出形式与验收标准，并要求先计划后编码，才能减少返工',
      '指令越短越好，只写一句「帮我优化一下」最不容易跑偏',
      '助手生成的代码看起来合理就可以合并，不必运行测试',
      '让它一次改完所有模块比小步提交更容易审查与回滚',
    ],
    answer: 0,
    code:
        '任务：给 src/services/order.ts 的 createOrder 增加幂等校验\n'
        '约束：不改动已有函数签名；复用现有 Redis 客户端；补充单元测试\n'
        '输出：先给改动计划，我确认后再输出完整代码\n'
        '验收：pnpm test order 全部通过，pnpm lint 无新增告警',
    language: 'text',
    explanation:
        '正确判断是交代上下文、约束、输出形式与验收标准，并要求先计划后编码，才能减少返工。'
        'AI 编程助手与代码生成的效果取决于输入质量：相关文件、接口定义、报错堆栈与运行命令决定它能否'
        '理解现场，语言版本、依赖限制与代码风格决定改动边界，验收标准决定何时算完成。'
        '生成结果必须由人复核并跑通编译、单元测试与类型检查，小步提交既方便回滚，也让代码评审聚焦每一处改动。',
  ),
  CodeQuestionTarget(
    lessonId: 'multimodal_rag',
    topic: '代码阅读·多模态分块',
    type: 'code',
    question: '阅读这个多模态分块结构，下面哪项判断是正确的？',
    options: <String>[
      '每个分块保留模态、文档与页码等定位信息，才能把答案引用回原始图片或表格',
      '图片分块只存一句描述即可，页码与资源地址可以省略',
      '多模态 RAG 只需把图片转成文字，检索时不必区分模态',
      '分块越粗越好，整篇文档一个分块能保留最完整的上下文',
    ],
    answer: 0,
    code:
        '@dataclass\n'
        'class MultiModalChunk:\n'
        '    chunk_id: str\n'
        '    modality: str          # text / table / image / formula\n'
        '    content: str           # 文本，或图片与图表的文字描述\n'
        '    doc_id: str\n'
        '    page: int\n'
        '    asset_uri: str | None = None',
    language: 'python',
    explanation:
        '正确判断是每个分块保留模态、文档与页码等定位信息，才能把答案引用回原始图片或表格。'
        '多模态 RAG 的难点不在拼接文本，而在让文字、表格、图片与公式进入同一检索空间：'
        '图片要先做 OCR 与版面分析生成描述，表格要保留表头与单位，分块必须携带文档、页码与资源地址，'
        '回答时才能给出可点开的引用。重排序阶段还要把跨模态分数校准到同一尺度，'
        '否则某一模态会长期霸占结果。',
  ),
  CodeQuestionTarget(
    lessonId: 'model_evaluation',
    topic: '代码阅读·加权评分',
    type: 'code',
    question: '阅读这段模型加权评分，下面哪项判断是正确的？',
    options: <String>[
      '权重按业务场景设定，质量、成本与延迟都要参与，不能只看公开榜单',
      '公开榜单分数最高的模型直接选用即可，不必评测自己的数据',
      '成本项写成倒数后，成本越高的模型得分越高',
      'P95 延迟与平均延迟等价，评测只需记录平均值',
    ],
    answer: 0,
    code:
        'def weighted(self, weights):\n'
        '    total = weights["quality"] * self.quality\n'
        '    total += weights["cost"] * (1 / self.cost_per_1k)       # 单价越低得分越高\n'
        '    total += weights["latency"] * (1 / self.p95_latency_ms)\n'
        '    return total',
    language: 'python',
    explanation:
        '正确判断是权重按业务场景设定，质量、成本与延迟都要参与，不能只看公开榜单。'
        '模型评测与选型要把质量、单价、P95 延迟、上下文长度、工具调用与合规要求放进同一张表，'
        '权重由业务决定：离线批处理更在意成本，交互式产品更在意尾延迟。'
        '评分函数对成本与延迟取倒数，让更便宜、更快的模型得到更高分。'
        '榜单成绩不能替代自有数据评测，上线前还应有自动评审与人工抽检交叉验证。',
  ),
  CodeQuestionTarget(
    lessonId: 'agent_memory',
    topic: '代码阅读·记忆打分',
    type: 'code',
    question: '阅读这段记忆打分函数，下面哪项判断是正确的？',
    options: <String>[
      '记忆得分同时考虑重要性与时间衰减，长期事实需要靠更高的 importance 保持',
      '记忆越多越好，应把整段对话原文无差别写入长期记忆',
      '时间衰减会让记忆在 30 天后被删除，属于数据丢失',
      '记忆不需要来源与用户标识，检索时可以全局共享',
    ],
    answer: 0,
    code:
        'import math\n\n'
        'def score(self, now):\n'
        '    age_days = (now - self.created_at) / 86400\n'
        '    recency = math.exp(-age_days / 30)      # 时间衰减\n'
        '    return self.importance * recency',
    language: 'python',
    explanation:
        '正确判断是记忆得分同时考虑重要性与时间衰减，长期事实需要靠更高的 importance 保持。'
        'Agent 记忆系统把对话中稳定的事实、偏好与事件抽取成结构化条目，检索时按重要性与新鲜度加权，'
        '衰减只是降低找回概率而不是删除数据。写入前要判重与合并，读取时按用户与租户隔离，'
        '并支持遗忘与删除请求；把整段对话原样塞进长期记忆会同时带来噪声、成本与隐私风险。',
  ),
  CodeQuestionTarget(
    lessonId: 'ai_data_engineering',
    topic: '代码阅读·去重指纹',
    type: 'code',
    question: '阅读这段数据清洗与去重代码，下面哪项判断是正确的？',
    options: <String>[
      '先标准化再算指纹能做精确去重，近似重复还要用相似度或 MinHash 这类方案',
      '只做精确哈希去重就能覆盖错别字与改写带来的重复样本',
      '训练数据不必记录来源与授权，去重后就与原文档无关',
      '标准化会改变语义，因此去重前不应做任何文本处理',
    ],
    answer: 0,
    code:
        'def normalize(text):\n'
        '    return " ".join(text.strip().lower().split())\n\n'
        'def content_hash(text):\n'
        '    return hashlib.sha256(normalize(text).encode("utf-8")).hexdigest()[:16]',
    language: 'python',
    explanation:
        '正确判断是先标准化再算指纹能做精确去重，近似重复还要用相似度或 MinHash 这类方案。'
        '数据工程与标注的流程通常是采集、清洗、去重、标注、质检与血缘登记：'
        '标准化统一大小写与空白后做哈希只能发现完全相同的文本，模板化改写与近义替换'
        '要用集合相似度或最小哈希才能识别。数据来源、授权与隐私处理必须落库留痕，'
        '去重并不能解除原来的许可约束。',
  ),
  CodeQuestionTarget(
    lessonId: 'vector_db',
    topic: '代码阅读·索引参数',
    type: 'code',
    question: '阅读这段索引参数代码，下面哪项判断是正确的？',
    options: <String>[
      'IVF 的 nlist 与 HNSW 的 M 决定召回与延迟的取舍，要拿自己的数据做基准测试',
      '索引参数只影响构建时间，调大 nlist 与 M 不会增加查询延迟',
      '只要选了 HNSW，就不必再关心召回率指标',
      '维度越高，HNSW 的 M 应越小，以减少内存占用',
    ],
    answer: 0,
    code:
        'def ivf_nlist(num_vectors):\n'
        '    return max(1, int(4 * math.sqrt(num_vectors)))\n\n'
        'def hnsw_m(dims):\n'
        '    if dims <= 256:\n'
        '        return 16\n'
        '    return 32        # 高维向量需要更大的邻居数',
    language: 'python',
    explanation:
        '正确判断是 IVF 的 nlist 与 HNSW 的 M 决定召回与延迟的取舍，要拿自己的数据做基准测试。'
        '向量数据库的近似检索要用召回率、P95 延迟、内存与过滤能力共同衡量：'
        'IVF 的 nlist 决定聚类数量，探测多少簇直接换召回；HNSW 的 M 与搜索宽度越大，图越密，'
        '召回更高但内存与延迟上升，维度越高通常越需要更大的 M。'
        '参数只有用真实语料跑基准才能定，索引参数与量化方式还会互相影响。',
  ),
  CodeQuestionTarget(
    lessonId: 'ai_multi_agent',
    topic: '代码阅读·多智能体编排',
    type: 'code',
    question: '阅读这个编排结构，下面哪项判断是正确的？',
    options: <String>[
      '编排者负责分解任务与汇总结果，子 Agent 各自专精，需要明确的输入输出契约',
      '子 Agent 越多越好，并行执行不需要汇总与去重',
      '多智能体一定比单 Agent 便宜，因为任务拆小后总 Token 会下降',
      '评审 Agent 与写作 Agent 共用一套提示词即可，不需要独立目标',
    ],
    answer: 0,
    code:
        '用户目标 -> 编排者（Planner）\n'
        '             ├── 检索 Agent   负责找资料\n'
        '             ├── 分析 Agent   负责计算与推理\n'
        '             ├── 写作 Agent   负责成文\n'
        '             └── 评审 Agent   负责检查与打分\n'
        '           -> 汇总输出',
    language: 'text',
    explanation:
        '正确判断是编排者负责分解任务与汇总结果，子 Agent 各自专精，需要明确的输入输出契约。'
        '多智能体与编排把复杂目标拆成可验证的子任务：编排者规划顺序、传递上下文并合并结果，'
        '子 Agent 只在各自职责范围内工作，上下文隔离能减少互相干扰。'
        '代价是 Token 与延迟随角色数量增长，还会出现重复检索与结论冲突，'
        '因此必须约定结构化输入输出、限制轮次并保留人工兜底。',
  ),
  CodeQuestionTarget(
    lessonId: 'agent_cost_performance',
    topic: '代码阅读·调用成本',
    type: 'code',
    question: '阅读这段成本计算代码，下面哪项判断是正确的？',
    options: <String>[
      '成本由输入与输出 Token 分别计价后累加，输出单价更高，压缩冗长回答往往最省钱',
      '成本只与请求次数有关，与输入输出 Token 数量无关',
      '缓存命中与模型路由只影响响应时间，不影响总成本',
      '为省钱应始终选最小模型，质量下降不会带来额外成本',
    ],
    answer: 0,
    code:
        '@property\n'
        'def total(self):\n'
        '    return (\n'
        '        self.input_tokens / 1000 * self.input_price\n'
        '        + self.output_tokens / 1000 * self.output_price\n'
        '    )',
    language: 'python',
    explanation:
        '正确判断是成本由输入与输出 Token 分别计价后累加，输出单价更高，压缩冗长回答往往最省钱。'
        'Agent 成本与性能优化要先把调用拆成可测量的口径：输入、输出与缓存命中的 Token 数，'
        '再加上工具调用与检索的额外开销。压缩上下文、裁剪无关检索结果、把简单任务路由到小模型、'
        '对稳定前缀做缓存，都能直接降低成本；一味换小模型会把成本转移到质量与返工上，'
        '必须用评测数据验证。',
  ),
  CodeQuestionTarget(
    lessonId: 'ai_training',
    topic: '代码阅读·显存估算',
    type: 'code',
    question: '阅读这段显存估算代码，下面哪项判断是正确的？',
    options: <String>[
      '训练显存主要来自参数、梯度、优化器状态与激活值，估算后才能决定分片或量化策略',
      '训练显存只取决于模型参数量，序列长度与批量大小可以忽略',
      '显存不足时只要换更大的显卡，并行策略不必调整',
      '量化只影响推理，训练阶段用量化不会损失精度',
    ],
    answer: 0,
    code:
        '@dataclass\n'
        'class MemoryPlan:\n'
        '    params_b: float\n'
        '    bytes_per_param_train: float = 16    # 权重 + 梯度 + 优化器状态\n'
        '    seq_len: int = 4096\n'
        '    batch_size: int = 4\n'
        '    activation_per_sample_gb: float = 0.6',
    language: 'python',
    explanation:
        '正确判断是训练显存主要来自参数、梯度、优化器状态与激活值，估算后才能决定分片或量化策略。'
        '模型训练与分布式并行要先算账：以每参数若干字节估算混合精度下的权重、梯度与优化器状态，'
        '激活值随序列长度与批量大小增长，往往才是长上下文训练的主要开销。'
        '据此选择数据并行、张量并行、流水并行或分片优化器，再配合梯度检查点与混合精度；'
        '换更大的显卡并不能替代这些取舍。',
  ),
  CodeQuestionTarget(
    lessonId: 'distributed_fundamentals',
    topic: '代码阅读·法定人数',
    type: 'code',
    question: '阅读这段法定人数计算，下面哪项判断是正确的？',
    options: <String>[
      '多数派读写集合必然相交，才能保证读到最新已提交值，all 与 one 的取舍不同',
      '副本数足够多时不需要法定人数，任意读写都满足一致性',
      'CAP 里的可用性意味着任何时候都能同时保证强一致与低延迟',
      '单机房内不会发生网络分区，副本间消息不会丢失',
    ],
    answer: 0,
    code:
        'def quorum(n, level="majority"):\n'
        '    if level == "majority":\n'
        '        return n // 2 + 1\n'
        '    if level == "all":\n'
        '        return n\n'
        '    return 1',
    language: 'python',
    explanation:
        '正确判断是多数派读写集合必然相交，才能保证读到最新已提交值，all 与 one 的取舍不同。'
        '分布式系统原理的核心是副本与共识：任意两个多数派之间至少重叠一个副本，'
        '读写相交才能保证读到已提交的写，代价是延迟取决于最慢的那个副本。'
        '要求全部副本确认会牺牲可用性，只要求一个副本又会失去一致性保证。'
        '网络分区无法避免，幂等、去重与超时后的重试都要按最坏情况设计。',
  ),
  CodeQuestionTarget(
    lessonId: 'microservices',
    topic: '代码阅读·服务契约',
    type: 'code',
    question: '阅读这份服务契约定义，下面哪项判断是正确的？',
    options: <String>[
      '显式声明依赖、超时、重试与 SLO，才能估出最坏延迟并控制重试放大',
      '服务拆得越细越好，同步调用不会增加故障面',
      '重试次数越多可用性越高，不需要退避与熔断配合',
      '只要每个服务自身可用性达到 99.9%，串联后的整体可用性就不会下降',
    ],
    answer: 0,
    code:
        '@dataclass\n'
        'class ServiceContract:\n'
        '    name: str\n'
        '    dependencies: list\n'
        '    timeout_ms: int = 800\n'
        '    retries: int = 1\n'
        '    slo_availability: float = 0.999\n\n'
        '    def worst_case_latency_ms(self):\n'
        '        return self.timeout_ms * (self.retries + 1)',
    language: 'python',
    explanation:
        '正确判断是显式声明依赖、超时、重试与 SLO，才能估出最坏延迟并控制重试放大。'
        '微服务拆分与治理要用契约把边界写清楚：依赖列表决定故障传播路径，超时与重试决定最坏延迟，'
        'SLO 决定容量与告警阈值。重试会把下游压力乘以调用方数量，必须配合退避、抖动、熔断与重试预算；'
        '每次同步调用都会串起可用性，链路上的概率相乘意味着整体必然低于任何单点。',
  ),
  CodeQuestionTarget(
    lessonId: 'messaging_events',
    topic: '代码阅读·幂等消费',
    type: 'debug',
    question: '阅读这段消息消费逻辑，下面哪项判断是正确的？',
    options: <String>[
      '同一业务键落到同一分区保证局部有序，去重标记要与业务写入放在同一事务',
      '消息队列保证全局严格有序，因此不需要按业务键分区',
      '消费者处理失败时直接丢弃消息即可，不需要重试与死信队列',
      '幂等只靠消息 ID 去重就够，业务状态不必考虑重复执行',
    ],
    answer: 0,
    code:
        'def partition_for(key, partitions):\n'
        '    digest = hashlib.md5(key.encode()).hexdigest()\n'
        '    return int(digest, 16) % partitions     # 同一键永远落在同一分区\n\n'
        'class IdempotentConsumer:\n'
        '    def handle(self, msg, tx):\n'
        '        if self.seen(tx, msg.id):\n'
        '            return                          # 重复投递直接跳过\n'
        '        self.apply(msg, tx)\n'
        '        self.mark(tx, msg.id)               # 与业务写入同一事务',
    language: 'python',
    explanation:
        '正确判断是同一业务键落到同一分区保证局部有序，去重标记要与业务写入放在同一事务。'
        '消息队列与事件驱动只能按分区保证顺序，因此要用业务键分区让同一实体的变更保持有序；'
        '投递语义通常是至少一次，消费端必须幂等。去重表必须与业务写入在同一事务提交，'
        '否则会出现写成功但标记丢失的重复执行；反复失败的消息要进入死信队列并告警，而不是静默丢弃。',
  ),
  CodeQuestionTarget(
    lessonId: 'high_availability',
    topic: '代码阅读·可用性计算',
    type: 'code',
    question: '阅读这段可用性计算代码，下面哪项判断是正确的？',
    options: <String>[
      '串行依赖会放大不可用，冗余并行能提升可用性，前提是故障不能同时发生',
      '串联的服务越多整体可用性越高，因为每个服务都有独立冗余',
      '单机可用性达到 99.99%，整条链路就一定满足 99.99% 的 SLO',
      '容量规划只看平均 QPS，峰值与突发余量不必预留',
    ],
    answer: 0,
    code:
        'def availability_chain(values):\n'
        '    result = 1.0\n'
        '    for value in values:\n'
        '        result *= value           # 串行依赖：可用性相乘\n'
        '    return round(result, 6)\n\n'
        'def availability_parallel(values):\n'
        '    failure = 1.0\n'
        '    for value in values:\n'
        '        failure *= (1 - value)\n'
        '    return round(1 - failure, 6)  # 冗余并联：1 减去同时故障概率',
    language: 'python',
    explanation:
        '正确判断是串行依赖会放大不可用，冗余并行能提升可用性，前提是故障不能同时发生。'
        '高可用与容量规划要先用可用性相乘算清链路：三个 99.9% 的服务串起来只剩约 99.7%，'
        '每月多出成倍的不可用时间；并联冗余按 1 减去同时故障概率计算，'
        '但如果冗余节点共享电源、交换机或同一份配置，故障就变成相关的，冗余不再生效。'
        '容量还要按峰值与突发的余量规划。',
  ),
  CodeQuestionTarget(
    lessonId: 'distributed_id',
    topic: '代码阅读·雪花算法',
    type: 'code',
    question: '阅读雪花 ID 的生成逻辑，下面哪项判断是正确的？',
    options: <String>[
      '时间戳、机器号与序列号拼成有序 ID，机器号必须唯一，还要处理时钟回拨',
      '机器号允许重复，冲突概率很低，不需要额外约束',
      '序列号用满后可以直接复用旧 ID，避免等待下一毫秒',
      '雪花 ID 依赖中心发号服务，节点增多时必须扩容数据库',
    ],
    answer: 0,
    code:
        'def next_id(self):\n'
        '    now = self._current_ms()\n'
        '    if now < self._last_ms:\n'
        '        self._wait_until(self._last_ms)     # 时钟回拨：等待或拒绝发号\n'
        '    if now == self._last_ms:\n'
        '        self.sequence = (self.sequence + 1) & self.MAX_SEQUENCE\n'
        '        if self.sequence == 0:\n'
        '            now = self._wait_next_ms()\n'
        '    return (now - self.EPOCH) << 22 | self.machine_id << 12 | self.sequence',
    language: 'python',
    explanation:
        '正确判断是时间戳、机器号与序列号拼成有序 ID，机器号必须唯一，还要处理时钟回拨。'
        '分布式 ID 与发号器要同时满足唯一、趋势递增与低延迟：雪花算法把毫秒时间戳、机器号与序列号'
        '按位拼接，机器号重复会直接产生重复 ID，同毫秒内序列号用满必须等到下一毫秒。'
        '时钟回拨会让新 ID 小于已发出的 ID，因此要等待、拒绝或借助位图补救；'
        '号段模式则用数据库批量领取区间换取吞吐。',
  ),
  CodeQuestionTarget(
    lessonId: 'design_patterns',
    topic: '代码阅读·策略模式',
    type: 'code',
    question: '阅读这段折扣策略实现，下面哪项判断是正确的？',
    options: <String>[
      '用可替换对象替代分支判断，新增折扣类型只需加一个实现类，符合开闭原则',
      '策略模式把所有分支集中到同一个 switch 里，修改更方便',
      'SOLID 的单一职责要求一个类承担全部折扣计算逻辑',
      '只要用了设计模式，代码就不需要单元测试与接口约定',
    ],
    answer: 0,
    code:
        'class DiscountStrategy(ABC):\n'
        '    @abstractmethod\n'
        '    def apply(self, amount: float) -> float:\n'
        '        raise NotImplementedError\n\n'
        'class NoDiscount(DiscountStrategy):\n'
        '    def apply(self, amount: float) -> float:\n'
        '        return amount\n\n'
        'class VipDiscount(DiscountStrategy):\n'
        '    def apply(self, amount: float) -> float:\n'
        '        return amount * 0.8',
    language: 'python',
    explanation:
        '正确判断是用可替换对象替代分支判断，新增折扣类型只需加一个实现类，符合开闭原则。'
        '设计模式与 SOLID 解决的是变化点定位问题：策略模式把易变算法抽成接口，'
        '调用方依赖抽象而不依赖具体分支，新增类型无须修改既有代码。'
        '单一职责要求一个类只承担一个变化原因，把折扣、税费与日志混在一个类里会让测试与发布互相牵连；'
        '模式也不能替代接口约定与单元测试，过度设计同样是一种反模式。',
  ),
  CodeQuestionTarget(
    lessonId: 'testing_strategy',
    topic: '代码阅读·测试套件统计',
    type: 'code',
    question: '阅读这份测试套件统计，下面哪项判断是正确的？',
    options: <String>[
      '除数量外还要跟踪不稳定用例与执行时长，用测试金字塔控制各层比例',
      '覆盖率是唯一指标，行覆盖率达到 100% 就不会有遗漏',
      'E2E 用例越多越好，应该用它替代单元测试以贴近真实环境',
      '不稳定的测试设置自动重试通过即可，不必记录与修复',
    ],
    answer: 0,
    code:
        '@dataclass\n'
        'class TestSuite:\n'
        '    unit: int = 0\n'
        '    integration: int = 0\n'
        '    e2e: int = 0\n'
        '    flaky: int = 0\n'
        '    durations: list = field(default_factory=list)\n\n'
        '    def total(self) -> int:\n'
        '        return self.unit + self.integration + self.e2e',
    language: 'python',
    explanation:
        '正确判断是除数量外还要跟踪不稳定用例与执行时长，用测试金字塔控制各层比例。'
        '测试策略要回答用什么成本换什么信心：大量快速的单元测试覆盖分支与边界，'
        '集成测试验证模块之间的契约与数据格式，少量端到端用例守住关键路径。'
        '不稳定用例会侵蚀团队对持续集成的信任，必须记录并定位原因；'
        '覆盖率只是下限指标，断言质量与用例分布才决定真实的防护能力。',
  ),
  CodeQuestionTarget(
    lessonId: 'requirements_modeling',
    topic: '代码阅读·验收标准',
    type: 'code',
    question: '阅读这条验收标准模板，下面哪项判断是正确的？',
    options: <String>[
      '用假如、当、那么写清前提、动作与预期结果，验收标准才能被测试化',
      '需求文档写清功能名称即可，验收细节由开发自行决定',
      '用户故事应写实现方案而不是用户价值，便于直接分配任务',
      '验收标准越多越好，重复与冲突的条目可以上线后再清理',
    ],
    answer: 0,
    code:
        '@dataclass\n'
        'class AcceptanceCriterion:\n'
        '    given: str\n'
        '    when: str\n'
        '    then: str\n\n'
        '    def text(self) -> str:\n'
        '        return f"假如 {self.given}，当 {self.when}，那么 {self.then}"',
    language: 'python',
    explanation:
        '正确判断是用假如、当、那么写清前提、动作与预期结果，验收标准才能被测试化。'
        '需求分析与建模把模糊诉求转成可验证条目：用户故事说明角色、目标与价值，'
        '验收标准用前提、操作与预期结果三段式描述，边界与异常路径要单独列出。'
        '术语、状态与领域模型要统一，避免同一概念在文档里有两种名字；'
        '架构决策记录用于保存关键取舍，UML 用于对齐结构，都不能代替与业务方的确认。',
  ),
  CodeQuestionTarget(
    lessonId: 'se_test_design',
    topic: '代码阅读·用例设计',
    type: 'code',
    question: '阅读这组用例设计辅助函数，下面哪项判断是正确的？',
    options: <String>[
      '边界值取边界本身与紧邻值，等价类划分有效与无效输入，两者结合能减少冗余用例',
      '边界值只需测区间内部，边界本身属于特殊情况不必覆盖',
      '等价类要求每个输入值各写一条用例，才能保证没有遗漏',
      '判定表与正交实验属于黑盒方法，不能与等价类结合使用',
    ],
    answer: 0,
    code:
        'def boundary_cases(low, high):\n'
        '    return [low - 1, low, low + 1, high - 1, high, high + 1]\n\n'
        'def equivalence_classes(value_range, invalid):\n'
        '    return {"valid": [value_range], "invalid": list(invalid)}',
    language: 'python',
    explanation:
        '正确判断是边界值取边界本身与紧邻值，等价类划分有效与无效输入，两者结合能减少冗余用例。'
        '测试用例设计方法的目标是用最少的用例暴露最多缺陷：等价类把输入划分成处理逻辑相同的集合，'
        '每一类取代表值；边界值专门覆盖最容易出错的分界，取值本身与紧邻值。'
        '多条件组合再用判定表或正交实验压缩，流程类需求用状态迁移覆盖；'
        '方法要与风险结合，高风险模块才值得加密用例。',
  ),
  CodeQuestionTarget(
    lessonId: 'sdl_security',
    topic: '代码阅读·威胁建模',
    type: 'code',
    question: '阅读这份威胁建模数据，下面哪项判断是正确的？',
    options: <String>[
      '按资产梳理威胁场景、评估可能性与影响并给出缓解措施，优先处理高风险项',
      '安全设计只需上线前做一次渗透测试，开发阶段不必建模',
      '威胁建模是安全团队的专属工作，研发与产品不必参与',
      '只要使用框架默认配置，就不必再检查依赖漏洞与权限边界',
    ],
    answer: 0,
    code:
        '@dataclass\n'
        'class Threat:\n'
        '    category: str            # STRIDE 之一\n'
        '    asset: str\n'
        '    scenario: str\n'
        '    likelihood: int          # 1 到 5\n'
        '    impact: int              # 1 到 5\n'
        '    mitigation: str = ""\n\n'
        '    def risk(self) -> int:\n'
        '        return self.likelihood * self.impact',
    language: 'python',
    explanation:
        '正确判断是按资产梳理威胁场景、评估可能性与影响并给出缓解措施，优先处理高风险项。'
        '安全开发生命周期把安全活动嵌进需求、设计、编码、测试与发布：'
        '用 STRIDE 分类枚举仿冒、篡改、抵赖、信息泄露、拒绝服务与权限提升，'
        '按资产与数据流评估风险，再决定缓解措施与验证方式。'
        '依赖漏洞、密钥管理与权限边界都要持续检查，上线前的一次渗透测试无法覆盖设计阶段留下的结构性问题。',
  ),
  CodeQuestionTarget(
    lessonId: 'se_postmortem',
    topic: '代码阅读·事故时间线',
    type: 'code',
    question: '阅读这段事故时间线，下面哪项判断是正确的？',
    options: <String>[
      '时间线要记录决策点与信息缺口，复盘聚焦系统与流程改进而不是追究个人',
      '复盘报告写清是谁导致了故障，就能避免同样的人再次犯错',
      '事故结束后应立即关闭相关监控，以减少告警噪音',
      '只要回滚成功，就不必补充回归用例与监控盲区',
    ],
    answer: 0,
    code:
        'T0     (10:02) 变更发布，监控无异常\n'
        'T0+3m  (10:05) 错误率从 0.1% 升至 4%，告警触发\n'
        'T0+15m (10:17) 决定回滚而不是原地修复\n'
        'T0+20m (10:22) 回滚完成，错误率回落到 0.2%\n'
        'T0+30m (10:32) 确认数据一致性，事故结束',
    language: 'text',
    explanation:
        '正确判断是时间线要记录决策点与信息缺口，复盘聚焦系统与流程改进而不是追究个人。'
        '故障复盘与事故管理按事实重建时间线：何时变更、何时告警、何时确认、依据什么决定回滚还是修复，'
        '并标出哪段时间没有监控覆盖。改进项要区分检测、响应与预防，落到负责人与期限，'
        '同时补回归用例、演练与告警阈值。把原因归结为个人疏忽会掩盖流程缺陷，也难以阻止同类事故再次发生。',
  ),
  CodeQuestionTarget(
    lessonId: 'se_tech_debt',
    topic: '代码阅读·债务评分',
    type: 'code',
    question: '阅读这段技术债评分，下面哪项判断是正确的？',
    options: <String>[
      '按风险、改动频率与修复成本排序，高频改动且风险高的债务优先偿还',
      '技术债只能靠重构偿还，补文档与补测试没有帮助',
      '只要功能能上线，就应该无限期推迟所有债务修复',
      '债务评分只反映代码行数，行数越多越应该优先重构',
    ],
    answer: 0,
    code:
        '@dataclass\n'
        'class DebtItem:\n'
        '    risk: int                # 1 到 5：稳定性与安全风险\n'
        '    change_frequency: int    # 1 到 5：改动频率\n'
        '    fix_cost_days: float\n\n'
        '    def score(self) -> float:\n'
        '        return self.risk * self.change_frequency / max(self.fix_cost_days, 0.5)',
    language: 'python',
    explanation:
        '正确判断是按风险、改动频率与修复成本排序，高频改动且风险高的债务优先偿还。'
        '技术债务管理的核心是把债务当成投资决策：风险高、每周都要改的模块，'
        '即使修复成本不低也应优先处理，因为它在持续产生利息；长期不动且风险可控的代码可以延后。'
        '偿还手段不只有重写，补测试、补文档、封装接口与渐进替换都能降低利息，'
        '关键是让技术债条目可见并纳入迭代预算。',
  ),
  CodeQuestionTarget(
    lessonId: 'math_eigen_svd',
    topic: '代码阅读·幂迭代',
    type: 'code',
    question: '阅读幂迭代实现，下面哪项判断是正确的？',
    options: <String>[
      '每轮用矩阵乘向量并归一化，向量会收敛到绝对值最大特征值对应的特征向量',
      '幂迭代能一次求出全部特征值与特征向量，不需要 QR 或 SVD 分解',
      '归一化只为数值好看，去掉后收敛速度与稳定性都不变',
      '特征值分解只适用于方阵，所以 PCA 与降维无法使用 SVD',
    ],
    answer: 0,
    code:
        'def power_iteration(matrix, iterations=500, tol=1e-9):\n'
        '    n = len(matrix)\n'
        '    vector = [1.0 / math.sqrt(n)] * n\n'
        '    for _ in range(iterations):\n'
        '        product = [sum(matrix[i][j] * vector[j] for j in range(n)) for i in range(n)]\n'
        '        norm = math.sqrt(sum(value * value for value in product))\n'
        '        vector = [value / norm for value in product]   # 每轮归一化\n'
        '    return vector',
    language: 'python',
    explanation:
        '正确判断是每轮用矩阵乘向量并归一化，向量会收敛到绝对值最大特征值对应的特征向量。'
        '特征值、奇异值分解与降维的关系要从定义出发：幂迭代靠反复乘矩阵放大主特征方向，'
        '归一化既防止数值溢出，也让收敛判断有统一尺度，主特征值可由瑞利商估计。'
        '要求出全部特征值要用 QR 迭代或 Lanczos，非方阵与低秩近似用奇异值分解，'
        'PCA 正是对中心化数据做奇异值分解或协方差矩阵的特征分解。',
  ),
  CodeQuestionTarget(
    lessonId: 'math_calculus_gradient',
    topic: '代码阅读·数值梯度',
    type: 'code',
    question: '阅读数值梯度实现，下面哪项判断是正确的？',
    options: <String>[
      '用中心差分近似偏导，常用来校验解析梯度，步长过大或过小都会带来误差',
      '数值梯度比解析梯度更精确，训练时应全程使用它',
      '梯度下降一定收敛到全局最优，与学习率选择无关',
      '学习率越大收敛越快，因此应取允许的最大值',
    ],
    answer: 0,
    code:
        'def numerical_gradient(f, point, eps=1e-6):\n'
        '    grad = []\n'
        '    for index in range(len(point)):\n'
        '        forward, backward = list(point), list(point)\n'
        '        forward[index] += eps\n'
        '        backward[index] -= eps\n'
        '        grad.append((f(forward) - f(backward)) / (2 * eps))\n'
        '    return grad',
    language: 'python',
    explanation:
        '正确判断是用中心差分近似偏导，常用来校验解析梯度，步长过大或过小都会带来误差。'
        '微积分与梯度下降的连接点是链式法则：反向传播用解析方法高效算出各参数偏导，'
        '数值梯度以两次函数求值近似，适合做梯度检查。'
        '步长过大截断误差明显，过小则被浮点舍入吞掉；中心差分的误差阶优于单侧差分。'
        '学习率过大导致震荡与发散，过小则收敛缓慢，非凸目标还可能停在局部最优或鞍点。',
  ),
];

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final file = File(manifestPath);
  final manifest = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final lessons = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessons[lesson['id'] as String] = lesson;
    }
  }

  final errors = <String>[];
  var replaced = 0;
  var skipped = 0;

  for (final target in targets) {
    final lesson = lessons[target.lessonId];
    if (lesson == null) {
      errors.add('找不到课程：${target.lessonId}');
      continue;
    }
    final quiz = (lesson['quiz'] as List).cast<Map<dynamic, dynamic>>();
    final normalizedTarget = _normalize(target.question);
    final exists = quiz.any(
      (item) => _normalize('${item['question'] ?? ''}') == normalizedTarget,
    );
    if (exists) {
      skipped++;
      continue;
    }
    final index = _replaceIndex(quiz);
    if (index < 0) {
      errors.add('${target.lessonId}：没有可替换的选择题');
      continue;
    }
    final removed = '${quiz[index]['question'] ?? ''}';
    quiz[index] = <String, dynamic>{
      'type': target.type,
      'question': target.question,
      'options': target.options,
      'answer': target.answer,
      'code': target.code,
      'language': target.language,
      'explanation': target.explanation,
    };
    if (!dryRun) {
      final failure = _replaceExamPoint(
        lesson['file'] as String,
        index + 1,
        target,
      );
      if (failure != null) {
        errors.add('${target.lessonId}：$failure');
        continue;
      }
    }
    replaced++;
    stdout.writeln(
      '${dryRun ? '[dry-run] ' : ''}${target.lessonId} 第 ${index + 1} 题：'
      '$removed -> ${target.type}',
    );
  }

  if (errors.isNotEmpty) {
    stderr.writeln('校验失败，未写入任何改动：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  if (dryRun) {
    stdout.writeln('[dry-run] 计划替换 $replaced 题，已存在跳过 $skipped 题');
    return;
  }

  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );
  stdout.writeln('已替换 $replaced 题，跳过（已存在）$skipped 题');
}

/// 优先替换最机械的「核心结论是什么」选择题，其次退到单选题。
int _replaceIndex(List<Map<dynamic, dynamic>> quiz) {
  for (var index = 0; index < quiz.length; index++) {
    final question = '${quiz[index]['question'] ?? ''}';
    if (question.contains('核心结论是什么')) return index;
  }
  for (var index = quiz.length - 1; index >= 0; index--) {
    if ('${quiz[index]['type'] ?? ''}' == 'single') return index;
  }
  for (var index = quiz.length - 1; index >= 0; index--) {
    if ('${quiz[index]['type'] ?? ''}'.isEmpty) return index;
  }
  return -1;
}

/// 同步改写 Markdown 里编号一致的「考点精讲」小节，返回错误说明或 null。
String? _replaceExamPoint(String path, int number, CodeQuestionTarget target) {
  final file = File(path);
  if (!file.existsSync()) return '教程文件不存在（$path）';
  var markdown = file.readAsStringSync();
  final header = '### 考点 $number：';
  final start = markdown.indexOf(header);
  if (start < 0) return '正文缺少「考点 $number」小节';
  var end = markdown.indexOf('### 考点 ${number + 1}：', start + header.length);
  if (end < 0) {
    end = markdown.indexOf('\n## ', start + header.length);
  }
  if (end < 0) end = markdown.length;
  final correct = target.options[target.answer];
  final block =
      '### 考点 $number：${target.topic}\n\n'
      '- **题目**：${target.question}\n'
      '- **正确判断**：$correct\n'
      '- **判断依据**：${target.explanation}\n\n';
  markdown = markdown.substring(0, start) + block + markdown.substring(end);
  file.writeAsStringSync(markdown, flush: true);
  return null;
}

String _normalize(String value) => value.replaceAll(RegExp(r'\s+'), '');
