// P0/P1 收尾修复：清理空英文子节、修复编号与空行等结构残留。
//
// 用法：
//   dart tool/repair_content_finalize.dart [--apply] [--lesson=id]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 这些英文小节在 55 篇课程里只有标题、没有正文，且用户确认不需要英文内容。
const Set<String> emptyEnglishHeadings = <String>{
  'Core Mental Model',
  'Step-by-step Study Plan',
  'Practice Tasks',
  'Common Failure Modes',
  'Self-check Questions',
  'Glossary',
};

void main(List<String> args) {
  final apply = args.contains('--apply');
  final onlyLesson = _stringOption(args, '--lesson=');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final stats = <String, int>{};
  var lessonsTouched = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (onlyLesson != null && onlyLesson != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      final markdown = file.readAsStringSync();
      final title =
          ((lesson['title'] as Map?)?['zh'] ?? id).toString().trim();
      final result = _repair(markdown, title, stats);
      if (result != markdown) {
        lessonsTouched++;
        if (apply) file.writeAsStringSync(result);
      }
    }
  }
  stdout.writeln(apply ? '=== 已写回收尾修复 ===' : '=== 试运行（未写文件）===');
  stdout.writeln('涉及课程  $lessonsTouched');
  final ordered = stats.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in ordered) {
    stdout.writeln('${entry.key.padRight(18)} ${entry.value}');
  }
}

String _repair(String markdown, String title, Map<String, int> stats) {
  var lines = markdown.split('\n');
  lines = _dropEmptyEnglishSubsections(lines, stats);
  lines = _renumberQuizLists(lines, stats);
  lines = _fixListIndent(lines, title, stats);
  lines = _collapseBlankLines(lines, stats);
  return lines.join('\n');
}

/// 删除英文概览里只有标题、没有正文的子节，保留 `## English Overview` 本身。
List<String> _dropEmptyEnglishSubsections(
  List<String> lines,
  Map<String, int> stats,
) {
  final sections = _headings(lines);
  final drop = <int>{};
  for (var i = 0; i < sections.length; i++) {
    final section = sections[i];
    if (!emptyEnglishHeadings.contains(section.text)) continue;
    var end = lines.length;
    for (var j = i + 1; j < sections.length; j++) {
      if (sections[j].level <= section.level) {
        end = sections[j].line;
        break;
      }
    }
    var hasBody = false;
    for (var k = section.line + 1; k < end; k++) {
      final trimmed = lines[k].trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      // 只剩旧的编号残留（如 4. 某题）不算正文。
      if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) continue;
      hasBody = true;
      break;
    }
    if (hasBody) continue;
    // 先保留小节标题，正文只有编号残留时也一并清掉。
    for (var k = section.line; k < end; k++) {
      drop.add(k);
      if (lines[k].trim().isNotEmpty) {
        stats.update('删除空英文子节', (v) => v + 1, ifAbsent: () => 1);
      }
    }
  }
  return <String>[
    for (var i = 0; i < lines.length; i++)
      if (!drop.contains(i)) lines[i],
  ];
}

/// 「测验回顾」里的题目编号从中间开始时，按 1..N 重新编号。
List<String> _renumberQuizLists(List<String> lines, Map<String, int> stats) {
  final output = List<String>.from(lines);
  String heading = '';
  var inFence = false;
  var i = 0;
  while (i < output.length) {
    final line = output[i];
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      i++;
      continue;
    }
    if (!inFence && line.startsWith('#')) heading = line;
    final inQuizSection = RegExp(r'复习|自测|考点|测验|回顾').hasMatch(heading);
    if (!inFence &&
        inQuizSection &&
        RegExp(r'^\d+\.\s').hasMatch(line)) {
      final block = <int>[i];
      var j = i + 1;
      while (j < output.length) {
        final next = output[j];
        if (RegExp(r'^\d+\.\s').hasMatch(next)) {
          block.add(j);
          j++;
          continue;
        }
        if (next.trimLeft().startsWith('   - ') ||
            next.trimLeft().startsWith('  - ') ||
            (next.trimLeft().startsWith('- ') && next.startsWith(' '))) {
          j++;
          continue;
        }
        if (next.trim().isEmpty) {
          var k = j;
          while (k < output.length && output[k].trim().isEmpty) {
            k++;
          }
          if (k < output.length && RegExp(r'^\d+\.\s').hasMatch(output[k])) {
            j = k;
            continue;
          }
          // 空行后面不是编号题就结束本题块，避免吞掉后续小节。
          j = k;
          break;
        }
        break;
      }
      final first = int.parse(RegExp(r'^(\d+)\.').firstMatch(line)!.group(1)!);
      if (first != 1) {
        var next = 1;
        for (final index in block) {
          final match = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(output[index])!;
          output[index] = '$next. ${match.group(2)}';
          next++;
          stats.update('测验编号重排', (v) => v + 1, ifAbsent: () => 1);
        }
      }
      i = j;
      continue;
    }
    i++;
  }
  return output;
}

/// 修复题目后紧跟的「   - 依据」缩进，使其成为同一列表项下的子项。
List<String> _fixListIndent(
  List<String> lines,
  String title,
  Map<String, int> stats,
) {
  final output = <String>[];
  var inFence = false;
  for (final line in lines) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      output.add(line);
      continue;
    }
    final match =
        inFence ? null : RegExp(r'^ {2,5}-\s+依据：').firstMatch(line);
    if (match != null && line != '   - 依据：${line.replaceFirst(RegExp(r'^ {2,5}-\s+依据：'), '')}') {
      stats.update('修正依据缩进', (v) => v + 1, ifAbsent: () => 1);
      output.add('   - 依据：${line.replaceFirst(RegExp(r'^ {2,5}-\s+依据：'), '')}');
      continue;
    }
    output.add(line);
  }
  return output;
}

List<String> _collapseBlankLines(List<String> lines, Map<String, int> stats) {
  final output = <String>[];
  var blanks = 0;
  var collapsed = 0;
  for (final line in lines) {
    if (line.trim().isEmpty) {
      blanks++;
      if (blanks > 1) {
        collapsed++;
        continue;
      }
    } else {
      blanks = 0;
    }
    output.add(line);
  }
  while (output.isNotEmpty && output.last.trim().isEmpty) {
    output.removeLast();
  }
  output.add('');
  if (collapsed > 0) {
    stats.update('压缩连续空行', (v) => v + collapsed, ifAbsent: () => collapsed);
  }
  return output;
}

class _Heading {
  _Heading(this.line, this.level, this.text);
  final int line;
  final int level;
  final String text;
}

List<_Heading> _headings(List<String> lines) {
  final result = <_Heading>[];
  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final match = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(lines[i]);
    if (match == null) continue;
    result.add(_Heading(i, match.group(1)!.length, match.group(2)!.trim()));
  }
  return result;
}

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
