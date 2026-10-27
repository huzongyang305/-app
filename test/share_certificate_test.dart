import 'package:code_learn_app/models/lesson_category.dart';
import 'package:code_learn_app/screens/certificate_screen.dart';
import 'package:code_learn_app/screens/share_card_screen.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/progress_provider.dart';
import 'package:code_learn_app/services/settings_provider.dart';
import 'package:code_learn_app/services/share_service.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:code_learn_app/theme/app_theme.dart';
import 'package:code_learn_app/widgets/widget_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// 学习成果卡片与结业证书：屏幕渲染、分享通道与完成度判定。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentProvider content;

  setUpAll(() async {
    content = ContentProvider();
    await content.load();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required StorageService storage,
    required ProgressProvider progress,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(storage),
          ),
          ChangeNotifierProvider<ProgressProvider>.value(value: progress),
          ChangeNotifierProvider<ContentProvider>.value(value: content),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          builder: textScale == 1.0
              ? null
              : (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child!,
                ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('分享图片通道', () {
    test('把 PNG 字节、文件名与文案交给原生层', () async {
      const channel = MethodChannel(ShareService.channelName);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      MethodCall? received;
      messenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final bytes = Uint8List.fromList(<int>[137, 80, 78, 71]);
      final shared = await const ShareService().shareImage(
        bytes,
        fileName: 'code_learn_card.png',
        text: '学习成果',
      );

      expect(shared, isTrue);
      expect(received?.method, 'shareImage');
      final args = (received!.arguments as Map).cast<String, Object?>();
      expect(args['bytes'], bytes);
      expect(args['fileName'], 'code_learn_card.png');
      expect(args['text'], '学习成果');
    });

    test('原生层拒绝或没有通道时返回 false', () async {
      const channel = MethodChannel(ShareService.channelName);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async => false);
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      expect(
        await const ShareService().shareImage(Uint8List.fromList(<int>[1])),
        isFalse,
      );
      // 空字节不触发平台调用。
      expect(await const ShareService().shareImage(Uint8List(0)), isFalse);
    });
  });

  testWidgets('学习成果卡片按本机数据渲染并可截图', (tester) async {
    final storage = StorageService.inMemory();
    final progress = ProgressProvider(storage);
    final lesson = content.allLessons.first;
    await progress.markLearned(lesson.id);
    await progress.toggleFavorite(lesson.id);

    await pumpScreen(
      tester,
      const ShareCardScreen(),
      storage: storage,
      progress: progress,
    );

    expect(find.text('我的学习成果'), findsOneWidget);
    expect(find.text('已学课程'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('/ ${content.totalLessons}'), findsOneWidget);
    expect(find.text('已收藏 1 · 笔记 0'), findsOneWidget);
    expect(find.text('分享图片'), findsOneWidget);
  });

  testWidgets('WidgetSnapshot 能把卡片导出为 PNG', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(width: 120, height: 80, color: Colors.blue),
          ),
        ),
      ),
    );

    final bytes = await tester.runAsync(
      () => WidgetSnapshot.capturePng(key, pixelRatio: 2),
    );
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(100));

    // 未挂载的 key 应安全返回 null，而不是抛异常。
    expect(await WidgetSnapshot.capturePng(GlobalKey()), isNull);
  });

  testWidgets('证书列表显示完成度并只允许打开已完成分类', (tester) async {
    final storage = StorageService.inMemory();
    final progress = ProgressProvider(storage);
    final category = _smallestCategory(content.categories);
    for (final lesson in category.lessons) {
      await progress.markLearned(lesson.id);
    }
    final title = category.title.zh;

    await pumpScreen(
      tester,
      const CertificateScreen(),
      storage: storage,
      progress: progress,
    );

    expect(
      find.text('已领取 1/${content.categories.length} 个分类证书'),
      findsOneWidget,
    );
    expect(find.text('可领取'), findsOneWidget);
    expect(find.text('学习中'), findsWidgets);
    expect(find.text(title), findsOneWidget);

    await tester.ensureVisible(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();

    expect(find.text('结业证书'), findsOneWidget);
    expect(find.text('CERTIFICATE OF COMPLETION'), findsOneWidget);
    expect(find.text('兹证明'), findsOneWidget);
    expect(find.textContaining('已完成《$title》全部'), findsOneWidget);
    expect(find.text('分享证书'), findsOneWidget);
  });

  testWidgets('未完成的分类点击后不会打开证书', (tester) async {
    final storage = StorageService.inMemory();
    final progress = ProgressProvider(storage);
    final category = _smallestCategory(content.categories);

    await pumpScreen(
      tester,
      const CertificateScreen(),
      storage: storage,
      progress: progress,
    );

    expect(
      find.text('已领取 0/${content.categories.length} 个分类证书'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text(category.title.zh));
    await tester.pumpAndSettle();
    await tester.tap(find.text(category.title.zh));
    await tester.pumpAndSettle();

    expect(find.text('结业证书'), findsNothing);
    expect(find.text('分享证书'), findsNothing);
    expect(find.text('学习证书'), findsOneWidget);
  });

  testWidgets('系统 2 倍字号下分享卡与证书都不溢出', (tester) async {
    final storage = StorageService.inMemory();
    final progress = ProgressProvider(storage);

    await pumpScreen(
      tester,
      const ShareCardScreen(),
      storage: storage,
      progress: progress,
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      CertificateViewScreen(
        categoryId: _smallestCategory(content.categories).id,
      ),
      storage: storage,
      progress: progress,
      textScale: 2.0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('英文界面证书与分享卡都使用英文且不溢出', (tester) async {
    final storage = StorageService.inMemory();
    await storage.write('locale_code', 'en');
    final progress = ProgressProvider(storage);

    await pumpScreen(
      tester,
      CertificateViewScreen(
        categoryId: _smallestCategory(content.categories).id,
      ),
      storage: storage,
      progress: progress,
    );

    expect(find.text('Certificate'), findsOneWidget);
    expect(find.text('结业证书'), findsNothing);
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      const ShareCardScreen(),
      storage: storage,
      progress: progress,
    );

    expect(find.text('My learning journey'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpScreen(
      tester,
      const ShareCardScreen(),
      storage: storage,
      progress: progress,
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
  });
}

LessonCategory _smallestCategory(List<LessonCategory> categories) {
  return categories
      .where((category) => category.lessons.isNotEmpty)
      .reduce((a, b) => a.lessons.length <= b.lessons.length ? a : b);
}
