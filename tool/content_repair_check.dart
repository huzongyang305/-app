// 内容修复自检：把 P0/P1 的核心不变量抠成一条命令，不再依赖肉眼看生成日志。
//
// 用法：
//   dart tool/content_repair_check.dart            # 在当前仓库自检
//   dart tool/content_repair_check.dart --root <目录>  # 自检指定的工作树
//
// 退出码 1 表示存在硬失败，可直接用于 CI 或提交前的最后一道关卡。
import 'dart:convert';
import 'dart:io';

const List<String> _coreSections = <String>[
  '本节知识框架',
  '核心概念定义',
  '原理与运行机制',
  '典型应用场景',
  '代码/协议/SQL 示例',
  '时间/空间复杂度或性能分析',
  '常见误区与易错点',
  '与其他知识点的关系',
  '自测题与参考答案',
];

/// 与 test/content_test.dart 保持同一套「内部题号」口径。
final RegExp _internalQuestionId = RegExp(
  r'[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)）]',
);

const List<String> _markdownTemplateMarkers = <String>[
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
];

String _squeeze(String text) => text.replaceAll(RegExp(r'\s+'), '');

/// 生成器把「引导词 + 片段」直接相连时，片段本身常以同一个字开头，
/// 于是写出「第三步按按任务…」「改成改成借用…」这类残句。正文与题库一起守。
const List<String> _doubledJoinMarkers = <String>[
  '第三步按按',
  '检验方式是按按',
  '第一步按按',
  '改成改成',
  '复现复现',
  '会造成造成',
  '正确做法是是',
  '整数有有符号',
];

/// 第 43 波收掉的四类标点与成对符号残留，在这里钉成硬指标，防止生成端再写出来。
/// 只扫正文与题库的可读文本，code 字段里的 `int **pp` 和 `。。` 都可能是真代码。
final List<RegExp> _punctuationCollisions = <RegExp>[
  RegExp(r'([。；，！？])\1+'), // 同一标点连排：「。。」「，，」
  RegExp(r'([。！？])”([。！？])'), // 引号里已点句末标点，引号外又点一次
  RegExp(r'。？|：；'),
];

/// 排序题的判断依据只写了一步，等于把「A → B → C」抄丢了后两截。
final RegExp _singleStepOrderChain = RegExp(r'本题顺序是「[^」\n]*」。');

/// 行内代码用等长空格占位，下标仍然对得上：标点指标不该被代码片段触发。
String _maskInline(String text) => text.replaceAllMapped(
  RegExp(r'``[^`\n]*``|`[^`\n]*`'),
  (match) => ' ' * match[0]!.length,
);

/// 跳过围栏代码块与行内代码后的正文行。
List<String> _proseLines(String markdown) {
  final out = <String>[];
  var inFence = false;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    out.add(_maskInline(line));
  }
  return out;
}

int _collisionCount(List<String> texts) {
  var total = 0;
  for (final pattern in _punctuationCollisions) {
    for (final text in texts) {
      total += pattern.allMatches(text).length;
    }
  }
  return total;
}

/// 一行里 `**` 个数为奇数，且最后一个后接冒号或汉字时，那是个只剩半个的粗体闭合；
/// 整行只有一个 ** 且它在行首时，那是「**答案：C → D → A → B」这类忘了收尾的开场。
int _orphanBoldCount(List<String> prose) {
  var count = 0;
  for (final masked in prose) {
    final marks = RegExp(r'\*\*')
        .allMatches(masked)
        .map((match) => match.start)
        .toList();
    if (marks.isEmpty || marks.length.isEven) continue;
    if (marks.length == 1 && marks.first == 0) {
      final trimmed = masked.trimRight();
      if (!RegExp(r'^#').hasMatch(masked.trimLeft()) &&
          !trimmed.endsWith('**')) {
        count++;
      }
      continue;
    }
    final at = marks.last;
    final before = at > 0 ? masked[at - 1] : '';
    final after = at + 2 < masked.length ? masked[at + 2] : '';
    if (before == '*' || after == '*' || before.isEmpty) continue;
    if (RegExp(r'\s').hasMatch(before)) continue;
    if (!RegExp(r'[：\u4e00-\u9fa5]').hasMatch(after)) continue;
    count++;
  }
  return count;
}

