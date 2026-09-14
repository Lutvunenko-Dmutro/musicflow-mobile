import 'package:flutter/material.dart';

class VisualizerPainter extends CustomPainter {
  final List<double> heights;
  final List<double> dotHeights;
  final int barCount;

  VisualizerPainter({required this.heights, required this.dotHeights, required this.barCount});

  @override
  void paint(Canvas canvas, Size size) {
    // 5 окремих блоків як на ПК
    int numBlocks = 5;
    int groupSize = barCount ~/ numBlocks;
    
    // Відступи між блоками
    double blockGap = size.width * 0.03; 
    double totalGaps = blockGap * (numBlocks - 1); 
    
    double usableWidth = size.width - totalGaps;
    double barWidth = usableWidth / barCount;
    double spacing = barWidth * 0.2;
    double actualBarWidth = barWidth - spacing;

    // Точні кольори з ПК версії (MusicFlow)
    final List<Color> barColors = [
      const Color(0xFFE52D27), // Deep Red
      const Color(0xFFF59E0B), // Orange
      const Color(0xFFFBBF24), // Yellow
      const Color(0xFF38BDF8), // Light Blue
      const Color(0xFF3B82F6), // Deep Blue
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

      final Paint barPaint = Paint()
        ..color = barColors[blockIndex]
        ..style = PaintingStyle.fill;
        
      final Paint dotPaint = Paint()
        ..color = dotColors[blockIndex]
        ..style = PaintingStyle.fill;

      // Малюємо стовпчик
      double currentHeight = heights[i] * size.height;
      double x = currentX + spacing / 2;
      double y = size.height - currentHeight;

      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, actualBarWidth, currentHeight),
        Radius.circular(actualBarWidth / 2),
      );
      canvas.drawRRect(rect, barPaint);

      // Малюємо падаючу лінію (крапку)
      double dotH = dotHeights[i] * size.height;
      double dotY = size.height - dotH - 4.0; // Трохи вище за висоту стовпчика
      
      final RRect dotRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, dotY, actualBarWidth, 3.0), // Тонка лінія висотою 3.0
        const Radius.circular(1.5),
      );
      canvas.drawRRect(dotRect, dotPaint);

      currentX += barWidth;
    }
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) {
    return true; 
  }
}
