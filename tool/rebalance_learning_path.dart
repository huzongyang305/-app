// P0 学习路径治理：修正先修关系、重建推荐顺序、校准预计用时。
//
// 用法：
//   dart tool/rebalance_learning_path.dart [--dry-run] [--only=edges|order|minutes]
//
// 三条不变量（口径见 docs/content_standard.md）：
//   1. 先修课的难度不得高于本课，否则先修边视为数据错误，直接删除；
//   2. 每个分类内按 order 排序后难度必须非递减，且先修课必须排在前面；
//   3. order 在分类内必须是连续的 0..n-1；
//   4. 预计用时必须等于 model 输出（tool/lesson_effort.dart）。
//
// 背景：历次内容扩容把「零基础入门块」追加到各分类，并给块内第一课挂了
// 该分类最后一课（往往是高级课）作为先修。结果是「Python 第一个脚本」要求
// 先学完「Python 打包、发布与性能」。这类边由脚本统一清理，难度标签只做
// 少量人工确认的上调（见 promotions）。
import 'dart:convert';
import 'dart:io';

import 'lesson_effort.dart';

const String manifestPath = 'assets/content/manifest.json';
const String _pathOrderVersionKey = 'path_order_version';
const String _minutesCalibrationVersionKey = 'minutes_calibration_version';

