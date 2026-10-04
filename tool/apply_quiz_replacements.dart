// 测验题目替换工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_quiz_replacements.dart tool/quiz_fix_batches
//
// 批次格式：{ "lesson_id#题号": { question, options, answer, explanation, type?, code? } }
// 用于去除重复题，并补充代码输出、排错、排序、填空等题型。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const Set<String> allowedTypes = {
  'single',
  'code',
  'debug',
  'order',
  'fill',
  'multi',
};

Future<void> main(List<String> args) async {
  final paths = args.where((item) => !item.startsWith('--')).toList();
  if (paths.isEmpty) {
    stderr.writeln('请传入批次目录或 JSON 文件');
    exitCode = 1;
    return;
  }

  final files = <File>[];
  for (final path in paths) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.directory) {
      files.addAll(
        Directory(path)
            .listSync()
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.json')),
      );
    } else {
      files.add(File(path));
    }
  }

  final manifestFile = File(manifestPath);
  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final lessons = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessons[lesson['id'] as String] = lesson;
    }
  }

  final errors = <String>[];
  var replaced = 0;

  for (final file in files) {
    final batch = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    for (final entry in batch.entries) {
      final parts = entry.key.split('#');
      if (parts.length != 2) {
        errors.add('${file.path}：键「${entry.key}」格式错误');
        continue;
      }
      final lesson = lessons[parts[0]];
      final index = int.tryParse(parts[1]);
      if (lesson == null || index == null) {
        errors.add('${file.path}：${entry.key} 知识点或题号不存在');
        continue;
      }
      final quiz = (lesson['quiz'] as List).cast<Map<String, dynamic>>();
      if (index < 0 || index >= quiz.length) {
        errors.add('${file.path}：${entry.key} 题号越界（共 ${quiz.length} 题）');
        continue;
      }

      final replacement = (entry.value as Map).cast<String, dynamic>();
      final question = (replacement['question'] as String? ?? '').trim();
      final options =
          (replacement['options'] as List?)
              ?.map((item) => item.toString().trim())
              .toList() ??
          <String>[];
      final answer = replacement['answer'];
      final explanation = (replacement['explanation'] as String? ?? '').trim();
      final type = replacement['type'] as String? ?? 'single';
      final code = replacement['code'] as String?;

      if (question.length < 8) {
        errors.add('${file.path}：${entry.key} 题干过短');
        continue;
      }
      if (options.length < 3 || options.length > 5) {
        errors.add('${file.path}：${entry.key} 选项数必须为 3~5');
        continue;
      }
      if (answer is! int || answer < 0 || answer >= options.length) {
        errors.add('${file.path}：${entry.key} answer 下标非法');
        continue;
      }
      if (explanation.length < 80) {
        errors.add('${file.path}：${entry.key} 解析少于 80 字符');
        continue;
      }
      if (!allowedTypes.contains(type)) {
        errors.add('${file.path}：${entry.key} 题型 $type 不支持');
        continue;
      }
      if (code != null && code.trim().length < 10) {
        errors.add('${file.path}：${entry.key} 代码片段过短');
        continue;
      }

      quiz[index] = {
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
        'type': type,
        if (code != null) 'code': code.trim(),
      };
      replaced++;
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('校验失败，未写入：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  await manifestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
    flush: true,
  );
  stdout.writeln('已替换 $replaced 道题');
}
