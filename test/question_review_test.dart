import 'package:code_learn_app/l10n/app_strings.dart';
import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/localized_text.dart';
import 'package:code_learn_app/models/quiz_answer.dart';
import 'package:code_learn_app/models/review_grade.dart';
import 'package:code_learn_app/screens/question_review_screen.dart';
import 'package:code_learn_app/services/practice_question_factory.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/question_review_planner.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/services/variant_question_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 题目级间隔重复与变式题：调度、队列排序、持久化和页面流程。
void main() {
  Lesson lesson(
    String id, {
    int count = 3,
    String categoryId = 'test',
    String title = '测试课程',
    List<String> types = const <String>[],
  }) {
    return Lesson(
      id: id,
      categoryId: categoryId,
      difficulty: '基础',
      title: LocalizedText(zh: title, en: title),
      summary: const LocalizedText(zh: '测试摘要', en: 'Test summary'),
      assetFile: 'test.md',
      minutes: 10,
      keywords: const <String>['测试'],
      quiz: <QuizQuestion>[
        for (var i = 0; i < count; i++)
          _question(
            '$title 测试题 ${i + 1}',
            type: i < types.length ? types[i] : 'single',
          ),
      ],
    );
  }

  group('题目级间隔重复', () {
    test('答对后 1 天到期，连续答对拉长到 3 天，答错重置并记录遗忘', () async {
      var clock = DateTime(2026, 10, 26, 9);
      final progress = ProgressProvider(
        StorageService.inMemory(),
        now: () => clock,
      );
      const id = 'lesson';

      await progress.recordAnswerOutcome(
        id,
        0,
        score: 1,
        confidence: AnswerConfidence.confident,
      );
      expect(progress.questionReviewIntervalOf(id, 0), 1);
      expect(progress.questionReviewRepetitionsOf(id, 0), 1);
      expect(progress.questionReviewLapsesOf(id, 0), 0);
      expect(
        progress.questionReviewDueAt(id, 0)!.difference(clock).inHours,
        closeTo(24, 1),
      );

      clock = clock.add(const Duration(days: 1));
      await progress.recordAnswerOutcome(
        id,
        0,
        score: 1,
        confidence: AnswerConfidence.confident,
      );
      expect(progress.questionReviewIntervalOf(id, 0), 3);
      expect(progress.questionReviewRepetitionsOf(id, 0), 2);
      final easeBefore = progress.questionReviewEaseOf(id, 0);

      clock = clock.add(const Duration(days: 3));
      await progress.recordAnswerOutcome(
        id,
        0,
        score: 0,
        confidence: AnswerConfidence.guessed,
      );
      expect(progress.questionReviewIntervalOf(id, 0), 1);
      expect(progress.questionReviewRepetitionsOf(id, 0), 0);
      expect(progress.questionReviewLapsesOf(id, 0), 1);
      expect(progress.questionReviewEaseOf(id, 0), lessThan(easeBefore));
      expect(
        progress.questionReviewDueAt(id, 0)!.difference(clock).inHours,
        closeTo(24, 1),
      );
    });

    test('部分得分会小幅延长间隔但不推进重复次数', () async {
      final progress = ProgressProvider(StorageService.inMemory());
      await progress.recordAnswerOutcome(
        'lesson',
        0,
        score: 0.6,
        confidence: AnswerConfidence.unsure,
      );
      expect(progress.questionReviewIntervalOf('lesson', 0), 1);
      expect(progress.questionReviewRepetitionsOf('lesson', 0), 0);
      expect(progress.questionReviewLapsesOf('lesson', 0), 0);
    });

    test('队列按逾期、错题次数和遗忘次数排序，并忽略失效题目', () async {
      final now = DateTime(2026, 10, 26, 9);
      final storage = StorageService.inMemory();
      await storage.write('question_review_due', <String, String>{
        'l1#0': now.subtract(const Duration(days: 2)).toIso8601String(),
        'l1#1': now.subtract(const Duration(days: 5)).toIso8601String(),
        'l1#2': now.subtract(const Duration(days: 1)).toIso8601String(),
        'l2#0': now.subtract(const Duration(days: 1)).toIso8601String(),
        'l1#99': now.subtract(const Duration(days: 9)).toIso8601String(),
        'gone#0': now.subtract(const Duration(days: 9)).toIso8601String(),
      });
      await storage.write('question_review_lapses', <String, int>{'l1#2': 2});
      await storage.write('wrong_counts', <String, int>{'l1#2': 3});
      final progress = ProgressProvider(storage, now: () => now);
      final lessons = <Lesson>[lesson('l1'), lesson('l2')];

      final plan = progress.questionReviewPlanFor(lessons, budgetMinutes: 30);
      expect(plan.count, 4);
      expect(plan.deferredCount, 0);
      expect(
        plan.items.map((item) => '${item.lesson.id}#${item.questionIndex}'),
        <String>['l1#1', 'l1#0', 'l1#2', 'l2#0'],
      );
      expect(plan.totalMinutes, 4);
    });

    test('超出预算的题目顺延，代码题按 3 分钟估算', () async {
      final now = DateTime(2026, 10, 26, 9);
      final codeLesson = lesson(
        'code',
        count: 3,
        types: const <String>['code', 'single', 'single'],
      );
      final plan = buildQuestionReviewPlan(
        <QuestionReviewCandidate>[
          for (var i = 0; i < 3; i++)
            QuestionReviewCandidate(
              lesson: codeLesson,
              questionIndex: i,
              dueAt: now.subtract(Duration(days: 2 - i)),
            ),
        ],
        budgetMinutes: 3,
        now: now,
      );
      expect(plan.items, hasLength(1));
      expect(plan.items.first.minutes, 3);
      expect(plan.totalMinutes, 3);
      expect(plan.deferredCount, 2);
    });

    test('暂停复习或当天不在允许的星期时不排题目队列', () async {
      final now = DateTime(2026, 10, 26, 9); // 周一
      final storage = StorageService.inMemory();
      await storage.write('question_review_due', <String, String>{
        'l1#0': now.subtract(const Duration(days: 1)).toIso8601String(),
      });
      final progress = ProgressProvider(storage, now: () => now);
      final lessons = <Lesson>[lesson('l1')];
      expect(progress.questionReviewPlanFor(lessons).count, 1);
      expect(progress.rawDueQuestionReviewCount, 1);

      await progress.pauseReviewsUntil(now);
      expect(progress.questionReviewPlanFor(lessons).isEmpty, isTrue);
      expect(progress.rawDueQuestionReviewCount, 1);

      await progress.resumeReviews();
      await progress.setReviewWeekdays(<int>{now.weekday + 1});
      expect(progress.questionReviewPlanFor(lessons).isEmpty, isTrue);
      expect(progress.rawDueQuestionReviewCount, 1);
    });

    test('调度状态会持久化，并随备份导出与恢复', () async {
      final storage = StorageService.inMemory();
      var clock = DateTime(2026, 10, 26, 9);
      final progress = ProgressProvider(storage, now: () => clock);
      await progress.recordAnswerOutcome(
        'l1',
        1,
        score: 1,
        confidence: AnswerConfidence.confident,
      );
      expect(storage.read('question_review_due'), isA<Map>());
      expect(storage.read('question_review_interval'), isA<Map>());
      expect(storage.read('question_review_ease'), isA<Map>());
      expect(storage.read('question_review_repetitions'), isA<Map>());
      expect(storage.read('question_review_lapses'), isA<Map>());

      final restored = ProgressProvider(storage, now: () => clock);
      expect(restored.questionReviewDueAt('l1', 1), isNotNull);
      expect(restored.questionReviewIntervalOf('l1', 1), 1);

      final dump = progress.exportData();
      final fromBackup = ProgressProvider(StorageService.inMemory());
      await fromBackup.importData(dump);
      expect(fromBackup.questionReviewDueAt('l1', 1), isNotNull);
      expect(fromBackup.questionReviewRepetitionsOf('l1', 1), 1);

      await fromBackup.importData(const <String, dynamic>{});
      expect(fromBackup.questionReviewDueAt('l1', 1), isNull);
      expect(fromBackup.rawDueQuestionReviewCount, 0);
    });

    test('三档自评决定排期，稍后复习只顺延到期日', () async {
      var clock = DateTime(2026, 10, 26, 9);
      final progress = ProgressProvider(
        StorageService.inMemory(),
        now: () => clock,
      );
      const id = 'graded';

      await progress.recordAnswerOutcome(
        id,
        0,
        score: 1,
        confidence: AnswerConfidence.confident,
        scheduleReview: false,
      );
      // 只记录作答，不排期；等自评后再写调度。
      expect(progress.questionReviewDueAt(id, 0), isNull);
      expect(progress.questionReviewRepetitionsOf(id, 0), 0);
      expect(progress.questionAttemptsOf(id, 0), 1);

      expect(
        await progress.scheduleQuestionReviewWithGrade(
          id,
          0,
          ReviewGrade.remembered,
        ),
        1,
      );
      expect(progress.questionReviewRepetitionsOf(id, 0), 1);
      expect(progress.questionReviewEaseOf(id, 0), closeTo(2.58, 0.001));
      expect(
        progress.questionReviewDueAt(id, 0)!.difference(clock).inHours,
        closeTo(24, 1),
      );

      clock = clock.add(const Duration(days: 1));
      expect(
        await progress.scheduleQuestionReviewWithGrade(
          id,
          0,
          ReviewGrade.remembered,
        ),
        3,
      );
      expect(progress.questionReviewRepetitionsOf(id, 0), 2);

      final fuzzyDays = await progress.scheduleQuestionReviewWithGrade(
        id,
        0,
        ReviewGrade.fuzzy,
      );
      expect(fuzzyDays, greaterThanOrEqualTo(3));
      expect(progress.questionReviewRepetitionsOf(id, 0), 2);

      expect(
        await progress.scheduleQuestionReviewWithGrade(
          id,
          0,
          ReviewGrade.forgot,
        ),
        1,
      );
      expect(progress.questionReviewRepetitionsOf(id, 0), 0);
      expect(progress.questionReviewLapsesOf(id, 0), 1);

      await progress.snoozeQuestionReview(id, 0);
      expect(progress.questionReviewIntervalOf(id, 0), 1);
      expect(
        progress.questionReviewDueAt(id, 0)!.difference(clock).inHours,
        closeTo(24, 1),
      );
    });
  });

  group('变式题', () {
    test('同一知识点轮换不同题，同一参数保持确定性', () {
      final lesson = _buildVariantLesson();
      final original = VariantQuestionService.forQuestion(
        lesson,
        0,
        attempt: 0,
      );
      expect(original!.kind, VariantKind.original);
      expect(original.variantIndex, 0);

      final first = VariantQuestionService.forQuestion(lesson, 0, attempt: 1)!;
      expect(first.kind, VariantKind.sameLesson);
      expect(first.variantIndex, isNot(0));
      expect(first.question.question, isNot(lesson.allQuiz[0].question));
      expect(
        first.question.correctIndexes,
        everyElement(inInclusiveRange(0, first.question.options.length - 1)),
      );

      final repeated = VariantQuestionService.forQuestion(
        lesson,
        0,
        attempt: 1,
      )!;
      expect(repeated.variantIndex, first.variantIndex);

      final second = VariantQuestionService.forQuestion(lesson, 0, attempt: 2)!;
      expect(second.variantIndex, isNot(first.variantIndex));
    });

    test('优先选择同题型，只有一道题时退回原题', () {
      final mixed = lesson(
        'mixed',
        count: 3,
        types: const <String>['single', 'multi', 'single'],
      );
      final variant = VariantQuestionService.forQuestion(mixed, 0, attempt: 1)!;
      expect(variant.variantIndex, 2);

      final single = lesson('single', count: 1);
      final fallback = VariantQuestionService.forQuestion(
        single,
        0,
        attempt: 5,
      )!;
      expect(fallback.kind, VariantKind.original);
      expect(fallback.variantIndex, 0);
    });

    test('越界下标返回 null，动态代码题也能成为变式', () {
      final variantLesson = _buildVariantLesson();
      expect(VariantQuestionService.forQuestion(variantLesson, 99), isNull);
      expect(VariantQuestionService.forQuestion(variantLesson, -1), isNull);

      final pythonLesson = lesson(
        'python_basics',
        count: 5,
        categoryId: 'python',
        title: 'Python 基础',
      );
      expect(
        pythonLesson.allQuiz.length,
        greaterThan(pythonLesson.quiz.length),
      );
      final variant = VariantQuestionService.forQuestion(
        pythonLesson,
        0,
        attempt: 3,
      )!;
      expect(variant.kind, VariantKind.sameLesson);
      expect(variant.variantIndex, isNot(0));
      expect(
        variant.question.correctIndexes,
        everyElement(inInclusiveRange(0, variant.question.options.length - 1)),
      );
    });
  });

  testWidgets('题目复习页可以作答并写回原题调度', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 10, 26, 9);
    final storage = StorageService.inMemory();
    final target = lesson('widget', count: 3);
    await storage.write('question_review_due', <String, String>{
      'widget#0': now.subtract(const Duration(days: 1)).toIso8601String(),
    });
    await storage.write('question_stats', <String, dynamic>{
      'widget#0': <String, dynamic>{'attempts': 1},
    });
    final progress = ProgressProvider(storage, now: () => now);
    final plan = progress.questionReviewPlanFor(<Lesson>[
      target,
    ], budgetMinutes: 30);
    final expected = VariantQuestionService.forQuestion(target, 0, attempt: 1)!;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProgressProvider>.value(value: progress),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(StorageService.inMemory()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: QuestionReviewScreen(plan: plan),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings('zh').get('reviewQuestionTitle')),
      findsWidgets,
    );
    expect(
      find.text(AppStrings('zh').get('reviewVariantBadge')),
      findsOneWidget,
    );
    expect(find.text(expected.question.question), findsOneWidget);

    await tester.tap(
      find.text(expected.question.options[expected.question.answerIndex]),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings('zh').get('correct')), findsOneWidget);
    expect(find.text(AppStrings('zh').get('reviewGradeTitle')), findsOneWidget);
    // 提交只记录作答，选择自评档位后才写入排期。
    expect(progress.questionReviewRepetitionsOf('widget', 0), 0);
    expect(progress.wrongCountOf('widget', 0), 0);

    final remembered = find.text(AppStrings('zh').get('gradeRemembered'));
    await tester.scrollUntilVisible(
      remembered,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(remembered);
    await tester.pumpAndSettle();

    expect(progress.questionReviewRepetitionsOf('widget', 0), 1);
    expect(progress.questionReviewIntervalOf('widget', 0), 1);
    expect(
      progress.questionReviewDueAt('widget', 0)!.difference(now).inHours,
      closeTo(24, 1),
    );
    expect(
      find.text(
        AppStrings('zh').get('reviewScheduled').replaceAll('{days}', '1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('稍后复习把题目顺延一天且不记录作答', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 10, 26, 9);
    final storage = StorageService.inMemory();
    final target = lesson('snooze', count: 1);
    await storage.write('question_review_due', <String, String>{
      'snooze#0': now.subtract(const Duration(days: 1)).toIso8601String(),
    });
    final progress = ProgressProvider(storage, now: () => now);
    final plan = progress.questionReviewPlanFor(<Lesson>[
      target,
    ], budgetMinutes: 30);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProgressProvider>.value(value: progress),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(StorageService.inMemory()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: QuestionReviewScreen(plan: plan),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();

    expect(
      progress.questionReviewDueAt('snooze', 0)!.difference(now).inHours,
      closeTo(24, 1),
    );
    expect(progress.questionReviewRepetitionsOf('snooze', 0), 0);
    expect(progress.questionAttemptsOf('snooze', 0), 0);
    expect(
      find.text(AppStrings('zh').get('reviewQuestionResult')),
      findsWidgets,
    );
  });
}

Lesson _buildVariantLesson() {
  return Lesson(
    id: 'variant',
    categoryId: 'test',
    difficulty: '基础',
    title: const LocalizedText(zh: '变式课程', en: 'Variant'),
    summary: const LocalizedText(zh: '测试摘要', en: 'Test summary'),
    assetFile: 'test.md',
    minutes: 10,
    keywords: const <String>['测试'],
    quiz: <QuizQuestion>[
      for (var i = 0; i < 5; i++) _question('变式课程 测试题 ${i + 1}'),
    ],
  );
}

QuizQuestion _question(String text, {String type = 'single'}) {
  if (type == 'multi') {
    return QuizQuestion(
      question: text,
      options: const <String>['选项甲', '选项乙', '选项丙', '选项丁'],
      answerIndex: 0,
      answerIndexes: const <int>[0, 1],
      explanation: '解析',
      type: type,
    );
  }
  if (type == 'code') {
    return QuizQuestion(
      question: text,
      options: const <String>['输出一', '输出二', '输出三', '输出四'],
      answerIndex: 0,
      explanation: '解析',
      type: type,
      code: 'print(1)',
      language: 'python',
      expectedOutput: '1',
    );
  }
  return QuizQuestion(
    question: text,
    options: const <String>['选项甲', '选项乙', '选项丙', '选项丁'],
    answerIndex: 0,
    explanation: '解析',
    type: type,
  );
}
