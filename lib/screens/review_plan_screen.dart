import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/practice_question_factory.dart';
import '../services/progress_provider.dart';
import '../services/review_planner.dart';
import '../services/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/index_card.dart';
import 'exam_screen.dart';
import 'quiz_screen.dart';

/// 复习队列：今日计划、分类筛选、场次时长与未来复习日历。
class ReviewPlanScreen extends StatefulWidget {
  const ReviewPlanScreen({super.key});

  @override
  State<ReviewPlanScreen> createState() => _ReviewPlanScreenState();
}

class _ReviewPlanScreenState extends State<ReviewPlanScreen> {
  /// null 表示全部分类。
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final categoryId = _categoryId;
    final plan = progress.reviewPlanFor(
      content.allLessons,
      budgetMinutes: settings.reviewSessionMinutes,
      categoryId: categoryId,
    );
    final upcoming = progress.upcomingReviewCandidates(
      content.allLessons,
      days: 7,
      categoryId: categoryId,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reviewPlanTitle'))),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              children: [
                // 分类筛选
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(context.tr('reviewCategoryAll')),
                          selected: categoryId == null,
                          onSelected: (_) => setState(() => _categoryId = null),
                        ),
                      ),
                      for (final category in content.categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              category.title.of(context.strings.localeCode),
                            ),
                            selected: categoryId == category.id,
                            onSelected: (_) =>
                                setState(() => _categoryId = category.id),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // 今日计划摘要 + 场次时长
                IndexCard(
                  accent: theme.colorScheme.primary,
                  semanticLabel: context.trArgs('reviewPlanSummary', {
                    'count': plan.count,
                    'minutes': plan.totalMinutes,
                  }),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: AppRadii.control,
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.trArgs('reviewPlanSummary', {
                                'count': plan.count,
                                'minutes': plan.totalMinutes,
                              }),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.trArgs('reviewSessionHint', {
                                'n': settings.reviewSessionMinutes,
                              }),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (plan.deferredCount > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  IndexCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.trArgs('reviewPlanDeferred', {
                              'n': plan.deferredCount,
                            }),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // 复习安排：暂停 / 恢复、允许复习的星期、最近场次总结
                _ReviewControlsCard(progress: progress),
                // 错题专项队列：把错题本里的题目集中重练
                if (progress.totalWrongQuestions > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  IndexCard(
                    accent: theme.colorScheme.error,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExamScreen(
                          wrongOnly: true,
                          practiceMode: true,
                        ),
                      ),
                    ),
                    semanticLabel: context.trArgs('reviewWrongQueueSummary', {
                      'n': progress.totalWrongQuestions,
                    }),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: AppRadii.control,
                          ),
                          child: Icon(
                            Icons.rule_folder_outlined,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('reviewWrongQueue'),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.trArgs('reviewWrongQueueSummary', {
                                  'n': progress.totalWrongQuestions,
                                }),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.play_circle_outline,
                          color: theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (plan.isEmpty)
                  IndexCard(
                    child: Row(
                      children: [
                        const Icon(Icons.task_alt, color: AppPalette.success),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            categoryId == null
                                ? context.tr('reviewPlanEmpty')
                                : context.tr('reviewCategoryEmpty'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final item in plan.items) ...[
                    _ReviewPlanTile(
                      item: item,
                      onTap: () => _openQuiz(context, item.lesson),
                      onSnooze: (days) => _snooze(context, item.lesson, days),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                // 未来 7 天：可以提前复习
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.tr('reviewUpcoming'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final candidate in upcoming)
                    _UpcomingTile(
                      candidate: candidate,
                      onTap: () => _openQuiz(context, candidate.lesson),
                    ),
                ],
              ],
            ),
    );
  }

  void _openQuiz(BuildContext context, Lesson lesson) {
    if (lesson.totalQuestionCount == 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(lesson: lesson, isReview: true),
      ),
    );
  }

  /// 稍后复习：把某门课的到期时间推后，适合今天确实没有时间的情况。
  Future<void> _snooze(BuildContext context, Lesson lesson, int days) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.trArgs('reviewSnoozed', {'n': days});
    await context.read<ProgressProvider>().snoozeReview(lesson.id, days);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReviewPlanTile extends StatelessWidget {
  const _ReviewPlanTile({
    required this.item,
    required this.onTap,
    required this.onSnooze,
  });

  final ReviewPlanItem item;
  final VoidCallback onTap;

  /// 稍后复习：传入推迟的天数。
  final ValueChanged<int> onSnooze;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = item.lesson;
    final content = context.read<ContentProvider>();
    final category = content.categoryById(lesson.categoryId);
    final dueLabel = item.overdueDays == 0
        ? context.tr('reviewPlanToday')
        : context.trArgs('reviewPlanOverdue', {'n': item.overdueDays});

    return IndexCard(
      onTap: onTap,
      semanticLabel:
          '${lesson.title.of(context.strings.localeCode)}, '
          '$dueLabel, ${context.trArgs('reviewPlanEstimate', {'n': item.minutes})}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadii.control,
            ),
            child: Text(
              '${item.overdueDays}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: item.overdueDays == 0
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title.of(context.strings.localeCode),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${category?.title.of(context.strings.localeCode) ?? ''} · '
                  '${context.difficultyLabel(lesson.difficulty)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Chip(
                      label: Text(dueLabel),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(
                        context.trArgs('reviewPlanEstimate', {
                          'n': item.minutes,
                        }),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          PopupMenuButton<int>(
            tooltip: context.tr('reviewSnooze'),
            onSelected: onSnooze,
            itemBuilder: (menuContext) => [
              for (final days in const [1, 3, 7])
                PopupMenuItem<int>(
                  value: days,
                  child: Text(
                    '${menuContext.tr('reviewSnooze')} · '
                    '${menuContext.trArgs('reviewInDays', {'n': days})}',
                  ),
                ),
            ],
            icon: const Icon(Icons.more_vert, size: 20),
          ),
          Icon(Icons.play_circle_outline, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

/// 未来到期的复习内容：可以主动提前复习。
class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.candidate, required this.onTap});

  final ReviewCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = candidate.lesson;
    final due = candidate.dueAt!;
    final content = context.read<ContentProvider>();
    final category = content.categoryById(lesson.categoryId);
    final now = context.read<ProgressProvider>().now;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IndexCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title.of(context.strings.localeCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category?.title.of(context.strings.localeCode) ?? ''} · '
                    '${_dueLabel(context, due, now)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onTap,
              child: Text(context.tr('reviewAheadOfSchedule')),
            ),
          ],
        ),
      ),
    );
  }
}

