// P0/P1 内容治理审计：专门捕捉模板化、引用复用和代码语言错配。
//
// 用法：
//   dart run tool/audit_content_governance.dart [--json] [--no-fail] [--top=30]
//
// 与 audit_content_quality.dart 的结构检查互补。本工具把内容治理问题计入
// warning_count，并在默认模式下返回非零退出码，适合 CI 卡口。
import 'dart:convert';
import 'dart:io';

import 'lesson_effort.dart';
import 'markdown_fences.dart';

const String manifestPath = 'assets/content/manifest.json';
const String defaultReportPath = 'tool/reports/content_governance_report.json';

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

const List<String> generatedExplanationMarkers = <String>[
  '这道题对应的课程',
  '修正后要重跑',
  '本课在「',
  '本课还在「',
  '本课把「',
  '本课在核心知识',
  '本课还在核心知识',
  '对照「',
  '课程摘要',
];

const List<String> generatedMarkdownMarkers = <String>[
  '先自己作答，再看「判断依据」',
  '**迁移检查**',
  '本课在「',
  '本课还在「',
  '本课在核心知识',
  '本课还在核心知识',
  '课程摘要指出',
  '回到正文对应章节补足概念',
  '把题干里的一个条件换成边界值',
  '把现象和原因写在一起',
  '错误信息通常会指出出错行和期望符号',
];

/// P0/P1 语义卡口：这些缺陷是生成器留下的可见问题，一律按 error 处理。
const String placeholderTitle = '本课主题';

/// P1 结构统一：每门课都必须具备的 14 个规范章节（见 docs/content_standard.md）。
const List<String> canonicalLessonSections = <String>[
  '学习目标',
  '前置知识',
  '动手练习',
  '考点精讲',
  '故障现场',
  '本课小结',
  '参考资料与复核',
  'English Overview',
  '内容元数据',
  '本课复习清单',
  '术语速查',
  '可运行练习',
  '常见错误与排查',
  '复习与自测',
];

/// 已被规范名取代的旧章节标题：再次出现说明生成器回退到旧命名。
const List<String> legacyLessonSections = <String>[
  '常见错误对照表',
  '常见错误',
  '常见错误速查',
  '常见误区',
  '常见坑',
  '常见陷阱',
  '常见问题',
  '常见问题与对策',
  '常见问题与排查顺序',
  '常见风险速查',
  '常见失败模式',
  '常见反模式速查',
  '反模式',
  '失败模式',
  '新手最容易踩的八个坑',
  '新手最容易踩的六个坑',
  '必须注意的坑',
  '五个高频坑',
  '三个经典坑',
  '易错点回顾',
  '自测清单',
  '逐节复习与自检',
  '深度追问与自测',
  '本课自测清单与错误对照',
  '实践任务',
];

const List<String> genericPythonQuestionMarkers = <String>[
  'bucket=[]',
  'items.remove(item)',
  'range(len(data) + 1)',
  '相关的一个常见故障',
];

final RegExp internalQuestionIdPattern = RegExp(
  r'[（(]\s*[A-Za-z0-9_]+\s*第\s*\d+\s*题\s*[)）]',
);

