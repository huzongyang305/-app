import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/widgets/quiz_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 模拟考试端到端流程：设置范围与题量 → 逐题作答 → 交卷看报告 → 错题入库。
void main() {
  late StorageService storage;

  setUp(() {
    storage = StorageService.inMemory();
  });

  Future<void> settleWithIo(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('完成一次 10 题模拟考试并写入错题', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(CodeLearnApp(storage: storage));
    await settleWithIo(tester);

    // 底部导航进入学习页
    await tester.tap(find.text('学习'));
    await tester.pumpAndSettle();

    // 学习页 → 测验列表
    await tester.tap(find.text('测验与模拟考试'));
    await tester.pumpAndSettle();

    // 测验列表 → 考试设置
    await tester.tap(find.text('模拟考试'));
    await tester.pumpAndSettle();
    expect(find.text('考试范围'), findsOneWidget);

    // 范围切到「算法与数据结构」分类（列表较长，先滚动到目标项）
    await tester.scrollUntilVisible(
      find.text('算法与数据结构'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('算法与数据结构'));
    await tester.pumpAndSettle();

    // 滚到题量区，验证「题量 → 时长」联动
    await tester.scrollUntilVisible(
      find.text('20 道题'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('20 道题'));
    await tester.pumpAndSettle();
    expect(find.textContaining('30 分钟'), findsOneWidget); // 20 题 → 30 分钟
    expect(find.textContaining('个知识点'), findsWidgets);

    await tester.tap(find.text('10 道题'));
    await tester.pumpAndSettle();
    expect(find.textContaining('15 分钟'), findsOneWidget);

    // 开始考试：考试页有周期计时器，不能用 pumpAndSettle
    await tester.tap(find.text('开始考试'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('第 1/10'), findsOneWidget);
    expect(find.textContaining('15:'), findsWidgets);
    expect(find.textContaining('模拟考试 · 算法与数据结构'), findsOneWidget);

    // 逐题作答：选择题点第一个选项，填空题输入占位答案，排序题直接使用初始顺序。
    for (var i = 0; i < 10; i++) {
      if (find.byType(QuizOptionTile).evaluate().isNotEmpty) {
        // 抽到长题干时选项可能位于屏幕外，先滚动到可见再点击。
        final option = find.byType(QuizOptionTile).first;
        await tester.ensureVisible(option);
        await tester.pump();
        await tester.tap(option);
      } else if (find.byType(TextField).evaluate().isNotEmpty) {
        await tester.enterText(find.byType(TextField), 'answer');
      }
      await tester.pump();
      await tester.tap(find.text(i == 9 ? '交卷' : '下一题'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    // 交卷后展示成绩报告（计时器已停止，可以正常 settle）
    await tester.pumpAndSettle();
    expect(find.textContaining('%'), findsWidgets);

    // 答错的题会进入错题本
    final wrong = storage.read('wrong_counts');
    expect(wrong, isA<Map<dynamic, dynamic>>());
    expect((wrong as Map).isNotEmpty, isTrue, reason: '随机选第一个选项必然有错题');
  });
}
