import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'dart:math' as math;

void paintWave(Canvas canvas, Size size, {required List<double> heights, required int barCount}) {
  double centerY = size.height / 2;
  double amplitudeMax = size.height / 2;

  final Paint linePaint1 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..color = AppColors.primary;

  final Paint linePaint2 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = AppColors.accentOrange.withValues(alpha: 0.8);

  final Paint linePaint3 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = AppColors.primary.withValues(alpha: 0.3);

  Path path1 = Path();
  Path path2 = Path();
  Path path3 = Path();

  double getSmoothed(int i) {
    if (i <= 0) return heights[0];
    if (i >= barCount - 1) return heights[barCount - 1];
    return (heights[i - 1] * 0.25) + (heights[i] * 0.5) + (heights[i + 1] * 0.25);
  }

  for (int j = 0; j < barCount; j++) {
    double x = (j / (barCount - 1)) * size.width;

    double centerIdx = barCount / 2;
    int dataIndex = ((j - centerIdx).abs() * 2).clamp(0, barCount - 1).toInt();
    double val = getSmoothed(dataIndex);
    
    double amp1 = val * amplitudeMax;
    double phase = math.sin(j * 0.4) * 0.4 + 0.6; 
    double amp2 = val * amplitudeMax * phase; 
    double amp3 = val * amplitudeMax * 1.2; 
    
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
  
  canvas.drawPath(path3, linePaint3);
  canvas.drawPath(path2, linePaint2);
  canvas.drawPath(path1, linePaint1);
  
  canvas.save();
  canvas.translate(0, size.height);
  canvas.scale(1.0, -1.0);
  canvas.drawPath(path3, linePaint3);
  canvas.drawPath(path2, linePaint2);
  canvas.drawPath(path1, linePaint1);
  canvas.restore();
}
