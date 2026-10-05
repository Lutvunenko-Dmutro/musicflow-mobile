import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/models/lrclib_search_result.dart';
import 'package:music_flow_mobile/services/online_lyrics_client.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_result_card.dart';

class LyricsSearchSheet extends StatefulWidget {
  final SongModel song;

  const LyricsSearchSheet({super.key, required this.song});

  static Future<void> show(BuildContext context, {required SongModel song}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => LyricsSearchSheet(song: song),
    );
  }

  @override
  State<LyricsSearchSheet> createState() => _LyricsSearchSheetState();
}

class _LyricsSearchSheetState extends State<LyricsSearchSheet> {
  late final TextEditingController _controller;
  List<LrclibSearchResult> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final info = OnlineLyricsClient.cleanArtistAndTitle(widget.song.author, widget.song.title);
    _controller = TextEditingController(text: '${info.artist} ${info.track}'.trim());
    _performSearch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await OnlineLyricsClient.searchLrclib(query);
      if (mounted) setState(() { _results = res; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Помилка пошуку. Перевірте зв\'язок.'; _isLoading = false; });
    }
  }

  void _selectAndSave(LrclibSearchResult item) async {
    final provider = context.read<AudioProvider>();
    final tag = item.isKaraoke ? 'Караоке' : 'Текст';
    await provider.setCustomLyrics(widget.song, '$tag (${item.artistName} - ${item.trackName})', item.bestLyrics);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Збережено караоке: ${item.trackName}'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Row(children: [
            Icon(Icons.manage_search_rounded, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text('Пошук та збереження караоке', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Введіть назву або виконавця...',
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Пошук', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(minHeight: 3, backgroundColor: primary.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation<Color>(primary)),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Шукаємо караоке в базі LRCLIB...', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    }
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_results.isEmpty) {
      return const Center(child: Text('Нічого не знайдено. Спробуйте змінити запит.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, i) => LyricsResultCard(
        item: _results[i],
        onSelect: () => _selectAndSave(_results[i]),
      ),
    );
  }
}
