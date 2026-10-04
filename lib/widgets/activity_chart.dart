import 'package:flutter/material.dart';

/// 最近 7 天学习活动量折线图（纯 CustomPaint 绘制，无第三方依赖）。
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.values, this.height = 64});

  final List<int> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ActivityPainter(
          values: values,
          lineColor: theme.colorScheme.primary,
          fillColor: theme.colorScheme.primary.withValues(alpha: 0.14),
          gridColor: theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _ActivityPainter extends CustomPainter {
  _ActivityPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
  });

  final List<int> values;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // 基线
    final baseline = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      baseline,
    );

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final top = maxValue == 0 ? 1.0 : maxValue.toDouble();
    final stepX = values.length == 1
        ? size.width
        : size.width / (values.length - 1);

    Offset pointAt(int index) {
      final ratio = values[index] / top;
      return Offset(
        index * stepX,
        size.height - 6 - ratio * (size.height - 14),
      );
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final point = pointAt(i);
      path.lineTo(point.dx, point.dy);
    }

    // 面积填充
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < values.length; i++) {
      final point = pointAt(i);
      canvas.drawCircle(point, 3, Paint()..color = lineColor);
      canvas.drawCircle(point, 1.4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}
