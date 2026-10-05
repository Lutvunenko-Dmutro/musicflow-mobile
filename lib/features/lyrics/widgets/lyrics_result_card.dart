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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isKaraoke ? primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPreview,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(primary, dur),
                const SizedBox(height: 10),
                _buildBadges(),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildPreviewBox(preview),
                ],
                const SizedBox(height: 12),
                _buildActions(primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary, String dur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (item.isKaraoke ? primary : Colors.white24).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.isKaraoke ? Icons.mic_external_on_rounded : Icons.lyrics_rounded, size: 20, color: item.isKaraoke ? primary : Colors.white70),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(item.trackName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (dur.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)), child: Text(dur, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70))),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.albumName != null && item.albumName!.trim().isNotEmpty ? '${item.artistName} • ${item.albumName}' : item.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadges() {
    final isK = item.isKaraoke;
    final color = isK ? const Color(0xFF00E676) : Colors.amber;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isK ? Icons.timer_outlined : Icons.article_outlined, size: 13, color: color),
              const SizedBox(width: 5),
              Text(isK ? 'Синхронізоване' : 'Статичний текст', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text('LRCLIB #${item.id}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white38))),
      ],
    );
  }

  Widget _buildPreviewBox(String preview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
      child: Text('«$preview»', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic, height: 1.3)),
    );
  }

  Widget _buildActions(Color primary) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPreview,
            icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
            label: const Text('Переглянути'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Вибрати'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
