import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/services/code_reading_bank.dart';
import 'package:code_learn_app/services/practice_question_factory.dart';
import 'package:flutter_test/flutter_test.dart';

/// 代码阅读题：题库自检 + 全量覆盖检查。
void main() {
  late List<LessonCategory> categories;
  late List<Lesson> lessons;

  setUpAll(() {
    final manifest = jsonDecode(
      File('assets/content/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    categories = (manifest['categories'] as List<dynamic>)
        .map(
          (item) =>
              LessonCategory.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
    lessons = categories.expand((category) => category.lessons).toList();
  });

  test('题库里每种语言的槽位唯一，且至少有 3 个干扰项来源', () {
    for (final entry in codeReadingBank.entries) {
      final slots = entry.value.map((item) => item.slot).toList();
      expect(slots.toSet().length, slots.length, reason: '${entry.key} 存在重复槽位');
      expect(
        entry.value.length,
        greaterThanOrEqualTo(3),
        reason: '${entry.key} 题目太少，凑不出干扰项',
      );
      for (final item in entry.value) {
        expect(item.code.trim(), isNotEmpty);
        expect(item.answer.trim(), isNotEmpty);
        expect(item.explanation.trim().length, greaterThanOrEqualTo(8));
        // 匹配正则必须能编译，否则开发工具会静默跳过课程。
        expect(() => RegExp(item.pattern, multiLine: true), returnsNormally);
      }
    }
  });

  test('生成的代码阅读题选项完整、答案合法且代码非空', () {
    for (final lesson in lessons.where((item) => item.hasCodeQuiz)) {
      final question = buildCodeReadingQuestion(
        lessonId: lesson.id,
        lessonTitle: lesson.title.zh,
        language: lesson.codeQuizLanguage!,
        slot: lesson.codeQuizSlot!,
      );
      expect(question, isNotNull, reason: lesson.id);
      expect(question!.type, 'code');
      expect(question.code, isNotNull);
      expect(question.code!.trim(), isNotEmpty);
      expect(question.options, hasLength(4));
      expect(question.options.toSet().length, 4, reason: '${lesson.id} 选项重复');
      expect(question.answerIndex, inInclusiveRange(0, 3));
      expect(
        question.explanation,
        contains(lesson.title.zh),
        reason: '${lesson.id} 解析没有回指课程',
      );
    }
  });

  test('同一门课的代码阅读题可重复生成且结果一致', () {
    final lesson = lessons.firstWhere((item) => item.hasCodeQuiz);
    final first = buildCodeReadingQuestion(
      lessonId: lesson.id,
      lessonTitle: lesson.title.zh,
      language: lesson.codeQuizLanguage!,
      slot: lesson.codeQuizSlot!,
    )!;
    final second = buildCodeReadingQuestion(
      lessonId: lesson.id,
      lessonTitle: lesson.title.zh,
      language: lesson.codeQuizLanguage!,
      slot: lesson.codeQuizSlot!,
    )!;
    expect(second.options, first.options);
    expect(second.answerIndex, first.answerIndex);
  });

  test('绝大多数课程都包含代码类题目（静态代码题或代码阅读题）', () {
    final withCode = lessons.where((lesson) => lesson.hasCodeQuestion).length;
    expect(
      withCode,
      greaterThanOrEqualTo((lessons.length * 0.9).floor()),
      reason: '只有 $withCode/${lessons.length} 门课有代码类题目',
    );
  });

  test('代码阅读题会进入 allQuiz 且计入题量', () {
    final lesson = lessons.firstWhere((item) => item.hasCodeQuiz);
    final all = lesson.allQuiz;
    expect(all.length, greaterThan(lesson.quiz.length));
    expect(all.where((item) => item.type == 'code'), isNotEmpty);
  });
}
