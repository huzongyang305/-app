import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  Future<void> settleWithIo(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.byType(Scrollable).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openFirstLesson(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('课程分类'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python 第一个脚本'));
    await settleWithIo(tester);
  }

  testWidgets('P2 无障碍语义和手机导航', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      CodeLearnApp(
        storage: StorageService.inMemory(),
        contentProvider: content,
      ),
    );
    await settleWithIo(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.bySemanticsLabel('主导航'), findsOneWidget);

    await openFirstLesson(tester);
    await tester.tap(find.text('开始测验'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'选项 A：')), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('P2 平板导航、教程分栏和横屏答题布局', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CodeLearnApp(
        storage: StorageService.inMemory(),
        contentProvider: content,
      ),
    );
    await settleWithIo(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await openFirstLesson(tester);
    expect(find.byKey(const ValueKey('lesson-wide-layout')), findsOneWidget);

    await tester.tap(find.text('开始测验'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quiz-wide-layout')), findsOneWidget);
  });

  testWidgets('P2 教程页提供离线朗读入口并在不可用时提示', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      CodeLearnApp(
        storage: StorageService.inMemory(),
        contentProvider: content,
      ),
    );
    await settleWithIo(tester);
    await openFirstLesson(tester);

    expect(find.byTooltip('朗读正文'), findsOneWidget);
    await tester.tap(find.byTooltip('朗读正文'));
    await settleWithIo(tester);

    // 测试环境没有原生 TTS，应给出可理解的降级提示而不是抛异常。
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('朗读引擎'), findsOneWidget);
  });
}
