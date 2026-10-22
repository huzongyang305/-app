// 学习支架精确校验工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_scaffold_guard.dart
//
// 修正两类常见偏差：
//   1. 只有“任务/挑战”等字样、但没有真正练习章节的课程，补一节标准动手练习；
//   2. 旧的 `## 小结` 统一改名为 `## 本课小结`。
import 'dart:convert';
import 'dart:io';

import 'apply_learning_scaffold.dart' show categoryTasks;

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- exercise-guard:v1 -->';

final RegExp exactPractice = RegExp(r'^## 动手练习\s*$', multiLine: true);
final RegExp exactSummary = RegExp(r'^## 本课小结\s*$', multiLine: true);

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();

  var practiceAdded = 0;
  var summaryRenamed = 0;
  var summaryAdded = 0;
  final errors = <String>[];

  for (final rawCategory in categories) {
    final category = rawCategory.cast<String, dynamic>();
    final categoryId = category['id'] as String;
    final categoryTitle =
        ((category['title'] as Map)['zh'] as String? ?? categoryId);
    for (final rawLesson in (category['lessons'] as List)) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'] as String;
      final file = File(lesson['file'] as String);
      if (!file.existsSync()) {
        errors.add('$id：文件不存在');
        continue;
      }

      var content = await file.readAsString();
      var changed = false;

      if (exactSummary.hasMatch(content)) {
        // 已统一，无需处理。
      } else if (RegExp(r'^## 小结\s*$', multiLine: true).hasMatch(content)) {
        content = content.replaceFirst(
          RegExp(r'^## 小结\s*$', multiLine: true),
          '## 本课小结',
        );
        summaryRenamed++;
        changed = true;
      } else {
        final title = ((lesson['title'] as Map)['zh'] as String? ?? id);
        final keywords =
            (lesson['keywords'] as List?)
                ?.map((item) => item.toString())
                .take(3)
                .join('、') ??
            title;
        content =
            '${content.trimRight()}\n\n'
            '## 本课小结\n\n'
            '- 能用自己的话解释「$title」解决的核心问题。\n'
            '- 能区分 $keywords 的职责和适用边界。\n'
            '- 能完成练习并说出一个失败场景或反例。\n';
        summaryAdded++;
        changed = true;
      }

      if (!exactPractice.hasMatch(content) && !content.contains(marker)) {
        final title = ((lesson['title'] as Map)['zh'] as String? ?? id);
        final keywords =
            (lesson['keywords'] as List?)
                ?.map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList() ??
            <String>[];
        final primary = keywords.isNotEmpty ? keywords.first : title;
        final secondary = keywords.length > 1 ? keywords[1] : categoryTitle;
        final transferTask =
            categoryTasks[categoryId] ?? '把本课方法用到一个真实小任务并留下可检查的结果。';
        content =
            '${content.trimRight()}\n\n'
            '$marker\n\n'
            '## 动手练习\n\n'
            '### 练习 1：概念复述（10 分钟）\n\n'
            '合上教程，用 3～5 句话解释「$title」解决什么问题，并写出一个边界条件。\n\n'
            '**验收标准**：至少使用一个本课关键词，并给出一个反例。\n\n'
            '### 练习 2：示例改写（20 分钟）\n\n'
            '从正文选一个最小示例，先预测修改一个输入后的结果，再实际验证并记录差异。\n\n'
            '**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。\n\n'
            '### 练习 3：迁移任务（30 分钟）\n\n'
            '$transferTask\n\n'
            '- 至少覆盖「$primary」和「$secondary」两个关键词。\n'
            '- 产出一个别人可以检查的结果。\n'
            '- 写出一个仍不确定的问题和验证方法。\n';
        practiceAdded++;
        changed = true;
      }

      if (changed && !dryRun) {
        await file.writeAsString(content, flush: true);
      }
    }
  }

  stdout.writeln(
    '${dryRun ? '待处理' : '已处理'}：补练习 $practiceAdded 篇，'
    '改名小结 $summaryRenamed 篇，新增小结 $summaryAdded 篇',
  );
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}
