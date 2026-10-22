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
const String defaultRecordsPath = 'docs/content_review_records.json';
const String defaultBatchDocPath = 'docs/content_review_batches.md';
const String defaultBatchJsonPath = 'docs/content_review_batches.json';

/// 每批人工复核的课程上限，方便按批次排期和抽查。
const int reviewBatchSize = 24;

/// 人工复核记录文件模板：复核人在这里登记结论，台账据此更新状态。
const String recordsTemplate = '''{
  "schema": 1,
  "updated_at": "",
  "instructions": [
    "在 human_reviews 下按课程 ID 登记人工复核结论；没有记录的课程一律保持待复核。",
    "reviewer 写真实复核人；method 固定为 human；reviewed_at 用 YYYY-MM-DD。",
    "scope 列出本次实际核对的范围，例如 术语、题目、代码、参考资料。",
    "notes 记录发现的问题与处理方式，便于下一轮复核追溯。"
  ],
  "human_reviews": {}
}
''';

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
  final recordsPath = options['records'] ?? defaultRecordsPath;
  final humanReviews = await _loadHumanReviews(recordsPath);
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
        humanReview: humanReviews[source.lesson['id']?.toString() ?? ''],
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

  // 人工复核批次：按分类切块，优先安排高风险课程先审。
  final batches = _buildReviewBatches(entries, manifest);
  final batchDocFile = File(options['out-batch-docs'] ?? defaultBatchDocPath);
  final batchJsonFile = File(options['out-batch-json'] ?? defaultBatchJsonPath);
  await batchDocFile.writeAsString(_renderBatchMarkdown(batches));
  await batchJsonFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'generated_at': report['generated_at'],
      'content_version': report['content_version'],
      'batch_size': reviewBatchSize,
      'batch_count': batches.length,
      'records_path': recordsPath,
      'batches': batches,
    }),
  );
  final recordsFile = File(recordsPath);
  if (!recordsFile.existsSync()) {
    recordsFile.parent.createSync(recursive: true);
    await recordsFile.writeAsString(recordsTemplate);
  }

  stdout.writeln('内容审核台账已生成：');
  stdout.writeln('  ${docFile.path}');
  stdout.writeln('  ${jsonFile.path}');
  stdout.writeln('复核批次已生成：');
  stdout.writeln('  ${batchDocFile.path}');
  stdout.writeln('  ${batchJsonFile.path}');
  if (recordsFile.existsSync()) {
    stdout.writeln('人工复核记录：${recordsFile.path}');
  }
  stdout.writeln(
    '课程 ${report['lesson_count']} · '
    '机器校验通过 ${report['machine_passed']} · '
    '已人工复核 ${report['reviewed_human']} · '
    '待人工复核 ${report['pending_human_review']} · '
    '无任何复核记录 ${report['pending_review']}',
  );
  if (options.containsKey('fail-on-pending') &&
      (report['pending_review'] as int) > 0) {
    exitCode = 1;
  }
  if (options.containsKey('fail-on-human-pending') &&
      (report['pending_human_review'] as int) > 0) {
    exitCode = 1;
  }
}

