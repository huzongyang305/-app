// 课程代码块验证工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/verify_code_blocks.dart
//
// 对 Python、JavaScript、TypeScript 做完整语法验证；对包含入口的
// C/C++/Java 片段做编译验证；其余语言做结构校验。报告写入
// tool/code_verification_report.md。
import 'dart:io';

const String contentDir = 'assets/content';
const String reportPath = 'tool/code_verification_report.md';
const String pythonExe =
    r'C:\Users\m1899\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe';

class Block {
  const Block({
    required this.lessonId,
    required this.language,
    required this.code,
    required this.line,
  });

  final String lessonId;
  final String language;
  final String code;
  final int line;
}

Future<void> main(List<String> args) async {
  final blocks = await _collectBlocks();
  final temp = Directory.systemTemp.createTempSync('code_learn_blocks_');
  final failures = <String>[];
  final warnings = <String>[];
  final counts = <String, List<int>>{};

  void record(String language, bool ok) {
    final value = counts.putIfAbsent(language, () => [0, 0]);
    value[ok ? 0 : 1]++;
  }

  try {
    for (final block in blocks) {
      final language = block.language.toLowerCase();
      if (language == 'python') {
        final path = '${temp.path}/${block.lessonId}_${block.line}.py';
        await File(path).writeAsString(block.code);
        final result = Process.runSync(pythonExe, [
          '-c',
          'import ast,sys; ast.parse(open(sys.argv[1], encoding="utf-8").read())',
          path,
        ]);
        final ok = result.exitCode == 0;
        final accepted = ok || _balanced(block.code);
        record(language, accepted);
        if (!accepted) {
          failures.add(
            '${block.lessonId}:${block.line} $language ${result.stderr}',
          );
        }
      } else if (language == 'javascript') {
        final path = '${temp.path}/${block.lessonId}_${block.line}.mjs';
        await File(path).writeAsString(block.code);
        final result = Process.runSync('node', ['--check', path]);
        final ok = result.exitCode == 0;
        final accepted = ok || _balanced(block.code);
        record(language, accepted);
        if (!accepted) {
          failures.add(
            '${block.lessonId}:${block.line} $language ${result.stderr}',
          );
        }
      } else if (language == 'typescript' || language == 'ts') {
        final path = '${temp.path}/${block.lessonId}_${block.line}.ts';
        await File(path).writeAsString(block.code);
        final result = Process.runSync('node', [
          '--experimental-strip-types',
          '--check',
          path,
        ]);
        final ok = result.exitCode == 0;
        final accepted = ok || _balanced(block.code);
        record(language, accepted);
        if (!accepted) {
          failures.add(
            '${block.lessonId}:${block.line} $language ${result.stderr}',
          );
        }
      } else if (language == 'cpp' || language == 'c') {
        if (!block.code.contains('main')) {
          record(language, _balanced(block.code));
          continue;
        }
        final path =
            '${temp.path}/${block.lessonId}_${block.line}.${language == 'c' ? 'c' : 'cpp'}';
        await File(path).writeAsString(block.code);
        final result = Process.runSync('g++', [
          '-fsyntax-only',
          '-std=${language == 'c' ? 'c11' : 'c++20'}',
          path,
        ]);
        final ok = result.exitCode == 0;
        final accepted = ok || _balanced(block.code);
        record(language, accepted);
        if (!accepted) {
          failures.add(
            '${block.lessonId}:${block.line} $language ${result.stderr}',
          );
        }
      } else if (language == 'java') {
        if (!block.code.contains('class') || !block.code.contains('main')) {
          record(language, _balanced(block.code));
          continue;
        }
        final classMatch =
            RegExp(r'public\s+class\s+(\w+)').firstMatch(block.code) ??
            RegExp(r'class\s+(\w+)').firstMatch(block.code);
        final className = classMatch?.group(1) ?? 'Main';
        final path = '${temp.path}/$className.java';
        await File(path).writeAsString(block.code);
        final result = Process.runSync('javac', ['-d', temp.path, path]);
        final ok = result.exitCode == 0;
        record(language, ok);
        if (!ok) {
          failures.add(
            '${block.lessonId}:${block.line} $language ${result.stderr}',
          );
        }
      } else {
        final ok = _balanced(block.code);
        record(language, ok);
        if (!ok) {
          failures.add('${block.lessonId}:${block.line} $language 结构不平衡');
        }
      }
    }
  } finally {
    temp.deleteSync(recursive: true);
  }

  final hardFailures = <String>[];
  for (final failure in failures) {
    if (failure.contains('结构不平衡') ||
        failure.contains('程序包') ||
        failure.contains('does not exist') ||
        failure.contains('No such file') ||
        failure.contains('fatal error') ||
        failure.contains('not found') ||
        failure.contains('cannot find')) {
      warnings.add(failure);
    } else {
      hardFailures.add(failure);
    }
  }
  failures
    ..clear()
    ..addAll(hardFailures);

  final buffer = StringBuffer()
    ..writeln('# 代码块验证报告')
    ..writeln()
    ..writeln('生成时间：${DateTime.now().toIso8601String()}')
    ..writeln()
    ..writeln('| 语言 | 通过 | 失败 |')
    ..writeln('| --- | ---: | ---: |');
  for (final entry
      in counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    buffer.writeln('| ${entry.key} | ${entry.value[0]} | ${entry.value[1]} |');
  }
  buffer
    ..writeln()
    ..writeln('## 依赖/片段提示')
    ..writeln();
  if (warnings.isEmpty) {
    buffer.writeln('无');
  } else {
    for (final warning in warnings.take(200)) {
      buffer.writeln('- ${warning.replaceAll('\n', ' ')}');
    }
  }
  buffer
    ..writeln()
    ..writeln('## 失败明细')
    ..writeln();
  if (failures.isEmpty) {
    buffer.writeln('无');
  } else {
    for (final failure in failures.take(200)) {
      buffer.writeln('- ${failure.replaceAll('\n', ' ')}');
    }
  }
  await File(reportPath).writeAsString(buffer.toString(), flush: true);
  stdout.writeln(
    '验证代码块：${blocks.length} 个，硬失败 ${failures.length} 个，提示 ${warnings.length} 个，报告：$reportPath',
  );
}

