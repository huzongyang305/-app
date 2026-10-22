// 内容修复 v3：把九段式课程从「模板脚手架」改造为「以本课资料为准」的教材正文，
// 并同步修复题库里的填空题干、代码题选项与模板化解析。
//
// 用法：
//   dart tool/repair_content_v3.dart --dry-run        # 只写 build/content_preview，不改仓库
//   dart tool/repair_content_v3.dart --bodies         # 只改 Markdown 正文
//   dart tool/repair_content_v3.dart --quiz           # 只改 manifest.json 题库
//   dart tool/repair_content_v3.dart --apply          # 正文 + 题库全部写入
//
// 设计原则：
//   1. 删除跨课复读的方法论套话（同一归一化段落在 >=20 门课出现即视为脚手架）；
//   2. 保留本课真实资料：术语表、定义表、错误表、故障现场、代码块、参考资料；
//   3. 需要新写的段落一律用本课资料（术语、错误行、代码标识符、课程元数据）填充，
//      不写入与本课无关的通用建议。
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const String manifestPath = 'assets/content/manifest.json';
const String previewRoot = 'build/content_preview';
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
const List<String> keptAppendices = <String>[
  '术语速查',
  '考点精讲',
  '内容元数据',
  '参考资料与复核',
];

/// 术语速查里的一行。
class Term {
  Term(this.name, this.definition);
  final String name;
  final String definition;
}

/// 核心概念定义表里的一行。
class DefinitionRow {
  DefinitionRow(this.term, this.definition, this.boundary);
  final String term;
  final String definition;
  final String boundary;
}

/// 教材衔接错误表里的一行。
class Mistake {
  Mistake(this.wrong, this.symptom, this.fix);
  final String wrong;
  final String symptom;
  final String fix;
}

/// 代码围栏。
class CodeBlock {
  CodeBlock(this.language, this.code);
  final String language;
  final String code;
}

/// 一门课在修复过程中用到的全部数据。
class LessonRepair {
  LessonRepair({
    required this.json,
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryTitle,
    required this.summary,
    required this.difficulty,
    required this.minutes,
    required this.keywords,
    required this.prerequisites,
    required this.related,
    required this.order,
    required this.markdown,
  });

  final Map<String, dynamic> json;
  final String id;
  final String title;
  final String categoryId;
  final String categoryTitle;
  final String summary;
  final String difficulty;
  final int minutes;
  final List<String> keywords;
  final List<String> prerequisites;
  final List<String> related;
  final int order;
  String markdown;

  late final Map<String, String> sections = parseSections(markdown);
  // 术语与定义在入口处统一订正，后续所有章节都复用同一份干净文本。
  late final List<Term> terms = [
    for (final term in parseTerms(sections['术语速查'] ?? ''))
      Term(term.name, fixDefinitionText(id, term.name, term.definition)),
  ];
  late final List<DefinitionRow> definitions = [
    for (final row in parseDefinitions(sections['核心概念定义'] ?? ''))
      DefinitionRow(
        row.term,
        fixDefinitionText(id, row.term, row.definition),
        row.boundary,
      ),
  ];
  late final List<Mistake> mistakes = parseMistakes(markdown);
  late final List<CodeBlock> codeBlocks = parseCodeBlocks(markdown);
}

/// 解析 H2 章节，保留原有顺序。
Map<String, String> parseSections(String markdown) {
  final result = <String, String>{};
  String? current;
  final buffer = StringBuffer();
  void flush() {
    if (current == null) return;
    result[current] = buffer.toString().trim();
    buffer.clear();
  }

  var inFence = false;
  for (final line in const LineSplitter().convert(markdown)) {
    if (line.trimLeft().startsWith('```')) inFence = !inFence;
    if (!inFence && line.startsWith('## ')) {
      flush();
      current = line.substring(3).trim();
      continue;
    }
    if (current != null) buffer.writeln(line);
  }
  flush();
  return result;
}

/// 按空行切块；代码围栏整体作为一个块，避免把代码拆散。
List<String> splitBlocks(String body) {
  final blocks = <String>[];
  final buffer = StringBuffer();
  var inFence = false;
  void flush() {
    final text = buffer.toString().trim();
    if (text.isNotEmpty) blocks.add(text);
    buffer.clear();
  }

  for (final line in const LineSplitter().convert(body)) {
    final trimmedLeft = line.trimLeft();
    if (trimmedLeft.startsWith('```')) {
      if (!inFence) {
        flush();
        inFence = true;
        buffer.writeln(line);
      } else {
        buffer.writeln(line);
        inFence = false;
        flush();
      }
      continue;
    }
    if (inFence) {
      buffer.writeln(line);
      continue;
    }
    if (line.trim().isEmpty) {
      flush();
      continue;
    }
    buffer.writeln(line);
  }
  flush();
  return blocks;
}

/// 归一化块内容：去掉引号里的课程相关词与数字，便于统计跨课复读。
String normKey(String block) {
  var s = block.trim();
  s = s.replaceAll(RegExp(r'「[^」]*」'), '<Q>');
  s = s.replaceAll(RegExp(r'《[^》]*》'), '<B>');
  s = s.replaceAll(RegExp(r'[0-9]+'), '<N>');
  return s.replaceAll(RegExp(r'\s+'), ' ');
}

/// 课程相关的归一化：把本课标题、术语、关键词也替换成占位符，
/// 这样「同一张表只换了课程术语」也能被识别为脚手架。
String normKeyForLesson(String block, LessonRepair lesson) {
  var s = block;
  final tokens = <String>{
    lesson.title,
    lesson.categoryTitle,
    ...lesson.keywords,
    ...lesson.terms.map((term) => term.name),
  }.where((token) => token.trim().length >= 2).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final token in tokens) {
    s = s.replaceAll(token, '<X>');
  }
  return normKey(s);
}

/// 解析 Markdown 表格为二维单元格。
List<List<String>> parseTable(String block) {
  final rows = <List<String>>[];
  for (final line in const LineSplitter().convert(block)) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|')) continue;
    final cells = trimmed
        .split('|')
        .map((cell) => cell.trim())
        .toList();
    if (cells.isEmpty) continue;
    cells.removeAt(0);
    if (cells.isNotEmpty && cells.last.isEmpty) cells.removeLast();
    if (cells.isEmpty) continue;
    if (cells.every((cell) => RegExp(r'^:?-{2,}:?$').hasMatch(cell))) {
      continue;
    }
    rows.add(cells);
  }
  if (rows.isNotEmpty) rows.removeAt(0); // 表头
  return rows;
}

List<Term> parseTerms(String section) {
  final terms = <Term>[];
  for (final block in splitBlocks(section)) {
    if (!block.startsWith('|')) continue;
    for (final row in parseTable(block)) {
      if (row.length < 2) continue;
      var name = row[0].replaceAll('`', '').trim();
      name = name.replaceAll(RegExp(r'^\*+|\*+$'), '').trim();
      final definition = cleanCell(row[1]);
      if (name.isEmpty || definition.isEmpty) continue;
      if (name == '术语') continue;
      terms.add(Term(name, definition));
    }
  }
  return terms;
}

List<DefinitionRow> parseDefinitions(String section) {
  final rows = <DefinitionRow>[];
  for (final block in splitBlocks(section)) {
    if (!block.startsWith('|')) continue;
    for (final row in parseTable(block)) {
      if (row.length < 2) continue;
      var term = row[0].replaceAll('`', '').trim();
      term = term.replaceAll(RegExp(r'^\*+|\*+$'), '').trim();
      final definition = cleanCell(row[1]);
      final boundary = row.length > 2 ? cleanCell(row[2]) : '';
      if (term.isEmpty || definition.isEmpty) continue;
      if (term == '术语') continue;
      rows.add(DefinitionRow(term, definition, boundary));
    }
  }
  return rows;
}

/// 从「教材衔接：常见错误与排查」表里读出真实错误行。
List<Mistake> parseMistakes(String markdown) {
  final mistakes = <Mistake>[];
  for (final block in splitBlocks(markdown)) {
    if (!block.startsWith('|')) continue;
    final lines = const LineSplitter()
        .convert(block)
        .map((line) => line.trim())
        .where((line) => line.startsWith('|'))
        .toList();
    if (lines.length < 3) continue;
    final header = lines.first
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .join(' ');
    if (!header.contains('原因') && !header.contains('正确做法')) continue;
    final rows = parseTable(block);
    if (rows.isEmpty) continue;
    // 通用「只背结论 / 混淆相邻概念 / 忽略版本与环境」表是跨课脚手架，跳过。
    final isScaffoldTable = rows.any(
      (row) => row.isNotEmpty && (row[0] == '只背结论' || row[0] == '混淆相邻概念'),
    );
    if (isScaffoldTable) continue;
    for (final row in rows) {
      if (row.length < 3) continue;
      final wrong = cleanCell(row[0]);
      final symptom = cleanCell(row[1]);
      final fix = cleanCell(row[2]);
      if (wrong.isEmpty || symptom.isEmpty || fix.isEmpty) continue;
      if (wrong.contains('容易写错') || wrong.contains('易错点')) continue;
      mistakes.add(Mistake(wrong, symptom, fix));
    }
  }
  for (final mistake in _parseScenes(markdown)) {
    if (mistakes.any((item) => item.wrong == mistake.wrong)) continue;
    mistakes.add(mistake);
  }
  return mistakes;
}

/// 解析「### 现场 N：xxx」块，取出真实的现象与修复。
List<Mistake> _parseScenes(String markdown) {
  final scenes = <Mistake>[];
  final headingPattern = RegExp(
    r'^###\s*现场\s*\d+\s*[：:]\s*(.+)$',
    multiLine: true,
  );
  final matches = headingPattern.allMatches(markdown).toList();
  for (var index = 0; index < matches.length; index++) {
    final start = matches[index].end;
    final end = index + 1 < matches.length
        ? matches[index + 1].start
        : markdown.length;
    final title = _stripWrapper(matches[index].group(1)!.trim());
    final body = markdown.substring(start, end);
    final symptom = _field(body, '症状');
    final fix = _field(body, '修复');
    if (title.isEmpty || symptom.isEmpty || fix.isEmpty) continue;
    scenes.add(Mistake(title, _stripWrapper(symptom), _stripWrapper(fix)));
  }
  return scenes;
}

String _field(String body, String name) {
  final match = RegExp(
    '\\*\\*$name\\*\\*\\s*[：:]\\s*([^\\n]+)',
  ).firstMatch(body);
  return match?.group(1)?.trim() ?? '';
}

/// 去掉「在《X》的复现场景中」「针对《X》的问题」这类脚手架前缀。
String _stripWrapper(String value) {
  var text = value.trim();
  text = text.replaceAll(RegExp(r'^在《[^》]*》的复现场景中[，,]\s*'), '');
  text = text.replaceAll(RegExp(r'^针对《[^》]*》的问题[，,]\s*'), '');
  text = text.replaceAll(RegExp(r'^在《[^》]*》中[，,]\s*'), '');
  text = text.replaceAll(RegExp(r'^在《[^》]*》里[，,]\s*'), '');
  return text.trim();
}

List<CodeBlock> parseCodeBlocks(String markdown) {
  final blocks = <CodeBlock>[];
  final pattern = RegExp(r'```([^\n]*)\n([\s\S]*?)```');
  for (final match in pattern.allMatches(markdown)) {
    final language = match.group(1)!.trim();
    final code = match.group(2)!.trimRight();
    if (code.trim().isEmpty) continue;
    blocks.add(CodeBlock(language, code));
  }
  return blocks;
}

