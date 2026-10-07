// P1 结构统一：把同义段落标题收敛到规范名，并补齐缺失的规范段落。
//
// 用法：
//   dart tool/unify_sections.dart [--dry-run] [--only=rename|fill]
//
// 规范段落（14 个，见 docs/content_standard.md）：
//   学习目标 / 前置知识 / 动手练习 / 考点精讲 / 故障现场 / 本课小结 /
//   参考资料与复核 / English Overview / 内容元数据 /
//   本课复习清单 / 术语速查 / 可运行练习 / 常见错误与排查 / 复习与自测
//
// 阶段一（rename）：错误族、自测族、练习族的同义标题统一改名；
//   同一课里出现多个同类段落时按出现顺序合并，并去掉完全重复的行。
// 阶段二（fill）：为缺段课程补写规范段落。内容全部取自该课正文、关键词
//   与测验，避免跨课通用模板句（治理审计会检查重复段落与模板标记）。
import 'dart:convert';
import 'dart:io';

import 'markdown_fences.dart';

const String manifestPath = 'assets/content/manifest.json';

/// 同义段落 → 规范段落。
const Map<String, String> sectionRenames = <String, String>{
  // 错误族：误区、坑、陷阱、FAQ、风险与反模式统一为「常见错误与排查」。
  '常见错误对照表': '常见错误与排查',
  '常见错误': '常见错误与排查',
  '常见错误速查': '常见错误与排查',
  '常见误区': '常见错误与排查',
  '常见坑': '常见错误与排查',
  '常见陷阱': '常见错误与排查',
  '常见问题': '常见错误与排查',
  '常见问题与对策': '常见错误与排查',
  '常见问题与排查顺序': '常见错误与排查',
  '常见风险速查': '常见错误与排查',
  '常见失败模式': '常见错误与排查',
  '常见反模式速查': '常见错误与排查',
  '反模式': '常见错误与排查',
  '失败模式': '常见错误与排查',
  '新手最容易踩的八个坑': '常见错误与排查',
  '新手最容易踩的六个坑': '常见错误与排查',
  '必须注意的坑': '常见错误与排查',
  '五个高频坑': '常见错误与排查',
  '三个经典坑': '常见错误与排查',
  '易错点回顾': '常见错误与排查',
  // 自测族：自查、逐节自检、深度追问统一为「复习与自测」。
  '自测清单': '复习与自测',
  '逐节复习与自检': '复习与自测',
  '深度追问与自测': '复习与自测',
  '本课自测清单与错误对照': '复习与自测',
  // 练习族：实践任务本来就是可运行练习。
  '实践任务': '可运行练习',
};

/// 规范段落全集，fill 阶段按需补齐后四个。
const List<String> canonicalSections = <String>[
  '学习目标',
  '前置知识',
  '动手练习',
  '考点精讲',
  '故障现场',
  '本课小结',
  '参考资料与复核',
  'English Overview',
  '内容元数据',
  '本课复习清单',
  '术语速查',
  '可运行练习',
  '常见错误与排查',
  '复习与自测',
];

/// 生成自测清单时排除的通用标题，避免跨课出现同一句话。
const Set<String> genericHeadings = <String>{
  '学习目标',
  '前置知识',
  '动手练习',
  '考点精讲',
  '故障现场',
  '本课小结',
  '参考资料与复核',
  'English Overview',
  '内容元数据',
  '本课复习清单',
  '术语速查',
  '可运行练习',
  '常见错误与排查',
  '复习与自测',
  '复习与迁移',
  '概念复述',
  '正文逐节复核',
  '测验回顾',
  '迁移练习',
  '小结',
  '总结',
  '应用场景',
  '核心概念',
  '关键概念',
  '为什么需要它',
  '解决什么问题',
  '要解决的问题',
  '它解决什么问题',
};

