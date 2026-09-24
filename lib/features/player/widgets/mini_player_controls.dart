import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/core/animations/animated_play_pause.dart';
import 'package:music_flow_mobile/core/animations/scale_tap_button.dart';

class MiniPlayerControls extends StatelessWidget {
  const MiniPlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 24),
          color: audioProvider.hasPrevious ? Colors.white : Colors.grey,
          onPressed: audioProvider.hasPrevious ? () => audioProvider.playPrevious() : null,
        ),
        if (audioProvider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          ScaleTapButton(
            onTap: () {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: AnimatedPlayPauseIcon(
                isPlaying: audioProvider.isPlaying,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 24),
          color: audioProvider.hasNext ? Colors.white : Colors.grey,
          onPressed: audioProvider.hasNext ? () => audioProvider.playNext() : null,
        ),
      ],
    );
  }
}
