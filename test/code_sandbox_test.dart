import 'dart:convert';

import 'package:code_learn_app/models/sandbox_language.dart';
import 'package:code_learn_app/models/sandbox_output.dart';
import 'package:code_learn_app/screens/code_sandbox_screen.dart';
import 'package:code_learn_app/screens/lesson_screen.dart';
import 'package:code_learn_app/services/code_sandbox_service.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/snippet_service.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:code_learn_app/widgets/code_block.dart';
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

  test('新增语言都带示例库，stdin 支持标记正确', () {
    for (final id in <String>['scheme', 'markdown', 'regex', 'xml', 'csv']) {
      final language = SandboxLanguage.fromId(id);
      expect(language.examples, isNotEmpty, reason: '$id 缺少示例');
      expect(language.sampleCode.trim(), isNotEmpty, reason: '$id 缺少默认代码');
    }
    expect(SandboxLanguage.scheme.supportsStdin, isTrue);
    expect(SandboxLanguage.python.supportsStdin, isTrue);
    expect(SandboxLanguage.lua.supportsStdin, isTrue);
    expect(SandboxLanguage.markdown.supportsStdin, isFalse);
  });

  test('片段库支持保存、收藏、按语言检索与删除', () async {
    final storage = StorageService.inMemory();
    final service = SnippetService(storage);
    expect(service.snippets, isEmpty);

    await service.upsert(
      languageId: 'python',
      title: '词频统计',
      code: 'print("hi")',
      stdin: '小明 92',
      now: DateTime(2026, 1, 1, 10),
    );
    await service.upsert(
      languageId: 'javascript',
      title: '平方和',
      code: 'console.log(1)',
      now: DateTime(2026, 1, 2, 10),
    );
    expect(service.length, 2);
    expect(service.forLanguage('python').single.stdin, '小明 92');

    final id = service.forLanguage('python').single.id;
    await service.toggleFavorite(id);
    expect(service.snippets.first.id, id, reason: '收藏的片段排在最前');

    await service.remove(id);
    expect(service.length, 1);

    // 重新构造服务验证持久化。
    final restored = SnippetService(storage);
    expect(restored.length, 1);
    expect(restored.snippets.single.title, '平方和');
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
      SandboxLanguage.scheme: 1,
      SandboxLanguage.markdown: 0,
      SandboxLanguage.regex: 0,
      SandboxLanguage.xml: 0,
      SandboxLanguage.csv: 0,
      SandboxLanguage.cpp: 1,
      SandboxLanguage.bash: 1,
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
      'assets/sandbox/biwascheme/biwascheme-min.js',
      'assets/sandbox/jscpp/jscpp.bundle.js',
      'assets/sandbox/bash/bashkit.bundle.js',
    ];
    for (final path in runtimes) {
      final content = await rootBundle.loadString(path);
      expect(content.length, greaterThan(1000), reason: '$path 内容异常');
    }
    // Bash 运行时是二进制 WebAssembly，单独校验体积。
    final wasm = await rootBundle.load('assets/sandbox/bash/bashkit.wasm');
    expect(wasm.lengthInBytes, greaterThan(1000000));
  });

  test('教程代码块围栏语言能正确映射到沙箱语言', () {
    expect(SandboxLanguage.tryFromFence('python'), SandboxLanguage.python);
    expect(SandboxLanguage.tryFromFence('py'), SandboxLanguage.python);
    expect(SandboxLanguage.tryFromFence('js'), SandboxLanguage.javascript);
    expect(SandboxLanguage.tryFromFence('C++'), SandboxLanguage.cpp);
    expect(SandboxLanguage.tryFromFence('c'), SandboxLanguage.cpp);
    expect(SandboxLanguage.tryFromFence('bash'), SandboxLanguage.bash);
    expect(SandboxLanguage.tryFromFence('sh'), SandboxLanguage.bash);
    expect(SandboxLanguage.tryFromFence('sql'), SandboxLanguage.sql);
    expect(SandboxLanguage.tryFromFence('markdown'), SandboxLanguage.markdown);
    // 教学模式语言同样要能映射，才能进入沙箱做静态追踪。
    expect(SandboxLanguage.tryFromFence('java'), SandboxLanguage.java);
    expect(SandboxLanguage.tryFromFence('csharp'), SandboxLanguage.csharp);
    expect(SandboxLanguage.tryFromFence('c#'), SandboxLanguage.csharp);
    expect(SandboxLanguage.tryFromFence('dart'), SandboxLanguage.dart);
    expect(SandboxLanguage.tryFromFence('go'), SandboxLanguage.golang);
    expect(SandboxLanguage.tryFromFence('rs'), SandboxLanguage.rust);
    expect(SandboxLanguage.tryFromFence('kotlin'), SandboxLanguage.kotlin);
    expect(SandboxLanguage.tryFromFence('swift'), SandboxLanguage.swift);
    // 完全未映射的语言必须返回 null，界面据此给出提示。
    expect(SandboxLanguage.tryFromFence('haskell'), isNull);
    expect(SandboxLanguage.tryFromFence('ruby'), isNull);
    expect(SandboxLanguage.tryFromFence(''), isNull);
  });

  test('结构化表格标记会从文本中剥离并解码', () {
    final payload = base64Encode(
      utf8.encode(
        '{"columns":["id","name"],"rows":[["1","小明"],["2","小红"]],'
        '"truncated":true}',
      ),
    );
    final parsed = SandboxStructuredOutput.parse(
      'id | name\n1 | 小明\n##SANDBOX_TABLE##$payload',
    );
    expect(parsed.text, 'id | name\n1 | 小明');
    expect(parsed.table, isNotNull);
    expect(parsed.table!.columns, ['id', 'name']);
    expect(parsed.table!.rows.length, 2);
    expect(parsed.table!.rows[0], ['1', '小明']);
    expect(parsed.table!.truncated, isTrue);
  });

  test('损坏的表格标记不会影响普通文本输出', () {
    final parsed = SandboxStructuredOutput.parse(
      'hello\n##SANDBOX_TABLE##not-base64!!',
    );
    expect(parsed.text, 'hello');
    expect(parsed.table, isNull);
  });

  test('正则沙箱输入按约定解析并计算匹配位置', () {
    final spec = SandboxRegexSpec.tryParse(
      r'\d{4}-\d{2}-\d{2}'
      '\ng\n订单 A: 2026-01-05 下单\n订单 B: 2025-12-31',
    );
    expect(spec, isNotNull);
    expect(spec!.flags, 'g');
    expect(spec.text, contains('订单 A'));
    final regex = spec.compile();
    expect(regex, isNotNull);
    final matches = regex!.allMatches(spec.text).toList();
    expect(matches.length, 2);
    expect(matches.first.group(0), '2026-01-05');
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
    final codeField = tester.widget<TextField>(find.byType(TextField).first);
    expect(codeField.controller?.text, contains('counts.get'));

    // 标准输入支持：填入两行后运行，参数应一起传给原生层。
    await tester.enterText(find.byType(TextField).at(1), '小明 92\n小红 88');
    await tester.pump();

    // 测试环境没有原生插件，应显示降级提示而不是崩溃
    await tester.scrollUntilVisible(
      find.text('运行代码'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('运行代码'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(received?.method, 'runCode');
    final arguments = (received?.arguments as Map).cast<String, Object?>();
    expect(arguments['language'], 'python');
    expect(arguments['code'], contains('counts.get'));
    expect(arguments['stdin'], contains('小明 92'));

    final output = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(output.data, 'sum = 55');
  });

  testWidgets('教程代码块可以带着代码和语言打开沙箱', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(StorageService.inMemory()),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: CodeBlock(code: 'print("hi")', language: 'python'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.terminal_rounded));
    await tester.pumpAndSettle();

    expect(find.text('代码沙箱'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller?.text, 'print("hi")');
  });

  testWidgets('暂不支持离线执行的代码块会给出明确提示', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(StorageService.inMemory()),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: CodeBlock(
                code: 'main = putStrLn "hi"',
                language: 'haskell',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.terminal_rounded));
    await tester.pump();

    expect(find.textContaining('暂不支持离线沙箱'), findsOneWidget);
    expect(find.textContaining('当前支持'), findsOneWidget);
  });

  testWidgets('教学模式语言的课程页会如实标注（不宣称真编译执行）', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = StorageService.inMemory();
    // testWidgets 运行在 FakeAsync 里，真实文件 I/O 必须放进 runAsync。
    final content = (await tester.runAsync(() async {
      final provider = ContentProvider();
      await provider.load();
      return provider;
    }))!;
    final lesson = content.allLessons.firstWhere(
      (item) => item.lab == 'sandbox:java',
      orElse: () => throw StateError('没有绑定 java 沙箱的课程'),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
          ChangeNotifierProvider(create: (_) => ProgressProvider(storage)),
          ChangeNotifierProvider<ContentProvider>.value(value: content),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: LessonScreen(lesson: lesson),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.textContaining('教学模式'),
      findsWidgets,
      reason: '教学模式语言必须在课程页标注，避免被当成真编译执行',
    );
    final labButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.school_outlined),
    );
    expect(labButton.tooltip, contains('教学模式'));
  });
}
