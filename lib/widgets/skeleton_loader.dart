import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 骨架屏加载组件：在内容加载时显示占位符，提升感知性能
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.height = 20,
    this.width,
    this.borderRadius = 4,
    this.shimmerDuration = const Duration(milliseconds: 1500),
  });

  final double height;
  final double? width;
  final double borderRadius;
  final Duration shimmerDuration;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.shimmerDuration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2F3A) : const Color(0xFFE7EAF0);
    final highlightColor = isDark ? const Color(0xFF3A3F4A) : const Color(0xFFF2F4F7);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.5,
                _animation.value,
                _animation.value + 0.5,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

/// 课程卡片骨架屏
class LessonCardSkeleton extends StatelessWidget {
  const LessonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题占位
            const SkeletonLoader(height: 20, width: double.infinity),
            const SizedBox(height: 8),
            // 摘要占位
            const SkeletonLoader(height: 14, width: double.infinity),
            const SizedBox(height: 4),
            const SkeletonLoader(height: 14, width: 200),
            const SizedBox(height: 12),
            // 元信息占位
            Row(
              children: [
                const SkeletonLoader(height: 12, width: 60),
                const SizedBox(width: 8),
                const SkeletonLoader(height: 12, width: 80),
                const Spacer(),
                const SkeletonLoader(height: 12, width: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 分类卡片骨架屏
class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图标占位
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            // 标题占位
            const SkeletonLoader(height: 18, width: 120),
            const SizedBox(height: 8),
            // 课程数占位
            const SkeletonLoader(height: 12, width: 80),
          ],
        ),
      ),
    );
  }
}

/// 学习进度卡片骨架屏
class ProgressCardSkeleton extends StatelessWidget {
  const ProgressCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(height: 20, width: 150),
            const SizedBox(height: 16),
            // 统计数据占位
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (_) => const Column(
                  children: [
                    SkeletonLoader(height: 24, width: 40),
                    SizedBox(height: 4),
                    SkeletonLoader(height: 12, width: 50),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 进度条占位
            const SkeletonLoader(height: 8, width: double.infinity),
          ],
        ),
      ),
    );
  }
}

/// 列表页面骨架屏（多个卡片）
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.builder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int)? builder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: builder ??
          (_, __) => const LessonCardSkeleton(),
    );
  }
}
