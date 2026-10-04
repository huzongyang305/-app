import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  Future<void> pumpApp(WidgetTester tester, Key key) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CodeLearnApp(
          storage: StorageService.inMemory(),
          contentProvider: content,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('视觉回归：手机首页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-phone');
    await pumpApp(tester, key);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/home_phone.png'),
    );
  });

  testWidgets('视觉回归：平板首页', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('golden-tablet');
    await pumpApp(tester, key);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/home_tablet.png'),
    );
  });
}