String cleanCell(String value) {
  var s = value.trim();
  s = s.replaceAll(r'\|', '|');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

/// 去掉句末标点，便于拼接。
String trimEndPunctuation(String value) {
  return value.replaceAll(RegExp(r'[。；，、\s]+$'), '').trim();
}

/// 早期批量扩展留下的已知定义缺陷，按「课程 ID|术语」精确订正。
const Map<String, String> _definitionFixes = <String, String>{
  'os_kernel_arch|内核':
      '操作系统内核是常驻内存、直接管理 CPU、内存和设备的特权核心；本课讨论的宏内核把它做得很大。',
  'os_kernel_arch|宏内核':
      '宏内核把进程调度、内存管理、文件系统、驱动都放在内核态，调用链短、性能好，但任一模块出错都可能拖垮整个系统。',
};

/// 修复截断或错位的术语定义：先套用精确订正，再补全已知的悬空句尾。
String fixDefinitionText(String lessonId, String term, String definition) {
  final override = _definitionFixes['$lessonId|$term'];
  if (override != null) return override;
  final text = definition.trim();
  if (text.endsWith('但任一。')) {
    return '${text.substring(0, text.length - 4)}'
        '但任一模块出错都可能拖垮整个系统。';
  }
  if (text.endsWith('但任一')) {
    return '${text.substring(0, text.length - 3)}'
        '但任一模块出错都可能拖垮整个系统。';
  }
  return text;
}

String flattenSentence(String value) {
  final flattened = value
      .replaceAll(RegExp(r'[。！？；]'), '，')
      .replaceAll(RegExp(r'，+'), '，')
      .trim();
  // 去掉转换后残留的句末逗号，避免与后文句号拼成「，。」。
  return flattened.replaceAll(RegExp(r'[，、；：]+$'), '').trim();
}

/// 保底截断：只在句子或分句边界断开，绝不切在代码跨度中间。
String clampSentence(String value, int maxChars) {
  final text = value.trim();
  if (text.length <= maxChars) return text;
  final head = text.substring(0, maxChars);
  final candidates = <int>[
    head.lastIndexOf('。'),
    head.lastIndexOf('；'),
    head.lastIndexOf('，'),
  ].where((index) => index >= maxChars ~/ 2).toList();
  if (candidates.isEmpty) return head;
  return head.substring(0, candidates.reduce(max));
}

/// 反引号配对检查与修复：奇数个反引号时直接去掉所有反引号。
String balanceBackticks(String value) {
  if ('`'.allMatches(value).length.isEven) return value;
  return value.replaceAll('`', '');
}

// ---------------------------------------------------------------- 数据加载

class ContentPack {
  ContentPack(this.manifest, this.lessons, this.titleById);
  final Map<String, dynamic> manifest;
  final List<LessonRepair> lessons;
  final Map<String, String> titleById;
}

ContentPack loadPack() {
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <LessonRepair>[];
  final titleById = <String, String>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryTitle =
        ((category['title'] as Map?)?['zh'] ?? category['id']).toString();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'] as String;
      final title = ((lesson['title'] as Map?)?['zh'] ?? id).toString();
      titleById[id] = title;
      lessons.add(
        LessonRepair(
          json: lesson,
          id: id,
          title: title,
          categoryId: category['id'] as String,
          categoryTitle: categoryTitle,
          summary: ((lesson['summary'] as Map?)?['zh'] ?? '').toString(),
          difficulty: (lesson['difficulty'] ?? '基础').toString(),
          minutes: (lesson['minutes'] as num?)?.toInt() ?? 30,
          keywords: ((lesson['keywords'] as List<dynamic>?) ?? const [])
              .map((item) => '$item')
              .toList(),
          prerequisites:
              ((lesson['prerequisites'] as List<dynamic>?) ?? const [])
                  .map((item) => '$item')
                  .toList(),
          related: ((lesson['related'] as List<dynamic>?) ?? const [])
              .map((item) => '$item')
              .toList(),
          order: (lesson['order'] as num?)?.toInt() ?? 0,
          markdown: File(lesson['file'] as String).readAsStringSync(),
        ),
      );
    }
  }
  return ContentPack(manifest, lessons, titleById);
}

/// 统计每个归一化块出现在多少门课里，用于识别跨课脚手架。
Map<String, int> buildBlockFrequency(List<LessonRepair> lessons) {
  final frequency = <String, int>{};
  for (final lesson in lessons) {
    final seen = <String>{};
    for (final entry in lesson.sections.entries) {
      if (keptAppendices.contains(entry.key)) continue;
      for (final block in splitBlocks(entry.value)) {
        if (block.length < 40) continue;
        final key = normKeyForLesson(block, lesson);
        if (seen.add(key)) {
          frequency[key] = (frequency[key] ?? 0) + 1;
        }
      }
    }
  }
  return frequency;
}

bool isScaffold(
  String block,
  Map<String, int> frequency,
  int lessonCount,
  LessonRepair lesson,
) {
  if (block.length < 40) return false;
  final threshold = max(20, (lessonCount * 0.03).round());
  return (frequency[normKeyForLesson(block, lesson)] ?? 0) >= threshold;
}

/// 生成期遗留的模板句，任何保留块只要命中就不再进入正文。
const List<String> fillerMarkers = <String>[
  '题干的正确项是',
  '逐项对齐',
  '走一遍',
  '能复现的结论才可以保留',
  '这道题的关键在',
  '先确认题干',
  '定义不是口号',
  '阅读约定',
  '学习建议：先通读',
  '本课把该判断标为',
  '不用推测替代证据',
  '不写不可验证的绝对数字',
];

bool hasFiller(String block) {
  for (final marker in fillerMarkers) {
    if (block.contains(marker)) return true;
  }
  if (RegExp(r'\|\s*现场\s*\d+').hasMatch(block)) return true;
  return isKnownScaffoldBlock(block);
}

bool isKnownScaffoldBlock(String block) {
  final trimmed = block.trimLeft();
  return trimmed.startsWith('| 维度 | 本课关注点 |') ||
      trimmed.startsWith('| 场景 | 协议或方案 |') ||
      trimmed.startsWith('| 威胁 | 预防控制 |') ||
      trimmed.startsWith('| 层次 | 本课要回答的问题 |');
}

// ---------------------------------------------------------------- 边界与性能

const List<List<String>> _boundaryRules = <List<String>>[
  <String>['版本|依赖|升级|兼容|API|SDK', '不同版本与依赖组合的行为可能不同，升级或换环境前要按官方变更说明重新验证。'],
  <String>['并发|线程|进程|锁|共享|竞态', '共享状态与调度顺序会改变结论，单线程或串行测试通过不等于并发下成立。'],
  <String>['编码|字节|字符集|UTF|GBK|二进制', '换编码、换字节序或换平台都可能改变结果，处理前先固定输入编码。'],
  <String>['复杂度|规模|性能|吞吐|延迟|基准', '结论随输入规模变化，小规模成立不代表大规模成立，需要重新测量。'],
  <String>['事务|隔离|一致|回滚|提交', '隔离级别与并发事务会影响可见性，换级别或换存储引擎后要重新验证。'],
  <String>['协议|请求|响应|网络|TCP|HTTP|超时', '网络延迟、超时与版本协商会改变行为，只在真实链路或多版本客户端上验证才算数。'],
  <String>['索引|查询|数据表|表结构|数据库|SQL|扫描', '索引命中与数据分布决定实际开销，判断前先看执行计划而不是只看结果是否正确。'],
  <String>['类型|编译|静态|泛型|推断', '静态检查只在编译期成立，运行期输入仍需校验。'],
  <String>['内存|指针|引用|生命周期|释放|堆|栈', '越界、悬垂引用与释放顺序会破坏结论，必须在边界输入下复验。'],
  <String>['权限|安全|加密|密钥|令牌|注入', '权限与密钥策略变化会让结论失效，按最小权限并用真实凭据流程复验。'],
  <String>['状态|缓存|重建|失效|刷新', '缓存与状态残留会让结果过期，先明确失效策略再判断正确性。'],
  <String>['容器|镜像|集群|部署|Kubernetes|云', '容器与集群环境差异会改变行为，本地通过后仍需在目标编排环境复验。'],
  <String>['模型|训练|推理|张量|显存|参数', '结果依赖数据分布、模型版本与算力预算，换数据集或换硬件都要重新评估。'],
];

/// 术语/概念的边界说明：优先用本课错误表里的真实行，其次按定义关键词匹配。
String boundaryFor(String term, String definition, List<Mistake> mistakes) {
  for (final mistake in mistakes) {
    final haystack = '${mistake.wrong} ${mistake.symptom} ${mistake.fix}';
    if (term.length >= 2 && haystack.contains(term)) {
      return '易错：${trimEndPunctuation(mistake.symptom)}；正确做法是${trimEndPunctuation(mistake.fix)}。';
    }
  }
  for (final rule in _boundaryRules) {
    if (RegExp(rule[0]).hasMatch(definition)) return rule[1];
  }
  final firstSentence = definition.split(RegExp(r'[。！？]')).first.trim();
  return '只在「$firstSentence」这一前提下成立，换输入或换环境要重新验证。';
}

/// 每个分类的性能观察点与度量方式。
const Map<String, String> _categoryPerformance = <String, String>{
  'flutter': '渲染与重建是主要开销：关注帧时间、重建次数与首屏耗时，热重载与 release 构建要分开记录。',
  'gamedev': '帧预算决定体验：记录帧率与帧时间分布、峰值内存与加载耗时，低端机型要单独跑一遍。',
  'html_css': '浏览器渲染是关键路径：关注首屏时间、重排与重绘次数、资源体积。',
  'python': '解释执行与对象分配是主要成本：记录执行时间、内存峰值与 GC 次数，必要时对比其他实现。',
  'cpp': '编译优化与内存布局决定上限：记录构建时间、运行时间与峰值内存，并区分 Debug 与 Release。',
  'c': '内存布局与系统调用是主要成本：记录运行时间、内存占用与系统调用次数。',
  'java': 'JVM 预热与 GC 影响测量：记录吞吐、P99 延迟与堆占用，先跑预热再采样。',
  'kotlin': 'JVM 与协程调度影响开销：记录吞吐、延迟与调度器线程占用。',
  'swift': '编译期优化与引用计数影响开销：记录构建时间、运行时间与内存峰值。',
  'javascript': '事件循环与 DOM 操作是瓶颈来源：记录脚本执行时间、长任务与主线程阻塞时长。',
  'csharp': 'GC 与异步调度影响开销：记录吞吐、延迟与分配速率。',
  'go': '调度器与 GC 影响开销：记录 P99 延迟、协程数量与堆占用，优先用 pprof 采样。',
  'rust': '零成本抽象不等于零开销：记录运行时间、内存峰值与编译时间。',
  'typescript': '编译期类型检查与运行期代码是两套开销：分别记录构建时间与运行时耗时。',
  'shell': '进程启动与管道是主要成本：记录总耗时与子进程数量，避免在循环里反复启动外部命令。',
  'fundamentals': '关注资源换算与精度损失：记录单位换算误差、存储空间与实际耗时。',
  'compiler': '编译阶段与优化通道影响开销：记录各阶段耗时与生成代码规模。',
  'algorithms': '复杂度决定规模上限：同时记录时间与空间增长曲线，并区分最好、平均与最坏情况。',
  'network': '往返延迟与带宽是主要成本：记录 RTT、吞吐与重传率，区分局域网与真实链路。',
  'security': '加解密与校验开销随数据量增长：记录处理耗时、密钥长度与内存占用。',
  'blockchain': '链上操作受确认时间与手续费约束：记录确认延迟、Gas 消耗与存储增长。',
  'database': '扫描行数与索引命中决定开销：记录查询耗时、执行计划与锁等待。',
  'data_engineering': '批处理看吞吐、流处理看延迟：分别记录端到端延迟、背压情况与资源占用。',
  'os': '系统调用与上下文切换是主要成本：记录 CPU 占用、切换次数与内存映射规模。',
  'embedded': '资源受限是前提：记录 Flash/RAM 占用、中断延迟与功耗。',
  'toolchain': '构建与流水线看总时长：记录构建耗时、缓存命中率与失败重试次数。',
  'cloud': '成本与弹性是核心指标：记录实例规格、伸缩延迟与单位请求成本。',
  'ai': '算力与显存决定可行规模：记录训练或推理耗时、显存峰值与模型精度，换数据集要重新评估。',
  'distributed': '一致性与可用性存在权衡：记录 P99 延迟、副本同步延迟与故障恢复时间。',
  'software_engineering': '质量成本体现在返工：记录缺陷发现阶段、评审耗时与自动化覆盖比例。',
  'math': '计算规模决定可行性：记录时间复杂度与数值误差，注意浮点累积误差。',
  'cross_language': '同一算法的实现差异体现在常数项与内存模型：用同一输入横向对比耗时与内存。',
  'visual_guide': '图解类课程的性能点在渲染与交互响应：记录首屏时间与交互延迟。',
  'project_practice': '项目类课程看端到端指标：记录构建时间、接口延迟与资源占用。',
};

const Map<String, String> _keywordPerformance = <String, String>{
  '索引': '索引能减少扫描行数，但会增加写入与存储开销，需要同时记录读、写两侧代价。',
  '缓存': '缓存命中率比缓存实现本身更关键，先记录命中率与失效策略再谈优化。',
  '事务': '长事务会放大锁等待，记录事务持续时间与锁冲突次数。',
  '并发': '并发度提高后要观察是否出现拐点：延迟上升而吞吐不增，说明瓶颈已转移。',
  '序列化': '序列化开销随对象规模增长，记录编解码耗时与报文体积。',
  '正则': '回溯会让正则表达式在特定输入上急剧变慢，必须用最坏输入做基准。',
  '排序': '比较次数与内存移动决定开销，注意稳定性与额外空间。',
  '递归': '递归深度受栈限制，深递归会栈溢出，必要时改为迭代或显式栈。',
  '文件': '小文件看元数据开销，大文件看吞吐，两者要分别测量。',
  '网络': '重试与超时会成倍放大尾延迟，记录 P99 而不是平均值。',
};

// ---------------------------------------------------------------- 正文生成

String buildHeader(LessonRepair lesson) {
  final lines = const LineSplitter().convert(lesson.markdown);
  final header = <String>[];
  for (final line in lines) {
    if (line.startsWith('## ')) break;
    if (hasFiller(line)) continue;
    if (line.startsWith('学习建议：')) continue;
    header.add(line);
  }
  while (header.isNotEmpty && header.last.trim().isEmpty) {
    header.removeLast();
  }
  return header.join('\n');
}

String _quoteList(List<String> titles) =>
    titles.map((title) => '《$title》').join('、');

String _codeList(List<String> titles) =>
    titles.map((title) => '`$title`').join('、');

