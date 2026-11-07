/// 备份恢复方式。
enum BackupImportMode { replace, merge }

/// 恢复前预览：让用户先知道文件里有什么，再决定覆盖还是合并。
class BackupPreview {
  const BackupPreview({
    required this.exportedAt,
    required this.formatVersion,
    required this.learned,
    required this.favorites,
    required this.quizResults,
    required this.notes,
    required this.wrongQuestions,
    required this.studyDays,
    this.settings = 0,
    this.snippets = 0,
    this.sandboxDrafts = 0,
  });

  final DateTime? exportedAt;
  final int formatVersion;
  final int learned;
  final int favorites;
  final int quizResults;
  final int notes;
  final int wrongQuestions;
  final int studyDays;

  /// 备份中包含的界面设置项数；0 表示旧版备份没有该分区。
  final int settings;

  /// 代码片段数量。
  final int snippets;

  /// 沙盒草稿数量（按语言计）。
  final int sandboxDrafts;

  factory BackupPreview.fromData(Map<String, dynamic> data) {
    Map<String, dynamic> map(dynamic value) =>
        value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
    List<dynamic> list(dynamic value) =>
        value is List ? value : const <dynamic>[];
    final version = int.tryParse(data['schema_version']?.toString() ?? '') ?? 1;
    return BackupPreview(
      exportedAt: DateTime.tryParse(data['exported_at']?.toString() ?? ''),
      formatVersion: version,
      learned: list(data['learned_ids']).length,
      favorites: list(data['favorite_ids']).length,
      quizResults: map(data['quiz_results']).length,
      notes: map(data['notes']).length,
      wrongQuestions: map(data['wrong_counts']).length,
      studyDays: list(data['study_days']).length,
      settings: map(data['settings']).length,
      snippets: list(data['snippets']).length,
      sandboxDrafts: map(data['sandbox_drafts']).length,
    );
  }

  String get formatLabel =>
      formatVersion <= 1 ? 'v1 / 旧版备份' : 'v$formatVersion';
}
