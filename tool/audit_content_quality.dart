// 内容质量巡检（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/audit_content_quality.dart [--json] [--no-fail] [--top=40]
//
// 与 audit_content_depth.dart 侧重「深度」不同，本工具做全量质量巡检：
//   · 篇幅目标（普通课 10000 字符，语言基础课 12000 字符）
//   · 章节结构、代码围栏、配图 alt 文本与图片文件是否存在
//   · 测验规模、题型分布、答案下标、解析长度与填空题答案
//   · 前置知识 ID 完整性、循环依赖、重复标题与跨课程模板化长句
//
// 发现错误时退出码为 1（可用 --no-fail 只报告），便于本地或 CI 卡口。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const int normalTarget = 10000;
const int languageTarget = 12000;

const Set<String> languageCategories = <String>{
  'python',
  'c',
  'cpp',
  'java',
  'javascript',
  'typescript',
  'csharp',
  'go',
  'rust',
  'kotlin',
  'swift',
  'shell',
};

const List<String> requiredSections = <String>[
  '## 考点精讲',
  '## 参考资料与复核',
  '## English Overview',
  '## 内容元数据',
];

const List<String> questionTypes = <String>[
  'single',
  'multi',
  'fill',
  'order',
  'code',
  'debug',
];

void main(List<String> args) {
  final emitJson = args.contains('--json');
  final failOnIssue = !args.contains('--no-fail');
  final top =
      int.tryParse(
        args
            .firstWhere(
              (arg) => arg.startsWith('--top='),
              orElse: () => '--top=40',
            )
            .substring('--top='.length),
      ) ??
      40;

  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final lessons = <_LessonAudit>[];
  final allIds = <String, _LessonAudit>{};
  final titleIndex = <String, List<String>>{};

  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      final file = lesson['file'].toString();
      final markdown = File(file).existsSync()
          ? File(file).readAsStringSync()
          : '';
      final title = ((lesson['title'] as Map?)?['zh'] ?? id).toString();
      final prerequisites =
          ((lesson['prerequisites'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString())
              .toList();
      final audit = _LessonAudit(
        id: id,
        categoryId: categoryId,
        title: title,
        markdown: markdown,
        quiz: ((lesson['quiz'] as List<dynamic>?) ?? const []).cast<Map>(),
        prerequisites: prerequisites,
        hasCodeQuizMeta: lesson['code_quiz'] is Map,
      );
      lessons.add(audit);
      allIds[id] = audit;
      titleIndex.putIfAbsent('$categoryId::$title', () => <String>[]).add(id);
    }
  }

  final issues = <_Issue>[];
  final typeHistogram = <String, int>{
    for (final type in questionTypes) type: 0,
  };
  var imageCount = 0;
  var lessonsWithImage = 0;
  var lessonsWithLab = 0;

  for (final lesson in lessons) {
    final target =
        languageCategories.contains(lesson.categoryId) && lesson.isIntro
        ? languageTarget
        : normalTarget;
    if (lesson.markdown.isEmpty) {
      issues.add(_Issue('error', lesson.id, 'Markdown 文件缺失或为空'));
      continue;
    }
    if (lesson.markdown.length < target) {
      issues.add(
        _Issue(
          'error',
          lesson.id,
          '正文 ${lesson.markdown.length} 字符，低于目标 $target',
        ),
      );
    }
    for (final section in requiredSections) {
      if (!lesson.markdown.contains(section)) {
        issues.add(_Issue('error', lesson.id, '缺少章节 $section'));
      }
    }
    final fenceCount = RegExp(
      r'^```',
      multiLine: true,
    ).allMatches(lesson.markdown).length;
    if (fenceCount.isOdd) {
      issues.add(_Issue('error', lesson.id, '代码围栏未闭合（``` 数量为奇数）'));
    }
    for (final match in RegExp(
      r'!\[([^\]]*)\]\(([^)]+)\)',
    ).allMatches(lesson.markdown)) {
      final alt = match.group(1)!.trim();
      final rawPath = match.group(2)!.trim();
      imageCount++;
      if (alt.isEmpty) {
        issues.add(_Issue('error', lesson.id, '配图缺少替代文本：$rawPath'));
      }
      if (rawPath.startsWith('http')) continue;
      final path = rawPath.startsWith('assets/')
          ? rawPath
          : 'assets/content/$rawPath';
      if (!File(path).existsSync()) {
        issues.add(_Issue('error', lesson.id, '配图文件不存在：$path'));
      }
    }
    if (lesson.imageCount > 0) lessonsWithImage++;
    if (lesson.markdown.contains('## 动手练习')) {
      lessonsWithLab++;
    }
    issues.addAll(_auditQuiz(lesson, typeHistogram));
  }

  for (final entry in titleIndex.entries) {
    if (entry.value.length > 1) {
      final title = entry.key.split('::').skip(1).join('::');
      issues.add(_Issue('warn', entry.value.first, '同一分类内标题重复：$title'));
    }
  }
  for (final lesson in lessons) {
    for (final prerequisite in lesson.prerequisites) {
      if (prerequisite == lesson.id) {
        issues.add(_Issue('error', lesson.id, '前置知识指向自己'));
      } else if (!allIds.containsKey(prerequisite)) {
        issues.add(_Issue('error', lesson.id, '前置知识不存在：$prerequisite'));
      }
    }
  }
  issues.addAll(_findPrerequisiteCycles(lessons, allIds));
  // 模板化长句是提示性信息：全库共享的学习支架会稳定复现，
  // 因此写进报告的 template_sentences 字段，不参与错误/警告计数。
  final templateNotes = _findBoilerplate(lessons);

  final lessonsWithoutCodeQuestion = lessons
      .where((lesson) => !lesson.hasCodeQuestion)
      .length;
  final errors = issues.where((issue) => issue.level == 'error').toList();
  final warnings = issues.where((issue) => issue.level == 'warn').toList();
  final report = <String, dynamic>{
    'generated_at': DateTime.now().toIso8601String(),
    'lesson_count': lessons.length,
    'total_chars': lessons.fold<int>(0, (sum, l) => sum + l.markdown.length),
    'min_chars': lessons.isEmpty
        ? 0
        : lessons.map((l) => l.markdown.length).reduce((a, b) => a < b ? a : b),
    'image_count': imageCount,
    'lessons_with_image': lessonsWithImage,
    'lessons_with_lab_section': lessonsWithLab,
    'question_type_histogram': typeHistogram,
    'lessons_without_code_question': lessonsWithoutCodeQuestion,
    'error_count': errors.length,
    'warning_count': warnings.length,
    'issues': issues.map((issue) => issue.toJson()).toList(),
    'template_sentences': templateNotes.map((issue) => issue.toJson()).toList(),
  };

  final reportFile = File('tool/reports/content_quality_report.json');
  reportFile.parent.createSync(recursive: true);
  reportFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
  );

  if (emitJson) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  } else {
    stdout.writeln('课程总数              ${report['lesson_count']}');
    stdout.writeln('正文总字符            ${report['total_chars']}');
    stdout.writeln('最短课程              ${report['min_chars']}');
    stdout.writeln('配图引用              ${report['image_count']}');
    stdout.writeln('有配图课程            ${report['lessons_with_image']}');
    stdout.writeln('有实验章节课程        ${report['lessons_with_lab_section']}');
    stdout.writeln('无代码类题目课程      $lessonsWithoutCodeQuestion');
    stdout.writeln(
      '题型分布              '
      '${typeHistogram.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
    );
    stdout.writeln('错误                  ${errors.length}');
    stdout.writeln('警告                  ${warnings.length}');
    if (errors.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln('--- 错误（前 $top 条）---');
      for (final issue in errors.take(top)) {
        stdout.writeln('${issue.lessonId}: ${issue.message}');
      }
    }
    if (warnings.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln('--- 警告（前 $top 条）---');
      for (final issue in warnings.take(top)) {
        stdout.writeln('${issue.lessonId}: ${issue.message}');
      }
    }
    stdout.writeln('');
    stdout.writeln('报告已写入 tool/reports/content_quality_report.json');
  }

  if (failOnIssue && errors.isNotEmpty) {
    exitCode = 1;
  }
}

