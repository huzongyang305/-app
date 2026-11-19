import 'package:code_learn_app/l10n/app_strings.dart';
import 'package:code_learn_app/models/backup_preview.dart';
import 'package:code_learn_app/models/custom_question.dart';
import 'package:code_learn_app/models/flashcard.dart';
import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/models/review_grade.dart';
import 'package:code_learn_app/screens/ocr_capture_screen.dart';
import 'package:code_learn_app/screens/wrong_answer_screen.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/flashcard_service.dart';
import 'package:code_learn_app/services/ocr_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

/// 假识别通道：按脚本返回文本或抛错，模拟 ML Kit 的各种结局。
void _stubChannel(Future<Object?> Function(MethodCall call)? handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel(OcrService.channelName),
        handler,
      );
}

Lesson _emptyLesson() => const Lesson(
  id: 'l1',
  categoryId: 'c1',
  title: LocalizedText(zh: '闭包', en: 'Closure'),
  summary: LocalizedText(zh: '闭包课程', en: 'Closure lesson'),
  assetFile: 'test.md',
  minutes: 10,
  keywords: <String>['闭包'],
  quiz: <QuizQuestion>[],
);

CustomQuestion _question(String id, {String answer = 'B'}) => CustomQuestion(
  id: id,
  question: '$id 的题干',
  answer: answer,
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
);

Widget _app(Widget child, ProgressProvider progress) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ProgressProvider>.value(value: progress),
    ChangeNotifierProvider<SettingsProvider>(
      create: (_) => SettingsProvider(StorageService.inMemory()),
    ),
  ],
  child: MaterialApp(theme: AppTheme.light(), home: child),
);

