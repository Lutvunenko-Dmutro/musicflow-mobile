import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer_bars_painter.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer_circle_painter.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer_wave_painter.dart';

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
        paintBars(canvas, size, isMirrored: style == VisualizerStyle.mirrored, heights: heights, dotHeights: dotHeights, barCount: barCount);
        break;
      case VisualizerStyle.circle:
        paintCircle(canvas, size, heights: heights, dotHeights: dotHeights, barCount: barCount);
        break;
      case VisualizerStyle.wave:
        paintWave(canvas, size, heights: heights, barCount: barCount);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) {
    return true; 
  }
}
