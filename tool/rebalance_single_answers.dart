// 单选题答案位置再均衡（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/rebalance_single_answers.dart [--dry-run] [--force]
//
// 背景：content_test.dart 要求 single 题的正确答案落在 A~D 各位置的比例处于
// 22%~28%。新增课程批量使用 answer=0 之后，A 位置占比一度升到 31.4%。
//
// 做法：只处理 type=single 且 options 为数组的题；解析里出现「选项一/二/三」
// 这类位置指代的题保持原位（避免指代错位），其余题目按当前计数最少的答案位置
// 轮转，保证轮转后正确答案文字不变。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int balanceVersion = 4;

final RegExp positionalReference = RegExp(r'选项[一二三四五12345A-E]|第[一二三四五12345]个');

int pickTarget(Map<int, int> counts, int optionCount, int rotation) {
  var minimum = -1;
  final candidates = <int>[];
  for (var index = 0; index < optionCount; index++) {
    final count = counts[index] ?? 0;
    if (minimum == -1 || count < minimum) {
      minimum = count;
      candidates
        ..clear()
        ..add(index);
    } else if (count == minimum) {
      candidates.add(index);
    }
  }
  return candidates[rotation % candidates.length];
}

String distribution(Map<int, int> counts) {
  final total = counts.values.fold<int>(0, (sum, value) => sum + value);
  return List<String>.generate(4, (index) {
    final count = counts[index] ?? 0;
    final percent = total == 0 ? 0 : count * 100 / total;
    return '${'ABCD'[index]} $count（${percent.toStringAsFixed(1)}%）';
  }).join('  ');
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  if (manifest['quiz_answer_balance_version'] == balanceVersion && !force) {
    stdout.writeln('单选答案位置已均衡（版本 $balanceVersion），跳过。');
    return;
  }

  final counts = <int, int>{};
  final movable = <Map<String, dynamic>>[];
  var fixed = 0;
  var scanned = 0;

  for (final rawCategory in manifest['categories'] as List) {
    for (final rawLesson in ((rawCategory as Map)['lessons'] as List)) {
      for (final rawQuestion in ((rawLesson as Map)['quiz'] as List)) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        // 早期数据省略 type 字段，此时按 single 处理（与 QuizQuestion 默认值一致）。
        final type = question['type']?.toString() ?? 'single';
        if (type != 'single') continue;
        if (question['options'] is! List) continue;
        final options = List<dynamic>.from(question['options'] as List);
        final answer = question['answer'];
        if (answer is! int || answer < 0 || answer >= options.length) continue;
        scanned++;
        final explanation = question['explanation'] as String? ?? '';
        if (options.length < 2 || positionalReference.hasMatch(explanation)) {
          counts[answer] = (counts[answer] ?? 0) + 1;
          fixed++;
          continue;
        }
        movable.add(question);
      }
    }
  }

  final before = Map<int, int>.from(counts);
  var rotation = 0;
  for (final question in movable) {
    final options = List<dynamic>.from(question['options'] as List);
    final answer = question['answer'] as int;
    final correct = options[answer];
    final target = pickTarget(counts, options.length, rotation++);
    final shift = (answer - target + options.length) % options.length;
    final rotated = List<dynamic>.generate(
      options.length,
      (index) => options[(index + shift) % options.length],
    );
    if (rotated[target] != correct) {
      stderr.writeln('轮转后正确答案错位，已中止');
      exitCode = 1;
      return;
    }
    question['options'] = rotated;
    question['answer'] = target;
    counts[target] = (counts[target] ?? 0) + 1;
  }

  stdout.writeln('单选题：$scanned，固定（位置指代）：$fixed，轮转：${movable.length}');
  stdout.writeln('均衡前：${distribution(before)}');
  stdout.writeln('均衡后：${distribution(counts)}');
  if (dryRun) {
    stdout.writeln('（dry-run，未写入）');
    return;
  }
  manifest['quiz_answer_balance_version'] = balanceVersion;
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
    flush: true,
  );
  stdout.writeln('已写入 $manifestPath');
}
