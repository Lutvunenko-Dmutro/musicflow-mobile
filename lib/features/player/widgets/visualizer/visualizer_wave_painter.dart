import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_palette_helper.dart';

void paintWave(
  Canvas canvas,
  Size size, {
  required List<double> heights,
  required int barCount,
  List<Color>? customColors,
}) {
  if (size.width <= 0 || size.height <= 0 || barCount <= 1) return;

  final double centerY = size.height / 2;
  final double maxAmp = (size.height / 2) * 0.92;

  final List<Color> colors = customColors ?? VisualizerPaletteHelper.brandPalette;
  final c0 = colors[0 % colors.length];
  final c1 = colors[1 % colors.length];
  final c2 = colors[2 % colors.length];
  final c3 = colors[3 % colors.length];

  double getSmoothed(int i) {
    if (i <= 0) return heights[0];
    if (i >= barCount - 1) return heights[barCount - 1];
    return (heights[i - 1] * 0.25) + (heights[i] * 0.5) + (heights[i + 1] * 0.25);
  }

  final double centerIdx = barCount / 2.0;

  final Path topPath = Path();
  final Path bottomPath = Path();
  final Path fillPath = Path();
  final Path harmonicPath = Path();

  for (int j = 0; j < barCount; j++) {
    final double x = (j / (barCount - 1)) * size.width;
    final int dataIndex = ((j - centerIdx).abs() * 2).clamp(0, barCount - 1).toInt();
    final double val = getSmoothed(dataIndex).clamp(0.04, 1.0);

    final double amp = val * maxAmp;
    final double harmonicPhase = math.sin(j * 0.35) * 0.35 + 0.65;
    final double harmonicAmp = val * maxAmp * harmonicPhase;

    final double yTop = centerY - amp;
    final double yBottom = centerY + (amp * 0.85);
    final double yHarmonic = centerY - harmonicAmp;

    if (j == 0) {
      topPath.moveTo(x, yTop);
      bottomPath.moveTo(x, yBottom);
      fillPath.moveTo(x, centerY);
      fillPath.lineTo(x, yTop);
      harmonicPath.moveTo(x, yHarmonic);
    } else {
      final double prevX = ((j - 1) / (barCount - 1)) * size.width;
      final int prevDataIndex = (((j - 1) - centerIdx).abs() * 2).clamp(0, barCount - 1).toInt();
      final double prevVal = getSmoothed(prevDataIndex).clamp(0.04, 1.0);

      final double pAmp = prevVal * maxAmp;
      final double prevHarmonicPhase = math.sin((j - 1) * 0.35) * 0.35 + 0.65;
      final double pHAmp = prevVal * maxAmp * prevHarmonicPhase;

      final double prevYTop = centerY - pAmp;
      final double prevYBottom = centerY + (pAmp * 0.85);
      final double prevYHarmonic = centerY - pHAmp;

      final double midX = prevX + (x - prevX) / 2;

      topPath.cubicTo(midX, prevYTop, midX, yTop, x, yTop);
      bottomPath.cubicTo(midX, prevYBottom, midX, yBottom, x, yBottom);
      fillPath.cubicTo(midX, prevYTop, midX, yTop, x, yTop);
      harmonicPath.cubicTo(midX, prevYHarmonic, midX, yHarmonic, x, yHarmonic);
    }
  }

  fillPath.lineTo(size.width, centerY);
  fillPath.close();

  final Rect fillRect = Rect.fromLTWH(0, centerY - maxAmp, size.width, maxAmp);
  final Paint fillPaint = Paint()
    ..style = PaintingStyle.fill
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        c0.withValues(alpha: 0.35),
        c1.withValues(alpha: 0.15),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(fillRect);
  canvas.drawPath(fillPath, fillPaint);

  final Paint harmonicPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..color = c2.withValues(alpha: 0.65);
  canvas.drawPath(harmonicPath, harmonicPaint);

  final Paint reflectionPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..color = c3.withValues(alpha: 0.5);
  canvas.drawPath(bottomPath, reflectionPaint);

  final Rect crestRect = Rect.fromLTWH(0, 0, size.width, size.height);
  final Paint crestPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..shader = LinearGradient(
      colors: [c1, c0, c2],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(crestRect);
  canvas.drawPath(topPath, crestPaint);
}
