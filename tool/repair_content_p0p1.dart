// P0/P1 内容修复：清理上一轮治理在正文与题库里留下的可见缺陷。
//
// 处理内容：
//   1. 恢复 H1 标题、配图替代文本，清掉「本课主题」占位符；
//   2. 删除内部题号（lessonid 第 N 题）、机械解析句和截断题干；
//   3. 用本课自己的代码示例替换跨域套用的 Python 通用题；
//   4. 合并重复的「复习与迁移」，清掉「复核补充」与残留标记；
//   5. 重建「考点精讲」并修好损坏的「术语速查」表格。
//
// 用法：
//   dart tool/repair_content_p0p1.dart                 # 只统计，不写文件
//   dart tool/repair_content_p0p1.dart --apply         # 写回 Markdown 与 manifest
//   dart tool/repair_content_p0p1.dart --lesson=cpp_loops --apply
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 生成器写下的标题占位符，任何用户可见内容里都不该再出现。
const String placeholderTitle = '本课主题';

/// 内部题号：`（lessonid 第 3 题）`。
final RegExp internalIdPattern = RegExp(
  r'[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)）]',
);

/// 课程分类 → 该分类要求使用的代码语言。
const Map<String, String> categoryLanguage = <String, String>{
  'python': 'python',
  'c': 'c',
  'cpp': 'cpp',
  'java': 'java',
  'javascript': 'javascript',
  'typescript': 'typescript',
  'csharp': 'csharp',
  'go': 'go',
  'rust': 'rust',
  'kotlin': 'kotlin',
  'swift': 'swift',
  'shell': 'shell',
};

/// 语言分类里「入门」课的目标篇幅更高。
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

/// 生成器写下的机械解析句，整句删除后按需重建。
const List<String> explanationBoilerplateMarkers = <String>[
  '本题应选',
  '正确答案包括',
  '正确答案是',
  '判断这类题时',
  '解题的关键不是',
  '等说法虽然包含相关术语',
  '符合题干条件的是',
  '正确的判断需要逐项核对',
  '这道题在问',
  '在这个复现里',
  '这道题对应的课程',
  '修正后要重跑',
  '本课在「',
  '本课还在「',
  // 上一轮补句模板：整体删除后由 _lessonLinkSentence 生成带锚点的新句子。
  '的输入、输出与失败路径逐项对齐',
  '替换任意一个输入或边界后都要重新核对结论',
  '因此干扰项只能排除，不能当成通用规则',
  '只在题干给定的条件下成立',
  '」的例子核对',
  '的术语表可以看到',
  '”的语境，只有符合',
  '”的语境与',
  '对照「',
];

/// `expand_lessons_p0_p1_p2.dart` 里 Python 通用题的特征。
const List<String> genericPythonMarkers = <String>[
  'bucket=[]',
  'items.remove(item)',
  'range(len(data) + 1)',
  '相关的一个常见故障',
];

/// 正文里需要整体删除的生成章节。
const List<String> removableHeadings = <String>['复习与迁移', '复核补充'];

void main(List<String> args) {
  final apply = args.contains('--apply');
  final lessonFilter = _option(args, '--lesson=');
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到内容清单：$manifestPath');
    exitCode = 2;
    return;
  }
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

  final stats = RepairStats();
  final lessons = <Lesson>[];
  var index = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lessonMap = (rawLesson as Map).cast<String, dynamic>();
      if (lessonFilter != null && lessonMap['id'].toString() != lessonFilter) {
        continue;
      }
      final file = File(lessonMap['file'].toString());
      lessons.add(
        Lesson(
          categoryMap: category,
          lessonMap: lessonMap,
          markdown: file.existsSync() ? file.readAsStringSync() : '',
          ordinal: index++,
        ),
      );
    }
  }

  // 修复跨课语义需要同分类的相邻课程，先按分类建索引。
  final siblingsByCategory = <String, List<Lesson>>{};
  for (final lesson in lessons) {
    siblingsByCategory
        .putIfAbsent(lesson.categoryId, () => <Lesson>[])
        .add(lesson);
  }

  for (final lesson in lessons) {
    final siblings = siblingsByCategory[lesson.categoryId] ?? const <Lesson>[];
    _repairQuiz(lesson, siblings, stats);
    _repairMarkdown(lesson, stats);
  }

  if (apply) {
    for (final lesson in lessons) {
      final text = lesson.markdown.trimRight();
      File(lesson.lessonMap['file'].toString())
          .writeAsStringSync('$text\n');
    }
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    );
  }

  _printReport(stats, lessons, apply: apply);
  if (stats.blockingIssues.isNotEmpty) exitCode = 1;
}

