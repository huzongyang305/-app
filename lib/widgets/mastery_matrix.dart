import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/progress_provider.dart';

/// 知识点掌握度矩阵：以网格形式展示各知识点的掌握情况
class MasteryMatrix extends StatelessWidget {
  const MasteryMatrix({
    super.key,
    required this.lessons,
    required this.progress,
    this.columns = 5,
  });

  final List<Lesson> lessons;
  final ProgressProvider progress;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    // 行高按字号推算：2 行标题 + 百分比 + 错题角标 + 内边距，
    // 避免固定宽高比在窄屏或大字号下把单元格内容挤爆。
    final scaler = MediaQuery.textScalerOf(context);
    final cellHeight =
        16 + scaler.scale(18) * 2 + 4 + scaler.scale(14) + 2 + 12 + 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: cellHeight,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final result = progress.resultOf(lesson.id);
        final isLearned = progress.isLearned(lesson.id);
        final wrongCount = progress.wrongCountFor(lesson.id);

        double mastery = 0;
        if (result != null) {
          mastery = result.accuracy;
        } else if (isLearned) {
          mastery = 0.5; // 已学但未测验
        }

        return _MasteryCell(
          title: lesson.title.zh,
          mastery: mastery,
          isLearned: isLearned,
          wrongCount: wrongCount,
          onTap: () {},
        );
      },
    );
  }
}

class _MasteryCell extends StatelessWidget {
  const _MasteryCell({
    required this.title,
    required this.mastery,
    required this.isLearned,
    required this.wrongCount,
    required this.onTap,
  });

  final String title;
  final double mastery;
  final bool isLearned;
  final int wrongCount;
  final VoidCallback onTap;

  Color _getColor(BuildContext context) {
    if (!isLearned) return Colors.grey.shade300;
    if (mastery >= 0.9) return Colors.green.shade400;
    if (mastery >= 0.7) return Colors.lightGreen.shade400;
    if (mastery >= 0.5) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: _getColor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: wrongCount > 0 ? Colors.red.shade700 : Colors.transparent,
            width: wrongCount > 0 ? 2 : 0,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title.length > 8 ? '${title.substring(0, 8)}...' : title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${(mastery * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (wrongCount > 0) ...[
              const SizedBox(height: 2),
              Icon(
                Icons.error_outline,
                size: 12,
                color: Colors.yellow.shade700,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
