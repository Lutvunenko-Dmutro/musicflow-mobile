import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_version_sheet.dart';

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
        content: Text('Видалити версію "$key" для "${song!.title}"?', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати', style: TextStyle(color: Colors.white60))),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Караоке успішно видалено'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = provider.selectedLyricsKey ?? '';
    String src = 'LRCLIB';
    IconData ico = Icons.mic_external_on_rounded;
    final lower = key.toLowerCase();
    if (lower.contains('youtube')) {
      src = 'YouTube';
      ico = Icons.play_circle_filled_rounded;
    } else if (lower.contains('ovh')) {
      src = 'Lyrics.ovh';
      ico = Icons.language_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => LyricsVersionSheet.show(context, audioProvider: provider, song: song),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(ico, size: 18, color: AppColors.primary),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('•', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isKaraoke ? 'Синхронізоване ⏱️' : 'Статичний текст 📄',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isKaraoke ? Colors.amberAccent : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (song != null) ...[
                  InkWell(
                    onTap: () => LyricsVersionSheet.show(context, audioProvider: provider, song: song),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Змінити',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, size: 20, color: Colors.white70),
                    tooltip: 'Знайти в базі',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => LyricsSearchSheet.show(context, song: song!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.white60),
                    tooltip: 'Видалити версію',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _confirmDelete(context, key),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
