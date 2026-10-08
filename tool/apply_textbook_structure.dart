// 把现有课程正文迁移为统一的九段式教材结构。
//
// 用法：
//   dart tool/apply_textbook_structure.dart [--dry-run] [--force]
//       [--only=id1,id2] [--preview=id]
//
// 迁移原则：
//   1. 九段式核心章节固定在最前，顺序与用户给定的教材模板一致；
//   2. 原有章节按语义归入对应核心章节，代码、图片和表格原样保留；
//   3. 考点精讲、术语速查、参考资料、内容元数据与英文附录保留为教材附录；
//   4. 缺少可验证复杂度时写“材料未提供”，不编造数量级。
import 'dart:convert';
import 'dart:io';

import 'markdown_fences.dart';

const String manifestPath = 'assets/content/manifest.json';
const String previewPath = 'tool/.textbook_preview.md';

const List<String> coreSections = <String>[
  '本节知识框架',
  '核心概念定义',
  '原理与运行机制',
  '典型应用场景',
  '代码/协议/SQL 示例',
  '时间/空间复杂度或性能分析',
  '常见误区与易错点',
  '与其他知识点的关系',
  '自测题与参考答案',
];

const Set<String> auxiliarySections = <String>{
  '考点精讲',
  '术语速查',
  '参考资料与复核',
  '内容元数据',
  'English Overview',
  'Full English Study Guide',
  'Bilingual Section Outline',
};

const Set<String> legacyCanonicalSections = <String>{
  '学习目标',
  '前置知识',
  '动手练习',
  '故障现场',
  '本课小结',
  '本课复习清单',
  '可运行练习',
  '常见错误与排查',
  '复习与自测',
  '复习与迁移',
  '实践任务',
  '小结',
  '总结',
};

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final only = _option(
    args,
    '--only=',
  ).split(',').where((v) => v.isNotEmpty).toSet();
  final preview = _option(args, '--preview=');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final metas = <_LessonMeta>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    final categoryTitle = _localized(category['title']);
    final lessons = (category['lessons'] as List<dynamic>).cast<Map>();
    for (var index = 0; index < lessons.length; index++) {
      final lesson = lessons[index].cast<String, dynamic>();
      metas.add(
        _LessonMeta(
          id: lesson['id'].toString(),
          categoryId: categoryId,
          categoryTitle: categoryTitle,
          title: _localized(lesson['title']),
          titleEn: _localized(lesson['title'], english: true),
          summary: _localized(lesson['summary']),
          file: lesson['file'].toString(),
          difficulty: lesson['difficulty']?.toString() ?? '基础',
          minutes: (lesson['minutes'] as num?)?.toInt() ?? 30,
          keywords: _stringList(lesson['keywords']),
          prerequisites: _stringList(lesson['prerequisites']),
          related: _stringList(lesson['related']),
          quiz: (lesson['quiz'] as List<dynamic>? ?? const [])
              .map((item) => (item as Map).cast<String, dynamic>())
              .toList(),
          lab: lesson['lab']?.toString(),
          order: (lesson['order'] as num?)?.toInt() ?? index,
        ),
      );
    }
  }
  final byId = <String, _LessonMeta>{for (final meta in metas) meta.id: meta};
  final byCategory = <String, List<_LessonMeta>>{};
  for (final meta in metas) {
    byCategory.putIfAbsent(meta.categoryId, () => <_LessonMeta>[]).add(meta);
  }
  for (final list in byCategory.values) {
    list.sort((a, b) => a.order.compareTo(b.order));
  }

  var changed = 0;
  var skipped = 0;
  var normalizedCount = 0;
  var minNewLength = 1 << 30;
  var maxNewLength = 0;
  final warnings = <String>[];
  for (final meta in metas) {
    if (only.isNotEmpty && !only.contains(meta.id)) continue;
    final file = File(meta.file);
    if (!file.existsSync()) {
      warnings.add('${meta.id}: 文件不存在 ${meta.file}');
      continue;
    }
    final original = file.readAsStringSync();
    final parsed = _parseMarkdown(original);
    if (!force && _hasTextbookStructure(parsed)) {
      // 已迁移课程只做模板句归一化：把跨课复用的通用句改写为带课程上下文的表述。
      final normalized = _normalizeStructuredMarkdown(original, meta);
      if (normalized == original) {
        skipped++;
        continue;
      }
      if (preview == meta.id) {
        File(previewPath).writeAsStringSync(normalized);
        stdout.writeln('预览已写入 $previewPath（${normalized.length} 字符）');
        return;
      }
      if (!dryRun) {
        file.writeAsStringSync(normalized);
      }
      normalizedCount++;
      continue;
    }
    final rebuilt = _normalizeStructuredMarkdown(
      _renderLesson(meta, parsed, byId, byCategory),
      meta,
    );
    final issues = _validateRebuild(original, rebuilt, parsed, meta);
    if (issues.isNotEmpty) {
      warnings.addAll(issues.map((issue) => '${meta.id}: $issue'));
      continue;
    }
    if (preview == meta.id) {
      File(previewPath).writeAsStringSync(rebuilt);
      stdout.writeln('预览已写入 $previewPath（${rebuilt.length} 字符）');
      return;
    }
    if (!dryRun) {
      file.writeAsStringSync(rebuilt);
    }
    changed++;
    minNewLength = minNewLength < rebuilt.length
        ? minNewLength
        : rebuilt.length;
    maxNewLength = maxNewLength > rebuilt.length
        ? maxNewLength
        : rebuilt.length;
  }
  stdout.writeln(
    '教材化课程 $changed 篇，模板句归一化 $normalizedCount 篇'
    '（跳过 $skipped 篇，dry-run=$dryRun）',
  );
  if (changed > 0) {
    stdout.writeln('迁移后正文长度：最短 $minNewLength，最长 $maxNewLength');
  }
  if (warnings.isNotEmpty) {
    stderr.writeln('校验提示 ${warnings.length} 条：');
    for (final warning in warnings.take(40)) {
      stderr.writeln('  - $warning');
    }
    exitCode = 1;
  }
}