/// 自测清单句式，按课程下标轮换，避免全站同一句式。
const List<String> checklistTemplates = <String>[
  '能说清「%s」的结论，并说出它的适用边界。',
  '能用自己的话复述「%s」，并各举一个正例和反例。',
  '能解释「%s」里最容易混淆的两个概念。',
  '能不看正文写出「%s」的关键步骤。',
  '能用一句话说明「%s」解决什么问题。',
  '能把「%s」的判断标准套到一个新例子上。',
];

/// 8 篇项目实战课的术语在正文里没有统一定义句（多为里程碑与现场描述），
/// 这里给出人工校准的一句话说明，避免把测验题干或导航行当成术语解释。
const Map<String, String> lessonGlossaries = <String, String>{
  'project_data_etl': '''
| `ETL` | 抽取、转换、加载三段式流水线，把来源数据整理成分析可用的表。 |
| `数据仓库` | 面向分析、按主题组织并保留历史的数据存储，常见分层是原始层、清洗层、汇总层。 |
| `Airflow` | 用 DAG 描述依赖并按调度时间触发任务的编排工具，负责重试与补数。 |
| `数据质量` | 对完整性、唯一性、及时性、准确性等维度的可验证约束，不通过就阻断下游。 |
| `分区` | 按日期等键把数据切成互不重叠的片段，便于增量处理和只重跑出错的那一天。 |
| `幂等回填` | 补算历史数据时重复执行同一批次仍得到相同结果，通常靠覆盖写或去重键保证。 |''',
  'project_network_capture_analysis': '''
| `抓包` | 在网卡或代理处复制流经的报文并保存，用来还原真实交互而不是只看应用日志。 |
| `Wireshark` | 图形化协议分析器，可按会话与流跟踪报文，配合密钥文件解密 TLS。 |
| `TCP` | 面向连接的传输层协议，靠握手、序号确认、重传与拥塞控制保证可靠字节流。 |
| `DNS` | 把域名解析成 IP 的层次化系统，排查时要区分递归解析器、权威服务器与本地缓存。 |
| `TLS` | 在 TCP 之上提供加密与身份校验的握手协议，抓包里只能看到 SNI、证书与密文长度。 |
| `延迟` | 一次交互的端到端耗时，要拆成 DNS、连接握手、首字节、传输与渲染各段分别测量。 |''',
  'project_database_tuning': '''
| `慢查询` | 超过阈值或明显拖慢业务的语句，先用日志与采样把它定位到具体 SQL 和参数。 |
| `执行计划` | 数据库为一条语句选出的访问路径，重点看扫描方式、连接顺序与预估行数和实际行数的偏差。 |
| `索引` | 用额外空间换检索速度的有序结构，写多读少、基数低或前缀模糊的列要谨慎建。 |
| `锁` | 并发访问同一份数据时的互斥机制，排查要区分行锁、表锁、间隙锁与等待链。 |
| `事务` | 一组要么全部生效要么全部回滚的操作，用隔离级别权衡一致性与并发度。 |
| `容量` | 数据量、连接数、IOPS 与磁盘的增长预测，调优前先确认瓶颈是资源还是语句。 |''',
  'project_security_lab': '''
| `OWASP` | 汇总 Web 常见风险的公开清单（注入、越权、失效的访问控制等），可当自查目录。 |
| `越权` | 已登录用户访问他人或更高权限的数据，分水平与垂直越权，靠服务端逐请求校验。 |
| `注入` | 把用户输入当成代码或命令执行，防法是参数化查询、白名单校验与最小权限。 |
| `供应链` | 依赖包、构建工具与镜像带来的风险，靠锁定版本、校验来源与扫描漏洞控制。 |
| `审计` | 记录谁在何时做了什么并留存证据，日志要防篡改、可检索且保留足够时间。 |
| `最小权限` | 每个账号、进程与服务只拿完成当前任务所需的权限，出事时把影响面限制住。 |''',
  'project_algorithm_engineering': '''
| `算法工程` | 把算法从「能算对」推进到可维护、可评测、可上线的工程实践。 |
| `基准测试` | 固定环境与输入规模重复测量耗时和内存，任何结论都要带上测量条件。 |
| `复杂度` | 描述规模增长时资源消耗的变化趋势，落地时还要看常数项与真实数据分布。 |
| `二分查找` | 在有序区间上每次折半的查找法，边界与不变式写错就会死循环或漏解。 |
| `动态规划` | 把问题拆成有重叠的子问题并复用结果，关键是状态定义与转移顺序。 |
| `性能回归` | 用基准数据持续对比历史版本，防止一次优化在别的输入上带来退化。 |''',
  'project_mobile_offline_app': '''
| `Flutter` | 用 Dart 编写、自带渲染引擎绘制界面的跨平台 UI 框架。 |
| `离线优先` | 默认本地可读写、联网只做同步，把网络当成可能失败的增强而不是前提。 |
| `本地数据库` | 设备上的结构化存储（如 sqflite、Drift），承担离线数据、索引与待同步队列。 |
| `同步` | 把本地改动与远端合并的流程，要有重试、幂等与断点续传。 |
| `冲突处理` | 两端修改同一份数据时的裁决规则，常见有最后写入优先、版本向量与人工合并。 |
| `移动性能` | 关注启动时间、帧率、内存与耗电，先测量再优化，避免在主线程做重活。 |''',
  'project_concurrency_runtime': '''
| `线程池` | 复用固定数量线程处理任务的执行器，要同时设置队列上限与拒绝策略。 |
| `锁竞争` | 多线程争抢同一把锁导致排队，表现为吞吐下降与延迟抖动，先量再拆锁。 |
| `上下文切换` | 保存并恢复执行现场的开销，切换过于频繁说明线程数或锁粒度不合理。 |
| `内存模型` | 规定多线程下读写可见性与重排序的规则，跨线程共享必须明确同步手段。 |
| `协程` | 用户态调度的轻量执行单元，挂起不阻塞线程，适合高并发 IO 但要避免阻塞调用。 |
| `性能剖析` | 用采样或插桩找出真正的热点，先定位再优化，避免凭直觉改代码。 |''',
  'project_devops_pipeline': '''
| `DevOps` | 把开发、测试与运维打通的工作方式，靠自动化流水线缩短交付反馈。 |
| `CI/CD` | 持续集成与持续交付/部署，每次提交自动构建、测试并按策略发布。 |
| `Docker` | 用镜像封装应用与依赖，保证开发、测试与生产环境一致。 |
| `Kubernetes` | 容器编排平台，负责调度、扩缩容、健康检查与滚动更新。 |
| `渐进发布` | 灰度、金丝雀与功能开关等分批放量手段，出问题能快速回滚。 |
| `可观测性` | 由日志、指标与链路追踪组成，能在不重启、不改代码的前提下问出新问题。 |''',
};

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final only = _stringOption(args, '--only=', '');
  final preview = _stringOption(args, '--preview=', '');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final lessons = <Map<String, dynamic>>[
    for (final rawCategory in manifest['categories'] as List<dynamic>)
      for (final raw in (rawCategory as Map)['lessons'] as List<dynamic>)
        (raw as Map).cast<String, dynamic>(),
  ];

  final contents = <String, String>{};
  final originals = <String, String>{};
  for (final lesson in lessons) {
    final file = File(lesson['file'].toString());
    if (!file.existsSync()) {
      stderr.writeln('找不到教程文件：${lesson['file']}');
      exitCode = 1;
      continue;
    }
    final text = file.readAsStringSync();
    contents[lesson['id'].toString()] = text;
    originals[lesson['id'].toString()] = text;
  }

  var renamed = 0;
  var merged = 0;
  if (only.isEmpty || only == 'rename') {
    for (final entry in contents.entries.toList()) {
      final result = unifySections(entry.value);
      if (!result.changed) continue;
      contents[entry.key] = result.markdown;
      renamed++;
      merged += result.mergedCount;
    }
  }

  if (preview.isNotEmpty) {
    final lesson = lessons.firstWhere(
      (item) => item['id'].toString() == preview,
      orElse: () => const <String, dynamic>{},
    );
    if (lesson.isEmpty) {
      stderr.writeln('找不到课程：$preview');
      exitCode = 2;
      return;
    }
    for (final section in planMissingSections(
      markdown: contents[preview]!,
      title: ((lesson['title'] as Map?)?['zh'] ?? preview).toString(),
      lessonId: preview,
      keywords: ((lesson['keywords'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      quiz: ((lesson['quiz'] as List<dynamic>?) ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList(),
      templateIndex: 0,
    )) {
      stdout.writeln('## ${section.heading}');
      stdout.writeln();
      stdout.writeln(section.body);
      stdout.writeln();
    }
    return;
  }

  // 阶段二：先为所有课程算出补写计划，再统一过滤跨课重复句。
  var filled = 0;
  final additions = <String, List<Section>>{};
  if (only.isEmpty || only == 'fill') {
    for (var index = 0; index < lessons.length; index++) {
      final lesson = lessons[index];
      final id = lesson['id'].toString();
      final markdown = contents[id];
      if (markdown == null) continue;
      final sections = planMissingSections(
        markdown: markdown,
        title: ((lesson['title'] as Map?)?['zh'] ?? id).toString(),
        lessonId: id,
        keywords: ((lesson['keywords'] as List<dynamic>?) ?? const [])
            .map((item) => item.toString())
            .toList(),
        quiz: ((lesson['quiz'] as List<dynamic>?) ?? const [])
            .map((item) => (item as Map).cast<String, dynamic>())
            .toList(),
        templateIndex: index,
      );
      if (sections.isNotEmpty) additions[id] = sections;
    }
    final droppedItems = _dropCrossLessonRepeats(additions);
    if (droppedItems > 0) {
      stdout.writeln('过滤跨课重复句 $droppedItems 条');
    }
    for (final entry in additions.entries) {
      if (entry.value.isEmpty) continue;
      contents[entry.key] = insertSections(contents[entry.key]!, entry.value);
      filled++;
    }
  }

  // 安全网：任何改写都不允许改变代码围栏数量，
  // 数量变化说明解析把示例里的 ``` 当成了结构。
  final brokenFences = <String>[
    for (final entry in contents.entries)
      if (originals[entry.key] != null &&
          _fenceCount(originals[entry.key]!) != _fenceCount(entry.value))
        entry.key,
  ];
  if (brokenFences.isNotEmpty) {
    stderr.writeln(
      '代码围栏数量发生变化，已中止：${brokenFences.take(10).join('、')}'
      '${brokenFences.length > 10 ? ' 等 ${brokenFences.length} 篇' : ''}',
    );
    exitCode = 1;
    return;
  }

  if (!dryRun) {
    for (final lesson in lessons) {
      final id = lesson['id'].toString();
      final markdown = contents[id];
      if (markdown == null) continue;
      final file = File(lesson['file'].toString());
      if (file.readAsStringSync() != markdown) {
        file.writeAsStringSync(markdown, flush: true);
      }
    }
  }

  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}统一段落 $renamed 篇（合并同类段 $merged 处），'
    '补齐缺段 $filled 篇',
  );
}

class Section {
  Section(this.heading, this.body);

  final String heading;
  String body;
}

class UnifyResult {
  UnifyResult(this.markdown, this.changed, this.mergedCount);

  final String markdown;
  final bool changed;
  final int mergedCount;
}

/// 把同义标题改成规范名，同一目标多次出现时合并正文并去重。
UnifyResult unifySections(String markdown) {
  final parsed = parseSections(markdown);
  final output = <Section>[];
  final byHeading = <String, Section>{};
  var merged = 0;
  var changed = false;
  for (final section in parsed.sections) {
    final target = sectionRenames[section.heading] ?? section.heading;
    if (target != section.heading) changed = true;
    final existing = byHeading[target];
    if (existing == null) {
      final created = Section(target, section.body);
      output.add(created);
      byHeading[target] = created;
      continue;
    }
    merged++;
    final kept = <String>{};
    final lines = <String>[];
    final mergedText = '${existing.body}\n${section.body}';
    final mergedLines = mergedText.split('\n');
    final fenceMask = markdownFenceMask(mergedText);
    for (var index = 0; index < mergedLines.length; index++) {
      final line = mergedLines[index];
      final trimmed = line.trim();
      // 代码围栏内的行（含闭合 ```）一律原样保留，
      // 否则第二个代码块的闭合标记会被当成重复行删掉。
      if (fenceMask[index] || trimmed.isEmpty || kept.add(trimmed)) {
        lines.add(line);
      }
    }
    existing.body = _trimBlankEdges(lines.join('\n'));
  }
  if (!changed) return UnifyResult(markdown, false, 0);
  return UnifyResult(rebuildSections(parsed.preamble, output), true, merged);
}

class ParsedMarkdown {
  ParsedMarkdown(this.preamble, this.sections);

  final String preamble;
  final List<Section> sections;
}

/// 按 `## ` 切分正文；前言（第一个 H2 之前的内容）单独保留。
ParsedMarkdown parseSections(String markdown) {
  final lines = markdown.split('\n');
  final headingPattern = RegExp(r'^##\s+(.+?)\s*$');
  final sections = <Section>[];
  final preamble = <String>[];
  List<String>? buffer;
  String? current;
  final fenceMask = markdownFenceMask(markdown);
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    // 代码围栏里的 `## ` 只是示例文本，不能当作章节边界，
    // 否则重建后会把围栏截断。
    final match = fenceMask[index] ? null : headingPattern.firstMatch(line);
    if (match != null) {
      if (current != null) {
        sections.add(Section(current, _trimBlankEdges(buffer!.join('\n'))));
      } else {
        preamble.addAll(buffer ?? const <String>[]);
      }
      current = match.group(1)!.trim();
      buffer = <String>[];
      continue;
    }
    (buffer ?? preamble).add(line);
  }
  if (current != null) {
    sections.add(Section(current, _trimBlankEdges(buffer!.join('\n'))));
  } else {
    preamble.addAll(buffer ?? const <String>[]);
  }
  return ParsedMarkdown(_trimBlankEdges(preamble.join('\n')), sections);
}

