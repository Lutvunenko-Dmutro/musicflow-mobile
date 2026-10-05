import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';

class LyricsSourceBanner extends StatelessWidget {
  final AudioProvider provider;
  final SongModel? song;
  final bool isKaraoke;

  const LyricsSourceBanner({
    super.key,
    required this.provider,
    required this.song,
    required this.isKaraoke,
  });

  Future<void> _confirmDelete(BuildContext context, String key) async {
    if (song == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Видалити це караоке?', style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Text(
          'Ви впевнені, що хочете видалити версію "$key" для пісні "${song!.title}"?',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.removeLyricsTrack(song!, key);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Караоке успішно видалено'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = provider.selectedLyricsKey ?? '';
    String src = 'LRCLIB';
    Color col = Theme.of(context).primaryColor;
    IconData ico = Icons.mic_external_on_rounded;
    final lower = key.toLowerCase();
    if (lower.contains('youtube')) {
      src = 'YouTube';
      col = Colors.redAccent;
      ico = Icons.play_circle_filled_rounded;
    } else if (lower.contains('ovh')) {
      src = 'Lyrics.ovh';
      col = Colors.lightBlueAccent;
      ico = Icons.language_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(ico, size: 16, color: col),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Джерело: $src', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: col)),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    const SizedBox(width: 6),
                    Text(
                      isKaraoke ? 'Синхронізоване ⏱️' : 'Статичний текст 📄',
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
                Text(key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
          if (song != null) ...[
            GestureDetector(
              onTap: () => LyricsSearchSheet.show(context, song: song!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                child: const Text('Змінити', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _confirmDelete(context, key),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
