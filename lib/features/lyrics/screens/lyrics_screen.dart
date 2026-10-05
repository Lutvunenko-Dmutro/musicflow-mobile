import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/utils/lyrics_parser.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_list_view.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_version_menu.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_empty_views.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  List<LyricsLine> _lines = [];
  bool _isKaraoke = false;
  String? _lastParsedLyrics;

  Widget _buildSourceInfoBanner(BuildContext context, AudioProvider provider, SongModel? song) {
    final key = provider.selectedLyricsKey ?? '';
    String src = 'LRCLIB';
    Color col = Theme.of(context).primaryColor;
    IconData ico = Icons.mic_external_on_rounded;
    final lower = key.toLowerCase();
    if (lower.contains('youtube')) {
      src = 'YouTube'; col = Colors.redAccent; ico = Icons.play_circle_filled_rounded;
    } else if (lower.contains('ovh')) {
      src = 'Lyrics.ovh'; col = Colors.lightBlueAccent; ico = Icons.language_rounded;
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
                    Text(_isKaraoke ? 'Синхронізоване ⏱️' : 'Статичний текст 📄', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
                Text(key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
          if (song != null)
            GestureDetector(
              onTap: () => LyricsSearchSheet.show(context, song: song),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                child: const Text('Змінити', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(song?.title ?? 'Текст пісні', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (song != null)
              Text(song.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
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
              if (audioProvider.currentLyrics != null && !audioProvider.isLyricsDisabledForCurrentSong)
                _buildSourceInfoBanner(context, audioProvider, song),
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
                        ? LyricsDisabledView(song: song, onEnable: () => audioProvider.enableLyricsForSong(song!.id))
                        : audioProvider.currentLyrics == null
                            ? LyricsEmptyView(song: song, errorMsg: audioProvider.lyricsErrorMsg)
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
