import 'package:code_learn_app/screens/analytics_screen.dart';
import 'package:code_learn_app/screens/interactive_lab_screen.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('学习分析页在手机宽度下可以正常渲染', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = StorageService.inMemory();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
          ChangeNotifierProvider(create: (_) => ContentProvider()),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('学习分析'), findsOneWidget);
    expect(find.text('分类掌握度'), findsOneWidget);
  });

  testWidgets('交互式实验室在手机宽度下可以正常渲染', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final storage = StorageService.inMemory();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ],
        child: const MaterialApp(home: InteractiveLabScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('交互式学习实验室'), findsOneWidget);
    expect(find.text('二分查找'), findsWidgets);
  });
}
