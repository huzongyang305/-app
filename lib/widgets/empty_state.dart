import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 空状态提示：图标 + 文案 + 可选操作按钮
/// 支持多种预设场景和自定义配置
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.title,
    this.secondaryAction,
    this.illustration,
    this.variant = EmptyStateVariant.standard,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;
  final Widget? secondaryAction;
  final Widget? illustration;
  final EmptyStateVariant variant;

  /// 预设空状态工厂构造函数
  factory EmptyState.noFavorites() {
    return EmptyState(
      icon: Icons.star_border,
      title: '暂无收藏',
      message: '浏览课程时点击星标，即可在这里快速访问',
      variant: EmptyStateVariant.friendly,
    );
  }

  factory EmptyState.noNotes() {
    return EmptyState(
      icon: Icons.edit_note,
      title: '还没有笔记',
      message: '在学习过程中记录重点，方便日后复习',
      variant: EmptyStateVariant.friendly,
    );
  }

  factory EmptyState.noSearchResults(String query) {
    return EmptyState(
      icon: Icons.search_off,
      title: '未找到相关内容',
      message: '尝试使用其他关键词搜索，或浏览全部课程',
      variant: EmptyStateVariant.friendly,
    );
  }

  factory EmptyState.noLessons() {
    return EmptyState(
      icon: Icons.school_outlined,
      title: '暂无课程',
      message: '该分类下暂时没有课程内容',
      variant: EmptyStateVariant.standard,
    );
  }

  factory EmptyState.offline() {
    return EmptyState(
      icon: Icons.cloud_off,
      title: '离线模式',
      message: '当前无网络连接，请检查网络设置后重试',
      variant: EmptyStateVariant.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFriendly = variant == EmptyStateVariant.friendly;
    final isWarning = variant == EmptyStateVariant.warning;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 插图或图标
            if (illustration != null)
              illustration!
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isFriendly ? 96 : 64,
                height: isFriendly ? 96 : 64,
                decoration: BoxDecoration(
                  color: isWarning
                      ? theme.colorScheme.error.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadii.card,
                ),
                child: Icon(
                  icon,
                  size: isFriendly ? 48 : 28,
                  color: isWarning
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // 标题（可选）
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            
            // 描述文案
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            
            // 操作按钮
            if (action != null || secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (secondaryAction != null) ...[
                    Expanded(child: secondaryAction!),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  if (action != null)
                    Expanded(child: action!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空状态变体：控制视觉风格
enum EmptyStateVariant {
  /// 标准样式：简洁图标 + 文案
  standard,
  
  /// 友好样式：大图标 + 标题 + 引导文案
  friendly,
  
  /// 警告样式：红色调，用于错误或离线状态
  warning,
}
