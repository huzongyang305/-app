import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/progress_provider.dart';
import '../l10n/l10n_extension.dart';
import 'index_card.dart';

/// 签到卡：连续学习天数 + 最近 7 天方格 + 签到按钮。
class CheckInCard extends StatelessWidget {
  const CheckInCard({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final days = progress.recentStudyDays(7);
    final now = DateTime.now();

    return IndexCard(
      accent: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 19,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.trArgs('checkInStreak', {'n': progress.streakDays}),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: progress.signedToday
                    ? null
                    : () => progress.checkInToday(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
          const SizedBox(height: 14),
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
    final activeColor = theme.colorScheme.primary;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: done
                ? activeColor
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: done
                  ? activeColor
                  : isToday
                  ? activeColor
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: done
              ? const Icon(Icons.check, size: 15, color: Colors.white)
              : Text(
                  '${date.day}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isToday
                        ? activeColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          isToday ? context.tr('homeToday') : '${date.month}/${date.day}',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
