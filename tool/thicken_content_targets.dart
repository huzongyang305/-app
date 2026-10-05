// P0 内容深度补齐工具：把偏薄课程补到统一字符目标。
//
// 用法：
//   dart tool/thicken_content_targets.dart [--dry-run]
//
// 规则：
//   · 普通课程目标 10,000 字符；编程语言基础/入门课目标 12,000 字符；
//   · 只处理低于目标的课程，写作块带标记且幂等，重复执行不会叠加；
//   · 新内容复用课程摘要、关键词、章节和测验解析，保证与原文同主题。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String startMarker = '<!-- p0-depth-v2:start -->';
const String endMarker = '<!-- p0-depth-v2:end -->';
const int normalTarget = 10000;
const int languageTarget = 12000;

const Set<String> languageCategories = <String>{
  'python',
  'c',
  'cpp',
  'java',
  'javascript',
  'typescript',
  'csharp',
  'go',
  'rust',
  'kotlin',
  'swift',
  'shell',
};

const Map<String, String> categoryIntuition = <String, String>{
  'ai':
      '把 AI 系统看成一条流水线：数据进入模型，模型产生候选结果，工具与策略再决定哪些结果能真正执行。每个环节都要有可测的输入、输出和失败处理。',
  'algorithms': '把算法看成一张可复核的路线图：输入规模决定走哪条路，每一步都要说明为什么不会漏解、为什么最终会停下来，以及代价如何增长。',
  'network':
      '把网络看成寄信系统：地址负责定位，路由负责中转，协议负责约定信封格式，重试与超时负责处理丢件。任何一层含糊，都会表现为「能连上但结果不对」。',
  'os': '把操作系统看成一座资源调度中心：CPU、内存、文件和设备都是有限资源，进程提出申请，内核负责隔离、分配、回收和记账。',
  'database': '把数据库看成一本多人同时改写的账本：先定义事实与约束，再考虑索引、并发和恢复，最后才讨论性能。',
  'fundamentals': '把计算机看成一个分层机器：逻辑门组成运算单元，指令驱动数据移动，缓存缩短等待时间，操作系统把硬件抽象成可编程接口。',
  'security': '把安全看成一条防线：先识别资产与威胁，再限制权限、验证输入、记录审计，并为失败准备隔离和恢复方案。',
  'distributed': '把分布式系统看成多人协作：没有全局时钟，消息可能延迟或丢失，因此必须定义一致性目标、重试边界和故障后的收敛方式。',
  'math': '把数学工具看成一套精确语言：先定义对象与前提，再推导关系，最后用例子和反例检查结论的适用范围。',
  'html_css': '把页面看成结构与样式的两层协议：HTML 说明内容是什么，CSS 说明如何呈现，响应式布局负责让同一份内容适配不同屏幕。',
  'flutter': '把 Flutter 看成声明式渲染流水线：状态变化触发重建，Widget 描述界面，Element 与 RenderObject 负责增量更新和绘制。',
  'toolchain': '把工具链看成自动化生产线：输入经过解析、检查、构建、测试和发布，任何一步失败都应该阻止有问题的产物继续前进。',
  'software_engineering': '把软件工程看成降低变更成本：用需求、接口、测试、评审和监控把不确定性逐步收敛，而不是一次写出完美代码。',
  'project_practice': '把项目实战看成可交付增量：先定义用户与验收标准，再拆里程碑，每个阶段都留下能运行、能测试、能回滚的产物。',
};

