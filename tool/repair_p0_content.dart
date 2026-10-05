// P0 内容修复工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/repair_p0_content.dart [--dry-run] [--stage=dedupe|examples|appendix|verify|all]
//
// 修复三类会被用户直接看到的内容硬伤：
//   1. dedupe   —— 同一篇教程里重复出现的整个 H2 章节（生成脚本重复执行导致）
//   2. examples —— 仍是 2+3 / bin(10) 占位符的最小示例，替换为主题化示例并校准预期输出
//   3. appendix —— 「课程专属精读」用字段名当概念（如「一句话入门 与相邻主题的边界是什么？」）
//
// 工具幂等：重复执行不会二次改写已经修好的文件。
import 'dart:io';

import 'p0_minimal_examples.dart';

const String contentDir = 'assets/content';

/// 与相邻主题边界这种模板句，说明精读章节是用字段名生成的。
const String placeholderQuestion = '与相邻主题的边界是什么';

/// 精读章节里被当成概念使用的脚手架字段名。
const List<String> scaffoldAnchors = <String>[
  '一句话入门',
  '最小示例',
  '常见错误',
  '适用边界',
  '测试与验证',
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final debug = args.contains('--debug');
  final stage = args
      .firstWhere(
        (arg) => arg.startsWith('--stage='),
        orElse: () => '--stage=all',
      )
      .substring('--stage='.length);

  final files =
      Directory(contentDir)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var changed = 0;
  if (stage == 'dedupe' || stage == 'all') {
    changed += _run(files, dryRun, '去重重复章节', _dedupe, debug: debug);
  }
  if (stage == 'examples' || stage == 'all') {
    changed += _run(files, dryRun, '替换占位最小示例', _replaceExample, debug: debug);
  }
  if (stage == 'appendix' || stage == 'all') {
    changed += _run(files, dryRun, '重写占位精读章节', _rewriteAppendix, debug: debug);
  }
  if (stage == 'verify' || stage == 'all') {
    _verify(files);
  }
  stdout.writeln('完成：$changed 个文件被修改${dryRun ? '（dry-run）' : ''}');
}

int _run(
  List<File> files,
  bool dryRun,
  String label,
  String? Function(String text, String lessonId) transform, {
  bool debug = false,
}) {
  var changed = 0;
  final preview = <String>[];
  for (final file in files) {
    final lessonId = file.uri.pathSegments.last.replaceAll('.md', '');
    final before = file.readAsStringSync();
    final after = transform(before, lessonId);
    if (after == null || after == before) continue;
    changed++;
    if (preview.length < 12) preview.add(lessonId);
    if (debug && changed <= 3) _printDiff(lessonId, before, after);
    if (dryRun) continue;
    file.writeAsStringSync(after);
  }
  stdout.writeln(
    '$label：$changed 个文件${preview.isEmpty ? '' : '（${preview.join(', ')}${changed > preview.length ? ' …' : ''}）'}',
  );
  return changed;
}

void _printDiff(String name, String before, String after) {
  var index = 0;
  while (index < before.length &&
      index < after.length &&
      before.codeUnitAt(index) == after.codeUnitAt(index)) {
    index++;
  }
  final from = index < 80 ? 0 : index - 80;
  stdout.writeln('--- diff $name @$index ---');
  stdout.writeln(
    'BEFORE<<${before.substring(from, index + 120 > before.length ? before.length : index + 120)}>>',
  );
  stdout.writeln(
    'AFTER <<${after.substring(from, index + 120 > after.length ? after.length : index + 120)}>>',
  );
}

// ---------------------------------------------------------------------------
// 1. 章节去重
// ---------------------------------------------------------------------------

