// P2 补图：把第二张配图插入到指定小节之前，而不是统一堆在文首。
//
// 用法：
//   dart tool/insert_section_images.dart tool/image_batches/p2_extra.json [--dry-run]
//
// 批次格式：{ "<lessonId>": { "image": "images/x.webp", "alt": "说明", "anchor": "本课小结" } }
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final paths = args.where((arg) => !arg.startsWith('--')).toList();
  if (paths.isEmpty) {
    stderr.writeln('请传入至少一个配图批次文件路径');
    exitCode = 1;
    return;
  }

  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessonFiles = <String, String>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessonFiles[lesson['id'] as String] = lesson['file'] as String;
    }
  }

  final errors = <String>[];
  var inserted = 0;
  var skipped = 0;
  for (final path in paths) {
    final batch =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    for (final entry in batch.entries) {
      final lessonId = entry.key;
      final config = (entry.value as Map).cast<String, dynamic>();
      final image = (config['image'] ?? '').toString();
      final alt = (config['alt'] ?? '').toString().trim();
      final anchor = (config['anchor'] ?? '').toString().trim();
      final lessonFile = lessonFiles[lessonId];
      if (lessonFile == null) {
        errors.add('$path：知识点 $lessonId 不存在');
        continue;
      }
      if (image.isEmpty || alt.isEmpty || anchor.isEmpty) {
        errors.add('$path：$lessonId 的 image/alt/anchor 不能为空');
        continue;
      }
      if (!File('assets/content/$image').existsSync()) {
        errors.add('$path：$lessonId 引用的图片不存在（$image）');
        continue;
      }
      final file = File(lessonFile);
      if (!file.existsSync()) {
        errors.add('$path：$lessonId 对应文件不存在（$lessonFile）');
        continue;
      }
      final content = file.readAsStringSync();
      if (content.contains(']($image)')) {
        skipped++;
        continue;
      }
      final anchorIndex = content.indexOf('\n## $anchor');
      if (anchorIndex < 0) {
        errors.add('$path：$lessonId 找不到小节「$anchor」');
        continue;
      }
      final block = '![$alt]($image)\n\n';
      final updated =
          '${content.substring(0, anchorIndex + 1)}$block'
          '${content.substring(anchorIndex + 1)}';
      if (!dryRun) file.writeAsStringSync(updated, flush: true);
      inserted++;
    }
  }

  stdout.writeln('${dryRun ? '[dry-run] ' : ''}新增配图：$inserted，已存在跳过：$skipped');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors) {
      stderr.writeln('  $error');
    }
    exitCode = 1;
  }
}
