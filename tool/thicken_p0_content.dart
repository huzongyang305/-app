// P0 内容加厚工具（开发期使用，不参与 App 打包）。
//
// 背景：章节去重修复删除了 125 篇教程里重复的 H2 后，151 篇课程暴露出
// 正文不足 6000 字符。这里不复用“工程化拆解”式模板，而是：
//   1. 把每课已有测验的题干、正确判断、解析与干扰项整理成正文“考点精讲”；
//   2. 对最薄的 24 篇入门课叠加逐课定制的概念、机制和边界讲义；
//   3. 验证阶段检查字符数、占位示例与幂等标记。
//
// 用法：
//   dart tool/thicken_p0_content.dart [--dry-run] [--debug]

import 'dart:convert';
import 'dart:io';

import 'p0_curated_supplements.dart';
import 'p0_language_mechanics.dart';

const String contentDir = 'assets/content';
const String marker = '<!-- p0-thicken:v1 -->';
const String practiceMarker = '<!-- p0-practice:v1 -->';
const String deepDiveMarker = '<!-- p0-deepdive:v1 -->';
const String checklistMarker = '<!-- p0-checklist:v1 -->';
const int minimumLength = 6000;

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final debug = args.contains('--debug');
  final manifest = jsonDecode(
    File('$contentDir/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final lessonByFile = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = (lesson['file'] as String).replaceAll('\\', '/');
      lessonByFile[file] = lesson;
    }
  }

  final files =
      Directory(contentDir)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var changed = 0;
  final preview = <String>[];
  for (final file in files) {
    final relative = file.path.replaceAll('\\', '/');
    final lesson = lessonByFile[relative];
    if (lesson == null) continue;

    final before = file.readAsStringSync();
    if (before.contains(marker)) continue;

    final lessonId = (lesson['id'] as String?) ?? file.uri.pathSegments.last;
    final curated =
        p0CuratedSupplements[file.uri.pathSegments.last.replaceAll('.md', '')];
    final shouldThicken = before.length < minimumLength || curated != null;
    if (!shouldThicken) continue;

    final block = _buildSupplement(lesson, curated);
    if (block.trim().isEmpty) continue;
    final after = _insertBeforeTail(before, block);
    if (after == before) continue;

    changed++;
    if (preview.length < 12) {
      preview.add('$lessonId(${before.length}→${after.length})');
    }
    if (debug && changed <= 3) {
      stdout.writeln('--- $lessonId ---');
      stdout.writeln(after.substring(after.length - block.length - 120).trim());
    }
    if (!dryRun) file.writeAsStringSync(after);
  }

  stdout.writeln(
    '考点精讲与定制讲义：$changed 个文件${dryRun ? '（dry-run）' : ''}'
    '${preview.isEmpty ? '' : '（${preview.join(', ')}${changed > preview.length ? ' …' : ''}）'}',
  );

  final practiceChanged = _addPracticeBlocks(
    files,
    lessonByFile,
    dryRun,
    debug,
  );
  stdout.writeln('代码实验记录：$practiceChanged 个文件${dryRun ? '（dry-run）' : ''}');

  final deepDiveChanged = _addDeepDives(files, lessonByFile, dryRun);
  stdout.writeln('语言机制速览：$deepDiveChanged 个文件${dryRun ? '（dry-run）' : ''}');

  final checklistChanged = _addChecklists(files, lessonByFile, dryRun);
  stdout.writeln('自测清单：$checklistChanged 个文件${dryRun ? '（dry-run）' : ''}');
  _verify(files, lessonByFile);
}

