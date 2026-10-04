// 语言项目课生成工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/generate_project_lessons.dart
//
// 读取 tool/project_specs/*.json，生成：
//   · assets/content/<知识点id>.md 项目教程
//   · tool/project_batches/<分类id>.json 可供 add_lessons.dart 使用的批次
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String specDir = 'tool/project_specs';
const String batchDir = 'tool/project_batches';
const String updatedAt = '2026-10-03';

Future<void> main(List<String> args) async {
  final force = args.contains('--force');
  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
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
    for (final lesson in lessons) {
      existingIds.add(lesson['id'] as String);
    }
    nextOrder[category['id'] as String] = lessons.isEmpty
        ? 1
        : (lessons
                  .map((item) => item['order'] as int? ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1);
  }

  final batches = <String, List<Map<String, dynamic>>>{};
  final errors = <String>[];
  var generated = 0;
  var skipped = 0;

  final specFiles =
      Directory(specDir)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in specFiles) {
    final specs = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    for (final entry in specs.entries) {
      final id = entry.key;
      final spec = (entry.value as Map).cast<String, dynamic>();
      final categoryId = spec['category'] as String? ?? '';
      if (!categoryById.containsKey(categoryId)) {
        errors.add('$id：分类 $categoryId 不存在');
        continue;
      }
      if (existingIds.contains(id) && !force) {
        skipped++;
        continue;
      }

      try {
        _validateSpec(id, spec);
        final markdown = _buildMarkdown(id, spec, categoryById[categoryId]!);
        if (markdown.length < 3000) {
          errors.add('$id：生成教程过短（${markdown.length} 字符）');
          continue;
        }
        final mdFile = File('assets/content/$id.md');
        await mdFile.writeAsString(markdown, flush: true);

        final order = nextOrder[categoryId]!;
        nextOrder[categoryId] = order + 1;
        batches.putIfAbsent(categoryId, () => <Map<String, dynamic>>[]).add({
          'id': id,
          'title': spec['title'],
          'summary': spec['summary'],
          'file': 'assets/content/$id.md',
          'minutes': spec['minutes'] ?? 120,
          'keywords': spec['keywords'],
          'difficulty': '高级',
          'order': order,
          'quiz': spec['quiz'],
        });
        existingIds.add(id);
        generated++;
      } on FormatException catch (error) {
        errors.add('$id：${error.message}');
      }
    }
  }

  await Directory(batchDir).create(recursive: true);
  for (final entry in batches.entries) {
    final output = File('$batchDir/${entry.key}.json');
    await output.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert({'category': entry.key, 'lessons': entry.value}),
      flush: true,
    );
  }

  stdout.writeln('已生成项目课：$generated 篇，已存在跳过：$skipped 篇，批次：${batches.length} 个');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}

void _validateSpec(String id, Map<String, dynamic> spec) {
  if ((spec['category'] as String? ?? '').trim().length < 2) {
    throw FormatException('category 缺失或过短');
  }
  if ((spec['language'] as String? ?? '').trim().length < 2) {
    throw FormatException('language 缺失或过短');
  }
  final requiredStrings = ['scenario', 'code'];
  for (final key in requiredStrings) {
    if ((spec[key] as String? ?? '').trim().length < 10) {
      throw FormatException('$key 缺失或过短');
    }
  }
  for (final key in ['title', 'summary']) {
    final map = (spec[key] as Map?)?.cast<String, dynamic>();
    if ((map?['zh'] as String? ?? '').length < 4 ||
        (map?['en'] as String? ?? '').length < 4) {
      throw FormatException('$key 需要中英文');
    }
  }
  for (final key in [
    'keywords',
    'outcomes',
    'features',
    'steps',
    'tests',
    'extensions',
  ]) {
    final list = spec[key] as List?;
    if (list == null || list.length < 3) {
      throw FormatException('$key 至少需要 3 项');
    }
  }
  final pitfalls = spec['pitfalls'] as List?;
  if (pitfalls == null || pitfalls.length < 4) {
    throw FormatException('pitfalls 至少需要 4 项');
  }
  for (final row in pitfalls) {
    if ((row as List).length < 2) {
      throw FormatException('pitfalls 每项需要问题和解决方案');
    }
  }
  final quiz = spec['quiz'] as List?;
  if (quiz == null || quiz.length < 3 || quiz.length > 5) {
    throw FormatException('quiz 需要 3~5 题');
  }
  for (final raw in quiz) {
    final question = (raw as Map).cast<String, dynamic>();
    final options = question['options'] as List?;
    final answer = question['answer'];
    if ((question['question'] as String? ?? '').trim().length < 8 ||
        options == null ||
        options.length < 3 ||
        answer is! int ||
        answer < 0 ||
        answer >= options.length ||
        (question['explanation'] as String? ?? '').trim().length < 10) {
      throw FormatException('quiz 题目结构不完整');
    }
  }
}

