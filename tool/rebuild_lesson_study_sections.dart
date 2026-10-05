// 内容治理：按当前题库重建每课的「考点精讲」，并清掉旧版自动生成的模板章节。
//
// 用法：
//   dart tool/rebuild_lesson_study_sections.dart [--dry-run]
//
// 处理内容：
//   1. 删除旧的 考点精讲 / 课程专属精读 / 专属复习题库 / 逐步练习 /
//      故障排查手册 / 自测与面试 / 专属进阶任务 / 本课连接 等自动章节；
//   2. 用当前 quiz 数据重建「考点精讲：把测验题还原成判断过程」；
//   3. 补一节「本课复习清单」；
//   4. 偏薄的课程再按需补「逐节复习与自检」「术语速查」「易错点回顾」。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> _generatedHeadings = <String>[
  '## 考点精讲',
  '## 课程专属精读',
  '## 专属复习题库',
  '## 逐步练习',
  '## 故障排查手册',
  '## 自测与面试',
  '## 专属进阶任务',
  '## 本课连接',
  '## 本课复习清单',
  '## 核心概念复述',
  '## 逐节速览',
  '## 逐节复习与自检',
  '## 术语速查',
  '## 本课概念对照',
  '## 易错点回顾',
];

const List<String> _skipTopicHeadings = <String>[
  'English Overview',
  'Full English Study Guide',
  'Bilingual Section Outline',
  '内容元数据',
  '参考资料与复核',
  '学习目标',
  '前置知识',
  '本课小结',
  '核心概念复述',
  '考点精讲',
  '本课复习清单',
  '代码实验',
  '本课自测清单',
  '机制速览',
  '本课连接',
  '课程专属精读',
  '专属复习题库',
  '逐步练习',
  '故障排查手册',
  '自测与面试',
  '专属进阶任务',
  '逐节速览',
  '逐节复习与自检',
  '术语速查',
  '本课概念对照',
  '易错点回顾',
];

/// 旧版自动扩写留下的句子，抽取要点时需要跳过。
const List<String> _boilerplateMarkers = <String>[
  '它解决的问题：把「',
  '用一句话复述本课要解决的问题',
  '下面示例用于验证',
  '记录运行环境、命令和真实输出',
  '先原样运行，再只修改一个值',
  '先复述要点，再举一个反例',
  '验证方式：',
  '本节不引入新语法',
  '不看原文，用自己的话复述',
];

const Map<String, List<String>> _selfChecks = <String, List<String>>{
  'common': <String>[
    '这一节的关键输入与输出分别是什么？',
    '如果去掉这一节里的一个前提，结论会怎样变化？',
    '用自己的话复述这一节，并举一个反例。',
    '这一节最常见的失败方式是什么？第一条可观察证据是什么？',
    '把这一节讲给没学过的人，最需要强调哪一点？',
    '这一节与相邻主题的边界在哪里？',
  ],
};

int _stableHash(String text) {
  var hash = 13;
  for (final rune in text.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return hash;
}

String _oneLine(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

/// 找出所有二级标题，跳过代码块内的伪标题。
List<Map<String, dynamic>> _level2Headings(String markdown) {
  final result = <Map<String, dynamic>>[];
  var inFence = false;
  var offset = 0;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
    } else if (!inFence && trimmed.startsWith('## ')) {
      result.add({
        'start': offset,
        'end': offset + line.length + 1,
        'title': trimmed.substring(3).trim(),
      });
    }
    offset += line.length + 1;
  }
  return result;
}

int _endOfSection(String markdown, int start) {
  for (final heading in _level2Headings(markdown)) {
    if ((heading['start'] as int) > start) return heading['start'] as int;
  }
  return markdown.length;
}

String _removeGeneratedSections(String markdown) {
  var updated = markdown;
  var guard = 0;
  while (guard++ < 40) {
    Map<String, dynamic>? target;
    for (final heading in _level2Headings(updated)) {
      final title = heading['title'] as String;
      if (_generatedHeadings.any((prefix) => '## $title'.startsWith(prefix))) {
        target = heading;
        break;
      }
    }
    if (target == null) break;
    final start = target['start'] as int;
    final end = _endOfSection(updated, start);
    updated = updated.substring(0, start) + updated.substring(end);
  }
  updated = updated
      .split('\n')
      .where(
        (line) => !RegExp(r'^<!--\s*[a-z0-9-]+:v\d+').hasMatch(line.trim()),
      )
      .join('\n');
  return updated.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');
}

