import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/audio_visualizer.dart';
import 'package:music_flow_mobile/features/player/widgets/player_header.dart';
import 'package:music_flow_mobile/features/player/widgets/player_controls.dart';
import 'package:music_flow_mobile/features/player/screens/queue_screen.dart';
import 'package:music_flow_mobile/features/lyrics/screens/lyrics_screen.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/inline_lyrics.dart';
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
        title: const Text('Now Playing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lyrics_outlined, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LyricsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.queue_music, size: 28),
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
        child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.5),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            if (isLandscape) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    children: [
                      // Left side: Cover art and title
                      Expanded(
                        flex: 1,
                        child: PlayerHeader(song: song),
                      ),
                      const SizedBox(width: 32),
                      // Right side: Lyrics, visualizer, controls
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (audioProvider.showInlineLyrics) const InlineLyrics(),
                            if (audioProvider.showVisualizer)
                              Flexible(
                                child: SizedBox(
                                  height: 60,
                                  width: double.infinity,
                                  child: audioProvider.playbackError != null
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.wifi_off, color: Colors.redAccent, size: 24),
                                              const SizedBox(height: 8),
                                              Text(
                                                audioProvider.playbackError!,
                                                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        )
                                      : AudioVisualizer(isPlaying: audioProvider.isPlaying),
                                ),
                              ),
                            PlayerControls(song: song),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Portrait Mode
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      flex: 7,
                      child: PlayerHeader(song: song),
                    ),
                    if (audioProvider.showInlineLyrics) const InlineLyrics(),
                    if (audioProvider.showVisualizer)
                      Flexible(
                        child: SizedBox(
                          height: 60,
                          width: double.infinity,
                          child: audioProvider.playbackError != null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.wifi_off, color: Colors.redAccent, size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        audioProvider.playbackError!,
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                )
                              : AudioVisualizer(isPlaying: audioProvider.isPlaying),
                        ),
                      ),
                    PlayerControls(song: song),
                  ],
                ),
              ),
            );
          }
        ),
      ),
      ),
    );
  }

}
