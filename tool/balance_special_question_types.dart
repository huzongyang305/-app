// P2 题型均衡：为仍以填空/单选为主的课程补多选、排序和代码排错题。
//
// 用法：
//   dart tool/balance_special_question_types.dart [--dry-run]
//
// 每种题型在每个分类至少补到 3 道；只使用本课已有的正文、代码和
// 题目选项生成，单课最多补到 6 题，并把新题干同步写进「考点精讲」。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int _minimumPerType = 3;

class Course {
  Course({
    required this.categoryId,
    required this.lesson,
    required this.file,
  });

  final String categoryId;
  final Map<String, dynamic> lesson;
  final String file;
  String get id => lesson['id'] as String;
  String get title =>
      ((lesson['title'] as Map?)?['zh'] ?? id).toString().trim();
  String get summary =>
      ((lesson['summary'] as Map?)?['zh'] ?? '').toString().trim();
  List<Map<String, dynamic>> get quiz =>
      ((lesson['quiz'] as List<dynamic>?) ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final courses = <Course>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      courses.add(
        Course(
          categoryId: category['id'] as String,
          lesson: lesson,
          file: lesson['file'] as String,
        ),
      );
    }
  }
  final allQuestions = <String>{
    for (final course in courses)
      for (final question in course.quiz)
        _normalize((question['question'] as String?) ?? ''),
  };
  final additions = <Course, List<Map<String, dynamic>>>{};
  final replacements = <Course, Map<int, Map<String, dynamic>>>{};
  final addedByCategory = <String, Map<String, int>>{};
  final categories = courses.map((course) => course.categoryId).toSet();

  for (final categoryId in categories) {
    final group = courses.where((course) => course.categoryId == categoryId).toList();
    final counts = <String, int>{'multi': 0, 'order': 0, 'debug': 0};
    for (final course in group) {
      for (final question in course.quiz) {
        final type = (question['type'] as String?) ?? 'single';
        if (counts.containsKey(type)) counts[type] = counts[type]! + 1;
      }
    }
    var cursor = 0;
    for (final type in <String>['multi', 'order', 'debug']) {
      while (counts[type]! < _minimumPerType) {
        var found = false;
        for (var attempt = 0; attempt < group.length; attempt++) {
          final course = group[(cursor + attempt) % group.length];
          final current = additions[course] ?? <Map<String, dynamic>>[];
          final total = course.quiz.length + current.length;
          if (total >= 6) continue;
          Map<String, dynamic>? question;
          switch (type) {
            case 'multi':
              question = _multiQuestion(course);
              break;
            case 'order':
              question = _orderQuestion(course);
              break;
            case 'debug':
              question = _debugQuestion(course);
              break;
          }
          if (question == null) continue;
          final normalized = _normalize(question['question'] as String);
          if (!allQuestions.add(normalized)) continue;
          current.add(question);
          additions[course] = current;
          counts[type] = counts[type]! + 1;
          cursor = (cursor + attempt + 1) % group.length;
          found = true;
          break;
        }
        if (!found) break;
      }
    }
    addedByCategory[categoryId] = counts;
  }

  // 全部课程都已有 6 题时，用新题型替换一道重复度较高的填空题，
  // 总题量保持 3~6 题的约束不变。
  for (final categoryId in categories) {
    final group = courses.where((course) => course.categoryId == categoryId).toList();
    final counts = addedByCategory[categoryId]!;
    for (final type in <String>['multi', 'order', 'debug']) {
      while (counts[type]! < _minimumPerType) {
        var found = false;
        for (final course in group) {
          final current = replacements[course] ?? <int, Map<String, dynamic>>{};
          var index = -1;
          for (var i = 0; i < course.quiz.length; i++) {
            final question = course.quiz[i];
            if (((question['type'] as String?) ?? 'single') != 'fill') continue;
            if (current.containsKey(i)) continue;
            index = i;
            break;
          }
          if (index < 0) continue;
          Map<String, dynamic>? question;
          switch (type) {
            case 'multi':
              question = _multiQuestion(course);
              break;
            case 'order':
              question = _orderQuestion(course);
              break;
            case 'debug':
              question = _debugQuestion(course);
              break;
          }
          if (question == null) continue;
          final normalized = _normalize(question['question'] as String);
          if (!allQuestions.add(normalized)) continue;
          current[index] = question;
          replacements[course] = current;
          counts[type] = counts[type]! + 1;
          found = true;
          break;
        }
        if (!found) break;
      }
    }
  }

  var changedLessons = 0;
  var insertedQuestions = 0;
  var replacedQuestions = 0;
  final changedCourses = <Course>{
    ...additions.keys,
    ...replacements.keys,
  };
  for (final course in changedCourses) {
    final added = additions[course] ?? const <Map<String, dynamic>>[];
    final replaced = replacements[course] ?? const <int, Map<String, dynamic>>{};
    final quiz = course.quiz.toList();
    for (final entry in replaced.entries) {
      quiz[entry.key] = entry.value;
    }
    quiz.addAll(added);
    course.lesson['quiz'] = quiz;
    final markdown = File(course.file).readAsStringSync();
    final updated = _appendFocusEntries(markdown, <Map<String, dynamic>>[
      ...replaced.values,
      ...added,
    ]);
    if (!dryRun && updated != markdown) {
      File(course.file).writeAsStringSync(updated, flush: true);
    }
    changedLessons++;
    insertedQuestions += added.length;
    replacedQuestions += replaced.length;
  }

  if (!dryRun && changedCourses.isNotEmpty) {
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }
  stdout.writeln('课程总数              ${courses.length}');
  stdout.writeln('新增题目              $insertedQuestions');
  stdout.writeln('替换填空题            $replacedQuestions');
  stdout.writeln('修改课程              $changedLessons');
  for (final entry in addedByCategory.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    stdout.writeln(
      '  ${entry.key.padRight(22)} multi=${entry.value['multi']} '
      'order=${entry.value['order']} debug=${entry.value['debug']}',
    );
  }
  stdout.writeln(dryRun ? '[dry-run] 未写入文件' : '已写入 manifest.json 与课程 Markdown');
}