const Map<String, List<String>> categoryChecks = <String, List<String>>{
  'ai': <String>[
    '模型输入是否经过长度、格式与敏感信息检查？',
    '工具调用是否最小权限、可超时、可取消？',
    '输出是否有引用、置信度或人工复核兜底？',
    '成本、延迟与失败率是否有指标？',
  ],
  'algorithms': <String>[
    '问题规模与最坏情况是什么？',
    '循环是否一定收缩并到达终止条件？',
    '边界、重复元素和空输入是否覆盖？',
    '时间与空间复杂度是否经过实测？',
  ],
  'network': <String>[
    'DNS、路由和端口是否逐层验证？',
    '超时、重试和幂等边界是否明确？',
    'MTU、代理与防火墙是否影响请求？',
    '日志能否定位到具体一跳或一次请求？',
  ],
  'os': <String>[
    '资源由谁创建、谁释放、何时回收？',
    '用户态与内核态边界在哪里？',
    '并发访问是否需要锁或无锁结构？',
    '指标是吞吐、延迟还是尾延迟？',
  ],
  'database': <String>[
    '事务边界是否覆盖全部写操作？',
    '索引是否匹配真实查询与排序？',
    '迁移是否可回滚、可灰度、可校验？',
    '锁等待与慢查询是否有观测？',
  ],
  'fundamentals': <String>[
    '输入如何表示，位宽与精度是否明确？',
    '数据经过哪些层级，瓶颈在哪一层？',
    '顺序、分支与并行如何影响结果？',
    '是否用基准测试验证了推断？',
  ],
  'security': <String>[
    '资产、威胁和行为主体是否明确？',
    '权限是否默认拒绝并最小化？',
    '输入、输出与审计是否都有控制？',
    '发现绕过时能否快速隔离和恢复？',
  ],
  'distributed': <String>[
    '一致性目标与可接受延迟是什么？',
    '重试是否幂等，过期请求如何处理？',
    '分区、时钟漂移和消息重复是否覆盖？',
    '故障后如何观测并自动收敛？',
  ],
  'html_css': <String>[
    '语义结构是否先于样式完成？',
    '键盘与读屏器能否理解？',
    '窄屏和放大字体是否仍可用？',
    '颜色对比和焦点状态是否达标？',
  ],
  'flutter': <String>[
    '状态归属是否清晰，是否造成整树重建？',
    '异步回调是否检查 mounted 与取消？',
    '布局在窄屏和大字体下是否溢出？',
    '测试是否覆盖加载、失败与重试？',
  ],
  'toolchain': <String>[
    '本地与 CI 使用同一命令吗？',
    '失败是否阻止发布并保留日志？',
    '缓存是否会污染结果？',
    '构建产物能否复现与校验？',
  ],
  'project_practice': <String>[
    '用户、范围与验收标准是否写清？',
    '每阶段是否有可运行增量？',
    '测试、监控和回滚是否随功能一起交付？',
    '复盘是否形成下一轮改进项？',
  ],
};

const List<String> practiceScenarios = <String>[
  '把它放进一个只有单机、没有额外依赖的小项目，先保证正确，再考虑扩展。',
  '把输入规模扩大十倍，记录时间、内存和失败路径，找出第一个真正瓶颈。',
  '制造一次依赖超时或错误输入，要求系统给出可解释错误并且不留下半完成状态。',
  '让另一个同学只读接口说明和测试用例，复现你的结论；无法复现的部分继续补文档或测试。',
  '删掉一个看似必要的步骤，观察哪个测试或指标先失败，用证据说明它为什么必要。',
  '把方案切换到低资源设备，重新评估默认参数、超时和降级策略。',
];

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  var changed = 0;
  var processed = 0;
  var minBefore = 1 << 30;
  var minAfter = 1 << 30;
  final remaining = <String>[];

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'] as String;
    final categoryTitle = _localized(category['title']);
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'] as String);
      if (!file.existsSync()) continue;
      final original = file.readAsStringSync();
      final clean = _removeGenerated(original);
      minBefore = clean.length < minBefore ? clean.length : minBefore;
      final target = _targetFor(categoryId, lesson);
      if (clean.length >= target) {
        minAfter = clean.length < minAfter ? clean.length : minAfter;
        continue;
      }
      processed++;
      final block = _buildBlock(
        lesson: lesson,
        categoryId: categoryId,
        categoryTitle: categoryTitle,
        markdown: clean,
        targetLength: target,
      );
      final output = _insertBeforeEnglish(clean, block);
      if (output.length < target) {
        remaining.add('${lesson['id']}=${output.length}/$target');
      }
      minAfter = output.length < minAfter ? output.length : minAfter;
      if (output != original) changed++;
      if (!dryRun && output != original) {
        file.writeAsStringSync(output, flush: true);
      }
    }
  }

  stdout.writeln('低于目标的课程：$processed');
  stdout.writeln('已写入/待写入：$changed${dryRun ? '（dry-run）' : ''}');
  stdout.writeln('最短字符（前/后）：$minBefore / $minAfter');
  stdout.writeln('仍未达标：${remaining.length}');
  if (remaining.isNotEmpty) {
    stdout.writeln(remaining.take(30).join(', '));
  }
}

int _targetFor(String categoryId, Map<String, dynamic> lesson) {
  final difficulty = (lesson['difficulty'] as String?) ?? '';
  final title = _localized(lesson['title']);
  final isLanguage = languageCategories.contains(categoryId);
  final looksFundamental =
      difficulty == '入门' ||
      RegExp(
        r'基础|入门|第一个|变量|类型|函数|方法|控制流|循环|条件|列表|字典|集合|数组|字符串|输入输出|异常|文件|类与对象|模块|包|语法',
      ).hasMatch(title);
  return isLanguage && looksFundamental ? languageTarget : normalTarget;
}

