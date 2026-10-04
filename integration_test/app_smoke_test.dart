import 'package:code_learn_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 轮询等待条件成立（真实时间）。
///
/// 集成测试里 `runAsync` 会真正等一段时间，适合等待 sqflite/资源解压等
/// 真实异步初始化，而不是只推进测试时钟。
Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 60),
  Duration interval = const Duration(milliseconds: 500),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(() => Future<void>.delayed(interval));
    await tester.pump();
    if (condition()) return true;
  }
  return condition();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android 真机启动与离线首页冒烟', (tester) async {
    app.main();
    await tester.pump();

    // 首页壳层在本地内容加载完成后出现；不依赖具体文案，避免语言设置影响。
    final shellReady = await _waitFor(
      tester,
      () => find.byType(NavigationBar).evaluate().isNotEmpty,
    );
    expect(shellReady, isTrue, reason: '首页在 60 秒内未完成本地内容加载');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.getSize(find.byType(NavigationBar)).height, greaterThan(0));

    // 离线搜索：输入关键词后应能在内置课程里命中结果。
    await tester.tap(find.byTooltip('搜索知识点'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '函数');
    await tester.pump(const Duration(milliseconds: 600));
    final hasHits = await _waitFor(
      tester,
      () => find.byType(ListTile).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 20),
    );
    expect(hasHits, isTrue, reason: '离线搜索「函数」没有返回任何知识点');
  });
}
