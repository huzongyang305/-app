import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/screens/image_viewer_screen.dart';
import 'package:code_learn_app/screens/lesson_screen.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  const caption = 'Flutter Widget、Element 与 RenderObject 三棵树';
  const asset = 'assets/content/images/diagram_flutter_trees.webp';
  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  Widget wrap(Widget child) => ChangeNotifierProvider<SettingsProvider>(
    create: (_) => SettingsProvider(StorageService.inMemory()),
    child: MaterialApp(home: child),
  );

  testWidgets('全屏查看器展示图注并支持缩放与复位', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      wrap(const ImageViewerScreen(assetPath: asset, caption: caption)),
    );
    await tester.pump();

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.scaleEnabled, isTrue);
    expect(viewer.panEnabled, isTrue);
    expect(viewer.maxScale, 5);
    expect(find.text('图注'), findsOneWidget);
    expect(find.text(caption), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('放大'));
    await tester.pump();
    expect(find.text('140%'), findsOneWidget);

    await tester.tap(find.byTooltip('缩小'));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byTooltip('复位'));
    await tester.pump();
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('教程配图可以点击进入全屏查看', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      CodeLearnApp(
        storage: StorageService.inMemory(),
        contentProvider: content,
      ),
    );
    // 教程正文通过文件 IO 读取，这里给真实异步留出时间。
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      if (find.byType(Scrollable).evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 400));

    await tester.scrollUntilVisible(
      find.text('课程分类'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python 第一个脚本'));
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      if (find.byTooltip('查看大图').evaluate().isNotEmpty) break;
    }

    expect(find.byTooltip('查看大图'), findsWidgets);
    // 测试环境里图片解码是真实异步；先预解码，避免 Image 尺寸为 0 时点击落空。
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/content/images/diagram_py_first.webp'),
        tester.element(find.byType(LessonScreen)),
      );
    });
    await tester.pumpAndSettle();
    final entry = find.byTooltip('查看大图').first;
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(ImageViewerScreen), findsOneWidget);
    expect(find.text('图注'), findsOneWidget);
    expect(find.textContaining('Python 脚本'), findsWidgets);
  });
}
