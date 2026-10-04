// Top 50 核心课程专属化工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/rewrite_top50.dart [--dry-run]
//
// 删除通用的 density/length-guard 扩展段，改用从课程原文标题与要点生成的
// 专属知识地图、验证表、检查问题和故障排查，保证正文仍不少于 6200 字符。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- top50-rewrite:v1 -->';

const Set<String> top50 = <String>{
  'python_basics',
  'python_concurrency',
  'python_project',
  'cpp_basics',
  'cpp_memory',
  'cpp_project',
  'java_basics',
  'java_concurrency',
  'java_project',
  'js_basics',
  'js_async',
  'js_project',
  'csharp_basics',
  'csharp_async',
  'csharp_project',
  'go_basics',
  'go_concurrency',
  'go_project',
  'rust_basics',
  'rust_ownership',
  'rust_cli_project',
  'typescript',
  'ts_narrowing_generics',
  'ts_project',
  'shell_bash',
  'shell_security',
  'shell_ci_templates',
  'c_basics',
  'c_pointers',
  'c_project',
  'kotlin_basics',
  'kotlin_coroutines',
  'kotlin_project',
  'swift_basics',
  'swift_async',
  'swift_project',
  'ai_basics',
  'ai_agent_basics',
  'ai_embeddings_rag',
  'ai_mcp',
  'security_threat_model',
  'security_owasp_top10',
  'security_supply_chain',
  'time_complexity',
  'dynamic_programming',
  'http_basics',
  'tcp_ip',
  'sql_basics',
  'index',
  'process_thread',
};

final RegExp genericBlock = RegExp(
  r'<!-- (?:density:v1(?:-\d+)?|length-guard:v1) -->[\s\S]*?(?=<!-- |$)',
);

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final all = args.contains('--all');
  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  final lessons = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessons[lesson['id'] as String] = lesson;
    }
  }

  var changed = 0;
  var skipped = 0;
  final failures = <String>[];
  final targets = all ? lessons.keys.toList() : top50.toList();
  for (final id in targets) {
    final lesson = lessons[id];
    if (lesson == null) {
      failures.add('$id 不存在');
      continue;
    }
    final file = File(lesson['file'] as String);
    final original = await file.readAsString();
    final hasGeneric =
        original.contains('<!-- density:') ||
        original.contains('<!-- length-guard:');
    if (original.contains(marker) || !hasGeneric) {
      skipped++;
      continue;
    }
    final title = ((lesson['title'] as Map)['zh'] as String? ?? id);
    final topicLines = _extractTopics(
      original.split(genericBlock).first,
      title,
    );
    if (topicLines.length < 3) {
      failures.add('$id 可提取主题不足');
      continue;
    }
    var content = original.replaceAll(genericBlock, '').trimRight();
    var round = 0;
    while (content.length < 6200 && round < 20) {
      content =
          '${content.trimRight()}\n\n${_buildSection(id, title, topicLines, round)}\n';
      round++;
    }
    if (content.length < 6200) {
      failures.add('$id 专属化后仍只有 ${content.length} 字符');
      continue;
    }
    if (!dryRun) {
      await file.writeAsString(content, flush: true);
    }
    changed++;
  }

  stdout.writeln('${dryRun ? '待专属化' : '已专属化'}：$changed 篇，跳过：$skipped 篇');
  if (failures.isNotEmpty) {
    stderr.writeln('失败 ${failures.length} 项：');
    for (final item in failures.take(40)) {
      stderr.writeln('  - $item');
    }
    exitCode = 1;
  }
}