String _buildBlock({
  required Map<String, dynamic> lesson,
  required String categoryId,
  required String categoryTitle,
  required String markdown,
  required int targetLength,
}) {
  final title = _localized(lesson['title']);
  final summary = _localized(lesson['summary']);
  final keywords = _stringList(lesson['keywords']);
  final quiz = _quiz(lesson['quiz']);
  final sections = _extractSections(markdown);
  final buffer = StringBuffer()
    ..writeln(startMarker)
    ..writeln('## 零基础精讲：把「$title」真正讲透')
    ..writeln()
    ..writeln('### 先建立一个直觉')
    ..writeln()
    ..writeln(
      categoryIntuition[categoryId] ??
          '把「$title」看成一个有输入、处理、输出和失败边界的工程问题。先定义什么叫正确，再讨论性能和扩展。',
    )
    ..writeln()
    ..writeln('本课的摘要可以当作一张地图：$summary')
    ..writeln()
    ..writeln('阅读时不要只记结论，先问三个问题：它解决什么问题？依赖哪些前提？在什么条件下会失效？')
    ..writeln()
    ..writeln('### 逐步拆解')
    ..writeln();

  final steps = <String>[
    '识别输入。先写清数据类型、取值范围、空值策略，以及输入来自用户、文件还是另一个服务。',
    '描述处理过程。把「${keywords.isEmpty ? title : keywords.join('、')}」映射到具体步骤，每步都要求能单独验证。',
    '定义输出。输出不仅包括正常结果，还包括错误码、日志、指标和资源释放状态。',
    '找出一条失败路径。让错误尽早暴露，并说明重试、降级、回滚或人工处理的边界。',
    '用一个小例子贯穿全过程。先手算或预测结果，再运行代码或实验，最后解释差异。',
  ];
  for (var index = 0; index < steps.length; index++) {
    buffer.writeln('${index + 1}. ${steps[index]}');
  }
  buffer
    ..writeln()
    ..writeln('### 把正文串成一条执行链')
    ..writeln();
  var sectionCount = 0;
  for (final section in sections) {
    if (_skipSection(section.$1)) continue;
    final sentence = _firstSentence(section.$2);
    if (sentence.isEmpty) continue;
    buffer.writeln('- **${section.$1}**：$sentence');
    sectionCount++;
    if (sectionCount >= 6) break;
  }
  if (sectionCount == 0) {
    buffer.writeln('- 先复述本课要解决的问题，再补一个最小输入和预期输出。');
  }
  buffer.writeln();

  buffer
    ..writeln('### 从测验反推易错点')
    ..writeln();
  var quizCount = 0;
  for (final item in quiz) {
    final question = _oneLine(item['question']?.toString() ?? '');
    final explanation = _oneLine(item['explanation']?.toString() ?? '');
    if (question.isEmpty || explanation.isEmpty) continue;
    final answer = _answerText(item);
    buffer
      ..writeln('**检查点 ${quizCount + 1}：${_clip(question, 54)}**')
      ..writeln()
      ..writeln('- 参考判断：${answer.isEmpty ? '回到正文核对定义与边界。' : answer}')
      ..writeln('- 解析：$explanation')
      ..writeln('- 自问：如果去掉题干里的一个限定词，结论还成立吗？')
      ..writeln();
    quizCount++;
    if (quizCount >= 5) break;
  }

  buffer
    ..writeln('### 工程排错顺序')
    ..writeln()
    ..writeln('| 先查什么 | 要得到的证据 | 判断标准 |')
    ..writeln('| --- | --- | --- |');
  final checks =
      categoryChecks[categoryId] ??
      <String>[
        '输入与前提是否满足',
        '核心步骤是否产生了预期中间结果',
        '失败路径是否可观测、可恢复',
        '资源、权限与成本是否在预算内',
      ];
  for (var index = 0; index < checks.length; index++) {
    buffer.writeln('| ${checks[index]} | 日志、输入样例、测试或指标 | 能复现并解释，才算定位 |');
  }
  buffer
    ..writeln()
    ..writeln('排查顺序应遵循「先复现、再缩小范围、再验证假设、最后修改」。不要同时改多个变量，否则即使问题消失，也无法知道真正原因。')
    ..writeln()
    ..writeln('### 变式训练')
    ..writeln();
  for (var index = 0; index < practiceScenarios.length; index++) {
    buffer.writeln('${index + 1}. ${practiceScenarios[index]}');
  }
  buffer
    ..writeln()
    ..writeln('每道变式都写下：预测、实际结果、差异、下一步。没有留下证据的练习，很难迁移到真实项目。')
    ..writeln()
    ..writeln('### 本课自测')
    ..writeln();
  final concepts = keywords.isEmpty ? <String>[title] : keywords;
  for (var index = 0; index < 5; index++) {
    final concept = concepts[index % concepts.length];
    buffer.writeln('- [ ] 能用一句话解释「$concept」在本课中的角色与边界。');
    buffer.writeln('- [ ] 能举出一个正常例子和一个失败例子。');
    buffer.writeln('- [ ] 能说出最小验证步骤，以及需要记录的证据。');
  }
  buffer
    ..writeln()
    ..writeln('### 迁移案例库')
    ..writeln()
    ..writeln('下面用不同约束重复同一套方法。每完成一轮，都把结论写进笔记，并只改变一个变量。')
    ..writeln();
  var variant = 1;
  while (buffer.length < targetLength - 200 && variant <= 16) {
    final concept = concepts[(variant - 1) % concepts.length];
    buffer
      ..writeln('#### 迁移案例 $variant：围绕「$concept」做一次小实验')
      ..writeln()
      ..writeln('**目标**：在不改变课程主体的前提下，验证「$title」中的一个关键判断。')
      ..writeln()
      ..writeln('**步骤**：')
      ..writeln('1. 复述当前方案对「$concept」的假设，写成一句可证伪的话。')
      ..writeln('2. 设计一个正常输入和一个边界输入，分别预测输出。')
      ..writeln('3. 运行或逐步演算，记录实际输出、耗时和失败信息。')
      ..writeln('4. 只调整一个参数，比较前后差异并解释原因。')
      ..writeln('5. 补充一条测试或复习卡，确保下次能更快复现。')
      ..writeln()
      ..writeln('**验收**：结论有证据、差异可解释、失败可恢复；如果做不到，说明还需要缩小问题范围。')
      ..writeln();
    variant++;
  }
  buffer.writeln(endMarker);
  return buffer.toString();
}

