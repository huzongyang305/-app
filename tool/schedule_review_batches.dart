// P0 复核排期：把 609 门课「下次复核」从同一天改成分批排期。
//
// 用法：
//   dart run tool/schedule_review_batches.dart [--dry-run]
//
// 输入：
//   docs/content_review_batches.json  （由 content_review_ledger.dart 生成）
//   assets/content/manifest.json
// 输出：
//   docs/content_review_schedule.md / .json
//   每门课「## 参考资料与复核」里的「- 下次复核：YYYY-MM-DD」
//
// 说明：本工具只调整排期，不登记人工复核结论；人工复核状态仍以
// docs/content_review_records.json 为准，未登记的课程保持 pending。
import 'dart:convert';
import 'dart:io';

const String manifestPath = 'assets/content/manifest.json';
const String batchPath = 'docs/content_review_batches.json';
const String scheduleMarkdownPath = 'docs/content_review_schedule.md';
const String scheduleJsonPath = 'docs/content_review_schedule.json';

/// 排期起始月份：内容最近一次整体复核是 2026-10-04，下一轮从 11 月开始。
const int firstMonthYear = 2026;
const int firstMonth = 11;

/// 整轮排期长度（月）。
const int scheduleMonths = 12;

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final manifest =
      jsonDecode(File(manifestPath).readAsStringSync()) as Map<String, dynamic>;
  final batches =
      jsonDecode(File(batchPath).readAsStringSync()) as Map<String, dynamic>;

  final lessonFileById = <String, String>{};
  final lessonTitleById = <String, String>{};
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final id = lesson['id'].toString();
      lessonFileById[id] = lesson['file'].toString();
      lessonTitleById[id] =
          ((lesson['title'] as Map?)?['zh'] ?? id).toString();
    }
  }

  final rawBatches = (batches['batches'] as List<dynamic>)
      .map((raw) => (raw as Map).cast<String, dynamic>())
      .toList();

  // 优先复核本轮改动过的课程：重写过错误表或新增过配图的课程。
  final priorityIds = <String>{};
  for (final entry in lessonFileById.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    if (content.contains('> 说明：本表由《') ||
        content.contains('](images/p0x_')) {
      priorityIds.add(entry.key);
    }
  }

  final ordered = [...rawBatches];
  ordered.sort((a, b) {
    int score(Map<String, dynamic> batch) {
      final lessons = batch['lessons'] as List<dynamic>;
      final touched = lessons
          .map((raw) => (raw as Map)['lesson_id'].toString())
          .where(priorityIds.contains)
          .length;
      final risk = batch['risk_high'] as int? ?? 0;
      final medium = batch['risk_medium'] as int? ?? 0;
      return touched * 100000 + risk * 1000 + medium * 10;
    }

    final byScore = score(b).compareTo(score(a));
    if (byScore != 0) return byScore;
    return a['batch_id'].toString().compareTo(b['batch_id'].toString());
  });

  final total = ordered.length;
  final schedule = <Map<String, dynamic>>[];
  var rewritten = 0;
  final missing = <String>[];
  for (var index = 0; index < total; index++) {
    final batch = ordered[index];
    final monthOffset = total <= 1 ? 0 : (index * scheduleMonths) ~/ total;
    final month = firstMonth - 1 + monthOffset;
    final year = firstMonthYear + month ~/ 12;
    final monthOfYear = month % 12 + 1;
    final day = 10 + (index % 3) * 7;
    final date =
        '$year-${monthOfYear.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
    final lessons = (batch['lessons'] as List<dynamic>)
        .map((raw) => (raw as Map).cast<String, dynamic>())
        .toList();
    final touched = lessons
        .where((lesson) => priorityIds.contains(lesson['lesson_id'].toString()))
        .length;
    schedule.add(<String, dynamic>{
      'batch_id': batch['batch_id'],
      'category_id': batch['category_id'],
      'category_title': batch['category_title'],
      'planned_review_at': date,
      'lesson_count': lessons.length,
      'p0_touched': touched,
      'risk_high': batch['risk_high'] ?? 0,
      'risk_medium': batch['risk_medium'] ?? 0,
      'lesson_ids': [
        for (final lesson in lessons) lesson['lesson_id'].toString(),
      ],
    });

    for (final lesson in lessons) {
      final id = lesson['lesson_id'].toString();
      final path = lessonFileById[id];
      if (path == null) {
        missing.add(id);
        continue;
      }
      final file = File(path);
      if (!file.existsSync()) {
        missing.add(id);
        continue;
      }
      final lines = file.readAsLinesSync();
      var changed = false;
      for (var line = 0; line < lines.length; line++) {
        if (!lines[line].startsWith('- 下次复核：')) continue;
        final updated = '- 下次复核：$date';
        if (lines[line] != updated) {
          lines[line] = updated;
          changed = true;
        }
      }
      if (changed) {
        rewritten++;
        if (!dryRun) file.writeAsStringSync('${lines.join('\n')}\n');
      }
    }
  }

  if (!dryRun) {
    File(scheduleJsonPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
            'generated_at': DateTime.now().toUtc().toIso8601String(),
            'schedule_months': scheduleMonths,
            'first_month': '$firstMonthYear-${firstMonth.toString().padLeft(2, '0')}',
            'batch_count': total,
            'p0_touched_lessons': priorityIds.length,
            'batches': schedule,
          })}\n',
    );
    File(scheduleMarkdownPath).writeAsStringSync(_renderMarkdown(schedule, priorityIds.length));
  }

  stdout.writeln(
    '${dryRun ? '[dry-run] ' : ''}排期批次 $total 个，'
    '改写课程 $rewritten 门，本轮优先复核课程 ${priorityIds.length} 门',
  );
  if (missing.isNotEmpty) {
    stderr.writeln('以下课程在清单中找不到文件：${missing.join('、')}');
  }
}

String _renderMarkdown(
  List<Map<String, dynamic>> schedule,
  int priorityCount,
) {
  final buffer = StringBuffer()
    ..writeln('# 人工复核排期表')
    ..writeln()
    ..writeln(
      '- 生成时间：${DateTime.now().toUtc().toIso8601String()}',
    )
    ..writeln('- 排期长度：$scheduleMonths 个月，每批 24 门课')
    ..writeln('- 本轮优先复核课程：$priorityCount 门（重写过错误表或新增过配图）')
    ..writeln()
    ..writeln(
      '> 排期只表示计划时间，不代表已经完成复核。人工复核结果请登记到 '
      '`docs/content_review_records.json`。',
    )
    ..writeln()
    ..writeln('| 批次 | 分类 | 计划复核 | 课程数 | 本轮改动 | 高风险 |')
    ..writeln('| --- | --- | --- | ---: | ---: | ---: |');
  for (final batch in schedule) {
    buffer.writeln(
      '| ${batch['batch_id']} | ${batch['category_title']} | '
      '${batch['planned_review_at']} | ${batch['lesson_count']} | '
      '${batch['p0_touched']} | ${batch['risk_high']} |',
    );
  }
  return buffer.toString();
}
