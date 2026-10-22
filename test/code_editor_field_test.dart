import 'package:code_learn_app/widgets/code_editor_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 代码编辑器输入增强的行为测试。
void main() {
  Future<TextEditingController> pumpField(WidgetTester tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CodeEditorField(controller: controller, maxLines: 20),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    return controller;
  }

  /// 逐字符模拟输入法：自动补全依赖 oldValue -> newValue 只增加一个字符。
  Future<void> typeIncrementally(
    WidgetTester tester,
    TextEditingController controller,
    String input,
  ) async {
    for (var index = 0; index < input.length; index++) {
      final value = controller.value;
      final caret = value.selection.isValid
          ? value.selection.baseOffset
          : value.text.length;
      final next =
          value.text.substring(0, caret) +
          input[index] +
          value.text.substring(caret);
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: caret + 1),
        ),
      );
      await tester.pump();
    }
  }

  testWidgets('输入左括号会自动补全右括号并停在中间', (tester) async {
    final controller = await pumpField(tester);
    await tester.enterText(find.byType(TextField), '(');
    await tester.pump();
    expect(controller.text, '()');
    expect(controller.selection.baseOffset, 1);
  });

  testWidgets('输入右括号时跳过已有的闭合符号', (tester) async {
    final controller = await pumpField(tester);
    await tester.enterText(find.byType(TextField), '(');
    await tester.pump();
    // 模拟光标停在 () 中间时再输入一个 )：
    // 输入法给出的新值是 ())，格式化器应去掉重复符号并只移动光标。
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '())',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '()');
    expect(controller.selection.baseOffset, 2);
  });

  testWidgets('在成对花括号中间回车会展开缩进', (tester) async {
    final controller = await pumpField(tester);
    await typeIncrementally(tester, controller, 'if (x) {');
    expect(controller.text, 'if (x) {}');

    final caret = controller.selection.baseOffset;
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text:
            '${controller.text.substring(0, caret)}\n'
            '${controller.text.substring(caret)}',
        selection: TextSelection.collapsed(offset: caret + 1),
      ),
    );
    await tester.pump();
    expect(controller.text, 'if (x) {\n  \n}');
    expect(controller.selection.baseOffset, 'if (x) {\n  '.length);
  });

  testWidgets('Tab 键插入两个空格缩进', (tester) async {
    final controller = await pumpField(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(controller.text, '  ');
  });
}
