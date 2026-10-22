import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 学习数据备份文件的系统交互服务。
///
/// Android 侧通过 Storage Access Framework 打开系统“另存为”和文件选择器，
/// 分享时使用临时缓存文件与 FileProvider，不会申请存储权限。
class BackupFileService {
  const BackupFileService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'code_learn_app/backup_files';
  static const int maxBackupBytes = 16 * 1024 * 1024;

  final MethodChannel _channel;

  /// 打开系统“另存为”。取消时返回 false。
  Future<bool> saveBackup({
    required String payload,
    required String suggestedName,
  }) async {
    _validatePayload(payload);
    try {
      return await _channel.invokeMethod<bool>('saveBackup', <String, Object>{
            'payload': payload,
            'suggestedName': suggestedName,
          }) ??
          false;
    } on MissingPluginException {
      throw const BackupFileException('backup_file_picker_unavailable');
    } on PlatformException catch (error) {
      throw BackupFileException(error.code, error.message);
    }
  }

  /// 打开系统文件选择器读取备份；取消时返回 null。
  Future<String?> openBackup() async {
    try {
      final result = await _channel.invokeMethod<String>('openBackup');
      if (result != null) _validatePayload(result);
      return result;
    } on MissingPluginException {
      throw const BackupFileException('backup_file_picker_unavailable');
    } on PlatformException catch (error) {
      throw BackupFileException(error.code, error.message);
    }
  }

  /// 调起系统分享面板，把备份发送到文件管理器、云盘或聊天工具。
  Future<bool> shareBackup({
    required String payload,
    required String suggestedName,
  }) async {
    _validatePayload(payload);
    try {
      return await _channel.invokeMethod<bool>('shareBackup', <String, Object>{
            'payload': payload,
            'suggestedName': suggestedName,
          }) ??
          false;
    } on MissingPluginException {
      throw const BackupFileException('backup_share_unavailable');
    } on PlatformException catch (error) {
      throw BackupFileException(error.code, error.message);
    }
  }

  void _validatePayload(String payload) {
    if (payload.isEmpty) {
      throw const BackupFileException('empty_backup');
    }
    if (payload.length > maxBackupBytes) {
      throw const BackupFileException('backup_too_large');
    }
  }
}

/// 可展示给界面的备份文件异常。
class BackupFileException implements Exception {
  const BackupFileException(this.code, [this.detail]);

  final String code;
  final String? detail;

  @override
  String toString() => detail ?? code;
}

/// 旧版本（1.0 及更早）把备份写到应用文档目录，新版改用系统文件选择器后
/// SAF 无法访问该位置；这里保留读写入口，供升级用户找回历史备份。
class LegacyBackupStore {
  const LegacyBackupStore({Future<Directory> Function()? documentsDirectory})
    : _documentsDirectory =
          documentsDirectory ?? getApplicationDocumentsDirectory;

  static const String fileName = 'code_learn_backup.json';

  final Future<Directory> Function() _documentsDirectory;

  Future<File> resolveFile() async {
    final directory = await _documentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  /// 文件不存在时返回 null，而不是抛异常。
  Future<String?> readIfExists() async {
    final file = await resolveFile();
    return file.existsSync() ? file.readAsString() : null;
  }

  /// 写入备份并返回实际文件，便于界面提示用户保存位置。
  Future<File> write(String payload) async {
    final file = await resolveFile();
    await file.writeAsString(payload, flush: true);
    return file;
  }
}
