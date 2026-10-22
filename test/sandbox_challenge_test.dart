import 'package:code_learn_app/data/sandbox_challenges.dart';
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
        }
      }
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
