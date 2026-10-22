import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson.dart';
import '../services/content_provider.dart';
import '../services/exam_builder.dart';
import '../services/practice_question_factory.dart';
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
    this.difficulties,
    this.questionTypes,
    this.practiceMode = false,
    this.resumeDraft = false,
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

  /// 难度筛选：空集合表示不限。
  final Set<String>? difficulties;

  /// 题型筛选：空集合表示不限。
  final Set<String>? questionTypes;

  /// 练习模式不限时；false 为限时考试。
  final bool practiceMode;

  /// 为 true 时从本地草稿恢复上次未完成的考试。
  final bool resumeDraft;

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
  late bool _practiceMode = widget.practiceMode;
  ProgressProvider? _progress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final content = context.read<ContentProvider>();
      final progress = context.read<ProgressProvider>();
      _progress = progress;
      final draft = widget.resumeDraft ? progress.examDraft : null;
      setState(() {
        if (draft == null || !_restoreDraft(draft, content)) {
          _buildFreshPaper(content, progress);
        }
      });
      if (!_practiceMode) _startTimer();
    });
  }

  /// 生成一份全新的试卷。
  void _buildFreshPaper(ContentProvider content, ProgressProvider progress) {
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
            difficulties: widget.difficulties,
            questionTypes: widget.questionTypes,
          );
    final paper = _paper!;
    _answer = paper.isEmpty ? null : QuizAnswer.initial(paper.first.question);
  }

  /// 从草稿恢复试卷；数据不完整时返回 false，由调用方重新组卷。
  bool _restoreDraft(Map<String, dynamic> draft, ContentProvider content) {
    final rawIds = (draft['lesson_ids'] as List?) ?? const [];
    final rawIndexes = (draft['question_indexes'] as List?) ?? const [];
    if (rawIds.isEmpty || rawIds.length != rawIndexes.length) return false;
    final byId = <String, Lesson>{
      for (final lesson in content.allLessons) lesson.id: lesson,
    };
    final paper = <ExamQuestion>[];
    for (var i = 0; i < rawIds.length; i++) {
      final lesson = byId[rawIds[i].toString()];
      final questionIndex = int.tryParse(rawIndexes[i].toString());
      if (lesson == null ||
          questionIndex == null ||
          questionIndex < 0 ||
          questionIndex >= lesson.allQuiz.length) {
        return false;
      }
      paper.add(ExamQuestion(lesson: lesson, questionIndex: questionIndex));
    }
    final answers = <QuizAnswer>[];
    for (final raw in (draft['answers'] as List?) ?? const []) {
      if (raw is Map) {
        answers.add(QuizAnswer.fromJson(raw.cast<String, dynamic>()));
      }
    }
    final current = draft['current'];
    final index = (draft['index'] as num?)?.toInt() ?? 0;
    _paper = paper;
    _answers
      ..clear()
      ..addAll(answers.take(paper.length));
    _index = index.clamp(0, paper.length - 1);
    _answer = current is Map
        ? QuizAnswer.fromJson(current.cast<String, dynamic>())
        : QuizAnswer.initial(paper[_index].question);
    _practiceMode = draft['practice'] == true || widget.practiceMode;
    final remaining = (draft['remaining_seconds'] as num?)?.toInt();
    if (remaining != null && remaining > 0) _remainingSeconds = remaining;
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _finished) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) _finish();
    });
  }

  /// 保存断点续考草稿；已交卷或没有试卷时不写。
  void _saveDraft() {
    final progress = _progress;
    final paper = _paper;
    if (progress == null || paper == null || paper.isEmpty || _finished) {
      return;
    }
    progress
        .saveExamDraft(<String, dynamic>{
          'created_at': DateTime.now().toIso8601String(),
          'scope_title': widget.scopeTitle,
          'practice': _practiceMode,
          'remaining_seconds': _practiceMode ? 0 : _remainingSeconds,
          'index': _index,
          'lesson_ids': [for (final item in paper) item.lesson.id],
          'question_indexes': [for (final item in paper) item.questionIndex],
          'answers': [for (final item in _answers) item.toJson()],
          'current': _answer?.toJson(),
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _saveDraft();
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
    _saveDraft();
  }

  void _finish() {
    _timer?.cancel();
    _recordWrongAnswers();
    setState(() => _finished = true);
    _progress?.clearExamDraft();
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
                  _practiceMode
                      ? context.tr('examPracticeMode')
                      : '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:'
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
        Text(
          context.tr('examReview'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < paper.length; i++)
          _QuestionReviewTile(
            number: i + 1,
            examQuestion: paper[i],
            answer: i < answers.length ? answers[i] : null,
          ),
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

/// 交卷后的逐题回顾：作答、正确答案与解析。
class _QuestionReviewTile extends StatelessWidget {
  const _QuestionReviewTile({
    required this.number,
    required this.examQuestion,
    required this.answer,
  });

  final int number;
  final ExamQuestion examQuestion;
  final QuizAnswer? answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = examQuestion.question;
    final picked = answer;
    final isCorrect = picked != null && picked.matches(question);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: isCorrect ? AppPalette.success : theme.colorScheme.error,
        ),
        title: Text(
          '$number. ${question.question}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          examQuestion.lesson.title.of(context.strings.localeCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewLine(
            label: context.tr('examYourAnswer'),
            value: _answerText(context, question, picked),
          ),
          const SizedBox(height: 8),
          _ReviewLine(
            label: context.tr('examCorrectAnswer'),
            value: _correctText(question),
          ),
          const SizedBox(height: 8),
          _ReviewLine(
            label: context.tr('explanation'),
            value: question.explanation,
          ),
        ],
      ),
    );
  }

  String _answerText(
    BuildContext context,
    QuizQuestion question,
    QuizAnswer? picked,
  ) {
    if (picked == null || !picked.hasResponse) {
      return context.tr('examUnanswered');
    }
    switch (question.type) {
      case 'fill':
        return picked.text;
      case 'order':
        return [
          for (final index in picked.orderedIndexes)
            if (index >= 0 && index < question.options.length)
              question.options[index],
        ].join(' → ');
      case 'multi':
        return [
          for (final index in picked.selectedIndexes.toList()..sort())
            if (index >= 0 && index < question.options.length)
              question.options[index],
        ].join('、');
      default:
        if (picked.selectedIndexes.isEmpty) {
          return context.tr('examUnanswered');
        }
        final index = picked.selectedIndexes.first;
        return index >= 0 && index < question.options.length
            ? question.options[index]
            : context.tr('examUnanswered');
    }
  }

  String _correctText(QuizQuestion question) {
    switch (question.type) {
      case 'fill':
        return question.acceptedAnswers.join(' / ');
      case 'order':
        return [
          for (final index in question.correctOrder)
            if (index >= 0 && index < question.options.length)
              question.options[index],
        ].join(' → ');
      case 'multi':
        return [
          for (final index in question.correctIndexes)
            if (index >= 0 && index < question.options.length)
              question.options[index],
        ].join('、');
      default:
        final index = question.correctIndexes.isEmpty
            ? -1
            : question.correctIndexes.first;
        return index >= 0 && index < question.options.length
            ? question.options[index]
            : '';
    }
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
      ],
    );
  }
}
