// P1 批量课程生成工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/generate_p1_lessons.dart
//
// 读取 tool/p1_specs/*.json，生成 Markdown 教程和 add_lessons 批次。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String specDir = 'tool/p1_specs';
const String batchDir = 'tool/p1_batches';
const String updatedAt = '2026-10-03';

const Map<String, String> fallbackDistractors = <String, String>{
  'security': '只要部署了防火墙，业务代码就不需要做输入校验。',
  'ai': '模型参数量越大，所有任务的效果和成本一定越好。',
  'language': '只要语法能编译通过，代码就没有性能和维护问题。',
  'systems': '增加机器数量就一定能解决延迟和一致性问题。',
  'data': '小数据上跑通就代表大规模和异常数据下也正确。',
  'product': '需求文档写完就不需要验收标准和变更管理。',
};

Future<void> main(List<String> args) async {
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();
  final categoryById = <String, Map<String, dynamic>>{
    for (final raw in categories)
      (raw as Map).cast<String, dynamic>()['id'] as String: raw
          .cast<String, dynamic>(),
  };
  final existingIds = <String>{};
  final nextOrder = <String, int>{};
  for (final category in categories) {
    final lessons = (category['lessons'] as List).cast<Map<String, dynamic>>();
    existingIds.addAll(lessons.map((item) => item['id'] as String));
    nextOrder[category['id'] as String] = lessons.isEmpty
        ? 1
        : lessons
                  .map((item) => item['order'] as int? ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1;
  }

  final specs = <String, Map<String, dynamic>>{};
  for (final file in Directory(specDir).listSync().whereType<File>().where(
    (item) => item.path.toLowerCase().endsWith('.json'),
  )) {
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    for (final entry in json.entries) {
      specs[entry.key] = (entry.value as Map).cast<String, dynamic>();
    }
  }
  final byCategory = <String, List<MapEntry<String, Map<String, dynamic>>>>{};
  for (final entry in specs.entries) {
    final categoryId = entry.value['category'] as String;
    byCategory.putIfAbsent(categoryId, () => []).add(entry);
  }

  final batches = <String, List<Map<String, dynamic>>>{};
  final errors = <String>[];
  var generated = 0;
  var skipped = 0;

  for (final entry in specs.entries) {
    final id = entry.key;
    final spec = entry.value;
    if (existingIds.contains(id)) {
      skipped++;
      continue;
    }
    final categoryId = spec['category'] as String? ?? '';
    if (!categoryById.containsKey(categoryId)) {
      errors.add('$id：分类 $categoryId 不存在');
      continue;
    }
    try {
      _validateSpec(id, spec);
      final markdown = _buildMarkdown(id, spec, categoryById[categoryId]!);
      if (markdown.length < 1200) {
        errors.add('$id：生成教程过短（${markdown.length} 字符）');
        continue;
      }
      await File('assets/content/$id.md').writeAsString(markdown, flush: true);
      final quiz = _buildQuiz(
        id,
        spec,
        byCategory[categoryId] ?? <MapEntry<String, Map<String, dynamic>>>[],
      );
      final order = nextOrder[categoryId]!;
      nextOrder[categoryId] = order + 1;
      batches.putIfAbsent(categoryId, () => []).add({
        'id': id,
        'title': spec['title'],
        'summary': spec['summary'],
        'file': 'assets/content/$id.md',
        'minutes': spec['minutes'] ?? 20,
        'keywords': spec['keywords'],
        'difficulty': spec['difficulty'] ?? '进阶',
        'order': order,
        'quiz': quiz,
      });
      existingIds.add(id);
      generated++;
    } on FormatException catch (error) {
      errors.add('$id：${error.message}');
    }
  }

  await Directory(batchDir).create(recursive: true);
  for (final entry in batches.entries) {
    await File('$batchDir/${entry.key}.json').writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert({'category': entry.key, 'lessons': entry.value}),
      flush: true,
    );
  }

  stdout.writeln('生成课程：$generated 篇，已存在跳过：$skipped 篇，批次 ${batches.length} 个');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(60)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}

