// P1-5 覆盖补齐：给还没有「代码阅读题」的分类补上 code_quiz 元数据。
//
// 用法：
//   dart tool/fill_code_quiz_gaps.dart            # dry-run，打印计划
//   dart tool/fill_code_quiz_gaps.dart --write    # 写回 manifest.json
//
// 背景：编译器、区块链、数据工程、嵌入式、云原生五个分类的题库里只有
// 单选/多选/排序/排错题，没有任何「读代码判断结论」的题目。这里复用
// lib/services/code_reading_bank.dart 的题库机制：manifest 只记录
// 「语言 + 槽位」，题干与选项在运行时生成，因此体积几乎不增加。
//
// 挑选规则：按正文顺序找第一段「题库已收录语言」的代码块，用它匹配槽位；
// 匹配不到就退回该语言的首个槽位。整课没有可用语言时如实打印课程 ID。
import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/services/code_reading_bank.dart';

const String manifestPath = 'assets/content/manifest.json';

/// 需要补齐代码题的分类（按 P1-5 的覆盖报告选出）。
const List<String> targetCategories = <String>[
  'compiler',
  'blockchain',
  'data_engineering',
  'embedded',
  'cloud',
];

void main(List<String> args) {
  final write = args.contains('--write');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var annotated = 0;
  var skippedWithCodeQuestion = 0;
  var skippedAnnotated = 0;
  final unresolved = <String>[];
  final byCategory = <String, int>{};
  final byLanguage = <String, int>{};

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    if (!targetCategories.contains(category['id'])) continue;
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final lessonId = lesson['id'].toString();
      final quiz = ((lesson['quiz'] as List<dynamic>?) ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
      if (quiz.any((question) => question['type'] == 'code')) {
        skippedWithCodeQuestion++;
        continue;
      }
      if (lesson['code_quiz'] is Map) {
        skippedAnnotated++;
        continue;
      }
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) {
        unresolved.add('$lessonId（缺少正文文件）');
        continue;
      }
      final block = _firstSupportedBlock(file.readAsStringSync());
      if (block == null) {
        unresolved.add('$lessonId（正文没有题库收录语言的代码块）');
        continue;
      }
      final language = canonicalCodeLanguage(block.language);
      final slot =
          codeReadingSlotFor(language, block.code) ??
          codeReadingBank[language]!.first.slot;
      lesson['code_quiz'] = <String, dynamic>{
        'language': language,
        'slot': slot,
      };
      annotated++;
      byCategory[category['id'].toString()] =
          (byCategory[category['id'].toString()] ?? 0) + 1;
      byLanguage[language] = (byLanguage[language] ?? 0) + 1;
      stdout.writeln('  + $lessonId -> $language/$slot');
    }
  }

  stdout.writeln('新增代码阅读题元数据   $annotated');
  stdout.writeln('已有代码题（跳过）     $skippedWithCodeQuestion');
  stdout.writeln('已标注（跳过）         $skippedAnnotated');
  stdout.writeln(
    '按分类                 '
    '${byCategory.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}',
  );
  stdout.writeln(
    '按语言                 '
    '${byLanguage.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}',
  );
  if (unresolved.isNotEmpty) {
    stdout.writeln('无法补齐（需要人工写题）：');
    for (final item in unresolved) {
      stdout.writeln('  - $item');
    }
  }

  if (!write) {
    stdout.writeln('');
    stdout.writeln('（dry-run，未写入文件；加 --write 生效）');
    return;
  }
  File(manifestPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('');
  stdout.writeln('已写入 $manifestPath');
}

class _CodeBlock {
  const _CodeBlock(this.language, this.code);

  final String language;
  final String code;
}

/// 取第一段「题库已收录语言」的代码块，跳过纯输出与图表围栏。
_CodeBlock? _firstSupportedBlock(String markdown) {
  final pattern = RegExp(r'^```([A-Za-z0-9_+#.-]+)[ \t]*$', multiLine: true);
  for (final match in pattern.allMatches(markdown)) {
    final language = match.group(1)!.toLowerCase();
    if (language == 'text' || language == 'output' || language == 'log') {
      continue;
    }
    if (!codeReadingBank.containsKey(canonicalCodeLanguage(language))) {
      continue;
    }
    final start = match.end;
    final end = markdown.indexOf('```', start);
    if (end < 0) continue;
    final code = markdown.substring(start, end).trim();
    if (code.isEmpty) continue;
    return _CodeBlock(language, code);
  }
  return null;
}
