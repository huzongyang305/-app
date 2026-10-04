import 'package:flutter/material.dart';

/// 全 App 共用响应式断点，避免每个页面各写一套魔法数字。
class AppBreakpoints {
  const AppBreakpoints._();

  /// 平板 / 横屏宽度：开始使用 NavigationRail 等宽屏布局。
  static const double tablet = 720;

  /// 宽屏阅读布局：教程和答题页开始分栏。
  static const double wideReading = 960;
}

/// 居中的阅读容器；手机保持全宽，平板限制行长，避免正文过宽。
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1120,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