void main() {
  const strings = AppStrings('zh');

  group('识别文本切分', () {
    test('按行首标记拆成题干 / 答案 / 解析', () {
      final result = suggestFromOcr('下列说法正确的是？\nA. 甲\nB. 乙\n答案：B\n解析：B 项正确。');
      expect(result.question, '下列说法正确的是？\nA. 甲\nB. 乙');
      expect(result.answer, 'B');
      expect(result.explanation, 'B 项正确。');
    });

    test('没有任何标记时整段并入题干', () {
      final result = suggestFromOcr('只有一句题干。\n第二行还是题干。');
      expect(result.question, '只有一句题干。\n第二行还是题干。');
      expect(result.answer, '');
      expect(result.explanation, '');
    });

    test('标记之后的同行内容不丢，空行与 CRLF 被忽略', () {
      final result = suggestFromOcr('题干\r\n\r\n正确答案: B 项\r\n详解 因为……');
      expect(result.question, '题干');
      expect(result.answer, 'B 项');
      expect(result.explanation, '因为……');
    });

    test('英文标记同样识别', () {
      final result = suggestFromOcr(
        'Which is right?\nAnswer: B\nExplanation: B is correct.',
      );
      expect(result.question, 'Which is right?');
      expect(result.answer, 'B');
      expect(result.explanation, 'B is correct.');
    });

    test('每段超长时截断到 2000 字', () {
      final long = '甲' * 2500;
      final result = suggestFromOcr('$long\n答案：${'乙' * 2500}');
      expect(result.question.length, 2000);
      expect(result.answer.length, 2000);
    });
  });

  group('识别通道降级', () {
    tearDown(() => _stubChannel(null));

    test('识别到文字返回 ok 并带回图片路径', () async {
      _stubChannel((call) async {
        expect(call.method, 'recognizeText');
        return '题干\n答案：A';
      });
      final service = OcrService();
      final outcome = await service.recognize('/tmp/p.jpg');
      expect(outcome.status, OcrStatus.ok);
      expect(outcome.hasText, isTrue);
      expect(outcome.imagePath, '/tmp/p.jpg');
      expect(service.isAvailable, isTrue);
    });

    test('空白结果判定为 empty，仍然算本机可用', () async {
      _stubChannel((call) async => '   ');
      final service = OcrService();
      final outcome = await service.recognize('/tmp/p.jpg');
      expect(outcome.status, OcrStatus.empty);
      expect(outcome.hasText, isFalse);
      expect(service.isAvailable, isTrue);
    });

    test('没有 handler 时降级 unavailable 并记住不再尝试', () async {
      _stubChannel(null);
      final service = OcrService();
      final outcome = await service.recognize('/tmp/p.jpg');
      expect(outcome.status, OcrStatus.unavailable);
      expect(service.isAvailable, isFalse);
    });

    test('原生抛错降级 failed', () async {
      _stubChannel((call) async => throw PlatformException(code: 'ocr_failed'));
      final outcome = await OcrService().recognize('/tmp/p.jpg');
      expect(outcome.status, OcrStatus.failed);
    });

    test('路径为空直接 failed，不触碰通道', () async {
      var called = false;
      _stubChannel((call) async {
        called = true;
        return 'x';
      });
      expect(
        (await OcrService().recognize('')).status,
        OcrStatus.failed,
        reason: '空路径不该发通道调用',
      );
      expect(called, isFalse);
    });

    test('capture 串起选图与识别；取消选择返回 null', () async {
      _stubChannel((call) async => '题干\n答案：C');
      final picked = <ImageSource>[];
      final service = OcrService(
        pick: (source) async {
          picked.add(source);
          return XFile('/tmp/shot.jpg');
        },
      );
      final outcome = await service.capture(source: ImageSource.camera);
      expect(picked, [ImageSource.camera]);
      expect(outcome?.status, OcrStatus.ok);
      expect(outcome?.imagePath, '/tmp/shot.jpg');

      final cancelled = OcrService(pick: (source) async => null);
      expect(await cancelled.capture(source: ImageSource.gallery), isNull);
    });

    test('选图失败返回 failed', () async {
      final service = OcrService(
        pick: (source) async => throw PlatformException(code: 'picker_denied'),
      );
      expect(
        (await service.capture(source: ImageSource.camera))?.status,
        OcrStatus.failed,
      );
    });
  });

  group('自录错题存取', () {
    late StorageService storage;
    late ProgressProvider progress;

    setUp(() {
      storage = StorageService.inMemory();
      progress = ProgressProvider(storage);
    });

    test('题干或答案缺一就不入库', () async {
      expect(
        await progress.addCustomQuestion(question: '只有一句', answer: ''),
        isNull,
      );
      expect(
        await progress.addCustomQuestion(question: '  ', answer: 'B'),
        isNull,
      );
      expect(progress.customQuestionCount, 0);
    });

    test('收录、更新、删除都能读回', () async {
      final saved = await progress.addCustomQuestion(
        question: '下列正确的是？',
        answer: 'B',
        explanation: 'B 项正确。',
      );
      expect(saved, isNotNull);
      expect(progress.customQuestionCount, 1);
      expect(progress.customQuestionOf(saved!.id)?.question, '下列正确的是？');
      expect(storage.read('custom_q_${saved.id}'), isNotNull);

      await progress.updateCustomQuestion(
        saved.id,
        question: '改过的题干',
        answer: 'C',
        explanation: '',
      );
      final updated = progress.customQuestionOf(saved.id)!;
      expect(updated.question, '改过的题干');
      expect(updated.answer, 'C');
      expect(updated.explanation, '');
      expect(updated.createdAt, saved.createdAt);

      await progress.updateCustomQuestion(
        saved.id,
        question: '   ',
        answer: 'C',
        explanation: '',
      );
      expect(
        progress.customQuestionOf(saved.id)!.question,
        '改过的题干',
        reason: '清空题干不该覆盖原记录',
      );

      await progress.deleteCustomQuestion(saved.id);
      expect(progress.customQuestionCount, 0);
      expect(storage.read('custom_q_${saved.id}'), isNull);
      expect(storage.read('all_custom_question_ids'), isEmpty);
    });

    test('新 provider 从本地存储恢复，无效记录被丢弃', () async {
      await progress.addCustomQuestion(question: '第一题', answer: 'A');
      await storage.write('custom_q_broken', <String, dynamic>{
        'id': 'broken',
        'question': '没有答案',
        'answer': '',
      });
      final ids = <String>[
        ...(storage.read('all_custom_question_ids') as List).cast<String>(),
        'broken',
      ];
      await storage.write('all_custom_question_ids', ids);

      final restarted = ProgressProvider(storage);
      expect(restarted.customQuestionCount, 1);
      expect(restarted.customQuestions['broken'], isNull);
    });

    test('按更新时间倒序返回', () async {
      await storage.write('all_custom_question_ids', <String>['old', 'new']);
      await storage.write('custom_q_old', _question('old').toJson());
      await storage.write(
        'custom_q_new',
        CustomQuestion(
          id: 'new',
          question: '新收录',
          answer: 'A',
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 18),
        ).toJson(),
      );
      final restored = ProgressProvider(storage);
      expect(
        restored.customQuestionsNewestFirst.map((item) => item.id).toList(),
        <String>['new', 'old'],
      );
    });

    test('删除时一并清掉该卡的闪卡排期，重启后也不会复活', () async {
      final saved = await progress.addCustomQuestion(
        question: '要删的题',
        answer: 'B',
      );
      await progress.scheduleFlashcardWithGrade(
        'custom:${saved!.id}',
        ReviewGrade.remembered,
      );
      expect(progress.flashcardDueAt('custom:${saved.id}'), isNotNull);

      await progress.deleteCustomQuestion(saved.id);
      expect(progress.flashcardDueAt('custom:${saved.id}'), isNull);
      expect(progress.flashcardRepetitionsOf('custom:${saved.id}'), 0);
      expect(
        storage.read('flashcard_due'),
        isNot(contains('custom:${saved.id}')),
        reason: '排期表要整体落盘，否则重启后又计入待复习',
      );

      final restarted = ProgressProvider(storage);
      expect(restarted.flashcardDueAt('custom:${saved.id}'), isNull);
    });

    test('备份导出后可在另一台设备还原', () async {
      await progress.addCustomQuestion(
        question: '导出题',
        answer: 'A',
        explanation: '因为甲',
      );
      final dump = progress.exportData();
      final restored = ProgressProvider(StorageService.inMemory());
      await restored.importData(dump, writeSnapshot: false);
      expect(restored.customQuestionCount, 1);
      final item = restored.customQuestions.values.single;
      expect(item.question, '导出题');
      expect(item.explanation, '因为甲');
    });

    test('合并导入：同 ID 取较新的一份，并保留两端独有记录', () async {
      await storage.write('all_custom_question_ids', <String>['a', 'shared']);
      await storage.write('custom_q_a', _question('a').toJson());
      await storage.write(
        'custom_q_shared',
        CustomQuestion(
          id: 'shared',
          question: '本机版本',
          answer: 'A',
          createdAt: DateTime(2026, 11, 1),
          updatedAt: DateTime(2026, 11, 2),
        ).toJson(),
      );
      final local = ProgressProvider(storage);

      final remote = <String, dynamic>{
        'custom_questions': <String, dynamic>{
          'shared': <String, dynamic>{
            'id': 'shared',
            'question': '另一台设备的版本',
            'answer': 'B',
            'createdAt': DateTime(2026, 11, 1).toIso8601String(),
            'updatedAt': DateTime(2026, 11, 9).toIso8601String(),
          },
          'onlyRemote': <String, dynamic>{
            'id': 'onlyRemote',
            'question': '只在另一台设备上',
            'answer': 'C',
            'createdAt': DateTime(2026, 11, 8).toIso8601String(),
            'updatedAt': DateTime(2026, 11, 8).toIso8601String(),
          },
          'broken': <String, dynamic>{
            'id': 'broken',
            'question': '缺答案',
            'answer': '',
          },
        },
      };
      await local.importData(remote, mode: BackupImportMode.merge);

      final merged = local.customQuestions;
      expect(merged.keys.toSet(), <String>{'a', 'shared', 'onlyRemote'});
      expect(merged['shared']!.question, '另一台设备的版本');
      expect(merged['shared']!.updatedAt, DateTime(2026, 11, 9));
    });
  });

  group('自录错题进闪卡队列', () {
    test('不限定分类时出卡，ID 用 custom: 前缀', () {
      final cards = FlashcardService.buildQueue(
        [_emptyLesson()],
        customQuestions: [_question('q1')],
        seed: 7,
      );
      final custom = cards
          .where((card) => card.kind == FlashcardKind.custom)
          .toList();
      expect(custom, hasLength(1));
      expect(custom.single.id, 'custom:q1');
      expect(custom.single.front, 'q1 的题干');
      expect(custom.single.back, 'B');
    });

    test('按分类或单课复习时不带自录错题', () {
      final byCategory = FlashcardService.buildQueue(
        [_emptyLesson()],
        customQuestions: [_question('q1')],
        categoryId: 'c1',
        seed: 7,
      );
      final byLesson = FlashcardService.buildQueue(
        [_emptyLesson()],
        customQuestions: [_question('q1')],
        lessonId: 'l1',
        seed: 7,
      );
      expect(
        byCategory.where((card) => card.kind == FlashcardKind.custom),
        isEmpty,
      );
      expect(
        byLesson.where((card) => card.kind == FlashcardKind.custom),
        isEmpty,
      );
    });

    test('每场最多 maxCustomPerSession 张，无效记录不出卡', () {
      final items = <CustomQuestion>[
        for (var i = 0; i < 20; i++) _question('q$i'),
        _question('blank', answer: ''),
      ];
      final cards = FlashcardService.buildQueue(
        [_emptyLesson()],
        customQuestions: items,
        maxCards: 200,
        seed: 3,
      ).where((card) => card.kind == FlashcardKind.custom).toList();
      expect(cards, hasLength(FlashcardService.maxCustomPerSession));
      expect(cards.map((card) => card.id), isNot(contains('custom:blank')));
    });
  });

  group('收录页面', () {
    late ProgressProvider progress;

    setUp(() {
      progress = ProgressProvider(StorageService.inMemory());
    });

    tearDown(() => _stubChannel(null));

    testWidgets('手动填写即可收录，答案留空时拒绝保存', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const OcrCaptureScreen(), progress));
      await tester.pumpAndSettle();
      expect(find.text(strings.get('ocrCaptureTitle')), findsOneWidget);

      // 点击保存按钮（两个字段都留空）。
      final saveButton = find.byType(FilledButton);
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      
      // 检查是否有任何错误文本出现（通过查找包含"填"的文本）。
      final allTexts = find.byType(Text);
      final textWidgets = tester.widgetList<Text>(allTexts);
      final errorLike = textWidgets.where((t) => t.data?.contains('填') == true).toList();
      
      // 如果找不到错误文本，打印所有可见文本以便调试。
      if (errorLike.isEmpty) {
        final visibleTexts = textWidgets
            .map((t) => t.data)
            .where((s) => s != null && s.isNotEmpty)
            .toSet();
        // ignore: avoid_print
        print('Visible texts: $visibleTexts');
      }
      
      expect(errorLike, isNotEmpty, reason: 'Should find error text containing "填"');
      expect(progress.customQuestionCount, 0);

      // 填入内容后保存成功。
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '下列正确的是？');
      await tester.enterText(fields.at(1), 'B');
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(progress.customQuestionCount, 1);
    });

    testWidgets('从相册选图后把识别结果预填三个框并可继续编辑', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      _stubChannel((call) async => '识别到的题干\n答案：A\n解析：因为甲');
      final service = OcrService(
        pick: (source) async => XFile('/tmp/shot.jpg'),
      );
      await tester.pumpWidget(_app(OcrCaptureScreen(ocr: service), progress));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(strings.get('ocrFromGallery')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        '识别到的题干',
      );
      expect(tester.widget<TextFormField>(fields.at(1)).controller!.text, 'A');
      expect(
        tester.widget<TextFormField>(fields.at(2)).controller!.text,
        '因为甲',
      );
      expect(find.text(strings.get('ocrDone')), findsOneWidget);

      await tester.tap(find.text(strings.get('ocrSave')));
      await tester.pumpAndSettle();
      expect(progress.customQuestionCount, 1);
    });

    testWidgets('本机不支持识别时给出降级提示，仍可手动收录', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // 让通道抛出 MissingPluginException，模拟本机不支持识别。
      _stubChannel((call) async {
        throw MissingPluginException('MethodChannel not implemented');
      });
      final service = OcrService(
        pick: (source) async => XFile('/tmp/shot.jpg'),
      );
      await tester.pumpWidget(
        _app(OcrCaptureScreen(ocr: service), progress),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(strings.get('ocrTakePhoto')));
      // 异步识别链需要多帧完成。
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.text(strings.get('ocrUnavailable')), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '手写的题干');
      await tester.enterText(fields.at(1), '手写的答案');
      await tester.tap(find.text(strings.get('ocrSave')));
      await tester.pumpAndSettle();
      expect(progress.customQuestionCount, 1);
    });

    testWidgets('编辑模式回填原文并保存修改', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final saved = await progress.addCustomQuestion(
        question: '原题干',
        answer: 'A',
        explanation: '原解析',
      );
      await tester.pumpWidget(
        _app(OcrCaptureScreen(existing: saved), progress),
      );
      await tester.pumpAndSettle();

      expect(find.text(strings.get('ocrEditTitle')), findsOneWidget);
      // 编辑模式不再提供拍照入口，也不显示识别提示。
      expect(find.byTooltip(strings.get('ocrTakePhoto')), findsNothing);
      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        '原题干',
      );

      await tester.enterText(fields.at(0), '改过的题干');
      await tester.tap(find.text(strings.get('ocrSaveUpdate')));
      await tester.pumpAndSettle();

      expect(progress.customQuestionCount, 1);
      final updated = progress.customQuestionOf(saved!.id)!;
      expect(updated.question, '改过的题干');
      expect(updated.answer, 'A');
      expect(updated.explanation, '原解析');
    });
  });

  group('错题本里的自录分区', () {
    late ContentProvider content;
    late ProgressProvider progress;

    setUpAll(() async {
      content = ContentProvider();
      await content.load();
    });

    setUp(() {
      progress = ProgressProvider(StorageService.inMemory());
    });

    Future<void> pumpBook(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ContentProvider>.value(value: content),
            ChangeNotifierProvider<ProgressProvider>.value(value: progress),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(StorageService.inMemory()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const WrongAnswerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('只有内置错题时仍显示空态文案与拍照入口', (tester) async {
      await pumpBook(tester);
      expect(find.text(strings.get('noWrongQuestions')), findsOneWidget);
      expect(find.byTooltip(strings.get('ocrCapture')), findsOneWidget);
      // 没有内置错题就没有重练入口。
      expect(find.byTooltip(strings.get('wrongDrill')), findsNothing);
    });

    testWidgets('收录后出现在自录分区，删除后回到空态', (tester) async {
      await progress.addCustomQuestion(question: '自录的题干', answer: '自录的答案');
      await pumpBook(tester);
      expect(
        find.text(strings.get('customQuestionsCount').replaceAll('{n}', '1')),
        findsOneWidget,
      );
      expect(find.text('自录的题干'), findsOneWidget);

      await tester.tap(find.byTooltip(strings.get('delete')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.get('delete')).last);
      await tester.pumpAndSettle();

      expect(progress.customQuestionCount, 0);
      expect(find.text('自录的题干'), findsNothing);
    });

    testWidgets('点编辑进入编辑模式并保存修改', (tester) async {
      final saved = await progress.addCustomQuestion(
        question: '待编辑的题干',
        answer: 'A',
      );
      await pumpBook(tester);

      await tester.tap(find.byTooltip(strings.get('ocrEdit')).first);
      await tester.pumpAndSettle();
      expect(find.text(strings.get('ocrEditTitle')), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '改好的题干');
      await tester.tap(find.text(strings.get('ocrSaveUpdate')));
      await tester.pumpAndSettle();

      expect(progress.customQuestionOf(saved!.id)!.question, '改好的题干');
      expect(find.text('改好的题干'), findsOneWidget);
    });
  });
}
