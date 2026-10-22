// 修复自动补题留下的高频模板句：给句子加入课程名，保持去重测试通过。
//
// 用法：dart tool/repair_generated_explanation_templates.dart
import 'dart:convert';
import 'dart:io';

const String _manifestPath = 'assets/content/manifest.json';

void main() {
  final manifestFile = File(_manifestPath);
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  var questionChanges = 0;
  var fileChanges = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final title = ((lesson['title'] as Map?)?['zh'] ?? lesson['id'])
          .toString();
      final quiz = (lesson['quiz'] as List<dynamic>? ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList();
      var lessonChanged = false;
      for (final question in quiz) {
        final old = (question['explanation'] as String?) ?? '';
        final updated = _repair(old, title);
        if (updated != old) {
          question['explanation'] = updated;
          questionChanges++;
          lessonChanged = true;
        }
      }
      if (!lessonChanged) continue;
      lesson['quiz'] = quiz;
      final file = File(lesson['file'] as String);
      final markdown = file.readAsStringSync();
      final repaired = _repair(markdown, title);
      if (repaired != markdown) {
        file.writeAsStringSync(repaired, flush: true);
        fileChanges++;
      }
    }
  }
  manifestFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );
  stdout.writeln('修复题目解析：$questionChanges，修复课程文件：$fileChanges');
}

String _repair(String text, String title) {
  var result = text;
  result = result.replaceAll(
    '多选时不能只凭一个关键词选答案，要逐项核对题干限定的对象和边界。',
    '在「$title」中，多选时不能只凭一个关键词选答案，要逐项核对题干限定的对象和边界。',
  );
  result = result.replaceAll(
    '本课先建立概念，再解释运行机制，随后进入代码与工程实践，最后处理失败路径。',
    '「$title」先建立概念，再解释运行机制，随后进入代码与工程实践，最后处理失败路径。',
  );
  result = result.replaceAll(
    '如果把后一步放到前面，通常会缺少前一步产生的定义、输入或验证结果。',
    '在「$title」里，如果把后一步放到前面，通常会缺少前一步产生的定义、输入或验证结果。',
  );
  result = result.replaceAll(
    '这段代码来自本课示例，判断时先看输入与输出，再检查条件、循环和边界。',
    '这段代码来自「$title」的示例，判断时先看输入与输出，再检查条件、循环和边界。',
  );
  result = result.replaceAll(
    '如果只改一个条件，输出通常会随之改变，因此不能脱离代码前提作答。',
    '在「$title」中，如果只改一个条件，输出通常会随之改变，因此不能脱离代码前提作答。',
  );
  result = result.replaceAll('正确顺序是：', '在「$title」中，正确顺序是：');
  return result;
}
