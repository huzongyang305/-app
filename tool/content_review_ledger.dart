// 生成内容审核台账：把「机器校验通过」与「人工复核状态」分开记录。
//
// 用法：
//   dart run tool/content_review_ledger.dart
//   dart run tool/content_review_ledger.dart --fail-on-pending
//
// 输出 docs/content_review_ledger.md 与 docs/content_review_ledger.json。
// 台账不会伪造审核人：没有人工复核记录的课程一律标记为 pending。
import 'dart:convert';
import 'dart:io';

const String defaultManifest = 'assets/content/manifest.json';
const String defaultMarkdownDir = 'assets/content';
const String defaultDocPath = 'docs/content_review_ledger.md';
const String defaultJsonPath = 'docs/content_review_ledger.json';

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final manifestFile = File(options['manifest'] ?? defaultManifest);
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到内容清单：${manifestFile.path}');
    exitCode = 2;
    return;
  }
  final manifest =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final markdownDir = options['content-dir'] ?? defaultMarkdownDir;
  final entries = <_LedgerEntry>[];
  for (final rawCategory in (manifest['categories'] as List? ?? const [])) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    for (final rawLesson in (category['lessons'] as List? ?? const [])) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final relative = lesson['file']?.toString() ?? '';
      // manifest 里的 file 可能是完整资产路径（assets/content/x.md），
      // 也可能是相对文件名，两种写法都要兼容。
      final path = relative.startsWith('assets/')
          ? relative
          : '$markdownDir/$relative';
      final file = File(path);
      final markdown = file.existsSync() ? await file.readAsString() : '';
      entries.add(
        _LedgerEntry.fromLesson(
          categoryId: category['id']?.toString() ?? '',
          lesson: lesson,
          markdown: markdown,
          fileExists: file.existsSync(),
        ),
      );
    }
  }

  final report = _buildReport(manifest, entries);
  final docFile = File(options['out-docs'] ?? defaultDocPath);
  final jsonFile = File(options['out-json'] ?? defaultJsonPath);
  docFile.parent.createSync(recursive: true);
  jsonFile.parent.createSync(recursive: true);
  await docFile.writeAsString(_renderMarkdown(report));
  await jsonFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );

  stdout.writeln('内容审核台账已生成：');
  stdout.writeln('  ${docFile.path}');
  stdout.writeln('  ${jsonFile.path}');
  stdout.writeln(
    '课程 ${report['lesson_count']} · '
    '机器校验通过 ${report['machine_passed']} · '
    '待人工复核 ${report['pending_review']}',
  );
  if (options.containsKey('fail-on-pending') &&
      (report['pending_review'] as int) > 0) {
    exitCode = 1;
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final index = arg.indexOf('=');
    if (index < 0) {
      result[arg.substring(2)] = '';
    } else {
      result[arg.substring(2, index)] = arg.substring(index + 1);
    }
  }
  return result;
}

Map<String, dynamic> _buildReport(
  Map<String, dynamic> manifest,
  List<_LedgerEntry> entries,
) {
  final pending = entries.where((item) => item.reviewStatus != 'reviewed');
  final machinePassed = entries.where((item) => item.machineIssues.isEmpty);
  final byCategory = <String, int>{};
  for (final entry in entries) {
    byCategory[entry.categoryId] = (byCategory[entry.categoryId] ?? 0) + 1;
  }
  final totalCharacters = entries.fold<int>(
    0,
    (sum, item) => sum + item.characters,
  );
  return <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'content_version': manifest['content_version']?.toString() ?? '',
    'content_last_reviewed_at':
        manifest['content_last_reviewed_at']?.toString() ?? '',
    'content_next_review_at':
        manifest['content_next_review_at']?.toString() ?? '',
    'lesson_count': entries.length,
    'category_count': byCategory.length,
    'total_characters': totalCharacters,
    'average_characters':
        entries.isEmpty ? 0 : (totalCharacters / entries.length).round(),
    'machine_passed': machinePassed.length,
    'machine_warnings': entries.length - machinePassed.length,
    'reviewed': entries.length - pending.length,
    'pending_review': pending.length,
    'by_category': byCategory,
    'lessons': entries.map((item) => item.toJson()).toList(),
  };
}