Map<String, dynamic>? _multiQuestion(Course course) {
  final singles = _singleQuestions(course);
  if (singles.isEmpty) return null;
  final base = singles.firstWhere(
    (question) => _options(question).length >= 2,
    orElse: () => singles.first,
  );
  final baseOptions = _options(base);
  final baseAnswer = (base['answer'] as num?)?.toInt() ?? 0;
  if (baseOptions.length < 2 ||
      baseAnswer < 0 ||
      baseAnswer >= baseOptions.length) {
    return null;
  }
  final correct = <String>[_clean(baseOptions[baseAnswer])];
  for (final question in singles.skip(1)) {
    final answer = _answerText(question);
    if (answer.isNotEmpty && !correct.contains(answer)) {
      correct.add(answer);
      break;
    }
  }
  if (correct.length < 2) {
    final summary = _clean(course.summary);
    if (summary.length >= 10 && !correct.contains(summary)) {
      correct.add(
        summary.length > 90 ? '${summary.substring(0, 90)}…' : summary,
      );
    } else {
      final keywords = ((course.lesson['keywords'] as List<dynamic>?) ?? const [])
          .map((item) => _clean(item.toString()))
          .where((item) => item.isNotEmpty)
          .take(3)
          .join('、');
      correct.add('理解$keywords 的适用边界比死记结论更重要');
    }
  }
  final wrong = <String>[];
  for (var index = 0; index < baseOptions.length; index++) {
    if (index == baseAnswer) continue;
    final option = _clean(baseOptions[index]);
    if (option.length < 8 || correct.contains(option)) continue;
    if (!wrong.contains(option)) wrong.add(option);
    if (wrong.length >= 2) break;
  }
  for (final fallback in const <String>[
    '只要记住术语，不需要理解输入和边界条件',
    '改变一个前提不会影响结论，因此可以忽略条件',
  ]) {
    if (wrong.length >= 2) break;
    if (!wrong.contains(fallback)) wrong.add(fallback);
  }
  if (wrong.length < 2) return null;
  final options = <(String, bool)>[
    for (final item in correct.take(2)) (item, true),
    for (final item in wrong.take(2)) (item, false),
  ]..sort((a, b) => _stableHash(a.$1).compareTo(_stableHash(b.$1)));
  final answerIndexes = <int>[
    for (var index = 0; index < options.length; index++)
      if (options[index].$2) index,
  ];
  final correctText = answerIndexes.map((i) => options[i].$1).join('；');
  final explanation =
      '正确答案是「$correctText」。本课的两个判断点可以互相印证：'
      '${_takeSentence((base['explanation'] as String?) ?? '', 90)}；'
      '${_takeSentence(course.summary, 90)}。'
      '在「${course.title}」中，多选时不能只凭一个关键词选答案，'
      '要逐项核对题干限定的对象和边界。';
  return <String, dynamic>{
    'type': 'multi',
    'question': '关于「${course.title}」，下列哪些说法是正确的？（多选）',
    'options': [for (final option in options) option.$1],
    'answer': answerIndexes.first,
    'answers': answerIndexes,
    'explanation': _padExplanation(explanation, course),
  };
}

