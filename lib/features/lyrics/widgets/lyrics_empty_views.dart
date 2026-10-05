import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';

class LyricsDisabledView extends StatelessWidget {
  final SongModel? song;
  final VoidCallback onEnable;

  const LyricsDisabledView({super.key, required this.song, required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.subtitles_off_outlined, size: 54, color: Colors.white38),
          const SizedBox(height: 14),
          const Text('Субтитри вимкнено для цієї пісні', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Налаштування збережено для цього треку', style: TextStyle(color: Colors.white38, fontSize: 13)),
          if (song != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.subtitles, size: 18),
              label: const Text('Увімкнути субтитри'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LyricsEmptyView extends StatelessWidget {
  final SongModel? song;
  final String? errorMsg;

  const LyricsEmptyView({super.key, required this.song, this.errorMsg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lyrics_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(errorMsg ?? 'Текст пісні не знайдено', style: const TextStyle(color: Colors.white54, fontSize: 15)),
          if (song != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => LyricsSearchSheet.show(context, song: song!),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Знайти караоке в базі'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                foregroundColor: Theme.of(context).primaryColor,
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
