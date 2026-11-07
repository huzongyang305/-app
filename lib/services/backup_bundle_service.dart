import '../models/backup_preview.dart';
import 'backup_document_service.dart';
import 'progress_provider.dart';
import 'sandbox_draft_service.dart';
import 'settings_provider.dart';
import 'snippet_service.dart';
import 'storage_service.dart';

/// 完整备份包：学习进度 + 界面设置 + 代码片段 + 沙盒草稿 + 阅读位置。
///
/// 手动导出、自动备份与回滚共用同一套组装逻辑，保证任意入口产出的
/// 文件都能完整恢复。旧版只有进度字段的备份仍可导入，缺失的分区保持
/// 本机现状不动。
class BackupBundleService {
  BackupBundleService(this._storage, this._progress, this._settings)
    : _snippets = SnippetService(_storage),
      _drafts = SandboxDraftService(_storage);

  static const String snapshotKey = 'backup_rollback_snapshot';

  final StorageService _storage;
  final ProgressProvider _progress;
  final SettingsProvider _settings;
  final SnippetService _snippets;
  final SandboxDraftService _drafts;

  bool get hasRollbackSnapshot => _storage.read(snapshotKey) is Map;

  /// 组装可导出的完整数据，顶层仍带 backup_document 的格式元数据。
  Map<String, dynamic> buildExportData() {
    final data = _progress.exportData();
    data['settings'] = _settings.exportPreferences();
    data['snippets'] = _snippets.exportJson();
    data['sandbox_drafts'] = _drafts.exportJson();
    data['reading'] = _progress.exportReadingProgress();
    return data;
  }

  /// 恢复完整备份；替换模式同时恢复界面设置，合并模式保留本机偏好。
  Future<void> restore(
    Map<String, dynamic> raw, {
    BackupImportMode mode = BackupImportMode.replace,
  }) async {
    final data = BackupDocumentService.normalizeForImport(raw);
    final localReading = _progress.exportReadingProgress();
    await _storage.write(snapshotKey, buildExportData());
    await _progress.importData(data, mode: mode, writeSnapshot: false);

    final merging = mode == BackupImportMode.merge;
    if (!merging) {
      await _settings.applyPreferences(_map(data['settings']));
    }
    await _snippets.importJson(data['snippets'], merge: merging);
    await _drafts.importJson(data['sandbox_drafts'], merge: merging);
    final reading = data['reading'];
    if (reading is Map) {
      if (merging) {
        // 合并时本机最近阅读位置与既有滚动位置优先，只补入缺失项。
        await _progress.applyReadingProgress(<String, dynamic>{
          'last_lesson_id': localReading['last_lesson_id'],
          'offsets': <String, dynamic>{
            ..._map(reading['offsets']),
            ..._map(localReading['offsets']),
          },
        });
      } else {
        await _progress.applyReadingProgress(reading.cast<String, dynamic>());
      }
    }
  }

  /// 撤销上一次恢复，回到导入前的完整状态。
  Future<bool> rollbackLastImport() async {
    final raw = _storage.read(snapshotKey);
    if (raw is! Map) return false;
    final data = raw.cast<String, dynamic>();
    await _progress.importData(
      data,
      mode: BackupImportMode.replace,
      writeSnapshot: false,
    );
    await _settings.applyPreferences(_map(data['settings']));
    await _snippets.importJson(data['snippets']);
    await _drafts.importJson(data['sandbox_drafts']);
    final reading = data['reading'];
    if (reading is Map) {
      await _progress.applyReadingProgress(reading.cast<String, dynamic>());
    }
    await _storage.delete(snapshotKey);
    return true;
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};
}
