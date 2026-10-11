import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/player/widgets/cover_sheen.dart';
import 'package:music_flow_mobile/features/player/widgets/smart_cover.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/cover_aura_visualizer.dart';

class PlayerCoverArt extends StatelessWidget {
  final SongModel song;
  final double dragOffset;

  const PlayerCoverArt({
    super.key,
    required this.song,
    required this.dragOffset,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<VisualizerSettingsProvider?>();
    final isAura = settings?.position == VisualizerPosition.coverAura;
    final isVinyl = isAura && settings?.coverShape == VisualizerCoverShape.circleVinyl;
    final borderRadius = isVinyl ? 1000.0 : 16.0;
    final coverSize = isAura ? 250.0 : 310.0;

    Widget coverWidget = AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: isVinyl ? 24 : 18,
              offset: Offset(dragOffset * 0.1, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CoverSheen(
                borderRadius: borderRadius,
                child: SmartCover(
                  song: song,
                  size: coverSize,
                  borderRadius: borderRadius,
                ),
              ),
              if (isVinyl) ...[
                // Vinyl outer groove styling
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10, width: 2),
                  ),
                ),
                // Center spindle hole
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
      ),
    );

    if (isAura) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: CoverAuraVisualizer(
          coverSize: coverSize,
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
