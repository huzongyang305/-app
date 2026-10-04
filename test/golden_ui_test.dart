import 'dart:io' show Platform;

import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pumpApp(WidgetTester tester, Key key) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CodeLearnApp(
          storage: StorageService.inMemory(),
          contentProvider: content,
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
}
