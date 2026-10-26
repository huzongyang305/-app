import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/quiz_answer.dart';
import '../services/progress_provider.dart';
import '../services/question_review_planner.dart';
import '../services/variant_question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_answer_panel.dart';
import '../widgets/quiz_meta_panel.dart';

/// 题目级间隔重复复习页：逐题作答，题面在同一知识点内轮换。
class QuestionReviewScreen extends StatefulWidget {
  const QuestionReviewScreen({super.key, required this.plan});

  final QuestionReviewPlan plan;

  @override
  State<QuestionReviewScreen> createState() => _QuestionReviewScreenState();
}

class _QuestionReviewScreenState extends State<QuestionReviewScreen> {
  int _index = 0;
  late VariantQuestion _variant;
  late QuizAnswer _answer;
  bool _submitted = false;
  double _score = 0;
  int _correct = 0;
  int _variantsUsed = 0;
  int? _nextIntervalDays;
  bool _finished = false;

  List<QuestionReviewItem> get _items => widget.plan.items;
  QuestionReviewItem get _item => _items[_index];
  QuizQuestion get _question => _variant.question;

  @override
  void initState() {
    super.initState();
    if (_items.isNotEmpty) _prepareCurrent(countVariant: true);
  }

  void _prepareCurrent({bool countVariant = false}) {
    final progress = context.read<ProgressProvider>();
    final attempts = progress.questionAttemptsOf(
      _item.lesson.id,
      _item.questionIndex,
    );
    _variant =
        VariantQuestionService.forQuestion(
          _item.lesson,
          _item.questionIndex,
          attempt: attempts,
        ) ??
        VariantQuestion(
          question: _item.question,
          kind: VariantKind.original,
          sourceIndex: _item.questionIndex,
          variantIndex: _item.questionIndex,
        );
    _answer = QuizAnswer.initial(_question);
    _submitted = false;
    _score = 0;
    _nextIntervalDays = null;
    if (countVariant && _variant.isVariant) _variantsUsed++;
  }

  void _setAnswer(QuizAnswer answer) {
    if (_submitted) return;
    setState(() => _answer = answer);
  }

  Future<void> _submit() async {
    if (_submitted || _items.isEmpty || !_answer.hasResponse) return;
    final score = _answer.scoreFor(_question);
    setState(() {
      _submitted = true;
      _score = score;
      if (score >= 0.999) _correct++;
    });
    final progress = context.read<ProgressProvider>();
    await progress.recordAnswerOutcome(
      _item.lesson.id,
      _item.questionIndex,
      score: score,
      confidence: _answer.confidence,
    );
    if (!mounted) return;
    setState(() {
      _nextIntervalDays = progress.questionReviewIntervalOf(
        _item.lesson.id,
        _item.questionIndex,
      );
    });
  }

  void _advance() {
    if (!_submitted) return;
    if (_index >= _items.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _prepareCurrent(countVariant: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return _buildEmpty(context);
    if (_finished) return _buildResult(context);
    final theme = Theme.of(context);
    final lesson = _item.lesson;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('reviewQuestionTitle')),
            Text(
              context.trArgs('reviewQuestionProgress', {
                'current': _index + 1,
                'total': _items.length,
              }),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_index + (_submitted ? 1 : 0)) / _items.length,
            minHeight: 4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Text(
            lesson.title.of(context.strings.localeCode),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(
                label: Text(context.difficultyLabel(lesson.difficulty)),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(
                  _item.overdueDays == 0
                      ? context.tr('reviewPlanToday')
                      : context.trArgs('reviewPlanOverdue', {
                          'n': _item.overdueDays,
                        }),
                ),
                visualDensity: VisualDensity.compact,
              ),
              if (_variant.isVariant)
                Chip(
                  avatar: Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: theme.colorScheme.tertiary,
                  ),
                  label: Text(context.tr('reviewVariantBadge')),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (_variant.isVariant) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr('reviewVariantHint'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          QuizMetaPanel(question: _question),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              _question.question,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: AppTheme.sansFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          QuizAnswerPanel(
            question: _question,
            answer: _answer,
            revealed: _submitted,
            submitOnSelect: _question.isSingleChoice,
            onChanged: _setAnswer,
            onSubmit: _submit,
          ),
          if (_submitted) ...[
            const SizedBox(height: AppSpacing.md),
            _ReviewFeedback(
              isCorrect: _score >= 0.999,
              score: _score,
              explanation: _question.explanation,
              expectedOutput: _question.expectedOutput,
              nextIntervalDays: _nextIntervalDays,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.md,
          ),
          child: _submitted
              ? SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _advance,
                    icon: Icon(
                      _index == _items.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _index == _items.length - 1
                          ? context.tr('reviewQuestionResult')
                          : context.tr('quizNextQuestion'),
                    ),
                  ),
                )
              : _question.isSingleChoice
              ? const SizedBox.shrink()
              : SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _answer.hasResponse ? _submit : null,
                    icon: const Icon(Icons.check),
                    label: Text(context.tr('quizSubmitAnswer')),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reviewQuestionTitle'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt, size: 44, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('reviewQuestionEmpty'),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr('reviewQuestionEmptyHint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text(context.tr('reviewQuestionBackToPlan')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reviewQuestionTitle'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_alt,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('reviewQuestionResult'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.trArgs('reviewQuestionResultSummary', {
                  'correct': _correct,
                  'total': _items.length,
                  'variants': _variantsUsed,
                }),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.plan.deferredCount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.trArgs('reviewQuestionQueueDeferred', {
                    'n': widget.plan.deferredCount,
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(context.tr('reviewQuestionBackToPlan')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单题反馈：判定、解析与下一次复习间隔。
class _ReviewFeedback extends StatelessWidget {
  const _ReviewFeedback({
    required this.isCorrect,
    required this.score,
    required this.explanation,
    required this.nextIntervalDays,
    this.expectedOutput,
  });

  final bool isCorrect;
  final double score;
  final String explanation;
  final String? expectedOutput;
  final int? nextIntervalDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect
        ? AppPalette.success
        : (score > 0 ? AppPalette.warning : theme.colorScheme.error);
    return Semantics(
      container: true,
      liveRegion: true,
      label: isCorrect ? context.tr('correct') : context.tr('wrong'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadii.card,
          border: Border.all(color: color.withValues(alpha: 0.24)),
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
                const Spacer(),
                Text(
                  isCorrect
                      ? context.tr('quizFullScore')
                      : context.trArgs('quizPartialScore', {
                          'percent': (score * 100).round(),
                        }),
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
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
                  fontFamily: AppTheme.monoFamily,
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
            if (nextIntervalDays != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.trArgs('reviewScheduled', {'days': nextIntervalDays}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
