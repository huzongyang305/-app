// P1 复用句审计：检查同一条正文句子是否出现在过多课程里。
//
// 用法：
//   dart tool/audit_scaffold_reuse.dart [--json] [--no-fail] [--top=40]
//   dart tool/audit_scaffold_reuse.dart --threshold=8
//
// 与 audit_content_governance.dart 的段落类检查互补：后者只看「完全相同的整段」，
// 漏掉了「同一句话出现在 8~20 门课」这种跨课复用水词。本工具按行统计，
// 排除代码围栏、表格、引用元数据、标题和参考资料链接后，把出现在
// threshold 门及以上课程里的句子列为复用句，默认阈值 8。
//
// 退出码：存在复用句时为 1（可用 --no-fail 只报告）。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String defaultReportPath = 'tool/reports/p1_scaffold_reuse.json';

/// 这些句子在多门课里合法重复：官方链接、环境说明、元数据。
/// 注意：这里比对的是 _normalize 之后的结果，列表符号已经被去掉。
const List<String> allowlistedPrefixes = <String>[
  '官方发布说明：',
  '官方说明：',
  '官方文档：',
  // 环境说明按语言/平台天然一致，例如「适用环境：Java 21+ / Maven 或 Gradle」。
  '适用环境：',
  '质量版本：',
  'Category: ',
  '| ',
  '```',
];

void main(List<String> args) {
  final emitJson = args.contains('--json');
  final failOnIssue = !args.contains('--no-fail');
  final top = _intOption(args, '--top=', 40);
  final threshold = _intOption(args, '--threshold=', 8);

  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lineLessons = <String, Set<String>>{};
  final lineSamples = <String, String>{};
  var lessonCount = 0;

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in ((rawCategory as Map)['lessons'] as List<dynamic>)) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      lessonCount++;
      final seen = <String>{};
      var inFence = false;
      for (final rawLine in file.readAsStringSync().split('\n')) {
        final line = rawLine.trim();
        if (line.startsWith('```')) {
          inFence = !inFence;
          continue;
        }
        if (inFence) continue;
        if (line.length < 30) continue;
        if (line.startsWith('#') ||
            line.startsWith('|') ||
            line.startsWith('![') ||
            line.startsWith('<!--') ||
            line.startsWith('>') ||
            line.contains('http://') ||
            line.contains('https://')) {
          continue;
        }
        final normalized = _normalize(line);
        if (normalized.length < 24) continue;
        if (allowlistedPrefixes.any(normalized.startsWith)) continue;
        if (!seen.add(normalized)) continue;
        lineLessons.putIfAbsent(normalized, () => <String>{}).add(id);
        lineSamples.putIfAbsent(normalized, () => line);
      }
    }
  }

  final repeated =
      lineLessons.entries
          .where((entry) => entry.value.length >= threshold)
          .toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

  if (emitJson) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'generated_at': DateTime.now().toIso8601String(),
        'lesson_count': lessonCount,
        'threshold': threshold,
        'repeated_line_count': repeated.length,
        'repeated_lines': [
          for (final entry in repeated)
            <String, dynamic>{
              'lessons': entry.value.length,
              'line': lineSamples[entry.key],
              'sample_lesson_ids': entry.value.take(6).toList(),
            },
        ],
      }),
    );
  } else {
    stdout.writeln('课程总数              $lessonCount');
    stdout.writeln('复用阈值              ≥$threshold 门');
    stdout.writeln('复用句数量            ${repeated.length}');
    for (final entry in repeated.take(top)) {
      final preview = entry.key.length > 60
          ? '${entry.key.substring(0, 60)}…'
          : entry.key;
      stdout.writeln('${entry.value.length.toString().padLeft(5)}  $preview');
    }
  }

  File(defaultReportPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'generated_at': DateTime.now().toIso8601String(),
        'lesson_count': lessonCount,
        'threshold': threshold,
        'repeated_line_count': repeated.length,
        'repeated_lines': [
          for (final entry in repeated)
            <String, dynamic>{
              'lessons': entry.value.length,
              'line': lineSamples[entry.key],
              'lesson_ids': entry.value.toList()..sort(),
            },
        ],
      }),
    );

  if (failOnIssue && repeated.isNotEmpty) exitCode = 1;
}

String _normalize(String line) => line
    .replaceFirst(RegExp(r'^[-*+\d.\s]+'), '')
    .replaceAll(RegExp(r'[*_`]+'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

int _intOption(List<String> args, String prefix, int fallback) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return int.tryParse(arg.substring(prefix.length)) ?? fallback;
    }
  }
  return fallback;
}