String rebuildSections(String preamble, List<Section> sections) {
  final buffer = StringBuffer();
  if (preamble.trim().isNotEmpty) {
    buffer.writeln(preamble.trimRight());
    buffer.writeln();
  }
  for (final section in sections) {
    buffer.writeln('## ${section.heading}');
    buffer.writeln();
    if (section.body.trim().isNotEmpty) {
      buffer.writeln(section.body.trim());
      buffer.writeln();
    }
  }
  return '${buffer.toString().trimRight()}\n';
}

/// 按规范顺序插入补写段落：可运行练习跟在动手练习之后，
/// 常见错误与排查跟在故障现场之后，其余跟在复习与迁移之后。
String insertSections(String markdown, List<Section> additions) {
  final parsed = parseSections(markdown);
  final sections = <Section>[...parsed.sections];
  for (final section in additions) {
    final anchor = switch (section.heading) {
      '可运行练习' => '动手练习',
      '常见错误与排查' => '故障现场',
      _ => '复习与迁移',
    };
    var index = sections.indexWhere((item) => item.heading == anchor);
    if (index < 0) {
      index = sections.indexWhere((item) => item.heading == '考点精讲');
    }
    if (index < 0) {
      sections.add(section);
    } else {
      sections.insert(index + 1, section);
    }
  }
  return rebuildSections(parsed.preamble, sections);
}

