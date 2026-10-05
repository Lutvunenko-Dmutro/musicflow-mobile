import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/lyrics_parser.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_list_view.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_version_menu.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  List<LyricsLine> _lines = [];
  bool _isKaraoke = false;
  String? _lastParsedLyrics;

  Widget _buildDisabledView(BuildContext context, AudioProvider provider, SongModel? song) {
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
              onPressed: () => provider.enableLyricsForSong(song.id),
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

  Widget _buildEmptyView(BuildContext context, AudioProvider provider, SongModel? song) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lyrics_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(provider.lyricsErrorMsg ?? 'Текст пісні не знайдено', style: const TextStyle(color: Colors.white54, fontSize: 15)),
          if (song != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => LyricsSearchSheet.show(context, song: song),
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

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;
    
    if (_lastParsedLyrics != audioProvider.currentLyrics) {
      _lastParsedLyrics = audioProvider.currentLyrics;
      final result = LyricsParser.parse(_lastParsedLyrics);
      _lines = result.lines;
      _isKaraoke = result.isKaraoke;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(song?.title ?? 'Текст пісні', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (song != null)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Знайти інше караоке',
              onPressed: () => LyricsSearchSheet.show(context, song: song),
            ),
          LyricsVersionMenu(audioProvider: audioProvider, song: song),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.3),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (!_isKaraoke && _lines.isNotEmpty && song != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 15, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Статичний текст (без синхронізації)', style: TextStyle(fontSize: 11, color: Colors.amber)),
                      ),
                      GestureDetector(
                        onTap: () => LyricsSearchSheet.show(context, song: song),
                        child: const Text('Знайти караоке ⏱️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: audioProvider.isLyricsLoading 
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 160,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Завантаження караоке та тексту...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      )
                    : audioProvider.isLyricsDisabledForCurrentSong
                        ? _buildDisabledView(context, audioProvider, song)
                        : audioProvider.currentLyrics == null
                            ? _buildEmptyView(context, audioProvider, song)
                            : StreamBuilder<Duration>(
                                stream: audioProvider.positionStream,
                                builder: (context, snapshot) {
                                  final currentSec = (snapshot.data?.inMilliseconds ?? 0) / 1000.0;
                                  return LyricsListView(
                                    lines: _lines,
                                    isKaraoke: _isKaraoke,
                                    currentSec: currentSec,
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
