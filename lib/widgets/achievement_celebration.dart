import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';

/// 成就解锁庆祝动画：彩带飘落 + 徽章展示
class AchievementCelebration extends StatefulWidget {
  const AchievementCelebration({
    super.key,
    required this.achievement,
    this.onComplete,
  });

  final Achievement achievement;
  final VoidCallback? onComplete;

  @override
  State<AchievementCelebration> createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final List<ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    // 主动画控制器
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // 彩带动画控制器
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // 缩放动画
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // 淡入动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 生成彩带粒子
    _generateConfetti();

    _mainController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onComplete?.call();
      });
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      AppPalette.primary,
      AppPalette.success,
    ];

    for (int i = 0; i < 50; i++) {
      _particles.add(
        ConfettiParticle(
          x: random.nextDouble(),
          y: -random.nextDouble() * 0.5,
          size: random.nextDouble() * 8 + 4,
          color: colors[random.nextInt(colors.length)],
          rotation: random.nextDouble() * 2 * math.pi,
          rotationSpeed: (random.nextDouble() - 0.5) * 4,
          fallSpeed: random.nextDouble() * 0.3 + 0.2,
          wobble: random.nextDouble() * 2 * math.pi,
          wobbleSpeed: random.nextDouble() * 3 + 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // 彩带层
        AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              painter: ConfettiPainter(
                particles: _particles,
                progress: _confettiController.value,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
        
        // 内容层
        FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Card(
                elevation: 8,
                shadowColor: AppPalette.primary.withValues(alpha: 0.5),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: AppGradients.achievement.length >= 2
                        ? LinearGradient(
                            colors: AppGradients.achievement.take(3).toList(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: AppRadii.card,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 徽章图标
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.achievement.icon,
                          size: 60,
                          color: AppPalette.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 成就名称
                      Text(
                        widget.achievement.titleKey,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      
                      // 祝贺文案
                      Text(
                        '恭喜解锁新成就！',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 彩带粒子数据类
class ConfettiParticle {
  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.fallSpeed,
    required this.wobble,
    required this.wobbleSpeed,
  });

  final double x;
  final double y;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final double fallSpeed;
  final double wobble;
  final double wobbleSpeed;
}

/// 彩带绘制器
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  final List<ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // 计算粒子位置
      final x = particle.x * size.width +
          math.sin(particle.wobble + progress * particle.wobbleSpeed) * 20;
      final y = (particle.y + progress * particle.fallSpeed) * size.height;

      // 如果粒子超出屏幕，跳过
      if (y > size.height || y < -50) continue;

      // 保存画布状态
      canvas.save();
      
      // 移动到粒子位置并旋转
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * particle.rotationSpeed);

      // 绘制矩形彩带
      final paint = Paint()
        ..color = particle.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      // 恢复画布状态
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 简单的成就提示（不含复杂动画）
class AchievementToast extends StatelessWidget {
  const AchievementToast({
    super.key,
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.success,
        borderRadius: AppRadii.card,
        boxShadow: AppShadows.soft(Brightness.light),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
