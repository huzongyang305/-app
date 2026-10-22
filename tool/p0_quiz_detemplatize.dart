// P0 内容治理：重建测验解析，去掉跨题模板骨架，并用课程原文补充依据。
//
// 用法：
//   dart tool/p0_quiz_detemplatize.dart [--dry-run] [--lesson=<id>] [--samples=8]
//
// 处理逻辑：
//   1. 删除旧版自动扩写留下的通用句（正确项/错误项/把题干放回……）；
//   2. 保留解析中真正与本题有关的核心句；
//   3. 按关键词与正确项重合度，从本课 Markdown 抽取 1-3 句原文依据；
//   4. 保证解析不少于 120 字符、包含正确项，并且不再出现模板骨架。
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const String manifestPath = 'assets/content/manifest.json';

/// 中文/英文高频虚词。抽取依据时跳过这些词，避免“本课/可以/需要”之类
/// 的通用词把无关句子排到前面。
const Set<String> _stopWords = <String>{
  'the',
  'and',
  'for',
  'with',
  'that',
  'this',
  'from',
  'into',
  'when',
  'then',
  'than',
  'have',
  'has',
  'are',
  'was',
  'were',
  'will',
  'would',
  'can',
  'could',
  'should',
  'must',
  'not',
  'you',
  'your',
  'its',
  'it',
  '的是',
  '一个',
  '可以',
  '我们',
  '这个',
  '这些',
  '那些',
  '如果',
  '进行',
  '使用',
  '需要',
  '没有',
  '不是',
  '就是',
  '以及',
  '并且',
  '或者',
  '因为',
  '所以',
  '例如',
  '下面',
  '通过',
  '对于',
  '其中',
  '已经',
  '可能',
  '应该',
  '必须',
  '如何',
  '什么',
  '为什么',
  '本课',
  '本节',
  '课程',
  '内容',
  '知识',
  '问题',
  '情况',
  '时候',
  '地方',
  '方式',
  '结果',
  '过程',
  '相关',
  '主要',
  '正确',
  '错误',
  '选项',
  '答案',
  '题干',
  '说法',
  '描述',
  '理解',
  '掌握',
};

/// 旧版自动扩写留下的长句骨架。命中即删除，不再参与重建。
final List<RegExp> _genericSentencePatterns = <RegExp>[
  RegExp(r'^把题干[「“].*?(放回《|语境，逐项对照|的语境下并不成立)'),
  RegExp(r'把题干'),
  RegExp(r'放回《'),
  RegExp(r'逐项对照定义与边界条件'),
  RegExp(r'就能排除其余说法'),
  RegExp(r'下列说法正确的是？'),
  RegExp(r'核心学习目标是什么'),
  RegExp(r'的语境下并不成立'),
  RegExp(
    r'^正确项[「“].*?(经得起边界检验|满足题干限定|与本课示例和结论一致|是该问题的规范说法|抓住了题干的核心条件|完整覆盖了题目要求|正面回答了题目所问|描述正确，能够解释|与题干要求一致|能够解释题干场景)',
  ),
  RegExp(
    r'^错误项[「“].*?(只看到了表面现象|忽略了题目中的限制条件|把因果关系颠倒了|在边界或失败路径上|与课程给出的定义相冲突|把不同概念混在一起|适用于其他场景|属于相邻主题的说法)',
  ),
  RegExp(r'^学习《.*?》时应把该要点'),
  RegExp(r'^复习《.*?》的[「“].*?[」”]时，再用一个边界输入'),
  RegExp(r'^[「“].*?[」”](混淆了相近概念|只看到了表面现象|忽略了题目中的限制条件|适用于其他场景|把因果关系颠倒了)'),
  RegExp(r'^如果采用[「“].*?[」”]，会在边界或失败路径上'),
  RegExp(r'项目目标是把.*?落实为'),
  RegExp(r'围绕.*?说明变量生命周期、资源释放、并发模型'),
  RegExp(r'关键关系：先分清'),
  RegExp(r'列出至少.*?个入口和对应的最小权限'),
];

