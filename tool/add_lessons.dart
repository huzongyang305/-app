// 知识点追加工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/add_lessons.dart tool/lesson_batches/math_batch1.json [...]
//
// 批次文件格式：
// {
//   "category": "math",
//   "lessons": [
//     {
//       "id": "math_information_theory",
//       "title": { "zh": "...", "en": "..." },
//       "summary": { "zh": "...", "en": "..." },
//       "file": "assets/content/math_information_theory.md",
//       "minutes": 16,
//       "keywords": ["信息论", "熵"],
//       "difficulty": "进阶",
//       "order": 4,
//       "quiz": [
//         { "question": "...", "options": ["a","b","c","d"], "answer": 0, "explanation": "..." }
//       ]
//     }
//   ]
// }
//
// 校验项（任一项失败即整体中止，不写回文件）：
//   · 分类必须存在；
//   · 知识点 id 不与现有或批次内重复；
//   · Markdown 文件必须已存在；
//   · 测验 3~5 题，每题 3~5 个选项，answer 下标合法，题干与解析非空；
//   · 同一知识点内题干不重复。
//
// 幂等：已存在的知识点 id 会被跳过，可反复执行。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('请传入至少一个批次文件路径');
    exitCode = 1;
    return;
  }

  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();

  final existingIds = <String>{};
  for (final category in categories) {
    for (final lesson in (category['lessons'] as List)) {
      existingIds.add((lesson as Map)['id'] as String);
    }
  }

  final errors = <String>[];
  var added = 0;
  var skipped = 0;

  for (final path in args) {
    final batch =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    final categoryId = batch['category'] as String?;
    final target = categories
        .where((item) => item['id'] == categoryId)
        .firstOrNull;
    if (target == null) {
      errors.add('$path：分类 $categoryId 不存在');
      continue;
    }

    for (final raw in (batch['lessons'] as List)) {
      final lesson = (raw as Map).cast<String, dynamic>();
      final id = lesson['id'] as String? ?? '';

      if (id.isEmpty) {
        errors.add('$path：存在缺少 id 的知识点');
        continue;
      }
      if (existingIds.contains(id)) {
        skipped++;
        continue;
      }

      final mdFile = File(lesson['file'] as String? ?? '');
      if (!mdFile.existsSync()) {
        errors.add('$path：$id 的教程文件不存在（${lesson['file']}）');
        continue;
      }

      final quiz = (lesson['quiz'] as List?) ?? const [];
      if (quiz.length < 3 || quiz.length > 5) {
        errors.add('$path：$id 的题量必须在 3~5 之间（当前 ${quiz.length}）');
        continue;
      }

      final seenQuestions = <String>{};
      for (final item in quiz) {
        final question = (item as Map).cast<String, dynamic>();
        final text = question['question'] as String? ?? '';
        final options = (question['options'] as List?) ?? const [];
        final answer = question['answer'];
        final explanation = question['explanation'] as String? ?? '';

        if (text.trim().isEmpty) {
          errors.add('$path：$id 存在空题干');
          break;
        }
        if (!seenQuestions.add(text)) {
          errors.add('$path：$id 题干重复「$text」');
          break;
        }
        if (options.length < 3 || options.length > 5) {
          errors.add('$path：$id 的「$text」选项数必须是 3~5');
          break;
        }
        if (answer is! int || answer < 0 || answer >= options.length) {
          errors.add('$path：$id 的「$text」answer 下标非法');
          break;
        }
        if (explanation.trim().isEmpty) {
          errors.add('$path：$id 的「$text」缺少解析');
          break;
        }
      }
      if (errors.any((item) => item.startsWith('$path：$id'))) {
        continue;
      }

      (target['lessons'] as List).add(lesson);
      existingIds.add(id);
      added++;
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

  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  stdout.writeln('已新增 $added 篇知识点，跳过（已存在）$skipped 篇');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
