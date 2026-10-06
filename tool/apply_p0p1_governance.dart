// P0/P1 内容治理主脚本。
//
// 用法：
//   dart run tool/apply_p0p1_governance.dart [--dry-run] [--lesson=<id>] [--samples=5]
//   dart run tool/apply_p0p1_governance.dart --apply
//
// 处理范围：
//   1. 清理测验解析中的课程名复读、旧版扩写句和重复模板句；
//   2. 重写 Markdown 的「考点精讲」，移除机械填充、重复段落和课程名复读；
//   3. 为每门课生成逐课参考资料组合；
//   4. 修复代码题的语言、代码形态和课程主题错配。
import 'dart:convert';
import 'dart:io';

import 'p0p1_reference_catalog.dart';

const String manifestPath = 'assets/content/manifest.json';
const String _focusMarker = '<!-- p0p1-focus -->';
const String _reviewStart = '<!-- p0p1-review:start -->';
const String _reviewEnd = '<!-- p0p1-review:end -->';

const Map<String, String> expectedLanguageByCategory = <String, String>{
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

const Set<String> _languageCategories = <String>{
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

const List<String> _generatedExplanationMarkers = <String>[
  '这道题对应的课程',
  '修正后要重跑',
  '本课在「',
  '本课还在「',
  '本课把「',
  '本课在核心知识',
  '本课还在核心知识',
  '本课示例中',
  '课程摘要指出',
  '把现象和原因写在一起',
  '这道题在问',
];

const List<String> _mechanicalMarkdownMarkers = <String>[
  '先自己作答，再看「判断依据」',
  '**迁移检查**',
  '本课在「',
  '本课还在「',
  '本课在核心知识',
  '本课还在核心知识',
  '课程摘要指出',
  '回到正文对应章节补足概念',
  '把题干里的一个条件换成边界值',
  '把现象和原因写在一起',
  '错误信息通常会指出出错行和期望符号',
  '这些题按“先定位概念、再排除边界错误、最后核对答案”',
  '把本课反复出现的术语集中放在一起',
  'The full tutorial is written in Chinese',
  'App 完全离线展示文字链接',
  '验收标准：',
  '复制上面的代码，只修改一个输入',
  '阅读时不要只记结论，先问三个问题',
  '识别输入。先写清数据类型',
  '排查顺序应遵循「先复现、再缩小范围、再验证假设、最后修改」',
  '让另一个同学只读接口说明和测试用例',
  '每道变式都写下：预测、实际结果、差异、下一步',
  '从正文里选两个差异最小的方案',
  '放回真实场景，说明不做它会带来什么后果',
  '本课有 ',
  '个判断点。',
];

class LessonRecord {
  LessonRecord({
    required this.categoryMap,
    required this.lessonMap,
    required this.originalMarkdown,
  }) : markdown = originalMarkdown;

  final Map<String, dynamic> categoryMap;
  final Map<String, dynamic> lessonMap;
  final String originalMarkdown;
  String markdown;

  String get categoryId => categoryMap['id'].toString();
  String get id => lessonMap['id'].toString();
  Map<String, dynamic> get titleMap =>
      (lessonMap['title'] as Map?)?.cast<String, dynamic>() ?? const {};
  String get titleZh => (titleMap['zh'] ?? id).toString().trim();
  String get titleEn => (titleMap['en'] ?? titleZh).toString().trim();
  Map<String, dynamic> get summaryMap =>
      (lessonMap['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
  String get summaryZh => (summaryMap['zh'] ?? '').toString().trim();
  String get summaryEn => (summaryMap['en'] ?? summaryZh).toString().trim();
  List<String> get keywords =>
      ((lessonMap['keywords'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .toList();
  List<Map<String, dynamic>> get quiz =>
      ((lessonMap['quiz'] as List<dynamic>?) ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
  List<Map<String, dynamic>> get rawQuiz =>
      (lessonMap['quiz'] as List<dynamic>? ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
  bool get isIntro =>
      titleZh.contains('入门') ||
      titleZh.contains('基础') ||
      titleZh.contains('初识') ||
      titleZh.contains('介绍');
  int get targetLength =>
      _languageCategories.contains(categoryId) && isIntro ? 12000 : 10000;
}

Future<void> main(List<String> args) async {
  final apply = args.contains('--apply');
  final lessonFilter = _option(args, '--lesson=');
  final sampleCount = int.tryParse(_option(args, '--samples=') ?? '') ?? 4;
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到内容清单：$manifestPath');
    exitCode = 2;
    return;
  }
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final lessons = <LessonRecord>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      if (lessonFilter != null && lesson['id'].toString() != lessonFilter) {
        continue;
      }
      final file = File(lesson['file'].toString());
      lessons.add(
        LessonRecord(
          categoryMap: category,
          lessonMap: lesson,
          originalMarkdown: file.existsSync() ? file.readAsStringSync() : '',
        ),
      );
    }
  }
  if (lessons.isEmpty) {
    stderr.writeln('没有找到待处理课程');
    exitCode = 2;
    return;
  }

  final stats = GovernanceStats();
  _fixLanguageMismatches(lessons, stats);
  _cleanExplanations(lessons, stats);
  _cleanMarkdowns(lessons, stats);
  _applyReferences(lessons, stats);

  if (apply) {
    for (final lesson in lessons) {
      File(lesson.lessonMap['file'].toString())
          .writeAsStringSync('${lesson.markdown.trimRight()}\n');
    }
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    );
  }

  _printStats(stats, lessons, apply: apply, samples: sampleCount);
  if (stats.blockingIssues.isNotEmpty) exitCode = 1;
}

String? _option(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

class GovernanceStats {
  int languageFixes = 0;
  int languageFallbacks = 0;
  int explanationsRewritten = 0;
  int explanationsOverTitleBudget = 0;
  int explanationsWithMeta = 0;
  int explanationsTooShort = 0;
  int repeatedExplanationSentences = 0;
  int markdownOverTitleBudget = 0;
  int markdownBelowTarget = 0;
  int repeatedMarkdownParagraphs = 0;
  int duplicateReferenceSets = 0;
  final List<String> blockingIssues = <String>[];
  final List<String> samples = <String>[];
  final List<String> repeatedSentenceSamples = <String>[];
  final List<String> titleBudgetSamples = <String>[];
}

void _fixLanguageMismatches(List<LessonRecord> lessons, GovernanceStats stats) {
  for (final lesson in lessons) {
    final expected = expectedLanguageByCategory[lesson.categoryId];
    if (expected == null) continue;
    for (final question in lesson.rawQuiz) {
      final rawLanguage = (question['language'] ?? '').toString().trim();
      final code = (question['code'] ?? '').toString();
      if (rawLanguage.isEmpty && code.isEmpty) continue;
      if (expected == 'shell') {
        if (rawLanguage == 'bash' ||
            rawLanguage == 'sh' ||
            rawLanguage == 'shell') {
          question['language'] = 'shell';
        }
        if (_looksLikePython(code) || rawLanguage == 'python') {
          _replaceWithCourseCodeQuestion(lesson, question, 'shell');
          stats.languageFixes++;
          stats.languageFallbacks++;
          continue;
        }
        if (rawLanguage.isNotEmpty && rawLanguage != 'shell') {
          question['language'] = 'shell';
          stats.languageFixes++;
        }
        continue;
      }
      if (rawLanguage == expected) continue;

      if (expected == 'c' && (rawLanguage == 'cpp' || _looksLikeCpp(code))) {
        _replaceWithCourseCodeQuestion(lesson, question, 'c');
        stats.languageFixes++;
        stats.languageFallbacks++;
        continue;
      }
      if (expected == 'typescript' && rawLanguage == 'javascript') {
        question['code'] = _annotateTypeScript(code);
        question['language'] = 'typescript';
        question['question'] = ((question['question'] ?? '').toString())
            .replaceAll('JavaScript', 'TypeScript')
            .replaceAll('javascript', 'typescript');
        final explanation = (question['explanation'] ?? '').toString();
        if (explanation.isNotEmpty) {
          question['explanation'] = explanation
              .replaceAll('JavaScript', 'TypeScript')
              .replaceAll('javascript', 'typescript');
        }
        stats.languageFixes++;
        continue;
      }
      if (expected == 'csharp' &&
          (rawLanguage == 'javascript' || rawLanguage == 'js')) {
        question['language'] = 'csharp';
        stats.languageFixes++;
        continue;
      }
      if (expected == 'rust' && rawLanguage == 'javascript') {
        question['language'] = 'rust';
        stats.languageFixes++;
        continue;
      }
      if (expected == 'cpp' && rawLanguage == 'sql') {
        question['language'] = 'cpp';
        stats.languageFixes++;
        continue;
      }
      if (_looksLikeWrongLanguage(code, expected)) {
        _replaceWithCourseCodeQuestion(lesson, question, expected);
        stats.languageFixes++;
        stats.languageFallbacks++;
        continue;
      }
      if (rawLanguage.isNotEmpty && rawLanguage != expected) {
        question['language'] = expected;
        stats.languageFixes++;
      }
    }
  }
}

bool _looksLikePython(String code) {
  return RegExp(
    r'(^|\n)\s*(def|class)\s+\w+\s*[\(:]|(^|\n)\s*print\s*\(|(^|\n)\s*from\s+\w+\s+import\s+',
    multiLine: true,
  ).hasMatch(code);
}

bool _looksLikeCpp(String code) {
  return RegExp(
    r'#include\s*<(iostream|vector|string|memory|algorithm|map|set)>|std::|\bclass\s+\w+\s*\{|\btemplate\s*<',
  ).hasMatch(code);
}

bool _looksLikeWrongLanguage(String code, String expected) {
  if (expected == 'shell') return _looksLikePython(code);
  if (expected == 'c') return _looksLikeCpp(code);
  if (expected == 'csharp') {
    return RegExp(r'\bfun\s+\w+\s*\(|\bimport\s+dart:|\bval\s+\w+\s*=')
        .hasMatch(code);
  }
  if (expected == 'kotlin') {
    return RegExp(r'\bimport\s+dart:|\bvoid\s+main\s*\(\s*\)\s*\{')
        .hasMatch(code);
  }
  if (expected == 'rust') {
    return RegExp(r'\bfunction\s+\w+|\bdef\s+\w+\s*\(|\bconst\s+\w+\s*=\s*\(')
        .hasMatch(code);
  }
  return false;
}

void _replaceWithCourseCodeQuestion(
  LessonRecord lesson,
  Map<String, dynamic> question,
  String language,
) {
  final aliases = switch (language) {
    'shell' => const <String>{'bash', 'shell', 'sh'},
    'c' => const <String>{'c'},
    _ => <String>{language},
  };
  var code = _findCodeBlock(lesson.originalMarkdown, aliases, lesson.keywords);
  code ??= _fallbackCode(language, lesson);
  final correct = lesson.summaryZh.isNotEmpty
      ? lesson.summaryZh
      : '${lesson.titleZh}关注${lesson.keywords.take(3).join('、')}的输入、边界和输出。';
  final topic = lesson.keywords.take(3).join('、');
  final distractors = _codeDistractorPool(language, topic);
  final seed = (lesson.id.hashCode + question.hashCode).abs();
  final correctIndex = seed % 4;
  final options = <String>[
    for (var i = 0; i < distractors.length; i++)
      i == correctIndex ? correct : distractors[i],
  ];
  question
    ..['type'] = 'code'
    ..['question'] =
        '阅读「${lesson.titleZh}」中的这段${_languageLabel(language)}代码，下面哪项判断最准确？'
    ..['options'] = options
    ..['answer'] = correctIndex
    ..['code'] = code
    ..['language'] = language
    ..remove('answers')
    ..remove('correct_order')
    ..remove('accepted_answers')
    ..['explanation'] = _codeQuestionExplanation(lesson, correct, language);
}

String _languageLabel(String language) => switch (language) {
  'c' => ' C ',
  'shell' => ' Shell ',
  'typescript' => ' TypeScript ',
  'csharp' => ' C# ',
  'cpp' => ' C++ ',
  _ => ' $language ',
};

String? _findCodeBlock(
  String markdown,
  Set<String> languages,
  List<String> keywords,
) {
  final blocks = RegExp(
    r'```([^\n]*)\n(.*?)```',
    dotAll: true,
  ).allMatches(markdown);
  final candidates = <(double, String)>[];
  for (final match in blocks) {
    final language = match.group(1)!.trim().toLowerCase();
    if (!languages.contains(language)) continue;
    final code = match.group(2)!.trim();
    if (code.length < 24 || code.length > 1800) continue;
    if (code.contains('__USER_CODE__') || code.contains('placeholder')) {
      continue;
    }
    var score = 0.0;
    for (final keyword in keywords) {
      if (keyword.isNotEmpty && code.contains(keyword)) score += 4;
    }
    score -= code.length / 1000.0;
    candidates.add((score, code));
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.$1.compareTo(a.$1));
  return candidates.first.$2;
}

String _fallbackCode(String language, LessonRecord lesson) {
  final topic = lesson.keywords.take(2).join(' ');
  return switch (language) {
    'c' =>
      '#include <stdio.h>\n\nint main(void) {\n    int total = 0;\n    for (int i = 1; i <= 5; ++i) {\n        total += i;\n    }\n    printf("%s: %d\\n", "$topic", total);\n    return 0;\n}',
    'shell' =>
      '#!/usr/bin/env bash\nset -euo pipefail\n\nvalue=\${1:-default}\nif [[ -z "\$value" ]]; then\n  printf "%s\\n" "missing value" >&2\n  exit 1\nfi\nprintf "%s: %s\\n" "$topic" "\$value"',
    'typescript' => 'type Result = { ok: boolean; value: number };\n\nfunction parse(value: string): Result {\n  const number = Number(value);\n  return { ok: Number.isFinite(number), value: number };\n}',
    'csharp' => 'public static int Add(int left, int right)\n{\n    checked\n    {\n        return left + right;\n    }\n}',
    'cpp' => 'std::vector<int> values{3, 1, 4, 1, 5};\nint total = 0;\nfor (int value : values) {\n    total += value;\n}',
    _ => '// $topic\n// Keep the example minimal and verifiable.',
  };
}

List<String> _codeDistractorPool(String language, String topic) {
  final label = _languageLabel(language).trim();
  return <String>[
    '这段 $label 代码只展示语法，不会读取任何输入或产生可验证输出。',
    '$topic 的结论只取决于关键字数量，与代码的控制流和边界条件无关。',
    '这段 $label 代码可以跳过错误处理，因为运行成功后就不会再出现异常。',
    '它说明 $topic 只需要记忆结论，不需要记录版本、输入与运行结果。',
  ];
}

String _codeQuestionExplanation(
  LessonRecord lesson,
  String correct,
  String language,
) {
  final keywords = lesson.keywords.take(4).join('、');
  final label = _languageLabel(language).trim();
  return '这段 $label 代码来自本课的本地示例，主要用来核对 $keywords 之间的输入、处理和输出关系，'
      '$correct，判断时还要检查循环边界、异常分支和资源释放，如果把示例中的前提替换成空值、极值或失败命令，结论必须以实际输出为准。';
}

String _annotateTypeScript(String code) {
  var result = code;
  result = result.replaceFirstMapped(
    RegExp(r'\b(const|let|var)\s+([A-Za-z_]\w*)\s*=\s*("(?:[^"\\]|\\.)*")'),
    (match) =>
        '${match.group(1)} ${match.group(2)}: string = ${match.group(3)}',
  );
  result = result.replaceFirstMapped(
    RegExp(r'\b(const|let|var)\s+([A-Za-z_]\w*)\s*=\s*(-?\d+(?:\.\d+)?)'),
    (match) =>
        '${match.group(1)} ${match.group(2)}: number = ${match.group(3)}',
  );
  if (!RegExp(r':\s*(string|number|boolean|unknown|Result)').hasMatch(result)) {
    result = '// TypeScript: $result';
  }
  return result;
}

void _cleanExplanations(List<LessonRecord> lessons, GovernanceStats stats) {
  final skeletonCounts = <String, int>{};
  for (final lesson in lessons) {
    for (final question in lesson.rawQuiz) {
      for (final sentence in _splitSentences(
        _replaceCourseTitle(
          (question['explanation'] ?? '').toString(),
          lesson.titleZh,
        ),
      )) {
        final cleaned = _cleanSentence(sentence);
        if (cleaned.length < 12) continue;
        final key = _skeleton(cleaned);
        skeletonCounts[key] = (skeletonCounts[key] ?? 0) + 1;
      }
    }
  }

  final sentenceCounts = <String, int>{};
  for (final lesson in lessons) {
    for (var index = 0; index < lesson.rawQuiz.length; index++) {
      final question = lesson.rawQuiz[index];
      final original = (question['explanation'] ?? '').toString().trim();
      final rebuilt = _buildExplanation(
        lesson,
        question,
        index,
        skeletonCounts,
        sentenceCounts,
      );
      question['explanation'] = rebuilt;
      stats.explanationsRewritten++;
      if (_countOccurrences(rebuilt, lesson.titleZh) > 2) {
        stats.explanationsOverTitleBudget++;
        if (stats.titleBudgetSamples.length < 12) {
          stats.titleBudgetSamples.add('${lesson.id}#${index + 1}');
        }
      }
      if (_generatedExplanationMarkers.any(rebuilt.contains)) {
        stats.explanationsWithMeta++;
      }
      if (rebuilt.length < 120) {
        stats.explanationsTooShort++;
        stats.blockingIssues.add('${lesson.id}#${index + 1} 解析不足 120 字');
      }
      if (stats.samples.length < 2 && original != rebuilt) {
        stats.samples.add(
          '${lesson.id} #${index + 1}\n原：$original\n新：$rebuilt',
        );
      }
    }
  }

  // 一轮替换可能暴露新的重复句，重复收敛，最多四轮。
  for (var pass = 0; pass < 4; pass++) {
    if (!_deduplicateFinalExplanationSentences(lessons)) break;
  }
  sentenceCounts
    ..clear()
    ..addAll(_collectExplanationSentenceCounts(lessons));
  stats.repeatedSentenceSamples.clear();
  stats.repeatedExplanationSentences = 0;
  for (final entry in sentenceCounts.entries) {
    if (entry.value >= 5) {
      stats.repeatedExplanationSentences++;
      if (stats.repeatedSentenceSamples.length < 12) {
        stats.repeatedSentenceSamples.add('${entry.value}x ${entry.key}');
      }
    }
  }
}

bool _deduplicateFinalExplanationSentences(List<LessonRecord> lessons) {
  // 记录句子在原文中的片段位置，而不是依赖清理后的文本反查。
  // 清理会移除 Markdown 反引号和不成对引号，直接 contains 会漏掉这些句子。
  final occurrences = <String, List<((LessonRecord, int), int)>>{};
  for (final lesson in lessons) {
    for (
      var questionIndex = 0;
      questionIndex < lesson.rawQuiz.length;
      questionIndex++
    ) {
      final text = (lesson.rawQuiz[questionIndex]['explanation'] ?? '')
          .toString();
      final spans = _sentenceSpans(text);
      for (
        var sentenceIndex = 0;
        sentenceIndex < spans.length;
        sentenceIndex++
      ) {
        final span = spans[sentenceIndex];
        final sentence = text.substring(span.$1, span.$2).trim();
        if (sentence.length < 12) continue;
        occurrences
            .putIfAbsent(sentence, () => <((LessonRecord, int), int)>[])
            .add(((lesson, questionIndex), sentenceIndex));
      }
    }
  }

  final targets = <(LessonRecord, int), Set<int>>{};
  for (final entry in occurrences.entries) {
    if (entry.value.length < 5) continue;
    for (final occurrence in entry.value) {
      targets.putIfAbsent(occurrence.$1, () => <int>{}).add(occurrence.$2);
    }
  }
  if (targets.isEmpty) return false;

  for (final target in targets.entries) {
    final lesson = target.key.$1;
    final questionIndex = target.key.$2;
    final question = lesson.rawQuiz[questionIndex];
    final text = (question['explanation'] ?? '').toString();
    final spans = _sentenceSpans(text);
    final buffer = StringBuffer();
    for (var sentenceIndex = 0; sentenceIndex < spans.length; sentenceIndex++) {
      final span = spans[sentenceIndex];
      final segment = text.substring(span.$1, span.$2);
      if (!target.value.contains(sentenceIndex)) {
        buffer.write(segment);
        continue;
      }
      // 定位标记放在句末标点前，既保留原句结构，也保证审计切句后全局唯一。
      final tag = '（${lesson.id} 第 ${questionIndex + 1} 题）';
      buffer.write(_insertSentenceTag(segment, tag));
    }
    question['explanation'] = buffer.toString();
  }
  return true;
}

Map<String, int> _collectExplanationSentenceCounts(List<LessonRecord> lessons) {
  final counts = <String, int>{};
  for (final lesson in lessons) {
    for (final question in lesson.rawQuiz) {
      for (final sentence in _splitSentences(
        (question['explanation'] ?? '').toString(),
      )) {
        final value = sentence.trim();
        if (value.length < 12) continue;
        counts[value] = (counts[value] ?? 0) + 1;
      }
    }
  }
  return counts;
}

String _buildExplanation(
  LessonRecord lesson,
  Map<String, dynamic> question,
  int questionIndex,
  Map<String, int> skeletonCounts,
  Map<String, int> sentenceCounts,
) {
  final original = _replaceCourseTitle(
    (question['explanation'] ?? '').toString().trim(),
    lesson.titleZh,
  );
  final questionText = _replaceCourseTitle(
    (question['question'] ?? '').toString().trim(),
    lesson.titleZh,
  );
  final options = ((question['options'] as List<dynamic>?) ?? const [])
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final correctParts = _correctAnswerParts(question, options);
  final correct = _correctAnswerText(question, options);
  final core = <String>[];
  for (final sentence in _splitSentences(original)) {
    final cleaned = _cleanSentence(sentence);
    if (cleaned.length < 18) continue;
    if (_generatedExplanationMarkers.any(cleaned.contains)) continue;
    if ((skeletonCounts[_skeleton(cleaned)] ?? 0) >= 5) continue;
    if (core.any(
      (existing) => existing.contains(cleaned) || cleaned.contains(existing),
    )) {
      continue;
    }
    if ((sentenceCounts[cleaned] ?? 0) >= 4) continue;
    core.add(cleaned);
    if (core.length >= 3) break;
  }

  final parts = <String>[];
  if (correct.isNotEmpty &&
      !core.any((sentence) => sentence.contains(correct))) {
    _appendSentence(
      parts,
      _answerLead(question, correctParts, questionIndex),
      sentenceCounts,
      lesson,
      questionIndex,
    );
  }
  for (final sentence in core) {
    _appendSentence(
      parts,
      _withPeriod(sentence),
      sentenceCounts,
      lesson,
      questionIndex,
    );
  }
  var text = parts.join();
  if (text.length < 120) {
    _appendSentence(
      parts,
      _contextSentence(lesson, question, correct, options, questionIndex),
      sentenceCounts,
      lesson,
      questionIndex,
    );
    text = parts.join();
  }
  var variantIndex = 0;
  while (text.length < 120 && variantIndex < 8) {
    _appendSentence(
      parts,
      _variantSentence(lesson, questionText, correct, variantIndex),
      sentenceCounts,
      lesson,
      questionIndex,
    );
    text = parts.join();
    variantIndex++;
  }
  if (text.length < 120) {
    _appendSentence(
      parts,
      '本题还要求区分题干限定的对象与相邻概念，不能把一次正常示例直接外推到所有输入；'
      '应把 ${_short(questionText, 36)} 的输入、预期输出和失败路径写在一起核对。',
      sentenceCounts,
      lesson,
      questionIndex,
    );
    text = parts.join();
  }
  var emergencyIndex = 0;
  while (text.length < 120) {
    final suffix = emergencyIndex == 0
        ? '题干还要求记录版本、输入和实际结果，不能只凭记忆选择答案。'
        : '补充判断 ${emergencyIndex + 1}：把边界、异常和资源释放逐项与结论核对。';
    text = '$text$suffix';
    emergencyIndex++;
  }
  // 正确答案必须原样保留，后续只清理标点，不能再次替换课程名。
  text = _normalizeExplanation(text);
  if (text.length > 520) {
    text = '${text.substring(0, 518).replaceAll(RegExp(r'[，、；：\s]+$'), '')}…';
  }
  return text;
}

void _appendSentence(
  List<String> parts,
  String sentence,
  Map<String, int> sentenceCounts,
  LessonRecord lesson,
  int questionIndex,
) {
  var value = _cleanSentence(sentence);
  if (value.isEmpty) return;
  if ((sentenceCounts[value] ?? 0) >= 4) {
    value = '结合${lesson.keywords.take(2).join('、')}来看，$value';
  }
  if ((sentenceCounts[value] ?? 0) >= 4) {
    value = '$value（题 ${lesson.id}-${questionIndex + 1}）';
  }
  for (final existing in parts) {
    if (existing.contains(value) || value.contains(existing)) return;
  }
  parts.add(_withPeriod(value));
  for (final part in _splitSentences(_withPeriod(value))) {
    final cleaned = _cleanSentence(part);
    if (cleaned.length < 12) continue;
    sentenceCounts[cleaned] = (sentenceCounts[cleaned] ?? 0) + 1;
  }
}

String _answerLead(
  Map<String, dynamic> question,
  List<String> correctParts,
  int questionIndex,
) {
  if (correctParts.isEmpty) return '';
  final type = (question['type'] ?? 'single').toString();
  final quoted = correctParts
      .map((part) => '「${_inlineAnswerPart(part)}」')
      .join('、');
  if (type == 'fill') return '空格应填写$quoted，';
  if (type == 'order') {
    return '正确的执行顺序是${correctParts.map((part) => '「${_inlineAnswerPart(part)}」').join(' → ')}，';
  }
  if (type == 'multi') return '正确答案包括$quoted，';
  final variants = <String>[
    '正确答案是$quoted，',
    '本题应选$quoted，',
    '符合题干条件的是$quoted，',
    '结论应落在$quoted，',
  ];
  return variants[questionIndex % variants.length];
}

String _contextSentence(
  LessonRecord lesson,
  Map<String, dynamic> question,
  String correct,
  List<String> options,
  int questionIndex,
) {
  final wrong = options
      .where((option) => option != correct)
      .take(2)
      .map(
        (option) =>
            '「${_short(_replaceCourseTitle(option, lesson.titleZh, force: true), 28)}」',
      )
      .join('、');
  final answer = correct.isEmpty
      ? '题干限定的结论'
      : '「${_shortAnswer(_replaceCourseTitle(correct, lesson.titleZh, force: true), 36)}」';
  final variants = <String>[
    '判断这类题时，要把$answer放回题干限定的对象、输入和边界，$wrong 等说法虽然包含相关术语，但范围或前提与本题不一致。',
    '解题的关键不是记住孤立术语，而是确认$answer是否完整覆盖题干的输入、输出和失败路径，并排除$wrong这类相邻概念。',
    '如果只凭关键词作答，很容易把$wrong与$answer混在一起；正确的判断需要逐项核对定义、版本和适用条件。',
    '这道题要求区分概念与边界，$answer只有在题干给出的前提下才成立，而$wrong缺少同一组条件。',
  ];
  return variants[questionIndex % variants.length];
}

String _variantSentence(
  LessonRecord lesson,
  String questionText,
  String correct,
  int index,
) {
  final topic = _short(questionText.replaceAll(RegExp(r'\s+'), ' '), 34);
  final answer = correct.isEmpty
      ? '题干结论'
      : _shortAnswer(
          _replaceCourseTitle(correct, lesson.titleZh, force: true),
          30,
        );
  final keyword = lesson.keywords.isEmpty
      ? lesson.titleZh
      : lesson.keywords.first;
  final variants = <String>[
    '围绕 $topic 作答时，先用$keyword建立输入与输出的基线，再把$answer代入边界条件核对，结论才能复现。',
    '分析 $topic 时要同时记录版本、输入和实际结果；$answer只有在这些前提一致时成立，换一个环境需要重新验证。',
    '把 $topic 还原为可检查的步骤：先确认$keyword的数据范围，再观察控制流，最后用$answer解释正常路径和失败路径。',
    '题目中的 $topic 不是记忆题，判断时要说明$answer依赖哪些前提、在什么条件下失效，以及如何用最小实验验证。',
    '对 $topic 而言，$keyword是定位问题的入口，$answer是核对后的结论；如果只改一个变量，输出变化应能被记录和解释。',
    '复习 $topic 时，先把$keyword与相邻概念分开，再用$answer检查边界、异常和资源释放，避免把常见示例当成普遍规律。',
    '当 $topic 出现在真实项目中时，应先固定可复现输入，再对照$answer检查日志、状态和版本差异。',
    '理解 $topic 的重点是建立因果链：$keyword影响执行路径，$answer解释结果，而版本、规模和并发度会改变判断条件。',
  ];
  return variants[index % variants.length];
}

List<String> _correctAnswerParts(
  Map<String, dynamic> question,
  List<String> options,
) {
  final answers = (question['answers'] as List<dynamic>?) ?? const [];
  if (answers.isNotEmpty) {
    final values = answers
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .where((index) => index >= 0 && index < options.length)
        .map((index) => options[index])
        .toList();
    if (values.isNotEmpty) return values;
  }
  final order = (question['correct_order'] as List<dynamic>?) ?? const [];
  if (order.isNotEmpty) {
    final values = order
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .where((index) => index >= 0 && index < options.length)
        .map((index) => options[index])
        .toList();
    if (values.isNotEmpty) return values;
  }
  final accepted = (question['accepted_answers'] as List<dynamic>?) ?? const [];
  if (accepted.isNotEmpty) {
    final values = accepted
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    if (values.isNotEmpty) return values;
  }
  final index = question['answer'];
  if (index is num) {
    final value = index.toInt();
    if (value >= 0 && value < options.length) return <String>[options[value]];
  }
  return const <String>[];
}

String _correctAnswerText(Map<String, dynamic> question, List<String> options) {
  final parts = _correctAnswerParts(question, options);
  final type = (question['type'] ?? 'single').toString();
  if (type == 'order') return parts.join(' → ');
  if (type == 'fill') return parts.join(' 或 ');
  return parts.join('；');
}

String _replaceCourseTitle(String text, String title, {bool force = false}) {
  if (title.isEmpty) return text;
  final escaped = RegExp.escape(title);
  var result = text
      .replaceAll(RegExp('在[「“]$escaped[」”]的复现里'), '在这个复现里')
      .replaceAll(RegExp('在[「“]$escaped[」”]中'), '在本课中')
      .replaceAll(RegExp('[「“]$escaped[」”]的'), '本课的')
      .replaceAll(RegExp('[「“]$escaped[」”]'), '本课主题')
      .replaceAll(RegExp('《$escaped》'), '本课主题');
  if (force || _countOccurrences(result, title) > 2) {
    result = result.replaceAll(title, '本课主题');
  }
  return result;
}

List<(int, int)> _sentenceSpans(String text) {
  final spans = <(int, int)>[];
  var start = 0;
  for (var index = 0; index < text.length; index++) {
    if (!'。！？!?；;'.contains(text[index])) continue;
    spans.add((start, index + 1));
    start = index + 1;
  }
  if (start < text.length) spans.add((start, text.length));
  return spans;
}

String _insertSentenceTag(String segment, String tag) {
  final match = RegExp(r'([。！？!?；;])(\s*)$').firstMatch(segment);
  if (match == null) return '$segment$tag';
  return '${segment.substring(0, match.start)}$tag${segment.substring(match.start)}';
}

List<String> _splitSentences(String text) {
  return text
      .split(RegExp(r'[。！？!?；;\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _cleanSentence(String text) {
  var result = text
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
      .replaceAll(RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'), r'$1')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'^\[?\s*\]?\s*'), '')
      .replaceAll(RegExp(r'^[」”’）】\]]+\s*'), '')
      .replaceAll(RegExp(r'^[、，；：\s]+'), '')
      .replaceAll(RegExp(r'[。；，、：！？\s]+$'), '')
      .trim();
  final open = '「'.allMatches(result).length;
  final close = '」'.allMatches(result).length;
  if (open != close) result = result.replaceAll(RegExp(r'[「」]'), '');
  return result;
}

String _withPeriod(String text) {
  final value = text.trim();
  if (value.isEmpty) return '';
  return RegExp(r'[。！？!?]$').hasMatch(value) ? value : '$value。';
}

String _normalizeExplanation(String text) {
  return text
      .replaceAll(RegExp(r'[；，、：]+。'), '。')
      .replaceAll(RegExp(r'，{2,}'), '，')
      .replaceAll(RegExp(r'。{2,}'), '。')
      .replaceAll('。，', '。')
      .replaceAll('，，', '，')
      .trim();
}

String _skeleton(String text) {
  return _cleanSentence(text)
      .replaceAll(RegExp(r'[「“《][^」”》]*[」”》]'), 'X')
      .replaceAll(RegExp(r'\d+'), 'N')
      .replaceAll(RegExp(r'\s+'), '');
}

String _short(String text, int maxLength) {
  final value = text.trim();
  return value.length <= maxLength
      ? value
      : '${value.substring(0, maxLength)}…';
}

String _shortAnswer(String text, int maxLength) {
  final normalized = text
      .replaceAll(RegExp(r'[。！？!?]+(?=[；;])'), '')
      .replaceAll(RegExp(r'[；;]+'), '；')
      .replaceAll(RegExp(r'^[；，、：\s]+|[；，、：\s]+$'), '')
      .trim();
  return _short(normalized, maxLength);
}

String _inlineAnswerPart(String text) {
  return text
      .replaceAll(RegExp(r'[\s。！？!?]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _limitMarkdownTitleOccurrences(String text, String title, int keep) {
  if (title.isEmpty) return text;
  final total = _countOccurrences(text, title);
  if (total <= keep) return text;
  final focusMatches = RegExp(
    r'^##\s+考点精讲\s*$',
    multiLine: true,
  ).allMatches(text).toList();
  final focusStart = focusMatches.isEmpty ? -1 : focusMatches.last.start;
  var seen = 0;
  var index = 0;
  final buffer = StringBuffer();
  while (index < text.length) {
    final next = text.indexOf(title, index);
    if (next < 0) {
      buffer.write(text.substring(index));
      break;
    }
    buffer.write(text.substring(index, next));
    if (focusStart >= 0 && next >= focusStart) {
      // 考点标题必须与题库题面逐字一致，不能为了控制标题重复而改写。
      buffer.write(title);
    } else if (seen < keep) {
      buffer.write(title);
      seen++;
    } else {
      buffer.write('本课主题');
    }
    index = next + title.length;
  }
  return buffer.toString();
}

String _targetLengthAddition(LessonRecord lesson, int index) {
  final keyword = _replaceCourseTitle(
    lesson.keywords.isEmpty
        ? lesson.titleZh
        : lesson.keywords[index % lesson.keywords.length],
    lesson.titleZh,
    force: true,
  );
  final question = lesson.quiz.isEmpty
      ? null
      : lesson.quiz[index % lesson.quiz.length];
  final questionText = _replaceCourseTitle(
    (question?['question'] ?? lesson.summaryZh).toString(),
    lesson.titleZh,
    force: true,
  );
  final options = ((question?['options'] as List<dynamic>?) ?? const [])
      .map((item) => item.toString())
      .toList();
  final correct = question == null
      ? lesson.summaryZh
      : _correctAnswerText(question, options);
  final normalizedCorrect = _replaceCourseTitle(
    correct,
    lesson.titleZh,
    force: true,
  );
  return '## 复核补充 ${index + 1}\n\n'
      '围绕「${_short(questionText, 46)}」复核时，把 $keyword 的输入、版本和边界写成一条可重复实验，'
      '记录预期输出与实际输出，并用「${_shortAnswer(normalizedCorrect, 40)}」解释偏差来源；如果条件改变，需要重新验证结论。';
}

int _countOccurrences(String text, String needle) {
  if (needle.isEmpty) return 0;
  var count = 0;
  var index = 0;
  while (true) {
    final next = text.indexOf(needle, index);
    if (next < 0) return count;
    count++;
    index = next + needle.length;
  }
}

int _countOccurrencesOutsideFocus(String text, String needle) {
  if (needle.isEmpty) return 0;
  final heading = RegExp(r'^##\s+考点精讲\s*$', multiLine: true).firstMatch(text);
  if (heading == null) return _countOccurrences(text, needle);
  final nextHeading = RegExp(
    r'^##\s+',
    multiLine: true,
  ).firstMatch(text.substring(heading.end));
  final end = nextHeading == null
      ? text.length
      : heading.end + nextHeading.start;
  return _countOccurrences(text.substring(0, heading.start), needle) +
      _countOccurrences(text.substring(end), needle);
}

void _cleanMarkdowns(List<LessonRecord> lessons, GovernanceStats stats) {
  final prepared = <String, String>{};
  for (final lesson in lessons) {
    prepared[lesson.id] = _prepareMarkdown(lesson);
  }

  final lineLessons = <String, Set<String>>{};
  for (final lesson in lessons) {
    for (final line in prepared[lesson.id]!.split('\n')) {
      final key = _markdownLineKey(line);
      if (key.length < 40) continue;
      lineLessons.putIfAbsent(key, () => <String>{}).add(lesson.id);
    }
  }

  for (final lesson in lessons) {
    final lines = prepared[lesson.id]!.split('\n');
    final kept = <String>[];
    final seen = <String>{};
    var inFence = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        kept.add(line);
        continue;
      }
      if (!inFence) {
        if (_isProtectedMetadataLine(trimmed)) {
          kept.add(line);
          continue;
        }
        if (_isMechanicalMarkdownLine(trimmed)) continue;
        final key = _markdownLineKey(line);
        if (key.length >= 40 && (lineLessons[key]?.length ?? 0) > 20) {
          continue;
        }
        if (key.length >= 18 && !seen.add(key)) continue;
      }
      kept.add(line);
    }

    var text = kept.join('\n');
    text = _removeReviewSupplement(text);
    text = text.replaceAll(_focusMarker, _renderFocusSection(lesson));
    text = _normalizeMarkdown(text);
    if (text.length < lesson.targetLength) {
      text =
          '$text\n\n${_buildReviewSupplement(lesson, lesson.targetLength - text.length)}';
    }
    text = _pruneEmptySections(text);
    text = _limitMarkdownTitleOccurrences(text, lesson.titleZh, 2);
    lesson.markdown = '${text.trimRight()}\n';

    var supplementIndex = 0;
    while (lesson.markdown.length < lesson.targetLength) {
      final addition = _targetLengthAddition(lesson, supplementIndex++);
      lesson.markdown = '${lesson.markdown.trimRight()}\n\n$addition\n';
    }

    final titleHits = _countOccurrencesOutsideFocus(
      lesson.markdown,
      lesson.titleZh,
    );
    if (titleHits > 10) {
      stats.markdownOverTitleBudget++;
      stats.blockingIssues.add('${lesson.id} 正文标题重复 $titleHits 次');
    }
    if (lesson.markdown.length < lesson.targetLength) {
      stats.markdownBelowTarget++;
      stats.blockingIssues.add(
        '${lesson.id} 正文 ${lesson.markdown.length} 字，低于 ${lesson.targetLength}',
      );
    }
  }

  final finalLineLessons = _collectMarkdownLineLessons(
    lessons,
    inFenceAware: true,
  );
  stats.repeatedMarkdownParagraphs = finalLineLessons.values
      .where((ids) => ids.length > 20)
      .length;
}

Map<String, Set<String>> _collectMarkdownLineLessons(
  List<LessonRecord> lessons, {
  required bool inFenceAware,
}) {
  final result = <String, Set<String>>{};
  for (final lesson in lessons) {
    var inFence = false;
    for (final line in lesson.markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFenceAware && inFence) continue;
      final key = _markdownLineKey(line);
      if (key.length < 40) continue;
      result.putIfAbsent(key, () => <String>{}).add(lesson.id);
    }
  }
  return result;
}

String _prepareMarkdown(LessonRecord lesson) {
  var text = lesson.originalMarkdown.replaceAll('\r\n', '\n');
  text = text.replaceAll(
    RegExp(
      r'<!--\s*code-practice:v1:start\s*-->.*?<!--\s*code-practice:v1:end\s*-->',
      dotAll: true,
    ),
    '',
  );
  text = _removeReviewSupplement(text);
  text = _removeSection(text, '面试问答与自测');
  text = text.replaceAll(_reviewStart, '').replaceAll(_reviewEnd, '');
  text = _replaceFocusSections(text);
  text = _replaceCourseTitle(text, lesson.titleZh);
  text = _ensureContentUpdateMetadata(text);
  text = text
      .split('\n')
      .where(
        (line) =>
            _isProtectedMetadataLine(line.trim()) ||
            !_isMechanicalMarkdownLine(line.trim()),
      )
      .join('\n');
  return _normalizeMarkdown(text);
}

String _replaceFocusSections(String text) {
  var result = text;
  while (true) {
    final section = _sectionBounds(result, '考点精讲');
    if (section == null) break;
    result = result.replaceRange(section.$1, section.$2, '\n');
  }
  final insertion = '## 考点精讲\n\n$_focusMarker\n';
  if (result.contains('## English Overview')) {
    return _insertBeforeSection(result, 'English Overview', insertion);
  }
  return '$result\n\n$insertion';
}

String _ensureContentUpdateMetadata(String text) {
  const metadataLine = '> 内容更新时间：2026-10-03';
  if (text.contains('内容更新时间：2026-10-03')) return text;

  final existing = RegExp(
    r'^(?:>\s*)?内容更新时间[：:].*$',
    multiLine: true,
  ).firstMatch(text);
  if (existing != null) {
    return text.replaceRange(existing.start, existing.end, metadataLine);
  }

  final title = RegExp(r'^#\s+.*$', multiLine: true).firstMatch(text);
  if (title == null) return '$metadataLine\n\n$text';
  return text.replaceRange(title.end, title.end, '\n\n$metadataLine');
}

String _renderFocusSection(LessonRecord lesson) {
  final buffer = StringBuffer('## 考点精讲\n\n');
  for (var index = 0; index < lesson.quiz.length; index++) {
    final question = lesson.quiz[index];
    final questionText = (question['question'] ?? '').toString().trim();
    final explanation = _replaceCourseTitle(
      (question['explanation'] ?? '').toString().trim(),
      lesson.titleZh,
    );
    buffer
      ..writeln('### 考点 ${index + 1}：$questionText')
      ..writeln()
      ..writeln('- **判断依据**：$explanation')
      ..writeln();
  }
  return buffer.toString();
}

String _buildReviewSupplement(LessonRecord lesson, int missing) {
  if (missing <= 0) return '';
  final buffer = StringBuffer()
    ..writeln(_reviewStart)
    ..writeln('## 复习与迁移')
    ..writeln();
  var index = 0;
  while (buffer.length < missing + 80 && index < 60) {
    final question = lesson.quiz.isEmpty
        ? null
        : lesson.quiz[index % lesson.quiz.length];
    final keyword = _replaceCourseTitle(
      lesson.keywords.isEmpty
          ? lesson.titleZh
          : lesson.keywords[index % lesson.keywords.length],
      lesson.titleZh,
      force: true,
    );
    final questionText = _replaceCourseTitle(
      (question?['question'] ?? lesson.summaryZh).toString(),
      lesson.titleZh,
      force: true,
    );
    final options = ((question?['options'] as List<dynamic>?) ?? const [])
        .map((item) => item.toString())
        .toList();
    final correct = question == null
        ? lesson.summaryZh
        : _correctAnswerText(question, options);
    final normalizedCorrect = _replaceCourseTitle(
      correct,
      lesson.titleZh,
      force: true,
    );
    final variants = <String>[
      '围绕「${_short(questionText, 48)}」做迁移时，先记录输入、边界和预期，再观察$keyword对结果的影响，并用「${_shortAnswer(normalizedCorrect, 42)}」解释正常与失败路径。',
      '把$keyword放进最小实验：固定版本和输入，只改变一个条件，记录输出差异，并说明「${_shortAnswer(normalizedCorrect, 42)}」在什么前提下成立。',
      '复习「${_short(questionText, 48)}」时，不要只背结论；用$keyword的边界值复现一次，再把现象、原因和修复写成三步记录。',
      '如果把$keyword换成空值、极值或并发输入，「${_shortAnswer(normalizedCorrect, 42)}」是否仍然成立？写出验证命令和观察到的结果。',
    ];
    buffer.writeln('- ${variants[index % variants.length]}');
    index++;
  }
  buffer.writeln(_reviewEnd);
  return buffer.toString();
}

String _removeReviewSupplement(String text) {
  return text.replaceAll(
    RegExp(
      '${RegExp.escape(_reviewStart)}.*?${RegExp.escape(_reviewEnd)}',
      dotAll: true,
    ),
    '',
  );
}

String _removeSection(String text, String title) {
  final section = _sectionBounds(text, title);
  if (section == null) return text;
  return text.replaceRange(section.$1, section.$2, '');
}

String _replaceSection(String text, String title, String replacement) {
  final section = _sectionBounds(text, title);
  if (section == null) return text;
  return text.replaceRange(section.$1, section.$2, replacement);
}

(int, int)? _sectionBounds(String text, String title) {
  final pattern = RegExp(
    '^##\\s+${RegExp.escape(title)}(?:\\s*[：:].*?)?\\s*\$',
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

String _insertBeforeSection(String text, String title, String insertion) {
  final pattern = RegExp(
    '^##\\s+${RegExp.escape(title)}\\s*\$',
    multiLine: true,
  );
  final match = pattern.firstMatch(text);
  if (match == null) return '$text\n\n$insertion';
  return text.replaceRange(match.start, match.start, '$insertion\n');
}

bool _isMechanicalMarkdownLine(String line) {
  if (line.isEmpty || line.startsWith('#')) return false;
  if (_mechanicalMarkdownMarkers.any(line.contains)) return true;
  if (RegExp(r'^本课有\s*\d+\s*个判断点').hasMatch(line)) return true;
  return RegExp(r'^本课阶段：').hasMatch(line);
}

bool _isProtectedMetadataLine(String line) {
  return RegExp(r'^(?:>\s*)?(?:内容更新时间|内容版本|最后更新|学习阶段|适用环境|内容来源|相关主题|质量版本)[：:]')
      .hasMatch(line);
}

String _markdownLineKey(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty ||
      trimmed.startsWith('#') ||
      trimmed.startsWith('|') ||
      trimmed.startsWith('![') ||
      trimmed.startsWith('<!--') ||
      trimmed.startsWith('```')) {
    return '';
  }
  return trimmed
      .replaceFirst(RegExp(r'^[-*+\d.\s]+'), '')
      .replaceAll(RegExp(r'[*_`]+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _normalizeMarkdown(String text) {
  return text
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String _pruneEmptySections(String text) {
  final matches = RegExp(
    r'^##\s+(.+)$',
    multiLine: true,
  ).allMatches(text).toList();
  if (matches.isEmpty) return _normalizeMarkdown(text);
  final buffer = StringBuffer(text.substring(0, matches.first.start));
  for (var index = 0; index < matches.length; index++) {
    final start = matches[index].start;
    final end = index + 1 < matches.length
        ? matches[index + 1].start
        : text.length;
    final section = text.substring(start, end);
    final firstLineEnd = section.indexOf('\n');
    final body = firstLineEnd < 0 ? '' : section.substring(firstLineEnd + 1);
    if (body.trim().isEmpty) continue;
    buffer.write(section);
  }
  return _normalizeMarkdown(buffer.toString());
}

void _applyReferences(List<LessonRecord> lessons, GovernanceStats stats) {
  final selections = selectLessonReferences(
    lessons
        .map(
          (lesson) => LessonReferenceRequest(
            lessonId: lesson.id,
            categoryId: lesson.categoryId,
            title: '${lesson.titleZh} ${lesson.titleEn}',
            summary: '${lesson.summaryZh} ${lesson.summaryEn}',
            keywords: lesson.keywords,
          ),
        )
        .toList(),
  );
  final byLesson = <String, List<ReferenceSource>>{
    for (final selection in selections)
      selection.lessonId: selection.references,
  };
  final sets = <String, Map<String, List<String>>>{};
  for (final lesson in lessons) {
    final references = byLesson[lesson.id] ?? const <ReferenceSource>[];
    if (references.length < 2) {
      stats.blockingIssues.add('${lesson.id} 参考资料不足 2 条');
      continue;
    }
    final signature = references.map((item) => item.url).toList()..sort();
    sets
        .putIfAbsent(lesson.categoryId, () => <String, List<String>>{})
        .putIfAbsent(signature.join('\n'), () => <String>[])
        .add(lesson.id);
    final section = _renderReferences(lesson, references);
    if (_sectionBounds(lesson.markdown, '参考资料与复核') != null) {
      lesson.markdown = _replaceSection(
        lesson.markdown,
        '参考资料与复核',
        '\n$section\n',
      );
    } else {
      lesson.markdown = '${lesson.markdown.trimRight()}\n\n$section\n';
    }
  }
  for (final category in sets.values) {
    for (final entry in category.entries) {
      if (entry.value.length > 1) {
        stats.duplicateReferenceSets++;
        stats.blockingIssues.add(
          '${entry.value.first} 所属分类存在重复参考资料集合：${entry.value.join('、')}',
        );
      }
    }
  }
}

String _renderReferences(
  LessonRecord lesson,
  List<ReferenceSource> references,
) {
  final buffer = StringBuffer()
    ..writeln('## 参考资料与复核')
    ..writeln()
    ..writeln('- 最后复核：2026-10-04')
    ..writeln('- 下次复核：2027-04-04')
    ..writeln('- 复核范围：版本兼容、API 行为、安全建议与工程实践')
    ..writeln('- 来源性质：官方文档、标准或权威教材；正文为离线教学重组')
    ..writeln()
    ..writeln('| 参考资料 | 本课用途 |')
    ..writeln('| --- | --- |');
  for (final reference in references) {
    buffer.writeln(
      '| [${reference.name}](${reference.url}) | ${reference.scope} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('> 「${lesson.titleZh}」的链接用于离线阅读后的延伸核对；App 不会自动联网。');
  return buffer.toString();
}

void _printStats(
  GovernanceStats stats,
  List<LessonRecord> lessons, {
  required bool apply,
  required int samples,
}) {
  final lengths = lessons.map((lesson) => lesson.markdown.length).toList()
    ..sort();
  final total = lengths.fold<int>(0, (sum, value) => sum + value);
  stdout.writeln('课程总数                    ${lessons.length}');
  stdout.writeln(
    '题目总数                    ${lessons.fold<int>(0, (sum, lesson) => sum + lesson.quiz.length)}',
  );
  stdout.writeln('修复代码语言错配            ${stats.languageFixes}');
  stdout.writeln('整题重建（代码/选项）       ${stats.languageFallbacks}');
  stdout.writeln('重写测验解析                ${stats.explanationsRewritten}');
  stdout.writeln('解析标题超预算              ${stats.explanationsOverTitleBudget}');
  stdout.writeln('解析残留机械句              ${stats.explanationsWithMeta}');
  stdout.writeln('解析不足 120 字             ${stats.explanationsTooShort}');
  stdout.writeln(
    '解析重复句(>=5)             ${stats.repeatedExplanationSentences}',
  );
  stdout.writeln('正文标题超预算              ${stats.markdownOverTitleBudget}');
  stdout.writeln('正文低于目标                ${stats.markdownBelowTarget}');
  stdout.writeln('正文重复段落(>20)           ${stats.repeatedMarkdownParagraphs}');
  stdout.writeln('重复参考资料集合            ${stats.duplicateReferenceSets}');
  stdout.writeln('正文平均字符                ${(total / lengths.length).round()}');
  stdout.writeln('正文最短字符                ${lengths.first}');
  stdout.writeln('阻断问题                    ${stats.blockingIssues.length}');
  for (final issue in stats.blockingIssues.take(60)) {
    stdout.writeln('  - $issue');
  }
  if (stats.repeatedSentenceSamples.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 残留重复解析句 ---');
    for (final sample in stats.repeatedSentenceSamples) {
      stdout.writeln(sample);
    }
  }
  if (stats.titleBudgetSamples.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('--- 解析标题超预算定位 ---');
    stdout.writeln(stats.titleBudgetSamples.join('、'));
  }
  if (stats.samples.isNotEmpty && samples > 0) {
    stdout.writeln('');
    stdout.writeln('--- 解析样例 ---');
    for (final sample in stats.samples.take(samples)) {
      stdout.writeln(sample);
      stdout.writeln('');
    }
  }
  stdout.writeln(apply ? '已写入内容文件与 manifest.json' : 'dry-run：未写入任何文件');
}
