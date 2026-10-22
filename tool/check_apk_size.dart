// 发布包体积门禁：在 CI 中阻止 APK 无提示地继续膨胀。
//
// 用法：
//   dart tool/check_apk_size.dart build/app/outputs/flutter-apk/app-release.apk 90
import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty
      ? args[0]
      : 'build/app/outputs/flutter-apk/app-release.apk';
  final maxMiB = args.length > 1 ? double.tryParse(args[1]) : 90.0;
  if (maxMiB == null || maxMiB <= 0) {
    stderr.writeln('无效的体积上限：${args[1]}');
    exitCode = 2;
    return;
  }
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('找不到 APK：$path');
    exitCode = 1;
    return;
  }
  final bytes = file.lengthSync();
  final mib = bytes / (1024 * 1024);
  stdout.writeln(
    'APK size: ${mib.toStringAsFixed(2)} MiB / limit ${maxMiB.toStringAsFixed(2)} MiB',
  );
  if (mib > maxMiB) {
    stderr.writeln('APK 超出发布体积门禁。');
    exitCode = 1;
  }
}