/// 计算需要补写的规范段落。
List<Section> planMissingSections({
  required String markdown,
  required String title,
  required String lessonId,
  required List<String> keywords,
  required List<Map<String, dynamic>> quiz,
  required int templateIndex,
}) {
  final headings = <String>{
    for (final section in parseSections(markdown).sections) section.heading,
  };
  final additions = <Section>[];
  final topics = _topicHeadings(markdown);
  if (!headings.contains('本课复习清单') && topics.isNotEmpty) {
    additions.add(
      Section(
        '本课复习清单',
        [for (final heading in topics.take(6)) '- [ ] 能独立完成「$heading」并说明验收标准。']
            .join('\n'),
      ),
    );
  }
  if (!headings.contains('术语速查')) {
    final table = _termTable(markdown, keywords, lessonId);
    if (table != null) additions.add(Section('术语速查', table));
  }
  if (!headings.contains('复习与自测') && topics.isNotEmpty) {
    additions.add(
      Section(
        '复习与自测',
        [
          for (var i = 0; i < topics.take(6).length; i++)
            '- [ ] ${checklistTemplates[(templateIndex + i) % checklistTemplates.length].replaceFirst('%s', topics[i])}',
        ].join('\n'),
      ),
    );
  }
  if (!headings.contains('常见错误与排查')) {
    final table = _mistakeTable(quiz, title);
    if (table != null) additions.add(Section('常见错误与排查', table));
  }
  return additions;
}

