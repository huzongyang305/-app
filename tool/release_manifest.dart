// 生成发布清单：版本号、文件大小与 SHA-256 校验和。
//
// 用法：
//   dart run tool/release_manifest.dart --version=1.4.0 build/app/outputs/flutter-apk/*.apk
//
// 输出 build/reports/release_manifest.json 与 build/reports/SHA256SUMS.txt，
// 供 GitHub Release 附件与用户校验使用。
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  final files = args.where((arg) => !arg.startsWith('--')).toList();
  var version = '';
  var outputDir = 'build/reports';
  for (final arg in args.where((arg) => arg.startsWith('--'))) {
    if (arg.startsWith('--version=')) {
      version = arg.split('=').last;
    } else if (arg.startsWith('--out=')) {
      outputDir = arg.split('=').last;
    }
  }
  if (files.isEmpty) {
    stderr.writeln('没有提供要发布的文件。');
    exitCode = 2;
    return;
  }
  if (version.isEmpty) version = _readPubspecVersion();

  final artifacts = <Map<String, dynamic>>[];
  final checksumLines = <String>[];
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('找不到文件：$path');
      exitCode = 1;
      return;
    }
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    final name = file.uri.pathSegments.last;
    artifacts.add(<String, dynamic>{
      'name': name,
      'path': path,
      'bytes': bytes.length,
      'mib': double.parse((bytes.length / 1024 / 1024).toStringAsFixed(2)),
      'sha256': digest,
    });
    checksumLines.add('$digest  $name');
  }

  Directory(outputDir).createSync(recursive: true);
  final manifest = <String, dynamic>{
    'version': version,
    'tag': version.startsWith('v') ? version : 'v$version',
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'artifact_count': artifacts.length,
    'artifacts': artifacts,
  };
  File('$outputDir/release_manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  File('$outputDir/SHA256SUMS.txt')
      .writeAsStringSync('${checksumLines.join('\n')}\n');
  stdout.writeln('发布清单（$version，共 ${artifacts.length} 个文件）：');
  for (final artifact in artifacts) {
    stdout.writeln(
      '  ${artifact['name']}  ${artifact['mib']} MiB  '
      '${artifact['sha256']}',
    );
  }
  stdout.writeln('已写入 $outputDir/release_manifest.json');
}

String _readPubspecVersion() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) return '';
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('version:')) {
      return line.split(':').last.trim().split('+').first;
    }
  }
  return '';
}