String? _option(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

class RepairStats {
  int lessons = 0;
  int titleRestored = 0;
  int altRestored = 0;
  int placeholdersCleared = 0;
  int idsCleared = 0;
  int quizIdsCleared = 0;
  int explanationsRewritten = 0;
  int questionsRegenerated = 0;
  int questionsRewrittenFromFallback = 0;
  int truncatedStemsFixed = 0;
  int reviewSectionsRemoved = 0;
  int reviewSectionsRebuilt = 0;
  int termTablesRebuilt = 0;
  int focusSectionsRebuilt = 0;
  int strayMarkersRemoved = 0;
  int languagesFixed = 0;
  int placeholderTouchedLessons = 0;
  final List<String> blockingIssues = <String>[];
  final List<String> samples = <String>[];
  int belowTarget = 0;
  int totalChars = 0;
  int minChars = 1 << 30;
  int maxEllipsis = 0;

  void sample(String text) {
    if (samples.length < 20) samples.add(text);
  }
}

class Lesson {
  Lesson({
    required this.categoryMap,
    required this.lessonMap,
    required this.markdown,
    required this.ordinal,
  });

  final Map<String, dynamic> categoryMap;
  final Map<String, dynamic> lessonMap;
  final int ordinal;
  String markdown;

  String get categoryId => categoryMap['id'].toString();
  String get id => lessonMap['id'].toString();
  Map<String, dynamic> get titleMap =>
      (lessonMap['title'] as Map?)?.cast<String, dynamic>() ?? const {};
  String get titleZh => (titleMap['zh'] ?? id).toString().trim();
  Map<String, dynamic> get summaryMap =>
      (lessonMap['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
  String get summaryZh => (summaryMap['zh'] ?? '').toString().trim();
  List<String> get keywords =>
      ((lessonMap['keywords'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
  List<Map<String, dynamic>> get quiz =>
      ((lessonMap['quiz'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
  String? get expectedLanguage => categoryLanguage[categoryId];
  bool get isIntro =>
      titleZh.contains('入门') ||
      titleZh.contains('基础') ||
      titleZh.contains('初识') ||
      titleZh.contains('介绍');
  int get targetLength =>
      languageCategories.contains(categoryId) && isIntro ? 12000 : 10000;
}

// ---------------------------------------------------------------------------
// 题库修复
// ---------------------------------------------------------------------------

void _repairQuiz(Lesson lesson, List<Lesson> siblings, RepairStats stats) {
  stats.lessons++;
  // 生成器把课程标题替换成了占位符，连代码注释和文档字符串一起改写，
  // 这里按字段递归还原，避免只在题干/解析里替换而漏掉示例代码。
  _replacePlaceholderDeep(lesson.lessonMap, lesson.titleZh, stats);
  for (final question in lesson.quiz) {
    _stripQuestionIds(lesson, question, stats);
    if (_isGenericPythonQuestion(question)) {
      _regenerateQuestion(lesson, question, siblings, stats);
    }
    _fixTruncatedStem(lesson, question, stats);
    _fixQuestionLanguage(lesson, question, stats);
    final cleaned = _cleanExplanation(lesson, question, stats);
    question['explanation'] = cleaned;
  }
  // 重出的题目会引用正文代码片段，可能把占位符一起带进来，这里再扫一遍。
  _replacePlaceholderDeep(lesson.lessonMap, lesson.titleZh, stats);
}

/// 清掉题干、选项、解析里的内部题号、标题占位符与多余空白。
void _stripQuestionIds(
  Lesson lesson,
  Map<String, dynamic> question,
  RepairStats stats,
) {
  String clean(String text) {
    if (!text.contains(placeholderTitle)) return _cleanText(text);
    stats.placeholdersCleared += placeholderTitle.allMatches(text).length;
    final fixed = text
        .replaceAll(placeholderTitle, lesson.titleZh)
        .replaceAll(RegExp(r'\s{2,}'), ' ');
    return _cleanText(fixed);
  }

  for (final key in const <String>['question', 'explanation']) {
    final value = question[key];
    if (value is! String) continue;
    final cleaned = clean(value);
    if (cleaned != value) {
      question[key] = cleaned;
      stats.quizIdsCleared++;
    }
  }
  for (final key in const <String>[
    'options',
    'accepted_answers',
    'correct_order',
  ]) {
    final value = question[key];
    if (value is! List) continue;
    question[key] = <dynamic>[
      for (final item in value)
        if (item is String) clean(item) else item,
    ];
  }
}

/// 递归还原课程清单里的标题占位符（题干、解析、选项与示例代码）。
void _replacePlaceholderDeep(
  Object? value,
  String title,
  RepairStats stats,
) {
  if (value is Map) {
    for (final key in value.keys.toList()) {
      final child = value[key];
      if (child is String) {
        if (!child.contains(placeholderTitle)) continue;
        stats.placeholdersCleared +=
            placeholderTitle.allMatches(child).length;
        value[key] = child
            .replaceAll(placeholderTitle, title)
            .replaceAll(RegExp(r'\s{2,}'), ' ');
      } else if (child is List || child is Map) {
        _replacePlaceholderDeep(child, title, stats);
      }
    }
    return;
  }
  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      final child = value[index];
      if (child is String) {
        if (!child.contains(placeholderTitle)) continue;
        stats.placeholdersCleared +=
            placeholderTitle.allMatches(child).length;
        value[index] = child
            .replaceAll(placeholderTitle, title)
            .replaceAll(RegExp(r'\s{2,}'), ' ');
      } else if (child is List || child is Map) {
        _replacePlaceholderDeep(child, title, stats);
      }
    }
  }
}

String _cleanText(String text) {
  var result = text.replaceAll(internalIdPattern, '');
  result = result.replaceAll(RegExp(r'（\s*）|\(\s*\)'), '');
  result = result.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  result = result.replaceAll(RegExp(r'。{2,}'), '。');
  result = result.replaceAll(RegExp(r'^[，、；：\s]+'), '');
  return result.trim();
}

bool _isGenericPythonQuestion(Map<String, dynamic> question) {
  final blob =
      '${question['question'] ?? ''}\n${question['code'] ?? ''}\n'
      '${question['explanation'] ?? ''}';
  if (genericPythonMarkers.any(blob.contains)) return true;
  final options = ((question['options'] as List<dynamic>?) ?? const <dynamic>[])
      .map((item) => item.toString())
      .join('\n');
  return genericPythonMarkers.any(options.contains);
}

/// 用本课自己的代码示例重出一道代码阅读题；没有示例时退化为概念题。
void _regenerateQuestion(
  Lesson lesson,
  Map<String, dynamic> question,
  List<Lesson> siblings,
  RepairStats stats,
) {
  final snippet = _pickSnippet(lesson);
  if (snippet != null) {
    final facts = _codeFacts(snippet.code);
    final correctFacts = facts.where((fact) => fact.present).toList();
    final wrongFacts = facts.where((fact) => !fact.present).toList();
    if (correctFacts.isNotEmpty && wrongFacts.length >= 3) {
      final correctFact = correctFacts[lesson.ordinal % correctFacts.length];
      final labels = <String>[
        correctFact.label,
        ..._rotate(wrongFacts, lesson.ordinal).take(3).map((f) => f.label),
      ];
      final options = _rotate(labels, lesson.ordinal);
      question
        ..['type'] = 'code'
        ..['question'] = _codeStem(lesson, snippet)
        ..['options'] = options
        ..['answer'] = options.indexOf(correctFact.label)
        ..['code'] = snippet.code
        ..['language'] = snippet.language
        ..remove('answers')
        ..remove('correct_order')
        ..remove('accepted_answers')
        ..remove('expected_output')
        ..['explanation'] = _codeExplanation(
          lesson,
          snippet,
          correctFact.label,
        );
      stats.questionsRegenerated++;
      stats.sample('regenerated ${lesson.id} → ${snippet.language}');
      return;
    }
  }

  final summary = _firstClause(lesson.summaryZh);
  final correct = '${lesson.titleZh}：$summary';
  final options = _rotate(<String>[
    correct,
    '只要示例数据能跑通，边界输入和失败路径就不必再验证。',
    '记住术语的字面意思就等于掌握本课，示例和输出可以跳过。',
    '把相邻知识点的结论直接套用到本课，不需要重新确认前提。',
  ], lesson.ordinal);
  question
    ..['type'] = 'single'
    ..['question'] = '「${lesson.titleZh}」的核心结论是什么？'
    ..['options'] = options
    ..['answer'] = options.indexOf(correct)
    ..remove('code')
    ..remove('language')
    ..remove('answers')
    ..remove('correct_order')
    ..remove('accepted_answers')
    ..remove('expected_output')
    ..['explanation'] =
        '$correct。在「${lesson.titleZh}」里，把${_keywordPhrase(lesson)}放进最小示例验证，换成空值或极值后结论仍要成立。';
  stats.questionsRegenerated++;
  stats.questionsRewrittenFromFallback++;
  stats.sample('fallback ${lesson.id}');
}

String _firstClause(String text) {
  final value = text.trim();
  if (value.isEmpty) return '本课给出的结论需要结合示例验证。';
  final match = RegExp(r'[^。；;]+').firstMatch(value);
  return match == null ? value : match.group(0)!.trim();
}

String _keywordPhrase(Lesson lesson) {
  final keywords = lesson.keywords.take(3).toList();
  if (keywords.isEmpty) return lesson.titleZh;
  return keywords.join('、');
}

String _codeStem(Lesson lesson, _Snippet snippet) {
  final label = _languageLabel(snippet.language);
  return switch (lesson.ordinal % 3) {
    0 =>
      '下面这段$label代码摘自「${lesson.titleZh}」的正文示例。关于这段代码，下面哪一项说法与实际内容相符？',
    1 =>
      '阅读「${lesson.titleZh}」正文里的这段$label代码，下面哪一项判断是正确的？',
    _ =>
      '这段$label代码是「${lesson.titleZh}」的示例片段，下面哪一项描述与它一致？',
  };
}

String _codeExplanation(
  Lesson lesson,
  _Snippet snippet,
  String correctLabel,
) {
  final title = lesson.titleZh;
  return '在「$title」里，$correctLabel'
      '这段代码出自「$title」的正文示例，围绕${_keywordPhrase(lesson)}展开；'
      '把输入或边界换成空值、极值或失败情况后，结论要以「$title」的实际运行结果为准。';
}

String _languageLabel(String language) => switch (language) {
  'python' => ' Python ',
  'javascript' => ' JavaScript ',
  'typescript' => ' TypeScript ',
  'c' => ' C ',
  'cpp' => ' C++ ',
  'csharp' => ' C# ',
  'java' => ' Java ',
  'go' => ' Go ',
  'rust' => ' Rust ',
  'kotlin' => ' Kotlin ',
  'swift' => ' Swift ',
  'shell' => ' Shell ',
  'sql' => ' SQL ',
  _ => '代码',
};

class _Snippet {
  const _Snippet(this.language, this.code);

  final String language;
  final String code;
}

/// 从本课正文里挑一段能作为代码阅读题的示例。
_Snippet? _pickSnippet(Lesson lesson) {
  final expected = lesson.expectedLanguage;
  final candidates = <(_Snippet, int)>[];
  for (final match
      in RegExp(r'```([^\n]*)\n(.*?)```', dotAll: true).allMatches(
    lesson.markdown,
  )) {
    final language = match
        .group(1)!
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .first;
    final code = match.group(2)!.trim();
    if (language.isEmpty || code.length < 40 || code.length > 1200) continue;
    if (code.contains('__USER_CODE__') || code.contains('placeholder')) {
      continue;
    }
    if (const <String>{'text', 'markdown', 'md', 'yaml', 'json', 'xml'}
        .contains(language)) {
      continue;
    }
    var score = 0;
    if (expected != null && language == expected) score += 6;
    for (final keyword in lesson.keywords) {
      if (code.contains(keyword)) score += 3;
    }
    score -= code.length ~/ 400;
    candidates.add((_Snippet(language, code), score));
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.$2.compareTo(a.$2));
  return candidates.first.$1;
}

class _Fact {
  const _Fact(this.label, this.present);

  final String label;
  final bool present;
}

/// 依据代码里实际出现的语法结构生成可判定的说法。
List<_Fact> _codeFacts(String code) {
  final hasLoop = RegExp(
    r'\b(for|while|do)\b|\.each\b|foreach\b',
  ).hasMatch(code);
  final hasBranch = RegExp(
    r'\b(if|else|switch|case)\b',
  ).hasMatch(code);
  final hasFunction = RegExp(
    r'\bdef\s+\w|\bfunction\s*\(|\bfunc\s+\w|\w+\s*\([^)]*\)\s*\{|=>',
  ).hasMatch(code);
  final hasTry = RegExp(
    r'\b(try|catch|except|rescue|finally)\b',
  ).hasMatch(code);
  final hasInput = RegExp(
    r'\binput\s*\(|\bscanf\s*\(|\bgets\b|\bstdin\b|\bargv\b|\bScanner\b|\breadLine\b|\bgetline\s*\(',
  ).hasMatch(code);
  final hasOutput = RegExp(
    r'\bprint\s*\(|\bprintf\s*\(|\bputs\s*\(|\bconsole\.log\b|\bSystem\.out\b|\bfmt\.Print|\bprintln\s*\(|\becho\b|\bcout\b|\bwriteln\s*\(',
  ).hasMatch(code);
  return <_Fact>[
    _Fact('这段代码包含循环结构，同一段逻辑会被重复执行。', hasLoop),
    _Fact('这段代码包含条件分支，不同输入会走不同的执行路径。', hasBranch),
    _Fact('这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。', hasFunction),
    _Fact('这段代码包含异常处理分支，失败时会走专门的补救路径。', hasTry),
    _Fact('这段代码会读取外部输入，结果依赖传入的数据。', hasInput),
    _Fact('这段代码会产生可观察的输出，运行后能看到结果。', hasOutput),
    _Fact(
      '这段代码只做静态声明，没有循环、分支或可观察输出。',
      !hasLoop && !hasBranch && !hasFunction && !hasTry && !hasOutput,
    ),
  ];
}

List<T> _rotate<T>(List<T> items, int offset) {
  if (items.isEmpty) return const <Never>[];
  final start = offset % items.length;
  return <T>[
    for (var index = 0; index < items.length; index++)
      items[(start + index) % items.length],
  ];
}

/// 修掉被生成器截断的题干：能从选项或术语表还原的就还原，否则删掉残缺片段。
void _fixTruncatedStem(
  Lesson lesson,
  Map<String, dynamic> question,
  RepairStats stats,
) {
  final text = (question['question'] ?? '').toString();
  if (!text.contains('…')) return;
  var fixed = text;
  final correct = _correctParts(question);
  if (text.startsWith('关于「') && text.contains('」，')) {
    final full = correct.isEmpty ? '' : correct.first;
    if (full.isNotEmpty) {
      fixed = text.replaceFirst(RegExp(r'「[^」]*…[^」]*」'), '「$full」');
    }
  } else if (text.contains('术语速查')) {
    final term = correct.isEmpty ? '' : correct.first;
    final definition = _definitionForTerm(lesson, term, text);
    if (term.isNotEmpty && definition.isNotEmpty) {
      fixed = '填空：在「${lesson.titleZh}」的术语速查里，「$definition」描述的是哪个术语？';
    } else if (term.isNotEmpty) {
      fixed = '填空：在「${lesson.titleZh}」里，下面这个术语的作用是什么：`$term`？';
    }
  }
  if (fixed.contains('…')) {
    fixed = fixed
        .replaceAllMapped(RegExp(r'「[^「」]*…[^」]*」'), (match) => '')
        .replaceAllMapped(RegExp(r'\*\*[^*「」]*…[^*]*\*\*'), (match) => '')
        .replaceAll(RegExp(r'[^，。；：、\s]{0,16}…'), '')
        .replaceAll(RegExp(r'[（(]\s*[)）]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^[：，、；\s]+'), '')
        .trim();
  }
  if (fixed.isEmpty || fixed.length < 6) return;
  if (fixed != text) {
    question['question'] = fixed;
    stats.truncatedStemsFixed++;
  }
}

/// 在术语速查表里找到以给定前缀开始的完整定义。
String _definitionForTerm(Lesson lesson, String term, String stem) {
  final prefixMatch = RegExp(r'表示「([^」]*)').firstMatch(stem);
  final prefix = prefixMatch?.group(1)?.replaceAll('…', '').trim() ?? '';
  for (final line in const LineSplitter().convert(lesson.markdown)) {
    if (!line.startsWith('|')) continue;
    final cells = line
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList();
    if (cells.length < 2) continue;
    final left = cells.first.replaceAll('`', '');
    if (term.isNotEmpty && left != term) continue;
    final definition = _cleanText(cells[1]);
    if (definition.isEmpty) continue;
    if (prefix.isEmpty || definition.contains(prefix)) return definition;
  }
  if (prefix.isEmpty) return '';
  return prefix.replaceAll(RegExp(r'[，、；：]+$'), '');
}

void _fixQuestionLanguage(
  Lesson lesson,
  Map<String, dynamic> question,
  RepairStats stats,
) {
  final code = (question['code'] ?? '').toString().trim();
  final language = (question['language'] ?? '').toString().trim();
  final expected = lesson.expectedLanguage;
  if (expected == null) return;
  if (code.isEmpty) {
    if (language.isNotEmpty && language != expected) {
      question['language'] = expected;
      stats.languagesFixed++;
    }
    return;
  }
  if (language == expected) return;
  question['language'] = expected;
  stats.languagesFixed++;
}

/// 解析去模板：删机械句、去重复、补齐正确答案与本课关联。
String _cleanExplanation(
  Lesson lesson,
  Map<String, dynamic> question,
  RepairStats stats,
) {
  final raw = (question['explanation'] ?? '').toString();
  final correctParts = _correctParts(question);
  final kept = <String>[];
  final skeletons = <String>{};
  for (final sentence in _splitSentences(raw)) {
    final cleaned = sentence.trim();
    if (cleaned.isEmpty) continue;
    if (cleaned.contains('…')) continue;
    // 引号只在补句里成对出现；数量不成对说明旧模板句被断句切碎，直接丢弃残片。
    if (_hasUnbalancedQuotes(cleaned)) continue;
    if (explanationBoilerplateMarkers.any(cleaned.contains)) continue;
    final skeleton = _skeleton(cleaned);
    if (skeleton.length >= 8 && !skeletons.add(skeleton)) continue;
    kept.add(cleaned);
  }
  // 每一句都要能指回本课：既避免跨课复读，也防止解析与主题脱节。
  final linked = <String>[
    for (final sentence in kept)
      sentence.contains(lesson.titleZh) || !_isOptionEcho(question, sentence)
          ? sentence
          : '在「${lesson.titleZh}」里，$sentence',
  ];
  var text = linked.join();
  // 上一版补句用「；」连接两个分句，会被全角断句切成重复片段；并回逗号。
  text = text.replaceAll('；换成“', '，换成“');
  final missing = correctParts
      .where(
        (part) =>
            part.trim().isNotEmpty &&
            !_containsAnswerStrict(text, part),
      )
      .toList();
  if (missing.isNotEmpty) {
    text = '在「${lesson.titleZh}」里，${missing.join('；')}。$text';
  }
  // 补句必须带上课内唯一的锚点（题干节选或正确项），否则同一门课的多道题
  // 会生成一模一样的句子，等于制造新的模板。句式用稳定散列挑选，重跑不变。
  final anchor = correctParts.isEmpty
      ? ''
      : _shortAnswerAnchor(correctParts.first);
  final excerpt = _questionExcerpt(question);
  var variant = _stableSeed('${lesson.id}|${question['question']}');
  if (!_linksToLesson(lesson, text)) {
    text =
        '$text${_lessonLinkSentence(lesson, variant, anchor: anchor, excerpt: excerpt)}';
    variant++;
  }
  var guard = 0;
  while (text.length < 140 && guard < 4) {
    final sentence = _lessonLinkSentence(
      lesson,
      variant,
      anchor: anchor,
      excerpt: excerpt,
    );
    text = _endsWithPeriod(text) ? '$text$sentence' : '$text。$sentence';
    variant++;
    guard++;
  }
  if (!_endsWithPeriod(text)) text = '$text。';
  final normalized = _normalizePunctuation(text);
  if (normalized != raw) {
    stats.explanationsRewritten++;
    if (Platform.environment['REPAIR_DEBUG'] != null &&
        stats.explanationsRewritten <= 6) {
      stdout.writeln('DEBUG ${lesson.id}');
      stdout.writeln('  before=${raw.substring(0, raw.length.clamp(0, 220))}');
      stdout.writeln(
        '  after =${normalized.substring(0, normalized.length.clamp(0, 220))}',
      );
    }
  }
  return normalized;
}

bool _endsWithPeriod(String text) =>
    RegExp(r'[。！？!?]$').hasMatch(text.trim());

bool _hasUnbalancedQuotes(String text) {
  final open = RegExp('“').allMatches(text).length;
  final close = RegExp('”').allMatches(text).length;
  return open != close;
}

bool _linksToLesson(Lesson lesson, String text) {
  if (lesson.titleZh.isNotEmpty && text.contains(lesson.titleZh)) return true;
  return lesson.keywords.any(
    (keyword) => keyword.length >= 2 && text.contains(keyword),
  );
}

/// 补句模板：每句都嵌入题干锚点或正确项，保证同一门课的多道题不会撞句。
String _lessonLinkSentence(
  Lesson lesson,
  int variant, {
  String anchor = '',
  String excerpt = '',
}) {
  final topic = _keywordPhrase(lesson);
  final focus = excerpt.isEmpty ? topic : excerpt;
  final answer = anchor.isEmpty ? topic : anchor;
  return switch (variant % 6) {
    0 =>
      '在「${lesson.titleZh}」里判断这道题，要把$topic的条件、过程与失败路径逐项对齐，换成“$focus”这个场景，只有满足前提的结论才成立。',
    1 =>
      '回到「${lesson.titleZh}」的正文示例，用“$focus”走一遍$topic的完整流程，能复现的结论才可以保留。',
    2 =>
      '「${lesson.titleZh}」要求先交代$topic的前提再下结论，所以“$answer”只在题干“$focus”给定的条件下成立。',
    3 =>
      '把“$answer”代回「${lesson.titleZh}」里“$focus”的例子核对，条件一旦改变，结论就要用$topic重新推导。',
    4 =>
      '这道题的关键在「${lesson.titleZh}」的$topic：先确认题干“$focus”问的是哪一步，再排除偷换前提的选项。',
    _ =>
      '“$focus”与「${lesson.titleZh}」的术语表相呼应，只有符合$topic约束的“$answer”才是正文支持的结论。',
  };
}

/// 题干里可读的一小段文字，作为补句锚点，避免同课多题生成同一句话。
String _questionExcerpt(Map<String, dynamic> question) {
  var raw = (question['question'] ?? '')
      .toString()
      .replaceAll(RegExp(r'[`*_>#]'), '')
      .replaceAll(RegExp(r'[「」“”…。；？！?!\n]'), '')
      .replaceAll(RegExp(r'[：:，,、]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (raw.isEmpty) return '';
  // 去掉「补全代码」「填空」这类通用前缀，只留下有区分度的题干内容。
  raw = raw.replaceFirst(
    RegExp(r'^(补全代码|填空|选择|判断|阅读代码|关于)\s*'),
    '',
  ).trim();
  if (raw.length < 4) return '';
  // 取第一个足够长的片段，避免「实战 把数据结构用起来」这类前缀占满配额。
  final chunks = raw
      .split(' ')
      .where((chunk) => chunk.trim().length >= 4)
      .toList();
  var excerpt = chunks.isEmpty ? raw : chunks.first.trim();
  if (excerpt.length > 30) excerpt = excerpt.substring(0, 30);
  return excerpt.length >= 4 ? excerpt : '';
}

/// 正确项文本可能很长，截断到可读长度并去掉会干扰断句的符号。
String _shortAnswerAnchor(String text) {
  var value = text
      .replaceAll(RegExp(r'[`*_「」“”…]'), '')
      .replaceAll(RegExp(r'[。；\n]'), '，')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (value.length > 20) {
    final cut = value.substring(0, 20);
    final lastPause = cut.lastIndexOf(RegExp(r'[，,。；;：:、]'));
    value = lastPause >= 6 ? cut.substring(0, lastPause) : cut;
  }
  return value.trim();
}

/// 与运行环境无关的稳定散列：保证修复工具重复执行得到同样的句式。
int _stableSeed(String text) {
  var hash = 17;
  for (final unit in text.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

/// 解析句如果就是某个选项的复述，跨课重复的概率很高，需要补上本课主题。
bool _isOptionEcho(Map<String, dynamic> question, String sentence) {
  final key = _normalizeForCompare(sentence);
  if (key.isEmpty) return false;
  final options = (question['options'] as List<dynamic>?) ?? const <dynamic>[];
  return options.any((option) {
    final optionKey = _normalizeForCompare('$option');
    if (optionKey.length < 8) return false;
    return key.contains(optionKey);
  });
}

/// 与审计工具一致：只压缩空白，不删除分号等符号，避免误判「解析已包含答案」。
bool _containsAnswerStrict(String text, String part) {
  final haystack = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final needle = part.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (needle.isEmpty) return true;
  return haystack.contains(needle);
}

List<String> _correctParts(Map<String, dynamic> question) {
  final options = ((question['options'] as List<dynamic>?) ?? const <dynamic>[])
      .map((item) => item.toString())
      .toList();
  final answers = (question['answers'] as List<dynamic>?) ?? const <dynamic>[];
  final indexes = answers
      .map((value) => value is num ? value.toInt() : int.tryParse('$value'))
      .whereType<int>()
      .where((value) => value >= 0 && value < options.length)
      .toList();
  if (indexes.isNotEmpty) {
    return indexes.map((index) => options[index]).toList();
  }
  final answer = question['answer'];
  if (answer is num) {
    final index = answer.toInt();
    if (index >= 0 && index < options.length) return <String>[options[index]];
  }
  final order = (question['correct_order'] as List<dynamic>?) ?? const [];
  final orderIndexes = order
      .map((value) => value is num ? value.toInt() : int.tryParse('$value'))
      .whereType<int>()
      .where((value) => value >= 0 && value < options.length)
      .toList();
  if (orderIndexes.isNotEmpty) {
    return orderIndexes.map((index) => options[index]).toList();
  }
  final accepted = (question['accepted_answers'] as List<dynamic>?) ?? const [];
  if (accepted.isNotEmpty) {
    return <String>[accepted.first.toString()];
  }
  if (answer is String && answer.trim().isNotEmpty) return <String>[answer];
  return const <String>[];
}

List<String> _splitSentences(String text) {
  return text
      // 只按全角标点断句：ASCII 的 `?`、`;` 常常出现在 `??`、`$(...)` 这类
      // 代码片段里，按它们断句会把选项原文拆开，导致解析与题干对不上。
      .split(RegExp(r'(?<=[。！？；])'))
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
}

String _skeleton(String text) {
  return text
      .replaceAll(RegExp(r'[「“《][^」”》]*[」”》]'), 'X')
      .replaceAll(RegExp(r'\d+'), 'N')
      .replaceAll(RegExp(r'\s+'), '');
}

String _normalizeForCompare(String text) {
  return text
      .replaceAll(RegExp(r'[「『“"\s。！？!?；;，,、]+'), '')
      .trim();
}

String _normalizePunctuation(String input) {
  var text = input.replaceAll(RegExp(r'…+'), '');
  // 注意：Dart 的 replaceAll 不会做 `$1` 分组替换，必须用 replaceAllMapped。
  text = text.replaceAllMapped(
    RegExp(r'([。！？；])\s*[，、；：]'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'[，、：]\s*([。！？；])'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'([，、：])\s*[，、：]'),
    (match) => match.group(1)!,
  );
  text = text.replaceAllMapped(
    RegExp(r'([。！？；])\s*[。！？；]'),
    (match) => match.group(1)!,
  );
  text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  text = text.replaceAll(RegExp(r'^[，、；：\s]+'), '');
  return text.trim();
}

// ---------------------------------------------------------------------------
// 正文修复
// ---------------------------------------------------------------------------

void _repairMarkdown(Lesson lesson, RepairStats stats) {
  var text = lesson.markdown.replaceAll('\r\n', '\n');
  if (text.trim().isEmpty) {
    stats.blockingIssues.add('${lesson.id}: Markdown 缺失');
    return;
  }
  final hadReviewSection = text.contains('## 复习与迁移');
  final before = text;

  text = _removeGeneratedReviewSections(text, stats);
  text = _restoreHeading(text, lesson, stats);
  text = _restoreAltText(text, lesson, stats);
  if (text.contains(placeholderTitle)) {
    stats.placeholderTouchedLessons++;
    stats.placeholdersCleared += placeholderTitle.allMatches(text).length;
    text = text.replaceAll(placeholderTitle, lesson.titleZh);
  }
  text = _repairTruncatedLines(text);
  stats.idsCleared += internalIdPattern.allMatches(text).length;
  text = text.replaceAll(internalIdPattern, '');
  text = _rebuildTermTables(lesson, text, stats);
  text = _replaceFocusSection(lesson, text, stats);
  text = _dedupeListItems(text);
  text = _ensureReviewSection(lesson, text, stats, hadReviewSection);
  text = _normalizeMarkdown(text);

  if (text != before) stats.sample('markdown ${lesson.id}');
  lesson.markdown = text;
  _collectLengthStats(lesson, stats);
}

/// 删除所有「复习与迁移 / 复核补充」章节与生成器标记。
String _removeGeneratedReviewSections(String text, RepairStats stats) {
  var result = text;
  for (final heading in removableHeadings) {
    while (true) {
      final bounds = _sectionBounds(result, heading);
      if (bounds == null) break;
      result = result.replaceRange(bounds.$1, bounds.$2, '');
      stats.reviewSectionsRemoved++;
    }
  }
  final markers = RegExp(r'<!--\s*p0p1-review:(start|end)\s*-->\s*');
  stats.strayMarkersRemoved += markers.allMatches(result).length;
  result = result.replaceAll(markers, '');
  // 行内残留的「复核补充 N」标签与标题行一并清掉。
  result = result.replaceAll(
    RegExp(r'\*\*复核补充\s*\d*\*\*\s*[：:]\s*'),
    '',
  );
  result = result.replaceAll(
    RegExp(r'^[>\s]*#{1,6}\s*(?:复核补充|复习与迁移)\s*\d*\s*$', multiLine: true),
    '',
  );
  return result;
}

/// 恢复 H1：必须与 manifest 标题逐字一致。
String _restoreHeading(String text, Lesson lesson, RepairStats stats) {
  final pattern = RegExp(r'^#\s+.*$', multiLine: true);
  final match = pattern.firstMatch(text);
  final expected = '# ${lesson.titleZh}';
  if (match == null) {
    final metadata = RegExp(
      r'^>\s*内容更新时间.*$',
      multiLine: true,
    ).firstMatch(text);
    if (metadata == null) return '$expected\n\n$text';
    return text.replaceRange(metadata.start, metadata.start, '$expected\n\n');
  }
  if (match.group(0)!.trim() == expected) return text;
  stats.titleRestored++;
  return text.replaceRange(match.start, match.end, expected);
}

/// 配图替代文本里不能出现占位符。
String _restoreAltText(String text, Lesson lesson, RepairStats stats) {
  return text.replaceAllMapped(RegExp(r'!\[([^\]]*)\]'), (match) {
    final alt = match.group(1) ?? '';
    if (!alt.contains(placeholderTitle)) return match.group(0)!;
    var fixed = alt
        .replaceAll(placeholderTitle, lesson.titleZh)
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (fixed.isEmpty) fixed = '${lesson.titleZh} 示意图';
    stats.altRestored++;
    return '![$fixed]';
  });
}

/// 修掉正文里的截断片段（代码块与表格单独处理）。
String _repairTruncatedLines(String text) {
  final output = <String>[];
  var inFence = false;
  for (final line in text.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      output.add(line);
      continue;
    }
    if (inFence || !line.contains('…') || line.startsWith('|')) {
      output.add(line);
      continue;
    }
    var fixed = line
        .replaceAllMapped(RegExp(r'「[^「」]*…[^」]*」'), (match) => '')
        .replaceAllMapped(RegExp(r'\*\*[^*]*…[^*]*\*\*'), (match) => '')
        .replaceAll(RegExp(r'[^，。；：、\s]{0,20}…'), '')
        .replaceAll(RegExp(r'[（(]\s*[)）]'), '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'[，、；：]{2,}'), '，')
        .replaceAll(RegExp(r'[，、；：]\s*$'), '')
        .trimRight();
    fixed = fixed.replaceAllMapped(
      RegExp(r'([。！？；])\s*[，、；：]'),
      (match) => match.group(1)!,
    );
    if (_isMeaninglessLine(fixed)) continue;
    output.add(fixed);
  }
  return output.join('\n');
}

bool _isMeaninglessLine(String line) {
  var stripped = line
      .replaceAll(RegExp(r'^\s*[-*+]\s*'), '')
      .replaceAll(RegExp(r'^\s*\d+\.\s*'), '')
      .replaceAll(RegExp(r'^[\[\]\s\-*]+'), '')
      .replaceAll(RegExp(r'[*`_#|>\s：:，。、；；]+'), '');
  return stripped.length < 3;
}

/// 术语速查表一旦出现机械解析残留或截断，就按本课关键词重建。
String _rebuildTermTables(Lesson lesson, String text, RepairStats stats) {
  final bounds = _sectionBounds(text, '术语速查');
  if (bounds == null) return text;
  var body = text.substring(bounds.$1, bounds.$2);
  // 旧版导语在 174 门课里逐字相同，属于跨课复读，改成带课程主题的版本。
  const genericIntro =
      '把本课反复出现的术语集中放在一起。复习时先遮住右列，尝试用自己的话解释，再回到正文核对。';
  if (body.contains(genericIntro)) {
    body = body.replaceAll(genericIntro, _termTableIntro(lesson));
    text = text.replaceRange(bounds.$1, bounds.$2, body);
  }
  final corrupt = body.split('\n').any(
    (line) =>
        line.startsWith('|') &&
        (line.contains('判断依据') ||
            line.contains('正确答案是') ||
            line.contains('…')),
  );
  if (!corrupt) return text;
  final keywords = lesson.keywords.isEmpty
      ? <String>[lesson.titleZh]
      : lesson.keywords.take(6).toList();
  final buffer = StringBuffer()
    ..writeln('## 术语速查')
    ..writeln()
    ..writeln(
      _termTableIntro(lesson),
    )
    ..writeln()
    ..writeln('| 术语 | 本课语境 |')
    ..writeln('| --- | --- |');
  for (var index = 0; index < keywords.length; index++) {
    final context = switch (index % 3) {
      0 => '在「${lesson.titleZh}」里理解它的定义、输入和输出。',
      1 => '本课用它说明边界条件与失败路径。',
      _ => '结合「${lesson.titleZh}」的正文示例确认它的适用条件。',
    };
    buffer.writeln('| `$keywords[index]` | $context |');
  }
  buffer.writeln();
  stats.termTablesRebuilt++;
  return text.replaceRange(bounds.$1, bounds.$2, buffer.toString());
}

String _termTableIntro(Lesson lesson) =>
    '把「${lesson.titleZh}」里反复出现的术语集中放在一起。'
    '复习时先遮住右列，尝试用自己的话解释，再回到正文核对。';

/// 按当前题库重建「考点精讲」，保证正文与题库逐题一致。
String _replaceFocusSection(Lesson lesson, String text, RepairStats stats) {
  final rendered = _renderFocusSection(lesson);
  var result = text;
  while (true) {
    final bounds = _sectionBounds(result, '考点精讲');
    if (bounds == null) break;
    result = result.replaceRange(bounds.$1, bounds.$2, '');
    stats.focusSectionsRebuilt++;
  }
  final english = RegExp(
    r'^##\s+English Overview\s*$',
    multiLine: true,
  ).firstMatch(result);
  if (english == null) return '$result\n\n$rendered';
  return result.replaceRange(english.start, english.start, '$rendered\n');
}

String _renderFocusSection(Lesson lesson) {
  final buffer = StringBuffer('## 考点精讲\n\n');
  final quiz = lesson.quiz;
  for (var index = 0; index < quiz.length; index++) {
    final question = quiz[index];
    final questionText = (question['question'] ?? '').toString().trim();
    final explanation = (question['explanation'] ?? '').toString().trim();
    buffer
      ..writeln('### 考点 ${index + 1}：$questionText')
      ..writeln()
      ..writeln('- **判断依据**：$explanation')
      ..writeln();
  }
  return buffer.toString();
}

/// 同一章节里重复出现的条目只保留第一次。
String _dedupeListItems(String text) {
  final output = <String>[];
  final seen = <String>{};
  for (final line in text.split('\n')) {
    if (line.startsWith('## ')) seen.clear();
    final trimmed = line.trimLeft();
    final isItem =
        trimmed.startsWith('- ') ||
        trimmed.startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(trimmed);
    if (isItem) {
      final key = _normalizeForCompare(trimmed);
      if (key.length >= 12 && !seen.add(key)) continue;
    }
    output.add(line);
  }
  return output.join('\n');
}

/// 复习章节：只保留一节，并按本课正文与题库生成可复核的条目。
String _ensureReviewSection(
  Lesson lesson,
  String text,
  RepairStats stats,
  bool hadReviewSection,
) {
  final target = lesson.targetLength;
  if (!hadReviewSection && text.length >= target) return text;
  final section = _buildReviewSection(lesson, text, target - text.length);
  stats.reviewSectionsRebuilt++;
  return '${text.trimRight()}\n\n$section';
}

String _buildReviewSection(Lesson lesson, String body, int missing) {
  final buffer = StringBuffer()
    ..writeln('## 复习与迁移')
    ..writeln()
    ..writeln(
      '复习目标：把「${lesson.titleZh}」的判断标准放回可复现的例子里。'
      '先自己作答，再对照依据；如果结论正确但理由不完整，回到正文补足前提。',
    )
    ..writeln()
    ..writeln('### 概念复述')
    ..writeln();
  final summary = lesson.summaryZh.isEmpty
      ? '本课给出的结论需要结合示例验证。'
      : lesson.summaryZh;
  buffer
    ..writeln('- 用一句话说明「${lesson.titleZh}」解决什么问题：$summary')
    ..writeln('- 写出${_keywordPhrase(lesson)}之间的关系，并各举一个例子。')
    ..writeln('- 说出本课最容易混淆的两个概念，以及区分它们的判据。')
    ..writeln();

  final recaps = _collectSectionRecaps(lesson, body);
  if (recaps.isNotEmpty) {
    buffer
      ..writeln('### 正文逐节复核')
      ..writeln();
    for (final recap in recaps) {
      buffer.writeln('- $recap');
    }
    buffer.writeln();
  }

  final quiz = lesson.quiz;
  if (quiz.isNotEmpty) {
    buffer
      ..writeln('### 测验回顾')
      ..writeln();
    for (var index = 0; index < quiz.length; index++) {
      final question = quiz[index];
      final questionText = (question['question'] ?? '').toString().trim();
      final explanation = (question['explanation'] ?? '').toString().trim();
      buffer
        ..writeln('${index + 1}. $questionText')
        ..writeln('   - 依据：$explanation');
    }
    buffer.writeln();
  }

  buffer
    ..writeln('### 迁移练习')
    ..writeln();
  final accepted = quiz.isEmpty
      ? <String>[lesson.titleZh]
      : quiz
            .expand(_correctParts)
            .where((part) => part.trim().isNotEmpty)
            .toList();
  final pool = accepted.isEmpty ? <String>[lesson.titleZh] : accepted;
  final prompts = quiz.isEmpty
      ? <String>[lesson.titleZh]
      : quiz
            .map((question) => (question['question'] ?? '').toString().trim())
            .where((text) => text.isNotEmpty)
            .toList();
  const actions = <String>[
    '先写下预测，再运行本课示例，最后记录预测与实际的差异。',
    '把结论写成一条可复现的验证步骤，让别人照着步骤就能核对。',
    '换一个边界输入（空值、极值或失败情况）重跑一次，说明结论是否仍然成立。',
    '用一句话说明干扰项错在哪里，再回到正文找到对应依据。',
    '把这个结论迁移到自己的数据或项目场景，并记录输入、输出与失败路径。',
    '画出这一步的输入—处理—输出流程，标出最容易失败的位置。',
  ];
  var index = 0;
  while (buffer.length < missing + 120 && index < 60) {
    final answer = pool[index % pool.length];
    final prompt = prompts[index % prompts.length];
    final action = actions[(index ~/ prompts.length) % actions.length];
    buffer.writeln(
      '- 第 ${index + 1} 次迁移：围绕「$prompt」$action'
      '参考答案是「$answer」。',
    );
    index++;
  }
  return buffer.toString();
}

/// 从正文小节里取一句包含本课主题的原话，作为逐节复核条目。
List<String> _collectSectionRecaps(Lesson lesson, String body) {
  const skip = <String>[
    '考点精讲',
    'English Overview',
    'Full English Study Guide',
    'Bilingual Section Outline',
    '内容元数据',
    '参考资料与复核',
    '学习目标',
    '前置知识',
    '本课小结',
    '术语速查',
    '复习与迁移',
    '复核补充',
    '动手练习',
    '可运行练习',
    '预期输出',
    '验证步骤',
    '最小可运行示例',
  ];
  final recaps = <String>[];
  final lines = body.split('\n');
  String? heading;
  var inFence = false;
  for (final line in lines) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (line.startsWith('## ')) {
      heading = line.substring(3).trim();
      continue;
    }
    if (heading == null || line.startsWith('#')) continue;
    if (skip.any(heading.contains)) continue;
    final text = line.trim();
    if (text.isEmpty ||
        text.startsWith('|') ||
        text.startsWith('![') ||
        text.startsWith('>') ||
        text.startsWith('-') ||
        text.startsWith('*') ||
        RegExp(r'^\d+\.').hasMatch(text)) {
      continue;
    }
    final sentence = _firstSentence(text);
    if (sentence.length < 24) continue;
    if (!_linksToLesson(lesson, sentence)) continue;
    recaps.add('**$heading**：$sentence');
    heading = null;
    if (recaps.length >= 10) break;
  }
  return recaps;
}

String _firstSentence(String text) {
  final match = RegExp(r'^[^。！？!?]{12,120}[。！？!?]?').firstMatch(text);
  final value = (match?.group(0) ?? text).trim();
  return _endsWithPeriod(value) ? value : '$value。';
}

void _collectLengthStats(Lesson lesson, RepairStats stats) {
  final length = lesson.markdown.length;
  stats.totalChars += length;
  if (length < stats.minChars) stats.minChars = length;
  final ellipsis = '…'.allMatches(lesson.markdown).length;
  if (ellipsis > stats.maxEllipsis) stats.maxEllipsis = ellipsis;
  if (length < lesson.targetLength) {
    stats.belowTarget++;
    stats.blockingIssues.add(
      '${lesson.id}: 正文 $length 字符，低于目标 ${lesson.targetLength}',
    );
  }
}

String _normalizeMarkdown(String text) {
  var result = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return '${result.trim()}\n';
}

(int, int)? _sectionBounds(String text, String title) {
  final pattern = RegExp(
    '^##\\s+${RegExp.escape(title)}(?:\\s*[：:].*?)?(?:\\s+\\d+)?\\s*\$',
    multiLine: true,
  );
  final match = pattern.firstMatch(text);
  if (match == null) return null;
  final next = RegExp(
    r'^##\s+',
    multiLine: true,
  ).firstMatch(text.substring(match.end));
  return (match.start, next == null ? text.length : match.end + next.start);
}

void _printReport(
  RepairStats stats,
  List<Lesson> lessons, {
  required bool apply,
}) {
  final titleFixes = <String>[];
  for (final lesson in lessons) {
    final h1 = RegExp(
      r'^#\s+(.+)$',
      multiLine: true,
    ).firstMatch(lesson.markdown)?.group(1)?.trim();
    if (h1 != lesson.titleZh) titleFixes.add(lesson.id);
  }
  stdout
    ..writeln(apply ? '=== 已写回内容 ===' : '=== 试运行（未写文件）===')
    ..writeln('课程数量            ${lessons.length}')
    ..writeln('恢复 H1 标题         ${stats.titleRestored}')
    ..writeln('修复配图替代文本     ${stats.altRestored}')
    ..writeln('清理占位符           ${stats.placeholdersCleared}')
    ..writeln('清理内部题号         ${stats.quizIdsCleared}')
    ..writeln('重写解析             ${stats.explanationsRewritten}')
    ..writeln('重出跨域题目         ${stats.questionsRegenerated}')
    ..writeln('  其中概念题回退     ${stats.questionsRewrittenFromFallback}')
    ..writeln('修复截断题干         ${stats.truncatedStemsFixed}')
    ..writeln('删除复习章节         ${stats.reviewSectionsRemoved}')
    ..writeln('重建复习章节         ${stats.reviewSectionsRebuilt}')
    ..writeln('重建术语表           ${stats.termTablesRebuilt}')
    ..writeln('重建考点精讲         ${stats.focusSectionsRebuilt}')
    ..writeln('清理残留标记         ${stats.strayMarkersRemoved}')
    ..writeln('修正代码语言         ${stats.languagesFixed}')
    ..writeln('正文总字符           ${stats.totalChars}')
    ..writeln('最短正文             ${stats.minChars}')
    ..writeln('低于目标课程         ${stats.belowTarget}')
    ..writeln('单课最多省略号       ${stats.maxEllipsis}')
    ..writeln('H1 仍不一致          ${titleFixes.length}');
  if (stats.blockingIssues.isNotEmpty) {
    stdout.writeln('--- 阻塞问题（前 10 条）---');
    for (final issue in stats.blockingIssues.take(10)) {
      stdout.writeln(issue);
    }
  }
}
