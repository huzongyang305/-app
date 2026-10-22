/// 沙箱挑战的输出比对逻辑（纯 Dart，可单测，不依赖平台通道）。
class SandboxChallengeService {
  const SandboxChallengeService._();

  /// SQL 沙箱会在文本输出后追加结构化表格标记（base64 JSON），
  /// 它属于界面渲染数据，不参与挑战比对。
  static const String _tableMarker = '##SANDBOX_TABLE##';

  /// 规范化输出文本：
  /// 1. 统一换行符为 \n；
  /// 2. 逐行去掉行尾空白（编辑器 / 运行时可能带尾随空格）；
  /// 3. 丢弃结构化表格标记行；
  /// 4. 去掉开头和结尾的空行。
  static String normalize(String raw) {
    final lines = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((line) => !line.trimLeft().startsWith(_tableMarker))
        .map((line) => line.replaceFirst(RegExp(r'[ \t]+$'), ''))
        .toList();
    var start = 0;
    var end = lines.length;
    while (start < end && lines[start].trim().isEmpty) {
      start++;
    }
    while (end > start && lines[end - 1].trim().isEmpty) {
      end--;
    }
    return lines.sublist(start, end).join('\n');
  }

  /// 判断运行输出是否通过挑战：规范化后逐字符完全一致。
  static bool matches({required String actual, required String expected}) {
    return normalize(actual) == normalize(expected);
  }

  /// 判断输出是否像一条运行错误（用于给学习者更明确的失败提示）。
  static bool looksLikeError(String output) {
    final text = normalize(output);
    if (text.isEmpty) return false;
    return text.startsWith('Error:') ||
        text.contains('\nError:') ||
        text.startsWith('执行失败') ||
        text.startsWith('执行超时') ||
        text.contains('Traceback (most recent call last)');
  }
}