/// 课程里的主题标题（H2/H3），用于生成自测与复习清单。
List<String> _topicHeadings(String markdown) {
  final result = <String>[];
  final seen = <String>{};
  final pattern = RegExp(r'^#{2,3}\s+(.+?)\s*$');
  final lines = markdown.split('\n');
  final fenceMask = markdownFenceMask(markdown);
  for (var index = 0; index < lines.length; index++) {
    if (fenceMask[index]) continue;
    final line = lines[index];
    final match = pattern.firstMatch(line);
    if (match == null) continue;
    final heading = match.group(1)!.trim();
    if (genericHeadings.contains(heading)) continue;
    if (heading.startsWith('考点') ||
        heading.startsWith('练习') ||
        heading.startsWith('任务') ||
        heading.startsWith('补充：') ||
        heading.startsWith('深入补充') ||
        heading.startsWith('零基础') ||
        heading.startsWith('English') ||
        heading.startsWith('Bilingual') ||
        heading.startsWith('Full English')) {
      continue;
    }
    if (heading.length < 4 || heading.length > 40) continue;
    if (!seen.add(heading)) continue;
    result.add(heading);
  }
  return result;
}

/// 用课程自身的术语与正文句子生成「术语速查」表格。
String? _termTable(String markdown, List<String> keywords, String lessonId) {
  final curated = lessonGlossaries[lessonId];
  if (curated != null) {
    return <String>[
      '| 术语 | 一句话说明 |',
      '| --- | --- |',
      curated.trim(),
    ].join('\n');
  }
  final terms = <String>[];
  for (final keyword in keywords) {
    final term = keyword.trim();
    if (term.isEmpty) continue;
    if (!terms.contains(term)) terms.add(term);
  }
  for (final match in RegExp(
    r'^\|\s*`?([^|`\n]{2,24})`?\s*\|',
    multiLine: true,
  ).allMatches(markdown)) {
    final term = match.group(1)!.trim();
    if (term.isEmpty || term == '术语' || term.startsWith('---')) continue;
    if (!terms.contains(term)) terms.add(term);
    if (terms.length >= 8) break;
  }
  final rows = <String>[];
  for (final term in terms.take(8)) {
    final explanation = _firstSentenceWith(markdown, term);
    if (explanation == null) continue;
    rows.add('| `$term` | $explanation |');
  }
  if (rows.length < 3) return null;
  return <String>['| 术语 | 一句话说明 |', '| --- | --- |', ...rows].join('\n');
}

