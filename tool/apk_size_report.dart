// APK 体积报告：按 ABI 汇总体积、预算占用与资产目录构成，输出 JSON + Markdown。
//
// 用法：
//   dart run tool/apk_size_report.dart build/app/outputs/flutter-apk/*.apk
//   dart run tool/apk_size_report.dart --budget-mb=90 app-release.apk
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final apks = args.where((arg) => !arg.startsWith('--')).toList();
  if (apks.isEmpty) {
    stderr.writeln(
      '用法：dart run tool/apk_size_report.dart [--budget-mb=90] <apk...>',
    );
    exitCode = 2;
    return;
  }
  var budgetMb = 90.0;
  var outputDir = 'build/reports';
  for (final arg in args.where((arg) => arg.startsWith('--'))) {
    if (arg.startsWith('--budget-mb=')) {
      budgetMb = double.tryParse(arg.split('=').last) ?? budgetMb;
    } else if (arg.startsWith('--out=')) {
      outputDir = arg.split('=').last;
    }
  }

  final entries = <Map<String, dynamic>>[];
  var failed = false;
  for (final path in apks) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('找不到 APK：$path');
      failed = true;
      continue;
    }
    final bytes = file.lengthSync();
    final mib = bytes / 1024 / 1024;
    final overBudget = mib > budgetMb;
    if (overBudget) failed = true;
    entries.add(<String, dynamic>{
      'path': path,
      'name': file.uri.pathSegments.last,
      'bytes': bytes,
      'mib': double.parse(mib.toStringAsFixed(2)),
      'budget_mib': budgetMb,
      'budget_used': double.parse((mib / budgetMb).toStringAsFixed(3)),
      'over_budget': overBudget,
    });
  }

  final assets = <String, dynamic>{
    for (final dir in const [
      'assets/content',
      'assets/content_en',
      'assets/sandbox',
    ])
      dir: _directorySize(Directory(dir)),
  };
  final report = <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'budget_mib': budgetMb,
    'apks': entries,
    'asset_directories': assets,
  };

  Directory(outputDir).createSync(recursive: true);
  File('$outputDir/apk_size_report.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
  );
  File('$outputDir/apk_size_report.md').writeAsStringSync(
    _renderMarkdown(report),
  );
  stdout.writeln(_renderMarkdown(report));
  stdout.writeln('报告已写入 $outputDir/apk_size_report.json');
  if (failed) exitCode = 1;
}

Map<String, int> _directorySize(Directory directory) {
  if (!directory.existsSync()) return <String, int>{'bytes': 0, 'files': 0};
  var bytes = 0;
  var files = 0;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File) {
      bytes += entity.lengthSync();
      files++;
    }
  }
  return <String, int>{'bytes': bytes, 'files': files};
}

String _renderMarkdown(Map<String, dynamic> report) {
  final buffer = StringBuffer()
    ..writeln('# APK 体积报告')
    ..writeln()
    ..writeln('- 生成时间：${report['generated_at']}')
    ..writeln('- 单包预算：${report['budget_mib']} MiB')
    ..writeln()
    ..writeln('| APK | 体积 (MiB) | 预算占用 | 结果 |')
    ..writeln('| --- | --- | --- | --- |');
  for (final raw in (report['apks'] as List)) {
    final item = (raw as Map).cast<String, dynamic>();
    final used = ((item['budget_used'] as num) * 100).toStringAsFixed(1);
    buffer.writeln(
      '| ${item['name']} | ${item['mib']} | $used% | '
      '${item['over_budget'] == true ? '超出预算' : '通过'} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## 资产构成')
    ..writeln()
    ..writeln('| 目录 | 体积 (MiB) | 文件数 |')
    ..writeln('| --- | --- | --- |');
  final assets = (report['asset_directories'] as Map).cast<String, dynamic>();
  for (final entry in assets.entries) {
    final value = (entry.value as Map).cast<String, dynamic>();
    final mib = ((value['bytes'] as int) / 1024 / 1024).toStringAsFixed(2);
    buffer.writeln('| ${entry.key} | $mib | ${value['files']} |');
  }
  return buffer.toString();
}
