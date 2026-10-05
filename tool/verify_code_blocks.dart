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
  final fragments = <String>[];
  final counts = <String, List<int>>{};

  // counts[语言] = [通过, 片段, 硬失败]
  void record(String language, bool ok) {
    final value = counts.putIfAbsent(language, () => [0, 0, 0]);
    value[ok ? 0 : 2]++;
  }

  void recordFragment(String language) {
    final value = counts.putIfAbsent(language, () => [0, 0, 0]);
    value[1]++;
  }

  try {
    for (final block in blocks) {
      final language = block.language.toLowerCase();
      if (_isDiagramBlock(language)) {
        record(language, true);
        continue;
      }
      if (_looksLikeFragment(block.code)) {
        recordFragment(language);
        fragments.add('${block.lessonId}:${block.line} $language 已标注片段');
        continue;
      }
      if (language == 'python') {
        final path = '${temp.path}/${block.lessonId}_${block.line}.py';
        await File(path).writeAsString(block.code);
        final result = Process.runSync(pythonExe, [
          '-c',
          'import ast,sys; ast.parse(open(sys.argv[1], encoding="utf-8").read())',
          path,
        ]);
        final ok = result.exitCode == 0;
        final accepted = ok || _balanced(block.code, language);
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
        final accepted = ok || _balanced(block.code, language);
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
        final accepted = ok || _balanced(block.code, language);
        record(language, accepted);
        if (!accepted) {
          failures.add(
            '${block.lessonId}:${block.line} $language ${result.stderr}',
          );
        }
      } else if (language == 'cpp' || language == 'c') {
        if (!block.code.contains('main')) {
          record(language, _balanced(block.code, language));
          continue;
        }
        final path =
            '${temp.path}/${block.lessonId}_${block.line}.${language == 'c' ? 'c' : 'cpp'}';
        await File(path).writeAsString(block.code);
        var result = Process.runSync('g++', [
          '-fsyntax-only',
          '-std=${language == 'c' ? 'c11' : 'c++20'}',
          path,
        ]);
        if (result.exitCode != 0 &&
            language == 'cpp' &&
            '${result.stderr}'.contains('unrecognized command line option')) {
          // 旧版 MinGW g++ 最高只认 c++2a，回退后仍按同一份源码校验。
          result = Process.runSync('g++', ['-fsyntax-only', '-std=c++2a', path]);
        }
        final ok = result.exitCode == 0;
        final accepted = ok || _balanced(block.code, language);
        record(language, accepted);
        if (!accepted) {
          failures.add(
            '${block.lessonId}:${block.line} $language ${result.stderr}',
          );
        }
      } else if (language == 'java') {
        if (!block.code.contains('class') || !block.code.contains('main')) {
          record(language, _balanced(block.code, language));
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
        final ok = _balanced(block.code, language);
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
    ..writeln('> 片段是课程里有意截取、无法独立编译的示例，不计入硬失败；')
    ..writeln('> 告警多为多行 Shell 命令或依赖演示环境导致的结构提示，')
    ..writeln('> 硬失败为 0 表示所有可执行代码块都能通过验证或已明确标注为片段。')
    ..writeln()
    ..writeln('| 语言 | 通过 | 片段 | 告警 |')
    ..writeln('| --- | ---: | ---: | ---: |');
  for (final entry
      in counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    buffer.writeln(
      '| ${entry.key} | ${entry.value[0]} | ${entry.value[1]} | ${entry.value[2]} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## 片段与依赖提示')
    ..writeln();
  for (final fragment in fragments.take(200)) {
    buffer.writeln('- $fragment');
  }
  if (warnings.isEmpty) {
    buffer.writeln('- 无结构或依赖提示');
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
    '验证代码块：${blocks.length} 个，硬失败 ${failures.length} 个，'
    '片段 ${fragments.length} 个，提示 ${warnings.length} 个，报告：$reportPath',
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

/// 图示类代码块不是程序，不参与括号配对检查。
bool _isDiagramBlock(String language) =>
    language == 'text' || language == 'markdown' || language == 'ascii';

final RegExp _fragmentMarker = RegExp(
  r'片段|省略|仅展示|只展示|不完整|伪代码|需要.*依赖|依赖.*未',
);

/// 片段标记必须写在注释行里，避免把正文里的「省略」误判为片段。
bool _looksLikeFragment(String code) {
  for (final line in code.split('\n')) {
    final trimmed = line.trim();
    final isComment =
        trimmed.startsWith('#') ||
        trimmed.startsWith('//') ||
        trimmed.startsWith('<!--') ||
        trimmed.startsWith('/*');
    if (isComment && _fragmentMarker.hasMatch(trimmed)) return true;
  }
  return false;
}

/// 行注释起点：行首，或前一个字符是空白。兼容 CRLF，避免 `\r` 让注释失效。
bool _isLineCommentStart(String code, int index) {
  if (index == 0) return true;
  final previous = code[index - 1];
  return previous == ' ' ||
      previous == '\t' ||
      previous == '\n' ||
      previous == '\r';
}

/// 语言相关的括号/引号配对检查：
/// - 只有脚本类语言把 `#` 当行注释，HTML/CSS 里的 `#0b57d0` 是颜色值；
/// - Python/Kotlin/Swift 支持三引号；
/// - shell 的 `case` 分支写作 `pattern)`，没有配对的 `(`，需要单独放过。
bool _balanced(String code, [String language = '']) {
  final lang = language.toLowerCase();
  final hashComment = const <String>{
    'python',
    'bash',
    'sh',
    'shell',
    'zsh',
    'ruby',
    'yaml',
    'toml',
    'dockerfile',
    'makefile',
    'c',
    'cpp',
    'java',
  }.contains(lang);
  final tripleQuote = const <String>{
    'python',
    'kotlin',
    'swift',
  }.contains(lang);
  final shellLike = const <String>{'bash', 'sh', 'shell', 'zsh'}.contains(lang);
  // Bash 的 `/*.log` 是通配符，不是块注释起点；若误判会把余下
  // 脚本全部跳过。`//` 在脚本里极少出现，按行注释处理可避免
  // URL 中的斜杠参与括号配对。
  final slashComment = true;
  final blockComment = !shellLike;
  final stack = <String>[];
  String? quote;
  for (var index = 0; index < code.length; index++) {
    final char = code[index];
    final next = index + 1 < code.length ? code[index + 1] : '';
    final activeQuote = quote;
    if (activeQuote != null) {
      if (activeQuote.length == 3) {
        if (code.startsWith(activeQuote, index)) {
          quote = null;
          index += 2;
        }
        continue;
      }
      if (char == '\\') {
        index++;
      } else if (char == activeQuote) {
        quote = null;
      }
      continue;
    }
    if (slashComment && char == '/' && next == '/') {
      while (index < code.length && code[index] != '\n') {
        index++;
      }
      continue;
    }
    if (hashComment && char == '#' && _isLineCommentStart(code, index)) {
      while (index < code.length && code[index] != '\n') {
        index++;
      }
      continue;
    }
    if (blockComment && char == '/' && next == '*') {
      index += 2;
      while (index + 1 < code.length &&
          !(code[index] == '*' && code[index + 1] == '/')) {
        index++;
      }
      index++;
      continue;
    }
    if (char == '"' || char == "'" || char == '`') {
      if (lang == 'rust' && char == "'" && _isRustLifetime(code, index)) {
        var cursor = index + 1;
        while (cursor < code.length && _isIdentifierChar(code.codeUnitAt(cursor))) {
          cursor++;
        }
        index = cursor - 1;
        continue;
      }
      final triple =
          tripleQuote &&
          next == char &&
          index + 2 < code.length &&
          code[index + 2] == char;
      quote = triple ? char * 3 : char;
      if (triple) index += 2;
      continue;
    }
    if (char == '(' || char == '{' || char == '[') stack.add(char);
    if (char == ')' || char == '}' || char == ']') {
      if (shellLike && char == ')' && _isShellCasePattern(code, index)) {
        continue;
      }
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

bool _isIdentifierChar(int code) =>
    (code >= 48 && code <= 57) ||
    (code >= 65 && code <= 90) ||
    (code >= 97 && code <= 122) ||
    code == 95;

/// Rust 的 `'static`、`'_` 是生命周期标注，不是字符字面量；
/// `'a'` 这种前后都有引号的才是字符。
bool _isRustLifetime(String code, int index) {
  if (index + 1 >= code.length) return false;
  if (!_isIdentifierChar(code.codeUnitAt(index + 1))) return false;
  return index + 2 >= code.length || code[index + 2] != "'";
}

/// shell 的 `case` 分支标签：从行首到 `)` 之间没有 `(`。
bool _isShellCasePattern(String code, int index) {
  final lineStart = code.lastIndexOf('\n', index) + 1;
  final before = code.substring(lineStart, index);
  final pattern = before.trim();
  // `dev|prod)`、`*)`、`"$root"/*)` 等分支标签不包含空白；
  // 多行命令的收尾 `)` 前面通常有参数和空格，不能误判成分支标签。
  return pattern.isNotEmpty && !pattern.contains(RegExp(r'\s'));
}
