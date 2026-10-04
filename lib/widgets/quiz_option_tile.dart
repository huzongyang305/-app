import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// 测验选项：做成「可勾选的行」。
///
/// 左侧 3px 状态条表示选中/正确/错误，行与行之间只用一条细线分隔，
/// 不再使用圆角胶囊或描边卡片。
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

    var stripe = Colors.transparent;
    var background = Colors.transparent;
    IconData? trailingIcon;
    Color? trailingColor;

    if (answered) {
      if (correct) {
        stripe = AppPalette.success;
        background = AppPalette.success.withValues(alpha: 0.07);
        trailingIcon = Icons.check;
        trailingColor = AppPalette.success;
      } else if (selected) {
        stripe = AppPalette.danger;
        background = AppPalette.danger.withValues(alpha: 0.07);
        trailingIcon = Icons.close;
        trailingColor = AppPalette.danger;
      }
    } else if (selected) {
      stripe = theme.colorScheme.primary;
      background = theme.colorScheme.primary.withValues(alpha: 0.06);
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: background,
            border: Border(
              left: BorderSide(color: stripe, width: 3),
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: InkWell(
            onTap: answered ? null : () => onTap(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 8, 13),
              child: Row(
                children: [
                  if (multiSelect)
                    Icon(
                      selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    )
                  else
                    SizedBox(
                      width: 22,
                      child: Text(
                        letter,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected || correct
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 14.5,
                        height: 1.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, color: trailingColor, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
