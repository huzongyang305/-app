// 答案位置安全均衡工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/rebalance_answers_safe.dart [--dry-run] [--force]
//
// 与旧版全量轮转不同：解析中提到「选项一/二/三/四」的题目保持原位置不动，
// 只轮转其余题目，避免文字指代与实际选项错位。最终各下标尽量接近 25%。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int balanceVersion = 3;

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
  return List.generate(4, (index) {
    final count = counts[index] ?? 0;
    final percent = total == 0 ? 0 : count * 100 / total;
    return '${String.fromCharCode(65 + index)} $count（${percent.toStringAsFixed(1)}%）';
  }).join('  ');
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;

  if (manifest['quiz_answer_balance_version'] == balanceVersion && !force) {
    stdout.writeln('答案位置已安全均衡（版本 $balanceVersion），跳过。');
    return;
  }

  final counts = <int, int>{};
  final movable = <Map<String, dynamic>>[];
  var fixed = 0;

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      for (final rawQuestion in lesson['quiz'] as List) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        final explanation = question['explanation'] as String? ?? '';
        final answer = question['answer'] as int;
        if (positionalReference.hasMatch(explanation)) {
          counts[answer] = (counts[answer] ?? 0) + 1;
          fixed++;
        } else {
          movable.add(question);
        }
      }
    }
  }

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
      stderr.writeln('轮转后正确答案错位');
      exitCode = 1;
      return;
    }
    question['options'] = rotated;
    question['answer'] = target;
    counts[target] = (counts[target] ?? 0) + 1;
  }

  stdout.writeln('固定题（解析含位置指代）：$fixed，安全轮转题：${movable.length}');
  stdout.writeln('均衡后分布：${distribution(counts)}');

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
