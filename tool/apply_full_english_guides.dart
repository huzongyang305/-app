// Top 50 核心课程英文学习指南工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_full_english_guides.dart [--dry-run]
//
// 为 Top 50 课程补充完整英文学习指南：目标、心智模型、学习步骤、练习、
// 失败模式、自测问题和术语表。它用于英文阅读与教学导航，详细示例仍以中文为主。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- full-english-guide:v1 -->';

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
  'project_python_cli_todo',
  'project_rest_api_sqlite',
  'project_rag_agent_service',
  'project_debug_performance_triage',
  'project_interview_coding_system_design',
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
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

  var appended = 0;
  var skipped = 0;
  final failures = <String>[];
  for (final id in top50) {
    final lesson = lessons[id];
    if (lesson == null) {
      failures.add('$id 不存在');
      continue;
    }
    final file = File(lesson['file'] as String);
    final content = await file.readAsString();
    if (content.contains(marker)) {
      skipped++;
      continue;
    }
    final titleEn = ((lesson['title'] as Map)['en'] as String? ?? id).trim();
    final summaryEn = ((lesson['summary'] as Map)['en'] as String? ?? '')
        .trim();
    final keywords =
        (lesson['keywords'] as List?)
            ?.map((item) => item.toString())
            .take(4)
            .toList() ??
        <String>[];
    final guide =
        '''$marker

## Full English Study Guide

### Overview

**$titleEn** focuses on ${summaryEn.isEmpty ? 'the core concepts, boundaries and engineering practices of this topic.' : summaryEn}

### Learning Outcomes

- Explain what **$titleEn** solves and when it should be used.
- Identify inputs, outputs, state and failure boundaries.
- Build a minimal reproducible example and observe the real result.
- Test normal, boundary and failure paths.
- Measure performance, resource cost or security impact before optimizing.
- Document the decision, rollback path and remaining uncertainty.

### Core Mental Model

1. **Problem first:** define the exact problem before choosing a tool or pattern.
2. **Smallest example:** reduce the system to one input and one observable output.
3. **State and flow:** trace how data, control or responsibility moves through the system.
4. **Boundaries:** identify invalid input, resource limits, timeouts and permission edges.
5. **Evidence:** use tests, logs, metrics or reproductions instead of intuition.
6. **Trade-offs:** compare correctness, latency, cost, complexity and operability.

### Step-by-step Study Plan

1. Read the Chinese lesson once and write down the main problem in one sentence.
2. Run the smallest example and save the exact command and output.
3. Change only one input or parameter and predict the result before running it.
4. Introduce one failure and record how the system detects, reports and recovers.
5. Write one test or checklist item for the normal, boundary and failure paths.
6. Complete the quiz and explain every wrong answer in your own words.

### Practice Tasks

- Rebuild the minimal example from an empty directory.
- Add one boundary test and one failure test.
- Produce a short report containing the baseline, change, result and rollback.

### Common Failure Modes

- Treating a happy-path demo as production readiness.
- Skipping boundary values and invalid inputs.
- Optimizing before establishing a measurable baseline.
- Hiding errors, permissions or resource limits.

### Self-check Questions

1. What is the smallest observable result that proves this lesson works?
2. What input or state is most likely to break it?
3. Which metric or test would reveal a regression?
4. What is the rollback path?
5. What is the cost of using this approach at 10x scale?
6. Which adjacent topic is most often confused with this one?

### Glossary

- Topic: **$titleEn**
- Related terms: ${keywords.isEmpty ? 'see lesson keywords' : keywords.join(', ')}
- Primary evidence: command output, tests, logs, metrics or reproductions

> This guide is an English study companion for the detailed Chinese lesson. It covers the learning path, mental model and acceptance questions; code examples and engineering details remain in the main tutorial.
''';
    if (guide.length < 1800) {
      failures.add('$id 英文指南过短');
      continue;
    }
    if (!dryRun) {
      await file.writeAsString(
        '${content.trimRight()}\n\n$guide\n',
        flush: true,
      );
    }
    appended++;
  }

  stdout.writeln('${dryRun ? '待补' : '已补'}英文学习指南：$appended 篇，跳过：$skipped 篇');
  if (failures.isNotEmpty) {
    stderr.writeln('失败：${failures.join('、')}');
    exitCode = 1;
  }
}
