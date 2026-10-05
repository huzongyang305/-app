import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/content_provider.dart';
import '../services/practice_question_factory.dart';
import '../services/progress_provider.dart';
import '../services/review_planner.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/index_card.dart';
import 'quiz_screen.dart';

/// 今日复习计划：按逾期程度和预计用时排序，并限制在每日时间预算内。
class ReviewPlanScreen extends StatelessWidget {
  const ReviewPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final plan = progress.reviewPlanFor(content.allLessons);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reviewPlanTitle'))),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : plan.isEmpty
          ? EmptyState(
              icon: Icons.task_alt,
              message: context.tr('reviewPlanEmpty'),
              action: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('reviewPlanEmptyHint')),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              children: [
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
                              context.tr('todayReviewHint'),
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
                const SizedBox(height: AppSpacing.lg),
                for (final item in plan.items) ...[
                  _ReviewPlanTile(
                    item: item,
                    onTap: () => _openQuiz(context, item),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }

  void _openQuiz(BuildContext context, ReviewPlanItem item) {
    if (item.lesson.totalQuestionCount == 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QuizScreen(lesson: item.lesson)),
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
