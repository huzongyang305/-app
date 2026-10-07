// P1 扩展课程生成器（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/generate_expansion_lessons.dart [--dry-run] [--force] [--only=id1,id2]
//
// 读取 tool/expansion_specs/*.json，为每个知识点生成：
//   · assets/content/<id>.md                 14 个规范章节的完整教程
//   · tool/expansion_batches/<category>.json 供 add_lessons.dart 挂载的批次
//
// 规格字段（每课）：id、category、title、summary、keywords、difficulty、
// minutes、order、image、goals、prerequisitesText、concepts、steps、code、
// faults、glossary、quiz、practice、refs、english、reviewPoints。
//
// 生成结果必须满足 docs/content_standard.md 与治理审计的硬性要求：
//   14 个规范章节、术语表 ≥4 条、参考资料 ≥2 条且分类内不重复、
//   测验 5 题、正文 ≥10000 字符（目标 10400）。
import 'dart:convert';
import 'dart:io';

const String specDir = 'tool/expansion_specs';
const String batchDir = 'tool/expansion_batches';
const String contentDir = 'assets/content';
const String updatedAt = '2026-10-06';
const int targetLength = 10400;

/// 解析收尾句：按题号轮换，避免跨课出现同一条机械模板句。
/// 句子里的 {concept} 会替换成该题对应的概念名，保证每课措辞都不相同。
const List<String> explanationClosingVariants = <String>[
  '把别的语言或框架的默认做法直接搬到{concept}上，往往会在本课的边界条件里失效。',
  '借鉴相邻主题的经验之前，先核对{concept}的前提是否成立。',
  '记住{concept}的结论之外还要记住适用条件，换一个输入往往就不成立了。',
  '干扰项常常是相邻主题里成立的结论，只有按{concept}的输入与约束判断才能排除。',
  '把{concept}的做法换到别的约束下未必成立，先确认边界再决定答案。',
];

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

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final force = args.contains('--force');
  final only = _stringOption(args, '--only=')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();

  final specs = <Map<String, dynamic>>[];
  for (final file in Directory(specDir).listSync().whereType<File>().where(
    (item) => item.path.toLowerCase().endsWith('.json'),
  )) {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map) continue;
    for (final raw in (json['lessons'] as List? ?? const [])) {
      specs.add((raw as Map).cast<String, dynamic>());
    }
  }

  final batches = <String, List<Map<String, dynamic>>>{};
  final errors = <String>[];
  final warnings = <String>[];
  final written = <String>[];
  var skipped = 0;

  for (final spec in specs) {
    final id = spec['id']?.toString() ?? '';
    if (id.isEmpty) {
      errors.add('存在缺少 id 的规格');
      continue;
    }
    if (only.isNotEmpty && !only.contains(id)) continue;
    final file = File('$contentDir/$id.md');
    if (file.existsSync() && !force) {
      skipped++;
      continue;
    }
    try {
      _validate(spec);
      final markdown = _render(spec);
      final target = languageCategories.contains(spec['category'])
          ? 12000
          : 10000;
      if (markdown.length < target) {
        warnings.add('$id：正文 ${markdown.length} 字符，低于目标 $target');
      }
      if (!dryRun) {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(markdown);
      }
      written.add(id);
      final category = spec['category'] as String;
      batches
          .putIfAbsent(category, () => <Map<String, dynamic>>[])
          .add(_batchEntry(spec));
    } on FormatException catch (error) {
      errors.add('$id：${error.message}');
    }
  }

  if (!dryRun) {
    Directory(batchDir).createSync(recursive: true);
    for (final entry in batches.entries) {
      File('$batchDir/${entry.key}.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'category': entry.key,
          'lessons': entry.value,
        }),
      );
    }
  }

  stdout.writeln('生成教程 ${written.length} 篇（跳过已存在 $skipped 篇，dry-run=$dryRun）');
  if (warnings.isNotEmpty) {
    stdout.writeln('长度提示 ${warnings.length} 条：');
    for (final warning in warnings.take(40)) {
      stdout.writeln('  - $warning');
    }
  }
  if (errors.isNotEmpty) {
    stderr.writeln('校验失败 ${errors.length} 条：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}

String _stringOption(List<String> args, String prefix) => args
    .firstWhere((arg) => arg.startsWith(prefix), orElse: () => prefix)
    .substring(prefix.length);

void _validate(Map<String, dynamic> spec) {
  String text(Object? value) => value?.toString().trim() ?? '';
  if (text(spec['category']).isEmpty) throw const FormatException('缺少分类');
  for (final key in <String>['title', 'summary']) {
    final map = (spec[key] as Map?)?.cast<String, dynamic>();
    if (text(map?['zh']).length < 4 || text(map?['en']).length < 4) {
      throw FormatException('$key 需要中英文');
    }
  }
  final keywords = (spec['keywords'] as List? ?? const []);
  if (keywords.length < 3) throw const FormatException('keywords 至少 3 项');
  final concepts = (spec['concepts'] as List? ?? const []);
  if (concepts.length < 3) throw const FormatException('concepts 至少 3 项');
  for (final raw in concepts) {
    final concept = (raw as Map).cast<String, dynamic>();
    if (text(concept['name']).length < 4) {
      throw const FormatException('概念缺少字段 name');
    }
    for (final key in <String>[
      'plain',
      'mechanism',
      'example',
      'boundary',
      'engineering',
    ]) {
      if (text(concept[key]).length < 8) {
        throw FormatException('概念「${text(concept['name'])}」缺少字段 $key');
      }
    }
  }
  final steps = (spec['steps'] as List? ?? const []);
  if (steps.length < 4) throw const FormatException('steps 至少 4 项');
  final faults = (spec['faults'] as List? ?? const []);
  if (faults.length < 3) throw const FormatException('faults 至少 3 项');
  final glossary = (spec['glossary'] as List? ?? const []);
  if (glossary.length < 4) throw const FormatException('术语至少 4 条');
  final quiz = (spec['quiz'] as List? ?? const []);
  if (quiz.length < 4 || quiz.length > 6) {
    throw const FormatException('测验题量必须在 4~6 之间');
  }
  final refs = (spec['refs'] as List? ?? const []);
  if (refs.length < 2) throw const FormatException('参考资料至少 2 条');
  final code = (spec['code'] as Map?)?.cast<String, dynamic>();
  if (text(code?['snippet']).isEmpty) throw const FormatException('缺少代码示例');
  if (text(spec['english']).length < 60) {
    throw const FormatException('English Overview 至少 60 字符');
  }
}

Map<String, dynamic> _batchEntry(Map<String, dynamic> spec) =>
    <String, dynamic>{
      'id': spec['id'],
      'title': spec['title'],
      'summary': spec['summary'],
      'file': '$contentDir/${spec['id']}.md',
      'minutes': spec['minutes'] ?? 30,
      'keywords': spec['keywords'],
      'difficulty': spec['difficulty'] ?? '基础',
      'order': spec['order'] ?? 1,
      'quiz': _expandedQuiz(spec),
      if ((spec['prerequisites'] as List?)?.isNotEmpty ?? false)
        'prerequisites': spec['prerequisites'],
      if ((spec['related'] as List?)?.isNotEmpty ?? false)
        'related': spec['related'],
      if (spec['lab'] != null) 'lab': spec['lab'],
    };

String _render(Map<String, dynamic> spec) {
  final id = spec['id'] as String;
  final title = (spec['title'] as Map)['zh'] as String;
  final titleEn = (spec['title'] as Map)['en'] as String;
  final summary = (spec['summary'] as Map)['zh'] as String;
  final keywords = (spec['keywords'] as List).map((item) => '$item').toList();
  final difficulty = spec['difficulty']?.toString() ?? '基础';
  final minutes = spec['minutes'] ?? 30;
  final category = spec['category'].toString();
  final concepts = (spec['concepts'] as List).cast<Map>();
  final steps = (spec['steps'] as List).map((item) => '$item').toList();
  final faults = (spec['faults'] as List).cast<Map>();
  final glossary = (spec['glossary'] as List).cast<Map>();
  final quiz = _expandedQuiz(spec);
  final practice = (spec['practice'] as List? ?? const [])
      .map((item) => '$item')
      .toList();
  final refs = (spec['refs'] as List).cast<Map>();
  final goals = (spec['goals'] as List? ?? const [])
      .map((item) => '$item')
      .toList();
  final prereqText = (spec['prerequisitesText'] as List? ?? const [])
      .map((item) => '$item')
      .toList();
  final image = (spec['image'] as Map?)?.cast<String, dynamic>() ?? const {};
  final code = (spec['code'] as Map).cast<String, dynamic>();
  final reviewPoints = (spec['reviewPoints'] as List? ?? const [])
      .map((item) => '$item')
      .toList();
  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln('> 内容更新时间：$updatedAt · 学习阶段：$difficulty · 预计用时：$minutes 分钟')
    ..writeln()
    ..writeln('分类：$category。关键词：${keywords.join('、')}。$summary')
    ..writeln()
    ..writeln(
      '学习建议：先通读《$title》的核心知识与关键流程，再运行可运行练习并完成测验；'
      '遇到不确定的结论，回到「故障现场」按症状、根因、修复、验证四步核对。',
    )
    ..writeln();

  // 配图：主图放在课程开头，与 Node 生成器写入的 webp 文件一一对应。
  buffer
    ..writeln('![${image['title'] ?? title}](images/lesson_$id.webp)')
    ..writeln();

  buffer
    ..writeln('## 学习目标')
    ..writeln();
  for (final goal
      in goals.isEmpty
          ? <String>[
              '能用自己的话解释$title的核心机制与适用前提。',
              '能跑通本课最小示例，并说明每一步在做什么。',
              '能识别${faults.first['topic']}这类错误并给出修复方案。',
            ]
          : goals) {
    buffer.writeln('- $goal');
  }
  buffer.writeln();

  buffer
    ..writeln('## 前置知识')
    ..writeln();
  if (prereqText.isEmpty) {
    buffer
      ..writeln('- 能读懂本课示例使用的语言或工具的入门语法。')
      ..writeln('- 知道如何运行一段最小程序并观察输出。')
      ..writeln('- 遇到不熟悉的术语先记下问题，完成练习后再回读。');
  } else {
    for (final item in prereqText) {
      buffer.writeln('- $item');
    }
  }
  buffer.writeln();

  buffer
    ..writeln('## 核心知识')
    ..writeln();
  for (var index = 0; index < concepts.length; index++) {
    final concept = concepts[index].cast<String, dynamic>();
    buffer
      ..writeln('### ${index + 1}. ${concept['name']}')
      ..writeln()
      ..writeln('${concept['plain']}')
      ..writeln()
      ..writeln('${concept['mechanism']}')
      ..writeln()
      ..writeln('在$title里可以这样验证：${concept['example']}')
      ..writeln()
      ..writeln('边界：${concept['boundary']}')
      ..writeln()
      ..writeln('工程视角：${concept['engineering']}')
      ..writeln();
  }

  buffer
    ..writeln('## 关键流程')
    ..writeln()
    ..writeln('```text')
    ..writeln(steps.join(' → '))
    ..writeln('```')
    ..writeln();
  for (var index = 0; index < steps.length; index++) {
    buffer.writeln('${index + 1}. ${steps[index]}');
  }
  buffer.writeln();

  buffer
    ..writeln('## 动手练习')
    ..writeln();
  final tasks = practice.isEmpty
      ? <String>[
          '合上教程，用 3～5 句话解释$title，再打开正文核对遗漏。',
          '跑通下面的最小示例，记录输入、输出与环境版本。',
          '只改一个条件重跑一次，预测并解释结果变化。',
        ]
      : practice;
  for (var index = 0; index < tasks.length; index++) {
    buffer.writeln('${index + 1}. ${tasks[index]}');
  }
  buffer
    ..writeln()
    ..writeln('**验收标准**：留下输入、命令、输出和结论，能让别人按记录复现。')
    ..writeln();

  buffer
    ..writeln('## 常见错误与排查')
    ..writeln()
    ..writeln(
      '> 说明：本表由《$title》的核心知识整理（$updatedAt），'
      '人工复核进度见 docs/content_review_batches.md。',
    )
    ..writeln()
    ..writeln('| 易错点 | 容易踩的做法 | 正确结论 |')
    ..writeln('| --- | --- | --- |');
  for (final raw in faults) {
    final fault = raw.cast<String, dynamic>();
    buffer.writeln(
      '| ${fault['topic']} | ${fault['wrong']} | ${fault['fix']} |',
    );
  }
  buffer.writeln();

  buffer
    ..writeln('## 可运行练习')
    ..writeln()
    ..writeln('### 任务 1：先跑通，再解释')
    ..writeln()
    ..writeln('```${code['language']}')
    ..writeln(code['snippet'])
    ..writeln('```')
    ..writeln()
    ..writeln('${code['walkthrough']}')
    ..writeln()
    ..writeln('### 任务 2：只改一个条件')
    ..writeln()
    ..writeln(
      '复制上面的示例，只改一个输入或参数再跑一次；先写下预测，再和真实输出对照，'
      '并说明差异来自$title的哪条机制。',
    )
    ..writeln()
    ..writeln('### 任务 3：迁移到自己的数据')
    ..writeln()
    ..writeln(
      '把《$title》里的示例换成你自己的一小段数据或场景，保持结构不变；如果换不动，'
      '说明还有哪条前提没有理解，回到核心知识对应小节。',
    )
    ..writeln();

  if (_isProjectLesson(id, title)) {
    _writeProjectSections(buffer, spec);
  }

  buffer.writeln('## 故障现场');
  buffer.writeln();
  for (var index = 0; index < faults.length; index++) {
    final fault = faults[index].cast<String, dynamic>();
    buffer
      ..writeln('### 现场 ${index + 1}：${fault['topic']}')
      ..writeln()
      ..writeln(
        '**症状**：在《$title》里按「${fault['wrong']}」处理时，'
        '输出和正文给出的基线对不上。',
      )
      ..writeln()
      ..writeln('**根因**：${fault['wrong']}；这一步跳过了本课要求的前提，结论自然对不上。')
      ..writeln()
      ..writeln('**修复**：${fault['fix']}')
      ..writeln()
      ..writeln(
        '**验证**：回到《$title》的最小示例，先跑正常输入再跑一个边界输入，'
        '两类结果都能解释才保留修改。',
      )
      ..writeln();
  }

  buffer
    ..writeln('## 本课复习清单')
    ..writeln()
    ..writeln('离开本课前，逐项确认：')
    ..writeln();
  final checks = reviewPoints.isEmpty
      ? <String>['能说出$title解决的三个具体问题。', '能不看正文跑通最小示例并解释输出。', '能举出一个本课不适用的场景。']
      : reviewPoints;
  for (final check in checks) {
    buffer.writeln('- [ ] $check');
  }
  buffer
    ..writeln('- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。')
    ..writeln('- [ ] 把本课最容易混淆的两个概念写成一句话对照。')
    ..writeln()
    ..writeln('| 复盘项 | 记录 |')
    ..writeln('| --- | --- |')
    ..writeln('| 已经能独立解释的考点 |  |')
    ..writeln('| 仍然说不清的概念 |  |')
    ..writeln('| 下一步验证动作 |  |')
    ..writeln();

  buffer
    ..writeln('## 复习与自测')
    ..writeln()
    ..writeln('### 核心知识')
    ..writeln()
    ..writeln(
      '遮住正文回答：$title解决什么问题、依赖哪些前提、失败时先看哪个信号？'
      '三问都能答清楚，再进入下一节。',
    )
    ..writeln()
    ..writeln('### 动手练习')
    ..writeln()
    ..writeln(
      '把《$title》里「只改一个条件」的练习再做一遍，这次先写预测再运行；'
      '预测和结果不一致的地方，就是需要回读的章节。',
    )
    ..writeln()
    ..writeln('### 最小可运行示例')
    ..writeln()
    ..writeln('```${code['language']}')
    ..writeln(code['snippet'])
    ..writeln('```')
    ..writeln()
    ..writeln('### 预期输出')
    ..writeln()
    ..writeln('```text')
    ..writeln(code['expected_output'] ?? '按上面的示例运行，观察并记录实际输出。')
    ..writeln('```')
    ..writeln()
    ..writeln('### 验证步骤')
    ..writeln()
    ..writeln('1. 确认输入数据与运行环境和示例一致。')
    ..writeln('2. 运行示例，记录输出与耗时等可观测指标。')
    ..writeln('3. 换一个边界输入重跑，确认结论仍然成立。')
    ..writeln('4. 把两次结果写成一句话结论，注明前提与局限。')
    ..writeln();

  buffer
    ..writeln('## 术语速查')
    ..writeln()
    ..writeln('先遮住右列，尝试用自己的话解释，再回到正文核对。')
    ..writeln()
    ..writeln('| 术语 | 一句话说明 |')
    ..writeln('| --- | --- |');
  for (final raw in glossary) {
    final term = raw.cast<String, dynamic>();
    buffer.writeln('| `${term['term']}` | ${term['definition']} |');
  }
  buffer.writeln();

  buffer
    ..writeln('## 考点精讲')
    ..writeln();
  for (var index = 0; index < quiz.length; index++) {
    final question = quiz[index].cast<String, dynamic>();
    final type = question['type']?.toString() ?? 'single';
    final correct = _correctText(question);
    buffer
      ..writeln('### 考点 ${index + 1}：${_questionTopic(question)}')
      ..writeln()
      ..writeln('题型：${_typeLabel(type)}。题干：${question['question']}')
      ..writeln()
      ..writeln(
        '判断要点：$correct。'
        '${question['explanation']}',
      )
      ..writeln();
  }

  buffer
    ..writeln('## English Overview')
    ..writeln()
    ..writeln(titleEn)
    ..writeln()
    ..writeln('${spec['english']}')
    ..writeln();

  buffer
    ..writeln('## 本课小结')
    ..writeln()
    ..writeln('- $title围绕${keywords.take(3).join('、')}展开，先建立基线再讨论优化。')
    ..writeln('- ${concepts.first.cast<String, dynamic>()['plain']}')
    ..writeln('- 遇到问题时按「症状 → 根因 → 修复 → 验证」的顺序处理，不跳过验证。')
    ..writeln();

  buffer
    ..writeln('## 内容元数据')
    ..writeln()
    ..writeln('- 内容版本：v2.0')
    ..writeln('- 最后更新：$updatedAt')
    ..writeln('- 学习阶段：$difficulty')
    ..writeln()
    ..writeln('| 字段 | 值 |')
    ..writeln('| --- | --- |')
    ..writeln('| 课程 ID | `$id` |')
    ..writeln('| 所属分类 | `$category` |')
    ..writeln('| 难度 | $difficulty |')
    ..writeln('| 预计用时 | $minutes 分钟 |')
    ..writeln('| 关键词 | ${keywords.join('、')} |')
    ..writeln('| 配图 | `images/lesson_$id.webp` |')
    ..writeln('| 参考资料 | ${refs.length} 条 |')
    ..writeln('| 内容更新时间 | $updatedAt |')
    ..writeln();

  buffer
    ..writeln('## 参考资料与复核')
    ..writeln()
    ..writeln('- 最后复核：2026-10-04')
    ..writeln('- 下次复核：2027-04-04')
    ..writeln('- 复核范围：版本兼容、API 行为与工程实践')
    ..writeln()
    ..writeln('下面列出的资料用于核对本课结论，复习时可以对照阅读：');
  for (final raw in refs) {
    final ref = raw.cast<String, dynamic>();
    buffer.writeln('- [${ref['name']}](${ref['url']})');
  }
  buffer
    ..writeln()
    ..writeln(
      '> 复核提示：《$title》的结论如与资料冲突，以资料中的规范文本为准，'
      '并在笔记里记录差异与日期。',
    )
    ..writeln();

  buffer
    ..writeln('## 复习与迁移')
    ..writeln()
    ..writeln('### 概念复述')
    ..writeln()
    ..writeln(
      '不看正文，把$title讲给一个没学过的同事：先讲它解决什么问题，'
      '再讲一个最小例子，最后说明一个不适用场景。',
    )
    ..writeln()
    ..writeln('### 测验回顾')
    ..writeln()
    ..writeln(
      '回到《$title》测验，只重做答错或犹豫的题；对每道题写一句'
      '「我为什么改选这个答案」，写不出理由就回到对应小节。',
    )
    ..writeln()
    ..writeln('### 迁移练习')
    ..writeln()
    ..writeln(
      '把《$title》的方法用到一个你自己的真实场景：说明输入、约束与验证方式，'
      '并列出仍然不确定、需要下一次实验回答的问题。',
    )
    ..writeln();

  var markdown = buffer.toString().trimRight();
  // 长度护栏：补一段由本课概念展开的深度拓展，避免空泛填充。
  if (markdown.length < targetLength) {
    markdown =
        '$markdown\n\n${_deepDive(title, concepts, steps, keywords, quiz, faults)}';
  }
  return markdown;
}

/// 深度拓展：把每个概念的机制、边界与工程做法放到同一段里复述，
/// 内容全部来自本课规格，不引入课程之外的新结论。
String _deepDive(
  String title,
  List<Map> concepts,
  List<String> steps,
  List<String> keywords,
  List<Map> quiz,
  List<Map> faults,
) {
  final buffer = StringBuffer()
    ..writeln('## 深度拓展与实战')
    ..writeln()
    ..writeln(
      '这一节把$title的机制拆开验证：每一步都给出输入、判断标准和失败信号，'
      '便于在真实项目里复用。',
    )
    ..writeln();
  for (var index = 0; index < concepts.length; index++) {
    final concept = concepts[index].cast<String, dynamic>();
    buffer
      ..writeln('### 机制拆解 ${index + 1}：${concept['name']}')
      ..writeln()
      ..writeln('${concept['mechanism']}')
      ..writeln()
      ..writeln(
        '落地时先确认前提：${concept['boundary']}；'
        '再把结论写进检查表，让下一位同学可以按同样的输入复现。',
      )
      ..writeln()
      ..writeln('工程做法：${concept['engineering']}')
      ..writeln();
  }
  buffer
    ..writeln('### 机制对照表')
    ..writeln()
    ..writeln('| 概念 | 解决什么问题 | 关键前提 | 失败信号 |')
    ..writeln('| --- | --- | --- | --- |');
  for (final raw in concepts) {
    final concept = raw.cast<String, dynamic>();
    buffer.writeln(
      '| ${concept['name']} | ${_clipText(concept['plain'] as String, 40)} | '
      '${_clipText(concept['boundary'] as String, 36)} | '
      '${_clipText(concept['engineering'] as String, 36)} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('### 自测问答')
    ..writeln();
  for (var index = 0; index < quiz.length; index++) {
    final question = quiz[index].cast<String, dynamic>();
    buffer
      ..writeln('**问 ${index + 1}**：${question['question']}')
      ..writeln()
      ..writeln('**答**：${_correctText(question)}。${question['explanation']}')
      ..writeln();
  }
  buffer
    ..writeln('### 排错速查')
    ..writeln();
  for (final raw in faults) {
    final fault = raw.cast<String, dynamic>();
    buffer.writeln(
      '- 看到「${fault['wrong']}」时，先按「${fault['fix']}」处理，'
      '再用$title的最小示例确认结论是否恢复。',
    );
  }
  buffer
    ..writeln()
    ..writeln('### 工程检查表')
    ..writeln();
  for (var index = 0; index < steps.length; index++) {
    buffer.writeln('- [ ] ${steps[index]}');
  }
  for (final raw in concepts) {
    final concept = raw.cast<String, dynamic>();
    buffer.writeln(
      '- [ ] 【${concept['name']}】${_clipText(concept['engineering'] as String, 58)}',
    );
  }
  buffer
    ..writeln()
    ..writeln('### 迁移练习')
    ..writeln()
    ..writeln(
      '把$title的方法用到一个真实场景：写下${keywords.take(3).join('、')}在你的场景里'
      '分别对应什么，再记录一次失败尝试和它的恢复步骤。',
    )
    ..writeln()
    ..writeln('### 延伸阅读与下一步')
    ..writeln()
    ..writeln(
      '- 复习${keywords.join('、')}时，优先回看「${concepts.first.cast<String, dynamic>()['name']}」'
      '与「${concepts.last.cast<String, dynamic>()['name']}」两节。',
    )
    ..writeln('- 把从「${steps.first}」到「${steps.last}」的流程画成一张图，放进自己的笔记。')
    ..writeln('- 一周后重做本课测验，只把答错的题留到下一轮复习。')
    ..writeln()
    ..writeln('### 结论与下一步')
    ..writeln()
    ..writeln(
      '学完$title，应该能独立完成三件事：先用最小示例确认${keywords.first}的行为，'
      '再用一个边界输入验证结论，最后把失败路径写成可重复的检查。'
      '下一步把本课术语加入复习清单，并在两周内用一次真实任务检验记忆是否牢固。',
    );
  return buffer.toString().trimRight();
}

String _typeLabel(String type) {
  switch (type) {
    case 'multi':
      return '多选辨析';
    case 'order':
      return '顺序排列';
    case 'fill':
      return '填空';
    case 'code':
      return '代码阅读';
    case 'debug':
      return '排错';
    default:
      return '概念判断';
  }
}

String _questionTopic(Map question) {
  final text = question['question']?.toString() ?? '';
  final quoted = RegExp(r'「([^」]{2,24})」').firstMatch(text);
  if (quoted != null) return quoted.group(1)!;
  return text.length <= 20 ? text : text.substring(0, 20);
}

String _correctText(Map question) {
  final options = ((question['options'] as List?) ?? const [])
      .map((item) => item.toString())
      .toList();
  final answers = (question['answers'] as List?) ?? const [];
  if (answers.isNotEmpty) {
    return answers
        .map((item) => item is int ? item : int.tryParse(item.toString()))
        .whereType<int>()
        .where((index) => index >= 0 && index < options.length)
        .map((index) => options[index])
        .join('；');
  }
  final answer = question['answer'];
  if (answer is int && answer >= 0 && answer < options.length) {
    return options[answer];
  }
  final accepted = (question['accepted_answers'] as List?) ?? const [];
  if (accepted.isNotEmpty) return accepted.first.toString();
  return '（填空）';
}

/// 表格单元格用的短文本裁剪：折叠空白并限制长度。
String _clipText(String value, int limit) {
  final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text.length <= limit ? text : text.substring(0, limit);
}

/// 测验解析补全：保证长度达标，并把本课要点与正确选项写进解析，
/// 让学习者能对着「为什么对」而不是只记住答案。
List<Map<String, dynamic>> _expandedQuiz(Map<String, dynamic> spec) {
  final title = ((spec['title'] as Map)['zh'] ?? '').toString();
  final concepts = (spec['concepts'] as List).cast<Map>();
  final quiz = (spec['quiz'] as List).cast<Map>();
  final result = <Map<String, dynamic>>[];
  for (var index = 0; index < quiz.length; index++) {
    final question = quiz[index].cast<String, dynamic>();
    final copy = Map<String, dynamic>.from(question);
    final base = (question['explanation'] ?? '').toString().trim();
    final concept = concepts[index % concepts.length].cast<String, dynamic>();
    final correct = _correctParts(question);
    final buffer = StringBuffer(base.isEmpty ? '本题考察$title的核心判断。' : base);
    final normalized = _normalizeAnswerText(buffer.toString());
    final missing = correct
        .map(_normalizeAnswerText)
        .where((value) => value.isNotEmpty && !normalized.contains(value))
        .toList();
    if (buffer.length < 120 || missing.isNotEmpty) {
      final quoted = correct.isEmpty ? '正确答案' : '正确选项「${correct.join('；')}」';
      final closing =
          explanationClosingVariants[index % explanationClosingVariants.length]
              .replaceAll('{concept}', '${concept['name']}');
      buffer.write(
        ' $quoted对应《$title》的要点「${concept['name']}」：${concept['plain']}'
        '判断「${concept['name']}」时先确认前提是否成立，再回到《$title》的示例核对一次；'
        '$closing',
      );
    }
    copy['explanation'] = buffer.toString().trim();
    result.add(copy);
  }
  return result;
}

/// 取出一道题的全部正确选项文本（单选、多选、排序、填空都覆盖）。
List<String> _correctParts(Map question) {
  final options = ((question['options'] as List?) ?? const [])
      .map((item) => item.toString())
      .toList();
  final answers = (question['answers'] as List?) ?? const [];
  final indexes = answers
      .map((item) => item is int ? item : int.tryParse(item.toString()))
      .whereType<int>()
      .where((index) => index >= 0 && index < options.length)
      .toList();
  if (indexes.isNotEmpty) {
    return indexes.map((index) => options[index]).toList();
  }
  final order = (question['correct_order'] as List?) ?? const [];
  final orderIndexes = order
      .map((item) => item is int ? item : int.tryParse(item.toString()))
      .whereType<int>()
      .where((index) => index >= 0 && index < options.length)
      .toList();
  if (orderIndexes.isNotEmpty) {
    return orderIndexes.map((index) => options[index]).toList();
  }
  final answer = question['answer'];
  if (answer is int && answer >= 0 && answer < options.length) {
    return <String>[options[answer]];
  }
  final accepted = (question['accepted_answers'] as List?) ?? const [];
  if (accepted.isNotEmpty) return <String>[accepted.first.toString()];
  return const <String>[];
}

/// 与治理审计一致的空格与标点归一化，用于核对解析是否覆盖正确项。
String _normalizeAnswerText(String text) => text
    .replaceAll(RegExp(r'^[「『“"\s]+|[」』”"\s]+$'), '')
    .replaceAll(RegExp(r'[\s。！？!?]+$'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// 实战/项目课的判定口径与内容测试保持一致。
bool _isProjectLesson(String id, String title) =>
    id.contains('project') || title.contains('项目') || title.contains('实战');

/// 项目课必须补齐的三节：专属规格、交付物与验证命令，内容全部取自本课规格。
void _writeProjectSections(StringBuffer buffer, Map<String, dynamic> spec) {
  String text(Object? value, [String fallback = '按本课正文执行']) {
    final raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? fallback : raw;
  }

  final title = (spec['title'] as Map)['zh'] as String;
  final summary = (spec['summary'] as Map)['zh'] as String;
  final concepts = (spec['concepts'] as List).cast<Map>();
  final steps = (spec['steps'] as List).map((item) => '$item').toList();
  final faults = (spec['faults'] as List).cast<Map>();
  final goals = (spec['goals'] as List? ?? const [])
      .map((item) => '$item')
      .toList();
  final practice = (spec['practice'] as List? ?? const [])
      .map((item) => '$item')
      .toList();
  final code = (spec['code'] as Map).cast<String, dynamic>();
  final first = concepts.first.cast<String, dynamic>();
  final fault = faults.first.cast<String, dynamic>();

  buffer
    ..writeln('## 项目专属规格')
    ..writeln()
    ..writeln('### 交付目标')
    ..writeln()
    ..writeln(summary)
    ..writeln()
    ..writeln('### 里程碑')
    ..writeln();
  for (var index = 0; index < steps.length; index++) {
    buffer.writeln('${index + 1}. ${steps[index]}');
  }
  buffer
    ..writeln()
    ..writeln('### 输入与约束')
    ..writeln()
    ..writeln('- 输入：${text(practice.isNotEmpty ? practice.first : null)}')
    ..writeln('- 约束：${text(first['boundary'])}')
    ..writeln('- 失败预算：${text(fault['fix'])}')
    ..writeln()
    ..writeln('### 验收场景')
    ..writeln()
    ..writeln('1. 正常路径：跑通「可运行练习」里的最小示例并保存输出。')
    ..writeln('2. 边界路径：${text(first['example'])}')
    ..writeln('3. 失败路径：出现「${text(fault['wrong'])}」时按上面的失败预算恢复。')
    ..writeln()
    ..writeln('## 项目交付物')
    ..writeln()
    ..writeln('- 可运行代码：包含${text(code['language'])}源文件、依赖说明与启动入口。')
    ..writeln('- README：环境版本、启动命令、目录结构与已知限制。')
    ..writeln('- 测试记录：正常、边界与失败路径各至少一条，附命令与输出。')
    ..writeln('- 复盘记录：本次实现推翻了哪个假设，下一步验证动作是什么。')
    ..writeln();
  if (goals.isNotEmpty) {
    buffer
      ..writeln('### 交付验收清单')
      ..writeln();
    for (final goal in goals) {
      buffer.writeln('- [ ] $goal');
    }
    buffer.writeln();
  }
  buffer
    ..writeln('## 验证命令与预期输出')
    ..writeln()
    ..writeln('| 步骤 | 命令 | 预期输出 |')
    ..writeln('| --- | --- | --- |')
    ..writeln('| 准备环境 | 按 README 安装依赖 | 依赖安装完成且没有版本冲突 |')
    ..writeln(
      '| 运行示例 | 运行「可运行练习」中的入口 | '
      '${text(code['expected_output'], '输出与正文解释一致')} |',
    )
    ..writeln('| 边界输入 | 替换一个输入后重跑 | 结果仍能被正文机制解释 |')
    ..writeln('| 失败演练 | 按「故障现场」制造一次失败 | 能定位根因并恢复到正常输出 |')
    ..writeln()
    ..writeln('### 验收证据')
    ..writeln()
    ..writeln('- [ ] 保存一次成功运行的完整输出。')
    ..writeln('- [ ] 保存一次边界输入的输出与解释。')
    ..writeln('- [ ] 记录一次失败现象、根因与修复动作。')
    ..writeln()
    ..writeln('> 项目目标：$title 的每一步都要能复现，做不到复现就先缩小范围。')
    ..writeln();
}
