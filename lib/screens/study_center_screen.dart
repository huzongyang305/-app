import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/study_center.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../services/study_center_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_content.dart';
import 'daily_question_screen.dart';
import 'exam_screen.dart';
import 'lesson_screen.dart';
import 'review_plan_screen.dart';

/// 今日学习中心：把复习、新知识、错题、每日一题与挑战合并成一份可执行清单，
/// 同时展示学习日历、挑战进度、项目里程碑与可复制的学习报告。
///
/// 所有数据都来自本地进度与 assets 课程，完全离线可用。
class StudyCenterScreen extends StatelessWidget {
  const StudyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();

    if (content.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('studyCenterTitle'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final lessons = content.allLessons;
    final tasks = StudyCenterService.todayTasks(
      lessons: lessons,
      progress: progress,
      settings: settings,
    );
    final totalMinutes = tasks.fold<int>(0, (sum, item) => sum + item.minutes);
    final daily = StudyCenterService.dailyChallenge(progress: progress);
    final weekly = StudyCenterService.weeklyChallenge(progress: progress);
    final calendar = StudyCenterService.calendar(
      lessons: lessons,
      progress: progress,
      settings: settings,
    );
    final completion = StudyCenterService.estimatedCompletionDate(
      lessons: lessons,
      progress: progress,
      settings: settings,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('studyCenterTitle')),
        actions: [
          IconButton(
            tooltip: context.tr('studyReportTitle'),
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showReportSheet(context),
          ),
        ],
      ),
      body: ResponsiveContent(
        child: ListView(
          children: [
            Text(
              context.tr('studyCenterSubtitle'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionTitle(
              icon: Icons.checklist_rtl,
              title: context.tr('studyCenterTasks'),
              trailing: tasks.isEmpty
                  ? null
                  : context.trArgs('studyCenterTotalMinutes', {
                      'n': totalMinutes,
                    }),
            ),
            if (tasks.isEmpty)
              EmptyState(
                icon: Icons.wb_sunny_outlined,
                message: context.tr('studyCenterEmpty'),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < tasks.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _TaskTile(
                        task: tasks[i],
                        onStart: () => _openTask(context, tasks[i]),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(
              icon: Icons.emoji_events_outlined,
              title: context.tr('studyChallenges'),
            ),
            Card(
              child: Column(
                children: [
                  _ChallengeTile(
                    challenge: daily,
                    onComplete: () => progress.markChallengeDone(daily.id),
                  ),
                  const Divider(height: 1),
                  _ChallengeTile(
                    challenge: weekly,
                    onComplete: () => progress.markChallengeDone(weekly.id),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(
              icon: Icons.calendar_month_outlined,
              title: context.tr('studyCalendarTitle'),
              trailing: context.trArgs('studyCalendarHint', {
                'n': calendar.length,
              }),
            ),
            if (completion != null) ...[
              Text(
                context.trArgs('studyEstimatedCompletion', {
                  'date': _formatDate(completion),
                }),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _CalendarCard(
              plans: calendar,
              onOpenDay: (plan) => _openTasks(context, plan.tasks),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(
              icon: Icons.flag_outlined,
              title: context.tr('studyProjects'),
            ),
            _ProjectSection(lessons: lessons, progress: progress),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// 任务跳转：复习、课程、错题、每日一题、挑战与项目各自进入对应页面。
  Future<void> _openTask(BuildContext context, StudyTask task) async {
    final progress = context.read<ProgressProvider>();
    switch (task.kind) {
      case StudyTaskKind.review:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ReviewPlanScreen()),
        );
      case StudyTaskKind.newLesson:
        await _openLessonById(context, task.lessonId);
      case StudyTaskKind.wrongPractice:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                const ExamScreen(wrongOnly: true, practiceMode: true),
          ),
        );
      case StudyTaskKind.dailyQuestion:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DailyQuestionScreen()),
        );
      case StudyTaskKind.challenge:
        await progress.markChallengeDone(
          task.id.replaceFirst('challenge:', ''),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('studyChallengeCompleted'))),
          );
        }
      case StudyTaskKind.project:
        final lesson = _lessonById(context, task.lessonId);
        if (lesson == null) return;
        final milestones = progress.milestonesForLesson(lesson.id);
        final pending = milestones.where((item) => !item.done).toList();
        if (pending.isEmpty) {
          await _openLessonById(context, lesson.id);
          return;
        }
        await progress.toggleProjectMilestone(pending.first.id, true);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(pending.first.title)));
        }
    }
  }

  Future<void> _openTasks(BuildContext context, List<StudyTask> tasks) async {
    if (tasks.isEmpty) return;
    await _openTask(context, tasks.first);
  }

  Lesson? _lessonById(BuildContext context, String? id) {
    if (id == null) return null;
    for (final lesson in context.read<ContentProvider>().allLessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  Future<void> _openLessonById(BuildContext context, String? id) async {
    final lesson = _lessonById(context, id);
    if (lesson == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
    );
  }

  /// 学习报告：Markdown 便于阅读，CSV 便于二次分析，两者都可直接复制。
  void _showReportSheet(BuildContext context) {
    final progress = context.read<ProgressProvider>();
    final settings = context.read<SettingsProvider>();
    final lessons = context.read<ContentProvider>().allLessons;
    final markdown = StudyCenterService.reportMarkdown(
      lessons: lessons,
      progress: progress,
      settings: settings,
    );
    final csv = StudyCenterService.reportCsv(progress: progress);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(context.tr('studyReportMarkdown')),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: markdown));
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('studyReportCopied'))),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: Text(context.tr('studyReportCsv')),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: csv));
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('studyReportCopied'))),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onStart});

  final StudyTask task;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, labelKey, color) = switch (task.kind) {
      StudyTaskKind.review => (
        Icons.history,
        'studyTaskReview',
        AppPalette.primary,
      ),
      StudyTaskKind.newLesson => (
        Icons.auto_stories_outlined,
        'studyTaskNew',
        AppPalette.success,
      ),
      StudyTaskKind.wrongPractice => (
        Icons.error_outline,
        'studyTaskWrong',
        AppPalette.danger,
      ),
      StudyTaskKind.dailyQuestion => (
        Icons.lightbulb_outline,
        'studyTaskDaily',
        AppPalette.warning,
      ),
      StudyTaskKind.challenge => (
        Icons.emoji_events_outlined,
        'studyTaskChallenge',
        AppPalette.primary,
      ),
      StudyTaskKind.project => (
        Icons.construction_outlined,
        'studyTaskProject',
        AppPalette.slate600,
      ),
    };
    return ListTile(
      onTap: onStart,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${context.tr(labelKey)} · ${task.subtitle} · '
        '${context.trArgs('studyMinutesShort', {'n': task.minutes})}',
        maxLines: 2,
      ),
      trailing: TextButton(
        onPressed: onStart,
        child: Text(context.tr('studyTaskStart')),
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge, required this.onComplete});

  final StudyChallenge challenge;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = challenge.completed
        ? AppPalette.success
        : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                challenge.completed
                    ? Icons.check_circle
                    : Icons.timelapse_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  challenge.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                context.trArgs('studyChallengeProgress', {
                  'done': challenge.progress,
                  'target': challenge.target,
                }),
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            challenge.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: challenge.ratio,
              minHeight: 6,
              color: color,
            ),
          ),
          if (!challenge.completed) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onComplete,
                child: Text(context.tr('studyChallengeCompleted')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.plans, required this.onOpenDay});

  final List<StudyDayPlan> plans;
  final ValueChanged<StudyDayPlan> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (final plan in plans)
              InkWell(
                onTap: plan.isEmpty ? null : () => onOpenDay(plan),
                borderRadius: AppRadii.chip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 74,
                        child: Text(
                          '${plan.date.month}/${plan.date.day}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontFamily: AppTheme.monoFamily,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          plan.isEmpty
                              ? context.tr('studyNoPlan')
                              : plan.tasks
                                    .map((item) => item.title)
                                    .take(2)
                                    .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        plan.isEmpty
                            ? ''
                            : context.trArgs('studyMinutesShort', {
                                'n': plan.totalMinutes,
                              }),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSection extends StatelessWidget {
  const _ProjectSection({required this.lessons, required this.progress});

  final List<Lesson> lessons;
  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final projects = lessons
        .where((lesson) => lesson.id.contains('project'))
        .take(6)
        .toList(growable: false);
    if (projects.isEmpty) {
      return EmptyState(
        icon: Icons.construction_outlined,
        message: context.tr('studyProjectsEmpty'),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < projects.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _ProjectTile(lesson: projects[i], progress: progress),
          ],
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.lesson, required this.progress});

  final Lesson lesson;
  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final milestones = progress.milestonesForLesson(lesson.id);
    final done = milestones.where((item) => item.done).length;
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      leading: const Icon(Icons.construction_outlined),
      title: Text(
        lesson.title.of(context.strings.localeCode),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        context.trArgs('studyChallengeProgress', {
          'done': done,
          'target': milestones.length,
        }),
      ),
      children: [
        for (final milestone in milestones)
          CheckboxListTile(
            dense: true,
            value: milestone.done,
            title: Text(milestone.title),
            onChanged: (value) =>
                progress.toggleProjectMilestone(milestone.id, value ?? false),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LessonScreen(lesson: lesson),
                ),
              ),
              child: Text(context.tr('studyOpenLesson')),
            ),
          ),
        ),
      ],
    );
  }
}
