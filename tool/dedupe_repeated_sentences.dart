// P0 正文去重：同一条句子在一行里被重复多次时只保留第一次。
//
// 用法：
//   dart run tool/dedupe_repeated_sentences.dart [--dry-run]
//
// 背景：部分课程的「零基础精讲」段落里，同一句话被连续写了 12 次，
// 属于生成阶段的拼接缺陷。这里按行处理，只压缩「同一行内重复 >= 3 次」
// 且长度 >= 12 的句子；跨行重复的清单句不在处理范围内。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String reportPath = 'tool/reports/p0_sentence_dedupe.json';
const int minRepeats = 3;
const int minSentenceLength = 12;

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final details = <Map<String, dynamic>>[];
  var changedLessons = 0;

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      final lines = file.readAsLinesSync();
      var removed = 0;
      var touchedLines = 0;
      for (var index = 0; index < lines.length; index++) {
        final result = _dedupeLine(lines[index]);
        if (result.removed == 0) continue;
        lines[index] = result.line;
        removed += result.removed;
        touchedLines++;
      }
      if (removed == 0) continue;
      changedLessons++;
      details.add(<String, dynamic>{
        'lesson_id': lesson['id'],
        'removed_sentences': removed,
        'lines': touchedLines,
      });
      if (!dryRun) file.writeAsStringSync('${lines.join('\n')}\n');
    }
  }

  File(reportPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'dry_run': dryRun,
        'changed_lessons': changedLessons,
        'removed_sentences':
            details.fold<int>(0, (sum, item) => sum + (item['removed_sentences'] as int)),
        'details': details,
      }),
    );
  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}压缩重复句：$changedLessons 门课，'
    '删除 ${details.fold<int>(0, (sum, item) => sum + (item['removed_sentences'] as int))} 条重复句',
  );
}

({String line, int removed}) _dedupeLine(String line) {
  if (line.length < 60) return (line: line, removed: 0);
  final parts = <String>[];
  var start = 0;
  final pattern = RegExp(r'[。！？；!?;]');
  for (final match in pattern.allMatches(line)) {
    parts.add(line.substring(start, match.end));
    start = match.end;
  }
  if (start < line.length) parts.add(line.substring(start));
  if (parts.length < minRepeats) return (line: line, removed: 0);

  final counts = <String, int>{};
  for (final part in parts) {
    final key = part.trim();
    if (key.length < minSentenceLength) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final duplicated = <String>{
    for (final entry in counts.entries)
      if (entry.value >= minRepeats) entry.key,
  };
  if (duplicated.isEmpty) return (line: line, removed: 0);

  final kept = <String>[];
  final seen = <String>{};
  var removed = 0;
  for (final part in parts) {
    final key = part.trim();
    if (duplicated.contains(key)) {
      if (seen.contains(key)) {
        removed++;
        continue;
      }
      seen.add(key);
    }
    kept.add(part);
  }
  return (line: kept.join(), removed: removed);
}
