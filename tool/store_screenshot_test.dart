import 'dart:io';
import 'dart:ui' as ui;

import 'package:code_learn_app/app.dart';
import 'package:code_learn_app/services/content_provider.dart';
import 'package:code_learn_app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 手动生成应用商店截图与功能图：
///   flutter test tool/store_screenshot_test.dart
///
/// 使用 Flutter SDK 自带 Roboto，避免 widget 测试默认 Ahem 字体把文字画成方块。
/// 图片直接从 RepaintBoundary 的渲染结果导出 PNG，不经过 golden comparator，
/// 因此不会把调试基线、尺寸线一类的辅助图层画进商店素材。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentProvider content;

  setUpAll(() async {
    await _loadDeviceFonts();
    content = ContentProvider();
    await content.load();
  });

  Future<void> settleWithIo(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.byType(Scrollable).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpApp(WidgetTester tester, Key key) async {
    final storage = StorageService.inMemory();
    await storage.write('locale_code', 'en');
    await storage.write('theme_mode', 'light');
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: CodeLearnApp(storage: storage, contentProvider: content),
      ),
    );
    await settleWithIo(tester);
  }

  testWidgets('商店截图：英文首页', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('store-home');
    await pumpApp(tester, key);
    await _writeBoundaryPng(tester, key, 'store/screenshots/01_home_en.png');
  });

  testWidgets('商店截图：Python 课程列表', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('store-category');
    await pumpApp(tester, key);
    await tester.scrollUntilVisible(
      find.text('Categories'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Python').first,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Python').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python').first);
    await tester.pumpAndSettle();
    await _writeBoundaryPng(
      tester,
      key,
      'store/screenshots/02_python_courses_en.png',
    );
  });

  testWidgets('商店截图：学习档案', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = ValueKey('store-profile');
    await pumpApp(tester, key);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await _writeBoundaryPng(tester, key, 'store/screenshots/03_profile_en.png');
  });

  testWidgets('商店功能图：1024x500', (tester) async {
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintPointersEnabled = false;
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final icon = File('store/icon_512.png').readAsBytesSync();
    final iconImage = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(icon);
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      return image;
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('store-feature-graphic'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          // 必须给文字一个 Material 祖先，否则 MaterialApp 会套用
          // “缺少 Material”的调试文本样式（红色 + 黄色双下划线）。
          home: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C8FF8), Color(0xFF8BA5FF)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 52,
                    top: 8,
                    child: Opacity(
                      opacity: 0.12,
                      child: Text(
                        '</>',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 220,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(72, 70, 72, 70),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(48),
                          child: RawImage(
                            image: iconImage!,
                            width: 280,
                            height: 280,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 58),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CS & Coding',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontSize: 58,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                '534 offline lessons',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                '2430 quizzes · AI · CS · Code',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 23,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _writeBoundaryPng(
      tester,
      const ValueKey('store-feature-graphic'),
      'store/feature_graphic_1024x500.png',
    );
  });
}

/// 把指定 RepaintBoundary 的当前画面按 1:1 导出为 PNG 文件。
///
/// 商店素材生成脚本没有断言，导出失败会直接抛错，避免静默产出空白图。
Future<void> _writeBoundaryPng(
  WidgetTester tester,
  Key key,
  String path,
) async {
  // 关闭所有调试绘制开关，保证导出的是纯 UI 画面。
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintPointersEnabled = false;
  debugPaintLayerBordersEnabled = false;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });
  if (bytes == null || bytes.isEmpty) {
    throw StateError('商店图片导出失败：$path');
  }
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

Future<void> _loadDeviceFonts() async {
  final fontDir = Directory(
    '${_flutterRoot().path}/bin/cache/artifacts/material_fonts',
  );
  final bytesByFile = <String, ByteData>{};
  Future<ByteData> fontBytes(String name) async {
    return bytesByFile.putIfAbsent(name, () {
      final file = File('${fontDir.path}/$name');
      if (!file.existsSync()) {
        throw StateError('缺少 Flutter SDK 字体：${file.path}');
      }
      return ByteData.sublistView(file.readAsBytesSync());
    });
  }

  for (final family in const ['Roboto', 'FlutterTest', 'Ahem']) {
    final loader = FontLoader(family)..addFont(fontBytes('roboto-regular.ttf'));
    await loader.load();
  }
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(fontBytes('materialicons-regular.otf'));
  await iconLoader.load();
}

Directory _flutterRoot() {
  final configured = Platform.environment['FLUTTER_ROOT'];
  if (configured != null && configured.isNotEmpty) {
    return Directory(configured);
  }
  final executable = File(Platform.resolvedExecutable);
  var directory = executable.parent;
  for (var i = 0; i < 5; i++) {
    final candidate = Directory('${directory.path}/bin/cache/artifacts');
    if (candidate.existsSync()) return directory;
    directory = directory.parent;
  }
  throw StateError('无法从 Dart 可执行文件定位 Flutter SDK。');
}
