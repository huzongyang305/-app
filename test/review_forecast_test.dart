import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 7 天复习量预测：按天聚合三类来源、逾期归入今天、支持分类筛选。
void main() {
  final clock = DateTime(2026, 10, 26, 9);
  late StorageService storage;

  setUp(() async {
    storage = StorageService.inMemory();
    await storage.write('review_due', <String, String>{
      'l1': clock.subtract(const Duration(days: 2)).toIso8601String(),
      'l2': clock.add(const Duration(days: 1)).toIso8601String(),
      'other': clock.add(const Duration(days: 2)).toIso8601String(),
      'l3': clock.add(const Duration(days: 9)).toIso8601String(),
    });
    await storage.write('question_review_due', <String, String>{
      'l1#0': clock.add(const Duration(hours: 2)).toIso8601String(),
      'l2#3': clock.add(const Duration(days: 2)).toIso8601String(),
      'broken': clock.add(const Duration(days: 2)).toIso8601String(),
    });
    await storage.write('flashcard_due', <String, String>{
      'note:l1': clock.subtract(const Duration(days: 1)).toIso8601String(),
      'term:l2#闭包': clock.add(const Duration(days: 2)).toIso8601String(),
      'legacy#1': clock.toIso8601String(),
    });
  });

  test('按天聚合知识点、题目与闪卡，逾期计入今天', () {
    final progress = ProgressProvider(storage, now: () => clock);
    final forecast = progress.reviewForecast();

    expect(forecast.length, 7);
    expect(forecast.first.date, DateTime(2026, 10, 26));
    expect(forecast[0].lessons, 1);
    expect(forecast[0].questions, 1);
    expect(forecast[0].flashcards, 1);
    expect(forecast[0].total, 3);

    expect(forecast[1].lessons, 1);
    expect(forecast[1].questions, 0);
    expect(forecast[1].total, 1);

    expect(forecast[2].lessons, 1);
    expect(forecast[2].questions, 1);
    expect(forecast[2].flashcards, 1);
    expect(forecast[2].total, 3);

    // l3 在 9 天后，超出窗口；题目卡旧键不计入闪卡来源。
    expect(forecast.fold<int>(0, (sum, day) => sum + day.total), 7);
  });

  test('分类筛选只统计指定课程', () {
    final progress = ProgressProvider(storage, now: () => clock);
    final forecast = progress.reviewForecast(
      lessonIds: const <String>{'l1', 'l2'},
    );
    expect(forecast.fold<int>(0, (sum, day) => sum + day.total), 6);

    final empty = progress.reviewForecast(lessonIds: const <String>{});
    expect(empty.every((day) => day.isEmpty), isTrue);
  });

  test('窗口长度可调，非法天数返回空列表', () {
    final progress = ProgressProvider(storage, now: () => clock);
    final twoDays = progress.reviewForecast(days: 2);
    expect(twoDays.length, 2);
    expect(twoDays[0].total, 3);
    expect(twoDays[1].total, 1);

    expect(progress.reviewForecast(days: 0), isEmpty);
    expect(progress.reviewForecast(days: -1), isEmpty);
  });
}
