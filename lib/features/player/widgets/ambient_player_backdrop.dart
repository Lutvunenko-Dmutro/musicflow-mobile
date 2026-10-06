import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_flow_mobile/models/song_model.dart';

class AmbientPlayerBackdrop extends StatefulWidget {
  final SongModel song;

  const AmbientPlayerBackdrop({super.key, required this.song});

  @override
  State<AmbientPlayerBackdrop> createState() => _AmbientPlayerBackdropState();
}

class _AmbientPlayerBackdropState extends State<AmbientPlayerBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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

        // 2. Animated blurred album art with living flowing pulse
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: AnimatedBuilder(
            key: ValueKey<String>('${widget.song.id}_${widget.song.coverUrl}'),
            animation: _pulseAnimation,
            builder: (context, child) {
              final val = _pulseAnimation.value;
              final scale = 1.10 + (val * 0.12);
              final alignX = (val - 0.5) * 0.16;
              final alignY = (0.5 - val) * 0.12;

              return Transform.scale(
                scale: scale,
                alignment: Alignment(alignX, alignY),
                child: child,
              );
            },
            child: SizedBox.expand(
              child: _buildCoverImage(primary),
            ),
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
    if (widget.song.coverBytes != null && widget.song.coverBytes!.isNotEmpty) {
      return Image.memory(
        widget.song.coverBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    if (widget.song.coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.song.coverUrl,
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
