import 'package:flutter/material.dart';

/// 知识点分组标题（例如「Python」「C++」），用于分类内的二级分组。
class LessonGroupHeader extends StatelessWidget {
  const LessonGroupHeader({super.key, required this.title, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Row(
        children: [
          Container(width: 2, height: 18, color: accent),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }
}
