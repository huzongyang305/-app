// 学习支架批量补全工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_learning_scaffold.dart [--dry-run]
//
// 作用：为 manifest.json 中的每篇教程补齐缺失的
//   学习目标 / 前置知识 / 动手练习 / 本课小结 / 内容更新时间
// 已存在对应章节时不重复插入，并用 `<!-- scaffold:v1 -->` 做幂等标记。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String marker = '<!-- scaffold:v1 -->';
const String updatedAt = '2026-10-03';

final RegExp goalsPattern = RegExp(
  r'^##\s+.*(学习目标|本课目标|你将学会)',
  multiLine: true,
);
final RegExp prereqPattern = RegExp(r'^##\s+.*(前置|先修|准备知识)', multiLine: true);
final RegExp practicePattern = RegExp(
  r'^##\s+.*(动手练习|练习|任务|挑战|作业)',
  multiLine: true,
);
final RegExp summaryPattern = RegExp(r'^##\s+.*(小结|总结|回顾)', multiLine: true);

/// 不同课程方向使用不同的迁移任务，避免所有练习都变成“写一段代码”。
const Map<String, String> categoryTasks = <String, String>{
  'flutter': '创建一个最小 Widget，分别验证正常输入、空数据和超长文本三种状态。',
  'html_css': '做一个只有标题、卡片和按钮的最小页面，并用浏览器设备模式检查窄屏。',
  'python': '写一个 20 行以内的小脚本，把本课概念用于处理一份真实文本或列表数据。',
  'cpp': '写一个可独立编译的小程序，开启 `-Wall -Wextra`，确保没有警告。',
  'java': '写一个可运行的小类，补一个普通测试和一个边界输入测试。',
  'javascript': '在浏览器控制台或 Node.js 中写一个最小示例，列出至少 3 组输入输出。',
  'csharp': '写一个控制台小程序，补一个正例、一个边界值和一个异常路径。',
  'go': '写一个可运行的小程序，并用 `go test` 或 `go vet` 验证结果。',
  'rust': '写一个最小 Cargo 示例，先用 `cargo check`，再补一个边界测试。',
  'typescript': '写一个最小类型示例，先让 `tsc --noEmit` 通过，再故意制造一次类型错误。',
  'shell': '写一个带 `set -euo pipefail` 的脚本，并用临时目录验证成功与失败路径。',
  'algorithms': '给定 8～12 个手工构造的数据，写出每一步状态，并统计比较或交换次数。',
  'network': '画出一张报文或时序图，标出每一跳的地址、协议、状态和可能失败点。',
  'database': '在 SQLite 或纸面表结构上写查询，分别验证正常数据、空值和边界数据。',
  'os': '用伪代码或小脚本模拟一次调度、竞争或资源分配，并记录至少 5 个状态变化。',
  'fundamentals': '用表格、真值表或计算过程把抽象概念落到一个可核对的结果上。',
  'toolchain': '在一个临时目录或本地仓库执行完整命令链，并记录失败时的回滚办法。',
  'ai': '构造 5 条小型离线样例，写清输入、期望输出、评分标准和失败案例。',
  'distributed': '画出系统拓扑，设计一次节点宕机或网络延迟演练，并写出恢复步骤。',
  'software_engineering': '为一个真实小功能写一页设计、检查表或评审记录，并让同伴能照着执行。',
  'math': '先手算一个 3～4 步的小例子，再用 Python 或计算器验证结果。',
  'cross_language': '选两种语言实现同一行为，列出语法、错误处理、性能和生态差异。',
  'visual_guide': '不看原图手绘一遍流程，再用自己的话指出图中的关键状态变化。',
  'project_practice': '把一个真实小需求拆成任务、验收标准、风险与回滚步骤。',
};

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  final manifest = jsonDecode(
    await File(manifestPath).readAsString(),
  ) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List)
      .cast<Map<String, dynamic>>();

  var changed = 0;
  var skipped = 0;
  final errors = <String>[];

  for (final rawCategory in categories) {
    final category = rawCategory.cast<String, dynamic>();
    final categoryTitle =
        ((category['title'] as Map)['zh'] as String? ??
        category['id'] as String);
    final lessons = (category['lessons'] as List).cast<Map<String, dynamic>>();

    for (var index = 0; index < lessons.length; index++) {
      final lesson = lessons[index];
      final id = lesson['id'] as String;
      final file = File(lesson['file'] as String);
      if (!file.existsSync()) {
        errors.add('$id：文件不存在（${file.path}）');
        continue;
      }

      var content = await file.readAsString();
      if (content.contains(marker)) {
        skipped++;
        continue;
      }

      final title = ((lesson['title'] as Map)['zh'] as String? ?? id).trim();
      final summary = ((lesson['summary'] as Map)['zh'] as String? ?? '')
          .trim();
      final difficulty = (lesson['difficulty'] as String? ?? '基础').trim();
      final minutes = lesson['minutes'] as int? ?? 15;
      final keywords =
          (lesson['keywords'] as List?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList() ??
          <String>[];
      final previousTitle = index == 0
          ? ''
          : (((lessons[index - 1]['title'] as Map)['zh'] as String?) ?? '')
                .trim();

      final topSections = <String>[];
      if (!content.contains('内容更新时间')) {
        topSections.add(
          '> 内容更新时间：$updatedAt · 学习阶段：$difficulty · 预计用时：$minutes 分钟',
        );
      }
      if (!goalsPattern.hasMatch(content)) {
        topSections.add(_buildGoals(title, summary, keywords, categoryTitle));
      }
      if (!prereqPattern.hasMatch(content)) {
        topSections.add(
          _buildPrerequisite(
            title: title,
            difficulty: difficulty,
            previousTitle: previousTitle,
            keywords: keywords,
          ),
        );
      }

      if (topSections.isNotEmpty) {
        final heading = RegExp(
          r'^#\s+.+$',
          multiLine: true,
        ).firstMatch(content);
        if (heading == null) {
          errors.add('$id：缺少一级标题');
          continue;
        }
        content =
            '${content.substring(0, heading.end)}\n\n'
            '${topSections.join('\n\n')}\n'
            '${content.substring(heading.end)}';
      }

      final tailSections = <String>[];
      if (!practicePattern.hasMatch(content)) {
        tailSections.add(
          _buildPractice(
            title: title,
            categoryId: category['id'] as String,
            categoryTitle: categoryTitle,
            keywords: keywords,
          ),
        );
      }
      if (!summaryPattern.hasMatch(content)) {
        tailSections.add(_buildSummary(title, categoryTitle, keywords));
      }
      tailSections.add(marker);
      content = '${content.trimRight()}\n\n${tailSections.join('\n\n')}\n';

      if (!dryRun) {
        await file.writeAsString(content, flush: true);
      }
      changed++;
    }
  }

  stdout.writeln('${dryRun ? '待更新' : '已更新'}：$changed 篇，已存在跳过：$skipped 篇');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}

