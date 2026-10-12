import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/settings/screens/visualizer_settings_screen.dart';
import 'package:music_flow_mobile/features/settings/screens/equalizer_screen.dart';
import 'package:music_flow_mobile/features/player/widgets/sleep_timer_dialog.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class PlayerPopupMenu extends StatelessWidget {
  final AudioProvider audioProvider;

  const PlayerPopupMenu({super.key, required this.audioProvider});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 28),
      onSelected: (value) {
        if (value == 'visualizer_settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VisualizerSettingsScreen()),
          );
        } else if (value == 'toggle_visualizer') {
          audioProvider.toggleVisualizer();
        } else if (value == 'toggle_lyrics') {
          audioProvider.toggleInlineLyrics();
        } else if (value == 'toggle_song_lyrics') {
          final song = audioProvider.currentSong;
          if (song != null) {
            if (audioProvider.isLyricsDisabledForCurrentSong) {
              audioProvider.enableLyricsForSong(song.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.lyricsEnabledSnackbar), behavior: SnackBarBehavior.floating),
              );
            } else {
              audioProvider.disableLyricsForSong(song.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(strings.lyricsDisabledSnackbar), behavior: SnackBarBehavior.floating),
              );
            }
          }
        } else if (value == 'search_lyrics') {
          final song = audioProvider.currentSong;
          if (song != null) {
            LyricsSearchSheet.show(context, song: song);
          }
        } else if (value == 'sleep_timer') {
          showDialog(
            context: context,
            builder: (context) => SleepTimerDialog(provider: audioProvider),
          );
        } else if (value == 'equalizer') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EqualizerScreen()));
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'search_lyrics',
          child: Row(
            children: [
              const Icon(Icons.manage_search_rounded, size: 20),
              const SizedBox(width: 12),
              Text(strings.searchKaraoke),
            ],
          ),
        ),
        if (audioProvider.availableLyrics != null && audioProvider.availableLyrics!.isNotEmpty)
          PopupMenuItem<String>(
            value: 'toggle_song_lyrics',
            child: Row(
              children: [
                Icon(
                  audioProvider.isLyricsDisabledForCurrentSong ? Icons.subtitles_off_rounded : Icons.subtitles_rounded,
                  size: 20,
                  color: audioProvider.isLyricsDisabledForCurrentSong ? Colors.amber : null,
                ),
                const SizedBox(width: 12),
                Text(
                  audioProvider.isLyricsDisabledForCurrentSong
                      ? strings.enableLyricsForSong
                      : strings.disableLyricsForSong,
                ),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'toggle_lyrics',
          child: Row(
            children: [
              Icon(
                audioProvider.showInlineLyrics ? Icons.lyrics : Icons.lyrics_outlined, 
                size: 20
              ),
              const SizedBox(width: 12),
              Text(audioProvider.showInlineLyrics ? strings.hideMiniKaraoke : strings.showMiniKaraoke),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_visualizer',
          child: Row(
            children: [
              Icon(
                audioProvider.showVisualizer ? Icons.graphic_eq : Icons.graphic_eq_outlined, 
                size: 20
              ),
              const SizedBox(width: 12),
              Text(audioProvider.showVisualizer ? strings.hideVisualizer : strings.showVisualizer),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'visualizer_settings',
          child: Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 12),
              Text(strings.visualizerSettings),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'sleep_timer',
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 12),
              Text(strings.sleepTimer),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'equalizer',
          child: Row(
            children: [
              const Icon(Icons.equalizer, size: 20),
              const SizedBox(width: 12),
              Text(strings.equalizer),
            ],
          ),
        ),
      ],
    );
  }
}
