// P3 题库体验收尾：降低「最长项即正确项」的长度线索，并微调答案下标分布。
//
// 用法：
//   dart tool/rebalance_option_length.dart [--dry-run] [--force]
//
// 两条独立策略：
//   1. 长度线索：对正确项明显长于其他选项的题目，只改写一个错误选项，
//      把干扰项补到接近正确项的长度；正确项与解析保持原样，不引入新事实。
//   2. 下标分布：把少量答案为 1 的单选题目交换选项 1 与 3 的位置，
//      让 A/B/C/D 四个位置更均匀；解析里若引用了选项位置则跳过。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int balanceVersion = 4;

class OptionPatch {
  const OptionPatch({
    required this.lessonId,
    required this.questionKeyword,
    required this.oldText,
    required this.appended,
  });

  final String lessonId;
  final String questionKeyword;
  final String oldText;
  final String appended;
}

const List<OptionPatch> patches = <OptionPatch>[
  OptionPatch(
    lessonId: 'java_exceptions',
    questionKeyword: '抛出异常时想保留原始异常信息',
    oldText: 'e.printStackTrace 后返回 null',
    appended: '，同时忽略原始异常信息',
  ),
  OptionPatch(
    lessonId: 'performance_metrics',
    questionKeyword: '性能度量与并行体系结构',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，遇到反例也无需回头修正结论',
  ),
  OptionPatch(
    lessonId: 'network_flow',
    questionKeyword: '网络流与二分图匹配',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'algorithms_project',
    questionKeyword: '实战：把数据结构用起来',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，示例与边界都可以跳过',
  ),
  OptionPatch(
    lessonId: 'socket_programming',
    questionKeyword: 'Socket 编程实战',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，示例与边界都可以跳过',
  ),
  OptionPatch(
    lessonId: 'auth_oauth',
    questionKeyword: '认证与授权',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'distributed_transaction',
    questionKeyword: '分布式事务与共识',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'ipc_io',
    questionKeyword: '进程间通信与 IO 模型',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，示例与边界都可以跳过',
  ),
  OptionPatch(
    lessonId: 'toolchain_project',
    questionKeyword: '搭一条完整 CI/CD 流水线',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，遇到反例也无需回头修正结论',
  ),
  OptionPatch(
    lessonId: 'gitops_argocd',
    questionKeyword: 'GitOps 与 ArgoCD',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'ai_coding_assistant',
    questionKeyword: 'AI 编程助手与代码生成',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，示例与边界都可以跳过',
  ),
  OptionPatch(
    lessonId: 'high_availability',
    questionKeyword: '高可用与容量规划',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'distributed_consensus',
    questionKeyword: '共识与复制：Raft 实战要点',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'design_patterns',
    questionKeyword: '设计模式与 SOLID',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'requirements_modeling',
    questionKeyword: '需求分析与建模',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'sdl_security',
    questionKeyword: '安全开发生命周期',
    oldText: '只要示例数据能跑通，边界输入和失败路径就不必再验证。',
    appended: '，也无需重新确认前提与边界',
  ),
  OptionPatch(
    lessonId: 'se_tech_writing',
    questionKeyword: '技术写作与文档工程',
    oldText: '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    appended: '，遇到反例也无需回头修正结论',
  ),
  OptionPatch(
    lessonId: 'cross_ci_config',
    questionKeyword: 'CI 流水线配置：九种生态横向对照',
    oldText: '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
    appended: '，遇到反例也无需回头修正结论',
  ),
  OptionPatch(
    lessonId: 'project_network_capture_analysis',
    questionKeyword: 'tcp.analysis_retransmission',
    oldText: 'DNS 解析一定失败',
    appended: '，与重传现象直接相关',
  ),
  OptionPatch(
    lessonId: 'project_concurrency_runtime',
    questionKeyword: '验证内存可见性与数据竞争',
    oldText: '只看 CPU 使用率',
    appended: '，忽略内存模型与竞态复现条件，认为指标正常就没有问题',
  ),
  OptionPatch(
    lessonId: 'project_algorithm_engineering',
    questionKeyword: '算法基准测试为什么需要预热阶段',
    oldText: '保证所有输入都变得有序',
    appended: '，从而消除测量误差与冷启动影响',
  ),
  OptionPatch(
    lessonId: 'project_devops_pipeline',
    questionKeyword: '流水线中的密钥应该如何处理',
    oldText: '放在公共聊天群中供团队共享',
    appended: '，方便快速复制到流水线',
  ),
  OptionPatch(
    lessonId: 'project_mobile_offline_app',
    questionKeyword: '移动端发布前为什么要同时检查性能和包体积',
    oldText: '性能与体积在生产网络和设备上无法感知',
    appended: '，因此不需要在发布前检查',
  ),
  OptionPatch(
    lessonId: 'project_data_etl',
    questionKeyword: '数据仓库为什么要区分原始层、清洗层和汇总层',
    oldText: '因为所有查询都必须扫描原始数据',
    appended: '，分层只是为了增加存储成本',
  ),
];