/// 题目里要扫的可见文本：题干、解析、选项；code 与 language 不进来。
List<String> _visibleQuizText(Map<String, dynamic> question) {
  return <String>[
    '${question['question'] ?? ''}',
    '${question['explanation'] ?? ''}',
    for (final option
        in (question['options'] as List<dynamic>? ?? const <dynamic>[]))
      '$option',
  ];
}

/// 生成器把课程名直接粘在「本课」后面（本课事务要解决的是ACID…），读起来像半截短语。
/// 第 45 波统一改成 本课《课程名》，这里守住它别自己长回来。
int _benkeGluedCount(String text, String title) =>
    title.isEmpty ? 0 : text.split('本课$title').length - 1;

/// 概念表与术语表的首格应当是个术语；`）、回溯处理（` 这类从正文中间截出来的碎片要响。
List<String> _brokenTermCells(List<String> lines) {
  final out = <String>[];
  var section = '';
  for (final line in lines) {
    if (line.startsWith('## ')) {
      section = line.substring(3).trim();
      continue;
    }
    if (section != '核心概念定义' && section != '术语速查') continue;
    if (!line.startsWith('|') || RegExp(r'^\|\s*[-: ]+\|').hasMatch(line)) {
      continue;
    }
    final cells = line.split('|').skip(1).toList();
    if (cells.length < 3) continue;
    final term = cells.first.trim();
    if (term.isEmpty || RegExp(r'^(术语|概念|名词)$').hasMatch(term)) continue;
    if (RegExp(r'^[）、，。；：]|[（「『“]$').hasMatch(term)) {
      out.add('$section:$term');
    }
  }
  return out;
}

final RegExp _imageRef = RegExp(r'!\[[^\]]*\]\((?:images/)?([^)\s]+)\)');
final RegExp _imagePrefix = RegExp(
  r'^(?:remaining|diagram|lesson|category|visual|p0x|p[0-2])_',
);

Set<String> _idTokens(String value) => value
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((part) => part.length >= 2)
    .toSet();

/// 首图借用了别课的专属配图：图片词干正好是另一篇课文的 id，那篇课文也在用这张图，
/// 而两个 id 的主题词不构成包含关系（java_microservices 用 microservices 的图不算）。
List<String> _borrowedHeroes(
  Map<String, String> heroById,
  Map<String, List<String>> usersByImage,
  Set<String> lessonIds,
) {
  final out = <String>[];
  for (final entry in heroById.entries) {
    final image = entry.value;
    final stem = image
        .replaceAll(RegExp(r'\.(webp|png|jpe?g|gif|svg)$'), '')
        .replaceFirst(_imagePrefix, '');
    if (stem == entry.key || !lessonIds.contains(stem)) continue;
    if (!(usersByImage[image] ?? const <String>[]).contains(stem)) continue;
    final selfTokens = _idTokens(entry.key);
    if (_idTokens(stem).every(selfTokens.contains)) continue;
    out.add('${entry.key}($image→$stem)');
  }
  return out;
}

