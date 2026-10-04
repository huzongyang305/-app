import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../theme/app_theme.dart';

/// 测验题型提示与代码片段。
///
/// 题型用等宽标签标注，代码片段使用与教程一致的左侧蓝竖条。
class QuizMetaPanel extends StatelessWidget {
  const QuizMetaPanel({super.key, required this.question});

  final QuizQuestion question;

  String _typeLabel(BuildContext context) {
    return switch (question.type) {
      'code' => context.tr('quizTypeCode'),
      'debug' => context.tr('quizTypeDebug'),
      'order' => context.tr('quizTypeOrder'),
      'fill' => context.tr('quizTypeFill'),
      'multi' => context.tr('quizTypeMulti'),
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _typeLabel(context);
    final code = question.code?.trim();
    if (label.isEmpty && (code == null || code.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 3),
                top: BorderSide(color: theme.colorScheme.outlineVariant),
                right: BorderSide(color: theme.colorScheme.outlineVariant),
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        if (code != null && code.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 3),
                top: BorderSide(color: theme.colorScheme.outlineVariant),
                right: BorderSide(color: theme.colorScheme.outlineVariant),
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: SelectableText(
                code,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontFamily: AppTheme.monoFamily,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
