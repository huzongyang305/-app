import 'package:flutter/services.dart';

import 'backup_file_service.dart';

/// 自动备份目录中的一份备份文件。
class AutoBackupEntry {
  const AutoBackupEntry({required this.name, required this.modifiedAt});

  final String name;
  final DateTime? modifiedAt;
}

/// 一次自动备份的写入结果。
class AutoBackupWriteResult {
  const AutoBackupWriteResult({required this.name, required this.deleted});

  final String name;

  /// 因超出保留份数而被清理的旧备份数量。
  final int deleted;
}

/// 自动备份：通过 SAF 目录长期授权，把备份直接写进用户选定的文件夹。
///
/// 所有操作都在本机完成，不依赖网络；目录授权由 Android 系统持久保存，
/// 重启 App 后仍然有效。
class AutoBackupService {
  const AutoBackupService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(BackupFileService.channelName);

  static const String fileNamePrefix = 'code_learn_backup_';

  final MethodChannel _channel;

  /// 打开系统目录选择器并取得长期写入授权；取消时返回 null。
  Future<String?> pickFolder() async {
    try {
      return await _channel.invokeMethod<String>('pickBackupFolder');
    } on MissingPluginException {
      throw const BackupFileException('backup_file_picker_unavailable');
    } on PlatformException catch (error) {
      throw BackupFileException(error.code, error.message);
    }
  }

  /// 当前已授权的目录 URI；未设置时为 null。
  Future<String?> currentFolder() async {
    try {
      return await _channel.invokeMethod<String>('getBackupFolder');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// 释放目录授权（关闭自动备份时调用）。
  Future<void> clearFolder() async {
    try {
      await _channel.invokeMethod<bool>('clearBackupFolder');
    } on MissingPluginException {
      // 桌面/测试环境没有原生实现，忽略即可。
    } on PlatformException {
      // 授权可能已失效，不影响 UI 状态。
    }
  }

  /// 写入一份备份，并按 [keepCount] 清理最旧的文件。
  ///
  /// 未选择目录时返回 null。
  Future<AutoBackupWriteResult?> writeBackup({
    required String payload,
    required String suggestedName,
    required int keepCount,
  }) async {
    if (payload.isEmpty) {
      throw const BackupFileException('empty_backup');
    }
    if (payload.length > BackupFileService.maxBackupBytes) {
      throw const BackupFileException('backup_too_large');
    }
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'writeAutoBackup',
        <String, Object>{
          'payload': payload,
          'suggestedName': suggestedName,
          'keepCount': keepCount,
        },
      );
      if (result == null) return null;
      return AutoBackupWriteResult(
        name: result['name']?.toString() ?? suggestedName,
        deleted: result['deleted'] is int ? result['deleted'] as int : 0,
      );
    } on MissingPluginException {
      throw const BackupFileException('backup_file_picker_unavailable');
    } on PlatformException catch (error) {
      throw BackupFileException(error.code, error.message);
    }
  }

  /// 列出目录中已有的备份文件（按修改时间倒序）。
  Future<List<AutoBackupEntry>> listBackups() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('listAutoBackups');
      if (raw == null) return const <AutoBackupEntry>[];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((item) {
            final modified = item['modifiedAt'];
            return AutoBackupEntry(
              name: item['name']?.toString() ?? '',
              modifiedAt: modified is int && modified > 0
                  ? DateTime.fromMillisecondsSinceEpoch(modified)
                  : null,
            );
          })
          .where((entry) => entry.name.isNotEmpty)
          .toList(growable: false);
    } on MissingPluginException {
      return const <AutoBackupEntry>[];
    } on PlatformException {
      return const <AutoBackupEntry>[];
    }
  }

  /// 自动备份文件命名：code_learn_backup_yyyyMMdd_HHmmss.json。
  static String backupFileName(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '$fileNamePrefix'
        '${time.year}${two(time.month)}${two(time.day)}_'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}.json';
  }
}

/// 自动备份调度：启动 / 回到前台时检查是否到期。
class AutoBackupCoordinator {
  const AutoBackupCoordinator({this.service = const AutoBackupService()});

  final AutoBackupService service;

  /// 到期时写入一份备份并返回文件名；未开启、未配置目录或未到期时返回 null。
  Future<String?> maybeRun({
    required bool enabled,
    required int intervalDays,
    required int keepCount,
    required DateTime? lastBackupAt,
    required DateTime now,
    required String payload,
  }) async {
    if (!enabled) return null;
    if (lastBackupAt != null) {
      final due = lastBackupAt.add(Duration(days: intervalDays));
      if (now.isBefore(due)) return null;
    }
    final folder = await service.currentFolder();
    if (folder == null || folder.isEmpty) return null;
    final result = await service.writeBackup(
      payload: payload,
      suggestedName: AutoBackupService.backupFileName(now),
      keepCount: keepCount,
    );
    return result?.name;
  }
}
