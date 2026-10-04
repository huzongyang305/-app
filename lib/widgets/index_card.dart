import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 索引卡：细线描边 + 2px 圆角，可用左侧竖标标记归属分类。
///
/// 这是「知识库 / 索引卡」设计语言的基础容器，替代原先的圆角阴影卡片。
class IndexCard extends StatelessWidget {
  const IndexCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 12, 12),
    this.semanticLabel,
    this.bordered = true,
    this.background,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 左侧 2px 竖标颜色，通常取分类色或主题主色。
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  /// 平铺列表可关闭描边，仅靠分隔线与左侧竖标建立层级。
  final bool bordered;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = bordered
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(color: scheme.outlineVariant),
          )
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(2));

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: background ?? scheme.surfaceContainerLow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            content,
            if (accent != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 2,
                child: IgnorePointer(child: ColoredBox(color: accent!)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 分区带：等宽小节编号 + 2px 竖标 + 标题，底部一条细分割线。
class SectionBand extends StatelessWidget {
  const SectionBand({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.trailing,
    this.accent,
  });

  /// 目录式编号，例如「01」「02」。
  final String index;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = accent ?? theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(width: 2, height: 34, color: mark),
              const SizedBox(width: 12),
              MonoLabel(index, color: mark, size: 12, weight: FontWeight.w700),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
        ),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
      ],
    );
  }
}

/// 等宽数据标签：用于编号、百分比、计数等需要对齐的信息。
class MonoLabel extends StatelessWidget {
  const MonoLabel(
    this.text, {
    super.key,
    this.color,
    this.size = 11,
    this.weight = FontWeight.w500,
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
        fontFamily: AppTheme.monoFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
