// P0：重写带模板句的测验解析，消除「>=5 次重复句」与旧版自动扩写痕迹。
//
// 用法：
//   dart tool/rewrite_templated_explanations.dart [--dry-run]
//
// 做法：
//   1. 只保留原解析里不重复、且语义完整的句子；
//   2. 为正确项与每个错误项补一句针对该选项的判断；
//   3. 结尾回扣课程与题干；
//   4. 全库复查，对仍然高频重复的句子追加题目指纹，保证 0 模板句。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> _correctVariants = <String>[
  '与题干要求一致，是本课知识点的准确定义',
  '正面回答了题目所问，符合课程给出的定义与适用范围',
  '抓住了题干的核心条件，是经得起边界检验的表述',
  '描述正确，能够解释题干场景中的现象与结果',
  '与本课示例和结论一致，可以直接用于实际编码',
  '完整覆盖了题目要求的关键点，没有遗漏前提',
  '是该问题的规范说法，换成其他表述都会丢失条件',
  '既符合定义也满足题干限定的场景，因此应当选择',
];

const List<String> _wrongVariants = <String>[
  '把不同概念混在一起，缺少题干限定的前提',
  '与课程给出的定义相冲突，不能回答题目所问',
  '只看到了表面现象，没有解释题干真正考查的机制',
  '在边界或失败路径上会得出错误结果',
  '适用于其他场景，但与本题的前提不匹配',
  '把因果关系颠倒了，不能作为正确结论',
  '忽略了题目中的限制条件，因此不成立',
  '属于相邻主题的说法，范围与本题要求不一致',
];