/// 只检查旧版模板尾巴；题干本身可能出现“下列说法正确的是”，不能误判。
final List<RegExp> _postCheckPatterns = <RegExp>[
  RegExp(r'放回《'),
  RegExp(r'逐项对照定义与边界条件'),
  RegExp(r'就能排除其余说法'),
  RegExp(r'只看到了表面现象'),
  RegExp(r'适用于其他场景，但与本题的前提不匹配'),
  RegExp(r'与课程给出的定义相冲突，不能回答题目所问'),
  RegExp(r'忽略了题目中的限制条件，因此不成立'),
  RegExp(r'把因果关系颠倒了，不能作为正确结论'),
  RegExp(r'把不同概念混在一起，缺少题干限定的前提'),
  RegExp(r'属于相邻主题的说法，范围与本题要求不一致'),
  RegExp(r'与本题的定义和前提不一致'),
  RegExp(r'会在边界或失败路径上产生错误结果'),
];

/// 本工具自己生成的脚手架句。重跑时不能把它们当作课程原文继承，
/// 否则一次次的改写会把前缀、摘要和例句滚成难以阅读的长句。
final List<RegExp> _generatedCorePatterns = <RegExp>[
  RegExp(r'^正确答案是'),
  RegExp(r'^针对「'),
  RegExp(r'^本课在「'),
  RegExp(r'^本课还在「'),
  RegExp(r'^本课示例中'),
  RegExp(r'^本课围绕'),
  RegExp(r'^本课术语速查给出的解释是'),
  RegExp(r'^课程摘要'),
  RegExp(r'^这道题'),
];

const List<String> _highValueSections = <String>[
  '核心知识',
  '关键流程',
  '原理',
  '机制',
  '常见误区',
  '常见错误',
  '深入理解',
  '重点',
  '要点',
  '概念',
  '术语',
  '验证',
  '项目',
  '实战',
  '故障',
  '排查',
  '边界',
  '对比',
  '为什么',
  '速览',
  '自测',
];

const List<String> _lowValueSections = <String>[
  'English',
  'Bilingual',
  '学习目标',
  '前置知识',
  '参考资料',
  '内容元数据',
  '动手练习',
  '练习',
  '复习清单',
  '自检',
  '作业',
];

/// 这些章节本身由题库/工具二次生成，不能再用作解析依据，否则会形成循环引用。
const List<String> _skipSections = <String>[
  '考点精讲',
  '本课复习清单',
  '逐节复习与自检',
  '术语速查',
  '易错点回顾',
  'English Overview',
  'Full English Study Guide',
  'Bilingual Section Outline',
  '内容元数据',
  '参考资料与复核',
  '前置知识',
  '学习目标',
  '动手练习',
  '本课自测清单',
  '自测清单',
  '代码实验',
];

/// 元话语：讲“本节要做什么/下面看什么”，不提供可引用的知识点。
const List<String> _metaPrefixes = <String>[
  '下面',
  '本节',
  '这一节',
  '本课将',
  '本课会',
  '本课把',
  '这里',
  '接下来',
  '完成本课',
  '学完本课',
  '到此',
  '最后',
];

const List<String> _metaMarkers = <String>[
  '最容易混淆的选项',
  '不引入新语法',
  '解决了什么问题',
  '不是孤立术语',
  '核心问题：',
  '本课有 ',
  '先自己作答',
  '对照解析',
  '回到正文',
];

class SourceSentence {
  const SourceSentence(this.text, this.section, this.order);

  final String text;
  final String section;
  final int order;
}

