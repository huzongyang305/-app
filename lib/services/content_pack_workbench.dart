import 'dart:convert';

/// 内容包分析结果：导入前在工作台里预览，避免直接把问题内容并入内置课程。
class ContentPackAnalysis {
  const ContentPackAnalysis({
    required this.packId,
    required this.version,
    required this.lessonCount,
    required this.categoryCount,
    required this.questionCount,
    required this.totalCharacters,
    required this.lessons,
    required this.issues,
  });

  final String packId;
  final String version;
  final int lessonCount;
  final int categoryCount;
  final int questionCount;
  final int totalCharacters;
  final List<ContentPackLessonSummary> lessons;
  final List<ContentPackIssue> issues;

  bool get hasErrors =>
      issues.any((item) => item.severity == ContentPackIssueSeverity.error);

  int get estimatedMinutes =>
      lessons.fold<int>(0, (sum, lesson) => sum + lesson.minutes);
}

/// 单个内容包课程的概要。
class ContentPackLessonSummary {
  const ContentPackLessonSummary({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.questions,
    required this.characters,
    required this.minutes,
  });

  final String id;
  final String categoryId;
  final String title;
  final int questions;
  final int characters;
  final int minutes;
}

enum ContentPackIssueSeverity { error, warning, info }

class ContentPackIssue {
  const ContentPackIssue({
    required this.severity,
    required this.message,
    this.lessonId,
  });

  final ContentPackIssueSeverity severity;
  final String message;
  final String? lessonId;

  String render() {
    final prefix = switch (severity) {
      ContentPackIssueSeverity.error => '[错误]',
      ContentPackIssueSeverity.warning => '[警告]',
      ContentPackIssueSeverity.info => '[提示]',
    };
    final target = lessonId == null ? '' : '（$lessonId）';
    return '$prefix$target $message';
  }
}

/// 内容包对照结果，用于「本次导入会带来什么变化」预览。
class ContentPackDiff {
  const ContentPackDiff({
    required this.added,
    required this.updated,
    required this.unchanged,
    required this.removed,
  });

  final List<String> added;
  final List<String> updated;
  final List<String> unchanged;
  final List<String> removed;

  bool get hasChanges =>
      added.isNotEmpty || updated.isNotEmpty || removed.isNotEmpty;

  String describe() =>
      '新增 ${added.length} · 更新 ${updated.length} · '
      '不变 ${unchanged.length} · 移除 ${removed.length}';
}

/// 内容包工作台：离线解析、校验、预览与生成模板。
///
/// 不依赖 Flutter 运行时，可在纯 Dart 审计脚本与单元测试中直接使用。
class ContentPackWorkbench {
  const ContentPackWorkbench._();

  static const String schema = 'code-learn-content-pack';
  static const int schemaVersion = 1;