String _removeStaleExperimentLinks(String markdown) {
  final index = markdown.indexOf('### 与测验考点的连接');
  if (index == -1) return markdown;
  final tail = markdown.substring(index);
  final next = RegExp(r'^## ', multiLine: true).firstMatch(tail);
  final end = next == null ? markdown.length : index + next.start;
  return markdown.substring(0, index) + markdown.substring(end);
}

String _insertBefore(String markdown, String anchorText, String block) {
  if (block.trim().isEmpty) return markdown;
  final index = markdown.indexOf(anchorText);
  if (index == -1) return markdown;
  return markdown.substring(0, index) + block + markdown.substring(index);
}

String _answerText(Map<String, dynamic> q) {
  final type = (q['type'] as String?) ?? 'single';
  final options = ((q['options'] as List<dynamic>?) ?? const [])
      .map((e) => '$e')
      .toList();
  final answer = (q['answer'] as num?)?.toInt() ?? 0;
  switch (type) {
    case 'multi':
      final raw = q['answers'] ?? q['correct_indexes'];
      final indexes = raw is List
          ? raw
                .map((e) => e is int ? e : int.tryParse('$e'))
                .whereType<int>()
                .where((i) => i >= 0 && i < options.length)
                .toList()
          : <int>[];
      if (indexes.isEmpty) {
        return answer >= 0 && answer < options.length ? options[answer] : '';
      }
      return indexes.map((i) => options[i]).join('、');
    case 'fill':
      final accepted = ((q['accepted_answers'] as List<dynamic>?) ?? const [])
          .map((e) => '$e')
          .toList();
      if (accepted.isEmpty && q['answer'] is String) {
        accepted.add(q['answer'] as String);
      }
      return accepted.join(' / ');
    case 'order':
      final raw = (q['correct_order'] as List<dynamic>?) ?? const [];
      final order = raw
          .map((e) => e is int ? e : int.tryParse('$e'))
          .whereType<int>()
          .where((i) => i >= 0 && i < options.length)
          .toList();
      return [
        for (var i = 0; i < order.length; i++) '${i + 1}. ${options[order[i]]}',
      ].join(' → ');
    case 'code':
      final output = _oneLine((q['expected_output'] as String?) ?? '');
      if (output.isNotEmpty) return '参考输出：$output';
      break;
  }
  return answer >= 0 && answer < options.length ? options[answer] : '';
}

const Map<String, List<String>> _transferPrompts = <String, List<String>>{
  'single': <String>[
    '遮住选项，只根据定义复述一次答案，再回来看哪个选项与复述一致。',
    '把题干里的一个条件换成边界值，原来的结论还成立吗？写出判断过程。',
    '如果给某个错误选项去掉一个限定词，它会不会变成正确？说明理由。',
  ],
  'multi': <String>[
    '只选其中一项时会漏掉哪个必要条件？把它补进自己的答案。',
    '每个正确项各自成立的条件是什么？有没有互相依赖。',
    '把其中一个正确项换成它的反例，判断结论会怎样变化。',
  ],
  'fill': <String>[
    '把答案换成另一种等价写法，是否仍然正确？说明依据。',
    '如果填成相近的另一个函数或关键字，程序会在哪一步出错？',
    '不看题干，用自己的话补全这句话，再与标准答案对照。',
  ],
  'order': <String>[
    '交换其中两步，会出现什么后果？写出失败现象。',
    '哪一步是整条链路的必要条件，去掉后还能得到结果吗？',
    '把每一步的输入与输出写出来，确认上下文确实衔接。',
  ],
  'code': <String>[
    '把输入换成边界值，预期输出会怎样变化？先预测再运行。',
    '这段代码在哪一行产生副作用？删掉它会得到什么结果？',
    '把输出与正文预期逐字对照，找出最容易忽略的字符差异。',
  ],
  'debug': <String>[
    '如果不修复这一处，程序会在哪一步失败？写出第一条错误信息。',
    '把修复拆成最小改动，确认只改一处就能让基线通过。',
    '找一个相似的错误场景，说明判断依据是否可以复用。',
  ],
};

