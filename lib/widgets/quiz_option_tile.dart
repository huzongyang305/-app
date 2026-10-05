import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// 测验选项：圆角卡片、低饱和底色与克制的状态色反馈。
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
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    var borderColor = scheme.outlineVariant;
    var background = scheme.surfaceContainerLow;
    var markerColor = scheme.onSurfaceVariant;
    var markerFill = scheme.surfaceContainerHighest;
    IconData? trailingIcon;
    Color? trailingColor;

    if (answered) {
      if (correct) {
        borderColor = AppPalette.success.withValues(alpha: 0.45);
        background = AppPalette.success.withValues(alpha: 0.07);
        markerColor = Colors.white;
        markerFill = AppPalette.success;
        trailingIcon = Icons.check_rounded;
        trailingColor = AppPalette.success;
      } else if (selected) {
        borderColor = AppPalette.danger.withValues(alpha: 0.45);
        background = AppPalette.danger.withValues(alpha: 0.06);
        markerColor = Colors.white;
        markerFill = AppPalette.danger;
        trailingIcon = Icons.close_rounded;
        trailingColor = AppPalette.danger;
      }
    } else if (selected) {
      borderColor = scheme.primary;
      background = scheme.primary.withValues(alpha: 0.06);
      markerColor = Colors.white;
      markerFill = scheme.primary;
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
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.control,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: answered ? null : () => onTap(index),
              borderRadius: AppRadii.control,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.normal,
                      curve: AppMotion.curve,
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: multiSelect && !selected
                            ? Colors.transparent
                            : markerFill,
                        borderRadius: BorderRadius.circular(AppRadii.xs + 1),
                        border: multiSelect && !selected
                            ? Border.all(color: scheme.outlineVariant)
                            : null,
                      ),
                      child: multiSelect
                          ? Icon(
                              selected
                                  ? Icons.check_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: selected
                                  ? markerColor
                                  : scheme.onSurfaceVariant,
                            )
                          : Text(
                              letter,
                              style: TextStyle(
                                fontFamily: AppTheme.sansFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: markerColor,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14.5,
                          height: 1.5,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    // 除颜色外再用文字标注对错，方便色觉障碍用户分辨。
                    if (answered && (correct || selected)) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _StatusBadge(
                        label: correct
                            ? context.tr('quizBadgeCorrect')
                            : context.tr('quizBadgeYourPick'),
                        color: correct ? AppPalette.success : AppPalette.danger,
                      ),
                    ],
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(trailingIcon, color: trailingColor, size: 21),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 答题状态文字徽标：形状与文字双重编码，不只依赖红绿颜色。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.sansFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
