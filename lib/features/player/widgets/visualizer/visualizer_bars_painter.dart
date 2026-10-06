import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';

void paintBars(Canvas canvas, Size size, {required bool isMirrored, required List<double> heights, required List<double> dotHeights, required int barCount}) {
  int numBlocks = 5;
  int groupSize = barCount ~/ numBlocks;
  
  double blockGap = isMirrored ? 0.0 : 12.0; 
  double totalGaps = blockGap * (numBlocks - 1); 
  if (size.width <= totalGaps || size.height <= 0) return;
  
  double usableWidth = size.width - totalGaps;
  double barWidth = usableWidth / barCount;
  
  double spacing = (barWidth * 0.2).clamp(1.0, 4.0);
  double actualBarWidth = barWidth - spacing;

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
