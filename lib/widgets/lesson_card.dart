import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/quiz_result.dart';
import '../theme/app_theme.dart';
import 'index_card.dart';

/// 知识点索引条目：序号、标题、简介与等宽元数据。
///
/// 条目之间靠细线分隔，不再使用独立阴影卡片。
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

  /// 课程内的序号（第 N 课），为空表示不展示。
  final int? courseIndex;

  /// 平铺模式：去掉描边与卡片底色，用于分类页的连续课程列表。
  final bool flat;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = context.strings.localeCode;
    final accent =
        accentColor ??
        (isLearned
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant);

    final meta = <String>[
      context.difficultyLabel(lesson.difficulty),
      '${lesson.minutes} ${context.tr('minutes')}',
      '${lesson.quiz.length} ${context.tr('questions')}',
      if (quizResult != null) '${quizResult!.correct}/${quizResult!.total}',
    ];

    return Semantics(
      button: true,
      label: lesson.title.of(localeCode),
      child: IndexCard(
        accent: accent,
        bordered: !flat,
        background: flat ? theme.colorScheme.surface : null,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (courseIndex != null) ...[
                        MonoLabel(
                          courseIndex!.toString().padLeft(2, '0'),
                          color: theme.colorScheme.primary,
                          size: 12,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (isLearned) ...[
                        Icon(
                          Icons.check,
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          lesson.title.of(localeCode),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.summary.of(localeCode),
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: MonoLabel(
                          meta.join('   /   '),
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                  isFavorite ? Icons.star : Icons.star_border,
                  size: 20,
                  color: isFavorite
                      ? AppPalette.warning
                      : theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