String _dueLabel(BuildContext context, DateTime due, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(due.year, due.month, due.day);
  final diff = day.difference(today).inDays;
  if (diff <= 0) return context.tr('reviewPlanToday');
  if (diff == 1) return context.tr('reviewTomorrow');
  return context.trArgs('reviewInDays', {'n': diff});
}

/// 复习安排控制卡：暂停 / 恢复、允许复习的星期与最近场次总结。
class _ReviewControlsCard extends StatelessWidget {
  const _ReviewControlsCard({required this.progress});

  final ProgressProvider progress;

  /// 1 = 周一 … 7 = 周日，与 DateTime.weekday 一致。
  static const List<int> _weekdays = <int>[1, 2, 3, 4, 5, 6, 7];

  String _weekdayLabel(BuildContext context, int weekday) => switch (weekday) {
    1 => context.tr('weekdayMon'),
    2 => context.tr('weekdayTue'),
    3 => context.tr('weekdayWed'),
    4 => context.tr('weekdayThu'),
    5 => context.tr('weekdayFri'),
    6 => context.tr('weekdaySat'),
    _ => context.tr('weekdaySun'),
  };

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _togglePause(BuildContext context) async {
    if (progress.reviewsPaused) {
      await progress.resumeReviews();
      return;
    }
    final now = progress.now;
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
      helpText: context.tr('reviewPausePick'),
    );
    if (picked == null) return;
    await progress.pauseReviewsUntil(picked);
  }

  Future<void> _toggleWeekday(BuildContext context, int weekday) async {
    final next = <int>{...progress.reviewWeekdays};
    if (!next.remove(weekday)) {
      next.add(weekday);
    } else if (next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('reviewWeekdayRequired'))),
      );
      return;
    }
    await progress.setReviewWeekdays(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paused = progress.reviewsPaused;
    final until = progress.reviewPausedUntil;
    final history = progress.reviewHistory.take(3).toList(growable: false);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              paused ? Icons.play_circle_outline : Icons.pause_circle_outline,
              color: paused ? AppPalette.success : theme.colorScheme.primary,
            ),
            title: Text(
              paused ? context.tr('reviewResume') : context.tr('reviewPause'),
            ),
            subtitle: Text(
              paused && until != null
                  ? context.trArgs('reviewPausedUntil', {
                      'date': _formatDate(until),
                    })
                  : context.tr('reviewControls'),
            ),
            trailing: paused
                ? Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(context.tr('reviewPausedBadge')),
                  )
                : null,
            onTap: () => _togglePause(context),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('reviewWeekdays'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr('reviewWeekdaysHint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final weekday in _weekdays)
                      FilterChip(
                        label: Text(_weekdayLabel(context, weekday)),
                        selected: progress.reviewWeekdays.contains(weekday),
                        onSelected: (_) => _toggleWeekday(context, weekday),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              context.tr('reviewSessionSummary'),
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Text(
                context.tr('reviewSessionEmpty'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final entry in history)
              ListTile(
                dense: true,
                leading: const Icon(Icons.history_toggle_off, size: 18),
                title: Text(
                  context.trArgs('reviewSessionLine', {
                    'lessons': entry['lessonCount'] ?? 0,
                    'correct': entry['correct'] ?? 0,
                    'total': entry['total'] ?? 0,
                    'minutes': entry['minutes'] ?? 0,
                  }),
                  style: theme.textTheme.bodySmall,
                ),
                subtitle: Text(
                  _formatDate(
                    DateTime.tryParse(entry['at']?.toString() ?? '') ??
                        progress.now,
                  ),
                  style: theme.textTheme.labelSmall,
                ),
              ),
        ],
      ),
    );
  }
}
