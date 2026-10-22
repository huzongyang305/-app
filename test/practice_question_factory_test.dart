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

  test('语言基础课程都有 6 道动态代码练习', () {
    final lessons = categories
        .where(
          (category) => PracticeQuestionFactory.supportsCategoryId(category.id),
        )
        .expand((category) => category.lessons)
        .where(PracticeQuestionFactory.supports)
        .toList();
    expect(lessons, isNotEmpty);
    expect(
      lessons.length,
      greaterThanOrEqualTo(70),
      reason: '语言基础课程应覆盖全部 12 门语言',
    );
    expect(
      lessons.map((lesson) => lesson.categoryId).toSet().length,
      PracticeQuestionFactory.supportedCategoryIds.length,
    );

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

  test('高阶语言课程不生成通用代码练习，只保留本课代码阅读题', () {
    final advanced = categories
        .where(
          (category) => PracticeQuestionFactory.supportsCategoryId(category.id),
        )
        .expand((category) => category.lessons)
        .where((lesson) => !PracticeQuestionFactory.supports(lesson))
        .toList();
    expect(advanced, isNotEmpty);
    for (final lesson in advanced) {
      // 通用模板练习仍然不生成，避免与高阶主题脱节。
      expect(PracticeQuestionFactory.questionsFor(lesson), isEmpty);
      // 手写题库里可能本来就有代码题，这里只核对新增的代码阅读题。
      final staticCode = lesson.quiz
          .where((question) => question.type == 'code')
          .length;
      final totalCode = lesson.allQuiz
          .where((question) => question.type == 'code')
          .length;
      expect(
        totalCode - staticCode,
        lesson.hasCodeQuiz ? 1 : 0,
        reason: lesson.id,
      );
      expect(
        lesson.totalQuestionCount,
        lesson.quiz.length + (lesson.hasCodeQuiz ? 1 : 0),
      );
    }
  });

  test('同一课程重复生成结果完全一致', () {
    final lesson = categories
        .firstWhere(
          (category) => PracticeQuestionFactory.supportsCategoryId(category.id),
        )
        .lessons
        .firstWhere(PracticeQuestionFactory.supports);
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
