import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/core/app_colors.dart';

class CoverColorExtractor {
  static final Map<String, Color> _cache = {};

  static Color? getCachedColor(String songId) => _cache[songId];

  static Future<Color> extractDominantColor(SongModel song) async {
    if (_cache.containsKey(song.id)) return _cache[song.id]!;

    ImageProvider? provider;
    if (song.coverBytes != null && song.coverBytes!.isNotEmpty) {
      provider = MemoryImage(song.coverBytes!);
    } else if (song.coverUrl.isNotEmpty) {
      provider = CachedNetworkImageProvider(song.coverUrl);
    }

    if (provider == null) {
      _cache[song.id] = AppColors.primary;
      return AppColors.primary;
    }

    try {
      final color = await _extractFromProvider(provider);
      _cache[song.id] = color;
      return color;
    } catch (_) {
      _cache[song.id] = AppColors.primary;
      return AppColors.primary;
    }
  }

  static Future<Color> _extractFromProvider(ImageProvider provider) {
    final stream = provider.resolve(const ImageConfiguration(size: Size(24, 24)));
    final completer = Completer<Color>();
    late ImageStreamListener listener;

    listener = ImageStreamListener((ImageInfo info, bool _) async {
      stream.removeListener(listener);
      try {
        final byteData = await info.image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData == null) {
          if (!completer.isCompleted) completer.complete(AppColors.primary);
          return;
        }

        final bytes = byteData.buffer.asUint8List();
        double bestScore = -1;
        Color bestColor = AppColors.primary;
        double maxLightness = 0;
        Color brightestAccent = const Color(0xFFE2E8F0);

        for (int i = 0; i < bytes.length; i += 16) {
          final r = bytes[i];
          final g = bytes[i + 1];
          final b = bytes[i + 2];
          final a = bytes[i + 3];
          if (a < 128) continue;

          final color = Color.fromARGB(255, r, g, b);
          final hsl = HSLColor.fromColor(color);

          if (hsl.lightness > maxLightness) {
            maxLightness = hsl.lightness;
            brightestAccent = color;
          }

          if (hsl.lightness < 0.12 || hsl.lightness > 0.90) continue;
          if (hsl.saturation < 0.12) continue;

          final score = hsl.saturation * 2.0 + (1.0 - (hsl.lightness - 0.5).abs());
          if (score > bestScore) {
            bestScore = score;
            bestColor = color;
          }
        }

        if (bestScore < 0) {
          final bHsl = HSLColor.fromColor(brightestAccent);
          final targetLight = bHsl.lightness < 0.35 ? 0.65 : bHsl.lightness.clamp(0.55, 0.75);
          final targetSat = bHsl.saturation < 0.1 ? 0.25 : bHsl.saturation;
          bestColor = bHsl.withLightness(targetLight).withSaturation(targetSat).toColor();
        }

        if (!completer.isCompleted) completer.complete(bestColor);
      } catch (_) {
        if (!completer.isCompleted) completer.complete(AppColors.primary);
      }
    }, onError: (_, __) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(AppColors.primary);
    });

    stream.addListener(listener);
    return completer.future;
  }
}
