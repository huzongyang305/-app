import 'package:code_learn_app/models/sandbox_language.dart';
import 'package:code_learn_app/screens/code_sandbox_screen.dart';
import 'package:code_learn_app/services/code_sandbox_service.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 多语言沙箱自检：语言元数据、平台降级，以及资源与原生层的标记约定。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('沙箱在当前平台不可用时安全降级', () async {
    final output = await CodeSandboxService.runJavaScript('1 + 1');
    expect(output, isNotEmpty);
  });

  test('每种语言的元数据完整', () {
    for (final language in SandboxLanguage.values) {
      expect(language.id, isNotEmpty, reason: '${language.name} 缺少语言标识');
      expect(language.labelKey, startsWith('sandboxLang'));
      expect(language.hintKey, startsWith('sandboxHint'));
      expect(
        language.sampleCode.trim(),
        isNotEmpty,
        reason: '${language.id} 缺少示例代码',
      );
      expect(language.timeout.inSeconds, greaterThan(0));
    }
  });

  test('语言标识可以双向解析，未知标识回退到 JavaScript', () {
    expect(CodeSandboxService.languages, SandboxLanguage.values);
    for (final language in CodeSandboxService.languages) {
      expect(SandboxLanguage.fromId(language.id), language);
    }
    expect(SandboxLanguage.fromId('cobol'), SandboxLanguage.javascript);
  });

  test('所有语言在无插件环境下都返回提示而不是抛异常', () async {
    for (final language in SandboxLanguage.values) {
      final output = await CodeSandboxService.runCode(
        language,
        language.sampleCode,
      );
      expect(output, isNotEmpty, reason: '${language.id} 应返回可展示的提示');
    }
  });

  test('沙箱资源齐全，且与原生层约定的标记一致', () async {
    // 与 MainActivity 的 specs 保持一致：语言 -> 内联运行时数量。
    const runtimeCounts = <SandboxLanguage, int>{
      SandboxLanguage.javascript: 0,
      SandboxLanguage.typescript: 1,
      SandboxLanguage.python: 2,
      SandboxLanguage.lua: 1,
      SandboxLanguage.sql: 2,
      SandboxLanguage.json: 0,
    };
    final common = await rootBundle.loadString(
      'assets/sandbox/harness/common.js',
    );
    expect(common, contains('SandboxBridge'));
    expect(common, contains('__sandboxBegin'));

    for (final entry in runtimeCounts.entries) {
      final harness = await rootBundle.loadString(
        'assets/sandbox/harness/${entry.key.id}.html',
      );
      expect(harness, contains('/*__COMMON__*/'));
      expect(harness, contains('__USER_CODE__'));
      for (var index = 1; index <= entry.value; index++) {
        expect(
          harness,
          contains('/*__RUNTIME_${index}__*/'),
          reason: '${entry.key.id} 缺少运行时标记 $index',
        );
      }
      expect(harness, isNot(contains('/*__RUNTIME_${entry.value + 1}__*/')));
    }
  });

  test('各语言运行时资源都已随 App 打包', () async {
    const runtimes = <String>[
      'assets/sandbox/brython/brython.js',
      'assets/sandbox/brython/brython_stdlib.js',
      'assets/sandbox/fengari/fengari-web.bundle.js',
      'assets/sandbox/sqljs/sql-wasm.js',
      'assets/sandbox/sqljs/sql-wasm-binary.js',
      'assets/sandbox/sucrase/sucrase.bundle.js',
    ];
    for (final path in runtimes) {
      final content = await rootBundle.loadString(path);
      expect(content.length, greaterThan(1000), reason: '$path 内容异常');
    }
  });

  testWidgets('沙箱页面可以切换语言并执行代码', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // 用假的原生通道记录 Dart 侧真正发出的调用参数
    const channel = MethodChannel('code_learn_app/sandbox');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return 'sum = 55';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(StorageService.inMemory()),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CodeSandboxScreen(),
        ),
      ),
    );

    expect(find.text('代码沙箱'), findsOneWidget);
    expect(find.text('JavaScript'), findsOneWidget);

    // 语言条是横向滚动的懒加载列表，先滚动到 Python 再点击
    final chipList = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.scrollUntilVisible(
      find.text('Python'),
      120,
      scrollable: find.descendant(
        of: chipList,
        matching: find.byType(Scrollable),
      ),
    );
    // 横向语言条可能只把目标滚到边缘，确保完整露出后再点击。
    await tester.ensureVisible(find.text('Python'));
    await tester.pumpAndSettle();

    // 切换语言后示例代码随之切换
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    final codeField = tester.widget<TextField>(find.byType(TextField));
    expect(codeField.controller?.text, contains('counts.get'));

    // 测试环境没有原生插件，应显示降级提示而不是崩溃
    await tester.tap(find.text('运行代码'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(received?.method, 'runCode');
    final arguments = (received?.arguments as Map).cast<String, Object?>();
    expect(arguments['language'], 'python');
    expect(arguments['code'], contains('counts.get'));

    final output = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(output.data, 'sum = 55');
  });
}
