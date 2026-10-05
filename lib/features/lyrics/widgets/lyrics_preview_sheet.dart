import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/models/lrclib_search_result.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/utils/lyrics_parser.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_list_view.dart';

class LyricsPreviewSheet extends StatelessWidget {
  final SongModel song;
  final LrclibSearchResult item;
  final VoidCallback onConfirmSave;

  const LyricsPreviewSheet({
    super.key,
    required this.song,
    required this.item,
    required this.onConfirmSave,
  });

  static Future<void> show(
    BuildContext context, {
    required SongModel song,
    required LrclibSearchResult item,
    required VoidCallback onConfirmSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => LyricsPreviewSheet(song: song, item: item, onConfirmSave: onConfirmSave),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final audio = context.watch<AudioProvider>();
    final parsed = LyricsParser.parse(item.bestLyrics);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: (item.isKaraoke ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(item.isKaraoke ? Icons.mic_external_on_rounded : Icons.article_outlined, size: 20, color: item.isKaraoke ? Colors.greenAccent : Colors.amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.trackName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${item.artistName} • Джерело: LRCLIB (#${item.id})', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (item.isKaraoke ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (item.isKaraoke ? Colors.greenAccent : Colors.amber).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(item.isKaraoke ? Icons.play_circle_fill_rounded : Icons.info_outline, size: 14, color: item.isKaraoke ? Colors.greenAccent : Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.isKaraoke ? 'Живий перегляд караоке під час поточної музики' : 'Статичний текст (без синхронних таймінгів)',
                    style: TextStyle(fontSize: 11, color: item.isKaraoke ? Colors.greenAccent : Colors.amber, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: item.isKaraoke
                ? StreamBuilder<Duration>(
                    stream: audio.positionStream,
                    builder: (context, snapshot) {
                      final currentSec = (snapshot.data?.inMilliseconds ?? 0) / 1000.0;
                      return LyricsListView(
                        lines: parsed.lines,
                        isKaraoke: true,
                        currentSec: currentSec,
                      );
                    },
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Text(item.bestLyrics, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white70)),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Назад'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirmSave();
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(item.isKaraoke ? 'Зберегти це караоке' : 'Зберегти цей текст', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
