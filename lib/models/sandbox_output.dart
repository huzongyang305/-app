import 'dart:convert';

/// SQL / CSV 沙箱输出的结构化表格。
///
/// 运行时会先在文本输出里附一行 `##SANDBOX_TABLE##<base64(JSON)>` 标记，
/// Dart 侧解析后渲染成真正的表格；标记本身不会出现在界面上，复制输出时
/// 也只会复制人类可读的文本部分。
class SandboxTable {
  const SandboxTable({
    required this.columns,
    required this.rows,
    this.truncated = false,
  });

  final List<String> columns;
  final List<List<String>> rows;

  /// 运行时是否因为行数过多而截断。
  final bool truncated;
}

/// 一次沙箱输出解析后的结果：文本 + 可选表格。
class SandboxStructuredOutput {
  const SandboxStructuredOutput({required this.text, this.table});

  /// 面向用户的纯文本（已去掉结构化标记）。
  final String text;

  /// SQL / CSV 等语言附带的表格数据。
  final SandboxTable? table;

  static const String tableMarker = '##SANDBOX_TABLE##';

  /// 从原始输出中分离文本与表格标记。
  ///
  /// 标记行可能出现在任意位置；无法解析的标记会被忽略，保证输出永远可读。
  static SandboxStructuredOutput parse(String raw) {
    final kept = <String>[];
    SandboxTable? table;
    for (final line in raw.split('\n')) {
      if (line.startsWith(tableMarker)) {
        table ??= _decodeTable(line.substring(tableMarker.length).trim());
        continue;
      }
      kept.add(line);
    }
    final text = kept.join('\n').replaceFirst(RegExp(r'\n+$'), '');
    return SandboxStructuredOutput(text: text, table: table);
  }

  static SandboxTable? _decodeTable(String payload) {
    if (payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(payload)));
      if (decoded is! Map) return null;
      final columns =
          (decoded['columns'] as List?)
              ?.map((item) => '$item')
              .toList(growable: false) ??
          const <String>[];
      if (columns.isEmpty) return null;
      final rows = <List<String>>[];
      final rawRows = decoded['rows'];
      if (rawRows is List) {
        for (final row in rawRows) {
          if (row is! List) continue;
          rows.add(row.map((item) => item == null ? 'NULL' : '$item').toList());
          if (rows.length >= 1000) break;
        }
      }
      return SandboxTable(
        columns: columns,
        rows: rows,
        truncated: decoded['truncated'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 正则沙箱的输入约定：第一行表达式，第二行可写 flags，其余行为待匹配文本。
class SandboxRegexSpec {
  const SandboxRegexSpec({
    required this.pattern,
    required this.flags,
    required this.text,
  });

  final String pattern;
  final String flags;
  final String text;

  bool get caseSensitive => !flags.contains('i');
  bool get multiLine => flags.contains('m');
  bool get dotAll => flags.contains('s');
  bool get unicode => flags.contains('u');

  /// 解析失败（表达式不合法）时返回 null，由界面回退到纯文本输出。
  static SandboxRegexSpec? tryParse(String source) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (normalized.trim().isEmpty) return null;
    final lines = normalized.split('\n');
    if (lines.isEmpty) return null;
    final pattern = lines.removeAt(0);
    var flags = '';
    if (lines.isNotEmpty &&
        RegExp(r'^[dgimsuvy]*$').hasMatch(lines[0].trim())) {
      flags = lines.removeAt(0).trim();
    }
    return SandboxRegexSpec(
      pattern: pattern,
      flags: flags,
      text: lines.join('\n'),
    );
  }

  /// 编译表达式；不合法时返回 null。
  RegExp? compile() {
    try {
      return RegExp(
        pattern,
        caseSensitive: caseSensitive,
        multiLine: multiLine,
        dotAll: dotAll,
        unicode: unicode,
      );
    } on FormatException {
      return null;
    }
  }
}
