// P0 内容治理：给只有单选题的课程补一道可判分的特殊题。
//
// 用法：
//   dart tool/p0_add_interactive_questions.dart [--dry-run] [--samples=8]
//
// 生成策略（按优先级）：
//   1. 关键流程/实践路径/排查步骤里的编号列表 -> 排序题；
//   2. 术语速查表或代码示例中的关键标识符 -> 填空题；
//   3. 本课关键词 + 其他课程关键词 -> 多选题（兜底）。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const Set<String> _processSectionWords = <String>{
  '流程', '步骤', '路径', '顺序', '排查', '操作', '调试', '迁移', '工作流',
};

const Set<String> _codeStopWords = <String>{
  'int', 'var', 'let', 'const', 'if', 'else', 'for', 'while', 'function',
  'class', 'def', 'import', 'from', 'public', 'private', 'static', 'void',
  'string', 'str', 'bool', 'true', 'false', 'null', 'none', 'self', 'this',
  'new', 'async', 'await', 'return', 'print', 'echo', 'end', 'begin', 'do',
  'switch', 'case', 'break', 'continue', 'try', 'catch', 'finally', 'throw',
  'package', 'namespace', 'using', 'struct', 'enum', 'interface', 'type',
  'x', 'y', 'z', 'a', 'b', 'c', 'i', 'j', 'k', 'n', 'm', 'id', 'key',
  'value', 'data', 'item', 'items', 'list', 'map', 'set', 'get', 'put',
  'the', 'and', 'or', 'not', 'is', 'as', 'in', 'of', 'to', 'with',
};

class Section {
  const Section(this.title, this.body);

  final String title;
  final String body;
}

class LessonInfo {
  LessonInfo({
    required this.json,
    required this.category,
    required this.id,
    required this.title,
    required this.summary,
    required this.keywords,
    required this.markdown,
    required this.sections,
  });

  final Map<String, dynamic> json;
  final String category;
  final String id;
  final String title;
  final String summary;
  final List<String> keywords;
  final String markdown;
  final List<Section> sections;
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final sampleCount =
      int.tryParse(_option(args, '--samples=') ?? '') ?? 8;
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List<dynamic>)
      .map((raw) => (raw as Map).cast<String, dynamic>())
      .toList();

  final lessons = <LessonInfo>[];
  for (final category in categories) {
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final markdown = File(lesson['file'] as String).readAsStringSync();
      lessons.add(
        LessonInfo(
          json: lesson,
          category: category['id'] as String,
          id: lesson['id'] as String,
          title: ((lesson['title'] as Map?)?['zh'] ?? '') as String,
          summary: ((lesson['summary'] as Map?)?['zh'] ?? '') as String,
          keywords: ((lesson['keywords'] as List<dynamic>?) ?? const [])
              .map((e) => '$e'.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          markdown: markdown,
          sections: _parseSections(markdown),
        ),
      );
    }
  }

  final questionTexts = <String>{
    for (final lesson in lessons)
      for (final raw in lesson.json['quiz'] as List<dynamic>)
        _normalizeQuestion(((raw as Map)['question'] as String?) ?? ''),
  };
  final globalKeywords = <String, List<LessonInfo>>{};
  for (final lesson in lessons) {
    for (final keyword in lesson.keywords) {
      globalKeywords.putIfAbsent(keyword, () => <LessonInfo>[]).add(lesson);
    }
  }

  var added = 0;
  var skippedExisting = 0;
  var orderCount = 0;
  var fillCount = 0;
  var multiCount = 0;
  var failed = 0;
  var fillFromCode = 0;
  var shortExplanation = 0;
  var duplicateQuestion = 0;
  var metaQuestion = 0;
  final samples = <String>[];

  for (final lesson in lessons) {
    final quiz = (lesson.json['quiz'] as List<dynamic>)
        .map((raw) => (raw as Map).cast<String, dynamic>())
        .toList();
    if (quiz.any((q) => ((q['type'] as String?) ?? 'single') != 'single')) {
      skippedExisting++;
      continue;
    }

    Map<String, dynamic>? question = _buildOrderQuestion(lesson);
    if (question != null) {
      orderCount++;
    } else {
      question = _buildFillQuestion(lesson);
      if (question != null) {
        fillCount++;
        if (question['_from_code'] == true) fillFromCode++;
        question.remove('_from_code');
      }
    }
    if (question == null) {
      question = _buildMultiQuestion(lesson, globalKeywords);
      if (question != null) multiCount++;
    }
    if (question == null) {
      failed++;
      continue;
    }

    final normalized = _normalizeQuestion(question['question'] as String);
    if (questionTexts.contains(normalized)) {
      duplicateQuestion++;
      continue;
    }
    questionTexts.add(normalized);
    if (RegExp(r'《[^》]+》').hasMatch(question['question'] as String)) {
      metaQuestion++;
    }
    if (((question['explanation'] as String?) ?? '').trim().length < 120) {
      shortExplanation++;
    }
    quiz.add(question);
    lesson.json['quiz'] = quiz;
    added++;
    if (samples.length < sampleCount) {
      samples.add(
        '--- ${lesson.id} [${question['type']}] ---\n'
        'Q: ${question['question']}\n'
        'A: ${question['explanation']}\n',
      );
    }
  }

  final missingAfter = lessons
      .where(
        (lesson) => !(lesson.json['quiz'] as List<dynamic>).any(
          (raw) => (((raw as Map)['type'] as String?) ?? 'single') != 'single',
        ),
      )
      .length;
  stdout.writeln('课程总数              ${lessons.length}');
  stdout.writeln('已有特殊题型          $skippedExisting');
  stdout.writeln('新增题目              $added');
  stdout.writeln('  排序题              $orderCount');
  stdout.writeln('  填空题              $fillCount（代码填空 $fillFromCode）');
  stdout.writeln('  多选题              $multiCount');
  stdout.writeln('无法生成              $failed');
  stdout.writeln('题干重复被跳过        $duplicateQuestion');
  stdout.writeln('题干含《》             $metaQuestion');
  stdout.writeln('解析 <120             $shortExplanation');
  stdout.writeln('新增后仍无特殊题型    $missingAfter');
  for (final sample in samples) {
    stdout.writeln('');
    stdout.writeln(sample);
  }

  if (dryRun) {
    stdout.writeln('dry-run：未写入 manifest.json');
    return;
  }
  manifestFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('已写入 $manifestPath');
}