/// 读取人工复核记录；文件缺失或损坏时按「全部待复核」处理，绝不伪造结论。
Future<Map<String, Map<String, dynamic>>> _loadHumanReviews(String path) async {
  final file = File(path);
  if (!file.existsSync()) return <String, Map<String, dynamic>>{};
  try {
    final json = jsonDecode(await file.readAsString());
    if (json is! Map) return <String, Map<String, dynamic>>{};
    final reviews = json['human_reviews'];
    if (reviews is! Map) return <String, Map<String, dynamic>>{};
    final result = <String, Map<String, dynamic>>{};
    for (final entry in reviews.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final record = value.cast<String, dynamic>();
      final reviewer = record['reviewer']?.toString().trim() ?? '';
      final reviewedAt = record['reviewed_at']?.toString().trim() ?? '';
      if (reviewer.isEmpty || reviewedAt.isEmpty) continue;
      result[entry.key.toString()] = record;
    }
    return result;
  } on FormatException {
    stderr.writeln('复核记录无法解析，按全部待复核处理：$path');
    return <String, Map<String, dynamic>>{};
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
  final humanReviewedIds = <String>{
    for (final entry in entries)
      if (entry.reviewStatus == 'reviewed' && entry.reviewMethod == 'human')
        entry.lessonId,
  };
  final automatedReviewed = entries
      .where(
        (item) =>
            item.reviewStatus == 'reviewed' && item.reviewMethod != 'human',
      )
      .toList();
  final humanPending = entries
      .where((item) => !humanReviewedIds.contains(item.lessonId))
      .toList();
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
  final totalRawCharacters = entries.fold<int>(
    0,
    (sum, item) => sum + item.rawCharacters,
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
    'total_raw_characters': totalRawCharacters,
    'average_characters': entries.isEmpty
        ? 0
        : (totalCharacters / entries.length).round(),
    'average_raw_characters': entries.isEmpty
        ? 0
        : (totalRawCharacters / entries.length).round(),
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
    'reviewed_human': humanReviewedIds.length,
    'reviewed_automated': automatedReviewed.length,
    'pending_review': pending.length,
    'pending_human_review': humanPending.length,
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
    ..writeln('| 已人工复核 | ${report['reviewed_human']} |')
    ..writeln('| 已登记其他复核 | ${report['reviewed_automated']} |')
    ..writeln('| 待人工复核 | ${report['pending_human_review']} |')
    ..writeln('| 无任何复核记录 | ${report['pending_review']} |')
    ..writeln('| 平均字数（去空白） | ${report['average_characters']} |')
    ..writeln('| 平均字数（原始字符） | ${report['average_raw_characters']} |')
    ..writeln('| 总字数（原始字符） | ${report['total_raw_characters']} |')
    ..writeln()
    ..writeln('> 说明：机器校验只覆盖结构与完整性问题，不能替代人工事实核对。')
    ..writeln('> 只有 docs/content_review_records.json 中登记了复核人、日期与范围的课程才计为已复核；')
    ..writeln('> 其余课程保持 pending，并按 docs/content_review_batches.md 分批安排人工复核。')
    ..writeln()
    ..writeln('## 课程明细')
    ..writeln()
    ..writeln(
      '| 课程 | 分类 | 字数(去空白) | 原始字数 | 题目 | 模板 | 引用集合 | 语言错配 | 风险 | 人工复核 |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final raw in (report['lessons'] as List)) {
    final item = (raw as Map).cast<String, dynamic>();
    final review = item['review_status'] == 'reviewed'
        ? '已复核 ${item['reviewed_at'] ?? ''}（${item['review_method'] ?? 'human'}）'
        : '待复核';
    final reference = item['duplicate_reference_set'] == true ? '重复' : '唯一';
    buffer.writeln(
      '| ${item['title']} | ${item['category_id']} | '
      '${item['characters']} | ${item['raw_characters']} | ${item['questions']} | '
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
    required this.rawCharacters,
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
    required this.reviewMethod,
    required this.reviewNotes,
  });

  final String lessonId;
  final String categoryId;
  final String title;
  final int characters;
  final int rawCharacters;
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
  final String reviewMethod;
  final String reviewNotes;

  factory _LedgerEntry.fromLesson({
    required String categoryId,
    required Map<String, dynamic> lesson,
    required String markdown,
    required bool fileExists,
    required bool duplicateReferenceSet,
    Map<String, dynamic>? humanReview,
  }) {
    final issues = <String>[];
    // 同时记录去空白字数与原始字符数：审计工具用原始字符数，
    // 台账此前只报去空白字数，两个口径曾对不上。
    final rawCharacters = markdown.length;
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
    final reviewedAt =
        humanReview?['reviewed_at']?.toString() ??
        lesson['reviewed_at']?.toString() ??
        '';
    final reviewer =
        humanReview?['reviewer']?.toString() ??
        lesson['reviewer']?.toString() ??
        '';
    final reviewMethod =
        humanReview?['method']?.toString() ??
        (humanReview != null ? 'human' : '');
    final reviewNotes = humanReview?['notes']?.toString() ?? '';
    final title = lesson['title'];
    return _LedgerEntry(
      lessonId: lesson['id']?.toString() ?? '',
      categoryId: categoryId,
      title: title is Map ? title['zh']?.toString() ?? '' : '$title',
      characters: characters,
      rawCharacters: rawCharacters,
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
      reviewMethod: reviewMethod,
      reviewNotes: reviewNotes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'lesson_id': lessonId,
    'category_id': categoryId,
    'title': title,
    'characters': characters,
    'raw_characters': rawCharacters,
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
    'review_method': reviewMethod,
    'review_notes': reviewNotes,
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

/// 复核批次：按分类切块，高风险课程排在每批前面，并给出该批重点检查项。
List<Map<String, dynamic>> _buildReviewBatches(
  List<_LedgerEntry> entries,
  Map<String, dynamic> manifest,
) {
  final categoryTitles = <String, String>{};
  for (final raw in (manifest['categories'] as List? ?? const [])) {
    final category = (raw as Map).cast<String, dynamic>();
    final title = category['title'];
    final id = category['id']?.toString() ?? '';
    categoryTitles[id] = title is Map
        ? title['zh']?.toString() ?? id
        : '$title';
  }
  final riskOrder = <String, int>{'high': 0, 'medium': 1, 'low': 2};
  final byCategory = <String, List<_LedgerEntry>>{};
  for (final entry in entries) {
    byCategory.putIfAbsent(entry.categoryId, () => <_LedgerEntry>[]).add(entry);
  }
  final batches = <Map<String, dynamic>>[];
  for (final categoryEntry in byCategory.entries) {
    final lessons = <_LedgerEntry>[...categoryEntry.value]
      ..sort((a, b) {
        final aRisk = riskOrder[a.riskPriority] ?? 9;
        final bRisk = riskOrder[b.riskPriority] ?? 9;
        if (aRisk != bRisk) return aRisk.compareTo(bRisk);
        return a.lessonId.compareTo(b.lessonId);
      });
    for (var index = 0; index < lessons.length; index += reviewBatchSize) {
      final end = (index + reviewBatchSize).clamp(0, lessons.length);
      final chunk = lessons.sublist(index, end);
      final reviewed = chunk
          .where(
            (item) =>
                item.reviewStatus == 'reviewed' && item.reviewMethod == 'human',
          )
          .length;
      batches.add(<String, dynamic>{
        'batch_id': '${categoryEntry.key}-${index ~/ reviewBatchSize + 1}',
        'category_id': categoryEntry.key,
        'category_title':
            categoryTitles[categoryEntry.key] ?? categoryEntry.key,
        'lesson_count': chunk.length,
        'reviewed': reviewed,
        'status': reviewed == chunk.length ? 'reviewed' : 'pending',
        'risk_high': chunk.where((item) => item.riskPriority == 'high').length,
        'risk_medium': chunk
            .where((item) => item.riskPriority == 'medium')
            .length,
        'risk_low': chunk.where((item) => item.riskPriority == 'low').length,
        'focus': _reviewFocus(categoryEntry.key, chunk),
        'lessons': <Map<String, dynamic>>[
          for (final item in chunk)
            <String, dynamic>{
              'lesson_id': item.lessonId,
              'title': item.title,
              'risk': item.riskPriority,
              'characters': item.characters,
              'questions': item.questions,
              'images': item.images,
              'machine_issues': item.machineIssues,
              'review_status': item.reviewStatus,
              'review_method': item.reviewMethod,
            },
        ],
      });
    }
  }
  batches.sort((a, b) {
    final riskA = (a['risk_high'] as int) + (a['risk_medium'] as int);
    final riskB = (b['risk_high'] as int) + (b['risk_medium'] as int);
    if (riskA != riskB) return riskB.compareTo(riskA);
    return (a['batch_id'] as String).compareTo(b['batch_id'] as String);
  });
  return batches;
}

/// 每批复核重点：分类共性检查 + 该批实测到的机器提示。
List<String> _reviewFocus(String categoryId, List<_LedgerEntry> chunk) {
  final focus = <String>[
    '正文事实与术语是否准确，有无过时结论或含糊表述。',
    '代码块能否按正文步骤运行，输出与解析是否一致。',
    '测验题干、选项与解析是否自洽，答案下标是否正确。',
    '参考资料链接可访问，且与课程主题匹配。',
  ];
  const languageCategories = <String>{
    'python',
    'c',
    'cpp',
    'java',
    'javascript',
    'typescript',
    'csharp',
    'go',
    'rust',
    'kotlin',
    'swift',
    'shell',
  };
  if (languageCategories.contains(categoryId)) {
    focus.add('示例代码在本语言主流版本上可编译或可运行，无跨语言残留写法。');
  }
  if (categoryId == 'ai') {
    focus.add('模型、工具与成本结论注明适用前提，避免把演示效果当成生产结论。');
  }
  if (categoryId == 'security') {
    focus.add('安全建议与威胁模型对应，示例不鼓励真实环境中的危险操作。');
  }
  if (chunk.any((item) => item.templateHits > 0)) {
    focus.add('该批存在模板命中记录，优先核对正文与解析的机械句残留。');
  }
  if (chunk.any((item) => item.duplicateReferenceSet)) {
    focus.add('该批存在参考资料集合重复，需替换为与课程对应的来源。');
  }
  if (chunk.any((item) => item.questions < 3)) {
    focus.add('该批有课程题量不足，需要补题后再复核。');
  }
  if (chunk.any((item) => item.images == 0)) {
    focus.add('该批有课程没有配图，需补图或说明不需要配图的理由。');
  }
  return focus;
}

String _renderBatchMarkdown(List<Map<String, dynamic>> batches) {
  final buffer = StringBuffer()
    ..writeln('# 人工复核批次台账')
    ..writeln()
    ..writeln('- 生成时间：${DateTime.now().toUtc().toIso8601String()}')
    ..writeln('- 批次大小：每批最多 $reviewBatchSize 门课')
    ..writeln('- 记录入口：`docs/content_review_records.json` 的 `human_reviews`')
    ..writeln()
    ..writeln('> 复核完成后，把复核人、日期、范围与结论写入记录文件，再重跑本工具刷新台账。')
    ..writeln();
  for (final batch in batches) {
    buffer
      ..writeln('## ${batch['batch_id']} · ${batch['category_title']}')
      ..writeln()
      ..writeln(
        '- 课程数：${batch['lesson_count']} · 已人工复核：${batch['reviewed']} · '
        '状态：${batch['status']}',
      )
      ..writeln(
        '- 风险分布：高 ${batch['risk_high']} · 中 ${batch['risk_medium']} · '
        '低 ${batch['risk_low']}',
      )
      ..writeln('- 复核重点：');
    for (final item in (batch['focus'] as List)) {
      buffer.writeln('  - $item');
    }
    buffer
      ..writeln()
      ..writeln('| 课程 | 风险 | 字数 | 题目 | 配图 | 状态 |')
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    for (final raw in (batch['lessons'] as List)) {
      final lesson = (raw as Map).cast<String, dynamic>();
      final status = lesson['review_status'] == 'reviewed' ? '已复核' : '待复核';
      buffer.writeln(
        '| ${lesson['title']}（${lesson['lesson_id']}） | ${lesson['risk']} | '
        '${lesson['characters']} | ${lesson['questions']} | '
        '${lesson['images']} | $status |',
      );
    }
    buffer.writeln();
  }
  return buffer.toString();
}
