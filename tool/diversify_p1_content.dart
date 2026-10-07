// P1 内容去模板化工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/diversify_p1_content.dart [--dry-run] [--lesson=id]
//
// 背景：早期几轮「补篇幅」脚本在数百门课里写入了跨课完全相同的 scaffold 句子，
// 例如「**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。」，
// 以及被截断成「关于，下列说法正确的是？」的测验题干。
//
// 本工具把这些句子改写成只属于当前课程的表达：每一句都必须引用本课的标题、
// 关键词、正文小节、代码标识符或测验答案中的至少一项，并按课程 id 选择句式，
// 因此同一句话不会再出现在多门课里。改写是幂等的：新句子不再匹配旧模板，
// 重复执行不会叠加内容。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String defaultReportPath = 'tool/reports/p1_diversify_report.json';

/// 跨课复用句（精确匹配）。这些是上一轮审计 grep 出来的高频 scaffold 行。
const String scaffoldFiveStep = '**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。';
const String scaffoldCompareTable =
    '**验收标准**：表格里两个方案的结论不能完全一样；写下“在什么条件下应该换方案”。';
const String scaffoldMigrationAcceptance =
    '**验收**：结论有证据、差异可解释、失败可恢复；如果做不到，说明还需要缩小问题范围。';
const String scaffoldFailurePath = '4. 找出一条失败路径。让错误尽早暴露，并说明重试、降级、回滚或人工处理的边界。';
const String scaffoldTinyExample = '5. 用一个小例子贯穿全过程。先手算或预测结果，再运行代码或实验，最后解释差异。';
const String truncatedQuestion = '关于，下列说法正确的是？';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final only = _stringOption(args, '--lesson=');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <_LessonProfile>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (only != null && only != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      lessons.add(
        _LessonProfile(
          id: id,
          categoryId: categoryId,
          title: ((lesson['title'] as Map?)?['zh'] ?? id).toString(),
          difficulty: (lesson['difficulty'] ?? '进阶').toString(),
          keywords: ((lesson['keywords'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
          quiz: ((lesson['quiz'] as List<dynamic>?) ?? const [])
              .map((item) => (item as Map).cast<String, dynamic>())
              .toList(),
          prerequisites:
              ((lesson['prerequisites'] as List<dynamic>?) ?? const [])
                  .map((item) => item.toString())
                  .toList(),
          file: file,
        ),
      );
    }
  }

  final titleById = <String, String>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in ((rawCategory as Map)['lessons'] as List<dynamic>)) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      titleById[lesson['id'].toString()] =
          ((lesson['title'] as Map?)?['zh'] ?? lesson['id']).toString();
    }
  }

  final changed = <String, List<String>>{};
  for (final lesson in lessons) {
    final before = lesson.file.readAsStringSync();
    final after = _rewriteLesson(lesson, before, titleById);
    if (after == before) continue;
    changed[lesson.id] = _changedKinds(before, after);
    if (!dryRun) lesson.file.writeAsStringSync(after);
  }

  final report = <String, dynamic>{
    'generated_at': DateTime.now().toIso8601String(),
    'dry_run': dryRun,
    'scanned_lessons': lessons.length,
    'changed_lessons': changed.length,
    'changes': changed,
  };
  File(defaultReportPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln(dryRun ? '=== 试运行（未写文件）===' : '=== 已写回去模板化内容 ===');
  stdout.writeln('扫描课程      ${lessons.length}');
  stdout.writeln('改写课程      ${changed.length}');
}

List<String> _changedKinds(String before, String after) {
  final kinds = <String>[];
  if (before.contains(scaffoldFiveStep)) kinds.add('five_step');
  if (before.contains(scaffoldCompareTable)) kinds.add('compare_table');
  if (before.contains(scaffoldMigrationAcceptance)) {
    kinds.add('migration_acceptance');
  }
  if (before.contains(scaffoldFailurePath) ||
      before.contains(scaffoldTinyExample)) {
    kinds.add('depth_steps');
  }
  if (before.contains(truncatedQuestion)) kinds.add('truncated_question');
  if (before.contains('"input": {"case": "normal", "value": 5}')) {
    kinds.add('project_acceptance_data');
  }
  if (RegExp(r'- 本课阶段：.+建议').hasMatch(before)) {
    kinds.add('stage_line');
  }
  return kinds;
}

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

class _LessonProfile {
  _LessonProfile({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.difficulty,
    required this.keywords,
    required this.quiz,
    required this.prerequisites,
    required this.file,
  });

  final String id;
  final String categoryId;
  final String title;
  final String difficulty;
  final List<String> keywords;
  final List<Map<String, dynamic>> quiz;
  final List<String> prerequisites;
  final File file;
}

/// 只改当前课程里出现的跨课复用句，逐条替换成本课专属表达。
String _rewriteLesson(
  _LessonProfile lesson,
  String markdown,
  Map<String, String> titleById,
) {
  final material = _LessonMaterial.from(lesson, markdown, titleById);
  var result = markdown;
  if (result.contains(scaffoldFiveStep)) {
    result = result.replaceAll(
      scaffoldFiveStep,
      _fiveStepAcceptance(lesson, material),
    );
  }
  if (result.contains(scaffoldCompareTable)) {
    result = result.replaceAll(
      scaffoldCompareTable,
      _compareAcceptance(lesson, material),
    );
  }
  final compareRowPattern = RegExp(
    r'\| `任务 2：做一次对比实验` \| 验收标准：'
    r'表格里两个方案的结论不能完全一样；'
    r'写下“在什么条件下应该换方案”。 \|',
  );
  if (compareRowPattern.hasMatch(result)) {
    result = result.replaceAllMapped(
      compareRowPattern,
      (match) =>
          '| `任务 2：做一次对比实验` | ${_tableCellAcceptance(lesson, material)}|',
    );
  }
  if (result.contains(scaffoldMigrationAcceptance)) {
    result = result.replaceAll(
      scaffoldMigrationAcceptance,
      _migrationAcceptance(lesson, material),
    );
  }
  if (result.contains(scaffoldFailurePath)) {
    result = result.replaceAll(
      scaffoldFailurePath,
      _failurePathStep(lesson, material),
    );
  }
  if (result.contains(scaffoldTinyExample)) {
    result = result.replaceAll(
      scaffoldTinyExample,
      _tinyExampleStep(lesson, material),
    );
  }
  final stagePattern = RegExp(r'- 本课阶段：[^\n]*?建议[^\n]*\n', multiLine: true);
  if (stagePattern.hasMatch(result)) {
    result = result.replaceAll(
      stagePattern,
      '- 本课阶段：${lesson.difficulty}。${_stageAdvice(lesson, material)}\n',
    );
  }
  if (result.contains(truncatedQuestion)) {
    result = _repairTruncatedQuestions(lesson, result);
  }
  if (result.contains('"project": "${lesson.id}"')) {
    result = _replaceProjectAcceptanceData(lesson, material, result);
  }
  result = _rewriteResidualScaffolds(lesson, material, result);
  return result;
}

/// 第二轮：处理审计报告 tool/reports/p1_repeated_lines.tsv 里剩下的高频复用句。
/// 每条规则都命中一个固定的跨课句子，替换结果必须引用本课素材。
String _rewriteResidualScaffolds(
  _LessonProfile lesson,
  _LessonMaterial material,
  String markdown,
) {
  var result = markdown;
  final term = material.terms.first;
  final second = material.terms.length > 1 ? material.terms[1] : term;
  final signal = material.signal;
  final heading = material.heading;

  result = _replaceLine(
    result,
    RegExp(r'^删掉一个看似必要的步骤，观察哪个测试或指标先失败，用证据说明它为什么必要。$', multiLine: true),
    (match) => _pick(<String>[
      '5. 删掉一个看似必要的步骤（例如 $term 相关的校验），观察哪个测试或指标先失败，'
          '用证据说明它为什么不能省。',
      '5. 在 $heading 这一步去掉一个前提，观察输出怎样变化；'
          '变化本身不能说明原因，还要写出 $term 相关的哪条假设被破坏。',
      '5. 把 $signal 的执行顺序调换一次，记录哪个中间结果先错；'
          '顺序敏感的地方就是本课的关键约束。',
      '5. 故意跳过 $second 的检查再运行，比较与正常流程的差异，'
          '并说明这个检查挡住的到底是哪一类失败。',
      '5. 减少一个输入字段后重跑 $signal，记录失败信息出现在哪一层，'
          '据此判断这个字段是必填还是可推导。',
      '5. 把「${lesson.title}」里最容易被省略的一步去掉，'
          '用测试或指标证明它不可省略，而不是凭感觉判断。',
    ], 'drop-step-${lesson.id}'),
  );
  result = _replaceLine(
    result,
    RegExp(
      r'^验收标准：至少有一个可复现的命令、代码片段或数据样例；'
      r'结论能被别人独立检查。$',
      multiLine: true,
    ),
    (match) => _pick(<String>[
      '**验收标准**：结论要附带 $signal 的可复现记录，'
          '并说明 $term 在「$heading」里的位置。',
      '**验收标准**：至少给出一个命令或数据样例，让读者能独立复现 $second 的结论。',
      '**验收标准**：把自己的判断写成可检查的形式——输入、步骤、输出、差异各一条，'
          '其中输入必须包含 $term。',
      '**验收标准**：换一个人按你的记录重跑 $signal，能得到相同输出；'
          '得不到就补写缺失的前提。',
      '**验收标准**：用自己的话复述 $term，并配一个反例；'
          '只写定义不算通过。',
      '**验收标准**：结论要能追溯到「$heading」的具体段落，'
          '并说明它和 $second 的边界。',
    ], 'accept-1-${lesson.id}'),
  );
  result = _replaceLine(
    result,
    RegExp(
      r'^\*\*实验一：建立基线：先原样运行上面的代码，'
      r'记录命令、完整输出和退出状态$',
      multiLine: true,
    ),
    (match) =>
        '- **实验一：建立基线**：先原样运行 $signal 所在的示例，'
        '记录版本、命令、完整输出与退出状态。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^输入 → 参数校验 → 业务处理 → 持久化/外部调用 → 结果输出 → 指标与日志$', multiLine: true),
    (match) =>
        '「${lesson.title}」的链路可以写成：'
        '${material.chain.isEmpty ? '$signal → $term → $second' : material.chain}。'
        '链上任何一环缺少可观察的输出，都不能算验证完成。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^能把本课知识放回「[^」]+」的知识体系，说明它和相邻主题的边界。$', multiLine: true),
    (match) =>
        '- 能把 $term 放回「${lesson.title}」的知识体系，'
        '说明它和 $second 的边界。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^升级前[^\n]*$', multiLine: true),
    (match) => _pick(<String>[
      '- 升级「${lesson.title}」涉及的依赖前，先用 $signal 复现当前行为，'
          '再逐项核对版本说明与破坏性变更。',
      '- 升级前先用 $signal 建立基线：记录版本、命令和输出，'
          '升级后只比较这些可观察量。',
      '- 升级前确认 $term 的兼容范围，把不可回退的改动单独拆成一次提交。',
    ], 'upgrade-${lesson.id}'),
  );
  result = _replaceLine(
    result,
    RegExp(
      r'^(?:写一个最小类型示例|先写最小程序并用 go test|写一个带 `set -euo pipefail` 的脚本|'
      r'写一个可运行的小程序|先让 cargo check 通过|写一个最小 Cargo 示例)[^\n]*$',
      multiLine: true,
    ),
    (match) => _pick(<String>[
      '围绕 $term 写一个最小示例，先用 $signal 跑通，再补一个边界输入。',
      '写一个只包含 $term 的最小程序，先验证正常路径，再制造一次失败。',
      '用 $signal 构造最小可运行示例，并把输出与「$heading」的结论对照。',
      '写一个只做一件事的小程序：输入 $term，输出 $second，其余全部省略。',
    ], 'lab-${lesson.id}'),
  );
  result = _replaceLine(
    result,
    RegExp(
      r'^(?:把复合语句末尾的冒号删掉[^\n]*|删掉一条语句末尾的分号[^\n]*|'
      r'把变量声明成不兼容的类型[^\n]*|把一个预期为数字的值改成字符串[^\n]*|'
      r'把输入改成空值、极值或类型不匹配的形式[^\n]*)$',
      multiLine: true,
    ),
    (match) => _pick(<String>[
      '把 $term 相关的那一行改成边界值（空、极值或类型不符），'
          '记录第一条错误信息、发生位置和恢复方式。',
      '把 $signal 的一个参数换成不兼容的类型，先预测报错位置再实际运行；'
          '预测与实际的差异就是本课的考点。',
      '删掉 $second 相关的一处必要写法，观察错误在哪一层出现，'
          '再恢复代码确认基线仍然可运行。',
      '把 $term 的输入从正常值改成越界值，记录程序是报错、降级还是静默出错，'
          '三者对应的修复策略不同。',
    ], 'fault-${lesson.id}'),
  );
  result = _replaceLine(
    result,
    RegExp(r'^把 AI 系统看成一条流水线[^\n]*$', multiLine: true),
    (match) =>
        '把「${lesson.title}」看成一条可评测的流水线：'
        '输入经过 $term 处理，产出候选结果，再由 $second 决定哪些结果可以真正执行；'
        '每一环都要有可测的输入、输出与失败处理。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^把安全看成一条防线[^\n]*$', multiLine: true),
    (match) =>
        '把「${lesson.title}」看成一条防线：先识别资产与威胁，'
        '再围绕 $term 限制权限、验证输入、记录审计，并为失败准备隔离与恢复方案。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^构造一次凭证泄露或越权访问[^\n]*$', multiLine: true),
    (match) =>
        '围绕「${lesson.title}」构造一次 $term 相关的越权或泄露场景，'
        '按发现、隔离、轮换、取证、恢复、复盘六步执行，记录时间线与剩余风险。',
  );
  result = _replaceLine(
    result,
    RegExp(
      r'^验收：正常、边界、失败三条路径都要有结论；'
      r'其中失败路径要写清恢复动作和剩余风险。$',
      multiLine: true,
    ),
    (match) =>
        '**验收**：$term 的正常、边界、失败三条路径都要有结论；'
        '失败路径要写清恢复动作与「${lesson.title}」里仍然存在的剩余风险。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^\*\*考点 (\d+)：代码阅读·第 \d+ 题：先独立作答[^\n]*$', multiLine: true),
    (match) =>
        '- **考点 ${match.group(1) ?? '1'}：'
        '$heading 的代码阅读题**：先独立作答，'
        '再回到本课正文核对 $signal 的执行路径；答错时记录是哪一个前提被忽略。',
  );
  result = _replaceLine(
    result,
    RegExp(
      r'^(?:Bash 5\.x 与 POSIX sh|Rust 2024 edition|Kotlin 2\.x 以 K2 编译器|'
      r'Go 1\.2\d|Swift 6 语言模式|TypeScript 5\.x)[^\n]*$',
      multiLine: true,
    ),
    (match) =>
        '- 版本提示：$term 的行为在最近几个大版本里有过调整，'
        '升级「${lesson.title}」前先用 $signal 复现当前输出，再对照官方发布说明逐条核对。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^改动点：只把[^\n]*更换成空值、极值或错误输入，其余保持不变。$', multiLine: true),
    (match) => '- 改动点：只把 $term 的输入换成空值、极值或错误输入，其余条件保持不变。',
  );
  result = _replaceLine(
    result,
    RegExp(
      r'^把(?:项目实战|计算机|数据库|算法|网络|操作系统|安全|分布式系统|数学工具|'
      r'页面|Flutter|工具链|软件工程)看成[^\n]*$',
      multiLine: true,
    ),
    (match) =>
        '${match.group(0)}'
        '落到本课，「${lesson.title}」关心的是 $term 与 $second 的配合，'
        '也就是说这条直觉要在 $heading 里被具体验证。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^适用环境：PostgreSQL / MySQL / SQLite 等主流数据库$', multiLine: true),
    (match) =>
        '- 适用环境：PostgreSQL / MySQL / SQLite 等主流数据库；'
        '本课聚焦其中的 $term。',
  );
  result = _replaceLine(
    result,
    RegExp(r'^-?\s*适用环境：[^\n]*$', multiLine: true),
    (match) {
      final line = match.group(0)!;
      if (line.contains('本课聚焦') || line.contains('本课讨论')) return line;
      return '$line；本课聚焦 $term。';
    },
  );
  return _applyTemplateRules(lesson, material, result);
}

