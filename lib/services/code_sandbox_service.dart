import 'dart:async';

import 'package:flutter/services.dart';

import '../models/sandbox_language.dart';

/// 离线代码沙箱：通过 Android 原生 WebView 执行代码。
///
/// JavaScript / TypeScript / Python / Lua / SQL / JSON 的运行时全部内置于
/// APK（assets/sandbox），执行时不会访问网络；WebView 每次执行后由原生层销毁。
class CodeSandboxService {
  const CodeSandboxService._();

  static const MethodChannel _channel = MethodChannel('code_learn_app/sandbox');

  /// 沙箱支持的语言，顺序即界面展示顺序。
  static const List<SandboxLanguage> languages = SandboxLanguage.values;

  /// 执行代码并返回输出文本；出错时返回可直接展示的提示文本。
  ///
  /// [stdin] 是按行提供的标准输入，支持 stdin 的语言可以在代码里
  /// 通过 input() / readLine() 读取。
  static Future<String> runCode(
    SandboxLanguage language,
    String code, {
    String stdin = '',
  }) async {
    try {
      final result = await _channel
          .invokeMethod<String>('runCode', <String, Object?>{
            'language': language.id,
            'code': code,
            'stdin': stdin,
          })
          .timeout(language.timeout);
      return (result ?? '').trim();
    } on MissingPluginException {
      return '当前平台暂不支持代码沙箱，请在 Android 设备上运行。';
    } on TimeoutException {
      // 原生层超时会自行销毁 WebView，这里再兜底一次，避免遗留后台页面。
      await destroy();
      return '执行超时：请检查是否有死循环、未结束的异步任务或过大的输入。';
    } on PlatformException catch (error) {
      return '执行失败：${error.message ?? error.code}';
    } catch (error) {
      return '执行失败：$error';
    }
  }

  /// 兼容旧调用：等价于执行 JavaScript。
  static Future<String> runJavaScript(String code) =>
      runCode(SandboxLanguage.javascript, code);

  /// 主动销毁正在运行的沙箱页面（例如用户中途返回）。
  static Future<void> destroy() async {
    try {
      await _channel.invokeMethod<void>('destroySandbox');
    } catch (_) {
      // 平台不支持时忽略。
    }
  }
}
