// 为语言类课程补齐「离线沙箱」实验入口（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart run tool/bind_language_labs.dart           # 预览将要绑定的课程
//   dart run tool/bind_language_labs.dart --write   # 写回 manifest.json
//
// 背景：Python / JavaScript / TypeScript 三门语言课已经带 lab 绑定，
// 而 C / C++ / Java / C# / Go / Rust / Kotlin / Swift / Shell 九类课程的
// lab 还是空的——学生看完教程没有一键跳进沙箱验代码的入口。
// 这里按分类补齐 `sandbox:<语言 id>`，只填空值，不覆盖已有绑定。
import 'dart:convert';
import 'dart:io';

import 'package:code_learn_app/models/sandbox_language.dart';

const String manifestPath = 'assets/content/manifest.json';

/// 分类 id -> 沙箱语言 id。
///
/// C 语言在沙箱里复用 C++ 运行时，和 Markdown 围栏别名 `c -> cpp` 一致。
const Map<String, String> sandboxByCategory = <String, String>{
  'c': 'cpp',
  'cpp': 'cpp',
  'java': 'java',
  'csharp': 'csharp',
  'go': 'go',
  'rust': 'rust',
  'kotlin': 'kotlin',
  'swift': 'swift',
  'shell': 'bash',
};

Future<void> main(List<String> args) async {
  final write = args.contains('--write');
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  var bound = 0;
  var skipped = 0;
  final boundPerCategory = <String, int>{};

  for (final category in categories) {
    final categoryId = category['id'] as String;
    final sandboxId = sandboxByCategory[categoryId];
    if (sandboxId == null) continue;
    // 语言 id 必须是沙箱真实支持的，避免把拼错的名字写进内容清单。
    if (SandboxLanguage.tryFromId(sandboxId) == null) {
      throw StateError('沙箱不支持语言 id：$sandboxId（分类 $categoryId）');
    }
    for (final lesson
        in (category['lessons'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final current = (lesson['lab'] as String? ?? '').trim();
      if (current.isNotEmpty) {
        skipped++;
        continue;
      }
      lesson['lab'] = 'sandbox:$sandboxId';
      bound++;
      boundPerCategory[categoryId] =
          (boundPerCategory[categoryId] ?? 0) + 1;
    }
  }

  for (final entry in boundPerCategory.entries) {
    stdout.writeln(
      '${entry.key.padRight(10)} 新绑定 ${entry.value} 门'
      '（sandbox:${sandboxByCategory[entry.key]}）',
    );
  }
  stdout.writeln('共新绑定 $bound 门课；跳过已有 lab 的课程 $skipped 门');

  if (!write) {
    stdout.writeln('dry-run：未写入文件（加 --write 生效）');
    return;
  }
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('已写入 $manifestPath');
}
