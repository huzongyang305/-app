import 'dart:math' as math;

import '../models/lesson.dart';
import '../models/quiz_result.dart';
import 'knowledge_graph_service.dart';

/// 掌握度等级：由测验准确率、复习间隔、错题与前置就绪度综合得出。
enum MasteryLevel {
  newLearner('未开始'),
  learning('学习中'),
  familiar('已熟悉'),
  proficient('较熟练'),
  mastered('已掌握');

  const MasteryLevel(this.label);

  final String label;

  static MasteryLevel fromScore(double score) {
    if (score >= 0.88) return MasteryLevel.mastered;
    if (score >= 0.70) return MasteryLevel.proficient;
    if (score >= 0.50) return MasteryLevel.familiar;
    if (score >= 0.25) return MasteryLevel.learning;
    return MasteryLevel.newLearner;
  }
}

/// 单个知识点在某时刻的掌握度快照。
class MasterySnapshot {
  const MasterySnapshot({
    required this.lessonId,
    required this.level,
    required this.score,
    required this.accuracy,
    required this.attempts,
    required this.wrongCount,
    required this.intervalDays,
    required this.retention,
    required this.readiness,
    required this.blockedBy,
    required this.isDue,
    this.lastPracticedAt,
  });

  final String lessonId;
  final MasteryLevel level;

  /// 0..1 综合掌握分。
  final double score;
  final double accuracy;
  final int attempts;
  final int wrongCount;
  final int intervalDays;

  /// 遗忘曲线保留率（0.3..1）。
  final double retention;

  /// 前置就绪度（0..1）。
  final double readiness;

  /// 尚未掌握的前置课程 id。
  final List<String> blockedBy;
  final bool isDue;
  final DateTime? lastPracticedAt;

  bool get needsReview => isDue || retention < 0.6;

  int get scorePercent => (score * 100).round();
}

/// 掌握度模型：把测验、错题与间隔复习数据折算成可解释的 0..1 分数。
///
/// 公式刻意保持简单、可审计：
///   基础分 = 0.5 × 测验准确率 + 0.2 × 复习间隔 + 0.2 × 错题抑制 + 0.1 × 前置就绪度
///   最终分 = 基础分 × (0.7 + 0.3 × 遗忘保留率)
/// 没有测验记录时不虚构分数，直接按低分处理。
class MasteryService {
  const MasteryService._();

  static const double quizWeight = 0.5;
  static const double intervalWeight = 0.2;
  static const double errorWeight = 0.2;
  static const double prerequisiteWeight = 0.1;
  static const int intervalCapDays = 30;

  static MasterySnapshot evaluate({
    required Lesson lesson,
    QuizResult? quizResult,
    int wrongCount = 0,
    DateTime? reviewDueAt,
    int intervalDays = 0,
    Map<String, double> prerequisiteScores = const <String, double>{},
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final accuracy = quizResult?.accuracy ?? 0;
    final attempts = quizResult?.attempts ?? 0;
    final clampedInterval = intervalDays.clamp(0, intervalCapDays);
    final intervalScore = clampedInterval / intervalCapDays;
    final wrongBudget = math.max(1, attempts) * 4;
    final errorScore = attempts == 0
        ? 0.0
        : (1 - (wrongCount.clamp(0, wrongBudget) / wrongBudget));
    final readiness = prerequisiteScores.isEmpty
        ? 1.0
        : prerequisiteScores.values.reduce((a, b) => a + b) /
              prerequisiteScores.length;
    final base =
        quizWeight * accuracy +
        intervalWeight * intervalScore +
        errorWeight * errorScore +
        prerequisiteWeight * readiness;
    final lastPracticedAt = quizResult?.updatedAt;
    final retention = _retention(
      lastPracticedAt: lastPracticedAt,
      reviewDueAt: reviewDueAt,
      intervalDays: clampedInterval,
      now: moment,
    );
    final score = (base * (0.7 + 0.3 * retention)).clamp(0.0, 1.0);
    final blockedBy = prerequisiteScores.entries
        .where((entry) => entry.value < 0.5)
        .map((entry) => entry.key)
        .toList(growable: false);
    return MasterySnapshot(
      lessonId: lesson.id,
      level: MasteryLevel.fromScore(score),
      score: score,
      accuracy: accuracy,
      attempts: attempts,
      wrongCount: wrongCount,
      intervalDays: clampedInterval,
      retention: retention,
      readiness: readiness,
      blockedBy: blockedBy,
      isDue: reviewDueAt != null && !reviewDueAt.isAfter(moment),
      lastPracticedAt: lastPracticedAt,
    );
  }

  /// 依据知识图谱顺序自底向上计算全部课程的掌握度。
  static List<MasterySnapshot> evaluateAll({
    required KnowledgeGraph graph,
    required Map<String, QuizResult> quizResults,
    int Function(String lessonId)? wrongCountOf,
    DateTime? Function(String lessonId)? reviewDueAtOf,
    int Function(String lessonId)? intervalDaysOf,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    final scores = <String, double>{};
    final snapshots = <String, MasterySnapshot>{};
    final ordered = graph.nodes.values.toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));
    for (final node in ordered) {
      final prerequisiteScores = <String, double>{
        for (final id in node.prerequisiteIds)
          if (scores.containsKey(id)) id: scores[id]!,
      };
      final snapshot = evaluate(
        lesson: node.lesson,
        quizResult: quizResults[node.lesson.id],
        wrongCount: wrongCountOf?.call(node.lesson.id) ?? 0,
        reviewDueAt: reviewDueAtOf?.call(node.lesson.id),
        intervalDays: intervalDaysOf?.call(node.lesson.id) ?? 0,
        prerequisiteScores: prerequisiteScores,
        now: moment,
      );
      snapshots[node.lesson.id] = snapshot;
      scores[node.lesson.id] = snapshot.score;
    }
    return graph.order.map((id) => snapshots[id]!).toList(growable: false);
  }

  static double _retention({
    required DateTime? lastPracticedAt,
    required DateTime? reviewDueAt,
    required int intervalDays,
    required DateTime now,
  }) {
    final reference = lastPracticedAt ?? reviewDueAt;
    if (reference == null) return 0.3;
    final elapsedDays = now.difference(reference).inHours / 24;
    if (elapsedDays <= 0) return 1;
    final stability = 2.0 + intervalDays * 3.0;
    final value = math.exp(-elapsedDays / stability);
    return value.clamp(0.3, 1.0);
  }
}
