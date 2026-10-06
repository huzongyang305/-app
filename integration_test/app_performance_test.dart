import 'dart:convert';

import 'package:code_learn_app/main.dart' as app;
import 'package:code_learn_app/widgets/category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Android 真机 / 模拟器性能基线。
///
/// 记录启动、内容加载、首次搜索（建索引）与二次搜索（缓存命中）的耗时，
/// 以 JSON 形式打印到测试输出，供 CI 归档对比。阈值刻意宽松，
/// 只拦截数量级退化，不把模拟器抖动当成失败。
Future<bool> _waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 60),
  Duration interval = const Duration(milliseconds: 200),
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

  testWidgets('Android 性能基线：启动 / 内容 / 搜索', (tester) async {
    final startupWatch = Stopwatch()..start();
    app.main();
    await tester.pump();
    // 底部导航先于正文出现，首页此时可能还在转加载动画；必须等到
    // 分类卡片真正渲染，否则会停在加载动画上，pumpAndSettle 永不收敛。
    final shellReady = await _waitFor(
      tester,
      () =>
          find.byType(NavigationBar).evaluate().isNotEmpty &&
          find.byType(CategoryCard).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
    );
    startupWatch.stop();
    expect(shellReady, isTrue, reason: '首页 90 秒内未完成加载');

    // 首屏稳定后再等一帧，避免把布局抖动计入启动时间。
    await tester.pump(const Duration(milliseconds: 300));

    final searchReady = await _waitFor(
      tester,
      () => find.byTooltip('搜索知识点').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 20),
    );
    expect(searchReady, isTrue, reason: '没有找到搜索入口');

    expect(find.byTooltip('搜索知识点'), findsWidgets);
    await tester.tap(find.byTooltip('搜索知识点').first);
    await _waitFor(
      tester,
      () => find.byType(TextField).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 20),
    );
    expect(find.byType(TextField), findsWidgets);

    final firstSearchWatch = Stopwatch()..start();
    await tester.enterText(find.byType(TextField).first, '函数');
    final firstHits = await _waitFor(
      tester,
      () => find.byType(Card).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
      interval: const Duration(milliseconds: 100),
    );
    firstSearchWatch.stop();
    expect(firstHits, isTrue, reason: '首次搜索 60 秒内没有结果');

    final secondSearchWatch = Stopwatch()..start();
    await tester.enterText(find.byType(TextField).first, '网络');
    final secondHits = await _waitFor(
      tester,
      () => find.byType(Card).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 20),
      interval: const Duration(milliseconds: 100),
    );
    secondSearchWatch.stop();
    expect(secondHits, isTrue, reason: '二次搜索 20 秒内没有结果');

    final report = <String, Object>{
      'platform': 'android',
      'startup_ms': startupWatch.elapsedMilliseconds,
      'first_search_ms': firstSearchWatch.elapsedMilliseconds,
      'second_search_ms': secondSearchWatch.elapsedMilliseconds,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
    };
    // CI 从测试输出里抓取这一行并归档。
    debugPrint('PERF_BASELINE_JSON=${jsonEncode(report)}');

    // 数量级门禁：明显慢于这些阈值时视为回归。
    expect(startupWatch.elapsedMilliseconds, lessThan(90000));
    expect(firstSearchWatch.elapsedMilliseconds, lessThan(60000));
    expect(secondSearchWatch.elapsedMilliseconds, lessThan(20000));
  });
}
