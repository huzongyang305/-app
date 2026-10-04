import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson_category.dart';
import 'icon_mapper.dart';
import 'index_card.dart';

/// 首页分类索引卡：左侧分类竖标 + 等宽进度数据 + 细线进度尺。
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
      child: IndexCard(
        accent: color,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconFromName(category.iconName), color: color, size: 20),
                const Spacer(),
                MonoLabel(
                  '${(ratio * 100).round()}%',
                  color: color,
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            MonoLabel(
              '$learnedCount/$total ${context.tr('lessons')}',
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Semantics(
              label: context.trArgs('progressSemantic', {
                'value': '${(ratio * 100).round()}%',
              }),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio.clamp(0.0, 1.0),
                      child: ColoredBox(color: color),
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
