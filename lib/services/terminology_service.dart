import '../models/lesson_term.dart';

/// 从课文 Markdown 中提取「术语速查」表，生成术语闪卡的原料。
///
/// 九段式教材每篇都有 `| 术语 | 一句话说明 |` 表格，且正文与附录可能
/// 各出现一次；这里按术语文本去重，只保留第一次出现的解释。
class TerminologyService {
  const TerminologyService._();

  /// 单篇课文最多返回的术语数量，避免长表格淹没闪卡队列。
  static const int maxTermsPerLesson = 12;

  static List<LessonTerm> extract(String markdown) {
    final lines = markdown.split('\n');
    final seen = <String>{};
    final result = <LessonTerm>[];
    var i = 0;
    while (i < lines.length) {
      if (!_isTermHeader(lines[i])) {
        i++;
        continue;
      }
      var j = i + 1;
      while (j < lines.length && _isTableRow(lines[j])) {
        final cells = _splitRow(lines[j]);
        if (!_isSeparator(cells) && !_isTermHeaderRow(cells)) {
          final term = _clean(cells.first);
          final explanation = _clean(
            cells.skip(1).where((cell) => cell.trim().isNotEmpty).join('；'),
          );
          if (term.isNotEmpty && explanation.isNotEmpty && seen.add(term)) {
            result.add(LessonTerm(term: term, explanation: explanation));
            if (result.length >= maxTermsPerLesson) return result;
          }
        }
        j++;
      }
      i = j;
    }
    return result;
  }

  static bool _isTermHeader(String line) {
    if (!_isTableRow(line)) return false;
    final cells = _splitRow(line);
    return cells.isNotEmpty && _clean(cells.first) == '术语';
  }

  static bool _isTermHeaderRow(List<String> cells) =>
      cells.isNotEmpty && _clean(cells.first) == '术语';

  static bool _isTableRow(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('|') && trimmed.endsWith('|');
  }

  static bool _isSeparator(List<String> cells) =>
      cells.isNotEmpty &&
      cells.every((cell) => RegExp(r'^:?-{2,}:?$').hasMatch(cell.trim()));

  /// 按未转义的竖线切分表格行，保留行内代码里的 `|`。
  static List<String> _splitRow(String line) {
    final trimmed = line.trim();
    final inner = trimmed.substring(1, trimmed.length - 1);
    final cells = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < inner.length; i++) {
      final char = inner[i];
      if (char == r'\' && i + 1 < inner.length && inner[i + 1] == '|') {
        buffer.write('|');
        i++;
      } else if (char == '|') {
        cells.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    cells.add(buffer.toString());
    return cells;
  }

  /// 去掉行内 Markdown 标记，保证卡片正反面是可直接阅读的纯文本。
  static String _clean(String value) => value
      .replaceAll('**', '')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
