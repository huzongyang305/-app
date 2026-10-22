// P0 收尾：清理由旧故障模板扩散到考点、复习清单和小结里的机械句。
//
// 用法：
//   dart tool/clean_legacy_template_lines.dart --dry-run
//   dart tool/clean_legacy_template_lines.dart
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> _removedGenericLines = <String>[
  '本课由 P1 内容扩展生成',
  '先保证正确与可复现，再讨论性能和扩展',
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <Map<String, dynamic>>[
    for (final rawCategory in manifest['categories'] as List<dynamic>)
      for (final raw in (rawCategory as Map)['lessons'] as List<dynamic>)
        (raw as Map).cast<String, dynamic>(),
  ];

  var changedLessons = 0;
  var changedLines = 0;
  var removedLines = 0;
  final samples = <String>[];

  for (final lesson in lessons) {
    final file = File(lesson['file'].toString());
    if (!file.existsSync()) continue;
    final title = ((lesson['title'] as Map?)?['zh'] ?? lesson['id']).toString();
    final keywords = ((lesson['keywords'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .take(4)
        .join('、');
    final lines = file.readAsLinesSync();
    final output = <String>[];
    var localChanges = 0;

    for (final line in lines) {
      if (_removedGenericLines.any(line.contains)) {
        removedLines++;
        localChanges++;
        continue;
      }
      if (line.contains('检查调用链、输入数据和环境配置')) {
        output.add('- 检查点：在《$title》中用最小输入复现问题，逐项核对版本、边界和失败路径后再修改。');
        changedLines++;
        localChanges++;
        continue;
      }
      if (line.contains('常规用例通过，但边界用例失败')) {
        output.add('- 检查点：用空值、极值和依赖失败各跑一次《$title》，确认边界行为与正文一致。');
        changedLines++;
        localChanges++;
        continue;
      }
      if (line.contains('结果在两次运行之间不一致')) {
        output.add('- 检查点：固定版本与输入重跑《$title》，记录两次差异并定位不稳定条件。');
        changedLines++;
        localChanges++;
        continue;
      }
      if (line.contains('本课属于「')) {
        output.add(
          keywords.isEmpty
              ? '- 本课围绕 $title 的核心流程展开，复习时重点核对输入、输出和失败路径。'
              : '- 本课围绕 $keywords 展开，复习时重点核对它们的输入、输出和失败路径。',
        );
        changedLines++;
        localChanges++;
        continue;
      }
      output.add(line);
    }

    if (localChanges == 0) continue;
    changedLessons++;
    if (samples.length < 12) {
      samples.add('${lesson['id']}  行改动=$localChanges');
    }
    if (!dryRun) {
      file.writeAsStringSync('${output.join('\n').trimRight()}\n', flush: true);
    }
  }

  stdout.writeln('模式        ${dryRun ? 'dry-run（不写文件）' : '清理'}');
  stdout.writeln('改动课程     $changedLessons');
  stdout.writeln('改写行数     $changedLines');
  stdout.writeln('删除通用句   $removedLines');
  if (samples.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 抽样 ---');
    for (final sample in samples) {
      stdout.writeln(sample);
    }
  }
}