String _buildMarkdown(
  String id,
  Map<String, dynamic> spec,
  Map<String, dynamic> category,
) {
  final title = ((spec['title'] as Map)['zh'] as String).trim();
  final summary = ((spec['summary'] as Map)['zh'] as String).trim();
  final keywords = (spec['keywords'] as List)
      .map((item) => item.toString())
      .toList();
  final outcomes = (spec['outcomes'] as List)
      .map((item) => item.toString())
      .toList();
  final features = (spec['features'] as List)
      .map((item) => item.toString())
      .toList();
  final steps = (spec['steps'] as List).map((item) => item.toString()).toList();
  final tests = (spec['tests'] as List).map((item) => item.toString()).toList();
  final extensions = (spec['extensions'] as List)
      .map((item) => item.toString())
      .toList();
  final pitfalls = spec['pitfalls'] as List;
  final stack =
      (spec['stack'] as List?)?.map((item) => item.toString()).toList() ??
      <String>[];
  final minutes = spec['minutes'] ?? 120;
  final language = spec['language'] as String;

  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln('> 内容更新时间：$updatedAt · 学习阶段：高级 · 预计用时：$minutes 分钟')
    ..writeln()
    ..writeln('## 学习目标')
    ..writeln();
  for (final item in outcomes) {
    buffer.writeln('- $item');
  }
  buffer
    ..writeln()
    ..writeln('## 前置知识')
    ..writeln()
    ..writeln('- 已完成本分类的基础与进阶课程，能独立运行正文中的最小示例。')
    ..writeln('- 熟悉命令行、依赖管理、测试和 Git 基本操作。')
    ..writeln('- 本课涉及：${keywords.join('、')}。')
    ..writeln()
    ..writeln('## 项目背景')
    ..writeln()
    ..writeln(spec['scenario'] as String)
    ..writeln()
    ..writeln('一句话摘要：$summary')
    ..writeln()
    ..writeln('## 技术栈')
    ..writeln();
  for (final item in stack) {
    buffer.writeln('- $item');
  }
  buffer
    ..writeln()
    ..writeln('## 架构与数据流')
    ..writeln()
    ..writeln('```text')
    ..writeln('输入 → 参数校验 → 业务处理 → 持久化/外部调用 → 结果输出 → 指标与日志')
    ..writeln('                 ↘ 失败分类 → 重试/回滚 → 错误响应')
    ..writeln('```')
    ..writeln()
    ..writeln('- 读路径要明确查询条件、分页方式和返回字段，避免一次加载全部数据。')
    ..writeln('- 写路径要明确事务边界、幂等键和失败补偿，不能留下半完成状态。')
    ..writeln('- 外部调用要设置超时、重试上限和降级策略。')
    ..writeln('- 每个关键阶段都要留下日志、指标或测试证据。')
    ..writeln()
    ..writeln('## 功能范围')
    ..writeln();
  for (final item in features) {
    buffer.writeln('- [ ] $item');
  }
  buffer
    ..writeln()
    ..writeln('## 示例数据与边界')
    ..writeln()
    ..writeln('| 场景 | 输入 | 期望结果 | 检查点 |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln('| 正常路径 | 合法的最小数据集 | 成功返回并写入正确数据 | 状态码、数据库记录、日志 |')
    ..writeln('| 边界值 | 最大值、最小值或空集合 | 明确成功或给出可理解错误 | 不崩溃、不越界、不写半条数据 |')
    ..writeln('| 非法输入 | 类型错误、缺字段、超长内容 | 返回校验错误并指出字段 | 错误结构统一且不泄露内部信息 |')
    ..writeln('| 依赖失败 | 数据库不可用、超时、网络抖动 | 重试、降级或快速失败 | 可恢复、可观测、无重复副作用 |')
    ..writeln()
    ..writeln('## 实施步骤')
    ..writeln();
  for (var index = 0; index < steps.length; index++) {
    buffer
      ..writeln('### 步骤 ${index + 1}：${steps[index]}')
      ..writeln()
      ..writeln('- 输入与产出：先写清本步依赖的配置、数据和最终产物，再开始编码。')
      ..writeln('- 验证方法：用最小请求、最小数据集或单元测试证明本步结果正确。')
      ..writeln('- 失败处理：记录错误类型、回滚动作和重试条件，避免把问题带到下一步。')
      ..writeln('- 证据留存：保留命令、输出、日志或截图，方便评审与复盘。')
      ..writeln();
  }
  buffer
    ..writeln('## 关键代码')
    ..writeln()
    ..writeln('```$language')
    ..writeln((spec['code'] as String).trim())
    ..writeln('```')
    ..writeln()
    ..writeln('## 验证命令与预期输出')
    ..writeln()
    ..writeln('先在干净环境执行启动和测试命令，再把真实输出记录到项目 README 或实施记录中。')
    ..writeln()
    ..writeln('```text')
    ..writeln('1. 安装依赖并启动项目')
    ..writeln('2. 执行至少 3 条自动化测试，其中包含 1 条失败路径')
    ..writeln('3. 用正常请求验证成功响应')
    ..writeln('4. 用非法输入验证错误响应')
    ..writeln('5. 重复执行一次，确认没有重复写入或副作用')
    ..writeln('```')
    ..writeln()
    ..writeln('预期输出必须包含：启动成功标志、测试通过数量、成功请求结果、错误状态码和重复执行的幂等结论。只写“运行正常”不算验收证据。')
    ..writeln()
    ..writeln('## 建议目录结构')
    ..writeln()
    ..writeln('```text')
    ..writeln('src/')
    ..writeln('  entry/        启动与配置')
    ..writeln('  domain/       业务模型与规则')
    ..writeln('  service/      用例编排')
    ..writeln('  infra/        数据库、HTTP、消息等适配器')
    ..writeln('tests/          单元、集成与接口测试')
    ..writeln('```')
    ..writeln()
    ..writeln('目录可以按语言习惯调整，但输入边界、业务规则和外部适配必须分层，不能全部堆在入口文件。')
    ..writeln()
    ..writeln('## 质量门禁')
    ..writeln()
    ..writeln('- [ ] 格式化和静态检查通过，不遗留明显警告。')
    ..writeln('- [ ] 单元测试覆盖核心规则，集成测试覆盖数据库或外部边界。')
    ..writeln('- [ ] 错误响应不泄露堆栈、SQL 和密钥。')
    ..writeln('- [ ] 配置来自环境变量或配置文件，不硬编码敏感信息。')
    ..writeln('- [ ] README 写清启动、测试、配置和回滚步骤。')
    ..writeln()
    ..writeln('## 安全、成本与可观测性')
    ..writeln()
    ..writeln('- 权限遵循最小授权，数据库账号、云资源和接口令牌都不能使用管理员默认权限。')
    ..writeln('- 所有外部输入都要校验、限长并转义，错误信息不能泄露内部路径和 SQL。')
    ..writeln('- 密钥通过环境变量或密钥管理服务注入，并记录轮换方式。')
    ..writeln('- 为数据库连接、线程/协程、队列、文件和网络请求设置上限，避免资源耗尽。')
    ..writeln('- 至少记录请求量、错误率、P95/P99 延迟、资源使用和成本趋势。')
    ..writeln('- 出现异常时能从日志和指标还原时间线，而不是只看到一句“服务不可用”。')
    ..writeln()
    ..writeln('## 测试与验收')
    ..writeln();
  for (final item in tests) {
    buffer.writeln('- $item');
  }
  buffer
    ..writeln()
    ..writeln('### 验收记录表')
    ..writeln()
    ..writeln('| 检查项 | 证据 | 结果 | 备注 |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln('| 最小路径可运行 | 启动命令与输出 |  |  |')
    ..writeln('| 失败路径可恢复 | 错误日志与重试 |  |  |')
    ..writeln('| 自动化测试通过 | 测试报告 |  |  |')
    ..writeln('| 配置和密钥安全 | 配置检查 |  |  |')
    ..writeln()
    ..writeln('## 常见问题')
    ..writeln()
    ..writeln('| 问题 | 原因 | 解决 |')
    ..writeln('| --- | --- | --- |');
  for (final row in pitfalls) {
    final cells = (row as List).map((item) => item.toString()).toList();
    buffer.writeln(
      '| ${cells[0]} | ${cells[1]} | ${cells.length > 2 ? cells[2] : '按日志和最小示例逐步定位'} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## 扩展任务')
    ..writeln();
  for (final item in extensions) {
    buffer.writeln('- $item');
  }
  buffer
    ..writeln()
    ..writeln('## 性能、容量与故障演练')
    ..writeln()
    ..writeln('| 维度 | 基线 | 压测方法 | 失败信号 |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln('| 延迟 | 记录 P50/P95/P99 | 用固定数据集逐步增加并发 | P99 持续上升或超时率增加 |')
    ..writeln('| 吞吐 | 记录每秒处理量 | 逐步加压直到资源打满 | 队列积压、CPU/内存饱和 |')
    ..writeln('| 存储 | 记录数据增长与索引大小 | 导入 10 倍数据并观察查询 | 磁盘、连接或锁等待成为瓶颈 |')
    ..writeln('| 恢复 | 记录故障恢复时间 | 停止数据库、注入延迟或重复请求 | 数据不一致、重复副作用、无法回滚 |')
    ..writeln()
    ..writeln('至少完成一次故障演练：先写下预期行为，再注入故障，最后对比真实行为并修正监控或代码。没有演练的容错设计只能算假设。')
    ..writeln()
    ..writeln('## 实施记录与复盘')
    ..writeln()
    ..writeln('每完成一步，记录以下内容：')
    ..writeln()
    ..writeln('1. 本步的输入、命令和输出是什么？')
    ..writeln('2. 遇到的最小失败是什么，如何定位和修复？')
    ..writeln('3. 哪个假设被验证或推翻？')
    ..writeln('4. 下一步的风险是什么，如何回滚？')
    ..writeln('5. 如果数据量或并发扩大 10 倍，最先出现的瓶颈在哪里？')
    ..writeln()
    ..writeln('## 动手练习')
    ..writeln()
    ..writeln('### 练习 1：最小可运行版本（30 分钟）')
    ..writeln()
    ..writeln('只实现最核心的一条路径，确保能启动、能返回结果、能运行测试。')
    ..writeln()
    ..writeln('**验收标准**：留下启动命令、请求示例和成功输出。')
    ..writeln()
    ..writeln('### 练习 2：失败路径（30 分钟）')
    ..writeln()
    ..writeln('制造一次输入错误、依赖失败或超时，记录系统如何报错、如何恢复。')
    ..writeln()
    ..writeln('**验收标准**：错误信息清晰，且不会破坏已有数据。')
    ..writeln()
    ..writeln('### 练习 3：扩展一个功能（60 分钟）')
    ..writeln()
    ..writeln('从扩展任务中选一项实现，并补一条自动化测试。')
    ..writeln()
    ..writeln('**验收标准**：新功能通过测试，且原有测试不回归。')
    ..writeln()
    ..writeln('## 本课小结')
    ..writeln()
    ..writeln('- 项目课的核心不是堆功能，而是把输入、状态、错误和验收标准连接起来。')
    ..writeln('- 先跑通最小路径，再补失败处理、测试和文档，最后才做性能优化。')
    ..writeln('- 每个阶段都要留下可复现证据：命令、输出、测试和变更记录。')
    ..writeln('- 完成后用扩展任务检验迁移能力，而不是只复制示例代码。')
    ..writeln()
    ..writeln('## 完成标准')
    ..writeln()
    ..writeln('- [ ] 能从干净环境按 README 启动项目。')
    ..writeln('- [ ] 至少 3 条自动化测试通过，且包含一条失败路径。')
    ..writeln('- [ ] 能演示一次错误、一次恢复和一次回滚。')
    ..writeln('- [ ] 有一份资源或性能基线，能说明瓶颈在哪里。')
    ..writeln('- [ ] 能说清一个尚未解决的问题和下一步验证方法。')
    ..writeln();
  return buffer.toString().trimRight();
}
