import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/models/note.dart';
import 'package:code_learn_app/models/review_grade.dart';
import 'package:code_learn_app/services/auto_backup_service.dart';
import 'package:code_learn_app/services/backup_file_service.dart';
import 'package:code_learn_app/services/daily_question_service.dart';
import 'package:code_learn_app/services/flashcard_service.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Lesson buildLesson({
  required String id,
  String categoryId = 'python',
  String group = 'Python',
  List<QuizQuestion> quiz = const <QuizQuestion>[
    QuizQuestion(
      question: 'Python 中哪个关键字用于定义函数？',
      options: ['def', 'func', 'function', 'lambda'],
      answerIndex: 0,
      explanation: 'Python 使用 def 定义函数。',
    ),
  ],
}) {
  return Lesson(
    id: id,
    categoryId: categoryId,
    group: group,
    difficulty: '基础',
    title: LocalizedText(zh: '课程 $id', en: 'Lesson $id'),
    summary: const LocalizedText(zh: '摘要', en: 'Summary'),
    assetFile: 'assets/content/$id.md',
    minutes: 10,
    keywords: const <String>['测试'],
    quiz: quiz,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('每日一题', () {
    final lessons = <Lesson>[
      buildLesson(id: 'python_basics'),
      buildLesson(id: 'python_flow', categoryId: 'python'),
    ];

    test('同一天抽到同一道题，不同日期通常不同', () {
      final first = DailyQuestionService.pick(lessons, DateTime(2026, 1, 5));
      final second = DailyQuestionService.pick(lessons, DateTime(2026, 1, 5));
      expect(first, isNotNull);
      expect(first!.lesson.id, second!.lesson.id);
      expect(first.questionIndex, second.questionIndex);

      final picks = <String>{
        for (var day = 1; day <= 14; day++)
          DailyQuestionService.pick(lessons, DateTime(2026, 1, day))!
              .lesson
              .id,
      };
      expect(picks.length, greaterThan(1));
    });

    test('题库为空时返回 null', () {
      expect(DailyQuestionService.pick(const <Lesson>[], DateTime(2026, 1, 5)), isNull);
    });
  });

  group('闪卡队列', () {
    final lessons = <Lesson>[
      buildLesson(id: 'python_basics'),
      buildLesson(id: 'python_flow'),
      buildLesson(id: 'sql_basics', categoryId: 'database', group: 'SQL'),
    ];

    test('从题库生成题目卡，按分类过滤', () {
      final all = FlashcardService.buildQueue(lessons, seed: 7);
      expect(all.length, 3);
      expect(all.every((card) => card.front.isNotEmpty), isTrue);
      expect(all.every((card) => card.back.isNotEmpty), isTrue);

      final pythonOnly = FlashcardService.buildQueue(
        lessons,
        categoryId: 'python',
        seed: 7,
      );
      expect(pythonOnly.length, 2);
      expect(
        pythonOnly.every((card) => card.categoryId == 'python'),
        isTrue,
      );
    });

    test('笔记生成卡片，并遵守数量上限', () {
      final notes = <Note>[
        Note(
          lessonId: 'python_basics',
          content: 'def 用于定义函数',
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      final cards = FlashcardService.buildQueue(
        lessons,
        notes: notes,
        maxCards: 2,
        seed: 3,
      );
      expect(cards.length, 2);
      final noteCard = FlashcardService.buildQueue(
        lessons,
        notes: notes,
        includeNotes: true,
        seed: 3,
      ).where((card) => card.id == 'note:python_basics');
      expect(noteCard, isNotEmpty);
      expect(noteCard.first.back, 'def 用于定义函数');
    });
  });

  group('错题排入复习队列', () {
    test('答错后复习时间提前到一天内，答对后计入消灭率', () async {
      final storage = StorageService.inMemory();
      final now = DateTime(2026, 3, 1, 9);
      final progress = ProgressProvider(storage, now: () => now);

      await progress.scheduleReviewWithGrade(
        'python_basics',
        ReviewGrade.remembered,
      );
      await progress.scheduleReviewWithGrade(
        'python_basics',
        ReviewGrade.remembered,
      );
      final before = progress.reviewDueAt('python_basics');
      expect(before, isNotNull);
      expect(before!.isAfter(now.add(const Duration(days: 2))), isTrue);

      await progress.recordWrong('python_basics', 0);
      final after = progress.reviewDueAt('python_basics');
      expect(after, isNotNull);
      expect(after!.isAfter(now), isTrue);
      expect(after.isBefore(before), isTrue);
      expect(
        after.isBefore(now.add(const Duration(days: 1, hours: 1))),
        isTrue,
      );
      expect(progress.everWrongQuestions, 1);
      expect(progress.wrongResolvedRatio, 0);

      await progress.clearWrong('python_basics', 0);
      expect(progress.totalWrongQuestions, 0);
      expect(progress.wrongResolvedRatio, 1);
    });
  });

  group('自动备份调度', () {
    const channel = MethodChannel(BackupFileService.channelName);
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            switch (call.method) {
              case 'getBackupFolder':
                return 'content://tree/primary%3ADownload%2FCodeLearn';
              case 'writeAutoBackup':
                return <String, Object>{
                  'name': call.arguments['suggestedName'].toString(),
                  'deleted': 2,
                };
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('未到期时不写入，到期时写入并带上保留份数', () async {
      final now = DateTime(2026, 4, 10, 20);
      final service = const AutoBackupService();
      final coordinator = AutoBackupCoordinator(service: service);

      final skipped = await coordinator.maybeRun(
        enabled: true,
        intervalDays: 1,
        keepCount: 5,
        lastBackupAt: now.subtract(const Duration(hours: 3)),
        now: now,
        payload: '{}',
      );
      expect(skipped, isNull);
      expect(calls, isEmpty);

      calls.clear();
      final name = await coordinator.maybeRun(
        enabled: true,
        intervalDays: 1,
        keepCount: 5,
        lastBackupAt: now.subtract(const Duration(days: 2)),
        now: now,
        payload: '{"a":1}',
      );
      expect(name, isNotNull);
      final writeCall = calls.singleWhere(
        (call) => call.method == 'writeAutoBackup',
      );
      expect(writeCall.arguments['keepCount'], 5);
      expect(
        writeCall.arguments['suggestedName'],
        AutoBackupService.backupFileName(now),
      );
    });

    test('关闭自动备份时不访问目录', () async {
      final coordinator = const AutoBackupCoordinator();
      final name = await coordinator.maybeRun(
        enabled: false,
        intervalDays: 1,
        keepCount: 5,
        lastBackupAt: null,
        now: DateTime(2026, 4, 10),
        payload: '{}',
      );
      expect(name, isNull);
      expect(calls, isEmpty);
    });
  });
}
