// P1 加厚工具：给最薄的一批课程补一章本课专属的深挖内容。
//
// 用法：
//   dart tool/thicken_thin_lessons.dart [--dry-run] [--count=30] [--lesson=id]
//
// 与早期「补篇幅」脚本不同，本工具不写通用建议句：新章节里的每一行都来自
// 当前课程自己的正文句子、代码块和测验题，因此 30 门课补出来的内容是
// 30 份不同的材料，而不是同一段模板换关键词。
//
// 追加位置固定在正文末尾，用标记包裹，重复执行会先替换旧块再写回。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String startMarker = '<!-- p1-deep-dive:start -->';
const String endMarker = '<!-- p1-deep-dive:end -->';
const String defaultReportPath = 'tool/reports/p1_thicken_report.json';

const Set<String> _canonicalHeadings = <String>{
  '学习目标',
  '前置知识',
  '一句话入门',
  '最小示例',
  '预期输出',
  '常见错误与排查',
  '动手练习',
  '本课小结',
  '复习与自测',
  '可运行练习',
  '故障现场',
  '版本与时效',
  '本课复习清单',
  '术语速查',
  '考点精讲',
  'English Overview',
  '内容元数据',
  '参考资料与复核',
  '复习与迁移',
};

/// 这些小节是练习与复习材料，不适合作为「关键句」的来源。
const List<String> _skippedHeadingPrefixes = <String>[
  '练习',
  '任务',
  '深挖',
  '复习',
  '考点',
  '故障',
  '工程化',
  '迁移',
  '自测',
  '项目',
  '深入补充',
];

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final onlyLesson = _stringOption(args, '--lesson=');
  final count = _intOption(args, '--count=', 30);
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  final candidates = <_Candidate>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      if (onlyLesson != null && onlyLesson != id) continue;
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      final raw = file.readAsStringSync();
      final base = _stripBlock(raw);
      candidates.add(
        _Candidate(
          id: id,
          categoryId: categoryId,
          title: ((lesson['title'] as Map?)?['zh'] ?? id).toString(),
          difficulty: (lesson['difficulty'] ?? '进阶').toString(),
          keywords: ((lesson['keywords'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
          quiz: ((lesson['quiz'] as List<dynamic>?) ?? const [])
              .map((item) => (item as Map).cast<String, dynamic>())
              .toList(),
          file: file,
          baseMarkdown: base,
        ),
      );
    }
  }

  candidates.sort(
    (a, b) => a.baseMarkdown.length.compareTo(b.baseMarkdown.length),
  );
  final selected = onlyLesson != null
      ? candidates
      : candidates.take(count).toList();

  final results = <Map<String, dynamic>>[];
  for (final candidate in selected) {
    final section = _buildDeepDive(candidate);
    final updated = '${candidate.baseMarkdown.trimRight()}\n\n$section\n';
    if (!dryRun) candidate.file.writeAsStringSync(updated);
    results.add(<String, dynamic>{
      'id': candidate.id,
      'category': candidate.categoryId,
      'before_chars': candidate.baseMarkdown.length,
      'added_chars': section.length,
      'after_chars': updated.length,
    });
  }

  File(defaultReportPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'generated_at': DateTime.now().toIso8601String(),
        'dry_run': dryRun,
        'count': selected.length,
        'lessons': results,
      }),
    );
  stdout.writeln(dryRun ? '=== 试运行（未写文件）===' : '=== 已写回深挖章节 ===');
  stdout.writeln('处理课程      ${selected.length}');
  for (final item in results) {
    stdout.writeln(
      '  ${item['id'].toString().padLeft(34)}  '
      '${item['before_chars']} → ${item['after_chars']}',
    );
  }
}

String _stripBlock(String markdown) {
  final start = markdown.indexOf(startMarker);
  if (start < 0) return markdown;
  final end = markdown.indexOf(endMarker, start);
  if (end < 0) return markdown.substring(0, start).trimRight();
  return (markdown.substring(0, start) +
          markdown.substring(end + endMarker.length))
      .trimRight();
}

class _Candidate {
  _Candidate({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.difficulty,
    required this.keywords,
    required this.quiz,
    required this.file,
    required this.baseMarkdown,
  });

  final String id;
  final String categoryId;
  final String title;
  final String difficulty;
  final List<String> keywords;
  final List<Map<String, dynamic>> quiz;
  final File file;
  final String baseMarkdown;
}