void main(List<String> args) {
  final jsonOutput = args.contains('--json');
  final failOnIssue = !args.contains('--no-fail');
  final top = _intOption(args, '--top=', 30);
  final reportPath = _stringOption(args, '--report=', defaultReportPath);

  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('找不到内容清单：$manifestPath');
    exitCode = 2;
    return;
  }
  final manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final lessons = <GovernanceLesson>[];
  for (final rawCategory in manifest['categories'] as List<dynamic>) {
    final category = (rawCategory as Map).cast<String, dynamic>();
    final categoryId = category['id'].toString();
    for (final rawLesson in category['lessons'] as List<dynamic>) {
      final lesson = (rawLesson as Map).cast<String, dynamic>();
      final file = File(lesson['file'].toString());
      lessons.add(
        GovernanceLesson(
          id: lesson['id'].toString(),
          categoryId: categoryId,
          title: (((lesson['title'] as Map?)?['zh'] ?? lesson['id']).toString())
              .trim(),
          keywords: ((lesson['keywords'] as List<dynamic>?) ?? const <dynamic>[])
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
          markdown: file.existsSync() ? file.readAsStringSync() : '',
          quiz: ((lesson['quiz'] as List<dynamic>?) ?? const [])
              .map((raw) => (raw as Map).cast<String, dynamic>())
              .toList(),
          codeQuiz: lesson['code_quiz'] is Map
              ? (lesson['code_quiz'] as Map).cast<String, dynamic>()
              : null,
          order: lesson['order'] is int
              ? lesson['order'] as int
              : int.tryParse('${lesson['order']}') ?? 0,
          difficulty: (lesson['difficulty'] ?? '基础').toString(),
          prerequisites: ((lesson['prerequisites'] as List<dynamic>?) ?? const [])
              .map(
                (item) => item is Map ? item['id'].toString() : item.toString(),
              )
              .where((id) => id.isNotEmpty)
              .toList(),
          minutes: lesson['minutes'] is int
              ? lesson['minutes'] as int
              : int.tryParse('${lesson['minutes']}') ?? 0,
        ),
      );
    }
  }

  final issues = <GovernanceIssue>[];
  final explanationSentences = <String, Set<String>>{};
  final markdownParagraphs = <String, Set<String>>{};
  final referenceSetsByCategory =
      <String, Map<String, List<GovernanceLesson>>>{};
  var placeholderTitleHits = 0;
  var internalIdHits = 0;
  var duplicateReviewSections = 0;
  var staleReviewSupplements = 0;
  var corruptTermTables = 0;
  var missingSectionLessons = 0;
  var legacySectionHeadings = 0;
  var codeQuestionsWithoutDomainLink = 0;
  var explanationsWithMeta = 0;
  var languageMismatches = 0;

  for (final lesson in lessons) {
    if (lesson.markdown.isEmpty) {
      issues.add(
        GovernanceIssue(
          level: 'error',
          lessonId: lesson.id,
          kind: 'missing_markdown',
          message: 'Markdown 文件缺失或为空',
        ),
      );
      continue;
    }

    // 标题、占位符、内部题号与重复复习章节的语义卡口。
    // 旧版按「标题出现次数」设预算，逼着生成器把真实标题改成「本课主题」占位符，
    // 反而破坏了 H1、配图替代文本和正文；这里改为直接检查这些结构性缺陷。
    final structureIssues = _auditLessonStructure(lesson);
    issues.addAll(structureIssues);
    for (final issue in structureIssues) {
      switch (issue.kind) {
        case 'internal_question_id':
          internalIdHits++;
        case 'duplicate_review_section':
          duplicateReviewSections++;
        case 'stale_review_supplement':
          staleReviewSupplements++;
        case 'corrupt_term_table':
          corruptTermTables++;
        case 'missing_section':
          missingSectionLessons++;
        case 'legacy_section_heading':
          legacySectionHeadings++;
      }
    }
    if (lesson.markdown.contains(placeholderTitle)) {
      placeholderTitleHits++;
      issues.add(
        GovernanceIssue(
          level: 'error',
          lessonId: lesson.id,
          kind: 'placeholder_title',
          message: '正文仍残留标题占位符「$placeholderTitle」',
        ),
      );
    }
    for (final marker in generatedMarkdownMarkers) {
      if (lesson.markdown.contains(marker)) {
        issues.add(
          GovernanceIssue(
            level: 'warn',
            lessonId: lesson.id,
            kind: 'markdown_generated_marker',
            message: '正文残留机械模板句：$marker',
          ),
        );
      }
    }
    for (final paragraph in _extractParagraphs(lesson.markdown)) {
      markdownParagraphs
          .putIfAbsent(paragraph, () => <String>{})
          .add(lesson.id);
    }

    if (lesson.quiz.isEmpty) {
      issues.add(
        GovernanceIssue(
          level: 'error',
          lessonId: lesson.id,
          kind: 'missing_quiz',
          message: '课程没有测验题',
        ),
      );
    }
    for (var index = 0; index < lesson.quiz.length; index++) {
      final question = lesson.quiz[index];
      final explanation = (question['explanation'] ?? '').toString().trim();
      final questionNumber = index + 1;
      final questionText = (question['question'] ?? '').toString();
      final questionBlob = jsonEncode(question);
      if (questionBlob.contains(placeholderTitle)) {
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: lesson.id,
            kind: 'placeholder_title',
            message: '第 $questionNumber 题仍残留标题占位符「$placeholderTitle」',
          ),
        );
      }
      if (internalQuestionIdPattern.hasMatch(questionBlob)) {
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: lesson.id,
            kind: 'internal_question_id',
            message: '第 $questionNumber 题残留内部题号',
          ),
        );
      }
      if (questionText.contains('…')) {
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: lesson.id,
            kind: 'truncated_question_text',
            message: '第 $questionNumber 题题干被截断',
          ),
        );
      }
      if (genericPythonQuestionMarkers.any(questionBlob.contains)) {
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: lesson.id,
            kind: 'generic_python_question',
            message: '第 $questionNumber 题仍是跨域套用的 Python 通用题',
          ),
        );
      }
      final questionType = (question['type'] ?? 'single').toString();
      if ((questionType == 'code' || questionType == 'debug') &&
          (question['code'] ?? '').toString().trim().isNotEmpty &&
          !_mentionsLessonDomain(lesson, explanation)) {
        codeQuestionsWithoutDomainLink++;
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: lesson.id,
            kind: 'code_question_domain_link',
            message: '第 $questionNumber 题代码题的解析没有对应本课主题或关键词',
          ),
        );
      }
      final metaMarkers = generatedExplanationMarkers
          .where(explanation.contains)
          .toList();
      if (metaMarkers.isNotEmpty) {
        explanationsWithMeta++;
        issues.add(
          GovernanceIssue(
            level: 'warn',
            lessonId: lesson.id,
            kind: 'explanation_generated_marker',
            message: '第 $questionNumber 题解析残留机械模板句：${metaMarkers.join('、')}',
          ),
        );
      }
      if (explanation.length < 120) {
        issues.add(
          GovernanceIssue(
            level: 'warn',
            lessonId: lesson.id,
            kind: 'explanation_too_short',
            message: '第 $questionNumber 题解析只有 ${explanation.length} 字，最低 120 字',
          ),
        );
      }
      if (RegExp(r'[。；，]{2,}|。，|，。|…；').hasMatch(explanation)) {
        issues.add(
          GovernanceIssue(
            level: 'warn',
            lessonId: lesson.id,
            kind: 'explanation_malformed_punctuation',
            message: '第 $questionNumber 题解析存在异常标点',
          ),
        );
      }
      final normalizedExplanation = _normalizeAnswerText(explanation);
      final correctParts = _correctOptions(question)
          .map(_normalizeAnswerText)
          .where((value) => value.isNotEmpty)
          .toList();
      final missingAnswers = correctParts
          .where((value) => !normalizedExplanation.contains(value))
          .toList();
      if (missingAnswers.isNotEmpty) {
        issues.add(
          GovernanceIssue(
            level: 'warn',
            lessonId: lesson.id,
            kind: 'explanation_missing_answer',
            message:
                '第 $questionNumber 题解析未包含 ${missingAnswers.length}/${correctParts.length} 个正确答案片段',
          ),
        );
      }
      for (final sentence in _splitSentences(explanation)) {
        if (sentence.length < 12) continue;
        explanationSentences
            .putIfAbsent(sentence, () => <String>{})
            .add(lesson.id);
      }

      final language = (question['language'] ?? '').toString().trim();
      final code = (question['code'] ?? '').toString();
      final expected = expectedLanguageByCategory[lesson.categoryId];
      if (expected != null && language.isNotEmpty && language != expected) {
        languageMismatches++;
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: lesson.id,
            kind: 'code_language_mismatch',
            message: '第 $questionNumber 题代码语言为 $language，课程应使用 $expected',
          ),
        );
      }
      final codeMismatch = _codeShapeMismatch(
        expectedLanguage: expected,
        language: language,
        code: code,
      );
      if (codeMismatch != null) {
        languageMismatches++;
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: lesson.id,
            kind: 'code_shape_mismatch',
            message: '第 $questionNumber 题$codeMismatch',
          ),
        );
      }
    }

    final references = _extractReferences(lesson.markdown);
    if (references.length < 2) {
      issues.add(
        GovernanceIssue(
          level: 'error',
          lessonId: lesson.id,
          kind: 'reference_coverage',
          message: '只有 ${references.length} 条可用参考资料，至少需要 2 条',
        ),
      );
    }
    final signature = references.map((item) => item.url).toSet().toList()
      ..sort();
    if (signature.isNotEmpty) {
      referenceSetsByCategory
          .putIfAbsent(
            lesson.categoryId,
            () => <String, List<GovernanceLesson>>{},
          )
          .putIfAbsent(signature.join('\n'), () => <GovernanceLesson>[])
          .add(lesson);
    }
  }

  final repeatedExplanationSentences =
      explanationSentences.entries
          .where((entry) => entry.value.length >= 5)
          .toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final entry in repeatedExplanationSentences) {
    issues.add(
      GovernanceIssue(
        level: 'warn',
        lessonId: entry.value.first,
        kind: 'repeated_explanation_sentence',
        message: '解析句子出现在 ${entry.value.length} 门课：${_short(entry.key, 72)}',
      ),
    );
  }

  final repeatedMarkdownParagraphs =
      markdownParagraphs.entries
          .where((entry) => entry.value.length > 20)
          .toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final entry in repeatedMarkdownParagraphs) {
    issues.add(
      GovernanceIssue(
        level: 'warn',
        lessonId: entry.value.first,
        kind: 'repeated_markdown_paragraph',
        message: '正文段落出现在 ${entry.value.length} 门课：${_short(entry.key, 72)}',
      ),
    );
  }

  final duplicateReferenceSets = <Map<String, dynamic>>[];
  for (final categoryEntry in referenceSetsByCategory.entries) {
    for (final setEntry in categoryEntry.value.entries) {
      if (setEntry.value.length < 2) continue;
      duplicateReferenceSets.add(<String, dynamic>{
        'category': categoryEntry.key,
        'lesson_count': setEntry.value.length,
        'lessons': setEntry.value.map((lesson) => lesson.id).toList(),
        'urls': setEntry.key.split('\n'),
      });
      issues.add(
        GovernanceIssue(
          level: 'warn',
          lessonId: setEntry.value.first.id,
          kind: 'duplicate_reference_set',
          message:
              '${categoryEntry.key} 有 ${setEntry.value.length} 门课使用完全相同的参考资料集合',
        ),
      );
    }
  }

  // 学习路径不变量：难度不倒挂、先修在推荐顺序之前、order 连续、时长可复核。
  final pathIssues = _auditLearningPath(lessons);
  issues.addAll(pathIssues);
  final difficultyInversions = _countKind(
    pathIssues,
    'difficulty_inversion',
  );
  final prerequisiteViolations = _countKind(
    pathIssues,
    'prerequisite_violation',
  );
  final orderGaps = _countKind(pathIssues, 'order_gap');
  final minutesDrift = _countKind(pathIssues, 'minutes_drift');
  final errorsAfterPath = issues.where((issue) => issue.level == 'error').toList();
  final warningsAfterPath = issues.where((issue) => issue.level == 'warn').toList();

  final report = <String, dynamic>{
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'lesson_count': lessons.length,
    'question_count': lessons.fold<int>(
      0,
      (sum, lesson) => sum + lesson.quiz.length,
    ),
    'error_count': errorsAfterPath.length,
    'warning_count': warningsAfterPath.length,
    'difficulty_inversions': difficultyInversions,
    'prerequisite_violations': prerequisiteViolations,
    'order_gaps': orderGaps,
    'minutes_drift': minutesDrift,
    'placeholder_title_hits': placeholderTitleHits,
    'internal_question_id_hits': internalIdHits,
    'duplicate_review_sections': duplicateReviewSections,
    'stale_review_supplements': staleReviewSupplements,
    'corrupt_term_tables': corruptTermTables,
    'lessons_missing_canonical_sections': missingSectionLessons,
    'legacy_section_headings': legacySectionHeadings,
    'code_questions_without_domain_link': codeQuestionsWithoutDomainLink,
    'explanations_with_meta_markers': explanationsWithMeta,
    'language_mismatches': languageMismatches,
    'repeated_explanation_sentence_classes':
        repeatedExplanationSentences.length,
    'repeated_markdown_paragraph_classes': repeatedMarkdownParagraphs.length,
    'duplicate_reference_sets': duplicateReferenceSets.length,
    'issues': issues.map((issue) => issue.toJson()).toList(),
    'top_repeated_explanation_sentences': [
      for (final entry in repeatedExplanationSentences.take(top))
        <String, dynamic>{
          'count': entry.value.length,
          'sentence': entry.key,
          'lessons': entry.value.take(8).toList(),
        },
    ],
    'top_repeated_markdown_paragraphs': [
      for (final entry in repeatedMarkdownParagraphs.take(top))
        <String, dynamic>{
          'count': entry.value.length,
          'paragraph': entry.key,
          'lessons': entry.value.take(8).toList(),
        },
    ],
    'duplicate_reference_set_details': duplicateReferenceSets,
  };

  final reportFile = File(reportPath);
  reportFile.parent.createSync(recursive: true);
  reportFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
  );

  if (jsonOutput) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
  } else {
    stdout.writeln('课程总数                    ${report['lesson_count']}');
    stdout.writeln('题目总数                    ${report['question_count']}');
    stdout.writeln('标题占位符                  $placeholderTitleHits');
    stdout.writeln('内部题号                    $internalIdHits');
    stdout.writeln('重复复习章节                $duplicateReviewSections');
    stdout.writeln('残留复核补充                $staleReviewSupplements');
    stdout.writeln('损坏术语表                  $corruptTermTables');
    stdout.writeln('缺规范章节课程              $missingSectionLessons');
    stdout.writeln('残留旧章节标题              $legacySectionHeadings');
    stdout.writeln('代码题缺本课关联            $codeQuestionsWithoutDomainLink');
    stdout.writeln('解析机械模板句              $explanationsWithMeta');
    stdout.writeln('代码语言错配                $languageMismatches');
    stdout.writeln(
      '解析重复句类(>=5)           '
      '${repeatedExplanationSentences.length}',
    );
    stdout.writeln(
      '正文重复段落类(>20)         '
      '${repeatedMarkdownParagraphs.length}',
    );
    stdout.writeln('重复参考资料集合            ${duplicateReferenceSets.length}');
    stdout.writeln('难度倒挂                    $difficultyInversions');
    stdout.writeln('先修顺序倒挂                $prerequisiteViolations');
    stdout.writeln('order 不连续分类            $orderGaps');
    stdout.writeln('预计用时偏差                $minutesDrift');
    stdout.writeln('错误                        ${errorsAfterPath.length}');
    stdout.writeln('警告                        ${warningsAfterPath.length}');
    if (errorsAfterPath.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln('--- 错误（前 $top 条）---');
      for (final issue in errorsAfterPath.take(top)) {
        stdout.writeln('${issue.lessonId}: ${issue.message}');
      }
    }
    if (warningsAfterPath.isNotEmpty) {
      stdout.writeln('');
      stdout.writeln('--- 警告（前 $top 条）---');
      for (final issue in warningsAfterPath.take(top)) {
        stdout.writeln('${issue.lessonId}: ${issue.message}');
      }
    }
    stdout.writeln('');
    stdout.writeln('报告已写入 ${reportFile.path}');
  }

  if (failOnIssue &&
      (errorsAfterPath.isNotEmpty || warningsAfterPath.isNotEmpty)) {
    exitCode = 1;
  }
}