class LessonSource {
  LessonSource({
    required this.id,
    required this.title,
    required this.summary,
    required this.keywords,
    required this.sentences,
    required this.markdown,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> keywords;
  final List<SourceSentence> sentences;
  final String markdown;
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final lessonFilter = _option(args, '--lesson=');
  final sampleCount = int.tryParse(_option(args, '--samples=') ?? '') ?? 8;

  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List<dynamic>)
      .map((raw) => (raw as Map).cast<String, dynamic>())
      .toList();

  final sources = <String, LessonSource>{};
  for (final category in categories) {
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      sources[lesson['id'] as String] = _loadLessonSource(lesson);
    }
  }
  final globalSentenceCounts = <String, int>{};
  for (final source in sources.values) {
    for (final sentence in source.sentences) {
      globalSentenceCounts[sentence.text] =
          (globalSentenceCounts[sentence.text] ?? 0) + 1;
    }
  }
  final globalOutputCounts = <String, int>{};
  var total = 0;
  var rewritten = 0;
  var grounded = 0;
  var fallback = 0;
  var beforeChars = 0;
  var afterChars = 0;
  var afterMin = 1 << 30;
  var below120 = 0;
  var containsCorrect = 0;
  var fillerCount = 0;
  var contrastFallback = 0;
  var optionRefsLeft = 0;
  final samples = <String>[];
  final fallbackSamples = <String>[];
  final afterSentences = <String>[];

  for (final category in categories) {
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'] as String;
      final source = sources[id]!;
      final questions = (lesson['quiz'] as List<dynamic>? ?? const [])
          .map((raw) => (raw as Map).cast<String, dynamic>())
          .toList();
      final usage = <String, int>{};
      for (final question in questions) {
        total++;
        final original = ((question['explanation'] as String?) ?? '').trim();
        beforeChars += original.length;
        final rebuilt = _rebuildExplanation(
          question,
          source,
          usage,
          globalSentenceCounts,
          globalOutputCounts,
        );
        final rebuiltText = rebuilt.text;
        question['explanation'] = rebuiltText;
        rewritten++;
        if (rebuilt.grounded) grounded++;
        if (rebuilt.usedFallback) fallback++;
        if (rebuilt.usedFallback && fallbackSamples.length < 5) {
          fallbackSamples.add('Q: ${question['question']}\nA: $rebuiltText\n');
        }
        afterChars += rebuiltText.length;
        afterMin = math.min(afterMin, rebuiltText.length);
        if (rebuiltText.length < 120) below120++;
        final correct = _correctAnswer(question);
        if (correct.isEmpty || rebuiltText.contains(correct)) {
          containsCorrect++;
        }
        if (rebuiltText.contains('判断这类题时')) fillerCount++;
        if (rebuiltText.contains('与正确项对照')) contrastFallback++;
        if (_optionRefPattern.hasMatch(rebuiltText)) optionRefsLeft++;
        for (final sentence in _splitSentences(rebuiltText)) {
          if (sentence.length >= 12) afterSentences.add(sentence);
        }
        if (samples.length < sampleCount) {
          samples.add('Q: ${question['question']}\nA: $rebuiltText\n');
        }
      }
    }
  }

  final repeated = <String, int>{};
  for (final sentence in afterSentences) {
    final trimmed = sentence.trim();
    repeated[trimmed] = (repeated[trimmed] ?? 0) + 1;
  }
  final repeatedFive = repeated.entries.where((e) => e.value >= 5).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final bannedLeft = afterSentences
      .where((s) => _postCheckPatterns.any((r) => r.hasMatch(s)))
      .length;
  final normalizedSkeletons = <String, int>{};
  for (final sentence in afterSentences) {
    if (sentence.length < 25) continue;
    final skeleton = sentence
        .replaceAll(RegExp(r'「[^」]*」'), '「X」')
        .replaceAll(RegExp(r'《[^》]*》'), '《X》')
        .replaceAll(RegExp(r'\d+'), 'N')
        .replaceAll(RegExp(r'\s+'), '');
    if (skeleton.length < 20) continue;
    normalizedSkeletons[skeleton] = (normalizedSkeletons[skeleton] ?? 0) + 1;
  }
  final topSkeletons =
      normalizedSkeletons.entries.where((entry) => entry.value >= 5).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  stdout.writeln('题目总数              $total');
  stdout.writeln('重写解析              $rewritten');
  stdout.writeln('有课程原文依据        $grounded');
  stdout.writeln('仅用摘要/兜底         $fallback');
  stdout.writeln(
    '解析平均字符          ${total == 0 ? 0 : (afterChars / total).toStringAsFixed(1)}（原 ${total == 0 ? 0 : (beforeChars / total).toStringAsFixed(1)}）',
  );
  stdout.writeln('解析最短              $afterMin');
  stdout.writeln('解析 <120             $below120');
  stdout.writeln('包含正确项            $containsCorrect / $total');
  stdout.writeln('残留模板骨架          $bannedLeft');
  stdout.writeln('兜底长句              $fillerCount');
  stdout.writeln('对比兜底句            $contrastFallback');
  stdout.writeln('残留相对选项指代      $optionRefsLeft');
  stdout.writeln('完全重复 >=5 的句子   ${repeatedFive.length}');
  stdout.writeln('归一化骨架 >=5        ${topSkeletons.length}');
  for (final entry in topSkeletons.take(5)) {
    stdout.writeln('  ${entry.value}x ${entry.key}');
  }
  if (repeatedFive.isNotEmpty) {
    for (final entry in repeatedFive.take(5)) {
      stdout.writeln('  ${entry.value}x ${entry.key}');
    }
  }

  if (lessonFilter != null) {
    for (final category in categories) {
      for (final rawLesson in category['lessons'] as List<dynamic>) {
        final lesson = (rawLesson as Map).cast<String, dynamic>();
        if (lesson['id'] != lessonFilter) continue;
        stdout.writeln('');
        stdout.writeln('--- 样例：${lesson['id']} ---');
        for (final rawQuestion in lesson['quiz'] as List<dynamic>) {
          final question = (rawQuestion as Map).cast<String, dynamic>();
          stdout.writeln('');
          stdout.writeln('Q: ${question['question']}');
          stdout.writeln('A: ${question['explanation']}');
        }
      }
    }
  } else if (samples.isNotEmpty) {
    for (final sample in samples.take(sampleCount)) {
      stdout.writeln(sample);
    }
    if (fallbackSamples.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln('--- 兜底样例（前 5 题） ---');
      for (final sample in fallbackSamples) {
        stdout.writeln(sample);
      }
    }
  }

  if (dryRun) {
    stdout.writeln('');
    stdout.writeln('dry-run：未写入 manifest.json');
    return;
  }
  manifestFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('');
  stdout.writeln('已写入 $manifestPath');
}

