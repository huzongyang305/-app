import '../models/lesson.dart';
import 'progress_provider.dart';

enum RecommendationReason { review, weak, next }

class LearningRecommendation {
  const LearningRecommendation({required this.lesson, required this.reason});

  final Lesson lesson;
  final RecommendationReason reason;
}

/// 生成最多 [limit] 条本地推荐：
/// 1. 到期复习；
/// 2. 正确率低于 80% 的薄弱知识点；
/// 3. 尚未学习的下一课。
List<LearningRecommendation> buildRecommendations({
  required List<Lesson> lessons,
  required ProgressProvider progress,
  int limit = 3,
}) {
  final byId = <String, Lesson>{
    for (final lesson in lessons) lesson.id: lesson,
  };
  final result = <LearningRecommendation>[];
  final used = <String>{};

  for (final id in progress.dueReviewLessonIds) {
    final lesson = byId[id];
    if (lesson != null && used.add(id)) {
      result.add(
        LearningRecommendation(
          lesson: lesson,
          reason: RecommendationReason.review,
        ),
      );
    }
    if (result.length >= limit) return result;
  }

  final weak =
      lessons.where((lesson) {
        final quiz = progress.resultOf(lesson.id);
        return quiz != null &&
            quiz.total > 0 &&
            quiz.correct / quiz.total < 0.8;
      }).toList()..sort((a, b) {
        final left = progress.resultOf(a.id)!;
        final right = progress.resultOf(b.id)!;
        return (left.correct / left.total).compareTo(
          right.correct / right.total,
        );
      });
  for (final lesson in weak) {
    if (used.add(lesson.id)) {
      result.add(
        LearningRecommendation(
          lesson: lesson,
          reason: RecommendationReason.weak,
        ),
      );
    }
    if (result.length >= limit) return result;
  }

  final next =
      lessons.where((lesson) => !progress.isLearned(lesson.id)).toList()
        ..sort((a, b) {
          final category = a.categoryId.compareTo(b.categoryId);
          return category != 0 ? category : a.order.compareTo(b.order);
        });
  for (final lesson in next) {
    if (used.add(lesson.id)) {
      result.add(
        LearningRecommendation(
          lesson: lesson,
          reason: RecommendationReason.next,
        ),
      );
    }
    if (result.length >= limit) break;
  }
  return result;
}
