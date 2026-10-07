// P0 残留修复：处理旧生成器留下的三类可见缺陷。
//
// 1. 「常见错误与排查」仍是跨课复用的四行通用表；
// 2. 「故障现场」由那张通用表展开，场景与本课内容无关；
// 3. 「本课复习清单」与正文里混入 `正确答案是「…」` 之类的解析残句。
//
// 修复策略：易错点改由本课测验的正确项与干扰项整理，故障场景再由这些
// 本课专属易错点展开；被截断的复习清单条目改用真实的测验题干重建。
// 所有改写都只使用课程自带内容，不引入外部结论。
//
// 用法：
//   dart tool/repair_p0_residuals.dart --dry-run
//   dart tool/repair_p0_residuals.dart
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String mistakeHeading = '常见错误与排查';
const String faultHeading = '故障现场';
const String checklistHeading = '本课复习清单';
const String reviewedMistakeHeader = '| 易错点 | 容易踩的做法 | 正确结论 |';
const String updatedAt = '2026-10-07';

/// 本工具自己写下的说明行特征：再次运行时用它定位需要改写的表。
const String generatedNoteMarker = '易错点依据本课测验';

/// 本工具写下的故障现场根因特征。
const String generatedFaultMarker = '这一步跳过了本课要求的前提';

/// 旧生成器写下的通用易错点：只要出现就说明这张表还没替换。
const List<String> genericMistakeMarkers = <String>[
  '只记术语不做实验',
  '只测正常路径',
  '没有基线就优化',
  '忽略成本与安全',
];

/// 解析残句特征：旧版把「正确答案是」直接写进了正文与复习清单。
const List<String> leakMarkers = <String>['正确答案是「', '不看解析，能说出的判断依据'];

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final report = <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'dry_run': dryRun,
    'scanned': 0,
    'leak_lines_removed': 0,
    'mistake_tables_rebuilt': 0,
    'fault_sections_rebuilt': 0,
    'checklists_rebuilt': 0,
    'lessons_changed': 0,
    'details': <Map<String, dynamic>>[],
  };

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file']?.toString() ?? '');
      if (!file.existsSync()) continue;
      report['scanned'] = (report['scanned'] as int) + 1;
      final original = file.readAsStringSync();
      var markdown = original;
      final changes = <String>[];

      // 1. 删掉解析残句行。
      final leakLines = <String>[];
      final kept = <String>[];
      for (final line in markdown.split('\n')) {
        final isLeak = leakMarkers.any(line.contains);
        if (isLeak) {
          leakLines.add(line);
        } else {
          kept.add(line);
        }
      }
      if (leakLines.isNotEmpty) {
        markdown = kept.join('\n');
        report['leak_lines_removed'] =
            (report['leak_lines_removed'] as int) + leakLines.length;
        changes.add('删除解析残句 ${leakLines.length} 行');
      }

      final lessonId = lesson['id']?.toString() ?? '';
      final title = ((lesson['title'] as Map?)?['zh'] ?? lessonId).toString();
      final quiz = ((lesson['quiz'] as List?) ?? const []).cast<Map>();

      // 2. 通用错误表 → 由本课测验整理的真实易错点。
      final mistakeSection = _section(markdown, mistakeHeading);
      final needsMistakeRebuild =
          mistakeSection != null &&
          (genericMistakeMarkers.any(mistakeSection.contains) ||
              mistakeSection.contains(generatedNoteMarker));
      var rows = _rowsFromQuiz(quiz, title);
      if (needsMistakeRebuild) {
        if (rows.length >= 3) {
          markdown = _replaceSection(
            markdown,
            mistakeHeading,
            _renderMistakeTable(title, rows),
          );
          report['mistake_tables_rebuilt'] =
              (report['mistake_tables_rebuilt'] as int) + 1;
          changes.add('重建错误表 ${rows.length} 行');
        }
      } else {
        // 已经人工重写过的表：沿用它的易错点，保证故障现场与正文一致。
        rows =
            _rowsFromMistakeTable(_section(markdown, mistakeHeading)) ?? rows;
      }

      // 3. 通用故障现场 → 由本课易错点展开的三个具体现场。
      final faultSection = _section(markdown, faultHeading);
      final needsFaultRebuild =
          faultSection != null &&
          (genericMistakeMarkers.any(faultSection.contains) ||
              faultSection.contains(generatedFaultMarker));
      if (needsFaultRebuild && rows.length >= 3) {
        markdown = _replaceSection(
          markdown,
          faultHeading,
          _renderFaultScenarios(title, rows),
        );
        report['fault_sections_rebuilt'] =
            (report['fault_sections_rebuilt'] as int) + 1;
        changes.add('重建故障现场 3 个');
      }

      // 4. 被截断的复习清单 → 用真实题干重建。
      final checklistSection = _section(markdown, checklistHeading);
      final needsChecklistRebuild =
          checklistSection != null &&
          (checklistSection.contains('「关于，') ||
              checklistSection.contains('能说出的判断依据') ||
              checklistSection.contains('本课的核心学习目标'));
      if (needsChecklistRebuild) {
        final rebuilt = _renderChecklist(quiz, title);
        if (rebuilt != null) {
          markdown = _replaceSection(markdown, checklistHeading, rebuilt);
          report['checklists_rebuilt'] =
              (report['checklists_rebuilt'] as int) + 1;
          changes.add('重建复习清单');
        }
      }

      if (changes.isNotEmpty) {
        report['lessons_changed'] = (report['lessons_changed'] as int) + 1;
        (report['details'] as List).add(<String, dynamic>{
          'lesson_id': lessonId,
          'category_id': category['id'],
          'changes': changes,
          'original_length': original.length,
          'new_length': markdown.length,
        });
        if (!dryRun) {
          file.writeAsStringSync(markdown);
        }
      }
    }
  }

  final reportFile = File('tool/reports/p0_residual_repair_report.json');
  reportFile.parent.createSync(recursive: true);
  reportFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
  );
  stdout.writeln('扫描课程        ${report['scanned']}');
  stdout.writeln('删除解析残句行  ${report['leak_lines_removed']}');
  stdout.writeln('重建错误表      ${report['mistake_tables_rebuilt']}');
  stdout.writeln('重建故障现场    ${report['fault_sections_rebuilt']}');
  stdout.writeln('重建复习清单    ${report['checklists_rebuilt']}');
  stdout.writeln('改动课程        ${report['lessons_changed']}');
  stdout.writeln('报告：${reportFile.path}');
}