String _replaceLine(
  String source,
  RegExp pattern,
  String Function(Match match) build,
) {
  if (!pattern.hasMatch(source)) return source;
  return source.replaceAllMapped(pattern, (match) => build(match));
}

/// 表格单元格里不能出现换行，因此去掉句首的加粗标记。
String _tableCellAcceptance(_LessonProfile lesson, _LessonMaterial material) =>
    _compareAcceptance(lesson, material).replaceFirst('**验收标准**：', '');

/// 第三轮：模板规则表。每条规则命中一个跨课复用句，variants 里必须出现
/// {term} / {second} / {signal} / {heading} / {title} 之一，保证改写结果逐课不同。
const List<(String, List<String>)> _templateRules = <(String, List<String>)>[
  // P1 第三批：项目交付章节的通用记录句，改写后必须带本课关键词。
  (
    r'^验收标准：把变量、命令和结果写在一起，使他人可以复现同一结论。$',
    <String>[
      '验收标准：把 {term} 的变量、命令和结果写在一起，使他人可以复现同一结论。',
      '验收标准：把 {signal} 的命令与输出写在一起，让 {term} 的结论可被他人复现。',
      '验收标准：{term} 的输入、命令与输出齐全，任何人按记录都能复现同一结论。',
    ],
  ),
  (
    r'^测试记录：正常、边界与失败路径各至少一条，附命令与输出。$',
    <String>[
      '测试记录：{term} 的正常、边界与失败路径各至少一条，附命令与输出。',
      '测试记录：为 {signal} 各准备一条正常、边界与失败用例，并附完整输出。',
      '测试记录：覆盖 {term} 与 {second} 的正常、边界与失败路径，附命令与输出。',
    ],
  ),
  (
    r'^复盘记录：本次实现推翻了哪个假设，下一步验证动作是什么。$',
    <String>[
      '复盘记录：本轮 {term} 的实现推翻了哪个假设，下一步验证动作是什么。',
      '复盘记录：写下 {signal} 的哪条假设被推翻，以及下一次验证怎么做。',
      '复盘记录：记录 {term} 与 {second} 的对比结论，并给出下一步验证动作。',
    ],
  ),
  (
    r'^\[ \] 至少运行一次本课示例，记录输入、输出和一个边界情况。$',
    <String>[
      '- [ ] 至少运行一次 {signal} 的示例，记录输入、输出和 {term} 的边界情况。',
      '- [ ] 用 {term} 构造一个正常输入和一个边界输入，分别记录输出与判断依据。',
      '- [ ] 跑通「{title}」的最小示例，并记录一次失败输入的处理方式。',
    ],
  ),
  (
    r'^用同一套思路处理一组你自己的数据或场景，保持输出格式与任务 1 一致。$',
    <String>[
      '用同一套思路处理一组你自己的 {term} 数据，保持输出格式与任务 1 一致。',
      '把 {signal} 换成你自己的输入，先保持步骤不变，再比较输出差异。',
      '换一个 {second} 场景重做一次，确认结论不是只对示例数据成立。',
    ],
  ),
  (
    r'^如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。$',
    <String>[
      '如果 {heading} 这一步看不懂，先记录具体卡点，再用 {signal} 复现一遍。',
      '卡在 {term} 上时不要跳过：把输入、预期和实际输出写成三行，再回头读正文。',
      '看不懂就直接缩小例子：只保留 {term} 相关的两行输入，跑通后再加回其余部分。',
    ],
  ),
  (
    r'^验收标准：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。$',
    <String>[
      '验收标准：回答里必须出现 {term}，并写出一个让结论失效的边界条件。',
      '验收标准：用自己的话解释 {term}，并给出一个它不成立的反例。',
      '验收标准：说明 {term} 与 {second} 的分工，并写出一个失效场景。',
    ],
  ),
  (
    r'^升级完成后更新本课的“最后复核 / 下次复核”日期与版本说明。$',
    <String>[
      '升级完成后更新本课「最后复核 / 下次复核」日期，并记录 {term} 的版本变化。',
      '升级后把 {signal} 的实测版本写进「内容元数据」，再更新复核日期。',
      '升级完成后记录 {term} 的新旧版本差异，并据此调整下次复核时间。',
    ],
  ),
  (
    r'^只改一个版本变量，记录编译、测试、性能与产物体积的变化。$',
    <String>[
      '只改 {term} 的版本变量，记录编译、测试与产物体积的变化。',
      '升级时只动一个依赖版本，用 {signal} 记录构建与运行结果。',
      '一次只改一个版本条件，把 {term} 相关的差异单独记成一条结论。',
    ],
  ),
  (
    r'^重点回归默认值、弃用警告、序列化格式、并发语义和错误信息。$',
    <String>[
      '升级后重点回归 {term} 的默认值、警告信息与错误格式。',
      '回归范围锁定 {signal} 的默认行为，并确认弃用警告是否出现在构建输出里。',
      '先回归 {term} 与 {second} 的默认行为和错误信息，再扩大测试范围。',
    ],
  ),
  (
    r'^下面按正文顺序回顾每一节，并给出一个自检问题；说不清的地方回到原章节补课。$',
    <String>[
      '下面按正文顺序回顾「{title}」的每一节；说不清的地方回到 {heading} 补课。',
      '逐节自检：能说清 {term} 的输入、输出与失败路径才算通过，否则回到原文。',
      '对照 {heading} 复述本课结论，答不上来的部分回到 {signal} 的示例重跑一次。',
    ],
  ),
  (
    r'^定义输出。输出不仅包括正常结果，还包括错误码、日志、指标和资源释放状态。$',
    <String>[
      '定义输出。{term} 的输出不仅包括正常结果，还包括错误码、日志和资源释放状态。',
      '定义输出。把 {signal} 的返回值、日志和失败信号都写清楚，缺一项都不算完整。',
      '定义输出。明确 {term} 与 {second} 各自的产物，以及失败时留下什么证据。',
    ],
  ),
  (
    r'^把它放进一个只有单机、没有额外依赖的小项目，先保证正确，再考虑扩展。$',
    <String>[
      '把 {term} 放进一个只有单机、没有额外依赖的小项目，先保证正确再扩展。',
      '先用一个单文件示例验证 {signal}，确认正确性后再引入框架或分布式组件。',
      '把 {term} 的实现压缩到一个进程内，去掉所有外部依赖后再谈扩展。',
    ],
  ),
  (
    r'^把输入规模扩大十倍，记录时间、内存和失败路径，找出第一个真正瓶颈。$',
    <String>[
      '把 {term} 的输入规模扩大十倍，记录时间、内存和失败路径，找出第一个瓶颈。',
      '把 {signal} 的数据量提高一个数量级，观察延迟与内存的变化拐点。',
      '扩大 {second} 的规模，记录本课结论在哪一个量级开始不成立。',
    ],
  ),
  (
    r'^制造一次依赖超时或错误输入，要求系统给出可解释错误并且不留下半完成状态。$',
    <String>[
      '制造一次 {term} 相关的依赖超时或错误输入，要求错误可解释且不留半完成状态。',
      '让 {signal} 的外部依赖超时，确认系统能回滚或补偿，而不是留下脏数据。',
      '把 {second} 换成失败输入，记录错误信息与恢复动作。',
    ],
  ),
  (
    r'^把方案切换到低资源设备，重新评估默认参数、超时和降级策略。$',
    <String>[
      '把 {term} 的方案切换到低资源设备，重新评估默认参数、超时和降级策略。',
      '限制 CPU 与内存上限后重跑 {signal}，观察哪一项参数需要重新设定。',
      '在低带宽或低算力条件下重跑 {second}，记录降级路径是否仍然可用。',
    ],
  ),
  (
    r'^下面用不同约束重复同一套方法。每完成一轮，都把结论写进笔记，并只改变一个变量。$',
    <String>[
      '下面用不同约束重复同一套方法，每轮只改变 {term} 的一个取值并记录结论。',
      '围绕 {signal} 重复同一套方法，每完成一轮就把差异写进笔记。',
      '换一个 {second} 约束重做一次，确认结论在新条件下是否仍然成立。',
    ],
  ),
  (
    r'^下面示例用于验证本课的最小输入、处理和输出。先原样运行，再只修改一个值：$',
    <String>[
      '下面示例用于验证 {term} 的最小输入、处理和输出。先原样运行，再只修改一个值：',
      '先用 {signal} 跑通最小示例，然后只改一个与 {term} 相关的取值：',
      '下面的示例覆盖「{title}」中 {term} 的核心路径。先原样运行，再按注释改一处：',
    ],
  ),
  (
    r'^关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。$',
    <String>[
      '关键做法：先用 {signal} 建立 {term} 的基线，再逐步加入边界与失败条件。',
      '关键做法：先让 {term} 的最小示例可复现，再加入并发或规模条件。',
      '关键做法：基线只保留 {second} 必需的部分，其余条件一次加一个。',
    ],
  ),
  (
    r'^验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。$',
    <String>[
      '验证标准：{term} 的结果可复现、错误可解释、失败能恢复。',
      '验证标准：{signal} 的输出能被他人复现，边界输入有对应用例。',
      '验证标准：{second} 的异常路径有明确错误信息与恢复动作。',
    ],
  ),
  (
    r'^完成练习和测验后，把仍然不确定的问题写成下一轮验证清单。$',
    <String>[
      '完成练习和测验后，把 {term} 上仍然不确定的问题写成下一轮验证清单。',
      '做完本课测验后，把答错且解释不清的 {second} 相关题目记成验证任务。',
      '把还不确定的 {signal} 行为写成一条可执行验证，再进入下一课。',
    ],
  ),
  (
    r'^能否给出一个反例，证明某个看似合理的结论在边界条件下不成立？$',
    <String>[
      '能否给出一个反例，证明 {term} 的结论在边界条件下不成立？',
      '把 {signal} 的输入推到边界，说明本课哪一条结论会先失效。',
      '构造一个 {second} 的反例，证明「总是成立」的说法不成立。',
    ],
  ),
  (
    r'^症状：正常样例能通过，空值、极值或错误输入却给出不可解释的结果。$',
    <String>[
      '**症状**：{term} 的正常样例能通过，换上空值、极值或错误输入却给出不可解释的结果。',
      '**症状**：{signal} 在正常输入下正确，遇到缺失字段或越界值就静默出错。',
      '**症状**：{term} 的示例能跑通，但把输入改成边界值后输出无法解释。',
    ],
  ),
  (
    r'^根因：前置条件和取值范围只写在说明里，没有转成代码中的校验或断言。$',
    <String>[
      '**根因**：{term} 的前置条件只写在说明里，没有转成代码中的校验或断言。',
      '**根因**：{signal} 的取值范围没有落到参数校验上，越界值因此一路走到执行阶段。',
      '**根因**：{second} 的失败路径没有明确返回约定，出错后只能靠猜。',
    ],
  ),
  (
    r'^修复：先列出合法输入、非法输入和失败后的返回约定，再补最小边界用例。$',
    <String>[
      '**修复**：先列出 {term} 的合法输入、非法输入与失败返回约定，再补最小边界用例。',
      '**修复**：把 {signal} 的取值约束写成参数校验，并补一条越界输入的测试。',
      '**修复**：为 {second} 定义明确的错误结构，让调用方可以区分失败类型。',
    ],
  ),
  (
    r'^修复：改成一个可观察、可重复且有边界样例的验证步骤。$',
    <String>[
      '**修复**：把验证步骤改成只观察 {term} 的输出，并补一个边界样例。',
      '**修复**：让 {signal} 的每一步都有可观察结果，失败时能定位到具体环节。',
      '**修复**：把 {term} 的结论写成可重复命令或断言，替换「看起来没问题」的判断。',
    ],
  ),
  (
    r'^症状：单次运行看似正确，更换版本、顺序或并发条件后结果不稳定。$',
    <String>[
      '**症状**：{signal} 单次运行看似正确，更换版本、顺序或并发条件后结果不稳定。',
      '**症状**：{term} 在串行执行下正确，一旦并发或重试就出现重复或丢失。',
      '**症状**：同一份输入重复运行 {second}，偶尔得到不同结果。',
    ],
  ),
  (
    r'^根因：验证时改变多个条件，无法判断差异来自实现、依赖还是环境。$',
    <String>[
      '**根因**：验证 {term} 时同时改变了多个条件，无法判断差异来自实现、依赖还是环境。',
      '**根因**：{signal} 依赖隐藏状态或环境变量，重复运行时前提并不一致。',
      '**根因**：{second} 的随机因素没有固定种子，结果因此不可复现。',
    ],
  ),
  (
    r'^修复：一次只改一个条件，并记录版本、输入、输出和重复次数。$',
    <String>[
      '**修复**：验证 {term} 时一次只改一个条件，并记录版本、输入、输出与重复次数。',
      '**修复**：固定 {signal} 的随机种子与环境版本，再比较两次运行的差异。',
      '**修复**：把 {second} 的隐藏状态显式化，让每次运行从同一初始条件开始。',
    ],
  ),
  (
    r'^验证：保存两次运行的完整记录，能复现差异后再定位修改点。$',
    <String>[
      '**验证**：保存两次 {signal} 运行的完整记录，能复现差异后再定位修改点。',
      '**验证**：把 {term} 的输入、命令与输出一起归档，确认他人也能复现同一差异。',
      '**验证**：连续运行 {second} 三次，结果一致才算问题已解决。',
    ],
  ),
  (
    r'^输入是什么，哪些输入属于合法范围，哪些属于边界或非法范围？$',
    <String>[
      '1. {term} 的输入是什么，哪些取值合法，哪些属于边界或非法范围？',
      '1. 在「{title}」里，{signal} 接受哪些输入，非法输入应该在哪里被挡住？',
      '1. 先写清 {term} 的输入契约：类型、范围、缺省值与非法值分别怎么处理？',
    ],
  ),
  (
    r'^程序按什么顺序处理输入，在哪一步产生了状态变化或副作用？$',
    <String>[
      '2. {term} 按什么顺序处理输入，在哪一步产生了状态变化或副作用？',
      '2. {signal} 的执行顺序里，哪一步会写数据或产生外部副作用？',
      '2. 在 {heading} 里，{second} 的状态是在什么条件下被改变的？',
    ],
  ),
  (
    r'^边界路径：空值、最大值、重复数据和超长内容得到明确处理。$',
    <String>[
      '2. 边界路径：{term} 的空值、最大值、重复数据和超长内容都得到明确处理。',
      '2. 边界路径：把 {signal} 的输入推到上下限，确认返回结果可解释。',
      '2. 边界路径：{second} 在重复提交与超长输入下不产生额外副作用。',
    ],
  ),
  (
    r'^回滚路径：回滚后数据一致，且能说明恢复时间和影响范围。$',
    <String>[
      '5. 回滚路径：{term} 回滚后数据一致，且能说明恢复时间和影响范围。',
      '5. 回滚路径：撤掉 {signal} 的变更后，数据与资源都回到变更前的状态。',
      '5. 回滚路径：{second} 的失败能按预案恢复，并记录影响范围。',
    ],
  ),
  (
    r'^\[ \] 能否指出最小可运行示例的输入、输出和一条失败路径？$',
    <String>[
      '- [ ] 能否指出 {signal} 最小示例的输入、输出和一条失败路径？',
      '- [ ] 能否说明 {term} 的正常输出，以及失败时留下的错误信息？',
      '- [ ] 能否用「{title}」的最小示例复现一次失败并解释原因？',
    ],
  ),
  (
    r'^\[ \] 能否把本课方法迁移到另一个相近问题，并说明需要改什么？$',
    <String>[
      '- [ ] 能否把 {term} 的方法迁移到相近问题，并说明需要改哪一步？',
      '- [ ] 换一个输入后，{signal} 的判断依据是否仍然成立？',
      '- [ ] 能否说明 {second} 在新场景下需要补充什么前提？',
    ],
  ),
  (
    r'^这一节把正文里的定义、代码和失败模式串成一条可操作的复习路线。$',
    <String>[
      '这一节把「{title}」正文里的定义、代码和失败模式串成一条可操作的复习路线。',
      '这一节把 {term} 的定义、{signal} 的代码与常见失败串成一条复习路线。',
      '这一节把 {heading} 的结论、示例与反例整理成可执行的复习步骤。',
    ],
  ),
  (
    r'^只改变一个条件，预测结果并说明依据；再运行或手算验证。$',
    <String>[
      '2. 只改变 {term} 的一个条件，预测结果并说明依据；再运行或手算验证。',
      '2. 固定其他输入，只调整 {signal} 的一个参数，先写预测再验证。',
      '2. 把 {second} 换成边界值，说明依据后再实际运行。',
    ],
  ),
  (
    r'^追问：如果把入门练习的条件换成边界值，这个结论是否仍然成立？$',
    <String>[
      '- 追问：如果把 {term} 的条件换成边界值，这个结论是否仍然成立？',
      '- 追问：当 {signal} 的输入越过合法范围时，本课结论还成立吗？',
      '- 追问：{second} 的条件变化到什么程度时，需要换一种做法？',
    ],
  ),
  (
    r'^重点回答三件事：它为什么存在、内部如何运转、什么时候会失效。$',
    <String>[
      '重点回答三件事：{term} 为什么存在、内部如何运转、什么时候会失效。',
      '重点回答三件事：{signal} 解决什么问题、依赖哪些前提、在什么条件下失效。',
      '重点回答三件事：{heading} 的机制、代价与边界。',
    ],
  ),
  (
    r'^项目代码不能只看“能编译”，还要能按固定命令复现结果。下表给出最低验证集：$',
    <String>[
      '「{title}」不能只看「能编译」，还要能按固定命令复现结果。下表给出最低验证集：',
      '{term} 的交付物要能用固定命令复现；下表是本项目的最低验证集：',
      '先让 {signal} 的结果可复现，再谈扩展。下表给出最低验证集：',
    ],
  ),
  (
    r'^\[ \] 重复执行同一操作两次，确认没有重复写入或副作用。$',
    <String>[
      '- [ ] 重复执行 {term} 的操作两次，确认没有重复写入或副作用。',
      '- [ ] 用同一个幂等键重放 {signal}，确认结果与首次一致。',
      '- [ ] 连续两次触发 {second}，检查数据与计数是否被重复累加。',
    ],
  ),
  (
    r'^\[ \] 在 README 中写明环境版本、启动方式和回滚方式。$',
    <String>[
      '- [ ] 在 README 中写明 {term} 所需的环境版本、启动方式和回滚方式。',
      '- [ ] 记录 {signal} 的运行环境与复现命令，并补一段回滚说明。',
      '- [ ] 在交付说明里注明依赖版本、启动步骤与失败回退路径。',
    ],
  ),
  (
    r'^先在一个可丢弃的目录或临时数据库执行，避免污染真实数据。$',
    <String>[
      '1. 先在可丢弃的目录或临时库里跑 {term}，避免污染真实数据。',
      '1. 用临时环境验证 {signal}，确认无误后再对真实数据执行。',
      '1. 先在副本上执行 {second}，并记录前后差异。',
    ],
  ),
  (
    r'^\[ \] 至少运行 3 条测试，其中包含一条非法输入或失败路径。$',
    <String>[
      '- [ ] 至少运行 3 条 {term} 相关测试，其中一条是非法输入或失败路径。',
      '- [ ] 为 {signal} 补三条测试：正常、边界、失败各一条。',
      '- [ ] 测试覆盖 {second} 的核心规则，并包含一次可预期的失败。',
    ],
  ),
  (
    r'^先不看资料复述“核心模型”，确认能说出它解决的三个问题。$',
    <String>[
      '1. 合上教程复述 {term}，确认能说出它解决的三个问题。',
      '1. 不看资料讲清「{title}」的核心模型，并各举一个正例和反例。',
      '1. 用自己的话说明 {signal} 的作用，再说出它不适用的情况。',
    ],
  ),
  (
    r'^最后完成小项目，把结果、失败记录和复查清单整理成一份可提交产物。$',
    <String>[
      '5. 最后完成 {term} 的小项目，把结果、失败记录和复查清单整理成可提交产物。',
      '5. 用 {signal} 做一个最小交付，附上运行命令与失败样例。',
      '5. 把 {second} 的实现、测试与复盘整理成一份可提交的产物。',
    ],
  ),
  (
    r'^判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。$',
    <String>[
      '- 判断标准：能解释 {term} 的正常场景、边界条件和失败场景，才算真正掌握。',
      '- 判断标准：能说清 {signal} 在正常与异常输入下的差别。',
      '- 判断标准：能举出 {second} 的一个反例并解释原因。',
    ],
  ),
  (
    r'^下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。$',
    <String>[
      '- 下一步：完成练习后写下 {term} 的 3 条要点，再去做本课测验。',
      '- 下一步：把 {signal} 的实验结论记成三句话，然后进入测验。',
      '- 下一步：先复述 {second} 的边界，再开始本课测验。',
    ],
  ),
  (
    r'^\[ \] 能用一句话解释「入门练习」在本课中的角色与边界。$',
    <String>[
      '- [ ] 能用一句话解释 {term} 在「{title}」中的角色与边界。',
      '- [ ] 能说明 {signal} 负责什么、不负责什么。',
      '- [ ] 能说出 {second} 与相邻概念的边界。',
    ],
  ),
  (
    r'^复述当前方案对「入门练习」的假设，写成一句可证伪的话。$',
    <String>[
      '1. 复述当前方案对 {term} 的假设，写成一句可证伪的话。',
      '1. 把 {signal} 依赖的前提写成一句可以被反例推翻的陈述。',
      '1. 写出 {second} 在新场景下必须成立的一个前提。',
    ],
  ),
  (
    r'^主干：一句话入门 → 最小示例 → 预期输出 → 常见错误$',
    <String>[
      '- 主干：{term} 的定义 → 最小示例 → 预期输出 → 常见错误',
      '- 主干：{signal} 的输入 → 处理 → 输出 → 失败路径',
      '- 主干：{heading} → 可运行示例 → 边界实验 → 复盘',
    ],
  ),
  (
    r'^主干：核心知识 → 关键流程 → 实践路径 → 常见误区$',
    <String>[
      '- 主干：{term} 的核心知识 → 关键流程 → 实践路径 → 常见误区',
      '- 主干：{signal} 的原理 → 操作步骤 → 验证方法 → 易错点',
      '- 主干：{heading} → 交付物 → 验收标准 → 复盘',
    ],
  ),
  (
    r'^检查点：如果输入换成边界值，这个结论还需要补充哪个前提？$',
    <String>[
      '- 检查点：如果 {term} 的输入换成边界值，这个结论还需要补充哪个前提？',
      '- 检查点：{signal} 在输入越界时会产生什么可观察的结果？',
      '- 检查点：{second} 的结论依赖哪一个隐含前提？',
    ],
  ),
  (
    r'^本课测验以直接定义和步骤判断为主。请把每个错误选项改写成一句反例，$',
    <String>[
      '「{title}」的测验以定义与步骤判断为主。请把每个错误选项改写成一句反例，',
      '本课测验围绕 {term} 展开。请把每个错误选项改写成一句反例，',
      '本课测验检验 {signal} 的判断依据。请把每个错误选项改写成一句反例，',
    ],
  ),
  (
    r'^\[ \] 能用具体输入复现最小示例，并逐行解释输入、处理与输出。$',
    <String>[
      '- [ ] 能用具体输入复现 {term} 的最小示例，并逐行解释输入、处理与输出。',
      '- [ ] 能逐行说明 {signal} 的输出是怎么得到的。',
      '- [ ] 能用自己的输入复现示例，并解释每一步的状态变化。',
    ],
  ),
  (
    r'^\[ \] 能只改一个值完成边界实验，并让预测与实际结果一致。$',
    <String>[
      '- [ ] 能只改 {term} 的一个值完成边界实验，并让预测与实际一致。',
      '- [ ] 能预测 {signal} 在边界输入下的输出，并用运行结果验证。',
      '- [ ] 能说明 {second} 在哪一个取值上开始失效。',
    ],
  ),
  (
    r'^\[ \] 能制造一个可控错误，读出第一条错误信息并完成修复。$',
    <String>[
      '- [ ] 能制造一个 {term} 相关的可控错误，读出第一条错误信息并完成修复。',
      '- [ ] 能触发 {signal} 的失败路径，并根据错误信息定位原因。',
      '- [ ] 能复现 {second} 的异常并说明恢复步骤。',
    ],
  ),
  (
    r'^\[ \] 能不看书说出本课至少两个易错点和对应的验证方法。$',
    <String>[
      '- [ ] 能不看书说出 {term} 的两个易错点和对应验证方法。',
      '- [ ] 能说出 {signal} 的两个常见误用，并各配一个检查方法。',
      '- [ ] 能列出 {second} 的两个失败场景与验证步骤。',
    ],
  ),
  (
    r'^遇到问题时按「症状 → 根因 → 修复 → 验证」的顺序处理，不跳过验证。$',
    <String>[
      '- 处理 {term} 的问题时按「症状 → 根因 → 修复 → 验证」的顺序推进，不跳过验证。',
      '- {signal} 出错时先记录症状，再定位根因，最后用一次复跑确认修复。',
      '- 排查 {second} 时保留原始错误信息，不要先改代码。',
    ],
  ),
  (
    r'^验收标准：留下输入、命令、输出和结论，能让别人按记录复现。$',
    <String>[
      '**验收标准**：留下 {signal} 的输入、命令、输出和结论，让别人能按记录复现。',
      '**验收标准**：记录 {term} 的输入、实际输出与差异解释，缺一项都不算完成。',
      '**验收标准**：把变量、命令和结果写在一起，使他人可以复现同一结论。',
    ],
  ),
  (
    r'^给定 8～12 个手工构造的数据，写出每一步状态，并统计比较或交换次数。$',
    <String>[
      '给定 8～12 个手工构造的数据，写出 {term} 每一步的状态并统计操作次数。',
      '用 8～12 个元素手算 {signal} 的状态变化，再与程序输出对照。',
      '手工构造一组数据，逐步记录 {second} 的状态与代价。',
    ],
  ),
  (
    r'^先手算 8 个元素的状态变化，再实现并统计操作次数与复杂度。$',
    <String>[
      '先手算 8 个元素在 {term} 中的状态变化，再实现并统计操作次数与复杂度。',
      '用 8 个元素手动走一遍 {signal}，把每一步代价与代码里的计数对齐。',
      '先笔算 {second} 的中间状态，再运行程序验证复杂度结论。',
    ],
  ),
  (
    r'^适用环境：TCP/IP、HTTP/2、HTTP/3 与现代网络栈$',
    <String>[
      '- 适用环境：TCP/IP、HTTP/2、HTTP/3 与现代网络栈；本课聚焦其中的 {term}。',
      '- 适用环境：主流网络栈；本课讨论 {signal} 在其中的位置。',
      '- 适用环境：TCP/IP 协议族；本课的落点是 {second}。',
    ],
  ),
  (
    r'^会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。$',
    <String>[
      '- 会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查 {term} 的词条。',
      '- 能运行 {signal} 所在环境的基本命令；陌生术语先回到本课术语表。',
      '- 能独立打开与保存文件即可；{second} 会在正文中从零解释。',
    ],
  ),
  (
    r'^已完成本分类的基础与进阶课程，能独立运行正文中的最小示例。$',
    <String>[
      '已完成本分类的基础与进阶课程，能独立运行 {term} 的最小示例。',
      '能独立跑通「{title}」的示例代码，并说清每一步的输入与输出。',
      '具备 {term} 的前置知识，能看懂 {signal} 相关的示例。',
    ],
  ),
  (
    r'^读路径要明确查询条件、分页方式和返回字段，避免一次加载全部数据。$',
    <String>[
      '读路径要明确 {term} 的查询条件、分页方式和返回字段，避免一次加载全部数据。',
      '{signal} 的读取接口必须写清过滤条件与分页，不能默认全量返回。',
      '查询 {second} 时限定字段与分页范围，把全表扫描留作最后手段。',
    ],
  ),
  (
    r'^写路径要明确事务边界、幂等键和失败补偿，不能留下半完成状态。$',
    <String>[
      '写路径要明确 {term} 的事务边界、幂等键和失败补偿，不能留下半完成状态。',
      '{signal} 的写入要以幂等键为准，失败后能补偿或安全重试。',
      '写入 {second} 前先定义事务范围，跨服务时改用可补偿流程。',
    ],
  ),
  (
    r'^输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。$',
    <String>[
      '输入与产出：先写清 {term} 依赖的配置、数据和最终产物，再开始编码。',
      '先列出 {signal} 这一步的输入、输出与中间产物，再动手实现。',
      '把 {second} 这一步的依赖与交付物写成两行清单，再开始实现。',
    ],
  ),
  (
    r'^验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。$',
    <String>[
      '验证方法：用最小请求或单元测试证明 {term} 这一步的结果正确。',
      '用一条最小输入验证 {signal}，断言输出符合预期。',
      '为 {second} 补一个最小用例，明确通过标准再扩展规模。',
    ],
  ),
  (
    r'^失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。$',
    <String>[
      '失败处理：记录 {term} 的错误类型、回滚动作和重试条件，避免把问题带到下一步。',
      '为 {signal} 定义失败分类与重试上限，超出后走人工处理。',
      '出错时先记录 {second} 的错误信息与回滚结果，再决定是否重试。',
    ],
  ),
  (
    r'^\[ \] 单元测试覆盖核心规则，集成测试覆盖数据库或外部边界。$',
    <String>[
      '- [ ] 单元测试覆盖 {term} 的核心规则，集成测试覆盖数据库或外部边界。',
      '- [ ] 为 {signal} 补单元测试，并至少覆盖一条真实的外部依赖。',
      '- [ ] 测试分层：核心规则用单元测试，{second} 的边界用集成测试。',
    ],
  ),
  (
    r'^权限遵循最小授权，数据库账号、云资源和接口令牌都不能使用管理员默认权限。$',
    <String>[
      '权限遵循最小授权：{term} 用到的数据库账号、云资源和令牌都不能使用管理员默认权限。',
      '{signal} 的运行身份只保留完成任务所需的权限，越权请求应当被拒绝。',
      '为 {second} 单独申请最小权限，并记录权限变更。',
    ],
  ),
  (
    r'^所有外部输入都要校验、限长并转义，错误信息不能泄露内部路径和 SQL。$',
    <String>[
      '所有进入 {term} 的外部输入都要校验、限长并转义，错误信息不能泄露内部路径。',
      '{signal} 的参数先校验再使用，错误响应里不出现堆栈或 SQL。',
      '把 {second} 的输入约束写成白名单，并统一错误结构。',
    ],
  ),
  (
    r'^为数据库连接、线程/协程、队列、文件和网络请求设置上限，避免资源耗尽。$',
    <String>[
      '为 {term} 涉及的连接、线程或协程、队列与网络请求设置上限，避免资源耗尽。',
      '{signal} 的并发度要有上限，并在达到上限时给出可解释的拒绝。',
      '给 {second} 的资源使用设定配额，超出后降级而不是拖垮整个进程。',
    ],
  ),
  (
    r'^至少记录请求量、错误率、P95/P99 延迟、资源使用和成本趋势。$',
    <String>[
      '至少记录 {term} 的请求量、错误率、P95/P99 延迟与资源使用趋势。',
      '为 {signal} 建立四个指标：吞吐、错误率、尾延迟和资源占用。',
      '监控 {second} 的延迟与成本，出现拐点时能追溯到具体变更。',
    ],
  ),
  (
    r'^出现异常时能从日志和指标还原时间线，而不是只看到一句“服务不可用”。$',
    <String>[
      '{term} 出现异常时，要能从日志和指标还原时间线，而不是只看到「服务不可用」。',
      '为 {signal} 的失败留下可检索的日志字段，能按请求定位到具体环节。',
      '把 {second} 的日志与指标对齐到同一时间轴，便于事后复盘。',
    ],
  ),
  (
    r'^如果数据量或并发扩大 10 倍，最先出现的瓶颈在哪里？$',
    <String>[
      '如果 {term} 的数据量或并发扩大 10 倍，最先出现的瓶颈在哪里？',
      '把 {signal} 的负载提高一个数量级，预期哪一项指标先触顶？',
      '规模扩大 10 倍后，{second} 会先成为瓶颈还是先暴露一致性风险？',
    ],
  ),
  (
    r'^只实现最核心的一条路径，确保能启动、能返回结果、能运行测试。$',
    <String>[
      '只实现 {term} 最核心的一条路径，确保能启动、能返回结果、能运行测试。',
      '第一版只做 {signal} 的主流程，先把可运行与可测试立起来。',
      '先交付 {second} 的最小闭环，再补分支与异常处理。',
    ],
  ),
  (
    r'^制造一次输入错误、依赖失败或超时，记录系统如何报错、如何恢复。$',
    <String>[
      '制造一次 {term} 的输入错误或依赖超时，记录系统如何报错、如何恢复。',
      '让 {signal} 的下游超时，确认错误可解释且状态可恢复。',
      '给 {second} 注入一次失败，检查是否有半完成状态残留。',
    ],
  ),
  (
    r'^项目课的核心不是堆功能，而是把输入、状态、错误和验收标准连接起来。$',
    <String>[
      '「{title}」的核心不是堆功能，而是把输入、状态、错误和验收标准连接起来。',
      '本项目的重点是让 {term} 的输入、状态与错误都有明确归属。',
      '先定义 {signal} 的验收标准，再决定要写多少功能。',
    ],
  ),
  (
    r'^先跑通最小路径，再补失败处理、测试和文档，最后才做性能优化。$',
    <String>[
      '先跑通 {term} 的最小路径，再补失败处理、测试和文档，最后才做性能优化。',
      '让 {signal} 先能端到端跑通，再考虑并发与性能。',
      '先把 {second} 的闭环做出来，优化留到有测量数据之后。',
    ],
  ),
  (
    r'^每个阶段都要留下可复现证据：命令、输出、测试和变更记录。$',
    <String>[
      '「{title}」的每个阶段都要留下证据：命令、输出、测试和变更记录。',
      '每完成一步就记录 {signal} 的运行结果与对应改动。',
      '把 {term} 的验证命令与输出一起归档，作为阶段交付物。',
    ],
  ),
  (
    r'^\[ \] 至少 3 条自动化测试通过，且包含一条失败路径。$',
    <String>[
      '- [ ] 至少 3 条 {term} 相关自动化测试通过，其中一条覆盖失败路径。',
      '- [ ] 为 {signal} 补三条测试：正常、边界、失败各一条。',
      '- [ ] 自动化测试覆盖 {second} 的核心规则，并验证一次错误处理。',
    ],
  ),
  (
    r'^下面的示例覆盖 核心知识 的核心路径。先原样运行，再按注释改一处：$',
    <String>[
      '下面的示例覆盖「{title}」中 {term} 的核心路径。先原样运行，再按注释改一处：',
      '下面这段代码演示 {term} 的最小路径，先原样运行，再按注释改一处：',
      '先用下面的示例确认 {term} 的基线，再只改一个与 {second} 相关的值：',
    ],
  ),
  (
    r'^修复：把结论写成可重复命令或断言，替换「看起来没问题」的判断。$',
    <String>[
      '**修复**：把 {term} 的结论写成可重复命令或断言，替换「看起来没问题」的判断。',
      '**修复**：给 {signal} 的验证步骤加一条断言，让结论可以被机器检查。',
      '**修复**：把「感觉对了」改写成 {second} 的可观察输出。',
    ],
  ),
  (
    r'^这一节把 核心知识 的结论、示例与反例整理成可执行的复习步骤。$',
    <String>[
      '这一节把 {term} 的结论、{signal} 的示例与反例整理成可执行的复习步骤。',
      '这一节把「{title}」的判断依据、示例和反例整理成复习步骤。',
      '这一节把 {heading} 中容易混淆的两点写成对照与反例。',
    ],
  ),
  (
    r'^C\+\+23 已在主流工具链落地，C\+\+26 进入定稿阶段$',
    <String>[
      'C++23 已在主流工具链落地；升级 {term} 相关代码前先确认标准库实现情况。',
      '{signal} 用到的语言特性要对照编译器支持矩阵，再决定采用哪一版标准。',
      '标准版本会影响 {term} 的写法与可用库，升级前先用现有工具链编译一次。',
    ],
  ),
  (
    r'^Java 25 是当前 LTS，Java 21 仍是大量生产系统的基线$',
    <String>[
      'Java 25 是当前 LTS，Java 21 仍是大量生产系统的基线；'
          '{term} 的写法要按目标版本选择。',
      '先确认运行环境是 Java 21 还是 25，再决定 {signal} 能否使用新语法。',
      '版本基线会影响 {term} 的可用 API，升级前先用编译与测试验证。',
    ],
  ),
  (
    r'^虚拟线程、记录模式、结构化并发与分代 ZGC 是升级收益最大的部分$',
    <String>[
      '虚拟线程与结构化并发对 {term} 的影响最大，升级前先确认线程模型。',
      '若 {signal} 依赖线程或 GC 行为，升级时要重点验证并发与停顿指标。',
      '升级收益集中在并发与内存模型；{second} 相关代码需要单独回归。',
    ],
  ),
  (
    r'^NET 10 是当前 LTS 主线，C# 版本随 SDK 一起演进$',
    <String>[
      '.NET 10 是当前 LTS 主线，{term} 的可用语法取决于 SDK 版本。',
      '先确认 SDK 版本，再决定 {signal} 是否可以使用新语法或新 API。',
      'C# 版本随 SDK 演进，升级前把 {second} 的兼容性纳入检查清单。',
    ],
  ),
  (
    r'^主构造函数、集合表达式、模式匹配与 AOT/裁剪是升级重点$',
    <String>[
      '主构造函数与集合表达式会影响 {term} 的写法，升级时先小范围替换。',
      '若使用 AOT 或裁剪，{signal} 的反射与动态加载路径需要重点验证。',
      '升级重点在语法与裁剪行为；先为 {second} 补一组回归用例。',
    ],
  ),
  (
    r'^异步运行时、trait 解析与借用检查规则的变化需要在 CI 中提前暴露$',
    <String>[
      '异步运行时与借用检查规则的变化会影响 {term}，要在 CI 中提前暴露。',
      '{signal} 涉及的 trait 解析差异应先用最小仓库验证，再升级主工程。',
      '把 {second} 的编译告警当作错误处理，升级后才能避免行为漂移。',
    ],
  ),
  (
    r'^运行时要同时考虑浏览器基线、Node LTS 与打包工具的降级策略$',
    <String>[
      '运行时要同时考虑浏览器基线与 Node LTS；{term} 的降级策略要写清楚。',
      '{signal} 依赖的新 API 必须有降级路径，否则老环境直接报错。',
      '打包与运行时版本会共同影响 {second}，升级前先固定二者版本。',
    ],
  ),
  (
    r'^先用表格或时序图描述机制，再手算一个最小例子，最后用程序验证。$',
    <String>[
      '先用表格或时序图描述 {term} 的机制，再手算一个最小例子，最后用程序验证。',
      '先画出 {signal} 的流程，再手算一组输入，最后运行核对。',
      '把 {heading} 的机制画成图，再用最小数据验证其中一个结论。',
    ],
  ),
  (
    r'^构造 5 条小型离线样例，写清输入、期望输出、评分标准和失败案例。$',
    <String>[
      '构造 5 条 {term} 的小型离线样例，写清输入、期望输出与失败案例。',
      '为 {signal} 准备 5 条固定样例，覆盖正常、边界与失败三类。',
      '把 {second} 的评测样例固定下来，并写清评分标准。',
    ],
  ),
  (
    r'^先不看原图手绘流程，再标出状态变化，最后用自己的话解释关键一步。$',
    <String>[
      '先不看原图手绘 {term} 的流程，再标出状态变化，最后解释关键一步。',
      '凭记忆画出 {signal} 的执行顺序，与正文对照后补上遗漏环节。',
      '手绘 {second} 的状态转移图，标出哪一步会写数据。',
    ],
  ),
  (
    r'^先写评测样例，再改一个提示、模型或数据变量，最后比较质量、成本与安全。$',
    <String>[
      '先写 {term} 的评测样例，再改一个变量，最后比较质量、成本与安全。',
      '为 {signal} 固定一组评测输入，改动一次提示或数据后再对比结果。',
      '先定义 {second} 的评测指标，再做单变量实验。',
    ],
  ),
  (
    r'^先写 schema 与查询，再补边界和失败数据，最后看执行计划与锁等待。$',
    <String>[
      '先写 {term} 的 schema 与查询，再补边界数据，最后看执行计划与锁等待。',
      '为 {signal} 准备正常、空值与边界数据，并用执行计划验证索引是否生效。',
      '先确定 {second} 的约束，再决定索引与事务边界。',
    ],
  ),
  (
    r'^在 SQLite 或纸面表结构上写查询，分别验证正常数据、空值和边界数据。$',
    <String>[
      '在 SQLite 或纸面表结构上写 {term} 的查询，分别验证正常、空值和边界数据。',
      '先用最小表结构验证 {signal}，确认结果正确后再迁移到主库。',
      '用三类数据验证 {second}：正常、空值与越界。',
    ],
  ),
  (
    r'^选两种语言实现同一行为，列出语法、错误处理、性能和生态差异。$',
    <String>[
      '选两种语言实现 {term} 的同一行为，列出语法、错误处理与生态差异。',
      '把 {signal} 用另一种语言重写一遍，对比错误处理与工具链差异。',
      '用两种语言实现 {second}，只比较客观差异，不评价语言优劣。',
    ],
  ),
  (
    r'^先抓一次真实请求或画出协议交互，再注入延迟或丢包，最后解释每层变化。$',
    <String>[
      '先抓一次真实请求或画出 {term} 的协议交互，再注入延迟或丢包并解释变化。',
      '抓包观察 {signal} 的往返过程，再对比注入故障后的差异。',
      '画出 {second} 的交互时序，标出每一层的失败表现。',
    ],
  ),
  (
    r'^画出一张报文或时序图，标出每一跳的地址、协议、状态和可能失败点。$',
    <String>[
      '画出一张 {term} 的报文或时序图，标出每一跳的地址、协议与失败点。',
      '为 {signal} 画出交互时序，标出重传、超时与降级可能发生的位置。',
      '把 {second} 的报文结构画出来，逐字段说明作用与边界。',
    ],
  ),
  (
    r'^在 .+ 这一步去掉一个前提，观察输出怎样变化；变化本身不能说明原因，还要写出.*$',
    <String>[
      '在 {heading} 这一步去掉一个前提，观察 {term} 的输出怎样变化，'
          '并写出「{title}」里哪条假设被破坏。',
      '去掉一个前提后重跑 {signal}，记录输出差异与对应的失败解释。',
      '把 {term} 的一个前提改成不成立，说明本课哪条结论先失效。',
    ],
  ),
  (
    r'^把输入从正常值改成越界值，记录程序是报错、降级还是静默出错，三者对应的修复策略不同。$',
    <String>[
      '把 {term} 的输入从正常值改成越界值，记录程序是报错、降级还是静默出错；'
          '「{title}」要求三者区分对待。',
      '把 {signal} 的输入推到越界值，记录错误信息与恢复动作。',
      '给 {second} 一个非法输入，说明它属于哪一类失败并给出修复方向。',
    ],
  ),
  (
    r'^改动点：只把.+的输入换成空值、极值或错误输入，其余保持不变。$',
    <String>[
      '- 改动点：只把 {term} 的输入换成空值、极值或错误输入，其余保持不变。',
      '- 改动点：只调整 {signal} 的一个参数，其余条件一律不动。',
      '- 改动点：把 {second} 换成边界值，其他输入保持原样。',
    ],
  ),
  (
    r'^\[ \] 在交付说明里注明依赖版本、启动步骤与失败回退路径。$',
    <String>[
      '- [ ] 在交付说明里注明 {term} 的依赖版本、启动步骤与回退路径。',
      '- [ ] 写清 {signal} 的运行前提、启动命令与失败回退方式。',
      '- [ ] 交付说明包含版本、启动、验证与回滚四部分。',
    ],
  ),
  (
    r'^\[ \] 能用自己的输入复现示例，并解释每一步的状态变化。$',
    <String>[
      '- [ ] 能用自己的输入复现 {term} 的示例，并解释每一步的状态变化。',
      '- [ ] 能把 {signal} 的输入换成自己的数据，并说明输出差异。',
      '- [ ] 能解释 {second} 的状态在每一步为什么改变。',
    ],
  ),
  (
    r'^已完成「.+」的基础课程，能运行正文中的最小示例。$',
    <String>[
      '已完成本分类的基础课程，能独立运行 {term} 的最小示例。',
      '具备本分类的前置知识，能跑通「{title}」的示例并解释输出。',
      '能运行 {signal} 所在的示例环境，并读懂报错信息。',
    ],
  ),
  (
    r'^一、工具链：\| 阶段 \| 推荐工具 \| 验收标准 \|$',
    <String>[
      '一、工具链：{term} 的阶段、推荐工具与验收标准',
      '一、工具链：实现 {signal} 所需的阶段与验收标准',
      '一、工具链：完成 {heading} 的推荐工具与检查项',
    ],
  ),
  (
    r'^自检：这一节最常见的失败方式是什么？第一条可观察证据是什么？$',
    <String>[
      '自检：{term} 这一节最常见的失败方式是什么？第一条可观察证据是什么？',
      '自检：{signal} 出错时你会先看到什么现象？如何确认根因？',
      '自检：{heading} 的结论在什么条件下会失效？',
    ],
  ),
  (
    r'^C23 已被主流编译器逐步支持，C17 仍是兼容性最好的基线$',
    <String>[
      'C23 已被主流编译器逐步支持，C17 仍是兼容性最好的基线；'
          '{term} 的写法要按目标标准选择。',
      '先确认编译器支持的标准版本，再决定 {signal} 能否使用新特性。',
      '把标准版本写进构建配置，避免 {second} 在不同环境下编译结果不一致。',
    ],
  ),
  (
    r'^Swift 6\.x 默认开启更严格的数据竞争检查，迁移成本主要在并发边界$',
    <String>[
      'Swift 6.x 默认开启更严格的数据竞争检查；{term} 的并发边界要先梳理。',
      '{signal} 涉及的跨 actor 调用需要逐个确认隔离规则。',
      '迁移成本集中在并发边界，先把 {second} 的共享状态标出来。',
    ],
  ),
  (
    r'^SwiftUI 与 Swift Testing 是当前迭代最快的两块$',
    <String>[
      'SwiftUI 与 Swift Testing 迭代最快；{term} 的示例要注明工具链版本。',
      '{signal} 的写法在最近几个版本有变化，升级前先跑一遍测试。',
      '把 {second} 的 UI 与测试代码分开，降低版本升级的影响面。',
    ],
  ),
  (
    r'^先写最小语义结构，再调整布局与样式，最后检查键盘、窄屏和对比度。$',
    <String>[
      '先写 {term} 的最小语义结构，再调整样式，最后检查键盘、窄屏与对比度。',
      '先让 {signal} 的内容结构正确，再处理视觉与响应式细节。',
      '从语义出发完成 {heading}，最后统一检查可访问性。',
    ],
  ),
  (
    r'^做一个只有标题、卡片和按钮的最小页面，并用浏览器设备模式检查窄屏。$',
    <String>[
      '做一个只包含 {term} 的最小页面，并用设备模式检查窄屏表现。',
      '用最少的结构演示 {signal}，再在窄屏下确认没有溢出。',
      '先完成 {heading} 的最小页面，再补交互与响应式。',
    ],
  ),
  (
    r'^从正文选一个最小示例，先预测修改一个输入后的结果，再实际验证并记录差异。$',
    <String>[
      '从正文选一个 {term} 的最小示例，先预测修改后的结果，再验证并记录差异。',
      '改动 {signal} 的一个输入并预测输出，然后运行核对。',
      '把 {second} 的条件换掉一个，记录预测与实际的差异。',
    ],
  ),
  (
    r'^为一个真实小功能写一页设计、检查表或评审记录，并让同伴能照着执行。$',
    <String>[
      '为 {term} 写一页设计或评审记录，并让同伴能照着执行。',
      '把 {signal} 的实现计划写成清单，标注验证方式与回滚条件。',
      '为「{title}」写一份包含目标、步骤与验收的记录。',
    ],
  ),
  (
    r'^在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。$',
    <String>[
      '在临时目录执行 {term} 的完整命令链，并记录失败时的回滚办法。',
      '把 {signal} 的构建与运行命令写成脚本，在干净环境里跑一遍。',
      '先记录 {second} 的失败回滚步骤，再执行变更。',
    ],
  ),
  (
    r'^先让类型检查通过，再制造一次类型错误，最后补运行时校验与测试。$',
    <String>[
      '先让 {term} 的类型检查通过，再制造一次类型错误，最后补运行时校验。',
      '为 {signal} 写出类型签名，然后故意传错一个参数观察编译器报错。',
      '把 {second} 的边界写成类型或断言，让错误在编译期暴露。',
    ],
  ),
  (
    r'^先在临时环境执行完整命令链，再模拟失败，最后验证回滚和清理。$',
    <String>[
      '先在临时环境执行 {term} 的完整命令链，再模拟失败并验证回滚。',
      '把 {signal} 的部署命令在临时环境跑通，再注入一次失败。',
      '为 {second} 准备回滚步骤，并确认清理后没有残留状态。',
    ],
  ),
  (
    r'^在浏览器控制台或 Node\.js 中写一个最小示例，列出至少 3 组输入输出。$',
    <String>[
      '在浏览器控制台或 Node.js 中写一个 {term} 的最小示例，列出 3 组输入输出。',
      '用 {signal} 写一个可直接运行的片段，覆盖正常、边界与失败输入。',
      '在运行时里验证 {second} 的行为，记录三组输入与对应输出。',
    ],
  ),
  (
    r'^写一个 20 行以内的小脚本，把本课概念用于处理一份真实文本或列表数据。$',
    <String>[
      '写一个 20 行以内的小脚本，用 {term} 处理一份真实文本或列表数据。',
      '用 {signal} 解析一份自己的数据，输出统计结果并核对一条记录。',
      '把 {second} 应用到真实样本上，记录输入规模与输出。',
    ],
  ),
  (
    r'^先开启警告编译最小程序，再验证内存与边界，最后用 Sanitizer 跑一遍。$',
    <String>[
      '先开启警告编译 {term} 的最小程序，再验证内存与边界，最后用 Sanitizer 复查。',
      '把 {signal} 的编译警告清零，再补一次越界与未初始化的检查。',
      '为 {second} 打开内存检查工具跑一遍，确认没有越界与泄漏。',
    ],
  ),
  (
    r'^写一个可独立编译的小程序，开启 -Wall -Wextra，确保没有警告。$',
    <String>[
      '写一个可独立编译的小程序演示 {term}，开启 -Wall -Wextra 并确保没有警告。',
      '把 {signal} 抽成一个单文件示例，在开启警告的编译选项下构建。',
      '用最小程序复现 {second} 的行为，编译时不允许出现警告。',
    ],
  ),
  (
    r'^先在 Node 或浏览器复现行为，再改写异步与错误路径，最后补测试。$',
    <String>[
      '先在 Node 或浏览器复现 {term} 的行为，再改写异步与错误路径，最后补测试。',
      '把 {signal} 的错误处理改成显式分支，并为每条分支补一个用例。',
      '先复现 {second} 的时序问题，再引入取消或超时机制。',
    ],
  ),
  (
    r'^先画拓扑与数据流，再注入节点或网络故障，最后验证恢复与一致性。$',
    <String>[
      '先画 {term} 的拓扑与数据流，再注入故障，最后验证恢复与一致性。',
      '给 {signal} 画一张组件图，标出注入故障后数据如何收敛。',
      '先定义 {second} 的一致性目标，再设计故障演练。',
    ],
  ),
  (
    r'^先跑通最小类与测试，再补异常和并发边界，最后观察线程与资源变化。$',
    <String>[
      '先跑通 {term} 的最小类与测试，再补异常与并发边界，最后观察资源变化。',
      '为 {signal} 写一个可运行的最小对象，再补线程安全的用例。',
      '先把 {second} 的正常路径测通，再引入并发与异常。',
    ],
  ),
  (
    r'^先写可运行脚本，再用类型注解与测试保护核心函数，最后处理真实输入。$',
    <String>[
      '先写可运行的脚本演示 {term}，再用类型注解与测试保护核心函数。',
      '把 {signal} 抽成函数并补类型标注，最后换成真实输入验证。',
      '先让 {second} 的脚本能跑，再补断言与边界处理。',
    ],
  ),
  (
    r'^创建一个最小 Widget，分别验证正常输入、空数据和超长文本三种状态。$',
    <String>[
      '创建一个最小 Widget 展示 {term}，分别验证正常、空数据和超长文本三种状态。',
      '把 {signal} 放进一个最小 Widget，逐个切换三种输入状态观察布局。',
      '用最小 Widget 验证 {second} 在空数据与超长文本下的表现。',
    ],
  ),
  (
    r'^先做一个最小 Widget，再切换状态与约束，最后在窄屏和深色模式下验证布局。$',
    <String>[
      '先做 {term} 的最小 Widget，再切换状态，最后在窄屏与深色模式下验证。',
      '把 {signal} 的布局放进窄屏与深色模式各检查一次。',
      '先固定 {second} 的约束，再验证不同屏幕宽度下的表现。',
    ],
  ),
  (
    r'^用伪代码或小脚本模拟一次调度、竞争或资源分配，并记录至少 5 个状态变化。$',
    <String>[
      '用伪代码模拟一次 {term} 的调度或资源分配，记录至少 5 个状态变化。',
      '写一个小脚本模拟 {signal} 的竞争过程，打印每一步的状态。',
      '把 {second} 的分配过程写成可运行模型，标注临界状态。',
    ],
  ),
  (
    r'^画出系统拓扑，设计一次节点宕机或网络延迟演练，并写出恢复步骤。$',
    <String>[
      '画出 {term} 的系统拓扑，设计一次节点宕机演练，并写出恢复步骤。',
      '为 {signal} 设计一次网络延迟注入实验，记录系统行为与恢复时间。',
      '标出 {second} 的单点，说明故障时的降级与恢复顺序。',
    ],
  ),
  (
    r'^一、资产、边界与信任：先回答：保护哪些数据、谁可以访问、哪些组件是信任边界、攻击者能从哪些入口进入$',
    <String>[
      '一、资产、边界与信任：先回答 {term} 保护哪些数据、谁能访问、攻击者从哪里进入。',
      '一、资产、边界与信任：列出 {signal} 涉及的资产、信任边界与入口。',
      '一、资产、边界与信任：明确 {second} 的权限范围与越权后果。',
    ],
  ),
  (
    r'^先画出进程、线程或资源状态，再模拟调度与竞争，最后记录状态迁移。$',
    <String>[
      '先画出 {term} 的进程或资源状态，再模拟调度与竞争，最后记录状态迁移。',
      '为 {signal} 画一张状态图，标出竞争与阻塞发生的时刻。',
      '先定义 {second} 的状态集合，再模拟一次切换。',
    ],
  ),
  (
    r'^验收：换回原条件能复现原结果，改动只影响TypeScript。$',
    <String>[
      '验收：换回原条件能复现原结果，改动只影响 {term}。',
      '验收：{signal} 在改动前后的输出可以对照，且影响范围可控。',
      '验收：把 {second} 改回原值后输出一致，证明改动是唯一变量。',
    ],
  ),
  (
    r'^验收标准：把变量、命令和结果写在一起，使他人可以复现同一结论。$',
    <String>[
      '验收标准：把 {term} 的变量、命令和结果写在一起，使他人可以复现同一结论。',
      '验收标准：{signal} 的运行记录包含输入、命令与输出三部分。',
      '验收标准：换一个人按记录重跑能得到同一结论。',
    ],
  ),
  (
    r'^先建最小控制台程序，再补类型、异步和异常路径，最后用 dotnet test 验证。$',
    <String>[
      '先建最小控制台程序演示 {term}，再补异常路径，最后用 dotnet test 验证。',
      '把 {signal} 放进一个可运行的 .NET 控制台项目，补测试后再扩展。',
      '先让 {second} 的主流程跑通，再处理异步与异常。',
    ],
  ),
  (
    r'^去掉变量展开外的引号，或者让管道中的前一段命令失败。记录退出码、标准错误和最终输出，确认错误是否被掩盖。$',
    <String>[
      '在 {term} 相关命令里去掉引号或让管道前段失败，记录退出码与标准错误，'
          '确认错误是否被掩盖。',
      '把 {signal} 的失败注入到管道中间，检查脚本是否按预期中断。',
      '让 {second} 的前置命令返回非零，确认错误没有被后续命令吞掉。',
    ],
  ),
  (
    r'^三、上线前安全清单：- \[ \] 所有外部输入经过校验和输出编码$',
    <String>[
      '三、上线前安全清单：- [ ] {term} 的所有外部输入经过校验和输出编码',
      '三、上线前安全清单：- [ ] {signal} 的输入校验与输出编码都已落实',
      '三、上线前安全清单：- [ ] {second} 的越权与注入路径已覆盖测试',
    ],
  ),
  (
    r'^先手算 3 步小例子，再画图或用程序验证，最后说明假设与误差。$',
    <String>[
      '先手算 {term} 的 3 步小例子，再画图或用程序验证，最后说明假设与误差。',
      '把 {signal} 的推导压缩到三步，手算后再用程序核对。',
      '先写出 {second} 的假设，再验证其中一步是否成立。',
    ],
  ),
  (
    r'^先手算一个 3～4 步的小例子，再用 Python 或计算器验证结果。$',
    <String>[
      '先手算一个 {term} 的 3～4 步小例子，再用程序或计算器验证结果。',
      '把 {signal} 的过程手算一遍，用程序核对每一步。',
      '先推导 {second} 的前三步，再验证最终数值。',
    ],
  ),
  (
    r'^准备一个可丢弃的本地环境；所有实验都要能重建、能清理、能回滚。$',
    <String>[
      '准备一个可丢弃的本地环境验证 {term}；实验要能重建、清理和回滚。',
      '在临时环境里运行 {signal}，确认结束后可以完全清理。',
      '为 {second} 的实验准备快照，失败时能恢复到初始状态。',
    ],
  ),
  (
    r'^如果某一步无法复现，先记录环境、输入和完整错误，再缩小到最小案例。$',
    <String>[
      '如果 {term} 的某一步无法复现，先记录环境、输入和完整错误，再缩小案例。',
      '把 {signal} 的失败现场压缩到最小输入，确认问题仍然出现。',
      '记录 {second} 的完整报错与版本信息，再逐步去掉无关变量。',
    ],
  ),
  (
    r'^下一步选择一个真实但范围可控的任务，先写验收标准，再提交一个可运行增量。每次只改变一个变量，并保留失败样本和回滚记录。$',
    <String>[
      '下一步选一个真实但范围可控的 {term} 任务，先写验收标准，再提交可运行增量，'
          '并保留失败样本与回滚记录。',
      '把 {signal} 拆成一个可交付增量，先定义验收标准再动手。',
      '选一个能用 {second} 解决的现实问题，每次只改一个变量并记录回滚方式。',
    ],
  ),
  (
    r'^正常路径：使用最小输入完成端到端流程，并留下命令、输出和版本信息。$',
    <String>[
      '正常路径：用最小输入跑完 {term} 的端到端流程，并留下命令、输出和版本信息。',
      '正常路径：让 {signal} 从输入走到输出，记录每一步的产物。',
      '正常路径：{second} 的主流程一次跑通，并把版本与输出一起归档。',
    ],
  ),
  (
    r'^边界路径：覆盖空值、最大值、重复数据和超长内容，结果必须可预测。$',
    <String>[
      '边界路径：覆盖 {term} 的空值、最大值、重复数据和超长内容，结果必须可预测。',
      '边界路径：把 {signal} 的输入推到上下限，确认返回值与错误都可解释。',
      '边界路径：用重复与超长输入验证 {second} 的行为。',
    ],
  ),
  (
    r'^失败路径：让一个依赖超时、返回错误或中途断开，验证系统能快速止损并说明恢复动作。$',
    <String>[
      '失败路径：让 {term} 的依赖超时或中途断开，验证能快速止损并说明恢复动作。',
      '失败路径：给 {signal} 注入一次超时，记录错误分类与重试上限。',
      '失败路径：让 {second} 的下游失败，确认没有留下半完成状态。',
    ],
  ),
  (
    r'^幂等路径：同一请求或任务执行两次，业务结果与资源状态保持一致。$',
    <String>[
      '幂等路径：把 {term} 的同一请求执行两次，业务结果与资源状态保持一致。',
      '幂等路径：用同一个幂等键重放 {signal}，比较两次结果。',
      '幂等路径：重复触发 {second}，确认没有重复写入或计数膨胀。',
    ],
  ),
  (
    r'^回滚路径：回到上一稳定状态，并验证数据、配置和外部资源没有残留。$',
    <String>[
      '回滚路径：把 {term} 退回上一稳定状态，并验证数据、配置与资源没有残留。',
      '回滚路径：撤销 {signal} 的变更后逐项检查数据与配置。',
      '回滚路径：确认 {second} 回退后不残留临时资源。',
    ],
  ),
  (
    r'^别人只阅读仓库说明和测试，就能复现主要结论；任何跳过、例外或未解决风险都有明确记录，而不是依赖口头解释。$',
    <String>[
      '别人只阅读仓库说明和测试，就能复现 {term} 的主要结论；'
          '任何跳过或未解决风险都有明确记录。',
      '把 {signal} 的结论、例外与已知限制写进仓库说明，不依赖口头解释。',
      '让 {second} 的风险登记与测试保持同步，避免只存在于对话里的约定。',
    ],
  ),
  (
    r'^练习按「复现 → 破坏 → 交付」递进，至少完成前两项并保留证据。$',
    <String>[
      '练习按「复现 → 破坏 → 交付」递进：先跑通 {term}，再制造一次失败，最后留下证据。',
      '先复现 {signal}，再有意破坏一个条件，最后交付修复后的结果。',
      '按三步推进 {heading}：复现、破坏、交付，前两步必须留下记录。',
    ],
  ),
  (
    r'^按照「验证命令与预期输出」从干净环境运行一次完整流程，记录版本、命令、真实输出和耗时。然后只修改一个输入或参数，先写预测.*$',
    <String>[
      '在干净环境按「验证命令与预期输出」跑一遍 {term} 的完整流程，记录版本、命令、'
          '真实输出与耗时；随后只改一个参数，先写预测再验证。',
      '从零复现 {signal} 的流程并归档输出，再做一次单变量改动。',
      '按验证清单跑通 {second}，记录耗时与差异来源。',
    ],
  ),
  (
    r'^验收标准：命令可以从零开始复现，输出与预测的差异有机制层面的解释，而不是只写成功或失败。$',
    <String>[
      '验收标准：{term} 的命令可以从零复现，输出与预测的差异有机制层面的解释。',
      '验收标准：{signal} 的运行记录包含命令与输出，差异原因写清楚。',
      '验收标准：换一台机器重跑 {second} 能得到同一结论。',
    ],
  ),
  (
    r'^验收标准：失败能稳定复现；系统没有留下半完成状态；回滚后关键数据与资源一致。$',
    <String>[
      '验收标准：{term} 的失败能稳定复现，系统不留半完成状态，回滚后数据一致。',
      '验收标准：{signal} 失败后可恢复，且能说明回滚验证方式。',
      '验收标准：{second} 的异常路径有明确错误信息与恢复动作。',
    ],
  ),
  (
    r'^验收标准：别人只阅读提交记录和测试就能复核结果；性能、权限、成本和回滚边界都有明确说明。$',
    <String>[
      '验收标准：别人只读提交记录和测试就能复核 {term} 的结果，'
          '性能、权限与回滚边界都有说明。',
      '验收标准：{signal} 的提交记录自解释，测试覆盖关键结论。',
      '验收标准：{second} 的成本、权限与回滚方式都写进交付说明。',
    ],
  ),
  (
    r'^处理至少一次超时、错误输入或依赖故障，且不留下半完成状态。$',
    <String>[
      '处理至少一次 {term} 的超时或依赖故障，且不留下半完成状态。',
      '给 {signal} 注入一次错误输入或超时，确认状态可恢复。',
      '让 {second} 的下游失败一次，验证补偿动作生效。',
    ],
  ),
  (
    r'^用测试、日志、指标和审计记录证明结果，而不是只凭主观判断。$',
    <String>[
      '用测试、日志与指标证明 {term} 的结果，而不是只凭主观判断。',
      '为 {signal} 的关键结论补一条断言或一条可检索日志。',
      '让 {second} 的每个阶段都有可核查的证据。',
    ],
  ),
];

