import 'package:code_learn_app/screens/review_plan_screen.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 复习计划页的 7 天预测面板：正常渲染且不出现布局溢出。
void main() {
  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  testWidgets('未来 7 天预测面板展示今日构成', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final clock = DateTime(2026, 10, 26, 9);
    final storage = StorageService.inMemory();
    final lesson = content.allLessons.firstWhere(
      (item) => item.quiz.isNotEmpty,
    );
    await storage.write('review_due', <String, String>{
      lesson.id: clock.subtract(const Duration(days: 1)).toIso8601String(),
    });
    await storage.write('question_review_due', <String, String>{
      '${lesson.id}#0': clock.add(const Duration(days: 2)).toIso8601String(),
    });
    await storage.write('flashcard_due', <String, String>{
      'note:${lesson.id}': clock.add(const Duration(days: 3)).toIso8601String(),
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ChangeNotifierProvider(
            create: (_) => ProgressProvider(storage, now: () => clock),
          ),
          ChangeNotifierProvider<ContentProvider>.value(value: content),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ReviewPlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    expect(find.text('未来 7 天复习量'), findsOneWidget);
    expect(find.text('按实际排期统计，逾期计入今天'), findsOneWidget);
    expect(find.textContaining('今天：1 个知识点'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
