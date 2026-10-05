import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/models/lrclib_search_result.dart';
import 'package:music_flow_mobile/services/online_lyrics_client.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_result_card.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_preview_sheet.dart';

class LyricsSearchSheet extends StatefulWidget {
  final SongModel song;

  const LyricsSearchSheet({super.key, required this.song});

  static Future<void> show(BuildContext context, {required SongModel song}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
  int _tab = 0;

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await OnlineLyricsClient.searchLrclib(query);
      if (mounted) setState(() { _results = res; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Помилка пошуку. Перевірте зв\'язок.'; _isLoading = false; });
    }
  }

  void _selectAndSave(LrclibSearchResult item) async {
    final provider = context.read<AudioProvider>();
    final tag = item.isKaraoke ? 'Караоке [LRCLIB]' : 'Текст [LRCLIB]';
    await provider.setCustomLyrics(widget.song, '$tag: ${item.artistName} - ${item.trackName}', item.bestLyrics);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Збережено караоке з LRCLIB: ${item.artistName} - ${item.trackName}'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildChip(int idx, String txt, Color pri) {
    final sel = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? pri.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? pri : Colors.white12),
        ),
        child: Text(txt, style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.bold : FontWeight.normal, color: sel ? pri : Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pri = Theme.of(context).primaryColor;
    final kCount = _results.where((r) => r.isKaraoke).length;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: pri.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.manage_search_rounded, size: 20, color: pri)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Пошук караоке в базі LRCLIB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${widget.song.author} • ${widget.song.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Виконавець або назва...',
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _performSearch(),
            )),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _performSearch,
              style: ElevatedButton.styleFrom(backgroundColor: pri, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Пошук', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
          if (_isLoading) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(minHeight: 3, backgroundColor: pri.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation<Color>(pri)))),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              _buildChip(0, 'Всі (${_results.length})', pri),
              _buildChip(1, '⏱️ Караоке ($kCount)', pri),
              _buildChip(2, '📄 Текст (${_results.length - kCount})', pri),
            ]),
          ],
          const SizedBox(height: 10),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _results.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Шукаємо караоке в базі LRCLIB...', style: TextStyle(color: Colors.white70, fontSize: 13))]));
    }
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    if (_results.isEmpty) return const Center(child: Text('Нічого не знайдено. Спробуйте змінити запит.', style: TextStyle(color: Colors.grey)));

    final list = _tab == 1 ? _results.where((r) => r.isKaraoke).toList() : (_tab == 2 ? _results.where((r) => !r.isKaraoke).toList() : _results);
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) => LyricsResultCard(
        item: list[i],
        onPreview: () => LyricsPreviewSheet.show(
          context,
          song: widget.song,
          item: list[i],
          onConfirmSave: () => _selectAndSave(list[i]),
        ),
        onSelect: () => _selectAndSave(list[i]),
      ),
    );
  }
}