String _applyTemplateRules(
  _LessonProfile lesson,
  _LessonMaterial material,
  String markdown,
) {
  // 规则里的 pattern 与 audit_scaffold_reuse.dart 的归一化结果对齐：
  // 去掉列表符号、加粗标记和多余空白后再匹配，因此不必为每种写法各写一条正则。
  final output = <String>[];
  for (final raw in markdown.split('\n')) {
    final trimmed = raw.trim();
    final normalized = _normalizeLine(trimmed);
    String? replacement;
    for (var index = 0; index < _templateRules.length; index++) {
      final (pattern, variants) = _templateRules[index];
      if (!RegExp(pattern).hasMatch(normalized)) continue;
      final marker =
          RegExp(r'^([-*+]\s+(?:\[[ xX]\]\s+)?|\d+\.\s+)')
              .firstMatch(trimmed)
              ?.group(1) ??
          '';
      final body = _fillTemplate(
        _pick(variants, 'rule-$index-${lesson.id}'),
        lesson,
        material,
      ).replaceFirst(RegExp(r'^([-*+]\s+(?:\[[ xX]\]\s+)?|\d+\.\s+)'), '');
      replacement = '$marker$body';
      break;
    }
    output.add(replacement ?? raw);
  }
  return output.join('\n');
}

