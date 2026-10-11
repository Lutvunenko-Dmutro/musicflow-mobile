import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/visualizer_options.dart';

class CoverAuraPainter extends CustomPainter {
  final List<double> heights;
  final List<double> dotHeights;
  final VisualizerCoverShape shape;
  final VisualizerColorScheme colorScheme;
  final Color? dominantColor;
  final double coverSize;
  final double maxRayLength;

  CoverAuraPainter({
    required this.heights,
    required this.dotHeights,
    required this.shape,
    required this.colorScheme,
    this.dominantColor,
    required this.coverSize,
    this.maxRayLength = 36.0,
  });

  List<Color> _getPalette() {
    switch (colorScheme) {
      case VisualizerColorScheme.fire:
        return const [
          AppColors.primary,
          AppColors.accentOrange,
          AppColors.accentYellow,
        ];
      case VisualizerColorScheme.adaptive:
        final base = dominantColor ?? AppColors.primary;
        return [
          base,
          Color.lerp(base, Colors.amber, 0.4) ?? base,
          Color.lerp(base, Colors.white, 0.3) ?? base,
        ];
      case VisualizerColorScheme.cyberpunk:
        return const [
          Color(0xFF00E5FF), // Cyan
          Color(0xFFD500F9), // Neon Magenta
          Color(0xFFFF9100), // Neon Amber
        ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final palette = _getPalette();
    final barCount = heights.length;

    if (shape == VisualizerCoverShape.circleVinyl) {
      _paintCircleAura(canvas, center, palette, barCount);
    } else {
      _paintSquareAura(canvas, center, palette, barCount);
    }
  }

  void _paintCircleAura(Canvas canvas, Offset center, List<Color> palette, int barCount) {
    final baseRadius = (coverSize / 2.0) + 2.0;

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = palette.first.withValues(alpha: 0.35);
    canvas.drawCircle(center, baseRadius, rimPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi - (math.pi / 2);
      final val = heights[i].clamp(0.0, 1.0);
      final rayLen = val * maxRayLength;
      final color = palette[((i / barCount) * (palette.length - 1)).round()];

      linePaint.color = color.withValues(alpha: 0.85);
      dotPaint.color = color;

      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      final inner = Offset(center.dx + baseRadius * cosA, center.dy + baseRadius * sinA);
      final outer = Offset(center.dx + (baseRadius + rayLen) * cosA, center.dy + (baseRadius + rayLen) * sinA);

      if (rayLen > 1.0) {
        canvas.drawLine(inner, outer, linePaint);
      }

      final dotH = dotHeights[i].clamp(0.0, 1.0) * maxRayLength;
      final dotPos = Offset(
        center.dx + (baseRadius + dotH + 3.0) * cosA,
        center.dy + (baseRadius + dotH + 3.0) * sinA,
      );
      canvas.drawCircle(dotPos, 1.8, dotPaint);
    }
  }

  void _paintSquareAura(Canvas canvas, Offset center, List<Color> palette, int barCount) {
    final half = coverSize / 2.0;
    final barsPerSide = (barCount / 4).ceil();

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    int currentBar = 0;
    for (int side = 0; side < 4; side++) {
      for (int i = 0; i < barsPerSide && currentBar < barCount; i++, currentBar++) {
        final t = (i + 0.5) / barsPerSide;
        final val = heights[currentBar].clamp(0.0, 1.0);
        final rayLen = val * maxRayLength;
        final color = palette[((currentBar / barCount) * (palette.length - 1)).round()];

        linePaint.color = color.withValues(alpha: 0.85);
        dotPaint.color = color;

        Offset inner;
        Offset normal;

        switch (side) {
          case 0: // Top
            inner = Offset(center.dx - half + (t * coverSize), center.dy - half);
            normal = const Offset(0, -1);
            break;
          case 1: // Right
            inner = Offset(center.dx + half, center.dy - half + (t * coverSize));
            normal = const Offset(1, 0);
            break;
          case 2: // Bottom
            inner = Offset(center.dx + half - (t * coverSize), center.dy + half);
            normal = const Offset(0, 1);
            break;
          case 3: // Left
          default:
            inner = Offset(center.dx - half, center.dy + half - (t * coverSize));
            normal = const Offset(-1, 0);
            break;
        }

        final outer = Offset(inner.dx + normal.dx * rayLen, inner.dy + normal.dy * rayLen);
        if (rayLen > 1.0) {
          canvas.drawLine(inner, outer, linePaint);
        }

        final dotH = dotHeights[currentBar].clamp(0.0, 1.0) * maxRayLength;
        final dotPos = Offset(inner.dx + normal.dx * (dotH + 3.0), inner.dy + normal.dy * (dotH + 3.0));
        canvas.drawCircle(dotPos, 1.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CoverAuraPainter oldDelegate) => true;
}
