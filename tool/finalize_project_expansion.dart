// 新增项目课收尾工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/finalize_project_expansion.dart --dry-run
//   dart tool/finalize_project_expansion.dart
//
// 只处理 add_project_expansion.dart 新增的 8 门项目课，补齐：
// 前置知识、项目专属规格、内容元数据、参考资料与复核。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String reviewedAt = '2026-10-04';
const String nextReviewAt = '2027-04-04';
const String contentVersion = '2.0';

const Set<String> targetIds = <String>{
  'project_network_capture_analysis',
  'project_database_tuning',
  'project_concurrency_runtime',
  'project_security_lab',
  'project_algorithm_engineering',
  'project_devops_pipeline',
  'project_mobile_offline_app',
  'project_data_etl',
};

class ProjectSource {
  const ProjectSource(this.name, this.url, this.scope);

  final String name;
  final String url;
  final String scope;
}

const Map<String, List<ProjectSource>> sourcesByProject =
    <String, List<ProjectSource>>{
      'project_network_capture_analysis': <ProjectSource>[
        ProjectSource(
          'RFC Editor',
          'https://www.rfc-editor.org/',
          'TCP、DNS 与 HTTP 标准',
        ),
        ProjectSource(
          'Wireshark Documentation',
          'https://www.wireshark.org/docs/',
          '抓包过滤与协议分析',
        ),
      ],
      'project_database_tuning': <ProjectSource>[
        ProjectSource(
          'PostgreSQL Documentation',
          'https://www.postgresql.org/docs/',
          'SQL、索引、事务与执行计划',
        ),
        ProjectSource(
          'Use The Index, Luke',
          'https://use-the-index-luke.com/',
          '索引设计与查询性能',
        ),
      ],
      'project_concurrency_runtime': <ProjectSource>[
        ProjectSource(
          'Linux Kernel Documentation',
          'https://docs.kernel.org/',
          '进程、调度、内存与 I/O',
        ),
        ProjectSource(
          'POSIX Threads',
          'https://pubs.opengroup.org/onlinepubs/9799919799/',
          '线程、同步与并发语义',
        ),
      ],
      'project_security_lab': <ProjectSource>[
        ProjectSource(
          'OWASP Top 10',
          'https://owasp.org/www-project-top-ten/',
          'Web 应用风险与防御',
        ),
        ProjectSource(
          'NIST Cybersecurity Framework',
          'https://www.nist.gov/cyberframework',
          '风险识别、保护、检测与恢复',
        ),
      ],
      'project_algorithm_engineering': <ProjectSource>[
        ProjectSource(
          'CP-Algorithms',
          'https://cp-algorithms.com/',
          '算法实现、复杂度与边界',
        ),
        ProjectSource(
          'MIT OpenCourseWare 6.006',
          'https://ocw.mit.edu/courses/6-006-introduction-to-algorithms-spring-2020/',
          '算法设计与性能分析',
        ),
      ],
      'project_devops_pipeline': <ProjectSource>[
        ProjectSource(
          'The Twelve-Factor App',
          'https://12factor.net/',
          '可部署、可配置与可运维原则',
        ),
        ProjectSource('DORA', 'https://dora.dev/', '交付性能、可靠性与持续改进'),
        ProjectSource(
          'Kubernetes Documentation',
          'https://kubernetes.io/docs/',
          '部署、滚动发布与回滚',
        ),
      ],
      'project_mobile_offline_app': <ProjectSource>[
        ProjectSource(
          'Flutter Documentation',
          'https://docs.flutter.dev/',
          'Flutter 开发、测试与发布',
        ),
        ProjectSource(
          'Android Performance',
          'https://developer.android.com/topic/performance',
          '移动端启动、渲染与内存性能',
        ),
      ],
      'project_data_etl': <ProjectSource>[
        ProjectSource(
          'Apache Airflow Documentation',
          'https://airflow.apache.org/docs/',
          '任务编排、依赖、重试与回填',
        ),
        ProjectSource(
          'dbt Documentation',
          'https://docs.getdbt.com/',
          '数据转换、测试与数据血缘',
        ),
      ],
    };

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();
  final lessonsById = <String, Map<String, dynamic>>{};
  final titlesById = <String, String>{};
  for (final rawCategory in categories) {
    final category = rawCategory.cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'] as String;
      lessonsById[id] = lesson;
      titlesById[id] = ((lesson['title'] as Map)['zh'] as String? ?? id).trim();
    }
  }

  final missing = targetIds
      .where((id) => !lessonsById.containsKey(id))
      .toList();
  if (missing.isNotEmpty) {
    stderr.writeln('目标课程不存在：${missing.join(', ')}');
    exitCode = 1;
    return;
  }

  var changed = 0;
  var unchanged = 0;
  for (final id in targetIds) {
    final lesson = lessonsById[id]!;
    final file = File(lesson['file'] as String);
    if (!file.existsSync()) {
      stderr.writeln('正文文件不存在：${file.path}');
      exitCode = 1;
      continue;
    }
    var content = file.readAsStringSync();
    final original = content;

    if (!content.contains('内容更新时间：2026-10-03')) {
      content = _insertAfterTitle(
        content,
        '> 内容更新时间：2026-10-03 · 学习阶段：${lesson['difficulty']} · 预计用时：${lesson['minutes']} 分钟',
      );
    }
    if (!content.contains('## 前置知识')) {
      content = _insertBeforeProjectBackground(
        content,
        _buildPrerequisite(lesson, titlesById),
      );
    }

    final blocks = <String>[];
    if (!content.contains('## 动手练习')) {
      blocks.add(_buildPractice(lesson));
    }
    if (!content.contains('## 项目专属规格')) {
      blocks.add(_buildProjectSpec(lesson));
    }
    if (!content.contains('## 内容元数据')) {
      blocks.add(_buildMetadata(lesson));
    }
    if (!content.contains('## 参考资料与复核')) {
      blocks.add(_buildReferences(lesson, sourcesByProject[id]!));
    }
    if (!content.contains('## 本课小结')) {
      blocks.add(_buildSummary(lesson));
    }
    if (blocks.isNotEmpty) {
      content = '${content.trimRight()}\n\n${blocks.join('\n\n')}\n';
    }

    if (content == original) {
      unchanged++;
      continue;
    }
    changed++;
    if (!dryRun) {
      file.writeAsStringSync(content, flush: true);
    }
  }

  stdout.writeln('${dryRun ? '待补齐' : '已补齐'}项目课：$changed 篇，保持不变：$unchanged 篇');
}

