import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class EqualizerPlaybackBar extends StatelessWidget {
  final AudioProvider audioProvider;

  const EqualizerPlaybackBar({super.key, required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF252528),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.music_note_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  audioProvider.currentSong?.title ?? 'Музика не грає',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                Text(
                  audioProvider.currentSong?.author ?? 'MusicFlow Player',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              audioProvider.playPrevious();
            },
          ),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
            icon: Icon(
              audioProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              audioProvider.playNext();
            },
          ),
        ],
      ),
    );
  }
}
