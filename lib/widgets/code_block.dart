import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extension.dart';
import '../screens/fullscreen_code_screen.dart';
import '../theme/app_theme.dart';
import 'code_block_body.dart';

/// 现代代码卡片：深色表面、统一 16px 圆角、等宽行号与一键复制。
///
/// 顶部工具条提供「全屏查看」与「复制」两个动作；正文渲染交给
/// [CodeBlockBody]，与全屏代码页共用同一套语法高亮和行号样式。
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.language});

  final String code;
  final String? language;

  static const Color _codeSurface = AppPalette.nightBase;
  static const Color _codeHeader = AppPalette.nightRaised;
  static const Color _codeMuted = AppPalette.paperMutedOnNight;

  @override
  Widget build(BuildContext context) {
    final source = CodeBlockBody.normalizeSource(code);

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
                Expanded(
                  child: Text(
                    CodeBlockBody.displayLanguage(language),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: _codeMuted,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.tr('fullscreenCode'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.open_in_full_rounded,
                    size: 18,
                    color: _codeMuted,
                  ),
                  onPressed: () => _openFullscreen(context),
                ),
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
          CodeBlockBody(source: source, language: language),
        ],
      ),
    );
  }

  /// 以全屏路由打开当前代码；返回后仍停留在教程原位置。
  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullscreenCodeScreen(code: code, language: language),
      ),
    );
  }
}
