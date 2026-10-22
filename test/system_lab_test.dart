import 'package:code_learn_app/screens/system_lab_screen.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 系统机制演示页测试：手机宽度渲染、步骤推进与模式切换。
void main() {
  Future<void> pumpLab(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(StorageService.inMemory()),
        child: const MaterialApp(home: SystemLabScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('手机宽度下渲染 HTTP 请求链路首步', (tester) async {
    await pumpLab(tester);

    expect(find.text('系统机制演示'), findsOneWidget);
    expect(find.text('HTTP 请求链路'), findsWidgets);
    expect(find.text('第 1/6 步'), findsOneWidget);
    expect(find.text('1. DNS 解析'), findsWidgets);
  });

  testWidgets('下一步会推进步骤并在末步给出完成提示', (tester) async {
    await pumpLab(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('下一步'));
      await tester.pumpAndSettle();
    }

    expect(find.text('第 6/6 步'), findsOneWidget);
    expect(find.text('流程演示完成'), findsOneWidget);
    expect(find.byTooltip('下一步'), findsOneWidget);
  });

  testWidgets('上一步与重新播放会回到正确位置', (tester) async {
    await pumpLab(tester);

    await tester.tap(find.byTooltip('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('第 2/6 步'), findsOneWidget);

    await tester.tap(find.byTooltip('上一步'));
    await tester.pumpAndSettle();
    expect(find.text('第 1/6 步'), findsOneWidget);

    await tester.tap(find.byTooltip('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('重新播放'));
    await tester.pumpAndSettle();
    expect(find.text('第 1/6 步'), findsOneWidget);
  });

  testWidgets('可以切换到数据库事务隔离演示', (tester) async {
    await pumpLab(tester);

    await tester.tap(find.text('数据库事务与隔离'));
    await tester.pumpAndSettle();

    expect(find.text('第 1/7 步'), findsOneWidget);
    expect(find.text('1. 事务 T1 开始'), findsWidgets);
  });

  testWidgets('平板宽度与减少动画设置下仍可渲染', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            SettingsProvider(StorageService.inMemory())..setReduceMotion(true),
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(home: SystemLabScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SystemLabScreen), findsOneWidget);
    expect(find.text('流程时间线'), findsOneWidget);
  });
}
