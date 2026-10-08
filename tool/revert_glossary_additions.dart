// 回滚 thicken_glossaries.dart 刚写入的术语行（P1-7 质量返工用）。
//
// 用法：
//   dart tool/revert_glossary_additions.dart
//   dart tool/revert_glossary_additions.dart tool/reports/glossary_thicken_write.txt
//
// 只按写入报告里的「路径｜术语｜说明」精确删除对应表格行，
// 不会动课程原有术语，也不会改正文。
import 'dart:io';

void main(List<String> args) {
  final reportPath =
      args.isNotEmpty ? args[0] : 'tool/reports/glossary_thicken_write.txt';
  final report = File(reportPath);
  if (!report.existsSync()) {
    stderr.writeln('找不到写入报告：$reportPath');
    exitCode = 1;
    return;
  }

  final additions = <String, List<({String term, String description})>>{};
  for (final line in report.readAsLinesSync()) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('+ ')) continue;
    final parts = trimmed.substring(2).split('｜');
    if (parts.length < 3) continue;
    final path = parts[0].trim();
    final term = parts[1].trim();
    final description = parts.sublist(2).join('｜').trim();
    additions
        .putIfAbsent(path, () => <({String term, String description})>[])
        .add((term: term, description: description));
  }

  var removed = 0;
  additions.forEach((path, rows) {
    final file = File(path);
    if (!file.existsSync()) return;
    final original = file.readAsStringSync();
    final newline = original.contains('\r\n') ? '\r\n' : '\n';
    final output = <String>[];
    var inGlossary = false;
    for (final rawLine in original.split('\n')) {
      final line = rawLine.endsWith('\r')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      final trimmed = line.trim();
      if (trimmed.startsWith('## ')) {
        inGlossary = trimmed == '## 术语速查';
        output.add(line);
        continue;
      }
      if (!inGlossary || !trimmed.startsWith('|')) {
        output.add(line);
        continue;
      }
      final cells = trimmed
          .split('|')
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .toList();
      if (cells.length < 2 || cells[0] == '术语') {
        output.add(line);
        continue;
      }
      final shouldRemove = rows.any(
        (row) =>
            _normalize(cells[0]) == _normalize(row.term) &&
            _matches(cells[1], row.description),
      );
      if (shouldRemove) {
        removed++;
        continue;
      }
      output.add(line);
    }
    var next = output.join(newline);
    if (original.endsWith('\n')) next += newline;
    file.writeAsStringSync(next);
  });

  stdout.writeln('已回滚术语行 $removed 行，涉及 ${additions.length} 个课程文件');
}

String _normalize(String text) =>
    text.replaceAll('`', '').replaceAll('**', '').trim();

bool _matches(String actual, String expected) {
  final a = _normalize(actual);
  final b = _normalize(expected);
  return a == b || a.startsWith(b) || b.startsWith(a);
}
