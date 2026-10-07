import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

/// 学习热力图：按周排列的日历格子，颜色越深表示当天学习时间越长。
class StudyHeatmap extends StatelessWidget {
  const StudyHeatmap({
    super.key,
    required this.endDate,
    required this.valueForDay,
    this.weeks = 12,
  });

  /// 热力图最后一天（通常是今天）。
  final DateTime endDate;

  /// 返回某一天的学习分钟数。
  final int Function(DateTime day) valueForDay;

  /// 展示最近多少周。
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime(endDate.year, endDate.month, endDate.day);
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final firstWeekStart = currentWeekStart.subtract(
      Duration(days: (weeks - 1) * 7),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 周一到周日的简写，只标三个位置，避免拥挤。
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: Column(
                children: [
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      height: 14,
                      child: Text(
                        switch (i) {
                          0 => '一',
                          2 => '三',
                          4 => '五',
                          _ => '',
                        },
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var week = 0; week < weeks; week++)
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Column(
                          children: [
                            for (var day = 0; day < 7; day++)
                              _HeatCell(
                                date: firstWeekStart.add(
                                  Duration(days: week * 7 + day),
                                ),
                                minutes: valueForDay(
                                  firstWeekStart.add(
                                    Duration(days: week * 7 + day),
                                  ),
                                ),
                                isFuture: firstWeekStart
                                    .add(Duration(days: week * 7 + day))
                                    .isAfter(today),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              context.tr('analyticsHeatmapLess'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            for (final level in const [0, 1, 2, 3, 4])
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: _colorFor(context, level),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            const SizedBox(width: 3),
            Text(
              context.tr('analyticsHeatmapMore'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.date,
    required this.minutes,
    required this.isFuture,
  });

  final DateTime date;
  final int minutes;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = context.trArgs('analyticsHeatmapTooltip', {
      'date': '${date.month}/${date.day}',
      'n': minutes,
    });
    if (isFuture) {
      return const SizedBox(width: 13, height: 13);
    }
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: _colorFor(context, _level(minutes)),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

int _level(int minutes) {
  if (minutes <= 0) return 0;
  if (minutes < 10) return 1;
  if (minutes < 25) return 2;
  if (minutes < 50) return 3;
  return 4;
}

Color _colorFor(BuildContext context, int level) {
  final scheme = Theme.of(context).colorScheme;
  return switch (level) {
    1 => scheme.primary.withValues(alpha: 0.25),
    2 => scheme.primary.withValues(alpha: 0.45),
    3 => scheme.primary.withValues(alpha: 0.7),
    4 => scheme.primary,
    _ => scheme.surfaceContainerHighest,
  };
}
