import 'dart:math' as math;

import '../models/lesson.dart';
import '../models/study_center.dart';
import 'practice_question_factory.dart';
import 'progress_provider.dart';
import 'settings_provider.dart';

/// 学习中心纯逻辑：把课程、进度和用户目标组合成可执行的今日任务、
/// 未来日历、挑战与学习报告。页面层只负责展示，不重复计算规则。
class StudyCenterService {
  const StudyCenterService._();

  static const int defaultCalendarDays = 14;

  static List<StudyTask> todayTasks({
    required List<Lesson> lessons,
    required ProgressProvider progress,
    required SettingsProvider settings,
  }) {
    final byId = <String, Lesson>{
      for (final lesson in lessons) lesson.id: lesson,
    };
    final tasks = <StudyTask>[];

    final reviewPlan = progress.reviewPlanFor(
      lessons,
      budgetMinutes: settings.reviewSessionMinutes,
    );
    for (final item in reviewPlan.items.take(4)) {
      tasks.add(
        StudyTask(
          id: 'review:${item.lesson.id}',
          kind: StudyTaskKind.review,
          title: item.lesson.title.zh,
          subtitle: item.overdueDays == 0
              ? '今日到期'
              : '已逾期 ${item.overdueDays} 天',
          minutes: item.minutes,
          lessonId: item.lesson.id,
        ),
      );
    }

    final next = _nextLesson(lessons, progress, settings);
    if (next != null) {
      tasks.add(
        StudyTask(
          id: 'new:${next.id}',
          kind: StudyTaskKind.newLesson,
          title: next.title.zh,
          subtitle: '${next.difficulty} · 建议先学新知识',
          minutes: math.max(5, next.minutes),
          lessonId: next.id,
        ),
      );
    }

    if (progress.wrongQuestionKeys.isNotEmpty) {
      tasks.add(
        StudyTask(
          id: 'wrong:today',
          kind: StudyTaskKind.wrongPractice,
          title: '错题专项',
          subtitle: '${progress.wrongQuestionKeys.length} 道待消灭错题',
          minutes: math.min(
            20,
            math.max(5, progress.wrongQuestionKeys.length * 2),
          ),
        ),
      );
    }

    if (!progress.dailyQuestionAnsweredToday) {
      tasks.add(
        const StudyTask(
          id: 'daily:today',
          kind: StudyTaskKind.dailyQuestion,
          title: '每日一题',
          subtitle: '用 2 分钟保持连续学习',
          minutes: 2,
        ),
      );
    }

    final challenge = dailyChallenge(progress: progress);
    if (!challenge.completed) {
      tasks.add(
        StudyTask(
          id: 'challenge:${challenge.id}',
          kind: StudyTaskKind.challenge,
          title: challenge.title,
          subtitle: challenge.description,
          minutes: 5,
        ),
      );
    }

    final project = _nextProjectMilestone(lessons, progress);
    if (project != null) {
      final lesson = byId[project.lessonId];
      tasks.add(
        StudyTask(
          id: 'project:${project.id}',
          kind: StudyTaskKind.project,
          title: project.title,
          subtitle: lesson == null ? '项目实战' : lesson.title.zh,
          minutes: 20,
          lessonId: project.lessonId,
        ),
      );
    }

    tasks.sort((a, b) {
      final kind = a.kind.index.compareTo(b.kind.index);
      if (kind != 0) return kind;
      return b.minutes.compareTo(a.minutes);
    });
    return List<StudyTask>.unmodifiable(tasks);
  }