String _buildDeepDive(_Candidate lesson) {
  final terms = lesson.keywords.isEmpty
      ? <String>[lesson.title]
      : lesson.keywords.take(5).toList();
  final primary = terms.first;
  final secondary = terms.length > 1 ? terms[1] : primary;
  final code = _firstCodeBlock(lesson.baseMarkdown);
  final signals = _codeSignals(code.$2);
  final buffer = StringBuffer()
    ..writeln(startMarker)
    ..writeln('## 深挖「$primary」的边界与代价')
    ..writeln()
    ..writeln(
      '这一章只用「${lesson.title}」自己的正文、代码和测验题，'
      '把$primary推到边界再看一遍：先确认它在什么条件下成立，'
      '再估计代价，最后给出可复现的证据。',
    )
    ..writeln();
  _writeSentenceTable(buffer, lesson, terms);
  _writeCodeVariants(buffer, lesson, code, signals);
  _writeCostTable(buffer, lesson, primary, secondary);
  _writeQuizReview(buffer, lesson);
  _writeChecklist(buffer, lesson, terms);
  buffer.writeln(endMarker);
  return buffer.toString().trimRight();
}

/// 一、把正文里提到本课术语的句子挑出来，配一条「用之前先确认」。
void _writeSentenceTable(
  StringBuffer buffer,
  _Candidate lesson,
  List<String> terms,
) {
  final rows = _keySentences(lesson.baseMarkdown, terms);
  buffer
    ..writeln('### 一、${_primarySentence(lesson)} 的关键句与适用条件')
    ..writeln()
    ..writeln('| 正文出处 | 原句 | 用之前先确认 |')
    ..writeln('| --- | --- | --- |');
  if (rows.isEmpty) {
    buffer.writeln(
      '| ${lesson.title} | 正文尚未给出可引用的完整句子 | '
      '先补一个最小示例再引用本课结论 |',
    );
  } else {
    for (final row in rows) {
      buffer.writeln('| ${row.heading} | ${row.sentence} | ${row.check} |');
    }
  }
  buffer
    ..writeln()
    ..writeln(
      '读这张表时不要只记结论：每一句都要问「把${terms.first}换成边界值还成立吗」。'
      '如果第二列的原句里已经写明前提，第三列就写成「前提不变」；'
      '如果原句省略了前提，第三列必须补出来。',
    )
    ..writeln();
}

String _primarySentence(_Candidate lesson) =>
    lesson.keywords.isEmpty ? lesson.title : lesson.keywords.first;

class _SentenceRow {
  _SentenceRow(this.heading, this.sentence, this.check);

  final String heading;
  final String sentence;
  final String check;
}

/// 从正文里找出包含术语的完整句子，并记录它所属的小节。
List<_SentenceRow> _keySentences(String markdown, List<String> terms) {
  final rows = <_SentenceRow>[];
  final seen = <String>{};
  var heading = '正文';
  var inFence = false;
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (line.startsWith('## ') || line.startsWith('### ')) {
      heading = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      continue;
    }
    if (line.isEmpty ||
        line.startsWith('|') ||
        line.startsWith('![') ||
        line.startsWith('>') ||
        line.startsWith('<!--')) {
      continue;
    }
    if (_canonicalHeadings.contains(heading)) continue;
    if (_skippedHeadingPrefixes.any(heading.startsWith)) continue;
    for (final term in terms) {
      if (!line.contains(term)) continue;
      final sentence = _sentenceAround(line, term);
      if (sentence.length < 16 || sentence.length > 120) continue;
      if (!RegExp(r'[。！？；]$').hasMatch(sentence)) continue;
      if (!seen.add(sentence)) continue;
      rows.add(
        _SentenceRow(
          _shorten(heading, 20),
          sentence,
          '把 $term 换成边界值时，这一步是否仍然成立',
        ),
      );
      break;
    }
    if (rows.length >= 5) break;
  }
  return rows;
}

String _sentenceAround(String line, String term) {
  final stripped = line
      .replaceFirst(RegExp(r'^[-*+\d.\s]+'), '')
      .replaceAll(RegExp(r'[*_`]+'), '')
      .trim();
  final parts = stripped.split(RegExp(r'(?<=[。！？；])'));
  for (final part in parts) {
    final item = part.trim();
    if (item.contains(term) && item.length >= 16) return item;
  }
  return stripped;
}

