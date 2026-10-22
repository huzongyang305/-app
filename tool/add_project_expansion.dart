// 项目实战扩容工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/add_project_expansion.dart --dry-run
//   dart tool/add_project_expansion.dart
//
// 在 project_practice 分类下追加 8 门项目课，生成 Markdown 并写回 manifest。
// 新增课程先各带 4 道单选，随后由 expand_lessons_p0_p1_p2.dart 补齐
// 多选 / 排序 / 排错题与可运行练习、故障现场章节。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String projectCategoryId = 'project_practice';
const String contentUpdatedAt = '2026-10-06';

class ProjectSpec {
  const ProjectSpec({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.summaryZh,
    required this.summaryEn,
    required this.difficulty,
    required this.order,
    required this.hours,
    required this.keywords,
    required this.image,
    required this.positioning,
    required this.background,
    required this.goals,
    required this.constraints,
    required this.architecture,
    required this.flow,
    required this.milestones,
    required this.command,
    required this.expected,
    required this.deliverables,
    required this.failures,
    required this.extensions,
    required this.questions,
    required this.prerequisites,
    required this.related,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String summaryZh;
  final String summaryEn;
  final String difficulty;
  final int order;
  final int hours;
  final List<String> keywords;
  final String image;
  final String positioning;
  final String background;
  final List<String> goals;
  final List<List<String>> constraints;
  final String architecture;
  final String flow;
  final List<List<String>> milestones;
  final String command;
  final String expected;
  final List<String> deliverables;
  final List<List<String>> failures;
  final List<String> extensions;
  final List<Map<String, Object>> questions;
  final List<String> prerequisites;
  final List<String> related;
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();
  final category = categories.firstWhere(
    (item) => item['id'] == projectCategoryId,
  );
  final lessons = (category['lessons'] as List).cast<Map<String, dynamic>>();
  final existingIds = <String>{
    for (final lesson in lessons) lesson['id'] as String,
  };
  final existingQuestions = <String>{};
  for (final rawCategory in categories) {
    for (final rawLesson in rawCategory['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      for (final rawQuestion in lesson['quiz'] as List? ?? const []) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        existingQuestions.add(
          (question['question'] as String? ?? '').replaceAll(
            RegExp(r'\s+'),
            '',
          ),
        );
      }
    }
  }

  final errors = <String>[];
  final seenQuestions = <String>{};
  for (final spec in projectSpecs) {
    if (!existingIds.add(spec.id)) errors.add('课程 ID 已存在：${spec.id}');
    if (!File('assets/content/images/${spec.image}').existsSync()) {
      errors.add('配图不存在：${spec.image}');
    }
    if (spec.questions.length != 4) {
      errors.add('${spec.id} 的题目数不是 4');
    }
    final answerIndexes =
        spec.questions.map((question) => question['answer'] as int).toList()
          ..sort();
    if (answerIndexes.join(',') != '0,1,2,3') {
      errors.add('${spec.id} 的答案下标不是 0/1/2/3 各一次');
    }
    for (final question in spec.questions) {
      final text = (question['question'] as String).replaceAll(
        RegExp(r'\s+'),
        '',
      );
      if (!seenQuestions.add(text) || existingQuestions.contains(text)) {
        errors.add('题干重复：${question['question']}');
      }
      if ((question['explanation'] as String).trim().length < 120) {
        errors.add('解析过短：${question['question']}');
      }
      final options = (question['options'] as List).cast<String>();
      if (options.length != 4 || options.toSet().length != 4) {
        errors.add('选项不合法：${question['question']}');
      }
    }
  }
  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('错误：$error');
    }
    exitCode = 1;
    return;
  }

  if (dryRun) {
    stdout.writeln('将新增 ${projectSpecs.length} 门项目课：');
    for (final spec in projectSpecs) {
      stdout.writeln('- ${spec.id}  ${spec.titleZh}');
    }
    return;
  }

  var nextOrder = 1;
  for (final lesson in lessons) {
    final order = (lesson['order'] as num?)?.toInt() ?? 0;
    if (order >= nextOrder) nextOrder = order + 1;
  }
  for (final spec in projectSpecs) {
    File('assets/content/${spec.id}.md')
        .writeAsStringSync(buildProjectMarkdown(spec), flush: true);
    lessons.add(<String, dynamic>{
      'id': spec.id,
      'title': <String, String>{'zh': spec.titleZh, 'en': spec.titleEn},
      'summary': <String, String>{'zh': spec.summaryZh, 'en': spec.summaryEn},
      'file': 'assets/content/${spec.id}.md',
      'minutes': spec.hours * 5,
      'keywords': spec.keywords,
      'difficulty': spec.difficulty,
      'order': nextOrder++,
      'quiz': <Map<String, dynamic>>[
        for (final question in spec.questions)
          <String, dynamic>{
            'question': question['question'],
            'options': question['options'],
            'answer': question['answer'],
            'explanation': question['explanation'],
          },
      ],
      'prerequisites': spec.prerequisites,
      'related': spec.related,
    });
  }
  manifest['content_updated_at'] = contentUpdatedAt;
  manifest['project_expansion_version'] = 1;
  File(manifestPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );
  stdout.writeln(
    '新增 ${projectSpecs.length} 门项目课，project_practice 现有 ${lessons.length} 门。',
  );
}

String buildProjectMarkdown(ProjectSpec spec) {
  final title = spec.titleZh;
  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln('> 项目定位：${spec.positioning}')
    ..writeln('> 建议投入：${spec.hours} 小时')
    ..writeln('> 难度：${spec.difficulty}')
    ..writeln()
    ..writeln('![$title 的架构与数据流](images/${spec.image})')
    ..writeln()
    ..writeln('## 项目背景')
    ..writeln()
    ..writeln(spec.background)
    ..writeln()
    ..writeln('## 学习目标')
    ..writeln();
  for (var index = 0; index < spec.goals.length; index++) {
    buffer.writeln('${index + 1}. ${spec.goals[index]}');
  }
  buffer
    ..writeln()
    ..writeln('## 需求与约束')
    ..writeln()
    ..writeln('| 维度 | 约束 |')
    ..writeln('| --- | --- |');
  for (final row in spec.constraints) {
    buffer.writeln('| ${row[0]} | ${row[1]} |');
  }
  buffer
    ..writeln()
    ..writeln('## 架构与数据流')
    ..writeln()
    ..writeln(spec.architecture)
    ..writeln()
    ..writeln('```text')
    ..writeln(spec.flow)
    ..writeln('```')
    ..writeln()
    ..writeln('## 实施步骤')
    ..writeln();
  for (var index = 0; index < spec.milestones.length; index++) {
    buffer
      ..writeln('### 里程碑 ${index + 1}：${spec.milestones[index][0]}')
      ..writeln()
      ..writeln(spec.milestones[index][1])
      ..writeln();
  }
  buffer
    ..writeln('## 验证命令与预期输出')
    ..writeln()
    ..writeln('在 $title 的仓库根目录执行以下命令，确认核心链路可以运行。')
    ..writeln()
    ..writeln('```bash')
    ..writeln(spec.command)
    ..writeln('```')
    ..writeln()
    ..writeln('**预期输出**：${spec.expected}')
    ..writeln()
    ..writeln('## 项目交付物')
    ..writeln();
  for (final item in spec.deliverables) {
    buffer.writeln('- $item');
  }
  buffer
    ..writeln()
    ..writeln('## 故障现场')
    ..writeln();
  for (var index = 0; index < spec.failures.length; index++) {
    final row = spec.failures[index];
    buffer
      ..writeln('### 现场 ${index + 1}：${row[0]}')
      ..writeln()
      ..writeln('**症状**：${row[0]}。')
      ..writeln()
      ..writeln('**定位**：${row[1]}。')
      ..writeln()
      ..writeln('**修复**：${row[2]}。')
      ..writeln();
  }
  buffer
    ..writeln('## 扩展任务')
    ..writeln();
  for (final item in spec.extensions) {
    buffer.writeln('- $item');
  }
  buffer
    ..writeln()
    ..writeln('## 复习与自测')
    ..writeln()
    ..writeln('1. 用一句话说明 $title 的核心输入、输出与失败边界。')
    ..writeln('2. 画出 ${spec.keywords.first} 的数据流，并标出至少一条失败路径。')
    ..writeln('3. 写出 $title 的下一条验证命令，并说明预期结果。')
    ..writeln()
    ..writeln('## 考点精讲');
  for (var index = 0; index < spec.questions.length; index++) {
    final question = spec.questions[index];
    final options = (question['options'] as List).cast<String>();
    final answer = question['answer'] as int;
    buffer
      ..writeln()
      ..writeln('### 考点 ${index + 1}：${question['question']}')
      ..writeln()
      ..writeln('- **正确判断**：${options[answer]}')
      ..writeln('- **判断依据**：${question['explanation']}');
  }
  buffer
    ..writeln()
    ..writeln('## English Overview')
    ..writeln()
    ..writeln(spec.summaryEn)
    ..writeln()
    ..writeln(
      'This project on "$title" turns the topic into a delivery workflow: define constraints, build a minimal end-to-end path, verify it with repeatable commands, and record failure handling.',
    )
    ..writeln();
  return buffer.toString();
}