String? _option(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

LessonSource _loadLessonSource(Map<String, dynamic> lesson) {
  final id = lesson['id'] as String;
  final title = ((lesson['title'] as Map?)?['zh'] ?? id) as String;
  final summary = ((lesson['summary'] as Map?)?['zh'] ?? '') as String;
  final keywords = ((lesson['keywords'] as List<dynamic>?) ?? const [])
      .map((e) => '$e')
      .toList();
  final file = lesson['file'] as String;
  final markdown = File(file).existsSync() ? File(file).readAsStringSync() : '';
  return LessonSource(
    id: id,
    title: title,
    summary: summary,
    keywords: keywords,
    sentences: _extractSentences(markdown),
    markdown: markdown,
  );
}

List<SourceSentence> _extractSentences(String markdown) {
  final result = <SourceSentence>[];
  final seen = <String>{};
  var inFence = false;
  var section = '';
  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || line.isEmpty) continue;
    if (line.startsWith('## ')) {
      section = line.substring(3).trim();
      continue;
    }
    if (_skipSections.any(section.contains)) continue;
    if (line.startsWith('|') ||
        line.startsWith('>') ||
        line.startsWith('![') ||
        line.startsWith('#') ||
        line.startsWith('<!--')) {
      continue;
    }
    var content = line.replaceFirst(RegExp(r'^[-*+\d.\s]+'), '').trim();
    content = content.replaceAll(RegExp(r'^\[?\s*\]?\s*'), '');
    if (content.contains('不看解析') ||
        content.contains('Key terms') ||
        content.contains('相关主题')) {
      continue;
    }
    if (content.length < 20) continue;
    for (final sentence in _splitSentences(content)) {
      final text = _cleanSentence(sentence);
      if (text.length < 20 || text.length > 200) continue;
      if (_genericSentencePatterns.any((r) => r.hasMatch(text))) continue;
      if (text.contains('《') && text.contains('》')) continue;
      if (text.contains('判断依据') || text.contains('正确判断')) continue;
      if (_metaPrefixes.any(text.startsWith)) continue;
      if (_metaMarkers.any(text.contains)) continue;
      if (!seen.add(text)) continue;
      result.add(SourceSentence(text, section, result.length));
    }
  }
  return result;
}