String _insertBeforeProjectBackground(String content, String block) {
  final index = content.indexOf('## 项目背景');
  if (index < 0) return '${content.trimRight()}\n\n$block\n';
  return '${content.substring(0, index).trimRight()}\n\n$block\n\n'
      '${content.substring(index)}';
}

String _insertAfterTitle(String content, String line) {
  final match = RegExp(r'^#\s+.+$', multiLine: true).firstMatch(content);
  if (match == null) return '${content.trimRight()}\n\n$line\n';
  return '${content.substring(0, match.end)}\n\n$line\n'
      '${content.substring(match.end)}';
}

String _buildPrerequisite(
  Map<String, dynamic> lesson,
  Map<String, String> titlesById,
) {
  final difficulty = (lesson['difficulty'] as String? ?? '进阶').trim();
  final keywords = _stringList(lesson['keywords']).take(4).join('、');
  final prerequisites = _stringList(lesson['prerequisites'])
      .map((id) => '《${titlesById[id] ?? id}》')
      .join('、');
  return '''## 前置知识

- 建议先完成：${prerequisites.isEmpty ? '同方向的入门课程与基础练习' : prerequisites}。
- 本课阶段：$difficulty。需要能够独立阅读命令、代码或配置，并会用日志和测试验证结果。
- 开始前复习：$keywords。
- 准备一个可丢弃的本地环境；所有实验都要能重建、能清理、能回滚。
- 如果某一步无法复现，先记录环境、输入和完整错误，再缩小到最小案例。''';
}

String _buildProjectSpec(Map<String, dynamic> lesson) {
  final title = _localized(lesson['title']);
  final summary = _localized(lesson['summary']);
  final keywords = _stringList(lesson['keywords']);
  final first = keywords.isNotEmpty ? keywords.first : title;
  final second = keywords.length > 1 ? keywords[1] : '质量';
  return '''## 项目专属规格

### 交付边界

$summary 项目交付不是一份说明文档，而是一组可以运行的命令、可检查的输入输出、失败处理和复盘证据。范围必须同时写明本阶段做什么、不做什么，以及哪些依赖属于外部前提。

### 最小数据模型

| 对象 | 关键字段 | 约束 |
| --- | --- | --- |
| 输入实体 | $first、来源、时间、版本 | 必填、可校验、可追溯到原始输入 |
| 任务实体 | 状态、优先级、执行标识、重试次数 | 状态迁移合法、重复执行不会产生重复副作用 |
| 结果实体 | 输出、错误码、耗时、资源指标 | 可序列化、可比较、失败原因可解释 |
| 审计记录 | 操作者、动作、批次、结果、时间 | 不记录敏感信息、可查询、可复核 |

### 验收场景

1. 正常路径：使用最小输入完成端到端流程，并留下命令、输出和版本信息。
2. 边界路径：覆盖空值、最大值、重复数据和超长内容，结果必须可预测。
3. 失败路径：让一个依赖超时、返回错误或中途断开，验证系统能快速止损并说明恢复动作。
4. 幂等路径：同一请求或任务执行两次，业务结果与资源状态保持一致。
5. 回滚路径：回到上一稳定状态，并验证数据、配置和外部资源没有残留。

### 证据清单

- 一条从干净环境开始的可复现命令，以及真实输出。
- 一份正常、边界、失败与幂等场景的测试矩阵。
- 一组修改前后的 $second 指标，包含测量方法和环境说明。
- 一份故障时间线、根因、修复动作、回滚耗时和后续改进项。

### 完成定义

别人只阅读仓库说明和测试，就能复现主要结论；任何跳过、例外或未解决风险都有明确记录，而不是依赖口头解释。''';
}

