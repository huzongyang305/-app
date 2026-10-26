import 'dart:math' as math;

import '../models/lesson.dart';
import 'practice_question_factory.dart';

/// 题目级复习候选：一道题 + 它的调度状态。
class QuestionReviewCandidate {
  const QuestionReviewCandidate({
    required this.lesson,
    required this.questionIndex,
    this.dueAt,
    this.intervalDays = 1,
    this.lapses = 0,
    this.wrongCount = 0,
  });

  final Lesson lesson;
  final int questionIndex;
  final DateTime? dueAt;

  /// 当前间隔天数，仅用于展示。
  final int intervalDays;

  /// 累计遗忘次数。
  final int lapses;

  /// 错题本里的答错次数。
  final int wrongCount;

  QuizQuestion? get question =>
      questionIndex >= 0 && questionIndex < lesson.allQuiz.length
      ? lesson.allQuiz[questionIndex]
      : null;
}

/// 计划里的一道题目复习任务。
class QuestionReviewItem {
  const QuestionReviewItem({
    required this.candidate,
    required this.minutes,
    required this.overdueDays,
  });

  final QuestionReviewCandidate candidate;

  /// 预计用时：选择题约 1 分钟，多选 / 填空 / 排序 2 分钟，代码题 3 分钟。
  final int minutes;

  /// 逾期天数：0 表示今天到期。
  final int overdueDays;

  Lesson get lesson => candidate.lesson;
  int get questionIndex => candidate.questionIndex;
  QuizQuestion get question => candidate.question!;
}

/// 一次题目级复习批次。
class QuestionReviewPlan {
  const QuestionReviewPlan({
    required this.items,
    required this.totalMinutes,
    required this.deferredCount,
  });

  final List<QuestionReviewItem> items;
  final int totalMinutes;
  final int deferredCount;

  bool get isEmpty => items.isEmpty;
  int get count => items.length;
  int get totalCount => items.length + deferredCount;
}

/// 生成题目级复习队列：逾期越久越靠前，其次优先错得多、忘得多的题。
///
/// [budgetMinutes] 是一次复习愿意投入的分钟数；超出预算的题目顺延，
/// 但仍保留在调度状态里，下次进入会重新排队。
QuestionReviewPlan buildQuestionReviewPlan(
  List<QuestionReviewCandidate> candidates, {
  int budgetMinutes = 30,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final sorted =
      candidates
          .where((candidate) => candidate.question != null)
          .map((candidate) => _toItem(candidate, today))
          .toList()
        ..sort((a, b) {
          final overdue = b.overdueDays.compareTo(a.overdueDays);
          if (overdue != 0) return overdue;
          final wrong = b.candidate.wrongCount.compareTo(
            a.candidate.wrongCount,
          );
          if (wrong != 0) return wrong;
          final lapses = b.candidate.lapses.compareTo(a.candidate.lapses);
          if (lapses != 0) return lapses;
          final due = _dueKey(a).compareTo(_dueKey(b));
          if (due != 0) return due;
          final lesson = a.lesson.id.compareTo(b.lesson.id);
          if (lesson != 0) return lesson;
          return a.questionIndex.compareTo(b.questionIndex);
        });

  final items = <QuestionReviewItem>[];
  var used = 0;
  for (final item in sorted) {
    if (items.isNotEmpty && used + item.minutes > budgetMinutes) continue;
    items.add(item);
    used += item.minutes;
  }
  return QuestionReviewPlan(
    items: items,
    totalMinutes: used,
    deferredCount: sorted.length - items.length,
  );
}

QuestionReviewItem _toItem(QuestionReviewCandidate candidate, DateTime today) {
  final due = candidate.dueAt;
  final minutes = _minutesFor(candidate.question!);
  if (due == null) {
    return QuestionReviewItem(
      candidate: candidate,
      minutes: minutes,
      overdueDays: 0,
    );
  }
  final todayStart = DateTime(today.year, today.month, today.day);
  final dueStart = DateTime(due.year, due.month, due.day);
  return QuestionReviewItem(
    candidate: candidate,
    minutes: minutes,
    overdueDays: math.max(0, todayStart.difference(dueStart).inDays),
  );
}

int _minutesFor(QuizQuestion question) => switch (question.type) {
  'code' || 'debug' => 3,
  'multi' || 'fill' || 'order' => 2,
  _ => 1,
};

String _dueKey(QuestionReviewItem item) =>
    item.candidate.dueAt?.toIso8601String() ?? '';