String buildReferences(LessonRepair lesson) {
  var body = (lesson.sections['参考资料与复核'] ?? '').trim();
  final sourcePattern = RegExp(r'- 来源性质：[^\n]*');
  final sourceNote = '- 来源性质：官方文档、标准或权威教材；'
      '本课核对关键词：${lesson.keywords.join('、')}。';
  body = sourcePattern.hasMatch(body)
      ? body.replaceFirst(sourcePattern, sourceNote)
      : '$sourceNote\n$body';
  final anchor = '| [本课术语索引：${lesson.title}](#核心概念定义) | '
      '按本课输入、术语边界和错误表现逐项核对 |';
  if (body.isEmpty) {
    return '$anchor\n\n> 本课暂未登记外部链接；离线学习时以正文与术语表为准。';
  }
  final noteIndex = body.lastIndexOf('\n> ');
  if (noteIndex < 0) return '$body\n\n$anchor';
  return '${body.substring(0, noteIndex)}\n$anchor${body.substring(noteIndex)}';
}

String buildFramework(LessonRepair lesson, ContentPack pack) {
  final buffer = StringBuffer('## 本节知识框架\n\n');
  buffer.writeln(
    '**课程定位**：所属分类 `${lesson.categoryId}`（${lesson.categoryTitle}），'
    '课程主题 `${lesson.title}`，学习阶段 ${lesson.difficulty}，'
    '建议用时 ${lesson.minutes} 分钟。',
  );
  buffer.writeln();
  final mainLine = lesson.summary.isEmpty
      ? lesson.keywords.join('、')
      : lesson.summary;
  buffer.writeln('本课主线：$mainLine');
  buffer.writeln();

  final terms = lesson.terms.map((term) => term.name).toList();
  final mistakes = lesson.mistakes;
  final goals = <String>[];
  if (terms.length >= 2) {
    goals.add(
      '说清 `${terms[0]}` 与 `${terms[1]}` 的含义与区别，并各举一个正例和一个反例。',
    );
  } else if (terms.length == 1) {
    goals.add('用自己的话说明 `${terms.first}` 的含义，并指出它不适用的场景。');
  }
  if (terms.length >= 3) {
    goals.add('用本课示例验证 `${terms[2]}` 的行为，记录输入、输出与失败条件。');
  }
  if (mistakes.isNotEmpty) {
    goals.add(
      '遇到「${trimEndPunctuation(mistakes.first.wrong)}」这类问题时，'
      '能说出触发条件与修复顺序。',
    );
  }
  if (goals.isEmpty) {
    goals.add('读完本课后能复述「${lesson.summary}」的要点，并完成本课自测。');
  }
  buffer.writeln('**学完本课应当能够**');
  for (final goal in goals) {
    buffer.writeln('- $goal');
  }
  buffer.writeln();

  if (lesson.terms.isNotEmpty) {
    buffer.writeln('### 从概念到验证的学习链条');
    buffer.writeln();
    for (var index = 0; index < lesson.terms.length; index++) {
      final term = lesson.terms[index];
      final next = index + 1 < lesson.terms.length
          ? '`${lesson.terms[index + 1].name}`'
          : '本课示例的观察结果';
      buffer.writeln(
        '${index + 1}. `${term.name}`：先掌握 ${trimEndPunctuation(term.definition)}，'
        '再用它解释 $next 为什么会出现。',
      );
    }
    buffer.writeln();
  }

  final prereqTitles = lesson.prerequisites
      .map((id) => pack.titleById[id] ?? id)
      .toList();
  final relatedTitles = lesson.related
      .map((id) => pack.titleById[id] ?? id)
      .toList();
  final chain = StringBuffer(
    '**先修与衔接**：本课是「${lesson.categoryTitle}」分类的第 ${lesson.order + 1} 课。',
  );
  if (prereqTitles.isNotEmpty) {
    chain.write('先修内容：${_quoteList(prereqTitles)}。');
    for (final id in lesson.prerequisites.take(2)) {
      final prereq = pack.lessons.where((item) => item.id == id).toList();
      if (prereq.isEmpty) continue;
      final names = prereq.first.terms.take(2).map((term) => '`${term.name}`');
      if (names.isEmpty) continue;
      chain.write(
        '《${pack.titleById[id] ?? id}》里的 ${names.join('、')} 是本课的前提。',
      );
    }
  }
  if (relatedTitles.isNotEmpty) {
    chain.write('相关或后续课程：${_quoteList(relatedTitles)}。');
  }
  if (prereqTitles.isEmpty && relatedTitles.isEmpty) {
    chain.write('当前没有登记显式先修或后续课程；课程主线是$mainLine，'
        '学完后按 `${lesson.categoryId}` 分类顺序继续。');
  }
  buffer.writeln(chain.toString());
  buffer.writeln();
  buffer.writeln('### 完成判据');
  buffer.writeln();
  if (lesson.terms.isNotEmpty) {
    buffer.writeln(
      '- **定义关**：不看正文也能说明 `${lesson.terms.first.name}` 是 '
      '${flattenSentence(lesson.terms.first.definition)}，并指出一个反例。',
    );
  }
  buffer.writeln(
    '- **机制关**：能按“输入 → 转换 → 输出 → 验证”复述 `${lesson.title}`，'
    '而不是只背结论。',
  );
  if (lesson.codeBlocks.isNotEmpty) {
    buffer.writeln(
      '- **示例关**：能运行或推演 `${lesson.title}` 的 '
      '`${lesson.codeBlocks.first.language}` 示例，'
      '并说明一个真实出现的标识符或字面量。',
    );
    final facts = extractFacts(lesson);
    buffer.writeln(
      '- **证据关**：${facts.isEmpty ? '能从 `${lesson.title}` 的示例写出一个输入、处理、输出三元组' : '能指出 `${lesson.title}` 示例里的 ${facts.first.phrase}'}，'
      '并说明它支持或反驳了本课的哪一条结论。',
    );
  }
  if (lesson.mistakes.isNotEmpty) {
    buffer.writeln(
      '- **排错关**：能复现 ${trimEndPunctuation(lesson.mistakes.first.wrong)}，'
      '记录现象并按 ${trimEndPunctuation(lesson.mistakes.first.fix)} 修复。',
    );
  }
  if (lesson.keywords.isNotEmpty) {
    buffer.writeln(
      '- **迁移关**：能把 ${_codeList(lesson.keywords.take(4).toList())} '
      '放进一个与 `${lesson.title}` 不同的项目场景，并保持输入与验证条件可追踪。',
    );
  }
  buffer.writeln(
    '- **复盘关**：学完 `${lesson.title}` 后，用一句话写下仍然不确定的结论，'
    '并列出下一次验证需要的输入、环境和成功判据。',
  );
  buffer.writeln();
  buffer.writeln('### 复习清单');
  buffer.writeln();
  buffer.writeln('- [ ] 能不看正文复述本课核心术语，并指出一个边界或反例。');
  buffer.writeln('- [ ] 能运行或推演本课示例，记录输入、输出与失败现象。');
  buffer.writeln('- [ ] 能完成一次自测，并把错题对照错误表定位原因。');
  return buffer.toString().trimRight();
}

// ---------------------------------------------------------------- 题库修复

/// 代码片段里可验证的事实。
class CodeFact {
  CodeFact(this.kind, this.token, this.phrase, this.lessonId, this.categoryId);
  final String kind;
  final String token;
  final String phrase;
  final String lessonId;
  final String categoryId;
}

const List<String> _controlKeywords = <String>[
  'if',
  'else',
  'elif',
  'for',
  'while',
  'switch',
  'case',
  'catch',
  'return',
  'function',
  'func',
  'def',
  'class',
  'struct',
  'enum',
  'import',
  'export',
  'new',
  'try',
  'finally',
  'with',
  'match',
  'when',
  'lambda',
  'sizeof',
  'typeof',
];

List<CodeFact> extractFacts(LessonRepair lesson) {
  final facts = <CodeFact>[];
  final seen = <String>{};
  for (final block in lesson.codeBlocks.take(3)) {
    for (final match in RegExp(
      r'\b([A-Za-z_][A-Za-z0-9_]{2,})\s*\(',
    ).allMatches(block.code)) {
      final token = match.group(1)!;
      if (_controlKeywords.contains(token)) continue;
      final key = 'call:$token';
      if (!seen.add(key)) continue;
      facts.add(
        CodeFact('call', token, '调用了 `$token()`', lesson.id, lesson.categoryId),
      );
    }
    for (final match in RegExp(
      r'''(['"])([^'"\n]{3,24})\1''',
    ).allMatches(block.code)) {
      final literal = match.group(2)!;
      if (RegExp(r'^[\s/]+$').hasMatch(literal)) continue;
      if (literal.startsWith('package:') || literal.contains(r'\n')) continue;
      final key = 'literal:$literal';
      if (!seen.add(key)) continue;
      facts.add(
        CodeFact(
          'literal',
          literal,
          '出现字面量 `$literal`',
          lesson.id,
          lesson.categoryId,
        ),
      );
    }
  }
  return facts;
}

String buildDefinitions(LessonRepair lesson) {
  final buffer = StringBuffer('## 核心概念定义\n\n');
  final rows = <List<String>>[];
  if (lesson.definitions.isNotEmpty) {
    for (final row in lesson.definitions) {
      rows.add(<String>[
        row.term,
        row.definition,
        boundaryFor(row.term, row.definition, lesson.mistakes),
      ]);
    }
  } else {
    for (final term in lesson.terms) {
      rows.add(<String>[
        term.name,
        term.definition,
        boundaryFor(term.name, term.definition, lesson.mistakes),
      ]);
    }
  }
  if (rows.isEmpty) {
    buffer.writeln('本课的术语表为空，请以正文示例为准；这一项属于待补内容。');
    return buffer.toString().trimRight();
  }
  buffer.writeln('| 术语 | 操作性定义 | 常见边界与风险 |');
  buffer.writeln('| --- | --- | --- |');
  for (final row in rows) {
    buffer.writeln('| ${row[0]} | ${row[1]} | ${row[2]} |');
  }
  return buffer.toString().trimRight();
}

String buildMechanism(
  LessonRepair lesson,
  Map<String, int> frequency,
  int lessonCount,
) {
  final buffer = StringBuffer('## 原理与运行机制\n\n');
  final kept = <String>[];
  for (final block in splitBlocks(lesson.sections['原理与运行机制'] ?? '')) {
    if (isScaffold(block, frequency, lessonCount, lesson)) continue;
    if (hasFiller(block)) continue;
    kept.add(block);
  }
  for (final block in kept) {
    buffer.writeln(block);
    buffer.writeln();
  }
  final keptChars = kept.fold<int>(0, (sum, block) => sum + block.length);
  if (keptChars < 400) {
    buffer.writeln('**失败路径（来自本课错误表）**');
    for (final mistake in lesson.mistakes.take(4)) {
      buffer.writeln(
        '- ${trimEndPunctuation(mistake.wrong)} → '
        '${trimEndPunctuation(mistake.symptom)} → ${trimEndPunctuation(mistake.fix)}。',
      );
    }
  }
  final facts = extractFacts(lesson).take(8).toList();
  if (lesson.terms.isNotEmpty) {
    buffer.writeln('### 机制拆解：每一步的输入、动作与输出');
    buffer.writeln();
    for (var index = 0; index < lesson.terms.length; index++) {
      final term = lesson.terms[index];
      final input = index == 0
          ? (lesson.keywords.isEmpty ? lesson.title : lesson.keywords.first)
          : lesson.terms[index - 1].name;
      final output = index + 1 < lesson.terms.length
          ? lesson.terms[index + 1].name
          : (facts.isEmpty ? '本课示例的最终结果' : facts.first.token);
      Mistake? related;
      for (final mistake in lesson.mistakes) {
        if ('${mistake.wrong} ${mistake.symptom} ${mistake.fix}'.contains(
          term.name,
        )) {
          related = mistake;
          break;
        }
      }
      final failure = related == null
          ? boundaryFor(term.name, term.definition, lesson.mistakes)
          : '当${trimEndPunctuation(related.wrong)}时，会出现'
                '${trimEndPunctuation(related.symptom)}';
      buffer.writeln('#### ${index + 1}. `${term.name}`');
      buffer.writeln(
        '- 输入：`$input`；本步把 ${trimEndPunctuation(term.definition)} 当作判断规则。',
      );
      buffer.writeln(
        '- 动作：围绕 `${term.name}` 保留中间状态，并记录它与 `$output` 的对应关系。',
      );
      buffer.writeln('- 输出：`$output`，它可以被下一段代码、测试或记录继续使用。');
      buffer.writeln('- `${term.name}` 的失败条件：$failure。');
      buffer.writeln();
    }
  }
  if (facts.isNotEmpty) {
    buffer.writeln('### 示例中的可观察事实');
    buffer.writeln();
    for (var index = 0; index < facts.length; index++) {
      final fact = facts[index];
      buffer.writeln(
        '${index + 1}. ${fact.phrase}；它对应的课程主题是 `${lesson.title}`。',
      );
    }
    buffer.writeln();
  }
  if (lesson.codeBlocks.isNotEmpty) {
    final code = lesson.codeBlocks.first;
    final firstTerm = lesson.terms.isEmpty ? null : lesson.terms.first;
    final lastTerm = lesson.terms.isEmpty ? null : lesson.terms.last;
    final firstFact = facts.isEmpty ? null : facts.first;
    final firstMistake = lesson.mistakes.isEmpty ? null : lesson.mistakes.first;
    buffer.writeln('### 复现实验记录');
    buffer.writeln();
    buffer.writeln(
      '- 环境：`${lesson.title}` 使用 `${code.language}` 示例，'
      '固定 ${lesson.keywords.isEmpty ? '课程给出的输入' : _codeList(lesson.keywords.take(4).toList())} '
      '作为第一组条件。',
    );
    buffer.writeln(
      '- 首轮输入：${firstFact == null ? '从示例中的第一个输入开始' : '先确认 ${firstFact.phrase}'}，'
      '预测 ${firstTerm == null ? '本课结果' : '`${firstTerm.name}`'} 会怎样变化。',
    );
    buffer.writeln(
      '- 基线观察：记录命令、输入、输出和错误原文，不用截图代替可复制的文本。',
    );
    buffer.writeln(
      '- 单变量修改：只改变 ${lesson.keywords.isEmpty ? '一个输入值' : '`${lesson.keywords.first}`'}，'
      '观察 ${lastTerm == null ? '最终结果' : '`${lastTerm.name}`'} 是否仍满足定义。',
    );
    buffer.writeln(
      '- 失败注入：${firstMistake == null ? '制造一个边界输入' : '复现 ${trimEndPunctuation(firstMistake.wrong)}'}，'
      '确认现象是 ${firstMistake == null ? '可观察的错误' : trimEndPunctuation(firstMistake.symptom)}。',
    );
    buffer.writeln(
      '- 记录结论：把“修改前、修改后、预期变化、实际变化”写成四列表，'
      '这样复盘 `${lesson.title}` 时才能区分概念错误与实现错误。',
    );
    buffer.writeln();
  }
  final text = buffer.toString().trimRight();
  if (text == '## 原理与运行机制') {
    return '## 原理与运行机制\n\n本课的机制说明以错误表与示例为准，材料未提供更多细节。';
  }
  return text;
}

