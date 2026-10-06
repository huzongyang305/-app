import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 代码编辑输入框：在普通 TextField 之上提供适合写代码的编辑体验。
///
/// 增强点：
///   * Tab / Shift+Tab 对当前行或选中行做缩进、反缩进（硬件键盘可用）；
///   * 回车自动继承上一行缩进，遇到 `{`、`(`、`[`、`:` 再增加一级；
///   * 在成对括号中间回车时自动展开成三行，并把光标放在中间；
///   * 自动补全 `()`、`[]`、`{}`、引号，再次输入闭合并时直接跳过。
///
/// 这些能力对触屏键盘同样有效：手机键盘上的换行键会走同一个自动缩进逻辑。
class CodeEditorField extends StatefulWidget {
  const CodeEditorField({
    super.key,
    required this.controller,
    this.style,
    this.decoration,
    this.minLines,
    this.maxLines,
    this.expands = false,
    this.autofocus = false,
    this.readOnly = false,
    this.textAlignVertical,
    this.enableEnhancements = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final bool autofocus;
  final bool readOnly;
  final TextAlignVertical? textAlignVertical;

  /// 关闭后等价于普通 TextField（例如标准输入框无需括号补全）。
  final bool enableEnhancements;

  final ValueChanged<String>? onChanged;

  @override
  State<CodeEditorField> createState() => _CodeEditorFieldState();
}

class _CodeEditorFieldState extends State<CodeEditorField> {
  /// 缩进宽度：两个空格，兼顾手机键盘输入与代码可读性。
  static const String _indentUnit = '  ';

  void _indentSelection() {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid) return;

    if (selection.isCollapsed) {
      _replace(
        value,
        selection.start,
        selection.end,
        _indentUnit,
        caretOffset: _indentUnit.length,
      );
      return;
    }

    final text = value.text;
    final lineStart = _lineStart(text, selection.start);
    final selected = text.substring(lineStart, selection.end);
    final indented = selected
        .split('\n')
        .map((line) => '$_indentUnit$line')
        .join('\n');
    widget.controller.value = TextEditingValue(
      text: text.replaceRange(lineStart, selection.end, indented),
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + indented.length,
      ),
    );
  }

  void _dedentSelection() {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid) return;

    final text = value.text;
    final lineStart = _lineStart(text, selection.start);
    final lineEnd = selection.isCollapsed
        ? _lineEnd(text, selection.start)
        : selection.end;
    final selected = text.substring(lineStart, lineEnd);
    final dedented = selected.split('\n').map(_removeIndent).join('\n');
    if (dedented == selected) return;

    widget.controller.value = TextEditingValue(
      text: text.replaceRange(lineStart, lineEnd, dedented),
      selection: TextSelection(
        baseOffset: lineStart,
        extentOffset: lineStart + dedented.length,
      ),
    );
  }

  static String _removeIndent(String line) {
    if (line.startsWith('\t')) return line.substring(1);
    if (line.startsWith(_indentUnit)) return line.substring(_indentUnit.length);
    if (line.startsWith(' ')) return line.substring(1);
    return line;
  }

  static int _lineStart(String text, int offset) {
    if (offset <= 0) return 0;
    final index = text.lastIndexOf('\n', offset - 1);
    return index < 0 ? 0 : index + 1;
  }

  static int _lineEnd(String text, int offset) {
    if (offset >= text.length) return text.length;
    final index = text.indexOf('\n', offset);
    return index < 0 ? text.length : index;
  }

  void _replace(
    TextEditingValue value,
    int start,
    int end,
    String replacement, {
    required int caretOffset,
  }) {
    widget.controller.value = TextEditingValue(
      text: value.text.replaceRange(start, end, replacement),
      selection: TextSelection.collapsed(offset: start + caretOffset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      expands: widget.expands,
      maxLines: widget.expands ? null : widget.maxLines,
      minLines: widget.expands ? null : widget.minLines,
      textAlignVertical: widget.textAlignVertical,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: widget.style,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
      inputFormatters: widget.enableEnhancements
          ? const <TextInputFormatter>[
              _AutoIndentFormatter(),
              _AutoCloseFormatter(),
            ]
          : null,
    );

    if (!widget.enableEnhancements) return field;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.tab): _indentSelection,
        const SingleActivator(LogicalKeyboardKey.tab, shift: true):
            _dedentSelection,
      },
      child: field,
    );
  }
}

