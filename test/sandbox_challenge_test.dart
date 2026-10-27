import 'dart:async';

import 'package:code_learn_app/data/sandbox_challenges.dart';
import 'package:code_learn_app/models/sandbox_challenge.dart';
import 'package:code_learn_app/models/sandbox_language.dart';
import 'package:code_learn_app/screens/code_sandbox_screen.dart';
import 'package:code_learn_app/services/sandbox_challenge_service.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:code_learn_app/widgets/code_editor_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 沙箱挑战模式：题库完整性、输出比对与通关记录。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('挑战输出比对', () {
    test('忽略行尾空白与首尾空行', () {
      expect(
        SandboxChallengeService.matches(actual: '42  \n', expected: '42'),
        isTrue,
      );
      expect(
        SandboxChallengeService.matches(actual: '\n1\n2\n\n', expected: '1\n2'),
        isTrue,
      );
    });

    test('统一 Windows 换行符', () {
      expect(
        SandboxChallengeService.matches(actual: 'a\r\nb', expected: 'a\nb'),
        isTrue,
      );
    });

    test('忽略 SQL 结构化表格标记行', () {
      const raw = 'total\n-----\n3\n##SANDBOX_TABLE##eyJjb2x1bW5zIjpbXX0=';
      expect(
        SandboxChallengeService.matches(
          actual: raw,
          expected: 'total\n-----\n3',
        ),
        isTrue,
      );
    });

    test('输出内容不同则不通过', () {
      expect(
        SandboxChallengeService.matches(actual: '41', expected: '42'),
        isFalse,
      );
    });

    test('可以识别运行错误输出', () {
      expect(SandboxChallengeService.looksLikeError('Error: boom'), isTrue);
      expect(SandboxChallengeService.looksLikeError('42'), isFalse);
    });
  });

  group('多用例挑战', () {
    SandboxChallenge cppAddTwo() => sandboxChallengesByLanguage['cpp']!
        .firstWhere((item) => item.id == 'cpp-add-two');

    test('cases 合并首组用例与附加用例', () {
      final challenge = cppAddTwo();
      expect(challenge.caseCount, 3);
      expect(challenge.cases.length, 3);
      expect(challenge.cases.first.stdin, '3 5');
      expect(challenge.cases.first.expectedOutput, '8');
      expect(challenge.cases[1].stdin, '-2 7');
      expect(challenge.cases[1].expectedOutput, '5');
      expect(challenge.cases[2].stdin, '100 200');
      expect(challenge.cases[2].expectedOutput, '300');
    });

    test('没有附加用例时只有一个用例', () {
      final challenge = sandboxChallengesByLanguage['javascript']!.firstWhere(
        (item) => item.id == 'js-sum-1-100',
      );
      expect(challenge.caseCount, 1);
      expect(challenge.cases, hasLength(1));
      expect(challenge.cases.single.expectedOutput, '5050');
    });

    test('passedCaseCount 逐条统计，passesAll 要求全部一致', () {
      final challenge = cppAddTwo();
      expect(
        SandboxChallengeService.passedCaseCount(
          challenge: challenge,
          actualOutputs: const ['8', '5', '300'],
        ),
        3,
      );
      expect(
        SandboxChallengeService.passesAll(
          challenge: challenge,
          actualOutputs: const ['8', '5', '300'],
        ),
        isTrue,
      );
      expect(
        SandboxChallengeService.passedCaseCount(
          challenge: challenge,
          actualOutputs: const ['8', '6', '300'],
        ),
        2,
      );
      expect(
        SandboxChallengeService.passesAll(
          challenge: challenge,
          actualOutputs: const ['8', '6', '300'],
        ),
        isFalse,
      );
      // 少跑一组用例不能算通过。
      expect(
        SandboxChallengeService.passesAll(
          challenge: challenge,
          actualOutputs: const ['8', '5'],
        ),
        isFalse,
      );
    });
  });

  group('挑战题库', () {
    test('至少覆盖 6 种有真实运行时的语言', () {
      expect(sandboxChallengesByLanguage.length, greaterThanOrEqualTo(6));
      for (final entry in sandboxChallengesByLanguage.entries) {
        final language = SandboxLanguage.tryFromId(entry.key);
        expect(language, isNotNull, reason: '未知语言：${entry.key}');
        expect(
          language!.isTraceOnly,
          isFalse,
          reason: '静态追踪语言不应配置挑战：${entry.key}',
        );
        expect(entry.value, isNotEmpty, reason: '${entry.key} 挑战为空');
      }
    });

    test('挑战 ID 唯一且字段完整', () {
      final ids = <String>{};
      for (final entry in sandboxChallengesByLanguage.entries) {
        for (final challenge in entry.value) {
          expect(
            ids.add(challenge.id),
            isTrue,
            reason: '挑战 ID 重复：${challenge.id}',
          );
          expect(challenge.title.zh.trim(), isNotEmpty);
          expect(challenge.title.en.trim(), isNotEmpty);
          expect(challenge.prompt.zh.trim(), isNotEmpty);
          expect(challenge.starterCode.trim(), isNotEmpty);
          expect(challenge.expectedOutput.trim(), isNotEmpty);
          for (final testCase in challenge.cases) {
            expect(
              testCase.expectedOutput.trim(),
              isNotEmpty,
              reason: '${challenge.id} 存在空的期望输出',
            );
          }
        }
      }
    });

    test('预置标准输入不会向程序输出插入宿主提示', () async {
      // 挑战按整段输出比对，页面自己打印的提示会让正确答案也判负。
      for (final id in const ['javascript', 'typescript', 'cpp']) {
        final harness = await rootBundle.loadString(
          'assets/sandbox/harness/$id.html',
        );
        expect(
          harness,
          isNot(contains('已预置')),
          reason: '$id 模板不应把预置 stdin 的提示写进程序输出',
        );
      }
    });

    test('素数挑战的输入让骨架代码必然判负', () {
      final challenge = sandboxChallengesByLanguage['python']!.firstWhere(
        (item) => item.id == 'py-prime-check',
      );
      // 骨架先按 n > 1 预设 is_prime 并直接打印；输入必须是非素数，
      // 否则一行不改也能通过（原来 stdin=17 / 期望 True 就有这个问题）。
      expect(challenge.starterCode, contains('is_prime = n > 1'));
      expect(challenge.starterCode, contains('print(is_prime)'));
      final n = int.parse(challenge.stdin.trim());
      expect(_isPrime(n), isFalse, reason: '输入必须是非素数，骨架才会输出错误的 True');
      expect(challenge.expectedOutput.trim(), 'False');
    });

    test('静态追踪模式的语言没有挑战', () {
      for (final language in SandboxLanguage.values.where(
        (l) => l.isTraceOnly,
      )) {
        expect(
          language.challenges,
          isEmpty,
          reason: '${language.id} 是静态追踪模式，不应有挑战',
        );
      }
    });
  });

  group('挑战通关记录', () {
    test('通过记录写入本地并可清空', () async {
      final storage = StorageService.inMemory();
      final settings = SettingsProvider(storage);
      expect(settings.isSandboxChallengePassed('js-sum-1-100'), isFalse);

      await settings.markSandboxChallengePassed('js-sum-1-100');
      expect(settings.isSandboxChallengePassed('js-sum-1-100'), isTrue);
      expect(settings.passedSandboxChallenges, contains('js-sum-1-100'));

      // 新实例应从本地读回记录。
      final restored = SettingsProvider(storage);
      expect(restored.isSandboxChallengePassed('js-sum-1-100'), isTrue);

      await restored.resetSandboxChallengeProgress();
      expect(restored.passedSandboxChallenges, isEmpty);
      expect(SettingsProvider(storage).passedSandboxChallenges, isEmpty);
    });
  });

  testWidgets('沙箱页面可以进入挑战、运行测试用例并记录通关', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // 假的原生通道：挑战要求输出 5050，这里直接返回正确结果。
    const channel = MethodChannel('code_learn_app/sandbox');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'runCode') return '5050';
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final storage = StorageService.inMemory();
    final settings = SettingsProvider(storage);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CodeSandboxScreen(),
        ),
      ),
    );

    // 打开挑战选择面板。
    await tester.tap(find.textContaining('挑战模式'));
    await tester.pumpAndSettle();
    expect(find.text('选择挑战'), findsOneWidget);

    // 选择「1 到 100 求和」。
    await tester.tap(find.text('1 到 100 求和'));
    await tester.pumpAndSettle();

    // 挑战卡出现，起始代码替换了编辑器内容。
    expect(find.text('期望输出'), findsOneWidget);
    expect(find.text('填入起始代码'), findsOneWidget);
    final editor = tester.widget<TextField>(
      find.descendant(
        of: find.byType(CodeEditorField),
        matching: find.byType(TextField),
      ),
    );
    expect(editor.controller?.text, contains('TODO'));

    // 运行测试用例：输出与期望一致，记录通关。
    await tester.tap(find.text('运行测试用例'));
    await tester.pumpAndSettle();
    expect(find.text('已通过'), findsOneWidget);
    expect(settings.isSandboxChallengePassed('js-sum-1-100'), isTrue);
  });

  testWidgets('多用例挑战逐条运行并只在全部通过时记录通关', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    const channel = MethodChannel('code_learn_app/sandbox');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final stdins = <String?>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'runCode') return null;
      final args = (call.arguments as Map).cast<String, Object?>();
      final stdin = args['stdin'] as String?;
      stdins.add(stdin);
      switch (stdin?.trim()) {
        case '3 5':
          return '8';
        case '-2 7':
          return '6'; // 故意错一组，验证不会误判通关。
        case '100 200':
          return '300';
      }
      return '';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final storage = StorageService.inMemory();
    final settings = SettingsProvider(storage);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CodeSandboxScreen(initialChallengeId: 'cpp-add-two'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试用例（3 个）'), findsOneWidget);
    expect(find.text('用例 1'), findsOneWidget);
    expect(find.text('用例 2'), findsOneWidget);
    expect(find.text('用例 3'), findsOneWidget);

    await tester.ensureVisible(find.text('运行测试用例'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行测试用例'));
    await tester.pumpAndSettle();

    expect(stdins, ['3 5', '-2 7', '100 200']);
    expect(find.text('本次通过 2/3 个用例'), findsOneWidget);
    expect(find.text('未通过'), findsWidgets);
    expect(settings.isSandboxChallengePassed('cpp-add-two'), isFalse);

    // 修正后三组全对，才记录通关。
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'runCode') return null;
      final args = (call.arguments as Map).cast<String, Object?>();
      switch ((args['stdin'] as String? ?? '').trim()) {
        case '3 5':
          return '8';
        case '-2 7':
          return '5';
        case '100 200':
          return '300';
      }
      return '';
    });
    await tester.ensureVisible(find.text('运行测试用例'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行测试用例'));
    await tester.pumpAndSettle();

    expect(find.text('已通过'), findsWidgets);
    expect(find.text('全部测试用例通过'), findsOneWidget);
    expect(settings.isSandboxChallengePassed('cpp-add-two'), isTrue);
  });

  testWidgets('运行中锁定编辑器与写入菜单，并沿用一个代码快照', (tester) async {
    // 挑战卡片较高，画面放足够大才能让下方编辑器一起构建出来。
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    const channel = MethodChannel('code_learn_app/sandbox');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final codes = <String?>[];
    final firstRun = Completer<String>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'runCode') return null;
      final args = (call.arguments as Map).cast<String, Object?>();
      codes.add(args['code'] as String?);
      if (codes.length == 1) return firstRun.future;
      switch ((args['stdin'] as String? ?? '').trim()) {
        case '-2 7':
          return '5';
        case '100 200':
          return '300';
      }
      return '';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    final storage = StorageService.inMemory();
    final settings = SettingsProvider(storage);
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CodeSandboxScreen(initialChallengeId: 'cpp-add-two'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final editor = find.descendant(
      of: find.byType(CodeEditorField),
      matching: find.byType(TextField),
    );
    final codeController = tester.widget<TextField>(editor).controller!;
    final original = codeController.text;

    await tester.ensureVisible(find.text('运行测试用例'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('运行测试用例'));
    await tester.pump();

    expect(codes, hasLength(1));
    expect(tester.widget<TextField>(editor).readOnly, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).readOnly,
      isTrue,
    );

    // 运行中「更多」里的写操作全部禁用，避免改代码或重置。
    await tester.ensureVisible(find.byTooltip('更多操作'));
    await tester.pump();
    await tester.tap(find.byTooltip('更多操作'));
    await tester.pump(const Duration(milliseconds: 300));
    for (final value in const ['clear', 'reset', 'clearDrafts']) {
      final item = tester.widget<PopupMenuItem<String>>(
        find.byWidgetPredicate(
          (widget) => widget is PopupMenuItem<String> && widget.value == value,
        ),
      );
      expect(item.enabled, isFalse, reason: '$value 应在运行中禁用');
    }
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 300));

    // 即使控制器被程序性改写，后续用例仍应执行运行前的快照。
    codeController.text = 'MUTATED';
    firstRun.complete('8');
    await tester.pumpAndSettle();

    expect(codes, hasLength(3));
    expect(codes.every((code) => code == original), isTrue);
    expect(settings.isSandboxChallengePassed('cpp-add-two'), isTrue);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('静态追踪语言给出无挑战提示', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(StorageService.inMemory()),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CodeSandboxScreen(initialLanguageId: 'java'),
        ),
      ),
    );

    await tester.ensureVisible(find.text('挑战模式'));
    await tester.pumpAndSettle();
    // chip 位于列表底部，命中点会被列表裁剪，但 InkWell 仍能响应。
    await tester.tap(find.text('挑战模式'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('当前语言暂无挑战用例'), findsOneWidget);
  });
}

bool _isPrime(int n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}
