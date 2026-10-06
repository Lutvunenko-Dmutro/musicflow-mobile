import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_flow_mobile/models/song_model.dart';

class AmbientPlayerBackdrop extends StatelessWidget {
  final SongModel song;

  const AmbientPlayerBackdrop({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final bg = theme.scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base dark background
        Container(color: bg),

        // 2. Animated blurred album art / glow
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: SizedBox.expand(
            key: ValueKey<String>('${song.id}_${song.coverUrl}'),
            child: _buildCoverImage(primary),
          ),
        ),

        // 3. Deep blur filter to turn the cover art into an ambient light field
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 75.0, sigmaY: 75.0),
            child: const SizedBox.expand(),
          ),
        ),

        // 4. Cinema vignette gradient for high contrast readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.72),
                  bg.withValues(alpha: 0.94),
                  bg,
                ],
                stops: const [0.0, 0.45, 0.85, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImage(Color fallbackColor) {
    if (song.coverBytes != null && song.coverBytes!.isNotEmpty) {
      return Image.memory(
        song.coverBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    if (song.coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: song.coverUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _buildFallbackMesh(fallbackColor),
        placeholder: (_, __) => _buildFallbackMesh(fallbackColor),
      );
    }

    return _buildFallbackMesh(fallbackColor);
  }

  Widget _buildFallbackMesh(Color primary) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.4),
          radius: 1.2,
          colors: [
            primary.withValues(alpha: 0.65),
            Colors.black,
          ],
        ),
      ),
    );
  }
}
