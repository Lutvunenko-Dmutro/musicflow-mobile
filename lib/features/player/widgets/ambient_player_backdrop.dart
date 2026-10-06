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
      duration: const Duration(milliseconds: 4000),
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
    final accent = theme.colorScheme.secondary;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base dark background
        Container(color: bg),

        // 2. Animated vibrant cover art + moving light orbs
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 650),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: AnimatedBuilder(
            key: ValueKey<String>('${widget.song.id}_${widget.song.coverUrl}'),
            animation: _pulseAnimation,
            builder: (context, child) {
              final t = _pulseAnimation.value;
              final scale = 1.25 + (t * 0.18);
              final rot = (t - 0.5) * 0.16;
              final orb1X = -30.0 + (t * 70.0);
              final orb1Y = -40.0 + (t * 60.0);
              final orb2X = 50.0 - (t * 80.0);
              final orb2Y = 60.0 - (t * 70.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Undulating cover artwork
                  Transform(
                    transform: Matrix4.identity()
                      ..translate((t - 0.5) * 40.0, (0.5 - t) * 30.0)
                      ..scale(scale)
                      ..rotateZ(rot),
                    alignment: Alignment.center,
                    child: child,
                  ),
                  // Primary luminous floating light orb (Top-Left)
                  Positioned(
                    top: orb1Y,
                    left: orb1X,
                    width: 360,
                    height: 360,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primary.withValues(alpha: 0.65 + (t * 0.25)),
                            primary.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Secondary accent floating light orb (Center-Right)
                  Positioned(
                    bottom: orb2Y,
                    right: orb2X,
                    width: 340,
                    height: 340,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withValues(alpha: 0.55 + ((1.0 - t) * 0.25)),
                            Colors.orangeAccent.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: SizedBox.expand(
              child: _buildCoverImage(primary),
            ),
          ),
        ),

        // 3. Silky 28px blur filter (preserves rich color luminescence & motion)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28.0, sigmaY: 28.0),
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
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                  bg.withValues(alpha: 0.72),
                  bg.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.35, 0.78, 1.0],
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
