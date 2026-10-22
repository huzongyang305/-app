import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/learning_paths.dart';
import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import '../services/settings_provider.dart';
import '../theme/app_theme.dart';
import 'exam_screen.dart';
import 'lesson_screen.dart';

/// 学习路径页：展示每条路线的进度与有序知识点。
///
/// P1 起支持三件事：
/// 1. 选定「我的学习目标」，目标路线排在最前并高亮；
/// 2. 入学测评：从路线中均匀抽题，快速定位薄弱知识点；
/// 3. 动态补课：根据测验正确率与错题记录实时生成补课清单和推荐起点。
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final paths = <LearningPath>[
      if (settings.selectedPathId.isNotEmpty)
        ...learningPaths.where((path) => path.id == settings.selectedPathId),
      ...learningPaths.where((path) => path.id != settings.selectedPathId),
    ];
    final goalPath = paths.isEmpty || settings.selectedPathId.isEmpty
        ? null
        : paths.first;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('learningPaths'))),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _GoalCard(
                  goalPath: goalPath,
                  onPick: () => _pickGoal(context, settings),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('learningPathsHint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final path in paths)
                  _PathCard(
                    path: path,
                    content: content,
                    progress: progress,
                    isGoal: goalPath?.id == path.id,
                    onSetGoal: () => _setGoal(context, settings, path),
                  ),
              ],
            ),
    );
  }

  Future<void> _pickGoal(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                sheetContext.tr('pathMyGoal'),
                style: Theme.of(sheetContext).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final path in learningPaths)
              ListTile(
                leading: Icon(path.icon),
                title: Text(sheetContext.tr(path.titleKey)),
                subtitle: Text(
                  sheetContext.tr(path.subtitleKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: settings.selectedPathId == path.id
                    ? const Icon(Icons.check_circle, color: AppPalette.success)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(path.id),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await _setGoal(
      context,
      settings,
      learningPaths.firstWhere((path) => path.id == selected),
    );
  }

  Future<void> _setGoal(
    BuildContext context,
    SettingsProvider settings,
    LearningPath path,
  ) async {
    await settings.setSelectedPathId(path.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.trRead('pathGoalSwitched')),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// 顶部目标卡：没有目标时给出引导，有目标时显示路线与进度。
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goalPath, required this.onPick});

  final LearningPath? goalPath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final path = goalPath;
    final lessons = path == null
        ? const <Lesson>[]
        : resolvePathLessons(content, path);
    final learned = lessons
        .where((lesson) => progress.isLearned(lesson.id))
        .length;
    final ratio = lessons.isEmpty ? 0.0 : learned / lessons.length;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Icon(
              path?.icon ?? Icons.flag_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('pathMyGoal'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    path == null
                        ? context.tr('pathNoGoal')
                        : '${context.tr(path.titleKey)} · '
                              '$learned/${lessons.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (path != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5,
                        backgroundColor: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: onPick,
              child: Text(context.tr('pathSetGoal')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.content,
    required this.progress,
    required this.isGoal,
    required this.onSetGoal,
  });

  final LearningPath path;
  final ContentProvider content;
  final ProgressProvider progress;
  final bool isGoal;
  final VoidCallback onSetGoal;

  /// 阶段检查点：25% / 50% / 75% 位置的课程。
  List<Lesson> _checkpoints(List<Lesson> lessons) {
    final ids = <String>{
      for (final ratio in const [0.25, 0.5, 0.75])
        if (lessons.isNotEmpty)
          lessons[(lessons.length * ratio)
                  .floor()
                  .clamp(0, lessons.length - 1)
                  .toInt()]
              .id,
    };
    return lessons.where((lesson) => ids.contains(lesson.id)).toList();
  }

  /// 入学测评抽样：整条路线均匀取 8 个知识点。
  List<Lesson> _diagnosticLessons(List<Lesson> lessons) {
    if (lessons.length <= 8) return lessons;
    final picked = <Lesson>[];
    for (var i = 0; i < 8; i++) {
      final index = (i * (lessons.length - 1) / 7).round();
      picked.add(lessons[index]);
    }
    return picked;
  }

  /// 动态补课清单：错题优先，其次正确率低于 80% 的课程。
  List<Lesson> _remediation(List<Lesson> lessons) {
    final items = <({Lesson lesson, double accuracy})>[];
    for (final lesson in lessons) {
      final wrong = progress.wrongCountFor(lesson.id);
      final result = progress.resultOf(lesson.id);
      final accuracy = result == null || result.total == 0
          ? 1.0
          : result.correct / result.total;
      if (wrong > 0 || accuracy < 0.8) {
        items.add((lesson: lesson, accuracy: accuracy));
      }
    }
    items.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return items.take(6).map((item) => item.lesson).toList();
  }

  Lesson? _recommended(List<Lesson> lessons) {
    for (final lesson in lessons) {
      final result = progress.resultOf(lesson.id);
      final accuracy = result == null || result.total == 0
          ? null
          : result.correct / result.total;
      final needsWork =
          progress.wrongCountFor(lesson.id) > 0 ||
          (accuracy != null && accuracy < 0.8);
      if (!progress.isLearned(lesson.id) || needsWork) return lesson;
    }
    return lessons.isEmpty ? null : lessons.last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessons = resolvePathLessons(content, path);
    final totalMinutes = lessons.fold<int>(
      0,
      (sum, lesson) => sum + lesson.minutes,
    );
    final hours = (totalMinutes / 60).ceil();
    final checkpointLessons = _checkpoints(lessons);
    final weakCheckpoints = checkpointLessons.where((lesson) {
      final result = progress.resultOf(lesson.id);
      return result == null ||
          result.total == 0 ||
          result.correct / result.total < 0.8;
    }).toList();
    final stagePassed = checkpointLessons.isNotEmpty && weakCheckpoints.isEmpty;
    final capstone = lessons.isEmpty
        ? null
        : lessons.lastWhere(
            (lesson) =>
                lesson.id.contains('project') ||
                lesson.title.zh.contains('实战') ||
                lesson.title.zh.contains('项目'),
            orElse: () => lessons.last,
          );
    final learned = lessons
        .where((lesson) => progress.isLearned(lesson.id))
        .length;
    final ratio = lessons.isEmpty ? 0.0 : learned / lessons.length;
    final diagnostic = _diagnosticLessons(lessons);
    final remediation = _remediation(lessons);
    final recommended = _recommended(lessons);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: isGoal
          ? RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary, width: 1.4),
              borderRadius: AppRadii.card,
            )
          : null,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(path.icon, color: theme.colorScheme.primary),
        title: Row(
          children: [
            Flexible(
              child: Text(
                context.tr(path.titleKey),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isGoal) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.tr('pathGoalBadge'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(path.subtitleKey),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: ratio, minHeight: 5),
              ),
              const SizedBox(height: 6),
              Text(
                '$learned / ${lessons.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.trArgs('pathDuration', {
                  'hours': hours,
                  'lessons': lessons.length,
                }),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          if (lessons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                children: [
                  if (!isGoal)
                    OutlinedButton.icon(
                      onPressed: onSetGoal,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(context.tr('pathSetGoal')),
                    )
                  else
                    Chip(
                      avatar: const Icon(Icons.flag, size: 16),
                      label: Text(context.tr('pathGoalBadge')),
                      visualDensity: VisualDensity.compact,
                    ),
                  const Spacer(),
                  if (recommended != null)
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LessonScreen(lesson: recommended),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(context.tr('pathContinue')),
                    ),
                ],
              ),
            ),
          if (recommended != null)
            ListTile(
              dense: true,
              leading: const Icon(Icons.near_me_outlined, size: 18),
              title: Text(
                '${context.tr('pathStartHere')} · '
                '${recommended.title.of(context.strings.localeCode)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(context.tr('pathRecommendHint')),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LessonScreen(lesson: recommended),
                ),
              ),
            ),
          if (lessons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExamScreen(
                          size: math.min(8, math.max(3, diagnostic.length)),
                          scopeTitle: context.tr(path.titleKey),
                          lessonIds: diagnostic
                              .map((lesson) => lesson.id)
                              .toSet(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: Text(
                      '${context.tr('pathDiagnostic')} · '
                      '${context.trArgs('pathDiagnosticSize', {'n': math.min(8, diagnostic.length)})}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExamScreen(
                          size: math.min(10, lessons.length),
                          scopeTitle: context.tr(path.titleKey),
                          lessonIds: lessons.map((lesson) => lesson.id).toSet(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: Text(context.tr('pathStageExam')),
                  ),
                ],
              ),
            ),
          if (remediation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('pathRemediation'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  for (final lesson in remediation)
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LessonScreen(lesson: lesson),
                        ),
                      ),
                      icon: const Icon(Icons.school_outlined, size: 16),
                      label: Text(
                        '${context.tr('pathPractice')} · '
                        '${lesson.title.of(context.strings.localeCode)}',
                      ),
                    ),
                ],
              ),
            ),
          if (lessons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Icon(
                    stagePassed ? Icons.check_circle : Icons.pending_outlined,
                    size: 18,
                    color: stagePassed
                        ? AppPalette.success
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stagePassed
                          ? context.tr('pathPassed')
                          : context.tr('pathPassRule'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < lessons.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 12,
                backgroundColor: progress.isLearned(lessons[i].id)
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                child: progress.isLearned(lessons[i].id)
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text('${i + 1}', style: theme.textTheme.labelSmall),
              ),
              title: Text(lessons[i].title.of(context.strings.localeCode)),
              subtitle: Text(
                '${context.difficultyLabel(lessons[i].difficulty)} · '
                '${lessons[i].minutes} '
                '${context.tr('minutes')}'
                '${checkpointLessons.contains(lessons[i]) ? ' · ${context.tr('pathCheckpoint')}' : ''}'
                '${capstone?.id == lessons[i].id ? ' · ${context.tr('pathCapstone')}' : ''}',
              ),
              trailing: capstone?.id == lessons[i].id
                  ? const Icon(Icons.emoji_events_outlined)
                  : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LessonScreen(lesson: lessons[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