/// 逐题检查：题型、选项、答案下标、解析与填空题答案。
List<_Issue> _auditQuiz(_LessonAudit lesson, Map<String, int> histogram) {
  final issues = <_Issue>[];
  if (lesson.quiz.length < 4) {
    issues.add(_Issue('error', lesson.id, '测验只有 ${lesson.quiz.length} 题'));
  }
  for (var index = 0; index < lesson.quiz.length; index++) {
    final question = lesson.quiz[index];
    final type = (question['type'] as String?) ?? 'single';
    histogram[type] = (histogram[type] ?? 0) + 1;
    if (!questionTypes.contains(type)) {
      issues.add(_Issue('warn', lesson.id, '第 ${index + 1} 题题型未知：$type'));
    }
    final explanation = (question['explanation'] as String? ?? '').trim();
    if (explanation.length < 12) {
      issues.add(_Issue('warn', lesson.id, '第 ${index + 1} 题解析过短'));
    }
    final options = ((question['options'] as List<dynamic>?) ?? const [])
        .map((item) => item.toString().trim())
        .toList();
    if (type != 'fill' && options.length < 2) {
      issues.add(_Issue('error', lesson.id, '第 ${index + 1} 题选项不足'));
    }
    if (options.toSet().length != options.length) {
      issues.add(_Issue('warn', lesson.id, '第 ${index + 1} 题存在重复选项'));
    }
    final rawAnswers =
        (question['answers'] as List<dynamic>?) ??
        (question['correct_indexes'] as List<dynamic>?) ??
        const <dynamic>[];
    final answers = rawAnswers
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList();
    final answerIndex = question['answer'];
    final normalized = answers.isNotEmpty
        ? answers
        : <int>[if (answerIndex is int) answerIndex];
    if (type != 'fill' && normalized.isEmpty) {
      issues.add(_Issue('error', lesson.id, '第 ${index + 1} 题没有答案'));
    }
    for (final answer in normalized) {
      if (type != 'fill' && (answer < 0 || answer >= options.length)) {
        issues.add(_Issue('error', lesson.id, '第 ${index + 1} 题答案下标越界'));
      }
    }
    if (type == 'fill') {
      final accepted = <dynamic>[
        ...((question['accepted_answers'] as List<dynamic>?) ?? const []),
        if (answerIndex is String) answerIndex,
      ];
      if (accepted.isEmpty) {
        issues.add(_Issue('error', lesson.id, '第 ${index + 1} 填空题没有可接受答案'));
      }
    }
    if (type == 'order') {
      final order = ((question['correct_order'] as List<dynamic>?) ?? const [])
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList();
      if (order.length != options.length ||
          order.toSet().length != options.length) {
        issues.add(_Issue('error', lesson.id, '第 ${index + 1} 排序题顺序不完整'));
      }
    }
    if ((type == 'code' || type == 'debug') &&
        (question['code'] as String? ?? '').trim().isEmpty) {
      issues.add(_Issue('error', lesson.id, '第 ${index + 1} 题缺少代码片段'));
    }
  }
  return issues;
}