void main(List<String> args) {
  final rootIndex = args.indexOf('--root');
  final root = rootIndex >= 0 && rootIndex + 1 < args.length
      ? args[rootIndex + 1]
      : '.';
  final manifestFile = File('$root/assets/content/manifest.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到清单：${manifestFile.path}');
    exitCode = 1;
    return;
  }
  final manifestText = manifestFile.readAsStringSync();
  final manifest = jsonDecode(manifestText) as Map<String, dynamic>;

  var lessonCount = 0;
  var questionCount = 0;
  var noCode = 0;
  var noImage = 0;
  var emptySections = 0;
  var thinChecklist = 0;
  var missingProjectSpec = 0;
  var missingSection = 0;
  var shortLesson = 0;
  var uncovered = <String>[];
  var internalIds = <String>[];
  var templateHits = <String>[];
  var punctuationHits = <String>[];
  var singleStepChains = <String>[];
  var orphanBold = <String>[];
  var benkeGlued = <String>[];
  var brokenTermCells = <String>[];
  var doubledJoins = <String>[
    for (final marker in _doubledJoinMarkers)
      if (manifestText.contains(marker)) 'manifest($marker)',
  ];
  final seenStems = <String, String>{};
  final duplicateStems = <String>[];
  final heroById = <String, String>{};
  final usersByImage = <String, List<String>>{};
  final lessonIds = <String>{};

  for (final rawCategory in (manifest['categories'] as List<dynamic>)) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in (category['lessons'] as List<dynamic>)) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = '${lesson['id']}';
      final title = '${(lesson['title'] as Map?)?['zh'] ?? id}'.trim();
      final file = File('$root/${lesson['file']}');
      if (!file.existsSync()) {
        stderr.writeln('缺少正文：${file.path}');
        exitCode = 1;
        continue;
      }
      final markdown = file.readAsStringSync();
      lessonCount++;
      lessonIds.add(id);
      final images = _imageRef
          .allMatches(markdown)
          .map((match) => match.group(1)!.split('/').last)
          .toList();
      if (images.isNotEmpty) heroById[id] = images.first;
      for (final image in images) {
        usersByImage.putIfAbsent(image, () => <String>[]).add(id);
      }
      if (markdown.length < 6000) shortLesson++;
      for (final section in _coreSections) {
        if (!markdown.contains('## $section')) missingSection++;
      }
      final fenceLanguages = RegExp(r'^```([^\n]*)$', multiLine: true)
          .allMatches(markdown)
          .map((match) => (match.group(1) ?? '').trim())
          .toList();
      final codeBlocks = fenceLanguages.where((item) => item.isNotEmpty).length;
      if (codeBlocks == 0) noCode++;
      if (!RegExp(r'!\[[^\]]*\]\([^)]+\)').hasMatch(markdown)) noImage++;
      // 空标题：H2 以下标题与下一个同级或更高级标题之间必须有正文。
      final lines = markdown.split('\n');
      final headings = <({int line, int level})>[];
      var inFence = false;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (line.trimLeft().startsWith('```')) {
          inFence = !inFence;
          continue;
        }
        if (inFence) continue;
        final match = RegExp(r'^(#{2,6})\s+').firstMatch(line);
        if (match != null) {
          headings.add((line: index, level: match.group(1)!.length));
        }
      }
      for (var index = 0; index < headings.length; index++) {
        final heading = headings[index];
        var end = lines.length;
        for (var next = index + 1; next < headings.length; next++) {
          if (headings[next].level <= heading.level) {
            end = headings[next].line;
            break;
          }
        }
        var hasBody = false;
        for (var line = heading.line + 1; line < end; line++) {
          final trimmed = lines[line].trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          hasBody = true;
          break;
        }
        if (!hasBody) emptySections++;
      }
      final checklist = RegExp(
        r'^- \[ \] ',
        multiLine: true,
      ).allMatches(markdown).length;
      if (checklist < 3) thinChecklist++;
      if (id.contains('project') ||
          title.contains('实战') ||
          title.contains('项目')) {
        if (!markdown.contains('项目专属规格')) missingProjectSpec++;
      }
      final markdownIds = _internalQuestionId.allMatches(markdown).length;
      if (markdownIds > 0) internalIds.add('$id(markdown:$markdownIds)');
      for (final marker in _markdownTemplateMarkers) {
        if (markdown.contains(marker)) templateHits.add('$id($marker)');
      }
      for (final marker in _doubledJoinMarkers) {
        if (markdown.contains(marker)) doubledJoins.add('$id($marker)');
      }
      final prose = _proseLines(markdown);
      final mdCollisions = _collisionCount(prose);
      if (mdCollisions > 0) punctuationHits.add('$id(md:$mdCollisions)');
      final mdChains = prose
          .where((line) => _singleStepOrderChain.hasMatch(line))
          .length;
      if (mdChains > 0) singleStepChains.add('$id(md:$mdChains)');
      final mdOrphans = _orphanBoldCount(prose);
      if (mdOrphans > 0) orphanBold.add('$id(md:$mdOrphans)');
      final mdBenke = _benkeGluedCount(markdown, title);
      if (mdBenke > 0) benkeGlued.add('$id(md:$mdBenke)');
      final mdCells = _brokenTermCells(lines);
      if (mdCells.isNotEmpty) {
        brokenTermCells.add('$id(md:${mdCells.first})');
      }

      final quiz = (lesson['quiz'] as List<dynamic>? ?? const <dynamic>[])
          .map((raw) => (raw as Map).cast<String, dynamic>())
          .toList();
      final normalizedMarkdown = _squeeze(markdown);
      for (var index = 0; index < quiz.length; index++) {
        questionCount++;
        final question = quiz[index];
        final blob = jsonEncode(question);
        if (_internalQuestionId.hasMatch(blob)) {
          internalIds.add('$id#${index + 1}(quiz)');
        }
        final visible = _visibleQuizText(question).map(_maskInline).toList();
        final quizCollisions = _collisionCount(visible);
        if (quizCollisions > 0) {
          punctuationHits.add('$id#${index + 1}(quiz:$quizCollisions)');
        }
        final quizChains = visible
            .where((text) => _singleStepOrderChain.hasMatch(text))
            .length;
        if (quizChains > 0) {
          singleStepChains.add('$id#${index + 1}(quiz:$quizChains)');
        }
        final quizOrphans = _orphanBoldCount(visible);
        if (quizOrphans > 0) {
          orphanBold.add('$id#${index + 1}(quiz:$quizOrphans)');
        }
        final quizBenke = _benkeGluedCount(visible.join('\n'), title);
        if (quizBenke > 0) {
          benkeGlued.add('$id#${index + 1}(quiz:$quizBenke)');
        }
        final stem = _squeeze('${question['question'] ?? ''}');
        if (stem.isEmpty) continue;
        if (!normalizedMarkdown.contains(stem)) {
          uncovered.add('$id#${index + 1}');
        }
        final owner = seenStems[stem];
        if (owner != null) {
          duplicateStems.add('$owner/$id#${index + 1}');
        } else {
          seenStems[stem] = id;
        }
      }
    }
  }

  final borrowedHeroes = _borrowedHeroes(heroById, usersByImage, lessonIds);

  stdout
    ..writeln('课程数                     $lessonCount')
    ..writeln('题目数                     $questionCount')
    ..writeln('无代码块课程               $noCode')
    ..writeln('无配图课程                 $noImage')
    ..writeln('空小节                     $emptySections')
    ..writeln('复习清单不足 3 条           $thinChecklist')
    ..writeln('项目课缺专属规格            $missingProjectSpec')
    ..writeln('缺核心章节                  $missingSection')
    ..writeln('少于 6000 字符的课程        $shortLesson')
    ..writeln('题库未进入考点精讲          ${uncovered.length}')
    ..writeln('内部题号残留                ${internalIds.length}')
    ..writeln('模板句残留                  ${templateHits.length}')
    ..writeln('拼接重复字残留              ${doubledJoins.length}')
    ..writeln('标点碰撞残留                ${punctuationHits.length}')
    ..writeln('单步顺序链残留              ${singleStepChains.length}')
    ..writeln('孤儿粗体闭合残留            ${orphanBold.length}')
    ..writeln('本课粘课程名                ${benkeGlued.length}')
    ..writeln('表格首格碎片                ${brokenTermCells.length}')
    ..writeln('首图借用别课专属图          ${borrowedHeroes.length}')
    ..writeln('题干重复                    ${duplicateStems.length}');
  for (final sample in doubledJoins.take(5)) {
    stdout.writeln('  重复字：$sample');
  }
  for (final sample in punctuationHits.take(5)) {
    stdout.writeln('  标点碰撞：$sample');
  }
  for (final sample in singleStepChains.take(5)) {
    stdout.writeln('  单步链：$sample');
  }
  for (final sample in orphanBold.take(5)) {
    stdout.writeln('  孤儿粗体：$sample');
  }
  for (final sample in benkeGlued.take(5)) {
    stdout.writeln('  本课粘名：$sample');
  }
  for (final sample in brokenTermCells.take(5)) {
    stdout.writeln('  首格碎片：$sample');
  }
  for (final sample in borrowedHeroes.take(5)) {
    stdout.writeln('  借用首图：$sample');
  }
  for (final sample in uncovered.take(5)) {
    stdout.writeln('  未覆盖：$sample');
  }
  for (final sample in duplicateStems.take(5)) {
    stdout.writeln('  重复：$sample');
  }

  final hardFailures =
      noCode +
      noImage +
      emptySections +
      thinChecklist +
      missingProjectSpec +
      missingSection +
      shortLesson +
      uncovered.length +
      internalIds.length +
      templateHits.length +
      doubledJoins.length +
      punctuationHits.length +
      singleStepChains.length +
      orphanBold.length +
      benkeGlued.length +
      brokenTermCells.length +
      borrowedHeroes.length +
      duplicateStems.length;
  if (hardFailures > 0) {
    stderr.writeln('自检失败：$hardFailures 项硬失败');
    exitCode = 1;
  } else {
    stdout.writeln('自检通过：全部硬指标为 0');
  }
}
