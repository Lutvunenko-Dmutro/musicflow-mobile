import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/visualizer_options.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/cover_aura_geometry.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_palette_helper.dart';

class CoverAuraPainter extends CustomPainter {
  final List<double> heights;
  final List<double> dotHeights;
  final VisualizerCoverShape shape;
  final VisualizerColorScheme colorScheme;
  final AuraSpectrumMode spectrumMode;
  final Color? dominantColor;
  final double coverSize;
  final double maxRayLength;

  CoverAuraPainter({
    required this.heights,
    required this.dotHeights,
    required this.shape,
    required this.colorScheme,
    this.spectrumMode = AuraSpectrumMode.live,
    this.dominantColor,
    required this.coverSize,
    this.maxRayLength = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final palette = VisualizerPaletteHelper.getPalette(colorScheme, dominantColor);
    final dotPalette = VisualizerPaletteHelper.getDotPalette(colorScheme, palette);
    final isCircle = shape == VisualizerCoverShape.circleVinyl;
    final barCount = heights.length;
    const cornerR = 20.0;

    _paintBaseGlow(canvas, center, isCircle, palette.first);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..style = PaintingStyle.fill;
    final sparkPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final t = i / barCount;
      final pt = CoverAuraGeometry.getPoint(
        center: center,
        width: coverSize,
        height: coverSize,
        cornerRadius: cornerR,
        t: t,
        isCircle: isCircle,
      );

      final int dataIdx;
      final Color color;
      final Color dotColor;

      switch (spectrumMode) {
        case AuraSpectrumMode.mirrored4Side:
          final offset = ((t * 4.0).round() - (t * 4.0)).abs() * 2.0;
          dataIdx = (offset * (barCount - 1)).clamp(0, barCount - 1).toInt();
          color = VisualizerPaletteHelper.lerpPalette(palette, offset);
          dotColor = VisualizerPaletteHelper.lerpPalette(dotPalette, offset);
          break;
        case AuraSpectrumMode.mirrored2H:
          final offset = t <= 0.5 ? (t * 2.0) : ((1.0 - t) * 2.0);
          dataIdx = (offset * (barCount - 1)).clamp(0, barCount - 1).toInt();
          color = VisualizerPaletteHelper.lerpPalette(palette, offset);
          dotColor = VisualizerPaletteHelper.lerpPalette(dotPalette, offset);
          break;
        case AuraSpectrumMode.mirrored2V:
          final offset = (1.0 - (t - 0.5).abs() * 2.0).clamp(0.0, 1.0);
          dataIdx = (offset * (barCount - 1)).clamp(0, barCount - 1).toInt();
          color = VisualizerPaletteHelper.lerpPalette(palette, offset);
          dotColor = VisualizerPaletteHelper.lerpPalette(dotPalette, offset);
          break;
        case AuraSpectrumMode.live:
          dataIdx = (t * (barCount - 1)).clamp(0, barCount - 1).toInt();
          color = VisualizerPaletteHelper.lerpPalette(palette, t);
          dotColor = VisualizerPaletteHelper.lerpPalette(dotPalette, t);
          break;
      }

      final rayLen = math.max(3.0, heights[dataIdx] * maxRayLength);

      linePaint.color = color.withValues(alpha: 0.92);
      dotPaint.color = dotColor.withValues(alpha: 0.95);
      sparkPaint.color = dotColor.withValues(alpha: 0.65);

      final inner = pt.position + pt.normal * 1.5;
      final outer = inner + pt.normal * rayLen;
      canvas.drawLine(inner, outer, linePaint);

      final dotH = math.max(rayLen + 3.0, dotHeights[dataIdx] * maxRayLength + 4.0);
      final dotPos = inner + pt.normal * dotH;
      canvas.drawCircle(dotPos, 1.8, dotPaint);

      if (heights[dataIdx] > 0.65) {
        final sparkPos = inner + pt.normal * (dotH + 6.0);
        canvas.drawCircle(sparkPos, 1.0, sparkPaint);
      }
    }
  }

  void _paintBaseGlow(Canvas canvas, Offset center, bool isCircle, Color color) {
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);
    final borderGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = color.withValues(alpha: 0.45);

    if (isCircle) {
      final r = (coverSize / 2.0) + 1.0;
      canvas.drawCircle(center, r + 4.0, glowPaint);
      canvas.drawCircle(center, r, borderGlow);
    } else {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: coverSize, height: coverSize),
        const Radius.circular(20.0),
      );
      canvas.drawRRect(rrect.inflate(4.0), glowPaint);
      canvas.drawRRect(rrect, borderGlow);
    }
  }

  @override
  bool shouldRepaint(covariant CoverAuraPainter oldDelegate) => true;
}
