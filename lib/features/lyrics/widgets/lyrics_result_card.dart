import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/lrclib_search_result.dart';

class LyricsResultCard extends StatelessWidget {
  final LrclibSearchResult item;
  final VoidCallback onSelect;

  const LyricsResultCard({
    super.key,
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final preview = item.bestLyrics
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .take(2)
        .join(' / ');

    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(item.trackName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(item.artistName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  item.isKaraoke ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 13,
                  color: item.isKaraoke ? Colors.greenAccent : Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  item.isKaraoke ? 'Синхронізовані таймінги (підсвічування)' : 'Статичний текст (без таймінгів)',
                  style: TextStyle(
                    color: item.isKaraoke ? Colors.greenAccent : Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: onSelect,
          style: ElevatedButton.styleFrom(
            backgroundColor: item.isKaraoke ? primary : Colors.white24,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            item.isKaraoke ? '⏱️ Караоке' : 'Текст',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
