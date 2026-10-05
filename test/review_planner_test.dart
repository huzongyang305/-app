import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/services/review_planner.dart';
import 'package:flutter_test/flutter_test.dart';

/// 每日复习计划：排序、用时估算、时间预算与顺延。
void main() {
  Lesson lesson(String id, {int minutes = 10, bool withQuiz = true}) => Lesson(
    id: id,
    categoryId: 'test',
    title: LocalizedText(zh: '课程 $id', en: 'Lesson $id'),
    summary: const LocalizedText(zh: '摘要', en: 'Summary'),
    assetFile: 'assets/content/$id.md',
    minutes: minutes,
    keywords: const <String>['测试'],
    quiz: withQuiz
        ? const <QuizQuestion>[
            QuizQuestion(
              question: '题干',
              options: <String>['A', 'B'],
              answerIndex: 0,
              explanation: '解析',
            ),
          ]
        : const <QuizQuestion>[],
  );

  test('逾期越久越靠前，同优先级先做用时短的', () {
    final now = DateTime(2026, 10, 5, 9);
    final plan = buildReviewPlan(
      <ReviewCandidate>[
        ReviewCandidate(
          lesson: lesson('today_long', minutes: 40),
          dueAt: DateTime(2026, 10, 5, 8),
        ),
        ReviewCandidate(
          lesson: lesson('overdue_3', minutes: 30),
          dueAt: DateTime(2026, 10, 2, 8),
        ),
        ReviewCandidate(
          lesson: lesson('overdue_1_short', minutes: 6),
          dueAt: DateTime(2026, 10, 4, 8),
        ),
        ReviewCandidate(
          lesson: lesson('overdue_1_long', minutes: 30),
          dueAt: DateTime(2026, 10, 4, 8),
        ),
      ],
      budgetMinutes: 120,
      now: now,
    );

    expect(plan.items.map((item) => item.lesson.id).toList(), <String>[
      'overdue_3',
      'overdue_1_short',
      'overdue_1_long',
      'today_long',
    ]);
    expect(plan.items.first.overdueDays, 3);
    expect(plan.items[1].overdueDays, 1);
    expect(plan.items.last.overdueDays, 0);
  });

  test('预计用时按阅读时长三分之一估算，最少 2 分钟', () {
    final now = DateTime(2026, 10, 5);
    final plan = buildReviewPlan(
      <ReviewCandidate>[
        ReviewCandidate(lesson: lesson('short', minutes: 4), dueAt: now),
        ReviewCandidate(lesson: lesson('long', minutes: 30), dueAt: now),
      ],
      budgetMinutes: 60,
      now: now,
    );

    expect(plan.items.map((item) => item.minutes).toList(), <int>[2, 11]);
    expect(plan.totalMinutes, 13);
  });

  test('超出每日预算的任务顺延到明天', () {
    final now = DateTime(2026, 10, 5);
    final plan = buildReviewPlan(
      <ReviewCandidate>[
        for (var i = 0; i < 5; i++)
          ReviewCandidate(
            lesson: lesson('a$i', minutes: 30),
            dueAt: now.subtract(Duration(days: i)),
          ),
      ],
      budgetMinutes: 12,
      now: now,
    );

    expect(plan.count, 1);
    expect(plan.totalMinutes, 11);
    expect(plan.deferredCount, 4);
  });

  test('没有题目的课程不会进入复习计划', () {
    final now = DateTime(2026, 10, 5);
    final plan = buildReviewPlan(<ReviewCandidate>[
      ReviewCandidate(lesson: lesson('empty', withQuiz: false), dueAt: now),
    ], now: now);

    expect(plan.isEmpty, isTrue);
    expect(plan.totalMinutes, 0);
  });
}