String _renderLesson(
  _LessonMeta meta,
  _ParsedMarkdown parsed,
  Map<String, _LessonMeta> byId,
  Map<String, List<_LessonMeta>> byCategory,
) {
  final buckets = <String, List<_SourceSection>>{
    for (final title in coreSections) title: <_SourceSection>[],
  };
  final auxiliary = <_SourceSection>[];
  for (final section in parsed.sections) {
    if (auxiliarySections.contains(section.title)) {
      auxiliary.add(section);
      continue;
    }
    final bucket = _bucketFor(section);
    buckets[bucket]!.add(section);
  }
  final allSource = parsed.sections.map((section) => section.body).join('\n\n');
  final glossary = _parseGlossary(auxiliary);
  final complexity = _extractComplexity(allSource);
  final firstFence = _extractFirstFence(allSource);
  if (firstFence != null &&
      !buckets['代码/协议/SQL 示例']!.any((s) => s.codeCount > 0)) {
    for (final entry in buckets.entries) {
      if (entry.key == '代码/协议/SQL 示例') continue;
      final index = entry.value.indexWhere(
        (section) => section.body.contains(firstFence.trim()),
      );
      if (index >= 0) {
        final section = entry.value.removeAt(index);
        buckets['代码/协议/SQL 示例']!.insert(0, section);
        break;
      }
    }
  }
  final buffer = StringBuffer();
  buffer.writeln('# ${meta.title}');
  buffer.writeln();
  final preamble = parsed.preamble.trim();
  if (preamble.isNotEmpty) {
    buffer.writeln(preamble);
    buffer.writeln();
  }
  _writeCoreSection(
    buffer,
    '本节知识框架',
    _renderFrame(meta, parsed, byId, byCategory, buckets['本节知识框架']!),
  );
  _writeCoreSection(
    buffer,
    '核心概念定义',
    _renderConcepts(meta, glossary, buckets['核心概念定义']!),
  );
  _writeCoreSection(
    buffer,
    '原理与运行机制',
    _renderMechanics(meta, glossary, buckets['原理与运行机制']!),
  );
  _writeCoreSection(
    buffer,
    '典型应用场景',
    _renderScenarios(meta, buckets['典型应用场景']!),
  );
  _writeCoreSection(
    buffer,
    '代码/协议/SQL 示例',
    _renderExamples(meta, buckets['代码/协议/SQL 示例']!, firstFence),
  );
  _writeCoreSection(
    buffer,
    '时间/空间复杂度或性能分析',
    _renderPerformance(meta, complexity, buckets['时间/空间复杂度或性能分析']!),
  );
  _writeCoreSection(
    buffer,
    '常见误区与易错点',
    _renderPitfalls(meta, buckets['常见误区与易错点']!),
  );
  _writeCoreSection(
    buffer,
    '与其他知识点的关系',
    _renderRelations(meta, byId, byCategory, buckets['与其他知识点的关系']!),
  );
  _writeCoreSection(
    buffer,
    '自测题与参考答案',
    _renderSelfTests(meta, buckets['自测题与参考答案']!),
  );
  if (auxiliary.isNotEmpty) {
    buffer.writeln('---');
    buffer.writeln();
    for (final section in auxiliary) {
      buffer.writeln('## ${section.title}');
      buffer.writeln();
      final body = section.body.trim();
      if (body.isNotEmpty) {
        buffer.writeln(body);
        buffer.writeln();
      }
    }
  }
  return '${buffer.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trimRight()}\n';
}

