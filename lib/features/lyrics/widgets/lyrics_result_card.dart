import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/lrclib_search_result.dart';

class LyricsResultCard extends StatelessWidget {
  final LrclibSearchResult item;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const LyricsResultCard({
    super.key,
    required this.item,
    required this.onSelect,
    required this.onPreview,
  });

  String _formatDuration(double sec) {
    if (sec <= 0) return '';
    final m = (sec / 60).floor();
    final s = (sec % 60).round().toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _cleanPreview(String raw) {
    return raw
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'\[\d+:\d+\.?\d*\]'), '').trim())
        .where((l) => l.isNotEmpty)
        .take(2)
        .join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final dur = _formatDuration(item.duration);
    final preview = _cleanPreview(item.bestLyrics);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: item.isKaraoke ? 0.07 : 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isKaraoke ? primary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.isKaraoke ? Icons.mic_external_on_rounded : Icons.article_outlined,
                size: 18,
                color: item.isKaraoke ? primary : Colors.white60,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.trackName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (dur.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                  child: Text(dur, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(item.artistName, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              if (item.albumName != null && item.albumName!.trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text('•', style: TextStyle(color: Colors.white38)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.albumName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (item.isKaraoke ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: (item.isKaraoke ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.isKaraoke ? Icons.check_circle : Icons.info_outline, size: 11, color: item.isKaraoke ? Colors.greenAccent : Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      item.isKaraoke ? 'Синхронізоване караоке' : 'Статичний текст',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: item.isKaraoke ? Colors.greenAccent : Colors.amber),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text('Джерело: LRCLIB (#${item.id})', style: const TextStyle(fontSize: 10, color: Colors.white60)),
              ),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '«$preview»',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  label: const Text('Прев\'ю 👁️'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Зберегти'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.isKaraoke ? primary : Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
