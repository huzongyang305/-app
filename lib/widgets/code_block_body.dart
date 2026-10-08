import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../theme/app_theme.dart';

/// 代码正文：左侧行号栏 + 右侧语法高亮。
///
/// 教程内嵌代码卡片与全屏代码页共用这一套渲染，避免两处样式漂移。
/// 组件内部只负责横向滚动，纵向滚动交给外层容器，这样长行不会被折断。
class CodeBlockBody extends StatelessWidget {
  const CodeBlockBody({
    super.key,
    required this.source,
    this.language,
    this.fontSize = 13,
    this.padding = 14,
    this.wrapLines = false,
  });

  /// 已去掉结尾换行的代码文本。
  final String source;
  final String? language;
  final double fontSize;
  final double padding;

  /// 是否让超长行自动换行。
  ///
  /// 换行后逻辑行会占用多行显示，行号栏无法再与代码对齐，因此换行模式下
  /// 自动隐藏行号，优先保证代码内容完整可读。
  final bool wrapLines;

  /// 代码行数，至少为 1。
  static int lineCountOf(String source) =>
      source.isEmpty ? 1 : '\n'.allMatches(source).length + 1;

  /// 去掉结尾多余空行，保证代码框显示的行数与复制内容一致。
  static String normalizeSource(String code) =>
      code.replaceFirst(RegExp(r'\n+$'), '');

  /// 代码区域底色，与高亮主题的根背景保持一致。
  static Color get surfaceColor =>
      monokaiSublimeTheme['root']?.backgroundColor ?? AppPalette.nightBase;

  /// 把 Markdown 围栏语言名转成界面上更易读的标签。
  static String displayLanguage(String? language) {
    final raw = (language ?? '').trim();
    if (raw.isEmpty) return 'CODE';
    const names = <String, String>{
      'js': 'JavaScript',
      'jsx': 'JSX',
      'ts': 'TypeScript',
      'tsx': 'TSX',
      'py': 'Python',
      'cpp': 'C++',
      'csharp': 'C#',
      'asm': 'Assembly',
      'sh': 'Shell',
      'shell': 'Shell',
      'dockerfile': 'Dockerfile',
      'powershell': 'PowerShell',
      'gitignore': '.gitignore',
      'html': 'HTML',
      'css': 'CSS',
      'sql': 'SQL',
      'xml': 'XML',
      'json': 'JSON',
      'jsonc': 'JSONC',
      'yaml': 'YAML',
      'toml': 'TOML',
      'http': 'HTTP',
      'hcl': 'HCL',
      'tf': 'Terraform',
      'terraform': 'Terraform',
      'solidity': 'Solidity',
      'cmake': 'CMake',
      'nginx': 'Nginx',
      'protobuf': 'Protobuf',
      'markdown': 'Markdown',
      'cron': 'Cron',
      'awk': 'AWK',
      'go': 'Go',
    };
    return names[raw.toLowerCase()] ?? raw.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // highlight 在 language 为 null 时会直接抛错；无语言围栏按纯文本处理。
    final resolvedLanguage = (language ?? '').trim().isEmpty
        ? 'plaintext'
        : language;
    if (wrapLines) {
      return ColoredBox(
        color: surfaceColor,
        child: SizedBox(
          width: double.infinity,
          child: HighlightView(
            source,
            language: resolvedLanguage,
            theme: monokaiSublimeTheme,
            padding: EdgeInsets.all(padding),
            textStyle: TextStyle(
              fontFamily: AppTheme.monoFamily,
              fontSize: fontSize,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    final lineNumbers = List<String>.generate(
      lineCountOf(source),
      (index) => '${index + 1}',
    ).join('\n');
    // 行号栏与代码区行高一致，因此各自按自然高度布局即可对齐；
    // 这里刻意不用 IntrinsicHeight，否则行号高度会被叠加进总高度，
    // 在代码框底部留下大片空白。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppPalette.nightRule)),
          ),
          padding: EdgeInsets.fromLTRB(14, padding, 10, padding),
          child: Text(
            lineNumbers,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppTheme.monoFamily,
              fontSize: fontSize,
              height: 1.5,
              color: const Color(0xFF5C6370),
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: surfaceColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                source,
                language: resolvedLanguage,
                theme: monokaiSublimeTheme,
                padding: EdgeInsets.all(padding),
                textStyle: TextStyle(
                  fontFamily: AppTheme.monoFamily,
                  fontSize: fontSize,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
