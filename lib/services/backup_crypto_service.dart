import 'dart:convert';

import 'package:flutter/services.dart';

/// 备份加密服务。
///
/// Android 侧使用 PBKDF2 派生密钥、AES-256-GCM 认证加密；Dart 侧只负责
/// 调用平台通道和识别备份信封，不把密码写入数据库或日志。
class BackupCryptoService {
  const BackupCryptoService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('code_learn_app/backup_crypto');

  static const String envelopePrefix = 'CLB1:';
  static const String channelName = 'code_learn_app/backup_crypto';

  final MethodChannel _channel;

  bool isEncrypted(String payload) =>
      payload.trimLeft().startsWith(envelopePrefix);

  Future<String> encryptJson(Map<String, dynamic> data, String password) async {
    if (password.isEmpty) {
      throw const BackupCryptoException('backup_password_required');
    }
    return encryptText(jsonEncode(data), password);
  }

  Future<String> encryptText(String plainText, String password) async {
    if (password.isEmpty) {
      throw const BackupCryptoException('backup_password_required');
    }
    try {
      final result = await _channel.invokeMethod<String>('encrypt', {
        'plainText': plainText,
        'password': password,
      });
      if (result == null || !isEncrypted(result)) {
        throw const BackupCryptoException('backup_encrypt_failed');
      }
      return result;
    } on BackupCryptoException {
      rethrow;
    } on PlatformException {
      throw const BackupCryptoException('backup_encrypt_failed');
    } on MissingPluginException {
      throw const BackupCryptoException('backup_crypto_unavailable');
    }
  }

  Future<Map<String, dynamic>> decryptJson(
    String payload,
    String password,
  ) async {
    final text = await decryptText(payload, password);
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const BackupCryptoException('backup_invalid_format');
    }
    return decoded.cast<String, dynamic>();
  }

  Future<String> decryptText(String payload, String password) async {
    if (password.isEmpty) {
      throw const BackupCryptoException('backup_password_required');
    }
    if (!isEncrypted(payload)) {
      throw const BackupCryptoException('backup_not_encrypted');
    }
    try {
      final result = await _channel.invokeMethod<String>('decrypt', {
        'payload': payload.trim(),
        'password': password,
      });
      if (result == null) {
        throw const BackupCryptoException('backup_decrypt_failed');
      }
      return result;
    } on BackupCryptoException {
      rethrow;
    } on PlatformException {
      throw const BackupCryptoException('backup_decrypt_failed');
    } on MissingPluginException {
      throw const BackupCryptoException('backup_crypto_unavailable');
    }
  }
}

/// 可展示给界面的备份加密异常类型。
class BackupCryptoException implements Exception {
  const BackupCryptoException(this.message);

  final String message;

  @override
  String toString() => message;
}