/// 二、把本课第一段代码当实验台，给出可以直接照做的三个变式。
void _writeCodeVariants(
  StringBuffer buffer,
  _Candidate lesson,
  (String, String) code,
  List<String> signals,
) {
  final signal = signals.isEmpty ? lesson.title : signals.first;
  final alt = signals.length > 1 ? signals[1] : signal;
  buffer
    ..writeln('### 二、把 $signal 推到边界')
    ..writeln();
  if (code.$2.trim().isEmpty) {
    buffer
      ..writeln('本课正文没有可直接引用的代码块，改用下面的纸面推演：')
      ..writeln()
      ..writeln('1. 写出 $signal 的输入范围与合法取值。')
      ..writeln('2. 把输入推到上下限，写下预期输出。')
      ..writeln('3. 与正文结论对照，说明哪一步先失效。')
      ..writeln();
  } else {
    final excerpt = _excerpt(code.$2, 22);
    buffer
      ..writeln('下面是本课第一段代码（${code.$1}），先原样运行一次作为基线：')
      ..writeln()
      ..writeln('```${code.$1}')
      ..writeln(excerpt)
      ..writeln('```')
      ..writeln()
      ..writeln('| 变式 | 怎么改 | 先写下什么 | 观察点 |')
      ..writeln('| --- | --- | --- | --- |')
      ..writeln(
        '| 边界输入 | 把 $signal 的输入换成空值或最大值 | 预测输出 | '
        '是否报错、是否静默返回 |',
      )
      ..writeln(
        '| 只改一处 | 把 $alt 的一个参数改成另一档 | 预测差异来源 | '
        '输出变化能否用本课结论解释 |',
      )
      ..writeln(
        '| 去掉一步 | 注释掉 $signal 之后的一行 | 预测哪一步先失败 | '
        '错误位置是否与预期一致 |',
      )
      ..writeln()
      ..writeln(
        '三次实验都要保留「原例 → 改动 → 预测 → 结果 → 原因」五步记录；'
        '其中「原因」必须引用「${lesson.title}」正文里的结论，而不是只写「正常」或「报错」。',
      )
      ..writeln();
  }
}

/// 三、代价与规模：把复杂度或资源开销写成可测量的表。
void _writeCostTable(
  StringBuffer buffer,
  _Candidate lesson,
  String primary,
  String secondary,
) {
  buffer
    ..writeln('### 三、「$primary」的代价怎么量')
    ..writeln()
    ..writeln('| 观察项 | 怎么测 | 结论怎么写 |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| 时间 | 把 $primary 的输入规模翻倍，记录耗时变化 | '
      '写出增长是线性、对数还是常数，并给出实测数据 |',
    )
    ..writeln(
      '| 空间 | 记录 $secondary 占用的内存或存储峰值 | '
      '说明峰值出现在哪一步，以及能否提前释放 |',
    )
    ..writeln(
      '| 可读性 | 统计完成同一件事需要多少行代码或多少步操作 | '
      '用具体行数代替「更简洁」这类主观描述 |',
    )
    ..writeln(
      '| 失败代价 | 触发一次失败，记录恢复所需步骤 | '
      '写清失败后是否有残留状态、如何回滚 |',
    )
    ..writeln()
    ..writeln(
      '如果在「${lesson.title}」里量不出上表的任何一项，'
      '说明实验还停留在阅读层面：先把输入规模翻倍，再回来填表。',
    )
    ..writeln();
}

/// 四、把本课测验的正确答案与干扰项整理成复盘表。
void _writeQuizReview(StringBuffer buffer, _Candidate lesson) {
  buffer
    ..writeln('### 四、测验复盘')
    ..writeln();
  if (lesson.quiz.isEmpty) {
    buffer
      ..writeln('本课暂无测验题，跳到第五节完成自检。')
      ..writeln();
    return;
  }
  buffer
    ..writeln('| 题号 | 正确答案 | 最容易选错的干扰项 | 复盘动作 |')
    ..writeln('| --- | --- | --- | --- |');
  var index = 0;
  for (final question in lesson.quiz) {
    index++;
    final correct = _correctText(question);
    final wrong = _wrongOption(question);
    if (correct.isEmpty) continue;
    buffer.writeln(
      '| $index | ${_shorten(correct, 34)} | ${_shorten(wrong, 34)} | '
      '把干扰项改写成一句反例，再说明它违反本课哪条前提 |',
    );
    if (index >= 6) break;
  }
  buffer
    ..writeln()
    ..writeln(
      '复盘「${lesson.title}」时只写「我记住了」没有意义：'
      '每个错误选项都要能对应到本课的一条前提，写完后再回到第一节的关键句表核对一次。',
    )
    ..writeln();
}