const List<ProjectSpec> projectSpecs = <ProjectSpec>[
  ProjectSpec(
    id: 'project_network_capture_analysis',
    titleZh: '网络抓包与协议分析实战',
    titleEn: 'Network Capture and Protocol Analysis',
    summaryZh: '用 tcpdump 与 Wireshark 抓包，按 DNS、TCP、TLS、HTTP 阶段定位真实延迟。',
    summaryEn: 'Capture traffic and locate latency across DNS, TCP, TLS and HTTP stages.',
    difficulty: '进阶',
    order: 11,
    hours: 12,
    keywords: <String>['抓包', 'Wireshark', 'TCP', 'DNS', 'TLS', '延迟'],
    image: 'diagram_network_performance.webp',
    positioning: '把“接口慢”拆成“哪一跳慢”，用数据包而不是猜测作为证据。',
    background: '线上接口偶发变慢，应用日志只有一行总耗时，无法判断问题在 DNS、建连、TLS、服务处理还是响应传输。本实战搭一套可重复的本地链路，抓取 pcap 并按阶段建立时间线，最后给出可复现的根因结论。',
    goals: <String>[
      '能用 tcpdump 抓取指定主机与端口的流量，并用 tshark 过滤 HTTP、DNS 与重传。',
      '能把一次请求拆成 DNS、TCP 握手、TLS、首字节和最后字节五个阶段。',
      '能识别重传、RST、窗口耗尽与证书链错误对应的现象，并写出修复对比。',
    ],
    constraints: <List<String>>[
      <String>['功能', '覆盖 HTTP、HTTPS 与 DNS 三类请求'],
      <String>['性能', '抓包对目标服务吞吐的影响控制在 5% 以内'],
      <String>['可靠性', '能定位丢包、重传与连接重置'],
      <String>['安全', 'pcap 必须脱敏，不保存 Cookie、Token 与真实用户数据'],
    ],
    architecture: '客户端通过本地反向代理访问服务，抓包点部署在代理所在主机；每个阶段记录时间戳与连接四元组，再用请求 ID 把 pcap、代理日志与应用日志关联起来。',
    flow: 'client -> tcpdump -> nginx -> app -> database\n           |          |        |\n        DNS/TLS    retrans   slow query',
    milestones: <List<String>>[
      <String>[
        '搭一套可重复的链路',
        '用容器启动 nginx、一个慢接口与一个正常接口，固定并发、请求次数和客户端机器，保证每次实验的输入一致。',
      ],
      <String>[
        '抓包并建立过滤器',
        '抓取 8080 与 443 端口的流量，分别用 http、dns、tcp.flags.reset 和 tcp.analysis_retransmission 过滤，记录每条过滤命令的输出。',
      ],
      <String>[
        '按阶段做时间线并复测',
        '把 DNS、握手、TLS、首字节和最后字节的时间戳写进表格，找出占比最大的阶段；只改一个变量后复测同一组请求并对比 P95 与重传次数。',
      ],
    ],
    command: '''docker compose up -d
sudo tcpdump -i any -w capture.pcap 'port 8080 or port 443'
curl -o /dev/null -s -w 'dns=%{time_namelookup} connect=%{time_connect} tls=%{time_appconnect} ttfb=%{time_starttransfer} total=%{time_total}' https://localhost:8443/health
tshark -r capture.pcap -Y 'http.request or dns or tcp.analysis_retransmission' -T fields -e frame.time_relative -e ip.src -e tcp.stream -e http.request.uri''',
    expected: 'curl 输出中 dns 与 connect 均在 20ms 内，ttfb 约 180ms，total 约 220ms；tshark 结果中没有 tcp.analysis_retransmission 行，若出现该行则对应阶段耗时明显变长。',
    deliverables: <String>[
      'capture.pcap 与脱敏说明',
      'tshark 过滤命令清单',
      '五阶段耗时表',
      '根因结论、修复前后对比与复现脚本',
    ],
    failures: <List<String>>[
      <String>[
        '抓不到任何数据包',
        '抓包点选错网卡，或容器流量走了独立的网桥',
        '用 tcpdump -D 列出网卡，改抓 any 或 docker0，并确认端口映射方向',
      ],
      <String>[
        'HTTPS 只能看到密文',
        '没有配置 TLS 密钥日志或代理解密',
        '测试环境导出 SSLKEYLOGFILE 后让 Wireshark 解密；生产环境优先分析握手与证书链',
      ],
    ],
    extensions: <String>[
      '对比 DNS 缓存命中与未命中的首字节差异',
      '人为注入 1% 丢包，观察重传对 P95 的影响',
      '用 mtr 对比网络路径并把统计脚本接入 CI',
    ],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': '网络抓包分析慢请求时，第一步最合理的动作是什么？',
        'options': <String>[
          '先按 DNS、握手、TLS、首字节和响应阶段拆分时间线',
          '直接重启服务并观察是否恢复',
          '先把所有数据库索引重建一遍',
          '先升级服务器带宽',
        ],
        'answer': 0,
        'explanation': '抓包的价值在于把一次请求拆成可测量阶段，而不是先做高风险改动。先把 DNS、TCP 握手、TLS、首字节与响应时间分别落到时间线上，才能看到最大耗时段；重启、重建索引或升级带宽都可能改变多个变量，无法证明根因。只有时间线指向具体阶段后，后续修复和复测才有意义。',
      },
      <String, Object>{
        'question': 'Wireshark 过滤结果里出现 tcp.analysis_retransmission，最准确的解释是什么？',
        'options': <String>[
          '服务端一定已经宕机',
          '数据包被重传，链路上可能存在丢包或超时',
          'DNS 解析一定失败',
          'TLS 证书一定过期',
        ],
        'answer': 1,
        'explanation': 'tcp.analysis_retransmission 是 Wireshark 根据序列号与确认号推断出的重传标记，说明发送方没有在预期时间内收到确认。它可能来自链路丢包、拥塞、接收窗口不足或对端处理过慢，但不能单独证明服务宕机、DNS 失败或证书过期。要结合前后数据包、RTT 与重传次数继续定位。',
      },
      <String, Object>{
        'question': '为什么抓包文件在提交分析前必须脱敏？',
        'options': <String>[
          '文件太大，不脱敏无法用 Wireshark 打开',
          '不脱敏会影响 TCP 重传次数',
          'pcap 可能包含 Cookie、Token、账号与业务数据',
          '脱敏后才能看到 DNS 查询',
        ],
        'answer': 2,
        'explanation': 'pcap 保存的是原始流量，HTTP Cookie、Authorization 头、表单内容以及未加密协议里的业务数据都可能被完整记录。这些数据一旦进入仓库或工单系统就会形成泄露风险。脱敏应保留时间戳、包长、协议字段与错误码，删除或替换身份凭证和业务内容，确保结论可复核但不暴露真实用户。',
      },
      <String, Object>{
        'question': '评估接口长尾体验时，最应该重点看哪组指标？',
        'options': <String>[
          '请求总数与 CPU 使用率',
          '平均延迟与内存占用',
          '带宽峰值与磁盘写入',
          'P95 与 P99 分位延迟以及重传次数',
        ],
        'answer': 3,
        'explanation': '平均值会把少数极慢请求稀释掉，而长尾用户往往正是投诉来源。P95 与 P99 能暴露最慢的 5% 和 1% 请求，重传次数则解释其中一部分延迟是否来自网络。把分位延迟与抓包时间线、重传标记放在一起，才能判断优化是否真正改善了用户体验，而不是只让平均值更好看。',
      },
    ],
    prerequisites: <String>['http_basics', 'tcp_ip', 'dns'],
    related: <String>[
      'visual_http_timeline',
      'visual_tcp_handshake',
      'network_performance',
    ],
  ),
  ProjectSpec(
    id: 'project_database_tuning',
    titleZh: '数据库性能调优实战',
    titleEn: 'Database Performance Tuning',
    summaryZh: '从慢查询到执行计划，完成索引、锁与容量的一次系统调优。',
    summaryEn: 'Tune slow queries through execution plans, indexes, locks and capacity planning.',
    difficulty: '进阶',
    order: 12,
    hours: 14,
    keywords: <String>['慢查询', '执行计划', '索引', '锁', '事务', '容量'],
    image: 'btree_index.webp',
    positioning: '不靠“加索引”碰运气，用执行计划和压测数据做可回滚的调优。',
    background: '订单表在数据量增长后出现慢查询和锁等待，接口 P95 从 80ms 升到 900ms。需要先抓慢查询与执行计划，再区分扫描行数、回表、排序、锁等待和连接池耗尽等原因，每次只改一个变量并压测对比。',
    goals: <String>[
      '会读 EXPLAIN 的访问类型、扫描行数、回表与排序代价。',
      '能设计覆盖索引，并验证最左前缀、选择性与排序是否被索引满足。',
      '能定位锁等待与长事务，给出可回滚的调优和容量方案。',
    ],
    constraints: <List<String>>[
      <String>['功能', '保留原有查询结果与事务语义'],
      <String>['性能', '优化后 P95 小于 200ms'],
      <String>['数据量', '至少使用 100 万行样本数据'],
      <String>['安全', '变更可回滚且不在高峰期执行'],
    ],
    architecture: '压测客户端访问应用，应用经过连接池访问主库，再由只读副本承担部分查询；慢查询日志、performance_schema 与压测指标汇总到同一张时间线。',
    flow: 'client -> app -> pool -> primary -> btree index\n                    |\n              slow log / locks',
    milestones: <List<String>>[
      <String>[
        '建立可重复的基线',
        '导入 100 万行样本，记录查询 SQL、EXPLAIN、P95、扫描行数与锁等待，确保三次压测结果波动可解释。',
      ],
      <String>['一次只改一个变量', '为高频查询设计覆盖索引或改写 SQL，重复压测并比较执行计划；如果结果不稳定，先排查缓存与连接池。'],
      <String>['处理锁与容量', '定位长事务与锁等待，调整事务边界或隔离级别，最后给出索引、归档与容量扩展的回滚方案。'],
    ],
    command: '''mysql -h 127.0.0.1 -u demo -p demo < seed.sql
mysql -h 127.0.0.1 -u demo -p demo -e "EXPLAIN ANALYZE SELECT id, user_id, amount FROM orders WHERE user_id = 42 ORDER BY created_at DESC LIMIT 20"
python benchmark.py --query orders_by_user --concurrency 32 --duration 120''',
    expected: 'EXPLAIN ANALYZE 显示使用 idx_orders_user_created，扫描行数从 18 万降到 21，P95 从 900ms 降到 120ms，锁等待次数为 0。',
    deliverables: <String>[
      '基线 SQL 与执行计划',
      '索引设计与回滚脚本',
      '压测前后对比报告',
      '锁等待清单与容量上线检查表',
    ],
    failures: <List<String>>[
      <String>[
        '加了索引仍然慢',
        '查询条件顺序不满足最左前缀，或排序字段没有被索引覆盖',
        '用 EXPLAIN 验证 key 与 key_len，再调整联合索引顺序或改成覆盖索引',
      ],
      <String>['压测结果波动很大', '连接池、缓存或机器负载混入了额外变量', '固定并发与数据量，清理缓存后至少重复三轮并比较 P95'],
    ],
    extensions: <String>[
      '对比覆盖索引与回表读的代价',
      '模拟长事务观察锁等待传播',
      '用分区或归档处理冷数据并把慢查询门禁接入 CI',
    ],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': '联合索引 (user_id, created_at) 对哪个查询最有效？',
        'options': <String>[
          'WHERE user_id = ? ORDER BY created_at DESC',
          'WHERE created_at = ? ORDER BY user_id',
          'WHERE amount = ? ORDER BY created_at',
          '只查 created_at 的全表范围扫描',
        ],
        'answer': 0,
        'explanation': '联合索引按 user_id 再按 created_at 排序，等值条件 user_id = ? 能直接定位到一段连续区间，随后 created_at DESC 可以顺着索引顺序读取，避免额外排序。反过来只按 created_at 过滤时，前导列 user_id 没有等值条件，索引通常无法高效定位。设计联合索引要先看等值条件与排序列，而不是只看字段是否出现在 WHERE 中。',
      },
      <String, Object>{
        'question': 'EXPLAIN 中 rows 很大而 filtered 很小，最可能说明什么？',
        'options': <String>[
          '磁盘一定损坏',
          '扫描了很多行才过滤出少量结果，索引选择性差或没有用上合适索引',
          '事务一定会回滚',
          '连接池一定已经耗尽',
        ],
        'answer': 1,
        'explanation': 'rows 是优化器估计要扫描的行数，filtered 是过滤后剩余比例。rows 很大而 filtered 很小，意味着数据库读了大量数据才筛出目标行，常见原因是缺少合适索引、联合索引顺序不对或条件无法被索引使用。下一步应查看 key、key_len 与访问类型，而不是先怀疑磁盘或事务。',
      },
      <String, Object>{
        'question': '长事务最直接的危害是什么？',
        'options': <String>[
          '自动删除历史数据',
          '让索引变成只读',
          '长时间持有锁与快照，阻塞其他事务并放大回滚成本',
          '把 InnoDB 自动切换成 MyISAM',
        ],
        'answer': 2,
        'explanation': '长事务会持续持有行锁、间隙锁和一致性快照，其他事务可能排队等待，更新与清理也会被拖慢。事务越久，undo 日志保留越多，回滚和崩溃恢复的成本越高。调优时应先找出长事务，缩短事务边界，把网络调用、文件操作和人工确认移出事务，再考虑隔离级别与锁策略。',
      },
      <String, Object>{
        'question': '为什么数据库调优要求每次只改一个变量？',
        'options': <String>[
          '可以少写 SQL',
          '让索引自动生效',
          '避免连接池扩容',
          '只有控制变量才能把性能变化归因到具体改动并安全回滚',
        ],
        'answer': 3,
        'explanation': '同时改索引、SQL、连接池和机器配置，即使指标变好也无法判断哪一项真正起作用，指标变差时更难回滚。一次只改一个变量，配合固定数据量、并发与缓存状态，才能把 P95、扫描行数和锁等待的变化归因到具体改动。这个原则和 A/B 实验一致，是性能调优可复现的基础。',
      },
    ],
    prerequisites: <String>['sql_basics', 'index', 'transaction'],
    related: <String>['db_query_optimization', 'mysql_lock_mvcc', 'db_ops'],
  ),
  ProjectSpec(
    id: 'project_concurrency_runtime',
    titleZh: '操作系统与并发实战',
    titleEn: 'Operating Systems and Concurrency',
    summaryZh: '用线程池、锁竞争与性能剖析定位并发生命周期问题。',
    summaryEn: 'Diagnose thread pools, lock contention, context switches and concurrency lifecycles.',
    difficulty: '高级',
    order: 13,
    hours: 16,
    keywords: <String>['线程池', '锁竞争', '上下文切换', '内存模型', '协程', '性能剖析'],
    image: 'concurrency_schedule.webp',
    positioning: '从“偶发卡顿”到“可复现的并发时间线”，用调度、锁与内存指标解释结果。',
    background: '一个批量任务在单机运行正常，上并发后偶发超时、CPU 利用率不高但吞吐上不去。需要区分线程池排队、锁竞争、伪共享、上下文切换、内存可见性与 GC 暂停，并用可控实验验证。',
    goals: <String>[
      '能画出任务从提交、排队、执行到完成的并发时间线。',
      '能用压测与采样定位锁竞争、上下文切换和内存可见性问题。',
      '能比较线程、协程与事件循环在 CPU 密集和 I/O 密集场景下的边界。',
    ],
    constraints: <List<String>>[
      <String>['功能', '保留任务结果、取消与异常传播语义'],
      <String>['性能', '吞吐提升 2 倍，或 P95 降低 50%'],
      <String>['可靠性', '能处理取消、超时、重复提交与下游失败'],
      <String>['安全', '共享状态必须有明确的同步或所有权策略'],
    ],
    architecture:
        '任务生产者把任务放入有界队列，工作线程池消费任务并更新共享计数器与下游 I/O；采样器记录线程状态、锁等待、上下文切换与 GC 暂停。',
    flow: 'producer -> bounded queue -> worker pool -> shared state\n                         |\n                    lock / sampling',
    milestones: <List<String>>[
      <String>['建立串行基线', '记录任务数、CPU、P95、上下文切换与 GC 暂停，确认单线程版本的吞吐上限和失败率。'],
      <String>['找到并发拐点', '逐步增加 worker 数量，观察吞吐、排队时长、锁等待与上下文切换；找到收益开始下降的那个点。'],
      <String>['只改一个并发策略', '把锁粒度缩小、改成无锁结构或换成协程或事件循环，复测并验证取消、超时与异常路径。'],
    ],
    command: '''python bench.py --mode serial --tasks 20000
python bench.py --mode threadpool --workers 4 --tasks 20000
python -m cProfile -o profile.out bench.py --mode threadpool --workers 4 --tasks 20000
python -c "import pstats; pstats.Stats('profile.out').sort_stats('cumtime').print_stats(15)"''',
    expected: '串行 P95 约 480ms；4 个 worker 时吞吐提升接近 3 倍；worker 继续加到 32 后吞吐不再上升，锁等待与上下文切换明显增加，剖析结果的热点集中在共享计数器的临界区。',
    deliverables: <String>[
      '并发时间线与任务状态图',
      '串行到并发的压测矩阵',
      '采样或火焰图报告',
      '锁、取消与异常传播设计说明',
    ],
    failures: <List<String>>[
      <String>[
        '并发度越高反而越慢',
        '锁竞争或线程切换成本超过了并行收益',
        '缩小临界区、分批聚合或改用无锁结构与 channel，再重新测并发拐点',
      ],
      <String>[
        '结果偶发不一致',
        '共享状态缺少同步，或内存可见性没有保证',
        '用原子操作、锁或 channel 明确所有权，并用 race detector 或压力测试复现',
      ],
    ],
    extensions: <String>[
      '用 ThreadSanitizer 或 race detector 复现数据竞争',
      '对比线程池与协程在 I/O 密集任务下的吞吐和内存',
      '加入取消与超时传播测试，验证下游失败不会拖垮整个池',
    ],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': 'CPU 利用率不高但吞吐上不去，最可能的原因是什么？',
        'options': <String>[
          '线程在锁、队列或 I/O 上排队等待',
          'CPU 核心数量一定不够',
          '内存容量一定太小',
          '磁盘一定已经损坏',
        ],
        'answer': 0,
        'explanation': 'CPU 利用率不高说明处理器并不是主要瓶颈，任务更可能卡在锁、队列、I/O 或调度等待上。只看 CPU 会误判为“机器没跑满”，实际吞吐被协调成本限制。下一步应采样线程状态、锁等待与上下文切换，找到等待最长的阶段，再决定缩小临界区、增加 I/O 并发还是调整队列。',
      },
      <String, Object>{
        'question': '线程池使用无界队列的主要风险是什么？',
        'options': <String>[
          '线程数会自动减少',
          '任务无限堆积，延迟恶化并可能耗尽内存',
          '队列会自动提高 CPU 频率',
          '异常会被自动忽略',
        ],
        'answer': 1,
        'explanation': '无界队列会让提交速度长期高于消费速度时任务不断堆积，表面上看不到拒绝，实际延迟持续上升，最终可能耗尽内存。有界队列配合拒绝策略、背压或降级能更早暴露过载。定位时要同时看排队长度、等待时间和任务完成速率，而不是只看线程池是否还在工作。容量上限必须结合吞吐与内存预算计算。',
      },
      <String, Object>{
        'question': '为什么并发度不是越高越好？',
        'options': <String>[
          '线程不能被操作系统调度',
          '锁会自动升级成分布式锁',
          '上下文切换、锁竞争与协调成本会超过并行收益',
          '协程不能与线程同时使用',
        ],
        'answer': 2,
        'explanation': '增加并发度能提升并行处理能力，但每个线程或协程都要占用栈、调度时间和缓存空间，共享资源的锁竞争也会加剧。当协调成本超过并行收益时，吞吐不再上升，P95 反而变差。正确做法是通过压测找到拐点，再结合任务类型选择线程、协程或事件循环，而不是盲目把并发数调大。',
      },
      <String, Object>{
        'question': '验证内存可见性与数据竞争，哪种方式最有效？',
        'options': <String>[
          '只跑一次功能测试',
          '只看 CPU 使用率',
          '只检查代码注释',
          '使用 race detector 或 ThreadSanitizer 并配合压力测试',
        ],
        'answer': 3,
        'explanation': '数据竞争和内存可见性问题往往只在特定调度顺序下出现，单次功能测试很难稳定复现。race detector 或 ThreadSanitizer 会在运行时记录内存访问与同步关系，能在问题造成业务错误前报告竞争；再配合高并发压力测试提高触发概率。修复后要保留回归测试，防止后续改动重新引入。',
      },
    ],
    prerequisites: <String>[
      'process_thread',
      'scheduling',
      'os_synchronization',
    ],
    related: <String>[
      'visual_concurrency_schedule',
      'deadlock',
      'visual_event_loop',
    ],
  ),
  ProjectSpec(
    id: 'project_security_lab',
    titleZh: '安全攻防与防御实战',
    titleEn: 'Security Attack and Defense Lab',
    summaryZh: '从越权、注入到供应链，完成一次可审计的安全加固。',
    summaryEn: 'Harden an application against authorization, injection and supply-chain risks with auditable evidence.',
    difficulty: '进阶',
    order: 14,
    hours: 14,
    keywords: <String>['OWASP', '越权', '注入', '供应链', '审计', '最小权限'],
    image: 'diagram_net_web_security.webp',
    positioning: '不做“扫一遍工具就结束”的安全演练，围绕资产、威胁、验证和修复闭环。',
    background:
        '一个内部管理系统需要在上线前做安全加固。练习从威胁建模开始，逐步验证越权、注入、会话、依赖与配置问题，并为每个发现补自动化用例和审计记录。',
    goals: <String>[
      '能用资产、信任边界和 STRIDE 建立可执行的威胁模型。',
      '能复现并修复越权、注入、会话固定与敏感信息泄露。',
      '能建立依赖、密钥与最小权限的持续检查。',
    ],
    constraints: <List<String>>[
      <String>['功能', '保留正常业务流程与角色矩阵'],
      <String>['安全', '高风险问题必须修复并留下回归用例'],
      <String>['可靠性', '安全修复不能引入拒绝服务或不可用'],
      <String>['合规', '审计记录不保存真实隐私数据与明文凭证'],
    ],
    architecture: '客户端经过网关鉴权访问应用服务，应用访问数据库与对象存储；所有敏感操作写入审计日志，依赖与镜像进入供应链扫描。',
    flow: 'client -> gateway(authz) -> app(validation) -> database\n                      |\n              audit + dependency scan',
    milestones: <List<String>>[
      <String>['资产与威胁建模', '列出入口、数据、角色与信任边界，按 STRIDE 标注威胁、现有控制和验证方式。'],
      <String>['复现与修复', '依次验证水平与垂直越权、注入、会话固定、敏感信息泄露和依赖漏洞；每个问题只改一处并补回归用例。'],
      <String>['持续防御', '把依赖扫描、密钥检查、最小权限与审计告警接入 CI 或发布流程，并记录例外与复核时间。'],
    ],
    command: '''docker compose up -d
python security_checks.py --base-url http://localhost:8080 --cases idor,injection,session
pip-audit -r requirements.txt''',
    expected: '安全脚本输出 3 个已修复用例与 0 个未授权访问；pip-audit 无高危依赖；审计日志能记录用户、资源、动作与结果，且不包含明文口令或 Token。',
    deliverables: <String>[
      '资产与威胁模型',
      '漏洞复现与修复记录',
      '自动化安全回归用例',
      '依赖、密钥与最小权限检查配置',
    ],
    failures: <List<String>>[
      <String>[
        '工具报漏洞但无法复现',
        '版本、配置或数据与扫描假设不一致',
        '固定镜像与依赖版本，写最小复现，再决定是修复还是记录误报',
      ],
      <String>['修复后正常流程被阻断', '权限校验过宽，或输入校验误伤合法数据', '用角色矩阵和边界样本回归，默认拒绝并保留明确白名单'],
    ],
    extensions: <String>['加入模糊测试生成畸形输入', '用密钥扫描阻止凭证入库', '模拟供应链投毒并验证隔离与回滚'],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': '水平越权与垂直越权的区别是什么？',
        'options': <String>[
          '水平越权访问同级他人资源，垂直越权获取更高权限功能',
          '水平越权只发生在数据库，垂直越权只发生在网络层',
          '水平越权无法修复，垂直越权可以忽略',
          '两者完全相同，只是命名不同',
        ],
        'answer': 0,
        'explanation': '水平越权是同一角色用户访问了别人的资源，例如把订单 ID 换成他人的订单；垂直越权是普通用户调用了管理员接口或获得了更高权限功能。两者的共同点是服务端没有对“当前用户是否有权操作这个具体资源”做校验，而不是界面隐藏得不够。修复时要在服务端按资源归属和角色双重校验权限。',
      },
      <String, Object>{
        'question': '为什么只在界面隐藏管理按钮不能防止越权？',
        'options': <String>[
          '按钮隐藏后页面会变慢',
          '攻击者可以直接调用后端接口，服务端仍然必须校验权限',
          '浏览器会自动恢复按钮',
          '隐藏按钮会影响数据库索引',
        ],
        'answer': 1,
        'explanation': '前端隐藏按钮只影响正常用户的可见操作，不能阻止攻击者用脚本、代理或修改请求直接调用后端接口。权限判断必须放在服务端每个敏感入口，并结合角色、资源归属与操作类型校验。前端可以做体验优化，但不能作为安全边界；否则一旦接口地址泄露，未授权用户就能执行管理操作。',
      },
      <String, Object>{
        'question': '治理依赖漏洞的第一步是什么？',
        'options': <String>[
          '禁用所有第三方依赖',
          '直接把所有依赖升级到最新版',
          '建立 SBOM 或依赖清单并对漏洞分级',
          '只在发布当天扫描一次',
        ],
        'answer': 2,
        'explanation': '没有依赖清单就无法知道系统里到底有哪些组件、版本和传递依赖。第一步是建立 SBOM 或依赖清单，再结合漏洞库按可利用性、暴露面和业务影响分级。直接升级到最新版可能引入破坏性变更，禁用全部依赖也不现实。分级后先修高危且可被利用的组件，并记录例外与复核时间。',
      },
      <String, Object>{
        'question': '最小权限原则的核心是什么？',
        'options': <String>[
          '给每个用户管理员权限以便排障',
          '只隐藏敏感页面',
          '只在生产环境启用权限校验',
          '只授予完成任务所需的最小权限，并定期复核',
        ],
        'answer': 3,
        'explanation': '最小权限要求身份、服务和进程只拥有完成当前任务所需的权限范围，并在任务结束后回收。这样可以缩小凭证泄露、配置错误和横向移动造成的破坏面。它不是一次性配置，而是需要角色矩阵、定期复核、临时授权和审计记录共同维护；生产与测试环境都应遵守，而不是只在某一套环境启用。',
      },
    ],
    prerequisites: <String>[
      'security_threat_model',
      'security_owasp_top10',
      'security_auth_session',
    ],
    related: <String>[
      'security_supply_chain',
      'security_secure_coding',
      'pentest_basics',
    ],
  ),
  ProjectSpec(
    id: 'project_algorithm_engineering',
    titleZh: '算法工程化与性能验证实战',
    titleEn: 'Algorithm Engineering and Performance Verification',
    summaryZh: '从问题建模到基准测试，把搜索、排序与动态规划算法做成可验证、可回归的工程模块。',
    summaryEn: 'Turn search, sorting and dynamic programming into a verifiable engineering module.',
    difficulty: '进阶',
    order: 12,
    hours: 14,
    keywords: <String>['算法工程', '基准测试', '复杂度', '二分查找', '动态规划', '性能回归'],
    image: 'diagram_algo_sorting_family.webp',
    positioning: '不只写出能通过的答案，还要证明它在边界输入、数据规模和资源约束下仍然可靠。',
    background: '很多算法练习只在样例上正确，一旦输入变大、数据分布改变或语言运行时不同，耗时和内存就失控。本实战选择一个真实日志分析场景，把需求拆成检索、聚合和路径规划三个子问题，分别实现二分、排序与动态规划方案，并建立数据集、基准测试和性能回归门禁。',
    goals: <String>[
      '能把业务问题转换成明确的输入、输出、约束和复杂度目标，而不是直接开始写循环。',
      '能用确定性数据集比较朴素解法与优化解法，记录正确性、时间、内存和尾延迟。',
      '能为边界、极值和随机数据建立回归测试，并在性能回退时给出可复现实验。',
    ],
    constraints: <List<String>>[
      <String>['正确性', '至少覆盖空输入、单元素、重复值、极值和随机数据五类用例'],
      <String>['性能', '十万条记录的目标查询 P95 小于 50ms，内存峰值小于 128MB'],
      <String>['可复现', '固定随机种子、数据版本、编译参数和运行环境'],
      <String>['可维护', '算法模块不依赖界面与数据库，输入输出使用纯函数或明确接口'],
    ],
    architecture: '数据生成器负责产出带版本号的数据集，算法模块只接收内存中的结构化记录；基准程序记录预热、重复次数和分位数，测试套件比较结果哈希与性能阈值，最后把报告写入持续集成产物。',
    flow: 'seed + config -> dataset -> algorithm -> result hash\n                     |            |\n                  baseline -> benchmark -> regression gate',
    milestones: <List<String>>[
      <String>[
        '定义接口与数据契约',
        '先写输入输出结构、错误返回和复杂度预算，再实现最朴素的正确解法作为基线；用小型手写样例验证契约，避免一开始就优化细节。',
      ],
      <String>[
        '实现三种优化路径',
        '用二分查找解决有序区间定位，用稳定排序处理聚合分组，用动态规划计算最小代价路径；每个实现都附复杂度推导和适用边界。',
      ],
      <String>[
        '建立基准与回归门禁',
        '生成小、中、大三级固定数据集，分别跑正确性测试、微基准与端到端基准；比较结果哈希、P50、P95 和峰值内存，超过阈值就让流水线失败。',
      ],
    ],
    command: '''dart pub get
dart test test/algorithm_regression_test.dart
dart run benchmark/run_benchmark.dart --dataset=large --repeat=7
python tools/compare_baseline.py benchmark/current.json benchmark/baseline.json''',
    expected: '回归测试全部通过；大型数据集三次预热后七次采样，结果哈希与基线一致，P95 小于 50ms，峰值内存小于 128MB；对比脚本输出 0 个明显回退。',
    deliverables: <String>[
      '问题定义与复杂度预算',
      '数据集生成器和版本说明',
      '正确性测试与边界用例',
      '基准程序、基线报告和回归门禁',
    ],
    failures: <List<String>>[
      <String>[
        '小数据正确但大数据超时',
        '算法复杂度或数据结构选择不适合目标规模，也可能存在重复扫描',
        '先用计数器和剖析定位热点，再比较哈希表、堆或排序方案，确认复杂度下降后复测',
      ],
      <String>[
        '基准结果每次波动很大',
        '预热不足、垃圾回收、机器负载或数据顺序不一致',
        '固定数据版本与随机种子，增加预热和采样次数，报告分布而非单次耗时，并隔离后台任务',
      ],
      <String>[
        '优化后边界答案错误',
        '新实现改变了重复值、空集或溢出时的语义',
        '把边界样例加入差分测试，用朴素实现作为随机对拍参考，直到结果哈希完全一致',
      ],
    ],
    extensions: <String>[
      '加入内存剖析并用流式算法降低峰值',
      '比较多种语言实现的常数开销',
      '用属性测试生成随机输入并做朴素对拍',
    ],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': '为什么要先实现朴素解法再优化？',
        'options': <String>[
          '用它建立正确性参考并测量真实瓶颈，避免盲目优化',
          '因为朴素解法一定更省内存',
          '为了增加代码行数',
          '只有朴素解法能通过边界测试',
        ],
        'answer': 0,
        'explanation': '朴素解法通常更容易理解和验证，可以作为随机对拍与边界测试的参考答案。它还能提供真实的基线数据，帮助判断瓶颈来自复杂度、常数开销还是输入输出。没有基线就优化，很容易在错误的问题上花费时间，也无法证明新实现没有改变语义。对拍时应保存失败输入，修复后自动复测。',
      },
      <String, Object>{
        'question': '算法基准测试为什么需要预热阶段？',
        'options': <String>[
          '让测试文件变大',
          '让即时编译、缓存和运行时状态进入稳定阶段，减少冷启动干扰',
          '避免编写单元测试',
          '保证所有输入都变得有序',
        ],
        'answer': 1,
        'explanation': '即时编译语言、虚拟机和硬件缓存都存在冷启动效应，第一次运行往往明显慢于稳定状态。预热后再采样，能让结果更接近持续负载下的真实表现。除此之外还要固定数据集、随机种子、编译参数和机器环境，并报告分位数而不是只报一次平均耗时。预热次数也要随运行时与负载规模调整。',
      },
      <String, Object>{
        'question': '性能回归门禁适合使用哪种判定方式？',
        'options': <String>[
          '只比较开发者的主观感受',
          '只看一次运行的最快值',
          '记录基线与分位数，同时设置允许波动范围，超过阈值时失败',
          '只要功能测试通过就不需要性能检查',
        ],
        'answer': 2,
        'explanation': '性能数据天然有波动，单次最快值会掩盖尾延迟，主观感受也无法稳定复现。更可靠的方法是保存同一环境下的基线分布，比较 P50、P95、内存和吞吐，并给出合理的波动范围。超过阈值时流水线失败并保留报告，才能让性能问题在合并前被发现。门禁阈值应在稳定环境中定期校准。',
      },
      <String, Object>{
        'question': '差分测试在算法工程中的主要价值是什么？',
        'options': <String>[
          '替代所有复杂度分析',
          '让程序自动选择最快的语言',
          '只在生产环境运行',
          '用可信实现与新实现处理同一批随机输入，快速发现语义差异',
        ],
        'answer': 3,
        'explanation': '差分测试把朴素实现或成熟参考实现作为可信答案，用大量随机、边界和特殊分布输入同时驱动两个版本，再比较输出。它能发现人工样例覆盖不到的语义偏差，例如重复值、溢出和并列排序规则。它不能替代复杂度分析，但能显著提高正确性信心。随机种子和失败样本必须进入回归集。',
      },
    ],
    prerequisites: <String>['time_complexity', 'binary_search', 'sorting'],
    related: <String>['dynamic_programming', 'graph', 'hash_table'],
  ),
  ProjectSpec(
    id: 'project_devops_pipeline',
    titleZh: 'DevOps CI/CD 流水线实战',
    titleEn: 'DevOps CI/CD Delivery Pipeline',
    summaryZh: '用容器、持续集成、渐进发布与可观测性，交付一条可回滚、可审计的自动发布流水线。',
    summaryEn: 'Build an auditable and reversible delivery pipeline with containers and progressive rollout.',
    difficulty: '进阶',
    order: 13,
    hours: 16,
    keywords: <String>[
      'DevOps',
      'CI/CD',
      'Docker',
      'Kubernetes',
      '渐进发布',
      '可观测性',
    ],
    image: 'diagram_ci_pipeline.webp',
    positioning: '把构建、测试、制品、部署、验证和回滚串成一条可重复执行的流水线，而不是依赖人工步骤。',
    background: '一个服务虽然能本地运行，但发布时仍靠手工打镜像、改配置和登录服务器，导致版本不可追溯、失败难回滚、环境差异频发。本实战从零搭建流水线：提交代码后自动检查与测试，生成不可变制品，部署到预发布环境做冒烟验证，再通过金丝雀策略进入生产，并保留审计与一键回滚能力。',
    goals: <String>[
      '能把构建、测试、制品签名、部署与验证拆成独立且可重试的阶段。',
      '能用同一份不可变镜像贯穿环境，配置通过环境变量或密钥系统注入。',
      '能用指标、日志和追踪判断发布健康度，并在异常时自动停止或回滚。',
    ],
    constraints: <List<String>>[
      <String>['可追溯', '每次发布都能关联提交、流水线、镜像摘要、配置版本与审批记录'],
      <String>['可回滚', '任意一次生产发布都能在五分钟内回到上一个健康版本'],
      <String>['安全', '凭证不进入仓库与镜像，流水线使用最小权限身份'],
      <String>['稳定', '相同提交重复执行得到相同制品摘要，部署脚本具备幂等性'],
    ],
    architecture: '代码仓库触发流水线，检查、单元测试和镜像构建在隔离执行器中完成；镜像按内容摘要推送到制品库，部署控制器从声明式清单读取版本与策略，指标系统根据错误率和延迟决定继续、暂停或回滚。',
    flow: 'commit -> lint/test -> image -> registry -> staging\n                                      |\n                           smoke -> canary -> prod\n                                      |\n                           metrics -> rollback/audit',
    milestones: <List<String>>[
      <String>[
        '把构建做成不可变制品',
        '固定基础镜像和依赖锁文件，先跑静态检查与测试，再生成带提交号和内容摘要的镜像；禁止在不同环境重新构建同名制品。',
      ],
      <String>[
        '做环境晋级与冒烟验证',
        '预发布环境使用与生产一致的清单和启动方式，部署后检查健康接口、关键依赖和数据库迁移状态，任何一步失败都停止晋级。',
      ],
      <String>[
        '接入金丝雀、观测和回滚',
        '先让少量流量进入新版本，比较错误率、P95 延迟和资源使用；达到阈值再扩大流量，异常时自动回滚并生成包含指标快照的事件记录。',
      ],
    ],
    command: '''docker build -t app:local .
docker run --rm app:local ./scripts/smoke-test.sh
docker scout quickview app:local
git rev-parse HEAD > revision.txt
kubectl apply --dry-run=server -f deploy/staging
./scripts/verify-release.sh staging 60''',
    expected:
        '构建成功且静态检查和测试全过；镜像扫描没有高危问题；预发布健康检查在 60 秒内通过；发布清单与当前提交关联，重复部署不会创建多余资源。',
    deliverables: <String>[
      '流水线配置与阶段说明',
      '不可变镜像与制品命名规则',
      '预发布冒烟和健康检查脚本',
      '金丝雀指标、回滚脚本与发布记录',
    ],
    failures: <List<String>>[
      <String>[
        '本地成功但流水线构建失败',
        '工具版本、依赖缓存、环境变量或文件权限与本地不同',
        '固定工具链版本，清理缓存后在新执行器复现，并把缺失依赖写入构建清单',
      ],
      <String>[
        '新版本部署后健康检查通过但用户报错',
        '探针只检查进程存活，没有覆盖关键依赖与真实请求',
        '增加端到端冒烟和关键业务指标，按错误率与延迟决定是否继续放大流量',
      ],
      <String>[
        '回滚后仍然异常',
        '数据库迁移或外部配置不可逆，旧镜像与当前结构不兼容',
        '采用向前兼容迁移，回滚应用与配置版本，并验证旧版本读写路径；必要时执行独立恢复预案',
      ],
    ],
    extensions: <String>['加入多环境审批与变更窗口', '用策略即代码检查部署清单', '接入追踪数据定位跨服务发布回归'],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': '为什么同一提交应该只构建一次并在各环境复用？',
        'options': <String>[
          '保证各处使用完全相同的制品，避免环境差异和重复构建引入变量',
          '因为重新构建会消耗所有磁盘',
          '为了减少提交数量',
          '只有预发布环境需要镜像',
        ],
        'answer': 0,
        'explanation': '一次构建、多次晋级能保证测试过的制品与生产运行的制品具有相同内容摘要。若每个环境重新构建，即使代码相同，也可能因为依赖解析、构建时间或基础镜像变化产生不同结果。复用不可变制品可以缩小变量范围，让测试结论、签名和审计记录真正对应生产版本。制品摘要应写入发布记录以便核对。',
      },
      <String, Object>{
        'question': '金丝雀发布最关键的判断依据是什么？',
        'options': <String>[
          '开发者的发布速度',
          '新版本与稳定版本的错误率、延迟和业务指标对比',
          '镜像文件大小',
          '代码仓库的提交数量',
        ],
        'answer': 1,
        'explanation': '金丝雀发布的核心是把少量流量导向新版本，并用可比较的指标判断它是否健康。除了技术错误率和 P95 延迟，还应观察下单、登录等业务成功率以及资源饱和度。只有指标达到预设阈值才扩大流量；若持续恶化则停止发布并回滚，不能仅凭进程存活判断成功。回滚动作也要提前演练并记录结果。',
      },
      <String, Object>{
        'question': '流水线中的密钥应该如何处理？',
        'options': <String>[
          '写进仓库方便审计',
          '打进镜像以加快启动',
          '存入专用密钥系统，按最小权限临时注入，并限制日志输出',
          '放在公共聊天群中供团队共享',
        ],
        'answer': 2,
        'explanation': '密钥一旦进入仓库或镜像层，就会随着历史记录和制品分发扩散，很难彻底删除。正确做法是使用专用密钥管理系统或执行器提供的短期身份，按任务最小权限临时注入，同时对日志做脱敏。还应定期轮换凭证、记录使用审计，并将泄露检测接入提交流程。临时凭证到期后必须自动失效。',
      },
      <String, Object>{
        'question': '发布流水线为什么需要可重复执行？',
        'options': <String>[
          '可以让每次结果都不同',
          '可以跳过所有测试',
          '只适用于人工发布',
          '失败重试或重复部署时不会产生重复资源和不可预测状态',
        ],
        'answer': 3,
        'explanation': '网络抖动、执行器重启和人工重试都会让同一阶段执行多次，因此部署与迁移步骤必须具有幂等性。脚本应检查当前状态并只做必要变更，资源使用稳定命名，迁移具备重复执行保护。可重复执行能减少排障成本，也让回滚、恢复和灾备演练更可控。失败重试次数和超时边界应明确配置。',
      },
    ],
    prerequisites: <String>['ci_cd', 'docker', 'kubernetes'],
    related: <String>['terraform', 'gitops_argocd', 'observability'],
  ),
  ProjectSpec(
    id: 'project_mobile_offline_app',
    titleZh: '移动端离线优先 App 实战',
    titleEn: 'Offline-First Mobile App',
    summaryZh: '用 Flutter 构建离线可用、冲突可合并、弱网可恢复的移动应用，并完成性能与发布验证。',
    summaryEn: 'Build an offline-first Flutter app with conflict handling, weak-network recovery and release checks.',
    difficulty: '进阶',
    order: 14,
    hours: 16,
    keywords: <String>['Flutter', '离线优先', '本地数据库', '同步', '冲突处理', '移动性能'],
    image: 'category_mobile_performance.webp',
    positioning: '把本地数据视为首要真相来源，让用户在无网、弱网和进程被终止后仍能继续工作。',
    background: '移动端网络不稳定，系统也会随时回收进程。如果每次打开都依赖接口，用户就会看到空白页、重复提交或丢失草稿。本实战实现一个离线任务应用：本地数据库承担读写与队列，界面只订阅本地状态；后台同步负责重试和冲突合并，最后验证冷启动、滚动性能、断网恢复与发布包完整性。',
    goals: <String>[
      '能设计本地表结构、待同步队列和稳定的客户端生成标识。',
      '能处理重试、幂等、删除、冲突与进程中断，保证同一操作不会重复生效。',
      '能测量冷启动、帧耗时、内存和包体积，并把关键指标纳入发布检查。',
    ],
    constraints: <List<String>>[
      <String>['离线', '除首次初始化外，核心查看、创建和编辑流程无网可用'],
      <String>['一致性', '同一操作重复提交不产生重复数据，冲突有确定的合并规则'],
      <String>['性能', '冷启动首帧小于 1.5 秒，常用列表滚动保持流畅'],
      <String>['隐私', '本地敏感字段加密，日志不记录令牌和用户正文'],
    ],
    architecture: '界面层只调用仓库接口，仓库同时写入本地数据库和同步队列；同步器在具备网络时按批次上传，使用操作标识保证幂等，并把服务端版本与本地版本合并后回写；诊断模块记录同步状态和性能采样。',
    flow: 'UI -> repository -> local db + outbox\n                         |\n                  sync worker -> API\n                         |\n                  merge/retry -> UI state',
    milestones: <List<String>>[
      <String>[
        '先把本地主链路跑通',
        '设计任务、标签和待同步操作表，使用客户端标识创建记录；在飞行模式下完成增删改查，并确认重启应用后数据仍存在。',
      ],
      <String>[
        '实现可靠同步',
        '为每个操作生成唯一标识和重试次数，上传成功后按条件删除队列项；模拟超时、重复响应和进程终止，验证服务端最终只得到一次业务效果。',
      ],
      <String>[
        '处理冲突与性能验收',
        '给记录增加版本或更新时间，定义字段级合并规则；用性能工具检查冷启动、滚动帧、内存和包体积，异常时保留采样报告再优化。',
      ],
    ],
    command: '''flutter pub get
flutter analyze
flutter test
flutter test integration_test/offline_sync_test.dart
flutter build apk --release --target-platform android-arm,android-arm64''',
    expected: '静态检查与测试全部通过；集成测试在断网、恢复网络和重复提交场景下保持数据一致；发布包成功生成，冷启动和列表滚动指标在预算内，日志中没有敏感字段。',
    deliverables: <String>[
      '离线数据模型与仓库接口',
      '待同步队列和冲突规则',
      '断网、重试与进程中断集成测试',
      '性能采样、发布包和体积报告',
    ],
    failures: <List<String>>[
      <String>[
        '恢复网络后出现重复任务',
        '请求已成功但响应丢失，客户端再次重试且服务端没有幂等处理',
        '为操作与创建请求使用稳定唯一标识，服务端按标识去重，客户端只删除确认成功的队列项',
      ],
      <String>[
        '离线修改覆盖了服务端更新',
        '同步时直接整条覆盖，没有比较版本或合并字段',
        '保留版本与更新时间，按字段合并并记录冲突；无法自动解决时让用户选择，不能静默丢弃数据',
      ],
      <String>[
        '列表滚动仍然掉帧',
        '在构建过程中解析大对象、频繁重建或一次加载过多记录',
        '分页查询并使用轻量模型，把解析与数据库访问移出首帧，结合帧图和内存采样逐项优化',
      ],
    ],
    extensions: <String>['加入后台任务与系统调度约束', '用数据库加密和密钥轮换保护敏感数据', '增加灰度发布与崩溃率监控'],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': '离线优先应用为什么先写本地数据库而不是直接调用接口？',
        'options': <String>[
          '让界面立即得到稳定状态，再由同步器在后台处理网络',
          '因为接口永远不可用',
          '可以减少业务字段数量',
          '这样就不需要测试同步',
        ],
        'answer': 0,
        'explanation': '离线优先把本地存储作为界面读取的即时真相来源，用户操作先落库并进入待同步队列，因此无网时仍可继续工作。后台同步随后完成上传、重试和冲突处理。这样能避免界面依赖网络往返，也能在进程被终止后恢复未完成操作；代价是必须额外设计幂等和一致性。本地写入与队列更新必须处于同一事务。',
      },
      <String, Object>{
        'question': '同步操作使用客户端生成唯一标识的主要目的是什么？',
        'options': <String>[
          '让标识更短',
          '让超时重试时服务端能够识别同一操作，避免重复创建',
          '替代所有数据库主键',
          '保证网络永不超时',
        ],
        'answer': 1,
        'explanation': '移动网络经常出现服务端已处理但客户端没收到响应的情况，此时客户端会重试。如果每次都生成新标识，就会创建重复数据；使用客户端生成的稳定操作标识，服务端就能在同一事务中识别并返回原结果。这属于幂等设计，通常还需要唯一的业务约束和重试记录共同保证。同一操作的重试应复用原有标识。',
      },
      <String, Object>{
        'question': '本地与服务端同时修改同一条记录时，可靠做法是什么？',
        'options': <String>[
          '总是保留本地版本',
          '直接删除冲突记录',
          '比较版本或更新时间，按字段规则合并，无法自动解决时明确交给用户',
          '关闭同步功能',
        ],
        'answer': 2,
        'explanation': '简单采用最后写入获胜会静默丢失一侧修改。更可靠的方式是保存版本或更新时间，识别并发变化，并按照业务规则合并不同字段；例如标题以最新为准、标签取并集。无法自动判断时可以展示冲突版本让用户选择。无论采用哪种策略，都要有日志和测试证明数据不会无声消失。',
      },
      <String, Object>{
        'question': '移动端发布前为什么要同时检查性能和包体积？',
        'options': <String>[
          '只影响开发机器',
          '性能与体积在生产网络和设备上无法感知',
          '可以替代功能测试',
          '弱网和低端设备会放大启动、内存与下载成本，直接影响可用性',
        ],
        'answer': 3,
        'explanation': '开发设备通常性能较好且网络稳定，无法代表真实用户环境。资源增加会拉长下载与安装时间，内存过高会增加后台被杀概率，启动耗时和掉帧则直接影响操作。发布前记录基线并设置预算，能在问题进入生产前发现回退，同时避免用单一功能测试代替真实设备测量。低端设备与弱网环境要纳入验收矩阵。',
      },
    ],
    prerequisites: <String>[
      'flutter_basics',
      'flutter_state',
      'mobile_performance',
    ],
    related: <String>[
      'flutter_release',
      'web_pwa_offline',
      'cross_serialization',
    ],
  ),
  ProjectSpec(
    id: 'project_data_etl',
    titleZh: '数据工程 ETL 与质量治理实战',
    titleEn: 'Data Engineering ETL and Quality Governance',
    summaryZh: '搭建可重跑、可观测、可追溯的数据管道，完成抽取、清洗、分区、质量门禁与回填。',
    summaryEn: 'Build a rerunnable and observable ETL pipeline with quality gates and backfills.',
    difficulty: '进阶',
    order: 15,
    hours: 18,
    keywords: <String>['ETL', '数据仓库', 'Airflow', '数据质量', '分区', '幂等回填'],
    image: 'diagram_db_airflow_quality.webp',
    positioning: '让每条数据都能回答从哪里来、何时处理、质量如何、失败后怎样安全重跑。',
    background: '业务数据分散在接口、文件与数据库中，手工清洗导致重复、迟到和口径不一致；一旦任务失败，团队不敢重跑，只能翻旧文件修补。本实战实现一条按日期分区的批处理管道，把原始层、清洗层和汇总层分开，使用调度器编排依赖，加入质量门禁、告警和可重复回填。',
    goals: <String>[
      '能设计原始、清洗与汇总分层，区分追加、覆盖和增量写入策略。',
      '能实现幂等抽取与分区替换，支持迟到数据和指定日期范围回填。',
      '能定义完整性、唯一性、有效性与一致性检查，并让质量问题阻断下游。',
    ],
    constraints: <List<String>>[
      <String>['幂等', '同一日期任务重复执行后，目标分区结果与一次成功执行完全相同'],
      <String>['可追溯', '每批数据记录来源、处理时间、代码版本、行数与质量结果'],
      <String>['质量', '关键字段非空率 100%，主键唯一，金额与状态满足业务约束'],
      <String>['恢复', '单日回填不影响其他分区，失败任务可安全重试并留下审计记录'],
    ],
    architecture: '抽取器把来源原样写入原始层并保存批次元数据；转换任务按日期读取原始分区，完成去重、类型转换和业务映射后原子替换清洗分区；质量检查在发布汇总层前运行，调度器负责依赖、重试、告警和回填。',
    flow: 'sources -> raw partition -> quality/clean -> curated\n                  |              |\n              metadata -> checks -> mart -> dashboard',
    milestones: <List<String>>[
      <String>[
        '建立分层与批次元数据',
        '先定义原始、清洗和汇总表结构及分区键，为每次运行记录批次标识、代码版本、来源游标和行数，保证问题发生时能定位输入。',
      ],
      <String>[
        '实现转换与质量门禁',
        '按主键去重，统一时间、金额和枚举类型，再检查空值、范围、引用关系与行数波动；任一关键检查失败就停止发布并告警。',
      ],
      <String>[
        '完成回填与对账',
        '选择一个日期范围重新执行，先在临时分区生成结果，检查通过后原子替换目标分区；对账脚本比较来源、清洗、汇总三层的关键指标。',
      ],
    ],
    command: '''python -m etl.cli run --date=2026-10-05
python -m etl.cli quality --date=2026-10-05
python -m etl.cli backfill --start=2026-10-01 --end=2026-10-05
python -m etl.cli reconcile --date=2026-10-05
airflow dags test daily_orders 2026-10-05''',
    expected: '首次运行和重复运行得到相同分区行数与指标；质量检查全部通过；回填只修改指定日期；对账脚本显示来源、清洗和汇总层的订单数与金额差异在允许阈值内。',
    deliverables: <String>[
      '分层模型与数据字典',
      '调度任务和依赖图',
      '质量规则、告警与阻断策略',
      '幂等回填脚本和对账报告',
    ],
    failures: <List<String>>[
      <String>[
        '重复运行后数据翻倍',
        '任务直接追加到目标分区，没有按批次去重或替换',
        '先写入临时分区，按业务主键去重并校验行数，再原子替换目标分区，同时记录每次批次元数据',
      ],
      <String>[
        '迟到数据没有进入汇总',
        '增量游标只按处理时间推进，忽略了来源事件时间',
        '同时维护事件时间与处理时间，按可回填窗口重新计算受影响分区，并监控迟到数据比例',
      ],
      <String>[
        '质量检查通过但报表口径错误',
        '只检查字段格式，没有验证业务规则和跨表一致性',
        '补充金额守恒、状态流转、引用完整性和历史波动检查，严重问题阻断发布，轻微异常进入隔离表',
      ],
    ],
    extensions: <String>[
      '加入数据血缘与列级影响分析',
      '把批处理结果接入实时增量链路',
      '建立数据契约并自动检测来源结构变更',
    ],
    questions: <Map<String, Object>>[
      <String, Object>{
        'question': '数据仓库为什么要区分原始层、清洗层和汇总层？',
        'options': <String>[
          '保留来源证据，把清洗与业务口径解耦，便于重跑和排查',
          '为了增加存储成本',
          '因为所有查询都必须扫描原始数据',
          '这样可以省略数据质量检查',
        ],
        'answer': 0,
        'explanation': '原始层尽量保留来源数据和批次信息，清洗层负责类型统一、去重和规范化，汇总层承载面向业务的指标口径。分层后出现错误时，可以从任意一层重跑而不用重新拉取所有来源，也能看清问题是输入变化还是转换逻辑变化。分层不是越多越好，但边界必须清晰。每层都要保留可重复生成的口径说明。',
      },
      <String, Object>{
        'question': 'ETL 任务实现幂等最常用的写入策略是什么？',
        'options': <String>[
          '每次直接追加所有记录',
          '先写临时分区或采用可合并写入，校验后原子替换目标分区',
          '失败后手工修改生产数据',
          '删除整张表再重新创建',
        ],
        'answer': 1,
        'explanation': '幂等要求同一批输入和时间分区反复执行得到相同结果。常用方式是先写临时表或临时分区，完成去重与质量检查后再原子替换目标分区；也可以使用带主键的合并写入并删除同批旧版本。直接追加会产生重复，删除整表则会影响并发读取且扩大故障范围。目标分区替换需要事务或原子重命名。',
      },
      <String, Object>{
        'question': '数据质量门禁应该在什么位置阻断任务？',
        'options': <String>[
          '只在任务成功后记录日志',
          '只在报表被用户投诉后处理',
          '在发布给下游之前，关键规则失败就停止晋级并告警',
          '所有异常都忽略，保持流水线绿色',
        ],
        'answer': 2,
        'explanation': '质量检查必须位于数据进入下游可见区域之前，否则错误会扩散到报表、模型和其他服务。完整性、唯一性、范围和跨表一致性等关键规则失败时应阻断发布，并保留隔离数据和批次信息。轻微波动可以告警或降级，但阈值和处置策略要明确，不能为了让流水线显示成功而忽略问题。隔离数据应保留批次与失败规则。',
      },
      <String, Object>{
        'question': '历史回填时最需要控制的风险是什么？',
        'options': <String>[
          '回填任务的名称',
          '渲染报表的颜色',
          '只运行最新日期',
          '影响范围与资源争用，避免覆盖当前数据或拖垮依赖系统',
        ],
        'answer': 3,
        'explanation': '回填会同时读取历史来源、写入多个分区并消耗数据库和计算资源，可能覆盖正在使用的数据或与其他任务争抢资源。应限制日期范围与并发，使用独立队列和临时分区，按依赖顺序执行，并先验证小范围结果。完成后还要对账并记录批次，确保可以审计和再次恢复。回填完成后再运行一次完整对账。',
      },
    ],
    prerequisites: <String>[
      'python_project_etl',
      'data_lakehouse',
      'airflow_quality',
    ],
    related: <String>[
      'realtime_warehouse',
      'bigdata_batch_stream',
      'visual_kafka_partition',
    ],
  ),
  // __SPECS__
];
