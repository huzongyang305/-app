import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/custom_question.dart';
import '../models/lesson.dart';
import '../models/lesson_category.dart';
import '../services/content_provider.dart';
import '../services/practice_question_factory.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import 'exam_screen.dart';
import 'ocr_capture_screen.dart';
import 'quiz_screen.dart';

class WrongAnswerScreen extends StatefulWidget {
  const WrongAnswerScreen({super.key});

  @override
  State<WrongAnswerScreen> createState() => _WrongAnswerScreenState();
}

class _WrongAnswerScreenState extends State<WrongAnswerScreen> {
  String? _selectedCategoryId;
  final Set<String> _expandedLessons = {};

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final content = context.watch<ContentProvider>();
    final wrongKeys = progress.wrongQuestionKeys;
    final customs = progress.customQuestionsNewestFirst;
    // 自录错题不属于任何分类，只在「全部」视图里出现，避免分类筛选串题。
    final showCustomSection = customs.isNotEmpty && _selectedCategoryId == null;

    if (wrongKeys.isEmpty && customs.isEmpty) {
      return Scaffold(
        appBar: _captureAppBar(drillEnabled: false),
        body: EmptyState(
          icon: Icons.task_alt,
          message: context.tr('noWrongQuestions'),
        ),
      );
    }

    final lessonWrongCounts = _groupWrongByLesson(
      wrongKeys,
      content.allLessons,
    );
    final categoriesWithWrong = _extractCategories(
      lessonWrongCounts,
      content.categories,
    );
    final filteredLessons = _selectedCategoryId == null
        ? lessonWrongCounts
        : lessonWrongCounts
              .where((entry) => entry.key.categoryId == _selectedCategoryId)
              .toList();

    return Scaffold(
      appBar: _captureAppBar(drillEnabled: wrongKeys.isNotEmpty),
      body: Column(
        children: [
          if (wrongKeys.isNotEmpty) _StatsHeader(progress: progress),
          if (categoriesWithWrong.length > 1)
            _CategoryFilter(
              categories: categoriesWithWrong,
              selected: _selectedCategoryId,
              onSelected: (cat) => setState(() => _selectedCategoryId = cat),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                ...filteredLessons.map((entry) {
                  final lesson = entry.key;
                  final wrongIndices = entry.value;
                  return _LessonWrongCard(
                    lesson: lesson,
                    wrongIndices: wrongIndices,
                    isExpanded: _expandedLessons.contains(lesson.id),
                    onToggle: () => setState(() {
                      if (_expandedLessons.contains(lesson.id)) {
                        _expandedLessons.remove(lesson.id);
                      } else {
                        _expandedLessons.add(lesson.id);
                      }
                    }),
                    onMastered: () => _markAllMastered(lesson.id, wrongIndices),
                    onRetake: () => _retakeLesson(context, lesson),
                  );
                }),
                if (showCustomSection) ...[
                  _CustomQuestionsHeader(count: customs.length),
                  ...customs.map(
                    (item) => _CustomQuestionCard(
                      question: item,
                      onEdit: () => _editCustom(item),
                      onDelete: () => _deleteCustom(item),
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

  AppBar _captureAppBar({required bool drillEnabled}) {
    return AppBar(
      title: Text(context.tr('wrongBook')),
      actions: [
        IconButton(
          icon: const Icon(Icons.photo_camera_outlined),
          tooltip: context.tr('ocrCapture'),
          onPressed: _openCapture,
        ),
        if (drillEnabled)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('wrongDrill'),
            onPressed: () => _startWrongDrill(context),
          ),
      ],
    );
  }

  Future<void> _openCapture() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const OcrCaptureScreen()),
    );
    if (saved == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _editCustom(CustomQuestion item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => OcrCaptureScreen(existing: item)),
    );
    if (saved != true) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trRead('ocrUpdated'))),
    );
  }

