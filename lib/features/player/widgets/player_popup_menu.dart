import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_settings_sheet.dart';
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
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => const VisualizerSettingsSheet(),
          );
        } else if (value == 'toggle_visualizer') {
          audioProvider.toggleVisualizer();
        } else if (value == 'toggle_lyrics') {
          audioProvider.toggleInlineLyrics();
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