/// 删除重复出现的 H2 章节（保留第一次出现），并把被删章节里的 HTML 注释标记
/// 追加到文末，避免生成工具的幂等标记丢失。
String? _dedupe(String text, String lessonId) {
  final lines = text.split('\n');
  final spans = <_Span>[];
  for (var i = 0; i < lines.length; i++) {
    if (RegExp(r'^##\s+\S').hasMatch(lines[i])) {
      spans.add(_Span(i, lines[i].replaceFirst(RegExp(r'^##\s+'), '').trim()));
    }
  }
  if (spans.isEmpty) return null;

  final seen = <String>{};
  final drop = <int, int>{}; // 起始行 -> 结束行（不含）
  for (var i = 0; i < spans.length; i++) {
    final span = spans[i];
    final end = i + 1 < spans.length ? spans[i + 1].line : lines.length;
    if (seen.add(span.title)) continue;
    drop[span.line] = end;
  }
  if (drop.isEmpty) return null;

  final markers = <String>[];
  final kept = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final end = drop[i];
    if (end != null) {
      for (var j = i; j < end; j++) {
        markers.addAll(
          RegExp(r'<!--.*?-->')
              .allMatches(lines[j])
              .map((match) => match.group(0)!),
        );
      }
      i = end - 1;
      continue;
    }
    kept.add(lines[i]);
  }

  final trimmed = <String>[...kept];
  while (trimmed.isNotEmpty && trimmed.last.trim().isEmpty) {
    trimmed.removeLast();
  }
  for (final marker in markers.toSet()) {
    if (!trimmed.contains(marker)) trimmed.add(marker);
  }
  return '${trimmed.join('\n')}\n';
}

class _Span {
  const _Span(this.line, this.title);

  final int line;
  final String title;
}

// ---------------------------------------------------------------------------
// 2. 最小示例 / 预期输出
// ---------------------------------------------------------------------------

String? _replaceExample(String text, String lessonId) {
  final example = p0MinimalExamples[lessonId];
  if (example == null) return null;

  var updated = _replaceFirstFence(
    text,
    RegExp(r'##\s+最小(?:可运行)?示例'),
    example.language,
    example.code,
  );
  updated = _replaceOutput(updated, example.output);
  return updated == text ? null : updated;
}

/// 预期输出章节可能没有代码围栏，此时直接替换正文段落。
String _replaceOutput(String text, String output) {
  final replaced = _replaceFirstFence(
    text,
    RegExp(r'##\s+预期输出'),
    'text',
    output,
  );
  if (replaced != text) return replaced;

  final section = RegExp(r'##\s+预期输出').firstMatch(text);
  if (section == null) return text;
  final start = section.end;
  final nextHeading = RegExp(r'\n##\s').firstMatch(text.substring(start));
  final end = nextHeading == null ? text.length : start + nextHeading.start;
  return '${text.substring(0, start)}\n\n```text\n$output\n```\n'
      '${text.substring(end)}';
}

/// 把 [sectionPattern] 章节里的第一个围栏代码块替换成 [code]。
String _replaceFirstFence(
  String text,
  RegExp sectionPattern,
  String language,
  String code,
) {
  final section = sectionPattern.firstMatch(text);
  if (section == null) return text;
  final start = section.end;
  final nextHeading = RegExp(r'\n##\s').firstMatch(text.substring(start));
  final end = nextHeading == null ? text.length : start + nextHeading.start;
  final body = text.substring(start, end);
  final fence = RegExp(
    r'```[a-zA-Z0-9_+#-]*\r?\n(.*?)\r?\n```',
    dotAll: true,
  ).firstMatch(body);
  if (fence == null) return text;
  final replacement = '```$language\n$code\n```';
  final newBody = body.replaceRange(fence.start, fence.end, replacement);
  return text.substring(0, start) + newBody + text.substring(end);
}

// ---------------------------------------------------------------------------
// 3. 精读章节重写
// ---------------------------------------------------------------------------

/// 这些 H2 是脚手架或速查表，不能当成知识点写进精读。
final RegExp _nonTeachingHeading = RegExp(
  r'^(学习目标|前置知识|本课小结|动手练习|自测清单|English|内容元数据|'
  r'参考资料|课程专属精读|专属复习题库|逐步练习|故障排查|自测与面试|'
  r'专属进阶任务|Bilingual|Full English|相关主题|'
  r'一句话入门|最小示例|最小可运行示例|预期输出|常见错误|常见误区|'
  r'适用边界|测试与验证|验证步骤)',
);

/// 速查表、对照表一类的标题只做检索用，不作为精读主题。
final RegExp _referenceHeading = RegExp(r'(速查|对照表|清单|检查表|术语表|附录)');

/// 脚手架字段名 → 更像知识点的说法。
const Map<String, String> _anchorAlias = <String, String>{
  '一句话入门': '核心概念',
  '最小示例': '最小示例',
  '最小可运行示例': '最小可运行示例',
  '预期输出': '预期输出',
  '常见错误': '常见错误',
  '常见误区': '常见误区',
  '适用边界': '适用边界',
  '测试与验证': '验证方法',
  '验证步骤': '验证方法',
};

