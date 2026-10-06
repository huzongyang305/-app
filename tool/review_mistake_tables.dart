// P2 错误表复核：P1 用测验题自动生成的「常见错误与排查」里混进了排序题、
// 代码题等模板行，这里逐课重写成真实的易错点，并留下复核标记。
//
// 用法：
//   dart tool/review_mistake_tables.dart --dry-run
//   dart tool/review_mistake_tables.dart --preview=<lessonId>
//   dart tool/review_mistake_tables.dart
import 'dart:convert';
import 'dart:io';

import 'markdown_fences.dart';

const String manifestPath = 'assets/content/manifest.json';
const String sectionHeading = '常见错误与排查';
const String reviewedHeader = '| 易错点 | 容易踩的做法 | 正确结论 |';
const String generatedHeader = '| 题目 | 容易踩的做法 | 正确结论 |';
const String separatorRow = '| --- | --- | --- |';
const String reviewMarker =
    '> 复核：已人工核对并重写（2026-10-06），每行对应本课的一个真实易错点。';

/// 课程 id → 易错点、容易踩的做法、正确结论。
const Map<String, List<List<String>>> reviewedMistakeTables =
    <String, List<List<String>>>{
  'index': <List<String>>[
    <String>['把索引当成越多越好', '每个索引都要在写入时维护，写多读少的表会被拖慢', '只给高频查询、高选择性的列建索引，并定期清理无用索引'],
    <String>['用 LIKE \'%关键词\' 做模糊匹配', '前缀不确定，B+ 树无法定位范围', '前缀确定的 LIKE \'关键词%\' 才能用上索引，否则改用全文检索'],
    <String>['联合索引 (a, b, c) 只查 b', '跳过最左列，索引的有序性用不上', '遵守最左前缀，把高频列放在最左边或另建索引'],
    <String>['只在开发库上判断索引是否生效', '数据量与统计信息不同，执行计划会完全不一样', '用 EXPLAIN 看真实数据量下的访问路径，并用真实参数验证'],
    <String>['建了索引就以为一定会被用上', '隐式类型转换、对列做函数运算、统计信息过期都会让索引失效', '保持列可比、避免在列上做运算，并及时更新统计信息'],
  ],
  'project_network_capture_analysis': <List<String>>[
    <String>['抓包位置选错', '在客户端抓到的是本地回环，看不到链路上的丢包', '按问题分层选择抓包点（客户端、服务端、中间设备）并对比'],
    <String>['把重传直接当成服务端宕机', 'tcp.analysis_retransmission 只说明发生了重传', '结合 RTT、丢包率与时间线判断是链路丢包还是超时重传'],
    <String>['只抓一次就下结论', '网络问题有随机性，单次样本不足以支撑结论', '固定过滤条件重复抓取，保留时间戳与抓包文件作为证据'],
    <String>['在明文抓包里直接查看口令', '抓包文件包含敏感数据，散落会造成泄露', '限制保存范围与访问权限，需要看 TLS 内容时用密钥解密而不是关掉加密'],
  ],
  'project_database_tuning': <List<String>>[
    <String>['凭感觉加索引', '没有执行计划证据，可能越加越慢', '先用慢查询日志与 EXPLAIN 定位，再针对性调整'],
    <String>['长事务不收敛', '长时间持有锁与快照，阻塞其他事务并放大回滚成本', '拆分大事务、控制批量提交大小，并监控锁等待'],
    <String>['只看平均耗时', '平均值掩盖了尾延迟，用户体感仍然很差', '同时看 P95/P99 与等待事件，找出真正的长尾来源'],
    <String>['把慢查询一律归因于数据库', '也可能是网络、连接池或应用层 N+1 查询', '按调用链分段计时，确认瓶颈在数据库还是上下游'],
  ],
  'project_security_lab': <List<String>>[
    <String>['只在前端做权限校验', '前端逻辑可以被绕过，接口会直接暴露', '服务端逐请求校验身份与数据归属'],
    <String>['把水平越权和垂直越权混为一谈', '两者的检测方式与修复位置不同', '水平越权查同级他人资源，垂直越权查更高权限功能'],
    <String>['依赖版本长期不升级', '已知漏洞会随着依赖进入生产环境', '锁定版本、持续扫描依赖，并保留升级与回滚预案'],
    <String>['日志里记录敏感信息', '审计日志本身会变成泄露源', '记录操作与主体，对口令、令牌与个人信息做脱敏'],
  ],
  'project_algorithm_engineering': <List<String>>[
    <String>['基准测试不做预热', '冷启动、即时编译与缓存未稳定，数据不可比', '先预热，再重复测量并报告中位数与波动'],
    <String>['只用一个输入规模下结论', '复杂度拐点可能在更大规模才出现', '至少测三档规模，画出增长趋势再判断复杂度'],
    <String>['只看平均耗时忽略内存', '内存分配与 GC 会造成线上抖动', '同时记录耗时与分配量，必要时做内存剖析'],
    <String>['优化后不做回归验证', '一次优化可能在别的输入上带来退化', '把基准用例纳入 CI，设阈值阻止性能回归'],
  ],
  'project_mobile_offline_app': <List<String>>[
    <String>['把网络当成一定可用', '弱网与断网时功能直接不可用', '本地先读写，网络只用于同步，并给出同步状态提示'],
    <String>['同步接口不幂等', '重试会产生重复数据或覆盖他人修改', '用客户端生成的唯一键与版本号，保证重复执行结果一致'],
    <String>['冲突策略没有想清楚', '两端同时修改时数据会被静默覆盖', '明确最后写入优先或版本向量，必要时提示用户合并'],
    <String>['上线前只在模拟器验证', '低端设备与弱网下的启动、内存和包体积问题不会暴露', '在真机与弱网环境测启动时间、帧率与包体积'],
  ],
  'project_concurrency_runtime': <List<String>>[
    <String>['线程池不设上限与拒绝策略', '任务堆积导致内存膨胀，最终雪崩', '设置队列上限与拒绝策略，并监控排队时间'],
    <String>['用锁保护过大的范围', '锁竞争让并行退化成串行', '缩小临界区，必要时拆锁或改用无锁结构'],
    <String>['靠功能测试验证数据竞争', '竞争有随机性，跑一次通过不代表没问题', '使用 race detector 或 ThreadSanitizer 并配合压力测试'],
    <String>['忽略上下文切换成本', '线程过多时切换开销吃掉并行收益', '按 CPU 与 IO 特性调整线程数，用剖析数据决定'],
  ],
  'project_devops_pipeline': <List<String>>[
    <String>['把密钥写进仓库或镜像', '历史记录与制品会带着密钥扩散，很难彻底删除', '存入专用密钥系统，按最小权限临时注入并限制日志输出'],
    <String>['流水线没有快速失败顺序', '慢任务先跑，反馈周期被拉长', '先跑最快的检查与单元测试，把耗时任务排在后面'],
    <String>['直接全量发布', '出问题时影响全部用户', '用灰度或金丝雀分批放量，并准备一键回滚'],
    <String>['只部署不观测', '发布后无法判断是否变坏', '把日志、指标与追踪接入发布流程，设定回滚阈值'],
  ],
  'project_data_etl': <List<String>>[
    <String>['不区分原始层、清洗层与汇总层', '出问题时无法回溯，也无法只重跑某一段', '分层保存来源证据与业务口径，按层重跑'],
    <String>['回填任务不幂等', '重复执行会产生重复数据', '用覆盖写或去重键，保证同一批次重复执行结果一致'],
    <String>['不分分区直接全量扫描', '成本高，迟到数据也难以补算', '按日期等键分区，只处理受影响分区'],
    <String>['质量检查只判空', '有数据但口径错误照样会流到下游', '除完整性外还检查唯一性、及时性与业务口径，不通过就阻断下游'],
    <String>['调度失败只靠人工发现', '延迟会被放大到下游报表', '配置告警与重试策略，记录每次运行的结果与耗时'],
  ],
};

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final preview = _stringOption(args, '--preview=', '');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <Map<String, dynamic>>[
    for (final rawCategory in manifest['categories'] as List<dynamic>)
      for (final raw in (rawCategory as Map)['lessons'] as List<dynamic>)
        (raw as Map).cast<String, dynamic>(),
  ];
  final ids = <String>{for (final lesson in lessons) lesson['id'].toString()};
  final invalid = <String>[
    for (final entry in reviewedMistakeTables.entries)
      if (entry.value.length < 3 ||
          entry.value.any(
            (row) =>
                row.length != 3 ||
                row.any((cell) => cell.trim().isEmpty) ||
                row.any(_hasUnescapedPipe),
          ))
        entry.key,
  ];
  if (invalid.isNotEmpty) {
    stderr.writeln('复核表数据不合法（行数不足、单元格为空或竖线未转义）：${invalid.join('、')}');
    exitCode = 3;
    return;
  }
  final unknown = reviewedMistakeTables.keys
      .where((id) => !ids.contains(id))
      .toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('复核表里有清单中不存在的课程：${unknown.join('、')}');
    exitCode = 4;
    return;
  }
  if (preview.isNotEmpty) {
    final lesson = lessons.firstWhere(
      (item) => item['id'].toString() == preview,
      orElse: () => const <String, dynamic>{},
    );
    if (lesson.isEmpty) {
      stderr.writeln('找不到课程：$preview');
      exitCode = 2;
      return;
    }
    stdout.writeln(
      _sectionText(
        rewriteMistakeTable(
          File(lesson['file'].toString()).readAsStringSync(),
          preview,
        ),
      ),
    );
    return;
  }
  var rewritten = 0;
  final skipped = <String>[];
  for (final entry in reviewedMistakeTables.entries) {
    final lesson = lessons.firstWhere(
      (item) => item['id'].toString() == entry.key,
    );
    final file = File(lesson['file'].toString());
    final before = file.readAsStringSync();
    final after = rewriteMistakeTable(before, entry.key);
    if (after == before) continue;
    if (!after.contains(reviewedHeader)) {
      skipped.add(entry.key);
      continue;
    }
    rewritten++;
    if (!dryRun) file.writeAsStringSync(after, flush: true);
  }
  if (skipped.isNotEmpty) stderr.writeln('以下课程没有找到目标章节：${skipped.join('、')}');
  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}复核并重写错误表 $rewritten 篇'
    '${skipped.isEmpty ? '' : '，跳过 ${skipped.length} 篇'}',
  );
}

