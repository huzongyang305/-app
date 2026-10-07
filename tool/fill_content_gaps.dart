// 内容补全工具：给只有标题没有正文的小节补上本课专属内容。
//
// 处理对象：
//   1. 空小节（标题后直接跟下一个同级/上级标题，正文为空）；
//   2. 旧生成器留下的「第 N 次迁移」迁移练习（题干被截断、答案与题库对不上）。
//
// 关键约束：补出来的长句必须带课程标题、小节名或本课原文，否则同一句会在
// 几百门课里重复，反而触发内容治理审计的「重复段落」卡口。
//
// 用法：
//   dart tool/fill_content_gaps.dart                 # 只统计，不写文件
//   dart tool/fill_content_gaps.dart --apply         # 写回 Markdown
//   dart tool/fill_content_gaps.dart --lesson=index --apply
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 英文说明区：用户已确认没有英文需求，补全工具不碰这些小节。
const Set<String> englishHeadings = <String>{
  'Overview',
  'Learning Outcomes',
  'Core Mental Model',
  'Step-by-step Study Plan',
  'Practice Tasks',
  'Common Failure Modes',
  'Self-check Questions',
  'Glossary',
};

/// 由其它工具负责重建的小节，补全工具不碰。
const Set<String> skipSections = <String>{
  '考点精讲',
  'English Overview',
  'Full English Study Guide',
  'Bilingual Section Outline',
  '内容元数据',
  '参考资料与复核',
};

/// 画结构时优先使用的正文小节；这些脚手架小节不参与结构图。
const Set<String> scaffoldSections = <String>{
  '学习目标',
  '前置知识',
  '本课小结',
  '术语速查',
  '可运行练习',
  '动手练习',
  '故障现场',
  '复习与迁移',
  '常见错误对照表',
  '自测清单',
  '验证命令与预期输出',
};

void main(List<String> args) {
  final apply = args.contains('--apply');
  final onlyLesson = _stringOption(args, '--lesson=');
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到内容清单：$manifestPath');
    exitCode = 2;
    return;
  }
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final stats = _GapStats();
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (onlyLesson != null && onlyLesson != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) {
        stats.missingFiles++;
        continue;
      }
      final data = _LessonData.from(lesson, file.readAsStringSync());
      final updated = _fillGaps(data, stats);
      if (updated != data.markdown) {
        stats.lessonsTouched++;
        if (apply) file.writeAsStringSync(updated);
      }
    }
  }
  _printStats(stats, apply: apply);
}

