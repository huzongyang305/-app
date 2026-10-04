import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';

/// 测验题型提示与代码片段：代码输出、排错、排序、填空共用单选交互。
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (code != null && code.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                code,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontFamily: 'monospace',
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
