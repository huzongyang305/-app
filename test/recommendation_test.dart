import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/recommendation_service.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Lesson lesson(String id, String category, int order) {
    return Lesson(
      id: id,
      categoryId: category,
      order: order,
      title: LocalizedText(zh: id, en: id),
      summary: const LocalizedText(zh: 'summary', en: 'summary'),
      assetFile: 'assets/content/$id.md',
      minutes: 10,
      keywords: const ['test'],
      quiz: const [],
    );
  }

  test('薄弱知识点优先于未学习课程', () async {
    final progress = ProgressProvider(StorageService.inMemory());
    await progress.saveQuizResult('weak', 1, 5);
    final lessons = [
      lesson('weak', 'python', 1),
      lesson('next-a', 'python', 2),
      lesson('next-b', 'java', 1),
    ];
    final result = buildRecommendations(lessons: lessons, progress: progress);
    expect(result.first.lesson.id, 'weak');
    expect(result.first.reason, RecommendationReason.weak);
    expect(
      result.any((item) => item.reason == RecommendationReason.next),
      isTrue,
    );
  });

  test('已学习且正确率达标时推荐下一课', () async {
    final progress = ProgressProvider(StorageService.inMemory());
    await progress.saveQuizResult('done', 5, 5);
    await progress.markLearned('done');
    final lessons = [
      lesson('done', 'python', 1),
      lesson('next-a', 'python', 2),
      lesson('next-b', 'python', 3),
    ];
    final result = buildRecommendations(lessons: lessons, progress: progress);
    expect(result.first.lesson.id, 'next-a');
    expect(result.first.reason, RecommendationReason.next);
  });
}
