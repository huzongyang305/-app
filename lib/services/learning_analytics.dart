import '../models/lesson.dart';
import '../models/lesson_category.dart';
import 'progress_provider.dart';

/// 单个课程分类的学习分析结果。
class CategoryMastery {
  const CategoryMastery({
    required this.category,
    required this.totalLessons,
    required this.learnedLessons,
    required this.quizzedLessons,
    required this.wrongQuestions,
    required this.estimatedMinutes,
    required this.averageAccuracy,
  });

  final LessonCategory category;
  final int totalLessons;
  final int learnedLessons;
  final int quizzedLessons;
  final int wrongQuestions;
  final int estimatedMinutes;
  final double averageAccuracy;

  double get learnedRatio =>
      totalLessons == 0 ? 0 : learnedLessons / totalLessons;

  /// 没有测验时不把测验正确率当成 0 分，而是主要按学习进度估算掌握度。
  double get masteryScore {
    if (totalLessons == 0) return 0;
    if (quizzedLessons == 0) return learnedRatio * 0.8;
    return (learnedRatio * 0.55) + (averageAccuracy * 0.45);
  }

  bool get isWeak =>
      learnedRatio < 0.6 || (quizzedLessons > 0 && averageAccuracy < 0.7);
}

/// 需要优先复习的知识点。
class WeakLesson {
  const WeakLesson({
    required this.lesson,
    required this.accuracy,
    required this.wrongCount,
  });

  final Lesson lesson;
  final double accuracy;
  final int wrongCount;
}

/// 学习分析快照：只读取已有本地进度，不改变任何用户数据。
class LearningAnalytics {
  const LearningAnalytics({
    required this.periodDays,
    required this.activity,
    required this.previousActivity,
    required this.streakDays,
    required this.totalLearned,
    required this.totalLessons,
    required this.averageAccuracy,
    required this.estimatedMinutes,
    required this.categoryMastery,
    required this.weakLessons,
    required this.recommendedLesson,
    required this.studyMinutesPerDay,
  });

  final int periodDays;
  final List<int> activity;
  final int previousActivity;
  final int streakDays;
  final int totalLearned;
  final int totalLessons;
  final double averageAccuracy;
  final int estimatedMinutes;
  final List<CategoryMastery> categoryMastery;
  final List<WeakLesson> weakLessons;
  final Lesson? recommendedLesson;

  /// 最近 [periodDays] 天每天的真实学习时长（分钟），最后一项是今天。
  final List<int> studyMinutesPerDay;

  int get studyMinutes =>
      studyMinutesPerDay.fold<int>(0, (sum, value) => sum + value);

  int get averageStudyMinutesPerDay => studyMinutesPerDay.isEmpty
      ? 0
      : (studyMinutes / studyMinutesPerDay.length).round();

  int get activityTotal => activity.fold<int>(0, (sum, value) => sum + value);

  int get activeDays => activity.where((value) => value > 0).length;

  int get activityTrend => activityTotal - previousActivity;

  double get progressRatio =>
      totalLessons == 0 ? 0 : totalLearned / totalLessons;

  List<CategoryMastery> get weakestCategories {
    final values = [...categoryMastery]
      ..sort((a, b) {
        final byScore = a.masteryScore.compareTo(b.masteryScore);
        if (byScore != 0) return byScore;
        return a.learnedRatio.compareTo(b.learnedRatio);
      });
    return values.take(5).toList(growable: false);
  }

  /// 从当前分类和课程构建分析快照。
  factory LearningAnalytics.build({
    required List<LessonCategory> categories,
    required ProgressProvider progress,
    int periodDays = 7,
    DateTime? now,
  }) {
    final days = _normalizePeriod(periodDays);
    // 取两倍窗口，前半段作为上一周期，用于周报环比。
    final allActivity = progress.dailyActivity(days * 2);
    final activity = allActivity.sublist(days);
    final previousActivity = allActivity
        .take(days)
        .fold<int>(0, (sum, value) => sum + value);

    final categoryRows = <CategoryMastery>[];
    final weakRows = <WeakLesson>[];
    var estimatedMinutes = 0;

    for (final category in categories) {
      var learned = 0;
      var quizzed = 0;
      var wrong = 0;
      var minutes = 0;
      var accuracyTotal = 0.0;

      for (final lesson in category.lessons) {
        if (progress.isLearned(lesson.id)) {
          learned++;
          minutes += lesson.minutes;
        }

        final result = progress.resultOf(lesson.id);
        final lessonWrong = progress.wrongCountFor(lesson.id);
        wrong += lessonWrong;

        if (result != null) {
          quizzed++;
          accuracyTotal += result.accuracy;
          if (result.accuracy < 0.8 || lessonWrong > 0) {
            weakRows.add(
              WeakLesson(
                lesson: lesson,
                accuracy: result.accuracy,
                wrongCount: lessonWrong,
              ),
            );
          }
        } else if (lessonWrong > 0) {
          weakRows.add(
            WeakLesson(lesson: lesson, accuracy: 0, wrongCount: lessonWrong),
          );
        }
      }

      estimatedMinutes += minutes;
      categoryRows.add(
        CategoryMastery(
          category: category,
          totalLessons: category.lessons.length,
          learnedLessons: learned,
          quizzedLessons: quizzed,
          wrongQuestions: wrong,
          estimatedMinutes: minutes,
          averageAccuracy: quizzed == 0 ? 0 : accuracyTotal / quizzed,
        ),
      );
    }

    weakRows.sort((a, b) {
      final byAccuracy = a.accuracy.compareTo(b.accuracy);
      if (byAccuracy != 0) return byAccuracy;
      return b.wrongCount.compareTo(a.wrongCount);
    });

    final orderedCategories = [...categoryRows]
      ..sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
    Lesson? recommended;
    for (final mastery in orderedCategories) {
      recommended = mastery.category.lessons
          .where((lesson) => !progress.isLearned(lesson.id))
          .firstOrNull;
      if (recommended != null) break;
    }
    recommended ??= weakRows.isEmpty ? null : weakRows.first.lesson;

    return LearningAnalytics(
      periodDays: days,
      activity: List<int>.unmodifiable(activity),
      previousActivity: previousActivity,
      streakDays: progress.streakDays,
      totalLearned: progress.learnedIds.length,
      totalLessons: categories.fold<int>(
        0,
        (sum, category) => sum + category.lessons.length,
      ),
      averageAccuracy: progress.averageQuizAccuracy,
      estimatedMinutes: estimatedMinutes,
      categoryMastery: List<CategoryMastery>.unmodifiable(categoryRows),
      weakLessons: List<WeakLesson>.unmodifiable(weakRows.take(8)),
      recommendedLesson: recommended,
      studyMinutesPerDay: List<int>.unmodifiable(
        progress.dailyStudyMinutes(days),
      ),
    );
  }

  static int _normalizePeriod(int value) {
    if (value <= 7) return 7;
    if (value <= 14) return 14;
    return 30;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
