import 'package:code_learn_app/l10n/app_strings.dart';
import 'package:code_learn_app/models/achievement.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 成就系统测试：解锁条件、样本门槛与文案完整性。
void main() {
  late ProgressProvider progress;

  setUp(() {
    progress = ProgressProvider(StorageService.inMemory());
  });

  /// 取某个成就的当前状态。
  AchievementStatus statusOf(String id) =>
      evaluateAchievements(progress)
          .firstWhere((status) => status.achievement.id == id);

  test('初始状态：一枚都未解锁，进度为 0', () {
    final statuses = evaluateAchievements(progress);
    expect(statuses.length, kAchievements.length);
    expect(earnedAchievementCount(statuses), 0);
    for (final status in statuses) {
      expect(status.ratio, 0);
      expect(status.earned, isFalse);
    }
  });

  test('学完第一篇即解锁「起步」', () async {
    await progress.markLearned('lesson_1');
    expect(statusOf('first_lesson').earned, isTrue);
    expect(statusOf('lessons_10').earned, isFalse);
    expect(statusOf('lessons_10').displayValue, 1);
  });

  test('学到 10 篇时同时满足「起步」与「十篇达成」', () async {
    for (var i = 0; i < 10; i++) {
      await progress.markLearned('lesson_$i');
    }
    expect(statusOf('first_lesson').earned, isTrue);
    expect(statusOf('lessons_10').earned, isTrue);
    expect(statusOf('lessons_50').earned, isFalse);
    expect(statusOf('lessons_50').displayValue, 10);
  });

  test('正确率成就需要样本达标：5 个知识点起算', () async {
    // 只做一个知识点的满分测验，不满足最小样本量
    await progress.saveQuizResult('lesson_1', 5, 5);
    expect(statusOf('quiz_80').displayValue, 0);
    expect(statusOf('quiz_80').earned, isFalse);

    // 再做 4 个知识点，平均正确率 100%
    for (var i = 2; i <= 5; i++) {
      await progress.saveQuizResult('lesson_$i', 5, 5);
    }
    expect(statusOf('quiz_80').displayValue, 100);
    expect(statusOf('quiz_80').earned, isTrue);
  });

  test('正确率低于 80% 不解锁', () async {
    for (var i = 1; i <= 5; i++) {
      await progress.saveQuizResult('lesson_$i', 3, 5); // 60%
    }
    expect(statusOf('quiz_80').displayValue, 60);
    expect(statusOf('quiz_80').earned, isFalse);
  });

  test('收藏 10 个与写 10 条笔记分别解锁对应徽章', () async {
    for (var i = 0; i < 10; i++) {
      await progress.toggleFavorite('fav_$i');
      await progress.saveNote('note_$i', '第 $i 条笔记');
    }
    expect(statusOf('favorites_10').earned, isTrue);
    expect(statusOf('notes_10').earned, isTrue);
  });

  test('徽章 id 唯一，且中英文文案都已配置', () {
    final ids = <String>{};
    for (final achievement in kAchievements) {
      expect(
        ids.add(achievement.id),
        isTrue,
        reason: '重复的成就 id：${achievement.id}',
      );
      for (final key in <String>[
        achievement.titleKey,
        achievement.descriptionKey,
      ]) {
        final entry = AppStrings.raw(key);
        expect(entry, isNotNull, reason: '成就 $key 缺少 l10n 词条');
        expect(entry!['zh'], isNotEmpty);
        expect(entry['en'], isNotEmpty);
      }
    }
  });
}