String? _rewriteAppendix(String text, String lessonId) {
  // 只删除生成器产出的精读类章节；项目交付物、English Guide、参考资料等
  // 章节必须原样保留，否则会把真正的正文一起删掉。
  final generated = RegExp(r'^(课程专属精读|专属复习题库|逐步练习：|故障排查手册：|自测与面试：|专属进阶任务)');
  final lines = text.split('\n');
  final spans = <_Span>[];
  for (var i = 0; i < lines.length; i++) {
    if (RegExp(r'^##\s+\S').hasMatch(lines[i])) {
      spans.add(_Span(i, lines[i].replaceFirst(RegExp(r'^##\s+'), '').trim()));
    }
  }

  final drops = <int, int>{};
  var insertAt = -1;
  for (var i = 0; i < spans.length; i++) {
    if (!generated.hasMatch(spans[i].title)) continue;
    final end = i + 1 < spans.length ? spans[i + 1].line : lines.length;
    drops[spans[i].line] = end;
    if (insertAt < 0) insertAt = spans[i].line;
  }
  if (insertAt < 0) return null;

  final markers = <String>{};
  final kept = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final end = drops[i];
    if (end != null) {
      for (var j = i; j < end; j++) {
        markers.addAll(
          RegExp(r'<!--.*?-->')
              .allMatches(lines[j])
              .map((match) => match.group(0)!),
        );
      }
      if (i == insertAt) kept.add('@@APPENDIX@@');
      i = end - 1;
      continue;
    }
    kept.add(lines[i]);
  }

  final title = RegExp(
    r'^#\s+(.+?)\s*$',
    multiLine: true,
  ).firstMatch(text)?.group(1)?.trim();
  if (title == null || title.isEmpty) return null;

  // 少数课程正文几乎全是速查表，严格筛选后凑不满三个主题，
  // 这时放宽到「速查表也算主题」，仍然按真实正文抽取要点。
  final strict = _teachingAnchors(text);
  final anchors = strict.length >= 3
      ? strict
      : _teachingAnchors(text, relaxed: true);

  // 真实教学主题不足三个时，直接删除旧的脚手架精读段。
  // 保留它会让「核心概念 / 最小示例」这类字段继续冒充知识点。
  if (anchors.length < 3) {
    final cleaned = kept
        .where((line) => line != '@@APPENDIX@@')
        .join('\n')
        .trimRight();
    final buffer = StringBuffer(cleaned);
    for (final marker in markers) {
      buffer
        ..writeln()
        ..writeln(marker);
    }
    return '${buffer.toString().trimRight()}\n';
  }

  final appendix = _buildAppendix(title, anchors, markers);
  final updated = kept
      .join('\n')
      .replaceFirst('@@APPENDIX@@', appendix.trimRight());
  return updated == text ? null : updated;
}

class _Anchor {
  const _Anchor(this.title, this.summary, this.hasCode);

  final String title;
  final String summary;
  final bool hasCode;
}

/// 从正文的 H2 章节里挑出真正的教学主题，并抽取一句话要点。
List<_Anchor> _teachingAnchors(String text, {bool relaxed = false}) {
  final teachingEnd =
      <RegExp>[
            RegExp(r'^##\s+English Overview', multiLine: true),
            RegExp(r'^##\s+内容元数据', multiLine: true),
          ]
          .map((pattern) => pattern.firstMatch(text)?.start)
          .whereType<int>()
          .fold<int>(text.length, (min, value) => value < min ? value : min);

  final body = text.substring(0, teachingEnd);
  final headings = RegExp(
    r'^##\s+(.+?)\s*$',
    multiLine: true,
  ).allMatches(body).toList();

  final anchors = <_Anchor>[];
  final seen = <String>{};
  for (var i = 0; i < headings.length; i++) {
    final raw = headings[i].group(1)!.trim();
    if (_nonTeachingHeading.hasMatch(raw) ||
        (!relaxed && _referenceHeading.hasMatch(raw))) {
      continue;
    }
    final sectionStart = headings[i].end;
    final sectionEnd = i + 1 < headings.length
        ? headings[i + 1].start
        : body.length;
    final section = body.substring(sectionStart, sectionEnd);
    final summary = _summaryOf(section);
    if (summary.length < 10) continue;
    final title = _anchorAlias[raw] ?? raw;
    if (!seen.add(title)) continue;
    anchors.add(_Anchor(title, summary, section.contains('```')));
    if (anchors.length == 6) break;
  }
  return anchors;
}

