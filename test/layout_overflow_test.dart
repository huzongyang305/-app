import 'package:code_learn_app/screens/achievements_screen.dart';
import 'package:code_learn_app/screens/analytics_screen.dart';
import 'package:code_learn_app/screens/certificate_screen.dart';
import 'package:code_learn_app/screens/gamification_hub_screen.dart';
import 'package:code_learn_app/screens/home_screen.dart';
import 'package:code_learn_app/screens/mentor_selection_screen.dart';
import 'package:code_learn_app/screens/profile_screen.dart';
import 'package:code_learn_app/screens/quiz_list_screen.dart';
import 'package:code_learn_app/screens/social_hub_screen.dart';
import 'package:code_learn_app/screens/storage_diagnostics_screen.dart';
import 'package:code_learn_app/screens/study_center_screen.dart';
import 'package:code_learn_app/services/achievement_unlock_service.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/notification_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 布局回归：窄屏（320 宽）、大字号（2 倍）与横屏下各页面不得溢出。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Size size,
    double textScale = 1.0,
    ProgressProvider? progress,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = StorageService.inMemory();
    final progressProvider = progress ?? ProgressProvider(storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(storage),
          ),
          ChangeNotifierProvider<ProgressProvider>.value(
            value: progressProvider,
          ),
          ChangeNotifierProvider<AchievementUnlockService>(
            create: (_) => AchievementUnlockService(progressProvider),
          ),
          ChangeNotifierProvider<ContentProvider>.value(value: content),
          Provider<NotificationService>.value(value: NotificationService()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// 逐屏滚动，强制构建懒加载列表中的所有行。
  Future<void> scrollThrough(WidgetTester tester, {int steps = 10}) async {
    final scrollable = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable && widget.axisDirection == AxisDirection.down,
        )
        .first;
    for (var i = 0; i < steps; i++) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('证书分类图标与进度条使用不透明颜色', (tester) async {
    await pumpScreen(
      tester,
      const CertificateScreen(),
      size: const Size(390, 844),
    );

    final icon = tester.widget<Icon>(
      find
          .descendant(
            of: find.byType(CircleAvatar).first,
            matching: find.byType(Icon),
          )
          .first,
    );
    expect(icon.color, isNotNull);
    expect(icon.color!.a, 1.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('我的页统计条在 390 宽与 2 倍字号下都不溢出', (tester) async {
    await pumpScreen(
      tester,
      const ProfileScreen(),
      size: const Size(390, 844),
    );
    expect(find.text('已学知识点'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      const ProfileScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await scrollThrough(tester, steps: 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首页分类卡在 320 宽与 2 倍字号下不溢出', (tester) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await scrollThrough(tester, steps: 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('学习分析掌握度矩阵在 320 宽与 1.3 倍字号下不溢出', (tester) async {
    await pumpScreen(
      tester,
      const AnalyticsScreen(),
      size: const Size(320, 568),
      textScale: 1.3,
    );
    await scrollThrough(tester, steps: 12);
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      const AnalyticsScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await scrollThrough(tester, steps: 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('游戏化中心卡片在窄屏与大字号下不溢出', (tester) async {
    await pumpScreen(
      tester,
      const GamificationHubScreen(),
      size: const Size(320, 568),
    );
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      const GamificationHubScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('导师选择卡片在大字号下不溢出', (tester) async {
    await pumpScreen(
      tester,
      const MentorSelectionScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('题库列表与成就页在 2 倍字号下不溢出', (tester) async {
    await pumpScreen(
      tester,
      const QuizListScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await scrollThrough(tester, steps: 8);
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      const AchievementsScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await scrollThrough(tester, steps: 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('学习中心在 2 倍字号下不溢出', (tester) async {
    await pumpScreen(
      tester,
      const StudyCenterScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await scrollThrough(tester, steps: 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('存储诊断在 2 倍字号下不溢出', (tester) async {
    await pumpScreen(
      tester,
      const StorageDiagnosticsScreen(),
      size: const Size(320, 568),
      textScale: 2.0,
    );
    await scrollThrough(tester, steps: 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('社交中心横屏只有一层 AppBar 且空态可滚动', (tester) async {
    await pumpScreen(
      tester,
      const SocialHubScreen(),
      size: const Size(844, 390),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('暂无好友'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final tab in ['排行', '分享', '小组']) {
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