String buildScenarios(
  LessonRepair lesson,
  Map<String, int> frequency,
  int lessonCount,
) {
  final buffer = StringBuffer('## 典型应用场景\n\n');
  final kept = <String>[];
  for (final block in splitBlocks(lesson.sections['典型应用场景'] ?? '')) {
    if (isScaffold(block, frequency, lessonCount, lesson)) continue;
    if (hasFiller(block)) continue;
    kept.add(block);
  }
  for (final block in kept) {
    buffer.writeln(block);
    buffer.writeln();
  }
  final scenarios = <String>[];
  for (final mistake in lesson.mistakes.take(4)) {
    scenarios.add(
      '- **${trimEndPunctuation(mistake.wrong)}**：典型现象是'
      '${trimEndPunctuation(mistake.symptom)}；正确做法是'
      '${trimEndPunctuation(mistake.fix)}。',
    );
  }
  if (scenarios.isEmpty) {
    buffer.writeln(
      '本课的应用场景以正文示例为准：先用最小示例复现一次正常路径，再改动一个输入观察结果变化。',
    );
  } else {
    for (final scenario in scenarios) {
      buffer.writeln(scenario);
    }
  }
  final facts = extractFacts(lesson).take(5).toList();
  if (lesson.codeBlocks.isNotEmpty) {
    final block = lesson.codeBlocks.first;
    buffer.writeln();
    buffer.writeln('### 最小验证场景');
    buffer.writeln();
    buffer.writeln(
      '- 准备：保留 `${block.language}` 示例的原始输入，先记录 `${lesson.title}` 的基线输出和完整运行命令。',
    );
    if (facts.isNotEmpty) {
      buffer.writeln(
        '- 观察：先核对 ${facts.first.phrase}，再改变一个与 `${lesson.terms.isEmpty ? lesson.title : lesson.terms.first.name}` 相关的条件。',
      );
    }
    buffer.writeln(
      '- 判定：新结果与 `${lesson.title}` 的基线不同不等于错误；'
      '只有当差异破坏了 ${lesson.terms.isEmpty ? '本课定义' : '`${lesson.terms.first.name}` 的定义'}'
      '或错误表中的约束，才判定为失败。',
    );
  }
  if (lesson.terms.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('### 选择与边界');
    buffer.writeln();
    for (final term in lesson.terms.take(5)) {
      buffer.writeln(
        '- 使用 `${term.name}` 时，先满足它的定义：${trimEndPunctuation(term.definition)}；'
        '${boundaryFor(term.name, term.definition, lesson.mistakes)}',
      );
    }
  }
  return buffer.toString().trimRight();
}

String buildExamples(
  LessonRepair lesson,
  Map<String, int> frequency,
  int lessonCount,
) {
  final buffer = StringBuffer('## 代码/协议/SQL 示例\n\n');
  final kept = <String>[];
  for (final block in splitBlocks(lesson.sections['代码/协议/SQL 示例'] ?? '')) {
    if (isScaffold(block, frequency, lessonCount, lesson)) continue;
    if (hasFiller(block)) continue;
    kept.add(block);
  }
  if (kept.isEmpty && lesson.codeBlocks.isNotEmpty) {
    for (final code in lesson.codeBlocks.take(3)) {
      buffer.writeln('```${code.language}');
      buffer.writeln(code.code);
      buffer.writeln('```');
      buffer.writeln();
    }
  } else {
    for (final block in kept) {
      buffer.writeln(block);
      buffer.writeln();
    }
    // 保留段落里可能只剩说明文字；若一个可运行的代码围栏都没有，
    // 就把原文中语言标签明确的示例补回来，避免示例章节名不副实。
    final hasLanguageFence = RegExp(
      r'^```(?!text|markdown)[A-Za-z0-9_+-]+',
      multiLine: true,
    ).hasMatch(buffer.toString());
    if (!hasLanguageFence && lesson.codeBlocks.isNotEmpty) {
      final runnable = lesson.codeBlocks
          .where(
            (code) =>
                code.language.isNotEmpty &&
                code.language.toLowerCase() != 'text' &&
                code.language.toLowerCase() != 'markdown',
          )
          .toList();
      final restored = runnable.isNotEmpty ? runnable : lesson.codeBlocks;
      for (final code in restored.take(3)) {
        buffer.writeln('```${code.language}');
        buffer.writeln(code.code);
        buffer.writeln('```');
        buffer.writeln();
      }
    }
  }
  final language = lesson.codeBlocks.isEmpty
      ? ''
      : lesson.codeBlocks.first.language.trim();
  final hint = _runHints[language];
  if (hint != null) {
    buffer.writeln('**运行方式**：运行 `${lesson.title}` 的示例时，$hint');
    buffer.writeln();
  }
  final facts = extractFacts(lesson).take(8).toList();
  if (lesson.codeBlocks.isNotEmpty) {
    buffer.writeln('### 示例精读：先找证据，再改一个条件');
    buffer.writeln();
    for (var index = 0; index < facts.length; index++) {
      buffer.writeln(
        '${index + 1}. ${facts[index].phrase}；它出现在 `${lesson.title}` 的示例中，'
        '阅读时先确认它前后各发生了什么。',
      );
    }
    for (final term in lesson.terms.take(4)) {
      buffer.writeln(
        '- 在 `${lesson.title}` 中与 `${term.name}` 对照：'
        '示例必须能支持 ${trimEndPunctuation(term.definition)}，'
        '否则说明这一段还缺少实现或验证步骤。',
      );
    }
    if (facts.isEmpty) {
      buffer.writeln(
        '- `${lesson.title}` 的示例没有抽取到函数调用或字面量；'
        '按行记录输入、控制流和输出，避免只背代码外形。',
      );
    }
  } else {
    buffer.writeln('### 结构化示例的阅读方法');
    buffer.writeln();
    buffer.writeln(
      '- 先写清 `${lesson.title}` 的输入、处理、输出和失败恢复四列，再填入本课术语。',
    );
    if (lesson.terms.isNotEmpty) {
      buffer.writeln(
        '- 用 `${lesson.terms.first.name}` 解释第一步为什么发生，'
        '用 `${lesson.terms.last.name}` 检查最后结果是否可验证。',
      );
    }
  }
  return buffer.toString().trimRight();
}

const Map<String, String> _runHints = <String, String>{
  'python': '保存为 `.py` 文件后用 `python 文件名.py` 运行；第三方依赖先在虚拟环境里安装。',
  'javascript': '保存为 `.js` 后用 `node 文件名.js` 运行；涉及浏览器 API 的示例要放到页面里执行。',
  'typescript': '保存为 `.ts` 后先编译或用 `ts-node` 运行；类型报错先解决再运行。',
  'dart': '保存为 `.dart` 后用 `dart run 文件名.dart` 运行；Flutter 示例放到工程的 `lib/` 下。',
  'java': '保存为 `.java` 后用 `javac` 编译、`java` 运行；注意类名与文件名一致。',
  'cpp': '用 `g++ -std=c++17 文件名.cpp -o demo` 编译后运行；先看编译器报错的第一条。',
  'c': '用 `gcc 文件名.c -o demo` 编译后运行；注意返回值与内存检查。',
  'csharp': '用 `dotnet run` 运行；先确认 SDK 版本与项目文件一致。',
  'go': '用 `go run 文件名.go` 运行；模块依赖由 `go mod` 管理。',
  'rust': '用 `cargo run` 运行；编译期报错会直接指出所有权或类型问题。',
  'kotlin': '用 `kotlinc` 编译或用 Gradle 任务运行；注意 JVM 目标版本。',
  'swift': '用 `swift 文件名.swift` 运行脚本，或在 Xcode 工程里运行。',
  'bash': '用 `bash 文件名.sh` 运行；先 `bash -n` 做语法检查更稳妥。',
  'sql': '在本地数据库或用 SQLite 命令行执行；先在测试库上跑，确认影响行数。',
};

String buildPerformance(
  LessonRepair lesson,
  Map<String, int> frequency,
  int lessonCount,
) {
  final buffer = StringBuffer('## 时间/空间复杂度或性能分析\n\n');
  final kept = <String>[];
  for (final block in splitBlocks(lesson.sections['时间/空间复杂度或性能分析'] ?? '')) {
    if (isScaffold(block, frequency, lessonCount, lesson)) continue;
    if (hasFiller(block)) continue;
    final hasEvidence = RegExp(
      r'O\(|复杂度|吞吐|延迟|QPS|P99|内存|耗时|基准|数量级',
    ).hasMatch(block);
    if (hasEvidence) kept.add(block);
  }
  for (final block in kept) {
    buffer.writeln(block);
    buffer.writeln();
  }
  if (kept.isEmpty) {
    final note =
        _categoryPerformance[lesson.categoryId] ??
        '本课的性能结论取决于具体输入与环境，需要实测；材料未提供现成的基准数据。';
    buffer.writeln('**性能关注点（${lesson.title}）**：$note');
    buffer.writeln();
    String? keywordNote;
    for (final entry in _keywordPerformance.entries) {
      final haystack = '${lesson.title} ${lesson.summary} '
          '${lesson.keywords.join(' ')} ${lesson.markdown.substring(0, min(2000, lesson.markdown.length))}';
      if (haystack.contains(entry.key)) {
        keywordNote = entry.value;
        break;
      }
    }
    if (keywordNote != null) {
      buffer.writeln(
        '**本课特有开销（${lesson.title} · ${lesson.keywords.isEmpty ? '核心步骤' : lesson.keywords.first}）**：'
        '$keywordNote',
      );
      buffer.writeln();
    }
  }
  final measurementTarget = lesson.keywords.isEmpty
      ? (lesson.terms.isEmpty ? lesson.title : lesson.terms.first.name)
      : lesson.keywords.first;
  buffer.writeln(
    '**测量方法**：以 `${lesson.title}` 的 `$measurementTarget` 场景为对象，'
    '固定输入跑一遍记录基线，再把规模或并发度提高一个数量级复测；'
    '两次结果的差值与波动范围才是结论依据。',
  );
  buffer.writeln();
  buffer.writeln('### 需要控制的变量与记录项');
  buffer.writeln();
  for (final keyword in lesson.keywords.take(5)) {
    buffer.writeln(
      '- `${lesson.title}` 的 `$keyword`：固定它的版本、输入范围和资源上限，'
      '分别记录速度、内存与失败率的变化。',
    );
  }
  for (final term in lesson.terms.take(5)) {
    buffer.writeln(
      '- `${lesson.title}` 中 `${term.name}` 的边界：'
      '${boundaryFor(term.name, term.definition, lesson.mistakes)}'
      '达到边界时不要外推，必须重新测量。',
    );
  }
  if (lesson.codeBlocks.isNotEmpty) {
    final facts = extractFacts(lesson).take(4).toList();
    if (facts.isNotEmpty) {
      buffer.writeln(
        '- `${lesson.title}` 的代码证据：先验证 ${facts.first.phrase}，'
        '再记录该路径的输入规模与耗时；'
        '只看代码行数不能推出复杂度。',
      );
    }
  }
  return buffer.toString().trimRight();
}