Map<String, dynamic>? _buildOrderQuestion(LessonInfo lesson) {
  for (final section in lesson.sections) {
    if (!_processSectionWords.any(section.title.contains)) continue;
    final items = _numberedItems(section.body);
    if (items.length < 3) continue;
    final steps = items.take(4).toList();
    if (steps.length < 3) continue;
    final correctOrder = List<int>.generate(steps.length, (i) => i);
    final answer = steps.join(' → ');
    final explanation =
        '正确答案是「$answer」。本课在「${section.title}」中给出的顺序存在依赖关系：'
        '${steps[0]}，先确定输入或前提；随后${steps[1]}；再${steps[2]}'
        '${steps.length > 3 ? '，最后${steps[3]}' : ''}；'
        '如果交换其中两步，后续步骤会缺少前一步产生的结果，因此不能得到稳定结论。';
    return <String, dynamic>{
      'type': 'order',
      'question': '把「${lesson.title}」中「${section.title}」的步骤调整为正确顺序。',
      'options': steps,
      'answer': 0,
      'correct_order': correctOrder,
      'explanation': _padExplanation(explanation, lesson),
    };
  }
  return null;
}

Map<String, dynamic>? _buildFillQuestion(LessonInfo lesson) {
  final terminology = _buildTerminologyFill(lesson);
  if (terminology != null) return terminology;
  return _buildCodeFill(lesson);
}

Map<String, dynamic>? _buildTerminologyFill(LessonInfo lesson) {
  Section? section;
  for (final candidate in lesson.sections) {
    if (candidate.title.contains('术语速查')) {
      section = candidate;
      break;
    }
  }
  if (section == null) return null;
  for (final line in section.body.split('\n')) {
    final match = RegExp(r'^\|\s*`([^`]+)`\s*\|\s*(.+?)\s*\|$')
        .firstMatch(line.trim());
    if (match == null) continue;
    final term = match.group(1)!.trim();
    var definition = match.group(2)!.trim().replaceAll(r'\|', '|');
    if (term.length < 2 || term.length > 30) continue;
    if (definition.length < 18 || definition.length > 140) continue;
    final blanked = definition.contains(term)
        ? definition.replaceAll(term, '____')
        : '____：$definition';
    final explanation =
        '正确答案是「$term」。本课术语速查给出的解释是：$definition。'
        '该术语出现在「${lesson.title}」的正文中，是理解相关概念和代码示例的关键；'
        '把术语与定义对应起来，才能在题干改变输入、边界或失败条件时正确判断。';
    return <String, dynamic>{
      'type': 'fill',
      'question': '填空：「${lesson.title}」术语速查中，表示「$blanked」的术语是什么？',
      'options': <String>[],
      'answer': 0,
      'accepted_answers': <String>[
        term,
        if (term.toLowerCase() != term) term.toLowerCase(),
      ],
      'explanation': _padExplanation(explanation, lesson),
    };
  }
  return null;
}