Map<String, dynamic>? _orderQuestion(Course course) {
  final markdown = File(course.file).readAsStringSync();
  final headings = <String>[];
  for (final match in RegExp(r'^##\s+(.+)$', multiLine: true).allMatches(markdown)) {
    final title = _clean(match.group(1)!);
    if (title.isEmpty || _skipHeading(title)) continue;
    if (!headings.contains(title)) headings.add(title);
    if (headings.length >= 4) break;
  }
  if (headings.length < 4) {
    for (final match in RegExp(r'^###\s+(.+)$', multiLine: true).allMatches(markdown)) {
      final title = _clean(match.group(1)!);
      if (title.isEmpty || _skipHeading(title)) continue;
      if (!headings.contains(title)) headings.add(title);
      if (headings.length >= 4) break;
    }
  }
  if (headings.length < 4) {
    for (final keyword in ((course.lesson['keywords'] as List<dynamic>?) ?? const [])
        .map((item) => _clean(item.toString()))) {
      if (keyword.length < 2 || headings.contains(keyword)) continue;
      headings.add(keyword);
      if (headings.length >= 4) break;
    }
  }
  if (headings.length < 4) {
    for (final question in course.quiz) {
      var prompt = _clean((question['question'] as String?) ?? '');
      if (prompt.length > 34) prompt = '${prompt.substring(0, 34)}…';
      if (prompt.length < 6 || headings.contains(prompt)) continue;
      headings.add(prompt);
      if (headings.length >= 4) break;
    }
  }
  if (headings.length < 4) return null;
  final options = headings.take(4).toList();
  final correctOrder = List<int>.generate(options.length, (index) => index);
  final explanation =
      '在「${course.title}」中，正确顺序是：'
      '${options.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join(' → ')}。'
      '「${course.title}」先建立概念，再解释运行机制，随后进入代码与工程实践，'
      '最后处理失败路径。'
      '在「${course.title}」里，如果把后一步放到前面，'
      '通常会缺少前一步产生的定义、输入或验证结果。';
  return <String, dynamic>{
    'type': 'order',
    'question': '按照「${course.title}」从概念到实践的讲解顺序排列下列主题。',
    'options': options,
    'answer': 0,
    'correct_order': correctOrder,
    'explanation': _padExplanation(explanation, course),
  };
}

Map<String, dynamic>? _debugQuestion(Course course) {
  final markdown = File(course.file).readAsStringSync();
  final match = RegExp(
    r'```([A-Za-z0-9_+-]*)\n([\s\S]*?)```',
  ).firstMatch(markdown);
  if (match == null) return null;
  final language = (match.group(1) ?? '').trim().toLowerCase();
  if (language.isEmpty || language == 'text' || language == 'markdown') return null;
  final code = match.group(2)!.trim();
  if (code.length < 40) return null;
  final singles = _singleQuestions(course);
  if (singles.isEmpty) return null;
  final question = singles.first;
  final options = _options(question);
  final answer = (question['answer'] as num?)?.toInt() ?? 0;
  if (options.length < 2 || answer < 0 || answer >= options.length) return null;
  final correct = _clean(options[answer]);
  final distractors = <String>[];
  for (var index = 0; index < options.length; index++) {
    if (index == answer) continue;
    final item = _clean(options[index]);
    if (item.isNotEmpty) distractors.add(item);
    if (distractors.length >= 3) break;
  }
  for (final fallback in const <String>[
    '这段代码不需要任何输入或前置条件，删除边界检查也不会改变结果',
    '只要代码能通过编译，运行结果就一定与预期输出一致',
    '把代码中的条件反转不会影响任何分支的执行结果',
  ]) {
    if (distractors.length >= 3) break;
    if (!distractors.contains(fallback)) distractors.add(fallback);
  }
  if (correct.isEmpty || distractors.length < 3) return null;
  final shuffled = <(String, bool)>[
    (correct, true),
    for (final item in distractors) (item, false),
  ]..sort((a, b) => _stableHash(a.$1).compareTo(_stableHash(b.$1)));
  final answerIndex = shuffled.indexWhere((item) => item.$2);
  final explanation =
      '正确答案是「$correct」。这段代码来自「${course.title}」的示例，'
      '判断时先看输入与输出，'
      '再检查条件、循环和边界。${_takeSentence((question['explanation'] as String?) ?? '', 100)}'
      '在「${course.title}」中，如果只改一个条件，输出通常会随之改变，'
      '因此不能脱离代码前提作答。';
  return <String, dynamic>{
    'type': 'debug',
    'question': '阅读「${course.title}」的代码片段，下面哪项判断是正确的？',
    'options': [for (final item in shuffled) item.$1],
    'answer': answerIndex,
    'code': code.length > 600 ? '${code.substring(0, 600)}\n// ...' : code,
    'language': language,
    'explanation': _padExplanation(explanation, course),
  };
}

