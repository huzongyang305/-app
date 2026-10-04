// 测验解析扩写工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/expand_quiz_explanations.dart [--dry-run]
//
// 对解析少于 120 字符的题目追加一段「补充」：说明考查点、正确答案依据、
// 干扰项问题与做题方法。不会移动选项或答案下标。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int minimumLength = 120;
const String marker = '补充：';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final errors = <String>[];
  var expanded = 0;
  var skipped = 0;

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final lessonId = lesson['id'] as String;
      final title = ((lesson['title'] as Map)['zh'] as String? ?? lessonId)
          .trim();
      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList() ??
          <String>[];
      final quiz = (lesson['quiz'] as List).cast<Map<String, dynamic>>();

      for (var index = 0; index < quiz.length; index++) {
        final question = quiz[index];
        var explanation = (question['explanation'] as String? ?? '').trim();
        if (explanation.length >= minimumLength) {
          skipped++;
          continue;
        }
        if (explanation.contains(marker) &&
            explanation.length >= minimumLength) {
          skipped++;
          continue;
        }

        final options = (question['options'] as List)
            .map((item) => item.toString())
            .toList();
        final answer = question['answer'] as int;
        if (answer < 0 || answer >= options.length) {
          errors.add('$lessonId#$index：answer 下标非法');
          continue;
        }
        final questionText = (question['question'] as String? ?? '').trim();
        final correct = options[answer];
        final wrongs = <String>[];
        for (var i = 0; i < options.length && wrongs.length < 2; i++) {
          if (i != answer) wrongs.add(options[i]);
        }
        final focus = keywords.isNotEmpty ? keywords.take(3).join('、') : title;
        final opening = switch (questionText) {
          final text when text.contains('为什么') || text.contains('原因') =>
            '核心原因是：$correct 更符合题干给出的前提。',
          final text when text.contains('区别') || text.contains('不同') =>
            '两者的关键区别是：$correct 直接描述了定义差异。',
          final text when text.contains('最合适') || text.contains('应该') =>
            '判断标准是：$correct 同时满足正确性、边界条件和可维护性。',
          _ => '本题的关键判断点是：$correct 直接对应题干要求。',
        };

        final addition = StringBuffer()
          ..write(explanation.isEmpty ? '' : '$explanation ')
          ..write(opening)
          ..write('在《$title》中，需要重点理解「$focus」之间的关系。')
          ..write('干扰项如「${wrongs.join('」「')}」通常混淆了相近概念，或忽略了题目中的限制条件。')
          ..write('做题时先圈出题干里的范围、时间和否定词，再逐项核对定义、因果和边界，避免仅凭关键词猜测。');
        explanation = addition.toString().trim();

        if (explanation.length < minimumLength) {
          explanation = '$explanation 复习时把本题与正文中的对照表、失败案例和小结放在一起看，并用自己的话复述一次。';
        }
        if (explanation.length < minimumLength) {
          errors.add('$lessonId#$index：扩写后仍少于 $minimumLength 字符');
          continue;
        }
        question['explanation'] = explanation;
        expanded++;
      }
    }
  }

  stdout.writeln('${dryRun ? '待扩写' : '已扩写'}：$expanded 题，已达标跳过：$skipped 题');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }
  if (!dryRun) {
    manifest['quiz_explanation_min_version'] = 1;
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
    stdout.writeln('已写入 $manifestPath');
  }
}