/// 从测验里整理易错点：正确项是结论，干扰项里最长的一条是典型错误做法。
List<List<String>> _rowsFromQuiz(List<Map> quiz, String title) {
  final rows = <List<String>>[];
  for (final raw in quiz) {
    final question = raw.cast<String, dynamic>();
    final options = ((question['options'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (options.isEmpty) continue;
    final correct = _correctOptions(question, options);
    if (correct.isEmpty) continue;
    final correctText = correct.join('；');
    String? wrong;
    for (final option in options) {
      if (correct.any((item) => _normalize(item) == _normalize(option))) {
        continue;
      }
      if (wrong == null || option.length > wrong.length) wrong = option;
    }
    if (wrong == null) continue;
    final focus = _focusFromQuestion(question['question']?.toString() ?? '');
    if (focus.isEmpty) continue;
    rows.add(<String>[
      focus,
      '把「${_clip(wrong, 48)}」直接套用到本课场景',
      _clip(correctText, 70),
    ]);
    if (rows.length >= 5) break;
  }
  return rows;
}

/// 已经人工重写过的错误表：直接沿用其中的易错点与结论。
List<List<String>>? _rowsFromMistakeTable(String? section) {
  if (section == null) return null;
  final rows = <List<String>>[];
  for (final line in section.split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|')) continue;
    final cells = trimmed
        .split('|')
        .skip(1)
        .map((cell) => cell.trim())
        .toList();
    if (cells.length < 3) continue;
    if (cells[0] == '易错点' || cells.every((cell) => cell.startsWith('---'))) {
      continue;
    }
    if (cells[0].isEmpty) continue;
    rows.add(<String>[cells[0], cells[1], cells[2]]);
  }
  return rows.isEmpty ? null : rows;
}

String _renderMistakeTable(String title, List<List<String>> rows) {
  final buffer = StringBuffer()
    ..writeln(
      '> 说明：本表由《$title》的测验正确项与干扰项整理（$updatedAt），'
      '人工复核进度见 docs/content_review_batches.md。',
    )
    ..writeln()
    ..writeln(reviewedMistakeHeader)
    ..writeln('| --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln('| ${row[0]} | ${row[1]} | ${row[2]} |');
  }
  return buffer.toString().trimRight();
}

String _renderFaultScenarios(String title, List<List<String>> rows) {
  final buffer = StringBuffer();
  final symptoms = <String>[
    '按「{wrong}」处理《$title》的任务时，输出和正文给出的基线对不上。',
    '照「{wrong}」做完以后，《$title》的示例只在最简单的输入上通过，换一个输入就复现不出来。',
    '把「{wrong}」当成《$title》的结论时，边界输入会给出与正文相反的结果。',
  ];
  final verifies = <String>[
    '回到《$title》的最小示例，固定输入与版本，先跑正常输入再跑一个边界输入，两类结果都能解释才保留修改。',
    '用《$title》的最小示例复现一次：记录修复前后的输出差异，只有差异能用本课机制解释才算完成。',
    '把《$title》的修复项写成一个可重复检查：同样的输入连续跑两次结果一致，再补一个越界输入。',
  ];
  for (var index = 0; index < 3; index++) {
    final row = rows[index % rows.length];
    final symptom = symptoms[index % symptoms.length].replaceAll(
      '{wrong}',
      row[1],
    );
    buffer
      ..writeln('### 现场 ${index + 1}：${row[0]}')
      ..writeln()
      ..writeln('**症状**：$symptom')
      ..writeln()
      ..writeln('**根因**：在《$title》里，${row[1]}；这一步跳过了本课要求的前提，结论自然对不上。')
      ..writeln()
      ..writeln('**修复**：按《$title》的结论「${row[2]}」重做这一处。')
      ..writeln()
      ..writeln('**验证**：${verifies[index % verifies.length]}')
      ..writeln();
  }
  return buffer.toString().trimRight();
}

String? _renderChecklist(List<Map> quiz, String title) {
  final questions = <String>[];
  for (final raw in quiz) {
    final question = raw.cast<String, dynamic>();
    final type = (question['type'] ?? 'single').toString();
    if (type == 'fill' || type == 'order') continue;
    final text = question['question']?.toString().trim() ?? '';
    if (text.isEmpty || text.contains('…')) continue;
    questions.add(text);
    if (questions.length >= 3) break;
  }
  if (questions.length < 2) return null;
  final buffer = StringBuffer()
    ..writeln('离开本课前，逐项确认：')
    ..writeln();
  for (final question in questions) {
    buffer.writeln('- [ ] 不看解析，能说出「$question」的判断依据。');
  }
  buffer
    ..writeln('- [ ] 至少运行一次《$title》的示例，记录输入、输出和一个边界情况。')
    ..writeln('- [ ] 把本课最容易混淆的两个概念写成一句话对照。')
    ..writeln()
    ..writeln('| 复盘项 | 记录 |')
    ..writeln('| --- | --- |')
    ..writeln('| 已经能独立解释的考点 |  |')
    ..writeln('| 仍然说不清的概念 |  |')
    ..writeln('| 下一步验证动作 |  |');
  return buffer.toString().trimRight();
}

String _focusFromQuestion(String question) {
  final quoted = RegExp(r'「([^」]{4,40})」').firstMatch(question);
  if (quoted != null) return _clip(quoted.group(1)!.trim(), 26);
  final cleaned = question
      .replaceAll(RegExp(r'^(关于|在|根据)'), '')
      .replaceAll(RegExp(r'[，,。？?]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.length < 6) return '';
  return _clip(cleaned, 26);
}

List<String> _correctOptions(
  Map<String, dynamic> question,
  List<String> options,
) {
  final answer = question['answer'];
  if (answer is int && answer >= 0 && answer < options.length) {
    return <String>[options[answer]];
  }
  final answers = (question['answers'] as List?) ?? const [];
  final indexes = answers
      .map((item) => item is int ? item : int.tryParse(item.toString()))
      .whereType<int>()
      .where((index) => index >= 0 && index < options.length)
      .toList();
  if (indexes.isNotEmpty) {
    return indexes.map((index) => options[index]).toList();
  }
  final order = (question['correct_order'] as List?) ?? const [];
  final orderIndexes = order
      .map((item) => item is int ? item : int.tryParse(item.toString()))
      .whereType<int>()
      .where((index) => index >= 0 && index < options.length)
      .toList();
  if (orderIndexes.isNotEmpty) {
    return orderIndexes.map((index) => options[index]).toList();
  }
  return const <String>[];
}

/// 取 markdown 里 `## 标题` 到下一个二级标题之间的内容，找不到返回 null。
String? _section(String markdown, String title) {
  final match = RegExp(
    '^##\\s+${RegExp.escape(title)}\\s*\$',
    multiLine: true,
  ).firstMatch(markdown);
  if (match == null) return null;
  final rest = markdown.substring(match.end);
  final next = RegExp(r'^##\s+', multiLine: true).firstMatch(rest);
  return next == null ? rest : rest.substring(0, next.start);
}

String _replaceSection(String markdown, String title, String body) {
  final match = RegExp(
    '^##\\s+${RegExp.escape(title)}\\s*\$',
    multiLine: true,
  ).firstMatch(markdown);
  if (match == null) return markdown;
  final rest = markdown.substring(match.end);
  final next = RegExp(r'^##\s+', multiLine: true).firstMatch(rest);
  final end = next == null ? markdown.length : match.end + next.start;
  return '${markdown.substring(0, match.end)}\n\n$body\n\n'
      '${markdown.substring(end).replaceFirst(RegExp(r'^\s*'), '')}';
}

String _normalize(String text) =>
    text.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp('[「」“”"\']'), '');

String _clip(String text, int limit) {
  final value = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return value.length <= limit ? value : '${value.substring(0, limit)}…';
}
