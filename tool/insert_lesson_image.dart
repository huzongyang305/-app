// 教程配图插入工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/insert_lesson_image.dart tool/image_batches/v1.json [...]
//
// 批次文件格式：
// {
//   "visual_memory_layout": {
//     "image": "images/memory_layout.png",
//     "alt": "栈、堆与静态区示意图"
//   }
// }
//
// 行为：在教程一级标题后的第一个非空行前插入图片引用，保持 Markdown 幂等；
// 已包含同一图片路径时跳过，不会重复插入。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('请传入至少一个配图批次文件路径');
    exitCode = 1;
    return;
  }

  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  final lessonFiles = <String, String>{};
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessonFiles[lesson['id'] as String] = lesson['file'] as String;
    }
  }

  final errors = <String>[];
  var inserted = 0;
  var skipped = 0;

  for (final path in args) {
    final batch =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    for (final entry in batch.entries) {
      final lessonId = entry.key;
      final config = (entry.value as Map).cast<String, dynamic>();
      final image = config['image'] as String? ?? '';
      final alt = config['alt'] as String? ?? '';
      final lessonFile = lessonFiles[lessonId];

      if (lessonFile == null) {
        errors.add('$path：知识点 $lessonId 不存在');
        continue;
      }
      if (image.isEmpty) {
        errors.add('$path：$lessonId 缺少 image');
        continue;
      }

      final file = File(lessonFile);
      if (!file.existsSync()) {
        errors.add('$path：$lessonId 对应文件不存在（$lessonFile）');
        continue;
      }

      var content = await file.readAsString();
      if (content.contains(']($image)')) {
        skipped++;
        continue;
      }

      final lines = content.split('\n');
      final titleIndex = lines.indexWhere((line) => line.startsWith('# '));
      if (titleIndex < 0) {
        errors.add('$path：$lessonId 缺少一级标题');
        continue;
      }

      var insertAt = titleIndex + 1;
      while (insertAt < lines.length && lines[insertAt].trim().isEmpty) {
        insertAt++;
      }
      lines.insertAll(insertAt, ['![$alt]($image)', '']);
      content = lines.join('\n');
      await file.writeAsString(content, flush: true);
      inserted++;
    }
  }

  stdout.writeln('新增配图：$inserted，已存在跳过：$skipped');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors) {
      stderr.writeln('  $error');
    }
    exitCode = 1;
  }
}