String _buildGoals(
  String title,
  String summary,
  List<String> keywords,
  String categoryTitle,
) {
  final keywordText = keywords.take(4).map((item) => '「$item」').join('、');
  return '''## 学习目标

- 能用自己的话解释「$title」解决了什么问题，而不是只背术语。
- 能说清 $keywordText 之间的关系，并分别举出一个例子。
- 能把本课知识放回「$categoryTitle」的知识体系，说明它和相邻主题的边界。
- 能完成本课练习，并用验收标准检查自己的结果。

> 一句话摘要：$summary''';
}

String _buildPrerequisite({
  required String title,
  required String difficulty,
  required String previousTitle,
  required List<String> keywords,
}) {
  final previous = previousTitle.isEmpty
      ? '会进行基本的文件、命令行或浏览器操作；遇到不熟悉的术语先查本课关键词。'
      : '先完成上一课《$previousTitle》；如果已经掌握，可以直接用本课练习自测。';
  final stage = switch (difficulty) {
    '入门' => '只需要基本计算机操作，不要求编程经验。',
    '基础' => '建议会读写简单代码或命令，并理解变量、输入输出等基本概念。',
    '进阶' => '建议先掌握同一分类的基础课程，并能独立运行正文中的最小示例。',
    _ => '建议具备同一方向的完整基础，能阅读较长的代码、配置或系统设计说明。',
  };
  final review = keywords.take(3).join('、');
  return '''## 前置知识

- $previous
- 本课阶段：$difficulty。$stage
- 开始前先复习：$review。
- 如果某一步看不懂，先记录具体卡点，完成练习后再回头读一遍。''';
}

String _buildPractice({
  required String title,
  required String categoryId,
  required String categoryTitle,
  required List<String> keywords,
}) {
  final primary = keywords.isNotEmpty ? keywords.first : title;
  final secondary = keywords.length > 1 ? keywords[1] : categoryTitle;
  final transferTask =
      categoryTasks[categoryId] ?? '把本课方法用到一个真实小任务上，并留下可检查的结果。';

  return '''## 动手练习

练习按「复述 → 改写 → 迁移」递进。不要只阅读，至少完成前两项。

### 练习 1：不看原文复述（10 分钟）

合上教程，用 3～5 句话回答：

1. 「$title」解决了什么问题？
2. 如果没有它，会出现什么具体后果？
3. 它和「$secondary」是什么关系？

**验收标准**：至少出现一个本课关键词，并写出一个反例、边界条件或失效场景。

### 练习 2：示例改写（20 分钟）

从正文中选一个最小示例，完成以下操作：

1. 先预测修改一个参数、输入或步骤后的结果。
2. 再实际执行或逐步推演，记录真实结果。
3. 如果结果与预测不同，写出差异原因。

**验收标准**：留下「原例 → 改动 → 预测 → 结果 → 原因」五步记录。

### 练习 3：迁移任务（30 分钟）

$transferTask

任务要求：

- 结果必须能被别人检查，不能只写“我已经理解了”。
- 至少覆盖「$primary」和「$secondary」两个关键词。
- 写出 1 个仍然不确定的问题，以及下一步如何验证。

> 提示：时间有限时优先做练习 1 和练习 2；练习 3 可以拆成两次完成。''';
}

String _buildSummary(
  String title,
  String categoryTitle,
  List<String> keywords,
) {
  final first = keywords.isNotEmpty ? keywords.first : title;
  final second = keywords.length > 1 ? keywords[1] : categoryTitle;
  final third = keywords.length > 2 ? keywords[2] : title;
  return '''## 本课小结

- 核心问题：「$title」不是孤立术语，而是在「$categoryTitle」中解决一类具体问题。
- 关键关系：先分清「$first」与「$second」的职责，再理解「$third」的适用边界。
- 判断标准：能解释正常场景、边界条件和失败场景，才算真正掌握。
- 下一步：完成练习后，用自己的话写下 3 条要点，再去做本课测验。''';
}