Map<String, dynamic>? _buildCodeFill(LessonInfo lesson) {
  final blocks = _codeBlocks(lesson.markdown);
  if (blocks.isEmpty) return null;
  final prose = lesson.markdown
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .toLowerCase();
  String? bestLine;
  String? bestToken;
  String? bestSection;
  var bestScore = 0.0;
  for (final block in blocks) {
    for (final rawLine in block.code.split('\n')) {
      final line = rawLine.trim();
      if (line.length < 16 || line.length > 90) continue;
      if (line.startsWith('//') || line.startsWith('#')) continue;
      final tokens = RegExp(r'[A-Za-z_][A-Za-z0-9_]{2,}')
          .allMatches(line)
          .map((m) => m.group(0)!)
          .toSet();
      for (final token in tokens) {
        final lower = token.toLowerCase();
        if (_codeStopWords.contains(lower)) continue;
        if (token.length < 3 || token.length > 24) continue;
        if (!prose.contains(lower)) continue;
        final occurrences = RegExp(
          RegExp.escape(token),
          caseSensitive: false,
        ).allMatches(line).length;
        if (occurrences != 1) continue;
        var score = token.length.toDouble();
        if (line.contains('$token(')) score += 3;
        if (line.contains('.$token') || line.contains('$token.')) score += 2;
        if (line.contains('=')) score += 1;
        if (block.sectionTitle.toLowerCase().contains(lower)) score += 2;
        if (score > bestScore) {
          bestScore = score;
          bestLine = line;
          bestToken = token;
          bestSection = block.sectionTitle;
        }
      }
    }
  }
  if (bestLine == null || bestToken == null || bestScore < 7) return null;
  final masked = bestLine.replaceFirst(bestToken, '____');
  final context = _proseSentence(lesson.markdown, bestToken);
  final explanation =
      '正确答案是「$bestToken」。本课示例中的完整写法是 `$bestLine`，'
      '它出现在「${bestSection ?? '代码示例'}」一节。$bestToken 是完成这条语句的关键部分，'
      '去掉或替换它就无法表达同样的语义，也得不到示例给出的结果。'
      '${context.isEmpty ? '' : '本课还说明：$context。'}';
  return <String, dynamic>{
    'type': 'fill',
    'question': '补全代码：「${lesson.title}」示例中，下面这行代码缺少哪个关键字或函数名？请填入 ____。\n\n`$masked`',
    'options': <String>[],
    'answer': 0,
    'accepted_answers': <String>[
      bestToken,
      if (bestToken.toLowerCase() != bestToken) bestToken.toLowerCase(),
    ],
    'explanation': _padExplanation(explanation, lesson),
    '_from_code': true,
  };
}

Map<String, dynamic>? _buildMultiQuestion(
  LessonInfo lesson,
  Map<String, List<LessonInfo>> globalKeywords,
) {
  final correct = <String>[];
  for (final keyword in lesson.keywords) {
    if (keyword.length < 2 || keyword.length > 20) continue;
    if (correct.any((e) => e.contains(keyword) || keyword.contains(e))) continue;
    if (lesson.markdown.contains(keyword)) correct.add(keyword);
    if (correct.length >= 2) break;
  }
  if (correct.length < 2) {
    for (final candidate in _splitTerms('${lesson.title}、${lesson.summary}')) {
      if (candidate.length < 2 || candidate.length > 20) continue;
      if (lesson.keywords.contains(candidate)) continue;
      if (correct.any((e) => e.contains(candidate) || candidate.contains(e))) {
        continue;
      }
      correct.add(candidate);
      if (correct.length >= 2) break;
    }
  }
  if (correct.length < 2) return null;

  final distractors = <String>[];
  final hash = _stableHash(lesson.id);
  final candidates = globalKeywords.keys.toList()..sort();
  for (var offset = 0; offset < candidates.length; offset++) {
    final keyword = candidates[(hash + offset) % candidates.length];
    if (keyword.length < 2 || keyword.length > 20) continue;
    if (lesson.keywords.contains(keyword)) continue;
    if (lesson.title.contains(keyword) || lesson.summary.contains(keyword)) {
      continue;
    }
    if (lesson.markdown.contains(keyword)) continue;
    final owners = globalKeywords[keyword] ?? const <LessonInfo>[];
    if (owners.any((owner) => owner.category == lesson.category)) continue;
    if (distractors.contains(keyword)) continue;
    distractors.add(keyword);
    if (distractors.length >= 2) break;
  }
  if (distractors.length < 2) return null;

  final options = <String>[
    correct[0],
    distractors[0],
    correct[1],
    distractors[1],
  ];
  final summary = lesson.summary.replaceAll(RegExp(r'[。；，,;:\s]+$'), '');
  final explanation =
      '正确答案是「${correct[0]}、${correct[1]}」。本课围绕$summary展开；'
      '${correct[0]}和${correct[1]}分别对应本课的关键概念，因此应同时选中。'
      '干扰项「${distractors[0]}」「${distractors[1]}」来自其他课程的主题，'
      '在本课语境下并不成立。';
  return <String, dynamic>{
    'type': 'multi',
    'question': '以下哪些术语与「${lesson.title}」直接相关？（多选）',
    'options': options,
    'answer': 0,
    'answers': <int>[0, 2],
    'explanation': _padExplanation(explanation, lesson),
  };
}

