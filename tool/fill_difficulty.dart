// 难度补齐工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/fill_difficulty.dart [--dry-run]
//
// 背景：
//   部分知识点在 manifest.json 中缺少 difficulty 字段，导致界面上的难度标签、
//   学习路径排序与测验组卷的难度配额都无法生效。本工具按下面的规则补齐：
//
//   1. 标题含「实战 / 项目 / 从零 / 完整」→ 高级
//   2. 标题含「入门 / 基础 / 是什么 / 简介 / 概览 / 第一」→ 入门
//   3. 标题含「性能 / 优化 / 深入 / 原理 / 底层 / 架构 / 并发 / 一致性 /
//      安全 / 分布式 / 调优 / 剖析」→ 进阶
//   4. 其余按该知识点在所属分类中的相对位置划分：
//        前 25% → 入门，25%~55% → 基础，55%~85% → 进阶，其余 → 高级
//
// 幂等：已有 difficulty 的知识点不会被改动，可反复执行。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';

/// 允许的难度取值，超出范围的取值会被视为无效并重新推断。
const List<String> validLevels = <String>['入门', '基础', '进阶', '高级'];

final RegExp advancedPattern = RegExp(r'实战|项目|从零|完整|高级');
final RegExp beginnerPattern = RegExp(r'入门|基础|是什么|简介|概览|第一');
final RegExp intermediatePattern = RegExp(
  r'进阶|性能|优化|深入|原理|底层|架构|并发|一致性|安全|分布式|调优|剖析',
);

String inferDifficulty(String title, int index, int total) {
  if (advancedPattern.hasMatch(title)) return '高级';
  if (beginnerPattern.hasMatch(title)) return '入门';
  if (intermediatePattern.hasMatch(title)) return '进阶';

  final double ratio = total <= 1 ? 0.0 : index / (total - 1);
  if (ratio < 0.25) return '入门';
  if (ratio < 0.55) return '基础';
  if (ratio < 0.85) return '进阶';
  return '高级';
}

Future<void> main(List<String> args) async {
  final bool dryRun = args.contains('--dry-run');
  final File file = File(manifestPath);
  final Map<String, dynamic> manifest =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;

  final counts = <String, int>{for (final level in validLevels) level: 0};
  final changed = <String>[];

  for (final rawCategory in manifest['categories'] as List) {
    final Map<String, dynamic> category = (rawCategory as Map)
        .cast<String, dynamic>();
    final List<dynamic> lessons = category['lessons'] as List;
    final String categoryId = category['id'] as String;

    for (int index = 0; index < lessons.length; index++) {
      final Map<String, dynamic> lesson = (lessons[index] as Map)
          .cast<String, dynamic>();
      final String current = (lesson['difficulty'] as String? ?? '').trim();

      if (validLevels.contains(current)) {
        counts[current] = counts[current]! + 1;
        continue;
      }

      final String title = ((lesson['title'] as Map)['zh'] as String? ?? '')
          .trim();
      final String inferred = inferDifficulty(title, index, lessons.length);
      lesson['difficulty'] = inferred;
      counts[inferred] = counts[inferred]! + 1;
      changed.add('$categoryId/${lesson['id']} → $inferred（$title）');
    }
  }

  stdout.writeln(
    '补齐 ${changed.length} 条难度：'
    '入门 ${counts['入门']}，基础 ${counts['基础']}，'
    '进阶 ${counts['进阶']}，高级 ${counts['高级']}',
  );
  final bool verbose = args.contains('--verbose');
  final int preview = verbose ? changed.length : 12;
  for (final line in changed.take(preview)) {
    stdout.writeln('  · $line');
  }
  if (changed.length > preview) {
    stdout.writeln('  · …其余 ${changed.length - preview} 条');
  }

  if (dryRun) {
    stdout.writeln('（dry-run，未写入文件）');
    return;
  }
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  stdout.writeln('已写入 $manifestPath');
}
