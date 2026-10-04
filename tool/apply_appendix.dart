// 教程附录批量追加工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_appendix.dart tool/appendix_batches
//   dart tool/apply_appendix.dart tool/appendix_v2 --marker=v2
//
// 目录下每个 `<知识点id>.md` 就是该知识点的附录内容，例如
// `tool/appendix_batches/python_variables.md` 会追加到「变量与数据类型」。
//
// 行为：
//   · 从 manifest.json 找到知识点对应的 Markdown 文件；
//   · 若文件里已存在标记行（默认 appendix:v1，可用 --marker=v2 换成第二轮），
//     跳过，保证可以反复执行；
//   · 否则在文件末尾追加「标记 + 内容」，统一使用 UTF-8 编码。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 每篇教程的附录只追加一次，靠这行标记去重。
/// 默认写入第一轮标记 `<!-- appendix:v1 -->`，传入 --marker=v2 则写第二轮。
const String defaultVersion = 'v1';

Future<void> main(List<String> args) async {
  var version = defaultVersion;
  for (final arg in args) {
    if (arg.startsWith('--marker=')) {
      version = arg.substring('--marker='.length).trim();
    }
  }
  final marker = '<!-- appendix:$version -->';
  final paths = args.where((item) => !item.startsWith('--')).toList();

  if (paths.isEmpty) {
    stderr.writeln('请传入存放附录的目录（或 .md 文件路径）');
    exitCode = 1;
    return;
  }

  final files = <File>[];
  for (final path in paths) {
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.directory) {
      files.addAll(
        Directory(path)
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.md')),
      );
    } else {
      files.add(File(path));
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));

  final manifest = jsonDecode(await File(manifestPath).readAsString());
  final lessons = <String, Map<String, dynamic>>{};
  for (final category in (manifest['categories'] as List)) {
    for (final lesson in (category['lessons'] as List)) {
      final map = lesson as Map<String, dynamic>;
      lessons[map['id'] as String] = map;
    }
  }

  final errors = <String>[];
  var appended = 0;
  var skipped = 0;

  for (final file in files) {
    final lessonId = file.uri.pathSegments.last.replaceAll('.md', '');
    final lesson = lessons[lessonId];
    if (lesson == null) {
      errors.add('${file.path}：找不到 id 为 $lessonId 的知识点');
      continue;
    }
    final body = await file.readAsString();
    if (body.trim().length < 80) {
      errors.add('${file.path}：附录内容过短');
      continue;
    }

    final target = File(lesson['file'] as String);
    if (!target.existsSync()) {
      errors.add('${file.path}：目标教程 ${lesson['file']} 不存在');
      continue;
    }
    final original = await target.readAsString();
    if (original.contains(marker)) {
      skipped++;
      continue;
    }

    final buffer = StringBuffer(original.trimRight())
      ..writeln()
      ..writeln()
      ..writeln(marker)
      ..writeln()
      ..writeln(body.trim());
    await target.writeAsString(buffer.toString());
    appended++;
  }

  if (errors.isNotEmpty) {
    stderr.writeln('校验失败，未处理的条目如下：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    stderr.writeln('共 ${errors.length} 条问题');
    exitCode = 1;
    return;
  }

  stdout.writeln('已追加附录 $appended 篇，跳过（已存在）$skipped 篇');
}