List<Section> _parseSections(String markdown) {
  final result = <Section>[];
  var title = '';
  final body = StringBuffer();
  var inFence = false;
  for (final line in markdown.split('\n')) {
    if (line.trimLeft().startsWith('```')) inFence = !inFence;
    if (!inFence && line.startsWith('## ')) {
      if (title.isNotEmpty || body.toString().trim().isNotEmpty) {
        result.add(Section(title, body.toString()));
      }
      title = line.substring(3).trim();
      body.clear();
    } else {
      body.writeln(line);
    }
  }
  if (title.isNotEmpty || body.toString().trim().isNotEmpty) {
    result.add(Section(title, body.toString()));
  }
  return result;
}

List<String> _numberedItems(String body) {
  final result = <String>[];
  for (final line in body.split('\n')) {
    final match = RegExp(r'^\s*\d+[.、]\s+(.+)$').firstMatch(line);
    if (match == null) continue;
    final item = _cleanInline(match.group(1)!);
    if (item.length < 6 || item.length > 60) continue;
    if (result.contains(item)) continue;
    result.add(item);
  }
  return result;
}

class CodeBlock {
  const CodeBlock(this.language, this.code, this.sectionTitle);

  final String language;
  final String code;
  final String sectionTitle;
}

List<CodeBlock> _codeBlocks(String markdown) {
  final result = <CodeBlock>[];
  var inFence = false;
  var language = '';
  var section = '';
  final code = StringBuffer();
  for (final line in markdown.split('\n')) {
    if (!inFence && line.startsWith('## ')) {
      section = line.substring(3).trim();
      continue;
    }
    if (!inFence && line.trimLeft().startsWith('```')) {
      inFence = true;
      language = line.trimLeft().substring(3).trim();
      code.clear();
      continue;
    }
    if (inFence && line.trimLeft().startsWith('```')) {
      inFence = false;
      result.add(CodeBlock(language, code.toString(), section));
      continue;
    }
    if (inFence) code.writeln(line);
  }
  return result;
}

String _proseSentence(String markdown, String token) {
  final prose = markdown
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'^\s*[#>|].*$', multiLine: true), ' ');
  final lower = token.toLowerCase();
  for (final sentence in prose.split(RegExp(r'[。！？\n]'))) {
    final text = _cleanInline(sentence);
    if (text.length < 20 || text.length > 160) continue;
    if (text.toLowerCase().contains(lower)) return text;
  }
  return '';
}

List<String> _splitTerms(String text) {
  return text
      .split(RegExp(r'[、，,：:；;（）()\[\]\s]+'))
      .map((e) => e.trim())
      .where((e) => e.length >= 2 && e.length <= 20)
      .toList();
}

String _cleanInline(String text) {
  return text
      .replaceAll(RegExp(r'[*_`]+'), '')
      .replaceAll(RegExp(r'^[-*\d.\s]+'), '')
      .replaceAll(RegExp(r'^\[[ xX]\]\s*'), '')
      .replaceAll(RegExp(r'^\[?\s*\]?\s*'), '')
      .replaceAll(RegExp(r'[。；，,;:\s]+$'), '')
      .trim();
}

String _padExplanation(String text, LessonInfo lesson) {
  var result = text.trim();
  if (result.length >= 120) return result;
  final summary = lesson.summary.replaceAll(RegExp(r'[。；，,;:\s]+$'), '');
  final keywords = lesson.keywords.take(4).join('、');
  if (summary.isNotEmpty && !result.contains(summary)) {
    result += '本课围绕$summary展开'
        '${keywords.isEmpty ? '。' : '，关键词包括$keywords。'}';
  } else if (keywords.isNotEmpty) {
    result += '本课的关键词包括$keywords。';
  }
  if (result.length < 120) {
    result +=
        '在「${lesson.title}」中，判断时要回到定义，逐项核对题干限定的对象、输入和边界条件。';
  }
  return result;
}

String _normalizeQuestion(String text) {
  return text.replaceAll(RegExp(r'\s+'), '').trim();
}

String? _option(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

int _stableHash(String text) {
  var hash = 17;
  for (final rune in text.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return hash;
}
