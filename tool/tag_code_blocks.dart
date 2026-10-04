// 代码块语言标记工具（开发期使用，不参与 App 打包）。
//
// 用法：
//   dart tool/tag_code_blocks.dart [--dry-run]
//
// 为所有没有语言标记的围栏代码块补上标签。明显的代码按语言标记，
// 纯文本图示统一标记为 text，保证语法高亮器不会误判。
import 'dart:io';

String detectLanguage(List<String> body) {
  final text = body.take(12).join('\n');
  final lower = text.toLowerCase();
  if (text.contains('#include') ||
      text.contains('std::') ||
      text.contains('template<')) {
    return 'cpp';
  }
  if (lower.contains('using system') ||
      text.contains('namespace ') && text.contains('class ')) {
    return 'csharp';
  }
  if (text.contains('package main') ||
      text.contains('func ') ||
      text.contains('fmt.')) {
    return 'go';
  }
  if (text.contains('fn main') ||
      text.contains('let mut') ||
      text.contains('impl ')) {
    return 'rust';
  }
  if (text.contains('public class') ||
      text.contains('import java.') ||
      text.contains('@Override')) {
    return 'java';
  }
  if (text.contains('def ') ||
      text.contains('from ') && text.contains(' import ')) {
    return 'python';
  }
  if (RegExp(
    r'\b(SELECT|INSERT|UPDATE|DELETE|CREATE TABLE)\b',
    caseSensitive: false,
  ).hasMatch(text)) {
    return 'sql';
  }
  if (text.contains('#!/usr/bin/env bash') ||
      text.contains('set -euo pipefail')) {
    return 'bash';
  }
  if (lower.contains('<html') || lower.contains('<div')) {
    return 'html';
  }
  if (lower.contains('import react') ||
      lower.contains('function ') ||
      lower.contains('const ')) {
    return 'javascript';
  }
  if (text.contains('interface ') ||
      text.contains('type ') ||
      text.contains(': string')) {
    return 'typescript';
  }
  if (text.contains('──') ||
      text.contains('│') ||
      text.contains('┌') ||
      text.contains('→') ||
      text.contains('└')) {
    return 'text';
  }
  if (text.trimLeft().startsWith('{') || text.trimLeft().startsWith('[')) {
    return 'json';
  }
  return 'text';
}

Future<void> main(List<String> args) async {
  final dryRun = args.contains('--dry-run');
  var filesChanged = 0;
  var tagged = 0;

  for (final file
      in Directory('assets/content')
          .listSync()
          .whereType<File>()
          .where((item) => item.path.toLowerCase().endsWith('.md'))) {
    final lines = (await file.readAsLines());
    var inFence = false;
    var changed = false;
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!line.trimLeft().startsWith('```')) continue;
      if (inFence) {
        inFence = false;
        continue;
      }
      inFence = true;
      final language = line.trimLeft().substring(3).trim();
      if (language.isNotEmpty) continue;

      var end = index + 1;
      while (end < lines.length && !lines[end].trimLeft().startsWith('```')) {
        end++;
      }
      final detected = detectLanguage(lines.sublist(index + 1, end));
      lines[index] = '```$detected';
      tagged++;
      changed = true;
    }
    if (changed) {
      filesChanged++;
      if (!dryRun) {
        await file.writeAsString('${lines.join('\n')}\n', flush: true);
      }
    }
  }

  stdout.writeln('${dryRun ? '待标记' : '已标记'}：$tagged 个代码块，涉及 $filesChanged 个文件');
}