  static StudyDayPlan buildDayPlan({
    required DateTime date,
    required List<Lesson> lessons,
    required ProgressProvider progress,
    required SettingsProvider settings,
    bool includeNewLessons = true,
  }) {
    final tasks = <StudyTask>[];
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    for (final lesson in lessons) {
      if (lesson.totalQuestionCount == 0) continue;
      final due = progress.reviewDueAt(lesson.id);
      if (due == null || due.isBefore(dayStart) || !due.isBefore(dayEnd)) {
        continue;
      }
      tasks.add(
        StudyTask(
          id: 'review:${lesson.id}:${dayStart.toIso8601String()}',
          kind: StudyTaskKind.review,
          title: lesson.title.zh,
          subtitle: '计划复习',
          minutes: math.max(2, (lesson.minutes * 0.35).round()),
          lessonId: lesson.id,
        ),
      );
    }
    final today = progress.now;
    final todayStart = DateTime(today.year, today.month, today.day);
    if (includeNewLessons &&
        !dayStart.isBefore(todayStart.subtract(const Duration(days: 1)))) {
      final unlearned =
          lessons.where((lesson) => !progress.isLearned(lesson.id)).toList()
            ..sort((a, b) {
              final category = a.categoryId.compareTo(b.categoryId);
              return category != 0 ? category : a.order.compareTo(b.order);
            });
      final offset = dayStart.difference(todayStart).inDays.clamp(0, 30);
      if (offset < unlearned.length) {
        final lesson = unlearned[offset];
        tasks.add(
          StudyTask(
            id: 'new:${lesson.id}:${dayStart.toIso8601String()}',
            kind: StudyTaskKind.newLesson,
            title: lesson.title.zh,
            subtitle: '推荐新知识',
            minutes: math.max(5, lesson.minutes),
            lessonId: lesson.id,
          ),
        );
      }
    }
    final total = tasks.fold<int>(0, (sum, item) => sum + item.minutes);
    return StudyDayPlan(
      date: dayStart,
      tasks: List<StudyTask>.unmodifiable(tasks),
      totalMinutes: total,
    );
  }

  static List<StudyDayPlan> calendar({
    required List<Lesson> lessons,
    required ProgressProvider progress,
    required SettingsProvider settings,
    int days = defaultCalendarDays,
    DateTime? from,
  }) {
    final start = from ?? progress.now;
    final today = DateTime(start.year, start.month, start.day);
    return List<StudyDayPlan>.generate(
      days,
      (index) => buildDayPlan(
        date: today.add(Duration(days: index)),
        lessons: lessons,
        progress: progress,
        settings: settings,
      ),
      growable: false,
    );
  }

  static DateTime? estimatedCompletionDate({
    required List<Lesson> lessons,
    required ProgressProvider progress,
    required SettingsProvider settings,
  }) {
    final remaining = lessons.where((lesson) => !progress.isLearned(lesson.id));
    if (remaining.isEmpty) return progress.now;
    final minutes = remaining.fold<int>(
      0,
      (sum, lesson) => sum + math.max(5, lesson.minutes),
    );
    final daily = math.max(5, settings.dailyGoalMinutes);
    final days = (minutes / daily).ceil();
    return DateTime(
      progress.now.year,
      progress.now.month,
      progress.now.day,
    ).add(Duration(days: days));
  }

  static StudyChallenge dailyChallenge({required ProgressProvider progress}) {
    const target = 3;
    final done = progress.answeredQuestionKeysToday.length;
    final key = _dayKey(progress.now);
    return StudyChallenge(
      id: 'daily-$key',
      kind: StudyChallengeKind.daily,
      title: '每日挑战 · 完成 3 道题',
      description: '今天是 $key，完成跨课程练习即可打卡。',
      target: target,
      progress: done,
      completed: progress.isChallengeDone('daily-$key') || done >= target,
    );
  }

  static StudyChallenge weeklyChallenge({required ProgressProvider progress}) {
    const target = 120;
    final done = progress.studyMinutesInLastDays(7);
    final key = _weekKey(progress.now);
    return StudyChallenge(
      id: 'weekly-$key',
      kind: StudyChallengeKind.weekly,
      title: '每周挑战 · 学习 120 分钟',
      description: '按最近 7 天累计时长计算，断网数据同样有效。',
      target: target,
      progress: done,
      completed: progress.isChallengeDone('weekly-$key') || done >= target,
    );
  }