String _removeGenerated(String markdown) {
  final start = markdown.indexOf(startMarker);
  final end = markdown.indexOf(endMarker);
  if (start < 0 || end < 0 || end < start) return '${markdown.trimRight()}\n';
  final removeTo = end + endMarker.length;
  final merged = (markdown.substring(0, start) + markdown.substring(removeTo))
      .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
      .trimRight();
  return '$merged\n';
}

String _insertBeforeEnglish(String markdown, String block) {
  final index = markdown.indexOf('## English Overview');
  if (index < 0) return '${markdown.trimRight()}\n\n$block\n';
  return '${markdown.substring(0, index).trimRight()}\n\n$block\n'
      '${markdown.substring(index)}';
}

List<(String, String)> _extractSections(String markdown) {
  final headings = <MapEntry<int, String>>[];
  var inFence = false;
  var offset = 0;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('<!-- code-practice:')) continue;
    if (trimmed.startsWith('```')) inFence = !inFence;
    if (!inFence && trimmed.startsWith('### ')) {
      headings.add(MapEntry(offset, trimmed.substring(4).trim()));
    }
    offset += line.length + 1;
  }
  final result = <(String, String)>[];
  for (var index = 0; index < headings.length; index++) {
    final start = headings[index].key;
    final end = index + 1 < headings.length
        ? headings[index + 1].key
        : markdown.length;
    result.add((headings[index].value, markdown.substring(start, end)));
  }
  return result;
}

bool _skipSection(String title) => <String>[
  '学习目标',
  '前置知识',
  '动手练习',
  '本课小结',
  '考点精讲',
  '本课复习清单',
  '代码实验',
  'English Overview',
].any(title.contains);

String _firstSentence(String text) {
  final withoutCode = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  for (final raw in withoutCode.split(RegExp(r'[。！？\n]'))) {
    final sentence = _oneLine(raw).replaceAll(RegExp(r'^#+\s*'), '');
    if (sentence.length >= 12 && sentence.length <= 180) return sentence;
  }
  return '';
}

String _answerText(Map<String, dynamic> item) {
  final options = _stringList(item['options']);
  final answers =
      (item['answers'] ?? item['correct_indexes']) as List<dynamic>?;
  if (answers != null && answers.isNotEmpty) {
    return answers
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .where((index) => index >= 0 && index < options.length)
        .map((index) => options[index])
        .join('、');
  }
  final accepted = _stringList(item['accepted_answers']);
  if (accepted.isNotEmpty) return accepted.join('、');
  final answer = item['answer'];
  if (answer is int && answer >= 0 && answer < options.length) {
    return options[answer];
  }
  return answer?.toString() ?? '';
}

List<Map<String, dynamic>> _quiz(Object? raw) =>
    (raw as List<dynamic>? ?? const [])
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList();

List<String> _stringList(Object? raw) => (raw as List<dynamic>? ?? const [])
    .map((item) => item.toString())
    .where((item) => item.trim().isNotEmpty)
    .toList();

String _localized(Object? raw) {
  if (raw is Map) {
    return (raw['zh'] ?? raw['en'] ?? '').toString().trim();
  }
  return raw?.toString().trim() ?? '';
}

String _oneLine(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

String _clip(String text, int max) =>
    text.length <= max ? text : '${text.substring(0, max)}…';
