// P1 题库补全：为 22 门只有 4 题的课程各补 1 道课程专属题目。
//
// 用法：
//   dart tool/add_quiz_questions.dart [--dry-run]
//
// 语言类课程补填空题，项目实战课程补排错题。新题会同时写入
// manifest.json 与对应 Markdown 的「考点精讲」，保证题面与讲解一致。
// 选项顺序按答案下标做了轮换，避免正确项总落在同一位置。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

class NewQuestion {
  const NewQuestion({
    required this.lessonId,
    required this.type,
    required this.question,
    required this.label,
    required this.explanation,
    this.options = const <String>[],
    this.answerIndex = 0,
    this.acceptedAnswers = const <String>[],
    this.code = '',
    this.language = '',
  });

  final String lessonId;
  final String type;
  final String question;
  final String label;
  final String explanation;
  final List<String> options;
  final int answerIndex;
  final List<String> acceptedAnswers;
  final String code;
  final String language;
}

const List<NewQuestion> questions = <NewQuestion>[
  NewQuestion(
    lessonId: 'python_first_script',
    type: 'fill',
    label: '填空·Python 第一个脚本',
    question: '补全命令：在终端里运行保存好的脚本 hello.py，应输入 python ____。',
    acceptedAnswers: <String>['hello.py'],
    explanation:
        'python hello.py 会把脚本文件名交给解释器，解释器读取该文件的每一行并顺序执行。'
        'Python 第一个脚本 的正文最小示例保存为 hello.py 后，要在终端执行 python hello.py 才能看到 print 的输出；'
        '如果只输入 python 会进入交互环境，等待逐行键入代码，并不会自动加载磁盘上的脚本文件。',
  ),
  NewQuestion(
    lessonId: 'python_if_else',
    type: 'fill',
    label: '填空·Python 条件判断',
    question: '补全代码：需要按顺序判断多个互斥条件时，应在 if 与 else 之间使用 ____ 分支。',
    acceptedAnswers: <String>['elif'],
    explanation:
        'elif 是 else if 的缩写，只有前面的 if 条件为假时才会继续判断它。'
        'Python 条件判断 的正文说明，多个互斥条件应该写成 if、elif、else 链，从上到下命中第一个为真的分支后就不再检查后面的条件；'
        '如果连续写多个独立的 if，所有条件都会被依次检查，可能同时命中多个分支。',
  ),
  NewQuestion(
    lessonId: 'python_loops',
    type: 'fill',
    label: '填空·Python 循环入门',
    question: '补全代码：要遍历 1、2、3、4 这四个整数，应写成 for i in ____(1, 5):。',
    acceptedAnswers: <String>['range'],
    explanation:
        'range(1, 5) 会生成从 1 开始、到 5 之前结束的整数序列，也就是 1、2、3、4 四个值。'
        'Python 循环入门 的正文示例用 range 控制 for 循环的迭代次数，起始值包含在下界里，终止值本身不会被取到；'
        '写成 range(1, 6) 会多循环一次，写成 range(5) 则从 0 开始。',
  ),
  NewQuestion(
    lessonId: 'python_list_dict_basics',
    type: 'fill',
    label: '填空·列表与字典入门',
    question: '补全代码：向列表 items 的末尾追加一个元素，应写成 items.____(x)。',
    acceptedAnswers: <String>['append'],
    explanation:
        'append 会把元素追加到列表末尾并原地修改列表，返回值是 None。'
        'Python 列表与字典入门 的正文示例用 items.append(x) 追加数据，再用下标或遍历读取；'
        '如果误写成 items = items.append(x)，列表本身虽然变了，但变量会被重新赋值为 None，后续读写就会报错。',
  ),
  NewQuestion(
    lessonId: 'cpp_variables_io',
    type: 'fill',
    label: '填空·C++ 变量与输入输出',
    question: '补全代码：向标准输出打印一行文本并换行，应写成 std::cout << "hi" << ____;。',
    acceptedAnswers: <String>['std::endl'],
    explanation:
        'std::endl 会先插入换行符再刷新输出缓冲区，因此终端能立刻看到这一行输出。'
        'C++ 变量与输入输出 的正文示例用 std::cout 搭配 << 输出内容，用 std::cin 搭配 >> 读取输入；'
        '只写换行符也能换行，但不会主动刷新缓冲区，调试信息可能延迟出现。',
  ),
  NewQuestion(
    lessonId: 'cpp_loops',
    type: 'fill',
    label: '填空·C++ 循环入门',
    question: '补全代码：在循环中跳过本次迭代、直接进入下一次判断，应使用 ____ 语句。',
    acceptedAnswers: <String>['continue'],
    explanation:
        'continue 会结束本次迭代的剩余语句，回到循环条件或迭代语句，判断是否进入下一轮。'
        'C++ 循环入门 的正文对比过 break 与 continue：break 直接跳出整个循环，continue 只跳过当前这一次；'
        '两者都只影响所在的那一层循环，嵌套结构里需要逐层确认作用范围。',
  ),
  NewQuestion(
    lessonId: 'java_variables_output',
    type: 'fill',
    label: '填空·Java 变量与输出',
    question: '补全代码：保存带小数点的价格，应使用 ____ 类型，例如 double price = 9.9;。',
    acceptedAnswers: <String>['double'],
    explanation:
        'double 是 Java 的 64 位双精度浮点类型，可以保存带小数点的数值。'
        'Java 变量与输出 的正文说明，整数默认是 int，浮点字面量默认是 double；'
        '用 int 保存 9.9 会被截断成 9，要保留小数必须声明为 double，或者声明 float 并给字面量加上后缀 f。',
  ),
  NewQuestion(
    lessonId: 'js_variables_types_intro',
    type: 'fill',
    label: '填空·JavaScript 变量与类型',
    question: '补全代码：声明一个初始化后不再重新赋值的块级常量，应写成 ____ PI = 3.14;。',
    acceptedAnswers: <String>['const'],
    explanation:
        'const 声明块级作用域的常量，必须在声明时初始化，之后不能重新赋值。'
        'JavaScript 变量与类型入门 的正文对比了 var、let 与 const：var 存在变量提升和函数作用域问题，let 允许重新赋值，'
        '只有确定不会改变的绑定才用 const，这样能在运行前就暴露误改。',
  ),
  NewQuestion(
    lessonId: 'js_conditions_loops',
    type: 'fill',
    label: '填空·JavaScript 条件与循环',
    question: '补全代码：判断两个值类型与内容都严格相等，应使用 ____ 运算符。',
    acceptedAnswers: <String>['==='],
    explanation:
        '=== 会同时比较类型和值，不会触发隐式类型转换。'
        'JavaScript 条件与循环 的正文用 === 与 == 做过对比：== 会把字符串 "1" 和数字 1 判为相等，'
        '容易在条件分支里产生意料之外的结果；判断数字、字符串与布尔值时应该优先使用 ===，只有明确需要类型转换时才用 ==。',
  ),
  NewQuestion(
    lessonId: 'js_functions_intro',
    type: 'fill',
    label: '填空·JavaScript 函数入门',
    question: '补全代码：用箭头函数声明求和函数，应写成 const add = (a, b) ____ a + b;。',
    acceptedAnswers: <String>['=>'],
    explanation:
        '箭头函数用 => 连接参数列表和函数体，没有自己的 this、arguments 与 prototype。'
        'JavaScript 函数入门 的正文同时给出函数声明与箭头函数两种写法：函数声明会被提升，可以先调用后定义；'
        '箭头函数赋值给 const 后不会提升，必须在声明之后才能调用，也不适合直接作为需要 this 的方法。',
  ),
  NewQuestion(
    lessonId: 'csharp_loops',
    type: 'fill',
    label: '填空·C# 循环入门',
    question: '补全代码：要求循环体至少执行一次再判断条件，应写成 ____ { ... } while (cond); 结构。',
    acceptedAnswers: <String>['do'],
    explanation:
        'do-while 会先执行一次循环体，之后再判断条件是否继续，因此循环体至少执行一次。'
        'C# 循环入门 的正文对比了 for、foreach、while 与 do-while：while 在入口先判断条件，条件一开始就不成立时一次也不执行；'
        'do-while 适合先执行再验证的场景，例如反复读取输入直到满足要求。',
  ),
  NewQuestion(
    lessonId: 'ts_basic_types',
    type: 'fill',
    label: '填空·TypeScript 基础类型',
    question: '补全代码：声明一个不允许修改内容的字符串数组，应写成 ____ string[] = ["a"];。',
    acceptedAnswers: <String>['readonly'],
    explanation:
        'readonly string[] 等价于 ReadonlyArray<string>，它禁止调用 push、pop 等会修改数组内容的成员，读取与遍历不受影响。'
        'TypeScript 基础类型 的正文说明，readonly 修饰只在编译期生效，运行时的数组仍然可以变化；'
        '如果要让变量绑定也不可重新赋值，还需要用 const 声明。',
  ),
  NewQuestion(
    lessonId: 'sql_table_intro',
    type: 'fill',
    label: '填空·表与 SQL 入门',
    question: '补全 SQL：让某列的取值在整张表里不重复，应在列定义后加上 ____ 约束。',
    acceptedAnswers: <String>['UNIQUE'],
    explanation:
        'UNIQUE 约束保证这一列或多列组合的取值在表中不重复，数据库会为它建立唯一索引。'
        '表与 SQL 入门 的正文在建表示例里同时使用了 PRIMARY KEY 与 UNIQUE：主键既唯一又非空，而且一张表只能有一个；'
        'UNIQUE 允许多个列各自声明，也允许插入 NULL，两者语义不能互相替代。',
  ),
  NewQuestion(
    lessonId: 'sql_query_intro',
    type: 'fill',
    label: '填空·SQL 查询入门',
    question: '补全 SQL：查询结果按 score 从高到低排序，应写成 ORDER BY score ____。',
    acceptedAnswers: <String>['DESC'],
    explanation:
        'DESC 表示降序排列，省略排序方向时默认按 ASC 升序。'
        'SQL 查询入门 的正文强调，ORDER BY 在 SELECT 之后执行，可以用列名、别名或表达式排序；'
        '同时写多列时前面的列优先级更高，只有前面的值相同时才继续按后面的列比较；'
        '把排序方向写错时，结果顺序会与预期完全相反。',
  ),
  NewQuestion(
    lessonId: 'project_network_capture_analysis',
    type: 'debug',
    label: '排错·网络抓包与协议分析',
    question: '抓包命令已经执行，但一个包都没有抓到。下面哪项判断最合理？',
    options: <String>[
      '抓包点选错网卡，容器流量走了独立网桥，应改抓 any 或 docker0',
      '网络链路已经断开，应先重启抓包工具再重新尝试排查问题',
      '输出级别不够，加上 -vvv 后任意网卡都能抓到容器流量',
      '服务需要重启，抓包工具才会重新加载网卡列表和过滤规则',
    ],
    answerIndex: 0,
    code:
        "tcpdump -i eth0 -nn 'tcp port 8080'\n"
        '# 容器通过 docker0 网桥访问宿主机，eth0 上看不到该服务流量',
    language: 'bash',
    explanation:
        '正确答案是「抓包点选错网卡，容器流量走了独立网桥，应改抓 any 或 docker0」。'
        '网络抓包与协议分析实战 的故障现场指出，抓不到任何数据包时先怀疑抓包点：'
        '容器流量经 docker0 转发，宿主机 eth0 上看不到；用 tcpdump -D 列出可用网卡，改抓 any 或 docker0，并确认端口映射方向后再复现问题。',
  ),
  NewQuestion(
    lessonId: 'project_database_tuning',
    type: 'debug',
    label: '排错·数据库性能调优',
    question: '给查询字段加了索引，但线上仍然很慢。下一步最应该做什么？',
    options: <String>[
      '继续叠加更多单列索引，认为索引数量越多查询速度就一定越快',
      '用 EXPLAIN 检查命中的索引与 key_len，再调整索引顺序或改成覆盖索引',
      '直接提高数据库的最大连接数，让慢查询的排队时间变得更短一些',
      '关闭慢查询日志，避免日志写入占用磁盘而拖慢整体数据库性能',
    ],
    answerIndex: 1,
    code: "EXPLAIN SELECT * FROM orders WHERE status = 'paid' ORDER BY created_at DESC;",
    language: 'sql',
    explanation:
        '正确答案是「用 EXPLAIN 检查命中的索引与 key_len，再调整索引顺序或改成覆盖索引」。'
        '数据库性能调优实战 的故障现场说明，加了索引仍然慢通常是查询条件顺序不满足最左前缀，或者排序字段没有被索引覆盖；'
        '先看执行计划中实际命中的索引与 key_len，再决定调整联合索引顺序还是改成覆盖索引。',
  ),
  NewQuestion(
    lessonId: 'project_concurrency_runtime',
    type: 'debug',
    label: '排错·操作系统与并发',
    question: '线程数从 8 调到 64 后，吞吐量反而下降。最可能的原因是什么？',
    options: <String>[
      '线程数仍然太少，任务都在队列里排队，继续把线程数翻倍即可',
      '机器 CPU 核心数不足，换成更多核心的机器就不用改任何代码',
      '锁竞争与上下文切换成本超过了并行收益，应缩小临界区并重测并发拐点',
      '并发下降说明业务量变小，与线程池配置和临界区范围都没有关系',
    ],
    answerIndex: 2,
    code:
        'synchronized (counter) {\n'
        '    counter++;\n'
        '    // 临界区里还有数据库查询与日志写入\n'
        '}',
    language: 'java',
    explanation:
        '正确答案是「锁竞争与上下文切换成本超过了并行收益，应缩小临界区并重测并发拐点」。'
        '操作系统与并发实战 的故障现场指出，并发度越高反而越慢通常来自锁竞争或线程切换开销；'
        '把数据库查询与日志写入移出临界区、分批聚合或改用 channel，再重新测量吞吐拐点才能确认结论。',
  ),
  NewQuestion(
    lessonId: 'project_security_lab',
    type: 'debug',
    label: '排错·安全攻防与防御',
    question: '扫描器报告了一个高危漏洞，但安全人员始终无法复现。正确做法是？',
    options: <String>[
      '无法复现的漏洞都属于误报，可以直接关闭扫描器不再处理',
      '只要把漏洞状态改成已修复，下次扫描通过就说明处理完成',
      '先降低扫描器规则等级，避免它继续产生无法复现的高危告警',
      '固定镜像与依赖版本，写出最小复现，再判断是真实漏洞还是误报',
    ],
    answerIndex: 3,
    code:
        '# 扫描器: CVE-2024-XXXX (critical)\n'
        '# 复现环境: 与扫描时的版本、配置均不一致',
    language: 'text',
    explanation:
        '正确答案是「固定镜像与依赖版本，写出最小复现，再判断是真实漏洞还是误报」。'
        '安全攻防与防御实战 的故障现场说明，工具报告漏洞却无法复现时，先对齐版本、配置与数据，写出最小复现；'
        '确认属于误报也要保留记录与依据，不能直接关闭扫描器或把状态改成已修复。',
  ),
  NewQuestion(
    lessonId: 'project_algorithm_engineering',
    type: 'debug',
    label: '排错·算法工程化与验证',
    question: '同一份算法实现，小数据全部正确，大数据却超时。应该先做什么？',
    options: <String>[
      '先把超时时间调大，让任务在更长时间窗口内跑完就可以交付',
      '用计数器与剖析定位热点，再比较哈希表、堆或排序方案是否适合规模',
      '直接改成并行执行，只要并行就一定能把复杂度和耗时降下来',
      '减少测试数据量，只要小数据全部正确就已经满足算法要求',
    ],
    answerIndex: 1,
    code:
        '# 输入规模从 1e3 提升到 1e7 后，单次运行超过 30s\n'
        'for i in range(n):\n'
        '    for j in range(n):\n'
        '        if data[i] == data[j]:\n'
        '            ...',
    language: 'python',
    explanation:
        '正确答案是「用计数器与剖析定位热点，再比较哈希表、堆或排序方案是否适合规模」。'
        '算法工程化与性能验证实战 的故障现场指出，小数据正确而大数据超时通常来自复杂度过高或数据结构选择不当；'
        '先用计数器和剖析确认热点，再验证替换方案后复杂度确实下降，最后用固定数据版本复测。',
  ),
  NewQuestion(
    lessonId: 'project_devops_pipeline',
    type: 'debug',
    label: '排错·DevOps 流水线',
    question: '本地构建成功，同一个提交在 CI 流水线里却失败。最应该先检查什么？',
    options: <String>[
      'CI 机器性能不足，直接升级流水线的机器配置即可解决失败',
      '把失败的步骤设置成允许失败，先让流水线整体状态变绿',
      '固定工具链版本，清理缓存后在新执行器复现并核对缺失依赖',
      '重新提交一次代码，只要这次通过就说明问题已经不存在了',
    ],
    answerIndex: 2,
    code:
        '# 本地: go1.22 / Node 20 / 有缓存\n'
        '# CI:   go1.21 / Node 18 / 缓存命中旧依赖',
    language: 'text',
    explanation:
        '正确答案是「固定工具链版本，清理缓存后在新执行器复现并核对缺失依赖」。'
        'DevOps CI/CD 流水线实战 的故障现场说明，本地成功而流水线失败多数来自工具版本、依赖缓存、环境变量或权限差异；'
        '把工具链版本固定进镜像，用干净执行器复现问题，再把缺失依赖写进构建清单。',
  ),
  NewQuestion(
    lessonId: 'project_mobile_offline_app',
    type: 'debug',
    label: '排错·移动端离线优先',
    question: '离线队列在恢复网络后重复提交了同一笔订单。根因最可能是什么？',
    options: <String>[
      '本地数据库写入太慢，应该在写入之前关闭事务来提升速度',
      '网络恢复速度太快，客户端必须固定延迟几秒后再发送队列',
      '离线队列只能保存一条记录，多余的记录被重复执行导致重复',
      '请求成功但响应丢失，重试时服务端没有按唯一标识幂等去重',
    ],
    answerIndex: 3,
    code:
        '// 本地队列重试\n'
        'await api.createOrder(payload);\n'
        'await queue.remove(item.id);\n'
        '// 服务端未校验 requestId',
    language: 'dart',
    explanation:
        '正确答案是「请求成功但响应丢失，重试时服务端没有按唯一标识幂等去重」。'
        '移动端离线优先 App 实战 的故障现场指出，恢复网络后出现重复任务，通常因为请求已成功但响应丢失后队列再次重试；'
        '为创建操作携带稳定唯一标识，服务端按标识去重，客户端只在收到确认后删除队列项。',
  ),
  NewQuestion(
    lessonId: 'project_data_etl',
    type: 'debug',
    label: '排错·数据工程 ETL',
    question: '同一个 ETL 任务重复运行后，目标分区行数翻倍。正确的修复方式是？',
    options: <String>[
      '先写临时分区，按业务主键去重并校验行数，再原子替换目标分区',
      '在任务入口加一个进程内标记，同一进程内只允许任务运行一次',
      '每次运行前清空整张表，然后重新导入全部历史数据再写回',
      '把任务改成手动执行，禁止调度器自动触发任何重跑操作',
    ],
    answerIndex: 0,
    code:
        "INSERT INTO fact_orders\n"
        'SELECT * FROM staging_orders\n'
        "WHERE dt = '2026-10-05';",
    language: 'sql',
    explanation:
        '正确答案是「先写临时分区，按业务主键去重并校验行数，再原子替换目标分区」。'
        '数据工程 ETL 与质量治理实战 的故障现场说明，重复运行导致数据翻倍是因为任务直接追加而没有按批次去重；'
        '正确做法是临时分区加业务主键去重、校验行数后原子替换，同时记录批次元数据以支持幂等回填。',
  ),
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final lessons = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessons[lesson['id'] as String] = lesson;
    }
  }

  var added = 0;
  var skipped = 0;
  for (final item in questions) {
    final lesson = lessons[item.lessonId];
    if (lesson == null) {
      stderr.writeln('找不到课程：${item.lessonId}');
      exitCode = 1;
      continue;
    }
    final problem = _validate(item);
    if (problem != null) {
      stderr.writeln('${item.lessonId}：$problem');
      exitCode = 1;
      continue;
    }
    final quiz = (lesson['quiz'] as List<dynamic>)
        .cast<Map<dynamic, dynamic>>();
    final normalized = _normalize(item.question);
    final exists = quiz.any(
      (entry) => _normalize((entry['question'] ?? '').toString()) == normalized,
    );
    if (exists) {
      skipped++;
      continue;
    }
    quiz.add(_toManifestEntry(item));
    if (!dryRun) {
      _appendExamPoint(lesson['file'] as String, item);
    }
    added++;
  }

  if (added > 0 && !dryRun) {
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }
  stdout.writeln(dryRun ? '[dry-run] 未写文件' : '已写入 manifest 与考点精讲');
  stdout.writeln('新增题目 $added，已存在跳过 $skipped');
}

