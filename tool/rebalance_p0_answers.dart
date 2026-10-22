// P0：把 p0QuizV2 新题的答案下标轮转均匀，满足 22%-28% 的分布要求。
//
// 用法：
//   dart tool/rebalance_p0_answers.dart [--dry-run]
import 'dart:io';

import 'p0_answer_balance.dart';
import 'p0_quiz_v2.dart';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest = loadManifest();
  final before = singleChoiceDistribution(manifest);
  final rotated = rebalanceP0Answers(manifest, p0QuizV2);
  final after = singleChoiceDistribution(manifest);

  stdout.writeln('轮转题目数          $rotated');
  stdout.writeln('轮转前              ${describeDistribution(before)}');
  stdout.writeln('轮转后              ${describeDistribution(after)}');
  final outOfRange = after.entries
      .where((entry) => entry.value < 22 || entry.value > 28)
      .toList();
  if (outOfRange.isNotEmpty) {
    stderr.writeln(
      '仍有下标超出 22%-28%：'
      '${outOfRange.map((e) => '${e.key}=${e.value.toStringAsFixed(1)}%').join(', ')}',
    );
    exitCode = 1;
    return;
  }
  if (!dryRun) {
    writeManifest(manifest);
    stdout.writeln('已写回 assets/content/manifest.json');
  }
}
