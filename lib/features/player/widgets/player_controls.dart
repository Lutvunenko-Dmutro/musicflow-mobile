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
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek Bar
          StreamBuilder<Duration>(
              stream: audioProvider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = song.duration;
                
                double sliderMax = total.inMilliseconds.toDouble();
                if (sliderMax <= 0.0) sliderMax = 1.0;
                
                double sliderValue = position.inMilliseconds.toDouble();
                if (sliderValue < 0.0) sliderValue = 0.0;
                if (sliderValue > sliderMax) sliderValue = sliderMax;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Theme.of(context).primaryColor,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: sliderValue,
                        max: sliderMax,
                        onChanged: (val) {
                          audioProvider.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                          Text(
                            _formatDuration(total),
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 8),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  icon: const Icon(Icons.shuffle),
                  color: audioProvider.isShuffleModeEnabled ? Theme.of(context).primaryColor : Colors.grey[400],
                  iconSize: 28,
                  onPressed: () {
                    audioProvider.toggleShuffle();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 42,
                  color: audioProvider.hasPrevious ? Colors.white : Colors.grey[700],
                  onPressed: audioProvider.hasPrevious ? () => audioProvider.playPrevious() : null,
                ),
                ScaleTapButton(
                  onTap: () {
                    if (audioProvider.isLoading) return;
                    if (audioProvider.isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.resume();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: audioProvider.isLoading 
                      ? const SizedBox(
                          width: 48, 
                          height: 48, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        )
                      : AnimatedPlayPauseIcon(
                          isPlaying: audioProvider.isPlaying,
                          color: Colors.white,
                          size: 48,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 42,
                  color: audioProvider.hasNext ? Colors.white : Colors.grey[700],
                  onPressed: audioProvider.hasNext ? () => audioProvider.playNext() : null,
                ),
                IconButton(
                  icon: Icon(
                    audioProvider.repeatMode == RepeatMode.one 
                      ? Icons.repeat_one 
                      : Icons.repeat,
                  ),
                  color: audioProvider.repeatMode != RepeatMode.off 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[400],
                  iconSize: 28,
                  onPressed: () {
                    audioProvider.toggleRepeat();
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
