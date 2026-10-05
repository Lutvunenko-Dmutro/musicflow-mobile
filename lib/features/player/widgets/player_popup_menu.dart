import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/settings/screens/visualizer_settings_screen.dart';
import 'package:music_flow_mobile/features/settings/screens/equalizer_screen.dart';
import 'package:music_flow_mobile/features/player/widgets/sleep_timer_dialog.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';

class PlayerPopupMenu extends StatelessWidget {
  final AudioProvider audioProvider;

  const PlayerPopupMenu({super.key, required this.audioProvider});

  @override
  Widget build(BuildContext context) {
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
                const SnackBar(content: Text('Субтитри увімкнено для цієї пісні'), behavior: SnackBarBehavior.floating),
              );
            } else {
              audioProvider.disableLyricsForSong(song.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Збережено: цю пісню залишено без субтитрів'), behavior: SnackBarBehavior.floating),
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
        const PopupMenuItem<String>(
          value: 'search_lyrics',
          child: Row(
            children: [
              Icon(Icons.manage_search_rounded, size: 20),
              SizedBox(width: 12),
              Text('Знайти інше караоке'),
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
                      ? 'Увімкнути субтитри для пісні'
                      : 'Без субтитрів для цієї пісні',
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
              Text(audioProvider.showInlineLyrics ? 'Приховати міні-караоке' : 'Показати міні-караоке'),
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
              Text(audioProvider.showVisualizer ? 'Приховати візуалізатор' : 'Показати візуалізатор'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'visualizer_settings',
          child: Row(
            children: [
              Icon(Icons.tune, size: 20),
              SizedBox(width: 12),
              Text('Налаштування візуалізатора'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'sleep_timer',
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 20),
              SizedBox(width: 12),
              Text('Таймер сну'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'equalizer',
          child: Row(
            children: [
              Icon(Icons.equalizer, size: 20),
              SizedBox(width: 12),
              Text('Еквалайзер'),
            ],
          ),
        ),
      ],
    );
  }
}