/// 跨课复用的通用句会让课程读起来像模板；这里统一改写为带课程上下文的表述。
/// 所有替换都是幂等的：已经归一化的正文再次执行不会发生变化。
String _normalizeStructuredMarkdown(String markdown, _LessonMeta meta) {
  final title = meta.title;
  final scenario =
      '判断「$title」的场景是否成立，标准是能否写出输入、处理、输出和失败路径；'
      '材料中没有出现的数据在本课标注为“材料未提供”，不用推测替代证据。';
  final performance =
      '评估「$title」时要区分“正确性成立”和“性能达标”两件事；'
      '材料没有给出基准时，本课只保留量级来源与测量方法，不写不可验证的绝对数字。';
  final complexity =
      '**复杂度证据**：「$title」的现有材料没有给出渐近时间或空间复杂度的明确结论，'
      '本课只做定性检查，不补写未经验证的 \$O\$ 记号。';
  final minimalExample =
      '下面保留《$title》原文中的最小示例。先预测《$title》示例的输出，再按正文步骤运行或推演；'
      '示例依赖外部环境时，同时记录版本与输入。';
  final replacements = <String, String>{
    '本课属于「': '所属分类为「',
    '> 阅读约定：术语第一次出现时先给操作性定义，再给边界；如果正文中的说法与这里冲突，以定义和可复现示例为准。':
        '> 阅读约定：本课先给「$title」相关术语的操作性定义与适用边界；'
        '正文里的口语化说法与定义冲突时，以定义和可复现示例为准。',
    '典型场景的判断标准不是“看起来像”，而是能否写出输入、处理、输出和失败路径。若某类数据在材料中没有出现，应明确标注“材料未提供”，而不是补一个无法验证的案例。':
        scenario,
    '判断《$title》的应用场景时，标准不是“看起来像”，而是能否写出输入、处理、输出和失败路径。材料中没有出现的数据要标注“材料未提供”，不能补一个无法验证的案例。':
        scenario,
    '性能结论必须区分“正确性成立”和“性能达标”两件事。材料没有给出基准时，本课只保留量级来源与测量方法，不给出不可验证的绝对数字。':
        performance,
    '分析《$title》时必须区分“正确性成立”和“性能达标”。材料没有给出基准时，只保留量级来源与测量方法，不给出不可验证的绝对数字。':
        performance,
    '**复杂度证据**：材料未提供明确的渐近时间复杂度或空间复杂度。下面只能按本课关键词做定性检查，不能虚构 \$O\$ 记号。':
        complexity,
    '**复杂度证据**：《$title》材料未提供明确的渐近时间复杂度或空间复杂度。下面只能按本课关键词做定性检查，不能虚构 \$O\$ 记号。':
        complexity,
    '若正文没有给出某个数量级、吞吐或内存数据，就只能把该判断标为“材料未提供”，不能从相邻主题外推。':
        '「$title」没有给出某个数量级、吞吐或内存数据时，本课把该判断标为“材料未提供”，'
        '不从相邻主题外推。',
    '下面保留本课原文中的最小示例。先预测输出，再按正文步骤运行或推演；如果示例依赖外部环境，必须同时记录版本与输入。': minimalExample,
    '下面保留《$title》原文中的最小示例。先预测输出，再按正文步骤运行或推演；示例依赖外部环境时，必须记录版本与输入。':
        minimalExample,
    '以下代码、协议或 SQL 片段来自本课原文，保留原有语言标记与上下文。先预测输出，再按正文步骤运行或推演；示例依赖外部环境时，必须记录版本与输入。':
        '以下代码、协议或 SQL 片段来自《$title》原文，保留原有语言标记与上下文；'
        '先预测《$title》示例的输出，再按正文步骤运行或推演，示例依赖外部环境时同时记录版本与输入。',
    '> 先独立作答，再展开下面的答案与解析。答案必须能在本课正文或示例中找到依据，不能只凭语感。':
        '> 先独立作答《$title》的自测题，再对照答案与解析；'
        '每处判断都要能在本课正文或示例中找到依据。',
    '> 复核原则：下面优先保留本课原有的错误表、故障现场与排错路径；每条误区的修正都要能用本课示例复验。':
        '> 复核《$title》的易错点时，优先保留原文的错误表、故障现场与排错路径；'
        '每条修正都要能用本课示例复验。',
    '> 复核《$title》时，优先保留原有错误表、故障现场与排错路径；每条误区的修正都要能用本课示例复验。':
        '> 复核《$title》的易错点时，优先保留原文的错误表、故障现场与排错路径；'
        '每条修正都要能用本课示例复验。',
  };
  var result = markdown;
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  result = result.replaceAllMapped(
    RegExp(r'\*\*课程内置实验入口\*\*：`([^`]+)`。实验用于验证本课机制，不替代概念定义与复杂度分析。'),
    (match) =>
        '**课程内置实验入口**：`${match.group(1)}`，用于动手验证《$title》的机制；'
        '实验结论不替代概念定义与复杂度分析。',
  );
  // 课时与难度会随时间校准工具变化，课程定位行必须跟着 manifest 走。
  result = result.replaceAllMapped(
    RegExp(
      r'\*\*课程定位\*\*：所属分类为「([^」]+)」，(?:主题是|课程主题为)「([^」]+)」，'
      r'学习阶段为「[^」]+」，建议用时 \d+ 分钟。',
    ),
    (match) =>
        '**课程定位**：所属分类为「${match.group(1)}」，'
        '课程主题为「${match.group(2)}」，学习阶段为「${meta.difficulty}」，'
        '建议用时 ${meta.minutes} 分钟。',
  );
  return result;
}

void _writeCoreSection(StringBuffer buffer, String title, String body) {
  buffer.writeln('## $title');
  buffer.writeln();
  buffer.writeln(body.trim());
  buffer.writeln();
}