_RebuiltExplanation _rebuildExplanation(
  Map<String, dynamic> question,
  LessonSource source,
  Map<String, int> usage,
  Map<String, int> globalSentenceCounts,
  Map<String, int> globalOutputCounts,
) {
  final original = ((question['explanation'] as String?) ?? '').trim();
  final questionText = ((question['question'] as String?) ?? '').trim();
  final options = ((question['options'] as List<dynamic>?) ?? const [])
      .map((e) => '$e'.trim())
      .toList();
  final correct = _correctAnswer(question);

  final core = <String>[];
  for (final sentence in _splitSentences(original)) {
    final text = _cleanSentence(sentence);
    if (text.length < 12) continue;
    if (_genericSentencePatterns.any((r) => r.hasMatch(text))) continue;
    if (_generatedCorePatterns.any((r) => r.hasMatch(text))) continue;
    if ((globalOutputCounts[text] ?? 0) >= 2) continue;
    if (text == '其他选项：' || text == '其它选项：') continue;
    if (core.any(
      (existing) => existing.contains(text) || text.contains(existing),
    )) {
      continue;
    }
    core.add(text);
    if (core.length >= 2) break;
  }

  final queryTokens = _queryTokens(<String>[
    questionText,
    correct,
    ...options,
    ...source.keywords,
    source.title,
  ]);
  final ranked =
      source.sentences
          .map(
            (sentence) => (
              sentence,
              _scoreSentence(sentence, queryTokens, correct) -
                  4.0 * (usage[sentence.text] ?? 0),
            ),
          )
          .where((entry) => entry.$2 > 1.5)
          .where((entry) => (globalSentenceCounts[entry.$1.text] ?? 0) < 3)
          .where((entry) => (globalOutputCounts[entry.$1.text] ?? 0) < 2)
          .toList()
        ..sort((a, b) {
          final byScore = b.$2.compareTo(a.$2);
          if (byScore != 0) return byScore;
          return a.$1.order.compareTo(b.$1.order);
        });

  final picked = <SourceSentence>[];
  for (final entry in ranked) {
    final sentence = entry.$1;
    if ((usage[sentence.text] ?? 0) >= 2) continue;
    if (_isTooSimilar(sentence.text, picked)) continue;
    picked.add(sentence);
    if (picked.length >= 3) break;
  }
  if (picked.isEmpty) {
    final relaxed =
        source.sentences
            .map(
              (sentence) => (
                sentence,
                _scoreSentence(sentence, queryTokens, correct) -
                    4.0 * (usage[sentence.text] ?? 0),
              ),
            )
            .where((entry) => entry.$2 > 0)
            .where((entry) => (globalSentenceCounts[entry.$1.text] ?? 0) < 3)
            .where((entry) => (globalOutputCounts[entry.$1.text] ?? 0) < 2)
            .toList()
          ..sort((a, b) {
            final byScore = b.$2.compareTo(a.$2);
            if (byScore != 0) return byScore;
            return a.$1.order.compareTo(b.$1.order);
          });
    for (final entry in relaxed) {
      final sentence = entry.$1;
      if ((usage[sentence.text] ?? 0) >= 2) continue;
      if (_isTooSimilar(sentence.text, picked)) continue;
      picked.add(sentence);
      if (picked.length >= 2) break;
    }
  }

  picked.removeWhere(
    (sentence) => core.any(
      (existing) =>
          existing.contains(sentence.text) || sentence.text.contains(existing),
    ),
  );
  final parts = <String>[];
  final fingerprint = _questionFingerprint(questionText);
  var answerInline = false;
  if (correct.isNotEmpty && !core.any((s) => s.contains(correct))) {
    if (picked.isNotEmpty) {
      final first = picked.removeAt(0);
      usage[first.text] = (usage[first.text] ?? 0) + 1;
      final section = _sectionLabel(first.section);
      parts.add('正确答案是「$correct」，本课在「$section」中说明：${first.text}。');
      answerInline = true;
    } else {
      parts.add(
        '正确答案是「$correct」，这道题在问$fingerprint，'
        '判断时要把题干限定的输入、边界与目标逐项对齐。',
      );
    }
  }
  for (final sentence in core) {
    parts.add(sentence.endsWith('。') ? sentence : '$sentence。');
  }

  for (var i = 0; i < picked.length; i++) {
    final sentence = picked[i];
    final section = _sectionLabel(sentence.section);
    final prefix = i == 0 && !answerInline
        ? '针对「${_shortTopic(questionText)}」，本课在「$section」中说明：'
        : '本课还在「$section」中说明：';
    parts.add('$prefix${sentence.text}。');
    usage[sentence.text] = (usage[sentence.text] ?? 0) + 1;
    if (_length(parts) >= 200) break;
  }

  final grounded = picked.isNotEmpty || answerInline;
  if (_length(parts) < 120) {
    final example = _exampleLine(source.markdown, correct);
    if (example != null) {
      final exampleSentence =
          '本课示例中还能看到 `$example` 这样的用法，'
          '说明该关键字在本课代码中承担实际功能';
      final exampleKey = _cleanSentence('$exampleSentence。');
      if ((globalOutputCounts[exampleKey] ?? 0) < 2) {
        parts.add('$exampleSentence。');
      }
    }
  }
  if (_length(parts) < 120 && source.summary.isNotEmpty) {
    final summary = source.summary.replaceAll(RegExp(r'[。；，、\n]+'), '，').trim();
    parts.add('课程摘要指出$summary，本课要判断的正是$fingerprint。');
  }
  var usedFallback = false;
  if (_length(parts) < 120) {
    usedFallback = true;
    final keywords = source.keywords.take(4).join('、');
    if (keywords.isNotEmpty) {
      parts.add(
        '这道题考查 $fingerprint 与$keywords这些概念之间的边界，'
        '判断时要把题干限定的条件逐项代入。',
      );
    } else {
      final wrong = options
          .where((option) => option != correct)
          .take(2)
          .map((option) => '「$option」')
          .join('、');
      parts.add('把$wrong与正确项对照，可以看出它们在适用条件或结论范围上并不等价。');
    }
  }
  var text = parts.join();
  text = text
      .replaceAll(RegExp(r'[；，、：]+。'), '。')
      .replaceAll(RegExp(r'，{2,}'), '，')
      .replaceAll(RegExp(r'。{2,}'), '。')
      .replaceAll('补充：', '补充·')
      .trim();
  text = _replaceOptionReferences(text, options);
  if (text.length > 420) text = '${text.substring(0, 418)}…';
  if (text.length < 120) {
    final filler =
        '回到 $fingerprint 本身，先抓住题干限定的对象与条件，'
        '再用课程给出的定义逐项核对，如果某个选项把前提去掉或换成相邻概念，'
        '就不能作为本题答案。';
    text = '$text$filler';
  }
  for (final sentence in _splitSentences(text)) {
    final cleaned = _cleanSentence(sentence);
    if (cleaned.length < 12) continue;
    globalOutputCounts[cleaned] = (globalOutputCounts[cleaned] ?? 0) + 1;
  }
  return _RebuiltExplanation(text, grounded, usedFallback);
}

