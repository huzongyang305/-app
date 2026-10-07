// P0 故障现场清理：把跨课复用的占位故障块替换成由本课错误表和关键词
// 生成的三个具体场景。
//
// 用法：
//   dart tool/rebuild_fault_scenarios.dart --dry-run
//   dart tool/rebuild_fault_scenarios.dart
//   dart tool/rebuild_fault_scenarios.dart --ids=<课程id逗号分隔>
//     只处理指定课程，并忽略「是否还残留旧套话」的判断：
//     错误表刚被重写的课程要用这种方式强制重建现场。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String faultHeading = '## 故障现场';
const String reportPath = 'tool/reports/p0_fault_scenario_rebuild.json';

const List<String> genericFaultMarkers = <String>[
  '输出和正文给出的基线对不上',
  '这一步跳过了本课要求的前提，结论自然对不上',
  '先跑正常输入再跑一个边界输入',
  '把关键前提变成隐性假设',
  '检查调用链、输入数据和环境配置',
  '先验证假设再改代码',
  '常规用例通过，但边界用例失败',
  '结果在两次运行之间不一致',
  '程序在开发机很快，换到目标机器后延迟飙升',
  '功能测试全部通过，但越权请求仍然拿到了数据',
  '需求反复变更，代码越改越难验证',
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final onlyIds = _idSet(args);
  final forced = onlyIds.isNotEmpty;
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <Map<String, dynamic>>[
    for (final rawCategory in manifest['categories'] as List<dynamic>)
      for (final raw in (rawCategory as Map)['lessons'] as List<dynamic>)
        (raw as Map).cast<String, dynamic>(),
  ];

  var changedLessons = 0;
  var skippedNoSection = 0;
  var unchanged = 0;
  final samples = <String>[];
  final details = <Map<String, dynamic>>[];

  for (final lesson in lessons) {
    if (forced && !onlyIds.contains(lesson['id'].toString())) continue;
    final file = File(lesson['file'].toString());
    if (!file.existsSync()) continue;
    final markdown = file.readAsStringSync();
    final section = _section(markdown, faultHeading);
    if (section == null) {
      skippedNoSection++;
      continue;
    }
    if (!forced && !genericFaultMarkers.any(section.contains)) {
      unchanged++;
      continue;
    }
    final title = ((lesson['title'] as Map?)?['zh'] ?? lesson['id']).toString();
    final keywords = ((lesson['keywords'] as List?) ?? const [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    final rows = _mistakeRows(markdown);
    final scenarios = _buildScenarios(
      lessonId: lesson['id'].toString(),
      title: title,
      keywords: keywords,
      rows: rows,
    );
    final replacement = _renderFaultSection(scenarios);
    final oldScenarios = _parseFaultScenarios(section);
    var next = _replaceSection(markdown, faultHeading, replacement);
    next = _replaceCrossReferences(next, oldScenarios, scenarios);
    if (next == markdown) continue;
    changedLessons++;
    details.add(<String, dynamic>{
      'lesson_id': lesson['id'].toString(),
      'source_rows': rows.length,
      'scenarios': scenarios.length,
      'original_length': markdown.length,
      'new_length': next.length,
    });
    if (samples.length < 12) {
      samples.add('${lesson['id']}  错误表=${rows.length} 场景=${scenarios.length}');
    }
    if (!dryRun) file.writeAsStringSync(next, flush: true);
  }

  stdout.writeln('模式        ${dryRun ? 'dry-run（不写文件）' : '重建'}');
  stdout.writeln('改动课程     $changedLessons');
  stdout.writeln('已有具体场景 $unchanged');
  stdout.writeln('没有故障章节 $skippedNoSection');
  if (samples.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 抽样 ---');
    for (final sample in samples) {
      stdout.writeln(sample);
    }
  }
  if (!dryRun) {
    final report = <String, dynamic>{
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'dry_run': false,
      'changed_lessons': changedLessons,
      'unchanged_lessons': unchanged,
      'lessons_without_fault_section': skippedNoSection,
      'details': details,
    };
    final file = File(reportPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(report),
      flush: true,
    );
    stdout.writeln('报告          $reportPath');
  }
}

/// 从「常见错误与排查」读取具体错误行；没有表格时退回列表项。
List<_MistakeRow> _mistakeRows(String markdown) {
  final section = _section(markdown, '## 常见错误与排查');
  if (section == null) return const <_MistakeRow>[];
  final rows = <_MistakeRow>[];
  for (final rawLine in section.split('\n')) {
    final line = rawLine.trim();
    if (!line.startsWith('|')) continue;
    if (line.startsWith('| ---') || line.startsWith('|---')) continue;
    final cells = _splitTableRow(line);
    if (cells.length < 3) continue;
    final first = cells[0];
    if (_isHeaderRow(cells)) {
      continue;
    }
    final practice = _cleanCell(first);
    final phenomenon = _cleanCell(cells[1]);
    final fix = _cleanCell(cells[2]);
    if (_isGenericCell(practice) ||
        _isGenericCell(phenomenon) ||
        _isGenericCell(fix)) {
      continue;
    }
    rows.add(_MistakeRow(practice: practice, phenomenon: phenomenon, fix: fix));
  }
  if (rows.length >= 3) return rows;

  for (final rawLine in section.split('\n')) {
    final match = RegExp(r'^\s*(?:[-*+]|\d+[.)、])\s+(.+)$').firstMatch(rawLine);
    if (match == null) continue;
    final text = match.group(1)!.trim();
    if (text.length < 8) continue;
    if (_isGenericCell(text)) continue;
    rows.add(
      _MistakeRow(
        practice: text,
        phenomenon: '执行“$text”后，结果与本课预期不一致',
        fix: '把“$text”改造成可复现检查，并补一个反例',
      ),
    );
    if (rows.length >= 6) break;
  }
  return rows;
}

bool _isGenericCell(String value) {
  final text = _cleanCell(value);
  if (text.length < 6) return true;
  const genericValues = <String>{
    '易错点',
    '容易踩的做法',
    '正确结论',
    '容易写错的做法',
    '实际现象',
    '原因与正确做法',
    '坑',
    '现象',
    '正确做法',
    '问题',
    '原因',
    '解决',
    '症状',
    '根因',
    '修复',
    '验证',
    '错误做法',
    '这一做法会让本课结论无法稳定复现',
    '改成一个可观察、可重复且有边界样例的验证步骤',
    '输入或环境与示例不一致，导致结果不符合预期。',
    '复制命令时遗漏空格、引号或必要参数。',
  };
  if (genericValues.contains(text)) return true;
  return text.contains('直接套用到本课场景') ||
      text.contains('这一做法会让本课结论无法稳定复现') ||
      text.contains('改成一个可观察、可重复且有边界样例的验证步骤') ||
      text.startsWith('这段代码');
}

bool _isHeaderRow(List<String> cells) {
  if (cells.length < 3) return false;
  final first = _cleanCell(cells[0]);
  final second = _cleanCell(cells[1]);
  final third = _cleanCell(cells[2]);
  const headerTokens = <String>{
    '易错点',
    '容易踩的做法',
    '正确结论',
    '容易写错的做法',
    '实际现象',
    '原因与正确做法',
    '坑',
    '现象',
    '正确做法',
    '问题',
    '原因',
    '解决',
    '症状',
    '根因',
    '修复',
    '验证',
    '错误做法',
    '表现',
    '建议',
  };
  if (headerTokens.contains(first) ||
      headerTokens.contains(second) ||
      headerTokens.contains(third)) {
    return true;
  }
  return first.contains('容易踩') ||
      first.contains('易错点') ||
      first.contains('误区') ||
      first.contains('题目') ||
      second.contains('容易踩的做法') ||
      second.contains('实际现象') ||
      third.contains('正确结论') ||
      third.contains('原因与正确做法');
}

List<_FaultScenario> _buildScenarios({
  required String lessonId,
  required String title,
  required List<String> keywords,
  required List<_MistakeRow> rows,
}) {
  if (rows.isNotEmpty) {
    final count = rows.length < 3 ? rows.length : 3;
    final scenarios = <_FaultScenario>[
      for (var index = 0; index < count; index++)
        _FaultScenario(
          title: rows[index].practice,
          symptom: '在《$title》的复现场景中，${rows[index].phenomenon}',
          cause: _specificCause(
            lessonId: lessonId,
            title: title,
            practice: rows[index].practice,
            phenomenon: rows[index].phenomenon,
            index: index,
          ),
          fix: '针对《$title》的问题，${rows[index].fix}',
          verification: _specificVerification(
            lessonId: lessonId,
            title: title,
            practice: rows[index].practice,
            phenomenon: rows[index].phenomenon,
            fix: rows[index].fix,
            index: index,
          ),
        ),
    ];
    final defaults = _defaultScenarios(title, keywords);
    for (final scenario in defaults) {
      if (scenarios.length >= 3) break;
      if (scenarios.any((item) => item.title == scenario.title)) continue;
      scenarios.add(scenario);
    }
    return scenarios;
  }

  return _defaultScenarios(title, keywords);
}

/// 用课程内已经存在的错误现象生成具体根因，避免再次出现只替换课名的模板句。
String _specificCause({
  required String lessonId,
  required String title,
  required String practice,
  required String phenomenon,
  required int index,
}) {
  final variants = <String>[
    '触发点是把“$practice”当成安全做法。它没有满足《$title》要求的前提，'
        '因此先表现为“$phenomenon”；排查时先完整复现这一段，再核对输入、配置与依赖。',
    '“$phenomenon”只是表层结果。向上追溯会落到“$practice”这一步，'
        '因为它省略了《$title》的约束，使实现行为和预期模型发生了偏离。',
    '当出现“$practice”时，执行路径已经绕过了《$title》的关键约束，'
        '最终以“$phenomenon”暴露出来；修复前必须先确认约束在哪里失效。',
  ];
  return variants[_stableVariant(
    '$lessonId|$practice|$index',
    variants.length,
  )];
}

/// 验证步骤围绕本课的失败现象与修复项展开，不再泛泛地要求三类输入。
String _specificVerification({
  required String lessonId,
  required String title,
  required String practice,
  required String phenomenon,
  required String fix,
  required int index,
}) {
  final variants = <String>[
    '在《$title》中按“$fix”调整后，从“$practice”的触发条件重放同一条路径，'
        '确认“$phenomenon”不再出现，并补一个相邻边界用例检查没有引入新问题。',
    '保留《$title》里触发“$phenomenon”的输入、版本和日志，按“$fix”完成修改后原样重放；'
        '只有失败现象消失且相邻场景仍可解释，才保留改动。',
    '先在《$title》中记录“$practice”留下的失败证据，再执行“$fix”并重放；'
        '确认错误路径变为明确结果，且修复没有掩盖同类故障。',
  ];
  return variants[_stableVariant(
    '$lessonId|$phenomenon|$fix|$index',
    variants.length,
  )];
}

int _stableVariant(String seed, int modulo) {
  var hash = 17;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash % modulo;
}

List<_FaultScenario> _defaultScenarios(String title, List<String> keywords) {
  final topic = keywords.isEmpty ? title : keywords.first;
  final secondTopic = keywords.length > 1 ? keywords[1] : topic;
  final thirdTopic = keywords.length > 2 ? keywords[2] : secondTopic;
  return <_FaultScenario>[
    _FaultScenario(
      title: '$topic 的输入边界没有写清',
      symptom: '在《$title》的正常示例中，$topic 的结果符合预期；遇到空值、极值或依赖缺失时却无法解释。',
      cause: '《$title》只写明了 $topic 的主路径，合法范围、失败返回和依赖前提没有转成可执行检查。',
      fix: '为《$title》的 $topic 列出合法、非法和失败三种输入，再补最小边界断言。',
      verification: '在《$title》中固定同一组 $topic 输入重放，确认主路径、失败路径与预期一致。',
    ),
    _FaultScenario(
      title: '$secondTopic 的依赖状态发生变化',
      symptom: '《$title》单次运行看似正确，但更换 $secondTopic 的版本、顺序或并发条件后结果不稳定。',
      cause: '复现《$title》时同时改变了多个条件，无法判断差异来自 $secondTopic 的实现、依赖还是环境。',
      fix: '先固定《$title》的其余条件，只改变 $secondTopic 的一个变量，并记录版本、输入、输出和重复次数。',
      verification: '保存《$title》两次运行围绕 $secondTopic 的完整记录，能复现差异后再定位修改点。',
    ),
    _FaultScenario(
      title: '$title 只验证了顺利路径',
      symptom: '《$title》的课堂示例通过，但 $thirdTopic 在超时、权限不足或资源耗尽时中断。',
      cause: '《$title》只检查了主流程输出，没有为 $thirdTopic 的失败分支设定可观测信号和恢复动作。',
      fix: '为《$title》中的 $thirdTopic 补超时、错误码和降级策略，并保留失败现场证据。',
      verification: '在《$title》中主动注入一次 $thirdTopic 失败，确认系统能给出可解释错误并按预期恢复。',
    ),
  ];
}

String _renderFaultSection(List<_FaultScenario> scenarios) {
  final buffer = StringBuffer('$faultHeading\n\n');
  for (var index = 0; index < scenarios.length; index++) {
    final scenario = scenarios[index];
    buffer
      ..writeln('### 现场 ${index + 1}：${scenario.title}')
      ..writeln()
      ..writeln('**症状**：${_ensureSentence(scenario.symptom)}')
      ..writeln()
      ..writeln('**根因**：${_ensureSentence(scenario.cause)}')
      ..writeln()
      ..writeln('**修复**：${_ensureSentence(scenario.fix)}')
      ..writeln()
      ..writeln('**验证**：${_ensureSentence(scenario.verification)}')
      ..writeln();
  }
  return buffer.toString().trimRight();
}

/// 解析旧故障现场，供深挖章节里的“根因 / 验证”引用做同步替换。
List<_FaultScenario> _parseFaultScenarios(String section) {
  final headingMatches = RegExp(
    r'^###\s+现场\s+\d+：(.+)$',
    multiLine: true,
  ).allMatches(section).toList();
  final scenarios = <_FaultScenario>[];
  for (var index = 0; index < headingMatches.length; index++) {
    final match = headingMatches[index];
    final bodyStart = match.end;
    final bodyEnd = index + 1 < headingMatches.length
        ? headingMatches[index + 1].start
        : section.length;
    final body = section.substring(bodyStart, bodyEnd);
    final symptom = _field(body, '症状');
    final cause = _field(body, '根因');
    final fix = _field(body, '修复');
    final verification = _field(body, '验证');
    if (symptom == null ||
        cause == null ||
        fix == null ||
        verification == null) {
      continue;
    }
    scenarios.add(
      _FaultScenario(
        title: match.group(1)!.trim(),
        symptom: symptom,
        cause: cause,
        fix: fix,
        verification: verification,
      ),
    );
  }
  return scenarios;
}

String? _field(String body, String label) {
  final match = RegExp(
    '^\\*\\*$label\\*\\*：(.+)\$',
    multiLine: true,
  ).firstMatch(body);
  return match?.group(1)?.trim();
}

String _replaceCrossReferences(
  String markdown,
  List<_FaultScenario> oldScenarios,
  List<_FaultScenario> newScenarios,
) {
  var output = markdown;
  final count = oldScenarios.length < newScenarios.length
      ? oldScenarios.length
      : newScenarios.length;
  for (var index = 0; index < count; index++) {
    final old = oldScenarios[index];
    final next = newScenarios[index];
    for (final label in const <String>['症状', '根因', '修复', '验证']) {
      final oldText = '$label：${_fieldValue(old, label)}';
      final newText = '$label：${_fieldValue(next, label)}';
      output = output.replaceAll(oldText, newText);
    }
    // 深挖章节的表格按「现场 N：标题」引用故障场景；场景标题改写后
    // 必须同步，否则读者按表格里的标题在正文中找不到对应现场。
    output = _replaceScenarioTitleReference(
      output,
      number: index + 1,
      oldTitle: old.title,
      newTitle: next.title,
    );
  }
  return output;
}

/// 同步「现场 N：标题」形式的引用。
///
/// 深挖表格的出处列由生成器写入，长标题会被截断成「前缀…」，
/// 因此除了精确匹配，还要接受「引用内容是原标题前缀」的截断写法。
String _replaceScenarioTitleReference(
  String markdown, {
  required int number,
  required String oldTitle,
  required String newTitle,
}) {
  if (oldTitle.isEmpty || oldTitle == newTitle) return markdown;
  final pattern = RegExp(
    '^(\\|\\s*现场\\s*$number：)([^|]*)(\\|)',
    multiLine: true,
  );
  return markdown.replaceAllMapped(pattern, (match) {
    final referenced = match.group(2)!.trim();
    if (!_matchesScenarioTitleReference(referenced, oldTitle)) {
      return match.group(0)!;
    }
    return '${match.group(1)}$newTitle |';
  });
}

/// 引用是否指向原标题：允许精确匹配，也允许「截断 + …」的写法。
bool _matchesScenarioTitleReference(String referenced, String title) {
  if (referenced == title) return true;
  final prefix = referenced.replaceFirst(RegExp(r'(…|\.\.\.)$'), '').trim();
  return prefix != referenced && prefix.isNotEmpty && title.startsWith(prefix);
}

String _fieldValue(_FaultScenario scenario, String label) {
  switch (label) {
    case '症状':
      return scenario.symptom;
    case '根因':
      return scenario.cause;
    case '修复':
      return scenario.fix;
    case '验证':
      return scenario.verification;
    default:
      return '';
  }
}

String? _section(String markdown, String heading) {
  final start = markdown.indexOf(heading);
  if (start < 0) return null;
  final bodyStart = start + heading.length;
  final next = RegExp(
    r'^##\s+',
    multiLine: true,
  ).firstMatch(markdown.substring(bodyStart));
  return next == null
      ? markdown.substring(start)
      : markdown.substring(start, bodyStart + next.start);
}

String _replaceSection(String markdown, String heading, String replacement) {
  final start = markdown.indexOf(heading);
  if (start < 0) return markdown;
  final bodyStart = start + heading.length;
  final next = RegExp(
    r'^##\s+',
    multiLine: true,
  ).firstMatch(markdown.substring(bodyStart));
  final end = next == null ? markdown.length : bodyStart + next.start;
  return '${markdown.substring(0, start)}$replacement\n\n${markdown.substring(end)}';
}

/// 解析 --ids=a,b,c；没有该参数时返回空集合。
Set<String> _idSet(List<String> args) {
  for (final arg in args) {
    if (!arg.startsWith('--ids=')) continue;
    return arg
        .substring('--ids='.length)
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }
  return const <String>{};
}

List<String> _splitTableRow(String line) {
  final escaped = line.trim().replaceAll(r'\|', '\u0000');
  return escaped
      .split('|')
      .map((cell) => cell.replaceAll('\u0000', '\\|').trim())
      .where((cell) => cell.isNotEmpty)
      .toList();
}

String _cleanCell(String value) => value
    .replaceAll(RegExp(r'`+'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'[。；;]+$'), '')
    .trim();

String _ensureSentence(String value) {
  final text = value.trim().replaceAll(RegExp(r'[。；;]+$'), '');
  return '$text。';
}

class _MistakeRow {
  const _MistakeRow({
    required this.practice,
    required this.phenomenon,
    required this.fix,
  });

  final String practice;
  final String phenomenon;
  final String fix;
}

class _FaultScenario {
  const _FaultScenario({
    required this.title,
    required this.symptom,
    required this.cause,
    required this.fix,
    required this.verification,
  });

  final String title;
  final String symptom;
  final String cause;
  final String fix;
  final String verification;
}
