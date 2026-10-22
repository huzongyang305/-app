// P3 内容时效维护：把课程元数据里的「最后更新 / 内容更新时间」统一到最新日期。
//
// 用法：
//   dart tool/refresh_content_dates.dart [--dry-run] [--date=2026-10-06]
//
// 只改写行首为「- 最后更新：」或「> 内容更新时间：」的元数据行，
// 不会触碰正文代码示例中的日期，也不会改动「最后复核 / 下次复核」。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String defaultDate = '2026-10-06';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final target = args
      .firstWhere(
        (arg) => arg.startsWith('--date='),
        orElse: () => '--date=$defaultDate',
      )
      .substring('--date='.length);

  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final files = <String>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      files.add(lesson['file'] as String);
    }
  }

  var changedFiles = 0;
  var changedLines = 0;
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final lines = file.readAsLinesSync();
    var changed = false;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      String? updated;
      if (line.startsWith('- 最后更新：')) {
        updated = '- 最后更新：$target';
      } else if (line.startsWith('> 内容更新时间：')) {
        updated = line.replaceFirst(
          RegExp(r'^> 内容更新时间：[0-9-]+'),
          '> 内容更新时间：$target',
        );
      }
      if (updated != null && updated != line) {
        lines[index] = updated;
        changed = true;
        changedLines++;
      }
    }
    if (changed) {
      changedFiles++;
      if (!dryRun) file.writeAsStringSync('${lines.join('\n')}\n');
    }
  }

  // 内容时间戳跟随目标日期，便于 App 展示与审计对齐。
  if (manifest['content_updated_at'] != target) {
    manifest['content_updated_at'] = target;
    if (!dryRun) {
      File(manifestPath).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      );
    }
  }
  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}更新课程 $changedFiles 篇，'
    '元数据行 $changedLines 处，目标日期 $target',
  );
}
