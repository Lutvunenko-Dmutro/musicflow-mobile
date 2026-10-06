import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/audio_visualizer.dart';
import 'package:music_flow_mobile/features/player/widgets/player_header.dart';
import 'package:music_flow_mobile/features/player/widgets/player_controls.dart';
import 'package:music_flow_mobile/features/player/screens/queue_screen.dart';
import 'package:music_flow_mobile/features/lyrics/screens/lyrics_screen.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/inline_lyrics.dart';
import 'package:music_flow_mobile/features/player/widgets/ambient_player_backdrop.dart';
import 'package:music_flow_mobile/features/player/widgets/player_popup_menu.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Зараз грає',
              style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lyrics_outlined, size: 24),
            tooltip: 'Текст пісні',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LyricsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music, size: 26),
            tooltip: 'Черга',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QueueScreen()),
              );
            },
          ),
          PlayerPopupMenu(audioProvider: audioProvider),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            AmbientPlayerBackdrop(song: song),
            OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;

                if (isLandscape) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: PlayerHeader(song: song)),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (audioProvider.showInlineLyrics && audioProvider.hasKaraokeLyrics)
                                  const InlineLyrics(),
                                _buildVisualizerArea(audioProvider),
                                PlayerControls(song: song),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(flex: 7, child: PlayerHeader(song: song)),
                        if (audioProvider.showInlineLyrics && audioProvider.hasKaraokeLyrics)
                          const InlineLyrics(),
                        _buildVisualizerArea(audioProvider),
                        PlayerControls(song: song),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildVisualizerArea(AudioProvider audioProvider) {
    if (!audioProvider.showVisualizer) return const SizedBox.shrink();
    if (audioProvider.playbackError != null) {
      return SizedBox(
        height: 50,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  audioProvider.playbackError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Flexible(
      child: SizedBox(
        height: 50,
        width: double.infinity,
        child: AudioVisualizer(
          isPlaying: audioProvider.isPlaying,
          width: double.infinity,
          height: 50,
          barCount: 60,
        ),
      ),
    );
  }
}
