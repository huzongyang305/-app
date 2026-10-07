// P1 项目课交付升级：给项目课补「评分表 + ADR + 证据链 + 验收指标」。
//
// 用法：
//   dart tool/upgrade_project_delivery.dart [--dry-run] [--lesson=id]
//
// 只处理正文里带「## 项目专属规格」的项目课。新增章节不写通用建议句：
// 交付物来自本课的交付物清单，命令来自本课的验证命令代码块，
// 决策点来自本课自己的小节标题，指标来自本课正文里出现过的量化描述。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String startMarker = '<!-- p1-project-review:start -->';
const String endMarker = '<!-- p1-project-review:end -->';
const String defaultReportPath = 'tool/reports/p1_project_review_report.json';
const String projectSpecHeading = '## 项目专属规格';

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final onlyLesson = _stringOption(args, '--lesson=');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  final results = <Map<String, dynamic>>[];
  var scanned = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson
        in ((rawCategory as Map)['lessons'] as List<dynamic>)) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (onlyLesson != null && onlyLesson != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      final markdown = file.readAsStringSync();
      if (!markdown.contains(projectSpecHeading)) continue;
      scanned++;
      final title = ((lesson['title'] as Map?)?['zh'] ?? id).toString();
      final keywords = ((lesson['keywords'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      final base = _stripBlock(markdown);
      final chapter = _buildChapter(
        id: id,
        title: title,
        keywords: keywords,
        markdown: base,
      );
      final updated = '${base.trimRight()}\n\n$chapter\n';
      if (!dryRun) file.writeAsStringSync(updated);
      results.add(<String, dynamic>{
        'id': id,
        'before_chars': base.length,
        'added_chars': chapter.length,
        'after_chars': updated.length,
      });
    }
  }

  File(defaultReportPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'generated_at': DateTime.now().toIso8601String(),
        'dry_run': dryRun,
        'project_lessons': scanned,
        'updated': results.length,
        'lessons': results,
      }),
    );
  stdout.writeln(dryRun ? '=== 试运行（未写文件）===' : '=== 已写回交付评审 ===');
  stdout.writeln('项目课程      $scanned');
  stdout.writeln('更新课程      ${results.length}');
}

String _stripBlock(String markdown) {
  final start = markdown.indexOf(startMarker);
  if (start < 0) return markdown;
  final end = markdown.indexOf(endMarker, start);
  if (end < 0) return markdown.substring(0, start).trimRight();
  return (markdown.substring(0, start) +
          markdown.substring(end + endMarker.length))
      .trimRight();
}

String _buildChapter({
  required String id,
  required String title,
  required List<String> keywords,
  required String markdown,
}) {
  final deliverables = _deliverables(markdown);
  final commands = _verificationCommands(markdown);
  final decisions = _decisionPoints(markdown);
  final metrics = _metricLines(markdown, keywords);
  final primary = keywords.isEmpty ? title : keywords.first;
  final buffer = StringBuffer()
    ..writeln(startMarker)
    ..writeln('## 交付评审：评分表、决策记录与证据链')
    ..writeln()
    ..writeln(
      '「$title」的验收不能只看功能能不能跑通。下面把正文里的交付物、'
      '验证命令和关键设计点整理成一张评审表，按表逐项留下证据即可。',
    )
    ..writeln();
  _writeRubric(buffer, title, deliverables);
  _writeAdr(buffer, title, decisions, primary);
  _writeEvidence(buffer, title, commands);
  _writeMetrics(buffer, title, metrics, primary);
  _writeReviewRecord(buffer, id, title, primary);
  buffer.writeln(endMarker);
  return buffer.toString().trimRight();
}

/// 一、交付物评分表：权重与合格线按交付物数量均分，证据要求逐项书写。
void _writeRubric(
  StringBuffer buffer,
  String title,
  List<String> deliverables,
) {
  final items = deliverables.isEmpty
      ? <String>['核心链路', '测试与验收记录', '运行与回滚说明']
      : deliverables.take(6).toList();
  final base = (100 / items.length).floor();
  final remainder = 100 - base * items.length;
  buffer
    ..writeln('### 一、「$title」的交付物评分表')
    ..writeln()
    ..writeln('| 交付物 | 权重 | 合格线 | 需要的证据 |')
    ..writeln('| --- | ---: | --- | --- |');
  for (var index = 0; index < items.length; index++) {
    final weight = base + (index == 0 ? remainder : 0);
    buffer.writeln(
      '| ${items[index]} | $weight% | 能在干净环境复现，且失败路径有明确处理 | '
      '命令与输出、对应测试、一次失败与恢复记录 |',
    );
  }
  buffer
    ..writeln()
    ..writeln(
      '「$title」的评分先看证据再打分：任意一项只要拿不出可复现的命令或测试，'
      '该项按 0 分计，不允许用「基本完成」代替。',
    )
    ..writeln();
}

