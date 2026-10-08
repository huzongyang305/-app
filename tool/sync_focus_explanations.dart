// 把 manifest.json 的题目解析同步回 Markdown 的「考点精讲」小节。
//
// 背景：P1-6 调整选项长度时改写了部分 explanation，而 Markdown 正文里的
// 「判断依据」仍是旧文本；另有少数项目课的考点缺少判断依据行。
// 本工具以 manifest 为唯一事实来源，逐题核对并补齐/更新对应行，可重复执行。
//
// 正文里存在两种历史格式：
//   1. 新版：`- **判断依据**：<解析>`；
//   2. 早期课程：`判断要点：<正确项文本>。<解析>`。
// 两种格式都按 manifest 重新渲染，缺失时插在「题目」行之后。
//
// 用法：
//   dart tool/sync_focus_explanations.dart            # 预演，只统计差异
//   dart tool/sync_focus_explanations.dart --write    # 写入 Markdown
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String focusHeading = '## 考点精讲';
final RegExp focusItemPattern = RegExp(r'^###\s+考点\s+(\d+)\s*[:：]');
final RegExp judgementPattern = RegExp(r'^-\s*\*\*判断依据\*\*\s*[:：]');
final RegExp pointsPattern = RegExp(r'^判断要点\s*[:：]');
final RegExp questionPattern = RegExp(r'^-\s*\*\*题目\*\*\s*[:：]');

void main(List<String> args) {
  final write = args.contains('--write');
  final manifest = jsonDecode(File(manifestPath).readAsStringSync())
      as Map<String, dynamic>;

  var lessonsTouched = 0;
  var blocksChecked = 0;
  var linesUpdated = 0;
  var linesInserted = 0;
  final warnings = <String>[];
  final samples = <String>[];

  for (final lesson in _lessons(manifest)) {
    final id = _text(lesson['id']);
    final quiz = _quiz(lesson);
    if (quiz.isEmpty) continue;
    final path = _text(lesson['file']);
    final file = File(path);
    if (!file.existsSync()) {
      warnings.add('$id 找不到正文文件 $path');
      continue;
    }
    final text = file.readAsStringSync();
    final lines = text.split('\n');
    final headingIndex = lines.indexWhere(
      (line) => line.trimRight() == focusHeading,
    );
    if (headingIndex < 0) {
      warnings.add('$id 正文缺少「考点精讲」小节');
      continue;
    }
    var sectionEnd = lines.length;
    for (var i = headingIndex + 1; i < lines.length; i++) {
      if (lines[i].startsWith('## ')) {
        sectionEnd = i;
        break;
      }
    }

    // 早期课程用「判断要点」段落，其余用「判断依据」条目。
    final pointsStyle = lines
        .sublist(headingIndex + 1, sectionEnd)
        .any(pointsPattern.hasMatch);
    final itemLines = <int, int>{};
    for (var i = headingIndex + 1; i < sectionEnd; i++) {
      final match = focusItemPattern.firstMatch(lines[i]);
      if (match == null) continue;
      itemLines[int.parse(match.group(1)!) - 1] = i;
    }

    for (var index = 0; index < quiz.length; index++) {
      final start = itemLines[index];
      if (start == null) continue;
      blocksChecked++;
      var end = sectionEnd;
      for (var i = start + 1; i < sectionEnd; i++) {
        if (focusItemPattern.hasMatch(lines[i])) {
          end = i;
          break;
        }
      }
      final expected = _renderLine(quiz[index], pointsStyle);
      if (expected.isEmpty) {
        warnings.add('$id 第 ${index + 1} 题无法从 manifest 还原正确项');
        continue;
      }
      var handled = false;
      for (var i = start + 1; i < end; i++) {
        if (!judgementPattern.hasMatch(lines[i]) &&
            !pointsPattern.hasMatch(lines[i])) {
          continue;
        }
        handled = true;
        if (lines[i] == expected) break;
        if (samples.length < 5) samples.add('$id 第 ${index + 1} 题');
        lines[i] = expected;
        linesUpdated++;
        break;
      }
      if (handled) continue;

      // 缺少判断行时，补在「题目」行之后。
      var questionLine = -1;
      for (var i = start + 1; i < end; i++) {
        if (questionPattern.hasMatch(lines[i])) {
          questionLine = i;
          break;
        }
      }
      if (questionLine < 0) {
        warnings.add('$id 第 ${index + 1} 题找不到「题目」行，无法补判断依据');
        continue;
      }
      final current = lines[questionLine];
      final newline = current.endsWith('\r') ? '\r' : '';
      lines.insert(questionLine + 1, '$expected$newline');
      if (samples.length < 5) samples.add('$id 第 ${index + 1} 题（补行）');
      linesInserted++;
    }

    final next = lines.join('\n');
    if (next == text) continue;
    lessonsTouched++;
    if (write) file.writeAsStringSync(next);
  }

  stdout.writeln('核对考点块      $blocksChecked');
  stdout.writeln('需要更新的课程  $lessonsTouched');
  stdout.writeln('更新判断行      $linesUpdated');
  stdout.writeln('补齐判断行      $linesInserted');
  if (samples.isNotEmpty) stdout.writeln('示例：${samples.join('、')}');
  if (warnings.isNotEmpty) {
    stdout.writeln('警告 ${warnings.length} 条：');
    for (final warning in warnings.take(20)) {
      stdout.writeln('  · $warning');
    }
  }
  stdout.writeln(write ? '已写入 Markdown' : '[dry-run] 未写文件，加 --write 写入');
}

