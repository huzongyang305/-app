// 难度标签归一化工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/normalize_difficulty.dart [--dry-run]
//
// 规则：首课不能是高级、末课不能是入门；早期课程不标高级；
// 已确认写反的课程使用显式覆盖，避免机械规则误伤。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const Map<String, String> overrides = <String, String>{
  'ts_types': '基础',
  'ts_narrowing_generics': '进阶',
  'go_interfaces_errors': '进阶',
  'rust_ownership': '进阶',
  'cross_i18n': '进阶',
  'time_complexity': '基础',
  'binary_search': '基础',
  'bubble_sort': '基础',
  'hash_table': '基础',
  'stack_queue': '基础',
  'processes_threads': '基础',
  'security_threat_model': '基础',
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final changes = <String>[];

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final lessons = (category['lessons'] as List).cast<Map<String, dynamic>>()
      ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    for (var index = 0; index < lessons.length; index++) {
      final lesson = lessons[index];
      final id = lesson['id'] as String;
      final ratio = lessons.length <= 1 ? 0.0 : index / (lessons.length - 1);
      final current = lesson['difficulty'] as String? ?? '基础';
      var target = current;

      if (overrides.containsKey(id)) {
        target = overrides[id]!;
      } else if (index == 0 && current == '高级') {
        target = '基础';
      } else if (ratio <= 0.15 && current == '高级') {
        target = '进阶';
      } else if (ratio >= 0.85 && current == '入门') {
        target = '进阶';
      }

      if (target != current) {
        changes.add('$id：$current → $target');
        if (!dryRun) lesson['difficulty'] = target;
      }
    }
  }

  stdout.writeln('${dryRun ? '待调整' : '已调整'}：${changes.length} 课');
  for (final change in changes.take(40)) {
    stdout.writeln('  - $change');
  }
  if (!dryRun && changes.isNotEmpty) {
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
    stdout.writeln('已写入 $manifestPath');
  }
}