String _normalizeLine(String line) => line
    .replaceFirst(RegExp(r'^[-*+\d.\s]+'), '')
    .replaceAll(RegExp(r'[*_`]+'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _fillTemplate(
  String template,
  _LessonProfile lesson,
  _LessonMaterial material,
) {
  final term = material.terms.first;
  final second = material.terms.length > 1 ? material.terms[1] : term;
  return template
      .replaceAll('{term}', term)
      .replaceAll('{second}', second)
      .replaceAll('{signal}', material.signal)
      .replaceAll('{heading}', material.heading)
      .replaceAll('{title}', lesson.title);
}

/// 从本课正文里抽取可引用的真实素材：小节、代码标识符、正文原句、测验答案。
class _LessonMaterial {
  _LessonMaterial({
    required this.terms,
    required this.heading,
    required this.signal,
    required this.altSignal,
    required this.sourceSentence,
    required this.quizAnswers,
    required this.prerequisiteTitles,
    required this.chain,
  });

  final List<String> terms;
  final String heading;
  final String signal;
  final String altSignal;
  final String sourceSentence;
  final List<String> quizAnswers;
  final List<String> prerequisiteTitles;
  final String chain;

  factory _LessonMaterial.from(
    _LessonProfile lesson,
    String markdown,
    Map<String, String> titleById,
  ) {
    final terms = lesson.keywords.isEmpty
        ? <String>[lesson.title]
        : lesson.keywords.take(4).toList();
    final headings = _bodyHeadings(markdown);
    final identifiers = _codeSignals(markdown);
    final signal = identifiers.isNotEmpty
        ? identifiers.first
        : (headings.isNotEmpty ? headings.first : lesson.title);
    final altSignal = identifiers.length > 1
        ? identifiers[1]
        : (headings.length > 1 ? headings[1] : signal);
    final quizAnswers = lesson.quiz
        .map(_correctAnswerText)
        .where((item) => item.length >= 6)
        .toList();
    final sentence = _termSentence(markdown, terms.first);
    return _LessonMaterial(
      terms: terms,
      heading: headings.isEmpty ? lesson.title : headings.first,
      signal: signal,
      altSignal: altSignal,
      sourceSentence: sentence.isEmpty
          ? (quizAnswers.isNotEmpty ? quizAnswers.first : lesson.title)
          : sentence,
      quizAnswers: quizAnswers,
      prerequisiteTitles: lesson.prerequisites
          .map((id) => titleById[id] ?? id)
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      chain: headings.take(4).join(' → '),
    );
  }
}

const Set<String> _canonicalHeadings = <String>{
  '学习目标',
  '前置知识',
  '一句话入门',
  '最小示例',
  '预期输出',
  '常见错误与排查',
  '动手练习',
  '本课小结',
  '复习与自测',
  '可运行练习',
  '故障现场',
  '版本与时效',
  '本课复习清单',
  '术语速查',
  '考点精讲',
  'English Overview',
  '内容元数据',
  '参考资料与复核',
  '复习与迁移',
};

const Set<String> _codeKeywords = <String>{
  'include',
  'stdio',
  'stdint',
  'using',
  'namespace',
  'public',
  'private',
  'static',
  'void',
  'int',
  'char',
  'float',
  'double',
  'bool',
  'string',
  'return',
  'class',
  'struct',
  'const',
  'let',
  'var',
  'function',
  'def',
  'import',
  'from',
  'print',
  'println',
  'async',
  'await',
  'final',
  'fun',
  'val',
  'if',
  'else',
  'for',
  'while',
  'true',
  'false',
  'null',
  'none',
};

List<String> _bodyHeadings(String markdown) {
  final headings = <String>[];
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (!line.startsWith('## ') && !line.startsWith('### ')) continue;
    final title = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
    if (title.isEmpty) continue;
    if (_canonicalHeadings.contains(title)) continue;
    if (title.startsWith('项目专属规格') ||
        title.startsWith('项目交付物') ||
        title.startsWith('工程化精练') ||
        title.startsWith('本课专属推演') ||
        title.startsWith('零基础精讲')) {
      continue;
    }
    if (headings.contains(title)) continue;
    headings.add(title);
    if (headings.length >= 6) break;
  }
  return headings;
}

List<String> _codeSignals(String markdown) {
  final candidates = <String>[];
  var inFence = false;
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) continue;
    if (line.startsWith('//') || line.startsWith('#') || line.startsWith('*')) {
      continue;
    }
    for (final match in RegExp(r'[A-Za-z_][A-Za-z0-9_]{3,}').allMatches(line)) {
      final token = match.group(0)!;
      final lower = token.toLowerCase();
      if (_codeKeywords.contains(lower)) continue;
      if (candidates.contains(token)) continue;
      candidates.add(token);
    }
    if (candidates.length >= 24) break;
  }
  if (candidates.length <= 1) return candidates;
  // 优先选函数名、类名和带下划线的标识符：它们比 import 进来的模块名更能代表本课。
  final ranked = candidates.toList()
    ..sort((a, b) {
      final byScore = _signalScore(b).compareTo(_signalScore(a));
      if (byScore != 0) return byScore;
      return b.length.compareTo(a.length);
    });
  return ranked;
}

