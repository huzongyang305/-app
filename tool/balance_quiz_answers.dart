// 测验答案位置均衡工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/balance_quiz_answers.dart [--dry-run] [--force]
//
// 背景：题库早期批量编写时，正确答案大量落在前两个选项
// （A 44%、B 52%、C 3%、D 1%），用户固定选 A 或 B 就能拿到一半分数，
// 测验失去区分度。
//
// 做法：不是随机洗牌（随机无法保证均衡），而是**配额式轮转**：
//   1. 按固定顺序遍历全部题目，每次把正确答案放到当前计数最少的选项位置；
//   2. 同分时按题序轮转打破平局，避免出现固定模式；
//   3. 其余选项整体轮转（保持内容不变，只改位置）；
//   4. 同步更新 answer 下标，保证正确答案文本不变。
// 这样 1180 道题可以精确摊成 295 / 295 / 295 / 295。
//
// 幂等：处理完成后在 manifest 写入 `quiz_answer_balance_version`，
// 再次执行直接跳过；需要重做时加 --force。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 均衡版本号：写入 manifest 用于保证工具幂等。
const int balanceVersion = 2;

Map<int, int> distribution(List<dynamic> questions) {
  final counts = <int, int>{};
  for (final raw in questions) {
    final answer = (raw as Map)['answer'] as int;
    counts[answer] = (counts[answer] ?? 0) + 1;
  }
  return counts;
}

String formatDistribution(Map<int, int> counts) {
  final total = counts.values.fold<int>(0, (sum, value) => sum + value);
  final labels = ['A', 'B', 'C', 'D', 'E'];
  final parts = <String>[];
  for (var index = 0; index < 5; index++) {
    final count = counts[index] ?? 0;
    if (count == 0) continue;
    final percent = total == 0 ? 0 : count * 100 / total;
    parts.add('${labels[index]} $count（${percent.toStringAsFixed(1)}%）');
  }
  return parts.join('  ');
}

/// 在计数最少的若干位置中，按轮转值挑一个，保证分布均衡且无固定模式。
int pickTarget(Map<int, int> counts, int optionCount, int rotation) {
  var minCount = -1;
  final candidates = <int>[];
  for (var index = 0; index < optionCount; index++) {
    final count = counts[index] ?? 0;
    if (minCount == -1 || count < minCount) {
      minCount = count;
      candidates
        ..clear()
        ..add(index);
    } else if (count == minCount) {
      candidates.add(index);
    }
  }
  return candidates[rotation % candidates.length];
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;

  if (manifest['quiz_answer_balance_version'] == balanceVersion && !force) {
    stdout.writeln('答案位置已均衡（版本 $balanceVersion），跳过。需要重做请加 --force。');
    return;
  }

  final counts = <int, int>{};
  final allQuestions = <dynamic>[];
  var processed = 0;
  var rotation = 0;

  for (final category in (manifest['categories'] as List)) {
    for (final lesson in ((category as Map)['lessons'] as List)) {
      final lessonMap = lesson as Map<String, dynamic>;
      final lessonId = lessonMap['id'] as String;
      final quiz = (lessonMap['quiz'] as List).cast<Map<String, dynamic>>();

      for (final question in quiz) {
        final options = List<dynamic>.from(question['options'] as List);
        final answerIndex = question['answer'] as int;
        final correctText = options[answerIndex];
        final optionCount = options.length;

        final target = pickTarget(counts, optionCount, rotation++);
        // 轮转整个选项数组，让正确答案落到 target 位置
        final shift = (answerIndex - target + optionCount) % optionCount;
        final rotated = List<dynamic>.generate(
          optionCount,
          (index) => options[(index + shift) % optionCount],
        );

        if (rotated[target] != correctText) {
          stderr.writeln('严重错误：$lessonId 轮转后正确答案错位');
          exitCode = 1;
          return;
        }

        question['options'] = rotated;
        question['answer'] = target;
        counts[target] = (counts[target] ?? 0) + 1;
        allQuestions.add(question);
        processed++;
      }
    }
  }

  stdout.writeln('共处理 $processed 道题');
  stdout.writeln('均衡后答案位置分布：${formatDistribution(distribution(allQuestions))}');

  if (dryRun) {
    stdout.writeln('（dry-run，未写入文件）');
    return;
  }

  manifest['quiz_answer_balance_version'] = balanceVersion;
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  stdout.writeln('已写入 $manifestPath');
}