/// 按正文历史格式渲染判断行。
String _renderLine(Map<String, dynamic> question, bool pointsStyle) {
  final explanation = _text(question['explanation'])
      .replaceAll(RegExp(r'\s*\n\s*'), ' ');
  if (!pointsStyle) return '- **判断依据**：$explanation';
  final prefix = _focusPointPrefix(question);
  if (prefix.isEmpty) return '';
  return '判断要点：$prefix$explanation';
}

/// 「判断要点」格式的前缀：正确项文本 + 句号。
///
/// 多选把全部正确项用「；」连接；顺序题只取第一步；填空题取第一个可接受答案。
String _focusPointPrefix(Map<String, dynamic> question) {
  final options = <String>[
    for (final option
        in (question['options'] as List<dynamic>? ?? const <dynamic>[]))
      option.toString(),
  ];
  final answers = question['answers'] as List<dynamic>? ?? const <dynamic>[];
  if (answers.isNotEmpty) {
    final picked = <String>[];
    for (final value in answers) {
      final index = int.tryParse(value.toString());
      if (index != null && index >= 0 && index < options.length) {
        picked.add(options[index]);
      }
    }
    if (picked.isNotEmpty) return '${picked.join('；')}。';
  }
  final direct = (question['answer'] as num?)?.toInt();
  if (direct != null && direct >= 0 && direct < options.length) {
    return '${options[direct]}。';
  }
  final order =
      question['correct_order'] as List<dynamic>? ?? const <dynamic>[];
  if (order.isNotEmpty) {
    final index = int.tryParse(order.first.toString());
    if (index != null && index >= 0 && index < options.length) {
      return '${options[index]}。';
    }
  }
  final accepted =
      question['accepted_answers'] as List<dynamic>? ?? const <dynamic>[];
  if (accepted.isNotEmpty) return '${accepted.first}。';
  return '';
}

List<Map<String, dynamic>> _lessons(Map<String, dynamic> manifest) {
  final lessons = <Map<String, dynamic>>[];
  for (final category in manifest['categories'] as List<dynamic>) {
    final map = category as Map<String, dynamic>;
    for (final lesson
        in (map['lessons'] as List<dynamic>? ?? const <dynamic>[])) {
      lessons.add(lesson as Map<String, dynamic>);
    }
  }
  return lessons;
}

List<Map<String, dynamic>> _quiz(Map<String, dynamic> lesson) =>
    <Map<String, dynamic>>[
      for (final question
          in (lesson['quiz'] as List<dynamic>? ?? const <dynamic>[]))
        question as Map<String, dynamic>,
    ];

String _text(Object? value) => (value ?? '').toString().trim();