void _validateSpec(String id, Map<String, dynamic> spec) {
  if ((spec['category'] as String? ?? '').trim().isEmpty) {
    throw FormatException('category 缺失');
  }
  if ((spec['difficulty'] as String? ?? '').trim().length < 2) {
    throw FormatException('difficulty 缺失');
  }
  for (final key in ['title', 'summary']) {
    final map = (spec[key] as Map?)?.cast<String, dynamic>();
    if ((map?['zh'] as String? ?? '').length < 4 ||
        (map?['en'] as String? ?? '').length < 4) {
      throw FormatException('$key 需要中英文');
    }
  }
  final keywords = spec['keywords'] as List?;
  if (keywords == null || keywords.length < 3) {
    throw FormatException('keywords 至少 3 项');
  }
  final points = spec['points'] as List?;
  if (points == null || points.length < 3) {
    throw FormatException('points 至少 3 项');
  }
  if (points.any((item) => item.toString().trim().length < 20)) {
    throw FormatException('points 存在过短条目');
  }
}

String _buildMarkdown(
  String id,
  Map<String, dynamic> spec,
  Map<String, dynamic> category,
) {
  final title = ((spec['title'] as Map)['zh'] as String).trim();
  final categoryTitle =
      ((category['title'] as Map)['zh'] as String? ?? category['id']);
  final keywords = (spec['keywords'] as List)
      .map((item) => item.toString())
      .toList();
  final points = (spec['points'] as List)
      .map((item) => item.toString())
      .toList();
  final minutes = spec['minutes'] ?? 20;
  final code = (spec['code'] as String?)?.trim();
  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln(
      '> 内容更新时间：$updatedAt · 学习阶段：${spec['difficulty']} · 预计用时：$minutes 分钟',
    )
    ..writeln()
    ..writeln('## 学习目标')
    ..writeln();
  for (final point in points.take(3)) {
    buffer.writeln('- 能用自己的话解释：$point');
  }
  buffer
    ..writeln('- 能把本课知识放回「$categoryTitle」，并完成练习与测验。')
    ..writeln()
    ..writeln('## 前置知识')
    ..writeln()
    ..writeln('- 已完成「$categoryTitle」的基础课程，能运行正文中的最小示例。')
    ..writeln('- 本课关键词：${keywords.join('、')}。')
    ..writeln('- 遇到不熟悉的术语先记录问题，完成练习后再回读。')
    ..writeln()
    ..writeln('## 核心知识')
    ..writeln();
  for (var index = 0; index < points.length; index++) {
    final point = points[index];
    buffer
      ..writeln('### ${index + 1}. $point')
      ..writeln()
      ..writeln('- 它解决的问题：把「$point」放回真实场景，说明不做它会带来什么后果。')
      ..writeln('- 关键做法：先用最小示例建立基线，再逐步加入边界、失败和性能条件。')
      ..writeln('- 验证标准：结果可复现、错误可解释、边界有测试、失败能恢复。')
      ..writeln();
  }
  buffer
    ..writeln('## 关键流程')
    ..writeln()
    ..writeln('```text')
    ..writeln('输入 → 校验 → 核心处理 → 验证 → 记录指标 → 失败恢复')
    ..writeln('```')
    ..writeln();
  if (code != null && code.isNotEmpty) {
    buffer
      ..writeln('## 代码示例')
      ..writeln()
      ..writeln('```${spec['language'] ?? 'text'}')
      ..writeln(code)
      ..writeln('```')
      ..writeln();
  }
  buffer
    ..writeln('## 实践路径')
    ..writeln()
    ..writeln('1. 用一句话复述本课要解决的问题。')
    ..writeln('2. 跑通正文中的最小示例并记录基线。')
    ..writeln('3. 只改变一个输入或参数，预测并验证结果。')
    ..writeln('4. 补一个失败路径，记录错误、恢复和指标。')
    ..writeln('5. 把结论写成可复现的笔记或测试。')
    ..writeln()
    ..writeln('## 常见误区')
    ..writeln()
    ..writeln('| 误区 | 后果 | 修正 |')
    ..writeln('| --- | --- | --- |')
    ..writeln('| 只记术语不做实验 | 遇到真实问题无法判断 | 用最小输入跑通并记录结果 |')
    ..writeln('| 只测正常路径 | 边界和故障上线才暴露 | 补空值、极值和依赖失败 |')
    ..writeln('| 没有基线就优化 | 无法证明改进有效 | 先测量再修改 |')
    ..writeln('| 忽略成本与安全 | 性能和风险失控 | 同时记录资源、权限与失败代价 |')
    ..writeln()
    ..writeln('## 动手练习')
    ..writeln()
    ..writeln('1. 合上教程，用 3～5 句话解释「$title」。')
    ..writeln('2. 从正文选一个例子，改变一个条件并预测结果。')
    ..writeln('3. 设计一个失败场景，写出止损与恢复步骤。')
    ..writeln()
    ..writeln('**验收标准**：留下输入、命令、输出、差异和下一步问题。')
    ..writeln()
    ..writeln('## 本课小结')
    ..writeln()
    ..writeln('- 本课属于「$categoryTitle」，核心关键词是 ${keywords.join('、')}。')
    ..writeln('- 先保证正确与可复现，再讨论性能和扩展。')
    ..writeln('- 完成练习和测验后，把仍然不确定的问题写成下一轮验证清单。')
    ..writeln()
    ..writeln('> 本课由 P1 内容扩展生成，重点补充原有课程缺失的主题与工程边界。');
  return buffer.toString().trimRight();
}

