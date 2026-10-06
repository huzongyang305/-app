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

const Map<String, String> expectedLanguageByCategory = <String, String>{
  'python': 'python',
  'c': 'c',
  'cpp': 'cpp',
  'java': 'java',
  'javascript': 'javascript',
  'typescript': 'typescript',
  'csharp': 'csharp',
  'go': 'go',
  'rust': 'rust',
  'kotlin': 'kotlin',
  'swift': 'swift',
  'shell': 'shell',
};

const List<String> generatedContentMarkers = <String>[
  '这道题对应的课程',
  '修正后要重跑',
  '本课在「',
  '本课还在「',
  '本课把「',
  '本课在核心知识',
  '本课还在核心知识',
  '对照「',
  '课程摘要',
  '先自己作答，再看「判断依据」',
  '**迁移检查**',
  '回到正文对应章节补足概念',
  '把题干里的一个条件换成边界值',
];

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
  final sources = <_LedgerSource>[];
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
      sources.add(
        _LedgerSource(
          categoryId: category['id']?.toString() ?? '',
          lesson: lesson,
          markdown: markdown,
          fileExists: file.existsSync(),
        ),
      );
    }
  }

  final referenceCounts = <String, Map<String, int>>{};
  for (final source in sources) {
    final signature = _referenceSignature(source.markdown);
    referenceCounts
        .putIfAbsent(source.categoryId, () => <String, int>{})
        .update(signature, (value) => value + 1, ifAbsent: () => 1);
  }
  final entries = <_LedgerEntry>[
    for (final source in sources)
      _LedgerEntry.fromLesson(
        categoryId: source.categoryId,
        lesson: source.lesson,
        markdown: source.markdown,
        fileExists: source.fileExists,
        duplicateReferenceSet:
            (referenceCounts[source.categoryId]?[_referenceSignature(
                  source.markdown,
                )] ??
                0) >
            1,
      ),
  ];

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
  final riskCounts = <String, int>{'high': 0, 'medium': 0, 'low': 0};
  for (final entry in entries) {
    riskCounts[entry.riskPriority] = (riskCounts[entry.riskPriority] ?? 0) + 1;
  }
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
    'average_characters': entries.isEmpty
        ? 0
        : (totalCharacters / entries.length).round(),
    'machine_passed': machinePassed.length,
    'machine_warnings': entries.length - machinePassed.length,
    'template_hits': entries.fold<int>(
      0,
      (sum, item) => sum + item.templateHits,
    ),
    'duplicate_reference_lessons': entries
        .where((item) => item.duplicateReferenceSet)
        .length,
    'language_mismatch_lessons': entries
        .where((item) => item.languageMismatches > 0)
        .length,
    'risk_high': riskCounts['high'] ?? 0,
    'risk_medium': riskCounts['medium'] ?? 0,
    'risk_low': riskCounts['low'] ?? 0,
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
    ..writeln('| 模板命中总数 | ${report['template_hits']} |')
    ..writeln('| 引用集合重复课程 | ${report['duplicate_reference_lessons']} |')
    ..writeln('| 代码语言错配课程 | ${report['language_mismatch_lessons']} |')
    ..writeln('| 高风险 | ${report['risk_high']} |')
    ..writeln('| 中风险 | ${report['risk_medium']} |')
    ..writeln('| 低风险 | ${report['risk_low']} |')
    ..writeln('| 已人工复核 | ${report['reviewed']} |')
    ..writeln('| 待人工复核 | ${report['pending_review']} |')
    ..writeln('| 平均字数 | ${report['average_characters']} |')
    ..writeln()
    ..writeln('> 说明：机器校验只覆盖结构与完整性问题，不能替代人工事实核对。')
    ..writeln('> 没有审核人记录的课程保持 pending，不伪造审核结果。')
    ..writeln()
    ..writeln('## 课程明细')
    ..writeln()
    ..writeln('| 课程 | 分类 | 字数 | 题目 | 模板 | 引用集合 | 语言错配 | 风险 | 人工复核 |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final raw in (report['lessons'] as List)) {
    final item = (raw as Map).cast<String, dynamic>();
    final review = item['review_status'] == 'reviewed'
        ? '已复核 ${item['reviewed_at'] ?? ''}'
        : '待复核';
    final reference = item['duplicate_reference_set'] == true ? '重复' : '唯一';
    buffer.writeln(
      '| ${item['title']} | ${item['category_id']} | '
      '${item['characters']} | ${item['questions']} | '
      '${item['template_hits']} | $reference | '
      '${item['language_mismatches']} | ${item['risk_priority']} | $review |',
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
    required this.templateHits,
    required this.duplicateReferenceSet,
    required this.languageMismatches,
    required this.riskPriority,
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
  final int templateHits;
  final bool duplicateReferenceSet;
  final int languageMismatches;
  final String riskPriority;
  final String reviewStatus;
  final String reviewedAt;
  final String reviewer;

  factory _LedgerEntry.fromLesson({
    required String categoryId,
    required Map<String, dynamic> lesson,
    required String markdown,
    required bool fileExists,
    required bool duplicateReferenceSet,
  }) {
    final issues = <String>[];
    final characters = markdown.replaceAll(RegExp(r'\s'), '').length;
    final fences = RegExp(r'^```', multiLine: true).allMatches(markdown).length;
    final codeBlocks = fences ~/ 2;
    final images = RegExp(r'!\[[^\]]*\]\([^)]*\)').allMatches(markdown).length;
    final questions = (lesson['quiz'] as List?)?.length ?? 0;
    final templateHits = generatedContentMarkers
        .where(
          (marker) =>
              markdown.contains(marker) ||
              (((lesson['quiz'] as List?) ?? const []).any(
                (raw) => ((raw as Map)['explanation'] ?? '')
                    .toString()
                    .contains(marker),
              )),
        )
        .length;
    final expectedLanguage = expectedLanguageByCategory[categoryId];
    final languageMismatches = expectedLanguage == null
        ? 0
        : ((lesson['quiz'] as List?) ?? const []).where((raw) {
            final language = ((raw as Map)['language'] ?? '').toString().trim();
            return language.isNotEmpty && language != expectedLanguage;
          }).length;
    if (!fileExists) issues.add('正文文件缺失');
    if (characters < 400) issues.add('正文偏短（少于 400 字）');
    if (questions == 0) issues.add('没有测验题');
    if (questions > 0 && questions < 3) issues.add('测验题少于 3 道');
    if (templateHits > 0) issues.add('命中机械模板 $templateHits 处');
    if (duplicateReferenceSet) issues.add('分类内参考资料集合重复');
    if (languageMismatches > 0) issues.add('代码语言错配 $languageMismatches 题');
    final riskPriority =
        !fileExists ||
            questions == 0 ||
            duplicateReferenceSet ||
            languageMismatches > 0
        ? 'high'
        : issues.isNotEmpty
        ? 'medium'
        : 'low';
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
      templateHits: templateHits,
      duplicateReferenceSet: duplicateReferenceSet,
      languageMismatches: languageMismatches,
      riskPriority: riskPriority,
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
    'template_hits': templateHits,
    'duplicate_reference_set': duplicateReferenceSet,
    'language_mismatches': languageMismatches,
    'risk_priority': riskPriority,
    'review_status': reviewStatus,
    'reviewed_at': reviewedAt,
    'reviewer': reviewer,
  };
}

class _LedgerSource {
  const _LedgerSource({
    required this.categoryId,
    required this.lesson,
    required this.markdown,
    required this.fileExists,
  });

  final String categoryId;
  final Map<String, dynamic> lesson;
  final String markdown;
  final bool fileExists;
}

String _referenceSignature(String markdown) {
  final sectionMatch = RegExp(
    r'^##\s+参考资料与复核\s*$',
    multiLine: true,
  ).firstMatch(markdown);
  if (sectionMatch == null) return 'missing';
  final rest = markdown.substring(sectionMatch.end);
  final nextHeading = RegExp(r'^##\s+', multiLine: true).firstMatch(rest);
  final section = nextHeading == null
      ? rest
      : rest.substring(0, nextHeading.start);
  final urls =
      RegExp(r'\[[^\]]+\]\((https?://[^)\s]+)\)')
          .allMatches(section)
          .map((match) => match.group(1)!)
          .toSet()
          .toList()
        ..sort();
  return urls.join('\n');
}
