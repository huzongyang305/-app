// 结构完整性审计：找出跨课程可见的 Markdown 结构缺陷。
//
// 用法：
//   dart tool/audit_content_structure.dart [--json] [--no-fail]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

void main(List<String> args) {
  final jsonOutput = args.contains('--json');
  final failOnIssue = !args.contains('--no-fail');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final stats = <String, int>{};
  final samples = <String, List<String>>{};
  var lessonCount = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      lessonCount++;
      final lines = file.readAsStringSync().split('\n');
      for (final issue in _scan(lines)) {
        stats.update(issue.kind, (v) => v + 1, ifAbsent: () => 1);
        samples
            .putIfAbsent(issue.kind, () => <String>[])
            .add('${lesson['id']}:${issue.line}: ${issue.detail}');
      }
    }
  }
  final ordered = stats.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (jsonOutput) {
    stdout.writeln(
      jsonEncode(<String, dynamic>{
        'lessons': lessonCount,
        'counts': Map<String, int>.fromEntries(ordered),
        'samples': samples.map(
          (key, value) => MapEntry(key, value.take(8).toList()),
        ),
      }),
    );
    if (failOnIssue && ordered.isNotEmpty) exitCode = 1;
    return;
  }
  stdout.writeln('课程总数  $lessonCount');
  if (ordered.isEmpty) {
    stdout.writeln('未发现结构缺陷');
    return;
  }
  for (final entry in ordered) {
    stdout.writeln('${entry.key.padRight(28)} ${entry.value}');
    for (final sample in (samples[entry.key] ?? const <String>[]).take(3)) {
      stdout.writeln('    $sample');
    }
  }
  if (failOnIssue) exitCode = 1;
}

class _Issue {
  _Issue(this.kind, this.line, this.detail);
  final String kind;
  final int line;
  final String detail;
}

List<_Issue> _scan(List<String> lines) {
  final issues = <_Issue>[];
  var inFence = false;
  var inTable = false;
  final headings = <_Heading>[];
  var inFenceForHeadings = false;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('```')) {
      inFenceForHeadings = !inFenceForHeadings;
      continue;
    }
    if (inFenceForHeadings) continue;
    final match = RegExp(r'^(#{2,6})\s+(.*)$').firstMatch(lines[i]);
    if (match != null) {
      headings.add(_Heading(i, match.group(1)!.length, match.group(2)!.trim()));
    }
  }
  for (var h = 0; h < headings.length; h++) {
    final heading = headings[h];
    var end = lines.length;
    for (var j = h + 1; j < headings.length; j++) {
      if (headings[j].level <= heading.level) {
        end = headings[j].line;
        break;
      }
    }
    var hasBody = false;
    for (var k = heading.line + 1; k < end; k++) {
      final trimmed = lines[k].trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      hasBody = true;
      break;
    }
    if (!hasBody) {
      issues.add(_Issue('空小节', heading.line + 1, heading.text));
    }
  }
  var lastOrdered = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (line.contains('][index]')) {
      issues.add(_Issue('未解析模板占位符', i + 1, line.trim()));
    }
    if (line.contains('本课围绕该主题展开')) {
      issues.add(_Issue('术语表套话', i + 1, line.trim()));
    }
    final bold = RegExp(r'^\s*-\s+\*\*(.+?)\*\*\s*[：:]\s*(.*)$')
        .firstMatch(line);
    if (bold != null) {
      final head = _normalize(bold.group(1)!);
      final tail = _normalize(bold.group(2)!);
      if (head.length >= 8 && tail.startsWith(head)) {
        issues.add(_Issue('要点自我重复', i + 1, line.trim()));
      }
    }
    final ordered = RegExp(r'^(\d+)\.\s').firstMatch(line);
    if (ordered != null) {
      final current = int.parse(ordered.group(1)!);
      var nextNumbered = false;
      for (var k = i + 1; k < lines.length; k++) {
        if (lines[k].trim().isEmpty) continue;
        nextNumbered = RegExp(r'^\d+\.\s').hasMatch(lines[k]);
        break;
      }
      if (!inTable && lastOrdered == 0 && current > 1 && nextNumbered) {
        issues.add(_Issue('有序列表从中间开始', i + 1, line.trim()));
      }
      lastOrdered = current;
    } else if (line.trim().isEmpty || line.startsWith('#')) {
      lastOrdered = 0;
    } else if (!line.startsWith('|')) {
      // 缩进依据、段落或代码都会打断编号列表。
      lastOrdered = 0;
    }
    if (line.startsWith('|')) {
      inTable = true;
    } else if (inTable) {
      inTable = false;
    }
  }
  return issues;
}

class _Heading {
  _Heading(this.line, this.level, this.text);
  final int line;
  final int level;
  final String text;
}

String _normalize(String value) {
  return value
      .replaceAll(RegExp(r'[。；，、：:！？!?\s]'), '')
      .replaceAll(RegExp(r'^[-*+\d.\s]+'), '')
      .trim();
}
