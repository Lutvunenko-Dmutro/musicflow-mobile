import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'dart:math' as math;

void paintCircle(
  Canvas canvas,
  Size size, {
  required List<double> heights,
  required List<double> dotHeights,
  required int barCount,
}) {
  if (size.width <= 0 || size.height <= 0 || barCount <= 0) return;

  final center = Offset(size.width / 2, size.height / 2);
  final minDim = math.min(size.width, size.height);
  final baseRadius = minDim * 0.30;
  final maxBarLength = minDim * 0.16;

  final List<Color> barColors = [
    AppColors.primary,
    AppColors.accentOrange,
    AppColors.accentYellow,
    AppColors.accentBlue,
    AppColors.accentDeepBlue,
  ];

  final List<Color> dotColors = [
    AppColors.dotRed,
    AppColors.dotOrange,
    AppColors.dotYellow,
    AppColors.dotLightBlue,
    AppColors.dotBlue,
  ];

  final ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = AppColors.primary.withValues(alpha: 0.25);
  canvas.drawCircle(center, baseRadius, ringPaint);

  final Paint linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  final Paint dotPaint = Paint()..style = PaintingStyle.fill;
  final double half = barCount / 2.0;

  for (int i = 0; i < barCount; i++) {
    double progress;
    double angle;

    if (i <= half) {
      progress = i / half;
      angle = -math.pi / 2 + (progress * math.pi);
    } else {
      progress = (barCount - i) / half;
      angle = -math.pi / 2 - (progress * math.pi);
    }

    final int dataIndex = (progress * (barCount - 1)).clamp(0, barCount - 1).toInt();
    final int colorIdx = (progress * (barColors.length - 1)).clamp(0, barColors.length - 1).toInt();

    final double val = heights[dataIndex].clamp(0.0, 1.0);
    final double lineLength = val * maxBarLength;

    linePaint.color = barColors[colorIdx];
    dotPaint.color = dotColors[colorIdx];

    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final inner = Offset(
      center.dx + baseRadius * cosA,
      center.dy + baseRadius * sinA,
    );
    final outer = Offset(
      center.dx + (baseRadius + lineLength) * cosA,
      center.dy + (baseRadius + lineLength) * sinA,
    );

    canvas.drawLine(inner, outer, linePaint);

    final double dotH = (dotHeights[dataIndex].clamp(0.0, 1.0)) * maxBarLength;
    final dotPos = Offset(
      center.dx + (baseRadius + dotH + 3.0) * cosA,
      center.dy + (baseRadius + dotH + 3.0) * sinA,
    );
    canvas.drawCircle(dotPos, 1.8, dotPaint);
  }
}