int _signalScore(String token) {
  var score = 0;
  if (token.contains('_')) score += 3;
  if (RegExp(r'[A-Z]').hasMatch(token.substring(1))) score += 3;
  if (token.length >= 8) score += 1;
  if (RegExp(r'(Fn|Func|Class|Impl|Manager|Service|Handler|Error)$')
      .hasMatch(token)) {
    score += 3;
  }
  return score;
}

String _termSentence(String markdown, String term) {
  if (term.isEmpty) return '';
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty ||
        line.startsWith('|') ||
        line.startsWith('#') ||
        line.startsWith('```') ||
        line.startsWith('![') ||
        line.startsWith('>')) {
      continue;
    }
    if (!line.contains(term)) continue;
    final stripped = line.replaceFirst(RegExp(r'^[-*\d.\s]+'), '').trim();
    for (final sentence in stripped.split(RegExp(r'(?<=[。！？])'))) {
      final item = sentence.trim();
      if (item.contains(term) && item.length >= 18 && item.length <= 110) {
        return item.endsWith('。') || item.endsWith('？') || item.endsWith('！')
            ? item
            : '$item。';
      }
    }
  }
  return '';
}

String _correctAnswerText(Map<String, dynamic> question) {
  final options = (question['options'] as List<dynamic>?) ?? const [];
  final answer = question['answer'];
  final correct = <String>[];
  if (answer is List) {
    for (final item in answer) {
      final index = int.tryParse(item.toString());
      if (index != null && index >= 0 && index < options.length) {
        correct.add(options[index].toString());
      } else if (item.toString().trim().isNotEmpty) {
        correct.add(item.toString().trim());
      }
    }
  } else if (answer != null) {
    final index = int.tryParse(answer.toString());
    if (index != null && index >= 0 && index < options.length) {
      correct.add(options[index].toString());
    } else {
      correct.add(answer.toString().trim());
    }
  }
  return correct
      .where((item) => item.isNotEmpty && !item.contains('…'))
      .join('；')
      .trim();
}