String _renderMarkdown(Map<String, dynamic> report) {
  final buffer = StringBuffer()
    ..writeln('# 内容审核台账')
    ..writeln()
    ..writeln('- 生成时间：${report['generated_at']}')
    ..writeln('- 内容版本：${report['content_version']}')
    ..writeln('- 内容最近复核：${report['content_last_reviewed_at']}')
    ..writeln('- 下次计划复核：${report['content_next_review_at']}')
    ..writeln()
    ..writeln('## 汇总')
    ..writeln()
    ..writeln('| 指标 | 数值 |')
    ..writeln('| --- | --- |')
    ..writeln('| 课程总数 | ${report['lesson_count']} |')
    ..writeln('| 分类数 | ${report['category_count']} |')
    ..writeln('| 机器校验通过 | ${report['machine_passed']} |')
    ..writeln('| 机器校验有提示 | ${report['machine_warnings']} |')
    ..writeln('| 已人工复核 | ${report['reviewed']} |')
    ..writeln('| 待人工复核 | ${report['pending_review']} |')
    ..writeln('| 平均字数 | ${report['average_characters']} |')
    ..writeln()
    ..writeln('> 说明：机器校验只覆盖结构与完整性问题，不能替代人工事实核对。')
    ..writeln('> 没有审核人记录的课程保持 pending，不伪造审核结果。')
    ..writeln()
    ..writeln('## 课程明细')
    ..writeln()
    ..writeln('| 课程 | 分类 | 字数 | 题目 | 代码块 | 配图 | 机器校验 | 人工复核 |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final raw in (report['lessons'] as List)) {
    final item = (raw as Map).cast<String, dynamic>();
    final machine = (item['machine_issues'] as List).isEmpty
        ? '通过'
        : '${(item['machine_issues'] as List).length} 条提示';
    final review = item['review_status'] == 'reviewed'
        ? '已复核 ${item['reviewed_at'] ?? ''}'
        : '待复核';
    buffer.writeln(
      '| ${item['title']} | ${item['category_id']} | '
      '${item['characters']} | ${item['questions']} | '
      '${item['code_blocks']} | ${item['images']} | $machine | $review |',
    );
  }
  return buffer.toString();
}

class _LedgerEntry {
  const _LedgerEntry({
    required this.lessonId,
    required this.categoryId,
    required this.title,
    required this.characters,
    required this.questions,
    required this.codeBlocks,
    required this.images,
    required this.machineIssues,
    required this.reviewStatus,
    required this.reviewedAt,
    required this.reviewer,
  });

  final String lessonId;
  final String categoryId;
  final String title;
  final int characters;
  final int questions;
  final int codeBlocks;
  final int images;
  final List<String> machineIssues;
  final String reviewStatus;
  final String reviewedAt;
  final String reviewer;

  factory _LedgerEntry.fromLesson({
    required String categoryId,
    required Map<String, dynamic> lesson,
    required String markdown,
    required bool fileExists,
  }) {
    final issues = <String>[];
    final characters = markdown.replaceAll(RegExp(r'\s'), '').length;
    final fences = RegExp(
      r'^```',
      multiLine: true,
    ).allMatches(markdown).length;
    final codeBlocks = fences ~/ 2;
    final images = RegExp(
      r'!\[[^\]]*\]\([^)]*\)',
    ).allMatches(markdown).length;
    final questions = (lesson['quiz'] as List?)?.length ?? 0;
    if (!fileExists) issues.add('正文文件缺失');
    if (characters < 400) issues.add('正文偏短（少于 400 字）');
    if (questions == 0) issues.add('没有测验题');
    if (questions > 0 && questions < 3) issues.add('测验题少于 3 道');
    final reviewedAt = lesson['reviewed_at']?.toString() ?? '';
    final reviewer = lesson['reviewer']?.toString() ?? '';
    final title = lesson['title'];
    return _LedgerEntry(
      lessonId: lesson['id']?.toString() ?? '',
      categoryId: categoryId,
      title: title is Map ? title['zh']?.toString() ?? '' : '$title',
      characters: characters,
      questions: questions,
      codeBlocks: codeBlocks,
      images: images,
      machineIssues: issues,
      reviewStatus: reviewedAt.isEmpty ? 'pending' : 'reviewed',
      reviewedAt: reviewedAt,
      reviewer: reviewer,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'lesson_id': lessonId,
    'category_id': categoryId,
    'title': title,
    'characters': characters,
    'questions': questions,
    'code_blocks': codeBlocks,
    'images': images,
    'machine_issues': machineIssues,
    'review_status': reviewStatus,
    'reviewed_at': reviewedAt,
    'reviewer': reviewer,
  };
}