String? _codeShapeMismatch({
  required String? expectedLanguage,
  required String language,
  required String code,
}) {
  if (code.trim().isEmpty) return null;
  if (expectedLanguage == 'c' &&
      RegExp(
        r'#include\s*<(iostream|vector|string|memory|algorithm)>|std::|\bclass\s+\w+',
      ).hasMatch(code)) {
    return '使用 C 课程，但代码形态是 C++';
  }
  if (expectedLanguage == 'typescript' &&
      language == 'javascript' &&
      RegExp(r'\b(interface|type|enum|namespace|declare|implements)\b')
          .hasMatch(code)) {
    return '使用 TypeScript 课程，但代码语言标记为 JavaScript';
  }
  if (expectedLanguage == 'csharp' &&
      RegExp(r'\bfun\s+\w+\s*\(|\bimport\s+dart:|\bval\s+\w+\s*=')
          .hasMatch(code)) {
    return '代码形态与 C# 不符';
  }
  if (expectedLanguage == 'shell' &&
      RegExp(
        r'\bdef\s+\w+\s*\(|\bprint\s*\(|\bimport\s+\w+|^\s*[a-zA-Z_]\w*\s*=\s*\[[^\]]*\]\s*$',
        multiLine: true,
      ).hasMatch(code)) {
    return '使用 Shell 课程，但代码形态是 Python';
  }
  if (expectedLanguage == 'rust' &&
      RegExp(r'\bfunction\s+\w+|\bconst\s+\w+\s*=\s*\(|\bdef\s+\w+\(')
          .hasMatch(code)) {
    return '代码形态与 Rust 不符';
  }
  if (expectedLanguage == 'kotlin' &&
      RegExp(r'\bimport\s+dart:|\bvoid\s+main\s*\(\s*\)\s*\{').hasMatch(code)) {
    return '代码形态与 Kotlin 不符';
  }
  return null;
}

