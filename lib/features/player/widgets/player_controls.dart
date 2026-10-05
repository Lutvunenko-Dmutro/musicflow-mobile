import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/core/animations/animated_play_pause.dart';
import 'package:music_flow_mobile/core/animations/scale_tap_button.dart';

class PlayerControls extends StatelessWidget {
  final SongModel song;

  const PlayerControls({super.key, required this.song});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<Duration>(
            stream: audioProvider.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = song.duration;
              double sliderMax = total.inMilliseconds.toDouble();
              if (sliderMax <= 0.0) sliderMax = 1.0;
              double sliderVal = position.inMilliseconds.toDouble().clamp(0.0, sliderMax);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                      activeTrackColor: primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: sliderVal,
                      max: sliderMax,
                      onChanged: (val) => audioProvider.seek(Duration(milliseconds: val.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          _formatDuration(total),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModeButton(
                icon: Icons.shuffle,
                isActive: audioProvider.isShuffleModeEnabled,
                onTap: audioProvider.toggleShuffle,
                primary: primary,
              ),
              ScaleTapButton(
                onTap: audioProvider.hasPrevious ? () => audioProvider.playPrevious() : null,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.skip_previous_rounded,
                    size: 44,
                    color: audioProvider.hasPrevious ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
              ScaleTapButton(
                onTap: () {
                  if (audioProvider.isLoading) return;
                  audioProvider.isPlaying ? audioProvider.pause() : audioProvider.resume();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: audioProvider.isLoading
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : AnimatedPlayPauseIcon(
                          isPlaying: audioProvider.isPlaying,
                          color: Colors.white,
                          size: 48,
                        ),
                ),
              ),
              ScaleTapButton(
                onTap: audioProvider.hasNext ? () => audioProvider.playNext() : null,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.skip_next_rounded,
                    size: 44,
                    color: audioProvider.hasNext ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
              _buildModeButton(
                icon: audioProvider.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                isActive: audioProvider.repeatMode != RepeatMode.off,
                onTap: audioProvider.toggleRepeat,
                primary: primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback? onTap,
    required Color primary,
  }) {
    return ScaleTapButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? primary : Colors.grey[400], size: 26),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
