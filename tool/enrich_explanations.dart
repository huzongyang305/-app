// 解析加厚工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/enrich_explanations.dart tool/explanation_batches/python.json [--dry-run]
//
// 批次文件格式（键为「知识点ID#题号」，题号从 0 开始）：
// {
//   "python_basics#0": "input() 返回字符串，需要用 int() 转换后才能参与算术；若输入非数字还会抛 ValueError。",
//   "python_basics#1": "Python 用缩进划分代码块，同一层级必须一致，混用 Tab 与空格会抛 TabError。"
// }
//
// 行为：
//   · 把文本追加到该题现有解析之后，前缀为「其他选项：」，形成
//     「正确原因 + 干扰项辨析」的两段式解析；
//   · 已包含该前缀的题目会被跳过，保证可反复执行（幂等）；
//   · 任一校验失败即整体中止，不写入文件。
//
// 校验项：
//   · 知识点存在、题号在范围内；
//   · 追加文本长度不少于 20 字（太短说明没写清干扰项）；
//   · 不与非「其他选项：」内容重复（避免重复追加同一段）。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '其他选项：';

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final paths = args.where((item) => !item.startsWith('--')).toList();
  if (paths.isEmpty) {
    stderr.writeln('请传入至少一个批次文件路径');
    exitCode = 1;
    return;
  }

  final file = File(manifestPath);
  final manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final lessons = <String, Map<String, dynamic>>{};
  for (final category in (manifest['categories'] as List)) {
    for (final lesson in ((category as Map)['lessons'] as List)) {
      final map = (lesson as Map).cast<String, dynamic>();
      lessons[map['id'] as String] = map;
    }
  }

  final errors = <String>[];
  var appended = 0;
  var skipped = 0;

  for (final path in paths) {
    final batch = jsonDecode(await File(path).readAsString());
    if (batch is! Map<String, dynamic>) {
      errors.add('$path：批次文件必须是 JSON 对象');
      continue;
    }

    for (final entry in batch.entries) {
      final parts = entry.key.split('#');
      if (parts.length != 2) {
        errors.add('$path：键「${entry.key}」格式应为 知识点ID#题号');
        continue;
      }
      final lesson = lessons[parts[0]];
      final index = int.tryParse(parts[1]);
      if (lesson == null) {
        errors.add('$path：知识点 ${parts[0]} 不存在');
        continue;
      }
      final quiz = (lesson['quiz'] as List).cast<Map<String, dynamic>>();
      if (index == null || index < 0 || index >= quiz.length) {
        errors.add('$path：${entry.key} 题号越界（共 ${quiz.length} 题）');
        continue;
      }

      final text = entry.value;
      if (text is! String || text.trim().length < 20) {
        errors.add('$path：${entry.key} 的补充内容过短或为空');
        continue;
      }

      final question = quiz[index];
      final explanation = (question['explanation'] as String? ?? '').trim();
      if (explanation.contains(marker)) {
        skipped++;
        continue;
      }
      if (explanation.contains(text.trim())) {
        skipped++;
        continue;
      }

      question['explanation'] = '$explanation\n$marker${text.trim()}';
      appended++;
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('校验失败，未写入任何改动：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    stderr.writeln('共 ${errors.length} 条问题');
    exitCode = 1;
    return;
  }

  stdout.writeln('已加厚 $appended 题，跳过（已加厚或其他）$skipped 题');
  if (dryRun) {
    stdout.writeln('（dry-run，未写入文件）');
    return;
  }
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  stdout.writeln('已写入 $manifestPath');
}