/// 把自动生成的错误表替换为人工复核版本，并写入复核标记。
String rewriteMistakeTable(String markdown, String lessonId) {
  final rows = reviewedMistakeTables[lessonId];
  if (rows == null) return markdown;
  final lines = markdown.split('\n');
  final range = _sectionRange(lines, markdownFenceMask(markdown));
  if (range == null) return markdown;
  final output = <String>[
    ...lines.sublist(0, range.heading + 1),
    '',
    reviewMarker,
    '',
    reviewedHeader,
    separatorRow,
    for (final row in rows) '| ${row[0]} | ${row[1]} | ${row[2]} |',
    '',
    ...lines.sublist(range.end),
  ];
  return '${output.join('\n').trimRight()}\n';
}

({int heading, int end})? _sectionRange(List<String> lines, List<bool> mask) {
  final headingPattern = RegExp('^##\\s+$sectionHeading\\s*\$');
  final sectionPattern = RegExp(r'^##\s+');
  var heading = -1;
  for (var index = 0; index < lines.length; index++) {
    if (mask[index]) continue;
    if (headingPattern.hasMatch(lines[index])) {
      heading = index;
      break;
    }
  }
  if (heading < 0) return null;
  var end = lines.length;
  for (var index = heading + 1; index < lines.length; index++) {
    if (mask[index]) continue;
    if (sectionPattern.hasMatch(lines[index])) {
      end = index;
      break;
    }
  }
  return (heading: heading, end: end);
}

String _sectionText(String markdown) {
  final lines = markdown.split('\n');
  final range = _sectionRange(lines, markdownFenceMask(markdown));
  if (range == null) return '(没有$sectionHeading章节)';
  return lines.sublist(range.heading, range.end).join('\n').trimRight();
}

/// 表格单元格里的竖线必须写成 \|，否则会把表格撑成多列。
bool _hasUnescapedPipe(String text) {
  for (var index = 0; index < text.length; index++) {
    if (text[index] != '|') continue;
    if (index > 0 && text[index - 1] == r'\') continue;
    return true;
  }
  return false;
}

String _stringOption(List<String> args, String prefix, String fallback) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    return arg.substring(prefix.length);
  }
  return fallback;
}