  static String reportMarkdown({
    required List<Lesson> lessons,
    required ProgressProvider progress,
    required SettingsProvider settings,
  }) {
    final learned = progress.learnedIds.length;
    final ratio = lessons.isEmpty ? 0.0 : learned / lessons.length;
    final daily = progress.dailyStudyMinutes(7);
    final next = _nextLesson(lessons, progress, settings);
    final buffer = StringBuffer()
      ..writeln('# 学习报告')
      ..writeln()
      ..writeln('- 生成时间：${_formatTime(progress.now)}')
      ..writeln(
        '- 已学课程：$learned / ${lessons.length}（${(ratio * 100).round()}%）',
      )
      ..writeln('- 平均正确率：${(progress.averageQuizAccuracy * 100).round()}%')
      ..writeln('- 连续学习：${progress.streakDays} 天')
      ..writeln('- 累计学习：${progress.totalStudyMinutes} 分钟')
      ..writeln('- 待复习：${progress.dueReviewCount} 门')
      ..writeln('- 错题本：${progress.totalWrongQuestions} 道')
      ..writeln()
      ..writeln('## 最近 7 天')
      ..writeln()
      ..writeln('| 日期 | 学习分钟 |')
      ..writeln('| --- | ---: |');
    for (var i = 0; i < daily.length; i++) {
      final day = progress.now.subtract(Duration(days: daily.length - 1 - i));
      buffer.writeln('| ${day.month}-${day.day} | ${daily[i]} |');
    }
    buffer
      ..writeln()
      ..writeln('## 下一步建议')
      ..writeln()
      ..writeln(
        next == null ? '所有课程已完成，建议进入复习与项目实战。' : '- 学习：${next.title.zh}',
      );
    if (progress.dueReviewCount > 0) {
      buffer.writeln('- 复习：今天有 ${progress.dueReviewCount} 门课程到期。');
    }
    if (progress.wrongQuestionKeys.isNotEmpty) {
      buffer.writeln('- 巩固：错题本还有 ${progress.wrongQuestionKeys.length} 道题。');
    }
    return buffer.toString().trimRight();
  }

  static String reportCsv({required ProgressProvider progress}) {
    final buffer = StringBuffer(
      'date,study_minutes,streak_days,quiz_accuracy\n',
    );
    final days = progress.dailyStudyMinutes(30);
    for (var i = 0; i < days.length; i++) {
      final day = progress.now.subtract(Duration(days: days.length - 1 - i));
      buffer.writeln(
        '${_dayKey(day)},${days[i]},${progress.streakDays},'
        '${(progress.averageQuizAccuracy * 100).round()}',
      );
    }
    return buffer.toString().trimRight();
  }

  static Lesson? _nextLesson(
    List<Lesson> lessons,
    ProgressProvider progress,
    SettingsProvider settings,
  ) {
    final selectedPath = settings.selectedPathId;
    final ordered = [...lessons]
      ..sort((a, b) {
        if (selectedPath.isNotEmpty) {
          final aMatch = a.categoryId == selectedPath ? 0 : 1;
          final bMatch = b.categoryId == selectedPath ? 0 : 1;
          if (aMatch != bMatch) return aMatch.compareTo(bMatch);
        }
        final category = a.categoryId.compareTo(b.categoryId);
        return category != 0 ? category : a.order.compareTo(b.order);
      });
    for (final lesson in ordered) {
      if (!progress.isLearned(lesson.id)) return lesson;
    }
    return null;
  }

  static ProjectMilestone? _nextProjectMilestone(
    List<Lesson> lessons,
    ProgressProvider progress,
  ) {
    for (final lesson in lessons.where(
      (lesson) => lesson.id.contains('project'),
    )) {
      final milestones = progress.milestonesForLesson(lesson.id);
      for (final milestone in milestones) {
        if (!milestone.done) return milestone;
      }
    }
    return null;
  }

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String _weekKey(DateTime day) {
    final thursday = day.add(
      Duration(days: 4 - (day.weekday == 0 ? 7 : day.weekday)),
    );
    final first = DateTime(thursday.year, 1, 1);
    final week = ((thursday.difference(first).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}
