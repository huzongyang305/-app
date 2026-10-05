// P0 题库质量巡检工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/analyze_quiz_quality.dart [--json] [--top=30]
//
// 输出四类 P0 硬指标：
//   1. 元问题：题干是「《课程名》的……」这类复述标题、无法真正作答的题；
//   2. 模板句：在 >=5 道题解析里重复出现的同一句话；
//   3. 最长项命中：正确选项严格最长（且与次长项差距 >= 8 字符）的比例；
//   4. 基础约束：解析长度 <120、单选答案下标分布、题干重复。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

void main(List<String> args) {
  final emitJson = args.contains('--json');
  final dump = args.contains('--dump');
  final top =
      int.tryParse(
        args
            .firstWhere((a) => a.startsWith('--top='), orElse: () => '--top=25')
            .substring('--top='.length),
      ) ??
      25;

  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final questions = <Map<String, dynamic>>[];
  final lessonTitles = <String, String>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'] as String;
      final title = ((lesson['title'] as Map?)?['zh'] ?? id) as String;
      lessonTitles[id] = title;
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        question['_lessonId'] = id;
        question['_categoryId'] = category['id'];
        questions.add(question);
      }
    }
  }

  String type(Map<String, dynamic> q) => (q['type'] as String?) ?? 'single';
  List<String> options(Map<String, dynamic> q) =>
      ((q['options'] as List<dynamic>?) ?? const []).cast<String>();
  int answerIndex(Map<String, dynamic> q) =>
      (q['answer'] as num?)?.toInt() ?? 0;

  // 1. 元问题。
  final metaPattern = RegExp(r'《.+?》');
  final meta = questions
      .where((q) => metaPattern.hasMatch((q['question'] as String?) ?? ''))
      .toList();
  final metaByLesson = <String, List<Map<String, dynamic>>>{};
  for (final q in meta) {
    metaByLesson.putIfAbsent(q['_lessonId'] as String, () => []).add(q);
  }

  // 2. 模板句（按句号/分号/换行切分，统计完全相同的句子）。
  final sentenceCount = <String, int>{};
  for (final q in questions) {
    final text = ((q['explanation'] as String?) ?? '').trim();
    for (final sentence in text.split(RegExp(r'[。；\n]'))) {
      final trimmed = sentence.trim();
      if (trimmed.length < 12) continue;
      sentenceCount[trimmed] = (sentenceCount[trimmed] ?? 0) + 1;
    }
  }
  final templateSentences =
      sentenceCount.entries.where((entry) => entry.value >= 5).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  final templatedQuestions = questions.where((q) {
    final text = ((q['explanation'] as String?) ?? '').trim();
    return text
        .split(RegExp(r'[。；\n]'))
        .map((s) => s.trim())
        .any((s) => (sentenceCount[s] ?? 0) >= 5);
  }).toList();

  // 3. 最长项命中。
  final single = questions
      .where(
        (q) =>
            type(q) == 'single' &&
            options(q).length >= 2 &&
            answerIndex(q) < options(q).length,
      )
      .toList();
  var strictlyLongest = 0;
  var stronglyLongest = 0;
  var tiedLongest = 0;
  var notLongest = 0;
  final longestHits = <Map<String, dynamic>>[];
  for (final q in single) {
    final opts = options(q);
    final correct = opts[answerIndex(q)];
    final lengths = opts.map((o) => o.trim().length).toList();
    final maxLength = lengths.reduce((a, b) => a > b ? a : b);
    final correctLength = correct.trim().length;
    final others = <int>[];
    for (var i = 0; i < lengths.length; i++) {
      if (i != answerIndex(q)) others.add(lengths[i]);
    }
    final second = others.reduce((a, b) => a > b ? a : b);
    if (correctLength > second) {
      strictlyLongest++;
      if (correctLength - second >= 8) {
        stronglyLongest++;
        longestHits.add({
          'lesson': q['_lessonId'],
          'question': q['question'],
          'answer': correct,
          'answerLen': correctLength,
          'secondLen': second,
          'options': opts,
        });
      }
    } else if (correctLength == maxLength) {
      tiedLongest++;
    } else {
      notLongest++;
    }
  }

  // 4. 基础约束。
  final shortExplanations = questions
      .where((q) => ((q['explanation'] as String?) ?? '').trim().length < 120)
      .toList();
  final answerCounts = <int, int>{};
  for (final q in single) {
    answerCounts[answerIndex(q)] = (answerCounts[answerIndex(q)] ?? 0) + 1;
  }
  final normalized = questions
      .map(
        (q) =>
            ((q['question'] as String?) ?? '').replaceAll(RegExp(r'\s+'), ''),
      )
      .toList();
  final seen = <String>{};
  final duplicates = <String>[];
  for (final text in normalized) {
    if (!seen.add(text)) duplicates.add(text);
  }

  final report = <String, dynamic>{
    'totalQuestions': questions.length,
    'metaQuestions': meta.length,
    'metaLessons': metaByLesson.length,
    'fullyMetaLessons': metaByLesson.values.where((l) => l.length >= 3).length,
    'templateSentences': templateSentences.length,
    'templatedQuestions': templatedQuestions.length,
    'singleChoice': single.length,
    'strictlyLongest': strictlyLongest,
    'stronglyLongest': stronglyLongest,
    'tiedLongest': tiedLongest,
    'notLongest': notLongest,
    'stronglyLongestRate': single.isEmpty
        ? 0
        : stronglyLongest * 100 / single.length,
    'shortExplanations': shortExplanations.length,
    'duplicateQuestions': duplicates.length,
    'answerIndexCounts': answerCounts,
    'answerIndexPercents': {
      for (var i = 0; i < 4; i++)
        '$i': single.isEmpty ? 0 : (answerCounts[i] ?? 0) * 100 / single.length,
    },
    'metaLessonsDetail': {
      for (final entry
          in (metaByLesson.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length))))
        entry.key: entry.value.length,
    },
  };

  if (dump) {
    final reportDir = Directory('tool/reports')..createSync(recursive: true);
    File('${reportDir.path}/p0_meta_questions.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert([
        for (final entry in metaByLesson.entries)
          {
            'lesson': entry.key,
            'questions': [
              for (final q in entry.value)
                {
                  'type': type(q),
                  'question': q['question'],
                  'options': options(q),
                  'answer': answerIndex(q),
                  'explanation': q['explanation'],
                },
            ],
          },
      ]),
    );
    File('${reportDir.path}/p0_template_sentences.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert([
        for (final entry in templateSentences)
          {'count': entry.value, 'sentence': entry.key},
      ]),
    );
    File('${reportDir.path}/p0_longest_hits.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert([
        for (final hit
            in (longestHits.toList()..sort(
              (a, b) => ((b['answerLen'] as int) - (b['secondLen'] as int))
                  .compareTo((a['answerLen'] as int) - (a['secondLen'] as int)),
            )))
          hit,
      ]),
    );
    final boilerplates = questions
        .where(
          (q) =>
              ((q['explanation'] as String?) ?? '').contains('直接满足题干给出的条件和范围'),
        )
        .map(
          (q) => {
            'lesson': q['_lessonId'],
            'question': q['question'],
            'explanation': q['explanation'],
            'options': options(q),
            'answer': answerIndex(q),
          },
        )
        .toList();
    File('${reportDir.path}/p0_boilerplate_explanations.json')
        .writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(boilerplates),
        );
    stdout.writeln(
      '已写入 tool/reports/：元问题 ${meta.length}、'
      '模板句 ${templateSentences.length}、'
      '最长项 ${longestHits.length}、'
      '模板解析 ${boilerplates.length}',
    );
  }

  if (emitJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
    return;
  }

  stdout.writeln('题目总数            ${questions.length}');
  stdout.writeln(
    '元问题              ${meta.length}（涉及 ${metaByLesson.length} 课，'
    '其中 ${report['fullyMetaLessons']} 课 >=3 道）',
  );
  stdout.writeln(
    '模板句(>=5 次)      ${templateSentences.length} 种，'
    '命中 ${templatedQuestions.length} 题',
  );
  stdout.writeln(
    '单选答案下标占比    '
    '${report['answerIndexPercents']}',
  );
  stdout.writeln('解析 <120 字符      ${shortExplanations.length}');
  stdout.writeln('题干重复            ${duplicates.length}');
  stdout.writeln(
    '最长项命中(严格)    $strictlyLongest/${single.length} '
    '= ${(strictlyLongest * 100 / single.length).toStringAsFixed(1)}%',
  );
  stdout.writeln(
    '最长项命中(差距>=8) $stronglyLongest '
    '= ${(stronglyLongest * 100 / single.length).toStringAsFixed(1)}%',
  );
  stdout.writeln('并列最长            $tiedLongest');
  stdout.writeln('非最长              $notLongest');
  stdout.writeln('');
  stdout.writeln('--- 元问题最多的课程（前 $top） ---');
  for (final entry
      in (metaByLesson.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length)))
          .take(top)) {
    stdout.writeln('${entry.value.length.toString().padLeft(3)}  ${entry.key}');
  }
  stdout.writeln('');
  stdout.writeln('--- 高频模板句（前 $top） ---');
  for (final entry in templateSentences.take(top)) {
    stdout.writeln('${entry.value.toString().padLeft(4)} x ${entry.key}');
  }
}
