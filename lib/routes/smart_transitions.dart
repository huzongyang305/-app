import 'package:flutter/material.dart';

/// 自定义页面转场类型
enum PageTransitionType {
  /// 淡入淡出：用于不相关的页面跳转
  fade,
  
  /// 滑动进入：用于前进导航（如列表 → 详情）
  slideRight,
  
  /// 滑动返回：用于后退导航
  slideLeft,
  
  /// 向上滑入：用于底部弹窗式页面
  slideUp,
  
  /// 缩放进入：用于重点内容展示
  scale,
  
  /// 共享轴转场：用于同级别内容切换
  sharedAxis,
}

/// 智能页面转场构建器：根据上下文自动选择最合适的转场效果
class SmartPageRoute<T> extends MaterialPageRoute<T> {
  final PageTransitionType type;
  final bool isRelatedContent;

  SmartPageRoute({
    required super.builder,
    super.settings,
    this.type = PageTransitionType.slideRight,
    this.isRelatedContent = false,
  });

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 如果是相关内容，使用共享轴转场
    if (isRelatedContent) {
      return _buildSharedAxisTransition(animation, secondaryAnimation, child);
    }

    switch (type) {
      case PageTransitionType.fade:
        return _buildFadeTransition(animation, child);
      case PageTransitionType.slideRight:
        return _buildSlideRightTransition(context, animation, child);
      case PageTransitionType.slideLeft:
        return _buildSlideLeftTransition(context, animation, child);
      case PageTransitionType.slideUp:
        return _buildSlideUpTransition(context, animation, child);
      case PageTransitionType.scale:
        return _buildScaleTransition(animation, child);
      case PageTransitionType.sharedAxis:
        return _buildSharedAxisTransition(animation, secondaryAnimation, child);
    }
  }

  /// 淡入淡出转场
  Widget _buildFadeTransition(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: child,
    );
  }

  /// 向右滑入转场（前进）
  Widget _buildSlideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: child,
    );
  }

  /// 向左滑入转场（后退）
  Widget _buildSlideLeftTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: child,
    );
  }

  /// 向上滑入转场
  Widget _buildSlideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: child,
    );
  }

  /// 缩放转场
  Widget _buildScaleTransition(Animation<double> animation, Widget child) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// 共享轴转场（用于相关内容切换）
  Widget _buildSharedAxisTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;
}

/// 便捷函数：创建智能路由
/// 
/// 使用示例：
/// ```dart
/// Navigator.push(
///   context,
///   createSmartRoute(
///     LessonScreen(lesson: lesson),
///     isRelated: true, // 相关内容使用共享轴转场
///   ),
/// );
/// ```
PageRoute<T> createSmartRoute<T>(
  Widget page, {
  bool isRelated = false,
  PageTransitionType type = PageTransitionType.slideRight,
}) {
  return SmartPageRoute<T>(
    builder: (_) => page,
    type: type,
    isRelatedContent: isRelated,
  );
}

/// 向后兼容的辅助函数，逐步替换现有的 MaterialPageRoute
PageRoute<T> createLessonRoute<T>(Widget page) {
  return createSmartRoute<T>(page, isRelated: true);
}

PageRoute<T> createCategoryRoute<T>(Widget page) {
  return createSmartRoute<T>(page, type: PageTransitionType.slideRight);
}

PageRoute<T> createModalRoute<T>(Widget page) {
  return createSmartRoute<T>(page, type: PageTransitionType.slideUp);
}