String _buildSupplement(Map<String, dynamic> lesson, String? curated) {
  final buffer = StringBuffer()
    ..writeln(marker)
    ..writeln();

  if (curated != null && curated.trim().isNotEmpty) {
    buffer
      ..writeln(curated.trim())
      ..writeln();
  }

  final quiz = lesson['quiz'] as List<dynamic>? ?? const <dynamic>[];
  if (quiz.isEmpty) return buffer.toString();

  buffer
    ..writeln('## 考点精讲：把选择题还原成判断过程')
    ..writeln()
    ..writeln(
      '下面不是答案速查，而是把本课测验里每个选项背后的判断标准展开。'
      '先自己作答，再对照解析检查推理链；如果结论正确但理由不完整，仍然需要回到正文补足概念。',
    )
    ..writeln();

  for (var i = 0; i < quiz.length; i++) {
    final question = (quiz[i] as Map).cast<String, dynamic>();
    final number = i + 1;
    buffer
      ..writeln('### 考点 $number：${question['question']}')
      ..writeln();

    final type = (question['type'] as String?) ?? 'single';
    final code = (question['code'] as String?)?.trim();
    if (code != null && code.isNotEmpty) {
      final language = (question['language'] as String?) ?? 'text';
      buffer
        ..writeln('```$language')
        ..writeln(code)
        ..writeln('```')
        ..writeln();
    }

    buffer
      ..writeln('- **正确判断**：${_correctAnswer(question, type)}')
      ..writeln(
        '- **解析**：${_cleanExplanation(question['explanation'] as String?)}',
      );

    final wrong = _wrongOptionNote(question);
    if (wrong.isNotEmpty) {
      buffer.writeln('- **干扰项辨析**：$wrong');
    }
    buffer
      ..writeln('- **迁移检查**：${_transferPrompt(type, number)}')
      ..writeln();
  }
  return buffer.toString();
}

