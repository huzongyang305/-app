import 'package:code_learn_app/screens/code_sandbox_screen.dart';
import 'package:code_learn_app/services/sandbox_draft_service.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:code_learn_app/widgets/code_editor_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 沙箱草稿：按语言保存代码与标准输入，重新打开页面后自动恢复。
void main() {
  group('草稿存储', () {
    test('按语言保存、读取并删除', () async {
      final storage = StorageService.inMemory();
      final service = SandboxDraftService(storage);
      expect(service.isEmpty, isTrue);

      await service.save('python', code: 'print(1)', stdin: '1\n2');
      await service.save('javascript', code: 'console.log(1)');

      final python = service.forLanguage('python');
      expect(python, isNotNull);
      expect(python!.code, 'print(1)');
      expect(python.stdin, '1\n2');
      expect(service.length, 2);

      // 新实例从同一份本地存储读回。
      final restored = SandboxDraftService(storage);
      expect(restored.forLanguage('javascript')?.code, 'console.log(1)');

      await restored.remove('python');
      expect(restored.forLanguage('python'), isNull);
      expect(restored.length, 1);

      await restored.clear();
      expect(restored.isEmpty, isTrue);
      expect(storage.keys, isNot(contains(SandboxDraftService.storageKey)));
    });

    test('空内容不写入草稿', () async {
      final storage = StorageService.inMemory();
      final service = SandboxDraftService(storage);
      await service.save('python', code: '   ', stdin: '\n');
      expect(service.isEmpty, isTrue);
      expect(storage.keys, isNot(contains(SandboxDraftService.storageKey)));
    });

    test('本地数据损坏时按无草稿处理', () async {
      final storage = StorageService.inMemory();
      await storage.write(SandboxDraftService.storageKey, '{not json');
      final service = SandboxDraftService(storage);
      expect(service.isEmpty, isTrue);
      expect(service.forLanguage('python'), isNull);
    });

    test('忽略缺少代码的无效条目', () async {
      final storage = StorageService.inMemory();
      await storage.write(
        SandboxDraftService.storageKey,
        '{"python":{"stdin":"1"},"lua":{"code":"print(1)","stdin":""}}',
      );
      final service = SandboxDraftService(storage);
      expect(service.length, 1);
      expect(service.forLanguage('python'), isNull);
      expect(service.forLanguage('lua')?.code, 'print(1)');
    });
  });

  testWidgets('重新打开沙箱会恢复上次编辑与标准输入', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final storage = StorageService.inMemory();
    final settings = SettingsProvider(storage);

    Widget buildScreen() => MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        Provider<StorageService>.value(value: storage),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const CodeSandboxScreen(),
      ),
    );

    Finder editor() => find.descendant(
      of: find.byType(CodeEditorField),
      matching: find.byType(TextField),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    await tester.enterText(editor(), 'const answer = 42;');
    await tester.enterText(find.byType(TextField).at(1), '1 2 3');
    // 超过 400ms 的防抖窗口，让草稿真正落盘。
    await tester.pump(const Duration(milliseconds: 600));

    // 离开页面会同步保存并销毁计时器。
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    final controller = tester.widget<TextField>(editor()).controller;
    expect(controller?.text, 'const answer = 42;');
    final stdinField = tester.widget<TextField>(
      find.byType(TextField).at(1),
    );
    expect(stdinField.controller?.text, '1 2 3');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('恢复示例会删除该语言的本地草稿', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final storage = StorageService.inMemory();
    final store = SandboxDraftService(storage);
    await store.save('javascript', code: 'console.log("draft")');

    final settings = SettingsProvider(storage);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          Provider<StorageService>.value(value: storage),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CodeSandboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('更多操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('恢复示例代码'));
    await tester.pumpAndSettle();

    expect(store.forLanguage('javascript'), isNull);
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byType(CodeEditorField),
              matching: find.byType(TextField),
            ),
          )
          .controller
          ?.text,
      contains('计算 1~10 的平方和'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