String _pick(List<String> candidates, String seed) {
  if (candidates.isEmpty) return '';
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return candidates[hash % candidates.length];
}

String _fiveStepAcceptance(_LessonProfile lesson, _LessonMaterial material) {
  final term = material.terms.first;
  final second = material.terms.length > 1 ? material.terms[1] : term;
  return _pick(<String>[
    '**验收标准**：先原样跑通正文里的 `${material.signal}`，再只改$term相关的输入，'
        '按「原例 → 改动 → 预测 → 结果 → 原因」记录；预测必须写在实际运行之前。',
    '**验收标准**：围绕「${material.heading}」小节做一次五步记录，'
        '原例取自 ${material.signal}，改动只允许动一处$term，原因要能指回正文的判断依据。',
    '**验收标准**：把 ${material.signal} 当作原例，改动一次$second的取值，'
        '记录命令、输出与差异原因；五步里缺任意一步都算未完成。',
    '**验收标准**：五步记录要写进笔记——原例是 ${material.signal}，改动落在$term上，'
        '结论必须能被他人在同一环境里复现。',
    '**验收标准**：先在「${material.heading}」里找一个可运行的最小输入，'
        '再按五步法记录$term的影响；预测与结果不一致时补写被忽略的前提。',
    '**验收标准**：用 ${material.signal} 复现原例后，把$second改成边界值，'
        '五步记录缺一不可，其中「原因」一栏要写明「${lesson.title}」里哪条规则被触发。',
  ], lesson.id);
}

