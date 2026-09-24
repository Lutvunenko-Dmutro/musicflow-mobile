import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../providers/visualizer_settings_provider.dart';

class VisualizerPainter extends CustomPainter {
  final List<double> heights;
  final List<double> dotHeights;
  final int barCount;
  final VisualizerStyle style;

  VisualizerPainter({
    required this.heights,
    required this.dotHeights,
    required this.barCount,
    this.style = VisualizerStyle.bars,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case VisualizerStyle.bars:
      case VisualizerStyle.mirrored:
        _paintBars(canvas, size, isMirrored: style == VisualizerStyle.mirrored);
        break;
      case VisualizerStyle.circle:
        _paintCircle(canvas, size);
        break;
      case VisualizerStyle.wave:
        _paintWave(canvas, size);
        break;
    }
  }

  void _paintBars(Canvas canvas, Size size, {required bool isMirrored}) {
    int numBlocks = 5;
    int groupSize = barCount ~/ numBlocks;
    
    double blockGap = isMirrored ? 0.0 : 12.0; 
    double totalGaps = blockGap * (numBlocks - 1); 
    
    double usableWidth = size.width - totalGaps;
    double barWidth = usableWidth / barCount;
    
    double spacing = (barWidth * 0.2).clamp(1.0, 4.0);
    double actualBarWidth = barWidth - spacing;

    final List<Color> barColors = [
      const Color(0xFFE52D27),
      const Color(0xFFF59E0B),
      const Color(0xFFFBBF24),
      const Color(0xFF38BDF8),
      const Color(0xFF3B82F6),
    ];
    final List<Color> dotColors = [
      const Color(0xFFFF4B4B),
      const Color(0xFFFCD34D),
      const Color(0xFFFDE68A),
      const Color(0xFF7DD3FC),
      const Color(0xFF93C5FD),
    ];

    double currentX = 0;

    for (int i = 0; i < barCount; i++) {
      int blockIndex = i ~/ groupSize;
      if (blockIndex >= numBlocks) blockIndex = numBlocks - 1;

      if (i > 0 && i % groupSize == 0) {
        currentX += blockGap;
      }

      int dataIndex = i;
      if (isMirrored) {
        double center = barCount / 2;
        dataIndex = ((i - center).abs() * 2).clamp(0, barCount - 1).toInt();
      }

      int colorBlockIndex = dataIndex ~/ groupSize;
      if (colorBlockIndex >= numBlocks) colorBlockIndex = numBlocks - 1;

      final Paint barPaint = Paint()
        ..color = barColors[colorBlockIndex]
        ..style = PaintingStyle.fill;
        
      final Paint dotPaint = Paint()
        ..color = dotColors[colorBlockIndex]
        ..style = PaintingStyle.fill;

      double currentHeight = heights[dataIndex] * size.height;
      double x = currentX + spacing / 2;
      double y = size.height - currentHeight;

      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, actualBarWidth, currentHeight),
        Radius.circular(actualBarWidth / 2),
      );
      canvas.drawRRect(rect, barPaint);

      double dotH = dotHeights[dataIndex] * size.height;
      double dotY = size.height - dotH - 4.0; 
      
      final RRect dotRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, dotY, actualBarWidth, 3.0),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(dotRect, dotPaint);

      currentX += barWidth;
    }
  }

  void _paintCircle(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double angleStep = 2 * math.pi / barCount;

    for (int i = 0; i < barCount; i++) {
      // Mirror the data mapping to make it symmetrical
      double centerIdx = barCount / 2;
      int dataIndex = ((i - centerIdx).abs() * 2).clamp(0, barCount - 1).toInt();

      double angle = i * angleStep - math.pi / 2;
      double val = heights[dataIndex];
      double lineLength = val * radius * 1.2;

      // Color gradient based on angle
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
      
      // Draw outer dot
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

  void _paintWave(Canvas canvas, Size size) {
    double centerY = size.height / 2;
    double amplitudeMax = size.height / 2;

    // Glowing fluid effect with multiple overlapping layers
    final Paint linePaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFE52D27); // Primary Theme Color

    final Paint linePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.8); // Accent

    final Paint linePaint3 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xFFE52D27).withValues(alpha: 0.3); // Glow

    Path path1 = Path();
    Path path2 = Path();
    Path path3 = Path();

    // Helper to get smooth value
    double getSmoothed(int i) {
      if (i <= 0) return heights[0];
      if (i >= barCount - 1) return heights[barCount - 1];
      // Weighted average for smoother peaks
      return (heights[i - 1] * 0.25) + (heights[i] * 0.5) + (heights[i + 1] * 0.25);
    }

    // Mirror the data from center so the wave expands symmetrically from the middle
    for (int j = 0; j < barCount; j++) {
      double x = (j / (barCount - 1)) * size.width;

      double centerIdx = barCount / 2;
      int dataIndex = ((j - centerIdx).abs() * 2).clamp(0, barCount - 1).toInt();
      double val = getSmoothed(dataIndex);
      
      // Calculate amplitudes for 3 overlapping waves
      double amp1 = val * amplitudeMax;
      // Use sine wave to create a phase shift for the second line (makes it look fluid)
      double phase = math.sin(j * 0.4) * 0.4 + 0.6; 
      double amp2 = val * amplitudeMax * phase; 
      double amp3 = val * amplitudeMax * 1.2; // Outer glow
      
      double y1 = centerY - amp1;
      double y2 = centerY - amp2;
      double y3 = centerY - amp3;
      
      if (j == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
        path3.moveTo(x, y3);
      } else {
        double prevX = ((j - 1) / (barCount - 1)) * size.width;
        int prevDataIndex = (((j - 1) - centerIdx).abs() * 2).clamp(0, barCount - 1).toInt();
        double prevVal = getSmoothed(prevDataIndex);
        
        double pAmp1 = prevVal * amplitudeMax;
        double pPhase = math.sin((j - 1) * 0.4) * 0.4 + 0.6;
        double pAmp2 = prevVal * amplitudeMax * pPhase;
        double pAmp3 = prevVal * amplitudeMax * 1.2;
        
        double prevY1 = centerY - pAmp1;
        double prevY2 = centerY - pAmp2;
        double prevY3 = centerY - pAmp3;
        
        double cX = prevX + (x - prevX) / 2;
        
        path1.cubicTo(cX, prevY1, cX, y1, x, y1);
        path2.cubicTo(cX, prevY2, cX, y2, x, y2);
        path3.cubicTo(cX, prevY3, cX, y3, x, y3);
      }
    }
    
    // Draw top half
    canvas.drawPath(path3, linePaint3);
    canvas.drawPath(path2, linePaint2);
    canvas.drawPath(path1, linePaint1);
    
    // Draw bottom half (mirrored)
    canvas.save();
    canvas.translate(0, size.height);
    canvas.scale(1.0, -1.0);
    canvas.drawPath(path3, linePaint3);
    canvas.drawPath(path2, linePaint2);
    canvas.drawPath(path1, linePaint1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) {
    return true; 
  }
}
