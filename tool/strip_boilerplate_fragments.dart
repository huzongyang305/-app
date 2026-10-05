// P0：清理解析里残留的旧版自动扩写句子。
//
// 用法：
//   dart tool/strip_boilerplate_fragments.dart [--dry-run]
//
// 这些句子虽然因为携带选项原文而不再「完全重复」，但仍是模板化表达，
// 这里按句删除；删除后不足 120 字符的解析补一句课程回扣。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> _markers = <String>[
  '直接满足题干给出的条件和范围',
  '同时满足正确性、边界条件和可维护性',
  '判断时应分别写出正确项和错误项的适用条件',
  '能更清楚地看出每个选项的边界',
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var strippedQuestions = 0;
  var strippedSegments = 0;
  var padded = 0;
  var shortAfter = 0;

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final title =
          ((lesson['title'] as Map?)?['zh'] ?? lesson['id']) as String;
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final q = (rawQuestion as Map).cast<String, dynamic>();
        final original = (q['explanation'] as String?) ?? '';
        var updated = original;
        for (final marker in _markers) {
          final pattern = RegExp(
            '[^。；\\n]*${RegExp.escape(marker)}[^。；\\n]*[。；]?',
          );
          final matches = pattern.allMatches(updated).length;
          if (matches == 0) continue;
          strippedSegments += matches;
          updated = updated.replaceAll(pattern, '');
        }
        if (updated != original) strippedQuestions++;
        if (updated.trim().length < 120) {
          final options = ((q['options'] as List<dynamic>?) ?? const [])
              .cast<String>();
          final answer = (q['answer'] as num?)?.toInt() ?? 0;
          final correct = answer >= 0 && answer < options.length
              ? options[answer]
              : '';
          updated =
              '${updated.trim()}回到《$title》的定义与示例，'
              '把「$correct」与其余选项逐一对照，就能确认各自的适用边界。';
          padded++;
        }
        if (updated.trim().length < 120) shortAfter++;
        q['explanation'] = updated;
      }
    }
  }

  stdout.writeln('删除模板句的题目    $strippedQuestions');
  stdout.writeln('删除句子片段        $strippedSegments');
  stdout.writeln('补写课程回扣        $padded');
  stdout.writeln('仍不足 120 字符     $shortAfter');
  if (!dryRun && shortAfter == 0) {
    File(
      manifestPath,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
    stdout.writeln('已写回 $manifestPath');
  }
}
