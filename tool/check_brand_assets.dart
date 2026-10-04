// 品牌资源自检（开发期脚本，不参与 App 打包）。
//
// 用法：
//   dart tool/check_brand_assets.dart
//
// 校验内容：
//   1. 各密度启动图标 / 圆形图标 / 启动页标记是否齐全且尺寸正确；
//   2. 自适应图标前景是否落在 66x66dp 安全区内（避免被启动器遮罩裁切）；
//   3. 清单、字符串、样式对图标的引用是否都能解析到真实资源。
import 'dart:io';

const _iconDensities = <String, int>{
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

const _splashDensities = <String, int>{
  'mdpi': 96,
  'hdpi': 144,
  'xhdpi': 192,
  'xxhdpi': 288,
  'xxxhdpi': 384,
};

/// Android 自适应图标保证可见的中心区域（108dp 画布内 66dp 居中）。
const double _safeMin = 21;
const double _safeMax = 87;

int _failures = 0;

void _check(bool ok, String message) {
  if (ok) {
    stdout.writeln('  ok   $message');
  } else {
    _failures++;
    stdout.writeln('  FAIL $message');
  }
}

/// 读取 PNG 的 IHDR，返回像素宽高。
({int width, int height}) _pngSize(File file) {
  final bytes = file.readAsBytesSync();
  if (bytes.length < 24) {
    throw StateError('${file.path} 不是有效的 PNG');
  }
  int readInt(int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  return (width: readInt(16), height: readInt(20));
}

/// 解析 VectorDrawable 里 pathData 的所有坐标点。
List<(double x, double y)> _pathPoints(String xml) {
  final points = <(double, double)>[];
  for (final match in RegExp(r'pathData\s*=\s*"([^"]+)"').allMatches(xml)) {
    final tokens = (match.group(1) ?? '').trim().split(RegExp(r'\s+'));
    for (final token in tokens) {
      final body = token.replaceFirst(RegExp(r'^[A-Za-z]'), '');
      final parts = body.split(',');
      if (parts.length != 2) continue;
      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);
      if (x != null && y != null) points.add((x, y));
    }
  }
  return points;
}

double? _strokeWidth(String xml) {
  final match = RegExp(r'strokeWidth\s*=\s*"([\d.]+)"').firstMatch(xml);
  return match == null ? null : double.tryParse(match.group(1)!);
}

void main() {
  final root = Directory.current;
  final res = Directory('${root.path}/android/app/src/main/res');
  if (!res.existsSync()) {
    stderr.writeln('找不到 android/app/src/main/res，请在项目根目录执行。');
    exitCode = 1;
    return;
  }

  stdout.writeln('== 启动图标与启动页标记 ==');
  for (final entry in _iconDensities.entries) {
    final size = entry.value;
    for (final name in ['ic_launcher', 'ic_launcher_round']) {
      final file = File('${res.path}/mipmap-${entry.key}/$name.png');
      if (!file.existsSync()) {
        _check(false, 'mipmap-${entry.key}/$name.png 缺失');
        continue;
      }
      final dimension = _pngSize(file);
      _check(
        dimension.width == size && dimension.height == size,
        'mipmap-${entry.key}/$name.png 尺寸 ${dimension.width}x${dimension.height}（期望 ${size}x$size）',
      );
    }
  }

  for (final entry in _splashDensities.entries) {
    final file = File('${res.path}/drawable-${entry.key}/splash_mark.png');
    if (!file.existsSync()) {
      _check(false, 'drawable-${entry.key}/splash_mark.png 缺失');
      continue;
    }
    final dimension = _pngSize(file);
    _check(
      dimension.width == entry.value && dimension.height == entry.value,
      'drawable-${entry.key}/splash_mark.png 尺寸 ${dimension.width}x${dimension.height}',
    );
  }

  stdout.writeln('== 自适应图标 ==');
  for (final name in ['ic_launcher', 'ic_launcher_round']) {
    final file = File('${res.path}/mipmap-anydpi-v26/$name.xml');
    if (!file.existsSync()) {
      _check(false, 'mipmap-anydpi-v26/$name.xml 缺失');
      continue;
    }
    final xml = file.readAsStringSync();
    _check(
      xml.contains('@drawable/ic_launcher_background') &&
          xml.contains('@drawable/ic_launcher_foreground'),
      'mipmap-anydpi-v26/$name.xml 引用前景与背景',
    );
  }

  final foreground = File('${res.path}/drawable/ic_launcher_foreground.xml');
  final background = File('${res.path}/drawable/ic_launcher_background.xml');
  _check(foreground.existsSync(), 'drawable/ic_launcher_foreground.xml 存在');
  _check(background.existsSync(), 'drawable/ic_launcher_background.xml 存在');

  if (foreground.existsSync()) {
    final xml = foreground.readAsStringSync();
    final points = _pathPoints(xml);
    final stroke = _strokeWidth(xml) ?? 0;
    _check(points.isNotEmpty, '前景矢量包含路径坐标（${points.length} 个点）');
    if (points.isNotEmpty) {
      final minX =
          points.map((p) => p.$1).reduce((a, b) => a < b ? a : b) - stroke / 2;
      final maxX =
          points.map((p) => p.$1).reduce((a, b) => a > b ? a : b) + stroke / 2;
      final minY =
          points.map((p) => p.$2).reduce((a, b) => a < b ? a : b) - stroke / 2;
      final maxY =
          points.map((p) => p.$2).reduce((a, b) => a > b ? a : b) + stroke / 2;
      final inside =
          minX >= _safeMin &&
          maxX <= _safeMax &&
          minY >= _safeMin &&
          maxY <= _safeMax;
      _check(
        inside,
        '前景落在安全区 ${_safeMin.toInt()}~${_safeMax.toInt()}dp 内'
        '（实际 x ${minX.toStringAsFixed(1)}~${maxX.toStringAsFixed(1)}，'
        'y ${minY.toStringAsFixed(1)}~${maxY.toStringAsFixed(1)}）',
      );
    }
  }

  stdout.writeln('== 清单与样式引用 ==');
  final manifest = File(
    '${root.path}/android/app/src/main/AndroidManifest.xml',
  );
  final manifestText = manifest.existsSync() ? manifest.readAsStringSync() : '';
  _check(
    manifestText.contains('android:icon="@mipmap/ic_launcher"'),
    '清单引用普通图标',
  );
  _check(
    manifestText.contains('android:roundIcon="@mipmap/ic_launcher_round"'),
    '清单引用圆形图标',
  );
  _check(
    manifestText.contains('android:label="@string/app_name"'),
    '清单使用字符串资源作为应用名',
  );

  for (final locale in ['values', 'values-en']) {
    final strings = File('${res.path}/$locale/strings.xml');
    final text = strings.existsSync() ? strings.readAsStringSync() : '';
    _check(
      RegExp(r'<string name="app_name">.+</string>').hasMatch(text),
      '$locale/strings.xml 定义了非空 app_name',
    );
  }

  for (final locale in ['values-v31', 'values-night-v31']) {
    final styles = File('${res.path}/$locale/styles.xml');
    final text = styles.existsSync() ? styles.readAsStringSync() : '';
    _check(
      text.contains('windowSplashScreenBackground') &&
          text.contains('windowSplashScreenAnimatedIcon'),
      '$locale/styles.xml 配置了 Android 12+ 启动画面',
    );
  }

  final splashIcon = File('${res.path}/drawable/splash_icon.xml');
  _check(
    splashIcon.existsSync() &&
        splashIcon.readAsStringSync().contains('@drawable/splash_mark'),
    'drawable/splash_icon.xml 引用启动页标记',
  );

  stdout.writeln('== 发布配置 ==');
  final gradle = File('${root.path}/android/app/build.gradle.kts');
  final gradleText = gradle.existsSync() ? gradle.readAsStringSync() : '';
  _check(
    !gradleText.contains('com.example.'),
    'build.gradle.kts 不再使用 com.example 包名',
  );
  _check(
    RegExp(r'applicationId\s*=\s*"([^"]+)"').hasMatch(gradleText),
    'build.gradle.kts 显式声明 applicationId',
  );
  _check(
    gradleText.contains('key.properties') &&
        gradleText.contains('signingConfigs'),
    'build.gradle.kts 从 key.properties 读取发布签名',
  );

  stdout.writeln('');
  if (_failures == 0) {
    stdout.writeln('品牌资源自检全部通过。');
  } else {
    stdout.writeln('品牌资源自检失败 $_failures 项。');
    exitCode = 1;
  }
}