  /// 解析并分析一份内容包 JSON，问题只报告不抛出，便于工作台完整展示。
  static ContentPackAnalysis analyze(Map<String, dynamic> pack) {
    final issues = <ContentPackIssue>[];
    final packId = pack['pack_id']?.toString() ?? '';
    final version = pack['version']?.toString() ?? '';
    if (pack['schema']?.toString() != schema) {
      issues.add(
        const ContentPackIssue(
          severity: ContentPackIssueSeverity.error,
          message: 'schema 必须是 code-learn-content-pack。',
        ),
      );
    }
    if (pack['schema_version'] != schemaVersion) {
      issues.add(
        ContentPackIssue(
          severity: ContentPackIssueSeverity.error,
          message: 'schema_version 必须是 $schemaVersion。',
        ),
      );
    }
    if (packId.trim().isEmpty || version.trim().isEmpty) {
      issues.add(
        const ContentPackIssue(
          severity: ContentPackIssueSeverity.error,
          message: '缺少 pack_id 或 version。',
        ),
      );
    }
    final rawLessons = pack['lessons'];
    if (rawLessons is! List || rawLessons.isEmpty) {
      issues.add(
        const ContentPackIssue(
          severity: ContentPackIssueSeverity.error,
          message: 'lessons 必须是非空数组。',
        ),
      );
      return ContentPackAnalysis(
        packId: packId,
        version: version,
        lessonCount: 0,
        categoryCount: 0,
        questionCount: 0,
        totalCharacters: 0,
        lessons: const <ContentPackLessonSummary>[],
        issues: issues,
      );
    }
    if (rawLessons.length > 1000) {
      issues.add(
        const ContentPackIssue(
          severity: ContentPackIssueSeverity.error,
          message: '单包课程数超过 1000，请拆分内容包。',
        ),
      );
    }
    final lessons = <ContentPackLessonSummary>[];
    final ids = <String>{};
    final categories = <String>{};
    var questionCount = 0;
    var totalCharacters = 0;
    for (final rawLesson in rawLessons) {
      if (rawLesson is! Map) {
        issues.add(
          const ContentPackIssue(
            severity: ContentPackIssueSeverity.error,
            message: 'lessons 中存在非对象元素。',
          ),
        );
        continue;
      }
      final lesson = rawLesson.cast<String, dynamic>();
      final id = lesson['id']?.toString().trim() ?? '';
      final categoryId = lesson['category_id']?.toString().trim() ?? '';
      final title = _localized(lesson['title']);
      final summary = _localized(lesson['summary']);
      final markdown = lesson['markdown']?.toString() ?? '';
      final quiz = (lesson['quiz'] as List?) ?? const <dynamic>[];
      if (id.isEmpty || categoryId.isEmpty) {
        issues.add(
          const ContentPackIssue(
            severity: ContentPackIssueSeverity.error,
            message: '课程缺少 id 或 category_id。',
          ),
        );
        continue;
      }
      if (!ids.add(id)) {
        issues.add(
          ContentPackIssue(
            severity: ContentPackIssueSeverity.error,
            message: '课程 id 重复。',
            lessonId: id,
          ),
        );
      }
      categories.add(categoryId);
      if (title.isEmpty || markdown.trim().isEmpty) {
        issues.add(
          ContentPackIssue(
            severity: ContentPackIssueSeverity.error,
            message: title.isEmpty ? '缺少课程标题。' : '正文 Markdown 为空。',
            lessonId: id,
          ),
        );
      }
      if (summary.isEmpty) {
        issues.add(
          ContentPackIssue(
            severity: ContentPackIssueSeverity.warning,
            message: '缺少课程摘要，列表页会显示为空。',
            lessonId: id,
          ),
        );
      }
      if (markdown.isNotEmpty && markdown.length < 200) {
        issues.add(
          ContentPackIssue(
            severity: ContentPackIssueSeverity.warning,
            message: '正文不足 200 字，可能过于单薄。',
            lessonId: id,
          ),
        );
      }
      if (markdown.length > 1024 * 1024) {
        issues.add(
          ContentPackIssue(
            severity: ContentPackIssueSeverity.error,
            message: '单课正文超过 1MB，请压缩配图或拆分内容。',
            lessonId: id,
          ),
        );
      }
      if (quiz.isEmpty) {
        issues.add(
          ContentPackIssue(
            severity: ContentPackIssueSeverity.info,
            message: '没有配套测验题。',
            lessonId: id,
          ),
        );
      }
      questionCount += quiz.length;
      totalCharacters += markdown.length;
      lessons.add(
        ContentPackLessonSummary(
          id: id,
          categoryId: categoryId,
          title: title,
          questions: quiz.length,
          characters: markdown.length,
          minutes: (lesson['minutes'] as num?)?.toInt() ?? 10,
        ),
      );
    }
    return ContentPackAnalysis(
      packId: packId,
      version: version,
      lessonCount: lessons.length,
      categoryCount: categories.length,
      questionCount: questionCount,
      totalCharacters: totalCharacters,
      lessons: List<ContentPackLessonSummary>.unmodifiable(lessons),
      issues: List<ContentPackIssue>.unmodifiable(issues),
    );
  }

  /// 生成空白内容包模板，便于作者离线填写后导入。
  static String template() {
    const sample = <String, dynamic>{
      'schema': schema,
      'schema_version': schemaVersion,
      'pack_id': 'my-pack',
      'version': '1.0.0',
      'name': '我的离线内容包',
      'lessons': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'my_lesson_1',
          'category_id': 'programming',
          'title': <String, String>{'zh': '示例课程', 'en': 'Sample lesson'},
          'summary': <String, String>{'zh': '一句话摘要', 'en': 'One line'},
          'difficulty': '基础',
          'minutes': 10,
          'keywords': <String>['示例'],
          'markdown': '# 示例课程\n\n在这里写正文。',
          'quiz': <Map<String, dynamic>>[
            <String, dynamic>{
              'question': '示例题目？',
              'options': <String>['选项 A', '选项 B'],
              'answer': 0,
              'explanation': '解析',
              'type': 'single',
            },
          ],
        },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(sample);
  }

  /// 比较当前课程与内容包的课程版本，得出新增 / 更新 / 不变 / 移除。
  static ContentPackDiff diff({
    required Map<String, String> installedVersions,
    required Map<String, String> incomingVersions,
  }) {
    final added = <String>[];
    final updated = <String>[];
    final unchanged = <String>[];
    final removed = <String>[];
    for (final entry in incomingVersions.entries) {
      final installed = installedVersions[entry.key];
      if (installed == null) {
        added.add(entry.key);
      } else if (installed != entry.value) {
        updated.add(entry.key);
      } else {
        unchanged.add(entry.key);
      }
    }
    for (final id in installedVersions.keys) {
      if (!incomingVersions.containsKey(id)) removed.add(id);
    }
    added.sort();
    updated.sort();
    unchanged.sort();
    removed.sort();
    return ContentPackDiff(
      added: added,
      updated: updated,
      unchanged: unchanged,
      removed: removed,
    );
  }

  static String _localized(dynamic value) {
    if (value is Map) {
      final zh = value['zh']?.toString() ?? '';
      if (zh.isNotEmpty) return zh;
      for (final item in value.values) {
        if (item.toString().trim().isNotEmpty) return item.toString();
      }
      return '';
    }
    return value?.toString() ?? '';
  }
}
