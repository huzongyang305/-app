// 为「有代码块但没有代码题」的课程写入代码阅读题元数据。
//
// 用法：
//   dart tool/annotate_code_reading.dart            # 只统计（dry-run）
//   dart tool/annotate_code_reading.dart --write    # 写回 manifest.json
//
// 题库与槽位定义在 lib/services/code_reading_bank.dart；本工具只负责扫描
// 每门课 Markdown 的第一段代码块、挑出最贴近的槽位，并写入：
//   "code_quiz": { "language": "python", "slot": "def" }
// manifest 体积只增加几十字节，题目在运行时生成。
import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/services/code_reading_bank.dart';

const String manifestPath = 'assets/content/manifest.json';

void main(List<String> args) {
  final write = args.contains('--write');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var annotated = 0;
  var alreadyHasCodeQuestion = 0;
  var alreadyAnnotated = 0;
  var skippedNoCode = 0;
  var skippedLanguage = 0;
  final byLanguage = <String, int>{};

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final quiz = ((lesson['quiz'] as List<dynamic>?) ?? const []).cast<Map>();
      final hasCodeQuestion = quiz.any((question) {
        final type = (question['type'] as String?) ?? 'single';
        return type == 'code' || type == 'debug';
      });
      if (hasCodeQuestion) {
        alreadyHasCodeQuestion++;
        continue;
      }
      if (lesson['code_quiz'] is Map) {
        alreadyAnnotated++;
        continue;
      }
      final markdown = File(lesson['file'].toString());
      if (!markdown.existsSync()) {
        skippedNoCode++;
        continue;
      }
      final block = _firstCodeBlock(markdown.readAsStringSync());
      if (block == null) {
        skippedNoCode++;
        continue;
      }
      final language = canonicalCodeLanguage(block.language);
      if (!codeReadingBank.containsKey(language)) {
        skippedLanguage++;
        continue;
      }
      final slot =
          codeReadingSlotFor(language, block.code) ??
          codeReadingBank[language]!.first.slot;
      lesson['code_quiz'] = <String, dynamic>{
        'language': language,
        'slot': slot,
      };
      byLanguage[language] = (byLanguage[language] ?? 0) + 1;
      annotated++;
    }
  }

  stdout.writeln('新增代码阅读题元数据   $annotated');
  stdout.writeln('已有代码类题目         $alreadyHasCodeQuestion');
  stdout.writeln('已标注（跳过）         $alreadyAnnotated');
  stdout.writeln('无可用代码块           $skippedNoCode');
  stdout.writeln('语言未收录             $skippedLanguage');
  final languageSummary = byLanguage.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
  if (languageSummary.isNotEmpty) {
    stdout.writeln('按语言分布             $languageSummary');
  }

  if (!write) {
    stdout.writeln('');
    stdout.writeln('（dry-run，未写入文件；加 --write 生效）');
    return;
  }
  File(manifestPath)
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  stdout.writeln('');
  stdout.writeln('已写入 $manifestPath');
}

class _CodeBlock {
  const _CodeBlock(this.language, this.code);

  final String language;
  final String code;
}

/// 取第一段带语言标记、且长度适中的代码块；text 围栏通常是输出而跳过。
_CodeBlock? _firstCodeBlock(String markdown) {
  final pattern = RegExp(r'^```([A-Za-z0-9_+#.-]+)[ \t]*$', multiLine: true);
  for (final match in pattern.allMatches(markdown)) {
    final language = match.group(1)!.toLowerCase();
    if (language == 'text' || language == 'output' || language == 'log') {
      continue;
    }
    final start = match.end;
    final end = markdown.indexOf('```', start);
    if (end < 0) continue;
    final code = markdown.substring(start, end).trim();
    if (code.isEmpty || code.length > 1200) continue;
    return _CodeBlock(language, code);
  }
  return null;
}