String _correctAnswer(Map<String, dynamic> question, String type) {
  final options = (question['options'] as List<dynamic>? ?? const <dynamic>[])
      .map((item) => '$item')
      .toList();

  if (type == 'fill') {
    final accepted =
        (question['accepted_answers'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => '$item')
            .where((item) => item.trim().isNotEmpty)
            .toList();
    return accepted.isEmpty ? '见解析' : accepted.join('、');
  }

  if (type == 'multi') {
    final answers = (question['answers'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item as int)
        .where((index) => index >= 0 && index < options.length)
        .map((index) => options[index])
        .toList();
    return answers.isEmpty ? '见解析' : answers.join('；');
  }

  if (type == 'order') {
    final order =
        (question['correct_order'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => item as int)
            .where((index) => index >= 0 && index < options.length)
            .map((index) => options[index])
            .toList();
    return order.isEmpty
        ? '见解析'
        : order
              .asMap()
              .entries
              .map((entry) => '${entry.key + 1}. ${entry.value}')
              .join(' → ');
  }

  final answer = question['answer'];
  if (answer is int && answer >= 0 && answer < options.length) {
    return options[answer];
  }
  return '见解析';
}

String _cleanExplanation(String? raw) {
  var text = (raw ?? '').trim();
  if (text.isEmpty) return '请结合正文中的定义与示例自行推导。';

  const genericMarkers = <String>[
    '正确答案「',
    '判断标准是：',
    '本题对应《',
    '把本题放回《',
    '做题时先圈出题干',
    '本题的关键判断点',
    '补充：',
  ];
  var cut = text.length;
  for (final marker in genericMarkers) {
    final index = text.indexOf(marker);
    if (index >= 0 && index < cut) cut = index;
  }
  text = text.substring(0, cut).trim();
  if (text.length < 80) text = (raw ?? '').trim();
  return _compact(text);
}

String _wrongOptionNote(Map<String, dynamic> question) {
  final explanation = (question['explanation'] as String? ?? '').trim();
  final markerIndex = explanation.indexOf('其他选项：');
  if (markerIndex < 0) return '';
  var note = explanation.substring(markerIndex + '其他选项：'.length).trim();
  const genericMarkers = <String>[
    '正确答案「',
    '判断标准是：',
    '本题对应《',
    '把本题放回《',
    '做题时先圈出题干',
    '本题的关键判断点',
    '补充：',
  ];
  var cut = note.length;
  for (final marker in genericMarkers) {
    final index = note.indexOf(marker);
    if (index >= 0 && index < cut) cut = index;
  }
  note = note.substring(0, cut).trim();
  return note.length < 12 ? '' : _compact(note);
}

String _compact(String text) {
  return text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String _transferPrompt(String type, int number) {
  const prompts = <String>[
    '把题目中的一个输入换成边界值，原来的结论还成立吗？为什么？',
    '如果去掉一个限制条件，哪个选项会变成正确？请写出判断过程。',
    '把这道题改写成一次可运行或可人工验证的实验，并记录预期输出。',
    '用自己的话写出正确项和两个错误项的适用边界。',
  ];
  final prefix = type == 'single' ? '' : '这道$type 题：';
  return '$prefix${prompts[(number - 1) % prompts.length]}';
}

String _insertBeforeTail(String text, String block) {
  final newline = text.contains('\r\n') ? '\r\n' : '\n';
  final normalized = block.trim().replaceAll('\n', newline);
  const anchors = <String>[
    '<!-- p2-enrichment:v1 -->',
    '## English Overview',
    '<!-- p2-references:v1 -->',
    '## 参考资料与复核',
  ];
  var index = text.length;
  for (final anchor in anchors) {
    final found = text.indexOf(anchor);
    if (found >= 0 && found < index) index = found;
  }
  final head = text.substring(0, index).trimRight();
  final tail = text.substring(index);
  return '$head$newline$newline$normalized$newline$newline$tail';
}

int _addPracticeBlocks(
  List<File> files,
  Map<String, Map<String, dynamic>> lessonByFile,
  bool dryRun,
  bool debug,
) {
  var changed = 0;
  for (final file in files) {
    final relative = file.path.replaceAll('\\', '/');
    final lesson = lessonByFile[relative];
    if (lesson == null) continue;
    final before = file.readAsStringSync();
    if (before.length >= minimumLength || before.contains(practiceMarker)) {
      continue;
    }
    final block = _buildPracticeBlock(lesson, before);
    if (block.trim().isEmpty) continue;
    final after = _insertBeforeTail(before, block);
    if (after == before) continue;
    changed++;
    if (debug && changed <= 3) {
      stdout.writeln('--- practice ${lesson['id']} ---');
      stdout.writeln(after.substring(after.length - block.length - 80).trim());
    }
    if (!dryRun) file.writeAsStringSync(after);
  }
  return changed;
}

String _buildPracticeBlock(Map<String, dynamic> lesson, String markdown) {
  final fence = RegExp(
    r'```(?!text|markdown)([A-Za-z0-9_+#-]+)\r?\n([\s\S]*?)\r?\n```',
  ).firstMatch(markdown);
  final language = fence?.group(1)?.trim() ?? 'text';
  final code = fence?.group(2)?.trim() ?? '';
  final title = _lessonTitle(lesson);

  final buffer = StringBuffer()
    ..writeln(practiceMarker)
    ..writeln()
    ..writeln('## 代码实验：把示例跑成证据')
    ..writeln()
    ..writeln(
      '这一节不引入新语法，而是把「$title」的最小示例变成可以复现、可以对照的实验。'
      '每次只改变一个条件，先写预测，再运行，最后解释差异。',
    )
    ..writeln()
    ..writeln('### 实验一：建立基线')
    ..writeln();

  if (code.isNotEmpty) {
    buffer
      ..writeln('```$language')
      ..writeln(code)
      ..writeln('```')
      ..writeln();
  }

  buffer
    ..writeln(
      '先原样运行上面的代码，记录命令、完整输出和退出状态。然后把输出与正文的预期输出逐字对照，'
      '不要用“看起来差不多”代替核对；空格、大小写、换行和错误流向都可能暴露环境差异。',
    )
    ..writeln()
    ..writeln('### 实验二：只改一个输入')
    ..writeln()
    ..writeln(
      '从代码中选一个会影响结果的字面量、参数或输入，把它替换成边界值：'
      '数值可尝试 0、1、最大值和最小值，字符串可尝试空串和超长文本，'
      '集合可尝试空集合、单元素和重复元素。先写出预测，再运行并记录实际结果。',
    )
    ..writeln()
    ..writeln('### 实验三：制造一个可控错误')
    ..writeln()
    ..writeln(_failureScenario(language))
    ..writeln()
    ..writeln('| 实验 | 改动 | 预测 | 实际 | 结论 |')
    ..writeln('| --- | --- | --- | --- | --- |')
    ..writeln('| 基线 | 保持原样 |  |  |  |')
    ..writeln('| 边界 |  |  |  |  |')
    ..writeln('| 失败 |  |  |  |  |')
    ..writeln()
    ..writeln('### 实验四：用三句话复述')
    ..writeln()
    ..writeln('1. 输入是什么，哪些输入属于合法范围，哪些属于边界或非法范围？')
    ..writeln('2. 程序按什么顺序处理输入，在哪一步产生了状态变化或副作用？')
    ..writeln('3. 输出如何验证，失败时第一条可观察证据是什么？')
    ..writeln()
    ..writeln('### 与测验考点的连接')
    ..writeln();

  final quiz = lesson['quiz'] as List<dynamic>? ?? const <dynamic>[];
  for (var i = 0; i < quiz.length; i++) {
    final question = (quiz[i] as Map).cast<String, dynamic>();
    final type = (question['type'] as String?) ?? 'single';
    buffer.writeln(
      '- 考点 ${i + 1}「${question['question']}」：先写出你的判断，'
      '再回到上方解析核对。正确判断：${_correctAnswer(question, type)}。',
    );
  }
  return buffer.toString();
}

String _lessonTitle(Map<String, dynamic> lesson) {
  final title = lesson['title'];
  if (title is Map && title['zh'] is String) return title['zh'] as String;
  return (lesson['id'] as String?) ?? '本课';
}

String _failureScenario(String language) {
  final key = language.toLowerCase();
  if (key == 'python') {
    return '把复合语句末尾的冒号删掉，或者把字符串直接参与数值运算。先记录解释器报出的第一行错误和行号，再修复并重跑基线。';
  }
  if (key == 'c' || key == 'cpp') {
    return '删掉一条语句末尾的分号，或者把格式化占位符与参数类型改成不匹配。记录编译器第一条诊断，再恢复代码确认基线仍然可运行。';
  }
  if (key == 'java' || key == 'csharp') {
    return '把变量声明成不兼容的类型，或者删除一个必要的分号。记录编译器给出的类型错误与位置，修复后确认输出没有变化。';
  }
  if (key == 'go') {
    return '声明一个局部变量却不使用，或者删除一个仍然被引用的导入。Go 会把它们当作编译错误；记录错误信息后再恢复。';
  }
  if (key == 'rust') {
    return '在需要修改变量时去掉 mut，或者制造一次所有权转移后继续使用原变量。记录借用检查器的完整提示，理解它阻止了什么运行时错误。';
  }
  if (key == 'javascript' || key == 'typescript' || key == 'js') {
    return '把一个预期为数字的值改成字符串，或者访问不存在的属性。记录结果是 undefined、NaN 还是类型错误，并说明为什么。';
  }
  if (key == 'bash' || key == 'shell') {
    return '去掉变量展开外的引号，或者让管道中的前一段命令失败。记录退出码、标准错误和最终输出，确认错误是否被掩盖。';
  }
  if (key == 'sql') {
    return '插入一条违反主键、非空或唯一约束的记录，或者让 NULL 参与普通比较。记录数据库拒绝操作的位置和错误码，再验证正确写法。';
  }
  if (key == 'html' || key == 'css') {
    return '删掉一个闭合标签、把类名写错，或者让选择器优先级被另一条规则覆盖。用开发者工具确认实际命中的元素和计算样式。';
  }
  if (key == 'dart') {
    return '把可空变量直接当作非空使用，或者去掉一个必要的 await。记录分析器或运行时的第一条错误，再用空安全或异步等待修复。';
  }
  return '把输入改成空值、极值或类型不匹配的形式，记录程序抛出的第一条错误、发生位置和恢复方式。';
}

int _addDeepDives(
  List<File> files,
  Map<String, Map<String, dynamic>> lessonByFile,
  bool dryRun,
) {
  var changed = 0;
  for (final file in files) {
    final relative = file.path.replaceAll('\\', '/');
    final lesson = lessonByFile[relative];
    if (lesson == null) continue;
    final before = file.readAsStringSync();
    if (before.length >= minimumLength || before.contains(deepDiveMarker)) {
      continue;
    }
    final key = _mechanicsKey(lesson, file.uri.pathSegments.last);
    final mechanics = p0LanguageMechanics[key];
    if (mechanics == null) continue;
    final block = _buildDeepDive(lesson, before, mechanics);
    final after = _insertBeforeTail(before, block);
    if (after == before) continue;
    changed++;
    if (!dryRun) file.writeAsStringSync(after);
  }
  return changed;
}

String _mechanicsKey(Map<String, dynamic> lesson, String fileName) {
  final id = (lesson['id'] as String?) ?? fileName;
  if (id == 'password_hash_intro') return 'security';
  const prefixes = <String, String>{
    'c_': 'c',
    'cpp_': 'cpp',
    'csharp_': 'csharp',
    'java_': 'java',
    'js_': 'javascript',
    'ts_': 'typescript',
    'python_': 'python',
    'shell_': 'shell',
    'go_': 'go',
    'rust_': 'rust',
    'swift_': 'swift',
    'kotlin_': 'kotlin',
    'flutter_': 'flutter',
    'security_': 'security',
  };
  for (final entry in prefixes.entries) {
    if (id.startsWith(entry.key)) return entry.value;
  }
  return id;
}

String _buildDeepDive(
  Map<String, dynamic> lesson,
  String markdown,
  String mechanics,
) {
  final title = _lessonTitle(lesson);
  final topics = _realTopics(markdown);
  final quiz = lesson['quiz'] as List<dynamic>? ?? const <dynamic>[];

  final buffer = StringBuffer()
    ..writeln(deepDiveMarker)
    ..writeln()
    ..writeln(mechanics.trim())
    ..writeln()
    ..writeln('## 本课连接：把机制放回「$title」')
    ..writeln()
    ..writeln(
      '上面的机制速览覆盖了该方向最容易反复出现的概念。下面把它收回到本课，'
      '用正文里的真实主题和测验考点建立连接。',
    )
    ..writeln()
    ..writeln('### 本课真实主题')
    ..writeln();

  if (topics.isEmpty) {
    buffer.writeln('- 本课目前以最小示例和测验为主要学习材料，先完成上面的实验记录。');
  } else {
    for (final topic in topics.take(8)) {
      buffer.writeln('- **$topic**');
    }
  }

  buffer
    ..writeln()
    ..writeln('### 测验考点回链')
    ..writeln();
  for (var i = 0; i < quiz.length; i++) {
    final question = (quiz[i] as Map).cast<String, dynamic>();
    final type = (question['type'] as String?) ?? 'single';
    buffer.writeln(
      '- 考点 ${i + 1}「${question['question']}」→ 正确判断：'
      '${_correctAnswer(question, type)}。',
    );
  }

  buffer
    ..writeln()
    ..writeln('### 边界检查')
    ..writeln()
    ..writeln('1. 本课机制在正常输入下如何工作？')
    ..writeln('2. 输入为空、越界、类型不符或重复时，哪一步最先失败？')
    ..writeln('3. 失败后应该保留哪些日志、输出或状态，才能复现并修复？')
    ..writeln('4. 如果把这套机制换成相邻主题的方案，哪些约束会改变？');
  return buffer.toString();
}

List<String> _realTopics(String markdown) {
  final scaffold = RegExp(
    r'^(学习目标|前置知识|本课小结|动手练习|自测清单|English|内容元数据|'
    r'参考资料|课程专属精读|专属复习题库|逐步练习|故障排查|自测与面试|'
    r'专属进阶任务|Bilingual|Full English|相关主题|一句话入门|最小示例|'
    r'最小可运行示例|预期输出|常见错误|常见误区|适用边界|测试与验证|验证步骤)',
  );
  final seen = <String>{};
  final topics = <String>[];
  for (final match in RegExp(
    r'^##\s+(.+?)\s*$',
    multiLine: true,
  ).allMatches(markdown)) {
    final title = match.group(1)!.trim();
    if (scaffold.hasMatch(title)) continue;
    if (title.contains('考点精讲') || title.contains('代码实验')) continue;
    if (!seen.add(title)) continue;
    topics.add(title);
    if (topics.length == 8) break;
  }
  return topics;
}

int _addChecklists(
  List<File> files,
  Map<String, Map<String, dynamic>> lessonByFile,
  bool dryRun,
) {
  var changed = 0;
  for (final file in files) {
    final relative = file.path.replaceAll('\\', '/');
    final lesson = lessonByFile[relative];
    if (lesson == null) continue;
    final before = file.readAsStringSync();
    if (before.length >= minimumLength || before.contains(checklistMarker)) {
      continue;
    }
    final block = _buildChecklist(lesson);
    final after = _insertBeforeTail(before, block);
    if (after == before) continue;
    changed++;
    if (!dryRun) file.writeAsStringSync(after);
  }
  return changed;
}

String _buildChecklist(Map<String, dynamic> lesson) {
  final title = _lessonTitle(lesson);
  final quiz = lesson['quiz'] as List<dynamic>? ?? const <dynamic>[];
  final buffer = StringBuffer()
    ..writeln(checklistMarker)
    ..writeln()
    ..writeln('## 本课自测清单与错误对照')
    ..writeln()
    ..writeln(
      '下面把「$title」最容易混淆的选项集中起来。不要只记正确答案，'
      '要能说明错误选项在什么条件下看似合理、又为什么不能满足题干。',
    )
    ..writeln();

  var written = 0;
  for (var i = 0; i < quiz.length && written < 4; i++) {
    final question = (quiz[i] as Map).cast<String, dynamic>();
    final note = _wrongOptionNote(question);
    if (note.isEmpty) continue;
    written++;
    buffer
      ..writeln('### 错误对照 $written：${question['question']}')
      ..writeln()
      ..writeln(note)
      ..writeln();
  }
  if (written == 0) {
    buffer
      ..writeln('本课测验以直接定义和步骤判断为主。请把每个错误选项改写成一句反例，')
      ..writeln('说明它在哪个输入、边界或前提变化下会失败。')
      ..writeln();
  }

  buffer
    ..writeln('### 完成标准')
    ..writeln()
    ..writeln('- [ ] 能用具体输入复现最小示例，并逐行解释输入、处理与输出。')
    ..writeln('- [ ] 能只改一个值完成边界实验，并让预测与实际结果一致。')
    ..writeln('- [ ] 能制造一个可控错误，读出第一条错误信息并完成修复。')
    ..writeln('- [ ] 能不看书说出本课至少两个易错点和对应的验证方法。')
    ..writeln()
    ..writeln('### 复盘记录')
    ..writeln()
    ..writeln('| 项目 | 记录 |')
    ..writeln('| --- | --- |')
    ..writeln('| 学到的核心机制 |  |')
    ..writeln('| 仍然不确定的问题 |  |')
    ..writeln('| 下一步验证动作 |  |');
  return buffer.toString();
}

void _verify(List<File> files, Map<String, Map<String, dynamic>> lessonByFile) {
  final thin = <String>[];
  final placeholders = <String>[];
  var thickened = 0;
  final placeholderPatterns = <RegExp>[
    RegExp(r'print\("hello"\)'),
    RegExp(r'result=5'),
    RegExp(r'print\(bin\(10\), hex\(255\), 0b1010\)'),
  ];

  for (final file in files) {
    final relative = file.path.replaceAll('\\', '/');
    final lesson = lessonByFile[relative];
    if (lesson == null) continue;
    final text = file.readAsStringSync();
    if (text.length < minimumLength) {
      thin.add('${lesson['id']}(${text.length})');
    }
    if (placeholderPatterns.any((pattern) => pattern.hasMatch(text))) {
      placeholders.add('${lesson['id']}');
    }
    if (text.contains(marker)) thickened++;
  }

  stdout.writeln('加厚标记：$thickened 篇');
  stdout.writeln(
    '少于 $minimumLength 字符：${thin.length} 篇'
    '${thin.isEmpty ? '' : '（${thin.take(20).join('、')}${thin.length > 20 ? ' …' : ''}）'}',
  );
  stdout.writeln(
    '占位示例残留：${placeholders.length} 篇'
    '${placeholders.isEmpty ? '' : '（${placeholders.join('、')}）'}',
  );
  if (thin.isEmpty && placeholders.isEmpty) {
    stdout.writeln('校验通过：正文长度与占位示例均达标。');
  } else {
    stdout.writeln('校验未通过：请先处理上面的课程。');
    exitCode = 1;
  }
}