/// 解析里出现这些字样时，说明它引用了选项位置，交换会破坏讲解。
const List<String> positionalMarkers = <String>[
  '选项 A',
  '选项 B',
  '选项 C',
  '选项 D',
  '第一个选项',
  '第二个选项',
  '第三个选项',
  '第四个选项',
  'A)',
  'B)',
  'C)',
  'D)',
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

  final questions = <Map<String, dynamic>>[];
  final byLesson = <String, List<Map<String, dynamic>>>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final quiz = (lesson['quiz'] as List<dynamic>)
          .cast<Map<dynamic, dynamic>>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
      byLesson[lesson['id'] as String] = quiz;
      questions.addAll(quiz);
    }
  }

  stdout.writeln('调整前：${_summary(questions)}');

  var patched = 0;
  var missing = 0;
  for (final patch in patches) {
    final quiz = byLesson[patch.lessonId];
    // 同一课程可能有多道题都含课程名，必须按「选项原文」定位目标题。
    final question = quiz?.firstWhere(
      (item) =>
          (item['question'] ?? '').toString().contains(patch.questionKeyword) &&
          ((item['options'] as List<dynamic>?) ?? const <dynamic>[])
              .map((option) => option.toString())
              .contains(patch.oldText),
      orElse: () => <String, dynamic>{},
    );
    if (question == null || question.isEmpty) {
      stderr.writeln('找不到题目：${patch.lessonId} / ${patch.questionKeyword}');
      missing++;
      continue;
    }
    final options = (question['options'] as List<dynamic>).cast<String>();
    final newText = '${patch.oldText.replaceAll(RegExp(r'[。；]$'), '')}'
        '${patch.appended}。';
    var changed = false;
    for (var index = 0; index < options.length; index++) {
      if (options[index] == patch.oldText) {
        options[index] = newText;
        changed = true;
        break;
      }
      if (options[index] == newText) {
        changed = false;
        break;
      }
    }
    if (changed) patched++;
  }
  stdout.writeln('改写干扰项：$patched 处，未匹配：$missing 处');

  final rebalanced = _rebalanceIndexes(questions, dryRun);
  stdout.writeln('交换答案位置：$rebalanced 题');

  if (!dryRun) {
    manifest['quiz_answer_balance_version'] = balanceVersion;
    manifest['option_length_balance_version'] = 1;
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }
  stdout.writeln('调整后：${_summary(questions)}');
  if (force) stdout.writeln('（--force 保留参数位，便于后续重算）');
}

/// 把答案下标为 1 的单选题交换选项 1 与 3，直到四个位置更均衡。
int _rebalanceIndexes(
  List<Map<String, dynamic>> questions,
  bool dryRun,
) {
  final singles = questions
      .where((item) => (item['type'] ?? 'single') == 'single')
      .where((item) => (item['options'] as List).length >= 4)
      .where((item) => item['answer'] is int)
      .toList();
  final counts = <int, int>{};
  for (final item in singles) {
    final index = item['answer'] as int;
    counts[index] = (counts[index] ?? 0) + 1;
  }
  final candidates = singles.where((item) {
    if (item['answer'] != 1) return false;
    final explanation = (item['explanation'] ?? '').toString();
    return !positionalMarkers.any(explanation.contains);
  }).toList();
  var moved = 0;
  for (final item in candidates) {
    final current = <int, int>{
      for (var index = 0; index < 4; index++) index: counts[index] ?? 0,
    };
    final lowest = current.entries.reduce(
      (a, b) => b.value < a.value ? b : a,
    );
    if (lowest.key == 1) continue;
    if ((current[1] ?? 0) - lowest.value < 2) continue;
    final options = item['options'] as List<dynamic>;
    final target = lowest.key;
    final temp = options[1];
    options[1] = options[target];
    options[target] = temp;
    item['answer'] = target;
    counts[1] = (counts[1] ?? 0) - 1;
    counts[target] = (counts[target] ?? 0) + 1;
    moved++;
  }
  return moved;
}

String _summary(List<Map<String, dynamic>> questions) {
  final singles = questions.where(
    (item) => (item['type'] ?? 'single') == 'single',
  );
  final counts = <int, int>{};
  var strictlyLongest = 0;
  var strong = 0;
  var total = 0;
  for (final item in singles) {
    final options = (item['options'] as List<dynamic>).cast<String>();
    final answer = item['answer'];
    if (options.length < 2 || answer is! int) continue;
    if (answer < 0 || answer >= options.length) continue;
    total++;
    counts[answer] = (counts[answer] ?? 0) + 1;
    final lengths = options.map((option) => option.trim().length).toList();
    final correct = lengths[answer];
    final others = <int>[
      for (var index = 0; index < lengths.length; index++)
        if (index != answer) lengths[index],
    ];
    final second = others.reduce((a, b) => a > b ? a : b);
    if (correct > second) {
      strictlyLongest++;
      if (correct - second >= 8) strong++;
    }
  }
  final spread = counts.entries
      .map((entry) => '${entry.key}:${entry.value}')
      .join(' ');
  final rate = total == 0 ? 0 : strictlyLongest * 100 / total;
  return '单选 $total 题，下标 $spread，最长项命中 '
      '${rate.toStringAsFixed(1)}%，强线索 $strong 题';
}
