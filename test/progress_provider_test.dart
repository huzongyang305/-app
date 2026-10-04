import 'package:code_learn_app/models/review_grade.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 学习进度的单元测试：间隔重复调度、连续天数、成绩保留与备份恢复。
void main() {
  late StorageService storage;
  late ProgressProvider progress;

  setUp(() {
    storage = StorageService.inMemory();
    progress = ProgressProvider(storage);
  });

  /// 与 ProgressProvider 内部一致的日期键（本地时区）。
  String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// 断言某个知识点的下次复习大约在 [days] 天之后（允许 2 小时误差）。
  void expectDueInDays(ProgressProvider provider, String lessonId, int days) {
    final due = provider.reviewDueAt(lessonId);
    expect(due, isNotNull, reason: '$lessonId 应当有复习计划');
    final hours = due!.difference(DateTime.now()).inMinutes / 60;
    expect(hours, closeTo(days * 24, 2), reason: '$lessonId 应约 $days 天后到期');
  }

  group('间隔重复调度', () {
    test('首次学习后 1 天到期，且当天不算「待复习」', () async {
      await progress.markLearned('a');
      expectDueInDays(progress, 'a', 1);
      expect(progress.dueReviewCount, 0);
    });

    test('全对时按 3 / 7 / 30 天逐级拉长并封顶', () async {
      await progress.markLearned('a');
      for (final days in <int>[3, 7, 30, 30]) {
        await progress.scheduleReview('a', perfect: true);
        expectDueInDays(progress, 'a', days);
      }
    });

    test('答错后立刻回落到 1 天，重新开始累积', () async {
      await progress.markLearned('a');
      await progress.scheduleReview('a', perfect: true); // 3 天
      await progress.scheduleReview('a', perfect: true); // 7 天
      await progress.scheduleReview('a', perfect: false);
      expectDueInDays(progress, 'a', 1);

      await progress.scheduleReview('a', perfect: true);
      expectDueInDays(progress, 'a', 3);
    });

    test('未标记已学也可单独写入复习计划，首次按第 1 级（1 天）计算', () async {
      await progress.scheduleReview('only_quiz', perfect: true);
      expectDueInDays(progress, 'only_quiz', 1);
      await progress.scheduleReview('only_quiz', perfect: true);
      expectDueInDays(progress, 'only_quiz', 3);
    });

    test('到期列表按到期时间升序，未到期的不会出现', () async {
      final now = DateTime.now();
      await storage.write('review_due', <String, String>{
        'later': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'earlier': now.subtract(const Duration(days: 3)).toIso8601String(),
        'future': now.add(const Duration(days: 2)).toIso8601String(),
      });
      final restored = ProgressProvider(storage);
      expect(restored.dueReviewLessonIds, <String>['earlier', 'later']);
      expect(restored.dueReviewCount, 2);
    });

    test('复习计划会写入本地存储，重启后仍然存在', () async {
      await progress.markLearned('a');
      expect(storage.read('review_due'), isA<Map>());
      expect(storage.read('review_stage'), isA<Map>());
      expect(ProgressProvider(storage).reviewDueAt('a'), isNotNull);
    });
  });

  group('连续学习天数', () {
    test('今天起往前连续三天记为 3 天', () async {
      final today = DateTime.now();
      await storage.write('study_days', <String>[
        dayKey(today),
        dayKey(today.subtract(const Duration(days: 1))),
        dayKey(today.subtract(const Duration(days: 2))),
        dayKey(today.subtract(const Duration(days: 5))),
      ]);
      expect(ProgressProvider(storage).streakDays, 3);
    });

    test('昨天学过今天没学仍算连续（给用户留一天缓冲）', () async {
      final today = DateTime.now();
      await storage.write('study_days', <String>[
        dayKey(today.subtract(const Duration(days: 1))),
        dayKey(today.subtract(const Duration(days: 2))),
      ]);
      expect(ProgressProvider(storage).streakDays, 2);
    });

    test('中断超过一天则归零', () async {
      final today = DateTime.now();
      await storage.write('study_days', <String>[
        dayKey(today.subtract(const Duration(days: 2))),
      ]);
      expect(ProgressProvider(storage).streakDays, 0);
    });
  });

  group('学习活动与进度', () {
    test('打开教程会记为已学并累加当天活动量', () async {
      await progress.markLearned('a');
      await progress.markLearned('a');
      expect(progress.learnedIds, <String>{'a'});
      expect(progress.dailyActivity(1).last, 1);
      expect(progress.lastLessonId, 'a');
      expect(progress.signedToday, isTrue);
      expect(progress.recentStudyDays(7).last, isTrue);
    });

    test('学习比例按已学 / 总数计算', () async {
      await progress.markLearned('a');
      await progress.markLearned('b');
      expect(progress.learnedRatio(4), 0.5);
      expect(progress.learnedRatio(0), 0);
    });
  });

  group('测验成绩', () {
    test('保留历史最好成绩并累计作答次数', () async {
      await progress.saveQuizResult('a', 4, 5);
      await progress.saveQuizResult('a', 2, 5);
      final result = progress.resultOf('a')!;
      expect(result.correct, 4);
      expect(result.total, 5);
      expect(result.attempts, 2);
      expect(result.accuracy, closeTo(0.8, 0.001));
    });

    test('平均正确率只统计做过测验的知识点', () async {
      await progress.saveQuizResult('a', 5, 5);
      await progress.saveQuizResult('b', 0, 5);
      expect(progress.averageQuizAccuracy, closeTo(0.5, 0.001));
    });

    test('错题按知识点汇总，清除后减少', () async {
      await progress.recordWrong('a', 1);
      await progress.recordWrong('a', 1);
      await progress.recordWrong('a', 3);
      await progress.recordWrong('b', 0);
      expect(progress.wrongCountFor('a'), 3);
      expect(progress.totalWrongQuestions, 3);

      await progress.clearWrong('a', 1);
      expect(progress.wrongCountFor('a'), 1);
    });
  });

  group('笔记与阅读位置', () {
    test('空白笔记等价于删除', () async {
      await progress.saveNote('a', '  有价值的内容  ');
      expect(progress.noteOf('a')!.content, '有价值的内容');
      await progress.saveNote('a', '   ');
      expect(progress.noteOf('a'), isNull);
      expect(storage.read('note_a'), isNull);
    });

    test('阅读位置只保存有效偏移（大于 1 像素）', () async {
      await progress.saveReadingOffset('a', 320);
      await progress.saveReadingOffset('b', 0.5);
      expect(progress.readingOffset('a'), 320);
      expect(progress.readingOffset('b'), 0);
    });
  });

  group('备份与恢复', () {
    test('导出后导入可完整还原学习数据', () async {
      await progress.markLearned('a');
      await progress.toggleFavorite('a');
      await progress.saveNote('a', '我的笔记');
      await progress.saveQuizResult('a', 4, 5);
      await progress.recordWrong('a', 2);
      await progress.scheduleReview('a', perfect: true);

      final dump = progress.exportData();
      final restored = ProgressProvider(StorageService.inMemory());
      await restored.importData(dump);

      expect(restored.learnedIds, contains('a'));
      expect(restored.isFavorite('a'), isTrue);
      expect(restored.noteOf('a')!.content, '我的笔记');
      expect(restored.resultOf('a')!.correct, 4);
      expect(restored.wrongCountFor('a'), 1);
      expect(restored.reviewDueAt('a'), isNotNull);
      expect(restored.signedToday, isTrue);
    });

    test('导入空数据不会抛异常，也不会残留旧的自选数据', () async {
      await progress.toggleFavorite('old');
      await progress.importData(const <String, dynamic>{});
      expect(progress.favoriteIds, isEmpty);
      expect(progress.learnedIds, isEmpty);
      expect(progress.quizResults, isEmpty);
    });
  });

  group('三档复习自评', () {
    late ProgressProvider progress;

    setUp(() {
      progress = ProgressProvider(StorageService.inMemory());
    });

    test('「记得」逐级拉长间隔：1 → 3 → 7 → 30 天', () async {
      await progress.markLearned('a'); // 首次进入第 1 档
      expect(progress.nextReviewDays('a'), 1);

      await progress.scheduleReviewWithGrade('a', ReviewGrade.remembered);
      expect(progress.nextReviewDays('a'), 3);

      await progress.scheduleReviewWithGrade('a', ReviewGrade.remembered);
      expect(progress.nextReviewDays('a'), 7);

      await progress.scheduleReviewWithGrade('a', ReviewGrade.remembered);
      expect(progress.nextReviewDays('a'), 30);

      // 到达最高档后保持 30 天，不会越界
      await progress.scheduleReviewWithGrade('a', ReviewGrade.remembered);
      expect(progress.nextReviewDays('a'), 30);
    });

    test('「忘记了」回到第 1 档（1 天后）', () async {
      await progress.markLearned('a');
      for (var i = 0; i < 3; i++) {
        await progress.scheduleReviewWithGrade('a', ReviewGrade.remembered);
      }
      expect(progress.nextReviewDays('a'), 30);

      await progress.scheduleReviewWithGrade('a', ReviewGrade.forgot);
      expect(progress.nextReviewDays('a'), 1);
      expect(progress.reviewGradeOf('a'), ReviewGrade.forgot);
    });

    test('「有点模糊」保持当前档位不前进', () async {
      await progress.markLearned('a');
      await progress.scheduleReviewWithGrade('a', ReviewGrade.remembered);
      expect(progress.nextReviewDays('a'), 3);

      await progress.scheduleReviewWithGrade('a', ReviewGrade.fuzzy);
      expect(progress.nextReviewDays('a'), 3);
      expect(progress.reviewGradeOf('a'), ReviewGrade.fuzzy);
    });

    test('自评档位可持久化并恢复', () async {
      final storage = StorageService.inMemory();
      final first = ProgressProvider(storage);
      await first.scheduleReviewWithGrade('a', ReviewGrade.fuzzy);

      final restored = ProgressProvider(storage);
      expect(restored.reviewGradeOf('a'), ReviewGrade.fuzzy);
      expect(restored.nextReviewDays('a'), 1);
    });

    test('旧接口 scheduleReview 仍然兼容：全对等于「记得」', () async {
      await progress.markLearned('a');
      await progress.scheduleReview('a', perfect: true);
      expect(progress.nextReviewDays('a'), 3);
      expect(progress.reviewGradeOf('a'), ReviewGrade.remembered);

      await progress.scheduleReview('a', perfect: false);
      expect(progress.nextReviewDays('a'), 1);
      expect(progress.reviewGradeOf('a'), ReviewGrade.forgot);
    });
  });
}
