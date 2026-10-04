// 题库批量合并工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_quiz_batch.dart tool/quiz_batches/xxx.json [...]
//
// 批次文件格式：
// {
//   "lesson_id": [
//     {
//       "question": "题干",
//       "options": ["A", "B", "C", "D"],
//       "answer": 0,
//       "explanation": "解析"
//     }
//   ]
// }
//
// 合并规则：把新题追加到对应知识点已有题目之后，最终题量不超过 5 题。
// 任一校验失败即整体中止，不写回文件，避免污染内容库。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int maxQuestions = 5;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('请至少传入一个批次文件路径');
    exitCode = 1;
    return;
  }

  final manifestFile = File(manifestPath);
  final manifest = jsonDecode(await manifestFile.readAsString());
  if (manifest is! Map<String, dynamic>) {
    stderr.writeln('$manifestPath 结构异常');
    exitCode = 1;
    return;
  }

  final lessons = <String, Map<String, dynamic>>{};
  for (final category in (manifest['categories'] as List)) {
    for (final lesson in (category['lessons'] as List)) {
      final map = lesson as Map<String, dynamic>;
      lessons[map['id'] as String] = map;
    }
  }

  final errors = <String>[];
  var added = 0;

  for (final path in args) {
    final batch = jsonDecode(await File(path).readAsString());
    if (batch is! Map<String, dynamic>) {
      errors.add('$path：批次文件必须是 JSON 对象');
      continue;
    }

    for (final entry in batch.entries) {
      final lesson = lessons[entry.key];
      if (lesson == null) {
        errors.add('$path：知识点 ${entry.key} 不存在');
        continue;
      }
      if (entry.value is! List) {
        errors.add('$path：${entry.key} 的值必须是数组');
        continue;
      }

      final quiz = (lesson['quiz'] as List).cast<Map<String, dynamic>>();
      final existing = quiz.map((q) => q['question'] as String).toSet();

      for (final raw in entry.value as List) {
        if (quiz.length >= maxQuestions) {
          errors.add('$path：${entry.key} 已有 $maxQuestions 题，无法继续追加');
          break;
        }
        final question = (raw as Map).cast<String, dynamic>();
        final text = question['question'];
        final options = question['options'];
        final answer = question['answer'];
        final explanation = question['explanation'];

        if (text is! String || text.trim().isEmpty) {
          errors.add('$path：${entry.key} 存在空题干');
          continue;
        }
        if (existing.contains(text)) {
          errors.add('$path：${entry.key} 题干重复「$text」');
          continue;
        }
        if (options is! List || options.length < 3 || options.length > 5) {
          errors.add('$path：$text 选项数量必须是 3~5 个');
          continue;
        }
        if (answer is! int || answer < 0 || answer >= options.length) {
          errors.add('$path：$text 的 answer 越界');
          continue;
        }
        if (explanation is! String || explanation.trim().isEmpty) {
          errors.add('$path：$text 缺少解析');
          continue;
        }

        quiz.add(question);
        existing.add(text);
        added++;
      }
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('校验失败，未写入任何改动：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    stderr.writeln('共 ${errors.length} 条问题');
    exitCode = 1;
    return;
  }

  await manifestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  stdout.writeln('已追加 $added 道题，写入 $manifestPath');
}
