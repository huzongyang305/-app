// 代码练习附录批量写入工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_practice_appendix.dart [--dry-run] [--lesson=python_first_script]
//   dart tool/apply_practice_appendix.dart --category=python
//
// 作用：
//   · 读取 assets/content/manifest.json，找出所有支持代码练习的语言课程；
//   · 调用 PracticeQuestionFactory 生成题目，与 App 内测验同源同序；
//   · 把题目渲染成 Markdown 附录并写入教程正文末尾；
//   · 通过 code-practice:v1:start / end 标记保证幂等，重复执行只替换旧块。
import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/services/practice_question_factory.dart';

const String manifestPath = 'assets/content/manifest.json';
const String startMarker = '<!-- code-practice:v1:start -->';
const String endMarker = '<!-- code-practice:v1:end -->';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final lessonFilter = _option(args, '--lesson=');
  final categoryFilter = _option(args, '--category=');

  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <Lesson>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'] as String;
    if (categoryFilter != null && categoryFilter != categoryId) continue;
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = Lesson.fromJson(
        (rawLesson as Map).cast<String, dynamic>(),
        categoryId,
      );
      if (lessonFilter != null && lessonFilter != lesson.id) continue;
      if (!PracticeQuestionFactory.supports(lesson)) {
        continue;
      }
      lessons.add(lesson);
    }
  }

  if (lessons.isEmpty) {
    stderr.writeln('没有匹配到任何课程，请检查过滤条件。');
    exitCode = 1;
    return;
  }

  final errors = <String>[];
  var updated = 0;
  var unchanged = 0;
  var questionTotal = 0;
  var addedChars = 0;

  for (final lesson in lessons) {
    final questions = PracticeQuestionFactory.questionsFor(lesson);
    if (questions.isEmpty) continue;
    questionTotal += questions.length;

    final file = File(lesson.assetFile);
    if (!file.existsSync()) {
      errors.add('${lesson.id}：找不到正文文件 ${lesson.assetFile}');
      continue;
    }
    final body = file.readAsStringSync();
    final appendix = renderAppendix(lesson, questions);
    final merged = _replaceBlock(body, appendix);
    if (merged == body) {
      unchanged++;
      continue;
    }
    addedChars += merged.length - body.length;
    updated++;
    if (dryRun) continue;
    file.writeAsStringSync(merged, encoding: utf8, flush: true);
  }

  stdout.writeln(
    '课程 ${lessons.length} 门 · 题目 $questionTotal 道 · '
    '${dryRun ? '待更新' : '已更新'} $updated 门 · 保持不变 $unchanged 门 · '
    '正文净增 $addedChars 字符',
  );
  if (errors.isNotEmpty) {
    stderr.writeln('以下课程写入失败：');
    for (final error in errors) {
      stderr.writeln('  · $error');
    }
    exitCode = 1;
  }
}

String? _option(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      final value = arg.substring(prefix.length).trim();
      if (value.isNotEmpty) return value;
    }
  }
  return null;
}

/// 用标记块替换正文末尾的旧附录；找不到标记时直接追加。
String _replaceBlock(String body, String appendix) {
  final start = body.indexOf(startMarker);
  if (start < 0) {
    final head = body.trimRight();
    return '$head\n\n$appendix';
  }
  final end = body.indexOf(endMarker, start);
  if (end < 0) {
    throw StateError('发现 $startMarker 却缺少对应的 $endMarker');
  }
  final tail = body.substring(end + endMarker.length);
  final rest = tail.trim();
  final suffix = rest.isEmpty ? '' : '\n$rest';
  return '${body.substring(0, start)}$appendix$suffix';
}

/// 把 6 道动态题渲染成与现有「考点精讲」风格一致的 Markdown 附录。
String renderAppendix(Lesson lesson, List<QuizQuestion> questions) {
  final buffer = StringBuffer()
    ..writeln(startMarker)
    ..writeln()
    ..writeln('## 代码练习（${questions.length} 题）')
    ..writeln()
    ..writeln(
      '下面题目与课程测验同源：覆盖代码输出、排错与场景判断。'
      '建议先自己写出答案，再到「测验」里核对成绩。',
    );

  for (var index = 0; index < questions.length; index++) {
    final question = questions[index];
    buffer
      ..writeln()
      ..writeln('### 练习 ${index + 1} · ${_typeLabel(question.type)}')
      ..writeln()
      ..writeln(question.question.trim());
    final code = question.code?.trim();
    if (code != null && code.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('```${_fenceLanguage(question.language)}')
        ..writeln(code)
        ..writeln('```');
    }
    if (question.options.isNotEmpty) {
      buffer.writeln();
      for (var option = 0; option < question.options.length; option++) {
        buffer.writeln(
          '- ${String.fromCharCode(65 + option)}. ${question.options[option]}',
        );
      }
    }
    buffer
      ..writeln()
      ..writeln('**参考答案**：${_answerText(question)}');
    final expected = question.expectedOutput?.trim();
    if (expected != null && expected.isNotEmpty) {
      final label = question.type == 'debug' ? '修复后输出' : '参考输出';
      buffer.writeln('**$label**：`$expected`');
    }
    final explanation = question.explanation.trim();
    if (explanation.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('**解析**')
        ..writeln()
        ..writeln(explanation);
    }
  }
  buffer
    ..writeln()
    ..writeln(endMarker);
  return buffer.toString();
}

/// 单选/代码/排错题展示选项字母，多选、填空、排序题回退到完整答案文本。
String _answerText(QuizQuestion question) {
  if (question.isSingleChoice && question.options.isNotEmpty) {
    final index = question.answerIndex;
    if (index >= 0 && index < question.options.length) {
      return '${String.fromCharCode(65 + index)}. ${question.options[index]}';
    }
  }
  if (question.correctOrder.isNotEmpty) {
    return question.correctOrder
        .map(
          (index) => index >= 0 && index < question.options.length
              ? question.options[index]
              : '#$index',
        )
        .join(' → ');
  }
  if (question.answerIndexes.isNotEmpty) {
    return question.answerIndexes
        .where((index) => index >= 0 && index < question.options.length)
        .map((index) => question.options[index])
        .join('、');
  }
  if (question.acceptedAnswers.isNotEmpty) {
    return question.acceptedAnswers.join(' / ');
  }
  return '见解析';
}

String _typeLabel(String type) => switch (type) {
  'code' => '代码输出',
  'debug' => '代码排错',
  'multi' => '多选',
  'fill' => '填空',
  'order' => '排序',
  _ => '概念判断',
};

/// 代码块语言标记统一成常见高亮别名。
String _fenceLanguage(String? language) {
  final value = (language ?? '').trim().toLowerCase();
  return switch (value) {
    'shell' => 'bash',
    'csharp' => 'csharp',
    'cpp' => 'cpp',
    '' => 'text',
    _ => value,
  };
}