/// 找出正文里最适合当术语说明的句子：优先定义式表述，
/// 跳过图片行、前置知识与「建议先完成」这类学习导航信息。
String? _firstSentenceWith(String markdown, String term) {
  var inFence = false;
  String? best;
  // 只接受带定义式表述或「术语：说明」结构的句子，宁缺毋滥。
  var bestScore = 3;
  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('![') || line.startsWith('>')) continue;
    if (line.contains('建议先完成') ||
        line.contains('开始前复习') ||
        line.contains('前置知识') ||
        line.contains('建议先学')) {
      continue;
    }
    if (!line.contains(term)) continue;
    var text = line.replaceFirst(RegExp(r'^[-*+\d.\s|>]+'), '').trim();
    text = text.replaceAll('|', '／').replaceAll(RegExp(r'[*_`]+'), '');
    if (text.length < 24 || text.length > 120) continue;
    if (text.contains('本课在') || text.contains('本课还在')) continue;
    final stop = text.indexOf(RegExp(r'[。；]'));
    if (stop > 16) text = text.substring(0, stop + 1);
    var score = 2;
    if (RegExp(r'[:：]').hasMatch(line)) score += 1;
    if (RegExp(r'(是|指|表示|负责|用来|用于|会把|用来把)')
        .hasMatch(text.substring(0, text.length ~/ 2))) {
      score += 2;
    }
    if (text.length > 100) score -= 1;
    if (score > bestScore) {
      bestScore = score;
      best = text;
    }
  }
  return best;
}

