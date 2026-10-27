import 'package:code_learn_app/l10n/app_strings.dart';
import 'package:code_learn_app/models/flashcard.dart';
import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/models/review_grade.dart';
import 'package:code_learn_app/screens/flashcard_screen.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/flashcard_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/services/terminology_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:code_learn_app/widgets/index_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Flashcard _card(String id) => Flashcard(
  id: id,
  lessonId: 'l1',
  categoryId: 'c1',
  kind: FlashcardKind.term,
  front: id,
  back: '$id-back',
);

Lesson _lesson() => const Lesson(
  id: 'l1',
  categoryId: 'c1',
  title: LocalizedText(zh: '闭包', en: 'Closure'),
  summary: LocalizedText(zh: '闭包课程', en: 'Closure lesson'),
  assetFile: 'test.md',
  minutes: 10,
  keywords: <String>['闭包'],
  quiz: <QuizQuestion>[],
);

void main() {
  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
    // 预热术语来源课程的 Markdown，widget 测试里就不再触发真实 IO。
    await content.markdownOf(content.lessonById('a11y_aria')!);
  });

  group('术语提取', () {
    test('解析术语表、去重并拼接多列说明', () {
      const markdown = '''
## 核心概念定义

| 术语 | 一句话说明 |
| --- | --- |
| 闭包 | 函数记住定义时的环境。 |
| `Future` | 表示未来结果的占位对象。 |

## 附录：关键术语表

| 术语 | 一句话说明 |
| --- | --- |
| 闭包 | 重复行不应重复出卡。 |
| 事件循环 | 从队列取任务执行。 | 易错点：阻塞主线程。 |
''';
      final terms = TerminologyService.extract(markdown);
      expect(terms.map((term) => term.term), ['闭包', 'Future', '事件循环']);
      expect(terms[0].explanation, '函数记住定义时的环境。');
      expect(terms[1].explanation, '表示未来结果的占位对象。');
      expect(terms[2].explanation, contains('易错点：阻塞主线程。'));
    });

    test('保留转义竖线，忽略分隔行与非术语表', () {
      const markdown = '''
| 概念 | 说明 |
| --- | --- |
| 不应出现 | 这不是术语表 |

| 术语 | 一句话说明 |
| :--- | :--- |
| A\\|B 分支 | 用竖线表示并行分支。 |
''';
      final terms = TerminologyService.extract(markdown);
      expect(terms.length, 1);
      expect(terms.first.term, 'A|B 分支');
      expect(terms.first.explanation, '用竖线表示并行分支。');
    });

    test('单篇术语数量有上限', () {
      final rows = List.generate(
        20,
        (index) => '| 术语$index | 解释$index |',
      ).join('\n');
      final terms = TerminologyService.extract('| 术语 | 说明 |\n$rows');
      expect(terms.length, TerminologyService.maxTermsPerLesson);
    });
  });

  group('闪卡排序', () {
    test('到期卡优先、新卡其次、未来卡最后', () {
      final now = DateTime(2026, 10, 26, 9);
      final ordered = FlashcardService.orderByDue(
        [_card('new'), _card('future'), _card('due'), _card('overdue')],
        now: now,
        dueAt: (card) => switch (card.id) {
          'overdue' => now.subtract(const Duration(days: 3)),
          'due' => now.subtract(const Duration(days: 1)),
          'future' => now.add(const Duration(days: 2)),
          _ => null,
        },
        maxCards: 10,
      );
      expect(ordered.map((card) => card.id), [
        'overdue',
        'due',
        'new',
        'future',
      ]);
    });

    test('截断时保留最久的到期卡', () {
      final now = DateTime(2026, 10, 26, 9);
      final ordered = FlashcardService.orderByDue(
        [_card('new'), _card('due'), _card('overdue')],
        now: now,
        dueAt: (card) => switch (card.id) {
          'overdue' => now.subtract(const Duration(days: 3)),
          'due' => now.subtract(const Duration(days: 1)),
          _ => null,
        },
        maxCards: 2,
      );
      expect(ordered.map((card) => card.id), ['overdue', 'due']);
    });
  });

  group('术语卡', () {
    test('术语卡标识包含课程与术语文本', () {
      final card = Flashcard.fromTerm(
        lesson: _lesson(),
        term: '闭包',
        explanation: '函数记住定义时的环境。',
      );
      expect(card.kind, FlashcardKind.term);
      expect(card.id, 'term:l1#闭包');
      expect(card.front, '闭包');
      expect(card.back, '函数记住定义时的环境。');
    });
  });

  group('闪卡间隔重复', () {
    test('三档自评决定排期，顺延只改到期日', () async {
      var clock = DateTime(2026, 10, 26, 9);
      final storage = StorageService.inMemory();
      final progress = ProgressProvider(storage, now: () => clock);
      const id = 'term:l1#闭包';

      expect(
        await progress.scheduleFlashcardWithGrade(id, ReviewGrade.remembered),
        1,
      );
      expect(progress.flashcardRepetitionsOf(id), 1);
      expect(progress.flashcardEaseOf(id), closeTo(2.58, 0.001));
      expect(
        progress.flashcardDueAt(id)!.difference(clock).inHours,
        closeTo(24, 1),
      );
      expect(progress.rawDueFlashcardCount, 0);

      clock = clock.add(const Duration(days: 1));
      expect(progress.rawDueFlashcardCount, 1);
      expect(progress.dueFlashcardCount, 1);

      expect(
        await progress.scheduleFlashcardWithGrade(id, ReviewGrade.remembered),
        3,
      );
      expect(progress.flashcardRepetitionsOf(id), 2);

      expect(
        await progress.scheduleFlashcardWithGrade(id, ReviewGrade.fuzzy),
        4,
      );
      expect(progress.flashcardRepetitionsOf(id), 2);

      expect(
        await progress.scheduleFlashcardWithGrade(id, ReviewGrade.forgot),
        1,
      );
      expect(progress.flashcardRepetitionsOf(id), 0);
      expect(progress.flashcardLapsesOf(id), 1);

      await progress.snoozeFlashcard(id, days: 2);
      expect(progress.flashcardIntervalOf(id), 1);
      expect(progress.flashcardDueAt(id)!.difference(clock).inDays, 2);
    });

    test('排期状态会持久化，并随备份导出与恢复', () async {
      var clock = DateTime(2026, 10, 26, 9);
      final storage = StorageService.inMemory();
      final progress = ProgressProvider(storage, now: () => clock);
      const id = 'term:l1#闭包';
      await progress.scheduleFlashcardWithGrade(id, ReviewGrade.remembered);
      expect(storage.read('flashcard_due'), isA<Map>());
      expect(storage.read('flashcard_interval'), isA<Map>());
      expect(storage.read('flashcard_ease'), isA<Map>());
      expect(storage.read('flashcard_repetitions'), isA<Map>());
      expect(storage.read('flashcard_lapses'), isA<Map>());

      final restored = ProgressProvider(storage, now: () => clock);
      expect(restored.flashcardDueAt(id), isNotNull);
      expect(restored.flashcardRepetitionsOf(id), 1);

      final dump = progress.exportData();
      final fromBackup = ProgressProvider(StorageService.inMemory());
      await fromBackup.importData(dump);
      expect(fromBackup.flashcardDueAt(id), isNotNull);
      expect(fromBackup.flashcardRepetitionsOf(id), 1);

      await fromBackup.importData(const <String, dynamic>{});
      expect(fromBackup.flashcardDueAt(id), isNull);
      expect(fromBackup.rawDueFlashcardCount, 0);
    });

    test('暂停复习时提醒数归零，原始积压保留', () async {
      final clock = DateTime(2026, 10, 26, 9);
      final storage = StorageService.inMemory();
      await storage.write('flashcard_due', <String, String>{
        'note:l1': clock.subtract(const Duration(days: 1)).toIso8601String(),
        'term:l2#闭包': clock
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      });
      final progress = ProgressProvider(storage, now: () => clock);
      expect(progress.rawDueFlashcardCount, 2);
      expect(progress.dueFlashcardCount, 2);
      expect(progress.dueFlashcardLessonIds, containsAll(['l1', 'l2']));

      await progress.pauseReviewsUntil(clock.add(const Duration(days: 2)));
      expect(progress.rawDueFlashcardCount, 2);
      expect(progress.dueFlashcardCount, 0);
      expect(progress.dueFlashcardLessonIds, containsAll(['l1', 'l2']));
    });
  });

  testWidgets('闪卡页从术语表补充卡片并写入单卡排期', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = StorageService.inMemory();
    final progress = ProgressProvider(storage);

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
          home: const FlashcardScreen(lessonId: 'a11y_aria'),
        ),
      ),
    );
    // 队列在 didChangeDependencies 里异步准备，markdown 已缓存，几帧即可完成。
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );

    final strings = AppStrings('zh');
    expect(find.text(strings.get('flashcardTitle')), findsOneWidget);

    // 术语卡是「新卡」，排在题目卡之后；先刷完题目卡直到术语卡出现。
    var guard = 0;
    while (find.text(strings.get('flashcardTermCard')).evaluate().isEmpty) {
      expect(guard, lessThan(30), reason: '队列里没有出现术语卡');
      await tester.tap(find.byType(IndexCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.get('gradeRemembered')));
      await tester.pumpAndSettle();
      guard++;
    }
    expect(find.text(strings.get('flashcardTermCard')), findsOneWidget);

    await tester.tap(find.byType(IndexCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings.get('gradeRemembered')));
    await tester.pumpAndSettle();

    final due = storage.read('flashcard_due');
    expect(due, isA<Map>());
    expect((due as Map).isNotEmpty, isTrue);
    expect(progress.rawDueFlashcardCount, 0);
  });
}