String _renderFrame(
  _LessonMeta meta,
  _ParsedMarkdown parsed,
  Map<String, _LessonMeta> byId,
  Map<String, List<_LessonMeta>> byCategory,
  List<_SourceSection> sources,
) {
  final previous = _neighbor(meta, byCategory, -1);
  final next = _neighbor(meta, byCategory, 1);
  final prereqText = meta.prerequisites.isEmpty
      ? '没有硬性先修课；仍建议先具备本分类的基础阅读与操作能力。'
      : meta.prerequisites
            .map((id) => byId[id] == null ? id : '《${byId[id]!.title}》')
            .join('、');
  final keywords = meta.keywords.isEmpty
      ? <String>['核心术语', '最小示例', '边界验证']
      : meta.keywords;
  final buffer = StringBuffer()
    ..writeln(
      '**课程定位**：所属分类为「${meta.categoryTitle}」，课程主题为「${meta.title}」，学习阶段为「${meta.difficulty}」，建议用时 ${meta.minutes} 分钟。',
    )
    ..writeln()
    ..writeln('**本课要解决的主问题**：${meta.summary}')
    ..writeln()
    ..writeln('| 学习层次 | 要回答的问题 | 完成判据 |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| 概念层 | 「${meta.title}」有哪些必须区分的对象与术语？ | 能用自己的话定义核心术语，并各举一个正例和一个反例。 |',
    )
    ..writeln('| 机制层 | 这些对象按什么顺序发生作用，输入如何变成输出？ | 能画出或写出机制步骤，并说明每一步的失败条件。 |')
    ..writeln(
      '| 应用层 | 什么场景适合使用「${meta.title}」，什么场景不适合？ | 能给出一个真实场景、一个最小示例和一个边界案例。 |',
    )
    ..writeln(
      '| 性能层 | 时间、空间、吞吐或延迟受哪些量影响？ | 能说出复杂度或性能瓶颈的证据来源；没有证据时明确写“材料未提供”。 |',
    )
    ..writeln('| 复习层 | 怎样确认自己不是只记住了结论？ | 能独立完成本课自测，并把错误定位到概念、机制、示例或边界。 |')
    ..writeln()
    ..writeln('### 阅读路线')
    ..writeln()
    ..writeln('1. 先读「核心概念定义」，建立「${keywords.first}」等对象的精确定义。')
    ..writeln('2. 再读「原理与运行机制」，把定义串成可重复的过程。')
    ..writeln('3. 用「代码/协议/SQL 示例」验证过程，并只改一个条件观察结果变化。')
    ..writeln('4. 最后检查性能、易错点、知识关系与自测题，形成可复习的证据链。')
    ..writeln()
    ..writeln('**前置知识**：$prereqText')
    ..writeln()
    ..writeln(
      previous == null
          ? '**学习位置**：本课是当前分类的第一课，建议从本页开始建立术语表。'
          : '**学习位置**：本课位于《${previous.title}》之后；如果前一课的自测不能通过，应先回补再继续。',
    )
    ..writeln()
    ..writeln(
      next == null
          ? '**后续衔接**：本课之后可进入项目实战或综合复习，把本课结论用于一个完整任务。'
          : '**后续衔接**：下一课《${next.title}》会继续使用本课术语，学完后建议立即完成一次自测。',
    )
    ..writeln();
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderConcepts(
  _LessonMeta meta,
  List<_Term> glossary,
  List<_SourceSection> sources,
) {
  final terms = glossary.isEmpty
      ? meta.keywords
            .take(6)
            .map((term) => _Term(term, '材料未提供独立定义；本课在示例与测验中直接使用该术语。'))
            .toList()
      : glossary;
  final buffer = StringBuffer()
    ..writeln(
      '> 在阅读《${meta.title}》时，术语第一次出现先给操作性定义，再给边界；正文说法与这里冲突时，以定义和可复现示例为准。',
    )
    ..writeln()
    ..writeln('| 术语 | 操作性定义 | 本课中的边界 |')
    ..writeln('| --- | --- | --- |');
  for (final term in terms.take(8)) {
    buffer.writeln(
      '| ${_escapeCell(term.term)} | ${_escapeCell(term.definition)} | 仅在「${_escapeCell(meta.title)}」明确给出的输入、版本与资源条件下成立。 |',
    );
  }
  buffer
    ..writeln()
    ..writeln('### 定义如何使用')
    ..writeln()
    ..writeln(
      '在「${meta.title}」中判断一个说法是否成立，先确认它使用的是哪个对象的定义，再检查输入规模、运行环境与失败路径。定义不是口号，而是后续推导、代码示例和自测题共享的约束。',
    )
    ..writeln();
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderMechanics(
  _LessonMeta meta,
  List<_Term> glossary,
  List<_SourceSection> sources,
) {
  final terms = glossary.map((term) => term.term).take(3).toList();
  final a = terms.isNotEmpty
      ? terms[0]
      : (meta.keywords.isNotEmpty ? meta.keywords.first : '输入对象');
  final b = terms.length > 1
      ? terms[1]
      : (meta.keywords.length > 1 ? meta.keywords[1] : '处理规则');
  final c = terms.length > 2
      ? terms[2]
      : (meta.keywords.length > 2 ? meta.keywords[2] : '输出结果');
  final buffer = StringBuffer()
    ..writeln('### 机制总览')
    ..writeln()
    ..writeln('1. **建立输入**：把「$a」按本课定义整理成可观察、可重复的输入条件。')
    ..writeln('2. **执行转换**：围绕「$b」执行本课的核心步骤；每一步都记录中间状态，避免只看最终输出。')
    ..writeln('3. **产生输出**：得到「$c」后，用正文示例或协议/SQL 结果核对输出是否符合预期。')
    ..writeln('4. **改变一个条件**：只替换一个边界条件或环境参数，观察「${meta.title}」的结论是否仍然成立。')
    ..writeln()
    ..writeln('| 阶段 | 关注对象 | 失败时应检查 |')
    ..writeln('| --- | --- | --- |')
    ..writeln('| 输入 | $a | 类型、范围、编码、版本或前置状态是否满足定义。 |')
    ..writeln('| 处理 | $b | 顺序、可见性、锁、路由、事务或调度规则是否被破坏。 |')
    ..writeln('| 输出 | $c | 结果是否可复现，错误是否被正确传播而不是被吞掉。 |')
    ..writeln()
    ..writeln(
      '本课的机制结论要用「${meta.title}」自己的示例验证。若正文没有给出某个数量级、吞吐或内存数据，就只能把该判断标为“材料未提供”，不能从相邻主题外推。',
    )
    ..writeln();
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderScenarios(_LessonMeta meta, List<_SourceSection> sources) {
  final keywords = meta.keywords.isEmpty ? <String>['基础示例'] : meta.keywords;
  final buffer = StringBuffer()
    ..writeln('| 场景 | 典型输入或前提 | 期望产物 |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| 学习验证 | 使用本课最小示例和 ${keywords.take(2).join('、')} | 能复现正文结论，并解释每一步。 |',
    )
    ..writeln('| 工程落地 | 把「${meta.title}」放入真实模块或服务边界 | 输出可观测、失败可定位、参数可配置。 |')
    ..writeln('| 故障排查 | 只改一个版本、规模、输入或依赖条件 | 能区分概念错误、实现错误和环境差异。 |')
    ..writeln()
    ..writeln(
      '判断《${meta.title}》的应用场景时，标准不是“看起来像”，而是能否写出输入、处理、输出和失败路径。材料中没有出现的数据要标注“材料未提供”，不能补一个无法验证的案例。',
    )
    ..writeln();
  if ((meta.lab ?? '').trim().isNotEmpty) {
    buffer
      ..writeln('**课程内置实验入口**：`${meta.lab}`。实验用于验证本课机制，不替代概念定义与复杂度分析。')
      ..writeln();
  }
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderExamples(
  _LessonMeta meta,
  List<_SourceSection> sources,
  String? firstFence,
) {
  final buffer = StringBuffer();
  final hasSourceCode = sources.any((section) => section.codeCount > 0);
  if (hasSourceCode) {
    buffer
      ..writeln(
        '以下代码、协议或 SQL 片段来自本课原文，保留原有语言标记与上下文。先预测输出，再按正文步骤运行或推演；示例依赖外部环境时，必须记录版本与输入。',
      )
      ..writeln();
  } else if (firstFence != null) {
    buffer
      ..writeln('### 最小可验证示例')
      ..writeln()
      ..writeln(
        '下面保留《${meta.title}》原文中的最小示例。先预测输出，再按正文步骤运行或推演；示例依赖外部环境时，必须记录版本与输入。',
      )
      ..writeln()
      ..writeln(firstFence.trim())
      ..writeln();
  } else {
    buffer
      ..writeln(
        '《${meta.title}》材料未提供可运行代码、协议报文或 SQL 示例；示例部分只能给出结构化检查表，不能用虚构代码替代原文。',
      )
      ..writeln()
      ..writeln('| 检查项 | 本课应补充的证据 |')
      ..writeln('| --- | --- |')
      ..writeln('| 输入 | 为「${meta.title}」列出一个最小输入及其类型。 |')
      ..writeln('| 过程 | 记录执行步骤、版本与关键中间状态。 |')
      ..writeln('| 输出 | 写出预期结果和至少一个错误结果。 |')
      ..writeln();
  }
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderPerformance(
  _LessonMeta meta,
  List<String> complexity,
  List<_SourceSection> sources,
) {
  final buffer = StringBuffer();
  if (complexity.isEmpty) {
    buffer
      ..writeln(
        '**复杂度证据**：《${meta.title}》材料未提供明确的渐近时间复杂度或空间复杂度。下面只能按本课关键词做定性检查，不能虚构 \$O\$ 记号。',
      )
      ..writeln();
  } else {
    buffer
      ..writeln(
        '**复杂度证据**：本课正文出现 ${complexity.map((item) => '`$item`').join('、')} 等量级表达式；使用前要同时确认输入规模、最好/平均/最坏情况以及常数项来源。',
      )
      ..writeln();
  }
  buffer
    ..writeln('| 维度 | 本课关注点 | 判断依据 |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| 时间/延迟 | 「${meta.title}」的主要步骤是否会随输入规模、并发度或网络往返增长。 | 以正文复杂度、基准数据或可重复测量为准。 |',
    )
    ..writeln('| 空间/内存 | 中间状态、缓存、副本、连接或索引是否随规模增长。 | 记录峰值内存与数据副本，不只看最终结果。 |')
    ..writeln('| 吞吐/资源 | 版本、调度、锁、IO、序列化或协议开销是否成为瓶颈。 | 固定环境做对照实验，改变一个变量。 |')
    ..writeln()
    ..writeln(
      '分析《${meta.title}》时必须区分“正确性成立”和“性能达标”。材料没有给出基准时，只保留量级来源与测量方法，不给出不可验证的绝对数字。',
    )
    ..writeln();
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderPitfalls(_LessonMeta meta, List<_SourceSection> sources) {
  final buffer = StringBuffer()
    ..writeln('> 复核《${meta.title}》时，优先保留原有错误表、故障现场与排错路径；每条误区的修正都要能用本课示例复验。')
    ..writeln()
    ..writeln('| 易错点 | 常见表现 | 正确做法 |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| 只背结论 | 能复述「${meta.title}」的定义，却说不清输入、输出与边界。 | 回到机制步骤，用最小示例逐一验证。 |',
    )
    ..writeln('| 混淆相邻概念 | 把本课对象与相邻主题的对象当成同一类。 | 先比较定义、资源归属、生命周期和失败模式。 |')
    ..writeln('| 忽略版本与环境 | 在开发机通过后直接外推到生产环境。 | 固定版本、输入和资源条件，再记录可复现结果。 |')
    ..writeln();
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderRelations(
  _LessonMeta meta,
  Map<String, _LessonMeta> byId,
  Map<String, List<_LessonMeta>> byCategory,
  List<_SourceSection> sources,
) {
  final previous = _neighbor(meta, byCategory, -1);
  final next = _neighbor(meta, byCategory, 1);
  final rows = <String>[];
  for (final id in meta.prerequisites) {
    rows.add('| 先修 | 《${byId[id]?.title ?? id}》 | 本课会直接使用它的概念或操作前提。 |');
  }
  for (final id in meta.related) {
    rows.add('| 关联 | 《${byId[id]?.title ?? id}》 | 用于横向比较或把本课结论迁移到相邻主题。 |');
  }
  if (previous != null) {
    rows.add('| 前置顺序 | 《${previous.title}》 | 同分类中安排在本课之前，建议先完成其自测。 |');
  }
  if (next != null) {
    rows.add('| 后续顺序 | 《${next.title}》 | 同分类中安排在本课之后，会继续使用本课术语。 |');
  }
  if (rows.isEmpty) {
    rows.add('| 独立主题 | 当前清单没有记录显式先修或关联课程 | 仍可按术语、机制、示例和性能四个层次复习。 |');
  }
  final buffer = StringBuffer()
    ..writeln('| 关系 | 课程 | 为什么 |')
    ..writeln('| --- | --- | --- |')
    ..writeln(rows.join('\n'))
    ..writeln()
    ..writeln(
      '把「${meta.title}」放回知识体系时，不只要记住“前面学过什么”，还要说明两个主题在输入、机制、资源边界和失败模式上的差异。这样才能把单课知识迁移到项目、排障和后续课程。',
    )
    ..writeln();
  _appendSources(buffer, sources);
  return buffer.toString();
}

String _renderSelfTests(_LessonMeta meta, List<_SourceSection> sources) {
  final buffer = StringBuffer()
    ..writeln('> 先独立完成《${meta.title}》的自测，再核对答案与解析。答案必须能在本课正文或示例中找到依据，不能只凭语感。')
    ..writeln();
  if (meta.quiz.isEmpty) {
    buffer.writeln('材料未提供本课自测题。');
  } else {
    final selected = _selectQuestions(meta.quiz, 3);
    for (var index = 0; index < selected.length; index++) {
      final question = selected[index];
      buffer
        ..writeln('### 自测 ${index + 1}')
        ..writeln()
        ..writeln(question['question']?.toString() ?? '材料未提供题干');
      final code = question['code']?.toString().trim() ?? '';
      if (code.isNotEmpty) {
        final language = question['language']?.toString() ?? 'text';
        buffer
          ..writeln()
          ..writeln('```$language')
          ..writeln(code)
          ..writeln('```');
      }
      final options = (question['options'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList();
      if (options.isNotEmpty) {
        buffer.writeln();
        for (var option = 0; option < options.length; option++) {
          buffer.writeln(
            '${String.fromCharCode(65 + option)}. ${options[option]}',
          );
        }
      }
      final answer = _answerText(question, options);
      buffer
        ..writeln()
        ..writeln('**参考答案**：$answer')
        ..writeln()
        ..writeln('**解析**：${question['explanation']?.toString() ?? '材料未提供解析。'}')
        ..writeln();
    }
  }
  _appendSources(buffer, sources);
  return buffer.toString();
}

void _appendSources(StringBuffer buffer, List<_SourceSection> sources) {
  for (final section in sources) {
    final body = section.body.trim();
    if (body.isEmpty) continue;
    buffer
      ..writeln('**教材衔接：${section.title}**')
      ..writeln()
      ..writeln(body)
      ..writeln();
  }
}

String _bucketFor(_SourceSection section) {
  final title = section.title;
  if (_matches(title, <String>[
    '学习目标',
    '前置知识',
    '本课小结',
    '小结',
    '总结',
    '知识框架',
    '课程定位',
  ])) {
    return '本节知识框架';
  }
  if (_matches(title, <String>[
    '核心概念',
    '概念',
    '定义',
    '术语',
    '变量',
    '类型',
    '模型',
    '数据结构',
    '对象',
  ])) {
    return '核心概念定义';
  }
  if (_matches(title, <String>[
    '常见错误',
    '误区',
    '易错',
    '故障',
    '坑',
    '陷阱',
    '反模式',
    '失败',
    '排错',
  ])) {
    return '常见误区与易错点';
  }
  if (_matches(title, <String>[
    '关系',
    '关联',
    '对照',
    '比较',
    '知识体系',
    '先修',
    '后续',
    '复习与迁移',
  ])) {
    return '与其他知识点的关系';
  }
  if (_matches(title, <String>['自测', '测验', '复习清单', '复习', '练习', '考点'])) {
    return '自测题与参考答案';
  }
  if (_matches(title, <String>[
    '性能',
    '复杂度',
    '开销',
    '延迟',
    '吞吐',
    '内存',
    '缓存',
    '并发',
    '调优',
    '优化',
    '基准',
  ])) {
    return '时间/空间复杂度或性能分析';
  }
  if (_matches(title, <String>['应用', '场景', '实战', '项目', '案例', '实验', '动手'])) {
    return '典型应用场景';
  }
  if (_matches(title, <String>[
    '代码',
    '示例',
    '语法',
    'SQL',
    '命令',
    'API',
    '协议',
    '配置',
    '部署',
    '测试',
  ])) {
    return '代码/协议/SQL 示例';
  }
  if (_matches(title, <String>[
    '原理',
    '机制',
    '结构',
    '流程',
    '工作',
    '生命周期',
    '实现',
    '架构',
    '算法',
    '运行',
    '上下文',
    '设计',
  ])) {
    return '原理与运行机制';
  }
  return section.codeCount > 0 ? '代码/协议/SQL 示例' : '原理与运行机制';
}

bool _matches(String title, List<String> needles) =>
    needles.any(title.contains);

List<_Term> _parseGlossary(List<_SourceSection> sections) {
  final section = sections.where((item) => item.title == '术语速查').firstOrNull;
  if (section == null) return const <_Term>[];
  final terms = <_Term>[];
  for (final raw in section.body.split('\n')) {
    final line = raw.trim();
    if (!line.startsWith('|')) continue;
    final cells = line.split('|').map((cell) => cell.trim()).toList();
    if (cells.length < 4) continue;
    final term = cells[1].replaceAll('`', '').trim();
    final definition = cells[2].replaceAll('`', '').trim();
    if (term.isEmpty ||
        term == '术语' ||
        term == '---' ||
        term.contains('一句话说明')) {
      continue;
    }
    if (definition.isEmpty || definition.contains('一句话说明')) continue;
    terms.add(_Term(term, definition));
  }
  return terms;
}

List<String> _extractComplexity(String markdown) {
  final found = <String>{};
  for (final match in RegExp(
    r'O\s*\([^)\n]{1,40}\)|Θ\s*\([^)\n]{1,40}\)|Ω\s*\([^)\n]{1,40}\)',
  ).allMatches(markdown)) {
    found.add(match.group(0)!.replaceAll(RegExp(r'\s+'), ' ').trim());
  }
  return found.take(6).toList();
}

String? _extractFirstFence(String markdown) {
  final lines = markdown.split('\n');
  final mask = markdownFenceMask(markdown);
  for (var index = 0; index < lines.length; index++) {
    if (!mask[index]) continue;
    final line = lines[index].trimLeft();
    final run = _backtickRun(line);
    if (run < 3) continue;
    for (var end = index + 1; end < lines.length; end++) {
      if (!mask[end]) continue;
      final close = lines[end].trimLeft();
      if (_backtickRun(close) >= run &&
          close.substring(_backtickRun(close)).trim().isEmpty) {
        return lines.sublist(index, end + 1).join('\n');
      }
    }
    return null;
  }
  return null;
}

int _backtickRun(String line) {
  var count = 0;
  while (count < line.length && line[count] == '`') {
    count++;
  }
  return count;
}

List<Map<String, dynamic>> _selectQuestions(
  List<Map<String, dynamic>> quiz,
  int count,
) {
  if (quiz.length <= count) return quiz;
  final selected = <Map<String, dynamic>>[];
  final buckets = <String, List<Map<String, dynamic>>>{};
  for (final question in quiz) {
    final type = question['type']?.toString() ?? 'single';
    buckets.putIfAbsent(type, () => <Map<String, dynamic>>[]).add(question);
  }
  for (final list in buckets.values) {
    if (selected.length >= count) break;
    selected.add(list.first);
  }
  for (final question in quiz) {
    if (selected.length >= count) break;
    if (!selected.contains(question)) selected.add(question);
  }
  return selected;
}

String _answerText(Map<String, dynamic> question, List<String> options) {
  final type = question['type']?.toString() ?? 'single';
  if (type == 'fill') {
    final answers = (question['accepted_answers'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    return answers.isEmpty ? '材料未提供参考答案。' : answers.join(' / ');
  }
  if (type == 'order') {
    final order = (question['correct_order'] as List<dynamic>? ?? const [])
        .map(
          (item) => item is num ? item.toInt() : int.tryParse(item.toString()),
        )
        .whereType<int>()
        .toList();
    if (order.isEmpty) return '材料未提供参考答案。';
    return order
        .map(
          (index) => index >= 0 && index < options.length
              ? options[index]
              : '[$index]',
        )
        .join(' → ');
  }
  final indexes = <int>[];
  final answers = question['answers'] as List<dynamic>? ?? const [];
  indexes.addAll(
    answers
        .map(
          (item) => item is num ? item.toInt() : int.tryParse(item.toString()),
        )
        .whereType<int>(),
  );
  if (indexes.isEmpty) {
    final answer = question['answer'];
    final index = answer is num
        ? answer.toInt()
        : int.tryParse(answer?.toString() ?? '');
    if (index != null) indexes.add(index);
  }
  final texts = indexes
      .where((index) => index >= 0 && index < options.length)
      .map((index) => options[index])
      .where((text) => text.isNotEmpty)
      .toList();
  return texts.isEmpty ? '材料未提供参考答案。' : texts.join('；');
}

_LessonMeta? _neighbor(
  _LessonMeta meta,
  Map<String, List<_LessonMeta>> byCategory,
  int offset,
) {
  final list = byCategory[meta.categoryId] ?? const <_LessonMeta>[];
  final index = list.indexWhere((item) => item.id == meta.id) + offset;
  return index >= 0 && index < list.length ? list[index] : null;
}

String _escapeCell(String text) =>
    text.replaceAll('|', r'\|').replaceAll('\n', ' ').trim();

_ParsedMarkdown _parseMarkdown(String markdown) {
  final lines = markdown.split('\n');
  final mask = markdownFenceMask(markdown);
  var h1Index = -1;
  for (var index = 0; index < lines.length; index++) {
    if (!mask[index] && RegExp(r'^#\s+\S').hasMatch(lines[index])) {
      h1Index = index;
      break;
    }
  }
  final headings = <int>[];
  for (var index = h1Index + 1; index < lines.length; index++) {
    if (!mask[index] && RegExp(r'^##\s+\S').hasMatch(lines[index])) {
      headings.add(index);
    }
  }
  final preambleEnd = headings.isEmpty ? lines.length : headings.first;
  final preamble = lines
      .sublist(h1Index < 0 ? 0 : h1Index + 1, preambleEnd)
      .join('\n');
  final sections = <_SourceSection>[];
  for (var index = 0; index < headings.length; index++) {
    final start = headings[index];
    final end = index + 1 < headings.length
        ? headings[index + 1]
        : lines.length;
    final title = lines[start].replaceFirst(RegExp(r'^##\s+'), '').trim();
    final body = lines.sublist(start + 1, end).join('\n');
    sections.add(_SourceSection(title, body, _countFences(body)));
  }
  return _ParsedMarkdown(preamble: preamble, sections: sections);
}

int _countFences(String text) =>
    RegExp(r'^```', multiLine: true).allMatches(text).length;

bool _hasTextbookStructure(_ParsedMarkdown parsed) {
  final titles = parsed.sections.map((section) => section.title).toSet();
  return coreSections.every(titles.contains);
}

List<String> _validateRebuild(
  String original,
  String rebuilt,
  _ParsedMarkdown parsed,
  _LessonMeta meta,
) {
  final issues = <String>[];
  final rebuiltParsed = _parseMarkdown(rebuilt);
  final titles = rebuiltParsed.sections
      .map((section) => section.title)
      .toList();
  for (final title in coreSections) {
    final count = titles.where((item) => item == title).length;
    if (count != 1) issues.add('核心章节「$title」出现 $count 次');
  }
  for (final title in legacyCanonicalSections) {
    if (titles.contains(title)) issues.add('仍残留旧章节「$title」');
  }
  if (_countFences(rebuilt) < _countFences(original)) {
    issues.add('代码围栏数量从 ${_countFences(original)} 降到 ${_countFences(rebuilt)}');
  }
  final oldImages = RegExp(r'!\[[^\]]*\]\(images/').allMatches(original).length;
  final newImages = RegExp(r'!\[[^\]]*\]\(images/').allMatches(rebuilt).length;
  if (newImages < oldImages) {
    issues.add('配图数量从 $oldImages 降到 $newImages');
  }
  if (!rebuilt.contains('# ${meta.title}')) {
    issues.add('H1 标题未保留为「${meta.title}」');
  }
  return issues;
}

String _option(List<String> args, String prefix) => args
    .firstWhere((arg) => arg.startsWith(prefix), orElse: () => prefix)
    .substring(prefix.length);

String _localized(dynamic value, {bool english = false}) {
  if (value is String) return value;
  if (value is Map) {
    final key = english ? 'en' : 'zh';
    return value[key]?.toString() ?? value.values.firstOrNull?.toString() ?? '';
  }
  return value?.toString() ?? '';
}

List<String> _stringList(dynamic value) {
  if (value == null) return const <String>[];
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return value
      .toString()
      .split(RegExp(r'[,，\s]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class _LessonMeta {
  const _LessonMeta({
    required this.id,
    required this.categoryId,
    required this.categoryTitle,
    required this.title,
    required this.titleEn,
    required this.summary,
    required this.file,
    required this.difficulty,
    required this.minutes,
    required this.keywords,
    required this.prerequisites,
    required this.related,
    required this.quiz,
    required this.lab,
    required this.order,
  });

  final String id;
  final String categoryId;
  final String categoryTitle;
  final String title;
  final String titleEn;
  final String summary;
  final String file;
  final String difficulty;
  final int minutes;
  final List<String> keywords;
  final List<String> prerequisites;
  final List<String> related;
  final List<Map<String, dynamic>> quiz;
  final String? lab;
  final int order;
}

class _ParsedMarkdown {
  const _ParsedMarkdown({required this.preamble, required this.sections});

  final String preamble;
  final List<_SourceSection> sections;
}

class _SourceSection {
  const _SourceSection(this.title, this.body, this.codeCount);

  final String title;
  final String body;
  final int codeCount;
}

class _Term {
  const _Term(this.term, this.definition);

  final String term;
  final String definition;
}