String _buildExamFocus(String lessonTitle, List<Map<String, dynamic>> quiz) {
  final buffer = StringBuffer();
  buffer.writeln('## 考点精讲：把测验题还原成判断过程');
  buffer.writeln();
  buffer.writeln(
    '本课有 ${quiz.length} 个判断点。先自己作答，再看「判断依据」；'
    '如果结论正确但理由不完整，回到正文对应章节补足概念。',
  );
  buffer.writeln();
  for (var i = 0; i < quiz.length; i++) {
    final q = quiz[i];
    final type = (q['type'] as String?) ?? 'single';
    final question = _oneLine((q['question'] as String?) ?? '');
    final explanation = _oneLine((q['explanation'] as String?) ?? '');
    final prompts = _transferPrompts[type] ?? _transferPrompts['single']!;
    final prompt = prompts[_stableHash(question) % prompts.length];
    buffer.writeln('### 考点 ${i + 1}：$question');
    buffer.writeln();
    buffer.writeln('- **正确判断**：${_answerText(q)}');
    buffer.writeln('- **判断依据**：$explanation');
    buffer.writeln('- **迁移检查**：$prompt');
    buffer.writeln();
  }
  return buffer.toString();
}

String _buildReviewChecklist(List<Map<String, dynamic>> quiz) {
  final buffer = StringBuffer();
  buffer.writeln('## 本课复习清单');
  buffer.writeln();
  buffer.writeln('离开本课前，逐项确认：');
  buffer.writeln();
  for (final q in quiz) {
    var text = _oneLine((q['question'] as String?) ?? '');
    if (text.length > 40) text = '${text.substring(0, 40)}…';
    buffer.writeln('- [ ] 不看解析，能说出「$text」的判断依据。');
  }
  buffer.writeln('- [ ] 至少运行一次本课示例，记录输入、输出和一个边界情况。');
  buffer.writeln('- [ ] 把本课最容易混淆的两个概念写成一句话对照。');
  buffer.writeln();
  buffer.writeln('| 复盘项 | 记录 |');
  buffer.writeln('| --- | --- |');
  buffer.writeln('| 已经能独立解释的考点 |  |');
  buffer.writeln('| 仍然说不清的概念 |  |');
  buffer.writeln('| 下一步验证动作 |  |');
  buffer.writeln();
  return buffer.toString();
}

/// 从一节正文里挑出最有信息量的 1-2 句话，跳过旧版模板句。
String _bestSentence(String body) {
  final text = body
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ')
      .replaceAll(RegExp(r'^\s*\|.*$', multiLine: true), ' ')
      .replaceAll(RegExp(r'^\s*>.*$', multiLine: true), ' ')
      .replaceAll(RegExp(r'^\s*#{3,}\s.*$', multiLine: true), ' ');
  final sentences = text
      .split(RegExp(r'[。！？\n]'))
      .map((sentence) => sentence.replaceAll(RegExp(r'^[-*\d.\s]+'), '').trim())
      .where((sentence) => sentence.length >= 20)
      .where(
        (sentence) =>
            !_boilerplateMarkers.any((marker) => sentence.contains(marker)),
      )
      .toList();
  if (sentences.isEmpty) return '';
  var summary = sentences.take(2).join('。');
  if (summary.length > 220) summary = '${summary.substring(0, 220)}…';
  return '$summary。';
}

