// 新分类追加工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/add_categories.dart tool/new_categories.json
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('请传入分类 JSON');
    exitCode = 1;
    return;
  }
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();
  final specs = jsonDecode(await File(args.first).readAsString()) as List;
  var added = 0;
  var skipped = 0;

  for (final raw in specs) {
    final spec = (raw as Map).cast<String, dynamic>();
    final id = spec['id'] as String;
    if (categories.any((category) => category['id'] == id)) {
      skipped++;
      continue;
    }
    final category = {
      'id': id,
      'title': spec['title'],
      'icon': spec['icon'] ?? 'code',
      'color': spec['color'] ?? '2563EB',
      'lessons': <Map<String, dynamic>>[],
    };
    final after = spec['after'] as String?;
    final index = after == null
        ? categories.length
        : categories.indexWhere((item) => item['id'] == after) + 1;
    categories.insert(index <= 0 ? categories.length : index, category);
    added++;
  }

  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
    flush: true,
  );
  stdout.writeln('新增分类：$added，已存在跳过：$skipped');
}