Map<String, dynamic> _toManifestEntry(NewQuestion item) {
  if (item.type == 'fill') {
    return <String, dynamic>{
      'type': 'fill',
      'question': item.question,
      'options': <String>[],
      'answer': 0,
      'accepted_answers': item.acceptedAnswers,
      'explanation': item.explanation,
    };
  }
  return <String, dynamic>{
    'type': item.type,
    'question': item.question,
    'options': item.options,
    'answer': item.answerIndex,
    'code': item.code,
    'language': item.language,
    'explanation': item.explanation,
  };
}

/// 写库前先自检：解析长度、答案片段与选项下标都要满足治理规则。
String? _validate(NewQuestion item) {
  if (item.explanation.length < 120) {
    return '解析只有 ${item.explanation.length} 字，低于 120 字';
  }
  final normalized = _normalize(item.explanation);
  if (item.type == 'fill') {
    for (final answer in item.acceptedAnswers) {
      if (!normalized.contains(_normalize(answer))) {
        return '解析未包含可接受答案「$answer」';
      }
    }
    return null;
  }
  if (item.options.length < 2) return '选项不足 2 个';
  if (item.answerIndex < 0 || item.answerIndex >= item.options.length) {
    return '答案下标越界';
  }
  final correct = _normalize(item.options[item.answerIndex]);
  if (!normalized.contains(correct)) return '解析未包含正确选项原文';
  if (item.type == 'debug' && item.code.trim().isEmpty) {
    return '排错题缺少代码片段';
  }
  return null;
}

String _normalize(String value) => value.replaceAll(RegExp(r'\s+'), '');

void _appendExamPoint(String path, NewQuestion item) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('找不到教程文件：$path');
    exitCode = 1;
    return;
  }
  final markdown = file.readAsStringSync();
  final start = markdown.indexOf('## 考点精讲');
  if (start < 0) {
    stderr.writeln('$path 缺少「考点精讲」章节');
    exitCode = 1;
    return;
  }
  var next = markdown.indexOf('\n## ', start + '## 考点精讲'.length);
  if (next < 0) next = markdown.length;
  final section = markdown.substring(start, next);
  final count = RegExp(
    r'^### 考点 \d+：',
    multiLine: true,
  ).allMatches(section).length;
  final block =
      '### 考点 ${count + 1}：${item.label}\n\n'
      '- **题目**：${item.question}\n'
      '- **判断依据**：${item.explanation}';
  final before = markdown.substring(0, next).trimRight();
  final after = markdown.substring(next).trimLeft();
  file.writeAsStringSync('$before\n\n$block\n\n$after', flush: true);
}
