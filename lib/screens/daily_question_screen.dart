import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/quiz_answer.dart';
import '../models/review_grade.dart';
import '../services/content_provider.dart';
import '../services/daily_question_service.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/index_card.dart';
import '../widgets/quiz_answer_panel.dart';
import 'lesson_screen.dart';

/// 每日一题：每天从本地题库确定性抽一道题，答完立即判分并写回学习数据。
class DailyQuestionScreen extends StatefulWidget {
  const DailyQuestionScreen({super.key});

  @override
  State<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends State<DailyQuestionScreen> {
  bool _initialized = false;
  DailyQuestion? _daily;
  QuizAnswer _answer = const QuizAnswer();
  bool _revealed = false;
  bool _correct = false;
  bool _alreadyAnswered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final content = context.read<ContentProvider>();
    final progress = context.read<ProgressProvider>();
    _daily = DailyQuestionService.pick(content.allLessons, progress.now);
    final current = _daily;
    if (current != null) {
      _answer = QuizAnswer.initial(current.question);
      if (progress.dailyQuestionAnsweredToday) {
        _alreadyAnswered = true;
        _revealed = true;
        _correct = progress.dailyQuestionCorrect;
      }
    }
  }

  Future<void> _submit() async {
    final daily = _daily;
    if (daily == null || _revealed) return;
    final progress = context.read<ProgressProvider>();
    final correct = _answer.matches(daily.question);
    setState(() {
      _revealed = true;
      _correct = correct;
    });
    await progress.markDailyQuestionAnswered(correct: correct);
    if (correct) {
      await progress.scheduleReviewWithGrade(
        daily.lesson.id,
        ReviewGrade.remembered,
        difficulty: daily.lesson.difficulty,
      );
    } else {
      // 答错同步进错题本与复习队列，后续可以在错题专项里重练。
      await progress.recordWrong(daily.lesson.id, daily.questionIndex);
      await progress.scheduleReviewWithGrade(
        daily.lesson.id,
        ReviewGrade.forgot,
        difficulty: daily.lesson.difficulty,
        wrongCount: 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final daily = _daily;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('dailyQuestionTitle'))),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : daily == null
          ? EmptyState(
              icon: Icons.quiz_outlined,
              message: context.tr('dailyQuestionEmpty'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              children: [
                IndexCard(
                  accent: theme.colorScheme.primary,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: AppRadii.control,
                        ),
                        child: Icon(
                          Icons.today_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('dailyQuestionTitle'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('dailyQuestionHint'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                IndexCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${daily.lesson.title.of(context.strings.localeCode)}'
                        ' · ${context.difficultyLabel(daily.lesson.difficulty)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        daily.question.question,
                        style: theme.textTheme.titleMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                      if (daily.question.code != null &&
                          daily.question.code!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: AppRadii.control,
                          ),
                          child: Text(
                            daily.question.code!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                IndexCard(
                  child: QuizAnswerPanel(
                    question: daily.question,
                    answer: _answer,
                    revealed: _revealed,
                    onChanged: (value) => setState(() => _answer = value),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!_revealed)
                  FilledButton.icon(
                    onPressed: _answer.hasResponse ? _submit : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(context.tr('quizSubmitAnswer')),
                  )
                else ...[
                  _ResultBanner(
                    correct: _correct,
                    alreadyAnswered: _alreadyAnswered,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IndexCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('examCorrectAnswer'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _correctAnswerText(daily),
                          style: theme.textTheme.bodyLarge,
                        ),
                        if (daily.question.explanation.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            context.tr('explanation'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            daily.question.explanation,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.7,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LessonScreen(lesson: daily.lesson),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(context.tr('viewLesson')),
                  ),
                ],
              ],
            ),
    );
  }

  String _correctAnswerText(DailyQuestion daily) {
    final question = daily.question;
    switch (question.type) {
      case 'multi':
        return question.correctIndexes
            .where((index) => index >= 0 && index < question.options.length)
            .map((index) => question.options[index])
            .join('、');
      case 'order':
        final order = question.correctOrder.isEmpty
            ? question.correctIndexes
            : question.correctOrder;
        return order
            .where((index) => index >= 0 && index < question.options.length)
            .map((index) => question.options[index])
            .join(' → ');
      case 'fill':
        return question.acceptedAnswers.isEmpty
            ? '--'
            : question.acceptedAnswers.first;
      default:
        final index = question.answerIndex;
        if (index >= 0 && index < question.options.length) {
          return question.options[index];
        }
        return '--';
    }
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.correct, required this.alreadyAnswered});

  final bool correct;
  final bool alreadyAnswered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? AppPalette.success : AppPalette.danger;
    return IndexCard(
      accent: color,
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? context.tr('correct') : context.tr('wrong'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (alreadyAnswered) ...[
                  const SizedBox(height: 2),
                  Text(
                    context.tr('dailyQuestionAnswered'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
