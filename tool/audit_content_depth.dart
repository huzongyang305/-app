// 内容深度审计（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/audit_content_depth.dart [--json] [--top=30]
//
// 逐课统计正文长度、章节完整度、配图、代码块与测验规模，
// 输出最薄的课程清单，作为后续加厚的依据。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> _requiredSections = <String>[
  '## 本节知识框架',
  '## 核心概念定义',
  '## 原理与运行机制',
  '## 典型应用场景',
  '## 代码/协议/SQL 示例',
  '## 时间/空间复杂度或性能分析',
  '## 常见误区与易错点',
  '## 与其他知识点的关系',
  '## 自测题与参考答案',
  '## 考点精讲',
  '## 参考资料与复核',
  '## English Overview',
  '## 内容元数据',
];

void main(List<String> args) {
  final emitJson = args.contains('--json');
  final top =
      int.tryParse(
        args
            .firstWhere((a) => a.startsWith('--top='), orElse: () => '--top=30')
            .substring('--top='.length),
      ) ??
      30;
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;

  final lessons = <Map<String, dynamic>>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = lesson['file'] as String;
      final markdown = File(file).existsSync()
          ? File(file).readAsStringSync()
          : '';
      final quiz = ((lesson['quiz'] as List<dynamic>?) ?? const []).cast<Map>();
      final missing = <String>[
        for (final section in _requiredSections)
          if (!markdown.contains(section)) section,
      ];
      final hasEnglishGuide = markdown.contains('## Full English Study Guide');
      final isProject =
          (lesson['id'] as String).contains('project') ||
          ((lesson['title'] as Map?)?['zh'] as String? ?? '').contains('实战') ||
          ((lesson['title'] as Map?)?['zh'] as String? ?? '').contains('项目');
      lessons.add({
        'id': lesson['id'],
        'category': category['id'],
        'title': (lesson['title'] as Map?)?['zh'],
        'chars': markdown.length,
        'headings': RegExp(
          r'^#{2,3} ',
          multiLine: true,
        ).allMatches(markdown).length,
        'codeBlocks': RegExp(
          r'^```[A-Za-z0-9_+-]+',
          multiLine: true,
        ).allMatches(markdown).length,
        'images': RegExp(r'!\[[^\]]*\]\(images/').allMatches(markdown).length,
        'quizCount': quiz.length,
        'specialQuiz': quiz
            .where((q) => ((q['type'] as String?) ?? 'single') != 'single')
            .length,
        'avgExplanation': quiz.isEmpty
            ? 0
            : quiz
                      .map((q) => ((q['explanation'] as String?) ?? '').length)
                      .reduce((a, b) => a + b) /
                  quiz.length,
        'missingSections': missing,
        'hasEnglishGuide': hasEnglishGuide,
        'isProject': isProject,
      });
    }
  }

  final byChars = [...lessons]
    ..sort((a, b) => (a['chars'] as int).compareTo(b['chars'] as int));
  final totalChars = lessons.fold<int>(
    0,
    (sum, lesson) => sum + (lesson['chars'] as int),
  );
  final missingSectionLessons = lessons
      .where((l) => (l['missingSections'] as List).isNotEmpty)
      .length;

  final report = {
    'lessonCount': lessons.length,
    'totalChars': totalChars,
    'averageChars': totalChars ~/ lessons.length,
    'minChars': byChars.first['chars'],
    'lessonsBelow6000': lessons.where((l) => (l['chars'] as int) < 6000).length,
    'lessonsBelow8000': lessons.where((l) => (l['chars'] as int) < 8000).length,
    'lessonsBelow10000': lessons
        .where((l) => (l['chars'] as int) < 10000)
        .length,
    'lessonsMissingSections': missingSectionLessons,
    'lessonsWithoutImage': lessons
        .where((l) => (l['images'] as int) == 0)
        .length,
    'lessonsWithoutEnglishGuide': lessons
        .where((l) => l['hasEnglishGuide'] != true)
        .length,
    'lessonsQuizBelow4': lessons
        .where((l) => (l['quizCount'] as int) < 4)
        .length,
    'lessonsWithoutSpecialQuiz': lessons
        .where((l) => (l['specialQuiz'] as int) == 0)
        .length,
  };

  if (emitJson) {
    stdout.writeln(
      const JsonEncoder.withIndent('  ')
          .convert({'summary': report, 'thinnest': byChars.take(top).toList()}),
    );
    return;
  }

  stdout.writeln('课程总数              ${report['lessonCount']}');
  stdout.writeln('正文总字符            ${report['totalChars']}');
  stdout.writeln('平均字符              ${report['averageChars']}');
  stdout.writeln('最短课程              ${report['minChars']}');
  stdout.writeln('< 6000 字符            ${report['lessonsBelow6000']}');
  stdout.writeln('< 8000 字符            ${report['lessonsBelow8000']}');
  stdout.writeln('< 10000 字符           ${report['lessonsBelow10000']}');
  stdout.writeln('缺标准章节            ${report['lessonsMissingSections']}');
  stdout.writeln('无配图                ${report['lessonsWithoutImage']}');
  stdout.writeln('无英文精读            ${report['lessonsWithoutEnglishGuide']}');
  stdout.writeln('测验少于 4 题         ${report['lessonsQuizBelow4']}');
  stdout.writeln('无特殊题型            ${report['lessonsWithoutSpecialQuiz']}');
  stdout.writeln('');
  stdout.writeln('--- 最薄的 $top 门课 ---');
  for (final lesson in byChars.take(top)) {
    stdout.writeln(
      '${(lesson['chars'] as int).toString().padLeft(6)}  '
      '${lesson['category']}/${lesson['id']}  '
      'quiz=${lesson['quizCount']} img=${lesson['images']}  '
      '${(lesson['title'] as String?) ?? ''}',
    );
  }
  if (missingSectionLessons > 0) {
    stdout.writeln('');
    stdout.writeln('--- 缺章节的课程 ---');
    for (final lesson
        in lessons
            .where((l) => (l['missingSections'] as List).isNotEmpty)
            .take(top)) {
      stdout.writeln(
        '${lesson['id']}: '
        '${(lesson['missingSections'] as List).join(', ')}',
      );
    }
  }
}