class _RebuiltExplanation {
  const _RebuiltExplanation(this.text, this.grounded, this.usedFallback);

  final String text;
  final bool grounded;
  final bool usedFallback;
}

int _length(List<String> parts) =>
    parts.fold<int>(0, (sum, s) => sum + s.length);

String _cleanSentence(String text) {
  var result = text
      .replaceAll(RegExp(r'[*_`]+'), '')
      .replaceAll(RegExp(r'^\[?\s*\]?\s*'), '')
      .replaceAll(RegExp(r'^[」”’）】\]]+\s*'), '')
      .replaceAll(RegExp(r'[。；，、：！？\s]+$'), '')
      .trim();
  final openQuotes = '「'.allMatches(result).length;
  final closeQuotes = '」'.allMatches(result).length;
  if (openQuotes != closeQuotes) {
    result = result.replaceAll(RegExp(r'[「」]'), '').trim();
  }
  return result;
}

String _shortTopic(String text) {
  final compact = text
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[「」《》]'), '')
      .replaceAll(RegExp(r'[。；！？]'), '，')
      .trim();
  return compact.length <= 26 ? compact : '${compact.substring(0, 24)}…';
}

/// 章节标题可能带“深入补充：”这类前缀，直接嵌入解析会命中旧模板检查。
String _sectionLabel(String section) {
  final title = section.trim().isEmpty ? '正文' : section.trim();
  return title.replaceAll('：', '·').replaceAll(':', '·');
}

