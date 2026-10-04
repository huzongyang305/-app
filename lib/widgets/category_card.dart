import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson_category.dart';
import 'icon_mapper.dart';

/// 首页分类卡片：图标、名称、知识点数量与分类进度。
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
    final color = Color(0xFF000000 | category.colorValue);
    final total = category.lessons.length;
    final ratio = total == 0 ? 0.0 : learnedCount / total;

    final title = category.title.of(context.strings.localeCode);
    return Semantics(
      button: true,
      label: '$title, $learnedCount/$total ${context.tr('lessons')}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconFromName(category.iconName),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category.title.of(context.strings.localeCode),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$learnedCount/$total ${context.tr('lessons')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: context.trArgs('progressSemantic', {
                    'value': '${(ratio * 100).round()}%',
                  }),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
