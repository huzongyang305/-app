import '../models/lesson.dart';
import '../models/lesson_category.dart';

/// 知识图谱中的一个节点：一门课程加上它的前置与关联边。
class KnowledgeGraphNode {
  KnowledgeGraphNode({required this.lesson, required this.category});

  final Lesson lesson;
  final LessonCategory category;

  /// 课程声明的直接前置知识点 id。
  final List<String> prerequisiteIds = <String>[];

  /// 课程声明的关联知识点 id（无方向，可互相跳转）。
  final List<String> relatedIds = <String>[];

  /// 前置 id 中无法在内容里找到的部分（内容质量问题）。
  final List<String> unresolvedPrerequisiteIds = <String>[];

  /// 哪些课程把当前节点列为前置。
  final List<String> dependentIds = <String>[];

  /// 拓扑层级：0 表示没有前置的入门节点。
  int depth = 0;

  bool get isRoot => prerequisiteIds.isEmpty;
}

/// 由课程自身的 prerequisites / related 字段构建的有向知识图谱。
///
/// 图谱完全离线构建，用于推荐学习顺序、展示前置链与检测内容断链。
class KnowledgeGraph {
  KnowledgeGraph._(this.nodes, this.order, this.cycles);

  final Map<String, KnowledgeGraphNode> nodes;

  /// 拓扑排序后的课程 id（前置永远排在后继之前）。
  final List<String> order;

  /// 无法拓扑排序的节点（内容里存在循环依赖）。
  final List<String> cycles;

  bool get isEmpty => nodes.isEmpty;

  List<KnowledgeGraphNode> get orderedNodes =>
      order.map((id) => nodes[id]!).toList(growable: false);

  List<KnowledgeGraphNode> get roots =>
      orderedNodes.where((node) => node.isRoot).toList(growable: false);

  List<KnowledgeGraphNode> prerequisitesOf(String lessonId) {
    final node = nodes[lessonId];
    if (node == null) return const <KnowledgeGraphNode>[];
    return node.prerequisiteIds
        .map((id) => nodes[id])
        .whereType<KnowledgeGraphNode>()
        .toList(growable: false);
  }

  List<KnowledgeGraphNode> dependentsOf(String lessonId) {
    final node = nodes[lessonId];
    if (node == null) return const <KnowledgeGraphNode>[];
    return node.dependentIds
        .map((id) => nodes[id])
        .whereType<KnowledgeGraphNode>()
        .toList(growable: false);
  }

  List<KnowledgeGraphNode> relatedOf(String lessonId) {
    final node = nodes[lessonId];
    if (node == null) return const <KnowledgeGraphNode>[];
    return node.relatedIds
        .map((id) => nodes[id])
        .whereType<KnowledgeGraphNode>()
        .toList(growable: false);
  }

  /// 从入门节点到 [lessonId] 的最短前置链（含目标节点自身）。
  List<KnowledgeGraphNode> pathTo(String lessonId) {
    final target = nodes[lessonId];
    if (target == null) return const <KnowledgeGraphNode>[];
    final queue = <String>[lessonId];
    final previous = <String, String?>{lessonId: null};
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (nodes[current]!.prerequisiteIds.isEmpty) {
        final path = <KnowledgeGraphNode>[];
        String? cursor = current;
        while (cursor != null) {
          path.add(nodes[cursor]!);
          cursor = previous[cursor];
        }
        // 反向搜索时每条记录的父节点更靠近目标，因此 path 已是根 -> 目标顺序。
        return path;
      }
      for (final id in nodes[current]!.prerequisiteIds) {
        if (!nodes.containsKey(id) || previous.containsKey(id)) continue;
        previous[id] = current;
        queue.add(id);
      }
    }
    return <KnowledgeGraphNode>[target];
  }

  /// 学完 [lessonId] 后建议继续：先直接后继，再关联课程，最后同分类后续。
  List<KnowledgeGraphNode> nextLessons(String lessonId, {int limit = 5}) {
    final node = nodes[lessonId];
    if (node == null) return const <KnowledgeGraphNode>[];
    final result = <KnowledgeGraphNode>[];
    final seen = <String>{lessonId};
    void add(KnowledgeGraphNode? candidate) {
      if (candidate == null || seen.contains(candidate.lesson.id)) return;
      seen.add(candidate.lesson.id);
      result.add(candidate);
    }

    for (final candidate in dependentsOf(lessonId)) {
      add(candidate);
    }
    for (final candidate in relatedOf(lessonId)) {
      add(candidate);
    }
    final siblings =
        node.category.lessons
            .where((lesson) => lesson.order > node.lesson.order)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    for (final lesson in siblings) {
      add(nodes[lesson.id]);
    }
    return result.take(limit).toList(growable: false);
  }

  /// 内容中断掉的引用（前置指向了不存在的课程）。
  List<String> get brokenReferences {
    final result = <String>[];
    for (final node in nodes.values) {
      for (final id in node.unresolvedPrerequisiteIds) {
        result.add('${node.lesson.id} -> $id');
      }
    }
    return List<String>.unmodifiable(result);
  }

  Map<String, int> get categoryLessonCounts {
    final counts = <String, int>{};
    for (final node in nodes.values) {
      counts[node.category.id] = (counts[node.category.id] ?? 0) + 1;
    }
    return counts;
  }

  /// 图谱规模指标，用于设置页与审计脚本展示。
  Map<String, int> get statistics => <String, int>{
    'nodes': nodes.length,
    'edges': nodes.values.fold<int>(
      0,
      (sum, node) => sum + node.prerequisiteIds.length,
    ),
    'roots': roots.length,
    'cycles': cycles.length,
    'brokenReferences': brokenReferences.length,
    'maxDepth': nodes.values.fold<int>(
      0,
      (max, node) => node.depth > max ? node.depth : max,
    ),
  };
}