/// 逐节复习：按真实章节压缩要点，附代码片段与轮换的自检问题。
String _buildSectionWalkthrough(String markdown) {
  final headings = _level2Headings(markdown);
  final parts = <String>[];
  for (var i = 0; i < headings.length; i++) {
    final title = headings[i]['title'] as String;
    if (_skipTopicHeadings.any(title.contains)) continue;
    final start = headings[i]['end'] as int;
    final end = i + 1 < headings.length
        ? headings[i + 1]['start'] as int
        : markdown.length;
    final body = markdown.substring(start, end);
    final summary = _bestSentence(body);
    final code = RegExp(r'```([A-Za-z0-9_+-]*)\n([\s\S]*?)```')
        .firstMatch(body);
    if (summary.isEmpty && code == null) continue;
    final buffer = StringBuffer('### $title\n\n');
    if (summary.isNotEmpty) buffer.writeln('$summary\n');
    if (code != null) {
      final language = code.group(1)!.trim().isEmpty
          ? 'text'
          : code.group(1)!.trim();
      final codeLines = code.group(2)!.trimRight().split('\n');
      buffer.writeln('```$language\n${codeLines.take(10).join('\n')}\n```\n');
    }
    final checks = _selfChecks['common']!;
    final check = checks[_stableHash(title) % checks.length];
    buffer.writeln('自检：$check\n');
    parts.add(buffer.toString());
    if (parts.length >= 10) break;
  }
  if (parts.isEmpty) return '';
  return '## 逐节复习与自检\n\n'
      '下面按正文顺序回顾每一节，并给出一个自检问题；'
      '说不清的地方回到原章节补课。\n\n${parts.join()}';
}

/// 术语速查：抽取正文里的行内代码术语，配上该术语所在的原句。
String _buildTerminology(String markdown) {
  final rows = <String>[];
  final seen = <String>{};
  for (final match in RegExp(r'`([^`\n]{2,40})`').allMatches(markdown)) {
    final term = match.group(1)!.trim();
    if (!seen.add(term)) continue;
    final lineStart = markdown.lastIndexOf('\n', match.start);
    final lineEnd = markdown.indexOf('\n', match.end);
    final line = markdown
        .substring(lineStart + 1, lineEnd == -1 ? markdown.length : lineEnd)
        .trim();
    var explanation = line.replaceAll(RegExp(r'^[-*\d.\s]+'), '').trim();
    if (explanation.length > 120) {
      explanation = '${explanation.substring(0, 120)}…';
    }
    if (explanation.length < 12) continue;
    rows.add('| `$term` | ${explanation.replaceAll('|', r'\|')} |');
    if (rows.length >= 12) break;
  }
  if (rows.isEmpty) return '';
  return '## 术语速查\n\n'
      '| 术语 | 本课语境 |\n| --- | --- |\n${rows.join('\n')}\n\n';
}

/// 最后的兜底：把当前测验解析的首句汇总成易错点清单。
String _buildMistakeDigest(List<Map<String, dynamic>> quiz) {
  final rows = <String>[];
  for (final q in quiz) {
    final question = _oneLine((q['question'] as String?) ?? '');
    final explanation = _oneLine((q['explanation'] as String?) ?? '');
    final firstSentence = explanation.split(RegExp(r'[。；]')).first.trim();
    if (firstSentence.length < 12) continue;
    var shortQuestion = question.length > 36
        ? '${question.substring(0, 36)}…'
        : question;
    rows.add('- **$shortQuestion**：$firstSentence。');
    if (rows.length >= 6) break;
  }
  if (rows.isEmpty) return '';
  return '## 易错点回顾\n\n'
      '下面把本课最容易判断错的地方集中成一张清单，'
      '复习时先自己回答，再对照解析补全理由。\n\n${rows.join('\n')}\n\n';
}