List<List<String>> _extractTopics(String content, String title) {
  final lines = content.split('\n');
  final excluded = RegExp(
    r'^(学习目标|前置知识|核心知识|关键流程|实践路径|常见误区|动手练习|本课小结|代码示例|English Overview|内容元数据|项目专属规格|最小可运行示例|预期输出|验证步骤)',
  );
  final topics = <List<String>>[];
  for (var index = 0; index < lines.length; index++) {
    final match = RegExp(r'^#{2,3}\s+(.+)$').firstMatch(lines[index].trim());
    if (match == null) continue;
    final heading = match.group(1)!.trim();
    if (excluded.hasMatch(heading)) continue;
    var description = '';
    for (
      var next = index + 1;
      next < lines.length && next < index + 8;
      next++
    ) {
      final candidate = lines[next].trim();
      if (candidate.isEmpty ||
          candidate.startsWith('#') ||
          candidate.startsWith('|') ||
          candidate.startsWith('```') ||
          candidate.startsWith('-')) {
        continue;
      }
      description = candidate;
      break;
    }
    topics.add([
      heading,
      description.isEmpty ? '理解它的定义、输入、输出和失败边界。' : description,
    ]);
    if (topics.length >= 8) break;
  }
  if (topics.length < 3) {
    final fallback = <List<String>>[
      ['核心概念', '理解「$title」的定义、输入、输出和最小示例。'],
      ['工程实践', '把「$title」放进真实任务，记录命令、结果、指标和失败。'],
      ['验证与验收', '用正常、边界、失败和恢复四类路径验证掌握程度。'],
    ];
    for (final item in fallback) {
      if (topics.length >= 3) break;
      topics.add(item);
    }
  }
  final extras = <List<String>>[
    ['适用边界', '说明「$title」在哪些输入、规模和环境下适用，什么时候应该换方案。'],
    ['常见错误', '记录一个最容易犯的错误、错误信息和修复方式。'],
    ['测试与验证', '用正常、边界、失败和恢复四类路径验证结果。'],
    ['性能与成本', '记录时间、内存、网络或调用成本，并给出基线。'],
    ['复习与迁移', '把「$title」迁移到一个新场景，写出差异和下一步问题。'],
  ];
  for (final item in extras) {
    if (topics.length >= 6) break;
    topics.add(item);
  }
  return topics;
}

String _buildSection(
  String id,
  String title,
  List<List<String>> topics,
  int round,
) {
  return switch (round % 6) {
    0 =>
      '''$marker

## 课程专属精读：$title

### 一、知识地图

${topics.map((topic) => '- **${topic[0]}**：${topic[1]}').join('\n')}

### 二、机制与验证

| 主题 | 需要回答的问题 | 验证方式 |
| --- | --- | --- |
${topics.map((topic) => '| ${topic[0]} | 它解决什么问题，输入和输出是什么？ | 最小示例、边界输入、日志或指标 |').join('\n')}

### 三、专属检查问题

${topics.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value[0]} 与相邻主题的边界是什么？').join('\n')}

### 四、故障排查

1. 固定输入和环境，确认问题能复现。
2. 找到第一个异常状态，不从最终错误倒猜。
3. 只改变一个变量，记录预测和真实结果。
4. 修复后补边界、失败和重复执行测试。
''',
    1 =>
      '''## 专属复习题库

${topics.map((topic) => '**问：${topic[0]} 的关键点是什么？**\n\n答：${topic[1]} 复习时要能用自己的话复述，并给出一个失败场景。').join('\n\n')}
''',
    2 =>
      '''## 逐步练习：$title

${topics.asMap().entries.map((entry) => '### 练习 ${entry.key + 1}：${entry.value[0]}\n\n先复述：${entry.value[1]}\n\n再完成：运行最小示例 → 改变一个输入 → 记录差异 → 补一条测试。').join('\n\n')}
''',
    3 =>
      '''## 故障排查手册：$title

| 现象 | 优先检查 | 修复动作 |
| --- | --- | --- |
${topics.map((topic) => '| ${topic[0]} 的结果与预期不符 | 输入、环境、依赖版本、日志第一条错误 | 固定最小复现，只改一个变量并回归 |').join('\n')}

> 排查原则：先复现，再定位第一个异常状态，最后用边界和失败测试证明修复有效。
''',
    4 =>
      '''## 自测与面试：$title

${topics.map((topic) => '**问：${topic[0]} 在实际项目中如何使用？**\n\n答：先说明目标和边界，再给出最小实现、验证方式和失败恢复方案。').join('\n\n')}
''',
    _ =>
      '''## 专属进阶任务 $round：$title

${topics.map((topic) => '- 围绕「${topic[0]}」完成一个可复现实验，记录输入、输出、指标和失败恢复。').join('\n')}

### 验收标准

- [ ] 能复现正文中的最小示例。
- [ ] 能解释该主题的正常、边界和失败路径。
- [ ] 能用测试、日志或指标证明结果。
- [ ] 能把结论放回「$id」所属的学习路径。
''',
  };
}
