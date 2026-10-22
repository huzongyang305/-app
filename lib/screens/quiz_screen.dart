import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../models/quiz_answer.dart';
import '../models/review_grade.dart';
import '../services/learning_insight_service.dart';
import '../services/practice_question_factory.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_answer_panel.dart';
import '../widgets/quiz_meta_panel.dart';
import '../widgets/responsive_content.dart';

/// 测验页：逐题作答，提交后立即判定并显示解析。
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lesson, this.isReview = false});

  final Lesson lesson;

  /// 从复习计划进入时记录一次复习场次，用于「最近复习场次」总结。
  final bool isReview;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  late List<QuizAnswer> _answers;
  late List<bool> _revealed;
  late List<double> _scores;

  /// 用户标记「稍后再看」的题号。
  final Set<int> _flagged = <int>{};

  /// 每题选择的错因，仅用于回显选中状态。
  final Map<int, String> _errorCauses = <int, String>{};

  bool _finished = false;

  /// 用户完成三档自评后，展示「多少天后再复习」。
  int? _gradedDays;

  List<QuizQuestion> get _questions => widget.lesson.allQuiz;
  QuizQuestion get _current => _questions[_index];
  QuizAnswer get _answer => _answers[_index];
  bool get _submitted => _revealed[_index];
  int get _correctCount => _scores.where((value) => value >= 0.999).length;
  int get _answeredCount => _revealed.where((value) => value).length;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  /// 重新开始或首次进入时初始化每题状态。
  void _resetState() {
    _answers = [
      for (final question in _questions) QuizAnswer.initial(question),
    ];
    _revealed = List<bool>.filled(_questions.length, false);
    _scores = List<double>.filled(_questions.length, 0);
    _flagged.clear();
    _errorCauses.clear();
    _index = 0;
    _finished = false;
    _gradedDays = null;
  }

  void _setAnswer(QuizAnswer answer) {
    if (_submitted) return;
    setState(() => _answers[_index] = answer);
  }

  /// 提交当前题：按题型计算 0..1 的部分得分，并把信心写入本地统计。
  Future<void> _submitAnswer() async {
    if (_submitted || !_answer.hasResponse) return;
    final progress = context.read<ProgressProvider>();
    final score = _answer.scoreFor(_current);
    final confidence = _answer.confidence;
    setState(() {
      _revealed[_index] = true;
      _scores[_index] = score;
    });
    await progress.recordAnswerOutcome(
      widget.lesson.id,
      _index,
      score: score,
      confidence: confidence,
    );
  }

  /// 答题后自评信心：不重复计次，只修正最近一次作答的掌握度标注。
  Future<void> _setConfidence(AnswerConfidence confidence) async {
    setState(() {
      _answers[_index] = _answer.copyWith(
        confidence: confidence,
        responded: true,
      );
    });
    await context.read<ProgressProvider>().annotateAnswerOutcome(
      widget.lesson.id,
      _index,
      confidence: confidence,
    );
  }

  /// 错因归类：把「概念不清 / 粗心 / 边界条件」等记录到本地统计。
  Future<void> _setErrorCause(String cause) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _errorCauses[_index] = cause);
    await context.read<ProgressProvider>().annotateAnswerOutcome(
      widget.lesson.id,
      _index,
      errorCause: cause,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(context.trRead('quizErrorCauseSaved'))),
    );
  }

  /// 跳题：答题卡与检查弹窗都通过它定位。
  void _goTo(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _index = index);
  }

  void _toggleFlag() {
    setState(() {
      if (!_flagged.add(_index)) _flagged.remove(_index);
    });
  }

  /// 作答后推进：优先跳到还没作答的题，全部答完后进入交卷检查。
  Future<void> _advance() async {
    for (var i = _index + 1; i < _questions.length; i++) {
      if (!_revealed[i]) {
        _goTo(i);
        return;
      }
    }
    if (_answeredCount < _questions.length) {
      _showAnswerSheet(context);
      return;
    }
    await _confirmFinish();
  }

  /// 交卷前检查：列出未作答与已标记的题号，可直接跳过去补答。
  Future<void> _confirmFinish() async {
    final unanswered = <int>[
      for (var i = 0; i < _questions.length; i++)
        if (!_revealed[i]) i,
    ];
    final flagged = _flagged.toList()..sort();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('quizCheckTitle')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unanswered.isEmpty
                    ? context.trArgs('quizCheckAllDone', {
                        'total': _questions.length,
                      })
                    : context.trArgs('quizCheckSummary', {
                        'total': _questions.length,
                        'answered': _answeredCount,
                        'unanswered': unanswered.length,
                        'flagged': flagged.length,
                      }),
              ),
              if (unanswered.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final index in unanswered)
                      ActionChip(
                        label: Text(''),
                        avatar: const Icon(Icons.help_outline, size: 16),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                          _goTo(index);
                        },
                      ),
                  ],
                ),
              ],
              if (flagged.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final index in flagged)
                      ActionChip(
                        label: Text(''),
                        avatar: const Icon(Icons.flag_outlined, size: 16),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                          _goTo(index);
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('quizCheckKeep')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('quizCheckFinish')),
          ),
        ],
      ),
    );
    if (proceed == true) _finish();
  }

  /// 结束测验：写入成绩并按正确率安排复习。
  void _finish() {
    final progress = context.read<ProgressProvider>();
    final correct = _correctCount;
    final total = _questions.length;
    progress.saveQuizResult(widget.lesson.id, correct, total);
    progress.scheduleReview(
      widget.lesson.id,
      perfect: correct == total,
      accuracy: total == 0 ? null : correct / total,
      wrongCount: progress.wrongCountFor(widget.lesson.id),
      difficulty: widget.lesson.difficulty,
    );
    if (widget.isReview) {
      progress.recordReviewSession(
        lessonCount: 1,
        correct: correct,
        total: total,
        minutes: widget.lesson.minutes,
      );
    }
    setState(() {
      _finished = true;
      _gradedDays = null;
    });
  }

  /// 结果页的三档自评：覆盖刚才按成绩自动安排的复习时间。
  void _gradeReview(ReviewGrade grade) {
    final progress = context.read<ProgressProvider>();
    progress.scheduleReviewWithGrade(
      widget.lesson.id,
      grade,
      accuracy: _questions.isEmpty ? null : _correctCount / _questions.length,
      wrongCount: progress.wrongCountFor(widget.lesson.id),
      difficulty: widget.lesson.difficulty,
    );
    setState(() => _gradedDays = progress.nextReviewDays(widget.lesson.id));
  }

  void _restart() {
    setState(_resetState);
  }

  /// 答题卡：一格一题，展示已答 / 未答 / 已标记与当前题，点击即可跳题。
  void _showAnswerSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('quizCardTitle'),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${context.trArgs('quizCardAnswered', {'n': _answeredCount})} · ${context.trArgs('quizCardFlagged', {'n': _flagged.length})}',
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < _questions.length; i++)
                    _AnswerCardCell(
                      number: i + 1,
                      answered: _revealed[i],
                      flagged: _flagged.contains(i),
                      current: i == _index,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _goTo(i);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _index == 0
                          ? null
                          : () {
                              Navigator.of(sheetContext).pop();
                              _goTo(_index - 1);
                            },
                      icon: const Icon(Icons.chevron_left),
                      label: Text(context.tr('quizPrevious')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _index == _questions.length - 1
                          ? null
                          : () {
                              Navigator.of(sheetContext).pop();
                              _goTo(_index + 1);
                            },
                      icon: const Icon(Icons.chevron_right),
                      label: Text(context.tr('quizNextQuestion')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.tr('loadFailed'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title.of(context.strings.localeCode)),
        actions: [
          IconButton(
            tooltip: _flagged.contains(_index)
                ? context.tr('quizFlagOff')
                : context.tr('quizFlagOn'),
            onPressed: _finished ? null : _toggleFlag,
            icon: Icon(
              _flagged.contains(_index) ? Icons.flag : Icons.flag_outlined,
              color: _flagged.contains(_index) ? AppPalette.warning : null,
            ),
          ),
          IconButton(
            tooltip: context.tr('quizCardTitle'),
            onPressed: _finished ? null : () => _showAnswerSheet(context),
            icon: const Icon(Icons.grid_view_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _finished ? 1 : _answeredCount / _questions.length,
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
      bottomNavigationBar: !_finished
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_submitted ||
                        (!_current.isSingleChoice && _answer.hasResponse))
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _submitted ? _advance : _submitAnswer,
                          icon: Icon(
                            _submitted ? Icons.arrow_forward : Icons.check,
                          ),
                          label: Text(
                            _submitted
                                ? (_answeredCount == _questions.length
                                      ? context.tr('seeResult')
                                      : context.tr('quizNextQuestion'))
                                : context.tr('quizSubmitAnswer'),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        IconButton(
                          tooltip: context.tr('quizPrevious'),
                          onPressed: _index == 0
                              ? null
                              : () => _goTo(_index - 1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAnswerSheet(context),
                            icon: const Icon(
                              Icons.grid_view_outlined,
                              size: 18,
                            ),
                            label: Text(
                              context.trArgs('quizCardAnswered', {
                                'n': _answeredCount,
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _submitted
                              // 已作答后主按钮已经承担「下一题」，这里换成
                              // 标记入口，避免同一屏出现两个同名按钮。
                              ? OutlinedButton.icon(
                                  onPressed: _toggleFlag,
                                  icon: Icon(
                                    _flagged.contains(_index)
                                        ? Icons.flag
                                        : Icons.flag_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _flagged.contains(_index)
                                        ? context.tr('quizFlagOff')
                                        : context.tr('quizFlagOn'),
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: _answeredCount == _questions.length
                                      ? _confirmFinish
                                      : _advance,
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _answeredCount == _questions.length
                                        ? context.tr('seeResult')
                                        : context.tr('quizNextQuestion'),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
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
    final score = _scores[_index];
    final isCorrect = score >= 0.999;

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
        const SizedBox(height: AppSpacing.md),
        QuizMetaPanel(question: _current),
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
          const SizedBox(height: AppSpacing.sm),
          _FeedbackCard(
            isCorrect: isCorrect,
            score: score,
            explanation: _current.explanation,
            expectedOutput: _current.expectedOutput,
            confidence: _answer.confidence,
            onConfidence: _setConfidence,
            errorCause: _errorCauses[_index],
            onErrorCause: isCorrect ? null : _setErrorCause,
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
    required this.score,
    required this.explanation,
    required this.confidence,
    required this.onConfidence,
    this.expectedOutput,
    this.errorCause,
    this.onErrorCause,
  });

  final bool isCorrect;

  /// 本题得分（0..1），多选与排序题可能是部分得分。
  final double score;
  final String explanation;
  final String? expectedOutput;

  /// 答后自评信心，用于概念掌握度校准。
  final AnswerConfidence confidence;
  final ValueChanged<AnswerConfidence> onConfidence;

  /// 错因归类，仅答错时需要。
  final String? errorCause;
  final ValueChanged<String>? onErrorCause;

  String _scoreLabel(BuildContext context) {
    if (isCorrect) return context.tr('quizFullScore');
    if (score <= 0) return context.tr('quizZeroScore');
    return context.trArgs('quizPartialScore', {
      'percent': (score * 100).round(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCorrect
        ? AppPalette.success
        : (score > 0 ? AppPalette.warning : AppPalette.danger);

    // liveRegion 让读屏软件在判定后立即播报结果，而不必等用户重新聚焦。
    return Semantics(
      container: true,
      liveRegion: true,
      label: isCorrect ? context.tr('correct') : context.tr('wrong'),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
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
                    _scoreLabel(context),
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
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('quizConfidenceTitle'),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: Text(context.tr('quizConfidenceGuessed')),
                    selected: confidence == AnswerConfidence.guessed,
                    onSelected: (_) => onConfidence(AnswerConfidence.guessed),
                  ),
                  ChoiceChip(
                    label: Text(context.tr('quizConfidenceUnsure')),
                    selected: confidence == AnswerConfidence.unsure,
                    onSelected: (_) => onConfidence(AnswerConfidence.unsure),
                  ),
                  ChoiceChip(
                    label: Text(context.tr('quizConfidenceConfident')),
                    selected: confidence == AnswerConfidence.confident,
                    onSelected: (_) => onConfidence(AnswerConfidence.confident),
                  ),
                ],
              ),
              if (onErrorCause != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('quizErrorCauseTitle'),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final cause in LearningInsightService.errorCauses)
                      ChoiceChip(
                        label: Text(cause),
                        selected: errorCause == cause,
                        onSelected: (_) => onErrorCause!(cause),
                      ),
                  ],
                ),
              ],
            ],
          ),
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

/// 答题卡单元格：用颜色区分已答 / 未答 / 已标记 / 当前题。
class _AnswerCardCell extends StatelessWidget {
  const _AnswerCardCell({
    required this.number,
    required this.answered,
    required this.flagged,
    required this.current,
    required this.onTap,
  });

  final int number;
  final bool answered;
  final bool flagged;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = answered
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = answered
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      label: '$number',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.control,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.control,
            border: Border.all(
              color: current
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.outlineVariant,
              width: current ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$number',
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
              if (flagged)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.flag,
                    size: 12,
                    color: answered
                        ? theme.colorScheme.onPrimary
                        : AppPalette.warning,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
