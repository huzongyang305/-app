// 把 tool/p0_quiz_v2.dart 里的真实测验题写回 manifest.json。
//
// 用法：
//   dart tool/apply_p0_quiz_v2.dart [--dry-run]
//
// 规则：每门课删除题干形如「《课程名》的……」的元问题，再按顺序插入
// p0QuizV2 中对应的新题；删除数量必须与新增数量一致，否则中止。
import 'dart:convert';
import 'dart:io';

import 'p0_answer_balance.dart';
import 'p0_quiz_v2.dart';

const String manifestPath = 'assets/content/manifest.json';
final RegExp metaPattern = RegExp(r'《.+?》');

String _questionType(dynamic raw) =>
    (((raw as Map)['type'] as String?) ?? 'single');

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  final seenQuestions = <String>{};
  final duplicates = <String>[];
  final lessonsById = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessonsById[lesson['id'] as String] = lesson;
    }
  }
  // 先收集全库题干，保证新题不会与任何现有题目重复。
  for (final lesson in lessonsById.values) {
    for (final rawQuestion in (lesson['quiz'] as List<dynamic>? ?? const [])) {
      final q = (rawQuestion as Map).cast<String, dynamic>();
      final text = ((q['question'] as String?) ?? '').replaceAll(
        RegExp(r'\s+'),
        '',
      );
      if (!seenQuestions.add(text)) duplicates.add(text);
    }
  }

  var replacedLessons = 0;
  var removed = 0;
  var inserted = 0;
  final errors = <String>[];

  for (final entry in p0QuizV2.entries) {
    final lesson = lessonsById[entry.key];
    if (lesson == null) {
      errors.add('未找到课程 ${entry.key}');
      continue;
    }
    final quiz = (lesson['quiz'] as List<dynamic>? ?? const []).toList();
    final kept = <dynamic>[];
    var removedHere = 0;
    for (final rawQuestion in quiz) {
      final q = (rawQuestion as Map).cast<String, dynamic>();
      final text = (q['question'] as String?) ?? '';
      if (metaPattern.hasMatch(text)) {
        removedHere++;
        final normalized = text.replaceAll(RegExp(r'\s+'), '');
        seenQuestions.remove(normalized);
        continue;
      }
      kept.add(rawQuestion);
    }
    if (removedHere != entry.value.length) {
      // 允许重复执行：如果该课已经没有元问题、且新题都已存在，则视为已完成。
      final existing = kept
          .map(
            (raw) => ((raw as Map)['question'] as String).replaceAll(
              RegExp(r'\s+'),
              '',
            ),
          )
          .toSet();
      final alreadyApplied =
          removedHere == 0 &&
          entry.value.every(
            (raw) => existing.contains(
              (raw['question'] as String).replaceAll(RegExp(r'\s+'), ''),
            ),
          );
      if (alreadyApplied) {
        continue;
      }
      errors.add(
        '${entry.key}: 删除 $removedHere 道元问题，'
        '但准备了 ${entry.value.length} 道新题',
      );
      continue;
    }
    final newQuestions = <Map<String, dynamic>>[];
    for (final raw in entry.value) {
      final question = raw['question'] as String;
      final options = (raw['options'] as List).cast<String>();
      final answer = raw['answer'] as int;
      final explanation = raw['explanation'] as String;
      final normalized = question.replaceAll(RegExp(r'\s+'), '');
      if (options.length != 4) {
        errors.add('${entry.key}: 选项数量不是 4 -> $question');
      }
      if (answer < 0 || answer >= options.length) {
        errors.add('${entry.key}: answer 越界 -> $question');
      }
      if (options.toSet().length != options.length) {
        errors.add('${entry.key}: 选项重复 -> $question');
      }
      if (explanation.trim().length < 120) {
        errors.add('${entry.key}: 解析过短 -> $question');
      }
      if (!seenQuestions.add(normalized)) {
        errors.add('${entry.key}: 题干与现有题目重复 -> $question');
      }
      newQuestions.add({
        'type': 'single',
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
      });
    }
    // 单选题统一排在前面，填空/代码/排错等互动题型放在最后，
    // 避免新题把互动题挤到测验开头。
    final merged = <dynamic>[...kept, ...newQuestions];
    lesson['quiz'] = [
      ...merged.where((raw) => _questionType(raw) == 'single'),
      ...merged.where((raw) => _questionType(raw) != 'single'),
    ];
    replacedLessons++;
    removed += removedHere;
    inserted += newQuestions.length;
  }

  if (errors.isNotEmpty) {
    stderr.writeln('发现 ${errors.length} 个问题：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }
  // 新题统一把正确答案下标轮转均匀，避免集中在 0 号位。
  final rotated = rebalanceP0Answers(manifest, p0QuizV2);
  final distribution = singleChoiceDistribution(manifest);
  if (!dryRun) {
    File(
      manifestPath,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  }
  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}替换 $replacedLessons 课，'
    '删除元问题 $removed 道，写入新题 $inserted 道',
  );
  stdout.writeln('答案下标轮转 $rotated 道：${describeDistribution(distribution)}');
}
