import 'package:flutter_test/flutter_test.dart';

import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/models/quiz_result.dart';
import 'package:code_learn_app/services/adaptive_quiz_service.dart';
import 'package:code_learn_app/services/knowledge_graph_service.dart';
import 'package:code_learn_app/services/mastery_service.dart';

Lesson _lesson(
  String id, {
  int order = 0,
  List<String> prerequisites = const <String>[],
  List<String> related = const <String>[],
  List<QuizQuestion> quiz = const <QuizQuestion>[],
}) {
  return Lesson(
    id: id,
    categoryId: 'cat',
    order: order,
    title: LocalizedText(zh: id, en: id),
    summary: const LocalizedText(zh: '摘要', en: 'summary'),
    assetFile: '$id.md',
    minutes: 10,
    keywords: const <String>[],
    quiz: quiz,
    prerequisites: prerequisites,
    related: related,
  );
}

LessonCategory _category(List<Lesson> lessons) => LessonCategory(
  id: 'cat',
  title: const LocalizedText(zh: '分类', en: 'category'),
  iconName: 'code',
  colorValue: 0x2563EB,
  lessons: lessons,
);

void main() {
  group('KnowledgeGraphService', () {
    test('拓扑顺序保证前置排在后继之前', () {
      final graph = KnowledgeGraphService.build(<LessonCategory>[
        _category(<Lesson>[
          _lesson('c', order: 2, prerequisites: <String>['b']),
          _lesson('a', order: 0),
          _lesson('b', order: 1, prerequisites: <String>['a']),
        ]),
      ]);
      expect(graph.order, <String>['a', 'b', 'c']);
      expect(graph.statistics['edges'], 2);
      expect(graph.statistics['maxDepth'], 2);
      expect(graph.roots.map((node) => node.lesson.id), <String>['a']);
    });

    test('pathTo 返回从根到目标的最短前置链', () {
      final graph = KnowledgeGraphService.build(<LessonCategory>[
        _category(<Lesson>[
          _lesson('a'),
          _lesson('b', prerequisites: <String>['a']),
          _lesson('c', prerequisites: <String>['b']),
        ]),
      ]);
      final path = graph.pathTo('c').map((node) => node.lesson.id).toList();
      expect(path, <String>['a', 'b', 'c']);
    });

    test('nextLessons 优先返回直接后继', () {
      final graph = KnowledgeGraphService.build(<LessonCategory>[
        _category(<Lesson>[
          _lesson('a'),
          _lesson('b', order: 1, prerequisites: <String>['a']),
          _lesson('c', order: 2),
        ]),
      ]);
      final next = graph.nextLessons('a').map((node) => node.lesson.id);
      expect(next.first, 'b');
      expect(next, contains('c'));
    });

    test('检测断链与循环依赖', () {
      final graph = KnowledgeGraphService.build(<LessonCategory>[
        _category(<Lesson>[
          _lesson('a', prerequisites: <String>['missing']),
          _lesson('b', prerequisites: <String>['c']),
          _lesson('c', prerequisites: <String>['b']),
        ]),
      ]);
      expect(graph.brokenReferences, contains('a -> missing'));
      expect(graph.cycles, containsAll(<String>['b', 'c']));
      expect(graph.statistics['brokenReferences'], 1);
    });
  });

  group('MasteryService', () {
    final lesson = _lesson('a');
    final now = DateTime(2026, 10, 6, 12);

    test('没有测验记录时不会给出高掌握度', () {
      final snapshot = MasteryService.evaluate(lesson: lesson, now: now);
      expect(snapshot.level, MasteryLevel.newLearner);
      expect(snapshot.score, lessThan(0.3));
      expect(snapshot.retention, 0.3);
    });

    test('高正确率与长复习间隔提升掌握度', () {
      final snapshot = MasteryService.evaluate(
        lesson: lesson,
        quizResult: QuizResult(
          lessonId: 'a',
          correct: 9,
          total: 10,
          attempts: 3,
          updatedAt: now,
        ),
        wrongCount: 0,
        intervalDays: 30,
        reviewDueAt: now.add(const Duration(days: 20)),
        now: now,
      );
      expect(snapshot.accuracy, closeTo(0.9, 1e-9));
      expect(snapshot.score, greaterThan(0.85));
      expect(snapshot.level, MasteryLevel.mastered);
    });

    test('前置未掌握时进入 blockedBy 并拉低分数', () {
      final snapshot = MasteryService.evaluate(
        lesson: lesson,
        quizResult: QuizResult(
          lessonId: 'a',
          correct: 5,
          total: 5,
          attempts: 1,
          updatedAt: now,
        ),
        prerequisiteScores: <String, double>{'p': 0.1},
        now: now,
      );
      expect(snapshot.blockedBy, <String>['p']);
      expect(snapshot.readiness, closeTo(0.1, 1e-9));
    });

    test('evaluateAll 按图谱顺序输出并继承前置分数', () {
      final graph = KnowledgeGraphService.build(<LessonCategory>[
        _category(<Lesson>[
          _lesson('a'),
          _lesson('b', prerequisites: <String>['a']),
        ]),
      ]);
      final results = MasteryService.evaluateAll(
        graph: graph,
        quizResults: <String, QuizResult>{
          'a': QuizResult(
            lessonId: 'a',
            correct: 5,
            total: 5,
            attempts: 2,
            updatedAt: now,
          ),
        },
        wrongCountOf: (_) => 0,
        intervalDaysOf: (_) => 10,
        now: now,
      );
      expect(results.map((item) => item.lessonId), <String>['a', 'b']);
      expect(results.last.blockedBy, isEmpty);
    });
  });

  group('AdaptiveQuizService', () {
    const quiz = <QuizQuestion>[
      QuizQuestion(
        question: '选出正确项',
        options: <String>['A', 'B', 'C', 'D'],
        answerIndex: 2,
        explanation: 'C 正确',
      ),
      QuizQuestion(
        question: '多选',
        options: <String>['W', 'X', 'Y', 'Z'],
        answerIndex: 0,
        explanation: 'WZ',
        type: 'multi',
        answerIndexes: <int>[0, 3],
      ),
      QuizQuestion(
        question: '填空',
        options: <String>[],
        answerIndex: 0,
        explanation: 'print',
        type: 'fill',
        acceptedAnswers: <String>['print'],
      ),
    ];

    test('按表现推荐档位', () {
      expect(
        AdaptiveQuizService.recommendLevel(
          recentAccuracy: 0,
          recentAttempts: 0,
          correctStreak: 0,
        ),
        QuizLevel.warmup,
      );
      expect(
        AdaptiveQuizService.recommendLevel(
          recentAccuracy: 0.9,
          recentAttempts: 5,
          correctStreak: 4,
        ),
        QuizLevel.challenge,
      );
      expect(
        AdaptiveQuizService.recommendLevel(
          recentAccuracy: 0.7,
          recentAttempts: 5,
          correctStreak: 1,
        ),
        QuizLevel.standard,
      );
    });

    test('相同种子生成稳定且题量正确的计划', () {
      final lesson = _lesson('a', quiz: quiz);
      final first = AdaptiveQuizService.buildPlan(
        lesson: lesson,
        level: QuizLevel.standard,
        questionCount: 3,
        seed: 7,
      );
      final second = AdaptiveQuizService.buildPlan(
        lesson: lesson,
        level: QuizLevel.standard,
        questionCount: 3,
        seed: 7,
      );
      expect(first.questions.length, 3);
      expect(
        first.questions.map((item) => item.question),
        second.questions.map((item) => item.question),
      );
    });

    test('选项乱序后正确答案的内容保持不变', () {
      const question = QuizQuestion(
        question: '选出正确项',
        options: <String>['A', 'B', 'C', 'D'],
        answerIndex: 2,
        explanation: 'C',
      );
      final shuffled = AdaptiveQuizService.shuffleQuestionOptions(question, 3);
      expect(shuffled.options.length, 4);
      expect(shuffled.options[shuffled.answerIndex], 'C');
      expect(shuffled.options.toSet(), question.options.toSet());
    });

    test('多选题乱序后所有正确选项仍被保留', () {
      const question = QuizQuestion(
        question: '多选',
        options: <String>['W', 'X', 'Y', 'Z'],
        answerIndex: 0,
        explanation: '',
        type: 'multi',
        answerIndexes: <int>[0, 3],
      );
      final shuffled = AdaptiveQuizService.shuffleQuestionOptions(question, 11);
      final correct = shuffled.answerIndexes
          .map((index) => shuffled.options[index])
          .toSet();
      expect(correct, <String>{'W', 'Z'});
    });

    test('测验结束后给出升降档建议', () {
      final up = AdaptiveQuizService.feedback(
        currentLevel: QuizLevel.standard,
        correct: 5,
        total: 5,
      );
      expect(up.nextLevel, QuizLevel.challenge);
      final down = AdaptiveQuizService.feedback(
        currentLevel: QuizLevel.challenge,
        correct: 1,
        total: 5,
      );
      expect(down.nextLevel, QuizLevel.standard);
    });
  });
}
