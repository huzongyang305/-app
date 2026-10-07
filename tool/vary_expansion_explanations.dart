// P0 收尾：把扩展课程解析里残留的机械收尾句替换成轮换措辞。
//
// 用法：
//   dart tool/vary_expansion_explanations.dart [--dry-run]
//
// 背景：generate_expansion_lessons.dart 早期版本给每道题追加同一句
// 「把相邻主题的做法直接套用到《…》的场景里」，跨课重复 100 次。
// 生成器已改为轮换措辞；本工具负责把已生成的课程就地修好：
//   · manifest 测验解析里的旧句按题号替换；
//   · 对应 Markdown 正文里的旧句按出现顺序替换；
//   · 找不到旧句的文件不动，可重复执行。
import 'dart:convert';
import 'dart:io';

import 'generate_expansion_lessons.dart' show explanationClosingVariants;

const String manifestPath = 'assets/content/manifest.json';

/// 第一版收尾句（跨课完全同文），以及第二版五种未带概念名的措辞。
const List<String> legacyClosingSentences = <String>[
  '把别的语言或框架的默认做法直接搬过来，通常会在本课的边界条件上失效。',
  '相邻主题的经验可以借鉴，但前提不同就会得出相反结论，答题前先核对前提。',
  '记忆结论之外还要记住适用条件，换一个输入往往就不成立了。',
  '干扰项常常是相邻主题里成立的结论，只有按本课的输入与约束判断才能排除。',
  '同一套做法换到不同约束下未必成立，先确认边界再决定答案。',
];

final RegExp _legacyClosing = RegExp(
  <String>[
    r'把相邻主题的做法直接套用到《[^》]*》的场景里，往往就是丢分的地方。?',
    r'借鉴相邻主题的经验前，先核对[^。；\n]*的前提；前提不同，结论就会反过来。?',
    ...legacyClosingSentences.map(RegExp.escape),
  ].join('|'),
);

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final file = File(manifestPath);
  final manifest = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  var touchedLessons = 0;
  var touchedQuestions = 0;
  var touchedMarkdown = 0;
  final updatedFiles = <String>[];

  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final quiz = ((lesson['quiz'] as List?) ?? const [])
          .cast<Map<dynamic, dynamic>>();
      var changed = false;
      for (var index = 0; index < quiz.length; index++) {
        final explanation = '${quiz[index]['explanation'] ?? ''}';
        if (!_legacyClosing.hasMatch(explanation)) continue;
        final replacement = _closing(index, _conceptOf(explanation));
        quiz[index]['explanation'] = explanation.replaceAll(
          _legacyClosing,
          replacement,
        );
        touchedQuestions++;
        changed = true;
      }
      if (!changed) continue;
      touchedLessons++;
      final path = lesson['file'] as String;
      final markdownFile = File(path);
      if (!markdownFile.existsSync()) continue;
      var markdown = markdownFile.readAsStringSync();
      if (!_legacyClosing.hasMatch(markdown)) continue;
      var occurrence = 0;
      markdown = markdown.replaceAllMapped(_legacyClosing, (match) {
        final replacement = _closing(
          occurrence,
          _conceptBefore(markdown, match.start),
        );
        occurrence++;
        return replacement;
      });
      if (!dryRun) markdownFile.writeAsStringSync(markdown, flush: true);
      touchedMarkdown++;
      updatedFiles.add(path);
    }
  }

  if (!dryRun && touchedQuestions > 0) {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }

  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}涉及课程 $touchedLessons，改写解析 $touchedQuestions 条，'
    '改写正文 $touchedMarkdown 个文件',
  );
  for (final path in updatedFiles.take(30)) {
    stdout.writeln('  - $path');
  }
}

/// 取该题解析里已经写明的概念名（生成器写在「要点」之后）。
String _conceptOf(String text) {
  final match = RegExp(r'要点「([^」]{2,30})」').firstMatch(text);
  return match?.group(1) ?? '本课概念';
}

/// 取某个位置之前最后一次出现的概念名，用于正文里逐条替换。
String _conceptBefore(String text, int index) {
  final matches = RegExp(r'要点「([^」]{2,30})」')
      .allMatches(text.substring(0, index));
  if (matches.isEmpty) return '本课概念';
  return matches.last.group(1)!;
}

String _closing(int index, String concept) =>
    explanationClosingVariants[index % explanationClosingVariants.length]
        .replaceAll('{concept}', concept);
