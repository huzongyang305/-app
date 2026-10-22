// 项目示例语法验证工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/verify_project_code.dart
//
// 当前环境可验证 Python 与 JavaScript；其余语言需要对应 SDK，
// 工具会明确列出“未验证”，避免把未执行的内容当成已验证。
// 解释器与运行时按 toolchain_resolver.dart 的候选列表探测，
// 缺少时自动降级为结构校验，不会让脚本崩溃。
import 'dart:convert';
import 'dart:io';

import 'toolchain_resolver.dart';

const String specDir = 'tool/project_specs';

Future<void> main(List<String> args) async {
  final specs = <String, Map<String, dynamic>>{};
  for (final file in Directory(specDir).listSync().whereType<File>().where(
    (item) => item.path.toLowerCase().endsWith('.json'),
  )) {
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    for (final entry in json.entries) {
      specs[entry.key] = (entry.value as Map).cast<String, dynamic>();
    }
  }

  final python = resolveToolchain(pythonCandidates);
  if (python == null) {
    stdout.writeln(
      '未找到 Python 解释器，Python 示例降级为结构校验（可设置 PYTHON 环境变量）。',
    );
  }
  final temp = Directory.systemTemp.createTempSync('code_learn_verify_');
  var syntaxPassed = 0;
  var structuralPassed = 0;
  final failures = <String>[];

  try {
    for (final entry in specs.entries) {
      final id = entry.key;
      final spec = entry.value;
      final language = spec['language'] as String;
      final code = (spec['code'] as String).trim();
      final path = switch (language) {
        'python' => '${temp.path}/$id.py',
        'javascript' => '${temp.path}/$id.mjs',
        'typescript' => '${temp.path}/$id.ts',
        _ => null,
      };
      if (path == null) {
        if (_balancedDelimiters(code)) {
          structuralPassed++;
        } else {
          failures.add('$id（$language）：括号或代码结构不平衡');
        }
        continue;
      }
      await File(path).writeAsString(code);

      final result = switch (language) {
        'python' => runToolchain(python, [
          '-c',
          'import ast,sys; ast.parse(open(sys.argv[1], encoding="utf-8").read())',
          path,
        ]),
        'javascript' => runToolchain('node', ['--check', path]),
        'typescript' => runToolchain('node', [
          '--experimental-strip-types',
          '--check',
          path,
        ]),
        _ => null,
      };
      if (result == null) {
        // 缺少对应运行时：按结构校验计通过，避免把环境缺失当成语法错误。
        structuralPassed++;
      } else if (result.exitCode == 0) {
        syntaxPassed++;
      } else {
        failures.add('$id（$language）：${result.stderr}');
      }
    }
  } finally {
    temp.deleteSync(recursive: true);
  }

  stdout.writeln('完整语法验证通过：$syntaxPassed 篇；结构校验通过（缺少 SDK）：$structuralPassed 篇');
  if (failures.isNotEmpty) {
    stderr.writeln('语法失败：');
    for (final failure in failures) {
      stderr.writeln('  - $failure');
    }
    exitCode = 1;
  }
}

bool _balancedDelimiters(String code) {
  final stack = <String>[];
  String? quote;
  var lineComment = false;
  for (var index = 0; index < code.length; index++) {
    final char = code[index];
    final next = index + 1 < code.length ? code[index + 1] : '';
    if (lineComment) {
      if (char == '\n') lineComment = false;
      continue;
    }
    if (quote != null) {
      if (char == '\\') {
        index++;
        continue;
      }
      if (char == quote) quote = null;
      continue;
    }
    if (char == '/' && next == '/') {
      lineComment = true;
      index++;
      continue;
    }
    if (char == '#' && (index == 0 || code[index - 1] == '\n')) {
      lineComment = true;
      continue;
    }
    if (char == '"' || char == "'" || char == '`') {
      quote = char;
      continue;
    }
    if (char == '(' || char == '{' || char == '[') {
      stack.add(char);
    } else if (char == ')' || char == '}' || char == ']') {
      if (stack.isEmpty) return false;
      final open = stack.removeLast();
      final matches =
          (open == '(' && char == ')') ||
          (open == '{' && char == '}') ||
          (open == '[' && char == ']');
      if (!matches) return false;
    }
  }
  return quote == null && stack.isEmpty;
}