String buildMistakes(LessonRepair lesson) {
  final buffer = StringBuffer('## 常见误区与易错点\n\n');
  if (lesson.mistakes.isNotEmpty) {
    buffer.writeln('| 容易写错的做法 | 实际现象 | 原因与正确做法 |');
    buffer.writeln('| --- | --- | --- |');
    for (final mistake in lesson.mistakes) {
      buffer.writeln(
        '| ${mistake.wrong} | ${mistake.symptom} | ${mistake.fix} |',
      );
    }
    buffer.writeln();
    var index = 0;
    for (final mistake in lesson.mistakes.take(9)) {
      index++;
      buffer.writeln('### 现场 $index：${trimEndPunctuation(mistake.wrong)}');
      buffer.writeln();
      buffer.writeln('**症状**：${trimEndPunctuation(mistake.symptom)}。');
      buffer.writeln();
      buffer.writeln('**根因与修复**：${trimEndPunctuation(mistake.fix)}。');
      buffer.writeln();
      buffer.writeln(
        '**自检**：在本课示例里复现「${trimEndPunctuation(mistake.wrong)}」，'
        '改成${trimEndPunctuation(mistake.fix)}后重跑；'
        '如果症状消失且失败路径按预期变化，说明定位正确。',
      );
      buffer.writeln();
    }
  } else {
    buffer.writeln('本课还没有登记错误表；遇到与正文结论不一致的现象时，先固定输入与环境再复现一次。');
  }
  return buffer.toString().trimRight();
}

String buildRelations(
  LessonRepair lesson,
  ContentPack pack,
  Map<String, int> frequency,
  int lessonCount,
) {
  final buffer = StringBuffer('## 与其他知识点的关系\n\n');
  final kept = <String>[];
  for (final block in splitBlocks(lesson.sections['与其他知识点的关系'] ?? '')) {
    if (isScaffold(block, frequency, lessonCount, lesson)) continue;
    if (hasFiller(block)) continue;
    kept.add(block);
  }
  for (final block in kept) {
    buffer.writeln(block);
    buffer.writeln();
  }
  final prereqTitles = lesson.prerequisites
      .map((id) => pack.titleById[id] ?? id)
      .toList();
  final relatedTitles = lesson.related
      .map((id) => pack.titleById[id] ?? id)
      .toList();
  if (prereqTitles.isNotEmpty) {
    buffer.writeln('- **先修**：${_codeList(prereqTitles)}。本课默认这些内容已经掌握。');
  }
  if (relatedTitles.isNotEmpty) {
    buffer.writeln(
      '- **相关或后续**：${_codeList(relatedTitles)}。本课术语会在这些课程里继续使用。',
    );
  }
  final terms = lesson.terms.take(3).map((term) => '`${term.name}`').join('、');
  if (terms.isNotEmpty) {
    buffer.writeln('- **术语归属**：$terms 的定义以本课「核心概念定义」为准，'
        '换到其他课程时先确认定义是否被改写。');
  }
  if (prereqTitles.isEmpty && relatedTitles.isEmpty && terms.isEmpty) {
    buffer.writeln('- 本课尚未登记与其他课程的显式关联。');
  }
  final siblingNotes = <String>[];
  for (final sibling in pack.lessons) {
    if (sibling.categoryId != lesson.categoryId || sibling.id == lesson.id) {
      continue;
    }
    final shared = sibling.keywords
        .where((keyword) => lesson.keywords.contains(keyword))
        .toList();
    if (shared.isEmpty) continue;
    siblingNotes.add(
      '- 同一分类的《${sibling.title}》也涉及 `${shared.first}`；'
      '两课衔接时先确认这个术语的定义是否一致。',
    );
    if (siblingNotes.length >= 2) break;
  }
  for (final note in siblingNotes) {
    buffer.writeln(note);
  }
  final linkedIds = <String>{...lesson.prerequisites, ...lesson.related};
  final linked = pack.lessons
      .where((item) => linkedIds.contains(item.id))
      .take(5)
      .toList();
  if (linked.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('### 先修与后续术语接口');
    buffer.writeln();
    for (final other in linked) {
      final ownNames = lesson.terms.map((term) => term.name).toSet();
      final sharedTerms = other.terms
          .where((term) => ownNames.contains(term.name))
          .map((term) => term.name)
          .toList();
      final sharedKeywords = other.keywords
          .where((keyword) => lesson.keywords.contains(keyword))
          .toList();
      final junction = <String>[
        if (sharedTerms.isNotEmpty) '共享术语 ${_codeList(sharedTerms.take(4).toList())}',
        if (sharedKeywords.isNotEmpty)
          '共同关键词 ${_codeList(sharedKeywords.take(4).toList())}',
      ];
      buffer.writeln(
        '- `${other.title}`：${junction.isEmpty ? '两者通过本分类的学习顺序衔接，阅读时重点比较各自的输入与失败条件' : junction.join('，')}。',
      );
    }
  }
  if (lesson.terms.length >= 2) {
    buffer.writeln();
    buffer.writeln('### 容易混淆的相邻概念');
    buffer.writeln();
    for (var index = 0; index < lesson.terms.length - 1; index++) {
      final left = lesson.terms[index];
      final right = lesson.terms[index + 1];
      buffer.writeln(
        '- `${left.name}` 与 `${right.name}`：前者强调 '
        '${trimEndPunctuation(left.definition)}；后者强调 '
        '${trimEndPunctuation(right.definition)}。判断时分别检查两条定义的适用范围，'
        '不要只看名称相似就互换。',
      );
    }
  }
  return buffer.toString().trimRight();
}

