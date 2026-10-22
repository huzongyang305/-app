import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 卡片层级枚举
enum CardLevel {
  /// L1 核心卡片：用于重要内容、推荐项、今日任务
  primary,
  
  /// L2 普通卡片：用于常规内容列表
  secondary,
  
  /// L3 辅助卡片：用于次要信息、提示、元数据
  tertiary,
}

/// 分层卡片组件：根据重要性自动应用不同的视觉样式
///
/// 使用示例：
/// ```dart
/// HierarchicalCard(
///   level: CardLevel.primary,
///   categoryColor: AppPalette.getCategoryColor('data_structures'),
///   child: Text('重要内容'),
/// )
/// ```
class HierarchicalCard extends StatelessWidget {
  final Widget child;
  final CardLevel level;
  final Color? categoryColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool showPulseAnimation;

  const HierarchicalCard({
    super.key,
    required this.child,
    this.level = CardLevel.secondary,
    this.categoryColor,
    this.onTap,
    this.padding,
    this.showPulseAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    
    // 根据层级选择样式
    final style = _getCardStyle(brightness);
    
    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: style.borderRadius,
        gradient: style.gradient,
        color: style.backgroundColor,
        border: style.border,
        boxShadow: style.shadows,
      ),
      child: Padding(
        padding: padding ?? style.padding,
        child: child,
      ),
    );
    
    // 如果需要脉动动画（用于未完成的学习路径等）
    if (showPulseAnimation) {
      card = _PulseAnimation(child: card);
    }
    
    // 如果可点击，添加 InkWell
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        borderRadius: style.borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: style.borderRadius,
          child: card,
        ),
      );
    }
    
    return card;
  }

  _CardStyle _getCardStyle(Brightness brightness) {
    switch (level) {
      case CardLevel.primary:
        return _CardStyle(
          borderRadius: AppRadii.cardPrimary,
          gradient: categoryColor != null
              ? LinearGradient(
                  colors: [
                    categoryColor!.withValues(alpha: 0.15),
                    categoryColor!.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          backgroundColor: AppPalette.surface,
          border: categoryColor != null
              ? Border.all(
                  color: categoryColor!.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
          shadows: AppShadows.primary(brightness),
          padding: const EdgeInsets.all(20),
        );
      
      case CardLevel.secondary:
        return _CardStyle(
          borderRadius: AppRadii.card,
          backgroundColor: AppPalette.surface,
          border: Border.all(color: AppPalette.rule, width: 1),
          shadows: AppShadows.soft(brightness),
          padding: const EdgeInsets.all(16),
        );
      
      case CardLevel.tertiary:
        return _CardStyle(
          borderRadius: AppRadii.cardSecondary,
          backgroundColor: AppPalette.neutralFill,
          border: Border.all(
            color: AppPalette.rule.withValues(alpha: 0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
          shadows: AppShadows.subtle(brightness),
          padding: const EdgeInsets.all(12),
        );
    }
  }
}

/// 卡片样式数据类
class _CardStyle {
  final BorderRadius borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry padding;

  _CardStyle({
    required this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.border,
    this.shadows,
    required this.padding,
  });
}

/// 脉动动画组件：用于吸引用户注意
class _PulseAnimation extends StatefulWidget {
  final Widget child;

  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 分类色标签组件：显示课程类型彩色标签
class CategoryBadge extends StatelessWidget {
  final String categoryId;
  final String label;
  final double fontSize;

  const CategoryBadge({
    super.key,
    required this.categoryId,
    required this.label,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppPalette.getCategoryColor(categoryId);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