/// 从课程列表构建知识图谱。
class KnowledgeGraphService {
  const KnowledgeGraphService._();

  static KnowledgeGraph build(List<LessonCategory> categories) {
    final nodes = <String, KnowledgeGraphNode>{};
    for (final category in categories) {
      for (final lesson in category.lessons) {
        nodes[lesson.id] = KnowledgeGraphNode(
          lesson: lesson,
          category: category,
        );
      }
    }

    for (final node in nodes.values) {
      for (final id in node.lesson.prerequisites) {
        if (nodes.containsKey(id)) {
          node.prerequisiteIds.add(id);
        } else {
          node.unresolvedPrerequisiteIds.add(id);
        }
      }
      for (final id in node.lesson.related) {
        if (nodes.containsKey(id)) node.relatedIds.add(id);
      }
    }

    for (final node in nodes.values) {
      for (final id in node.prerequisiteIds) {
        nodes[id]!.dependentIds.add(node.lesson.id);
      }
    }

    final order = <String>[];
    final cycles = <String>[];
    final indegree = <String, int>{
      for (final entry in nodes.entries)
        entry.key: entry.value.prerequisiteIds.length,
    };
    final queue =
        nodes.values
            .where((node) => indegree[node.lesson.id] == 0)
            .map((node) => node.lesson.id)
            .toList()
          ..sort(_byCurriculumOrder(nodes));

    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      order.add(id);
      final dependents = nodes[id]!.dependentIds.toList()
        ..sort(_byCurriculumOrder(nodes));
      for (final dependent in dependents) {
        final remaining = indegree[dependent]! - 1;
        indegree[dependent] = remaining;
        if (remaining == 0) queue.add(dependent);
      }
    }

    for (final entry in indegree.entries) {
      if (entry.value > 0) cycles.add(entry.key);
    }

    // 深度：无前置为 0，其余为前置深度最大值 + 1（带环保护）。
    final resolving = <String>{};
    int depthOf(String id) {
      final node = nodes[id]!;
      if (node.depth > 0) return node.depth;
      if (!resolving.add(id)) return 0;
      var depth = 0;
      for (final prerequisite in node.prerequisiteIds) {
        final candidate = depthOf(prerequisite) + 1;
        if (candidate > depth) depth = candidate;
      }
      resolving.remove(id);
      node.depth = depth;
      return depth;
    }

    for (final id in nodes.keys) {
      depthOf(id);
    }

    return KnowledgeGraph._(nodes, order, cycles);
  }

  static int Function(String, String) _byCurriculumOrder(
    Map<String, KnowledgeGraphNode> nodes,
  ) {
    return (a, b) {
      final left = nodes[a]!;
      final right = nodes[b]!;
      final byCategory = left.category.id.compareTo(right.category.id);
      if (byCategory != 0) return byCategory;
      final byOrder = left.lesson.order.compareTo(right.lesson.order);
      if (byOrder != 0) return byOrder;
      return a.compareTo(b);
    };
  }
}
