import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../screens/fullscreen_code_screen.dart';
import '../services/settings_provider.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import 'code_block_body.dart';

/// 现代代码卡片：深色表面、统一 16px 圆角、等宽行号与快捷工具条。
///
/// 工具条提供「分享 / 复制 / 全屏」三个动作，菜单里可调字号与换行方式；
/// 正文渲染交给 [CodeBlockBody]，与全屏代码页共用同一套语法高亮和行号样式。
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.language});

  final String code;
  final String? language;

  static const Color _codeSurface = AppPalette.nightBase;
  static const Color _codeHeader = AppPalette.nightRaised;
  static const Color _codeMuted = AppPalette.paperMutedOnNight;

  /// 菜单动作编码，避免在 UI 里散落字符串常量。
  static const String _actionFontLarger = 'font_larger';
  static const String _actionFontSmaller = 'font_smaller';
  static const String _actionFontReset = 'font_reset';
  static const String _actionToggleWrap = 'toggle_wrap';

  @override
  Widget build(BuildContext context) {
    final source = CodeBlockBody.normalizeSource(code);
    final settings = context.watch<SettingsProvider>();
    final fontSize = 13 * settings.codeFontScale;

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
                  tooltip: context.tr('codeShare'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 18,
                    color: _codeMuted,
                  ),
                  onPressed: () => _share(context, source),
                ),
                PopupMenuButton<String>(
                  tooltip: context.tr('codeViewOptions'),
                  icon: const Icon(
                    Icons.text_fields_rounded,
                    size: 18,
                    color: _codeMuted,
                  ),
                  onSelected: (action) => _handleMenu(context, action),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: _actionFontLarger,
                      child: _menuRow(
                        Icons.text_increase_rounded,
                        context.tr('codeFontLarger'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: _actionFontSmaller,
                      child: _menuRow(
                        Icons.text_decrease_rounded,
                        context.tr('codeFontSmaller'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: _actionFontReset,
                      child: _menuRow(
                        Icons.restart_alt_rounded,
                        context.tr('codeFontReset'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: _actionToggleWrap,
                      child: _menuRow(
                        settings.codeWrapLines
                            ? Icons.horizontal_rule_rounded
                            : Icons.wrap_text_rounded,
                        settings.codeWrapLines
                            ? context.tr('codeWrapOff')
                            : context.tr('codeWrapOn'),
                      ),
                    ),
                  ],
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
          CodeBlockBody(
            source: source,
            language: language,
            fontSize: fontSize,
            wrapLines: settings.codeWrapLines,
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
    );
  }

  Future<void> _handleMenu(BuildContext context, String action) async {
    final settings = context.read<SettingsProvider>();
    switch (action) {
      case _actionFontLarger:
        await settings.setCodeFontScale(settings.codeFontScale + 0.1);
      case _actionFontSmaller:
        await settings.setCodeFontScale(settings.codeFontScale - 0.1);
      case _actionFontReset:
        await settings.setCodeFontScale(1);
      case _actionToggleWrap:
        await settings.setCodeWrapLines(!settings.codeWrapLines);
    }
  }

  /// 分享代码；系统分享不可用时回退为复制，保证功能始终可用。
  Future<void> _share(BuildContext context, String source) async {
    final shared = await const ShareService().shareText(
      source,
      subject: CodeBlockBody.displayLanguage(language),
    );
    if (!context.mounted || shared) return;
    await Clipboard.setData(ClipboardData(text: source));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.trRead('codeShareFallback')),
        duration: const Duration(seconds: 2),
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
