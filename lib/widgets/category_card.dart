import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson_category.dart';
import '../theme/app_theme.dart';
import 'icon_mapper.dart';
import 'index_card.dart';

/// 分类卡片：统一主色、圆角图标容器与细进度条。
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.learnedCount,
    required this.onTap,
  });

  final LessonCategory category;
  final int learnedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = category.lessons.length;
    final ratio = total == 0 ? 0.0 : learnedCount / total;
    final title = category.title.of(context.strings.localeCode);
    final primary = theme.colorScheme.primary;

    return Semantics(
      button: true,
      label: '$title, $learnedCount/$total ${context.tr('lessons')}',
      child: IndexCard(
        accent: learnedCount > 0 ? primary : null,
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: AppRadii.control,
                  ),
                  child: Icon(
                    iconFromName(category.iconName),
                    color: primary,
                    size: 20,
                  ),
                ),
                const Spacer(),
                MonoLabel(
                  '${(ratio * 100).round()}%',
                  color: primary,
                  size: 13,
                  weight: FontWeight.w700,
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$learnedCount/$total ${context.tr('lessons')}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: context.trArgs('progressSemantic', {
                'value': '${(ratio * 100).round()}%',
              }),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
