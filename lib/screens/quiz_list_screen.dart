import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/content_provider.dart';
import '../services/practice_question_factory.dart';
import '../services/progress_provider.dart';
import '../widgets/icon_mapper.dart';
import '../widgets/lesson_card.dart';
import 'exam_setup_screen.dart';
import 'exam_screen.dart';
import 'lesson_screen.dart';
import 'quiz_screen.dart';

/// 测验标签页：按分类列出可测验的知识点与历史成绩。
class QuizListScreen extends StatelessWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('navQuiz'))),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${context.tr('quizAverage')}：'
                          '${(progress.averageQuizAccuracy * 100).round()}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(
                      Icons.timer_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(context.tr('mockExam')),
                    subtitle: Text(context.tr('mockExamHint')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExamSetupScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(
                      Icons.replay_circle_filled_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(context.tr('wrongDrill')),
                    subtitle: Text(
                      progress.totalWrongQuestions == 0
                          ? context.tr('wrongDrillEmpty')
                          : context.tr('wrongDrillHint'),
                    ),
                    trailing: progress.totalWrongQuestions == 0
                        ? null
                        : Chip(
                            label: Text('${progress.totalWrongQuestions}'),
                            visualDensity: VisualDensity.compact,
                          ),
                    enabled: progress.totalWrongQuestions > 0,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExamScreen(
                          size: progress.totalWrongQuestions.clamp(1, 50),
                          minutes: 15,
                          scopeTitle: context.tr('wrongDrill'),
                          wrongOnly: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final category in content.categories) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Row(
                      children: [
                        Icon(
                          iconFromName(category.iconName),
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category.title.of(context.strings.localeCode),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final lesson in category.lessons)
                    LessonCard(
                      lesson: lesson,
                      isLearned: progress.isLearned(lesson.id),
                      isFavorite: progress.isFavorite(lesson.id),
                      quizResult: progress.resultOf(lesson.id),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => lesson.allQuiz.isEmpty
                              ? LessonScreen(lesson: lesson)
                              : QuizScreen(lesson: lesson),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}
