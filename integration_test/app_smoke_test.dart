import 'package:code_learn_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android 真机启动与离线首页冒烟', (tester) async {
    app.main();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.text('课程分类').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('课程分类'), findsOneWidget);
    expect(find.text('搜索知识点'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