/// 用户是否只插入了一个换行符。
bool _isSingleNewline(TextEditingValue oldValue, TextEditingValue newValue) {
  if (newValue.composing.isValid) return false;
  if (!newValue.selection.isCollapsed) return false;
  if (newValue.text.length != oldValue.text.length + 1) return false;
  final caret = newValue.selection.baseOffset;
  return caret > 0 &&
      caret <= newValue.text.length &&
      newValue.text[caret - 1] == '\n';
}

/// 回车自动缩进：继承上一行缩进，块级符号后增加一级。
class _AutoIndentFormatter extends TextInputFormatter {
  const _AutoIndentFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_isSingleNewline(oldValue, newValue)) return newValue;

    final caret = newValue.selection.baseOffset;
    final before = newValue.text.substring(0, caret - 1);
    final after = newValue.text.substring(caret);
    final lineStart = before.lastIndexOf('\n') + 1;
    final lineText = before.substring(lineStart);
    final baseIndent = RegExp(r'^[ \t]*').firstMatch(lineText)?.group(0) ?? '';
    final trimmed = lineText.trimRight();
    final closer = _closerFor(trimmed);

    // 光标正好在两个成对符号之间：展开成三行，光标停在中间。
    if (closer != null && after.startsWith(closer)) {
      final text =
          '${newValue.text.substring(0, caret)}'
          '$baseIndent  \n'
          '$baseIndent$after';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(
          offset: caret + baseIndent.length + 2,
        ),
      );
    }

    final extra = _opensBlock(trimmed) ? '  ' : '';
    if (extra.isEmpty && baseIndent.isEmpty) return newValue;
    return TextEditingValue(
      text: newValue.text.substring(0, caret) + baseIndent + extra + after,
      selection: TextSelection.collapsed(
        offset: caret + baseIndent.length + extra.length,
      ),
    );
  }

  static bool _opensBlock(String line) {
    if (line.isEmpty) return false;
    final last = line[line.length - 1];
    return last == '{' || last == '(' || last == '[' || last == ':';
  }

  static String? _closerFor(String line) {
    if (line.isEmpty) return null;
    switch (line[line.length - 1]) {
      case '{':
        return '}';
      case '(':
        return ')';
      case '[':
        return ']';
      default:
        return null;
    }
  }
}

/// 括号与引号自动补全。
class _AutoCloseFormatter extends TextInputFormatter {
  const _AutoCloseFormatter();

  static const Map<String, String> _pairs = <String, String>{
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
    '`': '`',
  };

  static const String _closers = ')]}"\'`';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid) return newValue;
    if (newValue.text.length != oldValue.text.length + 1) return newValue;
    final selection = newValue.selection;
    if (!selection.isCollapsed) return newValue;
    final caret = selection.baseOffset;
    if (caret <= 0 || caret > newValue.text.length) return newValue;

    final inserted = newValue.text[caret - 1];
    final after = newValue.text.substring(caret);

    // 已有闭合符号时直接跳过，避免写出 `))`。
    if (_closers.contains(inserted) && after.startsWith(inserted)) {
      return TextEditingValue(
        text: newValue.text.substring(0, caret - 1) + after,
        selection: TextSelection.collapsed(offset: caret),
      );
    }

    final closer = _pairs[inserted];
    if (closer == null) return newValue;
    if (_shouldSkip(inserted, newValue.text, caret)) return newValue;

    return TextEditingValue(
      text: newValue.text.substring(0, caret) + closer + after,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  /// 引号出现在单词旁（don't）、括号后紧跟字母数字时不自动补全，
  /// 避免破坏已有的代码或英文缩写。
  static bool _shouldSkip(String inserted, String text, int caret) {
    final previous = caret >= 2 ? text[caret - 2] : '';
    final next = caret < text.length ? text[caret] : '';
    final isQuote = inserted == '"' || inserted == "'" || inserted == '`';
    if (isQuote && (_isWord(previous) || _isWord(next))) return true;
    if (!isQuote && _isWord(next)) return true;
    return false;
  }

  static bool _isWord(String character) {
    if (character.isEmpty) return false;
    final code = character.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        character == '_' ||
        character == r'$';
  }
}