/// 抽章节的第一段正文，去掉 Markdown 标记并截断成一句话。
String _summaryOf(String section) {
  final buffer = <String>[];
  for (final rawLine in section.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      if (buffer.isNotEmpty) break;
      continue;
    }
    final isMarkup =
        line.startsWith('```') ||
        line.startsWith('|') ||
        line.startsWith('>') ||
        line.startsWith('<!--') ||
        line.startsWith('![');
    if (isMarkup) {
      if (buffer.isNotEmpty) break;
      continue;
    }
    buffer.add(line);
  }
  var summary = buffer.isEmpty ? '' : _cleanMarkdown(buffer.join(' '));
  if (summary.length < 10) {
    // 速查型课程的章节正文常常整段是表格，退化时用表头 + 首行数据生成要点。
    summary = _summaryFromTable(section) ?? summary;
  }
  if (summary.length < 10) return '';

  final stop = summary.indexOf(RegExp(r'[。！？]'));
  if (stop > 8) summary = summary.substring(0, stop + 1);
  if (summary.length > 90) summary = '${summary.substring(0, 88)}…';
  return summary;
}

String _cleanMarkdown(String raw) {
  return raw
      .replaceAll(RegExp(r'^[-*\d.、\s]+'), '')
      .replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1')
      .replaceAll(RegExp(r'[*_`]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _summaryFromTable(String section) {
  final rows = section
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.startsWith('|'))
      .toList();
  if (rows.length < 3) return null;

  List<String> cells(String row) => row
      .split('|')
      .map(_cleanMarkdown)
      .where((cell) => cell.isNotEmpty && !RegExp(r'^-+$').hasMatch(cell))
      .toList();

  final header = cells(rows.first);
  final data = cells(rows[2]);
  if (header.length < 2 || data.length < 2) return null;

  final parts = <String>[];
  for (var i = 0; i < data.length && i < 3; i++) {
    final label = i < header.length ? header[i] : '';
    parts.add(label.isEmpty ? data[i] : '$label：${data[i]}');
  }
  return _cleanMarkdown(parts.join('；'));
}

String _buildAppendix(
  String title,
  List<_Anchor> anchors,
  Set<String> markers,
) {
  final buffer = StringBuffer()
    ..writeln('## 课程专属精读：$title')
    ..writeln()
    ..writeln('### 一、知识地图')
    ..writeln()
    ..writeln('| 主题 | 核心要点 | 验证方式 |')
    ..writeln('| --- | --- | --- |');
  for (final anchor in anchors) {
    buffer.writeln(
      '| ${anchor.title} | ${anchor.summary} | '
      '${anchor.hasCode ? '运行示例 + 换一个边界输入' : '复述要点 + 举一个反例'} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('### 二、机制与验证')
    ..writeln();
  for (var i = 0; i < anchors.length; i++) {
    final anchor = anchors[i];
    buffer.writeln(
      '${i + 1}. **${anchor.title}**：${anchor.summary} '
      '${anchor.hasCode ? '验证方式：先原样运行示例，再把输入换成边界值，对照输出差异。' : '验证方式：先复述要点，再举一个反例说明边界。'}',
    );
  }

  buffer
    ..writeln()
    ..writeln('### 三、专属检查问题')
    ..writeln();
  const questionTemplates = <String>[
    '要解决什么问题？请用一句话说明，并给出一个具体例子。',
    '的输入和输出分别是什么？',
    '最常见的失败方式是什么？如何定位？',
    '的适用边界在哪里？什么情况下不该使用？',
    '和相邻主题相比，最关键的差别是什么？',
    '如何验证自己真的掌握了？写出一个可执行的检查步骤。',
  ];
  for (var i = 0; i < anchors.length; i++) {
    final template = questionTemplates[i % questionTemplates.length];
    buffer.writeln('${i + 1}. 「${anchors[i].title}」$template');
  }

  buffer
    ..writeln()
    ..writeln('### 四、故障排查')
    ..writeln()
    ..writeln('1. 固定输入和环境，确认问题能稳定复现。')
    ..writeln('2. 找到第一个异常状态，不从最终错误倒推。')
    ..writeln('3. 每次只改一个变量，记录预测和真实结果。')
    ..writeln('4. 修复后补边界、失败与重复执行三类测试。')
    ..writeln()
    ..writeln('## 专属复习题库')
    ..writeln();
  for (final anchor in anchors) {
    buffer
      ..writeln('**问：${anchor.title}的核心要点是什么？**')
      ..writeln()
      ..writeln('答：${anchor.summary}')
      ..writeln();
  }

  buffer
    ..writeln('## 逐步练习：$title')
    ..writeln();
  for (var i = 0; i < anchors.length; i++) {
    final anchor = anchors[i];
    buffer
      ..writeln('### 练习 ${i + 1}：${anchor.title}')
      ..writeln()
      ..writeln('1. 不看原文，用自己的话复述：${anchor.summary}')
      ..writeln(
        '2. ${anchor.hasCode ? '跑通本课示例，再把其中一个输入换成边界值，记录输出差异。' : '举一个正例和一个反例，说明边界在哪里。'}',
      )
      ..writeln('3. 把结论写成两行笔记：一行结论，一行验证方式。')
      ..writeln();
  }

  buffer
    ..writeln('## 故障排查手册：$title')
    ..writeln()
    ..writeln('| 现象 | 优先检查 | 修复动作 |')
    ..writeln('| --- | --- | --- |');
  for (final anchor in anchors) {
    buffer.writeln(
      '| 「${anchor.title}」的结果与预期不符 | 输入、环境、依赖版本、日志里的第一条错误 | '
      '固定最小复现，只改一个变量并回归 |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## 自测与面试：$title')
    ..writeln();
  for (var i = 0; i < anchors.length; i++) {
    buffer.writeln(
      '${i + 1}. 「${anchors[i].title}」${questionTemplates[(i + 1) % questionTemplates.length]}',
    );
  }

  buffer
    ..writeln()
    ..writeln('## 专属进阶任务 5：$title')
    ..writeln()
    ..writeln(
      '把本课 ${anchors.length} 个主题串成一个小练习：选其中一个主题做出可运行的例子，'
      '再为另外两个主题各写一条边界用例，最后用一句话说明你的验证结论。',
    )
    ..writeln()
    ..writeln('### 验收标准')
    ..writeln()
    ..writeln('- 例子可以独立运行，输出与预期一致。')
    ..writeln('- 两条边界用例都说清了输入、预期与实际结果。')
    ..writeln('- 验证结论用一句话写清，不依赖“感觉正确”。');

  for (final marker in markers) {
    buffer.writeln();
    buffer.writeln(marker);
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// 校验
// ---------------------------------------------------------------------------

/// 只在代码围栏内识别整行 `2+3` / `print(2 + 3)`，避免误伤
/// 正常讲解中的 `1+2+3=6` 这类算式。
bool _hasTwoPlusThreePlaceholder(String text) {
  var inFence = false;
  final linePattern = RegExp(r'^(?:print\()?2\s*\+\s*3\)?$');
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence && linePattern.hasMatch(trimmed)) return true;
  }
  return false;
}

void _verify(List<File> files) {
  final problems = <String>[];
  for (final file in files) {
    final text = file.readAsStringSync();
    final name = file.uri.pathSegments.last;
    if (_hasTwoPlusThreePlaceholder(text)) {
      problems.add('$name: 仍存在 2+3 占位示例');
    }
    // 只拦截生成器插入的整段占位代码，避免误伤正常讲解进制的课程。
    if (text.contains('print(bin(10), hex(255), 0b1010)')) {
      problems.add('$name: 仍存在 Python 位运算占位片段');
    }
    if (text.contains(placeholderQuestion)) {
      problems.add('$name: 精读章节仍用字段名当概念');
    }
    final titles = RegExp(
      r'^##\s+(.+?)\s*$',
      multiLine: true,
    ).allMatches(text).map((match) => match.group(1)!).toList();
    final counts = <String, int>{};
    for (final title in titles) {
      counts[title] = (counts[title] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      if (entry.value > 1) {
        problems.add('$name: 重复章节「${entry.key}」x${entry.value}');
      }
    }
  }
  if (problems.isEmpty) {
    stdout.writeln('校验通过：教程无占位符、无重复章节');
    return;
  }
  stdout.writeln('校验发现 ${problems.length} 处问题：');
  for (final problem in problems.take(40)) {
    stdout.writeln('  - $problem');
  }
  if (problems.length > 40) stdout.writeln('  ...');
}