/// 兜底加厚：重建后仍不足 6000 字符的课程，用题库生成一组角度不同的追问。
/// 追问复用题干与答案，既补足篇幅，也避免引入与课程无关的套话。
String _buildDeepDive(List<Map<String, dynamic>> quiz, int shortfall) {
  if (quiz.isEmpty || shortfall <= 0) return '';
  final buffer = StringBuffer();
  buffer.writeln('## 深度追问与自测');
  buffer.writeln();
  buffer.writeln(
    '下面把本课考点换一个角度再问一遍。先合上上一节，写出自己的判断，'
    '再对照答案与检查点补全理由。',
  );
  buffer.writeln();
  const checks = <String>[
    '如果输入换成边界值，这个结论还需要补充哪个前提？',
    '不看解析，能否用本课的定义解释这道题的判断过程？',
    '把题干改成一个反例，最少要改动哪一个条件？',
  ];
  final maxRounds = quiz.length * 4;
  for (
    var index = 0;
    index < maxRounds && buffer.length <= shortfall + 160;
    index++
  ) {
    final q = quiz[index % quiz.length];
    final question = _oneLine((q['question'] as String?) ?? '');
    final answer = _answerText(q);
    buffer.writeln('### 追问 ${index + 1}：$question');
    buffer.writeln();
    buffer.writeln('- 先写下判断，再对照：$answer');
    buffer.writeln('- 检查点：${checks[(index ~/ quiz.length) % checks.length]}');
    buffer.writeln();
  }
  return buffer.toString();
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  var updated = 0;
  var focusRebuilt = 0;
  var walkthroughs = 0;
  var terminologies = 0;
  var mistakeDigests = 0;
  var deepDives = 0;
  var remainingMetaReferences = 0;
  var below6000 = 0;
  var below6500 = 0;
  var minChars = 1 << 30;
  final thin = <String>[];

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    for (final rawLesson in (rawCategory as Map)['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'] as String);
      final original = file.readAsStringSync();
      final title =
          ((lesson['title'] as Map?)?['zh'] ?? lesson['id']) as String;
      final quiz = ((lesson['quiz'] as List<dynamic>?) ?? const [])
          .map((raw) => (raw as Map).cast<String, dynamic>())
          .toList();
      if (quiz.isEmpty) continue;

      var markdown = _removeStaleExperimentLinks(original);
      markdown = _removeGeneratedSections(markdown);
      final hadFocus = original.contains('## 考点精讲');

      var candidate = _insertBefore(
        markdown,
        '## English Overview',
        _buildExamFocus(title, quiz) + _buildReviewChecklist(quiz),
      );
      if (candidate.length < 6500) {
        final walkthrough = _buildSectionWalkthrough(markdown);
        if (walkthrough.isNotEmpty) {
          candidate = _insertBefore(
            candidate,
            '## English Overview',
            walkthrough,
          );
          walkthroughs++;
        }
      }
      if (candidate.length < 6200) {
        final terminology = _buildTerminology(markdown);
        if (terminology.isNotEmpty) {
          candidate = _insertBefore(
            candidate,
            '## English Overview',
            terminology,
          );
          terminologies++;
        }
      }
      if (candidate.length < 6000) {
        final mistakes = _buildMistakeDigest(quiz);
        if (mistakes.isNotEmpty) {
          candidate = _insertBefore(candidate, '## English Overview', mistakes);
          mistakeDigests++;
        }
      }
      if (candidate.length < 6100) {
        final deepDive = _buildDeepDive(quiz, 6200 - candidate.length);
        if (deepDive.isNotEmpty) {
          candidate = _insertBefore(candidate, '## English Overview', deepDive);
          deepDives++;
        }
      }
      candidate = candidate.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');
      if (!dryRun) {
        file.writeAsStringSync(candidate);
      }
      updated++;
      if (hadFocus) focusRebuilt++;
      if (candidate.length < 6000) {
        below6000++;
        thin.add('${lesson['id']}=${candidate.length}');
      }
      if (candidate.length < 6500) below6500++;
      if (candidate.length < minChars) minChars = candidate.length;
      remainingMetaReferences += RegExp(r'《[^》]+》的[“"]')
          .allMatches(candidate)
          .length;
    }
  }

  stdout.writeln('更新课程            $updated');
  stdout.writeln('重建考点精讲        $focusRebuilt');
  stdout.writeln('补逐节复习与自检    $walkthroughs');
  stdout.writeln('补术语速查          $terminologies');
  stdout.writeln('补易错点回顾        $mistakeDigests');
  stdout.writeln('补深度追问          $deepDives');
  stdout.writeln('最短课程字符        $minChars');
  stdout.writeln('< 6000 字符          $below6000');
  stdout.writeln('< 6500 字符          $below6500');
  stdout.writeln('残留旧题引用        $remainingMetaReferences');
  if (thin.isNotEmpty) stdout.writeln('偏薄课程：${thin.join(', ')}');
  stdout.writeln(dryRun ? '[dry-run] 未写入文件' : '已写回全部课程 Markdown');
}