/// 课程结构层面的 P0/P1 卡口：H1 标题、内部题号、复习章节与术语表。
List<GovernanceIssue> _auditLessonStructure(GovernanceLesson lesson) {
  final issues = <GovernanceIssue>[];
  final h1 = RegExp(
    r'^#\s+(.+)$',
    multiLine: true,
  ).firstMatch(lesson.markdown)?.group(1)?.trim();
  if (h1 != lesson.title) {
    issues.add(
      GovernanceIssue(
        level: 'error',
        lessonId: lesson.id,
        kind: 'heading_title_mismatch',
        message: 'H1 标题为「$h1」，与清单标题「${lesson.title}」不一致',
      ),
    );
  }
  final idHits = internalQuestionIdPattern.allMatches(lesson.markdown).length;
  if (idHits > 0) {
    issues.add(
      GovernanceIssue(
        level: 'error',
        lessonId: lesson.id,
        kind: 'internal_question_id',
        message: '正文残留 $idHits 处内部题号',
      ),
    );
  }
  final reviewHits = RegExp(
    r'^##\s+复习与迁移\s*$',
    multiLine: true,
  ).allMatches(lesson.markdown).length;
  if (reviewHits > 1) {
    issues.add(
      GovernanceIssue(
        level: 'error',
        lessonId: lesson.id,
        kind: 'duplicate_review_section',
        message: '正文有 $reviewHits 个「复习与迁移」章节',
      ),
    );
  }
  if (RegExp(
    r'^[>\s]*#{1,6}\s*复核补充',
    multiLine: true,
  ).hasMatch(lesson.markdown)) {
    issues.add(
      GovernanceIssue(
        level: 'error',
        lessonId: lesson.id,
        kind: 'stale_review_supplement',
        message: '正文残留自动生成的「复核补充」章节',
      ),
    );
  }
  final termSection = _section(lesson.markdown, '术语速查');
  final missingSections = <String>[
    for (final title in canonicalLessonSections)
      if (!_hasSection(lesson.markdown, title)) title,
  ];
  if (missingSections.isNotEmpty) {
    issues.add(
      GovernanceIssue(
        level: 'error',
        lessonId: lesson.id,
        kind: 'missing_section',
        message: '缺少规范章节：${missingSections.join('、')}',
      ),
    );
  }
  final legacySections = <String>[
    for (final title in legacyLessonSections)
      if (_hasSection(lesson.markdown, title)) title,
  ];
  if (legacySections.isNotEmpty) {
    issues.add(
      GovernanceIssue(
        level: 'error',
        lessonId: lesson.id,
        kind: 'legacy_section_heading',
        message: '残留旧章节标题：${legacySections.join('、')}',
      ),
    );
  }
  final corruptRow = termSection.split('\n').any(
    (line) =>
        line.startsWith('|') &&
        (line.contains('判断依据') || line.contains('正确答案是')),
  );
  if (corruptRow) {
    issues.add(
      GovernanceIssue(
        level: 'error',
        lessonId: lesson.id,
        kind: 'corrupt_term_table',
        message: '「术语速查」表格混入了解析残句',
      ),
    );
  }
  return issues;
}

