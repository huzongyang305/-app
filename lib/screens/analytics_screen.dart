import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/learning_analytics.dart';
import '../services/progress_provider.dart';
import '../widgets/activity_chart.dart';
import '../widgets/empty_state.dart';
import 'lesson_screen.dart';

/// 学习分析：把本地学习记录整理成周期报告、分类掌握度和薄弱点。
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodDays = 7;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final snapshot = LearningAnalytics.build(
      categories: content.categories,
      progress: progress,
      periodDays: _periodDays,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('learningAnalytics'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _OverviewCard(snapshot: snapshot),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.trArgs('analyticsRecentActivity', {
                      'period': snapshot.periodDays,
                    }),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 7, label: Text('7')),
                        ButtonSegment(value: 14, label: Text('14')),
                        ButtonSegment(value: 30, label: Text('30')),
                      ],
                      selected: {_periodDays},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          setState(() => _periodDays = value.first),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ActivityChart(values: snapshot.activity, height: 76),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _InlineMetric(
                        label: context.tr('analyticsActivityTotal'),
                        value: '${snapshot.activityTotal}',
                      ),
                      _InlineMetric(
                        label: context.tr('analyticsActiveDays'),
                        value: '${snapshot.activeDays}',
                      ),
                      _InlineMetric(
                        label: context.tr('analyticsTrend'),
                        value: _trendLabel(context, snapshot.activityTrend),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.tr('analyticsStudyTime'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ActivityChart(
                    values: snapshot.studyMinutesPerDay,
                    height: 60,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _InlineMetric(
                        label: context.tr('analyticsStudyTotal'),
                        value: context.trArgs('analyticsMinutes', {
                          'n': snapshot.studyMinutes,
                        }),
                      ),
                      _InlineMetric(
                        label: context.tr('analyticsStudyPerDay'),
                        value: context.trArgs('analyticsMinutes', {
                          'n': snapshot.averageStudyMinutesPerDay,
                        }),
                      ),
                      _InlineMetric(
                        label: context.tr('analyticsActiveDays'),
                        value:
                            '${snapshot.studyMinutesPerDay.where((m) => m > 0).length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: context.tr('analyticsCategoryMastery'),
            subtitle: context.tr('analyticsCategoryMasteryHint'),
          ),
          Card(
            child: Column(
              children: [
                for (final mastery in snapshot.categoryMastery)
                  _MasteryTile(mastery: mastery),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: context.tr('analyticsWeakPoints'),
            subtitle: context.tr('analyticsWeakPointsHint'),
          ),
          if (snapshot.weakLessons.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: EmptyState(
                  icon: Icons.task_alt,
                  message: context.tr('analyticsNoWeakPoints'),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final weak in snapshot.weakLessons)
                    ListTile(
                      leading: Icon(
                        Icons.priority_high,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        weak.lesson.title.of(context.strings.localeCode),
                      ),
                      subtitle: Text(
                        '${context.tr('analyticsAccuracy')}: '
                        '${(weak.accuracy * 100).round()}% · '
                        '${context.trArgs('analyticsWrongTimes', {'n': weak.wrongCount})}',
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => _openLesson(weak.lesson),
                    ),
                ],
              ),
            ),
          if (snapshot.recommendedLesson != null) ...[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                leading: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                title: Text(
                  context.tr('analyticsRecommendation'),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  snapshot.recommendedLesson!.title.of(
                    context.strings.localeCode,
                  ),
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                onTap: () => _openLesson(snapshot.recommendedLesson!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openLesson(Lesson lesson) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
    );
  }

  String _trendLabel(BuildContext context, int trend) {
    if (trend > 0) {
      return context.trArgs('analyticsTrendUp', {'n': trend});
    }
    if (trend < 0) {
      return context.trArgs('analyticsTrendDown', {'n': trend.abs()});
    }
    return context.tr('analyticsTrendFlat');
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.snapshot});

  final LearningAnalytics snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('analyticsOverview'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 18,
              runSpacing: 14,
              children: [
                _Metric(
                  value: '${snapshot.streakDays}',
                  label: context.tr('analyticsStreak'),
                  icon: Icons.local_fire_department_outlined,
                  color: theme.colorScheme.primary,
                ),
                _Metric(
                  value: '${snapshot.totalLearned}/${snapshot.totalLessons}',
                  label: context.tr('learnedLessons'),
                  icon: Icons.menu_book_outlined,
                  color: theme.colorScheme.primary,
                ),
                _Metric(
                  value: '${(snapshot.averageAccuracy * 100).round()}%',
                  label: context.tr('quizAverage'),
                  icon: Icons.fact_check_outlined,
                  color: theme.colorScheme.primary,
                ),
                _Metric(
                  value: '${snapshot.estimatedMinutes}',
                  label: context.tr('analyticsEstimatedMinutes'),
                  icon: Icons.schedule_outlined,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: snapshot.progressRatio,
                minHeight: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 132,
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryTile extends StatelessWidget {
  const _MasteryTile({required this.mastery});

  final CategoryMastery mastery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = mastery.quizzedLessons == 0
        ? '--'
        : '${(mastery.averageAccuracy * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mastery.category.title.of(context.strings.localeCode),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(mastery.masteryScore * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: mastery.isWeak
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: mastery.masteryScore.clamp(0, 1),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${context.tr('learnedLessons')} '
            '${mastery.learnedLessons}/${mastery.totalLessons} · '
            '${context.tr('quizAverage')} $accuracy · '
            '${mastery.estimatedMinutes} ${context.tr('minutes')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
