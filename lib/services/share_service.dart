import 'package:flutter/services.dart';

/// 系统分享：把代码或笔记交给 Android 分享面板。
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
}
