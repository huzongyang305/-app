// 批次合并工具（开发期使用）：把新旧两批 batches JSON 按 id 合并。
//
// 背景：tool/generate_expansion_lessons.dart 每次只把「本次新生成」的课程写进
// tool/expansion_batches/<category>.json，会覆盖同名的旧批次。为了让批次文件保留
// 全部课程，本工具在生成后用备份目录与当前批次做一次按 id 去重的合并。
//
// 用法：
//   dart tool/merge_lesson_batches.dart <备份目录> [批次目录=tool/expansion_batches]
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('用法：dart tool/merge_lesson_batches.dart <备份目录> [批次目录]');
    exitCode = 1;
    return;
  }
  final backupDir = Directory(args.first);
  final targetDir = Directory(
    args.length > 1 ? args[1] : 'tool/expansion_batches',
  );
  if (!backupDir.existsSync()) {
    stderr.writeln('备份目录不存在：${backupDir.path}');
    exitCode = 1;
    return;
  }

  final newBatches = <String, Map<String, dynamic>>{};
  for (final file in targetDir.listSync().whereType<File>().where(
    (item) => item.path.toLowerCase().endsWith('.json'),
  )) {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map) continue;
    final category = json['category']?.toString() ?? '';
    if (category.isEmpty) continue;
    newBatches[category] = (json).cast<String, dynamic>();
  }

  var merged = 0;
  for (final entry in newBatches.entries) {
    final category = entry.key;
    final byId = <String, Map<String, dynamic>>{};
    final backupFile = File('${backupDir.path}/$category.json');
    if (backupFile.existsSync()) {
      final old = jsonDecode(backupFile.readAsStringSync());
      if (old is Map) {
        for (final raw in (old['lessons'] as List? ?? const [])) {
          final lesson = (raw as Map).cast<String, dynamic>();
          byId[lesson['id'].toString()] = lesson;
        }
      }
    }
    var added = 0;
    for (final raw in (entry.value['lessons'] as List? ?? const [])) {
      final lesson = (raw as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (byId.containsKey(id)) continue; // 已存在则保留旧条目
      byId[id] = lesson;
      added++;
    }
    final lessons = byId.values.toList()
      ..sort((a, b) {
        final orderA = int.tryParse('${a['order'] ?? 0}') ?? 0;
        final orderB = int.tryParse('${b['order'] ?? 0}') ?? 0;
        final cmp = orderA.compareTo(orderB);
        return cmp != 0 ? cmp : '${a['id']}'.compareTo('${b['id']}');
      });
    File('${targetDir.path}/$category.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ')
          .convert(<String, dynamic>{'category': category, 'lessons': lessons}),
    );
    stdout.writeln('$category：合并后 ${lessons.length} 条（新增 $added 条）');
    merged++;
  }
  stdout.writeln('完成，处理 $merged 个分类批次');
}
