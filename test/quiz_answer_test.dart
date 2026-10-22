import 'package:code_learn_app/models/lesson.dart';
import 'package:code_learn_app/models/quiz_answer.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0 四种交互的判分回归测试。
void main() {
  test('填空题忽略大小写、空格和中英文标点', () {
    const question = QuizQuestion(
      question: '补全代码',
      options: <String>[],
      answerIndex: 0,
      explanation: '解释',
      type: 'fill',
      acceptedAnswers: <String>['print'],
    );

    expect(const QuizAnswer(text: ' PRINT ').matches(question), isTrue);
    expect(const QuizAnswer(text: 'input').matches(question), isFalse);
  });

  test('多选题必须完整选中全部正确答案', () {
    const question = QuizQuestion(
      question: '选择不可变类型',
      options: <String>['int', 'list', 'tuple', 'dict'],
      answerIndex: 0,
      answerIndexes: <int>[0, 2],
      explanation: '解释',
      type: 'multi',
    );

    expect(
      const QuizAnswer(selectedIndexes: <int>{0, 2}).matches(question),
      isTrue,
    );
    expect(
      const QuizAnswer(selectedIndexes: <int>{0}).matches(question),
      isFalse,
    );
  });

  test('排序题按当前拖动顺序判分', () {
    const question = QuizQuestion(
      question: '调整顺序',
      options: <String>['提交', '初始化', '添加', '推送'],
      answerIndex: 0,
      correctOrder: <int>[1, 2, 0, 3],
      explanation: '解释',
      type: 'order',
    );

    expect(
      const QuizAnswer(orderedIndexes: <int>[1, 2, 0, 3]).matches(question),
      isTrue,
    );
    expect(
      const QuizAnswer(orderedIndexes: <int>[0, 1, 2, 3]).matches(question),
      isFalse,
    );

    // 初始顺序本身就是一份可提交的答案：不强制用户先拖动一次。
    final initial = QuizAnswer.initial(question);
    expect(initial.orderedIndexes, <int>[0, 1, 2, 3]);
    expect(initial.hasResponse, isTrue);
    expect(initial.responded, isFalse, reason: 'responded 仍表示用户是否操作过');
  });

  test('单选题与填空题初始状态不算已作答', () {
    const choice = QuizQuestion(
      question: '选择一项',
      options: <String>['A', 'B'],
      answerIndex: 0,
      explanation: '解释',
    );
    const fill = QuizQuestion(
      question: '填空',
      options: <String>[],
      answerIndex: 0,
      explanation: '解释',
      type: 'fill',
      acceptedAnswers: <String>['print'],
    );
    expect(QuizAnswer.initial(choice).hasResponse, isFalse);
    expect(QuizAnswer.initial(fill).hasResponse, isFalse);
  });

  test('代码输出题仍按单选答案判分', () {
    const question = QuizQuestion(
      question: '运行结果是什么？',
      options: <String>['5', '23'],
      answerIndex: 0,
      explanation: '解释',
      type: 'code',
      code: 'print(2 + 3)',
      language: 'python',
    );

    expect(
      const QuizAnswer(selectedIndexes: <int>{0}).matches(question),
      isTrue,
    );
    expect(
      const QuizAnswer(selectedIndexes: <int>{1}).matches(question),
      isFalse,
    );
  });
}