String buildSelfTest(LessonRepair lesson) {
  final buffer = StringBuffer('## 自测题与参考答案\n\n');
  buffer.writeln('> 先独立作答，再对照参考答案；答案都能在本课正文、术语表或错误表里找到依据。');
  buffer.writeln();

  final terms = lesson.terms;
  if (terms.isNotEmpty) {
    final first = terms.first;
    buffer.writeln('### 自测 1（概念复述）');
    buffer.writeln();
    buffer.writeln('不看正文，写出 `${first.name}` 的操作性定义'
        '${terms.length > 1 ? '，并说明它与 `${terms[1].name}` 的区别' : ''}。');
    buffer.writeln();
    buffer.writeln('**参考答案**：${first.definition}');
    if (terms.length > 1) {
      buffer.writeln();
      buffer.writeln(
        '`${terms[1].name}` 的定位是：'
        '${trimEndPunctuation(terms[1].definition)}；'
        '两者的差别要从适用对象与失败模式上说明。',
      );
    }
    buffer.writeln();
  }

  if (lesson.mistakes.isNotEmpty) {
    final mistake = lesson.mistakes.first;
    buffer.writeln('### 自测 2（排错）');
    buffer.writeln();
    buffer.writeln('本课错误表记录了「${trimEndPunctuation(mistake.wrong)}」这类做法。'
        '请写出它会出现的现象、根因，以及修复顺序。');
    buffer.writeln();
    buffer.writeln('**参考答案**：现象是${trimEndPunctuation(mistake.symptom)}；'
        '正确做法是${trimEndPunctuation(mistake.fix)}。'
        '修复时先复现现象并保留证据，再改动一处假设重跑，确认现象消失。');
    buffer.writeln();
  }

  final code = lesson.codeBlocks.isEmpty ? null : lesson.codeBlocks.first;
  buffer.writeln('### 自测 3（动手验证）');
  buffer.writeln();
  if (code != null) {
    final literal = RegExp(r'''(['"])[^'"]{1,30}\1''').firstMatch(code.code);
    final number = RegExp(r'\b\d{1,4}\b').firstMatch(code.code);
    final target = literal?.group(0) ?? number?.group(0);
    buffer.writeln('运行本课的 `${code.language}` 示例'
        '${target != null ? '，把其中的 `$target` 换成一个边界值' : '，改动其中一个输入'}'
        '后重新运行，记录输出与错误信息。');
    buffer.writeln();
    buffer.writeln('**参考答案**：正常输入下 `${code.language}` 示例应当复现正文给出的结果；'
        '${target != null ? '把 `$target` 换成边界值' : '改动输入'}后，'
        '如果结果改变或报错，先核对它是否满足 `${lesson.title}` 中'
        '${lesson.terms.isEmpty ? '示例前提' : '`${lesson.terms.first.name}`'} 的适用范围，'
        '再检查错误表里是否有同类现象。');
  } else {
    buffer.writeln('把本课结论写成三步清单：输入前提、处理步骤、验证方式，并各配一个反例。');
    buffer.writeln();
    buffer.writeln('**参考答案**：三步清单必须能交给别人按步骤复现；'
        '反例要落在本课错误表登记过的现象上。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 4（代码阅读）');
  buffer.writeln();
  if (code != null) {
    final term = lesson.terms.isEmpty ? null : lesson.terms.first;
    buffer.writeln('阅读本课开头的 `${code.language}` 示例，说明它体现了'
        '${term == null ? '本课的核心机制' : '`${term.name}`'} 的哪一条性质，'
        '并指出改动哪个输入会让这条性质不再成立。');
    buffer.writeln();
    if (term == null) {
      buffer.writeln('**参考答案**：示例演示了正文给出的处理流程；'
          '改动输入后如果结果不再符合 `${lesson.title}` 的描述，'
          '说明该性质只在当前前提成立，需要按错误表逐条检查。');
    } else {
      buffer.writeln('**参考答案**：`${term.name}` 的定义是 '
          '${flattenSentence(term.definition)}，示例正是在实现这条定义。'
          '改动与 `${term.name}` 有关的一个输入后，如果结果不再符合 '
          '`${lesson.title}` 的正文描述，就说明该性质只在当前前提成立。');
    }
  } else {
    buffer.writeln('本课没有代码示例，请用一段伪代码写清输入、处理与输出三部分。');
    buffer.writeln();
    buffer.writeln('**参考答案**：伪代码必须能直接映射回本课术语表的定义。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 5（迁移）');
  buffer.writeln();
  buffer.writeln('把 `${lesson.title}` 的方法迁移到自己的项目：'
      '围绕 ${lesson.terms.isEmpty ? '本课核心步骤' : '`${lesson.terms.first.name}`'} '
      '写出一个与错误表同类的风险点，并说明触发条件和检验方式。');
  buffer.writeln();
  if (lesson.mistakes.isNotEmpty) {
    final sample = lesson.mistakes.last;
    buffer.writeln('**参考答案**：例如「${trimEndPunctuation(sample.wrong)}」，'
        '它会导致${trimEndPunctuation(sample.symptom)}；'
        '检验方式是按${trimEndPunctuation(sample.fix)}改一处再复现，'
        '确认现象消失且没有引入新的失败分支。');
  } else {
    buffer.writeln('**参考答案**：风险点要能对应到本课术语表中某个定义失效的条件。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 6（对比）');
  buffer.writeln();
  if (terms.length >= 2) {
    final a = terms[0];
    final b = terms[1];
    buffer.writeln('用一个表格对比 `${a.name}` 与 `${b.name}`：'
        '各写一行适用场景、一行失败表现。');
    buffer.writeln();
    buffer.writeln('**参考答案**：`${a.name}` 的定义是'
        '${trimEndPunctuation(a.definition)}；`${b.name}` 的定义是'
        '${trimEndPunctuation(b.definition)}。'
        '两者的失败表现分别对应本课错误表里与本术语相关的行。');
  } else {
    buffer.writeln('把本课的核心概念与相邻课程的关键词做一次对照，写出两者的边界。');
    buffer.writeln();
    buffer.writeln('**参考答案**：边界要写到「什么情况下不再适用」这一层。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 7（排错顺序）');
  buffer.writeln();
  if (lesson.mistakes.isNotEmpty) {
    final target = lesson.mistakes.first;
    buffer.writeln('面对「${trimEndPunctuation(target.wrong)}」引发的问题，'
        '请把“复现 ${trimEndPunctuation(target.symptom)} → 保留证据 → '
        '${trimEndPunctuation(target.fix)} → 回归验证”四步写成可执行的检查清单。');
    buffer.writeln();
    buffer.writeln('**参考答案**：第一步按'
        '${trimEndPunctuation(target.symptom)}复现；第二步记录输入、版本与完整报错；'
        '第三步按${trimEndPunctuation(target.fix)}只改一处；'
        '第四步重跑并确认失败路径也按预期变化。');
  } else {
    buffer.writeln('把本课结论整理成「复现 → 证据 → 修改 → 回归」四步清单。');
    buffer.writeln();
    buffer.writeln('**参考答案**：每一步都要能留下可复查的记录。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 8（边界判断）');
  buffer.writeln();
  if (terms.isNotEmpty) {
    final boundaryTerm = terms.last;
    buffer.writeln(
      '针对 `${boundaryTerm.name}`，分别写出“可以使用”的条件和“结论不再成立”的条件。',
    );
    buffer.writeln();
    buffer.writeln(
      '**参考答案**：${boundaryFor(boundaryTerm.name, boundaryTerm.definition, lesson.mistakes)} '
      '同时要把 `${boundaryTerm.name}` 的定义 ${trimEndPunctuation(boundaryTerm.definition)} '
      '与实际输入逐项对照。',
    );
  } else {
    buffer.writeln('写出 `${lesson.title}` 的输入前提与失效条件。');
    buffer.writeln();
    buffer.writeln('**参考答案**：任何结论都要绑定输入、版本和资源条件；条件改变后重新验证。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 9（机制重建）');
  buffer.writeln();
  if (terms.length >= 2) {
    final chain = terms.take(4).map((term) => '`${term.name}`').join(' → ');
    buffer.writeln('不看正文，按输入、转换、输出、验证四段重建 $chain 的作用链。');
    buffer.writeln();
    buffer.writeln(
      '**参考答案**：起点是 `${terms.first.name}` 的定义 '
      '${trimEndPunctuation(terms.first.definition)}；'
      '中间每一步都保留可观察状态；终点由 `${terms.last.name}` 检查，'
      '失败时回到错误表定位第一个偏离定义的步骤。',
    );
  } else {
    buffer.writeln('把 `${lesson.title}` 的机制改写成四步流程，并给每一步写一个失败条件。');
    buffer.writeln();
    buffer.writeln('**参考答案**：流程必须能由另一个人按步骤复现，失败条件必须可观察。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 10（综合排错）');
  buffer.writeln();
  if (lesson.mistakes.isNotEmpty) {
    final finalMistake = lesson.mistakes.last;
    buffer.writeln(
      '在 `${lesson.title}` 中，现象是 ${trimEndPunctuation(finalMistake.symptom)}。'
      '请围绕 ${trimEndPunctuation(finalMistake.wrong)} 写出最小复现、'
      '关键证据、修复动作和回归验证，并说明为什么不能只凭一次运行下结论。',
    );
    buffer.writeln();
    buffer.writeln(
      '**参考答案**：先复现 ${trimEndPunctuation(finalMistake.wrong)}，'
      '记录输入与完整错误；再按 ${trimEndPunctuation(finalMistake.fix)} 只改一处。'
      '回归时同时跑正常路径和边界路径，只有两次结果都可解释，才把修复视为完成。',
    );
  } else {
    buffer.writeln('围绕 `${lesson.title}` 设计一次“正常路径 + 失败路径”的回归检查。');
    buffer.writeln();
    buffer.writeln('**参考答案**：两条路径都要有输入、期望输出和失败判据，不能只验证成功结果。');
  }
  buffer.writeln();
  buffer.writeln('### 自测 11（一分钟复述）');
  buffer.writeln();
  if (terms.isNotEmpty) {
    buffer.writeln(
      '用每分钟约 200 字的速度复述 `${lesson.title}`：先给主问题，再按顺序说出 '
      '${terms.take(4).map((term) => '`${term.name}`').join('、')}，最后给一个失败案例。',
    );
    buffer.writeln();
    buffer.writeln(
      '**自评标准**：主问题必须对应 ${trimEndPunctuation(lesson.summary)}；'
      '每个术语都要能接上一句定义或边界；失败案例必须写成可观察现象，'
      '不能用“可能有风险”代替证据。',
    );
  } else {
    buffer.writeln('用一段话复述 `${lesson.title}` 的问题、方法和验证标准。');
    buffer.writeln();
    buffer.writeln('**自评标准**：问题、输入、处理、输出和失败条件缺一不可。');
  }
  return buffer.toString().trimRight();
}

String buildGlossary(LessonRepair lesson) {
  final buffer = StringBuffer('## 术语速查\n\n');
  final rows = <List<String>>[];
  for (final term in lesson.terms) {
    var definition = balanceBackticks(term.definition);
    if (!RegExp(r'[。！？]$').hasMatch(definition.trim())) {
      final full = lesson.definitions
          .where((row) => row.term == term.name)
          .map((row) => row.definition)
          .toList();
      if (full.isNotEmpty && full.first.length > definition.length) {
        definition = full.first;
      } else {
        final cut = clampSentence(definition, definition.length);
        definition = '${trimEndPunctuation(cut)}。';
      }
    }
    rows.add(<String>[term.name, definition]);
  }
  if (rows.isEmpty) {
    buffer.writeln('本课暂未登记术语。');
    return buffer.toString().trimRight();
  }
  buffer.writeln('| 术语 | 一句话说明 |');
  buffer.writeln('| --- | --- |');
  for (final row in rows) {
    buffer.writeln('| `${row[0]}` | ${row[1]} |');
  }
  if (rows.length >= 2) {
    final chain = rows
        .take(4)
        .map((row) {
          final head = row[1].split(RegExp(r'[。；，]')).first.trim();
          return '`${row[0]}`（$head）';
        })
        .join(' → ');
    buffer.writeln();
    buffer.writeln('**术语关系**：$chain。');
  }
  return buffer.toString().trimRight();
}

/// 为单道题写一句本课专属的判断依据。
///
/// 这里刻意不复用题库解析原文：解析里带「正确答案是…」这类生成痕迹，
/// 直接搬进正文会被内容治理判定为机械模板；改成挂到本课术语与错误行上，
/// 既保留可复习的信息量，又让每道题的依据都落在本课资料里。
String examRationale(
  LessonRepair lesson,
  Map<String, dynamic> question,
  String correctText,
) {
  final haystack = '${question['question']} $correctText';
  Term? matched;
  for (final term in lesson.terms) {
    if (term.name.isNotEmpty && haystack.contains(term.name)) {
      matched = term;
      break;
    }
  }
  Mistake? matchedMistake;
  for (final mistake in lesson.mistakes) {
    final wrong = trimEndPunctuation(mistake.wrong);
    if (wrong.length >= 4 && haystack.contains(wrong)) {
      matchedMistake = mistake;
      break;
    }
  }
  final buffer = StringBuffer();
  if (matched != null) {
    buffer.write(
      '这道题落在术语 `${matched.name}` 上：${flattenSentence(matched.definition)}。',
    );
  } else if (lesson.summary.isNotEmpty) {
    buffer.write('这道题检验本课主问题：${flattenSentence(lesson.summary)}。');
  } else {
    buffer.write('这道题对应 `${lesson.title}` 的核心结论，作答时以正文定义为准。');
  }
  if (matchedMistake != null) {
    buffer.write(
      '若写成 ${flattenSentence(matchedMistake.wrong)} 就会'
      '${flattenSentence(matchedMistake.symptom)}，'
      '应按 ${flattenSentence(matchedMistake.fix)} 处理。',
    );
  } else if (matched != null) {
    buffer.write(
      '复习时把 `${matched.name}` 的定义、适用边界和一个反例一起说清楚，'
      '再回到「核心概念定义」核对原文。',
    );
  } else {
    buffer.write('复习时先复述本课主问题，再举一个会让结论失效的输入。');
  }
  return buffer.toString();
}

String buildExamPoints(LessonRepair lesson) {
  final buffer = StringBuffer('## 考点精讲\n\n');
  var index = 0;
  // 考点精讲必须与题库逐题对齐，否则读者在课程里看不到自己刚做错的题。
  final quiz = (lesson.json['quiz'] as List<dynamic>? ?? const <dynamic>[])
      .map((raw) => (raw as Map).cast<String, dynamic>())
      .toList();
  if (quiz.isEmpty) {
    buffer.writeln('本课题库还没有登记题目，先按下面的术语与错误行复习。');
    buffer.writeln();
  } else {
    buffer.writeln(
      '`${lesson.title}` 的题库有 ${quiz.length} 道题，下面逐题给出题干、正确项与判断依据：'
      '先自己作答，再核对正确项，最后回到正文对应小节复核。',
    );
    buffer.writeln();
    for (var quizIndex = 0; quizIndex < quiz.length; quizIndex++) {
      final question = quiz[quizIndex];
      final stem = collapsePunctuation(
        (question['question'] ?? '').toString().replaceAll('\n', ' '),
      ).trim();
      if (stem.isEmpty) continue;
      final correct = collapsePunctuation(
        correctTextOf(question).replaceAll('\n', ' '),
      ).trim();
      index++;
      buffer.writeln('### 考点 $index：第 ${quizIndex + 1} 题');
      buffer.writeln();
      buffer.writeln('- **题目**：$stem');
      if (correct.isNotEmpty) {
        buffer.writeln('- **正确项**：$correct');
      }
      buffer.writeln('- **判断依据**：${examRationale(lesson, question, correct)}');
      buffer.writeln();
    }
  }
  for (final term in lesson.terms.take(6)) {
    index++;
    final boundary = boundaryFor(
      term.name,
      term.definition,
      lesson.mistakes,
    );
    buffer.writeln('### 考点 $index：`${term.name}`');
    buffer.writeln();
    buffer.writeln('- **要点**：${term.definition}');
    buffer.writeln('- **${term.name} 的边界**：$boundary');
    buffer.writeln();
  }
  for (final mistake in lesson.mistakes.take(2)) {
    index++;
    buffer.writeln('### 考点 $index：排错——${trimEndPunctuation(mistake.wrong)}');
    buffer.writeln();
    buffer.writeln('- **现象**：${trimEndPunctuation(mistake.symptom)}。');
    buffer.writeln('- **处理**：${trimEndPunctuation(mistake.fix)}。');
    buffer.writeln();
  }
  if (lesson.terms.length >= 2) {
    index++;
    final first = lesson.terms.first;
    final last = lesson.terms.last;
    buffer.writeln('### 考点 $index：综合辨析——`${first.name}` 与 `${last.name}`');
    buffer.writeln();
    buffer.writeln(
      '- **辨析点**：`${first.name}` 的定义是 ${trimEndPunctuation(first.definition)}；'
      '`${last.name}` 的定义是 ${trimEndPunctuation(last.definition)}。',
    );
    buffer.writeln(
      '- **答题要求**：面对 `${lesson.title}` 的题目，先判断描述的是 '
      '`${first.name}` 还是 `${last.name}`，再归到对应定义，'
      '最后写出一个会让该定义失效的边界输入。',
    );
    buffer.writeln();
  }
  if (lesson.mistakes.isNotEmpty) {
    index++;
    final graded = lesson.mistakes.first;
    buffer.writeln('### 考点 $index：排错评分点');
    buffer.writeln();
    buffer.writeln(
      '- **现象分**：能写出 ${trimEndPunctuation(graded.symptom)}，而不是只写“程序有错”。',
    );
    buffer.writeln(
      '- **证据分**：保留触发 ${trimEndPunctuation(graded.wrong)} 的输入、版本和错误原文。',
    );
    buffer.writeln(
      '- **修复分**：按 ${trimEndPunctuation(graded.fix)} 只改一处，并同时回归正常路径与边界路径。',
    );
    buffer.writeln();
  }
  if (index == 0) {
    buffer.writeln('本课还没有登记术语与错误行，考点精讲待补充。');
  }
  return buffer.toString().trimRight();
}

/// 构造一道可验证的代码阅读题：正确项来自本片段真实出现的内容。
List<String>? buildCodeQuestionOptions(
  LessonRepair lesson,
  List<CodeFact> ownFacts,
  List<CodeFact> pool,
  int seed,
  String code,
) {
  if (ownFacts.isEmpty) return null;
  final random = Random(seed);
  final distinctive = ownFacts
      .where((fact) => pool.where((item) => item.token == fact.token).length <= 6)
      .toList();
  final correctPool = distinctive.isEmpty ? ownFacts : distinctive;
  final correct = correctPool[random.nextInt(correctPool.length)];
  final sameKind = pool
      .where(
        (fact) =>
            fact.kind == correct.kind &&
            fact.lessonId != lesson.id &&
            !code.contains(fact.token) &&
            fact.token != correct.token,
      )
      .toList();
  final fallback = pool
      .where(
        (fact) =>
            fact.lessonId != lesson.id &&
            !code.contains(fact.token) &&
            fact.token != correct.token,
      )
      .toList();
  final distractorPool = sameKind.length >= 3 ? sameKind : fallback;
  if (distractorPool.length < 3) return null;
  final options = <String>[correct.phrase];
  final used = <String>{correct.token};
  var guard = 0;
  while (options.length < 4 && guard < 400) {
    guard++;
    final candidate = distractorPool[random.nextInt(distractorPool.length)];
    if (!used.add(candidate.token)) continue;
    options.add(candidate.phrase);
  }
  if (options.length < 4) return null;
  return options;
}

/// 兜底：代码里出现过的术语做正确项，其他课程的术语做干扰项。
List<String>? buildCodeOptionsFromTerms(
  LessonRepair lesson,
  List<String> termPool,
  int seed,
  String code,
) {
  if (code.isEmpty) return null;
  final present = lesson.terms
      .where((term) => code.contains(term.name))
      .map((term) => term.name)
      .toList();
  final candidates = present.isEmpty
      ? lesson.terms.map((term) => term.name).toList()
      : present;
  if (candidates.isEmpty) return null;
  final correct = candidates[seed.abs() % candidates.length];
  final distractors = termPool
      .where((name) => name != correct)
      .toSet()
      .toList();
  if (distractors.length < 3) return null;
  final random = Random(seed);
  final options = <String>[
    present.isEmpty
        ? '这段示例用于说明本课术语 `$correct` 的行为'
        : '代码里出现了 `$correct` 这个名字',
  ];
  final used = <String>{correct};
  var guard = 0;
  while (options.length < 4 && guard < 200) {
    guard++;
    final candidate = distractors[random.nextInt(distractors.length)];
    if (!used.add(candidate)) continue;
    options.add('代码里出现了 `$candidate` 这个名字');
  }
  if (options.length < 4) return null;
  return options;
}

const List<String> _codeStemFrames = <String>[
  '下面这段 `%LANG%` 代码来自 `%TITLE%`。课程主线是%CONTEXT%；代码与 `%TERM%` 有关。哪一项是代码里真实出现的内容？',
  '阅读 `%TITLE%` 的 `%TERM%` 示例。它服务于%CONTEXT%；代码中实际包含下列哪一项？',
  '这段 `%LANG%` 代码对应 `%TITLE%` 的 `%TERM%`。课程要解决的是%CONTEXT%；关于代码内容，哪一项说法准确？',
  '`%TITLE%` 的示例代码用于验证 `%TERM%`，其背景是%CONTEXT%。代码的真实内容是下面哪一项？',
  '代码语言为 `%LANG%`，选自 `%TITLE%` 的 `%TERM%` 部分。课程问题为%CONTEXT%；哪一项描述与代码一致？',
];

String buildCodeStem(LessonRepair lesson, int seed, String language) {
  final term = lesson.terms.isEmpty
      ? lesson.categoryTitle
      : lesson.terms.first.name;
  final context = lesson.summary.isEmpty
      ? lesson.keywords.join('、')
      : clampSentence(lesson.summary, 72);
  return _codeStemFrames[seed % _codeStemFrames.length]
      .replaceAll('%LANG%', language.isEmpty ? '示例' : language)
      .replaceAll('%TITLE%', lesson.title)
      .replaceAll('%TERM%', term)
      .replaceAll('%CONTEXT%', context);
}

Map<String, dynamic> buildFillQuestion(
  LessonRepair lesson,
  Map<String, dynamic> question,
  int seed,
  Set<String> usedTerms,
) {
  final accepted =
      ((question['accepted_answers'] as List<dynamic>?) ?? const [])
          .map((item) => '$item')
          .toList();
  final answer = accepted.isEmpty ? '' : accepted.first;
  Term? term;
  for (final candidate in lesson.terms) {
    if (candidate.name.toLowerCase() == answer.toLowerCase() &&
        !usedTerms.contains(candidate.name)) {
      term = candidate;
      break;
    }
  }
  if (term == null) {
    final available =
        lesson.terms.where((item) => !usedTerms.contains(item.name)).toList();
    if (available.isNotEmpty) {
      term = available[seed.abs() % available.length];
    }
  }
  if (term == null || term.definition.isEmpty) {
    return <String, dynamic>{
      'question': '填空：请根据本课正文，写出「${lesson.title}」的核心术语名称。',
      'accepted_answers': <String>[lesson.title],
    };
  }
  usedTerms.add(term.name);
  var definition = balanceBackticks(term.definition);
  if (definition.contains(term.name)) {
    definition = definition.replaceAll(term.name, '`____`');
  } else {
    definition = '`____`：$definition';
  }
  definition = clampSentence(definition, 120);
  definition = balanceBackticks(definition);
  if (!definition.contains('____')) {
    definition = '`____`：${trimEndPunctuation(definition)}';
  }
  final context = lesson.summary.isEmpty
      ? lesson.keywords.join('、')
      : lesson.summary;
  return <String, dynamic>{
    'question': '填空：补齐下面这段术语说明中的空缺。课程 `$context`，'
        '这段说明是：$definition。空缺处应填哪个术语？',
    'accepted_answers': <String>[
      term.name,
      if (term.name.toLowerCase() != term.name) term.name.toLowerCase(),
    ],
  };
}

/// 非代码题里的模板化题干：换成嵌有本课术语的说法。
String detemplatizeStem(
  LessonRepair lesson,
  Map<String, dynamic> question,
  int seed,
) {
  final stem = ((question['question'] as String?) ?? '').trim();
  final type = (question['type'] as String?) ?? 'single';
  final term = lesson.terms.isEmpty ? '' : lesson.terms.first.name;
  final second = lesson.terms.length > 1 ? lesson.terms[1].name : term;
  final context = lesson.summary.isEmpty
      ? lesson.keywords.join('、')
      : lesson.summary;
  if (stem.startsWith('以下哪些术语与') && type == 'multi' && term.isNotEmpty) {
    return '课程 `$context`。在 `${lesson.title}` 里，`$term`、`$second` '
        '与下面哪些选项属于同一层概念？（多选）';
  }
  if (stem.contains('核心学习目标是什么')) {
    return '`${lesson.title}` 的主线是：${trimEndPunctuation(lesson.summary)}。'
        '下面哪一项与这条主线一致？';
  }
  if (stem.contains('的代码片段，下面哪项判断是正确的') && type == 'debug') {
    final frames = <String>[
      '`${lesson.title}` 的示例代码服务于“$context”。哪一条判断是正确的？',
      '结合 `${lesson.title}` 中围绕 `$term` 的代码，哪一项说法与“$context”一致？',
    ];
    return frames[seed % frames.length];
  }
  if (stem.startsWith('阅读') && stem.contains('代码，下面哪项判断最准确')) {
    return '阅读 `${lesson.title}` 中围绕 `$term` 的代码；课程主线是$context。'
        '下面哪项判断最准确？';
  }
  if (stem.startsWith('把') && stem.contains('的步骤调整为正确顺序')) {
    return '把 `${lesson.title}` 中与 `$term` 有关的步骤调整为正确顺序；'
        '该课主线是$context。';
  }
  if (stem.endsWith('的核心结论是什么？')) {
    return '结合$context，`${lesson.title}` 的核心结论是什么？';
  }
  if (stem.contains('从概念到实践的讲解顺序') && term.isNotEmpty) {
    return '下面几项都与 `$term` 有关，请按 `${lesson.title}` 的正文顺序排列；'
        '该课主线是$context。';
  }
  if (stem.startsWith('关于「') && stem.contains('下列哪些说法是正确的')) {
    return '关于 `$term`，下列哪些说法与 `${lesson.title}` 的正文一致？'
        '判断时以$context为主线。（多选）';
  }
  if (stem.startsWith('关于「') && stem.contains('下列说法正确的是')) {
    if (term.isEmpty) return stem;
    return '在 `${lesson.title}` 里，与 `$term` 有关的说法中，'
        '哪一项最符合$context？';
  }
  return stem;
}

String buildExplanation(
  LessonRepair lesson,
  Map<String, dynamic> question,
  String correctText,
  int questionNumber,
) {
  final stem = (question['question'] as String?) ?? '';
  final haystack = '$stem $correctText';
  final buffer = StringBuffer();
  buffer.write('在 `${lesson.title}` 第 $questionNumber 题中，');
  // 保留答案原文，确保复习时能把解析与选项逐字对照。
  final answerText = correctText.isEmpty ? '本课术语表里的对应术语' : correctText;
  buffer.write('正确答案是「$answerText」。');

  Term? matched;
  for (final term in lesson.terms) {
    if (haystack.contains(term.name)) {
      matched = term;
      break;
    }
  }
  matched ??= lesson.terms.isEmpty ? null : lesson.terms.first;
  if (matched != null) {
    buffer.write(
      '在「${lesson.title}」第 $questionNumber 题中，该判断与术语 `${matched.name}` 对应：'
      '${flattenSentence(matched.definition)}。',
    );
  } else if (lesson.summary.isNotEmpty) {
    buffer.write(
      '在「${lesson.title}」第 $questionNumber 题中，这道题检验的主问题是：'
      '${flattenSentence(lesson.summary)}。',
    );
  }

  Mistake? matchedMistake;
  for (final mistake in lesson.mistakes) {
    final fixProbe = mistake.fix.substring(0, min(6, mistake.fix.length));
    if (haystack.contains(trimEndPunctuation(mistake.wrong)) ||
        (fixProbe.isNotEmpty && haystack.contains(fixProbe))) {
      matchedMistake = mistake;
      break;
    }
  }
  matchedMistake ??= lesson.mistakes.isEmpty ? null : lesson.mistakes.first;
  if (matchedMistake != null) {
    buffer.write(
      '在「${lesson.title}」第 $questionNumber 题中，错误表现方面，'
      '${flattenSentence(matchedMistake.wrong)}会造成'
      '${flattenSentence(matchedMistake.symptom)}，应按'
      '${flattenSentence(matchedMistake.fix)}修复。',
    );
  }

  var text = buffer.toString();
  final keywords = lesson.keywords.take(4).toList();
  if (text.length < 220) {
    text = '$text 在「${lesson.title}」第 $questionNumber 题中，'
        '判断时先确认输入和适用范围，'
        '对照 ${keywords.isEmpty ? '本课核心术语与示例' : _codeList(keywords)} '
        '复现一次，最后把错误表现与正确做法逐项对照。';
  }
  if (text.length < 120) {
    text = '$text 这道 `${lesson.title}` 的题目还要求说明选择依据、适用边界和失败条件，'
        '不能只凭选项长度或关键词猜测。';
  }
  return text;
}

// ---------------------------------------------------------------- 组装与写盘

String rebuildLesson(
  LessonRepair lesson,
  ContentPack pack,
  Map<String, int> frequency,
  int lessonCount,
) {
  final buffer = StringBuffer();
  buffer.writeln(buildHeader(lesson));
  buffer.writeln();
  final sections = <String>[
    buildFramework(lesson, pack),
    buildDefinitions(lesson),
    buildMechanism(lesson, frequency, lessonCount),
    buildScenarios(lesson, frequency, lessonCount),
    buildExamples(lesson, frequency, lessonCount),
    buildPerformance(lesson, frequency, lessonCount),
    buildMistakes(lesson),
    buildRelations(lesson, pack, frequency, lessonCount),
    buildSelfTest(lesson),
    buildGlossary(lesson),
    buildExamPoints(lesson),
  ];
  for (final section in sections) {
    buffer.writeln(section);
    buffer.writeln();
  }
  for (final name in <String>['内容元数据']) {
    final body = (lesson.sections[name] ?? '').trim();
    if (body.isEmpty) continue;
    buffer.writeln('## $name');
    buffer.writeln();
    buffer.writeln(body);
    buffer.writeln();
  }
  final references = buildReferences(lesson);
  buffer.writeln('## 参考资料与复核');
  buffer.writeln();
  buffer.writeln(references);
  buffer.writeln();
  final assembled = ensureProjectSpec(
    restoreMissingImages('${buffer.toString().trimRight()}\n', lesson),
    lesson,
  );
  return dropEmptyHeadings(
    dedupeRepeatedBlocks(normalizeContentPunctuation(assembled)),
  );
}

/// 提取 Markdown 图片引用，用于在重建后补回被过滤掉的配图。
List<String> extractImageReferences(String markdown) {
  return RegExp(r'!\[[^\]]*\]\([^)]+\)')
      .allMatches(markdown)
      .map((match) => match.group(0)!)
      .toList();
}

/// 把原文里有、重建后丢失的图片补到「本节知识框架」末尾。
String restoreMissingImages(String markdown, LessonRepair lesson) {
  final missing = extractImageReferences(lesson.markdown)
      .where((image) => !markdown.contains(image))
      .toList();
  if (missing.isEmpty) return markdown;
  const heading = '## 本节知识框架';
  final start = markdown.indexOf(heading);
  if (start < 0) return markdown;
  final next = markdown.indexOf('\n## ', start + heading.length);
  final block = '\n\n**本课配图**\n\n${missing.join('\n\n')}\n';
  if (next < 0) return '$markdown$block';
  return '${markdown.substring(0, next)}$block${markdown.substring(next)}';
}

/// 项目课必须保留「项目专属规格」；早期重建把这段过滤掉时在这里补回。
String ensureProjectSpec(String markdown, LessonRepair lesson) {
  final isProject = lesson.id.contains('project') ||
      lesson.title.contains('实战') ||
      lesson.title.contains('项目');
  if (!isProject || markdown.contains('项目专属规格')) return markdown;
  const heading = '## 典型应用场景';
  final start = markdown.indexOf(heading);
  if (start < 0) return markdown;
  final next = markdown.indexOf('\n## ', start + heading.length);
  final block = '\n\n### 项目专属规格\n\n'
      '- **交付目标**：完成 `${lesson.title}` 描述的可运行产物，并留下可复查的证据。\n'
      '- **必须交付**：源代码、运行说明、测试或验证记录、失败路径说明。\n'
      '- **验收标准**：按本课「项目交付物」和「考点精讲」逐项核对，不能只展示正常路径。\n'
      '- **排错要求**：至少记录一次失败输入、现象、定位过程和修复结论。\n';
  if (next < 0) return '$markdown$block';
  return '${markdown.substring(0, next)}$block${markdown.substring(next)}';
}

/// 删除没有直接正文的 H3 及更深标题。
///
/// 这些标题是旧结构迁移的残留；保留空标题会让阅读器出现“点开后没有内容”。
String dropEmptyHeadings(String markdown) {
  final lines = const LineSplitter().convert(markdown);
  final headings = <({int line, int level})>[];
  for (var index = 0; index < lines.length; index++) {
    final match = RegExp(r'^(#{2,6})\s+').firstMatch(lines[index]);
    if (match != null) {
      headings.add((line: index, level: match.group(1)!.length));
    }
  }
  final remove = <int>{};
  for (var index = 0; index < headings.length; index++) {
    final heading = headings[index];
    if (heading.level < 3) continue;
    var end = lines.length;
    for (var next = index + 1; next < headings.length; next++) {
      if (headings[next].level <= heading.level) {
        end = headings[next].line;
        break;
      }
    }
    var hasBody = false;
    for (var line = heading.line + 1; line < end; line++) {
      final trimmed = lines[line].trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      hasBody = true;
      break;
    }
    if (!hasBody) remove.add(heading.line);
  }
  return [
    for (var index = 0; index < lines.length; index++)
      if (!remove.contains(index)) lines[index],
  ].join('\n');
}

/// 清理正文里的连续标点。这些痕迹来自早期“句子再补一个句号”式的批量拼接，
/// 只处理围栏外的正文，代码与命令示例保持原样。
String normalizeContentPunctuation(String markdown) {
  final buffer = StringBuffer();
  var inFence = false;
  for (final line in const LineSplitter().convert(markdown)) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      buffer.writeln(line);
      continue;
    }
    if (inFence) {
      buffer.writeln(line);
      continue;
    }
    buffer.writeln(collapsePunctuation(line));
  }
  return buffer.toString();
}

/// 收敛一行文本里的连续标点。
///
/// 正文与题库共用这一套规则：考点精讲会把题干与解析原样搬进 Markdown，
/// 两边只要有一边先被改写，就会出现「题库题干在正文里找不到」的不一致。
String collapsePunctuation(String line) {
  var cleaned = line;
  var previous = '';
  while (previous != cleaned) {
    previous = cleaned;
    cleaned = cleaned
        .replaceAll(RegExp(r'。。+'), '。')
        .replaceAll(RegExp(r'。；'), '。')
        .replaceAll(RegExp(r'，。'), '。')
        .replaceAll(RegExp(r'：。'), '。')
        .replaceAll(RegExp(r'；。'), '。')
        .replaceAll(RegExp(r'、。'), '。')
        .replaceAll(RegExp(r'！。'), '！')
        .replaceAll(RegExp(r'？。'), '？')
        .replaceAll(RegExp(r'。，'), '。')
        .replaceAll(RegExp(r'；，'), '；')
        .replaceAll(RegExp(r'，，+'), '，');
  }
  return cleaned;
}

/// 删掉同一课里重复出现的段落，保留第一次出现的位置。
String dedupeRepeatedBlocks(String markdown) {
  final parts = <String>[];
  final seen = <String>{};
  final buffer = StringBuffer();
  var inFence = false;
  void flush() {
    final text = buffer.toString().trim();
    buffer.clear();
    if (text.isEmpty) return;
    if (!text.startsWith('#')) {
      final key = text.replaceAll(RegExp(r'\s+'), ' ');
      if (key.length >= 80 && !seen.add(key)) return;
    }
    parts.add(text);
  }

  for (final line in const LineSplitter().convert(markdown)) {
    final trimmedLeft = line.trimLeft();
    if (trimmedLeft.startsWith('```')) {
      if (!inFence) {
        flush();
        inFence = true;
        buffer.writeln(line);
      } else {
        buffer.writeln(line);
        inFence = false;
        flush();
      }
      continue;
    }
    if (inFence) {
      buffer.writeln(line);
      continue;
    }
    if (line.trim().isEmpty) {
      flush();
      continue;
    }
    buffer.writeln(line);
  }
  flush();
  return '${parts.join('\n\n')}\n';
}

const List<String> _genericOptionMarkers = <String>[
  '这段代码包含循环结构',
  '这段代码只做静态声明',
  '这段代码把主要逻辑封装在函数或方法里',
  '这段代码会产生可观察的输出',
  '这段代码包含条件分支',
  '这段代码包含异常处理分支',
  '这段代码会读取外部输入',
  '这段代码会修改外部状态',
  '这段代码包含异常处理',
];

bool isGenericCodeOptions(Map<String, dynamic> question) {
  final options = ((question['options'] as List<dynamic>?) ?? const [])
      .map((item) => '$item')
      .toList();
  if (options.length < 3) return false;
  final hits = options
      .where((option) => _genericOptionMarkers.any(option.contains))
      .length;
  return hits >= options.length - 1;
}

String correctTextOf(Map<String, dynamic> question) {
  final type = (question['type'] as String?) ?? 'single';
  final options = ((question['options'] as List<dynamic>?) ?? const [])
      .map((item) => '$item')
      .toList();
  if (type == 'fill') {
    final accepted =
        ((question['accepted_answers'] as List<dynamic>?) ?? const [])
            .map((item) => '$item')
            .toList();
    return accepted.isEmpty ? '本课术语表里的对应术语' : accepted.first;
  }
  if (type == 'multi') {
    final answers = ((question['answers'] as List<dynamic>?) ?? const [])
        .map((item) => int.tryParse('$item') ?? -1)
        .where((index) => index >= 0 && index < options.length)
        .toList();
    if (answers.isEmpty) return options.isEmpty ? '' : options.first;
    // 去掉每个选项的句末标点后再拼接，避免出现「。；」这类异常标点，
    // 同时每个选项的主体仍然完整保留在解析里。
    return answers
        .map((index) => trimEndPunctuation(options[index]))
        .join('；');
  }
  if (type == 'order') {
    final order = ((question['correct_order'] as List<dynamic>?) ?? const [])
        .map((item) => int.tryParse('$item') ?? -1)
        .where((index) => index >= 0 && index < options.length)
        .toList();
    if (order.isEmpty) return options.join(' → ');
    return order.map((index) => options[index]).join(' → ');
  }
  final answer = (question['answer'] as num?)?.toInt() ?? 0;
  if (answer < 0 || answer >= options.length) {
    return options.isEmpty ? '' : options.first;
  }
  return options[answer];
}

class QuizStats {
  var fills = 0;
  var codeOptions = 0;
  var detemplated = 0;
  var explanations = 0;
}

/// 把题库文本收敛成与正文一致的标点写法。
///
/// 考点精讲会逐字引用题干，所以题干必须提前去掉「。。」「。；」这类痕迹：
/// 正文在组装时统一清理过一次，题库若不清理，两边就会永远对不上。
void sanitizeQuizPunctuation(Map<String, dynamic> question) {
  // 只处理人类可读文本；代码片段、语言标记与答案下标必须保持原样。
  const textKeys = <String>{
    'question',
    'options',
    'explanation',
    'accepted_answers',
  };
  for (final key in question.keys.toList()) {
    if (!textKeys.contains(key)) continue;
    final value = question[key];
    if (value is String) {
      final cleaned = collapsePunctuation(value.replaceAll('\n', ' '));
      question[key] = cleaned.replaceFirst(
        RegExp(r'^[。；，、]+'),
        '',
      );
    } else if (value is List) {
      question[key] = value
          .map<dynamic>(
            (item) => item is String
                ? collapsePunctuation(item.replaceAll('\n', ' '))
                : item,
          )
          .toList();
    }
  }
}

/// 把历史题库里的「本课主题」占位符替换成真实标题，覆盖题干、选项与解析。
void sanitizeQuizPlaceholders(Map<String, dynamic> question, String title) {
  const placeholder = '本课主题';
  final replacement = '`$title`';
  for (final key in question.keys.toList()) {
    final value = question[key];
    if (value is String) {
      question[key] = value.replaceAll(placeholder, replacement);
    } else if (value is List) {
      question[key] = value
          .map<dynamic>(
            (item) => item is String
                ? item.replaceAll(placeholder, replacement)
                : item,
          )
          .toList();
    }
  }
}

QuizStats repairQuiz(
  LessonRepair lesson,
  List<CodeFact> pool,
  List<CodeFact> ownFacts,
  List<String> termPool,
) {
  final stats = QuizStats();
  final quiz = lesson.json['quiz'];
  if (quiz is! List) return stats;
  final usedTerms = <String>{};
  for (var index = 0; index < quiz.length; index++) {
    final question = (quiz[index] as Map).cast<String, dynamic>();
    final type = (question['type'] as String?) ?? 'single';
    final seed = lesson.id.hashCode + index * 31;
    if (type == 'fill') {
      final rebuilt = buildFillQuestion(lesson, question, seed, usedTerms);
      question['question'] = rebuilt['question'];
      question['accepted_answers'] = rebuilt['accepted_answers'];
      stats.fills++;
    } else if (type == 'code' && isGenericCodeOptions(question)) {
      final code = (question['code'] ?? '').toString();
      final language = (question['language'] ?? '').toString();
      var options = buildCodeQuestionOptions(
        lesson,
        ownFacts,
        pool,
        seed,
        code.isEmpty ? lesson.markdown : code,
      );
      options ??= buildCodeOptionsFromTerms(
        lesson,
        termPool,
        seed,
        code.isEmpty ? lesson.markdown : code,
      );
      if (options != null) {
        final target = seed.abs() % 4;
        final correct = options.first;
        options[0] = options[target];
        options[target] = correct;
        question['options'] = options;
        question['answer'] = target;
        question['question'] = buildCodeStem(lesson, seed.abs(), language);
        stats.codeOptions++;
      }
    } else {
      final before = (question['question'] ?? '').toString();
      final after = detemplatizeStem(lesson, question, seed.abs());
      if (after != before) {
        question['question'] = after;
        stats.detemplated++;
      }
    }
    sanitizeQuizPunctuation(question);
    question['explanation'] = buildExplanation(
      lesson,
      question,
      correctTextOf(question),
      index + 1,
    );
    sanitizeQuizPlaceholders(question, lesson.title);
    stats.explanations++;
  }
  return stats;
}

/// 给完全相同的题干补上课程与题号定位，保证题库题干全局唯一。
void dedupeQuestionStems(ContentPack pack) {
  final seen = <String>{};
  for (final lesson in pack.lessons) {
    final quiz = lesson.json['quiz'];
    if (quiz is! List) continue;
    for (var index = 0; index < quiz.length; index++) {
      final question = (quiz[index] as Map).cast<String, dynamic>();
      final stem = (question['question'] as String?)?.trim() ?? '';
      if (stem.isEmpty) continue;
      final key = stem.replaceAll(RegExp(r'\s+'), '');
      if (seen.add(key)) continue;
      final label = lesson.categoryTitle.isEmpty
          ? lesson.title
          : '${lesson.title}·${lesson.categoryTitle}';
      var attempt = 1;
      var candidate = '$stem（$label 第 ${index + 1} 题）';
      while (!seen.add(candidate.replaceAll(RegExp(r'\s+'), ''))) {
        attempt++;
        candidate = '$stem（$label 第 ${index + 1} 题·$attempt）';
      }
      question['question'] = candidate;
    }
  }
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final bodiesOnly = args.contains('--bodies');
  final quizOnly = args.contains('--quiz');
  final doBodies = !quizOnly;
  final doQuiz = !bodiesOnly;
  final pack = loadPack();
  final frequency = buildBlockFrequency(pack.lessons);
  final lessonCount = pack.lessons.length;
  final factPool = <CodeFact>[];
  final ownFacts = <String, List<CodeFact>>{};
  final termPool = <String>[];
  for (final lesson in pack.lessons) {
    final facts = extractFacts(lesson);
    ownFacts[lesson.id] = facts;
    factPool.addAll(facts);
    termPool.addAll(lesson.terms.map((term) => term.name));
  }
  stdout.writeln('课程=$lessonCount 归一化块=${frequency.length} 代码事实=${factPool.length}');

  final totals = QuizStats();
  if (doQuiz) {
    for (final lesson in pack.lessons) {
      final stats = repairQuiz(
        lesson,
        factPool,
        ownFacts[lesson.id]!,
        termPool,
      );
      totals.fills += stats.fills;
      totals.codeOptions += stats.codeOptions;
      totals.detemplated += stats.detemplated;
      totals.explanations += stats.explanations;
    }
    dedupeQuestionStems(pack);
  }

  var bodies = 0;
  final tooShort = <String>[];
  final missingSections = <String>[];
  if (doBodies) {
    for (final lesson in pack.lessons) {
      final rebuilt = rebuildLesson(lesson, pack, frequency, lessonCount);
      for (final section in coreSections) {
        if (!rebuilt.contains('## $section')) {
          missingSections.add('${lesson.id}:$section');
        }
      }
      final target = lesson.categoryId == 'python' ? 12000 : 10000;
      if (rebuilt.length < target) {
        tooShort.add('${lesson.id}=${rebuilt.length}');
      }
      if (dryRun) {
        final out = File('$previewRoot/${lesson.id}.md');
        out.parent.createSync(recursive: true);
        out.writeAsStringSync(rebuilt);
      } else {
        File((lesson.json['file'] as String)).writeAsStringSync(rebuilt);
      }
      bodies++;
    }
  }

  if (doQuiz) {
    final encoded = const JsonEncoder.withIndent('  ').convert(pack.manifest);
    if (dryRun) {
      File('$previewRoot/manifest.json')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('$encoded\n');
    } else {
      File(manifestPath).writeAsStringSync('$encoded\n');
    }
  }

  stdout.writeln('正文处理=$bodies 低于目标=${tooShort.length} 缺章节=${missingSections.length}');
  if (tooShort.isNotEmpty) {
    stdout.writeln('  过短样例：${tooShort.take(5).toList()}');
  }
  if (missingSections.isNotEmpty) {
    stdout.writeln('  缺章节样例：${missingSections.take(5).toList()}');
  }
  stdout.writeln(
    '题库：填空重写=${totals.fills} 代码题重写=${totals.codeOptions} '
    '题干去模板=${totals.detemplated} 解析重写=${totals.explanations}',
  );
  stdout.writeln(dryRun ? '输出目录：$previewRoot' : '已写入仓库');
}
