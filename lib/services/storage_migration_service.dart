import 'storage_service.dart';

/// 本地 Hive 数据结构版本。
///
/// 迁移必须保持幂等：启动时读取版本号，逐级执行缺失的迁移，
/// 完成后写回 [currentVersion]。高于当前客户端认识的版本会直接拒绝，
/// 避免旧版 App 覆盖新版数据。
class StorageMigrationService {
  const StorageMigrationService._();

  static const String versionKey = 'storage_schema_version';
  static const int currentVersion = 2;

  static Future<StorageMigrationResult> run(StorageService storage) async {
    final rawVersion = storage.read(versionKey, defaultValue: 0);
    final storedVersion = rawVersion is int
        ? rawVersion
        : int.tryParse(rawVersion?.toString() ?? '') ?? 0;

    if (storedVersion > currentVersion) {
      throw StorageMigrationException(storedVersion, currentVersion);
    }
    if (storedVersion == currentVersion) {
      return const StorageMigrationResult(
        fromVersion: currentVersion,
        toVersion: currentVersion,
        migrated: false,
      );
    }

    var version = storedVersion;
    if (version < 1) {
      version = 1;
    }
    if (version < 2) {
      await _backfillIndexes(storage);
      version = 2;
    }
    await storage.write(versionKey, version);
    return StorageMigrationResult(
      fromVersion: storedVersion,
      toVersion: version,
      migrated: true,
    );
  }

  /// 旧版本通过扫描 `quiz_result_*` / `note_*` 还原详情，但没有维护
  /// 全量 ID 索引。v2 启动时补齐索引，供后续增量加载和诊断使用。
  static Future<void> _backfillIndexes(StorageService storage) async {
    final keys = storage.keys.toList(growable: false);
    if (storage.read('all_quiz_ids') == null) {
      final quizIds =
          keys
              .where((key) => key.startsWith('quiz_result_'))
              .map((key) => key.substring('quiz_result_'.length))
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      await storage.write('all_quiz_ids', quizIds);
    }
    if (storage.read('all_note_ids') == null) {
      final noteIds =
          keys
              .where((key) => key.startsWith('note_'))
              .map((key) => key.substring('note_'.length))
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      await storage.write('all_note_ids', noteIds);
    }
  }
}

class StorageMigrationResult {
  const StorageMigrationResult({
    required this.fromVersion,
    required this.toVersion,
    required this.migrated,
  });

  final int fromVersion;
  final int toVersion;
  final bool migrated;
}

class StorageMigrationException implements Exception {
  const StorageMigrationException(this.storedVersion, this.supportedVersion);

  final int storedVersion;
  final int supportedVersion;

  @override
  String toString() =>
      'storage_schema_too_new:$storedVersion>$supportedVersion';
}
