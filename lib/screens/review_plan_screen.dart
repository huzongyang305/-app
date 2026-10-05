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
                          onSelected: (_) =>
                              setState(() => _categoryId = null),
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
      MaterialPageRoute<void>(builder: (_) => QuizScreen(lesson: lesson)),
    );
  }
}

class _ReviewPlanTile extends StatelessWidget {
  const _ReviewPlanTile({required this.item, required this.onTap});

  final ReviewPlanItem item;
  final VoidCallback onTap;

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
