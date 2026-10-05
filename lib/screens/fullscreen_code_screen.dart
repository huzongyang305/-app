import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/code_block_body.dart';

/// 全屏代码页：深色沉浸背景、双轴滚动、可选中文本。
///
/// 从教程里的代码框点击「全屏」进入，适合阅读较长或较宽的示例代码。
class FullscreenCodeScreen extends StatelessWidget {
  const FullscreenCodeScreen({super.key, required this.code, this.language});

  final String code;
  final String? language;

  /// 深色页面下保持状态栏与导航栏图标清晰可见。
  static SystemUiOverlayStyle get _overlayStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: CodeBlockBody.surfaceColor,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    final source = CodeBlockBody.normalizeSource(code);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        // 整页使用代码底色，长代码之外不会出现突兀的色块断层。
        backgroundColor: CodeBlockBody.surfaceColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, source),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppPalette.nightRule,
              ),
              // SelectionArea 让代码在手机长按即可选中复制。
              Expanded(
                child: SelectionArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    child: CodeBlockBody(
                      source: source,
                      language: language,
                      fontSize: 14,
                      padding: AppSpacing.lg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String source) {
    return Container(
      color: AppPalette.nightRaised,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CodeBlockBody.displayLanguage(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppPalette.paperOnNight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.trArgs('codeLineCount', {
                    'n': CodeBlockBody.lineCountOf(source),
                  }),
                  style: const TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 11,
                    color: AppPalette.paperMutedOnNight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('copyTooltip'),
            onPressed: () => _copyCode(context, source),
            icon: const Icon(
              Icons.copy_rounded,
              size: 20,
              color: AppPalette.paperMutedOnNight,
            ),
          ),
          IconButton(
            tooltip: context.tr('exitFullscreen'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.close_fullscreen_rounded,
              size: 20,
              color: AppPalette.paperOnNight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCode(BuildContext context, String source) async {
    await Clipboard.setData(ClipboardData(text: source));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.trRead('codeCopied')),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