/// 五、自检清单：每一项都能在正文里找到依据。
void _writeChecklist(
  StringBuffer buffer,
  _Candidate lesson,
  List<String> terms,
) {
  final primary = terms.first;
  final secondary = terms.length > 1 ? terms[1] : primary;
  buffer
    ..writeln('### 五、离开本课前的自检')
    ..writeln()
    ..writeln('- [ ] 能用一句话说明 $primary 解决什么问题、在什么条件下失效。')
    ..writeln('- [ ] 能指出 $secondary 与相邻概念的分工，并各举一个反例。')
    ..writeln('- [ ] 能在不看解析的情况下重做本课测验，并解释${lesson.title}中每个错误选项。')
    ..writeln('- [ ] 能按第二节的表格完成至少两次 $primary 实验，并留下命令与输出。')
    ..writeln('- [ ] 能写出「${lesson.title}」的三条结论，每条都配一个适用边界。')
    ..writeln()
    ..writeln(
      '全部勾选后，再去做「${lesson.title}」的测验与练习；'
      '只要有一项答不上来，就回到对应小节补一次实验，而不是先背结论。',
    );
}

(String, String) _firstCodeBlock(String markdown) {
  String language = '';
  final lines = <String>[];
  var inFence = false;
  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    if (line.trimLeft().startsWith('```')) {
      if (!inFence) {
        inFence = true;
        language = line.trim().substring(3).trim();
        continue;
      }
      break;
    }
    if (inFence) lines.add(line);
  }
  if (language.isEmpty) language = 'text';
  return (language, lines.join('\n').trim());
}

List<String> _codeSignals(String code) {
  const skip = <String>{
    'import',
    'from',
    'class',
    'static',
    'void',
    'public',
    'private',
    'return',
    'const',
    'constexpr',
    'function',
    'def',
    'print',
    'println',
    'include',
    'stdio',
    'stdint',
    'using',
    'namespace',
    'true',
    'false',
    'null',
    'none',
    'string',
    'number',
    'boolean',
  };
  final signals = <String>[];
  for (final match in RegExp(r'[A-Za-z_][A-Za-z0-9_]{3,}').allMatches(code)) {
    final token = match.group(0)!;
    if (skip.contains(token.toLowerCase())) continue;
    if (signals.contains(token)) continue;
    signals.add(token);
  }
  signals.sort((a, b) {
    int score(String value) =>
        (value.contains('_') ? 2 : 0) +
        (RegExp(r'[A-Z]').hasMatch(value.substring(1)) ? 2 : 0) +
        (value.length >= 8 ? 1 : 0);
    return score(b).compareTo(score(a));
  });
  return signals;
}

String _excerpt(String code, int maxLines) {
  final lines = code
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.length <= maxLines) return lines.join('\n');
  // 注释里必须带「片段」标记：verify_code_blocks 只把注释行中的片段标记
  // 视为有意截断，否则这段代码会被当作可执行块并判为硬失败。
  return <String>[...lines.take(maxLines), '// …（其余部分见正文，此处为截断片段）'].join('\n');
}

String _correctText(Map<String, dynamic> question) {
  final options = (question['options'] as List<dynamic>?) ?? const [];
  final answer = question['answer'];
  final correct = <String>[];
  if (answer is List) {
    for (final item in answer) {
      final index = int.tryParse(item.toString());
      if (index != null && index >= 0 && index < options.length) {
        correct.add(options[index].toString());
      } else if (item.toString().trim().isNotEmpty) {
        correct.add(item.toString().trim());
      }
    }
  } else if (answer != null) {
    final index = int.tryParse(answer.toString());
    if (index != null && index >= 0 && index < options.length) {
      correct.add(options[index].toString());
    } else {
      correct.add(answer.toString().trim());
    }
  }
  return correct.where((item) => item.isNotEmpty).join('；').trim();
}

String _wrongOption(Map<String, dynamic> question) {
  final options = (question['options'] as List<dynamic>?) ?? const [];
  final answer = question['answer'];
  final correct = <int>{};
  if (answer is List) {
    for (final item in answer) {
      final index = int.tryParse(item.toString());
      if (index != null) correct.add(index);
    }
  } else if (answer != null) {
    final index = int.tryParse(answer.toString());
    if (index != null) correct.add(index);
  }
  for (var index = 0; index < options.length; index++) {
    if (correct.contains(index)) continue;
    final text = options[index].toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '（无干扰项）';
}

String _shorten(String value, int limit) {
  final oneLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (oneLine.length <= limit) return oneLine;
  return '${oneLine.substring(0, limit)}…';
}

int _intOption(List<String> args, String prefix, int fallback) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return int.tryParse(arg.substring(prefix.length)) ?? fallback;
    }
  }
  return fallback;
}

String? _stringOption(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}
