import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/content_provider.dart';
import '../services/exam_builder.dart';
import '../models/quiz_answer.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quiz_answer_panel.dart';
import 'lesson_screen.dart';

/// 模拟考试：随机组卷、倒计时、交卷后给出成绩与薄弱点。
class ExamScreen extends StatefulWidget {
  const ExamScreen({
    super.key,
    this.size = 10,
    this.minutes = 15,
    this.categoryId,
    this.scopeTitle,
    this.wrongOnly = false,
    this.lessonIds,
  });

  final int size;
  final int minutes;

  /// 组卷范围：为空表示全部课程，否则限定到某个分类。
  final String? categoryId;

  /// 试卷范围名称，仅用于标题展示。
  final String? scopeTitle;

  /// 是否为「错题重练」：只抽取错题本里记录过的题目。
  final bool wrongOnly;

  /// 限定组卷范围（用于学习路径的阶段自测）。
  final Set<String>? lessonIds;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  List<ExamQuestion>? _paper;
  final List<QuizAnswer> _answers = <QuizAnswer>[];
  int _index = 0;
  QuizAnswer? _answer;
  bool _finished = false;
  Timer? _timer;
  late int _remainingSeconds = widget.minutes * 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final content = context.read<ContentProvider>();
      final progress = context.read<ProgressProvider>();
      setState(() {
        final seed = DateTime.now().millisecondsSinceEpoch;
        _paper = widget.wrongOnly
            ? buildWrongAnswerPaper(
                content.allLessons,
                wrongKeys: progress.wrongQuestionKeys,
                size: widget.size,
                seed: seed,
              )
            : buildExamPaper(
                content.allLessons,
                size: widget.size,
                seed: seed,
                categoryId: widget.categoryId,
                lessonIds: widget.lessonIds,
              );
        final paper = _paper!;
        _answer = paper.isEmpty
            ? null
            : QuizAnswer.initial(paper.first.question);
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _finished) return;
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) _finish();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    final answer = _answer;
    if (answer == null || !answer.hasResponse) return;
    _answers.add(answer);
    if (_index >= (_paper?.length ?? 1) - 1) {
      _finish();
      return;
    }
    final nextIndex = _index + 1;
    setState(() {
      _index = nextIndex;
      _answer = QuizAnswer.initial(_paper![nextIndex].question);
    });
  }

  void _finish() {
    _timer?.cancel();
    _recordWrongAnswers();
    setState(() => _finished = true);
  }

  /// 交卷后把答错的题写进错题本，答对的题清除对应的历史错题记录。
  ///
  /// 未作答的题（例如超时自动交卷）不写入，避免污染错题本。
  void _recordWrongAnswers() {
    final paper = _paper;
    if (paper == null) return;
    final progress = context.read<ProgressProvider>();
    for (var i = 0; i < paper.length && i < _answers.length; i++) {
      final question = paper[i];
      if (_answers[i].matches(question.question)) {
        progress.clearWrong(question.lesson.id, question.questionIndex);
      } else {
        progress.recordWrong(question.lesson.id, question.questionIndex);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paper = _paper;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.scopeTitle == null
              ? context.tr('mockExam')
              : '${context.tr('mockExam')} · ${widget.scopeTitle}',
        ),
        actions: [
          if (paper != null && !_finished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:'
                  '${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
      body: paper == null
          ? const Center(child: CircularProgressIndicator())
          : _finished
          ? _ReportView(paper: paper, answers: _answers)
          : _buildQuestion(context, paper),
      bottomNavigationBar: paper == null || _finished
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _answer == null || !_answer!.hasResponse
                      ? null
                      : _next,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _index == paper.length - 1
                        ? context.tr('submitExam')
                        : context.tr('nextQuestion'),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildQuestion(BuildContext context, List<ExamQuestion> paper) {
    final theme = Theme.of(context);
    final current = paper[_index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Text(
              '${context.tr('question')} ${_index + 1}/${paper.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Text(
              current.lesson.title.of(context.strings.localeCode),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          current.question.question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        QuizAnswerPanel(
          question: current.question,
          answer: _answer ?? QuizAnswer.initial(current.question),
          revealed: false,
          onChanged: (answer) => setState(() => _answer = answer),
        ),
      ],
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.paper, required this.answers});

  final List<ExamQuestion> paper;
  final List<QuizAnswer> answers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wrong = <int>[];
    for (var i = 0; i < paper.length; i++) {
      final picked = i < answers.length ? answers[i] : null;
      if (picked == null || !picked.matches(paper[i].question)) {
        wrong.add(i);
      }
    }
    final correct = paper.length - wrong.length;
    final ratio = paper.isEmpty ? 0.0 : correct / paper.length;
    final weakLessons = wrong.map((i) => paper[i].lesson).toSet();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Text(
            '${(ratio * 100).round()}%',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ratio >= 0.8
                  ? AppPalette.success
                  : ratio >= 0.6
                  ? AppPalette.warning
                  : theme.colorScheme.error,
            ),
          ),
        ),
        Center(child: Text('$correct / ${paper.length}')),
        const SizedBox(height: 20),
        if (weakLessons.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.emoji_events,
                color: AppPalette.success,
              ),
              title: Text(context.tr('examAllCorrect')),
            ),
          )
        else ...[
          Text(
            context.tr('weakPoints'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final lesson in weakLessons)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(lesson.title.of(context.strings.localeCode)),
                subtitle: Text(
                  '${context.difficultyLabel(lesson.difficulty)} · '
                  '${lesson.categoryId}',
                ),
                trailing: const Icon(Icons.menu_book_outlined),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LessonScreen(lesson: lesson),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: Text(context.tr('backToLesson')),
        ),
      ],
    );
  }
}
