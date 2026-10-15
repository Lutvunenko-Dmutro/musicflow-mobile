import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/cover_color_extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoverColorExtractor Tests', () {
    test('Returns AppColors.primary when song has no coverUrl and no coverBytes', () async {
      final song = SongModel(
        id: 'no_cover_song',
        title: 'Song Without Cover',
        author: 'Artist',
        duration: const Duration(seconds: 120),
        coverUrl: '',
      );

      final color = await CoverColorExtractor.extractDominantColor(song);
      expect(color, equals(AppColors.primary));
    });

    test('Uses cached color on repeated requests for the same song id', () async {
      final song = SongModel(
        id: 'cached_song_id',
        title: 'Song For Cache',
        author: 'Artist',
        duration: const Duration(seconds: 120),
        coverUrl: '',
      );

      final firstColor = await CoverColorExtractor.extractDominantColor(song);
      expect(firstColor, equals(AppColors.primary));
      expect(CoverColorExtractor.getCachedColor('cached_song_id'), equals(AppColors.primary));

      final secondColor = await CoverColorExtractor.extractDominantColor(song);
      expect(secondColor, equals(firstColor));
    });

    test('Extracts color from memory coverBytes and boosts dark images', () async {
      // 1x1 transparent/black pixel PNG
      const base64Png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkWPifDwAErQHVd8f9+AAAAABJRU5ErkJggg==';
      final bytes = base64Decode(base64Png);

      final song = SongModel(
        id: 'pixel_cover_song',
        title: 'Pixel Cover',
        author: 'Artist',
        duration: const Duration(seconds: 120),
        coverUrl: '',
        coverBytes: bytes,
      );

      final color = await CoverColorExtractor.extractDominantColor(song);
      expect(color, isNotNull);
      final hsl = HSLColor.fromColor(color);
      // Ensure dark fallback elevates lightness into a readable glow range
      expect(hsl.lightness, greaterThanOrEqualTo(0.50));
    });
  });
}