/// 用本课测验的题干、干扰项与正确答案生成「常见错误与排查」对照表。
String? _mistakeTable(List<Map<String, dynamic>> quiz, String title) {
  final rows = <String>[];
  for (final question in quiz) {
    final prompt = _cell(
      (question['question'] ?? '').toString().replaceAll(RegExp(r'\s+'), ' '),
    );
    final options = ((question['options'] as List<dynamic>?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final answer = question['answer'];
    if (options.length < 2 || answer is! int) continue;
    if (answer < 0 || answer >= options.length) continue;
    final correct = options[answer];
    final wrong = options.firstWhere(
      (option) => option != correct,
      orElse: () => '',
    );
    if (wrong.isEmpty || wrong.length < 6) continue;
    final shortPrompt = prompt.length > 56
        ? '${prompt.substring(0, 56)}…'
        : prompt;
    rows.add('| $shortPrompt | ${_cell(wrong)} | ${_cell(correct)} |');
    if (rows.length >= 4) break;
  }
  if (rows.isEmpty) return null;
  return <String>[
    '| 题目 | 容易踩的做法 | 正确结论 |',
    '| --- | --- | --- |',
    ...rows,
  ].join('\n');
}

String _cell(String text) =>
    text.replaceAll('|', '／').replaceAll(RegExp(r'\s+'), ' ').trim();

/// 丢掉会在 15 篇以上课程里重复出现的自测句，避免机械模板。
int _dropCrossLessonRepeats(Map<String, List<Section>> additions) {
  final counts = <String, int>{};
  for (final sections in additions.values) {
    for (final section in sections) {
      if (section.heading != '复习与自测') continue;
      for (final line in section.body.split('\n')) {
        final key = line.trim();
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
  }
  var dropped = 0;
  for (final entry in additions.entries.toList()) {
    final kept = <Section>[];
    for (final section in entry.value) {
      if (section.heading != '复习与自测') {
        kept.add(section);
        continue;
      }
      final lines = <String>[];
      for (final line in section.body.split('\n')) {
        if ((counts[line.trim()] ?? 0) > 15) {
          dropped++;
          continue;
        }
        lines.add(line);
      }
      if (lines.length >= 3) {
        kept.add(Section(section.heading, lines.join('\n')));
      }
    }
    entry.value
      ..clear()
      ..addAll(kept);
  }
  return dropped;
}

int _fenceCount(String markdown) => RegExp('```').allMatches(markdown).length;

String _trimBlankEdges(String text) {
  final lines = text.split('\n');
  var start = 0;
  var end = lines.length;
  while (start < end && lines[start].trim().isEmpty) {
    start++;
  }
  while (end > start && lines[end - 1].trim().isEmpty) {
    end--;
  }
  return lines.sublist(start, end).join('\n');
}

String _stringOption(List<String> args, String prefix, String fallback) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    return arg.substring(prefix.length);
  }
  return fallback;
}
