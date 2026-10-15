import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/visualizer_options.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_palette_helper.dart';

void main() {
  group('VisualizerPaletteHelper Unit Tests', () {
    test('Returns static brand palette when fire scheme is selected', () {
      final palette = VisualizerPaletteHelper.getPalette(
        VisualizerColorScheme.fire,
        const Color(0xFF00FF00),
      );

      expect(palette, equals(VisualizerPaletteHelper.brandPalette));
      expect(palette.length, equals(5));
      expect(palette.first, equals(AppColors.primary));
    });

    test('Generates adaptive palette using fallback when dominantColor is null', () {
      final palette = VisualizerPaletteHelper.getPalette(
        VisualizerColorScheme.adaptive,
        null,
      );

      expect(palette.length, equals(5));
      expect(palette, isNot(equals(VisualizerPaletteHelper.brandPalette)));
      for (final color in palette) {
        expect(color.alpha, equals(255));
      }
    });

    test('Generates vibrant 5-stop adaptive palette with adjusted lightness and saturation', () {
      const customDominant = Color(0xFF1E3A8A); // dark blue
      final palette = VisualizerPaletteHelper.getPalette(
        VisualizerColorScheme.adaptive,
        customDominant,
      );

      expect(palette.length, equals(5));
      for (final color in palette) {
        final hsl = HSLColor.fromColor(color);
        expect(hsl.saturation, greaterThanOrEqualTo(0.60));
        expect(hsl.lightness, inInclusiveRange(0.40, 0.75));
      }
    });

    test('Returns static dot palette when fire scheme is selected', () {
      final dots = VisualizerPaletteHelper.getDotPalette(
        VisualizerColorScheme.fire,
        VisualizerPaletteHelper.brandPalette,
      );

      expect(dots, equals(VisualizerPaletteHelper.dotPalette));
      expect(dots.length, equals(5));
      expect(dots.first, equals(AppColors.dotRed));
    });

    test('Calculates brightened dot palette when adaptive scheme is selected', () {
      final basePalette = [
        const Color(0xFF882222),
        const Color(0xFF228822),
      ];

      final dots = VisualizerPaletteHelper.getDotPalette(
        VisualizerColorScheme.adaptive,
        basePalette,
      );

      expect(dots.length, equals(2));
      final hBase = HSLColor.fromColor(basePalette.first);
      final hDot = HSLColor.fromColor(dots.first);
      expect(hDot.lightness, greaterThanOrEqualTo(hBase.lightness));
    });

    test('lerpPalette interpolates correctly across range', () {
      const cRed = Color(0xFFFF0000);
      const cGreen = Color(0xFF00FF00);
      const cBlue = Color(0xFF0000FF);
      final palette = [cRed, cGreen, cBlue];

      expect(VisualizerPaletteHelper.lerpPalette(palette, 0.0), equals(cRed));
      expect(VisualizerPaletteHelper.lerpPalette(palette, 1.0), equals(cBlue));
      expect(VisualizerPaletteHelper.lerpPalette(palette, 0.5), equals(cGreen));
      expect(VisualizerPaletteHelper.lerpPalette([], 0.5), equals(Colors.white));
    });
  });
}
