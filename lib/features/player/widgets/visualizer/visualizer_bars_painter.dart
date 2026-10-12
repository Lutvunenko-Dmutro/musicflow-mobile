import 'package:flutter/material.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_palette_helper.dart';

void paintBars(
  Canvas canvas,
  Size size, {
  required bool isMirrored,
  required List<double> heights,
  required List<double> dotHeights,
  required int barCount,
  List<Color>? customColors,
  List<Color>? customDotColors,
}) {
  final int numBlocks = 5;
  final int groupSize = barCount ~/ numBlocks;

  final double blockGap = isMirrored ? 0.0 : 12.0;
  final double totalGaps = blockGap * (numBlocks - 1);
  if (size.width <= totalGaps || size.height <= 0) return;

  final double usableWidth = size.width - totalGaps;
  final double barWidth = usableWidth / barCount;

  final double spacing = (barWidth * 0.2).clamp(1.0, 4.0);
  final double actualBarWidth = barWidth - spacing;

  final List<Color> barColors = customColors ?? VisualizerPaletteHelper.brandPalette;
  final List<Color> dotColors = customDotColors ?? VisualizerPaletteHelper.dotPalette;

  double currentX = 0;

  for (int i = 0; i < barCount; i++) {
    int blockIndex = i ~/ groupSize;
    if (blockIndex >= numBlocks) blockIndex = numBlocks - 1;

    if (i > 0 && i % groupSize == 0) {
      currentX += blockGap;
    }

    int dataIndex = i;
    if (isMirrored) {
      final double center = barCount / 2;
      dataIndex = ((i - center).abs() * 2).clamp(0, barCount - 1).toInt();
    }

    int colorBlockIndex = dataIndex ~/ groupSize;
    if (colorBlockIndex >= numBlocks) colorBlockIndex = numBlocks - 1;

    final Paint barPaint = Paint()
      ..color = barColors[colorBlockIndex % barColors.length]
      ..style = PaintingStyle.fill;

    final Paint dotPaint = Paint()
      ..color = dotColors[colorBlockIndex % dotColors.length]
      ..style = PaintingStyle.fill;

    final double currentHeight = heights[dataIndex] * size.height;
    final double x = currentX + spacing / 2;
    final double y = size.height - currentHeight;

    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, actualBarWidth, currentHeight),
      Radius.circular(actualBarWidth / 2),
    );
    canvas.drawRRect(rect, barPaint);

    final double dotH = dotHeights[dataIndex] * size.height;
    final double dotY = size.height - dotH - 4.0;

    final RRect dotRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, dotY, actualBarWidth, 3.0),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(dotRect, dotPaint);

    currentX += barWidth;
  }
}