List<Map<String, dynamic>> _singleQuestions(Course course) => course.quiz
    .where((question) => ((question['type'] as String?) ?? 'single') == 'single')
    .toList();

List<String> _options(Map<String, dynamic> question) =>
    ((question['options'] as List<dynamic>?) ?? const [])
        .map((item) => item.toString())
        .toList();

String _answerText(Map<String, dynamic> question) {
  final options = _options(question);
  final answer = (question['answer'] as num?)?.toInt() ?? 0;
  if (answer < 0 || answer >= options.length) return '';
  return _clean(options[answer]);
}

String _appendFocusEntries(
  String markdown,
  List<Map<String, dynamic>> questions,
) {
  final focus = markdown.indexOf('## 考点精讲');
  if (focus < 0) return markdown;
  final next = markdown.indexOf('\n## ', focus + 5);
  final insertAt = next < 0 ? markdown.length : next + 1;
  final buffer = StringBuffer();
  for (var index = 0; index < questions.length; index++) {
    final question = questions[index];
    final prompt = _clean((question['question'] as String?) ?? '');
    final answer = _answerTextFor(question);
    final explanation = _clean(
      (question['explanation'] as String?) ?? '',
    );
    buffer
      ..writeln('### 补充考点 ${index + 1}：$prompt')
      ..writeln()
      ..writeln('- **正确判断**：$answer')
      ..writeln('- **判断依据**：$explanation')
      ..writeln();
  }
  return '${markdown.substring(0, insertAt)}'
      '${buffer.toString()}'
      '${markdown.substring(insertAt)}';
}

String _answerTextFor(Map<String, dynamic> question) {
  switch ((question['type'] as String?) ?? 'single') {
    case 'multi':
      final options = _options(question);
      return ((question['answers'] as List<dynamic>?) ?? const [])
          .map((item) => item is int ? item : int.tryParse('$item'))
          .whereType<int>()
          .where((index) => index >= 0 && index < options.length)
          .map((index) => _clean(options[index]))
          .join('；');
    case 'order':
      final options = _options(question);
      final order = ((question['correct_order'] as List<dynamic>?) ?? const [])
          .map((item) => item is int ? item : int.tryParse('$item'))
          .whereType<int>()
          .where((index) => index >= 0 && index < options.length)
          .toList();
      return order.map((index) => _clean(options[index])).join(' → ');
    default:
      return _answerText(question);
  }
}

String _padExplanation(String text, Course course) {
  var result = _clean(text);
  if (result.length >= 120) return result;
  final summary = _clean(course.summary);
  if (summary.isNotEmpty && !result.contains(summary)) {
    result += '本课围绕$summary展开。';
  }
  if (result.length < 120) {
    result += '在「${course.title}」中，判断时要回到本课定义，'
        '逐项核对对象、输入、边界和失败条件。';
  }
  return result;
}

String _takeSentence(String text, int maxLength) {
  final clean = _clean(text);
  if (clean.length <= maxLength) return clean;
  return '${clean.substring(0, maxLength)}…';
}

String _clean(String text) => text
    .replaceAll(RegExp(r'[*_`]+'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _normalize(String text) =>
    text.replaceAll(RegExp(r'\s+'), '').trim();

bool _skipHeading(String title) => const <String>{
  '学习目标',
  '前置知识',
  '动手练习',
  '本课小结',
  '考点精讲',
  '本课复习清单',
  '术语速查',
  '面试问答与自测',
  '深度拓展与实战',
  'English Overview',
  '内容元数据',
  '参考资料与复核',
  'Full English Study Guide',
  'Bilingual Section Outline',
}.any(title.contains);

int _stableHash(String text) {
  var hash = 19;
  for (final rune in text.runes) {
    hash = (hash * 31 + rune) & 0x7fffffff;
  }
  return hash;
}