/// 代码题解析必须落在本课主题或关键词上，避免跨域套题。
bool _mentionsLessonDomain(GovernanceLesson lesson, String text) {
  if (lesson.title.isNotEmpty && text.contains(lesson.title)) return true;
  return lesson.keywords.any(
    (keyword) => keyword.length >= 2 && text.contains(keyword),
  );
}

String _normalizeAnswerText(String text) {
  return text
      .replaceAll(RegExp(r'（[A-Za-z0-9_.-]+ 第 \d+ 题）'), '')
      .replaceAll(RegExp(r'^[「『“"\s]+|[」』”"\s]+$'), '')
      .replaceAll(RegExp(r'[\s。！？!?]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _correctOptions(Map<String, dynamic> question) {
  final options = ((question['options'] as List<dynamic>?) ?? const [])
      .map((item) => item.toString())
      .toList();
  final direct = (question['answer'] as num?)?.toInt();
  if (direct != null && direct >= 0 && direct < options.length) {
    return <String>[options[direct]];
  }
  final answers = (question['answers'] as List<dynamic>?) ?? const [];
  if (answers.isNotEmpty) {
    final indexes = answers
        .map(
          (value) =>
              value is num ? value.toInt() : int.tryParse(value.toString()),
        )
        .whereType<int>()
        .where((value) => value >= 0 && value < options.length)
        .toList();
    if (indexes.isNotEmpty) {
      return indexes.map((index) => options[index]).toList();
    }
  }
  final order = (question['correct_order'] as List<dynamic>?) ?? const [];
  if (order.isNotEmpty) {
    final indexes = order
        .map(
          (value) =>
              value is num ? value.toInt() : int.tryParse(value.toString()),
        )
        .whereType<int>()
        .where((value) => value >= 0 && value < options.length)
        .toList();
    if (indexes.isNotEmpty) {
      return indexes.map((index) => options[index]).toList();
    }
  }
  final accepted = (question['accepted_answers'] as List<dynamic>?) ?? const [];
  if (accepted.isNotEmpty) return <String>[accepted.first.toString()];
  return const <String>[];
}

List<GovernanceReference> _extractReferences(String markdown) {
  final section = _section(markdown, '参考资料与复核');
  final result = <GovernanceReference>[];
  final seen = <String>{};
  for (final match in RegExp(
    r'\[([^\]]+)\]\((https?://[^)\s]+)\)',
  ).allMatches(section)) {
    final url = match.group(2)!.trim();
    if (!seen.add(url)) continue;
    result.add(GovernanceReference(match.group(1)!.trim(), url));
  }
  return result;
}

RegExp _sectionHeadingPattern(String title) =>
    RegExp('^##\\s+${RegExp.escape(title)}\\s*\$', multiLine: true);

/// 把代码围栏内的行替换成等长空格：示例里的 `## 标题` 不是章节，
/// 但保持长度不变，才能继续用匹配偏移量从原文截取章节正文。
String _maskFencedLines(String markdown) {
  final lines = markdown.split('\n');
  final mask = markdownFenceMask(markdown);
  final buffer = StringBuffer();
  for (var index = 0; index < lines.length; index++) {
    buffer.write(mask[index] ? ' ' * lines[index].length : lines[index]);
    if (index < lines.length - 1) buffer.write('\n');
  }
  return buffer.toString();
}

bool _hasSection(String markdown, String title) =>
    _sectionHeadingPattern(title).hasMatch(_maskFencedLines(markdown));

String _section(String markdown, String title) {
  final masked = _maskFencedLines(markdown);
  final match = _sectionHeadingPattern(title).firstMatch(masked);
  if (match == null) return '';
  final start = match.end;
  final next = RegExp(
    r'^##\s+',
    multiLine: true,
  ).firstMatch(masked.substring(start));
  return next == null
      ? markdown.substring(start)
      : markdown.substring(start, start + next.start);
}

Iterable<String> _extractParagraphs(String markdown) sync* {
  var inFence = false;
  final seen = <String>{};
  for (final rawLine in markdown.split('\n')) {
    final line = rawLine.trim();
    if (line.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence ||
        line.isEmpty ||
        line.startsWith('#') ||
        line.startsWith('![') ||
        line.startsWith('|') ||
        line.startsWith('<!--')) {
      continue;
    }
    // 元数据行（更新 / 复核 / 版本时间戳）在多课之间天然重复，
    // 不是正文冗余，排除在段落重复统计之外。
    final metadata = line.replaceFirst(RegExp(r'^>\s*'), '');
    if (_metadataPrefixes.any(metadata.startsWith)) continue;
    final normalized = line
        .replaceFirst(RegExp(r'^[-*+\d.\s]+'), '')
        .replaceAll(RegExp(r'[*_`]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // 只统计完整句子或较长条目，短标签不视为机械填充。
    if (normalized.length < 40 || !seen.add(normalized)) continue;
    yield normalized;
  }
}

const List<String> _metadataPrefixes = <String>[
  '内容更新时间：',
  '内容版本：',
  '最后更新：',
  '最后复核：',
  '下次复核：',
  '质量版本：',
];

List<String> _splitSentences(String text) {
  return text
      .split(RegExp(r'(?<=[。！？!?；;])'))
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
}

String _short(String text, int maxLength) {
  return text.length <= maxLength ? text : '${text.substring(0, maxLength)}…';
}

int _countKind(List<GovernanceIssue> issues, String kind) =>
    issues.where((issue) => issue.kind == kind).length;

/// 学习路径不变量审计。
///
/// 1. 分类内 order 必须是 0..n-1 的连续编号；
/// 2. 按 order 排序后难度必须非递减（推荐顺序即学习顺序）；
/// 3. 先修课必须排在本课之前，且难度不得高于本课；
/// 4. 预计用时必须等于 tool/lesson_effort.dart 的模型输出。
List<GovernanceIssue> _auditLearningPath(List<GovernanceLesson> lessons) {
  final issues = <GovernanceIssue>[];
  final byId = <String, GovernanceLesson>{
    for (final lesson in lessons) lesson.id: lesson,
  };
  final byCategory = <String, List<GovernanceLesson>>{};
  for (final lesson in lessons) {
    byCategory.putIfAbsent(lesson.categoryId, () => <GovernanceLesson>[]).add(lesson);
  }

  for (final entry in byCategory.entries) {
    final ordered = <GovernanceLesson>[...entry.value]
      ..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].order != i) {
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: ordered[i].id,
            kind: 'order_gap',
            message:
                '分类 ${entry.key} 的 order 必须是 0..${ordered.length - 1} 的连续编号，'
                '「${ordered[i].title}」实际为 ${ordered[i].order}',
          ),
        );
        break;
      }
    }
    for (var i = 1; i < ordered.length; i++) {
      final previous = ordered[i - 1];
      final current = ordered[i];
      if (difficultyRank(current.difficulty) <
          difficultyRank(previous.difficulty)) {
        issues.add(
          GovernanceIssue(
            level: 'error',
            lessonId: current.id,
            kind: 'difficulty_inversion',
            message:
                '推荐顺序出现难度倒挂：「${previous.title}」(${previous.difficulty}) '
                '之后是更简单的「${current.title}」(${current.difficulty})',
          ),
        );
      }
    }
    final position = <String, int>{
      for (var i = 0; i < ordered.length; i++) ordered[i].id: i,
    };
    for (final lesson in ordered) {
      for (final id in lesson.prerequisites) {
        final prerequisite = byId[id];
        if (prerequisite == null) continue;
        if (difficultyRank(prerequisite.difficulty) >
            difficultyRank(lesson.difficulty)) {
          issues.add(
            GovernanceIssue(
              level: 'error',
              lessonId: lesson.id,
              kind: 'prerequisite_violation',
              message:
                  '先修「${prerequisite.title}」(${prerequisite.difficulty}) '
                  '比本课(${lesson.difficulty})更难',
            ),
          );
        }
        final prerequisitePosition = position[id];
        final selfPosition = position[lesson.id];
        if (prerequisitePosition != null &&
            selfPosition != null &&
            prerequisitePosition >= selfPosition) {
          issues.add(
            GovernanceIssue(
              level: 'error',
              lessonId: lesson.id,
              kind: 'prerequisite_violation',
              message: '先修「${prerequisite.title}」没有排在「${lesson.title}」之前',
            ),
          );
        }
      }
    }
  }

  for (final lesson in lessons) {
    if (lesson.markdown.isEmpty) continue;
    final effort = measureEffort(
      lesson.markdown,
      quizCount: lesson.quiz.length,
      handsOn: isHandsOnLesson(id: lesson.id, title: lesson.title),
    );
    final ideal = estimateMinutes(effort);
    if (lesson.minutes != ideal) {
      issues.add(
        GovernanceIssue(
          level: 'error',
          lessonId: lesson.id,
          kind: 'minutes_drift',
          message:
              '预计用时 ${lesson.minutes} 分钟与内容量不符：'
              '${effort.chars} 字 / ${effort.codeBlocks} 个代码块 / '
              '${effort.quizCount} 题，模型应为 $ideal 分钟',
        ),
      );
    }
  }
  return issues;
}

