import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/quiz_result.dart';
import '../theme/app_theme.dart';
import 'index_card.dart';

/// 知识点卡片：紧凑标题、低饱和元数据与单一主色状态提示。
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.isLearned,
    required this.isFavorite,
    required this.onTap,
    this.quizResult,
    this.onFavoriteTap,
    this.courseIndex,
    this.flat = false,
    this.accentColor,
  });

  final Lesson lesson;
  final bool isLearned;
  final bool isFavorite;
  final QuizResult? quizResult;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final int? courseIndex;
  final bool flat;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = context.strings.localeCode;
    final accent = accentColor ?? theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: lesson.title.of(localeCode),
      child: IndexCard(
        accent: isLearned ? accent : null,
        shadow: !flat,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (courseIndex != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: AppRadii.chip,
                          ),
                          child: Text(
                            courseIndex!.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontFamily: AppTheme.sansFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (isLearned) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          lesson.title.of(localeCode),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.summary.of(localeCode),
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MetaChip(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: context.difficultyLabel(lesson.difficulty),
                      ),
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: '${lesson.minutes} ${context.tr('minutes')}',
                      ),
                      _MetaChip(
                        icon: Icons.quiz_outlined,
                        label:
                            '${lesson.quiz.length} ${context.tr('questions')}',
                      ),
                      if (quizResult != null)
                        _MetaChip(
                          icon: Icons.emoji_events_outlined,
                          label: '${quizResult!.correct}/${quizResult!.total}',
                          highlight: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onFavoriteTap != null)
              IconButton(
                tooltip: context.tr('favorites'),
                visualDensity: VisualDensity.compact,
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 21,
                  color: isFavorite
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              const SizedBox(width: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppRadii.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
