// 薄课专题深化工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_deep_dive.dart tool/deep_dive_batches
//
// 批次 JSON 以知识点 id 为键，值包含 core / flow / facts / contrast /
// example / pitfalls / scenario / selfTest / miniProject / boundary / checklist。
// 内容会追加到对应教程末尾，并用 `<!-- deep-dive:v1 -->` 做幂等标记。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- deep-dive:v1 -->';

Future<void> main(List<String> args) async {
  final paths = args.where((item) => !item.startsWith('--')).toList();
  if (paths.isEmpty) {
    stderr.writeln('请传入深化批次目录或 JSON 文件');
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
  files.sort((a, b) => a.path.compareTo(b.path));

  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  final lessons = <String, Map<String, dynamic>>{};
  for (final rawCategory in manifest['categories'] as List) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      lessons[lesson['id'] as String] = lesson;
    }
  }

  var appended = 0;
  var skipped = 0;
  final errors = <String>[];

  for (final file in files) {
    final batch = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    for (final entry in batch.entries) {
      final id = entry.key;
      final profile = (entry.value as Map).cast<String, dynamic>();
      final lesson = lessons[id];
      if (lesson == null) {
        errors.add('${file.path}：知识点 $id 不存在');
        continue;
      }

      final target = File(lesson['file'] as String);
      if (!target.existsSync()) {
        errors.add('${file.path}：$id 的教程文件不存在');
        continue;
      }
      final original = await target.readAsString();
      if (original.contains(marker)) {
        skipped++;
        continue;
      }

      try {
        final block = _render(id, lesson, profile);
        if (block.length < 1600) {
          errors.add('${file.path}：$id 生成内容过短（${block.length} 字符）');
          continue;
        }
        await target.writeAsString(
          '${original.trimRight()}\n\n$block\n',
          flush: true,
        );
        appended++;
      } on FormatException catch (error) {
        errors.add('${file.path}：$id 字段错误（${error.message}）');
      }
    }
  }

  stdout.writeln('已深化：$appended 篇，已存在跳过：$skipped 篇');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(60)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}

String _render(
  String id,
  Map<String, dynamic> lesson,
  Map<String, dynamic> profile,
) {
  final title = ((lesson['title'] as Map)['zh'] as String? ?? id).trim();
  final core = _requiredString(profile, 'core');
  final flow = _requiredString(profile, 'flow');
  final facts = _requiredStrings(profile, 'facts', minimum: 5);
  final contrast = _requiredRows(profile, 'contrast', columns: 3, minimum: 4);
  final example = _requiredString(profile, 'example');
  final pitfalls = _requiredRows(profile, 'pitfalls', columns: 3, minimum: 4);
  final scenario = _requiredString(profile, 'scenario');
  final selfTest = _requiredRows(profile, 'selfTest', columns: 2, minimum: 4);
  final miniProject = _requiredString(profile, 'miniProject');
  final boundary = _requiredString(profile, 'boundary');
  final checklist = _requiredStrings(
    profile,
    'checklist',
    minimum: 5,
    minimumLength: 6,
  );

  final buffer = StringBuffer()
    ..writeln(marker)
    ..writeln()
    ..writeln('## 深入补充：$title')
    ..writeln()
    ..writeln('前面已经建立了基本概念。这一节换一个角度，把「$title」放进真实工程里，')
    ..writeln('重点回答三件事：它为什么存在、内部如何运转、什么时候会失效。')
    ..writeln()
    ..writeln('### 一、核心模型')
    ..writeln()
    ..writeln(core)
    ..writeln()
    ..writeln('```text')
    ..writeln(flow)
    ..writeln('```')
    ..writeln()
    ..writeln('### 二、关键机制拆解')
    ..writeln();

  for (var index = 0; index < facts.length; index++) {
    buffer.writeln('${index + 1}. ${facts[index]}');
  }

  buffer
    ..writeln()
    ..writeln('### 三、对照表：抓住容易混淆的边界')
    ..writeln()
    ..writeln('| 维度 | 一侧 | 另一侧 |')
    ..writeln('| --- | --- | --- |');
  for (final row in contrast) {
    buffer.writeln('| ${row[0]} | ${row[1]} | ${row[2]} |');
  }

  buffer
    ..writeln()
    ..writeln('### 四、工作示例')
    ..writeln()
    ..writeln(example)
    ..writeln()
    ..writeln('### 五、常见误区与失效边界')
    ..writeln()
    ..writeln('| 错误做法或假设 | 后果 | 正确做法 |')
    ..writeln('| --- | --- | --- |');
  for (final row in pitfalls) {
    buffer.writeln('| ${row[0]} | ${row[1]} | ${row[2]} |');
  }

  buffer
    ..writeln()
    ..writeln('### 六、场景推演')
    ..writeln()
    ..writeln(scenario)
    ..writeln()
    ..writeln('### 七、自测问答')
    ..writeln();
  for (var index = 0; index < selfTest.length; index++) {
    buffer
      ..writeln('**Q${index + 1}：${selfTest[index][0]}**')
      ..writeln()
      ..writeln(selfTest[index][1])
      ..writeln();
  }

  buffer
    ..writeln('### 八、小项目：把知识变成可检查的产出')
    ..writeln()
    ..writeln(miniProject)
    ..writeln()
    ..writeln('### 九、适用边界')
    ..writeln()
    ..writeln(boundary)
    ..writeln()
    ..writeln('### 十、完成检查清单')
    ..writeln();
  for (final item in checklist) {
    buffer.writeln('- [ ] $item');
  }
  buffer
    ..writeln()
    ..writeln('### 十一、复习顺序')
    ..writeln()
    ..writeln('1. 先不看资料复述“核心模型”，确认能说出它解决的三个问题。')
    ..writeln('2. 再对照表逐行解释容易混淆的概念，每个概念补一个反例。')
    ..writeln('3. 跟着工作示例做一遍，改变一个条件并预测结果。')
    ..writeln('4. 用自测问答检查理解，错题回到对应小节重新阅读。')
    ..writeln('5. 最后完成小项目，把结果、失败记录和复查清单整理成一份可提交产物。')
    ..writeln()
    ..writeln('> 复习不是重读一遍，而是离开原文重新产出：复述、改写、验证、复盘。');
  return buffer.toString().trimRight();
}

String _requiredString(Map<String, dynamic> profile, String key) {
  final value = profile[key] as String? ?? '';
  if (value.trim().length < 40) {
    throw FormatException('$key 内容过短');
  }
  return value.trim();
}

List<String> _requiredStrings(
  Map<String, dynamic> profile,
  String key, {
  required int minimum,
  int minimumLength = 20,
}) {
  final raw = profile[key] as List?;
  if (raw == null || raw.length < minimum) {
    throw FormatException('$key 至少需要 $minimum 项');
  }
  final values = raw.map((item) => item.toString().trim()).toList();
  if (values.any((item) => item.length < minimumLength)) {
    throw FormatException('$key 存在过短条目');
  }
  return values;
}

List<List<String>> _requiredRows(
  Map<String, dynamic> profile,
  String key, {
  required int columns,
  required int minimum,
}) {
  final raw = profile[key] as List?;
  if (raw == null || raw.length < minimum) {
    throw FormatException('$key 至少需要 $minimum 行');
  }
  return raw.map((item) {
    final row = (item as List).map((cell) => cell.toString().trim()).toList();
    if (row.length != columns || row.any((cell) => cell.isEmpty)) {
      throw FormatException('$key 的每行需要 $columns 个非空字段');
    }
    return row;
  }).toList();
}
