import 'package:flutter/services.dart';

/// Android 离线文字转语音服务。
///
/// App 不引入云端语音依赖：原生层使用系统 [android.speech.tts.TextToSpeech]，
/// 没有网络权限也能朗读已经安装语音数据的设备。Dart 层只负责清洗 Markdown
/// 与维护播放状态，具体分片和朗读顺序由原生层完成。
class TtsService {
  const TtsService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'code_learn_app/tts';

  final MethodChannel _channel;

  /// 清洗后可供系统语音引擎朗读的纯文本。
  ///
  /// 代码块不逐字符朗读，否则括号、缩进和符号会严重影响理解；这里用一句
  /// 简短提示代替，并保留图片替代文本、链接标题与正文。
  static String prepareSpeechText(
    String markdown, {
    String codePlaceholder = '代码示例。',
  }) {
    var text = markdown.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' $codePlaceholder ');
    text = text.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
      (match) => ' ${match.group(1) ?? ''} ',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (match) => ' ${match.group(1) ?? ''} ',
    );
    text = text
        .replaceAll(RegExp(r'[#>*_`|~]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text;
  }

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> speak({
    required String text,
    required String localeCode,
    VoidCallback? onDone,
  }) async {
    final prepared = prepareSpeechText(
      text,
      codePlaceholder: localeCode == 'en' ? 'Code example.' : '代码示例。',
    );
    if (prepared.isEmpty) return false;

    _ensureCallbackHandler(onDone);
    try {
      return await _channel.invokeMethod<bool>('speak', <String, Object>{
            'text': prepared,
            'locale': localeCode,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // 桌面测试环境没有原生 TTS，静默降级即可。
    } on PlatformException {
      // 停止失败不会影响页面退出，下一次 speak 会先清空旧队列。
    }
  }

  void _ensureCallbackHandler(VoidCallback? onDone) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDone' || call.method == 'onError') {
        onDone?.call();
      }
      return null;
    });
  }
}
