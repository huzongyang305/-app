import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/quiz_result.dart';

/// 知识点卡片：标题、简介、时长、学习状态与测验成绩。
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
  });

  final Lesson lesson;
  final bool isLearned;
  final bool isFavorite;
  final QuizResult? quizResult;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  /// 课程内的序号（第 N 课），为空表示不展示。
  final int? courseIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = context.strings.localeCode;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLearned) ...[
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            courseIndex == null
                                ? lesson.title.of(localeCode)
                                : context.trArgs('lessonIndex', {
                                    'n': courseIndex,
                                    'title': lesson.title.of(localeCode),
                                  }),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.summary.of(localeCode),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          icon: Icons.signal_cellular_alt,
                          label: context.difficultyLabel(lesson.difficulty),
                        ),
                        _MetaChip(
                          icon: Icons.schedule,
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
                            label:
                                '${quizResult!.correct}/${quizResult!.total}',
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
                  onPressed: onFavoriteTap,
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite
                        ? const Color(0xFFF59E0B)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
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
