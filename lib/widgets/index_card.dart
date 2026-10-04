import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 现代卡片容器：16px 圆角、柔和阴影、低对比描边。
///
/// [accent] 会转化为一层极浅的主色底，用于表达选中或分类归属，
/// 不会引入额外的高饱和色块。
class IndexCard extends StatelessWidget {
  const IndexCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.semanticLabel,
    this.bordered = true,
    this.background,
    this.shadow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;
  final bool bordered;
  final Color? background;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = AppRadii.card;
    final tint = accent;
    final fill =
        background ??
        (tint == null
            ? scheme.surfaceContainerLow
            : Color.alphaBlend(
                tint.withValues(alpha: 0.05),
                scheme.surfaceContainerLow,
              ));

    final decoration = BoxDecoration(
      color: fill,
      borderRadius: radius,
      border: bordered
          ? Border.all(
              color: tint == null
                  ? scheme.outlineVariant
                  : tint.withValues(alpha: 0.18),
            )
          : null,
      boxShadow: shadow ? AppShadows.soft(theme.brightness) : null,
    );

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: scheme.primary.withValues(alpha: 0.06),
        highlightColor: scheme.primary.withValues(alpha: 0.04),
        child: content,
      );
    }
    // 透明 Material 让内嵌的 ListTile / InkWell 有正确的绘制层，
    // 卡片底色仍由外层 DecoratedBox 提供，避免水波纹被遮挡。
    content = Material(type: MaterialType.transparency, child: content);

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: decoration,
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    );
  }
}

/// 现代分区标题：主色索引胶囊 + 紧凑标题，不再使用竖条与分割线。
class SectionBand extends StatelessWidget {
  const SectionBand({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.trailing,
    this.accent,
  });

  final String index;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = accent ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: mark.withValues(alpha: 0.10),
              borderRadius: AppRadii.chip,
            ),
            child: Text(
              index,
              style: TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: mark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 数据标签：使用无衬线 + 表格数字，保证计数和百分比对齐。
class MonoLabel extends StatelessWidget {
  const MonoLabel(
    this.text, {
    super.key,
    this.color,
    this.size = 12,
    this.weight = FontWeight.w600,
  });

  final String text;
  final Color? color;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.3,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