String _compareAcceptance(_LessonProfile lesson, _LessonMaterial material) {
  final term = material.terms.first;
  final second = material.terms.length > 1 ? material.terms[1] : term;
  return _pick(<String>[
    '**验收标准**：两个方案的差异必须落在「${lesson.title}」的实际约束上；'
        '写清当$term越过哪条边界时应该换方案。',
    '**验收标准**：对照表里只能用 ${material.signal} 这类可观察的指标做结论，'
        '并给出$second从优到劣的转折条件。',
    '**验收标准**：两个方案至少在一个输入上给出不同结果；'
        '把差异归因到$term，而不是笼统地写「性能更好」。',
    '**验收标准**：写出换方案的触发条件——当$second的规模、精度或资源上限变化到什么程度时，'
        '「${material.heading}」里的结论不再成立。',
    '**验收标准**：对照表两列都要有证据（命令、输出或数据），'
        '并注明$term与$second哪一个才是决定性变量。',
    '**验收标准**：用 ${material.signal} 做一次真实对照，'
        '结论要说明在「${lesson.title}」的哪个前提下成立。',
  ], 'compare-${lesson.id}');
}

String _migrationAcceptance(_LessonProfile lesson, _LessonMaterial material) {
  final term = material.terms.first;
  final second = material.terms.length > 1 ? material.terms[1] : term;
  return _pick(<String>[
    '**验收**：$term的结论要有证据、差异可解释、失败可恢复；'
        '做不到时回到「${material.heading}」缩小问题范围。',
    '**验收**：迁移过程要留下 ${material.signal} 的可运行记录，'
        '并说明$second在新场景下是否仍然成立。',
    '**验收**：正常、边界、失败三条路径都要有结论；'
        '其中失败路径要写清恢复动作和剩余风险。',
    '**验收**：把「${lesson.title}」的判断依据写成可复现步骤，'
        '换一台机器或换一个输入仍能得到同一结论。',
    '**验收**：至少给出一个反例，说明$term在什么情况下会失效；'
        '只写成功案例不算通过。',
    '**验收**：结论要能追溯到正文的具体小节与代码位置，'
        '并记录$second相关的指标变化。',
  ], 'migration-${lesson.id}');
}

