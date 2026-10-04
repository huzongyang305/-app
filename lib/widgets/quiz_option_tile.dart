import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

/// 测验选项：支持单选、多选与作答后的对错配色。
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.index,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
    this.multiSelect = false,
  });

  final String label;
  final int index;
  final bool selected;
  final bool correct;
  final bool answered;
  final ValueChanged<int> onTap;

  /// 多选模式使用复选框外观，并允许连续点选。
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var borderColor = theme.colorScheme.outlineVariant;
    var backgroundColor = theme.colorScheme.surface;
    IconData? trailingIcon;
    Color? trailingColor;

    if (answered) {
      if (correct) {
        borderColor = const Color(0xFF16A34A);
        backgroundColor = const Color(0xFF16A34A).withValues(alpha: 0.10);
        trailingIcon = Icons.check_circle;
        trailingColor = const Color(0xFF16A34A);
      } else if (selected) {
        borderColor = theme.colorScheme.error;
        backgroundColor = theme.colorScheme.errorContainer.withValues(
          alpha: 0.5,
        );
        trailingIcon = Icons.cancel;
        trailingColor = theme.colorScheme.error;
      }
    } else if (selected) {
      borderColor = theme.colorScheme.primary;
      backgroundColor = theme.colorScheme.primaryContainer.withValues(
        alpha: 0.32,
      );
    }

    final letter = String.fromCharCode(65 + index);
    return Semantics(
      button: true,
      enabled: !answered,
      selected: selected,
      label: context.trArgs('quizOptionSemantic', {
        'letter': letter,
        'text': label,
      }),
      hint: answered
          ? (correct
                ? context.tr('quizOptionCorrect')
                : context.tr('quizOptionWrong'))
          : null,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: answered ? null : () => onTap(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected && !multiSelect
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(multiSelect ? 4 : 6),
                    ),
                    child: multiSelect
                        ? Icon(
                            selected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 22,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          )
                        : Text(
                            letter,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodyMedium),
                  ),
                  if (trailingIcon != null)
                    Icon(trailingIcon, color: trailingColor, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
