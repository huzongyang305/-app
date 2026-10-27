import 'package:code_learn_app/screens/focus_session_screen.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 专注计时：真实时长累计到今日学习数据，但不应改写「最近学习」。
void main() {
  group('专注时长记录', () {
    late StorageService storage;
    late ProgressProvider progress;

    setUp(() {
      storage = StorageService.inMemory();
      progress = ProgressProvider(storage);
    });

    test('专注计时累加今日时长但不改变最近学习课程', () async {
      await progress.addStudySeconds('python_basics', 60);
      expect(progress.lastLessonId, 'python_basics');
      expect(progress.studySecondsToday, 60);

      await progress.addFocusStudySeconds(120);
      expect(progress.studySecondsToday, 180);
      expect(progress.lastLessonId, 'python_basics');
      expect(progress.dailyStudyMinutes(1).last, 3);
      expect(progress.studyMinutesOn(DateTime.now()), 3);
    });

    test('不足 5 秒的专注被忽略，避免误触产生噪声', () async {
      await progress.addFocusStudySeconds(4);
      expect(progress.studySecondsToday, 0);
      expect(progress.lastLessonId, isNull);
    });

    test('单次记录封顶 2 小时，异常时长不会污染统计', () async {
      await progress.addFocusStudySeconds(100000);
      expect(progress.studySecondsToday, 7200);
      expect(progress.studyMinutesOn(DateTime.now()), 120);
    });

    test('专注时长写入本地存储，重建后仍计入今日目标', () async {
      await progress.addFocusStudySeconds(90);
      final restored = ProgressProvider(storage);
      expect(restored.studySecondsToday, 90);
      expect(restored.lastLessonId, isNull);
    });
  });

  testWidgets('专注页可以切换预设、启动与暂停计时', (tester) async {
    final storage = StorageService.inMemory();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProgressProvider>.value(value: progress),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: const MaterialApp(home: FocusSessionScreen()),
      ),
    );

    expect(find.text('专注计时'), findsOneWidget);
    expect(find.text('25 分钟'), findsOneWidget);
    expect(find.text('开始专注'), findsOneWidget);

    await tester.tap(find.text('45 分钟'));
    await tester.pump();
    expect(find.text('目标 45 分钟'), findsOneWidget);

    await tester.tap(find.text('开始专注'));
    await tester.pump();
    expect(find.text('暂停计时'), findsOneWidget);

    final stopButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '结束并记录'),
    );
    expect(stopButton.onPressed, isNull, reason: '不足 5 秒时不能结束并记录');

    await tester.tap(find.text('暂停计时'));
    await tester.pump();
    // 测试时钟不会推进真实 Stopwatch，不足 1 秒时按钮回到「开始专注」。
    expect(find.text('开始专注'), findsOneWidget);
  });
}
