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
    Color col = const Color(0xFF4FC3F7); // Читабельний яскравий Cyan
    IconData ico = Icons.mic_external_on_rounded;
    final lower = key.toLowerCase();
    if (lower.contains('youtube')) {
      src = 'YouTube';
      col = const Color(0xFFFF5252);
      ico = Icons.play_circle_filled_rounded;
    } else if (lower.contains('ovh')) {
      src = 'Lyrics.ovh';
      col = const Color(0xFF81D4FA);
      ico = Icons.language_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ico, size: 18, color: col),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Джерело: $src',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: col,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(width: 6),
                    Text(
                      isKaraoke ? 'Синхронізоване ⏱️' : 'Статичний текст 📄',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isKaraoke ? Colors.amberAccent : Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (song != null) ...[
            InkWell(
              onTap: () => LyricsSearchSheet.show(context, song: song!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Змінити',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _confirmDelete(context, key),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
