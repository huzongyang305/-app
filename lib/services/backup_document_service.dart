/// 学习数据备份文档的格式与版本校验。
///
/// v1 是旧版无元数据的裸 JSON；v2 在顶层增加 format、schema_version 与
/// exported_at，同时保留原有数据字段，所以旧版 App 仍能读取基本内容。
class BackupDocumentService {
  const BackupDocumentService._();

  static const String format = 'code-learn-backup';
  static const int currentVersion = 2;

  static Map<String, dynamic> prepareForExport(
    Map<String, dynamic> data, {
    DateTime? exportedAt,
  }) {
    return <String, dynamic>{
      'format': format,
      'schema_version': currentVersion,
      'exported_at': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      ...data,
    };
  }

  /// 校验备份并返回可导入的数据。
  ///
  /// 没有格式字段的旧备份按 v1 接受；只有明确声明了 format 时才检查格式名，
  /// 这样旧版明文和加密备份都能继续恢复。
  static Map<String, dynamic> normalizeForImport(Map<String, dynamic> data) {
    final rawFormat = data['format'];
    final rawVersion = data['schema_version'];
    if (rawFormat == null && rawVersion == null) return data;
    if (rawFormat != format) {
      throw const BackupDocumentException('backup_invalid_format');
    }
    final version = rawVersion is int
        ? rawVersion
        : int.tryParse(rawVersion?.toString() ?? '');
    if (version == null || version < 1) {
      throw const BackupDocumentException('backup_invalid_version');
    }
    if (version > currentVersion) {
      throw BackupDocumentException(
        'backup_version_unsupported:$version>$currentVersion',
      );
    }
    return data;
  }
}

class BackupDocumentException implements Exception {
  const BackupDocumentException(this.code);

  final String code;

  @override
  String toString() => code;
}
