import 'dart:math' as math;

import '../models/lesson.dart';
import 'practice_question_factory.dart';

/// 待复习课程：课程本身 + 它的到期时间（null 表示没有计划，按今天处理）。
class ReviewCandidate {
  const ReviewCandidate({required this.lesson, required this.dueAt});

  final Lesson lesson;
  final DateTime? dueAt;
}

/// 计划里的一条复习任务。
class ReviewPlanItem {
  const ReviewPlanItem({
    required this.lesson,
    required this.minutes,
    required this.overdueDays,
  });

  final Lesson lesson;

  /// 预计复习用时（分钟）：按阅读时长的三分之一估算，最少 2 分钟。
  final int minutes;

  /// 逾期天数：0 表示今天到期。
  final int overdueDays;
}

/// 一天的复习计划。
class ReviewPlan {
  const ReviewPlan({
    required this.items,
    required this.totalMinutes,
    required this.deferredCount,
  });

  final List<ReviewPlanItem> items;
  final int totalMinutes;

  /// 超出每日时间预算、顺延到明天的课程数量。
  final int deferredCount;

  bool get isEmpty => items.isEmpty;

  int get count => items.length;
}

/// 生成每日复习计划：逾期越久越靠前，同优先级先做用时短的。
///
/// [budgetMinutes] 是每天愿意投入的复习上限，默认 30 分钟；超出的任务
/// 仍然保留在复习队列里，只是不在今天这一批中，避免一次复习过载。
ReviewPlan buildReviewPlan(
  List<ReviewCandidate> candidates, {
  int budgetMinutes = 30,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final sorted =
      candidates
          .where((candidate) => candidate.lesson.totalQuestionCount > 0)
          .map((candidate) => _toItem(candidate, today))
          .toList()
        ..sort((a, b) {
          final overdue = b.overdueDays.compareTo(a.overdueDays);
          if (overdue != 0) return overdue;
          final minutes = a.minutes.compareTo(b.minutes);
          if (minutes != 0) return minutes;
          return a.lesson.id.compareTo(b.lesson.id);
        });

  final items = <ReviewPlanItem>[];
  var used = 0;
  for (final item in sorted) {
    if (items.isNotEmpty && used + item.minutes > budgetMinutes) continue;
    items.add(item);
    used += item.minutes;
  }
  return ReviewPlan(
    items: items,
    totalMinutes: used,
    deferredCount: sorted.length - items.length,
  );
}

ReviewPlanItem _toItem(ReviewCandidate candidate, DateTime today) {
  final due = candidate.dueAt;
  final minutes = math.max(2, (candidate.lesson.minutes * 0.35).round());
  if (due == null) {
    return ReviewPlanItem(
      lesson: candidate.lesson,
      minutes: minutes,
      overdueDays: 0,
    );
  }
  final todayStart = DateTime(today.year, today.month, today.day);
  final dueStart = DateTime(due.year, due.month, due.day);
  final overdue = todayStart.difference(dueStart).inDays;
  return ReviewPlanItem(
    lesson: candidate.lesson,
    minutes: minutes,
    overdueDays: math.max(0, overdue),
  );
}
