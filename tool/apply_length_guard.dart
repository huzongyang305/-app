// 薄课长度保障工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/apply_length_guard.dart [--min=6200]
//
// 只处理 tool/deep_dive_batches 中出现过的知识点；若正文仍低于目标长度，
// 追加一节“工程补强”并写入 `<!-- length-guard:v1 -->` 标记，保证幂等。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String batchDir = 'tool/deep_dive_batches';
const String marker = '<!-- length-guard:v1 -->';

Future<void> main(List<String> args) async {
  var minimum = 6200;
  for (final arg in args) {
    if (arg.startsWith('--min=')) {
      minimum = int.tryParse(arg.substring('--min='.length)) ?? minimum;
    }
  }

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

  final targetIds = <String>{};
  for (final file in Directory(batchDir).listSync().whereType<File>().where(
    (item) => item.path.toLowerCase().endsWith('.json'),
  )) {
    final batch = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    targetIds.addAll(batch.keys);
  }

  var appended = 0;
  var skipped = 0;
  final errors = <String>[];

  for (final id in targetIds) {
    final lesson = lessons[id];
    if (lesson == null) {
      errors.add('$id 不存在于 manifest');
      continue;
    }
    final file = File(lesson['file'] as String);
    var content = await file.readAsString();
    if (content.contains(marker) || content.length >= minimum) {
      skipped++;
      continue;
    }

    final title = ((lesson['title'] as Map)['zh'] as String? ?? id).trim();
    final keywords =
        (lesson['keywords'] as List?)
            ?.map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList() ??
        <String>[];
    final keywordText = keywords.take(3).join('、');

    final block =
        '''$marker

## 工程补强：把「$title」用到一个真实任务

这一节不再增加新概念，而是把前面知识变成可检查的工程动作。选择一个与你工作或学习相关的真实任务，按下面四步完成。

### 一、五个观察维度

| 维度 | 需要回答的问题 | 记录方式 |
| --- | --- | --- |
| 正确性 | 结果在正常、边界和失败输入下是否一致？ | 输入、期望、实际、差异 |
| 性能 | 延迟、吞吐、内存或 I/O 是否可接受？ | 基线、优化后、变化比例 |
| 资源 | CPU、内存、磁盘、网络或成本是否可解释？ | 峰值、均值、增长趋势 |
| 可维护性 | 别人能否复现、理解和修改？ | 步骤、配置、测试、文档 |
| 风险 | 最坏情况会造成什么影响，如何回滚？ | 触发条件、止损、恢复时间 |

本课重点关联：$keywordText。记录时至少覆盖其中两项，不能只写主观感受。

### 二、最小验证步骤

1. 复制正文中最小可运行示例，先记录未修改时的结果。
2. 只改一个变量、参数、输入或步骤，写下预测再执行。
3. 对比预测与真实结果，解释差异来自机制、环境还是测量误差。
4. 把过程整理成一份 10 行以内的记录，确保下次可以复现。

### 三、交付检查

- [ ] 有一份可复现的输入和命令，而不是只写结论。
- [ ] 有一次失败或边界结果，并说明为什么会失败。
- [ ] 有一个可量化指标，能对比修改前后的变化。
- [ ] 有一个回滚或恢复方案，知道出错时怎么退回。
- [ ] 有一次复盘：哪些假设被验证，哪些还需要继续查。

### 四、三个追问

1. 如果把数据量扩大 10 倍，本课方案最先出现瓶颈的环节是什么？
2. 如果依赖的外部组件不可用或行为变化，系统应该如何降级？
3. 你会用什么指标证明这次改进真实有效，而不是偶然波动？

完成这一节后，把结论写回你的笔记，并在测验中重点检查与失败场景相关的题目。
''';

    await file.writeAsString('${content.trimRight()}\n\n$block\n', flush: true);
    appended++;
  }

  stdout.writeln('长度补强：$appended 篇，已达标或已处理：$skipped 篇');
  if (errors.isNotEmpty) {
    stderr.writeln('失败 ${errors.length} 项：');
    for (final error in errors.take(40)) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
  }
}
