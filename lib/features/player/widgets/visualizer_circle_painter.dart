import 'package:flutter/material.dart';
import 'dart:math' as math;

void paintCircle(Canvas canvas, Size size, {required List<double> heights, required List<double> dotHeights, required int barCount}) {
  final center = Offset(size.width / 2, size.height / 2);
  final radius = math.min(size.width, size.height) / 2 * 0.8;
  
  final Paint paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;

  final double angleStep = 2 * math.pi / barCount;

  for (int i = 0; i < barCount; i++) {
    double centerIdx = barCount / 2;
    int dataIndex = ((i - centerIdx).abs() * 2).clamp(0, barCount - 1).toInt();

    double angle = i * angleStep - math.pi / 2;
    double val = heights[dataIndex];
    double lineLength = val * radius * 1.2;

    double hue = (i / barCount) * 360;
    paint.color = HSLColor.fromAHSL(1.0, hue, 0.8, 0.6).toColor();

    Offset inner = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    Offset outer = Offset(
      center.dx + (radius + lineLength) * math.cos(angle),
      center.dy + (radius + lineLength) * math.sin(angle),
    );

    canvas.drawLine(inner, outer, paint);
    
    double dotH = dotHeights[dataIndex] * radius * 1.2;
    Offset dotPos = Offset(
      center.dx + (radius + dotH + 4.0) * math.cos(angle),
      center.dy + (radius + dotH + 4.0) * math.sin(angle),
    );
    
    final Paint dotPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotPos, 2.0, dotPaint);
  }
}
