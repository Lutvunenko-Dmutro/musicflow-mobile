import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/visualizer_options.dart';

class VisualizerPaletteHelper {
  static const List<Color> brandPalette = [
    AppColors.primary,
    AppColors.accentOrange,
    AppColors.accentYellow,
    AppColors.accentBlue,
    AppColors.accentDeepBlue,
  ];

  static const List<Color> dotPalette = [
    AppColors.dotRed,
    AppColors.dotOrange,
    AppColors.dotYellow,
    AppColors.dotLightBlue,
    AppColors.dotBlue,
  ];

  static List<Color> getPalette(VisualizerColorScheme scheme, Color? dominantColor) {
    if (scheme == VisualizerColorScheme.fire) return brandPalette;
    final base = dominantColor ?? AppColors.primary;
    final hsl = HSLColor.fromColor(base);
    final sat = math.max(0.65, hsl.saturation);
    final light = hsl.lightness.clamp(0.45, 0.70);
    final v = hsl.withSaturation(sat).withLightness(light);
    return [
      v.toColor(),
      v.withHue((v.hue + 25) % 360).toColor(),
      v.withHue((v.hue + 55) % 360).toColor(),
      v.withHue((v.hue + 160) % 360).withSaturation(0.70).toColor(),
      v.withHue((v.hue + 200) % 360).withSaturation(0.80).toColor(),
    ];
  }

  static List<Color> getDotPalette(VisualizerColorScheme scheme, List<Color> palette) {
    if (scheme == VisualizerColorScheme.fire) return dotPalette;
    return palette.map((c) {
      final h = HSLColor.fromColor(c);
      return h
          .withLightness(math.min(1.0, h.lightness * 1.35))
          .withSaturation(math.min(1.0, h.saturation * 1.1))
          .toColor();
    }).toList();
  }

  static Color lerpPalette(List<Color> palette, double t) {
    if (palette.isEmpty) return Colors.white;
    final scaled = (t.clamp(0.0, 1.0)) * (palette.length - 1);
    final idx = scaled.floor();
    final frac = scaled - idx;
    if (idx >= palette.length - 1) return palette.last;
    return Color.lerp(palette[idx], palette[idx + 1], frac) ?? palette[idx];
  }
}
