import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/flashcard.dart';
import '../models/lesson.dart';
import '../models/review_grade.dart';
import '../services/content_provider.dart';
import '../services/flashcard_service.dart';
import '../services/progress_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/index_card.dart';

/// 闪卡复习：题目/笔记自动成卡，翻面自评后接入间隔重复。
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, this.categoryId, this.lessonId});

  /// 限定分类；为空表示全部课程。
  final String? categoryId;

  /// 限定单门课程。
  final String? lessonId;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<Flashcard>? _queue;
  int _index = 0;
  int _remembered = 0;
  int _fuzzy = 0;
  int _forgot = 0;
  int _round = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _queue ??= _buildQueue();
  }

  List<Flashcard> _buildQueue() {
    final content = context.read<ContentProvider>();
    final progress = context.read<ProgressProvider>();
    return FlashcardService.buildQueue(
      content.allLessons,
      notes: progress.notes.values.toList(),
      categoryId: widget.categoryId,
      lessonId: widget.lessonId,
      seed: DateTime.now().millisecondsSinceEpoch % 100000 + _round,
    );
  }

  void _rebuildQueue() {
    setState(() {
      _round++;
      _queue = _buildQueue();
      _index = 0;
      _remembered = 0;
      _fuzzy = 0;
      _forgot = 0;
    });
  }

  Future<void> _grade(Flashcard card, ReviewGrade grade) async {
    final progress = context.read<ProgressProvider>();
    final content = context.read<ContentProvider>();
    final lesson = content.lessonById(card.lessonId);
    if (lesson != null) {
      await progress.scheduleReviewWithGrade(
        lesson.id,
        grade,
        difficulty: lesson.difficulty,
        wrongCount: grade == ReviewGrade.forgot ? 1 : 0,
      );
    }
    if (!mounted) return;
    setState(() {
      switch (grade) {
        case ReviewGrade.forgot:
          _forgot++;
        case ReviewGrade.fuzzy:
          _fuzzy++;
        case ReviewGrade.remembered:
          _remembered++;
      }
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final queue = _queue ?? const <Flashcard>[];
    final finished = queue.isEmpty || _index >= queue.length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('flashcardTitle'))),
      body: content.isLoading
          ? const Center(child: CircularProgressIndicator())
          : finished
          ? _SummaryView(
              total: queue.length,
              remembered: _remembered,
              fuzzy: _fuzzy,
              forgot: _forgot,
              onAgain: _rebuildQueue,
              onExit: () => Navigator.of(context).maybePop(),
            )
          : Column(
              children: [
                _ProgressHeader(index: _index, total: queue.length),
                Expanded(
                  child: _FlashcardView(
                    key: ValueKey<String>(queue[_index].id),
                    card: queue[_index],
                    lesson: content.lessonById(queue[_index].lessonId),
                    onGrade: (grade) => _grade(queue[_index], grade),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('flashcardHint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              MonoLabel(
                '${index + 1} / $total',
                color: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : index / total,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单张闪卡：点击翻面，翻面后自评或左右滑动。
class _FlashcardView extends StatefulWidget {
  const _FlashcardView({
    super.key,
    required this.card,
    required this.lesson,
    required this.onGrade,
  });

  final Flashcard card;
  final Lesson? lesson;
  final ValueChanged<ReviewGrade> onGrade;

  @override
  State<_FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<_FlashcardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  bool get _showingBack => _flip.value >= 0.5;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_showingBack) {
      _flip.reverse();
    } else {
      _flip.forward();
    }
  }

  void _handleSwipe(DragEndDetails details) {
    if (!_showingBack) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -280) {
      widget.onGrade(ReviewGrade.forgot);
    } else if (velocity > 280) {
      widget.onGrade(ReviewGrade.remembered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = widget.card;
    final lesson = widget.lesson;
    final categoryName = context
        .read<ContentProvider>()
        .categoryById(card.categoryId)
        ?.title
        .of(context.strings.localeCode);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggle,
              onHorizontalDragEnd: _handleSwipe,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final angle = _flip.value * math.pi;
                  final showBack = _flip.value >= 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(angle),
                    child: showBack
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _CardFace(
                              label: context.tr('flashcardBack'),
                              accent: AppPalette.success,
                              child: _BackContent(card: card),
                            ),
                          )
                        : _CardFace(
                            label: card.kind == FlashcardKind.note
                                ? context.tr('flashcardNoteCard')
                                : context.tr('flashcardFront'),
                            accent: theme.colorScheme.primary,
                            child: _FrontContent(card: card),
                          ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            lesson == null
                ? (categoryName ?? '')
                : '${lesson.title.of(context.strings.localeCode)}'
                      '${categoryName == null ? '' : ' · $categoryName'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedBuilder(
            animation: _flip,
            builder: (context, _) => _showingBack
                ? _GradeBar(onGrade: widget.onGrade)
                : Text(
                    context.tr('flashcardTapToFlip'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('flashcardSwipeHint'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.label,
    required this.accent,
    required this.child,
  });

  final String label;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: IndexCard(
        accent: accent,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadii.chip,
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: SingleChildScrollView(child: child)),
          ],
        ),
      ),
    );
  }
}

class _FrontContent extends StatelessWidget {
  const _FrontContent({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.front,
          style: theme.textTheme.titleLarge?.copyWith(height: 1.5),
        ),
        if (card.code != null && card.code!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadii.control,
            ),
            child: Text(
              card.code!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BackContent extends StatelessWidget {
  const _BackContent({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.back,
          style: theme.textTheme.titleMedium?.copyWith(
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (card.explanation != null &&
            card.explanation!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            card.explanation!,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _GradeBar extends StatelessWidget {
  const _GradeBar({required this.onGrade});

  final ValueChanged<ReviewGrade> onGrade;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => onGrade(ReviewGrade.forgot),
            icon: const Icon(Icons.close, size: 18),
            label: Text(context.tr('gradeForgot')),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: () => onGrade(ReviewGrade.fuzzy),
            icon: const Icon(Icons.help_outline, size: 18),
            label: Text(context.tr('gradeFuzzy')),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onGrade(ReviewGrade.remembered),
            icon: const Icon(Icons.check, size: 18),
            label: Text(context.tr('gradeRemembered')),
          ),
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.total,
    required this.remembered,
    required this.fuzzy,
    required this.forgot,
    required this.onAgain,
    required this.onExit,
  });

  final int total;
  final int remembered;
  final int fuzzy;
  final int forgot;
  final VoidCallback onAgain;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (total == 0) {
      return EmptyState(
        icon: Icons.style_outlined,
        message:
            '${context.tr('flashcardEmpty')}\n'
            '${context.tr('flashcardEmptyHint')}',
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: IndexCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('flashcardDone'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.trArgs('flashcardSummary', {
                  'remembered': remembered,
                  'fuzzy': fuzzy,
                  'forgot': forgot,
                }),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExit,
                      child: Text(context.tr('flashcardExit')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAgain,
                      child: Text(context.tr('flashcardAgain')),
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
}
