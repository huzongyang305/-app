import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/learning_paths.dart';
import '../l10n/l10n_extension.dart';
import '../services/content_provider.dart';
import '../services/progress_provider.dart';
import 'exam_screen.dart';
import 'lesson_screen.dart';

/// 学习路径页：展示每条路线的进度与有序知识点。
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('learningPaths'))),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  context.tr('learningPathsHint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final path in learningPaths)
                  _PathCard(path: path, content: content, progress: progress),
              ],
            ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.content,
    required this.progress,
  });

  final LearningPath path;
  final ContentProvider content;
  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessons = resolvePathLessons(content, path);
    final totalMinutes = lessons.fold<int>(
      0,
      (sum, lesson) => sum + lesson.minutes,
    );
    final hours = (totalMinutes / 60).ceil();
    final checkpointIds = <String>{
      for (final ratio in const [0.25, 0.5, 0.75])
        if (lessons.isNotEmpty)
          lessons[(lessons.length * ratio)
                  .floor()
                  .clamp(0, lessons.length - 1)
                  .toInt()]
              .id,
    };
    final checkpointLessons = lessons
        .where((lesson) => checkpointIds.contains(lesson.id))
        .toList();
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(path.icon, color: theme.colorScheme.primary),
        title: Text(
          context.tr(path.titleKey),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('pathStageExam'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
          if (lessons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        stagePassed
                            ? Icons.check_circle
                            : Icons.pending_outlined,
                        size: 18,
                        color: stagePassed
                            ? const Color(0xFF16A34A)
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
                  if (!stagePassed)
                    for (final lesson in weakCheckpoints)
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
                '${checkpointIds.contains(lessons[i].id) ? ' · ${context.tr('pathCheckpoint')}' : ''}'
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