int _intOption(List<String> args, String prefix, int fallback) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    return int.tryParse(arg.substring(prefix.length)) ?? fallback;
  }
  return fallback;
}

String _stringOption(List<String> args, String prefix, String fallback) {
  for (final arg in args) {
    if (!arg.startsWith(prefix)) continue;
    return arg.substring(prefix.length);
  }
  return fallback;
}

class GovernanceLesson {
  const GovernanceLesson({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.keywords,
    required this.markdown,
    required this.quiz,
    required this.codeQuiz,
    required this.order,
    required this.difficulty,
    required this.prerequisites,
    required this.minutes,
  });

  final String id;
  final String categoryId;
  final String title;
  final List<String> keywords;
  final String markdown;
  final List<Map<String, dynamic>> quiz;
  final Map<String, dynamic>? codeQuiz;

  /// 分类内推荐顺序（0 起连续编号）。
  final int order;

  /// 难度梯度：入门 / 基础 / 进阶 / 高级。
  final String difficulty;

  /// 先修知识点 ID。
  final List<String> prerequisites;

  /// 预计用时（分钟），必须与 tool/lesson_effort.dart 的模型一致。
  final int minutes;
}

class GovernanceReference {
  const GovernanceReference(this.name, this.url);

  final String name;
  final String url;
}

class GovernanceIssue {
  const GovernanceIssue({
    required this.level,
    required this.lessonId,
    required this.kind,
    required this.message,
  });

  final String level;
  final String lessonId;
  final String kind;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'level': level,
    'lesson_id': lessonId,
    'kind': kind,
    'message': message,
  };
}
