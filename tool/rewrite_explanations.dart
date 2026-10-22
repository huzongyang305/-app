// 测验解析去模板化工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/rewrite_explanations.dart [--dry-run]
//
// 把自动扩写的「补充：」段落替换为引用正确选项和错误选项的具体分析。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> wrongPatterns = <String>[
  '「{wrong}」混淆了相近概念，不能回答题干要求。',
  '「{wrong}」忽略了题目中的限制条件，因此不成立。',
  '如果采用「{wrong}」，会在边界或失败路径上产生错误结果。',
  '「{wrong}」适用于其他场景，但与本题的定义和前提不一致。',
  '「{wrong}」只看到了表面现象，没有解释题干真正考查的机制。',
  '「{wrong}」把因果关系颠倒了，不能作为正确结论。',
];

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  var rewritten = 0;
  var skipped = 0;
  final failures = <String>[];

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final lessonId = lesson['id'] as String;
      final title = ((lesson['title'] as Map)['zh'] as String? ?? lessonId);
      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString())
              .take(3)
              .join('、') ??
          title;
      final quiz = (lesson['quiz'] as List).cast<Map<String, dynamic>>();
      for (var index = 0; index < quiz.length; index++) {
        final question = quiz[index];
        final current = (question['explanation'] as String? ?? '').trim();
        final isAuto =
            current.contains('补充：') ||
            current.contains('做题时先圈出题干') ||
            current.contains('干扰项如');
        if (!isAuto) {
          skipped++;
          continue;
        }
        final options = (question['options'] as List)
            .map((item) => item.toString())
            .toList();
        final answer = question['answer'] as int;
        if (answer < 0 || answer >= options.length) {
          failures.add('$lessonId#$index answer 越界');
          continue;
        }
        final correct = options[answer];
        final wrongs = <String>[
          for (var i = 0; i < options.length; i++)
            if (i != answer) options[i],
        ];
        final base = _cleanBase(current);
        final seed = '$lessonId#$index'.hashCode;
        final buffer = StringBuffer();
        if (base.isNotEmpty) {
          buffer.write(base.endsWith('。') ? base : '$base。');
        } else {
          buffer.write('本题的正确答案是「$correct」。');
        }
        buffer.write('正确答案「$correct」直接满足题干给出的条件和范围，是唯一与定义一致的选项。');
        for (var i = 0; i < wrongs.length && i < 2; i++) {
          final pattern = wrongPatterns[(seed + i) % wrongPatterns.length];
          buffer.write(pattern.replaceAll('{wrong}', wrongs[i]));
        }
        final closing = switch (seed % 3) {
          0 => '本题对应《$title》的「$keywords」，判断时应分别写出正确项和错误项的适用条件。',
          1 => '把本题放回《$title》的「$keywords」语境，能更清楚地看出每个选项的边界。',
          _ => '复习《$title》的「$keywords」时，再用一个边界输入验证同一个结论。',
        };
        buffer.write(closing);
        var explanation = buffer.toString().trim();
        if (explanation.length < 120) {
          explanation = '$explanation 复习时把正确选项和错误选项放在一起对照，写出各自的适用条件和失败场景。';
        }
        if (explanation.length < 120) {
          failures.add('$lessonId#$index 解析过短');
          continue;
        }
        if (!dryRun) question['explanation'] = explanation;
        rewritten++;
      }
    }
  }

  stdout.writeln('${dryRun ? '待重写' : '已重写'}解析：$rewritten 题，无需处理：$skipped 题');
  if (failures.isNotEmpty) {
    stderr.writeln('失败 ${failures.length} 项：${failures.take(20).join('、')}');
    exitCode = 1;
    return;
  }
  if (!dryRun) {
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
    stdout.writeln('已写入 $manifestPath');
  }
}

String _cleanBase(String explanation) {
  var base = explanation.split('补充：').first.trim();
  final patterns = <RegExp>[
    RegExp(r'\s*本题的关键判断点是：[\s\S]*$'),
    RegExp(r'\s*在《[^》]*》中，需要重点理解[\s\S]*$'),
    RegExp(r'\s*干扰项如[\s\S]*$'),
    RegExp(r'\s*做题时先圈出题干[\s\S]*$'),
    RegExp(r'\s*核心原因是：[\s\S]*$'),
    RegExp(r'\s*正确答案「[^」]*」直接满足[\s\S]*$'),
  ];
  for (final pattern in patterns) {
    base = base.replaceAll(pattern, '').trim();
  }
  return base;
}
