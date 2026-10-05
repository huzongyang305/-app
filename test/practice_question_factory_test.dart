import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/services/practice_question_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<LessonCategory> categories;

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
  });

  test('每个编程语言分类都有动态代码练习', () {
    final lessons = categories
        .where(
          (category) => PracticeQuestionFactory.supportsCategoryId(category.id),
        )
        .expand((category) => category.lessons)
        .toList();
    expect(lessons, isNotEmpty);

    final questionTexts = <String, String>{};
    for (final lesson in lessons) {
      final questions = PracticeQuestionFactory.questionsFor(lesson);
      expect(questions, hasLength(6), reason: lesson.id);
      expect(
        questions.where((question) => question.type == 'code'),
        hasLength(3),
        reason: '${lesson.id} 需要 3 道代码输出题',
      );
      expect(
        questions.where((question) => question.type == 'debug'),
        hasLength(2),
        reason: '${lesson.id} 需要 2 道排错题',
      );
      expect(
        questions.where((question) => question.type == 'single'),
        hasLength(1),
        reason: '${lesson.id} 需要 1 道场景设计题',
      );

      for (final question in questions) {
        expect(question.explanation.trim().length, greaterThanOrEqualTo(120));
        expect(question.options.length, greaterThanOrEqualTo(4));
        expect(
          question.answerIndex,
          inInclusiveRange(0, question.options.length - 1),
        );
        final existingTitle = questionTexts[question.question];
        if (existingTitle == null) {
          questionTexts[question.question] = lesson.title.zh;
        } else {
          // 同名课程允许出现同一题干，不同主题的课程不允许重复。
          expect(existingTitle, lesson.title.zh, reason: question.question);
        }
        if (question.type == 'code' || question.type == 'debug') {
          expect(question.code?.trim(), isNotEmpty);
          expect(question.language?.trim(), isNotEmpty);
        }
        if (question.type == 'code') {
          expect(question.expectedOutput?.trim(), isNotEmpty);
        }
      }
    }
  });

  test('同一课程重复生成结果完全一致', () {
    final lesson = categories
        .firstWhere(
          (category) => PracticeQuestionFactory.supportsCategoryId(category.id),
        )
        .lessons
        .first;
    final first = PracticeQuestionFactory.questionsFor(lesson);
    final second = PracticeQuestionFactory.questionsFor(lesson);
    expect(
      first.map((question) => question.question).toList(),
      second.map((question) => question.question).toList(),
    );
    expect(
      first.map((question) => question.options.join('|')).toList(),
      second.map((question) => question.options.join('|')).toList(),
    );
  });
}
