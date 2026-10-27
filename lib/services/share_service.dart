import 'package:flutter/services.dart';

/// 系统分享：把代码、笔记或学习卡片交给 Android 分享面板。
///
/// 平台通道不可用（例如单元测试、桌面调试）时返回 false，
/// 调用方可以退回「复制到剪贴板」的兜底路径。
class ShareService {
  const ShareService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'code_learn_app/share';

  final MethodChannel _channel;

  Future<bool> shareText(String text, {String? subject}) async {
    if (text.trim().isEmpty) return false;
    try {
      final result = await _channel.invokeMethod<bool>('shareText', {
        'text': text,
        'subject': subject,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// 分享 PNG 图片（学习卡片、证书）。
  ///
  /// 原生侧把字节写入缓存目录后经 FileProvider 交给系统分享面板，
  /// 不申请存储权限；通道不可用时返回 false。
  Future<bool> shareImage(
    Uint8List bytes, {
    String? fileName,
    String? text,
  }) async {
    if (bytes.isEmpty) return false;
    try {
      final result = await _channel.invokeMethod<bool>('shareImage', {
        'bytes': bytes,
        'fileName': fileName,
        'text': text,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
