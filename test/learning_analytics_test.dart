import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/services/learning_analytics.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Lesson lesson(String id, {int minutes = 10}) {
    return Lesson(
      id: id,
      categoryId: 'lang',
      difficulty: '基础',
      order: 0,
      title: LocalizedText(zh: id, en: id),
      summary: const LocalizedText(zh: '摘要', en: 'Summary'),
      assetFile: 'assets/content/$id.md',
      minutes: minutes,
      keywords: const <String>[],
      quiz: const <QuizQuestion>[],
    );
  }

  test('分析快照汇总进度、掌握度、薄弱点和推荐课程', () async {
    final storage = StorageService.inMemory();
    final progress = ProgressProvider(storage);
    await progress.markLearned('l1');
    await progress.saveQuizResult('l1', 2, 5);
    await progress.recordWrong('l1', 0);

    final snapshot = LearningAnalytics.build(
      categories: <LessonCategory>[
        LessonCategory(
          id: 'lang',
          title: const LocalizedText(zh: '语言', en: 'Language'),
          iconName: 'code',
          colorValue: 0x2563EB,
          lessons: <Lesson>[lesson('l1', minutes: 12), lesson('l2')],
        ),
      ],
      progress: progress,
      periodDays: 8,
    );

    expect(snapshot.periodDays, 14);
    expect(snapshot.totalLearned, 1);
    expect(snapshot.totalLessons, 2);
    expect(snapshot.estimatedMinutes, 12);
    expect(snapshot.averageAccuracy, closeTo(0.4, 0.001));
    expect(snapshot.categoryMastery.single.learnedLessons, 1);
    expect(
      snapshot.categoryMastery.single.averageAccuracy,
      closeTo(0.4, 0.001),
    );
    expect(snapshot.weakLessons.single.lesson.id, 'l1');
    expect(snapshot.recommendedLesson?.id, 'l2');
  });

  test('没有学习记录时返回空分析而不是异常', () {
    final snapshot = LearningAnalytics.build(
      categories: <LessonCategory>[
        LessonCategory(
          id: 'empty',
          title: const LocalizedText(zh: '空', en: 'Empty'),
          iconName: 'code',
          colorValue: 0x2563EB,
          lessons: <Lesson>[lesson('l1')],
        ),
      ],
      progress: ProgressProvider(StorageService.inMemory()),
    );

    expect(snapshot.activityTotal, 0);
    expect(snapshot.totalLearned, 0);
    expect(snapshot.weakLessons, isEmpty);
    expect(snapshot.recommendedLesson?.id, 'l1');
  });
}