/// 人工确认的难度上调：课名与同级姊妹课不一致，或主题明显超出当前档位。
/// 上调后再删边，可以让真正合理的先修链（如 cpp_types ← cpp_basics）保留下来。
const Map<String, String> promotions = <String, String>{
  // 语言主干：与同语言的 *_basics 属于同一层，不应是「入门」。
  'cpp_types': '基础',
  'kotlin_functions': '基础',
  'swift_functions': '基础',
  'shell_flow': '基础',
  'rust_types_traits': '进阶',
  // 并发、微服务、工程实践需要先掌握语言主干。
  'go_concurrency': '基础',
  'go_project': '进阶',
  'go_microservice': '进阶',
  // 与同主题姊妹课对齐。
  'compiler_frontend': '进阶',
  // 核心机制课：索引、TCP/IP、机器学习与 OWASP 都不是「第一次接触」。
  'index': '基础',
  'tcp_ip': '基础',
  'ml_fundamentals': '基础',
  'security_owasp_top10': '基础',
  // 实战课依赖真实环境验证，与同类项目课同级。
  'project_devops_pipeline': '高级',
  'project_data_etl': '高级',
};

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final only = _stringOption(args, '--only=', '');
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到内容清单：$manifestPath');
    exitCode = 2;
    return;
  }
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final categories = (manifest['categories'] as List<dynamic>)
      .map((raw) => (raw as Map).cast<String, dynamic>())
      .toList();

  // 建立全局索引：id → 课程 Map，以及 id → 分类。
  final lessonsById = <String, Map<String, dynamic>>{};
  final categoryOf = <String, String>{};
  final markdownById = <String, String>{};
  for (final category in categories) {
    for (final raw in category['lessons'] as List<dynamic>) {
      final lesson = (raw as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      lessonsById[id] = lesson;
      categoryOf[id] = category['id'].toString();
      final file = File(lesson['file'].toString());
      if (file.existsSync()) {
        markdownById[id] = file.readAsStringSync();
      } else {
        stderr.writeln('找不到教程文件：${lesson['file']}');
        exitCode = 1;
      }
    }
  }

  // 一、难度上调：先按人工确认的清单调整，再处理先修边。
  var promoted = 0;
  if (only.isEmpty || only == 'edges') {
    for (final entry in promotions.entries) {
      final lesson = lessonsById[entry.key];
      if (lesson == null) continue;
      if (lesson['difficulty'] == entry.value) continue;
      lesson['difficulty'] = entry.value;
      promoted++;
    }
  }

  // 二、删除「先修比后修更难」的错误边。
  final droppedEdges = <String, List<String>>{};
  var dropped = 0;
  if (only.isEmpty || only == 'edges') {
    for (final lesson in lessonsById.values) {
      final prerequisites = _prerequisiteIds(lesson);
      if (prerequisites.isEmpty) continue;
      final rank = difficultyRank(lesson['difficulty'].toString());
      final kept = <String>[];
      for (final id in prerequisites) {
        final prerequisite = lessonsById[id];
        if (prerequisite == null ||
            difficultyRank(prerequisite['difficulty'].toString()) > rank) {
          dropped++;
          droppedEdges
              .putIfAbsent(
                categoryOf[lesson['id'].toString()]!,
                () => <String>[],
              )
              .add('${lesson['id']} ← $id');
          continue;
        }
        kept.add(id);
      }
      if (kept.length != prerequisites.length) {
        lesson['prerequisites'] = kept;
      }
    }
  }

  // 三、重建推荐顺序：稳定拓扑排序，优先排低难度课，先修永远在前面。
  var reordered = 0;
  var cycles = 0;
  if (only.isEmpty || only == 'order') {
    for (final category in categories) {
      final lessons = (category['lessons'] as List<dynamic>)
          .map((raw) => (raw as Map).cast<String, dynamic>())
          .toList();
      final current = <Map<String, dynamic>>[...lessons]
        ..sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));
      final indexOf = <String, int>{
        for (var i = 0; i < current.length; i++) current[i]['id'].toString(): i,
      };
      final placed = <String>{};
      final rebuilt = <Map<String, dynamic>>[];
      while (rebuilt.length < current.length) {
        Map<String, dynamic>? best;
        var bestKey = 0;
        for (final lesson in current) {
          final id = lesson['id'].toString();
          if (placed.contains(id)) continue;
          final pending = _prerequisiteIds(
            lesson,
          ).where((pre) => indexOf.containsKey(pre) && !placed.contains(pre));
          if (pending.isNotEmpty) continue;
          final key =
              difficultyRank(lesson['difficulty'].toString()) * 100000 +
              indexOf[id]!;
          if (best == null || key < bestKey) {
            best = lesson;
            bestKey = key;
          }
        }
        if (best == null) {
          // 先修成环时退化为「按难度、原顺序」取第一个未排课程，并记录。
          cycles++;
          best = current.firstWhere(
            (lesson) => !placed.contains(lesson['id'].toString()),
          );
        }
        placed.add(best['id'].toString());
        rebuilt.add(best);
      }
      var changed = false;
      for (var i = 0; i < rebuilt.length; i++) {
        if (rebuilt[i]['order'] != i) {
          rebuilt[i]['order'] = i;
          changed = true;
        }
      }
      if (changed) {
        reordered++;
        category['lessons'] = rebuilt;
      }
    }
  }

  // 四、校准预计用时：正文量度 → 分钟，并同步正文标注。
  var minutesChanged = 0;
  if (only.isEmpty || only == 'minutes') {
    for (final entry in lessonsById.entries) {
      final lesson = entry.value;
      final markdown = markdownById[entry.key];
      if (markdown == null) continue;
      final quiz = (lesson['quiz'] as List<dynamic>?) ?? const <dynamic>[];
      final title = ((lesson['title'] as Map?)?['zh'] ?? '').toString();
      final effort = measureEffort(
        markdown,
        quizCount: quiz.length,
        handsOn: isHandsOnLesson(id: entry.key, title: title),
      );
      final minutes = estimateMinutes(effort);
      if (lesson['minutes'] == minutes) continue;
      lesson['minutes'] = minutes;
      minutesChanged++;
    }
  }

  // 五、写回：manifest + 正文的「学习阶段」「预计用时」行。
  var syncedFiles = 0;
  if (!dryRun) {
    for (final entry in lessonsById.entries) {
      final lesson = entry.value;
      final cached = markdownById[entry.key];
      if (cached == null) continue;
      final file = File(lesson['file'].toString());
      final difficulty = lesson['difficulty'].toString();
      final minutes = lesson['minutes'].toString();
      var updated = cached.replaceAllMapped(
        RegExp(r'学习阶段：[^\s·]+'),
        (match) => '学习阶段：$difficulty',
      );
      updated = updated.replaceAllMapped(
        RegExp(r'预计用时：\d+\s*分钟'),
        (match) => '预计用时：$minutes 分钟',
      );
      // 旧课程的头部只有更新时间，补齐「学习阶段 + 预计用时」，
      // 让 542 篇课程的头部元数据格式保持一致。
      if (!updated.contains('预计用时')) {
        updated = updated.replaceFirstMapped(
          RegExp(r'^> 内容更新时间：(\d{4}-\d{2}-\d{2})[^\n]*$', multiLine: true),
          (match) =>
              '> 内容更新时间：${match.group(1)} · '
              '学习阶段：$difficulty · 预计用时：$minutes 分钟',
        );
      }
      if (updated != cached) {
        file.writeAsStringSync(updated, flush: true);
        syncedFiles++;
      }
    }
    manifest[_pathOrderVersionKey] = 1;
    manifest[_minutesCalibrationVersionKey] = 1;
    manifestFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      flush: true,
    );
  }

  final report = verifyManifest(manifest, markdownById);
  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}难度上调 $promoted 篇，'
    '删除错误先修边 $dropped 条，重建顺序 $reordered 个分类，'
    '校准时长 $minutesChanged 篇，同步正文 $syncedFiles 个',
  );
  if (cycles > 0) stdout.writeln('先修成环退化的分类：$cycles 个');
  if (droppedEdges.isNotEmpty) {
    stdout.writeln('删除的先修边（按分类）：');
    for (final entry in droppedEdges.entries) {
      stdout.writeln('  ${entry.key}：${entry.value.length} 条');
    }
  }
  stdout.writeln(
    '校验：难度倒挂 ${report['inversions']} 处，'
    '先修倒挂 ${report['prerequisiteViolations']} 条，'
    'order 不连续 ${report['orderGaps']} 个分类，'
    '时长偏差 ${report['minutesDrift']} 篇',
  );
  // 部分执行（--only）与 dry-run 不改变文件，校验结果只作参考。
  if (!dryRun && only.isEmpty && report.values.any((value) => value != 0)) {
    exitCode = 1;
  }
}

