import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';

/// 现代代码卡片：深色表面、统一 16px 圆角、等宽行号与一键复制。
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.language});

  final String code;
  final String? language;

  static const Color _codeSurface = AppPalette.nightBase;
  static const Color _codeHeader = AppPalette.nightRaised;
  static const Color _codeMuted = AppPalette.paperMutedOnNight;

  @override
  Widget build(BuildContext context) {
    final source = code.replaceAll(RegExp(r'\n$'), '');
    final lineCount = source.isEmpty ? 1 : '\n'.allMatches(source).length + 1;
    final lineNumbers = List<String>.generate(
      lineCount,
      (index) => '${index + 1}',
    ).join('\n');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _codeSurface,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _codeHeader,
            padding: const EdgeInsets.only(left: AppSpacing.lg, right: 4),
            child: Row(
              children: [
                Text(
                  (language ?? 'code').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: _codeMuted,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.tr('copyTooltip'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: _codeMuted,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: source));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.trRead('codeCopied')),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // IntrinsicHeight 让左侧行号栏、分隔线与代码区等高，
          // 同时避免在 Markdown 的无界高度环境里出现无限约束。
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Text(
                    lineNumbers,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: AppTheme.monoFamily,
                      fontSize: 11,
                      height: 1.5,
                      color: Color(0xFF5C6370),
                    ),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppPalette.nightRule,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: HighlightView(
                      source,
                      language: language,
                      theme: monokaiSublimeTheme,
                      padding: const EdgeInsets.all(14),
                      textStyle: const TextStyle(
                        fontFamily: AppTheme.monoFamily,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
