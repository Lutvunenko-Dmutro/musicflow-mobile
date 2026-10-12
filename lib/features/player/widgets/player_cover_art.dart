import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/player/widgets/cover_sheen.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/cover_aura_visualizer.dart';
import 'package:music_flow_mobile/utils/cover_color_extractor.dart';

class PlayerCoverArt extends StatefulWidget {
  final SongModel song;
  final double dragOffset;

  const PlayerCoverArt({
    super.key,
    required this.song,
    required this.dragOffset,
  });

  @override
  State<PlayerCoverArt> createState() => _PlayerCoverArtState();
}

class _PlayerCoverArtState extends State<PlayerCoverArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _loadDominantColor(widget.song);
  }

  @override
  void didUpdateWidget(PlayerCoverArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _loadDominantColor(widget.song);
    }
  }

  void _loadDominantColor(SongModel song) {
    _dominantColor = CoverColorExtractor.getCachedColor(song.id);
    CoverColorExtractor.extractDominantColor(song).then((color) {
      if (mounted && _dominantColor != color) {
        setState(() => _dominantColor = color);
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _syncRotation(bool isVinyl, bool isPlaying) {
    if (isVinyl && isPlaying) {
      if (!_rotationController.isAnimating) _rotationController.repeat();
    } else {
      if (_rotationController.isAnimating) _rotationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<VisualizerSettingsProvider?>();
    final isPlaying = context.select<AudioProvider?, bool>((p) {
      try {
        return p?.isPlaying ?? false;
      } catch (_) {
        return false;
      }
    });
    final isAura = settings?.position == VisualizerPosition.coverAura;
    final isVinyl = settings?.coverShape == VisualizerCoverShape.circleVinyl;
    final borderRadius = isVinyl ? 1000.0 : 16.0;
    final coverSize = isAura ? 240.0 : 310.0;

    _syncRotation(isVinyl, isPlaying);

    Widget innerCover = AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CoverSheen(
              borderRadius: borderRadius,
              child: SmartCover(
                song: widget.song,
                size: coverSize,
                borderRadius: borderRadius,
              ),
            ),
            if (isVinyl) ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10, width: 2),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isVinyl) {
      innerCover = RotationTransition(
        turns: _rotationController,
        child: innerCover,
      );
    }

    Widget coverWidget = AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: isVinyl ? 24 : 18,
              offset: Offset(widget.dragOffset * 0.1, 8),
            ),
          ],
        ),
        child: innerCover,
      ),
    );

    if (isAura) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: CoverAuraVisualizer(
          coverSize: coverSize,
          dominantColor: _dominantColor,
          child: SizedBox(
            width: coverSize,
            height: coverSize,
            child: coverWidget,
          ),
        ),
      );
    }

    return coverWidget;
  }
}