List<Map<String, dynamic>> _buildQuiz(
  String id,
  Map<String, dynamic> spec,
  List<MapEntry<String, Map<String, dynamic>>> siblings,
) {
  final title = ((spec['title'] as Map)['zh'] as String).trim();
  final summary = ((spec['summary'] as Map)['zh'] as String).trim();
  final points = (spec['points'] as List)
      .map((item) => item.toString())
      .toList();
  final category = spec['category'] as String;
  final questions = <Map<String, dynamic>>[];

  for (var index = 0; index < points.length && questions.length < 3; index++) {
    final correct = points[index];
    final candidates = <String>[];
    for (final sibling in siblings) {
      if (sibling.key == id) continue;
      final siblingPoints = (sibling.value['points'] as List?) ?? const [];
      if (index < siblingPoints.length) {
        candidates.add(siblingPoints[index].toString());
      }
    }
    final options = _buildOptions(correct, candidates, category, 3);
    questions.add({
      'question': '关于「${_shorten(correct)}」，下列说法正确的是？',
      'options': options,
      'answer': 0,
      'explanation':
          '正确选项直接描述了本课要点。其他选项来自相邻主题，混淆了概念边界或适用条件；判断时要回到定义、输入和失败场景。学习《$title》时应把该要点与「${spec['keywords'][0]}」一起理解。',
      'type': 'single',
    });
  }

  final summaryCandidates = siblings
      .where((item) => item.key != id)
      .map(
        (item) =>
            ((item.value['summary'] as Map)['zh'] as String? ?? '').trim(),
      )
      .where((item) => item.isNotEmpty)
      .toList();
  questions.add({
    'question': '「$title」的核心学习目标是什么？',
    'options': _buildOptions(summary, summaryCandidates, category, 3),
    'answer': 0,
    'explanation':
        '正确选项概括了本课目标。其他选项描述的是其他主题的目标或手段，不能回答本题；学习时应先明确目标，再用练习验证是否真正掌握。',
    'type': 'single',
  });
  return questions;
}

List<String> _buildOptions(
  String correct,
  List<String> candidates,
  String category,
  int count,
) {
  final options = <String>[correct];
  for (final candidate in candidates) {
    final value = candidate.trim();
    if (value.isNotEmpty && !options.contains(value)) options.add(value);
    if (options.length > count) break;
  }
  final fallbacks = <String>[
    fallbackDistractors[category] ?? '只要小数据能跑通，大规模和异常情况也一定正确。',
    '跳过验证直接上线，出现问题后再临时修复。',
    '只增加资源或参数，不需要理解机制和边界。',
    '把工具输出当成结论，不需要复现和交叉验证。',
  ];
  for (final fallback in fallbacks) {
    if (options.length > count) break;
    if (!options.contains(fallback)) options.add(fallback);
  }
  return options.take(count + 1).toList();
}

String _shorten(String text) {
  final clean = text.replaceAll(RegExp(r'[。；，,.]'), ' ').trim();
  return clean.length <= 18 ? clean : '${clean.substring(0, 18)}…';
}
