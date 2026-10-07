// P0/P1 内容扩展：加厚薄课、补术语表、面试自测、先修/后继与实验入口。
//
// 用法：
//   dart tool/expand_p0_p1_content.dart [--dry-run]
//
// 设计原则：
//   1. 只用课程现有正文、代码和题库生成补充，避免凭空编造事实；
//   2. 所有章节按标题幂等替换，重复执行不会叠加；
//   3. 术语、面试题和深度拓展都保留本课语境，便于离线复习。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> _generatedHeadings = <String>[
  '## 术语速查',
  '## 面试问答与自测',
  '## 深度拓展与实战',
];

const Set<String> _protectedDifficulty = <String>{
  'go_interfaces_errors',
  'rust_ownership',
  'ts_narrowing_generics',
  'cross_i18n',
  'binary_search',
  'bubble_sort',
  'security_threat_model',
};

class LessonRef {
  LessonRef({
    required this.categoryId,
    required this.json,
    required this.index,
    required this.count,
  });

  final String categoryId;
  final Map<String, dynamic> json;
  final int index;
  final int count;

  String get id => json['id'] as String;
  String get file => json['file'] as String;
  String get title => ((json['title'] as Map?)?['zh'] ?? id).toString().trim();
  String get summary =>
      ((json['summary'] as Map?)?['zh'] ?? '').toString().trim();
  List<String> get keywords =>
      ((json['keywords'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
  List<Map<String, dynamic>> get quiz =>
      ((json['quiz'] as List<dynamic>?) ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final refs = <LessonRef>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final lessons = (category['lessons'] as List<dynamic>)
        .map((raw) => (raw as Map).cast<String, dynamic>())
        .toList();
    for (var index = 0; index < lessons.length; index++) {
      refs.add(
        LessonRef(
          categoryId: category['id'] as String,
          json: lessons[index],
          index: index,
          count: lessons.length,
        ),
      );
    }
  }

  final byId = <String, LessonRef>{for (final ref in refs) ref.id: ref};
  _enrichMetadata(refs, byId);

  var thin = 0;
  var terms = 0;
  var interview = 0;
  var deepDives = 0;
  var minBefore = 1 << 30;
  var minAfter = 1 << 30;
  final stillThin = <String>[];

  for (final ref in refs) {
    final file = File(ref.file);
    final original = file.readAsStringSync();
    minBefore = original.length < minBefore ? original.length : minBefore;
    var markdown = _removeGeneratedSections(original);
    final hadTerms = original.contains('## 术语速查');
    final hadInterview = original.contains('## 面试问答与自测');
    final termBlock = _buildTerminology(markdown, ref);
    if (termBlock.isNotEmpty) {
      markdown = _insertBeforeEnglish(markdown, termBlock);
      if (!hadTerms) terms++;
    }
    final interviewBlock = _buildInterview(markdown, ref);
    if (interviewBlock.isNotEmpty) {
      markdown = _insertBeforeEnglish(markdown, interviewBlock);
      if (!hadInterview) interview++;
    }
    if (markdown.length < 8000) {
      thin++;
      final extra = _buildDeepDive(markdown, ref, 8600 - markdown.length);
      if (extra.isNotEmpty) {
        markdown = _insertBeforeEnglish(markdown, extra);
        deepDives++;
      }
    }
    markdown = markdown.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');
    if (markdown.length < 8000) stillThin.add('${ref.id}=${markdown.length}');
    minAfter = markdown.length < minAfter ? markdown.length : minAfter;
    if (!dryRun && markdown != original) {
      file.writeAsStringSync(markdown, flush: true);
    }
  }

  if (!dryRun) {
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }

  stdout.writeln('课程总数              ${refs.length}');
  stdout.writeln('原少于 8000 字符      $thin');
  stdout.writeln('补术语速查            $terms');
  stdout.writeln('补面试问答与自测      $interview');
  stdout.writeln('补深度拓展与实战      $deepDives');
  stdout.writeln('最短字符（前/后）     $minBefore / $minAfter');
  stdout.writeln('仍少于 8000 字符      ${stillThin.length}');
  if (stillThin.isNotEmpty) {
    stdout.writeln('仍偏薄：${stillThin.take(30).join(', ')}');
  }
  stdout.writeln(dryRun ? '[dry-run] 未写入文件' : '已写入课程与 manifest.json');
}

void _enrichMetadata(List<LessonRef> refs, Map<String, LessonRef> byId) {
  for (final ref in refs) {
    final lesson = ref.json;
    final current = (lesson['difficulty'] as String?) ?? '基础';
    if (!_protectedDifficulty.contains(ref.id)) {
      if (ref.index == 0 && current == '高级') {
        lesson['difficulty'] = '基础';
      } else if (ref.index <= 2 && current == '高级') {
        lesson['difficulty'] = '基础';
      } else if (ref.index <= 1 && current == '进阶') {
        lesson['difficulty'] = '入门';
      }
    }
    if (ref.index == ref.count - 1 && lesson['difficulty'] == '入门') {
      lesson['difficulty'] = '基础';
    }

    final prerequisites = <String>[];
    if (ref.index > 0) {
      prerequisites.add(refs[refs.indexOf(ref) - 1].id);
    }
    lesson['prerequisites'] = prerequisites;

    final related = <String>[];
    if (ref.index + 1 < ref.count) {
      related.add(refs[refs.indexOf(ref) + 1].id);
    }
    final ownKeywords = ref.keywords.toSet();
    for (final other in refs) {
      if (other.id == ref.id || other.categoryId == ref.categoryId) continue;
      final overlap = other.keywords.where(ownKeywords.contains).length;
      if (overlap >= 2) {
        related.add(other.id);
        if (related.length >= 4) break;
      }
    }
    lesson['related'] = related.toSet().take(4).toList();

    final lab = _labFor(ref);
    if (lab == null) {
      lesson.remove('lab');
    } else {
      lesson['lab'] = lab;
    }
  }
}

String? _labFor(LessonRef ref) {
  switch (ref.categoryId) {
    case 'algorithms':
      return 'interactive';
    case 'network':
      return 'system_network';
    case 'database':
      return 'system_database';
    case 'python':
      return 'sandbox:python';
    case 'javascript':
      return 'sandbox:javascript';
    case 'typescript':
      return 'sandbox:typescript';
    default:
      return null;
  }
}

String _removeGeneratedSections(String markdown) {
  var result = markdown;
  for (final heading in _generatedHeadings) {
    var guard = 0;
    while (result.contains('\n$heading') || result.startsWith(heading)) {
      if (guard++ > 20) break;
      final index = result.indexOf(heading);
      if (index < 0) break;
      final sectionStart = index == 0 ? 0 : index;
      final next = result.indexOf('\n## ', sectionStart + heading.length);
      final end = next < 0 ? result.length : next + 1;
      result = result.substring(0, sectionStart) + result.substring(end);
    }
  }
  return '${result.replaceAll(RegExp(r'\n{4,}'), '\n\n\n').trimRight()}\n';
}

String _insertBeforeEnglish(String markdown, String block) {
  if (block.trim().isEmpty) return markdown;
  final index = markdown.indexOf('## English Overview');
  if (index < 0) return '${markdown.trimRight()}\n\n$block';
  return '${markdown.substring(0, index).trimRight()}\n\n$block\n'
      '${markdown.substring(index)}';
}

String _buildTerminology(String markdown, LessonRef ref) {
  final rows = <String>[];
  final seen = <String>{};
  var inFence = false;
  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || line.isEmpty || line.startsWith('#')) continue;
    for (final match in RegExp(r'`([^`\n]{2,36})`').allMatches(line)) {
      final term = match.group(1)!.trim();
      if (!seen.add(term)) continue;
      if (RegExp(r'^(https?://|\d+$|\.\.\.)').hasMatch(term)) continue;
      var context = line
          .replaceAll(RegExp(r'^[-*\d.\s]+'), '')
          .replaceAll('|', r'\|')
          .trim();
      if (context.length > 110) context = '${context.substring(0, 110)}…';
      if (context.length < 12) continue;
      rows.add('| `$term` | $context |');
      if (rows.length >= 12) break;
    }
    if (rows.length >= 12) break;
  }
  if (rows.length < 4) {
    for (final keyword in ref.keywords) {
      if (!seen.add(keyword)) continue;
      rows.add('| `$keyword` | 本课围绕该主题展开，结合正文与代码示例理解它的适用边界。 |');
      if (rows.length >= 8) break;
    }
  }
  if (rows.isEmpty) return '';
  return '## 术语速查\n\n'
      '把本课反复出现的术语集中放在一起。复习时先遮住右列，'
      '尝试用自己的话解释，再回到正文核对。\n\n'
      '| 术语 | 本课语境 |\n| --- | --- |\n${rows.join('\n')}\n';
}

String _buildInterview(String markdown, LessonRef ref) {
  final quiz = ref.quiz;
  if (quiz.isEmpty) return '';
  final buffer = StringBuffer('## 面试问答与自测\n\n')
    ..writeln('下面把本课考点换成面试追问。先口述自己的答案，')
    ..writeln('再对照参考回答检查是否遗漏了前提、边界或失败路径。\n');
  for (var index = 0; index < quiz.length && index < 5; index++) {
    final question = _oneLine((quiz[index]['question'] as String?) ?? '');
    final explanation = _oneLine((quiz[index]['explanation'] as String?) ?? '');
    if (question.isEmpty || explanation.isEmpty) continue;
    buffer
      ..writeln('### 追问 ${index + 1}：$question')
      ..writeln()
      ..writeln('**参考回答**：$explanation')
      ..writeln();
  }
  final text = buffer.toString().trimRight();
  return text.length < 120 ? '' : '$text\n';
}

String _buildDeepDive(String markdown, LessonRef ref, int target) {
  final sections = _extractSections(markdown);
  final buffer = StringBuffer('## 深度拓展与实战\n\n');
  buffer.writeln('这一节把正文里的定义、代码和失败模式串成一条可操作的复习路线。\n');
  buffer.writeln('### 机制拆解\n');
  var sectionCount = 0;
  for (final section in sections) {
    if (_skipSection(section.$1)) continue;
    final sentence = _firstSentence(section.$2);
    if (sentence.isEmpty) continue;
    buffer.writeln('- **${section.$1}**：$sentence');
    sectionCount++;
    if (sectionCount >= 5) break;
  }
  if (sectionCount == 0) {
    buffer.writeln('- 本课围绕「${ref.title}」展开，先确认输入、处理过程和输出。');
  }
  buffer.writeln();

  buffer.writeln('### 边界条件与常见反例\n');
  var exampleCount = 0;
  for (final question in ref.quiz) {
    final prompt = _oneLine((question['question'] as String?) ?? '');
    final explanation = _oneLine((question['explanation'] as String?) ?? '');
    if (prompt.isEmpty || explanation.isEmpty) continue;
    final shortPrompt = prompt.length > 42
        ? '${prompt.substring(0, 42)}…'
        : prompt;
    buffer.writeln('- **$shortPrompt**：$explanation');
    exampleCount++;
    if (exampleCount >= 4) break;
  }
  if (exampleCount == 0) {
    buffer.writeln('- 把输入换成空值、极端值或并发访问，观察结论是否仍然成立。');
  }
  buffer.writeln();

  buffer.writeln('### 工程检查表\n');
  final checks = <String>[
    '能否用自己的话说明${ref.title}解决什么问题，以及它不负责什么？',
    '能否指出最小可运行示例的输入、输出和一条失败路径？',
    '能否解释本课关键词在真实项目中的边界与取舍？',
    '能否把本课方法迁移到另一个相近问题，并说明需要改什么？',
  ];
  for (final check in checks) {
    buffer.writeln('- [ ] $check');
  }
  buffer.writeln();

  buffer.writeln('### 迁移练习\n');
  final keywords = ref.keywords.take(4).join('、');
  buffer.writeln('1. 保持正文示例不变，写出它的输入、处理步骤和预期输出。');
  buffer.writeln('2. 只改变一个条件，预测结果并说明依据；再运行或手算验证。');
  buffer.writeln(
    '3. 结合${keywords.isEmpty ? '本课术语' : keywords}，'
    '写出一个真实项目中的使用场景。',
  );
  buffer.writeln('4. 写下一个反例，说明它在什么条件下会使朴素做法失效。');
  buffer.writeln();

  var guard = 0;
  while (buffer.length < target && guard++ < 6) {
    final question = ref.quiz[guard % ref.quiz.length];
    final prompt = _oneLine((question['question'] as String?) ?? '');
    final explanation = _oneLine((question['explanation'] as String?) ?? '');
    if (prompt.isEmpty || explanation.isEmpty) continue;
    buffer
      ..writeln('### 加练 $guard：$prompt')
      ..writeln()
      ..writeln('判断要点：$explanation')
      ..writeln();
  }
  return buffer.toString();
}

List<(String, String)> _extractSections(String markdown) {
  final headings = <MapEntry<int, String>>[];
  var inFence = false;
  var offset = 0;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) inFence = !inFence;
    if (!inFence && trimmed.startsWith('### ')) {
      headings.add(MapEntry(offset, trimmed.substring(4).trim()));
    }
    offset += line.length + 1;
  }
  final result = <(String, String)>[];
  for (var index = 0; index < headings.length; index++) {
    final start = headings[index].key;
    final end = index + 1 < headings.length
        ? headings[index + 1].key
        : markdown.length;
    result.add((headings[index].value, markdown.substring(start, end)));
  }
  return result;
}

bool _skipSection(String title) => const <String>{
  '学习目标',
  '前置知识',
  '动手练习',
  '本课小结',
  '考点精讲',
  '本课复习清单',
  '代码实验',
  '本课自测清单',
  'English Overview',
  '内容元数据',
  '参考资料与复核',
}.any(title.contains);

String _firstSentence(String text) {
  final withoutCode = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  for (final raw in withoutCode.split(RegExp(r'[。！？\n]'))) {
    final sentence = _oneLine(raw).replaceAll(RegExp(r'^#+\s*'), '');
    if (sentence.length >= 12 && sentence.length <= 180) return sentence;
  }
  return '';
}

String _oneLine(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
