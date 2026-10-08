// 内容修复自检：把 P0/P1 的核心不变量抠成一条命令，不再依赖肉眼看生成日志。
//
// 用法：
//   dart tool/content_repair_check.dart            # 在当前仓库自检
//   dart tool/content_repair_check.dart --root <目录>  # 自检指定的工作树
//
// 退出码 1 表示存在硬失败，可直接用于 CI 或提交前的最后一道关卡。
import 'dart:convert';
import 'dart:io';

const List<String> _coreSections = <String>[
  '本节知识框架',
  '核心概念定义',
  '原理与运行机制',
  '典型应用场景',
  '代码/协议/SQL 示例',
  '时间/空间复杂度或性能分析',
  '常见误区与易错点',
  '与其他知识点的关系',
  '自测题与参考答案',
];

/// 与 test/content_test.dart 保持同一套「内部题号」口径。
final RegExp _internalQuestionId = RegExp(
  r'[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)）]',
);

const List<String> _markdownTemplateMarkers = <String>[
  '先自己作答，再看「判断依据」',
  '**迁移检查**',
  '本课在「',
  '本课还在「',
  '本课在核心知识',
  '本课还在核心知识',
  '课程摘要指出',
  '回到正文对应章节补足概念',
  '把题干里的一个条件换成边界值',
  '把现象和原因写在一起',
  '错误信息通常会指出出错行和期望符号',
];

String _squeeze(String text) => text.replaceAll(RegExp(r'\s+'), '');

void main(List<String> args) {
  final rootIndex = args.indexOf('--root');
  final root = rootIndex >= 0 && rootIndex + 1 < args.length
      ? args[rootIndex + 1]
      : '.';
  final manifestFile = File('$root/assets/content/manifest.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到清单：${manifestFile.path}');
    exitCode = 1;
    return;
  }
  final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

  var lessonCount = 0;
  var questionCount = 0;
  var noCode = 0;
  var noImage = 0;
  var emptySections = 0;
  var thinChecklist = 0;
  var missingProjectSpec = 0;
  var missingSection = 0;
  var shortLesson = 0;
  var uncovered = <String>[];
  var internalIds = <String>[];
  var templateHits = <String>[];
  final seenStems = <String, String>{};
  final duplicateStems = <String>[];

  for (final rawCategory in (manifest['categories'] as List<dynamic>)) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in (category['lessons'] as List<dynamic>)) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = '${lesson['id']}';
      final title =
          '${(lesson['title'] as Map?)?['zh'] ?? id}'.trim();
      final file = File('$root/${lesson['file']}');
      if (!file.existsSync()) {
        stderr.writeln('缺少正文：${file.path}');
        exitCode = 1;
        continue;
      }
      final markdown = file.readAsStringSync();
      lessonCount++;
      if (markdown.length < 6000) shortLesson++;
      for (final section in _coreSections) {
        if (!markdown.contains('## $section')) missingSection++;
      }
      final fenceLanguages = RegExp(r'^```([^\n]*)$', multiLine: true)
          .allMatches(markdown)
          .map((match) => (match.group(1) ?? '').trim())
          .toList();
      final codeBlocks = fenceLanguages.where((item) => item.isNotEmpty).length;
      if (codeBlocks == 0) noCode++;
      if (!RegExp(r'!\[[^\]]*\]\([^)]+\)').hasMatch(markdown)) noImage++;
      // 空标题：H2 以下标题与下一个同级或更高级标题之间必须有正文。
      final lines = markdown.split('\n');
      final headings = <({int line, int level})>[];
      var inFence = false;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.trimLeft().startsWith('```')) {
          inFence = !inFence;
          continue;
        }
        if (inFence) continue;
        final match = RegExp(r'^(#{2,6})\s+').firstMatch(line);
        if (match != null) {
          headings.add((line: index, level: match.group(1)!.length));
        }
      }
      for (var index = 0; index < headings.length; index++) {
        final heading = headings[index];
        var end = lines.length;
        for (var next = index + 1; next < headings.length; next++) {
          if (headings[next].level <= heading.level) {
            end = headings[next].line;
            break;
          }
        }
        var hasBody = false;
        for (var line = heading.line + 1; line < end; line++) {
          final trimmed = lines[line].trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          hasBody = true;
          break;
        }
        if (!hasBody) emptySections++;
      }
      final checklist =
          RegExp(r'^- \[ \] ', multiLine: true).allMatches(markdown).length;
      if (checklist < 3) thinChecklist++;
      if (id.contains('project') ||
          title.contains('实战') ||
          title.contains('项目')) {
        if (!markdown.contains('项目专属规格')) missingProjectSpec++;
      }
      final markdownIds = _internalQuestionId.allMatches(markdown).length;
      if (markdownIds > 0) internalIds.add('$id(markdown:$markdownIds)');
      for (final marker in _markdownTemplateMarkers) {
        if (markdown.contains(marker)) templateHits.add('$id($marker)');
      }

      final quiz = (lesson['quiz'] as List<dynamic>? ?? const <dynamic>[])
          .map((raw) => (raw as Map).cast<String, dynamic>())
          .toList();
      final normalizedMarkdown = _squeeze(markdown);
      for (var index = 0; index < quiz.length; index++) {
        questionCount++;
        final question = quiz[index];
        final blob = jsonEncode(question);
        if (_internalQuestionId.hasMatch(blob)) {
          internalIds.add('$id#${index + 1}(quiz)');
        }
        final stem = _squeeze('${question['question'] ?? ''}');
        if (stem.isEmpty) continue;
        if (!normalizedMarkdown.contains(stem)) {
          uncovered.add('$id#${index + 1}');
        }
        final owner = seenStems[stem];
        if (owner != null) {
          duplicateStems.add('$owner/$id#${index + 1}');
        } else {
          seenStems[stem] = id;
        }
      }
    }
  }

  stdout
    ..writeln('课程数                     $lessonCount')
    ..writeln('题目数                     $questionCount')
    ..writeln('无代码块课程               $noCode')
    ..writeln('无配图课程                 $noImage')
    ..writeln('空小节                     $emptySections')
    ..writeln('复习清单不足 3 条           $thinChecklist')
    ..writeln('项目课缺专属规格            $missingProjectSpec')
    ..writeln('缺核心章节                  $missingSection')
    ..writeln('少于 6000 字符的课程        $shortLesson')
    ..writeln('题库未进入考点精讲          ${uncovered.length}')
    ..writeln('内部题号残留                ${internalIds.length}')
    ..writeln('模板句残留                  ${templateHits.length}')
    ..writeln('题干重复                    ${duplicateStems.length}');
  for (final sample in uncovered.take(5)) {
    stdout.writeln('  未覆盖：$sample');
  }
  for (final sample in duplicateStems.take(5)) {
    stdout.writeln('  重复：$sample');
  }

  final hardFailures = noCode +
      noImage +
      emptySections +
      thinChecklist +
      missingProjectSpec +
      missingSection +
      shortLesson +
      uncovered.length +
      internalIds.length +
      templateHits.length +
      duplicateStems.length;
  if (hardFailures > 0) {
    stderr.writeln('自检失败：$hardFailures 项硬失败');
    exitCode = 1;
  } else {
    stdout.writeln('自检通过：全部硬指标为 0');
  }
}
