import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/quiz_answer.dart';
import '../models/review_grade.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_answer_panel.dart';
import '../widgets/responsive_content.dart';

/// 测验页：逐题作答，提交后立即判定并显示解析。
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  late QuizAnswer _answer;
  int _correctCount = 0;
  bool _finished = false;
  bool _submitted = false;

  /// 用户完成三档自评后，展示「多少天后再复习」。
  int? _gradedDays;

  List<QuizQuestion> get _questions => widget.lesson.quiz;
  QuizQuestion get _current => _questions[_index];
  bool get _answered => _submitted;

  @override
  void initState() {
    super.initState();
    _answer = _questions.isEmpty
        ? const QuizAnswer()
        : QuizAnswer.initial(_questions.first);
  }

  void _setAnswer(QuizAnswer answer) {
    if (_submitted) return;
    setState(() => _answer = answer);
  }

  void _submitAnswer() {
    if (_answered || !_answer.hasResponse) return;
    final progress = context.read<ProgressProvider>();
    final isCorrect = _answer.matches(_current);
    setState(() {
      _submitted = true;
      if (isCorrect) {
        _correctCount++;
        progress.clearWrong(widget.lesson.id, _index);
      } else {
        progress.recordWrong(widget.lesson.id, _index);
      }
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      final nextIndex = _index + 1;
      setState(() {
        _index = nextIndex;
        _answer = QuizAnswer.initial(_questions[nextIndex]);
        _submitted = false;
      });
      return;
    }

    // 最后一题：先立刻展示结果，成绩持久化交给后台完成。
    final progress = context.read<ProgressProvider>();
    progress.saveQuizResult(widget.lesson.id, _correctCount, _questions.length);
    progress.scheduleReview(
      widget.lesson.id,
      perfect: _correctCount == _questions.length,
    );
    setState(() {
      _finished = true;
      _gradedDays = null;
    });
  }

  /// 结果页的三档自评：覆盖刚才按成绩自动安排的复习时间。
  void _gradeReview(ReviewGrade grade) {
    final progress = context.read<ProgressProvider>();
    progress.scheduleReviewWithGrade(widget.lesson.id, grade);
    setState(() => _gradedDays = progress.nextReviewDays(widget.lesson.id));
  }

  void _restart() {
    setState(() {
      _index = 0;
      _answer = _questions.isEmpty
          ? const QuizAnswer()
          : QuizAnswer.initial(_questions.first);
      _submitted = false;
      _correctCount = 0;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.tr('loadFailed'))),
      );
    }

    final canSubmit = !_current.isSingleChoice && _answer.hasResponse;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title.of(context.strings.localeCode)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _finished
                ? 1
                : (_index + (_submitted ? 1 : 0)) / _questions.length,
            minHeight: 4,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _finished
            ? _ResultView(
                key: const ValueKey('result'),
                correct: _correctCount,
                total: _questions.length,
                onRestart: _restart,
                onBack: () => Navigator.of(context).pop(),
                onGrade: _gradeReview,
                gradedDays: _gradedDays,
              )
            : _buildQuestion(context),
      ),
      bottomNavigationBar: !_finished && (_submitted || canSubmit)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _submitted ? _next : _submitAnswer,
                  icon: Icon(
                    _submitted
                        ? (_index == _questions.length - 1
                              ? Icons.flag_outlined
                              : Icons.arrow_forward)
                        : Icons.check,
                  ),
                  label: Text(
                    _submitted
                        ? (_index == _questions.length - 1
                              ? context.tr('seeResult')
                              : context.tr('nextQuestion'))
                        : context.tr('quizSubmitAnswer'),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressProvider>();
    final best = progress.resultOf(widget.lesson.id);
    final isCorrect = _submitted && _answer.matches(_current);

    final prompt = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${context.tr('question')} ${_index + 1}/${_questions.length}',
              style: TextStyle(
                fontFamily: AppTheme.monoFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            if (best != null)
              Text(
                '${context.tr('bestScore')}: ${best.correct}/${best.total}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            _current.question,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: AppTheme.sansFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.55,
            ),
          ),
        ),
      ],
    );

    final answer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizAnswerPanel(
          question: _current,
          answer: _answer,
          revealed: _submitted,
          submitOnSelect: _current.isSingleChoice,
          onChanged: _setAnswer,
          onSubmit: _submitAnswer,
        ),
        if (_submitted) ...[
          const SizedBox(height: 6),
          _FeedbackCard(
            isCorrect: isCorrect,
            explanation: _current.explanation,
            expectedOutput: _current.expectedOutput,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.wideReading;
        if (!wide) {
          return ListView(
            key: ValueKey('question-$_index'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [prompt, const SizedBox(height: 18), answer],
          );
        }
        return Center(
          child: SingleChildScrollView(
            key: ValueKey('question-$_index'),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Row(
                key: const ValueKey('quiz-wide-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: prompt),
                  const SizedBox(width: 36),
                  Expanded(child: answer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 作答反馈：对错动画 + 答案解析。
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.isCorrect,
    required this.explanation,
    this.expectedOutput,
  });

  final bool isCorrect;
  final String explanation;
  final String? expectedOutput;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect ? AppPalette.success : AppPalette.danger;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          border: Border(
            left: BorderSide(color: color, width: 3),
            top: BorderSide(color: theme.colorScheme.outlineVariant),
            right: BorderSide(color: theme.colorScheme.outlineVariant),
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? context.tr('correct') : context.tr('wrong'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (expectedOutput?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Text(
                context.tr('quizExpectedOutput'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                expectedOutput!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              context.tr('explanation'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// 测验结果页：分数、评语与重做入口。
class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.correct,
    required this.total,
    required this.onRestart,
    required this.onBack,
    required this.onGrade,
    this.gradedDays,
  });

  final int correct;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  /// 三档自评回调：忘记 / 模糊 / 记得。
  final ValueChanged<ReviewGrade> onGrade;

  /// 自评完成后要展示的「下次复习间隔天数」。
  final int? gradedDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : correct / total;
    final color = ratio >= 0.8
        ? AppPalette.success
        : ratio >= 0.6
        ? AppPalette.warning
        : AppPalette.danger;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(ratio * 100).round()}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: AppTheme.monoFamily,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        '$correct / $total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('quizDone'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('yourScore')} $correct / $total',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              context.tr('reviewGradeTitle'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onGrade(ReviewGrade.forgot),
                  icon: const Icon(Icons.replay, size: 18),
                  label: Text(context.tr('gradeForgot')),
                ),
                OutlinedButton.icon(
                  onPressed: () => onGrade(ReviewGrade.fuzzy),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: Text(context.tr('gradeFuzzy')),
                ),
                FilledButton.icon(
                  onPressed: () => onGrade(ReviewGrade.remembered),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(context.tr('gradeRemembered')),
                ),
              ],
            ),
            if (gradedDays != null) ...[
              const SizedBox(height: 10),
              Text(
                context.trArgs('reviewScheduled', {'days': gradedDays}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: Text(context.tr('backToLesson')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('retakeQuiz')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
