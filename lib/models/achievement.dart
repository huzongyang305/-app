import 'package:flutter/material.dart';

import '../services/progress_provider.dart';

/// 成就衡量的指标来源。
enum AchievementMetric {
  /// 已学知识点数量。
  learned,

  /// 连续学习天数。
  streak,

  /// 测验平均正确率（百分比）。
  quizAccuracy,

  /// 笔记条数。
  notes,

  /// 收藏数量。
  favorites,
}

/// 一枚徽章的定义：指标 + 目标值即构成解锁条件。
class Achievement {
  const Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.metric,
    required this.target,
    this.minimumQuizzes = 0,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final AchievementMetric metric;

  /// 解锁所需达到的数值。
  final double target;

  /// 仅对「正确率」类成就有意义：样本不足时不计进度，
  /// 避免只做一道题就拿到高正确率徽章。
  final int minimumQuizzes;

  /// 当前进度值。
  double valueOf(ProgressProvider progress) {
    switch (metric) {
      case AchievementMetric.learned:
        return progress.learnedIds.length.toDouble();
      case AchievementMetric.streak:
        return progress.streakDays.toDouble();
      case AchievementMetric.notes:
        return progress.notes.length.toDouble();
      case AchievementMetric.favorites:
        return progress.favoriteIds.length.toDouble();
      case AchievementMetric.quizAccuracy:
        if (progress.quizResults.length < minimumQuizzes) return 0;
        return progress.averageQuizAccuracy * 100;
    }
  }
}

/// 徽章 + 当前进度，用于界面展示。
class AchievementStatus {
  const AchievementStatus({required this.achievement, required this.value});

  final Achievement achievement;
  final double value;

  bool get earned => value >= achievement.target;

  /// 0~1，用于进度环或进度条。
  double get ratio => achievement.target <= 0
      ? 1
      : (value / achievement.target).clamp(0.0, 1.0);

  int get displayValue => value.round();

  int get targetValue => achievement.target.round();
}

/// 全部徽章定义。新增成就只需在这里追加一条。
const List<Achievement> kAchievements = <Achievement>[
  Achievement(
    id: 'first_lesson',
    titleKey: 'achFirstLesson',
    descriptionKey: 'achFirstLessonDesc',
    icon: Icons.play_circle_outline,
    metric: AchievementMetric.learned,
    target: 1,
  ),
  Achievement(
    id: 'lessons_10',
    titleKey: 'achLessons10',
    descriptionKey: 'achLessons10Desc',
    icon: Icons.auto_stories_outlined,
    metric: AchievementMetric.learned,
    target: 10,
  ),
  Achievement(
    id: 'lessons_50',
    titleKey: 'achLessons50',
    descriptionKey: 'achLessons50Desc',
    icon: Icons.menu_book_outlined,
    metric: AchievementMetric.learned,
    target: 50,
  ),
  Achievement(
    id: 'lessons_100',
    titleKey: 'achLessons100',
    descriptionKey: 'achLessons100Desc',
    icon: Icons.workspace_premium_outlined,
    metric: AchievementMetric.learned,
    target: 100,
  ),
  Achievement(
    id: 'streak_3',
    titleKey: 'achStreak3',
    descriptionKey: 'achStreak3Desc',
    icon: Icons.local_fire_department_outlined,
    metric: AchievementMetric.streak,
    target: 3,
  ),
  Achievement(
    id: 'streak_7',
    titleKey: 'achStreak7',
    descriptionKey: 'achStreak7Desc',
    icon: Icons.whatshot_outlined,
    metric: AchievementMetric.streak,
    target: 7,
  ),
  Achievement(
    id: 'streak_30',
    titleKey: 'achStreak30',
    descriptionKey: 'achStreak30Desc',
    icon: Icons.emoji_events_outlined,
    metric: AchievementMetric.streak,
    target: 30,
  ),
  Achievement(
    id: 'quiz_80',
    titleKey: 'achQuiz80',
    descriptionKey: 'achQuiz80Desc',
    icon: Icons.track_changes_outlined,
    metric: AchievementMetric.quizAccuracy,
    target: 80,
    minimumQuizzes: 5,
  ),
  Achievement(
    id: 'notes_10',
    titleKey: 'achNotes10',
    descriptionKey: 'achNotes10Desc',
    icon: Icons.edit_note_outlined,
    metric: AchievementMetric.notes,
    target: 10,
  ),
  Achievement(
    id: 'favorites_10',
    titleKey: 'achFavorites10',
    descriptionKey: 'achFavorites10Desc',
    icon: Icons.star_outline,
    metric: AchievementMetric.favorites,
    target: 10,
  ),
];

/// 计算全部徽章的当前状态（界面按此渲染）。
List<AchievementStatus> evaluateAchievements(ProgressProvider progress) {
  return <AchievementStatus>[
    for (final achievement in kAchievements)
      AchievementStatus(
        achievement: achievement,
        value: achievement.valueOf(progress),
      ),
  ];
}

/// 已解锁徽章数量。
int earnedAchievementCount(List<AchievementStatus> statuses) =>
    statuses.where((status) => status.earned).length;
