import 'package:code_learn_app/screens/fullscreen_code_screen.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:code_learn_app/widgets/code_block.dart';
import 'package:code_learn_app/widgets/code_block_body.dart';
import 'package:code_learn_app/widgets/markdown_code_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 代码块全屏展开：交互、剪贴板与长行布局回归测试。
void main() {
  Widget wrap(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(StorageService.inMemory()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
  }

  Future<void> setPhoneSize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('教程代码块可以全屏展开并返回', (tester) async {
    await setPhoneSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      wrap(
        const CodeBlock(
          code: 'def add(a, b):\n    return a + b\n',
          language: 'python',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FullscreenCodeScreen), findsNothing);
    await tester.tap(find.byTooltip('全屏查看代码'));
    await tester.pumpAndSettle();

    final screen = find.byType(FullscreenCodeScreen);
    expect(screen, findsOneWidget);
    expect(
      find.descendant(of: screen, matching: find.text('PYTHON')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: screen, matching: find.text('共 2 行')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: screen, matching: find.byType(HighlightView)),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('退出全屏'));
    await tester.pumpAndSettle();
    expect(find.byType(FullscreenCodeScreen), findsNothing);
    expect(find.byType(CodeBlock), findsOneWidget);
  });

  testWidgets('全屏页复制按钮写入完整代码', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await setPhoneSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      wrap(
        const FullscreenCodeScreen(code: 'print("hi")\n\n', language: 'python'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('复制'));
    await tester.pumpAndSettle();

    final copyCall = calls.firstWhere(
      (call) => call.method == 'Clipboard.setData',
    );
    expect(
      (copyCall.arguments as Map<Object?, Object?>)['text'],
      'print("hi")',
    );
    expect(find.text('代码已复制'), findsOneWidget);
  });

  testWidgets('全屏页超长代码行不溢出', (tester) async {
    await setPhoneSize(tester, const Size(390, 844));
    final longLine =
        'const data = [${List.generate(40, (i) => 'item$i').join(', ')}];';
    await tester.pumpWidget(
      wrap(FullscreenCodeScreen(code: longLine, language: 'javascript')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HighlightView), findsOneWidget);
  });

  testWidgets('全屏页在横屏短视口下正常渲染', (tester) async {
    await setPhoneSize(tester, const Size(844, 390));
    await tester.pumpWidget(
      wrap(
        FullscreenCodeScreen(
          code: List.generate(60, (i) => 'print($i)').join('\n'),
          language: 'python',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(FullscreenCodeScreen), findsOneWidget);
  });

  test('常见围栏语言显示为易读标签', () {
    expect(CodeBlockBody.displayLanguage('cpp'), 'C++');
    expect(CodeBlockBody.displayLanguage('csharp'), 'C#');
    expect(CodeBlockBody.displayLanguage('js'), 'JavaScript');
    expect(CodeBlockBody.displayLanguage('ts'), 'TypeScript');
    expect(CodeBlockBody.displayLanguage('sql'), 'SQL');
    expect(CodeBlockBody.displayLanguage(null), 'CODE');
  });

  testWidgets('Markdown 围栏代码渲染为可全屏的代码块', (tester) async {
    await setPhoneSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      wrap(
        Markdown(
          // 尾部保留段落：与真实课程一致，也避开 flutter_markdown
          // 在「文档以代码块结尾」时的内部断言。
          data:
              '示例：\n\n```cpp\nint main() { return 0; }\n```\n\n'
              '以上是完整示例。\n',
          padding: const EdgeInsets.all(20),
          builders: {'pre': CodeBlockBuilder()},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CodeBlock), findsOneWidget);
    expect(find.text('C++'), findsOneWidget);
    expect(find.byTooltip('全屏查看代码'), findsOneWidget);
  });
}
