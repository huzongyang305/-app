// P0 新题的答案下标轮转表：每 12 道题覆盖 0-3 各 3 次，
// 既保证分布均匀，也避免连续多题落在同一个下标上。
import 'dart:convert';
import 'dart:io';

const List<int> p0AnswerCycle = <int>[0, 2, 1, 3, 2, 0, 3, 1, 1, 3, 0, 2];

/// 把 p0QuizV2 生成的题目按 manifest 顺序轮转答案下标。
///
/// 依赖两个前提：p0QuizV2 里每道题的 options[answer] 是正确项；
/// manifest 中这些题的 answer 字段可信（截断工具只改文本、不改下标）。
/// 返回实际轮转的题目数量。
int rebalanceP0Answers(
  Map<String, dynamic> manifest,
  Map<String, dynamic> p0Quiz,
) {
  final expectedByQuestion = <String, String>{};
  for (final entry in p0Quiz.entries) {
    for (final raw in entry.value as List<dynamic>) {
      final item = (raw as Map).cast<String, dynamic>();
      final question = (item['question'] as String).replaceAll(
        RegExp(r'\s+'),
        '',
      );
      final options = (item['options'] as List).cast<String>();
      final answer = item['answer'] as int;
      expectedByQuestion[question] = options[answer];
    }
  }

  var counter = 0;
  var rotated = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = rawCategory as Map;
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final q = (rawQuestion as Map).cast<String, dynamic>();
        final question = ((q['question'] as String?) ?? '').replaceAll(
          RegExp(r'\s+'),
          '',
        );
        final expectedCorrect = expectedByQuestion[question];
        if (expectedCorrect == null) continue;
        final options = ((q['options'] as List<dynamic>?) ?? const [])
            .cast<String>();
        final current = (q['answer'] as num?)?.toInt() ?? 0;
        if (current < 0 || current >= options.length) continue;
        final target = p0AnswerCycle[counter % p0AnswerCycle.length];
        counter++;
        if (current == target) continue;
        final correct = options[current];
        final rest = [...options]..removeAt(current);
        q['options'] = [...rest.take(target), correct, ...rest.skip(target)];
        q['answer'] = target;
        rotated++;
      }
    }
  }
  return rotated;
}

/// 读取 manifest + p0QuizV2，统计单选答案下标占比。
Map<String, double> singleChoiceDistribution(Map<String, dynamic> manifest) {
  final counts = <int, int>{};
  var total = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson in (rawCategory as Map)['lessons'] as List<dynamic>) {
      for (final rawQuestion
          in (((rawLesson as Map)['quiz'] as List<dynamic>?) ?? const [])) {
        final q = (rawQuestion as Map).cast<String, dynamic>();
        if (((q['type'] as String?) ?? 'single') != 'single') continue;
        if (((q['options'] as List<dynamic>?) ?? const []).length < 2) continue;
        final answer = (q['answer'] as num?)?.toInt() ?? 0;
        counts[answer] = (counts[answer] ?? 0) + 1;
        total++;
      }
    }
  }
  return {
    for (var i = 0; i < 4; i++)
      '$i': total == 0 ? 0 : (counts[i] ?? 0) * 100 / total,
  };
}

String describeDistribution(Map<String, double> distribution) => distribution
    .entries
    .map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(1)}%')
    .join('  ');

Map<String, dynamic> loadManifest([
  String path = 'assets/content/manifest.json',
]) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void writeManifest(
  Map<String, dynamic> manifest, [
  String path = 'assets/content/manifest.json',
]) {
  File(path)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
}
