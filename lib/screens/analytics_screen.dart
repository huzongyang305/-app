import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/learning_analytics.dart';
import '../services/learning_insight_service.dart';
import '../models/study_center.dart';
import '../services/progress_provider.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/activity_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/study_heatmap.dart';
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
    final languageRows = _languageStats(content, progress);
    final concepts = LearningInsightService.buildConceptMastery(
      lessons: content.allLessons,
      progress: progress,
    );
    final causes = LearningInsightService.errorCauseStats(progress);
    final questions = LearningInsightService.buildQuestionStats(
      lessons: content.allLessons,
      progress: progress,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('learningAnalytics')),
        actions: [
          IconButton(
            tooltip: context.tr('analyticsExport'),
            icon: const Icon(Icons.ios_share),
            onPressed: _exportReport,
          ),
        ],
      ),
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
            title: context.tr('analyticsHeatmap'),
            subtitle: context.tr('analyticsHeatmapHint'),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: StudyHeatmap(
                endDate: progress.now,
                valueForDay: progress.studyMinutesOn,
              ),
            ),
          ),
          if (languageRows.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle(
              title: context.tr('analyticsByLanguage'),
              subtitle: context.tr('analyticsByLanguageHint'),
            ),
            Card(
              child: Column(
                children: [
                  for (final stat in languageRows) _LanguageTile(stat: stat),
                ],
              ),
            ),
          ],
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
          const SizedBox(height: 16),
          // 概念级掌握度：按课程关键词聚合测验与错题数据
          _SectionTitle(
            title: context.tr('insightConceptTitle'),
            subtitle: context.tr('insightConceptHint'),
          ),
          if (concepts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: EmptyState(
                  icon: Icons.insights_outlined,
                  message: context.tr('insightConceptEmpty'),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final concept in concepts.take(10))
                    _ConceptTile(concept: concept),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: context.tr('insightCauseTitle'),
            subtitle: context.tr('insightCauseHint'),
          ),
          if (causes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: EmptyState(
                  icon: Icons.rule_outlined,
                  message: context.tr('insightCauseEmpty'),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final cause in causes)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.label_outline, size: 18),
                      title: Text(cause.cause),
                      trailing: Text('${cause.count}'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: context.tr('insightQuestionTitle'),
            subtitle: context.tr('insightQuestionHint'),
          ),
          if (questions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: EmptyState(
                  icon: Icons.quiz_outlined,
                  message: context.tr('insightQuestionEmpty'),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final stat in questions.take(12))
                    _QuestionStatTile(
                      stat: stat,
                      lessonTitle: _lessonTitleOf(content, stat.lessonId),
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

  /// 把当前分析快照导出为文本报告；系统分享不可用时退回剪贴板。
  Future<void> _exportReport() async {
    final content = context.read<ContentProvider>();
    final progress = context.read<ProgressProvider>();
    final snapshot = LearningAnalytics.build(
      categories: content.categories,
      progress: progress,
      periodDays: _periodDays,
      now: progress.now,
    );
    final locale = context.strings.localeCode;
    final buffer = StringBuffer()
      ..writeln(context.trRead('analyticsReportTitle'))
      ..writeln(
        '${context.trRead('analyticsReportGenerated')}: '
        '${_dateText(progress.now)}',
      )
      ..writeln(
        '${context.trRead('analyticsReportOverall')}: '
        '${snapshot.totalLearned}/${snapshot.totalLessons} '
        '(${(snapshot.progressRatio * 100).round()}%)',
      )
      ..writeln('${context.trRead('analyticsStreak')}: ${snapshot.streakDays}')
      ..writeln(
        context.trReadArgs('analyticsReportPeriod', {'n': snapshot.periodDays}),
      )
      ..writeln(
        '${context.trRead('analyticsStudyTotal')}: '
        '${snapshot.studyMinutes} ${context.trRead('minutes')}',
      )
      ..writeln(
        '${context.trRead('analyticsActiveDays')}: ${snapshot.activeDays}',
      )
      ..writeln();
    buffer.writeln('${context.trRead('analyticsCategoryMastery')}:');
    for (final row in snapshot.categoryMastery) {
      buffer.writeln(
        '- ${row.category.title.of(locale)}: '
        '${(row.masteryScore * 100).round()}%',
      );
    }
    if (snapshot.weakLessons.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('${context.trRead('analyticsReportWeak')}:');
      for (final weak in snapshot.weakLessons.take(5)) {
        buffer.writeln(
          '- ${weak.lesson.title.of(locale)} '
          '(${(weak.accuracy * 100).round()}%)',
        );
      }
    }
    if (snapshot.recommendedLesson != null) {
      buffer
        ..writeln()
        ..writeln(
          '${context.trRead('analyticsReportNext')}: '
          '${snapshot.recommendedLesson!.title.of(locale)}',
        );
    }

    final text = buffer.toString();
    final shared = await const ShareService().shareText(
      text,
      subject: context.trRead('analyticsReportTitle'),
    );
    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trRead('analyticsExportCopied'))),
      );
    }
  }

  String _dateText(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  /// 按课程分组（group）聚合语言学习数据。
  List<_LanguageStat> _languageStats(
    ContentProvider content,
    ProgressProvider progress,
  ) {
    final rows = <String, _LanguageStat>{};
    for (final lesson in content.allLessons) {
      final group = lesson.group?.trim() ?? '';
      if (group.isEmpty) continue;
      final row = rows.putIfAbsent(group, () => _LanguageStat(group));
      row.total++;
      if (progress.isLearned(lesson.id)) row.learned++;
      final result = progress.resultOf(lesson.id);
      if (result != null) {
        row.quizzed++;
        row.accuracyTotal += result.accuracy;
      }
    }
    final list = rows.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return list.take(30).toList(growable: false);
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

/// 按课程分组（语言）聚合的学习统计行。
class _LanguageStat {
  _LanguageStat(this.group);

  final String group;
  int total = 0;
  int learned = 0;
  int quizzed = 0;
  double accuracyTotal = 0;

  double get accuracy => quizzed == 0 ? 0 : accuracyTotal / quizzed;
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

/// 单个语言（课程分组）的掌握度行：进度条 + 已学 / 正确率。
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.stat});

  final _LanguageStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = stat.total == 0 ? 0.0 : stat.learned / stat.total;
    final accuracy = stat.quizzed == 0 ? 0 : (stat.accuracy * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.group,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.trArgs('analyticsLanguageRow', {
              'learned': stat.learned,
              'total': stat.total,
              'accuracy': accuracy,
            }),
            maxLines: 1,
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

/// 概念掌握度：进度条 + 作答次数，低分概念自动排在前面。
class _ConceptTile extends StatelessWidget {
  const _ConceptTile({required this.concept});

  final ConceptMastery concept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = concept.score >= 0.8
        ? AppPalette.success
        : concept.score >= 0.5
        ? AppPalette.warning
        : AppPalette.danger;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  concept.concept,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${concept.percent}%',
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: concept.score.clamp(0.0, 1.0),
              minHeight: 6,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.trArgs('insightQuestionMeta', {
              'attempts': concept.attempts,
              'percent': (concept.accuracy * 100).round(),
            }),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单题统计：展示题目、作答次数、正确率与难度标签。
class _QuestionStatTile extends StatelessWidget {
  const _QuestionStatTile({required this.stat, required this.lessonTitle});

  final QuestionStat stat;
  final String lessonTitle;

  String _difficultyLabel(BuildContext context) =>
      switch (stat.difficultyLabel) {
        '偏简单' => context.tr('insightDifficultyEasy'),
        '偏难' => context.tr('insightDifficultyHard'),
        '有挑战' => context.tr('insightDifficultyChallenging'),
        '适中' => context.tr('insightDifficultyMedium'),
        _ => context.tr('insightDifficultyLow'),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = (stat.accuracy * 100).round();
    final color = accuracy >= 80
        ? AppPalette.success
        : accuracy >= 50
        ? AppPalette.warning
        : AppPalette.danger;
    return ListTile(
      leading: Icon(Icons.quiz_outlined, color: color),
      title: Text(stat.question, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            context.trArgs('insightQuestionLine', {
              'lesson': lessonTitle,
              'index': stat.questionIndex + 1,
            }),
            style: theme.textTheme.labelSmall,
          ),
          Text(
            context.trArgs('insightQuestionMeta', {
              'attempts': stat.attempts,
              'percent': accuracy,
            }),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Chip(
        visualDensity: VisualDensity.compact,
        label: Text(_difficultyLabel(context)),
      ),
    );
  }
}

/// 课程 ID 到标题的映射，用于单题统计里的课程名。
String _lessonTitleOf(ContentProvider content, String lessonId) {
  for (final lesson in content.allLessons) {
    if (lesson.id == lessonId) return lesson.title.zh;
  }
  return lessonId;
}
