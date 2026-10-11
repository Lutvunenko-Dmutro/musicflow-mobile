import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/audio_visualizer.dart';
import 'package:music_flow_mobile/features/player/widgets/player_header.dart';
import 'package:music_flow_mobile/features/player/widgets/player_controls.dart';
import 'package:music_flow_mobile/features/player/screens/queue_screen.dart';
import 'package:music_flow_mobile/features/lyrics/screens/lyrics_screen.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/inline_lyrics.dart';
import 'package:music_flow_mobile/features/player/widgets/ambient_player_backdrop.dart';
import 'package:music_flow_mobile/features/player/widgets/player_popup_menu.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  void _dismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

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

    return PopScope(
      onPopInvokedWithResult: (didPop, _) => FocusManager.instance.primaryFocus?.unfocus(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 180) {
            _dismiss(context);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _dismiss(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 5),
                  Text(context.l10n.nowPlaying, style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 30),
              onPressed: () => _dismiss(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.lyrics_outlined, size: 24),
                tooltip: 'Текст пісні',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LyricsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.queue_music, size: 26),
                tooltip: 'Черга',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QueueScreen())),
              ),
              PlayerPopupMenu(audioProvider: audioProvider),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
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
                                _buildVisualizerArea(context, audioProvider),
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
                        _buildVisualizerArea(context, audioProvider),
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
    ),
  );
}


  Widget _buildVisualizerArea(BuildContext context, AudioProvider audioProvider) {
    if (!audioProvider.showVisualizer) return const SizedBox.shrink();
    if (audioProvider.playbackError != null) {
      return SizedBox(
        height: 50,
        child: Center(
          child: InkWell(
            onTap: () {
              final song = audioProvider.currentSong;
              if (song != null) audioProvider.playSong(song);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${audioProvider.playbackError!} • Натисніть для повтору',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final vis = context.watch<VisualizerSettingsProvider?>();
    if (vis?.position == VisualizerPosition.coverAura) {
      return const SizedBox(height: 12);
    }
    final h = (vis?.style == VisualizerStyle.circle) ? 75.0 : 50.0;
    return Flexible(
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: AudioVisualizer(
          isPlaying: audioProvider.isPlaying,
          width: double.infinity,
          height: h,
        ),
      ),
    );
  }
}