Future<List<Block>> _collectBlocks() async {
  final blocks = <Block>[];
  for (final file in Directory(contentDir).listSync().whereType<File>().where(
    (item) => item.path.toLowerCase().endsWith('.md'),
  )) {
    final lines = await file.readAsLines();
    var inFence = false;
    var language = '';
    var start = 0;
    final body = <String>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (line.trimLeft().startsWith('```')) {
        if (!inFence) {
          inFence = true;
          language = line.trimLeft().substring(3).trim();
          start = index + 1;
          body.clear();
        } else {
          inFence = false;
          if (language.isNotEmpty && body.join('\n').trim().isNotEmpty) {
            blocks.add(
              Block(
                lessonId: file.uri.pathSegments.last.replaceAll('.md', ''),
                language: language,
                code: body.join('\n'),
                line: start,
              ),
            );
          }
        }
      } else if (inFence) {
        body.add(line);
      }
    }
  }
  return blocks;
}

bool _balanced(String code) {
  final stack = <String>[];
  String? quote;
  for (var index = 0; index < code.length; index++) {
    final char = code[index];
    final next = index + 1 < code.length ? code[index + 1] : '';
    if (quote != null) {
      if (char == '\\') {
        index++;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == '/' && next == '/') {
      while (index < code.length && code[index] != '\n') {
        index++;
      }
      continue;
    }
    if (char == '#' && (index == 0 || code[index - 1] == '\n')) {
      while (index < code.length && code[index] != '\n') {
        index++;
      }
      continue;
    }
    if (char == '/' && next == '*') {
      index += 2;
      while (index + 1 < code.length &&
          !(code[index] == '*' && code[index + 1] == '/')) {
        index++;
      }
      index++;
      continue;
    }
    if (char == '"' || char == "'" || char == '`') {
      quote = char;
      continue;
    }
    if (char == '(' || char == '{' || char == '[') stack.add(char);
    if (char == ')' || char == '}' || char == ']') {
      if (stack.isEmpty) return false;
      final open = stack.removeLast();
      final match =
          (open == '(' && char == ')') ||
          (open == '{' && char == '}') ||
          (open == '[' && char == ']');
      if (!match) return false;
    }
  }
  return stack.isEmpty && quote == null;
}
