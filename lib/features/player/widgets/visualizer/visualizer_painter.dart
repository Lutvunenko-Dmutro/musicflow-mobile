import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_bars_painter.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_circle_painter.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_wave_painter.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_palette_helper.dart';

class VisualizerPainter extends CustomPainter {
  final List<double> heights;
  final List<double> dotHeights;
  final int barCount;
  final VisualizerStyle style;
  final VisualizerColorScheme colorScheme;
  final Color? dominantColor;

  VisualizerPainter({
    required this.heights,
    required this.dotHeights,
    required this.barCount,
    this.style = VisualizerStyle.bars,
    this.colorScheme = VisualizerColorScheme.fire,
    this.dominantColor,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final palette = VisualizerPaletteHelper.getPalette(colorScheme, dominantColor);
    final dotPalette = VisualizerPaletteHelper.getDotPalette(colorScheme, palette);

    switch (style) {
      case VisualizerStyle.bars:
      case VisualizerStyle.mirrored:
        paintBars(
          canvas,
          size,
          isMirrored: style == VisualizerStyle.mirrored,
          heights: heights,
          dotHeights: dotHeights,
          barCount: barCount,
          customColors: palette,
          customDotColors: dotPalette,
        );
        break;
      case VisualizerStyle.circle:
        paintCircle(
          canvas,
          size,
          heights: heights,
          dotHeights: dotHeights,
          barCount: barCount,
          customColors: palette,
          customDotColors: dotPalette,
        );
        break;
      case VisualizerStyle.wave:
        paintWave(
          canvas,
          size,
          heights: heights,
          barCount: barCount,
          customColors: palette,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant VisualizerPainter oldDelegate) => true;
}
