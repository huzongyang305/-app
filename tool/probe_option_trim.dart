// P0 探针：评估「正确选项过长」能否用子句截断安全修复。
//
// 用法：dart tool/probe_option_trim.dart [--show=10]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

List<String> _clauses(String text) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '(' || ch == '（') depth++;
    if (ch == ')' || ch == '）') depth = depth > 0 ? depth - 1 : 0;
    if (depth == 0 && (ch == '，' || ch == '；' || ch == '、')) {
      parts.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(ch);
  }
  if (buffer.isNotEmpty) parts.add(buffer.toString());
  return parts;
}

void main(List<String> args) {
  final show =
      int.tryParse(
        args
            .firstWhere(
              (a) => a.startsWith('--show='),
              orElse: () => '--show=10',
            )
            .substring('--show='.length),
      ) ??
      10;
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  var single = 0;
  var stronglyLongest = 0;
  var trimmable = 0;
  var untrimmable = 0;
  var afterTrimStrict = 0;
  final samples = <String>[];
  final stuck = <String>[];

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final q = (rawQuestion as Map).cast<String, dynamic>();
        final type = (q['type'] as String?) ?? 'single';
        if (type != 'single') continue;
        final options = ((q['options'] as List<dynamic>?) ?? const [])
            .cast<String>();
        final answer = (q['answer'] as num?)?.toInt() ?? 0;
        if (options.length < 2 || answer >= options.length) continue;
        single++;
        final correct = options[answer].trim();
        final others = <int>[];
        for (var i = 0; i < options.length; i++) {
          if (i != answer) others.add(options[i].trim().length);
        }
        final second = others.reduce((a, b) => a > b ? a : b);
        if (correct.length <= second) {
          if (correct.length == second) afterTrimStrict++;
          continue;
        }
        if (correct.length - second >= 8) stronglyLongest++;
        // 尝试在子句边界截断，去掉尾部细节。
        final clauses = _clauses(correct);
        String? trimmed;
        for (var keep = clauses.length - 1; keep >= 1; keep--) {
          final candidate = clauses.take(keep).join('，').trim();
          if (candidate.length >= 4 && candidate.length <= second) {
            trimmed = candidate;
            break;
          }
        }
        if (trimmed != null) {
          trimmable++;
          if (trimmed.length >= second) afterTrimStrict++;
          if (samples.length < show) {
            samples.add('$correct  ==>  $trimmed  (second=$second)');
          }
        } else {
          untrimmable++;
          if (stuck.length < show) {
            stuck.add(
              '${lesson['id']} | ${q['question']} | $correct | '
              'second=$second | opts=${options.join(' || ')}',
            );
          }
        }
      }
    }
  }
  stdout.writeln('单选总数            $single');
  stdout.writeln('严格最长            ${single - afterTrimStrict}');
  stdout.writeln('其中强最长(gap>=8)  $stronglyLongest');
  stdout.writeln('可安全截断          $trimmable');
  stdout.writeln('无法截断            $untrimmable');
  stdout.writeln('截断后强最长        ${stronglyLongest - trimmable}');
  stdout.writeln('');
  stdout.writeln('--- 截断示例 ---');
  samples.forEach(stdout.writeln);
  stdout.writeln('');
  stdout.writeln('--- 无法截断示例 ---');
  stuck.forEach(stdout.writeln);
}
