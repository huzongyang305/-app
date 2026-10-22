import 'package:flutter/material.dart';

/// 学习曲线：展示学习效率随时间的变化趋势
class LearningCurve extends StatelessWidget {
  const LearningCurve({
    super.key,
    required this.dailyMinutes,
    required this.dailyAccuracy,
    this.height = 200,
  });

  final List<int> dailyMinutes;
  final List<double> dailyAccuracy;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (dailyMinutes.isEmpty || dailyAccuracy.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _CurveLegend(
              title: '学习时长',
              color: Theme.of(context).colorScheme.primary,
              unit: '分钟',
            ),
          ),
          Expanded(
            flex: 3,
            child: CustomPaint(
              painter: _LearningCurvePainter(
                minutes: dailyMinutes,
                accuracy: dailyAccuracy,
                primaryColor: Theme.of(context).colorScheme.primary,
                secondaryColor: Theme.of(context).colorScheme.secondary,
                gridColor: Theme.of(context).colorScheme.outlineVariant,
              ),
              size: Size(double.infinity, height),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurveLegend extends StatelessWidget {
  const _CurveLegend({
    required this.title,
    required this.color,
    required this.unit,
  });

  final String title;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LearningCurvePainter extends CustomPainter {
  _LearningCurvePainter({
    required this.minutes,
    required this.accuracy,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
  });

  final List<int> minutes;
  final List<double> accuracy;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (minutes.isEmpty || accuracy.isEmpty) return;

    final padding = 20.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // 绘制网格线
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // 绘制学习时长曲线
    _drawLine(
      canvas,
      data: minutes.map((e) => e.toDouble()).toList(),
      maxValue: minutes.reduce((a, b) => a > b ? a : b).toDouble(),
      color: primaryColor,
      padding: padding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
    );

    // 绘制正确率曲线
    _drawLine(
      canvas,
      data: accuracy.map((e) => e * 100).toList(),
      maxValue: 100.0,
      color: secondaryColor,
      padding: padding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
    );
  }

  void _drawLine(
    Canvas canvas, {
    required List<double> data,
    required double maxValue,
    required Color color,
    required double padding,
    required double chartWidth,
    required double chartHeight,
  }) {
    if (data.isEmpty) return;

    final stepX = data.length == 1 ? chartWidth : chartWidth / (data.length - 1);

    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < data.length; i++) {
      final x = padding + i * stepX;
      final ratio = maxValue == 0 ? 0 : data[i] / maxValue;
      final y = padding + chartHeight - (ratio * chartHeight);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 绘制面积
    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, padding + chartHeight)
      ..lineTo(points.first.dx, padding + chartHeight)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    // 绘制线条
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 绘制数据点
    for (final point in points) {
      canvas.drawCircle(
        point,
        3,
        Paint()..color = color,
      );
      canvas.drawCircle(
        point,
        1.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LearningCurvePainter oldDelegate) {
    return oldDelegate.minutes != minutes ||
        oldDelegate.accuracy != accuracy ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