/// 校验四条不变量，返回各类缺陷数量。
Map<String, int> verifyManifest(
  Map<String, dynamic> manifest,
  Map<String, String> markdownById,
) {
  final categories = (manifest['categories'] as List<dynamic>)
      .map((raw) => (raw as Map).cast<String, dynamic>())
      .toList();
  final lessonsById = <String, Map<String, dynamic>>{};
  for (final category in categories) {
    for (final raw in category['lessons'] as List<dynamic>) {
      final lesson = (raw as Map).cast<String, dynamic>();
      lessonsById[lesson['id'].toString()] = lesson;
    }
  }
  var inversions = 0;
  var prerequisiteViolations = 0;
  var orderGaps = 0;
  for (final category in categories) {
    final ordered =
        (category['lessons'] as List<dynamic>)
            .map((raw) => (raw as Map).cast<String, dynamic>())
            .toList()
          ..sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));
    final position = <String, int>{
      for (var i = 0; i < ordered.length; i++) ordered[i]['id'].toString(): i,
    };
    for (var i = 1; i < ordered.length; i++) {
      if (difficultyRank(ordered[i]['difficulty'].toString()) <
          difficultyRank(ordered[i - 1]['difficulty'].toString())) {
        inversions++;
      }
    }
    final orders = ordered.map(_orderOf).toList()..sort();
    for (var i = 0; i < orders.length; i++) {
      if (orders[i] != i) {
        orderGaps++;
        break;
      }
    }
    for (final lesson in ordered) {
      for (final id in _prerequisiteIds(lesson)) {
        final prerequisite = lessonsById[id];
        if (prerequisite == null) continue;
        final prePosition = position[id];
        if (prePosition != null &&
            prePosition >= position[lesson['id'].toString()]!) {
          prerequisiteViolations++;
        }
        if (difficultyRank(prerequisite['difficulty'].toString()) >
            difficultyRank(lesson['difficulty'].toString())) {
          prerequisiteViolations++;
        }
      }
    }
  }
  return <String, int>{
    'inversions': inversions,
    'prerequisiteViolations': prerequisiteViolations,
    'orderGaps': orderGaps,
    'minutesDrift': _minutesDrift(manifest, markdownById),
  };
}

/// 预计用时与模型输出不一致的课程数量。
int _minutesDrift(
  Map<String, dynamic> manifest,
  Map<String, String> markdownById,
) {
  var drift = 0;
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final raw in category['lessons'] as List<dynamic>) {
      final lesson = (raw as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      final markdown = markdownById[id];
      if (markdown == null) continue;
      final quiz = (lesson['quiz'] as List<dynamic>?) ?? const <dynamic>[];
      final title = ((lesson['title'] as Map?)?['zh'] ?? '').toString();
      final effort = measureEffort(
        markdown,
        quizCount: quiz.length,
        handsOn: isHandsOnLesson(id: id, title: title),
      );
      if (lesson['minutes'] != estimateMinutes(effort)) drift++;
    }
  }
  return drift;
}

List<String> _prerequisiteIds(Map<String, dynamic> lesson) {
  final raw = lesson['prerequisites'];
  if (raw is! List) return const <String>[];
  return raw
      .map((item) => item is Map ? item['id'].toString() : item.toString())
      .where((id) => id.isNotEmpty)
      .toList();
}

int _orderOf(Map<String, dynamic> lesson) {
  final raw = lesson['order'];
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

String _stringOption(List<String> args, String prefix, String fallback) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    return arg.substring(prefix.length);
  }
  return fallback;
}