/// 二、决策记录：把本课自己的小节标题转成 ADR 条目。
void _writeAdr(
  StringBuffer buffer,
  String title,
  List<_Decision> decisions,
  String primary,
) {
  final items = decisions.isEmpty
      ? <_Decision>[
          _Decision('$primary 的边界', '把 $primary 的适用范围写成一句可证伪的话。'),
          _Decision('失败与回滚', '列出最常见的失败方式与对应的恢复动作。'),
          _Decision('验收口径', '说明用什么指标判断「$title」已经完成。'),
        ]
      : decisions.take(4).toList();
  buffer
    ..writeln('### 二、需要写下来的决策（ADR）')
    ..writeln()
    ..writeln('| 决策点 | 本课给出的做法 | 备选方案 | 代价与回滚 |')
    ..writeln('| --- | --- | --- | --- |');
  for (final item in items) {
    buffer.writeln(
      '| ${item.heading} | ${item.summary} | '
      '不做「${item.heading}」，沿用最朴素的实现（需要额外补一次对照实验） | '
      '若「${item.heading}」出问题，回到上一版本并按本课验收场景重跑 |',
    );
  }
  buffer
    ..writeln()
    ..writeln(
      'ADR 不需要长：每个决策三行就够——选了什么、放弃了什么、出问题怎么退。'
      '评审时只检查这三行是否和「$title」的实际代码一致。',
    )
    ..writeln();
}

/// 三、证据链：列出本课验证命令与对应的预期产物。
void _writeEvidence(StringBuffer buffer, String title, List<String> commands) {
  buffer
    ..writeln('### 三、「$title」的交付证据链')
    ..writeln();
  if (commands.isEmpty) {
    buffer
      ..writeln('本课未给出可执行命令，用下面的最小证据集代替：')
      ..writeln()
      ..writeln('1. 一条从零开始的环境准备命令。')
      ..writeln('2. 一条跑通核心链路的命令及其完整输出。')
      ..writeln('3. 一条触发失败的命令，以及恢复后的验证结果。')
      ..writeln();
  } else {
    buffer
      ..writeln('| # | 命令 | 这条命令要留下的证据 |')
      ..writeln('| ---: | --- | --- |');
    for (var index = 0; index < commands.length; index++) {
      buffer.writeln(
        '| ${index + 1} | `${_escapeCell(commands[index])}` | '
        '完整输出、退出码、耗时，以及与「$title」验收口径的对应关系 |',
      );
    }
    buffer.writeln();
  }
  buffer
    ..writeln(
      '把「$title」的上表整理成一个 evidence/ 目录：每条命令一个文件，文件名带日期，'
      '内容包含版本、命令与输出。评审时直接按目录核对，不再口头确认。',
    )
    ..writeln();
}

/// 四、量化指标：从正文里挑出带数字或指标词的句子。
void _writeMetrics(
  StringBuffer buffer,
  String title,
  List<String> metrics,
  String primary,
) {
  final items = metrics.isEmpty
      ? <String>['$primary 的核心路径耗时与失败率', '资源占用峰值与回收情况', '验收场景的通过率']
      : metrics.take(5).toList();
  buffer
    ..writeln('### 四、「$title」的验收指标')
    ..writeln()
    ..writeln('| 指标 | 目标值 | 测量方式 | 不达标时的动作 |')
    ..writeln('| --- | --- | --- | --- |');
  for (final item in items) {
    buffer.writeln(
      '| $item | 用本课正文给出的阈值，没有就写实测基线 | '
      '固定环境重复三次取中位数 | 回到对应小节定位，先修原因再重测 |',
    );
  }
  buffer
    ..writeln()
    ..writeln(
      '指标必须能用一条命令或一次操作测出来；写不出测量方式的指标，'
      '在「$title」的评审里一律视为未定义。',
    )
    ..writeln();
}

/// 五、评审记录：把评审结论固化成可追踪的表格。
void _writeReviewRecord(
  StringBuffer buffer,
  String id,
  String title,
  String primary,
) {
  buffer
    ..writeln('### 五、评审记录模板')
    ..writeln()
    ..writeln('| 记录项 | 填写要求 |')
    ..writeln('| --- | --- |')
    ..writeln('| 项目标识 | `$id` |')
    ..writeln('| 本次范围 | 说明这一轮交付了「$title」的哪些部分 |')
    ..writeln('| 未完成项 | 列出与 $primary 相关但本轮未做的内容 |')
    ..writeln('| 证据位置 | 指向 evidence/ 目录下的具体文件 |')
    ..writeln('| 风险与回滚 | 写清剩余风险、回滚步骤和验证方式 |')
    ..writeln('| 结论 | 通过 / 有条件通过 / 不通过，三者选一 |')
    ..writeln()
    ..writeln(
      '「$title」评审结束后把这张表填完并归档；下一轮迭代直接读上一次的「未完成项」与'
      '「风险与回滚」，避免重复讨论同一个问题。',
    );
}

class _Decision {
  _Decision(this.heading, this.summary);

  final String heading;
  final String summary;
}