String _questionFingerprint(String text) {
  var compact = text
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[「」《》]'), '')
      .replaceAll(RegExp(r'[。；！？]'), '，');
  compact = compact.replaceAll(RegExp(r'，+$'), '');
  if (compact.length <= 50) return compact;
  return '${compact.substring(0, 26)}…${compact.substring(compact.length - 20)}';
}

final RegExp _optionRefPattern = RegExp(
  r'选项[一二三四五六A-F]|第[一二三四五六1-6]个选项|[A-F]选项',
);

/// App 会打乱选项顺序，解析中不能保留“选项二/选项C”这类相对指代。
/// 这里把可解析的序号换成真实选项文本，越界或无法解析的统一降级为“该选项”。
String _replaceOptionReferences(String text, List<String> options) {
  const ordinals = <String>['一', '二', '三', '四', '五', '六'];
  var result = text;
  result = result.replaceAllMapped(RegExp(r'选项([一二三四五六](?:[、和及][一二三四五六])*)'), (
    match,
  ) {
    final parts = match
        .group(1)!
        .split(RegExp(r'[、和及]'))
        .where((part) => part.isNotEmpty)
        .toList();
    final labels = <String>[];
    for (final part in parts) {
      final index = ordinals.indexOf(part);
      if (index < 0 || index >= options.length) continue;
      final option = options[index].trim();
      if (option.isNotEmpty && !labels.contains('「$option」')) {
        labels.add('「$option」');
      }
    }
    return labels.isEmpty ? '该选项' : labels.join('、');
  });
  for (var i = 0; i < ordinals.length && i < options.length; i++) {
    final option = options[i].trim();
    if (option.isEmpty) continue;
    final quoted = '「$option」';
    result = result
        .replaceAll('第${ordinals[i]}个选项', quoted)
        .replaceAll('第${i + 1}个选项', quoted);
  }
  for (var i = 0; i < 6 && i < options.length; i++) {
    final option = options[i].trim();
    if (option.isEmpty) continue;
    final letter = String.fromCharCode(65 + i);
    final quoted = '「$option」';
    result = result
        .replaceAll('$letter选项', quoted)
        .replaceAll('选项$letter', quoted);
  }
  return result.replaceAll(
    RegExp(r'选项[一二三四五六A-F]|第[一二三四五六1-6]个选项|[A-F]选项'),
    '该选项',
  );
}

String? _exampleLine(String markdown, String correct) {
  final needle = correct.trim().toLowerCase();
  if (needle.length < 2) return null;
  var inFence = false;
  String? best;
  for (final line in markdown.split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (!inFence) continue;
    final text = line.trim();
    if (text.isEmpty || text.length > 90) continue;
    if (!text.toLowerCase().contains(needle)) continue;
    if (best == null || text.length < best.length) best = text;
  }
  return best;
}