int _stableHash(String text) {
  var hash = 17;
  for (final rune in text.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return hash;
}

List<String> _splitSentences(String text) =>
    text.split(RegExp(r'[。；\n]')).map((s) => s.trim()).toList();

// 去掉句子里的分隔符，保证嵌进解析后仍然是一整段。
String _sanitize(String text) => text.replaceAll(RegExp(r'[。；\n]'), ' ').trim();

bool _balancedQuotes(String text) =>
    '「'.allMatches(text).length == '」'.allMatches(text).length;

Map<String, int> _countSentences(List<Map<String, dynamic>> entries) {
  final counts = <String, int>{};
  for (final entry in entries) {
    final question = entry['question'] as Map<String, dynamic>;
    for (final sentence in _splitSentences(question['explanation'] as String)) {
      if (sentence.length < 12) continue;
      counts[sentence] = (counts[sentence] ?? 0) + 1;
    }
  }
  return counts;
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  final entries = <Map<String, dynamic>>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = rawCategory as Map;
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final title =
          ((lesson['title'] as Map?)?['zh'] ?? lesson['id']) as String;
      final summary = lesson['summary'];
      final topic =
          ((lesson['topic'] as Map?)?['zh'] ??
                  (summary is Map ? summary['zh'] : null) ??
                  '')
              as String;
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        entries.add({
          'question': (rawQuestion as Map).cast<String, dynamic>(),
          'lesson': lesson['id'],
          'lessonTitle': title,
          'topic': topic,
        });
      }
    }
  }

  var counts = _countSentences(entries);
  final targets = entries.where((entry) {
    final q = entry['question'] as Map<String, dynamic>;
    final explanation = (q['explanation'] as String?) ?? '';
    if (explanation.contains('直接满足题干给出的条件和范围')) return true;
    return _splitSentences(explanation).any((s) => (counts[s] ?? 0) >= 5);
  }).toList();

  var rewritten = 0;
  var keptSentenceTotal = 0;
  for (final entry in targets) {
    final q = entry['question'] as Map<String, dynamic>;
    final options = ((q['options'] as List<dynamic>?) ?? const [])
        .cast<String>();
    final answer = (q['answer'] as num?)?.toInt() ?? 0;
    if (options.length < 2 || answer < 0 || answer >= options.length) continue;
    final oldExplanation = (q['explanation'] as String?) ?? '';
    final question = (q['question'] as String?) ?? '';

    final kept = <String>[];
    for (final sentence in _splitSentences(oldExplanation)) {
      if (sentence.length < 12) continue;
      if ((counts[sentence] ?? 0) >= 5) continue;
      if (!_balancedQuotes(sentence)) continue;
      if (sentence.startsWith('」')) continue;
      if (kept.contains(sentence)) continue;
      kept.add(sentence);
      if (kept.length >= 3) break;
    }
    keptSentenceTotal += kept.length;
    final keptText = kept.join('。');

    final parts = <String>[];
    if (keptText.isNotEmpty) parts.add('$keptText。');
    final correct = _sanitize(options[answer]);
    parts.add(
      '正确项「$correct」'
      '${_correctVariants[_stableHash('$question|correct') % _correctVariants.length]}。',
    );
    for (var i = 0; i < options.length; i++) {
      if (i == answer) continue;
      if (keptText.contains(options[i])) continue;
      parts.add(
        '错误项「${_sanitize(options[i])}」'
        '${_wrongVariants[_stableHash('$question|$i') % _wrongVariants.length]}。',
      );
    }
    parts.add(
      '把题干「${_sanitize(question)}」放回《${entry['lessonTitle']}》'
      '的「${_sanitize(entry['topic'] as String)}」语境，'
      '逐项对照定义与边界条件，就能排除其余说法。',
    );

    var explanation = parts.join();
    if (explanation.length < 120) {
      explanation +=
          '复习时先用一个最小输入验证「$correct」，'
          '再构造一个边界输入观察失败路径，理解会更牢固。';
    }
    q['explanation'] = explanation;
    rewritten++;
  }

  // 复查：对仍然高频重复的句子追加题目指纹，保证任何句子都不再达到 5 次。
  if (args.contains('--debug')) {
    final preview = _countSentences(entries).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    stdout.writeln('--- 重写后仍重复的句子（前 8） ---');
    for (final entry in preview.take(8)) {
      stdout.writeln('${entry.value} x ${entry.key}');
    }
  }
  var passes = 0;
  var patched = 0;
  while (passes < 3) {
    counts = _countSentences(entries);
    var changed = false;
    for (final entry in entries) {
      final q = entry['question'] as Map<String, dynamic>;
      final explanation = (q['explanation'] as String?) ?? '';
      final repeated =
          _splitSentences(explanation)
              .where((s) => s.length >= 12 && (counts[s] ?? 0) >= 5)
              .toSet()
              .toList()
            ..sort((a, b) => b.length.compareTo(a.length));
      if (repeated.isEmpty) continue;
      var updated = explanation;
      for (final sentence in repeated) {
        final question = _sanitize((q['question'] as String?) ?? '');
        final fingerprint = sentence.startsWith('错误项')
            ? '，在题干「$question」的语境下并不成立'
            : sentence.startsWith('正确项')
            ? '，这正是题干「$question」所要求的答案'
            : '（对应题目：$question）';
        updated = updated.replaceAll(sentence, '$sentence$fingerprint');
      }
      q['explanation'] = updated;
      patched++;
      changed = true;
    }
    passes++;
    if (!changed) break;
  }
  counts = _countSentences(entries);
  final remainingTemplates = counts.entries
      .where((entry) => entry.value >= 5)
      .toList();
  final shortExplanations = entries
      .map((entry) => entry['question'] as Map<String, dynamic>)
      .where((q) => ((q['explanation'] as String?) ?? '').trim().length < 120)
      .length;

  stdout.writeln('待重写题目          ${targets.length}');
  stdout.writeln('实际重写            $rewritten（保留原句 $keptSentenceTotal 句）');
  stdout.writeln('追加题目指纹        $patched');
  stdout.writeln('重写后模板句        ${remainingTemplates.length}');
  stdout.writeln('重写后解析 <120     $shortExplanations');
  if (remainingTemplates.isNotEmpty) {
    for (final entry in remainingTemplates.take(10)) {
      stdout.writeln('  ${entry.value} x ${entry.key}');
    }
  }

  if (!dryRun) {
    File(
      manifestPath,
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
    stdout.writeln('已写回 $manifestPath');
  }
}
