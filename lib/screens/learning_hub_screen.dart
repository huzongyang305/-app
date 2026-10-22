import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/lesson_category.dart';
import '../services/content_provider.dart';
import '../services/knowledge_graph_service.dart';
import '../services/mastery_service.dart';
import '../services/progress_provider.dart';
import 'content_pack_workbench_screen.dart';

/// 学习中枢：知识图谱 + 掌握度总览 + 学习顺序。
///
/// 全部数据来自本地课程与本地进度，不联网；图谱只在内容变化时重建。
class LearningHubScreen extends StatefulWidget {
  const LearningHubScreen({super.key});

  @override
  State<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends State<LearningHubScreen> {
  KnowledgeGraph? _graph;
  List<MasterySnapshot> _snapshots = const <MasterySnapshot>[];
  Map<String, MasterySnapshot> _snapshotById =
      const <String, MasterySnapshot>{};
  String _graphSignature = '';
  String _progressSignature = '';

  void _rebuildIfNeeded(
    List<LessonCategory> categories,
    ProgressProvider progress,
  ) {
    final graphSignature =
        '${categories.length}:${categories.fold<int>(0, (sum, category) => sum + category.lessons.length)}';
    if (_graph == null || _graphSignature != graphSignature) {
      _graph = KnowledgeGraphService.build(categories);
      _graphSignature = graphSignature;
      _progressSignature = '';
    }
    final progressSignature =
        '${progress.quizResults.length}:${progress.totalWrongQuestions}:'
        '${progress.learnedIds.length}:${progress.now.day}';
    if (_progressSignature == progressSignature) return;
    final graph = _graph!;
    _snapshots = MasteryService.evaluateAll(
      graph: graph,
      quizResults: progress.quizResults,
      wrongCountOf: progress.wrongCountFor,
      reviewDueAtOf: progress.reviewDueAt,
      intervalDaysOf: (lessonId) {
        final due = progress.reviewDueAt(lessonId);
        if (due == null) return 0;
        final days = due.difference(progress.now).inDays;
        return days > 0 ? days : 0;
      },
      now: progress.now,
    );
    // 542 节课的掌握度快照一次建表，避免列表滚动时反复线性查找。
    _snapshotById = {for (final item in _snapshots) item.lessonId: item};
    _progressSignature = progressSignature;
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentProvider>();
    final progress = context.watch<ProgressProvider>();
    _rebuildIfNeeded(content.categories, progress);
    final graph = _graph!;
    final mastered = _snapshots
        .where((item) => item.level.index >= MasteryLevel.proficient.index)
        .length;
    final due = _snapshots.where((item) => item.needsReview).length;
    final average = _snapshots.isEmpty
        ? 0.0
        : _snapshots.fold<double>(0, (sum, item) => sum + item.score) /
              _snapshots.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('learningHubTitle')),
        actions: [
          IconButton(
            tooltip: context.tr('learningHubPackWorkbench'),
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ContentPackWorkbenchScreen(),
              ),
            ),
          ),
        ],
      ),
      // 课程总数已达数百节，头部与课程列表都按需构建，避免一次性铺满整棵树。
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _SummaryCard(
                  average: average,
                  mastered: mastered,
                  total: _snapshots.length,
                  due: due,
                ),
                const SizedBox(height: 12),
                _GraphStatsCard(graph: graph),
                const SizedBox(height: 16),
                Text(
                  context.tr('learningHubOrder'),
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.builder(
              itemCount: graph.orderedNodes.length,
              itemBuilder: (context, index) {
                final node = graph.orderedNodes[index];
                return _NodeTile(
                  node: node,
                  snapshot: _snapshotById[node.lesson.id],
                  graph: graph,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.average,
    required this.mastered,
    required this.total,
    required this.due,
  });

  final double average;
  final int mastered;
  final int total;
  final int due;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('learningHubAverage'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(average * 100).round()}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.trArgs('learningHubMastered', {
                      'mastered': mastered,
                      'total': total,
                    }),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: average.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
            if (due > 0) ...[
              const SizedBox(height: 10),
              Text(
                context.trArgs('learningHubDue', {'n': due}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GraphStatsCard extends StatelessWidget {
  const _GraphStatsCard({required this.graph});

  final KnowledgeGraph graph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = graph.statistics;
    final problems = (stats['brokenReferences'] ?? 0) + (stats['cycles'] ?? 0);
    final chips = <String>[
      context.trArgs('learningHubNodes', {'n': stats['nodes'] ?? 0}),
      context.trArgs('learningHubEdges', {'n': stats['edges'] ?? 0}),
      context.trArgs('learningHubMaxDepth', {'n': stats['maxDepth'] ?? 0}),
      if (problems > 0)
        context.trArgs('learningHubProblems', {'n': problems})
      else
        context.tr('learningHubHealthy'),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('learningHubGraph'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final label in chips)
                  Chip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.node,
    required this.snapshot,
    required this.graph,
  });

  final KnowledgeGraphNode node;
  final MasterySnapshot? snapshot;
  final KnowledgeGraph graph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mastery = snapshot;
    final color = _levelColor(theme, mastery?.level);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Text('${node.depth}'),
        ),
        title: Text(
          node.lesson.title.zh,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: mastery?.score ?? 0,
                      minHeight: 6,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  mastery == null
                      ? context.tr('learningHubNotStarted')
                      : '${mastery.level.label} ${mastery.scorePercent}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (node.prerequisiteIds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                context.trArgs('learningHubPrereq', {
                  'n': node.prerequisiteIds.length,
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => _showDetails(context),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final mastery = snapshot;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final prerequisites = graph.prerequisitesOf(node.lesson.id);
        final next = graph.nextLessons(node.lesson.id, limit: 6);
        final path = graph.pathTo(node.lesson.id);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  node.lesson.title.zh,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  node.category.title.zh,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                if (mastery != null) ...[
                  _DetailRow(
                    label: sheetContext.tr('learningHubLevel'),
                    value: mastery.level.label,
                  ),
                  _DetailRow(
                    label: sheetContext.tr('learningHubScore'),
                    value: '${mastery.scorePercent}%',
                  ),
                  _DetailRow(
                    label: sheetContext.tr('learningHubAccuracy'),
                    value:
                        '${(mastery.accuracy * 100).round()}% '
                        '(${mastery.attempts} 次)',
                  ),
                  _DetailRow(
                    label: sheetContext.tr('learningHubRetention'),
                    value: '${(mastery.retention * 100).round()}%',
                  ),
                  if (mastery.blockedBy.isNotEmpty)
                    _DetailRow(
                      label: sheetContext.tr('learningHubBlocked'),
                      value: mastery.blockedBy.length.toString(),
                    ),
                ],
                if (path.length > 1) ...[
                  const SizedBox(height: 12),
                  Text(
                    sheetContext.tr('learningHubPath'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path.map((item) => item.lesson.title.zh).join(' → '),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (prerequisites.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    sheetContext.tr('learningHubPrereqList'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prerequisites.map((item) => item.lesson.title.zh).join('、'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (next.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    sheetContext.tr('learningHubNext'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    next.map((item) => item.lesson.title.zh).join('、'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _levelColor(ThemeData theme, MasteryLevel? level) {
    switch (level) {
      case MasteryLevel.mastered:
        return theme.colorScheme.primary;
      case MasteryLevel.proficient:
        return theme.colorScheme.primary.withValues(alpha: 0.8);
      case MasteryLevel.familiar:
        return theme.colorScheme.secondary;
      case MasteryLevel.learning:
        return theme.colorScheme.tertiary;
      case MasteryLevel.newLearner:
      case null:
        return theme.colorScheme.outline;
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