bool _isTooSimilar(String text, List<SourceSentence> picked) {
  final normalized = text.replaceAll(RegExp(r'\s+'), '');
  for (final existing in picked) {
    final other = existing.text.replaceAll(RegExp(r'\s+'), '');
    if (normalized == other) return true;
    final shorter = normalized.length < other.length ? normalized : other;
    final longer = normalized.length < other.length ? other : normalized;
    if (shorter.length >= 12 && longer.contains(shorter)) return true;
  }
  return false;
}

Set<String> _queryTokens(List<String> texts) {
  final tokens = <String>{};
  for (final text in texts) {
    for (final match in RegExp(
      r'[A-Za-z][A-Za-z0-9_+#.\-]{1,30}',
    ).allMatches(text)) {
      final word = match.group(0)!.toLowerCase();
      if (!_stopWords.contains(word)) tokens.add(word);
    }
    for (final match in RegExp(r'[\u4e00-\u9fff]+').allMatches(text)) {
      final run = match.group(0)!;
      for (var n = 2; n <= 4; n++) {
        for (var i = 0; i + n <= run.length; i++) {
          final token = run.substring(i, i + n);
          if (!_stopWords.contains(token)) tokens.add(token);
        }
      }
    }
  }
  return tokens;
}

double _scoreSentence(
  SourceSentence sentence,
  Set<String> queryTokens,
  String correct,
) {
  final compact = sentence.text.replaceAll(RegExp(r'\s+'), '');
  var score = 0.0;
  for (final token in queryTokens) {
    if (compact.contains(token)) {
      score += math.min(token.length, 4).toDouble();
    }
  }
  final correctCompact = correct.replaceAll(RegExp(r'\s+'), '');
  if (correctCompact.length >= 3 && compact.contains(correctCompact)) {
    score += 10;
  }
  if (_highValueSections.any(sentence.section.contains)) score += 2;
  if (_lowValueSections.any(sentence.section.contains)) score -= 4;
  if (sentence.text.startsWith('下面') ||
      sentence.text.startsWith('如果') ||
      sentence.text.startsWith('请') ||
      sentence.text.startsWith('例如')) {
    score -= 1.5;
  }
  return score;
}

String _correctAnswer(Map<String, dynamic> question) {
  final type = (question['type'] as String?) ?? 'single';
  final options = ((question['options'] as List<dynamic>?) ?? const [])
      .map((e) => '$e'.trim())
      .toList();
  switch (type) {
    case 'multi':
      final raw = question['answers'] ?? question['correct_indexes'];
      final indexes = raw is List
          ? raw
                .map((e) => e is int ? e : int.tryParse('$e'))
                .whereType<int>()
                .where((i) => i >= 0 && i < options.length)
                .toList()
          : <int>[];
      return indexes.map((i) => options[i]).join('、');
    case 'fill':
      final accepted =
          ((question['accepted_answers'] as List<dynamic>?) ?? const [])
              .map((e) => '$e'.trim())
              .toList();
      if (accepted.isNotEmpty) return accepted.first;
      return question['answer'] is String ? question['answer'] as String : '';
    case 'order':
      final raw = (question['correct_order'] as List<dynamic>?) ?? const [];
      final order = raw
          .map((e) => e is int ? e : int.tryParse('$e'))
          .whereType<int>()
          .where((i) => i >= 0 && i < options.length)
          .toList();
      return order.map((i) => options[i]).join(' → ');
    case 'code':
      return ((question['expected_output'] as String?) ?? '').trim();
    default:
      final answer = (question['answer'] as num?)?.toInt() ?? 0;
      return answer >= 0 && answer < options.length ? options[answer] : '';
  }
}

List<String> _splitSentences(String text) {
  final parts = <String>[];
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    buffer.write(ch);
    if (ch == '。' || ch == '；' || ch == '！' || ch == '？' || ch == '\n') {
      final sentence = buffer.toString().trim();
      if (sentence.isNotEmpty) parts.add(sentence);
      buffer.clear();
    }
  }
  final tail = buffer.toString().trim();
  if (tail.isNotEmpty) parts.add(tail);
  return parts;
}