  Future<void> _deleteCustom(CustomQuestion item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(dialogContext.tr('customQuestionDeleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<ProgressProvider>().deleteCustomQuestion(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trRead('customQuestionDeleted'))),
    );
  }

  List<MapEntry<Lesson, List<int>>> _groupWrongByLesson(
    List<String> wrongKeys,
    List<Lesson> allLessons,
  ) {
    final byLesson = <String, List<int>>{};
    for (final key in wrongKeys) {
      final parts = key.split('#');
      if (parts.length != 2) continue;
      final lessonId = parts[0];
      final qIndex = int.tryParse(parts[1]);
      if (qIndex == null) continue;
      byLesson.putIfAbsent(lessonId, () => []).add(qIndex);
    }
    final lessonMap = {for (final l in allLessons) l.id: l};
    return byLesson.entries
        .where((e) => lessonMap.containsKey(e.key))
        .map((e) => MapEntry(lessonMap[e.key]!, e.value..sort()))
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
  }

  List<LessonCategory> _extractCategories(
    List<MapEntry<Lesson, List<int>>> lessons,
    List<LessonCategory> allCategories,
  ) {
    final catIds = <String>{};
    for (final entry in lessons) {
      catIds.add(entry.key.categoryId);
    }
    return allCategories.where((cat) => catIds.contains(cat.id)).toList();
  }

  void _markAllMastered(String lessonId, List<int> wrongIndices) async {
    final progress = context.read<ProgressProvider>();
    for (final idx in wrongIndices) {
      await progress.clearWrong(lessonId, idx);
    }
    setState(() {});
  }

  void _retakeLesson(BuildContext context, Lesson lesson) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => QuizScreen(lesson: lesson)));
  }

  void _startWrongDrill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ExamScreen(wrongOnly: true, practiceMode: true),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.progress});

  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final total = progress.totalWrongQuestions;
    final everWrong = progress.everWrongQuestions;
    final resolved = progress.resolvedWrongQuestions;
    final ratio = progress.wrongResolvedRatio;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.primary, AppPalette.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadii.card,
        boxShadow: [
          BoxShadow(
            color: AppPalette.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.error_outline,
                label: context.tr('wrongCount'),
                value: '$total',
              ),
              _StatItem(
                icon: Icons.check_circle_outline,
                label: context.tr('wrongResolved'),
                value: '$resolved/$everWrong',
              ),
              _StatItem(
                icon: Icons.trending_up,
                label: context.tr('progress'),
                value: '${(ratio * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<LessonCategory> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = context.strings.localeCode;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          FilterChip(
            label: Text(context.tr('searchFilterAll')),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat.title.of(locale)),
                selected: selected == cat.id,
                onSelected: (_) =>
                    onSelected(cat.id == selected ? null : cat.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonWrongCard extends StatefulWidget {
  const _LessonWrongCard({
    required this.lesson,
    required this.wrongIndices,
    required this.isExpanded,
    required this.onToggle,
    required this.onMastered,
    required this.onRetake,
  });

  final Lesson lesson;
  final List<int> wrongIndices;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onMastered;
  final VoidCallback onRetake;

  @override
  State<_LessonWrongCard> createState() => _LessonWrongCardState();
}

class _LessonWrongCardState extends State<_LessonWrongCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.lesson.title.of(context.strings.localeCode);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppPalette.danger.withValues(alpha: 0.1),
              child: Text(
                '${widget.wrongIndices.length}',
                style: TextStyle(
                  color: AppPalette.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${context.tr('wrongCount')}: ${widget.wrongIndices.length}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  tooltip: context.tr('wrongDrill'),
                  onPressed: widget.onRetake,
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  tooltip: context.tr('wrongResolved'),
                  onPressed: widget.onMastered,
                ),
                Icon(widget.isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: widget.onToggle,
          ),
          if (widget.isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.wrongIndices
                    .map(
                      (idx) => _WrongQuestionItem(
                        questionIndex: idx,
                        lesson: widget.lesson,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _WrongQuestionItem extends StatelessWidget {
  const _WrongQuestionItem({required this.questionIndex, required this.lesson});

  final int questionIndex;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiz = lesson.allQuiz;
    if (questionIndex >= quiz.length) return const SizedBox.shrink();
    final question = quiz[questionIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.neutralFill,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${questionIndex + 1}: ${question.question}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...question.options.asMap().entries.map((entry) {
            final isCorrect = question.correctIndexes.contains(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isCorrect ? AppPalette.success : AppPalette.inkMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isCorrect ? AppPalette.success : null,
                        fontWeight: isCorrect ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.primary.withValues(alpha: 0.05),
                borderRadius: AppRadii.card,
                border: Border.all(
                  color: AppPalette.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppPalette.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomQuestionsHeader extends StatelessWidget {
  const _CustomQuestionsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
        top: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 18,
            color: AppPalette.primary,
          ),
          const SizedBox(width: 6),
          Text(
            context.trArgs('customQuestionsCount', {'n': count}),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 自录错题卡：题干与答案都先给一行摘要，点开再看解析。
class _CustomQuestionCard extends StatefulWidget {
  const _CustomQuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_CustomQuestionCard> createState() => _CustomQuestionCardState();
}

class _CustomQuestionCardState extends State<_CustomQuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.question;
    final explanation = item.explanation.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppPalette.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 18,
                color: AppPalette.primary,
              ),
            ),
            title: Text(
              item.question,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              item.answer,
              maxLines: _expanded ? null : 1,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.success,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: context.tr('ocrEdit'),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: context.tr('delete'),
                  onPressed: widget.onDelete,
                ),
                if (explanation.isNotEmpty)
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: explanation.isEmpty
                ? widget.onEdit
                : () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded && explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppPalette.primary.withValues(alpha: 0.05),
                  borderRadius: AppRadii.card,
                  border: Border.all(
                    color: AppPalette.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