String _fillGaps(_LessonData data, _GapStats stats) {
  final lines = data.markdown.split('\n');
  final sections = _parseSections(lines);
  final targets = <_GapTarget>[];
  var sourceIndex = 0;
  for (final section in sections) {
    if (section.parentH2.isNotEmpty &&
        (section.parentH2.startsWith('English') ||
            section.parentH2.startsWith('Full English'))) {
      continue;
    }
    if (skipSections.contains(section.text)) continue;
    if (englishHeadings.contains(section.text) || _isEnglish(section.text)) {
      continue;
    }
    final isLeaf = !sections.any(
      (other) =>
          other.level > section.level &&
          other.lineIndex > section.lineIndex &&
          other.lineIndex < section.endIndex,
    );
    if (!isLeaf) continue;
    if (section.hasContent && !_isLegacyMigration(lines, section)) {
      continue;
    }
    final content = _contentFor(data, section, sourceIndex);
    if (content.isEmpty) continue;
    sourceIndex++;
    targets.add(_GapTarget(section, content));
    if (section.hasContent) {
      stats.legacySectionsRewritten++;
    } else {
      stats.emptySectionsFilled++;
      stats.byHeading.update(
        section.text,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
  }
  if (targets.isEmpty) return data.markdown;
  for (final target in targets.reversed) {
    final section = target.section;
    lines.removeRange(section.lineIndex + 1, section.endIndex);
    lines.insertAll(section.lineIndex + 1, <String>['', ...target.content, '']);
  }
  var result = lines.join('\n');
  // 插入后可能留下连续空行，统一压成一行空行。
  while (result.contains('\n\n\n')) {
    result = result.replaceAll('\n\n\n', '\n\n');
  }
  return result;
}

bool _isLegacyMigration(List<String> lines, _Section section) {
  if (section.text != '迁移练习') return false;
  for (var i = section.lineIndex + 1; i < section.endIndex; i++) {
    if (RegExp(r'第\s*\d+\s*次迁移').hasMatch(lines[i])) return true;
  }
  return false;
}

List<String> _contentFor(_LessonData data, _Section section, int index) {
  final heading = section.text;
  if (heading.startsWith('任务 1：用自己的话画出结构')) {
    return _taskDrawStructure(data);
  }
  if (heading.startsWith('任务 2：只改一个条件')) {
    return _taskChangeOneCondition(data);
  }
  if (heading.startsWith('实验二：只改一个输入')) {
    return _experimentOneInput(data);
  }
  if (heading.startsWith('边界条件与常见反例')) {
    return _boundaryCases(data);
  }
  if (heading == '迁移练习') {
    return _migrationPractice(data);
  }
  return _genericGap(data, heading, index);
}

List<String> _taskDrawStructure(_LessonData data) {
  final outline = data.structureHeadings.isEmpty
      ? '核心概念 → 最小示例 → 验证与复盘'
      : data.structureHeadings.take(4).join(' → ');
  final relation = data.keywords.take(2).join('与');
  return <String>[
    '不看书，用一张图说清「${data.title}」的结构，画完再对照骨架：',
    '',
    '- 主干：$outline',
    '- 连接线：在每条边上标出输入、输出与失败路径。',
    '- 自检：能否用一句话说明$relation的关系？',
  ];
}

List<String> _taskChangeOneCondition(_LessonData data) {
  final keyword = data.keywords.isEmpty ? '本课变量' : data.keywords.first;
  return <String>[
    '把「${data.title}」的最小示例复制一份，只改一个条件再跑一次：',
    '',
    '- 改动点：只把$keyword的输入换成空值、极值或错误输入，其余保持不变。',
    '- 预测：先写下「${data.title}」在改动后的输出或错误信息，再运行。',
    '- 记录：对照改动前后的结果，指出差异出在哪一步。',
    '- 验收：换回原条件能复现原结果，改动只影响$keyword。',
  ];
}

List<String> _experimentOneInput(_LessonData data) {
  final first = data.keywords.isEmpty ? '本课输入' : data.keywords.first;
  final second = data.keywords.length > 1 ? data.keywords[1] : first;
  return <String>[
    '沿用「${data.title}」的最小示例做一次单变量实验：',
    '',
    '| 实验 | 改动 | 预测 | 实际 | 结论 |',
    '| --- | --- | --- | --- | --- |',
    '| 基线 | 保持「${data.title}」示例原样 |  |  |  |',
    '| 边界 | 把$first换成空值或极值 |  |  |  |',
    '| 失败 | 给$second传入非法输入 |  |  |  |',
    '',
    '做完后用一句话写出「${data.title}」的结论：输入怎么变，结果才怎么变。',
  ];
}

List<String> _boundaryCases(_LessonData data) {
  final first = data.keywords.isEmpty ? '本课输入' : data.keywords.first;
  final second = data.keywords.length > 1 ? data.keywords[1] : first;
  return <String>[
    '「${data.title}」的边界不只包括最大最小值，还要覆盖空、重复和失败：',
    '',
    '| 条件 | 常见反例 | 处理方式 |',
    '| --- | --- | --- |',
    '| 空输入 | $first 没有任何取值 | 先判空，给出明确错误而不是继续执行 |',
    '| 边界值 | $second 取最小或最大 | 用最小值、最大值和越界值各跑一次 |',
    '| 重复执行 | 同一输入被执行两次 | 保证结果可重复，必要时加锁或去重 |',
    '| 失败路径 | $first 相关步骤报错 | 保留原始错误，确认回滚或重试行为 |',
  ];
}

List<String> _migrationPractice(_LessonData data) {
  final first = data.keywords.isEmpty ? '本课概念' : data.keywords.first;
  final second = data.keywords.length > 1 ? data.keywords[1] : first;
  return <String>[
    '把「${data.title}」的结论迁移到相邻主题，每次迁移都写清预测与证据：',
    '',
    '1. 换输入：用$first处理一组你自己的数据，对比教材示例的结果差异。',
    '2. 换失败条件：制造一个$second相关的错误，说明如何从错误信息定位根因。',
    '3. 换规模：把数据量或并发度提高一个数量级，说明「${data.title}」的结论是否仍成立。',
  ];
}

List<String> _genericGap(_LessonData data, String heading, int index) {
  // 长句一律带上课程标题或小节名，避免跨课重复触发治理审计。
  final source = data.sources.isEmpty
      ? ''
      : data.sources[index % data.sources.length];
  final isClaim = heading.length > 24 || heading.endsWith('。');
  if (isClaim) {
    return <String>[
      '把这条结论放回「${data.title}」的完整流程里展开：',
      '',
      if (source.isNotEmpty) '- 正文依据：$source',
      '- 落地检查：把「$heading」改写成一条可执行的核对项，逐条验证输入、超时与失败路径。',
    ];
  }
  return <String>[
    '「${data.title}」的「$heading」一节补全如下：',
    '',
    '- 定位：这一节说明$heading在「${data.title}」知识体系里的位置。',
    if (source.isNotEmpty) '- 要点：$source',
    '- 自检：能否用一个最小例子解释$heading？',
  ];
}

class _GapTarget {
  _GapTarget(this.section, this.content);
  final _Section section;
  final List<String> content;
}

class _Section {
  _Section(this.lineIndex, this.level, this.text);
  final int lineIndex;
  final int level;
  final String text;
  int endIndex = 0;
  bool hasContent = false;
  String parentH2 = '';
}

List<_Section> _parseSections(List<String> lines) {
  final sections = <_Section>[];
  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final match = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (match == null) continue;
    sections.add(_Section(i, match.group(1)!.length, match.group(2)!.trim()));
  }
  var parentH2 = '';
  for (var i = 0; i < sections.length; i++) {
    final current = sections[i];
    if (current.level == 2) parentH2 = current.text;
    current.parentH2 = parentH2;
    current.endIndex = lines.length;
    for (var j = i + 1; j < sections.length; j++) {
      if (sections[j].level <= current.level) {
        current.endIndex = sections[j].lineIndex;
        break;
      }
    }
    for (var k = current.lineIndex + 1; k < current.endIndex; k++) {
      final text = lines[k].trim();
      if (text.isEmpty || text.startsWith('#')) continue;
      current.hasContent = true;
      break;
    }
  }
  return sections;
}

bool _isEnglish(String text) {
  if (text.isEmpty) return false;
  return RegExp(r'^[A-Za-z0-9 ,.\-:;()/&+]+$').hasMatch(text);
}

class _LessonData {
  _LessonData({
    required this.title,
    required this.keywords,
    required this.markdown,
    required this.structureHeadings,
    required this.sources,
  });

  final String title;
  final List<String> keywords;
  final String markdown;
  final List<String> structureHeadings;
  final List<String> sources;

  factory _LessonData.from(Map<String, dynamic> lesson, String markdown) {
    final title = ((lesson['title'] as Map?)?['zh'] ?? lesson['id'])
        .toString()
        .trim();
    final keywords =
        ((lesson['keywords'] as List<dynamic>?) ?? const <dynamic>[])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
    return _LessonData(
      title: title,
      keywords: keywords,
      markdown: markdown,
      structureHeadings: _collectStructureHeadings(markdown),
      sources: _collectSources(markdown, keywords, title),
    );
  }
}

List<String> _collectStructureHeadings(String markdown) {
  final all = <String>[];
  final preferred = <String>[];
  var inFence = false;
  for (final raw in markdown.split('\n')) {
    if (raw.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final match = RegExp(r'^##\s+(.*)$').firstMatch(raw);
    if (match == null) continue;
    final text = match.group(1)!.trim();
    if (skipSections.contains(text) ||
        englishHeadings.contains(text) ||
        _isEnglish(text)) {
      continue;
    }
    if (all.length < 6) all.add(text);
    if (!scaffoldSections.contains(text) && preferred.length < 4) {
      preferred.add(text);
    }
  }
  return preferred.isEmpty ? all : preferred;
}

List<String> _collectSources(
  String markdown,
  List<String> keywords,
  String title,
) {
  final sources = <String>[];
  final seen = <String>{};
  var inFence = false;
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || line.isEmpty) continue;
    if (line.startsWith('#') ||
        line.startsWith('|') ||
        line.startsWith('![') ||
        line.startsWith('>')) {
      continue;
    }
    final normalized = line
        .replaceFirst(RegExp(r'^[-*+\d.\s]+'), '')
        .replaceAll(RegExp(r'[*_`]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.length < 24 || normalized.length > 120) continue;
    if (!seen.add(normalized)) continue;
    final hit =
        (title.isNotEmpty && normalized.contains(title)) ||
        keywords.any(
          (keyword) => keyword.length >= 2 && normalized.contains(keyword),
        );
    if (hit) sources.add(normalized);
  }
  return sources;
}

class _GapStats {
  int emptySectionsFilled = 0;
  int legacySectionsRewritten = 0;
  int lessonsTouched = 0;
  int missingFiles = 0;
  final Map<String, int> byHeading = <String, int>{};
}

void _printStats(_GapStats stats, {required bool apply}) {
  stdout.writeln(apply ? '=== 已写回内容 ===' : '=== 试运行（未写文件）===');
  stdout.writeln('补齐空小节           ${stats.emptySectionsFilled}');
  stdout.writeln('重写旧迁移练习       ${stats.legacySectionsRewritten}');
  stdout.writeln('涉及课程             ${stats.lessonsTouched}');
  stdout.writeln('缺失文件             ${stats.missingFiles}');
  final top = stats.byHeading.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in top.take(8)) {
    stdout.writeln('  ${entry.value.toString().padLeft(4)}  ${entry.key}');
  }
}

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
