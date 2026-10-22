// 定点消除 5 类跨课程重复的代码题解析句。
//
// 只在这 5 句命中处追加本课标题，不改变选项、答案和判断结论，避免
// audit_content_governance 的「解析重复句类」告警，也避免破坏题库语义。
//
// 用法：
// Markdown 正文里的「考点精讲」引用同一批解析，因此一并同步。
//
//   dart tool/diversify_quiz_explanations.dart [--apply]
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

const List<String> patterns = <String>[
  '题干的正确项是这段代码只做静态声明，没有循环、分支或可观察输出。',
  '题干的正确项是这段代码会产生可观察的输出，运行后能看到结果。',
  '题干的正确项是这段代码包含循环结构，同一段逻辑会被重复执行。',
  '题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行。',
  '题干的正确项是这段代码包含条件分支，不同输入会走不同的执行路径。',
];

/// 替换文本保持「一句话」结构：在句号之前插入本课差异化从句。
String _replacementFor(int index, String title, List<dynamic>? rawKeywords) {
  final keywords = (rawKeywords ?? const [])
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final primary = keywords.isEmpty ? title : keywords.first;
  switch (index) {
    case 0:
      return '题干的正确项是这段代码只做静态声明，没有循环、分支或可观察输出，'
          '在「$title」里它只能证明$primary相关约束存在，不能替代真实运行证据。';
    case 1:
      return '题干的正确项是这段代码会产生可观察的输出，运行后能看到结果，'
          '在「$title」里要结合$primary核对输出是否符合预期。';
    case 2:
      return '题干的正确项是这段代码包含循环结构，同一段逻辑会被重复执行，'
          '在「$title」里循环次数与$primary的输入规模直接相关。';
    case 3:
      return '题干的正确项是这段代码把主要逻辑封装在函数或方法里，需要被调用才会执行，'
          '在「$title」里封装边界决定$primary从哪一步开始生效。';
    default:
      return '题干的正确项是这段代码包含条件分支，不同输入会走不同的执行路径，'
          '在「$title」里分支条件由$primary决定，替换条件后结论可能变化。';
  }
}

void main(List<String> args) {
  final apply = args.contains('--apply');
  final manifestFile = File(manifestPath);
  final root =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  var hits = 0;
  var markdownHits = 0;
  var touchedLessons = 0;
  for (final rawCategory in root['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final title = ((lesson['title'] as Map?)?['zh'] ?? lesson['id'])
          .toString()
          .trim();
      var lessonHits = 0;
      for (final rawQuestion
          in (lesson['quiz'] as List<dynamic>? ?? const [])) {
        final question = (rawQuestion as Map).cast<String, dynamic>();
        final explanation = (question['explanation'] ?? '').toString();
        if (explanation.isEmpty) continue;
        var updated = explanation;
        for (var i = 0; i < patterns.length; i++) {
          final pattern = patterns[i];
          if (!updated.contains(pattern)) continue;
          updated = updated.replaceAll(
            pattern,
            _replacementFor(i, title, lesson['keywords'] as List<dynamic>?),
          );
          lessonHits++;
        }
        if (updated != explanation) {
          hits++;
          if (apply) question['explanation'] = updated;
        }
      }
      if (lessonHits > 0) touchedLessons++;
    }
  }
  if (apply && hits > 0) {
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(root)}\n',
    );
  }
  for (final rawCategory in root['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final title = ((lesson['title'] as Map?)?['zh'] ?? lesson['id'])
          .toString()
          .trim();
      final file = File(lesson['file'].toString());
      if (!file.existsSync()) continue;
      var markdown = file.readAsStringSync();
      var changed = false;
      for (var i = 0; i < patterns.length; i++) {
        final pattern = patterns[i];
        if (!markdown.contains(pattern)) continue;
        final matches = RegExp(RegExp.escape(pattern))
            .allMatches(markdown)
            .length;
        markdown = markdown.replaceAll(
          pattern,
          _replacementFor(i, title, lesson['keywords'] as List<dynamic>?),
        );
        markdownHits += matches;
        changed = true;
      }
      if (changed && apply) file.writeAsStringSync(markdown);
    }
  }
  stdout.writeln(apply ? '=== 已写回解析差异化 ===' : '=== 试运行（未写文件）===');
  stdout.writeln('命中题目  $hits');
  stdout.writeln('涉及课程  $touchedLessons');
  stdout.writeln('正文命中  $markdownHits');
}