String _buildPractice(Map<String, dynamic> lesson) {
  final title = _localized(lesson['title']);
  final keywords = _stringList(lesson['keywords']);
  final first = keywords.isNotEmpty ? keywords.first : title;
  final second = keywords.length > 1 ? keywords[1] : '质量';
  return '''## 动手练习

练习按「复现 → 破坏 → 交付」递进，至少完成前两项并保留证据。

### 练习 1：复现最小闭环（30 分钟）

按照「验证命令与预期输出」从干净环境运行一次完整流程，记录版本、命令、真实输出和耗时。然后只修改一个输入或参数，先写预测，再运行并解释差异。

**验收标准**：命令可以从零开始复现，输出与预测的差异有机制层面的解释，而不是只写成功或失败。

### 练习 2：制造一次可恢复故障（45 分钟）

围绕「$first」制造一次超时、错误输入、资源不足或依赖不可用，观察日志、指标和业务状态。完成止损、修复、复测和回滚，并画出从触发到恢复的时间线。

**验收标准**：失败能稳定复现；系统没有留下半完成状态；回滚后关键数据与资源一致。

### 练习 3：扩展为可交付增量（60 分钟）

给 $title 增加一个与「$second」相关的小功能或改进。先写验收标准，再补正常、边界、失败和幂等测试，最后更新运行说明与风险记录。

**验收标准**：别人只阅读提交记录和测试就能复核结果；性能、权限、成本和回滚边界都有明确说明。''';
}

String _buildMetadata(Map<String, dynamic> lesson) {
  final title = _localized(lesson['title']);
  final keywords = _stringList(lesson['keywords']);
  final difficulty = (lesson['difficulty'] as String? ?? '进阶').trim();
  return '''## 内容元数据

- 内容版本：v$contentVersion
- 最后更新：2026-10-06
- 学习阶段：$difficulty
- 适用环境：本地容器、单机服务或移动开发环境，具体版本以课程命令为准
- 内容来源：内置结构化课程与项目工程实践整理
- 相关主题：${keywords.join('、')}
- 质量版本：P0 可运行练习 + P1 专项题型 + P2 项目规格与复核
- 项目标识：${lesson['id']}
- 学习产出：$title 的可运行增量、验证证据与复盘记录''';
}

String _buildReferences(
  Map<String, dynamic> lesson,
  List<ProjectSource> sources,
) {
  final summary = _localized(lesson['summary']);
  final buffer = StringBuffer()
    ..writeln('## 参考资料与复核')
    ..writeln()
    ..writeln('- 最后复核：$reviewedAt')
    ..writeln('- 下次复核：$nextReviewAt')
    ..writeln('- 复核范围：版本兼容、API 行为、安全建议与工程实践')
    ..writeln('- 来源性质：官方文档、标准与社区资料；本课正文为离线教学重组，不复制原文')
    ..writeln()
    ..writeln('| 参考资料 | 本课用途 |')
    ..writeln('| --- | --- |');
  for (final source in sources) {
    buffer.writeln('| [${source.name}](${source.url}) | ${source.scope} |');
  }
  buffer
    ..writeln()
    ..writeln('> 本课主题：$summary')
    ..writeln()
    ..writeln('> App 完全离线展示文字链接，不会自动联网；需要延伸阅读时可复制链接到浏览器。');
  return buffer.toString().trimRight();
}

String _buildSummary(Map<String, dynamic> lesson) {
  final title = _localized(lesson['title']);
  final keywords = _stringList(lesson['keywords']);
  return '''## 本课小结

$title 的核心不是记住某一条命令，而是建立「定义验收标准 → 搭建最小闭环 → 用证据定位 → 安全回滚 → 留下复盘」的完整方法。

完成后你应该能够：

1. 说明本项目的输入、输出、质量指标与失败边界。
2. 从干净环境重复核心流程，并解释修改一个变量后的变化。
3. 处理至少一次超时、错误输入或依赖故障，且不留下半完成状态。
4. 用测试、日志、指标和审计记录证明结果，而不是只凭主观判断。
5. 把 ${keywords.take(4).join('、')} 串联成可交付、可复核、可改进的工程闭环。

下一步选择一个真实但范围可控的任务，先写验收标准，再提交一个可运行增量。每次只改变一个变量，并保留失败样本和回滚记录。''';
}

List<String> _stringList(Object? raw) => (raw as List? ?? const [])
    .map((item) => item.toString().trim())
    .where((item) => item.isNotEmpty)
    .toList();

String _localized(Object? raw) {
  if (raw is Map) return (raw['zh'] ?? raw['en'] ?? '').toString().trim();
  return raw?.toString().trim() ?? '';
}
