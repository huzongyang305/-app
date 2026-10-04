import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// 代码块：语法高亮 + 行号 + 一键复制。
///
/// 左侧电光蓝竖条与等宽行号构成「代码摘录」的视觉标记。
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.language});

  final String code;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlightTheme = isDark ? monokaiSublimeTheme : githubTheme;
    final source = code.replaceAll(RegExp(r'\n$'), '');
    final lineCount = source.isEmpty ? 1 : '\n'.allMatches(source).length + 1;
    final lineNumbers = List<String>.generate(
      lineCount,
      (index) => '${index + 1}',
    ).join('\n');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 12, right: 2),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (language ?? 'code').toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('copyTooltip'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.copy_all_outlined, size: 17),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: source));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.trRead('codeCopied')),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
                    child: Text(
                      lineNumbers,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFamily,
                        fontSize: 11,
                        height: 1.45,
                        color: Color(0xFF9A9C95),
                      ),
                    ),
                  ),
                  Container(width: 1, color: theme.colorScheme.outlineVariant),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: HighlightView(
                        source,
                        language: language,
                        theme: highlightTheme,
                        padding: const EdgeInsets.all(12),
                        textStyle: const TextStyle(
                          fontFamily: AppTheme.monoFamily,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: IgnorePointer(
              child: ColoredBox(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