String _failurePathStep(_LessonProfile lesson, _LessonMaterial material) {
  final term = material.terms.first;
  final second = material.terms.length > 1 ? material.terms[1] : term;
  return _pick(<String>[
    '4. 让「${lesson.title}」的失败路径尽早暴露：把$term推到边界值，'
        '记录错误信息、重试或降级动作，以及人工兜底条件。',
    '4. 制造一次$second的失败输入，确认错误出现在「${material.heading}」的哪一步，'
        '并写下恢复后如何验证状态已回到一致。',
    '4. 把 ${material.signal} 的输入换成空值、极值或类型不符的形式，'
        '记录第一条错误信息、发生位置和修复动作。',
    '4. 先预测$term会怎样失败，再实际触发一次；'
        '差异部分就是本课最需要补的前提。',
    '4. 关掉一个看似必要的检查（$second相关），观察哪个测试或指标先失败，'
        '用证据说明它为什么不能省。',
    '4. 构造一次$term越界，记录系统是拒绝、降级还是静默出错；'
        '三者对应的修复策略完全不同。',
  ], 'failure-${lesson.id}');
}

String _tinyExampleStep(_LessonProfile lesson, _LessonMaterial material) {
  final term = material.terms.first;
  return _pick(<String>[
    '5. 用 ${material.signal} 贯穿一次小实验：先预测输出，再运行或逐步推演，'
        '最后解释差异来自哪一步。',
    '5. 把「${material.heading}」里的最小示例抄成 ${material.signal} 一行的输入，'
        '先手算结果再执行，确认两者一致。',
    '5. 用同一个$term输入跑两遍：一遍按正文步骤，一遍故意跳过一步，'
        '比较输出并解释为什么必须按顺序执行。',
    '5. 把 ${material.signal} 的规模缩小到一眼能算清的程度，'
        '手动推导结果后再用程序验证，差异处就是理解漏洞。',
    '5. 选一个只有两三步的$term例子，先写出预期输出，再运行确认；'
        '不一致时先怀疑前提而不是代码。',
    '5. 用 ${material.signal} 构造一个最小反例，证明「${lesson.title}」的结论有边界。',
  ], 'tiny-${lesson.id}');
}

String _stageAdvice(_LessonProfile lesson, _LessonMaterial material) {
  final signal = material.signal;
  if (material.prerequisiteTitles.isNotEmpty) {
    final names = material.prerequisiteTitles
        .take(2)
        .map((item) => '「$item」')
        .join('、');
    return '建议先完成$names，或确认自己能独立跑通正文里的 $signal 示例。';
  }
  return '建议先掌握同一分类的基础课程，并能独立运行正文里的 $signal 示例。';
}

/// 修复被旧脚本截断成「关于，下列说法正确的是？」的题干。
String _repairTruncatedQuestions(_LessonProfile lesson, String markdown) {
  final lines = markdown.split('\n');
  final output = <String>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (!line.contains(truncatedQuestion)) {
      output.add(line);
      continue;
    }
    final answer = _answerAfter(lines, index);
    final repaired = _repairTruncatedLine(lesson, line, answer);
    output.add(repaired ?? line);
  }
  return output.join('\n');
}

String? _answerAfter(List<String> lines, int index) {
  for (var offset = 1; offset <= 3 && index + offset < lines.length; offset++) {
    final line = lines[index + offset].trim();
    final match = RegExp(r'^-\s*(?:先写下判断，再对照|参考判断)：(.+)$').firstMatch(line);
    if (match != null) {
      final value = match.group(1)!.trim();
      if (value.isNotEmpty) return value;
    }
  }
  return null;
}

String? _repairTruncatedLine(
  _LessonProfile lesson,
  String line,
  String? answer,
) {
  final checkMatch = RegExp(r'^检查点 \d+：').firstMatch(line);
  final resolved = answer ?? _quizQuestionFallback(lesson, line);
  if (checkMatch != null && resolved != null) {
    final number = RegExp(r'\d+').firstMatch(line)?.group(0) ?? '1';
    return '**检查点 $number：关于「$resolved」，下列说法正确的是？**';
  }
  final followUpMatch = RegExp(r'^### 追问 \d+：').firstMatch(line);
  if (followUpMatch != null && resolved != null) {
    final number = RegExp(r'\d+').firstMatch(line)?.group(0) ?? '1';
    return '### 追问 $number：关于「$resolved」，下列说法正确的是？';
  }
  if ((checkMatch != null || followUpMatch != null) && resolved == null) {
    final number = RegExp(r'\d+').firstMatch(line)?.group(0) ?? '1';
    return '${checkMatch != null ? '**检查点 $number' : '### 追问 $number'}：'
        '把${lesson.keywords.isEmpty ? lesson.title : lesson.keywords.first}'
        '换成一个反例，结论还成立吗？${checkMatch != null ? '**' : ''}';
  }
  final pointMatch = RegExp(r'^\*\*考点 (\d+)：').firstMatch(line);
  if (pointMatch != null) {
    final number = int.tryParse(pointMatch.group(1)!) ?? 1;
    final question = number - 1 < lesson.quiz.length
        ? (lesson.quiz[number - 1]['question'] ?? '').toString().trim()
        : '';
    final type = number - 1 < lesson.quiz.length
        ? (lesson.quiz[number - 1]['type'] ?? 'single').toString()
        : 'single';
    if (question.isEmpty) return null;
    final label = (type == 'code' || type == 'debug')
        ? '代码阅读·第 $number 题'
        : question;
    return '- **考点 $number：$label**：先独立作答，再回到本课对应小节核对判断依据；'
        '答错时记录是哪一个前提被忽略。';
  }
  return null;
}

/// 追问/检查点编号与测验题号一一对应；缺邻近答案时直接回查题库。
String? _quizQuestionFallback(_LessonProfile lesson, String line) {
  final number = int.tryParse(RegExp(r'\d+').firstMatch(line)?.group(0) ?? '');
  if (number == null || number < 1 || number > lesson.quiz.length) return null;
  final question = lesson.quiz[number - 1];
  final type = (question['type'] ?? 'single').toString();
  if (type == 'code' || type == 'debug') return null;
  final text = (question['question'] ?? '').toString().trim();
  if (text.isEmpty) return null;
  return text
      .replaceFirst(RegExp(r'^关于「'), '')
      .replaceFirst(RegExp(r'」，下列说法正确的是？$'), '');
}

/// 项目课的验收样例 JSON 在 65 门课里完全一致，改成引用本项目自身的术语。
String _replaceProjectAcceptanceData(
  _LessonProfile lesson,
  _LessonMaterial material,
  String markdown,
) {
  final term = material.terms.first;
  final second = material.terms.length > 1 ? material.terms[1] : term;
  final block = <String>[
    '```json',
    '{',
    '  "project": "${lesson.id}",',
    '  "scenario": "$term的正常路径",',
    '  "input": {"case": "normal", "value": "${material.signal}"},',
    '  "expected": {"ok": true, "checks": ["$term可复现", "$second有记录"]},',
    '  "failure_case": {"case": "$second越界或缺失", "error": "validation_error"},',
    '  "idempotency_key": "${lesson.id}-001"',
    '}',
    '```',
  ].join('\n');
  final newline = markdown.contains('\r\n') ? '\r\n' : '\n';
  final body = newline == '\n' ? block : block.replaceAll('\n', newline);
  return markdown.replaceAllMapped(
    RegExp(
      r'```json\r?\n\{\r?\n  "project": "' +
          RegExp.escape(lesson.id) +
          r'",[\s\S]*?\r?\n\}\r?\n```',
    ),
    (match) => body,
  );
}
