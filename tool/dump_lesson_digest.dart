// P0 辅助工具：为受元问题影响的课程导出精简讲义摘要，
// 供人工重写测验题时核对知识点，不参与 App 打包。
//
// 用法：
//   dart tool/dump_lesson_digest.dart [--ids=a,b,c] [--chars=1600]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

void main(List<String> args) {
  final idsArg = args
      .firstWhere((a) => a.startsWith('--ids='), orElse: () => '--ids=')
      .substring('--ids='.length);
  final ids = idsArg.isEmpty ? <String>{} : idsArg.split(',').toSet();
  final perLesson =
      int.tryParse(
        args
            .firstWhere(
              (a) => a.startsWith('--chars='),
              orElse: () => '--chars=1600',
            )
            .substring('--chars='.length),
      ) ??
      1600;

  final root = Directory.current.path;
  final manifest = jsonDecode(
    File('$root/$manifestPath').readAsStringSync(),
  ) as Map<String, dynamic>;
  final buffer = StringBuffer();
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'] as String;
      if (ids.isNotEmpty && !ids.contains(id)) continue;
      final title = (lesson['title'] as Map)['zh'];
      final file = (lesson['file'] as String).replaceAll('\\', '/');
      final markdown = File('$root/$file').readAsStringSync();
      final text = _digest(markdown, perLesson);
      buffer.writeln('## $id | $title | ${category['id']}');
      buffer.writeln(text.trim());
      buffer.writeln();
      buffer.writeln('现有测验：');
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final q = (rawQuestion as Map).cast<String, dynamic>();
        final options = ((q['options'] as List<dynamic>?) ?? const [])
            .cast<String>();
        final answer = (q['answer'] as num?)?.toInt() ?? 0;
        final answerText = options.isEmpty || answer >= options.length
            ? ''
            : options[answer];
        buffer.writeln(
          '- [${q['type'] ?? 'single'}] ${q['question']} => $answerText',
        );
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
  }
  final out = File('tool/reports/p0_lesson_digest.md');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(buffer.toString());
  stdout.writeln('已写入 ${out.path}（${buffer.length} 字符）');
}

/// 只保留「一句话入门 / 最小示例 / 预期输出 / 常见错误 / 学习目标」等
/// 能直接支撑出题的小节，其余小节仅保留标题作为结构索引。
String _digest(String markdown, int budget) {
  const keepSections = <String>[
    '学习目标',
    '一句话入门',
    '最小示例',
    '预期输出',
    '常见错误',
    '常见误区',
    '易错点',
    '适用边界',
  ];
  const skipSections = <String>[
    '考点精讲',
    '代码实验',
    'English Overview',
    '内容元数据',
    '参考资料与复核',
    '专属复习题库',
  ];
  final lines = markdown.split('\n');
  final out = <String>[];
  var keep = false;
  var inFence = false;
  var codeLines = 0;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      if (inFence && keep) out.add('  ```${trimmed.substring(3)}');
      if (!inFence && keep) out.add('  ```');
      codeLines = 0;
      continue;
    }
    if (!inFence && trimmed.startsWith('#')) {
      final heading = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
      final spaceIndex = trimmed.indexOf(' ');
      final level = spaceIndex == -1 ? trimmed.length : spaceIndex;
      // 只有二级标题才重新决定是否保留正文，避免三级标题里的
      // 「最小示例」等字样误触发保留逻辑。
      if (level <= 2) {
        keep =
            keepSections.any(heading.contains) &&
            !skipSections.any(heading.contains);
      }
      if (level <= 3) out.add(trimmed);
      continue;
    }
    if (inFence) {
      if (keep && codeLines < 12) {
        out.add('  $trimmed');
        codeLines++;
      }
      continue;
    }
    if (!keep || trimmed.isEmpty) continue;
    out.add(trimmed.length > 150 ? '${trimmed.substring(0, 150)}…' : trimmed);
    if (out.join('\n').length > budget) break;
  }
  return out.join('\n');
}
