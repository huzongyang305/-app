import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/widgets/quiz_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 端到端流程测试：选分类 → 看教程 → 做测验 → 看进度。
///
/// 使用内存存储替代真机 Hive，其余逻辑与线上完全一致。
void main() {
  late StorageService storage;

  setUp(() {
    storage = StorageService.inMemory();
  });

  /// flutter_test 的 FakeAsync 不会推进真实文件 IO，
  /// 这里先让出一小段真实时间给 assets 读取，再把界面动画走完。
  Future<void> settleWithIo(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('完成一次完整学习流程', (tester) async {
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(CodeLearnApp(storage: storage));
    await settleWithIo(tester);

    // 首页：顶部进度与签到卡已渲染
    expect(find.textContaining('总体学习进度'), findsOneWidget);
    expect(find.textContaining('连续学习'), findsOneWidget);

    // 分类网格在首屏下方，滚动到「编程语言」再点击
    await tester.scrollUntilVisible(
      find.text('课程分类'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Python'), findsWidgets);

    // 选分类
    await tester.tap(find.text('Python').first);
    await tester.pumpAndSettle();
    // 入门课程排在分类最前面，直接学习第一课。
    expect(find.text('Python 第一个脚本'), findsOneWidget);
    await tester.tap(find.text('Python 第一个脚本'));
    await settleWithIo(tester);
    expect(find.textContaining('本节知识框架'), findsWidgets);

    // 复制全文：把标题、摘要与正文写入剪贴板，并给出反馈
    await tester.tap(find.byTooltip('复制全文'));
    await settleWithIo(tester);
    expect(find.text('已复制标题、摘要与正文'), findsOneWidget);

    // 打开测验。题库 = 内置题 + 语言课程动态代码练习，逐题作答直到最后一题。
    await tester.tap(find.text('开始测验'));
    await tester.pumpAndSettle();

    var answered = 0;
    var sawCorrectFeedback = false;
    while (answered < 30) {
      final options = find.byType(QuizOptionTile);
      if (options.evaluate().isNotEmpty) {
        await tester.tap(options.first);
      } else {
        // 填空题：输入 print 后手动提交。
        await tester.enterText(find.byType(TextField), 'print');
      }
      await tester.pumpAndSettle();

      final submit = find.text('提交答案');
      if (submit.evaluate().isNotEmpty) {
        await tester.tap(submit);
        await tester.pumpAndSettle();
      }
      answered++;
      if (find.text('回答正确').evaluate().isNotEmpty) {
        sawCorrectFeedback = true;
      }

      if (find.text('查看结果').evaluate().isNotEmpty) break;
      await tester.tap(find.text('下一题'));
      await tester.pumpAndSettle();
    }
    expect(answered, greaterThanOrEqualTo(4));
    expect(sawCorrectFeedback, isTrue);
    await tester.tap(find.text('查看结果'));
    await tester.pumpAndSettle();

    // 新增交卷前检查：确认交卷后才进入结果页。
    final finish = find.text('交卷查看结果');
    if (finish.evaluate().isNotEmpty) {
      await tester.tap(finish);
      await tester.pumpAndSettle();
    }

    // 结果页
    expect(find.text('测验完成'), findsOneWidget);

    // 返回后进度已记录
    await tester.tap(find.text('返回教程'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 首页进度条显示已学 1 个知识点（不写死总数，便于持续扩充内容）
    // 之前滚动过首页列表，这里先滚回顶部让进度卡重新构建
    await tester.scrollUntilVisible(
      find.textContaining('已学知识点'),
      -320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final progressText = tester
        .widgetList<Text>(find.textContaining('已学知识点'))
        .map((widget) => widget.data ?? '')
        .firstWhere((text) => text.contains(' / '), orElse: () => '');
    expect(
      progressText.startsWith('1 / '),
      isTrue,
      reason: '首页应显示已学 1 篇，实际：$progressText',
    );

    final progressBox = storage.read('learned_ids') as List<dynamic>?;
    expect(progressBox, isNotNull);
    expect(progressBox!.contains('python_first_script'), isTrue);
    expect(storage.read('quiz_result_python_first_script'), isNotNull);
  });
}
