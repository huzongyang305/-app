import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import 'index_card.dart';

/// 签到卡：连续学习天数 + 最近 7 天状态 + 主色操作按钮。
class CheckInCard extends StatelessWidget {
  const CheckInCard({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final days = progress.recentStudyDays(7);
    final now = progress.now;
    final primary = theme.colorScheme.primary;

    return IndexCard(
      accent: progress.signedToday ? primary : null,
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
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.trArgs('checkInStreak', {'n': progress.streakDays}),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: progress.signedToday
                    ? null
                    : () => progress.checkInToday(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: Text(
                  progress.signedToday
                      ? context.tr('checkInDone')
                      : context.tr('checkInAction'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _DayCell(
                    date: now.subtract(Duration(days: days.length - 1 - i)),
                    done: days[i],
                    isToday: i == days.length - 1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.done,
    required this.isToday,
  });

  final DateTime date;
  final bool done;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.curve,
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            color: done ? primary : theme.colorScheme.surfaceContainerHighest,
            border: isToday && !done
                ? Border.all(color: primary, width: 1.4)
                : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '${date.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          isToday ? context.tr('homeToday') : '${date.month}/${date.day}',
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.5),
        ),
      ],
    );
  }
}
