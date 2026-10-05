import 'dart:io' show Platform;

import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/screens/lesson_screen.dart';
import 'package:code_learn_app/screens/quiz_screen.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/notification_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 金图像素对比只在生成它们的 Windows 上执行。
///
/// Linux/macOS 的字体栅格化与 Windows 存在像素级差异，在 CI 上强行对比
/// 会把平台渲染差异误报成视觉回归；其他平台保留「页面可渲染、关键组件
/// 存在」的冒烟断言，仍能捕获布局异常和运行时错误。
final bool _compareGoldens = Platform.isWindows;

void main() {
  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Key key, {
    StorageService? storage,
  }) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CodeLearnApp(
          storage: storage ?? StorageService.inMemory(),
          contentProvider: content,
          // 固定日期，避免金图随系统日期漂移。
          clock: () => DateTime(2026, 1, 5, 9, 30),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('视觉回归：手机首页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-phone');
    await pumpApp(tester, key);
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/home_phone.png'),
      );
    } else {
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    }
  });

  testWidgets('视觉回归：平板首页', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-tablet');
    await pumpApp(tester, key);
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/home_tablet.png'),
      );
    } else {
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    }
  });

  testWidgets('视觉回归：手机首页深色模式', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final storage = StorageService.inMemory();
    await storage.write('theme_mode', 'dark');
    const key = ValueKey('golden-phone-dark');
    await pumpApp(tester, key, storage: storage);
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/home_phone_dark.png'),
      );
    } else {
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    }
  });

  testWidgets('英文界面可正常渲染', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final storage = StorageService.inMemory();
    await storage.write('locale_code', 'en');
    const key = ValueKey('golden-phone-en');
    await pumpApp(tester, key, storage: storage);
    expect(find.text('CS & Coding'), findsOneWidget);
    expect(find.text('Overall progress'), findsOneWidget);
  });

  /// 切换到指定底部导航页，等待页面稳定后截图。
  Future<void> openTab(WidgetTester tester, IconData icon) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(icon),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('视觉回归：手机学习页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-learn');
    await pumpApp(tester, key);
    await openTab(tester, Icons.menu_book_outlined);
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/learn_phone.png'),
      );
    } else {
      expect(find.byType(NavigationBar), findsOneWidget);
    }
  });

  testWidgets('视觉回归：手机工具页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-tools');
    await pumpApp(tester, key);
    await openTab(tester, Icons.build_outlined);
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/tools_phone.png'),
      );
    } else {
      expect(find.byType(NavigationBar), findsOneWidget);
    }
  });

  testWidgets('视觉回归：手机我的页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-profile');
    await pumpApp(tester, key);
    await openTab(tester, Icons.person_outline);
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/profile_phone.png'),
      );
    } else {
      expect(find.byType(NavigationBar), findsOneWidget);
    }
  });

  /// 直接挂载单个页面，避免依赖多级导航，专注页面自身的视觉回归。
  Future<void> pumpScreen(WidgetTester tester, Key key, Widget screen) async {
    final storage = StorageService.inMemory();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
            ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
            ChangeNotifierProvider<ContentProvider>.value(value: content),
            Provider<NotificationService>.value(value: NotificationService()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
  }

  /// 选一篇带测验的教程，保证教程页与测验页都有内容可渲染。
  Lesson visualLesson() =>
      content.allLessons.firstWhere((lesson) => lesson.quiz.isNotEmpty);

  testWidgets('视觉回归：手机教程页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-lesson');
    await pumpScreen(tester, key, LessonScreen(lesson: visualLesson()));
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/lesson_phone.png'),
      );
    } else {
      expect(find.byType(LessonScreen), findsOneWidget);
    }
  });

  testWidgets('视觉回归：手机测验页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-quiz');
    await pumpScreen(tester, key, QuizScreen(lesson: visualLesson()));
    if (_compareGoldens) {
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/quiz_phone.png'),
      );
    } else {
      expect(find.byType(QuizScreen), findsOneWidget);
    }
  });
}