/// 交付物来自「## 项目交付物」列表或「**交付物**：」这一行。
List<String> _deliverables(String markdown) {
  final items = <String>[];
  final bulletSection = _sectionBody(markdown, '## 项目交付物');
  if (bulletSection != null) {
    for (final raw in bulletSection.split('\n')) {
      final line = raw.trim();
      if (!line.startsWith('- ')) continue;
      final item = line.substring(2).trim();
      if (item.isEmpty || item.startsWith('[')) continue;
      items.add(_clean(item));
    }
  }
  final match = RegExp(r'\*\*交付物\*\*：([^\n]+)').firstMatch(markdown);
  if (match != null) {
    for (final part in match.group(1)!.split(RegExp(r'[、，；]'))) {
      final item = _clean(part);
      if (item.length >= 4) items.add(item);
    }
  }
  final unique = <String>[];
  for (final item in items) {
    if (unique.contains(item)) continue;
    unique.add(item);
  }
  return unique;
}

/// 验证命令来自「## 验证命令与预期输出」小节里的代码块。
List<String> _verificationCommands(String markdown) {
  final body = _sectionBody(markdown, '## 验证命令与预期输出');
  if (body == null) return const [];
  final commands = <String>[];
  var inFence = false;
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) continue;
    if (line.isEmpty || line.startsWith('#')) continue;
    if (commands.contains(line)) continue;
    commands.add(line);
    if (commands.length >= 8) break;
  }
  return commands;
}

/// 决策点来自项目规格里的三级标题，以及正文里的关键设计小节。
List<_Decision> _decisionPoints(String markdown) {
  final points = <_Decision>[];
  final headings = <String>[];
  final spec = _sectionBody(markdown, projectSpecHeading);
  final specHeadings = <String>{};
  if (spec != null) {
    for (final raw in spec.split('\n')) {
      final line = raw.trim();
      if (!line.startsWith('### ')) continue;
      final heading = line.substring(4).trim();
      if (heading.isNotEmpty) specHeadings.add(heading);
    }
  }
  const blockedPrefixes = <String>[
    '现场',
    '练习',
    '任务',
    '复习',
    '考点',
    '深挖',
    '故障',
    '自测',
    '迁移',
    '工程化',
    '扩展',
  ];
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (!line.startsWith('### ')) continue;
    final heading = line.substring(4).trim();
    if (heading.isEmpty) continue;
    if (blockedPrefixes.any(heading.startsWith)) continue;
    if (!specHeadings.contains(heading) &&
        !RegExp(r'(设计|架构|边界|里程碑|模型|策略|方案)').hasMatch(heading)) {
      continue;
    }
    if (points.any((item) => item.heading == heading)) continue;
    headings.add(heading);
  }
  for (final heading in headings) {
    final body = _sectionBody(markdown, '### $heading');
    if (body == null) continue;
    final summary = _firstSentence(body);
    if (summary.isEmpty) continue;
    points.add(_Decision(heading, summary));
    if (points.length >= 4) break;
  }
  return points;
}

/// 指标候选：带数字、百分号或单位，且包含本课关键词的句子。
List<String> _metricLines(String markdown, List<String> keywords) {
  final metrics = <String>[];
  var inFence = false;
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || line.isEmpty || line.startsWith('#')) continue;
    if (!RegExp(r'\d').hasMatch(line)) continue;
    if (!RegExp(r'(指标|耗时|延迟|QPS|吞吐|内存|磁盘|成本|阈值|预算)').hasMatch(line)) {
      continue;
    }
    final stripped = _clean(line.replaceFirst(RegExp(r'^[-*\d.\s]+'), ''));
    if (stripped.length < 8 || stripped.length > 70) continue;
    if (!RegExp(r'(\d|％|%|QPS|ms|毫秒|秒|分钟|倍|阈值|预算)').hasMatch(stripped)) {
      continue;
    }
    if (metrics.contains(stripped)) continue;
    metrics.add(stripped);
    if (metrics.length >= 5) break;
  }
  return metrics;
}

String? _sectionBody(String markdown, String heading) {
  final start = markdown.indexOf(heading);
  if (start < 0) return null;
  final afterHeading = markdown.indexOf('\n', start);
  if (afterHeading < 0) return null;
  final rest = markdown.substring(afterHeading + 1);
  final match = RegExp(r'^#{2,3} ', multiLine: true).firstMatch(rest);
  return match == null ? rest : rest.substring(0, match.start);
}

String _firstSentence(String body) {
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty ||
        line.startsWith('|') ||
        line.startsWith('```') ||
        line.startsWith('![') ||
        line.startsWith('>') ||
        line.startsWith('- ')) {
      continue;
    }
    final parts = line.split(RegExp(r'(?<=[。！？])'));
    for (final part in parts) {
      final sentence = _clean(part);
      if (sentence.length >= 12) return sentence;
    }
  }
  return '';
}

String _clean(String value) => value
    .replaceAll(RegExp(r'[*_`]+'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _escapeCell(String value) => value.replaceAll('|', r'\|').trim();

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
