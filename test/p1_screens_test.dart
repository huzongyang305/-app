import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:code_learn_app/screens/content_pack_workbench_screen.dart';
import 'package:code_learn_app/screens/learning_hub_screen.dart';
import 'package:code_learn_app/screens/notes_screen.dart';
import 'package:code_learn_app/screens/skill_tree_screen.dart';
import 'package:code_learn_app/services/content_pack_workbench.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';

/// P1 新增页面的冒烟测试：只关心能不能渲染、数据是否接上。
Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ContentProvider? content,
  ProgressProvider? progress,
}) async {
  final storage = StorageService.inMemory();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => progress ?? ProgressProvider(storage),
        ),
        if (content != null)
          ChangeNotifierProvider<ContentProvider>.value(value: content),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: screen,
      ),
    ),
  );
}

void main() {
  late ContentProvider content;

  // 真实资源读取要放在 testWidgets 的假时钟之外，否则会一直等待 I/O。
  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  testWidgets('学习中枢展示掌握度总览、图谱统计与推荐顺序', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpScreen(tester, const LearningHubScreen(), content: content);
    await tester.pumpAndSettle();

    expect(find.text('学习中枢'), findsOneWidget);
    expect(find.text('平均掌握度'), findsOneWidget);
    expect(find.text('知识图谱'), findsOneWidget);
    expect(find.text('推荐学习顺序'), findsOneWidget);

    // 课程有数百节；列表必须按需构建，不能一次性把全部卡片塞进 widget 树。
    expect(content.allLessons.length, greaterThan(100));
    expect(tester.widgetList(find.byType(Card)).length, lessThan(60));
  });

  testWidgets('内容包工作台可以离线校验模板并展示统计', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpScreen(tester, const ContentPackWorkbenchScreen());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      ContentPackWorkbench.template(),
    );
    await tester.tap(find.text('分析'));
    await tester.pumpAndSettle();

    expect(find.text('课程 1'), findsOneWidget);
    expect(find.text('分类 1'), findsOneWidget);
    expect(find.text('题目 1'), findsOneWidget);
    // 模板可以包含提示/警告，但不应出现错误级结果。
    expect(find.textContaining('错误'), findsNothing);
  });

  testWidgets('内容包工作台遇到非法 JSON 会给出错误而不是崩溃', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpScreen(tester, const ContentPackWorkbenchScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '{not json');
    await tester.tap(find.text('分析'));
    await tester.pumpAndSettle();

    expect(find.textContaining('JSON 解析失败'), findsOneWidget);
  });

  testWidgets('笔记导出菜单可以把 Markdown 复制到剪贴板', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final progress = ProgressProvider(StorageService.inMemory());
    final lessonId = content.allLessons.first.id;
    await tester.runAsync(
      () => progress.saveNote(lessonId, '这是导出测试笔记', tags: <String>['测试']),
    );

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? clipboardText;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = (call.arguments as Map).cast<String, Object?>();
        clipboardText = args['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await _pumpScreen(
      tester,
      const NotesScreen(),
      content: content,
      progress: progress,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('导出笔记'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出 Markdown'));
    await tester.pumpAndSettle();

    expect(clipboardText, contains('这是导出测试笔记'));
    expect(find.textContaining('已复制'), findsOneWidget);
  });

  testWidgets('技能树按真实进度展示节点，锁定节点不能开始学习', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final progress = ProgressProvider(StorageService.inMemory());
    await tester.runAsync(() => progress.markLearned('html_basics'));

    await _pumpScreen(
      tester,
      const SkillTreeScreen(),
      content: content,
      progress: progress,
    );
    await tester.pumpAndSettle();

    expect(find.text('技能树'), findsOneWidget);
    expect(find.text('总体进度'), findsOneWidget);
    expect(find.text('0 / 9 已掌握'), findsOneWidget);

    final tree = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is SkillTreePainter,
    );
    expect(tree, findsOneWidget);
    final origin = tester.getTopLeft(tree);

    // HTML/CSS 已学 1/3，可以打开详情并继续学习。
    await tester.tapAt(origin + const Offset(180, 160));
    await tester.pumpAndSettle();
    expect(find.text('HTML / CSS'), findsOneWidget);
    expect(find.text('33% · 1/3 门课已学'), findsOneWidget);
    expect(find.text('继续学习'), findsOneWidget);

    // 关闭详情，点 JavaScript：前置未掌握，按钮不可用。
    Navigator.of(tester.element(find.text('HTML / CSS'))).pop();
    await tester.pumpAndSettle();
    await tester.tapAt(origin + const Offset(180, 340));
    await tester.pumpAndSettle();
    expect(find.text('JavaScript'), findsOneWidget);
    expect(find.text('HTML / CSS · 33%'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('请先完成前置技能'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('请先完成前置技能'), findsOneWidget);
  });
}