/// 检测 A→B→A 这类前置知识循环，避免学习路径无法排序。
List<_Issue> _findPrerequisiteCycles(
  List<_LessonAudit> lessons,
  Map<String, _LessonAudit> allIds,
) {
  final issues = <_Issue>[];
  final state = <String, int>{}; // 0=未访问 1=访问中 2=已完成

  void visit(String id, List<String> stack) {
    final current = allIds[id];
    if (current == null) return;
    state[id] = 1;
    for (final next in current.prerequisites) {
      if (!allIds.containsKey(next)) continue;
      if (state[next] == 1) {
        final start = stack.indexOf(next);
        final cycle = <String>[
          if (start >= 0) ...stack.sublist(start),
          id,
          next,
        ];
        issues.add(_Issue('error', id, '前置知识存在循环：${cycle.join(' -> ')}'));
        continue;
      }
      if (state[next] == null) visit(next, <String>[...stack, id]);
    }
    state[id] = 2;
  }

  for (final lesson in lessons) {
    if (state[lesson.id] == null) visit(lesson.id, <String>[]);
  }
  return issues;
}

/// 跨课程重复的长句大概率是模板化水词，按出现课程数报告。
List<_Issue> _findBoilerplate(List<_LessonAudit> lessons) {
  final sentenceIndex = <String, List<String>>{};
  for (final lesson in lessons) {
    final seen = <String>{};
    for (final raw in lesson.markdown.split(RegExp(r'[\n。！？]'))) {
      final sentence = raw.trim();
      if (sentence.length < 40) continue;
      if (sentence.startsWith('#') ||
          sentence.startsWith('|') ||
          sentence.startsWith('```') ||
          sentence.startsWith('![')) {
        continue;
      }
      if (!seen.add(sentence)) continue;
      sentenceIndex.putIfAbsent(sentence, () => <String>[]).add(lesson.id);
    }
  }
  final threshold = lessons.length * 0.25;
  final issues = <_Issue>[];
  for (final entry in sentenceIndex.entries) {
    if (entry.value.length >= threshold && entry.value.length >= 20) {
      final preview = entry.key.length > 30
          ? '${entry.key.substring(0, 30)}…'
          : entry.key;
      issues.add(
        _Issue(
          'warn',
          entry.value.first,
          '模板化长句出现在 ${entry.value.length} 门课：$preview',
        ),
      );
    }
  }
  return issues;
}

class _LessonAudit {
  _LessonAudit({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.markdown,
    required this.quiz,
    required this.prerequisites,
    required this.hasCodeQuizMeta,
  });

  final String id;
  final String categoryId;
  final String title;
  final String markdown;
  final List<Map<dynamic, dynamic>> quiz;
  final List<String> prerequisites;

  /// manifest 中是否已写入代码阅读题元数据（运行时生成题目）。
  final bool hasCodeQuizMeta;

  bool get isIntro =>
      title.contains('入门') ||
      title.contains('基础') ||
      title.contains('初识') ||
      title.contains('介绍');

  int get imageCount =>
      RegExp(r'!\[[^\]]*\]\(images/').allMatches(markdown).length;

  bool get hasCodeQuestion =>
      hasCodeQuizMeta ||
      quiz.any((question) {
        final type = (question['type'] as String?) ?? 'single';
        return type == 'code' || type == 'debug';
      });
}

class _Issue {
  const _Issue(this.level, this.lessonId, this.message);

  final String level;
  final String lessonId;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'level': level,
    'lesson_id': lessonId,
    'message': message,
  };
}
