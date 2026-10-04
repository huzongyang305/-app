// 为部分机器翻译的英文正文添加状态说明（开发期使用）。
import 'dart:io';

const String marker =
    '> Translation status: machine translation (lightweight zh-en model).';

Future<void> main() async {
  final dir = Directory('assets/content_en');
  if (!dir.existsSync()) {
    stderr.writeln('assets/content_en 不存在');
    exitCode = 1;
    return;
  }
  var changed = 0;
  for (final file in dir.listSync().whereType<File>().where(
    (item) => item.path.toLowerCase().endsWith('.md'),
  )) {
    final lines = await file.readAsLines();
    if (lines.any((line) => line.contains(marker))) continue;
    final titleIndex = lines.indexWhere((line) => line.startsWith('# '));
    final note =
        '$marker Technical terms may need review; use the Chinese tutorial as the authoritative version.';
    if (titleIndex >= 0) {
      lines.insertAll(titleIndex + 1, ['', note, '']);
    } else {
      lines.insertAll(0, [note, '']);
    }
    await file.writeAsString('${lines.join('\n')}\n', flush: true);
    changed++;
  }
  stdout.writeln('已标注部分翻译：$changed 篇');
}
